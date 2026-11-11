import CoreGraphics
import Foundation

extension Species {
    static let oyekorall = SpeciesInfo(
        key: "oyekorall", norsk: "Øyekorall", latin: "Desmophyllum pertusum", english: "Cold-water coral",
        sprites: [
            SpriteDef(name: "oyekorall-1", w: 760, h: 620) { draw($0, base: hex(0xcbb7a4), tip: hex(0xf4ebdd), seed: 11) },
            SpriteDef(name: "oyekorall-2", w: 760, h: 620) { draw($0, base: hex(0xcf7a47), tip: hex(0xf3b98c), seed: 29) },
            SpriteDef(name: "oyekorall-3", w: 620, h: 500) { draw($0, base: hex(0xbdab9c), tip: hex(0xfaf2e7), seed: 47) },
        ],
        place: { scene in
            // Reef mounds carry the coral first so nothing else crowds them out.
            for _ in 0..<24 {
                guard let s = scene.findSpot(z: 7.5...17, ndc: -0.9...0.9, rock: 0.55...1.01) else { continue }
                let v = scene.rng.chance(0.1) ? "oyekorall-2" : (scene.rng.chance(0.5) ? "oyekorall-1" : "oyekorall-3")
                scene.addFixture(v, spot: s, height: scene.rng.float(0.8, 1.5), mode: 0, amp: 0, shadowW: 0.7)
            }
        })
}

/// Branching cold-water reef coral, Desmophyllum pertusum (Lophelia).
private func draw(_ a: Art, base: C3, tip: C3, seed: UInt64) {
    var rng = RNG(seed)
    var limbs: [BenthosArt.Limb] = []
    func grow(_ x: Double, _ y: Double, _ ang: Double, _ w: Double, _ depth: Int) {
        var px = x, py = y, th = ang
        var pts: [XY] = [(x, y)]
        for _ in 0..<rng.int(3, 4) {
            th += rng.range(-0.5, 0.5) // the zigzag of sympodial growth
            th += (-.pi / 2 - th) * 0.16
            let len = rng.range(46, 74)
            px += cos(th) * len
            py += sin(th) * len
            pts.append((px, py))
        }
        limbs.append(BenthosArt.Limb(pts: pts, w: w, depth: depth))
        guard depth < 4 else { return }
        for _ in 0..<(depth < 2 ? 2 : rng.int(1, 2)) {
            let spread = rng.range(0.35, 0.85) * (rng.chance(0.5) ? 1 : -1)
            let anchor = pts[rng.int(pts.count - 2, pts.count - 1)]
            grow(anchor.0, anchor.1, th + spread, w * rng.range(0.74, 0.86), depth + 1)
        }
    }
    for i in 0..<5 {
        let t = Double(i) / 4
        grow(120 + t * 760, 0, -.pi / 2 + (t - 0.5) * 1.1, 36 + 12 * (1 - abs(t - 0.5) * 2), abs(t - 0.5) > 0.3 ? 1 : 0)
    }
    let fitted = BenthosArt.fit(limbs, a)

    // Pale calcareous skeleton: a cool greyed core where the colony is old and dead,
    // grading to translucent cream at the living tips. Cup colours are kept close to it.
    let skel = mix(base, hex(0x8f8d86), 0.26)
    let cupWall = mix(base, tip, 0.62)
    let cupRim = mix(tip, C3(1, 0.99, 0.96), 0.4)
    let cupThroat = mix(base * 0.62, hex(0x7a6b5e), 0.3)

    for b in fitted.sorted(by: { $0.depth < $1.depth }) {
        let live = min(1, Float(b.depth) / 4)
        let c = mix(skel * 0.66, tip, live * 0.92)
        let w = b.w
        // contact shadow and the rounded underside of the tube
        a.taper(b.pts, w * 1.34, w * 1.06, c * 0.46)
        a.taper(b.pts, w, w * 0.84, c)
        // faint longitudinal costae (ribs) running the length of the tube
        for d in [-0.5, 0.5] {
            a.line(oyeOffset(b.pts, w * d), c * 0.68, 0.3, max(0.8, w * 0.1))
        }
        // rounded specular catching the light from the upper left
        a.taper(b.pts.map { ($0.0 - w * 0.24, $0.1) }, w * 0.34, w * 0.24, mix(c, C3(1, 0.99, 0.94), 0.55), 0.5)
    }

    // Cup corallites (calices) tipping the branches, rimmed with radiating septa.
    for b in fitted where b.depth >= 1 {
        for (j, q) in b.pts.enumerated() where j > 0 {
            let isTip = j == b.pts.count - 1 && b.depth >= 2
            let bud = !isTip && b.depth >= 2 && rng.chance(0.3)
            guard isTip || bud else { continue }
            let side = rng.chance(0.5) ? -1.0 : 1.0
            let px = q.0 + (isTip ? 0 : side * b.w * 0.7), py = q.1
            let r = isTip ? max(7, b.w * 0.66) : max(5, b.w * 0.46)
            oyeCup(a, px, py, r, wall: cupWall, rim: cupRim, throat: cupThroat, tilt: rng.range(0, .pi), rng: &rng)
        }
    }
}

/// Offsets a polyline sideways by `d` along its local normal, for ribs parallel to a branch.
private func oyeOffset(_ pts: [XY], _ d: Double) -> [XY] {
    var out: [XY] = []
    out.reserveCapacity(pts.count)
    for i in 0..<pts.count {
        let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
        var nx = -(b.1 - a.1), ny = b.0 - a.0
        let len = max(1e-6, (nx * nx + ny * ny).squareRoot())
        nx /= len; ny /= len
        out.append((pts[i].0 + nx * d, pts[i].1 + ny * d))
    }
    return out
}

/// A single cup-shaped corallite: flared lit rim, shadowed throat and fine radiating septa.
private func oyeCup(_ a: Art, _ x: Double, _ y: Double, _ r: Double,
                    wall: C3, rim: C3, throat: C3, tilt: Double, rng: inout RNG) {
    let sy = 0.82   // the low viewing angle flattens the cup opening into an ellipse
    // soft shadow so the cup seats on the branch
    a.disc(x, y + r * 0.1, r * 1.2, wall * 0.42, 0.55, sy: sy)
    // ribbed outer wall, lit flared rim, then the shadowed bowl and dark throat
    a.disc(x, y, r * 1.04, wall * 0.9, 1, sy: sy)
    a.disc(x, y, r * 0.9, rim, 1, sy: sy)
    a.disc(x, y, r * 0.68, wall * 0.78, 1, sy: sy)
    a.disc(x, y, r * 0.24, throat, 1, sy: sy)
    // septa: alternating primary and secondary ridges from the throat out to the rim
    let n = 18
    let ridge = mix(rim, C3(1, 1, 1), 0.2)
    for k in 0..<n {
        let an = Double(k) / Double(n) * 2 * .pi + tilt
        let r1 = (k % 2 == 0 ? 0.94 : 0.74) * r
        let ca = cos(an), sa = sin(an) * sy
        a.line([(x + ca * r * 0.19, y + sa * r * 0.19), (x + ca * r1, y + sa * r1)],
               ridge, 0.72, max(0.8, r * 0.075))
    }
    // highlight on the upper rim
    a.softDot(x - r * 0.18, y - r * 0.42 * sy, r * 0.75, C3(1, 0.99, 0.95), 0.4, sy: sy)
}
