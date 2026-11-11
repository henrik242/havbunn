import CoreGraphics
import Foundation

extension Species {
    static let rodspette = SpeciesInfo(
        key: "rodspette", norsk: "Rødspette", latin: "Pleuronectes platessa", english: "European plaice",
        sprites: [SpriteDef(name: "rodspette", w: 420, h: 168, paint: draw)],
        place: { scene in
            scene.addRester(ResterSpec(length: 0.32, mode: 3, amp: 0.05, glide: 0.4, rest: (15, 60), z: 3.6...7, rock: 0...0.08, lift: 0))
        })
}

/// Plaice seen from above at a low angle, both eyes on the upper side.
private func draw(_ a: Art) {
    let fringe = hex(0x7d6a42)
    a.fin(base: [(140, 170), (120, 195), (140, 220)], edge: [(10, 120), (0, 195), (10, 270)], root: fringe, tip: hex(0xa68f5d), rays: 12)
    a.fin(base: [(150, 165), (780, 60)], edge: [(140, 112), (450, 8), (790, 22)], root: fringe, tip: hex(0xa68f5d), rays: 40)
    a.fin(base: [(150, 225), (780, 345)], edge: [(140, 280), (450, 395), (790, 385)], root: fringe, tip: hex(0xa68f5d), rays: 40)
    let top: [XY] = [(135, 170), (260, 120), (450, 70), (640, 52), (820, 70), (930, 120), (985, 190)]
    let bottom: [XY] = [(135, 222), (260, 268), (450, 325), (640, 350), (820, 330), (930, 276), (985, 210)]
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = mix(hex(0x7f6c44), hex(0x93804f), v)
        c *= 0.86 + 0.28 * artNoise.fbm(x * 0.03, y * 0.03, 3)
        let o = spots(x, y, cell: 62, radius: 15, keep: 0.75)
        c = mix(c, hex(0xe8681f), o)
        let ll = clamp01(1 - abs(v - 0.5 - 0.02 * sin(x * 0.012)) * 90)
        c = mix(c, hex(0x54462a), ll * 0.6)
        return rgba(c * (0.8 + 0.25 * roundLight(v)))
    }
    for (x, y) in [(600.0, 150.0), (400, 260), (720, 280), (320, 140)] { a.softDot(x, y, 22, hex(0xef6f22), 0.8) }
    a.line([(792, 118), (760, 190), (786, 298)], hex(0x4a3b21), 0.45, 5)
    a.line([(985, 198), (950, 228), (905, 236)], hex(0x2e2412), 0.85, 5)
    a.eye(895, 136, 15, iris: hex(0xc2a24c))
    a.eye(905, 182, 14, iris: hex(0xc2a24c))
}
