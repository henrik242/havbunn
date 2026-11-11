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

/// Whiting: a slender gadoid, silvery flanks under a sandy-grey back, three dorsal fins and two
/// anal fins (cod-family spacing), a pale curved lateral line, a slightly protruding upper jaw,
/// and the diagnostic dark smudge at the upper base of the pectoral fin.
private func draw(_ a: Art) {
    let finC = hex(0x5e5b46), finD = hex(0x8c8970)
    // Caudal (near-truncate), three dorsals and two anals, all behind the body.
    a.fin(base: [(90, 172), (58, 184), (90, 196)], edge: [(2, 96), (28, 184), (2, 272)], root: finC, tip: finD, alpha: 0.78, rays: 14)
    a.fin(base: [(150, 160), (300, 116)], edge: [(160, 118), (230, 80), (310, 84)], root: finC, tip: finD, alpha: 0.74, rays: 10)
    a.fin(base: [(320, 110), (480, 78)], edge: [(330, 64), (402, 34), (490, 46)], root: finC, tip: finD, alpha: 0.74, rays: 11)
    a.fin(base: [(500, 74), (648, 66)], edge: [(510, 34), (582, 20), (654, 36)], root: finC, tip: finD, alpha: 0.74, rays: 10)
    a.fin(base: [(150, 202), (318, 244)], edge: [(160, 242), (232, 282), (328, 288)], root: finC, tip: finD, alpha: 0.7, rays: 10)
    a.fin(base: [(342, 248), (512, 266)], edge: [(354, 288), (432, 314), (520, 304)], root: finC, tip: finD, alpha: 0.7, rays: 11)
    let top: [XY] = [(85, 170), (170, 150), (300, 108), (480, 74), (650, 64), (790, 76), (900, 116), (985, 170)]
    let bottom: [XY] = [(85, 190), (170, 200), (300, 230), (480, 262), (650, 270), (790, 262), (900, 232), (985, 186)]
    let back = hex(0x938b6a), side = hex(0xd6d7cd), belly = hex(0xf5f5ef)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.42)
        // Cool silvery sheen along the mid-flank (a highlight, not a white blowout).
        c += C3(0.07, 0.10, 0.13) * pow(clamp01(1 - abs(v - 0.5) * 3.0), 2)
        // Subtle greenish-grey dorsal mottling, strongest on the back.
        let dorsal = 1 - smooth(0.14, 0.42, v)
        let marble = smooth(0.52, 0.8, artNoise.fbm(x * 0.045, y * 0.06, 3))
        c = mix(c, hex(0x7c7a5d), marble * dorsal * 0.18)
        // Fine scaling.
        c *= 1 - scales(x, y, size: 15) * 0.05
        return rgba(c * (0.74 + 0.32 * roundLight(v)))
    }
    // Pale, gently arched lateral line with a faint shaded under-edge.
    let llPts: [XY] = [(150, 173), (300, 159), (480, 150), (640, 144), (760, 143), (852, 151), (905, 164)]
    a.line(llPts, hex(0x8c8d80), 0.3, 4.5)
    a.line(llPts, hex(0xf0f1ea), 0.5, 2.0)
    // Pectoral fin, then the diagnostic dark smudge at its upper base.
    a.fin(base: [(768, 170), (770, 206)], edge: [(688, 172), (662, 200), (700, 234)], root: finC, tip: finD, alpha: 0.64, rays: 8)
    a.softDot(768, 176, 18, hex(0x20201a), 0.5)
    a.disc(767, 175, 8, hex(0x17170f), 0.85)
    // Gill cover edge and a faint cheek shade.
    a.line([(858, 118), (876, 170), (862, 220)], hex(0x3a3828), 0.24, 3)
    a.softDot(878, 190, 34, hex(0x8f8c6e), 0.12)
    gill(a, 806, 100, 250, bow: 26, 0.16)
    // Terminal mouth with a slightly protruding upper jaw.
    a.line([(910, 178), (958, 180), (990, 176)], hex(0x242318), 0.42, 3)
    a.line([(986, 184), (948, 191), (912, 190)], hex(0x242318), 0.5, 3.5)
    a.eye(905, 140, 21, iris: hex(0xd4d5c6))
}
