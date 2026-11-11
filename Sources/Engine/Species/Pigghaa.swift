import CoreGraphics
import Foundation

extension Species {
    static let pigghaa = SpeciesInfo(
        key: "pigghaa", norsk: "Pigghå", latin: "Squalus acanthias", english: "Spiny dogfish",
        sprites: [SpriteDef(name: "pigghaa", w: 720, h: 230, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.95, speed: 0.55, z: 5...15, alt: 0.9...3.2, amp: 0.45, wave: 7.5, count: 2))
        })
}

private func draw(_ a: Art) {
    let c1 = hex(0x4f5b62)
    a.fill([(92, 148), (10, 40), (8, 66), (28, 150), (0, 240), (60, 186), (92, 174)], c1, 1)
    a.fill([(340, 92), (372, 34), (392, 30), (416, 82)], c1)
    a.line([(412, 84), (396, 26)], hex(0xd8dcd6), 1, 5, smooth: false)
    a.fill([(632, 72), (665, 16), (688, 10), (720, 62)], c1)
    a.line([(716, 64), (698, 4)], hex(0xd8dcd6), 1, 5.5, smooth: false)
    let top: [XY] = [(85, 150), (200, 122), (360, 92), (520, 74), (690, 60), (820, 70), (920, 108), (995, 162)]
    let bottom: [XY] = [(85, 172), (200, 186), (360, 214), (520, 232), (690, 238), (820, 226), (920, 198), (995, 172)]
    let back = hex(0x47535a), side = hex(0x6e7a7f), belly = hex(0xe5e8e0)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.56)
        let vis = 1 - smooth(0.46, 0.60, v)
        c = mix(c, hex(0xdfe5e2), spots(x, y, cell: 40, radius: 7.5, keep: 0.5) * vis)
        c *= 0.97 + 0.06 * artNoise.fbm(x * 0.14, y * 0.14, 2)
        return rgba(c * roundLight(v))
    }
    a.fill([(690, 214), (610, 300), (668, 306), (748, 228)], c1, 0.98)
    a.fill([(300, 208), (240, 258), (290, 258), (356, 216)], c1, 0.98)
    for i in 0..<5 {
        let x = 782 - Double(i) * 13
        a.line([(x, 150 + Double(i) * 2), (x - 6, 190)], hex(0x202529), 0.75, 3)
    }
    a.line([(958, 180), (920, 194), (890, 192)], hex(0x20262a), 0.85, 4)
    a.eye(888, 128, 14, iris: hex(0x8db1a0))
}
