import CoreGraphics
import Foundation

extension Species {
    static let lange = SpeciesInfo(
        key: "lange", norsk: "Lange", latin: "Molva molva", english: "Ling",
        sprites: [SpriteDef(name: "lange", w: 720, h: 180, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 1.0, speed: 0.14, z: 5...12, alt: 0.2...0.9, amp: 0.22, wave: 7.5, hover: 0.9))
        })
}

/// Ling: a long, slightly flattened cod relative with a barbel, a short first and long second
/// dorsal, dark spots at the rear of the vertical fins and pale fin margins.
private func draw(_ a: Art) {
    let finC = hex(0x4c4632), finD = hex(0x6f684a), rim = hex(0xe6e0cc)
    a.fin(base: [(60, 112), (44, 122), (60, 132)], edge: [(6, 84), (0, 122), (6, 160)], root: finC, tip: finD, alpha: 0.85, rays: 10)
    let d2: [XY] = [(120, 80), (400, 62), (660, 56)]
    a.fin(base: [(120, 106), (400, 88), (660, 80)], edge: d2, root: finC, tip: finD, alpha: 0.85, rays: 30)
    a.line(d2, rim, 0.7, 3)
    a.disc(130, 90, 10, hex(0x14120c), 0.85)
    a.fin(base: [(700, 78), (780, 76)], edge: [(705, 50), (740, 42), (785, 58)], root: finC, tip: finD, alpha: 0.85, rays: 7)
    let an: [XY] = [(120, 170), (360, 186), (560, 190)]
    a.fin(base: [(120, 140), (360, 158), (560, 164)], edge: an, root: finC, tip: finD, alpha: 0.85, rays: 22)
    a.line(an, rim, 0.7, 3)
    a.disc(130, 160, 9, hex(0x14120c), 0.85)
    let top: [XY] = [(56, 110), (250, 94), (500, 82), (700, 76), (850, 80), (940, 98), (995, 126)]
    let bottom: [XY] = [(56, 134), (250, 150), (500, 162), (700, 166), (850, 160), (940, 146), (995, 134)]
    let back = hex(0x5a5434), side = hex(0x8c8458), belly = hex(0xdcd6c0)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.55)
        c = mix(c, hex(0x3a3420), smooth(0.48, 0.66, artNoise.fbm(x * 0.015, y * 0.06, 3)) * 0.5 * (1 - smooth(0.5, 0.7, v)))
        return rgba(c * roundLight(v))
    }
    a.fin(base: [(820, 120), (820, 144)], edge: [(760, 126), (740, 150), (770, 168)], root: finC, tip: finD, alpha: 0.75, rays: 7)
    gill(a, 850, 84, 158, bow: 20)
    a.line([(995, 130), (968, 140), (940, 138)], hex(0x22200f), 0.5, 3)
    a.line([(958, 150), (954, 172), (946, 184)], hex(0xbdb38a), 1, 3)
    a.eye(930, 104, 10, iris: hex(0x9a8e5c))
}
