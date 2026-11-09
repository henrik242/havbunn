import Foundation

private struct SwimmerSpec {
    let key: String
    let length: Float
    let speed: Float
    let zr: ClosedRange<Float>
    let alt: ClosedRange<Float>
    let amp: Float
    let wave: Float
    let count: Int
}

private final class Fish {
    let spec: SwimmerSpec
    let frame: AtlasFrame
    let scale: Float
    var x, y, z: Float
    var vx: Float = 0, vy: Float = 0, vz: Float = 0
    var tx: Float = 0, ty: Float = 0, tz: Float = 0
    var retarget: Float = 0
    var phase: Float
    var yaw: Float       // 0 facing +x, pi facing -x
    var pitch: Float = 0
    var tint: C3
    var active = true
    init(spec: SwimmerSpec, frame: AtlasFrame, x: Float, y: Float, z: Float, phase: Float, facing: Float, scale: Float, tint: C3) {
        self.spec = spec; self.frame = frame
        self.x = x; self.y = y; self.z = z
        self.phase = phase
        self.yaw = facing > 0 ? 0 : .pi
        self.scale = scale
        self.tint = tint
    }
}

private final class School {
    let spec: SwimmerSpec
    var members: [Fish] = []
    var cx: Float = 0, cy: Float = 0, cz: Float = 0
    var retarget: Float = 0
    init(spec: SwimmerSpec) { self.spec = spec }
}

private final class Walker {
    enum Gait { case walk, sideways }
    let key: String, frames: [AtlasFrame], gait: Gait
    let length, speed: Float
    var x, z: Float
    var facing: Float
    var yaw: Float
    var pause: Float
    var leg: Float = 0
    var heading: Float
    var moving = false
    init(key: String, frames: [AtlasFrame], gait: Gait, length: Float, speed: Float, x: Float, z: Float, facing: Float, heading: Float) {
        self.key = key; self.frames = frames; self.gait = gait
        self.length = length; self.speed = speed
        self.x = x; self.z = z
        self.facing = facing
        yaw = facing > 0 ? 0 : .pi
        pause = 0
        self.heading = heading
    }
}

/// Bottom-dwelling fish that rest and sometimes glide.
private final class Rester {
    let key: String, frame: AtlasFrame, length: Float
    let mode: Float, amp: Float
    let glideSpeed: Float
    let restMin, restMax: Float
    var x, z: Float
    var y: Float
    var facing: Float
    var yaw: Float
    var phase: Float = 0
    var timer: Float
    var gliding = false
    var glideAmount: Float = 0
    var dirZ: Float = 0
    let height: Float   // how far the anchor floats above the floor
    init(key: String, frame: AtlasFrame, length: Float, mode: Float, amp: Float, glideSpeed: Float, rest: (Float, Float),
         x: Float, z: Float, y: Float, facing: Float, height: Float, timer: Float) {
        self.key = key; self.frame = frame; self.length = length
        self.mode = mode; self.amp = amp; self.glideSpeed = glideSpeed
        restMin = rest.0; restMax = rest.1
        self.x = x; self.z = z; self.y = y
        self.facing = facing
        yaw = facing > 0 ? 0 : .pi
        self.height = height
        self.timer = timer
    }
}

private final class Jelly {
    let key: String, frame: AtlasFrame, width: Float
    var x, y, z: Float
    var vx: Float
    var phase: Float
    let rate: Float
    init(key: String, frame: AtlasFrame, width: Float, x: Float, y: Float, z: Float, vx: Float, phase: Float, rate: Float) {
        self.key = key; self.frame = frame; self.width = width
        self.x = x; self.y = y; self.z = z; self.vx = vx; self.phase = phase; self.rate = rate
    }
}

private struct Fixture {
    let key: String
    let frame: AtlasFrame
    let x, y, z: Float
    let halfW, halfH: Float
    let mode: Float
    let amp: Float
    let ripple: Float
    let phase: Float
    let flip: Float
    let tint: C3
    let shadowW: Float
    let rate: Float
}

final class World {
    private let terrain: Terrain
    private let atlas: Atlas
    private var rng: RNG
    private let aspect, focal, camY, horizon: Float
    private var time: Float = 0

    private var schools: [School] = []
    private var loners: [Fish] = []
    private var rare: Fish?
    private var rareTimer: Float
    private var walkers: [Walker] = []
    private var resters: [Rester] = []
    private var jellies: [Jelly] = []
    private var fixtures: [Fixture] = []

    private var drawList: [(Float, Sprite)] = []

    private var captionKey: String?
    private var captionClock: Float = -3
    private var captionHistory: [String] = []
    /// Slightly larger than life so animals hold their own on screen.
    private static let creatureScale: Float = 1.3
    private static let captionShown: Float = 9
    private static let captionGap: Float = 12

    private let shadow: AtlasFrame

    init(seed: UInt64, terrain: Terrain, atlas: Atlas, aspect: Float, focal: Float, camY: Float, horizon: Float) {
        self.terrain = terrain
        self.atlas = atlas
        self.aspect = aspect; self.focal = focal; self.camY = camY; self.horizon = horizon
        rng = RNG(seed ^ 0xF15B)
        shadow = atlas.frame("shadow")
        rareTimer = rng.float(150, 320)
        populateFixtures()
        populateSwimmers()
        populateBottom()
    }

    // MARK: setup

    private func viewHalfWidth(_ z: Float) -> Float { z * aspect / focal }

    /// Looks for a seabed spot in view that satisfies the rock-mask test.
    private func findSpot(z zr: ClosedRange<Float>, ndc: ClosedRange<Float> = -1.1...1.1,
                          rock: ClosedRange<Float>, tries: Int = 80) -> (Float, Float, Float)? {
        for _ in 0..<tries {
            let z = rng.float(zr.lowerBound, zr.upperBound)
            let x = rng.float(ndc.lowerBound, ndc.upperBound) * viewHalfWidth(z)
            if rock.contains(terrain.rock(x, z)) {
                return (x, terrain.height(x, z) - 0.03, z)
            }
        }
        return nil
    }

    private func populateFixtures() {
        func tint(_ low: Float = 0.9, _ high: Float = 1.06) -> C3 {
            let v = rng.float(low, high)
            return C3(repeating: v)
        }
        func add(_ key: String, _ frameName: String, spot: (Float, Float, Float), height: Float, mode: Float, amp: Float,
                 ripple: Float = 0, shadowW: Float = 0, tintC: C3? = nil, flip: Bool = true, rate: Float = 1) {
            let f = atlas.frame(frameName)
            fixtures.append(Fixture(
                key: key, frame: f, x: spot.0, y: spot.1, z: spot.2, halfW: height * f.aspect / 2, halfH: height / 2,
                mode: mode, amp: amp, ripple: ripple, phase: rng.float(0, 6.28),
                flip: flip && rng.chance(0.5) ? -1 : 1, tint: tintC ?? tint(), shadowW: shadowW, rate: rate))
        }

        // Reef mounds carry the coral first so nothing else crowds them out.
        for _ in 0..<14 {
            guard let s = findSpot(z: 7.5...19, ndc: -0.9...0.9, rock: 0.55...1.01) else { continue }
            let v = ["oyekorall-1", "oyekorall-2", "oyekorall-3", "oyekorall-1"][rng.int(0, 3)]
            add("oyekorall", v, spot: s, height: rng.float(0.95, 1.7), mode: 0, amp: 0, shadowW: 0.8)
        }
        for _ in 0..<5 {
            guard let s = findSpot(z: 8...20, rock: 0.55...1.01) else { continue }
            add("sjotre", rng.chance(0.6) ? "sjotre-1" : "sjotre-2", spot: s, height: rng.float(0.8, 1.35), mode: 2, amp: 0.018, shadowW: 0.5)
        }

        // Kelp forest on shallower rock.
        for _ in 0..<26 {
            guard let s = findSpot(z: 4.5...24, rock: 0.5...1.01) else { continue }
            add("stortare", "stortare-\(rng.int(1, 3))", spot: s, height: rng.float(1.5, 2.5), mode: 2, amp: 0.055, shadowW: 0.4)
        }
        for _ in 0..<16 {
            guard let s = findSpot(z: 4...20, rock: 0.4...1.01) else { continue }
            add("sukkertare", "sukkertare-\(rng.int(1, 2))", spot: s, height: rng.float(1.5, 2.8), mode: 2, amp: 0.12, ripple: 0.05, shadowW: 0.3)
        }
        // Out-of-focus kelp close to the lens frames the shot.
        for side: Float in [-1, 1] {
            for _ in 0..<(rng.int(1, 3)) {
                let z = rng.float(3.0, 3.9)
                let x = side * rng.float(0.82, 1.04) * viewHalfWidth(z)
                let key = rng.chance(0.5) ? "sukkertare" : "stortare"
                let name = key == "sukkertare" ? "sukkertare-\(rng.int(1, 2))" : "stortare-\(rng.int(1, 3))"
                add(key, name, spot: (x, terrain.height(x, z) - 0.03, z), height: rng.float(2.2, 3.0), mode: 2, amp: 0.08, ripple: 0.03)
            }
        }

        for _ in 0..<26 {
            guard let s = findSpot(z: 4.2...18, rock: 0.45...1.01) else { continue }
            let orange = rng.chance(0.35)
            add("sjonellik", orange ? "sjonellik-o" : "sjonellik", spot: s, height: rng.float(0.28, 0.5), mode: 5, amp: 0.05, shadowW: 0.2)
        }
        for _ in 0..<12 {
            guard let s = findSpot(z: 4...16, rock: 0.45...1.01) else { continue }
            add("dodningehand", "dodningehand", spot: s, height: rng.float(0.13, 0.22), mode: 0, amp: 0, shadowW: 0.16)
        }
        for _ in 0..<6 {
            guard let s = findSpot(z: 3.6...14, rock: 0.2...1.01) else { continue }
            add("oskjell", "oskjell", spot: s, height: rng.float(0.09, 0.14), mode: 0, amp: 0, shadowW: 0.22)
        }
        for _ in 0..<9 {
            guard let s = findSpot(z: 3.6...14, rock: 0.25...1.01) else { continue }
            add("drobak", "drobak", spot: s, height: rng.float(0.07, 0.11), mode: 0, amp: 0, shadowW: 0.12, flip: false)
        }
        for _ in 0..<5 {
            guard let s = findSpot(z: 3.6...14, rock: 0.25...1.01) else { continue }
            add("kraakebolle", "kraakebolle", spot: s, height: rng.float(0.11, 0.16), mode: 0, amp: 0, shadowW: 0.15, flip: false)
        }

        // Soft bottom life.
        for _ in 0..<26 {
            guard let s = findSpot(z: 6...24, rock: 0...0.08) else { continue }
            add("sjofjaer", "sjofjaer", spot: s, height: rng.float(0.8, 1.5), mode: 2, amp: 0.05)
        }
        for _ in 0..<5 {
            guard let s = findSpot(z: 3.4...10, rock: 0...0.2) else { continue }
            add("kamskjell", "kamskjell", spot: s, height: rng.float(0.06, 0.09), mode: 0, amp: 0, shadowW: 0.09)
        }
    }

    private func populateSwimmers() {
        let loneSpecs: [SwimmerSpec] = [
            .init(key: "torsk", length: 0.95, speed: 0.42, zr: 4.2...11, alt: 0.45...2.0, amp: 0.34, wave: 6.5, count: 3),
            .init(key: "laks", length: 0.82, speed: 0.85, zr: 6...15, alt: 2.5...6.5, amp: 0.28, wave: 6.5, count: 1),
            .init(key: "uer", length: 0.44, speed: 0.17, zr: 4.5...12, alt: 0.25...1.0, amp: 0.22, wave: 6, count: 4),
            .init(key: "berggylt", length: 0.46, speed: 0.28, zr: 3.9...10, alt: 0.3...1.4, amp: 0.26, wave: 6, count: 2),
            .init(key: "blaastaal", length: 0.32, speed: 0.36, zr: 3.8...9, alt: 0.3...1.5, amp: 0.26, wave: 6, count: 2),
            .init(key: "rognkjeks", length: 0.38, speed: 0.18, zr: 3.8...9, alt: 0.4...1.6, amp: 0.2, wave: 5, count: 1),
            .init(key: "pigghaa", length: 0.95, speed: 0.6, zr: 5...15, alt: 0.9...3.2, amp: 0.45, wave: 7.5, count: 2),
        ]
        for spec in loneSpecs {
            for _ in 0..<spec.count { loners.append(makeFish(spec, onScreen: true)) }
        }

        let schoolSpecs: [SwimmerSpec] = [
            .init(key: "sild", length: 0.30, speed: 0.95, zr: 8...18, alt: 3...7.5, amp: 0.4, wave: 7, count: 80),
            .init(key: "sei", length: 0.68, speed: 0.72, zr: 6...15, alt: 1.2...4.5, amp: 0.36, wave: 7, count: 11),
            .init(key: "makrell", length: 0.38, speed: 1.25, zr: 7...17, alt: 3...7, amp: 0.42, wave: 8, count: 15),
        ]
        for spec in schoolSpecs {
            let school = School(spec: spec)
            let z = rng.float(spec.zr.lowerBound, spec.zr.upperBound)
            school.cx = rng.float(-0.8, 0.8) * viewHalfWidth(z)
            school.cz = z
            school.cy = terrain.height(school.cx, z) + rng.float(spec.alt.lowerBound, spec.alt.upperBound)
            let spread = 0.5 + Float(spec.count).squareRoot() * 0.18
            let facing: Float = rng.chance(0.5) ? 1 : -1
            for _ in 0..<spec.count {
                let f = makeFish(spec, onScreen: true)
                f.x = school.cx + rng.float(-spread, spread) * 1.7
                f.y = school.cy + rng.float(-spread, spread) * 0.6
                f.z = max(3.4, school.cz + rng.float(-spread, spread))
                f.vx = facing * spec.speed
                f.yaw = facing > 0 ? 0 : .pi
                school.members.append(f)
            }
            schools.append(school)
        }

        let moon = atlas.frame("glassmanet"), lion = atlas.frame("brennmanet")
        for i in 0..<7 {
            let z = rng.float(6, 20)
            let x = rng.float(-1.1, 1.1) * viewHalfWidth(z)
            let isLion = i == 0
            jellies.append(Jelly(
                key: isLion ? "brennmanet" : "glassmanet", frame: isLion ? lion : moon,
                width: isLion ? rng.float(0.5, 0.75) : rng.float(0.2, 0.32),
                x: x, y: rng.float(2.5, 7), z: z,
                vx: rng.float(-0.05, 0.05), phase: rng.float(0, 6), rate: isLion ? rng.float(0.8, 1.1) : rng.float(1.3, 1.9)))
        }
    }

    private func makeFish(_ spec: SwimmerSpec, onScreen: Bool) -> Fish {
        let z = rng.float(spec.zr.lowerBound, spec.zr.upperBound)
        let x = rng.float(-1.2, 1.2) * viewHalfWidth(z)
        let y = terrain.height(x, z) + rng.float(spec.alt.lowerBound, spec.alt.upperBound)
        let v = rng.float(0.93, 1.05)
        let f = Fish(spec: spec, frame: atlas.frame(spec.key), x: x, y: y, z: z, phase: rng.float(0, 6.28),
                     facing: rng.chance(0.5) ? 1 : -1, scale: rng.float(0.85, 1.12), tint: C3(repeating: v))
        pickTarget(f)
        return f
    }

    private func populateBottom() {
        func frames(_ k: String) -> [AtlasFrame] { (0..<4).map { atlas.frame("\(k)-\($0)") } }
        func addWalker(_ key: String, gait: Walker.Gait, length: Float, speed: Float, z zr: ClosedRange<Float>, rock: ClosedRange<Float>) {
            guard let s = findSpot(z: zr, rock: rock) else { return }
            walkers.append(Walker(key: key, frames: frames(key), gait: gait, length: length, speed: speed,
                                  x: s.0, z: s.2, facing: rng.chance(0.5) ? 1 : -1, heading: rng.float(0, 6.28)))
        }
        for _ in 0..<2 { addWalker("hummer", gait: .walk, length: 0.46, speed: 0.08, z: 3.8...7.5, rock: 0...0.3) }
        for _ in 0..<3 { addWalker("sjokreps", gait: .walk, length: 0.22, speed: 0.07, z: 3.5...7, rock: 0...0.15) }
        for _ in 0..<3 { addWalker("taskekrabbe", gait: .sideways, length: 0.26, speed: 0.09, z: 3.5...8, rock: 0...0.3) }

        func addRester(_ key: String, length: Float, mode: Float, amp: Float, glide: Float, rest: (Float, Float),
                       z zr: ClosedRange<Float>, rock: ClosedRange<Float>, lift: Float) {
            guard let s = findSpot(z: zr, ndc: -0.95...0.95, rock: rock) else { return }
            resters.append(Rester(key: key, frame: atlas.frame(key), length: length, mode: mode, amp: amp, glideSpeed: glide,
                                  rest: rest, x: s.0, z: s.2, y: s.1, facing: rng.chance(0.5) ? 1 : -1, height: lift,
                                  timer: rng.float(5, rest.1)))
        }
        addRester("breiflabb", length: 0.95, mode: 1, amp: 0.02, glide: 0, rest: (9999, 9999), z: 4.3...7, rock: 0...0.2, lift: 0)
        for _ in 0..<2 {
            addRester("rodspette", length: 0.42, mode: 3, amp: 0.05, glide: 0.45, rest: (12, 45), z: 3.5...7, rock: 0...0.1, lift: 0)
        }
        for _ in 0..<2 {
            addRester("piggskate", length: 0.68, mode: 3, amp: 0.05, glide: 0.5, rest: (18, 70), z: 3.9...9, rock: 0...0.15, lift: 0)
        }
        addRester("steinbit", length: 1.05, mode: 1, amp: 0.10, glide: 0.24, rest: (20, 60), z: 4...8, rock: 0...0.6, lift: 0)

        // Starfish crawl on the same floor, far too slowly to need walk frames.
        for _ in 0..<7 {
            guard let s = findSpot(z: 3.4...10, rock: 0...0.6) else { continue }
            let f = atlas.frame("korstroll")
            fixtures.append(Fixture(key: "korstroll", frame: f, x: s.0, y: s.1 - 0.012, z: s.2,
                                    halfW: rng.float(0.13, 0.19), halfH: 0.08, mode: 0, amp: 0, ripple: 0, phase: 0,
                                    flip: rng.chance(0.5) ? -1 : 1, tint: C3(repeating: rng.float(0.9, 1.08)), shadowW: 0.12, rate: 1))
        }
        for _ in 0..<3 {
            guard let s = findSpot(z: 3.5...10, rock: 0...0.8) else { continue }
            let f = atlas.frame("solstjerne")
            fixtures.append(Fixture(key: "solstjerne", frame: f, x: s.0, y: s.1 - 0.012, z: s.2,
                                    halfW: rng.float(0.15, 0.21), halfH: 0.09, mode: 0, amp: 0, ripple: 0, phase: 0,
                                    flip: 1, tint: C3(repeating: rng.float(0.92, 1.05)), shadowW: 0.14, rate: 1))
        }
    }

    // MARK: simulation

    func forceRareVisitor() { rareTimer = 0 }

    func update(dt: Float) {
        time += dt
        for f in loners { stepLoner(f, dt: dt) }
        for s in schools { stepSchool(s, dt: dt) }
        stepRare(dt)
        for w in walkers { stepWalker(w, dt: dt) }
        for r in resters { stepRester(r, dt: dt) }
        for j in jellies { stepJelly(j, dt: dt) }
        stepCaption(dt)
    }

    private func pickTarget(_ f: Fish) {
        let s = f.spec
        let z = rng.float(s.zr.lowerBound, s.zr.upperBound)
        // Mostly cross the view, often leaving it for a while.
        let reach = viewHalfWidth(z)
        f.tx = rng.float(-1.45, 1.45) * reach
        f.tz = z
        f.ty = terrain.height(f.tx, f.tz) + rng.float(s.alt.lowerBound, s.alt.upperBound)
        f.retarget = rng.float(8, 26)
    }

    private func steer(_ f: Fish, toward d: SIMD3<Float>, agility: Float, dt: Float) {
        let k = min(1, agility * dt)
        f.vx += (d.x - f.vx) * k
        f.vy += (d.y - f.vy) * k
        f.vz += (d.z - f.vz) * k
    }

    private func integrate(_ f: Fish, dt: Float) {
        // Keep clear of rock, looking a little ahead.
        let aheadX = f.x + f.vx * 1.4, aheadZ = f.z + f.vz * 1.4
        let floor = max(terrain.height(f.x, f.z), terrain.height(aheadX, aheadZ))
        let clearance = 0.18 + f.spec.length * 0.25
        if f.y < floor + clearance { f.vy += (floor + clearance - f.y) * 3 * dt + 0.5 * dt }
        f.x += f.vx * dt; f.y += f.vy * dt; f.z = max(3.3, f.z + f.vz * dt)

        let speed = (f.vx * f.vx + f.vy * f.vy + f.vz * f.vz).squareRoot()
        f.phase += dt * (2.2 + 5.5 * speed / max(0.25, f.spec.length))
        if abs(f.vx) > 0.03 {
            let target: Float = f.vx > 0 ? 0 : .pi
            let rate: Float = 2.6
            let d = target - f.yaw
            f.yaw += max(-rate * dt, min(rate * dt, d))
        }
        let targetPitch = max(-0.4, min(0.4, atan2(f.vy, max(0.05, abs(f.vx)))))
        f.pitch += (targetPitch - f.pitch) * min(1, dt * 2.5)
    }

    private func stepLoner(_ f: Fish, dt: Float) {
        f.retarget -= dt
        let dx = f.tx - f.x, dy = f.ty - f.y, dz = f.tz - f.z
        let d = (dx * dx + dy * dy + dz * dz).squareRoot()
        if d < 0.5 || f.retarget <= 0 { pickTarget(f) }
        let cruise = f.spec.speed * (0.8 + 0.35 * sin(time * 0.19 + f.phase * 0.01))
        let k = cruise / max(0.1, d)
        steer(f, toward: SIMD3(dx * k, dy * k, dz * k), agility: 0.65, dt: dt)
        integrate(f, dt: dt)
    }

    private func stepSchool(_ s: School, dt: Float) {
        s.retarget -= dt
        if s.retarget <= 0 {
            let spec = s.spec
            let z = rng.float(spec.zr.lowerBound, spec.zr.upperBound)
            // Sweep past the screen edge, then come back.
            let side: Float = s.cx > 0 ? -1 : 1
            s.cx = side * rng.float(0.4, 1.8) * viewHalfWidth(z)
            s.cz = z
            s.cy = terrain.height(s.cx, z) + rng.float(spec.alt.lowerBound, spec.alt.upperBound)
            s.retarget = rng.float(16, 36)
        }
        let spec = s.spec
        let sep = spec.length * 1.25
        let perception = spec.length * 4.5
        let ms = s.members
        for (i, f) in ms.enumerated() {
            var sepV = SIMD3<Float>(repeating: 0), ali = sepV, coh = sepV
            var n: Float = 0
            for (j, o) in ms.enumerated() where j != i {
                let dx = o.x - f.x, dy = o.y - f.y, dz = (o.z - f.z)
                let d2 = dx * dx + dy * dy + dz * dz
                if d2 > perception * perception { continue }
                let d = max(0.02, d2.squareRoot())
                if d < sep {
                    let w = (sep - d) / d
                    sepV -= SIMD3(dx, dy, dz) * w
                }
                ali += SIMD3(o.vx, o.vy, o.vz)
                coh += SIMD3(o.x, o.y, o.z)
                n += 1
            }
            var want = SIMD3<Float>(f.vx, f.vy, f.vz)
            if n > 0 {
                let a = ali / n, c = coh / n - SIMD3(f.x, f.y, f.z)
                want += (a - want) * 0.5 + c * 0.45 + sepV * 1.6
            }
            let toward = SIMD3(s.cx - f.x, s.cy - f.y, s.cz - f.z)
            let dist = max(0.1, simdLength(toward))
            want += toward / dist * spec.speed * 0.42
            let len = max(0.01, simdLength(want))
            let target = spec.speed * (0.88 + 0.25 * sin(time * 0.31 + Float(i)))
            want *= target / len
            steer(f, toward: want, agility: 1.5, dt: dt)
        }
        for f in ms { integrate(f, dt: dt) }
    }

    private func stepRare(_ dt: Float) {
        if let f = rare {
            f.x += f.vx * dt
            let fl = terrain.height(f.x, f.z) + 1.2
            f.y += (max(fl, f.ty) - f.y) * min(1, dt * 0.3)
            f.phase += dt * 1.1
            if abs(f.x) > viewHalfWidth(f.z) * 1.5 + 2.5 {
                rare = nil
                rareTimer = rng.float(220, 480)
            }
        } else {
            rareTimer -= dt
            if rareTimer <= 0 {
                let spec = SwimmerSpec(key: "haakjerring", length: 3.6, speed: 0.34, zr: 11...16, alt: 1.5...3,
                                       amp: 0.18, wave: 5, count: 1)
                let z = rng.float(11, 16)
                let dir: Float = rng.chance(0.5) ? 1 : -1
                let x = -dir * (viewHalfWidth(z) * 1.45 + 2.2)
                let y = terrain.height(0, z) + rng.float(1.6, 3)
                let f = Fish(spec: spec, frame: atlas.frame("haakjerring"), x: x, y: y, z: z, phase: 0,
                             facing: dir, scale: rng.float(0.9, 1.15), tint: C3(repeating: 1))
                f.vx = dir * 0.34
                f.ty = y
                rare = f
            }
        }
    }

    private func stepWalker(_ w: Walker, dt: Float) {
        if w.pause > 0 {
            w.pause -= dt
            w.moving = false
            if w.pause <= 0 {
                w.heading = rng.float(0, 6.28)
                w.facing = cos(w.heading) >= 0 ? 1 : -1
            }
        } else {
            w.moving = true
            let dx = cos(w.heading), dz = sin(w.heading) * 0.5
            let nx = w.x + dx * w.speed * dt, nz = w.z + dz * w.speed * dt
            let climb = terrain.height(nx, nz) - terrain.height(w.x, w.z)
            let hw = viewHalfWidth(nz)
            if abs(climb) > 0.2 * max(0.01, w.speed * dt) * 8 || terrain.rock(nx, nz) > 0.4 || nz < 3.3 || nz > 10 || abs(nx) > hw * 1.1 {
                w.heading = atan2(-dz, -dx) + rng.float(-0.7, 0.7)
                w.facing = cos(w.heading) >= 0 ? 1 : -1
                w.pause = rng.float(0.5, 2)
            } else {
                w.x = nx; w.z = nz
                w.leg += dt * w.speed * 60 / max(0.2, w.length) * 0.5
            }
            if rng.chance(Double(dt) * 0.05) { w.pause = rng.float(3, 16) }
        }
        let target: Float = w.facing > 0 ? 0 : .pi
        w.yaw += max(-1.6 * dt, min(1.6 * dt, target - w.yaw))
    }

    private func stepRester(_ r: Rester, dt: Float) {
        r.timer -= dt
        if r.gliding {
            r.glideAmount = min(1, r.glideAmount + dt * 0.6)
            let nx = r.x + (r.facing * r.glideSpeed) * dt * r.glideAmount
            let nz = r.z + r.dirZ * dt * r.glideAmount
            let edge = abs(nx) > viewHalfWidth(nz) * 1.05
            if r.timer <= 0 || terrain.rock(nx, nz) > 0.5 || edge || nz < 3.4 || nz > 11 {
                r.gliding = false
                r.timer = rng.float(r.restMin, r.restMax)
                if edge { r.facing = -r.facing }
            } else {
                r.x = nx; r.z = nz
            }
            r.phase += dt * 5.2
        } else {
            r.glideAmount = max(0, r.glideAmount - dt * 0.8)
            r.phase += dt * 0.7
            if r.timer <= 0, r.glideSpeed > 0 {
                r.gliding = true
                r.timer = rng.float(2.5, 7)
                if rng.chance(0.4) { r.facing = -r.facing }
                r.dirZ = rng.float(-0.1, 0.1)
            }
        }
        let target: Float = r.facing > 0 ? 0 : .pi
        r.yaw += max(-2.2 * dt, min(2.2 * dt, target - r.yaw))
        r.y = terrain.height(r.x, r.z) + 0.02 + r.height + r.glideAmount * 0.12
    }

    private func stepJelly(_ j: Jelly, dt: Float) {
        j.phase += dt * j.rate
        // Rise on the power stroke, sink in between.
        let thrust = max(0, sin(j.phase)) * 0.09 - 0.022
        j.y += thrust * dt
        j.x += (j.vx + 0.03 * sin(time * 0.05 + j.z)) * dt
        let floor = terrain.height(j.x, j.z) + 1.0
        if j.y < floor { j.y += (floor - j.y) * dt * 0.5 }
        if j.y > 8.5 { j.y -= dt * 0.1 }
        let reach = viewHalfWidth(j.z) * 1.35
        if j.x > reach { j.x = -reach } else if j.x < -reach { j.x = reach }
    }

    private func stepCaption(_ dt: Float) {
        captionClock += dt
        if captionClock > World.captionShown + World.captionGap || captionKey == nil && captionClock > 0 {
            captionKey = pickCaption()
            captionClock = 0
        }
    }

    private func isVisible(x: Float, y: Float, z: Float, margin: Float = 0.9) -> Bool {
        let nx = x * focal / (z * aspect)
        let ny = horizon + (y - camY) * focal / z
        return abs(nx) < margin && abs(ny) < margin
    }

    private func pickCaption() -> String? {
        // Favor what is visible and close, skipping recent ones.
        var options: [String: Float] = [:]
        func vote(_ key: String, _ z: Float, weight: Float = 1) {
            options[key] = max(options[key] ?? 0, weight * max(0.1, 16 - z))
        }
        for f in loners where isVisible(x: f.x, y: f.y, z: f.z) { vote(f.spec.key, f.z, weight: 2) }
        for s in schools {
            for f in s.members.prefix(5) where isVisible(x: f.x, y: f.y, z: f.z) { vote(f.spec.key, f.z, weight: 2) }
        }
        if let r = rare, isVisible(x: r.x, y: r.y, z: r.z, margin: 1.0) { return "haakjerring" }
        for w in walkers where isVisible(x: w.x, y: terrain.height(w.x, w.z), z: w.z) { vote(w.key, w.z, weight: 1.6) }
        for r in resters where isVisible(x: r.x, y: r.y, z: r.z) { vote(r.key, r.z, weight: 1.6) }
        for j in jellies where isVisible(x: j.x, y: j.y, z: j.z) { vote(j.key, j.z, weight: 1.6) }
        for f in fixtures where isVisible(x: f.x, y: f.y, z: f.z) { vote(f.key, f.z) }
        for key in captionHistory { options[key] = nil }
        guard !options.isEmpty else {
            captionHistory.removeAll()
            return nil
        }
        let total = options.values.reduce(0, +)
        var roll = Float(rng.unit()) * total
        var pick: String?
        for (k, w) in options.sorted(by: { $0.key < $1.key }) {
            roll -= w
            pick = k
            if roll <= 0 { break }
        }
        if let p = pick {
            captionHistory.append(p)
            if captionHistory.count > 18 { captionHistory.removeFirst() }
        }
        return pick
    }

    // MARK: drawing

    private func dof(_ z: Float) -> Float {
        if z < 4.2 { return min(3.6, (4.2 - z) * 3.4) }
        return min(2.4, max(0, abs(z - 6.2) * 0.085 - 0.3))
    }

    private func yawScale(_ yaw: Float) -> Float {
        let c = cos(yaw)
        return abs(c) < 0.10 ? (c < 0 ? -0.10 : 0.10) : c
    }

    private func put(_ s: Sprite) { drawList.append((s.pos.z, s)) }

    private func putShadow(x: Float, y: Float, z: Float, halfW: Float, alpha: Float) {
        guard alpha > 0.01 else { return }
        let squash = max(0.05, 1.3 / z * 0.55)
        put(Sprite(pos: SIMD4(x, y + halfW * squash * 0.1, z + 0.02, 0),
                   size: SIMD4(halfW, halfW * squash, 1, 0),
                   uv: shadow.uv,
                   anim: SIMD4(0, 0, 0, 1.5 + dof(z)),
                   look: SIMD4(alpha, 0, 1, 0),
                   tint: SIMD4(1, 1, 1, 0)))
    }

    private func fishSprite(_ f: Fish) {
        let len = f.spec.length * f.scale * World.creatureScale
        let hw = len / 2, hh = hw / f.frame.aspect
        let height = terrain.height(f.x, f.z)
        let alt = f.y - height
        if alt < 2.5 { putShadow(x: f.x, y: height, z: f.z, halfW: hw * 0.8, alpha: (1 - alt / 2.5) * 0.48) }
        put(Sprite(pos: SIMD4(f.x, f.y, f.z, f.pitch),
                   size: SIMD4(hw, hh, yawScale(f.yaw), 0),
                   uv: f.frame.uv,
                   anim: SIMD4(1, f.phase, f.spec.amp, dof(f.z)),
                   look: SIMD4(1, 0.3, 1, f.spec.wave),
                   tint: SIMD4(f.tint.x, f.tint.y, f.tint.z, 1)))
    }

    func fillSprites(into ptr: UnsafeMutablePointer<Sprite>, capacity: Int, showNames: Bool) -> Int {
        drawList.removeAll(keepingCapacity: true)
        let t = time

        for f in fixtures {
            if f.shadowW > 0 { putShadow(x: f.x, y: f.y + 0.02, z: f.z, halfW: f.shadowW, alpha: 0.6) }
            let phase = t * 0.55 * f.rate + f.phase + f.x * 0.22 + f.z * 0.13
            put(Sprite(pos: SIMD4(f.x, f.y, f.z, 0),
                       size: SIMD4(f.halfW, f.halfH, f.flip, 1),
                       uv: f.frame.uv,
                       anim: SIMD4(f.mode, phase, f.amp, dof(f.z)),
                       look: SIMD4(1, 0.7, 1, f.ripple),
                       tint: SIMD4(f.tint.x, f.tint.y, f.tint.z, 1)))
        }
        for f in loners { fishSprite(f) }
        for s in schools { for f in s.members { fishSprite(f) } }
        if let f = rare { fishSprite(f) }

        for w in walkers {
            let frame = w.frames[Int(w.leg) & 3]
            let hw = w.length * 0.75 * World.creatureScale, hh = hw / frame.aspect
            let y = terrain.height(w.x, w.z) - 0.015
            let slope = max(-0.3, min(0.3, terrain.slope(w.x, w.z)))
            putShadow(x: w.x, y: y + 0.01, z: w.z, halfW: hw * 0.9, alpha: 0.62)
            put(Sprite(pos: SIMD4(w.x, y, w.z, atan(slope) * yawScale(w.yaw)),
                       size: SIMD4(hw, hh, w.gait == .walk ? yawScale(w.yaw) : 1, 1),
                       uv: frame.uv,
                       anim: SIMD4(0, 0, 0, dof(w.z)),
                       look: SIMD4(1, 0.7, 1, 0),
                       tint: SIMD4(1, 1, 1, 0)))
        }

        for r in resters {
            let hw = r.length / 2 * World.creatureScale, hh = hw / r.frame.aspect
            let flat = r.mode == 3 ? max(0.58, min(0.82, 2.8 / r.z)) : 1.0
            let amp = r.mode == 3 ? 0.05 + r.glideAmount * 0.6 : r.amp + r.glideAmount * 0.42
            let floorY = terrain.height(r.x, r.z)
            putShadow(x: r.x, y: floorY + 0.01, z: r.z, halfW: hw * 0.95, alpha: 0.6)
            put(Sprite(pos: SIMD4(r.x, r.y - 0.02, r.z, 0),
                       size: SIMD4(hw, hh * flat, yawScale(r.yaw), 1),
                       uv: r.frame.uv,
                       anim: SIMD4(r.mode, r.phase, amp, dof(r.z)),
                       look: SIMD4(1, 0.65, 1, r.mode == 1 ? 9 : 0),
                       tint: SIMD4(1, 1, 1, 1)))
        }

        for j in jellies {
            let hw = j.width / 2 * 1.35
            let hh = hw / j.frame.aspect
            put(Sprite(pos: SIMD4(j.x, j.y, j.z, sin(t * 0.07 + j.z) * 0.14),
                       size: SIMD4(hw, hh, 1, 0),
                       uv: j.frame.uv,
                       anim: SIMD4(4, j.phase, 0.7, dof(j.z)),
                       look: SIMD4(0.92, 0.3, 1, 0),
                       tint: SIMD4(1, 1, 1, 0)))
        }

        drawList.sort { $0.0 > $1.0 }
        var count = 0
        for (_, s) in drawList where count < capacity - 1 {
            ptr[count] = s
            count += 1
        }

        if showNames, let key = captionKey, captionClock < World.captionShown {
            let frame = atlas.frame("cap-\(key)")
            let c = captionClock, fadeIn = smooth(0, 1.2, c), fadeOut = 1 - smooth(World.captionShown - 1.5, World.captionShown, c)
            let hh: Float = 0.040
            let hw = hh * frame.aspect
            // Anchor to the lower left, scaled by screen height.
            ptr[count] = Sprite(
                pos: SIMD4(-1 + (0.07 + hw) / aspect, -0.89, 1, 0),
                size: SIMD4(hw, hh, 1, 0),
                uv: frame.uv,
                anim: SIMD4(9, 0, 0, 0),
                look: SIMD4(fadeIn * fadeOut, 0, 0, 0),
                tint: SIMD4(1, 1, 1, 0))
            count += 1
        }
        return count
    }
}

private func simdLength(_ v: SIMD3<Float>) -> Float {
    (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
}
