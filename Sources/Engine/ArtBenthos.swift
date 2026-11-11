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

    /// Sea urchin, shared by both species with their own colours and spines.
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
}
