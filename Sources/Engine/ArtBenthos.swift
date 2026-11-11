import CoreGraphics
import Foundation

/// Drawing shared by several bottom species.
enum BenthosArt {

    // MARK: lobsters (four-frame walk cycles)

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

    // MARK: branching colonies

    struct Limb { var pts: [XY]; var w: Double; var depth: Int }

    /// Scales a generated branching colony to fit its cell, rooted at the bottom edge.
    static func fit(_ limbs: [Limb], _ a: Art) -> [Limb] {
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

    // MARK: urchins

    /// A single radiating spine: one sphere point, projected with foreshortening.
    private struct Spine {
        var bx, by, ox, oy, px, py, depth, w, fore: Double
    }

    /// Sea urchin: a domed test seen at a low angle, with spines radiating all the
    /// way round. Each spine sits on a point of a squashed sphere and is foreshortened
    /// by how far it leans toward the viewer, so rim spines are long and near-face ones
    /// shrink to stubs — revealing the test and its pale tubercles between them.
    ///
    /// - length/count/width: spine reach, how many, base thickness.
    /// - tipWidth/tipPale: blunt vs needle tips, and how much paler the tips go.
    /// - tubercleN/tubercleR/tubercleA: pale bumps dotting the test's near face.
    static func urchin(_ a: Art, deep: C3, light: C3, spine: C3,
                       length: Double, count: Int, width: Double,
                       tipWidth: Double = 1.2, tipPale: Float = 0.45,
                       tubercleN: Int = 110, tubercleR: Double = 8, tubercleA: Double = 0.35) {
        let cx = 500.0, cy = a.unitH / 2, R = 236.0
        let tilt = 0.58                       // low-angle view: looking slightly down
        let cosT = cos(tilt), sinT = sin(tilt)
        let sy = cosT                         // the test's vertical squash falls out of the tilt
        let pale = mix(spine, hex(0xf0ece2), tipPale)   // sun-bleached spine tips
        let paleBack = mix(spine * 0.62, hex(0x9a9a8c), tipPale * 0.5)
        let bump = mix(light, hex(0xf2ece0), 0.4)       // tubercle cap

        // Lay every spine out once, then sort by depth so they stack back-to-front.
        var spines: [Spine] = []
        spines.reserveCapacity(count)
        for _ in 0..<count {
            let az = a.rng.range(0, 2 * .pi)
            let el = asin(a.rng.range(-1, 1))           // uniform over the sphere
            let ce = cos(el), se = sin(el)
            let vx = ce * cos(az), vy = se, vz = ce * sin(az)
            let up = vy * cosT - vz * sinT              // screen-up component (world up)
            let depth = vy * sinT + vz * cosT           // +toward viewer
            let bx = cx + R * vx, by = cy - R * up
            let len = length * a.rng.range(0.78, 1.10)
            // Projected offset keeps the foreshortening: |(vx,-up)| = sqrt(1-depth^2).
            let ox = len * vx, oy = -len * up
            let bend = a.rng.range(-1, 1) * len * 0.05
            let m = max(1e-4, (ox * ox + oy * oy).squareRoot())
            let px = -oy / m * bend, py = ox / m * bend // sideways kink at the midpoint
            let fore = (max(0, 1 - depth * depth)).squareRoot()   // 1 at the rim, 0 head-on
            spines.append(Spine(bx: bx, by: by, ox: ox, oy: oy, px: px, py: py,
                                depth: depth, w: width * a.rng.range(0.82, 1.18), fore: fore))
        }
        spines.sort { $0.depth < $1.depth }

        func draw(_ s: Spine, base: C3, tip: C3) {
            let mx = s.bx + s.ox * 0.5 + s.px, my = s.by + s.oy * 0.5 + s.py
            let tx = s.bx + s.ox, ty = s.by + s.oy
            a.taper([(s.bx, s.by), (mx, my), (tx, ty)], s.w, tipWidth, base)
            // Bleached tips only where the spine lies across the view; head-on stubs
            // keep the base colour so they don't flare into a bright central burst.
            let t = mix(base, tip, Float(s.fore))
            a.taper([(mx, my), ((mx + tx) / 2 + s.px * 0.5, (my + ty) / 2 + s.py * 0.5), (tx, ty)],
                    s.w * 0.6, tipWidth, t)
        }

        // Spines on the far side sit behind the body; draw them first and dimmer.
        for s in spines where s.depth < 0 { draw(s, base: spine * 0.6, tip: paleBack) }

        // The test: a domed sphere, lit soft from the upper left.
        let lx: Float = -0.42, ly: Float = -0.52, lz: Float = 0.74   // screen x, y(down), toward
        a.polar(cx: cx, cy: cy, sy: sy, maxR: R, radius: { _ in Float(R) }) { r, th, x, y in
            let nx = cos(th) * r, ny = sin(th) * r
            let nz = (max(0, 1 - r * r)).squareRoot()
            let diff = clamp01(nx * lx + ny * ly + nz * lz)
            var c = mix(deep, light, clamp01(0.22 + 0.9 * diff))
            c = mix(c, deep * 0.8, clamp01(pow(r, 3) * 0.7))        // shaded rim
            let meridian = abs(sin(th * 5))                         // faint five-fold sections
            c *= 0.95 + 0.07 * meridian
            c *= 0.9 + 0.2 * artNoise.fbm(x * 0.05, y * 0.05, 2)    // mottled skin
            return rgba(c)
        }

        // Pale tubercles scattered over the near face, showing between the spines.
        for _ in 0..<tubercleN {
            let az = a.rng.range(0, 2 * .pi)
            let el = asin(a.rng.range(-1, 1))
            let ce = cos(el), se = sin(el)
            let vx = ce * cos(az), vy = se, vz = ce * sin(az)
            let up = vy * cosT - vz * sinT
            let depth = vy * sinT + vz * cosT
            if depth <= 0.08 { continue }
            let bx = cx + R * vx * 0.985, by = cy - R * up * 0.985
            let sz = tubercleR * (0.55 + 0.6 * depth)
            // A soft-edged bump: shadow halo below, pale rounded cap, soft top light.
            a.softDot(bx, by + sz * 0.18, sz * 1.15, deep, tubercleA * 0.55, sy: sy)
            a.softDot(bx, by - sz * 0.06, sz, bump, tubercleA, sy: sy)
            a.softDot(bx - sz * 0.18, by - sz * 0.22, sz * 0.5, pale, tubercleA * 0.5, sy: sy)
        }

        // Near-side spines on top, full brightness.
        for s in spines where s.depth >= 0 { draw(s, base: spine, tip: pale) }
    }
}
