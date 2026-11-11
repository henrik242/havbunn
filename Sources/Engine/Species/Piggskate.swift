import CoreGraphics
import Foundation

extension Species {
    static let piggskate = SpeciesInfo(
        key: "piggskate", norsk: "Piggskate", latin: "Raja clavata", english: "Thornback ray",
        sprites: [SpriteDef(name: "piggskate", w: 560, h: 340, paint: draw)],
        place: { scene in
            scene.addRester(ResterSpec(length: 0.6, mode: 3, amp: 0.05, glide: 0.45, rest: (25, 90), z: 4...9, rock: 0...0.12, lift: 0))
        })
}

/// Thornback ray, disc from above at a low angle.
private func draw(_ a: Art) {
    a.taper([(300, 300), (180, 298), (70, 305), (6, 298)], 46, 8, hex(0x6f5a3a))
    for i in 0..<9 {
        let x = 40 + Double(i) * 30
        a.fill([(x - 6, 300), (x, 278), (x + 6, 300)], hex(0xe0d4ae), 1, raw: true)
    }
    a.fill([(70, 296), (58, 268), (88, 268), (96, 294)], hex(0x5e4b31))
    a.fill([(30, 296), (18, 274), (44, 274), (52, 296)], hex(0x5e4b31))
    let top: [XY] = [(250, 280), (310, 240), (420, 110), (520, 18), (640, 110), (790, 215), (900, 268), (995, 300)]
    let bottom: [XY] = [(250, 320), (310, 360), (420, 490), (520, 582), (640, 490), (790, 385), (900, 332), (995, 300)]
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = mix(hex(0x8a724a), hex(0x7c653e), v)
        c *= 0.85 + 0.3 * artNoise.fbm(x * 0.02, y * 0.02, 4)
        let sp = spots(x, y, cell: 42, radius: 7.2, keep: 0.65)
        c = mix(c, hex(0x3f3019), sp * 0.8)
        let pale = spots(x, y, cell: 64, radius: 7.5, keep: 0.45, seed: 7)
        c = mix(c, hex(0xd9c79a), pale * 0.85)
        _ = t
        // Ridge along the midline.
        let mid = clamp01(1 - abs(v - 0.5) * 7)
        return rgba(c * (0.82 + 0.28 * mid))
    }
    for i in 0..<10 {
        let x = 310 + Double(i) * 50
        a.fill([(x - 7, 306), (x + 5, 288), (x + 13, 306)], hex(0xe6dab6), 1, raw: true)
    }
    for (x, y) in [(590.0, 232.0), (560, 368), (480, 195), (455, 410), (700, 258), (700, 342)] {
        a.disc(x, y, 7, hex(0xe6dab6))
    }
    a.eye(842, 264, 12, iris: hex(0xa88f50))
    a.eye(842, 334, 12, iris: hex(0xa88f50))
    a.disc(806, 268, 6, hex(0x1b1610)); a.disc(806, 330, 6, hex(0x1b1610))
}
