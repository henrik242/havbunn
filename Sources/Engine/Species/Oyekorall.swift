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
    // Dead, darker skeleton at the core, living white or orange at the tips.
    for b in fitted.sorted(by: { $0.depth < $1.depth }) {
        let live = min(1, Float(b.depth) / 4)
        let c = mix(base * 0.55, tip, live)
        a.taper(b.pts, b.w * 1.3, b.w * 1.05, c * 0.5)
        a.taper(b.pts, b.w, b.w * 0.8, c)
        a.taper(b.pts.map { ($0.0 - b.w * 0.2, $0.1) }, b.w * 0.34, b.w * 0.24, tip, 0.45)
    }
    for b in fitted where b.depth >= 2 {
        for (j, q) in b.pts.enumerated() where j > 0 {
            let isTip = j == b.pts.count - 1
            guard isTip || rng.chance(0.28) else { continue }
            let side = rng.chance(0.5) ? -1.0 : 1.0
            let cup = max(5, b.w * 0.5)
            let px = q.0 + (isTip ? 0 : side * b.w * 0.75), py = q.1
            a.disc(px, py, cup * 1.16, base * 0.72)
            a.disc(px, py, cup, tip)
            a.disc(px, py, cup * 0.56, hex(0xb98a68))
            for k in 0..<12 {
                let an = Double(k) / 12 * 2 * .pi
                a.line([(px + cos(an) * cup * 0.5, py + sin(an) * cup * 0.5),
                        (px + cos(an) * cup * 1.65, py + sin(an) * cup * 1.65)], C3(1, 0.97, 0.92), 0.55, 1.5, smooth: false)
            }
        }
    }
}
