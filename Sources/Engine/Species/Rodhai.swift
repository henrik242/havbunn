import CoreGraphics
import Foundation

extension Species {
    static let rodhai = SpeciesInfo(
        key: "rodhai", norsk: "Småflekket rødhai", latin: "Scyliorhinus canicula", english: "Small-spotted catshark",
        sprites: [SpriteDef(name: "rodhai", w: 640, h: 170, paint: draw)],
        place: { scene in
            // Mostly lying still, now and then a slow swim along the bottom.
            scene.addRester(ResterSpec(length: 0.6, mode: 1, amp: 0.05, glide: 0.22, rest: (25, 80), z: 4...9, rock: 0...0.3, lift: 0))
        })
}

/// Small-spotted catshark: slender, sandy brown with many small dark spots, both dorsals set
/// far back, a long low tail and a cat-like slit eye.
private func draw(_ a: Art) {
    let fin = hex(0x7e6848)
    a.fill([(84, 126), (0, 110), (6, 128), (24, 152), (84, 146)], fin, 0.95)
    a.fill([(470, 92), (498, 48), (520, 46), (546, 86)], fin)
    a.fill([(300, 106), (324, 70), (342, 68), (358, 102)], fin)
    a.fill([(360, 168), (334, 200), (380, 200), (420, 172)], fin, 0.9)
    a.fill([(560, 178), (520, 214), (580, 214), (630, 180)], fin, 0.9)
    let top: [XY] = [(60, 126), (180, 116), (380, 96), (560, 82), (720, 78), (850, 88), (940, 108), (995, 138)]
    let bottom: [XY] = [(60, 142), (180, 152), (380, 170), (560, 180), (720, 182), (850, 176), (940, 162), (995, 148)]
    let back = hex(0x8a7454), side = hex(0xb39a74), belly = hex(0xe8dcc4)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.6)
        let upper = 1 - smooth(0.55, 0.75, v)
        c = mix(c, hex(0x3a2c1c), spots(x, y, cell: 12, radius: 3.2, keep: 0.7) * upper)
        c = mix(c, hex(0xe9dfc8), spots(x, y, cell: 40, radius: 4, keep: 0.35, seed: 3) * upper * 0.7)
        return rgba(c * roundLight(v))
    }
    a.fill([(800, 160), (740, 206), (800, 210), (850, 168)], fin, 0.95)
    a.disc(905, 114, 11, hex(0xc9b060))
    a.disc(905, 114, 9, hex(0x0a0806), 1, sy: 0.25)
    a.line([(995, 146), (968, 156), (944, 154)], hex(0x2a2014), 0.45, 3)
}
