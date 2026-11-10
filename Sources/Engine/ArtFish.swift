import CoreGraphics
import Foundation

// Fish are drawn in profile, head to the right, on a 1000-unit wide cell.

private func flank(_ v: Float, back: C3, side: C3, belly: C3, split: Float = 0.42) -> C3 {
    v < split ? mix(back, side, smooth(0.04, split, v)) : mix(side, belly, smooth(split, min(0.98, split + 0.36), v))
}

private func gill(_ a: Art, _ x: Double, _ y0: Double, _ y1: Double, bow: Double = 34, _ alpha: Double = 0.2) {
    a.line([(x, y0), (x - bow, (y0 + y1) * 0.5), (x, y1)], hex(0x14100c), min(alpha, 0.22), 3)
}

enum FishArt {
    static func torsk(_ a: Art) {
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

    static func sei(_ a: Art) {
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
            // Conspicuous, near-straight pale lateral line — the saithe ID mark.
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

    /// Pollack: like saithe but bronze-olive, with a lateral line arching strongly over the
    /// pectoral and a jutting lower jaw. No barbel.
    static func lyr(_ a: Art) {
        let finC = hex(0x45432d), finD = hex(0x797048)
        // Caudal (slightly forked), three dorsals, then two anals, drawn before the body.
        a.fin(base: [(92, 172), (60, 186), (92, 200)], edge: [(0, 80), (30, 186), (0, 294)], root: finC, tip: finD, alpha: 0.82, rays: 16)
        a.fin(base: [(130, 165), (280, 122)], edge: [(140, 118), (212, 78), (290, 82)], root: finC, tip: finD, alpha: 0.78, rays: 11)
        a.fin(base: [(300, 116), (460, 82)], edge: [(310, 64), (386, 28), (470, 40)], root: finC, tip: finD, alpha: 0.78, rays: 12)
        a.fin(base: [(485, 78), (630, 70)], edge: [(495, 30), (572, 14), (640, 32)], root: finC, tip: finD, alpha: 0.78, rays: 11)
        a.fin(base: [(150, 206), (310, 246)], edge: [(160, 250), (226, 290), (320, 296)], root: finC, tip: finD, alpha: 0.72, rays: 11)
        a.fin(base: [(340, 254), (510, 278)], edge: [(355, 298), (432, 328), (520, 318)], root: finC, tip: finD, alpha: 0.72, rays: 12)
        a.fin(base: [(810, 262), (845, 258)], edge: [(770, 312), (800, 318), (840, 292)], root: finC, tip: finD, alpha: 0.72, rays: 5)
        let top: [XY] = [(85, 176), (170, 160), (300, 116), (480, 80), (650, 68), (790, 80), (900, 118), (975, 166)]
        let bottom: [XY] = [(85, 196), (170, 206), (300, 236), (480, 270), (650, 280), (790, 270), (900, 236), (985, 200)]
        let back = hex(0x474a2b), side = hex(0xa79a5e), belly = hex(0xe7e1c8)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.48)
            // Brassy sheen along the mid-flank.
            c += C3(0.06, 0.05, 0.018) * pow(clamp01(1 - abs(v - 0.56) * 2.7), 2)
            // Dorsal mottling: broken greenish-brown marbling, strongest on the back.
            let dorsal = 1 - smooth(0.24, 0.52, v)
            let marble = smooth(0.52, 0.72, artNoise.fbm(x * 0.032, y * 0.05, 3))
            c = mix(c, hex(0x3b4023), marble * dorsal * 0.46)
            let fleck = spots(x, y, cell: 16, radius: 3.9, keep: 0.52, seed: 5)
            c = mix(c, hex(0x33371d), fleck * dorsal * 0.36)
            c *= 1 - scales(x, y, size: 11) * 0.06
            _ = t
            return rgba(c * roundLight(v))
        }
        // Lateral line: dark, arching high over the pectoral then running to the tail.
        let llPts: [XY] = [(128, 181), (280, 171), (440, 158), (600, 142),
                           (720, 128), (790, 120), (842, 124), (886, 140), (912, 154)]
        a.line(llPts, hex(0x262514), 0.3, 5)
        a.line(llPts, hex(0x201f10), 0.62, 2.6)
        a.fin(base: [(760, 172), (760, 214)], edge: [(675, 176), (645, 210), (685, 248)], root: finC, tip: finD, alpha: 0.72, rays: 9)
        gill(a, 795, 96, 252, bow: 30, 0.2)
        // Gill cover (operculum) edge and a faint cheek shade.
        a.line([(858, 114), (877, 170), (863, 224)], hex(0x2b2816), 0.22, 3)
        a.softDot(878, 198, 38, hex(0x7d7446), 0.14)
        // Terminal mouth with a jutting lower jaw.
        a.line([(905, 199), (952, 200), (984, 193)], hex(0x22200f), 0.52, 3.5)
        a.fill([(970, 200), (997, 192), (995, 203), (968, 210)], hex(0xc0b588))
        a.line([(975, 168), (946, 180), (912, 180)], hex(0x22200f), 0.36, 3)
        a.eye(905, 146, 19, iris: hex(0x8f8452))
    }

    static func sild(_ a: Art) {
        let finC = hex(0x51676f), finD = hex(0x90a3a7)
        // Deeply forked tail, single mid-body dorsal, small pelvic and anal fins.
        a.fin(base: [(85, 142), (55, 160), (85, 178)], edge: [(0, 42), (42, 160), (0, 278)], root: finC, tip: finD, rays: 12)
        a.fin(base: [(450, 80), (560, 75)], edge: [(465, 20), (510, 14), (575, 66)], root: finC, tip: finD, rays: 8)
        a.fin(base: [(205, 218), (320, 240)], edge: [(215, 262), (270, 282), (330, 258)], root: finD, tip: finD, rays: 7)
        a.fin(base: [(490, 262), (545, 266)], edge: [(470, 300), (510, 322), (548, 292)], root: finD, tip: finD, rays: 6)

        let top: [XY] = [(80, 150), (180, 126), (350, 90), (540, 70), (720, 72), (860, 96), (985, 150)]
        let bottom: [XY] = [(80, 172), (180, 192), (350, 236), (540, 270), (720, 268), (860, 226), (985, 166)]
        let back = hex(0x2b5159), ridge = hex(0x15313a), side = hex(0xb4cace), belly = hex(0xf1f6f4)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.30)
            // Crisp dark blue-green dorsal cap for a sharp countershade line.
            c = mix(c, ridge, clamp01(1 - v * 7) * 0.85)
            // Metallic blue-green to violet iridescence in a band under the back.
            let irid = pow(clamp01(1 - abs(v - 0.32) * 4.0), 2) * smooth(0.05, 0.2, t)
            let hue = artNoise.value(x * 0.009, 5.3)
            c += mix(C3(-0.03, 0.05, 0.01), C3(0.05, -0.01, 0.06), hue) * irid
            // Broad cool metallic sheen along the silver flank.
            let sheen = pow(clamp01(1 - abs(v - 0.5) * 2.6), 3)
            c += C3(0.10, 0.12, 0.12) * sheen
            // Fine along-body glint, softened so it stays legible when small.
            let glint = pow(artNoise.value(x * 0.009, 3.1), 3) * 0.07
            c += C3(glint, glint * 1.08, glint * 1.16)
            // Faint large scale rows, strongest on the upper silver flank, fading at belly and back.
            let scaleMask = smooth(0.14, 0.34, v) * (1 - smooth(0.66, 0.9, v))
            c *= 1 - scales(x, y, size: 30) * 0.075 * scaleMask
            _ = t
            return rgba(c * (0.74 + 0.32 * roundLight(v)))
        }
        // Pectoral fin, low behind the gill.
        a.fin(base: [(770, 214), (770, 238)], edge: [(700, 240), (680, 262), (712, 268)], root: finC, tip: finD, alpha: 0.6, rays: 5)
        // Keeled, light-catching belly edge.
        a.line([(150, 188), (350, 232), (540, 266), (720, 263), (868, 223)], hex(0xf8fbf9), 0.4, 3)
        // Silvery gill cover: soft highlight on the cheek, then the operculum rim and gill slit.
        a.softDot(852, 170, 48, hex(0xe1edec), 0.32, sy: 1.1)
        a.line([(820, 96), (792, 150), (812, 232)], hex(0xcddddc), 0.4, 3)
        a.line([(812, 96), (786, 150), (806, 236)], hex(0x203038), 0.3, 4)
        gill(a, 805, 112, 228, bow: 22, 0.3)
        a.softDot(800, 210, 26, hex(0x8f5a60), 0.22, sy: 1.1)
        a.line([(985, 157), (948, 186), (908, 182)], hex(0x101820), 0.7, 6)
        a.eye(905, 138, 25, iris: hex(0xc3d0cf))
    }

    static func makrell(_ a: Art) {
        let finC = hex(0x274751), finD = hex(0x51757a)
        // Deeply forked caudal fin on a slender keeled peduncle.
        a.fin(base: [(74, 170), (54, 180), (74, 190)], edge: [(2, 38), (36, 180), (2, 322)], root: finC, tip: finD, rays: 15)
        // Two well-separated dorsal fins.
        a.fin(base: [(560, 100), (690, 92)], edge: [(575, 36), (628, 16), (700, 70)], root: finC, tip: finD, alpha: 0.82, rays: 10)
        a.fin(base: [(300, 124), (432, 106)], edge: [(310, 56), (356, 38), (440, 90)], root: finC, tip: finD, alpha: 0.85, rays: 10)
        // Pelvic and anal fins below.
        a.fin(base: [(300, 240), (432, 254)], edge: [(310, 298), (356, 312), (442, 262)], root: finD, tip: finD, alpha: 0.72, rays: 8)
        a.fin(base: [(636, 262), (700, 262)], edge: [(600, 302), (648, 314), (700, 288)], root: finD, tip: finD, alpha: 0.72, rays: 6)
        let top: [XY] = [(72, 172), (150, 164), (300, 124), (470, 96), (650, 86), (800, 102), (910, 136), (990, 178)]
        let bottom: [XY] = [(72, 188), (150, 198), (300, 236), (470, 262), (650, 270), (800, 256), (910, 226), (990, 186)]
        let back = hex(0x1d6f7a), mid = hex(0xaad0c3), belly = hex(0xf2f6ee)
        let barC = hex(0x14323b), iridG = hex(0x2f8a72), iridB = hex(0x2a6f93)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: mid, belly: belly, split: 0.46)
            // Metallic blue-green iridescence shimmering across the back.
            let back01 = 1 - smooth(0.30, 0.52, v)
            let shimmer = artNoise.fbm(x * 0.018 + v * 3, y * 0.012, 3)
            c = mix(c, iridG, clamp01(shimmer - 0.52) * 0.5 * back01)
            c = mix(c, iridB, clamp01(0.48 - shimmer) * 0.45 * back01)
            // Dark wavy tiger bars: crisp, numerous, never crossing the midline.
            let wob = (artNoise.fbm(x * 0.013, y * 0.022, 2) - 0.5) * 58
            let band = sin((x + y * 0.66 + wob) * 0.112)
            let reach = 1 - smooth(0.30, 0.50, v + (artNoise.value(x * 0.03, 8) - 0.5) * 0.12)
            let onBody = smooth(0.07, 0.2, t) * (1 - smooth(0.9, 0.99, t))
            let stripe = smooth(0.28, 0.60, band) * reach * onBody
            // Faint green-gold sheen on the leading edge of each bar.
            let edge = smooth(0.1, 0.34, band) * (1 - smooth(0.34, 0.5, band)) * reach * onBody
            c = mix(c, iridG * 1.12, edge * 0.3)
            c = mix(c, barC, stripe * 0.9)
            c += C3(0.05, 0.10, 0.09) * pow(clamp01(1 - abs(v - 0.3) * 4), 2)
            c += C3(0.12, 0.10, 0.14) * pow(clamp01(1 - abs(v - 0.62) * 5), 3)
            return rgba(c * (0.68 + 0.38 * roundLight(v)))
        }
        // Row of small finlets between the rear fins and the tail.
        for i in 0..<5 {
            let x = 112 + Double(i) * 40, drop = Double(i) * 5
            let ty = 162.0 - drop
            a.fill([(x, ty), (x + 11, ty - 22), (x + 22, ty - 2), (x + 14, ty + 2)], finC, 0.95)
            let by = 200.0 + drop
            a.fill([(x, by), (x + 11, by + 22), (x + 22, by + 2), (x + 14, by - 2)], finC, 0.95)
        }
        // Keel ridge on the slender caudal peduncle.
        a.line([(88, 181), (124, 181), (152, 180)], hex(0x1a343d), 0.35, 2.5)
        // Low swept-back pectoral fin, set just behind the gill, pointing down and back.
        a.fin(base: [(802, 172), (800, 196)], edge: [(720, 206), (698, 214), (722, 210)], root: finC, tip: finD, alpha: 0.5, rays: 6)
        gill(a, 818, 108, 246, bow: 30, 0.4)
        a.line([(990, 182), (940, 200), (905, 196)], hex(0x101820), 0.8, 5)
        a.eye(912, 150, 20, iris: hex(0xd5d9c4))
    }

    static func laks(_ a: Art) {
        let finC = hex(0x3c4a52), finD = hex(0x71808a)
        a.fin(base: [(88, 162), (60, 182), (88, 202)], edge: [(0, 60), (28, 182), (0, 304)], root: finC, tip: finD, rays: 16)
        a.fin(base: [(450, 82), (570, 76)], edge: [(455, 26), (495, 10), (585, 66)], root: finC, tip: finD, rays: 10)
        // Small fleshy adipose fin on the ridge between dorsal and tail; a low flap leaning
        // toward the tail, with its base hidden by the body.
        a.fill([(236, 158), (250, 124), (278, 113), (298, 122), (304, 158)], finC, 0.95)
        a.fill([(252, 134), (266, 120), (284, 118)], finD, 0.35)
        a.fin(base: [(235, 228), (330, 248)], edge: [(240, 276), (285, 300), (345, 262)], root: finD, tip: finD, rays: 8)
        a.fin(base: [(490, 268), (560, 276)], edge: [(480, 318), (525, 334), (568, 298)], root: finD, tip: finD, rays: 7)
        let top: [XY] = [(82, 170), (170, 152), (300, 112), (480, 78), (650, 70), (790, 86), (900, 124), (985, 178)]
        let bottom: [XY] = [(82, 194), (170, 208), (300, 236), (480, 268), (650, 276), (790, 262), (900, 226), (985, 188)]
        let back = hex(0x3d5159), green = hex(0x44584c), side = hex(0xbfcdcf), belly = hex(0xf7f8f3)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.38)
            // Greenish-steel sheen on the dorsal ridge, silver highlight along the flank.
            c = mix(c, green, (1 - smooth(0.0, 0.26, v)) * 0.32)
            c += C3(0.12, 0.10, 0.13) * pow(clamp01(1 - abs(v - 0.55) * 3.8), 3)
            // Lateral line: a faint silver seam running nearly straight down the flank.
            let llY: Float = 0.46 - 0.03 * smooth(0.6, 0.95, t)
            let ll = clamp01(1 - abs(v - llY) * 46)
            c = mix(c, side * 1.08, ll * 0.3)
            c = mix(c, c * 0.84, clamp01(1 - abs(v - llY - 0.028) * 80) * 0.6)
            // Fine dark freckling above the lateral line, thinning toward tail and head.
            let aboveLL = 1 - smooth(0.30, 0.46, v)
            let span = smooth(0.24, 0.32, t) * (1 - smooth(0.82, 0.92, t))
            c = mix(c, hex(0x141a1d), spots(x, y, cell: 30, radius: 4.4, keep: 0.34) * aboveLL * span * 0.9)
            c *= 1 - scales(x, y, size: 12) * 0.07
            return rgba(c * (0.7 + 0.36 * roundLight(v)))
        }
        // Characteristic black X / cross-shaped spots, mostly above the lateral line and on the gill cover.
        let spotC = hex(0x15191c)
        func xspot(_ cx: Double, _ cy: Double, _ r: Double, _ a2: Double = 0.82) {
            a.line([(cx - r, cy - r * 0.8), (cx + r, cy + r * 0.8)], spotC, a2, r * 0.6)
            a.line([(cx - r, cy + r * 0.8), (cx + r, cy - r * 0.8)], spotC, a2, r * 0.6)
        }
        func dot(_ cx: Double, _ cy: Double, _ r: Double, _ a2: Double = 0.82) {
            a.disc(cx, cy, r, spotC, a2)
            a.disc(cx + r * 0.28, cy + r * 0.2, r * 0.55, spotC, a2 * 0.6)
        }
        xspot(372, 128, 8.5); dot(420, 150, 5.2); xspot(466, 118, 7.5)
        dot(508, 142, 5.6); xspot(556, 112, 8.0); dot(598, 138, 4.8)
        xspot(640, 122, 7.8); dot(688, 150, 5.4); xspot(712, 118, 7.2)
        dot(752, 140, 5.0); xspot(792, 126, 6.8)
        // A few on the gill cover, smaller.
        dot(846, 164, 4.6); xspot(872, 148, 6.0); dot(892, 182, 4.2); dot(864, 196, 3.8)
        a.fin(base: [(758, 178), (758, 215)], edge: [(675, 196), (650, 226), (690, 262)], root: finC, tip: finD, rays: 8)
        gill(a, 802, 98, 246)
        // Operculum (gill-cover) margin for a crisper head.
        a.line([(852, 112), (838, 180), (858, 238)], hex(0x20262a), 0.3, 3)
        a.line([(985, 186), (935, 204), (884, 198)], hex(0x181a1e), 0.85, 5)
        a.eye(905, 146, 17, iris: hex(0xd7cda9))
    }

    static func uer(_ a: Art) {
        let finC = hex(0xb33a24), finD = hex(0xe5734d)
        a.fin(base: [(96, 240), (70, 270), (96, 300)], edge: [(0, 165), (10, 270), (0, 375)], root: finC, tip: finD, rays: 14)
        var spiny: [XY] = [], base: [XY] = []
        for i in 0...12 {
            let t = Double(i) / 12
            base.append((300 + t * 330, 112 - 56 * sin(t * 2.4) + 2))
            spiny.append((295 + t * 330, (i % 2 == 0 ? 8 : 34) + 22 * abs(t - 0.5)))
        }
        a.fin(base: [(140, 196), (290, 128)], edge: [(145, 148), (210, 66), (290, 62)], root: finC, tip: finD, rays: 9)
        a.fill(base + spiny.reversed(), finC, 0.9, raw: true)
        for i in 0...12 { a.line([base[i], spiny[i]], hex(0xf1c7a0), 0.9, 3.4, smooth: false) }
        a.fin(base: [(200, 362), (330, 402)], edge: [(205, 420), (270, 475), (340, 462)], root: finC, tip: finD, rays: 9)

        let top: [XY] = [(90, 238), (170, 190), (300, 118), (470, 62), (620, 56), (780, 94), (880, 170), (960, 268)]
        let bottom: [XY] = [(90, 302), (170, 330), (300, 388), (470, 438), (620, 448), (780, 428), (880, 370), (960, 300)]
        let back = hex(0xb23a22), side = hex(0xe05a35), belly = hex(0xf7c3a6)
        a.body(top: top, bottom: bottom) { _, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.52)
            let m = smooth(0.48, 0.68, artNoise.fbm(x * 0.018, y * 0.022 + 4, 3)) * (1 - smooth(0.5, 0.78, v))
            c = mix(c, hex(0x651a12), m * 0.65)
            c *= 1 - scales(x, y, size: 20) * 0.13
            return rgba(c * roundLight(v))
        }
        a.fin(base: [(650, 270), (650, 345)], edge: [(530, 270), (490, 340), (545, 410)], root: finC, tip: finD, rays: 12)
        a.fin(base: [(640, 412), (700, 412)], edge: [(590, 470), (640, 495), (700, 455)], root: finC, tip: finD, rays: 6)
        gill(a, 738, 150, 390, bow: 44, 0.42)
        for i in 0..<4 {
            let dx = Double(i) * 18
            a.line([(748 - dx, 212 + dx), (722 - dx, 200 + dx)], hex(0x54160e), 0.7, 5)
        }
        a.line([(960, 288), (895, 316), (838, 306)], hex(0x4a130c), 0.9, 6)
        a.eye(840, 196, 38, iris: hex(0xe8b34e))
    }

    private static func wrasseBody(_ a: Art, shader: @escaping (Float, Float, Float, Float) -> RGBA, finC: C3, finD: C3) {
        a.fin(base: [(100, 200), (80, 240), (100, 280)], edge: [(5, 150), (0, 240), (5, 330)], root: finC, tip: finD, rays: 14)
        a.fin(base: [(150, 170), (760, 94)], edge: [(135, 110), (260, 56), (520, 18), (780, 46)], root: finC, tip: finD, rays: 26)
        a.fin(base: [(150, 312), (420, 396)], edge: [(135, 362), (240, 442), (430, 462)], root: finC, tip: finD, rays: 14)
        let top: [XY] = [(92, 206), (170, 172), (340, 122), (520, 92), (690, 88), (830, 118), (920, 180), (975, 252)]
        let bottom: [XY] = [(92, 276), (170, 308), (340, 372), (520, 408), (690, 414), (830, 386), (920, 330), (975, 272)]
        a.body(top: top, bottom: bottom, shader)
        a.fin(base: [(690, 396), (735, 392)], edge: [(640, 450), (680, 462), (730, 430)], root: finC, tip: finD, alpha: 0.75, rays: 6)
    }

    static func berggylt(_ a: Art) {
        let back = hex(0x4c6a3a), side = hex(0x88955a), belly = hex(0xe1cf9a)
        wrasseBody(a, shader: { _, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.50)
            let m = smooth(0.47, 0.66, artNoise.fbm(x * 0.016, y * 0.022, 3))
            c = mix(c, hex(0x8a4e23), m * 0.55)
            let dots = spots(x, y, cell: 22, radius: 6.5, keep: 0.8)
            c = mix(c, hex(0xe8e0ac), dots * 0.78)
            c *= 1 - scales(x, y, size: 26) * 0.17
            return rgba(c * roundLight(v))
        }, finC: hex(0x516a3e), finD: hex(0x90905a))
        a.fin(base: [(705, 256), (705, 320)], edge: [(590, 262), (560, 310), (605, 372)], root: hex(0x7c7c4c), tip: hex(0xb4a668), rays: 10)
        gill(a, 792, 140, 372, bow: 40)
        a.taper([(980, 256), (952, 276), (905, 286)], 28, 16, hex(0xb88e62))
        a.line([(978, 262), (940, 271), (900, 282)], hex(0x2a1e10), 0.95, 4)
        a.eye(872, 188, 22, iris: hex(0xd29545))
    }

    static func blaastaal(_ a: Art) {
        let orange = hex(0xcf7a2c), deep = hex(0xa95520), blue = hex(0x2a62a0), bright = hex(0x3f9bd4)
        wrasseBody(a, shader: { t, v, x, y in
            var c = v < 0.6 ? mix(deep, orange, smooth(0, 0.45, v)) : mix(orange, hex(0xf6c15a), smooth(0.6, 1, v))
            // Blue head and back streaks, typical of the breeding male.
            let wav = artNoise.fbm(x * 0.012, y * 0.02, 2) * 0.08
            let head = smooth(0.62, 0.82, t + wav * 2)
            let backline = clamp01(1 - abs(v - 0.20 - wav) * 16) * smooth(0.10, 0.28, t)
            let midline = clamp01(1 - abs(v - 0.54 + wav) * 22) * smooth(0.20, 0.45, t)
            c = mix(c, blue, max(head * 0.96, max(backline, midline) * 0.95))
            let glow = clamp01(1 - abs(v - 0.20 - wav) * 34) * smooth(0.10, 0.28, t)
            c = mix(c, bright, glow * 0.8)
            c *= 1 - scales(x, y, size: 22) * 0.10
            return rgba(c * roundLight(v))
        }, finC: hex(0xdc6e1c), finD: hex(0x2f8fe0))
        a.fin(base: [(705, 256), (705, 320)], edge: [(590, 262), (560, 310), (605, 372)], root: hex(0xf09a30), tip: hex(0x2b7fd8), rays: 10)
        a.line([(974, 262), (930, 268), (870, 296)], hex(0x3ec3ff), 0.9, 7)
        a.line([(960, 230), (900, 208), (830, 200)], hex(0x3ec3ff), 0.7, 6)
        gill(a, 792, 140, 372, bow: 40, 0.3)
        a.line([(978, 262), (945, 272), (905, 270)], hex(0x07213f), 0.95, 4)
        a.eye(872, 186, 21, iris: hex(0xf0c040))
    }

    static func rognkjeks(_ a: Art) {
        let finC = hex(0x45606b), finD = hex(0x7d98a0)
        a.fin(base: [(100, 300), (84, 340), (100, 380)], edge: [(10, 280), (0, 340), (10, 400)], root: finC, tip: finD, rays: 10)
        a.fin(base: [(160, 212), (330, 132)], edge: [(150, 150), (225, 100), (320, 92)], root: finC, tip: finD, rays: 9)
        a.fin(base: [(180, 452), (350, 540)], edge: [(155, 520), (240, 570), (360, 590)], root: finC, tip: finD, rays: 9)
        let top: [XY] = [(95, 306), (160, 214), (290, 112), (480, 56), (650, 58), (800, 118), (910, 230), (965, 330)]
        let bottom: [XY] = [(95, 372), (160, 440), (290, 548), (480, 612), (650, 606), (800, 550), (910, 462), (965, 378)]
        let back = hex(0x36525f), side = hex(0x6d8f96), belly = hex(0xcdb79f)
        a.body(top: top, bottom: bottom) { _, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.58)
            let m = artNoise.fbm(x * 0.02, y * 0.02, 3)
            c *= 0.84 + 0.32 * m
            // Rows of bony tubercles.
            for row: Float in [0.16, 0.42, 0.68] {
                let wobble = sin(x * 0.012) * 0.015
                let dv = abs(v - row - wobble)
                let bumps = pow(clamp01(sin(x * 0.075) * 0.5 + 0.5), 2)
                if dv < 0.042 {
                    let s = (1 - dv / 0.042) * bumps
                    c = mix(c, hex(0xc0d2d0), s * 0.8)
                }
            }
            c = mix(c, c * 0.72, spots(x, y, cell: 30, radius: 9, keep: 0.7) * 0.8)
            return rgba(c * roundLight(v))
        }
        // Sucker disc on the belly.
        a.disc(610, 612, 62, hex(0x8c7d6e), 0.9, sy: 0.28)
        a.fin(base: [(700, 310), (700, 400)], edge: [(590, 300), (560, 370), (610, 450)], root: finC, tip: finD, rays: 12)
        a.line([(965, 350), (925, 372), (885, 368)], hex(0x101a1f), 0.9, 6)
        a.eye(842, 262, 28, iris: hex(0xb38f58))
    }

    static func pigghaa(_ a: Art) {
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

    static func haakjerring(_ a: Art) {
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

    /// Anglerfish lying on the bottom: broad flat head, wide closed mouth with the lower jaw
    /// jutting, eyes on top, fringed edge, lure on the snout.
    static func breiflabb(_ a: Art) {
        let skin = hex(0x6f5a3f), dark = hex(0x3e321d), pale = hex(0xb7a582)
        a.fin(base: [(150, 352), (130, 380), (150, 408)], edge: [(10, 300), (0, 380), (20, 450)], root: dark, tip: skin, alpha: 0.75, rays: 12)
        a.fin(base: [(250, 330), (420, 300)], edge: [(250, 280), (330, 240), (430, 262)], root: dark, tip: skin, alpha: 0.7, rays: 10)
        let top: [XY] = [(140, 345), (250, 320), (390, 295), (520, 262), (680, 235), (820, 232), (925, 252), (985, 300)]
        let bottom: [XY] = [(140, 395), (250, 405), (390, 420), (520, 440), (680, 455), (820, 452), (925, 430), (990, 372)]
        a.body(top: top, bottom: bottom) { _, v, x, y in
            var c = mix(skin, pale, smooth(0.7, 1.0, v))
            let m = artNoise.fbm(x * 0.015, y * 0.02, 4)
            c = mix(c, dark, smooth(0.35, 0.75, m) * 0.55)
            c = mix(c, hex(0x9a8560), smooth(0.58, 0.76, artNoise.fbm(x * 0.04 + 9, y * 0.05, 3)) * 0.5)
            c *= 1 - spots(x, y, cell: 15, radius: 3.6, keep: 0.4) * 0.22
            return rgba(c * (0.70 + 0.34 * roundLight(v)))
        }
        // Rounded pectoral behind the head.
        a.fin(base: [(560, 360), (585, 420)], edge: [(470, 410), (490, 470), (580, 480)], root: skin * 0.85, tip: hex(0x8c7756), alpha: 0.8, rays: 9)
        // Closed mouth along the front, lower jaw ahead of the upper.
        a.line([(990, 336), (930, 350), (840, 352), (760, 340)], hex(0x1c140f), 0.8, 7)
        a.fill([(998, 344), (990, 364), (930, 368), (900, 356), (940, 352)], hex(0x7c6748))
        for i in 0..<6 {
            let x = 980 - Double(i) * 16
            a.fill([(x - 4, 350), (x, 336 - Double(i % 2) * 4), (x + 4, 350)], hex(0xa89f88), 0.9, raw: true)
        }
        // Skin fringe along the jaw and flanks.
        for i in 0..<30 {
            let t = Double(i) / 29
            let x = 170 + t * 810, y = 404 + 46 * sin(min(1, t * 1.15) * 1.7) - t * t * 50
            let len = 10 + (i % 4 == 0 ? 18.0 : 6.0)
            a.taper([(x, y), (x + 4, y + len * 0.6), (x - 2, y + len)], 7, 1.4, i % 2 == 0 ? hex(0x5f4e35) : hex(0x9b8862), 0.85)
        }
        // Lure rod and flap, eyes high on the head.
        a.line([(880, 250), (905, 190), (950, 160), (982, 170)], hex(0xa8976f), 0.95, 4.5)
        a.taper([(982, 170), (974, 192), (984, 206)], 20, 3, hex(0xd5c7a3))
        a.line([(800, 240), (812, 210), (830, 198)], hex(0xa8976f), 0.8, 3.4)
        a.eye(770, 252, 14, iris: hex(0xa88f50))
        a.eye(735, 246, 11, iris: hex(0x8a7543))
    }

    static func steinbit(_ a: Art) {
        let finC = hex(0x3f4a57), finD = hex(0x65727d)
        a.fin(base: [(55, 158), (880, 62)], edge: [(0, 112), (250, 92), (640, 30), (890, 28)], root: finC, tip: finD, rays: 50)
        a.fin(base: [(55, 188), (470, 232)], edge: [(0, 212), (180, 264), (480, 288)], root: finC, tip: finD, rays: 22)
        let top: [XY] = [(40, 160), (200, 136), (450, 106), (680, 74), (830, 56), (920, 62), (975, 102), (995, 150)]
        let bottom: [XY] = [(40, 186), (200, 198), (450, 224), (680, 244), (830, 250), (920, 238), (975, 208), (995, 174)]
        let back = hex(0x43505d), side = hex(0x6e7d88), belly = hex(0xc8c9bb)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.58)
            let wob = (artNoise.fbm(x * 0.02, y * 0.03, 2) - 0.5) * 18
            let band = sin((x + wob) * 0.058 + 0.5)
            let bar = smooth(0.10, 0.45, band) * (1 - smooth(0.48, 0.72, v)) * (1 - smooth(0.82, 0.90, t))
            c = mix(c, hex(0x1b2129), bar * 0.88)
            c *= 0.96 + 0.08 * artNoise.fbm(x * 0.09, y * 0.1, 2)
            return rgba(c * roundLight(v))
        }
        a.fin(base: [(770, 170), (770, 225)], edge: [(680, 182), (660, 240), (705, 294)], root: finC, tip: finD, rays: 11)
        gill(a, 802, 90, 230, bow: 26)
        // Big canine teeth, the reason for the name.
        a.fill([(994, 150), (955, 168), (900, 165), (925, 196), (994, 188)], hex(0x1a1312), 0.95)
        for (x, y0, l) in [(978.0, 158.0, 22.0), (962, 164, 20), (946, 166, 15), (928, 166, 12)] {
            a.fill([(x - 5, y0), (x, y0 + l), (x + 5, y0)], hex(0xf2ecd5), 1, raw: true)
        }
        for (x, y0, l) in [(972.0, 190.0, 18.0), (952, 193, 15), (936, 192, 11)] {
            a.fill([(x - 5, y0), (x, y0 - l), (x + 5, y0)], hex(0xf2ecd5), 1, raw: true)
        }
        a.line([(994, 150), (955, 168), (900, 165)], hex(0x7e8892), 1, 5)
        a.eye(915, 118, 15, iris: hex(0xb7a56c))
    }

    /// Plaice seen from above at a low angle, both eyes on the upper side.
    /// Goldsinny wrasse: small, slim, red-brown to gold, with a dark spot on top of the tail stalk
    /// and another at the front of the dorsal fin.
    static func bergnebb(_ a: Art) {
        let back = hex(0x8a4a24), side = hex(0xc0803f), belly = hex(0xe8c58a)
        wrasseBody(a, shader: { _, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.5)
            c *= 0.9 + 0.2 * artNoise.fbm(x * 0.02, y * 0.03, 3)
            c *= 1 - scales(x, y, size: 24) * 0.12
            return rgba(c * roundLight(v))
        }, finC: hex(0x9a4a22), finD: hex(0xcf8a48))
        a.disc(150, 172, 24, hex(0x1a120c), 0.9)
        a.disc(745, 92, 18, hex(0x1a120c), 0.8)
        a.fin(base: [(705, 256), (705, 320)], edge: [(600, 262), (570, 310), (612, 368)], root: hex(0xb06a34), tip: hex(0xd8a066), rays: 9)
        gill(a, 792, 140, 372, bow: 40)
        a.line([(978, 262), (940, 271), (905, 276)], hex(0x2a1608), 0.6, 4)
        a.eye(872, 190, 24, iris: hex(0xc58a3a))
    }

    /// Tusk: a long cod relative with one continuous dorsal fin, a rounded tail, pale-edged fins
    /// and a chin barbel.
    static func brosme(_ a: Art) {
        let finC = hex(0x4a3524), finD = hex(0x6d5238), rim = hex(0xe3dccb)
        a.fin(base: [(80, 150), (60, 165), (80, 180)], edge: [(8, 95), (0, 165), (8, 235)], root: finC, tip: finD, alpha: 0.85, rays: 14)
        a.line([(10, 98), (2, 165), (10, 232)], rim, 0.75, 5)
        let dorsalEdge: [XY] = [(85, 112), (300, 66), (560, 50), (770, 66)]
        a.fin(base: [(90, 140), (300, 104), (560, 86), (760, 92)], edge: dorsalEdge, root: finC, tip: finD, alpha: 0.85, rays: 40)
        a.line(dorsalEdge, rim, 0.7, 4)
        let analEdge: [XY] = [(85, 215), (300, 252), (570, 262)]
        a.fin(base: [(90, 190), (300, 222), (560, 236)], edge: analEdge, root: finC, tip: finD, alpha: 0.85, rays: 28)
        a.line(analEdge, rim, 0.7, 4)
        let top: [XY] = [(78, 148), (200, 124), (400, 96), (600, 84), (760, 86), (880, 104), (950, 130), (990, 160)]
        let bottom: [XY] = [(78, 182), (200, 206), (400, 230), (600, 240), (760, 238), (880, 220), (950, 196), (990, 172)]
        let back = hex(0x5a3e27), side = hex(0x8a6a48), belly = hex(0xd9c8a6)
        a.body(top: top, bottom: bottom) { _, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.55)
            c = mix(c, c * 0.72, smooth(0.5, 0.7, artNoise.fbm(x * 0.02, y * 0.04, 3)) * (1 - smooth(0.5, 0.75, v)))
            c *= 1 - scales(x, y, size: 10) * 0.05
            return rgba(c * roundLight(v))
        }
        a.fin(base: [(800, 168), (800, 200)], edge: [(720, 176), (700, 206), (735, 232)], root: finC, tip: finD, alpha: 0.75, rays: 8)
        gill(a, 828, 100, 228, bow: 26)
        a.line([(990, 170), (955, 182), (925, 180)], hex(0x241810), 0.5, 4)
        a.line([(948, 196), (944, 222), (936, 236)], hex(0xbfae8a), 1, 3.5)
        a.eye(920, 138, 13, iris: hex(0x9a8656))
    }

    /// Rabbit fish: a big blunt head with large green eyes, broad wing-like pectorals, a tall first
    /// dorsal spine and a body tapering to a long thin tail.
    static func havmus(_ a: Art) {
        a.taper([(400, 196), (250, 202), (120, 206), (0, 200)], 26, 2, hex(0x8d8a80))
        a.fin(base: [(420, 178), (560, 150), (720, 108)], edge: [(420, 162), (560, 126), (720, 88)], root: hex(0x6e6458), tip: hex(0x9a9084), alpha: 0.7, rays: 20)
        let top: [XY] = [(380, 188), (480, 152), (600, 120), (720, 98), (820, 94), (900, 112), (960, 150), (990, 190)]
        let bottom: [XY] = [(380, 204), (480, 228), (600, 252), (720, 262), (820, 262), (900, 250), (960, 230), (990, 206)]
        let back = hex(0x7c6a5a), side = hex(0xb7aa98), belly = hex(0xd8d2c8)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.5)
            let marble = smooth(0.48, 0.62, artNoise.fbm(x * 0.012, y * 0.05, 3))
            c = mix(c, hex(0x5a4636), marble * 0.55 * (1 - smooth(0.4, 0.7, v)))
            c += C3(0.05, 0.08, 0.10) * pow(clamp01(1 - abs(v - 0.45) * 3), 3)
            _ = t
            return rgba(c * roundLight(v))
        }
        a.fill([(760, 98), (790, 18), (816, 96)], hex(0x6e6458), 0.95)
        a.line([(782, 98), (792, 16)], hex(0xe7e1d6), 0.9, 4, smooth: false)
        a.fin(base: [(770, 200), (790, 244)], edge: [(640, 290), (560, 340), (700, 336)], root: hex(0x7c7064), tip: hex(0xa8a092), alpha: 0.8, rays: 12)
        for (y0, y1) in [(170.0, 150.0), (200.0, 196.0)] {
            a.line([(980, y0), (930, y1), (860, y1 + 6)], hex(0xe9e4da), 0.35, 3)
        }
        a.eye(905, 152, 30, iris: hex(0x4f8a5a))
    }

    /// Lemon sole, seen from above at a low angle: small head, smooth mottled yellow-brown skin.
    static func lomre(_ a: Art) {
        let fringe = hex(0x7a6440)
        a.fin(base: [(140, 170), (120, 195), (140, 220)], edge: [(10, 120), (0, 195), (10, 270)], root: fringe, tip: hex(0xa48c5c), rays: 12)
        a.fin(base: [(150, 165), (800, 66)], edge: [(140, 112), (460, 14), (810, 30)], root: fringe, tip: hex(0xa48c5c), rays: 40)
        a.fin(base: [(150, 225), (800, 335)], edge: [(140, 280), (460, 388), (810, 375)], root: fringe, tip: hex(0xa48c5c), rays: 40)
        let top: [XY] = [(135, 172), (260, 124), (450, 76), (640, 60), (820, 78), (920, 122), (975, 188)]
        let bottom: [XY] = [(135, 220), (260, 264), (450, 318), (640, 342), (820, 322), (920, 272), (975, 206)]
        a.body(top: top, bottom: bottom) { _, v, x, y in
            var c = mix(hex(0x957d4c), hex(0xa68f5a), v)
            c = mix(c, hex(0x5e4a2c), smooth(0.52, 0.7, artNoise.fbm(x * 0.03, y * 0.03 + 3, 3)) * 0.6)
            c = mix(c, hex(0xd8c79c), spots(x, y, cell: 46, radius: 6, keep: 0.35) * 0.6)
            return rgba(c * (0.82 + 0.24 * roundLight(v)))
        }
        a.line([(975, 192), (958, 206), (936, 210)], hex(0x2e2412), 0.5, 4)
        a.eye(905, 146, 12, iris: hex(0xb79a50))
        a.eye(915, 182, 11, iris: hex(0xb79a50))
    }

    /// Small-spotted catshark: slender, sandy brown with many small dark spots, both dorsals set
    /// far back, a long low tail and a cat-like slit eye.
    static func rodhai(_ a: Art) {
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

    /// Grey gurnard: a big bony sloping head, small white spots, wide pectoral fans, and three
    /// free fin rays it walks on.
    static func knurr(_ a: Art) {
        let finC = hex(0x5d5a52), finD = hex(0x8b8a80)
        a.fin(base: [(84, 178), (64, 190), (84, 202)], edge: [(0, 120), (30, 190), (0, 260)], root: finC, tip: finD, alpha: 0.8, rays: 10)
        a.fin(base: [(300, 130), (590, 104)], edge: [(300, 104), (440, 78), (600, 80)], root: finC, tip: finD, alpha: 0.75, rays: 18)
        let spineBase: [XY] = [(610, 100), (680, 94), (760, 92)]
        let spineTips: [XY] = [(620, 40), (660, 30), (700, 34), (740, 52), (764, 76)]
        a.fill(spineBase + spineTips.reversed(), finC, 0.85, raw: true)
        a.softDot(690, 70, 22, hex(0x16130f), 0.8)
        for x in stride(from: 330.0, through: 560, by: 30) {
            a.fill([(x - 6, 248), (x, 262), (x + 6, 248)], finD, 0.7, raw: true)
        }
        let top: [XY] = [(80, 176), (200, 152), (400, 122), (600, 100), (780, 92), (900, 112), (985, 190)]
        let bottom: [XY] = [(80, 198), (200, 214), (400, 242), (600, 262), (780, 278), (880, 274), (950, 252), (990, 206)]
        let back = hex(0x5f5c54), side = hex(0x8e8a7e), belly = hex(0xe2ddd0)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.55)
            c = mix(c, hex(0xe6e2d6), spots(x, y, cell: 18, radius: 3, keep: 0.6) * (1 - smooth(0.5, 0.7, v)))
            // Bony plates on the head.
            if t > 0.82 { c *= 0.92 + 0.12 * artNoise.fbm(x * 0.08, y * 0.08, 2) }
            return rgba(c * roundLight(v))
        }
        // Free rays used as legs, then the pectoral fan over them.
        for i in 0..<3 {
            let x0 = 770 + Double(i) * 22
            a.line([(x0, 264), (x0 + 10, 330), (x0 + 4, 396)], hex(0xcbc4b2), 0.95, 6)
        }
        a.fin(base: [(720, 190), (740, 254)], edge: [(560, 240), (470, 320), (640, 352)], root: hex(0x6e6b62), tip: hex(0x8fa8b8), alpha: 0.75, rays: 12)
        a.line([(985, 196), (956, 214), (920, 214)], hex(0x26231e), 0.5, 4)
        a.eye(870, 150, 24, iris: hex(0xb8a46a))
    }

    /// Ling: a long, slightly flattened cod relative with a barbel, a short first and long second
    /// dorsal, dark spots at the rear of the vertical fins and pale fin margins.
    static func lange(_ a: Art) {
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

    /// Whiting: silvery with a sandy back, three dorsal fins, and a dark spot at the base of the
    /// pectoral fin.
    static func hvitting(_ a: Art) {
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

    static func rodspette(_ a: Art) {
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

    /// Thornback ray, disc from above at a low angle.
    static func piggskate(_ a: Art) {
        a.taper([(300, 300), (180, 298), (70, 305), (6, 298)], 46, 8, hex(0x6f5a3a))
        for i in 0..<9 {
            let x = 40 + Double(i) * 30
            a.fill([(x - 6, 300), (x, 278), (x + 6, 300)], hex(0xe0d4ae), 1, raw: true)
        }
        a.fill([(70, 296), (58, 268), (88, 268), (96, 294)], hex(0x5e4b31))
        a.fill([(30, 296), (18, 274), (44, 274), (52, 296)], hex(0x5e4b31))
        let top: [XY] = [(250, 280), (310, 240), (420, 110), (520, 18), (640, 110), (790, 215), (900, 268), (995, 300)]
        let bottom: [XY] = [(250, 320), (310, 360), (420, 490), (520, 582), (640, 490), (790, 385), (900, 332), (995, 300)]
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = mix(hex(0x8a724a), hex(0x7c653e), v)
            c *= 0.85 + 0.3 * artNoise.fbm(x * 0.02, y * 0.02, 4)
            let sp = spots(x, y, cell: 42, radius: 7.2, keep: 0.65)
            c = mix(c, hex(0x3f3019), sp * 0.8)
            let pale = spots(x, y, cell: 64, radius: 7.5, keep: 0.45, seed: 7)
            c = mix(c, hex(0xd9c79a), pale * 0.85)
            _ = t
            // Ridge along the midline.
            let mid = clamp01(1 - abs(v - 0.5) * 7)
            return rgba(c * (0.82 + 0.28 * mid))
        }
        for i in 0..<10 {
            let x = 310 + Double(i) * 50
            a.fill([(x - 7, 306), (x + 5, 288), (x + 13, 306)], hex(0xe6dab6), 1, raw: true)
        }
        for (x, y) in [(590.0, 232.0), (560, 368), (480, 195), (455, 410), (700, 258), (700, 342)] {
            a.disc(x, y, 7, hex(0xe6dab6))
        }
        a.eye(842, 264, 12, iris: hex(0xa88f50))
        a.eye(842, 334, 12, iris: hex(0xa88f50))
        a.disc(806, 268, 6, hex(0x1b1610)); a.disc(806, 330, 6, hex(0x1b1610))
    }

    static func jellyMoon(_ a: Art) {
        for i in 0..<34 {
            let t = Double(i) / 33
            let x = 170 + t * 660
            let len = 60 + a.rng.range(0, 60)
            let y0 = 370 + 40 * sin(t * .pi)
            a.line([(x, y0), (x + a.rng.range(-8, 8), y0 + len * 0.5), (x + a.rng.range(-14, 14), y0 + len)], hex(0xe5eef0), 0.42, 2.6)
        }
        for (x0, d) in [(420.0, -60.0), (580, 60), (500, 10)] {
            a.taper([(x0, 340), (x0 + d * 0.5, 480), (x0 + d, 650)], 36, 4, hex(0xe6eef2), 0.30)
        }
        let cx = 500.0, cy = 370.0
        a.polar(cx: cx, cy: cy, sy: 0.58, maxR: 350, radius: { th in
            // Lower half of the bell is cut flatter.
            let ripple = 3.5 * sin(th * 32)
            return th > 0 ? 340 * (1 - 0.55 * sin(th)) + ripple : 340 + ripple
        }) { r, th, _, _ in
            let a0 = 0.20 + 0.42 * r * r * r
            let c = mix(hex(0xd7e8ee), hex(0xf8fbfd), r)
            let seg = abs(sin(th * 32)) * pow(r, 3) * 0.1
            return rgba(c, a0 + seg)
        }
        // Four horseshoe gonads, the signature of this species.
        for (dx, dy) in [(-92.0, -58.0), (92, -58), (-82, 38), (82, 38)] {
            let x = cx + dx, y = cy + dy
            a.ctx.setStrokeColor(a.color(hex(0xc689c4), 0.92))
            a.ctx.setLineWidth(18)
            a.ctx.setLineCap(.round)
            a.ctx.addArc(center: CGPoint(x: x, y: y), radius: 42, startAngle: 0.5, endAngle: 5.8, clockwise: false)
            a.ctx.strokePath()
        }
        a.softDot(cx - 90, cy - 130, 150, C3(1, 1, 1), 0.3, sy: 0.5)
    }

    static func jellyLion(_ a: Art) {
        for i in 0..<100 {
            let t = Double(i) / 99
            let x = 150 + t * 700
            let y0 = 215 + 28 * sin(t * .pi)
            let len = a.rng.range(380, 760)
            let sway = a.rng.range(-45, 45)
            let col = i % 3 == 0 ? hex(0xebb04f) : hex(0xb0502e)
            a.line([(x, y0), (x + sway * 0.4, y0 + len * 0.35), (x + sway, y0 + len * 0.7), (x + sway * 0.6, y0 + len)], col, 0.48, 2.3)
        }
        for i in 0..<9 {
            let t = Double(i) / 8
            let x = 320 + t * 360
            let wig = a.rng.range(-26, 26)
            a.taper([(x, 210), (x + wig, 360), (x - wig, 520), (x + wig * 0.5, 680)], 40, 4, i % 2 == 0 ? hex(0xd05b2e) : hex(0xe69a43), 0.60)
        }
        a.polar(cx: 500, cy: 200, sy: 0.54, maxR: 372, radius: { th in
            let lobes = 15 * abs(sin(th * 8))
            return th > 0 ? 350 * (1 - 0.72 * sin(th)) + lobes : 350 + lobes
        }) { r, th, x, y in
            let radial = abs(sin(th * 24))
            var c = mix(hex(0xe5a23f), hex(0x8e2f1d), smooth(0.25, 0.92, r))
            c = mix(c, hex(0x651b13), radial * pow(r, 2) * 0.55)
            c *= 0.88 + 0.26 * artNoise.fbm(x * 0.02, y * 0.02, 2)
            return rgba(c, 0.86)
        }
        a.softDot(420, 130, 150, hex(0xffe0a8), 0.42, sy: 0.5)
    }
}
