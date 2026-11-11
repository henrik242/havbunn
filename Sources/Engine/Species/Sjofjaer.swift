import CoreGraphics
import Foundation

extension Species {
    static let sjofjaer = SpeciesInfo(
        key: "sjofjaer", norsk: "Stor piperenser", latin: "Funiculina quadrangularis", english: "Tall sea pen",
        sprites: [SpriteDef(name: "sjofjaer", w: 120, h: 760, paint: draw)],
        place: { scene in
            // Soft bottom life.
            for _ in 0..<26 {
                guard let s = scene.findSpot(z: 6...24, rock: 0...0.08) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.8, 1.5), mode: 2, amp: 0.05)
            }
        })
}

/// Tall sea pen, Funiculina quadrangularis: a slender whip with short, irregular polyps,
/// no side branches.
private func draw(_ a: Art) {
    let h = a.unitH
    let axis: [XY] = [(500, h - 4), (506, h * 0.7), (494, h * 0.4), (504, 10)]
    a.taper(axis, 60, 22, hex(0xd9cbb2))
    a.taper(axis.map { ($0.0 - 8, $0.1) }, 18, 6, hex(0xf3eadb), 0.7)
    var rng = a.rng
    for i in 0..<70 {
        let t = Double(i) / 69
        let y = h * 0.88 - t * h * 0.86
        let x = 500 + sin(t * 3) * 6
        let side = rng.chance(0.5) ? -1.0 : 1.0
        let len = rng.range(30, 90) * (1 - t * 0.5)
        let tip = (x + side * len, y - rng.range(10, 30))
        a.line([(x, y), tip], hex(0xf2e2cf), 0.85, 20)
        a.disc(tip.0, tip.1, 22, hex(0xfbeee0), 0.9)
    }
    a.rng = rng
}
