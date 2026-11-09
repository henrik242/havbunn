import CoreGraphics
import Foundation

// Fish are drawn in profile, head to the right, on a 1000-unit wide cell.

private func flank(_ v: Float, back: C3, side: C3, belly: C3, split: Float = 0.42) -> C3 {
    v < split ? mix(back, side, smooth(0.04, split, v)) : mix(side, belly, smooth(split, min(0.98, split + 0.36), v))
}

private func gill(_ a: Art, _ x: Double, _ y0: Double, _ y1: Double, bow: Double = 34, _ alpha: Double = 0.38) {
    a.line([(x, y0), (x - bow, (y0 + y1) * 0.5), (x, y1)], hex(0x14100c), alpha, 5)
}

enum FishArt {
    static func torsk(_ a: Art) {
        let finC = hex(0x6a6240), finD = hex(0x8f8660)
        a.fin(base: [(115, 195), (70, 215), (115, 235)], edge: [(10, 110), (0, 215), (10, 322)], root: finC, tip: finD, rays: 18)
        a.fin(base: [(470, 90), (620, 76)], edge: [(495, 28), (560, 8), (630, 42)], root: finC, tip: finD, rays: 12)
        a.fin(base: [(285, 142), (450, 95)], edge: [(290, 88), (360, 38), (460, 42)], root: finC, tip: finD, rays: 13)
        a.fin(base: [(130, 188), (270, 148)], edge: [(135, 138), (190, 90), (280, 96)], root: finC, tip: finD, rays: 12)
        a.fin(base: [(430, 336), (590, 348)], edge: [(445, 400), (510, 422), (595, 392)], root: finC, tip: finD, rays: 12)
        a.fin(base: [(145, 242), (290, 290)], edge: [(150, 295), (210, 340), (295, 345)], root: finC, tip: finD, rays: 11)
        a.fin(base: [(700, 345), (745, 340)], edge: [(640, 420), (690, 425), (735, 395)], root: finD, tip: finD, rays: 7)

        let top: [XY] = [(100, 203), (170, 188), (300, 132), (480, 88), (650, 75), (790, 94), (900, 150), (972, 212)]
        let bottom: [XY] = [(100, 228), (170, 240), (300, 285), (480, 332), (650, 350), (790, 340), (900, 298), (972, 228)]
        let back = hex(0x5d5a33), side = hex(0x9b9460), belly = hex(0xe9e3cd)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.46)
            let vis = 1 - smooth(0.48, 0.74, v)
            let mottle = smooth(0.50, 0.70, artNoise.fbm(x * 0.022, y * 0.030, 3))
            c = mix(c, c * 0.62, mottle * vis)
            let sp = spots(x, y, cell: 19, radius: 5.2, keep: 0.72)
            c = mix(c, hex(0x3b3a1f), sp * vis * 0.85)
            let llY = 0.40 + 0.14 * sin(Float(t) * 2.4 - 0.2) * (1 - t)
            let ll = clamp01(1 - abs(v - llY) * 70)
            c = mix(c, hex(0xe6dfbd), ll * 0.85)
            c = c * (1 - scales(x, y, size: 13) * 0.05)
            return rgba(c * roundLight(v))
        }
        a.fin(base: [(770, 215), (770, 265)], edge: [(680, 225), (648, 268), (690, 310)], root: finC * 1.1, tip: finD, rays: 9)
        gill(a, 802, 118, 310)
        a.line([(972, 226), (930, 244), (884, 240)], hex(0x2a2415), 0.75, 5)
        a.line([(915, 287), (908, 325), (897, 348)], hex(0x8a7f55), 1, 4.5)
        a.eye(890, 172, 21)
    }

    static func sei(_ a: Art) {
        let finC = hex(0x2d3b3a), finD = hex(0x4e5d5b)
        a.fin(base: [(90, 170), (55, 185), (90, 200)], edge: [(0, 66), (40, 185), (0, 306)], root: finC, tip: finD, rays: 16)
        a.fin(base: [(120, 165), (270, 118)], edge: [(135, 118), (210, 72), (280, 76)], root: finC, tip: finD, rays: 11)
        a.fin(base: [(290, 112), (455, 76)], edge: [(300, 62), (375, 24), (465, 34)], root: finC, tip: finD, rays: 12)
        a.fin(base: [(480, 72), (630, 64)], edge: [(490, 26), (570, 8), (640, 26)], root: finC, tip: finD, rays: 11)
        a.fin(base: [(135, 206), (300, 248)], edge: [(145, 250), (210, 292), (310, 298)], root: finD, tip: finD, rays: 11)
        a.fin(base: [(330, 256), (510, 282)], edge: [(345, 300), (420, 332), (520, 322)], root: finD, tip: finD, rays: 12)

        let top: [XY] = [(85, 174), (170, 156), (300, 110), (480, 72), (650, 60), (790, 74), (900, 118), (985, 176)]
        let bottom: [XY] = [(85, 196), (170, 208), (300, 240), (480, 276), (650, 286), (790, 276), (900, 236), (985, 188)]
        let back = hex(0x26393b), side = hex(0x6d8080), belly = hex(0xdfe5e0)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.45)
            let shine = pow(clamp01(1 - abs(v - 0.60) * 3.4), 3)
            c += C3(0.16, 0.18, 0.17) * shine
            let ll = clamp01(1 - abs(v - 0.40) * 60)
            c = mix(c, hex(0xcfd8d0), ll * 0.75)
            c *= 1 - scales(x, y, size: 11) * 0.07
            _ = t
            return rgba(c * roundLight(v))
        }
        a.fin(base: [(760, 170), (760, 215)], edge: [(675, 170), (640, 208), (680, 248)], root: finC, tip: finD, rays: 9)
        gill(a, 790, 92, 256)
        a.line([(985, 184), (940, 196), (902, 192)], hex(0x101817), 0.8, 4)
        a.eye(902, 142, 20, iris: hex(0xb9c4b6))
    }

    static func sild(_ a: Art) {
        let finC = hex(0x51676f), finD = hex(0x8c9fa3)
        a.fin(base: [(85, 142), (55, 160), (85, 178)], edge: [(0, 42), (42, 160), (0, 278)], root: finC, tip: finD, rays: 12)
        a.fin(base: [(450, 80), (560, 75)], edge: [(465, 20), (510, 14), (575, 66)], root: finC, tip: finD, rays: 8)
        a.fin(base: [(205, 218), (320, 240)], edge: [(215, 262), (270, 282), (330, 258)], root: finD, tip: finD, rays: 7)
        a.fin(base: [(490, 262), (545, 266)], edge: [(470, 300), (510, 322), (548, 292)], root: finD, tip: finD, rays: 6)

        let top: [XY] = [(80, 150), (180, 126), (350, 90), (540, 70), (720, 72), (860, 96), (985, 150)]
        let bottom: [XY] = [(80, 172), (180, 192), (350, 236), (540, 270), (720, 268), (860, 226), (985, 166)]
        let back = hex(0x1f5168), side = hex(0xaec8cb), belly = hex(0xf4f8f4)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.30)
            let sheen = pow(clamp01(1 - abs(v - 0.46) * 3), 3)
            c += C3(0.14, 0.15, 0.14) * sheen
            let glint = pow(artNoise.value(x * 0.012, 3.1), 2) * 0.12
            c += C3(glint, glint * 1.1, glint * 1.2)
            c *= 1 - scales(x, y, size: 26) * 0.14
            _ = t
            return rgba(c * (0.72 + 0.34 * roundLight(v)))
        }
        gill(a, 808, 92, 244, bow: 26, 0.35)
        a.line([(985, 157), (948, 186), (908, 182)], hex(0x101820), 0.7, 6)
        a.eye(905, 138, 25, iris: hex(0xdcdcc8))
    }

    static func makrell(_ a: Art) {
        let finC = hex(0x25424a), finD = hex(0x4a6d72)
        a.fin(base: [(72, 170), (52, 180), (72, 190)], edge: [(0, 40), (34, 180), (0, 320)], root: finC, tip: finD, rays: 14)
        a.fin(base: [(560, 100), (690, 92)], edge: [(575, 34), (625, 12), (700, 70)], root: finC, tip: finD, rays: 9)
        a.fin(base: [(310, 122), (430, 108)], edge: [(320, 66), (360, 50), (438, 92)], root: finC, tip: finD, rays: 7)
        a.fin(base: [(310, 240), (430, 254)], edge: [(320, 296), (360, 310), (440, 262)], root: finD, tip: finD, rays: 7)
        for i in 0..<5 {
            let x = 110 + Double(i) * 38
            a.fill([(x, 160 - Double(i) * 6), (x + 14, 134 - Double(i) * 6), (x + 22, 156 - Double(i) * 6)], finC)
            a.fill([(x, 202 + Double(i) * 6), (x + 14, 226 + Double(i) * 6), (x + 22, 204 + Double(i) * 6)], finC)
        }
        let top: [XY] = [(72, 172), (150, 164), (300, 124), (470, 96), (650, 86), (800, 102), (910, 136), (990, 178)]
        let bottom: [XY] = [(72, 188), (150, 198), (300, 236), (470, 262), (650, 270), (800, 256), (910, 226), (990, 186)]
        let back = hex(0x1d6f7a), mid = hex(0xaad0c3), belly = hex(0xf2f6ee)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: mid, belly: belly, split: 0.46)
            // Tiger stripes on the back only.
            let wob = artNoise.fbm(x * 0.012, y * 0.02, 2) * 42
            let band = sin((x + y * 0.62 + wob) * 0.092)
            let reach = 1 - smooth(0.34, 0.52, v + (artNoise.value(x * 0.03, 8) - 0.5) * 0.14)
            let stripe = smooth(0.18, 0.55, band) * reach * smooth(0.08, 0.2, t)
            c = mix(c, hex(0x08171e), stripe * 0.95)
            c += C3(0.05, 0.10, 0.09) * pow(clamp01(1 - abs(v - 0.3) * 4), 2)
            c += C3(0.12, 0.10, 0.14) * pow(clamp01(1 - abs(v - 0.62) * 5), 3)
            return rgba(c * (0.68 + 0.38 * roundLight(v)))
        }
        a.fin(base: [(760, 170), (760, 205)], edge: [(675, 158), (650, 180), (680, 215)], root: finC, tip: finD, rays: 7)
        gill(a, 818, 108, 246, bow: 30, 0.4)
        a.line([(990, 182), (940, 200), (905, 196)], hex(0x101820), 0.8, 5)
        a.eye(912, 150, 20, iris: hex(0xd5d9c4))
    }

    static func laks(_ a: Art) {
        let finC = hex(0x3c4a52), finD = hex(0x71808a)
        a.fin(base: [(88, 162), (60, 182), (88, 202)], edge: [(0, 60), (28, 182), (0, 304)], root: finC, tip: finD, rays: 16)
        a.fin(base: [(450, 82), (570, 76)], edge: [(455, 26), (495, 10), (585, 66)], root: finC, tip: finD, rays: 10)
        a.fill([(205, 116), (222, 86), (262, 92), (260, 104)], finC, 0.95)
        a.fin(base: [(235, 228), (330, 248)], edge: [(240, 276), (285, 300), (345, 262)], root: finD, tip: finD, rays: 8)
        a.fin(base: [(490, 268), (560, 276)], edge: [(480, 318), (525, 334), (568, 298)], root: finD, tip: finD, rays: 7)
        let top: [XY] = [(82, 170), (170, 152), (300, 112), (480, 78), (650, 70), (790, 86), (900, 124), (985, 178)]
        let bottom: [XY] = [(82, 194), (170, 208), (300, 236), (480, 268), (650, 276), (790, 262), (900, 226), (985, 188)]
        let back = hex(0x41545f), side = hex(0xbfcdcf), belly = hex(0xf7f8f3)
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = flank(v, back: back, side: side, belly: belly, split: 0.38)
            c += C3(0.12, 0.10, 0.13) * pow(clamp01(1 - abs(v - 0.55) * 3.8), 3)
            let vis = (1 - smooth(0.38, 0.5, v)) * smooth(0.22, 0.3, t)
            c = mix(c, hex(0x12181c), spots(x, y, cell: 25, radius: 6.4, keep: 0.48) * vis)
            c *= 1 - scales(x, y, size: 12) * 0.07
            return rgba(c * (0.7 + 0.36 * roundLight(v)))
        }
        a.fin(base: [(758, 178), (758, 215)], edge: [(675, 196), (650, 226), (690, 262)], root: finC, tip: finD, rays: 8)
        gill(a, 802, 98, 246)
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
        let orange = hex(0xe88424), deep = hex(0xc25b16), blue = hex(0x1f71d0), bright = hex(0x38b1f0)
        wrasseBody(a, shader: { t, v, x, y in
            var c = v < 0.6 ? mix(deep, orange, smooth(0, 0.45, v)) : mix(orange, hex(0xf6c15a), smooth(0.6, 1, v))
            // Blue head and back streaks, typical of the breeding male.
            let wav = artNoise.fbm(x * 0.012, y * 0.02, 2) * 0.08
            let head = smooth(0.70, 0.78, t + wav)
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
        let c1 = hex(0x4f5b62), c2 = hex(0x6a767c)
        a.fill([(92, 148), (10, 40), (8, 66), (28, 150), (0, 240), (60, 186), (92, 174)], c1, 1)
        a.fill([(340, 92), (372, 34), (392, 30), (416, 82)], c1)
        a.line([(358, 92), (366, 22)], hex(0xd8dcd6), 1, 5, smooth: false)
        a.fill([(632, 72), (665, 16), (688, 10), (720, 62)], c1)
        a.line([(650, 74), (660, 6)], hex(0xd8dcd6), 1, 5.5, smooth: false)
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
        let c1 = hex(0x34383a), c2 = hex(0x4b5053)
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

    static func breiflabb(_ a: Art) {
        let skin = hex(0x7a6346), dark = hex(0x45371f), pale = hex(0xc9b794)
        // Tail and fins behind body.
        a.fin(base: [(150, 330), (130, 370), (150, 410)], edge: [(10, 250), (0, 370), (20, 460)], root: dark, tip: skin, rays: 12)
        a.fin(base: [(220, 300), (400, 250)], edge: [(215, 235), (300, 170), (420, 190)], root: dark, tip: skin, rays: 11)
        let top: [XY] = [(140, 340), (250, 300), (390, 248), (520, 188), (680, 140), (820, 142), (925, 190), (985, 286)]
        let bottom: [XY] = [(140, 400), (250, 420), (390, 462), (520, 504), (680, 530), (820, 528), (925, 490), (990, 420)]
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = mix(skin, pale, smooth(0.62, 1.0, v))
            let m = artNoise.fbm(x * 0.017, y * 0.022, 4)
            c = mix(c, dark, smooth(0.46, 0.66, m) * 0.85)
            c = mix(c, hex(0xa58d62), smooth(0.60, 0.74, artNoise.fbm(x * 0.04 + 9, y * 0.05, 3)) * 0.8)
            c *= 1 - spots(x, y, cell: 15, radius: 3.8, keep: 0.45) * 0.28
            _ = t
            return rgba(c * (0.68 + 0.36 * roundLight(v)))
        }
        // Huge upturned mouth.
        a.fill([(990, 330), (850, 360), (690, 345), (640, 318), (700, 400), (860, 425), (985, 392)], hex(0x1e1411), 0.98)
        let lip = hex(0xb29a72)
        a.line([(990, 330), (850, 360), (690, 345), (640, 318)], lip, 1, 8)
        a.line([(985, 394), (860, 427), (700, 402), (640, 318)], lip, 1, 8)
        for i in 0..<22 {
            let t = Double(i) / 21
            let x = 985 - t * 320, yU = 332 + 30 * sin(t * 2.6)
            a.line([(x, yU), (x - 4, yU + 25 + Double(i % 3) * 6)], hex(0xefeadc), 1, 3.2, smooth: false)
            let yL = 394 + 36 * sin(t * 2.5)
            a.line([(x + 4, yL), (x + 1, yL - 19 - Double(i % 2) * 7)], hex(0xefeadc), 0.95, 2.8, smooth: false)
        }
        // Fringe of skin flaps along the jaw.
        for i in 0..<28 {
            let t = Double(i) / 27
            let x = 180 + t * 790, y = 410 + 118 * sin(min(1, t * 1.2) * 1.7) - t * t * 62
            let len = 16 + (i % 4 == 0 ? 24.0 : 7.0)
            a.taper([(x, y), (x + 5, y + len * 0.6), (x - 3, y + len)], 8, 1.5, i % 2 == 0 ? hex(0x6d5a3e) : hex(0xb19b73))
        }
        a.fin(base: [(560, 330), (570, 420)], edge: [(440, 400), (450, 510), (580, 545)], root: skin * 0.9, tip: hex(0x9a8560), rays: 11)
        // Lure rod and flap.
        a.line([(838, 146), (880, 80), (956, 56), (994, 76)], hex(0xbaa881), 1, 5)
        a.taper([(994, 76), (982, 104), (994, 124)], 24, 3, hex(0xe2d5b3))
        a.line([(742, 146), (758, 104), (782, 86)], hex(0xbaa881), 0.95, 3.8)
        a.eye(786, 216, 20, iris: hex(0xc9a853))
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
