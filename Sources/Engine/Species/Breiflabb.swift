import CoreGraphics
import Foundation

extension Species {
    static let breiflabb = SpeciesInfo(
        key: "breiflabb", norsk: "Breiflabb", latin: "Lophius piscatorius", english: "Angler",
        sprites: [SpriteDef(name: "breiflabb", w: 640, h: 352, paint: draw)],
        place: { scene in
            // Lies in wait and never moves off.
            scene.addRester(ResterSpec(length: 0.85, mode: 1, amp: 0.02, glide: 0, rest: (9999, 9999), z: 4.3...7, rock: 0.05...0.3, lift: -0.03))
        })
}

/// Anglerfish lying on the bottom: broad flat head, wide closed mouth with the lower jaw
/// jutting, eyes on top, fringed edge, lure on the snout.
private func draw(_ a: Art) {
    let skin = hex(0x6f5a3f), dark = hex(0x3e321d), pale = hex(0xb7a582)
    a.fin(base: [(150, 352), (130, 380), (150, 408)], edge: [(10, 300), (0, 380), (20, 450)], root: dark, tip: skin, alpha: 0.75, rays: 12)
    a.fin(base: [(250, 330), (420, 300)], edge: [(250, 280), (330, 240), (430, 262)], root: dark, tip: skin, alpha: 0.7, rays: 10)
    let top: [XY] = [(140, 345), (250, 320), (390, 295), (520, 262), (680, 235), (820, 232), (925, 252), (985, 300)]
    let bottom: [XY] = [(140, 395), (250, 405), (390, 420), (520, 440), (680, 455), (820, 452), (925, 430), (990, 372)]
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = mix(skin, pale, smooth(0.7, 1.0, v))
        let m = artNoise.fbm(x * 0.015, y * 0.02, 4)
        c = mix(c, dark, smooth(0.35, 0.75, m) * 0.55)
        c = mix(c, hex(0x9a8560), smooth(0.58, 0.76, artNoise.fbm(x * 0.04 + 9, y * 0.05, 3)) * 0.5)
        c *= 1 - spots(x, y, cell: 15, radius: 3.6, keep: 0.4) * 0.22
        return rgba(c * (0.70 + 0.34 * roundLight(v)))
    }
    // Rounded pectoral behind the head.
    a.fin(base: [(560, 360), (585, 420)], edge: [(470, 410), (490, 470), (580, 480)], root: skin * 0.85, tip: hex(0x8c7756), alpha: 0.8, rays: 9)
    // Closed mouth along the front, lower jaw ahead of the upper.
    a.line([(990, 336), (930, 350), (840, 352), (760, 340)], hex(0x1c140f), 0.8, 7)
    a.fill([(998, 344), (990, 364), (930, 368), (900, 356), (940, 352)], hex(0x7c6748))
    for i in 0..<6 {
        let x = 980 - Double(i) * 16
        a.fill([(x - 4, 350), (x, 336 - Double(i % 2) * 4), (x + 4, 350)], hex(0xa89f88), 0.9, raw: true)
    }
    // Skin fringe along the jaw and flanks.
    for i in 0..<30 {
        let t = Double(i) / 29
        let x = 170 + t * 810, y = 404 + 46 * sin(min(1, t * 1.15) * 1.7) - t * t * 50
        let len = 10 + (i % 4 == 0 ? 18.0 : 6.0)
        a.taper([(x, y), (x + 4, y + len * 0.6), (x - 2, y + len)], 7, 1.4, i % 2 == 0 ? hex(0x5f4e35) : hex(0x9b8862), 0.85)
    }
    // Lure rod and flap, eyes high on the head.
    a.line([(880, 250), (905, 190), (950, 160), (982, 170)], hex(0xa8976f), 0.95, 4.5)
    a.taper([(982, 170), (974, 192), (984, 206)], 20, 3, hex(0xd5c7a3))
    a.line([(800, 240), (812, 210), (830, 198)], hex(0xa8976f), 0.8, 3.4)
    a.eye(770, 252, 14, iris: hex(0xa88f50))
    a.eye(735, 246, 11, iris: hex(0x8a7543))
}
