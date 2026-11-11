import CoreGraphics
import Foundation

extension Species {
    static let hvitting = SpeciesInfo(
        key: "hvitting", norsk: "Hvitting", latin: "Merlangius merlangus", english: "Whiting",
        sprites: [SpriteDef(name: "hvitting", w: 300, h: 100, paint: draw)],
        place: { scene in
            scene.addSchool(SwimmerSpec(length: 0.3, speed: 0.5, z: 5...11, alt: 0.6...2.5, amp: 0.38, wave: 7, count: 18))
        })
}

/// Whiting: silvery with a sandy back, three dorsal fins, and a dark spot at the base of the
/// pectoral fin.
private func draw(_ a: Art) {
    let finC = hex(0x8a8670), finD = hex(0xb8b6a6)
    a.fin(base: [(90, 172), (60, 184), (90, 196)], edge: [(0, 90), (24, 184), (0, 278)], root: finC, tip: finD, alpha: 0.7, rays: 12)
    a.fin(base: [(150, 160), (300, 116)], edge: [(160, 120), (230, 82), (310, 84)], root: finC, tip: finD, alpha: 0.65, rays: 9)
    a.fin(base: [(320, 110), (480, 78)], edge: [(330, 66), (400, 36), (490, 46)], root: finC, tip: finD, alpha: 0.65, rays: 10)
    a.fin(base: [(500, 74), (640, 66)], edge: [(510, 34), (580, 20), (650, 34)], root: finC, tip: finD, alpha: 0.65, rays: 9)
    a.fin(base: [(150, 200), (320, 244)], edge: [(160, 240), (230, 280), (330, 290)], root: finD, tip: finD, alpha: 0.6, rays: 9)
    let top: [XY] = [(85, 170), (170, 150), (300, 108), (480, 74), (650, 64), (790, 76), (900, 116), (985, 170)]
    let bottom: [XY] = [(85, 190), (170, 200), (300, 230), (480, 262), (650, 270), (790, 262), (900, 232), (985, 186)]
    let back = hex(0x9a9070), side = hex(0xd9dad0), belly = hex(0xf6f6f0)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.4)
        c += C3(0.12, 0.13, 0.12) * pow(clamp01(1 - abs(v - 0.55) * 3.2), 3)
        c *= 1 - scales(x, y, size: 24) * 0.08
        return rgba(c * (0.72 + 0.34 * roundLight(v)))
    }
    a.fin(base: [(770, 170), (770, 205)], edge: [(690, 172), (665, 200), (700, 232)], root: finC, tip: finD, alpha: 0.6, rays: 7)
    a.disc(772, 176, 13, hex(0x1a1a14), 0.9)
    a.line([(985, 180), (950, 196), (910, 194)], hex(0x2a2a22), 0.5, 4)
    a.eye(905, 140, 22, iris: hex(0xd8d8c8))
}
