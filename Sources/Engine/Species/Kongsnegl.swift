import CoreGraphics
import Foundation

extension Species {
    static let kongsnegl = SpeciesInfo(
        key: "kongsnegl", norsk: "Kongsnegl", latin: "Buccinum undatum", english: "Common whelk",
        sprites: [SpriteDef(name: "kongsnegl", w: 220, h: 160, paint: draw)],
        place: { scene in
            // Creeps almost without pause.
            scene.addRester(ResterSpec(length: 0.1, mode: 0, amp: 0, glide: 0.012, rest: (1, 5), z: 3.6...7, rock: 0...0.2, lift: 0,
                                       crawls: true))
        })
}

/// Common whelk crawling: a spired, ribbed shell over a pale foot, with the siphon tube held
/// forward and two head tentacles.
private func draw(_ a: Art) {
    // Foot, siphon and tentacles under and ahead of the shell.
    a.fill([(120, 640), (300, 590), (700, 590), (930, 620), (960, 660), (700, 690), (300, 690)], hex(0xe6dcc6))
    a.taper([(820, 560), (880, 470), (960, 400)], 44, 30, hex(0xd8ccb2))
    a.taper([(860, 610), (930, 560), (990, 560)], 16, 6, hex(0xe6dcc6))
    a.taper([(840, 612), (900, 540), (950, 520)], 14, 6, hex(0xe6dcc6))
    // Shell: body whorl and a spire of smaller whorls toward the apex.
    let whorls: [(Double, Double, Double, Double)] = [(520, 430, 320, 210), (400, 290, 200, 130), (320, 200, 130, 86), (265, 140, 82, 56), (230, 100, 50, 34)]
    for (i, w) in whorls.enumerated().reversed() {
        let tone = Float(1 - Double(i) * 0.06)
        a.polar(cx: w.0, cy: w.1, sy: w.3 / w.2, maxR: w.2, radius: { _ in Float(w.2) }) { r, th, x, y in
            var c = mix(hex(0xc7ab78), hex(0x8a6e44), smooth(0.2, 1, r)) * tone
            c *= 0.88 + 0.16 * abs(sin(th * 9 + Float(i)))          // axial ribs
            c *= 0.93 + 0.1 * sin(y * 0.2 + Float(i) * 2)           // spiral cords
            c *= 0.95 + 0.1 * artNoise.fbm(x * 0.05, y * 0.05, 2)
            return rgba(c * (1.08 - 0.3 * r * r))
        }
    }
    // Aperture toward the front, under the siphonal canal.
    a.fill([(760, 470), (850, 420), (870, 520), (800, 590), (730, 560)], hex(0x5a3f26), 0.9)
}
