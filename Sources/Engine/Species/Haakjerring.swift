import CoreGraphics
import Foundation

extension Species {
    static let haakjerring = SpeciesInfo(
        key: "haakjerring", norsk: "Håkjerring", latin: "Somniosus microcephalus", english: "Greenland shark",
        sprites: [SpriteDef(name: "haakjerring", w: 1024, h: 276, paint: draw)],
        place: { scene in
            // Comes up from deeper water now and then.
            scene.addRareVisitor(SwimmerSpec(length: 3.2, speed: 0.34, z: 11...16, alt: 1.5...3, amp: 0.18, wave: 5),
                                 weight: 0.25)
        })
}

private func draw(_ a: Art) {
    let c1 = hex(0x34383a)
    a.fill([(120, 122), (8, 18), (6, 40), (48, 130), (34, 190), (96, 158), (120, 146)], c1)
    a.fill([(290, 98), (320, 68), (350, 68), (366, 92)], c1)
    a.fill([(500, 80), (535, 42), (570, 42), (595, 72)], c1)
    let top: [XY] = [(110, 122), (220, 100), (400, 74), (600, 58), (760, 58), (880, 78), (955, 112), (990, 158)]
    let bottom: [XY] = [(110, 148), (220, 170), (400, 208), (600, 232), (760, 232), (880, 216), (955, 192), (990, 170)]
    let back = hex(0x2c3134), side = hex(0x484e52), belly = hex(0x6e7273)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.58)
        let m = artNoise.fbm(x * 0.028, y * 0.05, 4)
        c *= 0.84 + 0.32 * m
        c = mix(c, c * 0.72, spots(x, y, cell: 24, radius: 6, keep: 0.5) * 0.7)
        // Old scars.
        let s = clamp01(1 - abs(artNoise.fbm(x * 0.013, y * 0.04 + 8, 2) - 0.52) * 90)
        c = mix(c, hex(0x8b8f8c), s * 0.25)
        return rgba(c * roundLight(v))
    }
    a.fill([(770, 212), (700, 262), (752, 268), (818, 222)], c1)
    a.fill([(360, 202), (300, 238), (346, 240), (408, 210)], c1)
    for i in 0..<5 {
        let x = 848 - Double(i) * 9
        a.line([(x, 165 + Double(i) * 1.5), (x - 3, 186)], hex(0x15181a), 0.8, 2.2)
    }
    a.line([(990, 172), (955, 186), (925, 182)], hex(0x101314), 0.85, 3)
    a.eye(918, 124, 7, iris: hex(0x4e6470))
    // Eye parasite, Ommatokoita elongata, on most adults.
    a.line([(918, 126), (906, 134), (898, 150), (892, 158)], hex(0xd8d2b7), 0.95, 2.4)
    a.line([(918, 126), (910, 138), (906, 154)], hex(0xd8d2b7), 0.9, 2.1)
}
