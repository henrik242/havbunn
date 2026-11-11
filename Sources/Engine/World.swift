import Foundation

/// A free-swimming fish: a loner, a school member or a rare visitor. Lengths are in metres,
/// speeds in m/s, `z` is distance from the camera and `alt` height above the bottom.
struct SwimmerSpec {
    let length: Float
    let speed: Float
    let z: ClosedRange<Float>
    let alt: ClosedRange<Float>
    /// Body wave amplitude and wavelength in the shader.
    let amp: Float
    let wave: Float
    /// Loners and schools only.
    var count = 1
    /// Loners only: share of arrivals followed by holding station near a home patch.
    var hover: Float = 0
    /// Loners only: rock-mask range for the home patch.
    var homeRock: ClosedRange<Float> = 0.35...1.01
    /// Rare visitors only: tail-beat rate while passing through.
    var beat: Float = 1.1
}

enum Gait { case walk, sideways }

/// A crustacean on four-frame walk cycles, keeping near a home spot.
struct WalkerSpec {
    let gait: Gait
    let length, speed: Float
    let z: ClosedRange<Float>
    let rock: ClosedRange<Float>
    let range, maxRock: Float
    let rest: (Float, Float)
    var count = 1
}

/// A bottom animal that lies still and now and then glides or crawls a little way.
struct ResterSpec {
    let length, mode, amp: Float
    let glide: Float
    let rest: (Float, Float)
    let z: ClosedRange<Float>
    let rock: ClosedRange<Float>
    let lift: Float
    /// Rock-mask value that ends a glide.
    var glideRock: Float = 0.5
    /// Walks or creeps along the bottom: no lift off and no silt puffs.
    var crawls = false
}

/// A drifting jelly that pulses up and sinks back.
struct JellySpec {
    let count: Int
    let z, y, width: ClosedRange<Float>
    let drift: Float
    let rate: ClosedRange<Float>
    /// Bell pulse strength in the shader.
    var pulse: Float = 0.7
    var opacity: Float = 0.6
}

/// What a species sees while placing itself in a new scene. Everything it adds is filed under
/// its key, which also names its main sprite.
struct Placement {
    fileprivate let world: World
    let key: String

    /// The scene's one random sequence, so the whole scene follows from the seed.
    var rng: RNG {
        get { world.rng }
        nonmutating set { world.rng = newValue }
    }

    /// A seabed spot in view whose rock mask is in `rock`: x, floor height, z.
    func findSpot(z: ClosedRange<Float>, ndc: ClosedRange<Float> = -1.1...1.1, rock: ClosedRange<Float>) -> (Float, Float, Float)? {
        world.findSpot(z: z, ndc: ndc, rock: rock)
    }

    /// The seabed spot at x, z, or nil unless the rock mask there is above `rockAbove`.
    func ground(_ x: Float, _ z: Float, rockAbove: Float) -> (Float, Float, Float)? {
        world.ground(x, z, rockAbove: rockAbove)
    }

    /// Something rooted or lying still, sized by height from its sprite, which defaults to the key.
    /// Random phase, and random mirror and shade unless given.
    func addFixture(_ sprite: String? = nil, spot: (Float, Float, Float), height: Float, mode: Float, amp: Float,
                    ripple: Float = 0, shadowW: Float = 0, tint: C3? = nil, flip: Bool = true, rate: Float = 1) {
        world.addFixture(key: key, sprite: sprite ?? key, spot: spot, height: height, mode: mode, amp: amp, ripple: ripple,
                         shadowW: shadowW, tint: tint, flip: flip, rate: rate)
    }

    /// Something lying flat on the floor, like a starfish, sized by its half extents.
    func addFlat(spot: (Float, Float, Float), halfW: Float, halfH: Float, flip: Bool, tint: ClosedRange<Float>, shadowW: Float) {
        world.addFlat(key: key, spot: spot, halfW: halfW, halfH: halfH, flip: flip, tint: tint, shadowW: shadowW)
    }

    func addLoners(_ spec: SwimmerSpec) { world.addLoners(key: key, spec) }
    func addSchool(_ spec: SwimmerSpec) { world.addSchool(key: key, spec) }
    /// A fish that now and then passes through, picked among the rare visitors by weight.
    func addRareVisitor(_ spec: SwimmerSpec, weight: Double) { world.addRareVisitor(key: key, spec, weight: weight) }
    func addJellies(_ spec: JellySpec) { world.addJellies(key: key, spec) }
    /// Needs sprites `<key>-0` to `<key>-3`, the walk cycle.
    func addWalkers(_ spec: WalkerSpec) { world.addWalkers(key: key, spec) }
    /// Places one.
    func addRester(_ spec: ResterSpec) { world.addRester(key: key, spec) }
}

private final class Fish {
    let key: String
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
    var homeX: Float = 0, homeY: Float = 0, homeZ: Float = 0
    var holdTimer: Float = 0
    init(key: String, spec: SwimmerSpec, frame: AtlasFrame, x: Float, y: Float, z: Float, phase: Float, facing: Float, scale: Float, tint: C3) {
        self.key = key; self.spec = spec; self.frame = frame
        self.x = x; self.y = y; self.z = z
        self.phase = phase
        self.yaw = facing > 0 ? 0 : .pi
        self.scale = scale
        self.tint = tint
    }
}

private final class School {
    let key: String
    let spec: SwimmerSpec
    var members: [Fish] = []
    var cx: Float = 0, cy: Float = 0, cz: Float = 0
    var retarget: Float = 0
    init(key: String, spec: SwimmerSpec) { self.key = key; self.spec = spec }
}

private final class Walker {
    let key: String, frames: [AtlasFrame], gait: Gait
    let length, speed: Float
    var x, z: Float
    var facing: Float
    var yaw: Float
    var pause: Float
    var leg: Float = 0
    var heading: Float
    var moving = false
    let homeX, homeZ, range, maxRock: Float
    let restMin, restMax: Float
    init(key: String, spec: WalkerSpec, frames: [AtlasFrame], x: Float, z: Float, facing: Float, heading: Float, pause: Float) {
        self.key = key; self.frames = frames; gait = spec.gait
        length = spec.length; speed = spec.speed
        self.x = x; self.z = z
        homeX = x; homeZ = z; range = spec.range; maxRock = spec.maxRock
        restMin = spec.rest.0; restMax = spec.rest.1
        self.facing = facing
        yaw = facing > 0 ? 0 : .pi
        self.pause = pause
        self.heading = heading
    }
}

/// Bottom-dwelling fish that rest and sometimes glide.
private final class Rester {
    let key: String, frame: AtlasFrame, length: Float
    let mode: Float, amp: Float
    let glideSpeed: Float
    let restMin, restMax: Float
    let glideRock: Float, crawls: Bool
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
    init(key: String, spec: ResterSpec, frame: AtlasFrame, x: Float, z: Float, y: Float, facing: Float, timer: Float) {
        self.key = key; self.frame = frame; length = spec.length
        mode = spec.mode; amp = spec.amp; glideSpeed = spec.glide
        restMin = spec.rest.0; restMax = spec.rest.1
        glideRock = spec.glideRock; crawls = spec.crawls
        self.x = x; self.z = z; self.y = y
        self.facing = facing
        yaw = facing > 0 ? 0 : .pi
        height = spec.lift
        self.timer = timer
    }
}

private final class Jelly {
    let key: String, frame: AtlasFrame, width: Float
    let pulse, opacity: Float
    var x, y, z: Float
    var vx: Float
    var phase: Float
    let rate: Float
    init(key: String, spec: JellySpec, frame: AtlasFrame, width: Float, x: Float, y: Float, z: Float, vx: Float, phase: Float, rate: Float) {
        self.key = key; self.frame = frame; self.width = width
        pulse = spec.pulse; opacity = spec.opacity
        self.x = x; self.y = y; self.z = z; self.vx = vx; self.phase = phase; self.rate = rate
    }
}

/// Something rooted or lying still on the bottom, animated in place by the shader.
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
    /// Shared with species placement, so the whole scene follows from one seed.
    fileprivate var rng: RNG
    private let aspect, focal, camY, horizon: Float
    private var time: Float = 0

    private var schools: [School] = []
    private var loners: [Fish] = []
    private var rare: Fish?
    private var rareTimer: Float
    private var rareVisitors: [(key: String, spec: SwimmerSpec, weight: Double)] = []
    private var walkers: [Walker] = []
    private var resters: [Rester] = []
    private var jellies: [Jelly] = []
    private var fixtures: [Fixture] = []

    private var drawList: [(Float, Sprite)] = []

    private var captionKey: String?
    /// Where the captioned animal is now, or nil once it is gone.
    private var captionSubject: (() -> SIMD3<Float>?)?
    private var captionNdc = SIMD2<Float>(-0.6, -0.8)
    private var captionPlaced = false
    private var captionSize: Float = 0.3
    /// Sprites at the end of the list that are drawn after the overlay: caption and pointer.
    private(set) var overlaySprites = 0

    /// Tidal current along the view, reversing over minutes. Plants, drift and fish follow it.
    private(set) var flow: Float = 0
    /// Slow camera pan, as the tangent of the yaw angle. Starts centred.
    private(set) var pan: Float = 0
    private let overscan: Float
    private static let panPeriod: Float = 300
    private(set) var flowIntegral: Float = 0
    private let flowPhase: Float
    /// Rock tops where mysids hang in clouds: x, y, z, radius.
    private(set) var mysidAnchors: [SIMD4<Float>] = []
    private struct Puff { var x, y, z, age, size: Float }
    private var puffs: [Puff] = []
    private let puffFrame: AtlasFrame
    private let pointerLine: AtlasFrame
    private let pointerHead: AtlasFrame
    private var captionClock: Float = -8
    private var captionGap: Float = 3
    private var captionHistory: [String] = []
    /// Slightly larger than life so animals hold their own on screen.
    private static let creatureScale: Float = 1.15
    private static let captionShown: Float = 9

    private let shadow: AtlasFrame

    init(seed: UInt64, terrain: Terrain, atlas: Atlas, aspect: Float, overscan: Float, focal: Float, camY: Float, horizon: Float) {
        self.overscan = overscan
        self.terrain = terrain
        self.atlas = atlas
        self.aspect = aspect; self.focal = focal; self.camY = camY; self.horizon = horizon
        rng = RNG(seed ^ 0xF15B)
        shadow = atlas.frame("shadow")
        pointerLine = atlas.frame("pointer-line")
        pointerHead = atlas.frame("pointer-head")
        puffFrame = atlas.frame("puff")
        flowPhase = Float(seed % 360)
        rareTimer = rng.float(120, 300)
        // Each species places itself, in list order.
        for s in Species.all { s.place(Placement(world: self, key: s.key)) }
        placeLensKelp()
        for _ in 0..<5 {
            guard let s = findSpot(z: 5...12, rock: 0.55...1.01) else { continue }
            mysidAnchors.append(SIMD4(s.0, s.1 + rng.float(0.25, 0.6), s.2, rng.float(0.25, 0.45)))
        }
    }

    // MARK: setup

    /// Half width of the whole field the pan can show, for placing and roaming.
    private func viewHalfWidth(_ z: Float) -> Float { z * aspect / focal * overscan }

    private func screenX(_ x: Float, _ z: Float) -> Float { (x / z - pan) * focal / aspect }

    /// Looks for a seabed spot in view that satisfies the rock-mask test.
    fileprivate func findSpot(z zr: ClosedRange<Float>, ndc: ClosedRange<Float> = -1.1...1.1,
                              rock: ClosedRange<Float>, tries: Int = 80) -> (Float, Float, Float)? {
        for _ in 0..<tries {
            let z = rng.float(zr.lowerBound, zr.upperBound)
            let x = rng.float(ndc.lowerBound, ndc.upperBound) * viewHalfWidth(z)
            if rock.contains(terrain.rock(x, z)) { return floorSpot(x, z) }
        }
        return nil
    }

    /// Slightly sunk, so nothing seems to hover over the floor.
    private func floorSpot(_ x: Float, _ z: Float) -> (Float, Float, Float) { (x, terrain.height(x, z) - 0.03, z) }

    fileprivate func ground(_ x: Float, _ z: Float, rockAbove: Float) -> (Float, Float, Float)? {
        terrain.rock(x, z) > rockAbove ? floorSpot(x, z) : nil
    }

    /// Out-of-focus kelp close to the lens frames the shot. Here rather than in the kelp files
    /// because it is placed after every species.
    private func placeLensKelp() {
        let lensSide: Float = rng.chance(0.5) ? -1 : 1
        for side: Float in [-1, 1] {
            for _ in 0..<(side == lensSide ? rng.int(1, 2) : 0) {
                let z = rng.float(3.0, 3.9)
                let x = side * rng.float(0.82, 1.04) * viewHalfWidth(z)
                let key = rng.chance(0.5) ? "sukkertare" : "stortare"
                let name = key == "sukkertare" ? "sukkertare-\(rng.int(1, 2))" : "stortare-\(rng.int(1, 3))"
                addFixture(key: key, sprite: name, spot: floorSpot(x, z), height: rng.float(2.0, 2.6), mode: 2, amp: 0.08, ripple: 0.03,
                           shadowW: 0, tint: C3(0.36, 0.40, 0.34), flip: true, rate: 1)
            }
        }
    }

    private func makeFish(key: String, _ spec: SwimmerSpec) -> Fish {
        let z = rng.float(spec.z.lowerBound, spec.z.upperBound)
        let x = rng.float(-1.2, 1.2) * viewHalfWidth(z)
        let y = terrain.height(x, z) + rng.float(spec.alt.lowerBound, spec.alt.upperBound)
        let v = rng.float(0.93, 1.05)
        let f = Fish(key: key, spec: spec, frame: atlas.frame(key), x: x, y: y, z: z, phase: rng.float(0, 6.28),
                     facing: rng.chance(0.5) ? 1 : -1, scale: rng.float(0.85, 1.12), tint: C3(repeating: v))
        pickTarget(f)
        return f
    }

    // MARK: placement, through Placement

    fileprivate func addFixture(key: String, sprite: String, spot: (Float, Float, Float), height: Float, mode: Float, amp: Float,
                                ripple: Float, shadowW: Float, tint: C3?, flip: Bool, rate: Float) {
        let f = atlas.frame(sprite)
        fixtures.append(Fixture(
            key: key, frame: f, x: spot.0, y: spot.1, z: spot.2, halfW: height * f.aspect / 2, halfH: height / 2,
            mode: mode, amp: amp, ripple: ripple, phase: rng.float(0, 6.28),
            flip: flip && rng.chance(0.5) ? -1 : 1, tint: tint ?? C3(repeating: rng.float(0.9, 1.06)), shadowW: shadowW, rate: rate))
    }

    fileprivate func addFlat(key: String, spot: (Float, Float, Float), halfW: Float, halfH: Float, flip: Bool,
                             tint: ClosedRange<Float>, shadowW: Float) {
        fixtures.append(Fixture(
            key: key, frame: atlas.frame(key), x: spot.0, y: spot.1 - 0.012, z: spot.2, halfW: halfW, halfH: halfH,
            mode: 0, amp: 0, ripple: 0, phase: 0, flip: flip && rng.chance(0.5) ? -1 : 1,
            tint: C3(repeating: rng.float(tint.lowerBound, tint.upperBound)), shadowW: shadowW, rate: 1))
    }

    fileprivate func addLoners(key: String, _ spec: SwimmerSpec) {
        for _ in 0..<spec.count {
            let f = makeFish(key: key, spec)
            // Station keepers get a home patch over rock.
            if spec.hover > 0, let home = findSpot(z: spec.z, ndc: -1.0...1.0, rock: spec.homeRock) {
                f.homeX = home.0; f.homeZ = home.2
                f.homeY = home.1 + rng.float(spec.alt.lowerBound, spec.alt.upperBound)
                f.x = f.homeX + rng.float(-1, 1); f.z = f.homeZ; f.y = f.homeY
                pickTarget(f)
            }
            loners.append(f)
        }
    }

    fileprivate func addSchool(key: String, _ spec: SwimmerSpec) {
        let school = School(key: key, spec: spec)
        let z = rng.float(spec.z.lowerBound, spec.z.upperBound)
        school.cx = rng.float(-0.8, 0.8) * viewHalfWidth(z)
        school.cz = z
        school.cy = terrain.height(school.cx, z) + rng.float(spec.alt.lowerBound, spec.alt.upperBound)
        let spread = 0.5 + Float(spec.count).squareRoot() * 0.18
        let facing: Float = rng.chance(0.5) ? 1 : -1
        for _ in 0..<spec.count {
            let f = makeFish(key: key, spec)
            f.x = school.cx + rng.float(-spread, spread) * 1.7
            f.y = school.cy + rng.float(-spread, spread) * 0.6
            f.z = max(3.4, school.cz + rng.float(-spread, spread))
            f.vx = facing * spec.speed
            f.yaw = facing > 0 ? 0 : .pi
            school.members.append(f)
        }
        schools.append(school)
    }

    fileprivate func addRareVisitor(key: String, _ spec: SwimmerSpec, weight: Double) {
        rareVisitors.append((key, spec, weight))
    }

    fileprivate func addJellies(key: String, _ spec: JellySpec) {
        let frame = atlas.frame(key)
        for _ in 0..<spec.count {
            let z = rng.float(spec.z.lowerBound, spec.z.upperBound)
            let x = rng.float(-1.1, 1.1) * viewHalfWidth(z)
            jellies.append(Jelly(
                key: key, spec: spec, frame: frame, width: rng.float(spec.width.lowerBound, spec.width.upperBound),
                x: x, y: rng.float(spec.y.lowerBound, spec.y.upperBound), z: z,
                vx: rng.float(-spec.drift, spec.drift), phase: rng.float(0, 6),
                rate: rng.float(spec.rate.lowerBound, spec.rate.upperBound)))
        }
    }

    fileprivate func addWalkers(key: String, _ spec: WalkerSpec) {
        let frames = (0..<4).map { atlas.frame("\(key)-\($0)") }
        for _ in 0..<spec.count {
            guard let s = findSpot(z: spec.z, rock: spec.rock) else { continue }
            walkers.append(Walker(key: key, spec: spec, frames: frames, x: s.0, z: s.2, facing: rng.chance(0.5) ? 1 : -1,
                                  heading: rng.float(0, 6.28), pause: rng.float(0, spec.rest.1)))
        }
    }

    fileprivate func addRester(key: String, _ spec: ResterSpec) {
        guard let s = findSpot(z: spec.z, ndc: -0.95...0.95, rock: spec.rock) else { return }
        resters.append(Rester(key: key, spec: spec, frame: atlas.frame(key), x: s.0, z: s.2, y: s.1,
                              facing: rng.chance(0.5) ? 1 : -1, timer: rng.float(5, spec.rest.1)))
    }

    // MARK: simulation

    func forceRareVisitor() { rareTimer = 0 }

    func update(dt: Float) {
        time += dt
        let tide = sin((time + flowPhase * 10) * 2 * .pi / 600)
        flow = 0.7 * tide + 0.25 * sin(time * 2 * .pi / 143 + flowPhase)
        flowIntegral += flow * dt
        // Swing through most of the overscan and back, keeping inside the baked field.
        pan = (overscan - 1) * aspect / focal * 0.85 * sin(time * 2 * .pi / World.panPeriod)
        stepPuffs(dt)
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
        if s.hover > 0, f.homeZ > 0, !rng.chance(0.12) {
            // Short repositioning around the home patch.
            f.tx = f.homeX + rng.float(-1.6, 1.6)
            f.tz = max(3.6, f.homeZ + rng.float(-0.8, 0.8))
            f.ty = max(f.homeY + rng.float(-0.4, 0.4), terrain.height(f.tx, f.tz) + s.alt.lowerBound)
            f.retarget = rng.float(20, 50)
            return
        }
        let z = rng.float(s.z.lowerBound, s.z.upperBound)
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
        f.phase += dt * (1.6 + 5.5 * speed / max(0.25, f.spec.length))
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
        if f.holdTimer > 0 {
            // Holding station: barely moving, small corrections.
            f.holdTimer -= dt
            let k = min(1, dt * 0.8)
            // Hold station facing into the current.
            f.vx += (-flow * 0.03 + 0.01 * sin(time * 0.3 + f.phase) - f.vx) * k
            f.vy += (0.01 * sin(time * 0.23 + f.phase) - f.vy) * k
            f.vz += (0 - f.vz) * k
            integrate(f, dt: dt)
            if f.holdTimer <= 0 { pickTarget(f) }
            return
        }
        f.retarget -= dt
        let dx = f.tx - f.x, dy = f.ty - f.y, dz = f.tz - f.z
        let d = (dx * dx + dy * dy + dz * dz).squareRoot()
        if d < 0.35 || f.retarget <= 0 {
            if f.spec.hover > 0, rng.chance(Double(f.spec.hover)) {
                f.holdTimer = rng.float(8, 30)
            } else {
                pickTarget(f)
            }
        }
        // Ease in near the target instead of overshooting.
        let cruise = f.spec.speed * (0.8 + 0.35 * sin(time * 0.19 + f.phase * 0.01)) * min(1, d / 0.8 + 0.25)
        let k = cruise / max(0.1, d)
        steer(f, toward: SIMD3(dx * k, dy * k, dz * k), agility: 0.65, dt: dt)
        integrate(f, dt: dt)
    }

    private func stepSchool(_ s: School, dt: Float) {
        s.retarget -= dt
        if s.retarget <= 0 {
            let spec = s.spec
            let z = rng.float(spec.z.lowerBound, spec.z.upperBound)
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
            f.phase += dt * f.spec.beat
            if abs(f.x) > viewHalfWidth(f.z) * 1.5 + f.spec.length * 0.7 + 1 {
                rare = nil
                rareTimer = rng.float(240, 480)
            }
        } else {
            rareTimer -= dt
            if rareTimer <= 0, let last = rareVisitors.last {
                let total = rareVisitors.reduce(0) { $0 + $1.weight }
                var roll = rng.unit() * total
                var pick = last
                for v in rareVisitors {
                    if roll < v.weight { pick = v; break }
                    roll -= v.weight
                }
                let spec = pick.spec
                let z = rng.float(spec.z.lowerBound, spec.z.upperBound)
                let dir: Float = rng.chance(0.5) ? 1 : -1
                let x = -dir * (viewHalfWidth(z) * 1.45 + spec.length)
                let y = terrain.height(0, z) + rng.float(spec.alt.lowerBound, spec.alt.upperBound)
                let f = Fish(key: pick.key, spec: spec, frame: atlas.frame(pick.key), x: x, y: y, z: z, phase: 0,
                             facing: dir, scale: rng.float(0.9, 1.1), tint: C3(repeating: 1))
                f.vx = dir * spec.speed
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
                // Head back toward home when straying.
                let hx = w.homeX - w.x, hz = w.homeZ - w.z
                w.heading = (hx * hx + hz * hz).squareRoot() > w.range * 0.6 ? atan2(hz * 2, hx) + rng.float(-0.5, 0.5) : rng.float(0, 6.28)
                w.facing = cos(w.heading) >= 0 ? 1 : -1
            }
        } else {
            w.moving = true
            let dx = cos(w.heading), dz = sin(w.heading) * 0.5
            let nx = w.x + dx * w.speed * dt, nz = w.z + dz * w.speed * dt
            let climb = terrain.height(nx, nz) - terrain.height(w.x, w.z)
            let hw = viewHalfWidth(nz)
            let hx = nx - w.homeX, hz = nz - w.homeZ
            let away = (hx * hx + hz * hz).squareRoot() > w.range
            if abs(climb) > 0.2 * max(0.01, w.speed * dt) * 8 || terrain.rock(nx, nz) > w.maxRock || away
                || nz < 3.3 || nz > 11 || abs(nx) > hw * 1.1 {
                w.pause = rng.float(1, w.restMin)
            } else {
                w.x = nx; w.z = nz
                w.leg += dt * w.speed * 60 / max(0.2, w.length) * 0.5
            }
            if rng.chance(Double(dt) * 0.08) { w.pause = rng.float(w.restMin, w.restMax) }
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
            if r.timer <= 0 || terrain.rock(nx, nz) > r.glideRock || edge || nz < 3.4 || nz > 11 {
                r.gliding = false
                r.timer = rng.float(r.restMin, r.restMax)
                addPuff(r)
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
                addPuff(r)
                if rng.chance(0.4) { r.facing = -r.facing }
                r.dirZ = rng.float(-0.1, 0.1)
            }
        }
        let target: Float = r.facing > 0 ? 0 : .pi
        r.yaw += max(-2.2 * dt, min(2.2 * dt, target - r.yaw))
        let lifts: Float = r.crawls ? 0 : 1
        r.y = terrain.height(r.x, r.z) + 0.02 + r.height + r.glideAmount * 0.12 * lifts
    }

    /// Silt kicked up when a ray or flatfish lifts off or settles.
    private func addPuff(_ r: Rester) {
        // Walkers and crawlers do not stir up the bottom like a ray lifting off.
        guard puffs.count < 12, !r.crawls else { return }
        puffs.append(Puff(x: r.x, y: terrain.height(r.x, r.z), z: r.z, age: 0, size: r.length * 0.5))
    }

    private func stepPuffs(_ dt: Float) {
        for i in puffs.indices {
            puffs[i].age += dt
            puffs[i].x += flow * 0.08 * dt
        }
        puffs.removeAll { $0.age > 9 }
    }

    private func stepJelly(_ j: Jelly, dt: Float) {
        j.phase += dt * j.rate
        // Rise on the power stroke, sink in between.
        let thrust = max(0, sin(j.phase)) * 0.09 - 0.022
        j.y += thrust * dt
        j.x += (j.vx + 0.03 * sin(time * 0.05 + j.z) + flow * 0.06) * dt
        let floor = terrain.height(j.x, j.z) + 1.0
        if j.y < floor { j.y += (floor - j.y) * dt * 0.5 }
        if j.y > 8.5 { j.y -= dt * 0.1 }
        let reach = viewHalfWidth(j.z) * 1.35
        if j.x > reach { j.x = -reach } else if j.x < -reach { j.x = reach }
    }

    private func stepCaption(_ dt: Float) {
        captionClock += dt
        if captionClock > World.captionShown + captionGap || captionKey == nil && captionClock > 0 {
            if let pick = pickCaption() {
                captionKey = pick.0
                captionSize = pick.1
                captionSubject = pick.2
            } else {
                captionKey = nil
                captionSubject = nil
            }
            captionClock = 0
            captionPlaced = false
            captionGap = rng.float(2.5, 4.5)
        }
        // Follow the animal; leave early if it swims out of view.
        guard captionKey != nil, captionClock < World.captionShown, let p = captionSubject?() else { return }
        let nx = screenX(p.x, p.z), ny = horizon + (p.y - camY) * focal / p.z
        if abs(nx) > 1.0 || abs(ny) > 1.0 {
            captionClock = max(captionClock, World.captionShown - 1.2)
            return
        }
        let target = SIMD2<Float>(nx, ny + (ny > -0.45 ? -0.13 : 0.13))
        if !captionPlaced {
            captionNdc = target
            captionPlaced = true
        } else {
            captionNdc += (target - captionNdc) * min(1, dt / 0.9)
        }
    }

    private func isVisible(x: Float, y: Float, z: Float, margin: Float = 0.9) -> Bool {
        let nx = screenX(x, z)
        let ny = horizon + (y - camY) * focal / z
        return abs(nx) < margin && abs(ny) < margin
    }

    /// True when rock lies on the line of sight from the camera to this point.
    private func hiddenByTerrain(x: Float, y: Float, z: Float) -> Bool {
        for i in 1...10 {
            let t = Float(i) / 11
            let px = x * t, pz = z * t, py = camY + (y - camY) * t
            if pz > 0.5, terrain.height(px, pz) > py + 0.05 { return true }
        }
        return false
    }

    private func pickCaption() -> (String, Float, () -> SIMD3<Float>?)? {
        // Favor animals that are visible and close, skipping recent ones. Plants count less.
        var options: [(String, Float, Float, () -> SIMD3<Float>?)] = []
        func vote(_ key: String, _ x: Float, _ y: Float, _ z: Float, _ weight: Float, size: Float, _ pos: @escaping () -> SIMD3<Float>?) {
            // Only name what is big enough to see: about 3% of the screen height or more.
            guard size * focal / z > 0.06, isVisible(x: x, y: y, z: z, margin: 0.75), !captionHistory.contains(key),
                  !hiddenByTerrain(x: x, y: y + size * 0.3, z: z) else { return }
            options.append((key, weight * max(0.1, 14 - z), size, pos))
        }
        if let r = rare, isVisible(x: r.x, y: r.y, z: r.z, margin: 0.9), !captionHistory.contains(r.key) {
            captionHistory.append(r.key)
            return (r.key, r.spec.length * World.creatureScale, { [weak self, weak r] in self?.rare === r ? r.map { SIMD3($0.x, $0.y, $0.z) } : nil })
        }
        for f in loners { vote(f.key, f.x, f.y, f.z, 2, size: f.spec.length * World.creatureScale, { [f] in SIMD3(f.x, f.y, f.z) }) }
        for sc in schools {
            guard let f = sc.members.first else { continue }
            vote(sc.key, f.x, f.y, f.z, 2, size: 1.2, { [sc] in
                let n = Float(sc.members.count)
                return sc.members.reduce(SIMD3<Float>(repeating: 0)) { $0 + SIMD3($1.x, $1.y, $1.z) } / n
            })
        }
        for w in walkers {
            let y = terrain.height(w.x, w.z)
            vote(w.key, w.x, y, w.z, 1.6, size: w.length * World.creatureScale, { [w, terrain] in SIMD3(w.x, terrain.height(w.x, w.z) + 0.1, w.z) })
        }
        for r in resters { vote(r.key, r.x, r.y, r.z, 1.6, size: r.length * World.creatureScale, { [r] in SIMD3(r.x, r.y + 0.1, r.z) }) }
        for j in jellies { vote(j.key, j.x, j.y, j.z, 1.6, size: j.width * 1.35, { [j] in SIMD3(j.x, j.y, j.z) }) }
        for f in fixtures {
            let top = SIMD3(f.x, f.y + f.halfH, f.z)
            vote(f.key, f.x, f.y + f.halfH, f.z, 0.3, size: max(f.halfW, f.halfH) * 2, { top })
        }
        guard !options.isEmpty else {
            // Everything visible has been named: start a new round.
            captionHistory.removeAll()
            return nil
        }
        // One candidate per species, the best placed.
        var best: [String: (Float, Float, () -> SIMD3<Float>?)] = [:]
        for (k, w, size, p) in options where w > (best[k]?.0 ?? -1) { best[k] = (w, size, p) }
        let total = best.values.reduce(0) { $0 + $1.0 }
        var roll = Float(rng.unit()) * total
        for (k, v) in best.sorted(by: { $0.key < $1.key }) {
            roll -= v.0
            if roll <= 0 {
                captionHistory.append(k)
                if captionHistory.count >= Species.all.count { captionHistory.removeFirst() }
                return (k, v.1, v.2)
            }
        }
        return nil
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

    private func speedOf(_ f: Fish) -> Float { (f.vx * f.vx + f.vy * f.vy + f.vz * f.vz).squareRoot() }

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
                   anim: SIMD4(1, f.phase, f.spec.amp * (0.25 + 0.75 * min(1, speedOf(f) / max(0.05, f.spec.speed))), dof(f.z)),
                   look: SIMD4(1, 0.12, 1, f.spec.wave),
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
                       look: SIMD4(1, 0.3, 1, f.ripple),
                       tint: SIMD4(f.tint.x, f.tint.y, f.tint.z, 1),
                       light: SIMD4(f.mode == 2 ? 0.3 : 0.55, 0.74, 0, f.mode == 2 ? 0 : 0.05)))
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
                       look: SIMD4(1, 0.3, 1, 0),
                       tint: SIMD4(1, 1, 1, 0),
                       light: SIMD4(0.4, 0.74, 0, 0.04)))
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
                       look: SIMD4(1, 0.3, 1, r.mode == 1 ? 9 : 0),
                       tint: SIMD4(1, 1, 1, 1),
                       light: SIMD4(r.mode == 3 ? 1 : 0.3, 0.72, 0, r.mode == 3 ? 0.05 : 0.1)))
        }

        for j in jellies {
            let hw = j.width / 2 * 1.35
            let hh = hw / j.frame.aspect
            put(Sprite(pos: SIMD4(j.x, j.y, j.z, sin(t * 0.07 + j.z) * 0.14),
                       size: SIMD4(hw, hh, 1, 0),
                       uv: j.frame.uv,
                       anim: SIMD4(4, j.phase, j.pulse, dof(j.z)),
                       look: SIMD4(j.opacity, 0.1, 1, 0),
                       tint: SIMD4(1, 1, 1, 0),
                       light: SIMD4(1, 0.9, 0, 0)))
        }

        for pf in puffs {
            let grow = min(1, pf.age / 3)
            let w = pf.size * (0.4 + 0.8 * grow)
            let alpha = 0.26 * min(1, pf.age * 3) * (1 - pf.age / 9)
            put(Sprite(pos: SIMD4(pf.x, pf.y - 0.02, pf.z - 0.05, 0), size: SIMD4(w, w * 0.45, 1, 1),
                       uv: puffFrame.uv, anim: SIMD4(0, 0, 0, 1.2 + dof(pf.z)), look: SIMD4(alpha, 0, 1, 0),
                       tint: SIMD4(1, 1, 1, 0), light: SIMD4(1, 0.6, 0, 0)))
        }

        drawList.sort { $0.0 > $1.0 }
        var count = 0
        for (_, s) in drawList where count < capacity - 1 {
            ptr[count] = s
            count += 1
        }

        overlaySprites = 0
        if showNames, let key = captionKey, captionClock < World.captionShown, captionPlaced {
            let frame = atlas.frame("cap-\(key)")
            let c = captionClock, fadeIn = smooth(0, 2.5, c), fadeOut = 1 - smooth(World.captionShown - 2.5, World.captionShown, c)
            let hh: Float = 0.036
            let hw = hh * frame.aspect
            // Beside the animal, kept clear of the screen edges.
            let edgeX = hw / aspect + 0.03
            let cx = min(1 - edgeX, max(-1 + edgeX, captionNdc.x + hw / aspect * 0.8))
            let cy = min(0.9, max(-0.92, captionNdc.y))
            ptr[count] = Sprite(
                pos: SIMD4(cx, cy, 1, 0),
                size: SIMD4(hw, hh, 1, 0),
                uv: frame.uv,
                anim: SIMD4(9, 0, 0, 0),
                look: SIMD4(fadeIn * fadeOut * 0.78, 0, 0, 0),
                tint: SIMD4(1, 1, 1, 0))
            count += 1
            overlaySprites = 1

            // A thin pointer from the start of the text to the animal, stopping just short of it.
            if let p = captionSubject?(), count + 2 <= capacity {
                let nx = screenX(p.x, p.z), ny = horizon + (p.y - camY) * focal / p.z
                let textLeft = cx - hw / aspect + 2 * hw / aspect * (26.0 / (frame.aspect * 96))
                let below = cy < ny
                let start = SIMD2<Float>((textLeft + 0.012) * aspect, cy + (below ? hh * 0.55 : -hh * 0.55))
                var end = SIMD2<Float>(nx * aspect, ny)
                let d = end - start
                let len = (d.x * d.x + d.y * d.y).squareRoot()
                let margin = max(0.03, captionSize * focal / p.z * 0.4)
                if len > margin + 0.03 {
                    let dir = d / len
                    end = start + dir * (len - margin)
                    let angle = atan2(dir.y, dir.x)
                    let alpha = fadeIn * fadeOut * 0.5
                    let head: Float = 0.010
                    let lineEnd = end - dir * head
                    let mid = (start + lineEnd) / 2
                    let lineLen = ((lineEnd - start) * (lineEnd - start)).sum().squareRoot()
                    ptr[count] = Sprite(pos: SIMD4(mid.x / aspect, mid.y, 1, angle), size: SIMD4(lineLen / 2, 0.0016, 1, 0),
                                        uv: pointerLine.uv, anim: SIMD4(9, 0, 0, 0), look: SIMD4(alpha, 0, 0, 0), tint: SIMD4(1, 1, 1, 0))
                    let hc = end - dir * head
                    ptr[count + 1] = Sprite(pos: SIMD4(hc.x / aspect, hc.y, 1, angle), size: SIMD4(head, head * 0.8, 1, 0),
                                            uv: pointerHead.uv, anim: SIMD4(9, 0, 0, 0), look: SIMD4(alpha, 0, 0, 0), tint: SIMD4(1, 1, 1, 0))
                    count += 2
                    overlaySprites = 3
                }
            }
        }
        return count
    }
}

private func simdLength(_ v: SIMD3<Float>) -> Float {
    (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
}
