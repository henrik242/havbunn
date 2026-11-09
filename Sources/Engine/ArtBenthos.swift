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
        back: hex(0x17335f), side: hex(0x41709f), belly: hex(0xd6cba8), dark: hex(0x0c1a33),
        leg: hex(0x3f659a), claw: hex(0x28518a), highlight: hex(0x9dbde0),
        speckle: 0.9, clawScale: 1.0, clawDepth: 1.0, banded: false, eye: 13, bodyY: 235, thickness: 1.0)

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
        a.eye(cx - 34, cy + 94, 9, iris: hex(0x1d1612))
        a.eye(cx + 34, cy + 94, 9, iris: hex(0x1d1612))
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

    static func sjonellik(_ a: Art, column: C3, crown: C3) {
        let h = a.unitH
        let dome: (x: Double, y: Double) = (500, 330)
        // Stout column flaring at the foot, half hidden by the plume.
        let col: [XY] = [(250, h), (300, h - 90), (345, h - 260), (310, dome.y), (690, dome.y), (655, h - 260), (700, h - 90), (750, h)]
        a.gradient(a.path(col), [(column * 0.5, 1, 0), (column * 0.95, 1, 0.32), (column * 1.08, 1, 0.5), (column * 0.48, 1, 1)],
                   from: (290, 700), to: (710, 700))
        for i in 0..<9 {
            let x = 340 + Double(i) * 40
            a.line([(x, dome.y + 60), (x + (x - 500) * 0.3, h - 2)], column * 0.6, 0.3, 5)
        }
        // Solid underlayer so the plume never looks hollow.
        a.disc(dome.x, dome.y + 8, 400, crown * 0.42, 1, sy: 0.72)
        var rng = a.rng
        // Lobed plume of fine tentacles, dark and deep first, light on top.
        for layer in 0..<4 {
            let b = 1 - Double(layer) * 0.2
            let tone = Float(0.58 + Double(layer) * 0.16)
            for _ in 0..<420 {
                let th = rng.range(.pi * 0.86, 2.14 * .pi)
                let lobe = 1 + 0.15 * sin(th * 8 + Double(layer) * 1.3)
                let reach = rng.range(0.72, 1.0) * 480 * b * lobe
                let root = reach * 0.32
                let x0 = dome.x + cos(th) * root, y0 = dome.y + sin(th) * root * 0.62
                let x1 = dome.x + cos(th) * reach, y1 = max(4, dome.y + sin(th) * reach * 0.68)
                let c = crown * tone * Float(rng.range(0.9, 1.1))
                a.line([(x0, y0), ((x0 + x1) / 2 + rng.range(-9, 9), (y0 + y1) / 2 - 9), (x1, y1)], c, 0.65, 2.4, smooth: false)
            }
        }
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
                let cup = max(7, b.w * 0.74)
                let px = q.0 + (isTip ? 0 : side * b.w * 0.75), py = q.1
                a.disc(px, py, cup * 1.16, base * 0.72)
                a.disc(px, py, cup, tip)
                a.disc(px, py, cup * 0.56, hex(0xb98a68))
                for k in 0..<12 {
                    let an = Double(k) / 12 * 2 * .pi
                    a.line([(px + cos(an) * cup * 0.5, py + sin(an) * cup * 0.5),
                            (px + cos(an) * cup * 1.65, py + sin(an) * cup * 1.65)], C3(1, 0.97, 0.92), 0.85, 1.7, smooth: false)
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
        grow(0, 0, -.pi / 2, 72, 0)
        for l in fit(limbs, a).reversed() {
            let w = l.w, tone = Float(l.depth) / 4
            let shade = Float(0.7 + Double(l.depth) * 0.08)
            a.taper(l.pts, w * 1.12, w, base * shade * 0.65)
            a.taper(l.pts, w, w * 0.88, mix(base, tip, tone) * shade)
            let end = l.pts.last!
            a.disc(end.0, end.1, w * 0.72, tip)
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

    /// Tall sea pen, Funiculina quadrangularis. Very narrow cell.
    static func sjofjaer(_ a: Art) {
        let h = a.unitH
        a.taper([(500, h - 4), (510, h * 0.6), (490, h * 0.3), (510, 12)], 75, 25, hex(0xdac7a4))
        var rng = a.rng
        for i in 0..<92 {
            let t = Double(i) / 91
            let y = h * 0.85 - t * (h * 0.84)
            let x = 500 + sin(t * 3) * 10
            let span = 200 - t * 110
            for side in [-1.0, 1.0] {
                let wob = rng.range(-16, 16)
                a.taper([(x, y), (x + side * span * 0.6, y - 20 + wob), (x + side * span, y - 28 + wob)], 22, 8, hex(0xeed8b4), 0.95)
                a.disc(x + side * span, y - 28 + wob, 13, hex(0xfff0d8), 0.95)
            }
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

    // MARK: utility

    static func shadow(_ a: Art) {
        let c = a.unitH / 2
        a.softDot(500, c, 495, C3(0, 0, 0), 0.72, sy: a.unitH / 1000)
    }
}
