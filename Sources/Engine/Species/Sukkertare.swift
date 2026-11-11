import CoreGraphics
import Foundation

extension Species {
    static let sukkertare = SpeciesInfo(
        key: "sukkertare", norsk: "Sukkertare", latin: "Saccharina latissima", english: "Sugar kelp",
        sprites: [
            SpriteDef(name: "sukkertare-1", w: 240, h: 860) { draw($0, seed: 2) },
            SpriteDef(name: "sukkertare-2", w: 240, h: 860) { draw($0, seed: 23) },
        ],
        place: { scene in
            for _ in 0..<3 {
                guard let s = scene.findSpot(z: 9...20, rock: 0.5...1.01), s.1 > 1.0 else { continue }
                scene.addFixture("sukkertare-\(scene.rng.int(1, 2))", spot: s, height: scene.rng.float(1.5, 2.8), mode: 2, amp: 0.12,
                                 ripple: 0.05, shadowW: 0.3, tint: kelpTint)
            }
        })
}

/// Saccharina latissima: one long ruffled blade.
private func draw(_ a: Art, seed: UInt64) {
    var rng = RNG(seed)
    let h = a.unitH
    a.taper([(500, h - 2), (505, h * 0.9), (495, h * 0.84)], 34, 22, hex(0x4b3819))
    let n = 46
    var left: [XY] = [], right: [XY] = []
    for i in 0...n {
        let t = Double(i) / Double(n)
        let y = h * 0.86 - t * (h * 0.85)
        let spine = 500 + sin(t * 5 + 1) * 62 * t
        let width = 250 * pow(sin(min(1, t * 1.25 + 0.05) * .pi * 0.92), 0.6) * (1 - t * 0.55)
        let ruffleL = sin(t * 46 + 0.4) * 34 * t + sin(t * 91) * 10
        let ruffleR = sin(t * 49 + 2.1) * 34 * t + sin(t * 87) * 10
        left.append((spine - width + ruffleL, y))
        right.append((spine + width + ruffleR, y))
    }
    let blade = a.path(left + right.reversed(), closed: true, smooth: true)
    a.gradient(blade, [(hex(0x6f5120), 1, 0), (hex(0xa98336), 1, 0.45), (hex(0xbd983f), 0.97, 1)], from: (500, h), to: (500, 0))
    a.ctx.saveGState()
    a.ctx.addPath(blade)
    a.ctx.clip()
    // Dark and bright bands from the characteristic frilled edges.
    for i in 0..<40 {
        let t = rng.unit()
        let y = h * 0.86 - t * h * 0.85
        let light = i % 2 == 0
        let c = light ? hex(0xe0bb5c) : hex(0x3f2c0f)
        let bow = rng.range(-22, 22)
        a.line([(100, y + bow), (300, y - bow), (500, y + bow * 0.5), (700, y - bow), (900, y + bow)], c, light ? 0.10 : 0.11, rng.range(14, 40))
    }
    let spine = (0...n).map { i -> XY in
        let t = Double(i) / Double(n)
        return (500 + sin(t * 5 + 1) * 62 * t, h * 0.86 - t * h * 0.85)
    }
    a.taper(spine, 150, 50, hex(0x5a3f18), 0.40)
    for _ in 0..<70 {
        a.softDot(rng.range(260, 760), rng.range(10, h * 0.85), rng.range(12, 34), hex(0xd4b360), 0.10, sy: 1.4)
    }
    a.ctx.restoreGState()
}
