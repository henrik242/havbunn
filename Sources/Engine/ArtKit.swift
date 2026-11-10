import CoreGraphics
import CoreText
import Foundation
import Metal
import Synchronization

typealias XY = (Double, Double)
typealias C3 = SIMD3<Float>
typealias RGBA = SIMD4<Float>

func hex(_ v: UInt32) -> C3 {
    C3(Float((v >> 16) & 255) / 255, Float((v >> 8) & 255) / 255, Float(v & 255) / 255)
}
@inline(__always) func mix(_ a: C3, _ b: C3, _ t: Float) -> C3 { a + (b - a) * t }
@inline(__always) func mixf(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
@inline(__always) func clamp01(_ x: Float) -> Float { min(1, max(0, x)) }
@inline(__always) func rgba(_ c: C3, _ a: Float = 1) -> RGBA { RGBA(c.x, c.y, c.z, a) }

func chaikin(_ pts: [XY], closed: Bool = false, iterations: Int = 3) -> [XY] {
    var cur = pts
    guard cur.count > 2 else { return cur }
    for _ in 0..<iterations {
        var out: [XY] = []
        out.reserveCapacity(cur.count * 2)
        let n = cur.count
        if !closed { out.append(cur[0]) }
        for i in 0..<(closed ? n : n - 1) {
            let a = cur[i], b = cur[(i + 1) % n]
            out.append((a.0 * 0.75 + b.0 * 0.25, a.1 * 0.75 + b.1 * 0.25))
            out.append((a.0 * 0.25 + b.0 * 0.75, a.1 * 0.25 + b.1 * 0.75))
        }
        if !closed { out.append(cur[n - 1]) }
        cur = out
    }
    return cur
}

/// Polyline y(x), sampled for per-column body painting.
struct Curve {
    let pts: [XY]
    init(_ control: [XY]) { pts = chaikin(control).sorted { $0.0 < $1.0 } }
    var minX: Double { pts.first!.0 }
    var maxX: Double { pts.last!.0 }
    func value(_ x: Double) -> Double {
        if x <= pts.first!.0 { return pts.first!.1 }
        if x >= pts.last!.0 { return pts.last!.1 }
        var lo = 0, hi = pts.count - 1
        while hi - lo > 1 {
            let m = (lo + hi) / 2
            if pts[m].0 <= x { lo = m } else { hi = m }
        }
        let a = pts[lo], b = pts[hi]
        let t = (x - a.0) / max(1e-6, b.0 - a.0)
        return a.1 + (b.1 - a.1) * t
    }
}

let artNoise = Noise(seed: 77)

/// Jittered dots on a grid. Returns coverage 0...1.
func spots(_ x: Float, _ y: Float, cell: Float, radius: Float, keep: Float = 1, seed: Int32 = 0) -> Float {
    let gx = (x / cell).rounded(.down), gy = (y / cell).rounded(.down)
    var best: Float = 0
    for oy in Int32(-1)...1 {
        for ox in Int32(-1)...1 {
            let ix = Int32(gx) &+ ox &+ seed, iy = Int32(gy) &+ oy &+ seed &* 3
            if artNoise.hash(ix &+ 91, iy &- 17) > keep { continue }
            let px = gx + Float(ox) + artNoise.hash(ix, iy)
            let py = gy + Float(oy) + artNoise.hash(iy, ix &+ 5)
            let scale = 0.55 + 0.75 * artNoise.hash(ix &+ 3, iy &+ 8)
            let dx = x / cell - px, dy = y / cell - py
            let d = (dx * dx + dy * dy).squareRoot() * cell
            let r = radius * scale
            best = max(best, clamp01((r - d) / max(0.7, r * 0.35)))
        }
    }
    return best
}

/// Overlapping scale rows. Returns line strength 0...1.
func scales(_ x: Float, _ y: Float, size s: Float) -> Float {
    let row = (y / (s * 0.8)).rounded(.down)
    let shift: Float = Int(row) % 2 == 0 ? 0 : 0.5
    let fx = x / s + shift
    let cx = fx.rounded(.down) + 0.5
    let dx = fx - cx, dy = y / (s * 0.8) - row - 0.1
    let d = (dx * dx + dy * dy).squareRoot()
    return clamp01(1 - abs(d - 0.58) * 6)
}

/// Lit like a rounded flank: brighter above the midline, dark at both edges.
@inline(__always) func roundLight(_ v: Float) -> Float {
    let n = 2 * v - 1
    let s = max(0, 1 - n * n).squareRoot()
    return 0.56 + 0.46 * s - 0.17 * n
}

final class Art {
    let ctx: CGContext
    let data: UnsafeMutablePointer<UInt8>
    let atlasW: Int
    let ox: Int, oy: Int, pxW: Int, pxH: Int
    let k: Double
    let unitH: Double
    var rng: RNG

    init(ctx: CGContext, ox: Int, oy: Int, pxW: Int, pxH: Int, seed: UInt64) {
        self.ctx = ctx
        data = ctx.data!.assumingMemoryBound(to: UInt8.self)
        atlasW = ctx.width
        self.ox = ox; self.oy = oy; self.pxW = pxW; self.pxH = pxH
        k = Double(pxW) / 1000
        unitH = 1000 * Double(pxH) / Double(pxW)
        rng = RNG(seed &+ 1)
    }

    func color(_ c: C3, _ a: Double = 1) -> CGColor {
        CGColor(srgbRed: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: CGFloat(a))
    }

    func path(_ pts: [XY], closed: Bool = true, smooth: Bool = true) -> CGPath {
        let list = smooth ? chaikin(pts, closed: closed) : pts
        let p = CGMutablePath()
        p.move(to: CGPoint(x: list[0].0, y: list[0].1))
        for q in list.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
        if closed { p.closeSubpath() }
        return p
    }

    func fill(_ pts: [XY], _ c: C3, _ a: Double = 1) {
        ctx.setFillColor(color(c, a))
        ctx.addPath(path(pts))
        ctx.fillPath()
    }

    func gradient(_ p: CGPath, _ stops: [(C3, Double, CGFloat)], from: XY, to: XY) {
        let cols = stops.map { color($0.0, $0.1) } as CFArray
        let locs = stops.map { $0.2 }
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let g = CGGradient(colorsSpace: cs, colors: cols, locations: locs) else { return }
        ctx.saveGState()
        ctx.addPath(p)
        ctx.clip()
        ctx.drawLinearGradient(g, start: CGPoint(x: from.0, y: from.1), end: CGPoint(x: to.0, y: to.1),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
    }

    func line(_ pts: [XY], _ c: C3, _ a: Double, _ w: Double, smooth: Bool = true) {
        ctx.setStrokeColor(color(c, a))
        ctx.setLineWidth(w)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addPath(path(pts, closed: false, smooth: smooth))
        ctx.strokePath()
    }

    func softDot(_ x: Double, _ y: Double, _ r: Double, _ c: C3, _ a: Double, sy: Double = 1) {
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let g = CGGradient(colorsSpace: cs, colors: [color(c, a), color(c, 0)] as CFArray, locations: [0, 1]) else { return }
        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.scaleBy(x: 1, y: sy)
        ctx.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: r, options: [])
        ctx.restoreGState()
    }

    func disc(_ x: Double, _ y: Double, _ r: Double, _ c: C3, _ a: Double = 1, sy: Double = 1) {
        ctx.setFillColor(color(c, a))
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r * sy, width: r * 2, height: r * 2 * sy))
    }

    /// Tapered ribbon along a smoothed centerline.
    func taper(_ pts: [XY], _ w0: Double, _ w1: Double, _ c: C3, _ a: Double = 1) {
        fill(taperPolygon(pts, w0, w1), c, a, raw: true)
    }

    func taperPolygon(_ pts: [XY], _ w0: Double, _ w1: Double) -> [XY] {
        let line = chaikin(pts, iterations: 3)
        var left: [XY] = [], right: [XY] = []
        for i in 0..<line.count {
            let a = line[max(0, i - 1)], b = line[min(line.count - 1, i + 1)]
            var nx = -(b.1 - a.1), ny = b.0 - a.0
            let len = max(1e-6, (nx * nx + ny * ny).squareRoot())
            nx /= len; ny /= len
            let t = Double(i) / Double(line.count - 1)
            let w = (w0 + (w1 - w0) * t) * 0.5
            left.append((line[i].0 + nx * w, line[i].1 + ny * w))
            right.append((line[i].0 - nx * w, line[i].1 - ny * w))
        }
        return left + right.reversed()
    }

    func fill(_ pts: [XY], _ c: C3, _ a: Double, raw: Bool) {
        ctx.setFillColor(color(c, a))
        ctx.addPath(path(pts, closed: true, smooth: !raw))
        ctx.fillPath()
    }

    /// Fin: membrane between base and edge polylines, with rays.
    func fin(base: [XY], edge: [XY], root: C3, tip: C3, alpha: Double = 0.85, rays: Int = 12) {
        let e = chaikin(edge, iterations: 2)
        let b = chaikin(base, iterations: 2)
        let outline = b + e.reversed()
        let p = path(outline, closed: true, smooth: false)
        let bc = base[base.count / 2], ec = edge[edge.count / 2]
        gradient(p, [(root, alpha, 0), (tip, alpha * 0.32, 1)], from: bc, to: ec)
        guard rays > 0 else { return }
        ctx.saveGState()
        ctx.addPath(p)
        ctx.clip()
        for i in 0...rays {
            let t = Double(i) / Double(rays)
            let bi = b[Int(t * Double(b.count - 1))]
            let ei = e[Int(t * Double(e.count - 1))]
            line([bi, ei], root * 0.55, 0.25, 1.4, smooth: false)
        }
        ctx.restoreGState()
    }

    func eye(_ x: Double, _ y: Double, _ r: Double, iris: C3 = hex(0xc8a24a)) {
        disc(x, y, r * 1.12, hex(0x14120e), 0.45)
        disc(x, y, r, iris)
        softDot(x + r * 0.2, y + r * 0.35, r * 0.9, iris * 0.45, 0.8)
        disc(x, y, r * 0.58, hex(0x05070a))
        disc(x - r * 0.26, y - r * 0.30, r * 0.13, C3(1, 1, 1), 0.6)
    }

    private func composite(_ px: Int, _ py: Int, _ c: RGBA) {
        let idx = (py * atlasW + px) * 4
        let a = clamp01(c.w)
        if a <= 0 { return }
        let inv = 1 - a
        for (i, v) in [c.x, c.y, c.z].enumerated() {
            let d = Float(data[idx + i]) / 255
            data[idx + i] = UInt8(clamp01(clamp01(v) * a + d * inv) * 255 + 0.5)
        }
        let d = Float(data[idx + 3]) / 255
        data[idx + 3] = UInt8(clamp01(a + d * inv) * 255 + 0.5)
    }

    /// Paints a body between two curves using a per-pixel shader.
    /// Shader gets t (0 at min x, 1 at max x), v (0 top, 1 bottom), and unit coordinates.
    func body(top: [XY], bottom: [XY], _ shader: (Float, Float, Float, Float) -> RGBA) {
        let T = Curve(top), B = Curve(bottom)
        let x0 = min(T.minX, B.minX), x1 = max(T.maxX, B.maxX)
        let px0 = max(0, Int(x0 * k) - 1), px1 = min(pxW - 1, Int(x1 * k) + 1)
        for px in px0...px1 {
            let xu = (Double(px) + 0.5) / k
            if xu < x0 || xu > x1 { continue }
            let yt = T.value(xu), yb = B.value(xu)
            if yb <= yt { continue }
            let t = Float((xu - x0) / (x1 - x0))
            let edgeCov = Float(min(1, min((xu - x0) * k + 0.5, (x1 - xu) * k + 0.5)))
            let py0 = max(0, Int(yt * k) - 1), py1 = min(pxH - 1, Int(yb * k) + 1)
            if py0 > py1 { continue }
            for py in py0...py1 {
                let yu = (Double(py) + 0.5) / k
                let cov = Float(max(0, min(1, (yu - yt) * k + 0.5)) * max(0, min(1, (yb - yu) * k + 0.5))) * edgeCov
                if cov <= 0 { continue }
                let v = Float(max(0, min(1, (yu - yt) / (yb - yt))))
                var c = shader(t, v, Float(xu), Float(yu))
                c.w *= cov
                composite(ox + px, oy + py, c)
            }
        }
    }

    /// Paints a polar shape, squashed vertically for a low viewing angle.
    func polar(cx: Double, cy: Double, sy: Double, maxR: Double,
               radius: (Float) -> Float, _ shader: (Float, Float, Float, Float) -> RGBA) {
        let px0 = max(0, Int((cx - maxR) * k) - 1), px1 = min(pxW - 1, Int((cx + maxR) * k) + 1)
        let py0 = max(0, Int((cy - maxR * sy) * k) - 1), py1 = min(pxH - 1, Int((cy + maxR * sy) * k) + 1)
        guard px0 <= px1, py0 <= py1 else { return }
        for py in py0...py1 {
            for px in px0...px1 {
                let xu = (Double(px) + 0.5) / k - cx, yu = ((Double(py) + 0.5) / k - cy) / sy
                let r = Float((xu * xu + yu * yu).squareRoot())
                let th = Float(atan2(yu, xu))
                let R = radius(th)
                let cov = clamp01((R - r) * Float(k) * Float(sy) + 0.5)
                if cov <= 0 { continue }
                var c = shader(r / max(0.001, R), th, Float(xu + cx), Float(yu + cy))
                c.w *= cov
                composite(ox + px, oy + py, c)
            }
        }
    }
}

struct AtlasFrame {
    let uv: SIMD4<Float>
    let aspect: Float   // width over height
}

struct SpriteDef {
    let name: String
    let w: Int, h: Int
    let paint: (Art) -> Void
}

final class Atlas {
    static let side = 4096
    static let maxHeight = 8192
    static let pad = 24

    let texture: MTLTexture
    private(set) var frames: [String: AtlasFrame] = [:]

    private struct Cache { weak var atlas: Atlas? }
    private static let cache = Mutex(Cache())

    let english: Bool

    static func shared(device: MTLDevice, english: Bool) -> Atlas {
        // Built under the lock, so displays starting together share one atlas.
        cache.withLock { c in
            if let a = c.atlas, a.texture.device === device, a.english == english { return a }
            let a = Atlas(device: device, english: english)
            c.atlas = a
            return a
        }
    }

    func frame(_ name: String) -> AtlasFrame {
        guard let f = frames[name] else { fatalError("missing sprite \(name)") }
        return f
    }

    private init(device: MTLDevice, english: Bool) {
        self.english = english
        let side = Atlas.side
        let defs = Species.spriteDefs(english: english).sorted { $0.h > $1.h }

        // Pack first, then size the texture to what the sprites need, so adding species never
        // overflows. Shelves in order of height keep the packing tight.
        var layout: [(SpriteDef, Int, Int)] = []
        var x = Atlas.pad, y = Atlas.pad, shelf = 0
        for d in defs {
            if x + d.w + Atlas.pad > side {
                x = Atlas.pad
                y += shelf + Atlas.pad
                shelf = 0
            }
            layout.append((d, x, y))
            x += d.w + Atlas.pad
            shelf = max(shelf, d.h)
        }
        let height = min(Atlas.maxHeight, y + shelf + Atlas.pad)
        Atlas.usedHeight = y + shelf
        if y + shelf + Atlas.pad > Atlas.maxHeight {
            NSLog("Havbunn: atlas needs %d rows, more than %d", y + shelf + Atlas.pad, Atlas.maxHeight)
        }

        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(data: nil, width: side, height: height, bitsPerComponent: 8, bytesPerRow: side * 4,
                            space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)
        ctx.interpolationQuality = .high

        let w = Float(side), h = Float(height)
        for (seed, (d, x, y)) in layout.enumerated() where y + d.h <= height {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: x, y: y, width: d.w, height: d.h))
            ctx.translateBy(x: CGFloat(x), y: CGFloat(y))
            let art = Art(ctx: ctx, ox: x, oy: y, pxW: d.w, pxH: d.h, seed: UInt64(seed + 1))
            ctx.scaleBy(x: art.k, y: art.k)
            d.paint(art)
            ctx.restoreGState()
            frames[d.name] = AtlasFrame(
                uv: SIMD4(Float(x) / w, Float(y) / h, Float(x + d.w) / w, Float(y + d.h) / h),
                aspect: Float(d.w) / Float(d.h))
        }

        let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: side, height: height, mipmapped: true)
        td.usage = .shaderRead
        texture = device.makeTexture(descriptor: td)!
        texture.replace(region: MTLRegionMake2D(0, 0, side, height), mipmapLevel: 0,
                        withBytes: ctx.data!, bytesPerRow: side * 4)
        if let q = device.makeCommandQueue(), let c = q.makeCommandBuffer(), let b = c.makeBlitCommandEncoder() {
            b.generateMipmaps(for: texture)
            b.endEncoding()
            c.commit()
            c.waitUntilCompleted()
        }
    }

    static var usedHeight = 0
}
