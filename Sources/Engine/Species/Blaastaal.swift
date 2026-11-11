import CoreGraphics
import Foundation

extension Species {
    static let blaastaal = SpeciesInfo(
        key: "blaastaal", norsk: "Blåstål", latin: "Labrus mixtus", english: "Cuckoo wrasse",
        sprites: [SpriteDef(name: "blaastaal", w: 400, h: 192, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.26, speed: 0.26, z: 3.8...9, alt: 0.3...1.5, amp: 0.24, wave: 6, count: 2, hover: 0.5))
        })
}

private func draw(_ a: Art) {
    // Breeding male: muted steel/periwinkle blue head and back over warm, restrained orange.
    let orange = hex(0xc0772f), deep = hex(0x9c4c22), blue = hex(0x516890), bright = hex(0x8294bc)
    let lineBlue = hex(0x93a4c9)
    FishArt.wrasseBody(a, shader: { t, v, x, y in
        var c = v < 0.6 ? mix(deep, orange, smooth(0, 0.45, v)) : mix(orange, hex(0xe6bb6a), smooth(0.6, 1, v))
        let wav = artNoise.fbm(x * 0.012, y * 0.02, 2) * 0.08
        // Blue head and spreading back wash, typical of the breeding male.
        let head = smooth(0.60, 0.84, t + wav * 2)
        c = mix(c, blue, head * 0.95)
        // Wavy blue lines running the length of the flank.
        let backline = clamp01(1 - abs(v - 0.19 - wav) * 15) * smooth(0.08, 0.26, t)
        let midline = clamp01(1 - abs(v - 0.52 + wav) * 20) * smooth(0.18, 0.42, t)
        let lowline = clamp01(1 - abs(v - 0.80 + wav * 0.7) * 22) * smooth(0.14, 0.40, t) * (1 - head)
        c = mix(c, blue, max(backline, max(midline, lowline)) * 0.9)
        let glow = clamp01(1 - abs(v - 0.19 - wav) * 30) * smooth(0.08, 0.26, t)
        c = mix(c, bright, glow * 0.7)
        c *= 1 - scales(x, y, size: 22) * 0.10
        return rgba(c * roundLight(v))
    }, finC: hex(0xcf7a2c), finD: hex(0x5e79a6))
    a.fin(base: [(705, 256), (705, 320)], edge: [(590, 262), (560, 310), (605, 372)], root: hex(0xd98c38), tip: hex(0x5a76a6), rays: 10)
    // Blue wavy lines radiating across the head and snout.
    a.line([(980, 250), (938, 246), (892, 238)], lineBlue, 0.75, 5)
    a.line([(978, 266), (934, 272), (888, 280)], lineBlue, 0.75, 5)
    a.line([(964, 300), (922, 312), (882, 320)], lineBlue, 0.65, 4.5)
    a.line([(906, 158), (866, 176), (842, 200)], lineBlue, 0.6, 4)
    a.line([(948, 224), (902, 214), (856, 212)], lineBlue, 0.55, 4)
    gill(a, 792, 140, 372, bow: 40, 0.3)
    a.line([(978, 262), (945, 272), (905, 270)], hex(0x16263c), 0.9, 4)
    a.eye(872, 186, 21, iris: hex(0xe6bc52))
}
