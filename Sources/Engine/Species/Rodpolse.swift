import CoreGraphics
import Foundation

extension Species {
    static let rodpolse = SpeciesInfo(
        key: "rodpolse", norsk: "Rødpølse", latin: "Parastichopus tremulus", english: "Red sea cucumber",
        sprites: [SpriteDef(name: "rodpolse", w: 320, h: 120, paint: draw)],
        place: { scene in
            // Lies on the soft bottom.
            for _ in 0..<3 {
                guard let s = scene.findSpot(z: 4...9, rock: 0...0.08) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.08, 0.1), mode: 0, amp: 0, shadowW: 0.14)
            }
        })
}

/// Red sea cucumber lying on the bottom: a warty sausage, red above and paler below, with
/// conical papillae along the back and a fringe of tube feet.
private func draw(_ a: Art) {
    let top: [XY] = [(40, 220), (150, 150), (400, 122), (700, 126), (900, 160), (970, 222)]
    let bottom: [XY] = [(40, 252), (150, 292), (400, 312), (700, 306), (900, 286), (970, 248)]
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = mix(hex(0xa8402a), hex(0xe2a070), smooth(0.4, 1, v))
        c *= 0.9 + 0.2 * artNoise.fbm(x * 0.03, y * 0.05, 3)
        return rgba(c * (0.75 + 0.35 * roundLight(v)))
    }
    var rng = a.rng
    for _ in 0..<26 {
        let x = rng.range(120, 920)
        let yTop = 150 - 60 * sin((x - 40) / 930 * .pi) + 30
        let h = rng.range(20, 44)
        a.taper([(x, yTop + 8), (x + rng.range(-6, 6), yTop - h)], 22, 3, hex(0xc5583a))
        a.disc(x, yTop - h, 4, hex(0xf4d0b0), 0.9)
    }
    for i in 0..<40 {
        let x = 90 + Double(i) * 21
        a.disc(x, 302 + 8 * sin(Double(i)), 7, hex(0xf2c8a8), 0.7)
    }
    a.rng = rng
}
