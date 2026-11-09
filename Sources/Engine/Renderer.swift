import Foundation
import Metal
import QuartzCore

struct Uniforms {
    var time: Float = 0, aspect: Float = 1.6, focal: Float = 1.5, camY: Float = 1.3
    var horizon: Float = -0.4, fogK: Float = 0.058, fade: Float = 1, seed: Float = 0
    var viewport = SIMD2<Float>(1, 1)
    var worldHalf = SIMD2<Float>(45, 90)
}

struct Sprite {
    var pos: SIMD4<Float>
    var size: SIMD4<Float>
    var uv: SIMD4<Float>
    var anim: SIMD4<Float>
    var look: SIMD4<Float>
    var tint: SIMD4<Float>
}

public final class Renderer {
    enum RenderError: Error { case setup(String) }

    public static let pixelFormat = MTLPixelFormat.bgra8Unorm
    private static let maxSprites = 1400
    private static let framesInFlight = 3
    private static let causticSize = 512
    private static let gridCells = 24

    let device: MTLDevice
    private let queue: MTLCommandQueue
    private let bakePipeline, causticPipeline, backdropPipeline, spritePipeline, snowPipeline, overlayPipeline: MTLRenderPipelineState
    private let gridVertices, gridIndices: MTLBuffer
    private let gridIndexCount: Int
    private var spriteBuffers: [MTLBuffer] = []
    private var frameIndex = 0
    private let inflight = DispatchSemaphore(value: Renderer.framesInFlight)

    private var atlas: Atlas?
    private var terrain: Terrain?
    private var world: World?
    private var bakeColor, bakeDepth, caustic: MTLTexture?
    private var uniforms = Uniforms()
    private let seed: UInt64
    private var clock: Double = 0
    private var causticClock: Double = 1

    public var showNames = true
    public private(set) var isPrepared = false
    public var preparedAspect: Float { uniforms.aspect }

    public init(device: MTLDevice, shaderSource: URL, seed: UInt64) throws {
        self.device = device
        self.seed = seed
        guard let queue = device.makeCommandQueue() else { throw RenderError.setup("no queue") }
        self.queue = queue
        let lib = try device.makeLibrary(source: String(contentsOf: shaderSource, encoding: .utf8), options: nil)

        func make(_ vs: String, _ fs: String, formats: [MTLPixelFormat], blend: Bool) throws -> MTLRenderPipelineState {
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = lib.makeFunction(name: vs)
            d.fragmentFunction = lib.makeFunction(name: fs)
            for (i, f) in formats.enumerated() { d.colorAttachments[i].pixelFormat = f }
            if blend {
                let a = d.colorAttachments[0]!
                a.isBlendingEnabled = true
                a.sourceRGBBlendFactor = .one
                a.sourceAlphaBlendFactor = .one
                a.destinationRGBBlendFactor = .oneMinusSourceAlpha
                a.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
            return try device.makeRenderPipelineState(descriptor: d)
        }
        let fmt = Renderer.pixelFormat
        bakePipeline = try make("fullscreenVS", "bakeFS", formats: [.rgba8Unorm, .r32Float], blend: false)
        causticPipeline = try make("fullscreenVS", "causticFS", formats: [.r8Unorm], blend: false)
        backdropPipeline = try make("fullscreenVS", "backdropFS", formats: [fmt], blend: false)
        spritePipeline = try make("spriteVS", "spriteFS", formats: [fmt], blend: true)
        snowPipeline = try make("snowVS", "snowFS", formats: [fmt], blend: true)
        overlayPipeline = try make("fullscreenVS", "overlayFS", formats: [fmt], blend: true)

        // Unit grid shared by all sprites; deformation happens in the vertex shader.
        let n = Renderer.gridCells
        var verts: [Float] = []
        for j in 0...n { for i in 0...n { verts += [Float(i) / Float(n), Float(j) / Float(n)] } }
        var idx: [UInt16] = []
        for j in 0..<n {
            for i in 0..<n {
                let a = UInt16(j * (n + 1) + i), b = a + 1, c = a + UInt16(n + 1), d = c + 1
                idx += [a, b, c, b, d, c]
            }
        }
        guard let vb = device.makeBuffer(bytes: verts, length: verts.count * 4),
              let ib = device.makeBuffer(bytes: idx, length: idx.count * 2) else { throw RenderError.setup("grid") }
        gridVertices = vb; gridIndices = ib; gridIndexCount = idx.count

        for _ in 0..<Renderer.framesInFlight {
            guard let b = device.makeBuffer(length: MemoryLayout<Sprite>.stride * Renderer.maxSprites,
                                            options: .storageModeShared) else { throw RenderError.setup("sprites") }
            spriteBuffers.append(b)
        }
    }

    /// Heavy one-time setup. Safe off the main thread, must finish before draw.
    public func prepare(width: Int, height: Int) {
        let aspect = Float(width) / Float(max(1, height))
        uniforms.aspect = aspect
        uniforms.seed = Float(seed % 997) * 0.37
        uniforms.worldHalf = SIMD2(45, 90)

        let atlas = Atlas.shared(device: device)
        let terrain = Terrain(seed: seed, aspect: aspect, focal: uniforms.focal)
        self.atlas = atlas
        self.terrain = terrain
        world = World(seed: seed, terrain: terrain, atlas: atlas, aspect: aspect, focal: uniforms.focal,
                      camY: uniforms.camY, horizon: uniforms.horizon)
        bake(terrain: terrain, width: width, height: height)

        let cd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: Renderer.causticSize,
                                                          height: Renderer.causticSize, mipmapped: true)
        cd.usage = [.renderTarget, .shaderRead]
        cd.storageMode = .private
        caustic = device.makeTexture(descriptor: cd)
        isPrepared = true
    }

    private func bake(terrain: Terrain, width: Int, height: Int) {
        // Water and rock are soft, so capping the bake saves real time on 5K+ panels.
        let scale = min(1.0, 2880.0 / Double(max(width, 1)))
        let w = max(16, Int(Double(width) * scale)), h = max(16, Int(Double(height) * scale))

        let hd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rg32Float, width: Terrain.size,
                                                          height: Terrain.size, mipmapped: false)
        hd.usage = .shaderRead
        guard let heightTex = device.makeTexture(descriptor: hd) else { return }
        terrain.data.withUnsafeBytes {
            heightTex.replace(region: MTLRegionMake2D(0, 0, Terrain.size, Terrain.size), mipmapLevel: 0,
                              withBytes: $0.baseAddress!, bytesPerRow: Terrain.size * 8)
        }

        let cd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: w, height: h, mipmapped: false)
        cd.usage = [.renderTarget, .shaderRead]
        cd.storageMode = .private
        let dd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: w, height: h, mipmapped: false)
        dd.usage = [.renderTarget, .shaderRead]
        dd.storageMode = .private
        guard let color = device.makeTexture(descriptor: cd), let depth = device.makeTexture(descriptor: dd) else { return }

        // Bands in separate command buffers keep the GPU responsive during the bake.
        let bands = 12
        var last: MTLCommandBuffer?
        for b in 0..<bands {
            let rp = MTLRenderPassDescriptor()
            rp.colorAttachments[0].texture = color
            rp.colorAttachments[1].texture = depth
            rp.colorAttachments[0].loadAction = b == 0 ? .clear : .load
            rp.colorAttachments[1].loadAction = b == 0 ? .clear : .load
            rp.colorAttachments[0].storeAction = .store
            rp.colorAttachments[1].storeAction = .store
            guard let cmd = queue.makeCommandBuffer(), let enc = cmd.makeRenderCommandEncoder(descriptor: rp) else { continue }
            let y0 = h * b / bands, y1 = h * (b + 1) / bands
            enc.setScissorRect(MTLScissorRect(x: 0, y: y0, width: w, height: y1 - y0))
            enc.setRenderPipelineState(bakePipeline)
            var u = uniforms
            enc.setFragmentBytes(&u, length: MemoryLayout<Uniforms>.stride, index: 0)
            enc.setFragmentTexture(heightTex, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
            cmd.commit()
            last = cmd
        }
        last?.waitUntilCompleted()
        bakeColor = color
        bakeDepth = depth
    }

    /// Advances the simulation without drawing.
    public func step(_ dt: Double) {
        clock += dt
        world?.update(dt: Float(dt))
    }

    /// Encodes a full frame targeting `texture`. Caller presents and commits via `finish`.
    public func draw(to texture: MTLTexture, dt: Double, finish: (MTLCommandBuffer) -> Void) {
        guard isPrepared, let world = world, let atlas = atlas, let color = bakeColor, let depth = bakeDepth,
              let caustic = caustic else { return }
        inflight.wait()
        guard let cmd = queue.makeCommandBuffer() else { inflight.signal(); return }
        let sem = inflight
        cmd.addCompletedHandler { _ in sem.signal() }

        step(min(dt, 0.1))
        causticClock += dt
        let time = Float(clock.truncatingRemainder(dividingBy: 7200))
        uniforms.time = time
        uniforms.viewport = SIMD2(Float(texture.width), Float(texture.height))
        uniforms.fade = Float(min(1, clock / 1.6))
        if fadeOverride >= 0 { uniforms.fade = fadeOverride }
        var u = uniforms

        // Caustic tile, refreshed at 30 Hz.
        if causticClock >= 1.0 / 30.0 {
            causticClock = 0
            let rp = MTLRenderPassDescriptor()
            rp.colorAttachments[0].texture = caustic
            rp.colorAttachments[0].loadAction = .dontCare
            rp.colorAttachments[0].storeAction = .store
            if let enc = cmd.makeRenderCommandEncoder(descriptor: rp) {
                enc.setRenderPipelineState(causticPipeline)
                enc.setFragmentBytes(&u, length: MemoryLayout<Uniforms>.stride, index: 0)
                enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                enc.endEncoding()
            }
            if let blit = cmd.makeBlitCommandEncoder() {
                blit.generateMipmaps(for: caustic)
                blit.endEncoding()
            }
        }

        frameIndex = (frameIndex + 1) % Renderer.framesInFlight
        let buffer = spriteBuffers[frameIndex]
        let ptr = buffer.contents().bindMemory(to: Sprite.self, capacity: Renderer.maxSprites)
        let count = world.fillSprites(into: ptr, capacity: Renderer.maxSprites, showNames: showNames)

        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = texture
        rp.colorAttachments[0].loadAction = .clear
        rp.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        rp.colorAttachments[0].storeAction = .store
        guard let enc = cmd.makeRenderCommandEncoder(descriptor: rp) else { finish(cmd); return }

        enc.setRenderPipelineState(backdropPipeline)
        enc.setFragmentBytes(&u, length: MemoryLayout<Uniforms>.stride, index: 0)
        enc.setFragmentTexture(color, index: 0)
        enc.setFragmentTexture(depth, index: 1)
        enc.setFragmentTexture(caustic, index: 2)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        enc.setRenderPipelineState(spritePipeline)
        enc.setVertexBuffer(gridVertices, offset: 0, index: 0)
        enc.setVertexBuffer(buffer, offset: 0, index: 1)
        enc.setVertexBytes(&u, length: MemoryLayout<Uniforms>.stride, index: 2)
        enc.setFragmentTexture(atlas.texture, index: 0)
        enc.setFragmentTexture(depth, index: 1)
        enc.setFragmentTexture(caustic, index: 2)
        if count > 0 {
            enc.drawIndexedPrimitives(type: .triangle, indexCount: gridIndexCount, indexType: .uint16,
                                      indexBuffer: gridIndices, indexBufferOffset: 0, instanceCount: count)
        }

        enc.setRenderPipelineState(snowPipeline)
        enc.setVertexBytes(&u, length: MemoryLayout<Uniforms>.stride, index: 0)
        enc.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1500)

        enc.setRenderPipelineState(overlayPipeline)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()

        finish(cmd)
    }

    /// Lets the host control the fade, for example to skip it in offscreen renders.
    public var fadeOverride: Float = -1

    /// Drops GPU-heavy state after the saver stops. `prepare` restores it.
    public func tearDown() {
        for _ in 0..<Renderer.framesInFlight { inflight.wait() }
        for _ in 0..<Renderer.framesInFlight { inflight.signal() }
        isPrepared = false
        atlas = nil
        terrain = nil
        world = nil
        bakeColor = nil
        bakeDepth = nil
        caustic = nil
    }

    public func forceHaakjerring() { world?.forceRareVisitor() }
}
