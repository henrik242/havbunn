// Prints a GPU-free fingerprint of the scene: the atlas pixels, and per seed a hash of every
// sprite the world emits over a few simulated minutes plus the order of captions shown.
// `make check` compares it with Tools/trace.golden; `make golden` rewrites that file after an
// intended change to the scene.
//
// Usage: havbunn-trace [seconds]
import Foundation
import Metal

@main
struct Main {
    static func fnv(_ h: inout UInt64, _ p: UnsafeRawBufferPointer) {
        for b in p { h = (h ^ UInt64(b)) &* 1099511628211 }
    }

    static func main() {
        let seconds = CommandLine.arguments.count > 1 ? Double(CommandLine.arguments[1])! : 300
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("no metal") }

        for english in [false, true] {
            let t = Atlas.shared(device: device, english: english).texture
            var px = [UInt8](repeating: 0, count: t.width * t.height * 4)
            t.getBytes(&px, bytesPerRow: t.width * 4, from: MTLRegionMake2D(0, 0, t.width, t.height), mipmapLevel: 0)
            var h: UInt64 = 1469598103934665603
            px.withUnsafeBytes { fnv(&h, $0) }
            print("atlas \(english ? "en" : "no") \(t.width)x\(t.height) \(String(h, radix: 16))")
        }

        let atlas = Atlas.shared(device: device, english: false)
        var captionOf: [SIMD4<Float>: String] = [:]
        for s in Species.all { captionOf[atlas.frame("cap-\(s.key)").uv] = s.key }
        let cap = 2048
        let buf = UnsafeMutablePointer<Sprite>.allocate(capacity: cap)
        defer { buf.deallocate() }

        for seed: UInt64 in [1, 7, 42] {
            // Same camera as Renderer.prepare at 16:10.
            let aspect: Float = 1.6, focal = max(1.5, aspect / 1.25)
            let horizon: Float = -0.4 + 0.1 * min(1, max(0, (aspect - 1.78) / 0.6))
            let terrain = Terrain(seed: seed, aspect: aspect, focal: focal)
            let world = World(seed: seed, terrain: terrain, atlas: atlas, aspect: aspect, overscan: Renderer.overscan,
                              focal: focal, camY: 1.3, horizon: horizon)
            var h: UInt64 = 1469598103934665603
            var captions: [String] = []
            for _ in 0..<Int(seconds * 30) {
                world.update(dt: 1 / 30)
                let n = world.fillSprites(into: buf, capacity: cap, showNames: true)
                fnv(&h, UnsafeRawBufferPointer(start: buf, count: n * MemoryLayout<Sprite>.stride))
                if let key = (0..<n).lazy.compactMap({ captionOf[buf[$0].uv] }).first, captions.last != key {
                    captions.append(key)
                }
            }
            print("seed \(seed) \(String(h, radix: 16)) \(captions.joined(separator: ","))")
        }
    }
}
