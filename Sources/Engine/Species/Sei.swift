import CoreGraphics
import Foundation

extension Species {
    static let sei = SpeciesInfo(
        key: "sei", norsk: "Sei", latin: "Pollachius virens", english: "Saithe",
        sprites: [SpriteDef(name: "sei", w: 680, h: 226, paint: draw)],
        place: { scene in
            scene.addSchool(SwimmerSpec(length: 0.68, speed: 0.72, z: 6...15, alt: 1.2...4.5, amp: 0.36, wave: 7, count: 11))
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x2d3b3a), finD = hex(0x4e5d5b)
    a.fin(base: [(90, 170), (55, 185), (90, 200)], edge: [(0, 76), (25, 185), (0, 296)], root: finC, tip: finD, rays: 16)
    a.fin(base: [(805, 258), (842, 252)], edge: [(765, 300), (800, 310), (840, 288)], root: finD, tip: finD, rays: 5)
    a.fin(base: [(120, 165), (270, 118)], edge: [(135, 118), (210, 72), (280, 76)], root: finC, tip: finD, rays: 11)
    a.fin(base: [(290, 112), (455, 76)], edge: [(300, 62), (375, 24), (465, 34)], root: finC, tip: finD, rays: 12)
    a.fin(base: [(480, 72), (630, 64)], edge: [(490, 26), (570, 8), (640, 26)], root: finC, tip: finD, rays: 11)
    a.fin(base: [(135, 206), (300, 248)], edge: [(145, 250), (210, 292), (310, 298)], root: finD, tip: finD, rays: 11)
    a.fin(base: [(330, 256), (510, 282)], edge: [(345, 300), (420, 332), (520, 322)], root: finD, tip: finD, rays: 12)

    let top: [XY] = [(85, 174), (170, 156), (300, 110), (480, 72), (650, 60), (790, 74), (900, 118), (985, 176)]
    let bottom: [XY] = [(85, 196), (170, 208), (300, 240), (480, 276), (650, 286), (790, 276), (900, 236), (985, 188)]
    let back = hex(0x263736), side = hex(0x75878a), belly = hex(0xe1e7e2)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.40)
        // Dark greenish, almost-black dorsal ridge with a crisp edge to the silver flank.
        c = mix(c, hex(0x151f1e), (1 - smooth(0.0, 0.15, v)) * 0.85)
        c = mix(c, hex(0x2a3e34), (1 - smooth(0.10, 0.40, v)) * 0.40)
        // Smooth, low-contrast green-grey tone variation over the back (no discrete spots).
        let dorsal = 1 - smooth(0.26, 0.46, v)
        let tone = clamp01(artNoise.fbm(x * 0.03, y * 0.05, 3) - 0.5)
        c *= 1 - tone * dorsal * 0.14
        // Muted silvery flank sheen, strongest just below the midline.
        let shine = pow(clamp01(1 - abs(v - 0.58) * 3.2), 3)
        c += C3(0.12, 0.14, 0.13) * shine * (0.6 + 0.4 * artNoise.value(x * 0.012, 2.3))
        // Conspicuous, near-straight pale lateral line: the saithe ID mark.
        let llY = 0.355 - 0.03 * t
        let ll = clamp01(1 - abs(v - llY) * 92)
        c = mix(c, hex(0xeef3ee), ll * 0.55)
        // Thin shadow hugging the underside of the lateral line for relief.
        let shad = clamp01(1 - abs(v - (llY + 0.028)) * 150)
        c = mix(c, c * 0.84, shad * 0.35)
        // Scales: present on the flank, fading out on back and belly.
        c *= 1 - scales(x, y, size: 11) * 0.065 * smooth(0.14, 0.44, v) * (1 - smooth(0.74, 0.95, v))
        // Fine silvery horizontal striations along the flank.
        let striae = pow(clamp01(1 - abs(v - 0.62) * 2.2), 2) * (artNoise.value(x * 0.05, 6.1) - 0.5)
        c += C3(0.05, 0.055, 0.05) * Float(striae)
        return rgba(c * roundLight(v))
    }
    a.fin(base: [(760, 170), (760, 215)], edge: [(675, 170), (640, 208), (680, 248)], root: finC, tip: finD, rays: 9)
    gill(a, 790, 92, 256)
    // Gill-cover (operculum) margin curving down behind the cheek.
    a.line([(838, 96), (826, 170), (842, 244)], hex(0x16201f), 0.35, 3.5)
    a.line([(844, 102), (833, 168), (848, 236)], hex(0xd8e0da), 0.12, 2)
    // Soft cheek shading on the head.
    a.softDot(888, 176, 70, hex(0x25332f), 0.22, sy: 1.1)
    // Small pointed snout with a slightly projecting lower jaw.
    a.line([(985, 184), (948, 197), (905, 196)], hex(0x101817), 0.85, 4)
    a.line([(986, 190), (955, 205), (918, 206)], hex(0x0d1413), 0.5, 3)
    a.fill([(982, 186), (998, 193), (980, 200)], hex(0x394845), 0.7)
    a.eye(902, 142, 20, iris: hex(0xb9c4b6))
}
