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

/// Tall sea pen, Funiculina quadrangularis: a tall, slender, nearly straight quadrangular whip
/// rising from a bulbous buried base, its upper two-thirds lined with rows of small polyp leaves.
private func draw(_ a: Art) {
    let h = a.unitH
    var rng = a.rng
    let stalk = hex(0xe3d6bf), pale = hex(0xf6efe0), polyp = hex(0xf3e6d2)

    // Bulbous peduncle anchoring the base in the mud.
    a.softDot(500, h - 36, 70, hex(0x7f7156), 0.35, sy: 0.9)
    a.disc(500, h - 70, 54, stalk, 1, sy: 1.25)
    a.disc(492, h - 86, 30, pale, 0.6, sy: 1.25)

    // Slender, slightly swaying rachis.
    let axis: [XY] = [(500, h - 60), (508, h * 0.7), (492, h * 0.4), (502, 12)]
    a.taper(axis, 46, 12, stalk)
    // Two edge highlights hint at the four-sided (quadrangular) cross-section.
    a.taper(axis.map { ($0.0 - 12, $0.1) }, 10, 3, pale, 0.7)
    a.taper(axis.map { ($0.0 + 11, $0.1) }, 7, 2, hex(0xbfb295), 0.5)

    let A = Curve(axis.map { ($0.1, $0.0) })   // x as a function of height y
    func axisX(_ y: Double) -> Double { A.value(y) }

    // Rows of small polyp leaves along the upper two-thirds; the lower third is a bare stalk.
    let rows = 26
    for r in 0..<rows {
        let t = Double(r) / Double(rows - 1)        // 0 near mid-stalk, 1 at the top
        let y = h * 0.60 - t * (h * 0.60 - h * 0.05)
        let x = axisX(y)
        let w = 44.0 * (1 - t * 0.55)               // leaves shrink toward the tip
        for side in [-1.0, 1.0] {
            // A small leaf: a short stub carrying a fan of fine polyp tentacles, angled upward.
            let bx = x + side * 14, by = y
            let fan = rng.int(3, 5)
            for k in 0..<fan {
                let f = Double(k) / Double(max(1, fan - 1)) - 0.5
                let tip = (bx + side * w * (0.7 + 0.3 * abs(f)), by - w * (0.8 - 0.4 * abs(f)) - rng.range(0, 12))
                let mid = ((bx + tip.0) / 2 + side * 6, (by + tip.1) / 2)
                a.line([(bx, by), mid, tip], polyp, 0.8, 6)
            }
            a.disc(bx, by, 8, pale, 0.8)
        }
    }
    a.rng = rng
}
