import Foundation

/// Small deterministic RNG so a seed reproduces a whole scene.
struct RNG {
    var s: UInt64
    init(_ seed: UInt64) { s = seed &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> UInt64 {
        s ^= s << 13; s ^= s >> 7; s ^= s << 17
        return s
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
    mutating func range(_ a: Double, _ b: Double) -> Double { a + (b - a) * unit() }
    mutating func float(_ a: Float, _ b: Float) -> Float { a + (b - a) * Float(unit()) }
    mutating func int(_ a: Int, _ b: Int) -> Int { a + Int(unit() * Double(b - a + 1)) }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
}

func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
    let t = min(1, max(0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)
}

/// Value noise used for terrain and for sprite painting.
struct Noise {
    let seed: UInt32
    @inline(__always) func hash(_ x: Int32, _ y: Int32) -> Float {
        var h = UInt32(bitPattern: x) &* 1597334677 ^ UInt32(bitPattern: y) &* 3812015801 ^ seed
        h = (h ^ (h >> 15)) &* 2246822519
        h = (h ^ (h >> 13)) &* 3266489917
        h ^= h >> 16
        return Float(h) / 4294967295.0
    }
    @inline(__always) func value(_ x: Float, _ y: Float) -> Float {
        let fx = x.rounded(.down), fy = y.rounded(.down)
        let ix = Int32(truncatingIfNeeded: Int(fx)), iy = Int32(truncatingIfNeeded: Int(fy))
        let tx = x - fx, ty = y - fy
        let ux = tx * tx * (3 - 2 * tx), uy = ty * ty * (3 - 2 * ty)
        let a = hash(ix, iy), b = hash(ix &+ 1, iy), c = hash(ix, iy &+ 1), d = hash(ix &+ 1, iy &+ 1)
        return (a + (b - a) * ux) * (1 - uy) + (c + (d - c) * ux) * uy
    }
    func fbm(_ x: Float, _ y: Float, _ oct: Int = 4) -> Float {
        var a: Float = 0.5, s: Float = 0, n: Float = 0, px = x, py = y
        for _ in 0..<oct {
            s += a * value(px, py); n += a; a *= 0.5
            let nx = px * 1.6 - py * 1.2 + 7.1
            py = px * 1.2 + py * 1.6 + 3.7
            px = nx
        }
        return s / n
    }
}

/// Seabed heightfield, built on the CPU so placement and the GPU raymarch agree.
final class Terrain {
    static let size = 640
    let halfX: Float = 45
    let maxZ: Float = 90
    /// Screen x of the coral mound, where light and attention gather.
    let focusNdc: Float
    private(set) var data: [SIMD2<Float>]   // height, rock mask

    private struct Boulder { var x, z, r, h: Float }

    init(seed: UInt64, aspect: Float, focal: Float) {
        let n = Terrain.size
        data = [SIMD2<Float>](repeating: .zero, count: n * n)
        var rng = RNG(seed ^ 0x5EABED)
        let noise = Noise(seed: UInt32(truncatingIfNeeded: seed))
        let halfXv = halfX, maxZv = maxZ

        // Rocks are placed in screen terms so each seed composes a framed view
        // with open sand in the middle foreground.
        var boulders: [Boulder] = []
        func addBoulder(ndc: Float, z: Float, r: Float, h: Float) {
            boulders.append(Boulder(x: ndc * z * aspect / focal, z: z, r: r, h: h))
        }
        let side: Float = rng.chance(0.5) ? 1 : -1
        for _ in 0..<7 {  // major outcrop on one side
            addBoulder(ndc: side * rng.float(0.55, 1.15), z: rng.float(4.5, 13), r: rng.float(1.0, 2.6), h: rng.float(0.7, 2.4))
        }
        for _ in 0..<5 {  // lesser outcrop on the other
            addBoulder(ndc: -side * rng.float(0.65, 1.2), z: rng.float(5.5, 15), r: rng.float(0.8, 2.0), h: rng.float(0.5, 1.6))
        }
        // Reef mound behind the sand, where the coral grows.
        let moundNdc = -side * rng.float(0.05, 0.32)
        focusNdc = moundNdc
        addBoulder(ndc: moundNdc, z: rng.float(11, 14), r: rng.float(3.0, 4.2), h: rng.float(1.3, 1.9))
        addBoulder(ndc: moundNdc + side * 0.28, z: rng.float(13, 17), r: rng.float(2.5, 3.5), h: rng.float(1.3, 2.0))
        for _ in 0..<16 {  // scattered stones
            addBoulder(ndc: rng.float(-1.3, 1.3), z: rng.float(4.5, 22), r: rng.float(0.16, 0.55), h: rng.float(0.1, 0.42))
        }

        let cx = rng.float(-3, 3)
        data.withUnsafeMutableBufferPointer { buf in
            for j in 0..<n {
                let z = Float(j) / Float(n - 1) * maxZv
                for i in 0..<n {
                    let x = (Float(i) / Float(n - 1) * 2 - 1) * halfXv
                    let sand = (noise.fbm(x * 0.11 + 3, z * 0.11, 3) - 0.5) * 0.65
                    let warp = noise.fbm(x * 0.09 + 40, z * 0.09, 3) * 12 - 6

                    // Fjord wall climbing away from the camera, with ridges.
                    let ridge = 1 - abs(noise.fbm(x * 0.075, z * 0.075 + 9, 4) * 2 - 1)
                    let wall = smooth(17, 52, z + warp) * (9 + ridge * 11)

                    // Flanks closing in at the screen edges further away.
                    let lateral = abs(x - cx) / (z * 0.95 + 2)
                    let flankAmt = smooth(0.85, 1.45, lateral + warp * 0.02)
                    let flank = flankAmt * (2.0 + z * 0.17) * (0.5 + ridge)

                    var bump: Float = 0
                    for b in boulders {
                        let dx = x - b.x, dz = (z - b.z) * 1.15
                        let d2 = dx * dx + dz * dz
                        let reach = b.r * 1.5
                        if d2 > reach * reach { continue }
                        let w = noise.fbm(x * 0.9 + b.x, z * 0.9 + b.z, 3) * 0.55 - 0.27
                        let d = d2.squareRoot() / b.r + w
                        if d < 1 {
                            let v = (1 - d * d)
                            // Height capped by width, with gentle shoulders, so no lone spires.
                            bump = max(bump, min(b.h, b.r * 0.9) * v * v * (3 - 2 * v))
                        }
                    }
                    // Nothing may reach the camera plane, or rays start inside rock.
                    let relief = max(max(wall, flank), bump) * smooth(2.4, 3.8, z)
                    let rock = smooth(0.10, 0.45, relief)
                    let craggy = rock * (noise.fbm(x * 0.45 + 17, z * 0.45, 4) - 0.5) * 1.6 * smooth(0.5, 3, relief)
                    buf[j * n + i] = SIMD2(sand + relief + craggy, rock)
                }
            }
        }
    }

    private func lookup(_ x: Float, _ z: Float) -> SIMD2<Float> {
        let n = Terrain.size
        let gx = min(Float(n - 1) - 0.001, max(0, (x + halfX) / (2 * halfX) * Float(n - 1)))
        let gz = min(Float(n - 1) - 0.001, max(0, z / maxZ * Float(n - 1)))
        let ix = Int(gx), iz = Int(gz)
        let fx = gx - Float(ix), fz = gz - Float(iz)
        let a = data[iz * n + ix], b = data[iz * n + ix + 1]
        let c = data[(iz + 1) * n + ix], d = data[(iz + 1) * n + ix + 1]
        let top = a + (b - a) * fx, bottom = c + (d - c) * fx
        return top + (bottom - top) * fz
    }

    func height(_ x: Float, _ z: Float) -> Float { lookup(x, z).x }
    func rock(_ x: Float, _ z: Float) -> Float { lookup(x, z).y }
    func slope(_ x: Float, _ z: Float) -> Float {
        let e: Float = 0.25
        return (height(x + e, z) - height(x - e, z)) / (2 * e)
    }
}
