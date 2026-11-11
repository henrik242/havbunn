import CoreGraphics
import Foundation

extension Species {
    static let torsk = SpeciesInfo(
        key: "torsk", norsk: "Torsk", latin: "Gadus morhua", english: "Atlantic cod",
        sprites: [SpriteDef(name: "torsk", w: 720, h: 306, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.75, speed: 0.26, z: 4.2...11, alt: 0.4...1.8, amp: 0.30, wave: 6.5, count: 3, hover: 0.6))
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x6a6240), finD = hex(0x8f8660), finMarg = hex(0x514a2e)
    // Caudal fin: broad, slightly truncate with a shallow fork.
    a.fin(base: [(115, 195), (70, 215), (115, 235)], edge: [(10, 108), (0, 170), (16, 215), (0, 260), (10, 324)], root: finC, tip: finD, rays: 20)
    // Three rounded, soft-rayed dorsal fins (first nearest the head on the right).
    a.fin(base: [(466, 90), (545, 82), (624, 78)], edge: [(478, 46), (520, 26), (562, 20), (602, 28), (628, 44)], root: finC, tip: finD, rays: 15)
    a.fin(base: [(283, 140), (368, 114), (452, 95)], edge: [(292, 92), (332, 58), (372, 44), (418, 48), (458, 62)], root: finC, tip: finD, rays: 15)
    a.fin(base: [(130, 188), (200, 168), (270, 148)], edge: [(136, 140), (172, 108), (210, 96), (250, 104), (278, 120)], root: finC, tip: finD, rays: 13)
    // Two rounded anal fins on the belly.
    a.fin(base: [(430, 336), (512, 346), (590, 348)], edge: [(446, 392), (492, 416), (540, 418), (578, 400), (596, 382)], root: finC, tip: finD, rays: 14)
    a.fin(base: [(145, 242), (218, 268), (290, 290)], edge: [(152, 292), (196, 326), (240, 338), (280, 330), (296, 314)], root: finC, tip: finD, rays: 12)
    // Thoracic pelvic fin, set well forward under the throat, with a trailing first ray.
    a.fin(base: [(805, 328), (845, 318)], edge: [(758, 398), (792, 414), (838, 386), (848, 352)], root: finD, tip: finD, rays: 8)
    a.line([(844, 320), (812, 372), (784, 408)], finMarg, 0.5, 4)

    let top: [XY] = [(100, 203), (170, 188), (300, 132), (480, 88), (650, 75), (790, 94), (900, 150), (972, 212)]
    let bottom: [XY] = [(100, 228), (170, 240), (300, 285), (480, 332), (650, 350), (790, 340), (900, 298), (972, 228)]
    let back = hex(0x595733), side = hex(0x9c9462), belly = hex(0xe9e3cd)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.46)
        let vis = 1 - smooth(0.50, 0.78, v)      // detail fades toward the pale belly
        // Fine olive-brown mottling over the back, much softer than hard blotches.
        let mottle = smooth(0.50, 0.72, artNoise.fbm(x * 0.030, y * 0.044, 4))
        c = mix(c, c * 0.72, mottle * vis * 0.85)
        let mottle2 = smooth(0.60, 0.82, artNoise.fbm(x * 0.012 + 11, y * 0.016 + 4, 3))
        c = mix(c, mix(c, hex(0x4a4626), 0.5), mottle2 * vis * 0.4)
        // Dense small spots, as cod wear: fine warm-brown stipple plus sparser larger flecks.
        let sp1 = spots(x, y, cell: 15, radius: 3.5, keep: 0.82, seed: 1)
        c = mix(c, hex(0x463a1f), sp1 * vis * 0.78)
        let sp2 = spots(x, y, cell: 31, radius: 5.4, keep: 0.52, seed: 7)
        c = mix(c, hex(0x39301a), sp2 * vis * 0.6)
        // Darker olive dorsal ridge.
        c = mix(c, c * 0.82, (1 - smooth(0.02, 0.20, v)) * 0.55)
        // Pale lateral line: arches high just behind the head, then eases down to the tail.
        let llY = 0.30 + 0.16 * smooth(0.28, 0.96, 1 - t) + 0.05 * smooth(0.72, 0.9, t) * (1 - smooth(0.9, 1, t))
        let ll = clamp01(1 - abs(v - llY) * 60)
        c = mix(c, hex(0xece5c8), ll * 0.5 * (0.5 + 0.5 * vis))
        c = c * (1 - scales(x, y, size: 13) * 0.055)
        return rgba(c * roundLight(v))
    }
    // Rounded, soft pectoral paddle set just behind the gill cover.
    a.fin(base: [(772, 212), (772, 268)], edge: [(694, 218), (656, 250), (650, 288), (696, 312)], root: finC * 1.1, tip: finD, rays: 10)
    gill(a, 802, 118, 310)
    // Operculum: soft curved rear edge of the gill cover, faint pre-opercular fold.
    a.line([(838, 118), (862, 210), (848, 300)], hex(0x3f3a24), 0.28, 5)
    a.softDot(820, 210, 120, hex(0x2d2817), 0.12, sy: 1.4)
    a.line([(906, 282), (901, 306), (896, 326)], hex(0x817652), 0.45, 4)        // gill-membrane fold, tucked under the operculum
    // Blunt head: slightly overhanging upper jaw with a subterminal mouth.
    a.line([(974, 222), (935, 240), (892, 240)], hex(0x2a2415), 0.8, 5.5)      // mouth / jaw line
    a.line([(975, 214), (948, 222), (926, 228)], hex(0x6d6744), 0.5, 3)        // upper-lip highlight edge
    a.fill([(974, 218), (986, 230), (968, 236), (960, 228)], hex(0x3a3320), 0.5) // overhanging snout tip
    a.softDot(930, 164, 15, hex(0x2a2516), 0.4)                                 // nostril ahead of the eye
    // Single prominent chin barbel hanging from the lower jaw.
    a.line([(952, 250), (945, 286), (930, 312)], hex(0x4c452c), 0.85, 4.5)
    a.disc(929, 314, 5, hex(0x5a5236), 0.8)
    a.eye(890, 172, 21)
}
