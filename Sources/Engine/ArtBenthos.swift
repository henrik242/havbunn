import CoreGraphics
import Foundation

/// Crustaceans, echinoderms, molluscs, cnidarians and algae.
enum BenthosArt {

    // MARK: crustaceans (four-frame walk cycles)

    private static func leg(_ a: Art, _ pts: [XY], _ c: C3, _ w: Double) {
        a.line([pts[0], pts[1]], c * 0.65, 1, w + 3, smooth: false)
        a.line(Array(pts[1...]), c * 0.65, 1, w * 0.9 + 2, smooth: false)
        a.line([pts[0], pts[1]], c, 1, w, smooth: false)
        a.line(Array(pts[1...]), c, 1, w * 0.8, smooth: false)
    }

    /// Clawed lobster in profile, head right. Shared by hummer and sjøkreps.
    static func lobster(_ a: Art, frame: Int, palette p: LobsterPalette) {
        let phase = Double(frame) / 4 * 2 * .pi
        let by = p.bodyY
        let thick = p.thickness

        a.line([(735, by - 30), (800, by - 110), (870, by - 150), (985, by - 165)], p.dark, 0.95, 4.5)
        a.line([(720, by - 34), (640, by - 130), (480, by - 178), (300, by - 170)], p.dark, 0.9, 4.5)

        // Walking legs, far side first.
        for i in 0..<4 {
            let x = 400 + Double(i) * 72
            let ph = phase + Double(i) * .pi / 2
            let farLift = max(0, sin(ph + .pi)) * 24, farSwing = cos(ph + .pi) * 26
            leg(a, [(x + 16, by + 40), (x + 42 + farSwing * 0.5, by + 92 - farLift * 0.5), (x + 28 + farSwing, by + 146 - farLift)], p.leg * 0.55, 9)
            let lift = max(0, sin(ph)) * 24, swing = cos(ph) * 26
            leg(a, [(x, by + 44), (x - 28 + swing * 0.5, by + 100 - lift * 0.5), (x - 12 + swing, by + 158 - lift)], p.leg, 11)
        }

        // Far claw sits behind the body.
        claw(a, x: 742, y: by - 34, length: 215 * p.clawScale, height: 112 * p.clawScale * p.clawDepth, palette: p, shade: 0.62)
        a.taper([(640, by + 8), (700, by - 8), (748, by - 30)], 30, 24, p.leg * 0.6)

        // Tail fan and abdomen.
        for (dy, len) in [(-34.0, 80.0), (0, 96), (34, 80)] {
            a.taper([(112, by + 24), (112 - len * 0.6, by + 24 + dy), (112 - len, by + 28 + dy * 1.8)], 26, 58, p.dark * 1.3)
        }
        let top: [XY] = [(92, by + 8), (170, by - 34 * thick), (290, by - 62 * thick), (410, by - 74 * thick), (540, by - 84 * thick), (660, by - 76 * thick), (760, by - 40 * thick), (830, by - 4)]
        let bottom: [XY] = [(92, by + 42), (170, by + 56 * thick), (290, by + 66 * thick), (410, by + 68 * thick), (540, by + 72 * thick), (660, by + 62 * thick), (760, by + 30 * thick), (830, by + 4)]
        a.body(top: top, bottom: bottom) { t, v, x, y in
            var c = mix(p.back, p.side, smooth(0.08, 0.62, v))
            c = mix(c, p.belly, smooth(0.80, 1, v))
            c = mix(c, p.dark, spots(x, y, cell: 15, radius: 4, keep: 0.65) * p.speckle)
            c = mix(c, p.highlight, spots(x, y, cell: 34, radius: 3, keep: 0.4, seed: 5) * p.speckle * 0.5)
            if x < 400 {
                let seg = abs(sin(x * 0.0425))   // abdomen plates
                c *= 0.58 + 0.50 * pow(seg, 0.45)
            }
            return rgba(c * roundLight(v))
        }
        a.line([(410, by - 74 * thick), (384, by), (420, by + 66 * thick)], p.dark, 0.75, 6)
        a.line([(450, by + 8), (620, by - 12), (790, by - 4)], p.dark, 0.3, 3.5)

        // Near claw held forward, the dominant feature of the animal.
        let raise = sin(phase * 0.5) * 6
        a.taper([(640, by + 40), (705, by + 58 + raise), (762, by + 26 + raise)], 38, 30, p.leg * 0.9)
        claw(a, x: 752, y: by + 18 + raise, length: 240 * p.clawScale, height: 148 * p.clawScale * p.clawDepth, palette: p, shade: 1)
        a.eye(780, by - 32 * thick, p.eye, iris: hex(0x1c1a1a))
    }

    private static func claw(_ a: Art, x: Double, y: Double, length l: Double, height h: Double, palette p: LobsterPalette, shade: Float) {
        let palm: [XY] = [(x, y + 0.1 * h), (x + 0.15 * l, y - 0.42 * h), (x + 0.58 * l, y - 0.60 * h), (x + l, y - 0.30 * h),
                          (x + 0.74 * l, y - 0.06 * h), (x + 0.52 * l, y + 0.08 * h), (x + 0.2 * l, y + 0.36 * h)]
        let finger: [XY] = [(x + 0.34 * l, y + 0.16 * h), (x + 0.68 * l, y + 0.14 * h), (x + 0.97 * l, y - 0.14 * h),
                            (x + 0.8 * l, y + 0.38 * h), (x + 0.42 * l, y + 0.44 * h)]
        a.fill(finger, p.claw * shade * 0.8)
        a.gradient(a.path(palm), [(p.claw * shade * 1.2, 1, 0), (p.claw * shade, 1, 0.5), (p.claw * shade * 0.62, 1, 1)],
                   from: (x, y - 0.6 * h), to: (x, y + 0.36 * h))
        a.ctx.saveGState()
        a.ctx.addPath(a.path(palm))
        a.ctx.clip()
        for _ in 0..<Int(70 * p.speckle) {
            a.disc(x + a.rng.range(0, l), y + a.rng.range(-0.6, 0.4) * h, a.rng.range(1.5, 4.4), p.dark * shade, 0.8)
        }
        a.ctx.restoreGState()
        a.softDot(x + 0.42 * l, y - 0.32 * h, 0.2 * l, p.highlight * shade, 0.5, sy: 0.6)
        if p.banded {
            for f in [0.34, 0.6, 0.82] {
                a.line([(x + f * l, y - 0.50 * h), (x + f * l - 8, y + 0.1 * h)], p.dark, 0.85, 8)
            }
        }
    }

    struct LobsterPalette {
        var back, side, belly, dark, leg, claw, highlight: C3
        var speckle: Float
        var clawScale, clawDepth: Double
        var banded: Bool
        var eye, bodyY, thickness: Double
    }

    static let hummerPalette = LobsterPalette(
        back: hex(0x16243a), side: hex(0x2f4a68), belly: hex(0xb8ae90), dark: hex(0x0a1220),
        leg: hex(0x34506f), claw: hex(0x22385a), highlight: hex(0x7d97b5),
        speckle: 0.9, clawScale: 1.22, clawDepth: 1.0, banded: false, eye: 13, bodyY: 235, thickness: 1.0)

    static let sjokrepsPalette = LobsterPalette(
        back: hex(0xe48e6b), side: hex(0xf5bc9c), belly: hex(0xfbe5d4), dark: hex(0xa24a33),
        leg: hex(0xeca98a), claw: hex(0xf0a78a), highlight: hex(0xffe5d2),
        speckle: 0.2, clawScale: 0.98, clawDepth: 0.55, banded: true, eye: 18, bodyY: 240, thickness: 0.72)

    /// Edible crab from the front and slightly above.
    static func taskekrabbe(_ a: Art, frame: Int) {
        let phase = Double(frame) / 4 * 2 * .pi
        let shell = hex(0x9d5332), edge = hex(0x6c3119), leg = hex(0x8d4a2b)
        let cx = 500.0, cy = 170.0
        for side in [-1.0, 1.0] {
            for i in 0..<4 {
                let ph = phase + Double(i) * .pi / 2 + (side < 0 ? .pi : 0)
                let lift = max(0, sin(ph)) * 22
                let sw = cos(ph) * 20
                let x0 = cx + side * (170 + Double(i) * 28), y0 = cy + 40 + Double(i) * 12
                let knee = (x0 + side * (88 + Double(i) * 22) + sw * 0.4, y0 - 26 - lift * 0.4)
                let foot = (x0 + side * (150 + Double(i) * 26) + sw, y0 + 96 - lift - Double(i) * 8)
                let c = i % 2 == 0 ? leg : leg * 0.82
                a.line([(x0, y0), knee], c * 0.6, 1, 20, smooth: false)
                a.line([knee, foot], c * 0.6, 1, 14, smooth: false)
                a.line([(x0, y0), knee], c, 1, 15, smooth: false)
                a.line([knee, foot], c, 1, 10, smooth: false)
                a.line([foot, (foot.0 + side * 6, foot.1 + 14)], hex(0x151110), 1, 6, smooth: false)
            }
        }
        // Claws in front, with black tips.
        for side in [-1.0, 1.0] {
            let x = cx + side * 150, y = cy + 90
            a.taper([(cx + side * 90, cy + 66), (x, y + 8), (x + side * 8, y + 28)], 44, 34, leg)
            a.fill([(x - 42, y + 12), (x + 42, y + 8), (x + 56, y + 56), (x + 14, y + 96), (x - 40, y + 68)], shell * 1.1)
            a.softDot(x - side * 6, y + 34, 38, hex(0xdc9264), 0.55)
            a.fill([(x + 10, y + 84), (x - 16, y + 118), (x - 26, y + 72)], hex(0x14100e))
            a.fill([(x - 26, y + 72), (x - 36, y + 106), (x - 46, y + 62)], hex(0x14100e))
        }
        // Carapace with pie-crust front edge.
        a.polar(cx: cx, cy: cy, sy: 0.54, maxR: 236, radius: { th in
            let crust = th > 0 ? 8 * abs(sin(th * 11)) : 0
            return 212 + crust
        }) { r, th, x, y in
            var c = mix(hex(0xbb6d44), shell, smooth(0.0, 0.9, r))
            c = mix(c, edge, smooth(0.88, 1, r))
            c *= 0.9 + 0.2 * artNoise.fbm(x * 0.03, y * 0.03, 3)
            let lit = 1.06 - 0.26 * sin(th) * r
            let pits = spots(x, y, cell: 22, radius: 3.2, keep: 0.7)
            c = mix(c, edge, pits * 0.35)
            return rgba(c * lit)
        }
        a.softDot(cx - 40, cy - 40, 110, hex(0xefb48a), 0.32, sy: 0.5)
        a.line([(cx - 34, cy - 34), (cx - 14, cy + 22), (cx + 14, cy + 22), (cx + 34, cy - 34)], edge, 0.35, 4)
        a.disc(cx - 34, cy + 92, 6, hex(0x120d0a), 0.95, sy: 0.6)
        a.disc(cx + 34, cy + 92, 6, hex(0x120d0a), 0.95, sy: 0.6)
    }

    /// Spiny squat lobster from the front and above: a flattened red carapace with blue
    /// transverse lines, long spiny claws held forward, tail tucked under.
    static func krinakrabbe(_ a: Art) {
        let red = hex(0xb8352a), blue = hex(0x3a7ad6)
        let cx = 500.0, cy = 380.0
        for side in [-1.0, 1.0] {
            for i in 0..<3 {
                let x0 = cx + side * (110 + Double(i) * 30), y0 = cy + 40 + Double(i) * 30
                a.line([(x0, y0), (x0 + side * 120, y0 - 30), (x0 + side * 170, y0 + 80)], red * 0.8, 1, 16, smooth: false)
            }
            // Long claws reaching forward and out.
            let arm: [XY] = [(cx + side * 100, cy - 40), (cx + side * 220, cy - 170), (cx + side * 330, cy - 300)]
            a.taper(arm, 46, 30, red)
            for t in stride(from: 0.2, through: 0.9, by: 0.23) {
                let p = (arm[0].0 + (arm[2].0 - arm[0].0) * t, arm[0].1 + (arm[2].1 - arm[0].1) * t)
                a.line([(p.0 - 14, p.1), (p.0 + 14, p.1 + 4)], blue, 0.85, 6, smooth: false)
            }
            let tip = arm[2]
            a.taper([tip, (tip.0 + side * 40, tip.1 - 120)], 30, 6, red * 1.1)
            a.taper([tip, (tip.0 + side * 80, tip.1 - 90)], 26, 6, red * 0.9)
        }
        a.polar(cx: cx, cy: cy, sy: 0.9, maxR: 140, radius: { th in 128 + 6 * abs(sin(th * 9)) }) { r, _, x, y in
            var c = mix(red * 1.12, red * 0.75, r)
            let band = clamp01(1 - abs(sin(y * 0.11)) * 4) * (1 - smooth(0.85, 1, r))
            c = mix(c, blue, band * 0.85)
            c *= 0.9 + 0.2 * artNoise.fbm(x * 0.04, y * 0.04, 2)
            return rgba(c)
        }
        a.disc(cx - 40, cy - 120, 12, hex(0x111111))
        a.disc(cx + 40, cy - 120, 12, hex(0x111111))
    }

    /// Red sea cucumber lying on the bottom: a warty sausage, red above and paler below, with
    /// conical papillae along the back and a fringe of tube feet.
    static func rodpolse(_ a: Art) {
        let top: [XY] = [(40, 220), (150, 150), (400, 122), (700, 126), (900, 160), (970, 222)]
        let bottom: [XY] = [(40, 252), (150, 292), (400, 312), (700, 306), (900, 286), (970, 248)]
        a.body(top: top, bottom: bottom) { _, v, x, y in
            var c = mix(hex(0xa8402a), hex(0xe2a070), smooth(0.4, 1, v))
            c *= 0.9 + 0.2 * artNoise.fbm(x * 0.03, y * 0.05, 3)
            return rgba(c * (0.75 + 0.35 * roundLight(v)))
        }
        var rng = a.rng
        for _ in 0..<26 {
            let x = rng.range(120, 920)
            let yTop = 150 - 60 * sin((x - 40) / 930 * .pi) + 30
            let h = rng.range(20, 44)
            a.taper([(x, yTop + 8), (x + rng.range(-6, 6), yTop - h)], 22, 3, hex(0xc5583a))
            a.disc(x, yTop - h, 4, hex(0xf4d0b0), 0.9)
        }
        for i in 0..<40 {
            let x = 90 + Double(i) * 21
            a.disc(x, 302 + 8 * sin(Double(i)), 7, hex(0xf2c8a8), 0.7)
        }
        a.rng = rng
    }

    /// Common whelk crawling: a spired, ribbed shell over a pale foot, with the siphon tube held
    /// forward and two head tentacles.
    static func kongsnegl(_ a: Art) {
        // Foot, siphon and tentacles under and ahead of the shell.
        a.fill([(120, 640), (300, 590), (700, 590), (930, 620), (960, 660), (700, 690), (300, 690)], hex(0xe6dcc6))
        a.taper([(820, 560), (880, 470), (960, 400)], 44, 30, hex(0xd8ccb2))
        a.taper([(860, 610), (930, 560), (990, 560)], 16, 6, hex(0xe6dcc6))
        a.taper([(840, 612), (900, 540), (950, 520)], 14, 6, hex(0xe6dcc6))
        // Shell: body whorl and a spire of smaller whorls toward the apex.
        let whorls: [(Double, Double, Double, Double)] = [(520, 430, 320, 210), (400, 290, 200, 130), (320, 200, 130, 86), (265, 140, 82, 56), (230, 100, 50, 34)]
        for (i, w) in whorls.enumerated().reversed() {
            let tone = Float(1 - Double(i) * 0.06)
            a.polar(cx: w.0, cy: w.1, sy: w.3 / w.2, maxR: w.2, radius: { _ in Float(w.2) }) { r, th, x, y in
                var c = mix(hex(0xc7ab78), hex(0x8a6e44), smooth(0.2, 1, r)) * tone
                c *= 0.88 + 0.16 * abs(sin(th * 9 + Float(i)))          // axial ribs
                c *= 0.93 + 0.1 * sin(y * 0.2 + Float(i) * 2)           // spiral cords
                c *= 0.95 + 0.1 * artNoise.fbm(x * 0.05, y * 0.05, 2)
                return rgba(c * (1.08 - 0.3 * r * r))
            }
        }
        // Aperture toward the front, under the siphonal canal.
        a.fill([(760, 470), (850, 420), (870, 520), (800, 590), (730, 560)], hex(0x5a3f26), 0.9)
    }

    // MARK: echinoderms

    static func korstroll(_ a: Art) {
        a.polar(cx: 500, cy: 310, sy: 0.62, maxR: 490, radius: { th in
            let arm = pow(abs(cos(2.5 * (th + 0.3))), 2.6)
            return 110 + 370 * arm
        }) { r, th, x, y in
            var c = mix(hex(0xd4792d), hex(0xbe5620), r)
            let arm = pow(abs(cos(2.5 * (th + 0.3))), 8)
            c = mix(c, hex(0xf0c583), arm * 0.55 * (1 - r * 0.3))
            let b = spots(x, y, cell: 20, radius: 5, keep: 0.86)
            c = mix(c, hex(0xf4dcae), b * 0.75)
            let h = 1.12 - 0.42 * pow(r, 2)
            return rgba(c * h)
        }
    }

    static func solstjerne(_ a: Art) {
        let arms: Float = 11
        a.polar(cx: 500, cy: 310, sy: 0.62, maxR: 490, radius: { th in
            260 + 215 * pow(abs(cos(arms * 0.5 * th)), 2.2)
        }) { r, th, x, y in
            let inner = r < 0.52
            var c = inner ? hex(0xe35f4a) : hex(0xc73224)
            c = mix(c, hex(0xf6e1cf), smooth(0.34, 0.5, r) * (1 - smooth(0.52, 0.70, r)))
            let arm = pow(abs(cos(arms * 0.5 * th)), 8)
            if !inner { c = mix(c, hex(0xf9dfc9), arm * 0.3) }
            c = mix(c, hex(0xf4c7b0), spots(x, y, cell: 16, radius: 4.5, keep: 0.8) * 0.65)
            return rgba(c * (1.12 - 0.36 * r))
        }
    }

    static func urchin(_ a: Art, deep: C3, light: C3, spine: C3, length: Double, count: Int, width: Double) {
        let cx = 500.0, cy = 430.0, R = 280.0
        // Back spines, then dome, then front spines for depth.
        func spines(front: Bool) {
            for _ in 0..<count {
                let th = a.rng.range(.pi, 2 * .pi)
                let ring = a.rng.unit()
                let rx = R * (front ? ring : 1)
                let bx = cx + cos(th) * rx
                let by = cy + sin(th) * R * (front ? 0.72 * ring : 0.82)
                let dx = (bx - cx) / R, dy = (by - cy) / R - (front ? 0.45 : 0.15)
                let len = length * a.rng.range(0.8, 1.15)
                let tip = (bx + dx * len, by + dy * len)
                a.taper([(bx, by), ((bx + tip.0) / 2, (by + tip.1) / 2), tip], width, 1.2, front ? spine : spine * 0.62)
            }
        }
        spines(front: false)
        a.polar(cx: cx, cy: cy, sy: 0.82, maxR: R, radius: { th in th > 0 ? Float(R) * (1 - 0.72 * sin(th)) : Float(R) }) { r, th, x, y in
            var c = mix(light, deep, r)
            c *= 0.84 + 0.3 * artNoise.fbm(x * 0.06, y * 0.06, 2)
            let meridian = abs(sin(th * 5))
            c *= 0.9 + 0.14 * meridian
            return rgba(c * (1.1 - 0.5 * pow(r, 3)))
        }
        spines(front: true)
    }

    // MARK: molluscs

    static func kamskjell(_ a: Art) {
        a.polar(cx: 500, cy: 370, sy: 0.72, maxR: 460, radius: { th in
            let sc = 7 * abs(sin(th * 15))
            return (th > 1.1 && th < 2.04) ? 150 + (abs(th - 1.57) * 450) : 420 + sc
        }) { r, th, x, y in
            let ribs = abs(sin(th * 15))
            var c = mix(hex(0xd5a06a), hex(0xbe6c50), smooth(0.2, 1, r))
            c *= 0.76 + 0.34 * pow(ribs, 0.6)
            let growth = sin(r * 44 + artNoise.value(x * 0.01, y * 0.01) * 3)
            c *= 0.95 + 0.05 * growth
            return rgba(c * (0.96 + 0.15 * (1 - r)))
        }
        a.fill([(390, 620), (610, 620), (580, 670), (420, 670)], hex(0xb88358))
    }

    static func oskjell(_ a: Art) {
        // Cluster of horse mussels half buried, with byssus threads.
        for _ in 0..<7 {
            let cx = a.rng.range(130, 870), cy = a.rng.range(180, 340)
            let ang = a.rng.range(-0.8, 0.8)
            a.ctx.saveGState()
            a.ctx.translateBy(x: cx, y: cy)
            a.ctx.rotate(by: CGFloat(ang))
            let shell: [XY] = [(-150, 14), (-80, -60), (60, -86), (160, -24), (150, 40), (40, 72), (-100, 64)]
            a.fill(shell, hex(0x1d1a27))
            a.gradient(a.path(shell), [(hex(0x52466b), 0.9, 0), (hex(0x141219), 0.9, 1)], from: (0, -80), to: (0, 70))
            for i in 1...4 {
                let f = Double(i) * 0.2
                a.line(shell.prefix(5).map { ($0.0 * f, $0.1 * f) }, hex(0x8678a1), 0.25, 4)
            }
            a.line([(-146, 26), (20, 18), (150, 38)], hex(0x0c0a12), 0.7, 4)
            a.ctx.restoreGState()
        }
    }

    // MARK: cnidarians

    /// Plumose anemone: a stout column flaring into a broad, lobed plume of fine tentacles.
    static func sjonellik(_ a: Art, column: C3, crown: C3) {
        let h = a.unitH
        let neck = 470.0
        let col: [XY] = [(300, h), (330, h - 120), (380, h - 280), (330, neck), (670, neck), (620, h - 280), (670, h - 120), (700, h)]
        a.gradient(a.path(col), [(column * 0.55, 1, 0), (column * 0.95, 1, 0.35), (column * 1.02, 1, 0.55), (column * 0.5, 1, 1)],
                   from: (300, 700), to: (700, 700))
        for i in 0..<8 {
            let x = 370 + Double(i) * 37
            a.line([(x + (x - 500) * 0.4, neck + 40), (x + (x - 500) * 0.3, h - 2)], column * 0.6, 0.25, 4)
        }
        var rng = a.rng
        // Lobes, back to front, each a dome of tentacles fanning out from the oral disc.
        let lobes: [(Double, Double, Double, Float)] = [
            (330, 330, 190, 0.62), (670, 330, 190, 0.62), (420, 270, 210, 0.78), (590, 265, 210, 0.78), (500, 300, 230, 0.95),
        ]
        for (lx, ly, r, tone) in lobes {
            for _ in 0..<130 {
                let th = rng.range(-.pi * 1.05, .pi * 0.05)
                let len = r * rng.range(0.55, 1.0)
                let x0 = lx + cos(th) * r * 0.25, y0 = ly + 60 + sin(th) * r * 0.12
                let x1 = lx + cos(th) * len, y1 = max(6, ly + sin(th) * len * 0.85)
                let c = crown * tone * Float(rng.range(0.88, 1.08))
                a.line([(x0, y0), ((x0 + x1) / 2 + rng.range(-8, 8), (y0 + y1) / 2 - 6), (x1, y1)], c, 0.5, 9, smooth: false)
            }
        }
        a.softDot(470, 200, 200, crown, 0.18, sy: 0.6)
        a.rng = rng
    }

    static func dodningehand(_ a: Art) {
        // Thick blunt lobes grown from a shared base, furred with tiny polyps.
        let h = a.unitH
        let base = hex(0xe8d8b6)
        let lobes: [[XY]] = [
            [(290, h - 30), (210, h - 190), (140, h - 300)],
            [(420, h - 30), (390, h - 240), (340, h - 450)],
            [(530, h - 30), (560, h - 220), (530, h - 420)],
            [(640, h - 30), (700, h - 200), (760, h - 340)],
            [(770, h - 20), (850, h - 110), (890, h - 180)],
        ]
        a.disc(500, h - 22, 370, base * 0.55, 1, sy: 0.16)
        for lobe in lobes {
            let line = chaikin(lobe, iterations: 4)
            for (i, q) in line.enumerated() {
                let t = Double(i) / Double(line.count - 1)
                a.disc(q.0, q.1, 88 - 18 * t, base * 0.62)
            }
            for (i, q) in line.enumerated() {
                let t = Double(i) / Double(line.count - 1)
                a.disc(q.0 - 7, q.1 - 4, 75 - 16 * t, base)
            }
            for (i, q) in line.enumerated() where i % 3 == 0 {
                let t = Double(i) / Double(line.count - 1)
                a.softDot(q.0 - 22, q.1 - 10, 44 - 10 * t, C3(1, 0.98, 0.92), 0.28)
            }
            for _ in 0..<130 {
                let q = line[a.rng.int(0, line.count - 1)]
                let px = q.0 + a.rng.range(-70, 70), py = q.1 + a.rng.range(-70, 70)
                a.disc(px, py, 3.0, hex(0xc09a62), 0.6)
                a.disc(px, py - 1, 1.5, C3(1, 0.99, 0.94), 0.95)
            }
        }
    }

    private struct Limb { var pts: [XY]; var w: Double; var depth: Int }

    /// Scales a generated branching colony to fit its cell, rooted at the bottom edge.
    private static func fit(_ limbs: [Limb], _ a: Art) -> [Limb] {
        var minX = Double.infinity, maxX = -Double.infinity, minY = Double.infinity, maxY = -Double.infinity
        for l in limbs { for q in l.pts {
            minX = min(minX, q.0 - l.w); maxX = max(maxX, q.0 + l.w)
            minY = min(minY, q.1 - l.w); maxY = max(maxY, q.1)
        } }
        let s = min(960 / (maxX - minX), (a.unitH - 24) / (maxY - minY))
        let cx = (minX + maxX) / 2
        return limbs.map { l in
            Limb(pts: l.pts.map { (500 + ($0.0 - cx) * s, a.unitH - 4 - (maxY - $0.1) * s) }, w: l.w * s, depth: l.depth)
        }
    }

    /// Branching cold-water reef coral, Desmophyllum pertusum (Lophelia).
    static func lophelia(_ a: Art, base: C3, tip: C3, seed: UInt64) {
        var rng = RNG(seed)
        var limbs: [Limb] = []
        func grow(_ x: Double, _ y: Double, _ ang: Double, _ w: Double, _ depth: Int) {
            var px = x, py = y, th = ang
            var pts: [XY] = [(x, y)]
            for _ in 0..<rng.int(3, 4) {
                th += rng.range(-0.5, 0.5) // the zigzag of sympodial growth
                th += (-.pi / 2 - th) * 0.16
                let len = rng.range(46, 74)
                px += cos(th) * len
                py += sin(th) * len
                pts.append((px, py))
            }
            limbs.append(Limb(pts: pts, w: w, depth: depth))
            guard depth < 4 else { return }
            for _ in 0..<(depth < 2 ? 2 : rng.int(1, 2)) {
                let spread = rng.range(0.35, 0.85) * (rng.chance(0.5) ? 1 : -1)
                let anchor = pts[rng.int(pts.count - 2, pts.count - 1)]
                grow(anchor.0, anchor.1, th + spread, w * rng.range(0.74, 0.86), depth + 1)
            }
        }
        for i in 0..<5 {
            let t = Double(i) / 4
            grow(120 + t * 760, 0, -.pi / 2 + (t - 0.5) * 1.1, 36 + 12 * (1 - abs(t - 0.5) * 2), abs(t - 0.5) > 0.3 ? 1 : 0)
        }
        let fitted = fit(limbs, a)
        // Dead, darker skeleton at the core, living white or orange at the tips.
        for b in fitted.sorted(by: { $0.depth < $1.depth }) {
            let live = min(1, Float(b.depth) / 4)
            let c = mix(base * 0.55, tip, live)
            a.taper(b.pts, b.w * 1.3, b.w * 1.05, c * 0.5)
            a.taper(b.pts, b.w, b.w * 0.8, c)
            a.taper(b.pts.map { ($0.0 - b.w * 0.2, $0.1) }, b.w * 0.34, b.w * 0.24, tip, 0.45)
        }
        for b in fitted where b.depth >= 2 {
            for (j, q) in b.pts.enumerated() where j > 0 {
                let isTip = j == b.pts.count - 1
                guard isTip || rng.chance(0.28) else { continue }
                let side = rng.chance(0.5) ? -1.0 : 1.0
                let cup = max(5, b.w * 0.5)
                let px = q.0 + (isTip ? 0 : side * b.w * 0.75), py = q.1
                a.disc(px, py, cup * 1.16, base * 0.72)
                a.disc(px, py, cup, tip)
                a.disc(px, py, cup * 0.56, hex(0xb98a68))
                for k in 0..<12 {
                    let an = Double(k) / 12 * 2 * .pi
                    a.line([(px + cos(an) * cup * 0.5, py + sin(an) * cup * 0.5),
                            (px + cos(an) * cup * 1.65, py + sin(an) * cup * 1.65)], C3(1, 0.97, 0.92), 0.55, 1.5, smooth: false)
                }
            }
        }
    }

    /// Bubblegum coral, Paragorgia arborea.
    static func sjotre(_ a: Art, base: C3, tip: C3, seed: UInt64) {
        var rng = RNG(seed)
        var limbs: [Limb] = []
        func grow(_ x: Double, _ y: Double, _ ang: Double, _ w: Double, _ depth: Int) {
            var pts: [XY] = [(x, y)]
            var px = x, py = y, th = ang
            for _ in 0..<3 {
                th += rng.range(-0.3, 0.3)
                let len = rng.range(50, 85) * (0.8 + w / 90)
                px += cos(th) * len; py += sin(th) * len
                pts.append((px, py))
            }
            limbs.append(Limb(pts: pts, w: w, depth: depth))
            guard depth < 4 else { return }
            let kids = depth == 0 ? 3 : rng.int(2, 3)
            for i in 0..<kids {
                let f = Double(i) / Double(kids - 1) - 0.5
                grow(px, py, th + f * 1.25 + rng.range(-0.12, 0.12), w * rng.range(0.70, 0.84), depth + 1)
            }
        }
        grow(0, 0, -.pi / 2, 92, 0)
        for l in fit(limbs, a).reversed() {
            let w = l.w, tone = Float(l.depth) / 4
            let shade = Float(0.7 + Double(l.depth) * 0.08)
            a.taper(l.pts, w * 1.12, w, base * shade * 0.65)
            a.taper(l.pts, w, w * 0.88, mix(base, tip, tone) * shade)
            let end = l.pts.last!
            a.disc(end.0, end.1, w * 1.0, tip)
            a.softDot(end.0 - w * 0.2, end.1 - w * 0.2, w * 0.7, C3(1, 0.9, 0.86), 0.7)
            for q in l.pts.dropFirst().dropLast() {
                a.disc(q.0 + rng.range(-w * 0.3, w * 0.3), q.1, w * 0.56, mix(base, tip, tone))
            }
            for _ in 0..<14 {
                let q = l.pts[rng.int(0, l.pts.count - 1)]
                a.disc(q.0 + rng.range(-w * 0.4, w * 0.4), q.1 + rng.range(-w * 0.4, w * 0.4), max(1.6, w * 0.05), C3(1, 0.92, 0.88), 0.85)
            }
        }
    }

    /// Tall sea pen, Funiculina quadrangularis: a slender whip with short, irregular polyps,
    /// no side branches.
    static func sjofjaer(_ a: Art) {
        let h = a.unitH
        let axis: [XY] = [(500, h - 4), (506, h * 0.7), (494, h * 0.4), (504, 10)]
        a.taper(axis, 60, 22, hex(0xd9cbb2))
        a.taper(axis.map { ($0.0 - 8, $0.1) }, 18, 6, hex(0xf3eadb), 0.7)
        var rng = a.rng
        for i in 0..<70 {
            let t = Double(i) / 69
            let y = h * 0.88 - t * h * 0.86
            let x = 500 + sin(t * 3) * 6
            let side = rng.chance(0.5) ? -1.0 : 1.0
            let len = rng.range(30, 90) * (1 - t * 0.5)
            let tip = (x + side * len, y - rng.range(10, 30))
            a.line([(x, y), tip], hex(0xf2e2cf), 0.85, 20)
            a.disc(tip.0, tip.1, 22, hex(0xfbeee0), 0.9)
        }
        a.rng = rng
    }

    // MARK: kelp

    /// Laminaria hyperborea: stiff stipe holding a broad blade split into straps.
    static func stortare(_ a: Art, seed: UInt64) {
        var rng = RNG(seed)
        let h = a.unitH
        let crown: XY = (500 + rng.range(-30, 30), h * 0.56)
        // The whole blade streams one way in the current, so it never reads as a symmetric cup.
        let sweep = (rng.chance(0.5) ? 1.0 : -1.0) * rng.range(170, 300)
        let straps = 17
        var order = Array(0..<straps)
        for i in order.indices.reversed() { order.swapAt(i, rng.int(0, i)) }
        for (rank, i) in order.enumerated() {
            let t = Double(i) / Double(straps - 1)
            let spread = t - 0.5
            let startX = crown.0 + spread * 300
            let startY = crown.1 - 120 - (0.25 - spread * spread) * 300
            let len = rng.range(0.72, 1.0) * (crown.1 - 40)
            let tipX = startX + spread * 340 + sweep * rng.range(0.7, 1.2)
            let tipY = max(14, crown.1 - len)
            let wig = rng.range(30, 90) * (rng.chance(0.5) ? 1 : -1)
            let pts: [XY] = [(crown.0 + spread * 90, crown.1 - 30), (startX, startY),
                             (startX + (tipX - startX) * 0.28 + wig, startY + (tipY - startY) * 0.35),
                             (startX + (tipX - startX) * 0.66 - wig, startY + (tipY - startY) * 0.68), (tipX, tipY)]
            let depth = Float(rank) / Float(straps - 1)
            let c = mix(hex(0x5a3f17), hex(0xa98336), depth * 0.75 + Float(rng.unit()) * 0.25)
            a.taper(pts, rng.range(78, 118), rng.range(18, 34), c)
            a.taper(pts.map { ($0.0 - 7, $0.1) }, 14, 5, hex(0xd7b464), 0.2)
        }
        let palm: [XY] = [(crown.0, crown.1 + 6), (crown.0 - 110, crown.1 - 70), (crown.0 - 170, crown.1 - 210),
                          (crown.0, crown.1 - 280), (crown.0 + 170, crown.1 - 210), (crown.0 + 110, crown.1 - 70)]
        a.gradient(a.path(palm), [(hex(0x4a3211), 1, 0), (hex(0x7c5f27), 0.9, 0.6), (hex(0x7c5f27), 0, 1)],
                   from: (crown.0, crown.1), to: (crown.0, crown.1 - 280))
        let st: [XY] = [(500, h - 2), (520 + rng.range(-20, 20), h * 0.76), crown]
        a.taper(st, 74, 40, hex(0x4e3b1c))
        a.taper(st.map { ($0.0 - 9, $0.1) }, 30, 14, hex(0x7d6333), 0.8)
        for _ in 0..<34 {
            let t = rng.range(0.70, 0.98)
            let x = 500 + rng.range(-38, 38), y = h * t
            a.line([(x, y), (x + rng.range(-46, 46), y - rng.range(16, 44))], hex(0x8d2d38), 0.85, 6)
        }
        for i in 0..<9 {
            let x = 500 + (Double(i) - 4) * 40
            a.taper([(500, h - 50), (x, h - 24), (x + (x - 500) * 0.3, h - 1)], 26, 12, hex(0x3d2d13))
        }
    }

    /// Saccharina latissima: one long ruffled blade.
    static func sukkertare(_ a: Art, seed: UInt64) {
        var rng = RNG(seed)
        let h = a.unitH
        a.taper([(500, h - 2), (505, h * 0.9), (495, h * 0.84)], 34, 22, hex(0x4b3819))
        let n = 46
        var left: [XY] = [], right: [XY] = []
        for i in 0...n {
            let t = Double(i) / Double(n)
            let y = h * 0.86 - t * (h * 0.85)
            let spine = 500 + sin(t * 5 + 1) * 62 * t
            let width = 250 * pow(sin(min(1, t * 1.25 + 0.05) * .pi * 0.92), 0.6) * (1 - t * 0.55)
            let ruffleL = sin(t * 46 + 0.4) * 34 * t + sin(t * 91) * 10
            let ruffleR = sin(t * 49 + 2.1) * 34 * t + sin(t * 87) * 10
            left.append((spine - width + ruffleL, y))
            right.append((spine + width + ruffleR, y))
        }
        let blade = a.path(left + right.reversed(), closed: true, smooth: true)
        a.gradient(blade, [(hex(0x6f5120), 1, 0), (hex(0xa98336), 1, 0.45), (hex(0xbd983f), 0.97, 1)], from: (500, h), to: (500, 0))
        a.ctx.saveGState()
        a.ctx.addPath(blade)
        a.ctx.clip()
        // Dark and bright bands from the characteristic frilled edges.
        for i in 0..<40 {
            let t = rng.unit()
            let y = h * 0.86 - t * h * 0.85
            let light = i % 2 == 0
            let c = light ? hex(0xe0bb5c) : hex(0x3f2c0f)
            let bow = rng.range(-22, 22)
            a.line([(100, y + bow), (300, y - bow), (500, y + bow * 0.5), (700, y - bow), (900, y + bow)], c, light ? 0.10 : 0.11, rng.range(14, 40))
        }
        let spine = (0...n).map { i -> XY in
            let t = Double(i) / Double(n)
            return (500 + sin(t * 5 + 1) * 62 * t, h * 0.86 - t * h * 0.85)
        }
        a.taper(spine, 150, 50, hex(0x5a3f18), 0.40)
        for _ in 0..<70 {
            a.softDot(rng.range(260, 760), rng.range(10, h * 0.85), rng.range(12, 34), hex(0xd4b360), 0.10, sy: 1.4)
        }
        a.ctx.restoreGState()
    }

    /// Sea gooseberry, a comb jelly: a clear oval with eight rows of iridescent combs and two
    /// trailing, side-branched tentacles.
    static func seaGooseberry(_ a: Art) {
        let cx = 500.0, cy = 280.0, rx = 230.0, ry = 260.0
        let tentacle = C3(0.95, 0.90, 0.85)
        for side in [-1.0, 1.0] {
            var pts: [XY] = []
            for i in 0...8 {
                let t = Double(i) / 8
                pts.append((cx + side * 40 + sin(t * 5 + side) * 70 * t, cy + ry * 0.8 + t * (a.unitH - 20 - cy - ry * 0.8)))
            }
            a.line(pts, tentacle, 0.45, 10)
            for i in 1..<8 { a.line([pts[i], (pts[i].0 + side * 60, pts[i].1 + 30)], tentacle, 0.3, 6) }
        }
        a.polar(cx: cx, cy: cy, sy: ry / rx, maxR: rx, radius: { _ in Float(rx) }) { r, _, _, _ in
            rgba(mix(hex(0xd9ece7), hex(0xf6fbfa), r), 0.10 + 0.42 * pow(r, 4))
        }
        let combs: [C3] = [hex(0x8fe3ff), hex(0xffa6dc), hex(0xfff09e), hex(0xa6ffc2)]
        for k in -3...3 where k != 0 {
            let xo = Double(k) / 3.6 * rx
            let span = ry * (1 - (xo / rx) * (xo / rx)).squareRoot() * 0.85
            var i = 0
            var y = cy - span
            while y < cy + span {
                a.disc(cx + xo, y, 13, combs[(i + k + 8) % combs.count], 0.55)
                y += 34
                i += 1
            }
        }
    }

    // MARK: utility

    static func shadow(_ a: Art) {
        let c = a.unitH / 2
        a.softDot(500, c, 495, C3(0, 0, 0), 0.72, sy: a.unitH / 1000)
    }
}
