import CoreGraphics
import Foundation

extension Species {
    static let sjotre = SpeciesInfo(
        key: "sjotre", norsk: "Sjøtre", latin: "Paragorgia arborea", english: "Bubblegum coral",
        sprites: [
            SpriteDef(name: "sjotre-1", w: 500, h: 560) { draw($0, base: hex(0x98202c), tip: hex(0xdf5661), seed: 5) },
            SpriteDef(name: "sjotre-2", w: 440, h: 500) { draw($0, base: hex(0xcc7c86), tip: hex(0xf4c8c7), seed: 8) },
        ],
        place: { scene in
            for _ in 0..<5 {
                guard let s = scene.findSpot(z: 8...20, rock: 0.55...1.01) else { continue }
                scene.addFixture(scene.rng.chance(0.6) ? "sjotre-1" : "sjotre-2", spot: s, height: scene.rng.float(0.8, 1.35), mode: 2, amp: 0.018, shadowW: 0.5)
            }
        })
}

/// Bubblegum coral, Paragorgia arborea.
private func draw(_ a: Art, base: C3, tip: C3, seed: UInt64) {
    var rng = RNG(seed)
    var limbs: [BenthosArt.Limb] = []
    func grow(_ x: Double, _ y: Double, _ ang: Double, _ w: Double, _ depth: Int) {
        var pts: [XY] = [(x, y)]
        var px = x, py = y, th = ang
        for _ in 0..<3 {
            th += rng.range(-0.3, 0.3)
            let len = rng.range(50, 85) * (0.8 + w / 90)
            px += cos(th) * len; py += sin(th) * len
            pts.append((px, py))
        }
        limbs.append(BenthosArt.Limb(pts: pts, w: w, depth: depth))
        guard depth < 4 else { return }
        let kids = depth == 0 ? 3 : rng.int(2, 3)
        for i in 0..<kids {
            let f = Double(i) / Double(kids - 1) - 0.5
            grow(px, py, th + f * 1.25 + rng.range(-0.12, 0.12), w * rng.range(0.70, 0.84), depth + 1)
        }
    }
    grow(0, 0, -.pi / 2, 92, 0)
    for l in BenthosArt.fit(limbs, a).reversed() {
        let w = l.w, tone = Float(l.depth) / 4
        let shade = Float(0.7 + Double(l.depth) * 0.08)
        a.taper(l.pts, w * 1.12, w, base * shade * 0.65)
        a.taper(l.pts, w, w * 0.88, mix(base, tip, tone) * shade)
        let end = l.pts.last!
        a.disc(end.0, end.1, w * 1.0, tip)
        a.softDot(end.0 - w * 0.2, end.1 - w * 0.2, w * 0.7, C3(1, 0.9, 0.86), 0.7)
        for q in l.pts.dropFirst().dropLast() {
            a.disc(q.0 + rng.range(-w * 0.3, w * 0.3), q.1, w * 0.56, mix(base, tip, tone))
        }
        for _ in 0..<14 {
            let q = l.pts[rng.int(0, l.pts.count - 1)]
            a.disc(q.0 + rng.range(-w * 0.4, w * 0.4), q.1 + rng.range(-w * 0.4, w * 0.4), max(1.6, w * 0.05), C3(1, 0.92, 0.88), 0.85)
        }
    }
}
