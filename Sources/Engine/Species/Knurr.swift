import CoreGraphics
import Foundation

extension Species {
    static let knurr = SpeciesInfo(
        key: "knurr", norsk: "Knurr", latin: "Eutrigla gurnardus", english: "Grey gurnard",
        sprites: [SpriteDef(name: "knurr", w: 420, h: 170, paint: draw)],
        place: { scene in
            // Walks the sand on its free pectoral rays.
            scene.addRester(ResterSpec(length: 0.3, mode: 1, amp: 0.03, glide: 0.08, rest: (4, 14), z: 3.8...8, rock: 0...0.1, lift: 0,
                                       crawls: true))
        })
}

/// Grey gurnard: a big bony sloping head, small white spots, wide pectoral fans, and three
/// free fin rays it walks on.
private func draw(_ a: Art) {
    let finC = hex(0x5d5a52), finD = hex(0x8b8a80)
    a.fin(base: [(84, 178), (64, 190), (84, 202)], edge: [(0, 120), (30, 190), (0, 260)], root: finC, tip: finD, alpha: 0.8, rays: 10)
    a.fin(base: [(300, 130), (590, 104)], edge: [(300, 104), (440, 78), (600, 80)], root: finC, tip: finD, alpha: 0.75, rays: 18)
    let spineBase: [XY] = [(610, 100), (680, 94), (760, 92)]
    let spineTips: [XY] = [(620, 40), (660, 30), (700, 34), (740, 52), (764, 76)]
    a.fill(spineBase + spineTips.reversed(), finC, 0.85, raw: true)
    a.softDot(690, 70, 22, hex(0x16130f), 0.8)
    for x in stride(from: 330.0, through: 560, by: 30) {
        a.fill([(x - 6, 248), (x, 262), (x + 6, 248)], finD, 0.7, raw: true)
    }
    let top: [XY] = [(80, 176), (200, 152), (400, 122), (600, 100), (780, 92), (900, 112), (985, 190)]
    let bottom: [XY] = [(80, 198), (200, 214), (400, 242), (600, 262), (780, 278), (880, 274), (950, 252), (990, 206)]
    let back = hex(0x5f5c54), side = hex(0x8e8a7e), belly = hex(0xe2ddd0)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.55)
        c = mix(c, hex(0xe6e2d6), spots(x, y, cell: 18, radius: 3, keep: 0.6) * (1 - smooth(0.5, 0.7, v)))
        // Bony plates on the head.
        if t > 0.82 { c *= 0.92 + 0.12 * artNoise.fbm(x * 0.08, y * 0.08, 2) }
        return rgba(c * roundLight(v))
    }
    // Free rays used as legs, then the pectoral fan over them.
    for i in 0..<3 {
        let x0 = 770 + Double(i) * 22
        a.line([(x0, 264), (x0 + 10, 330), (x0 + 4, 396)], hex(0xcbc4b2), 0.95, 6)
    }
    a.fin(base: [(720, 190), (740, 254)], edge: [(560, 240), (470, 320), (640, 352)], root: hex(0x6e6b62), tip: hex(0x8fa8b8), alpha: 0.75, rays: 12)
    a.line([(985, 196), (956, 214), (920, 214)], hex(0x26231e), 0.5, 4)
    a.eye(870, 150, 24, iris: hex(0xb8a46a))
}
