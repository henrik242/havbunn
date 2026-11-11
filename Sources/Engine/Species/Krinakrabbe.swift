import CoreGraphics
import Foundation

extension Species {
    static let krinakrabbe = SpeciesInfo(
        key: "krinakrabbe", norsk: "Krinakrabbe", latin: "Galathea strigosa", english: "Spiny squat lobster",
        sprites: [SpriteDef(name: "krinakrabbe", w: 260, h: 150, paint: draw)],
        place: { scene in
            // Keeps to crevices at the reef foot.
            for _ in 0..<5 {
                guard let s = scene.findSpot(z: 4...10, rock: 0.4...0.8) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.09, 0.12), mode: 0, amp: 0, shadowW: 0.07)
            }
        })
}

/// Spiny squat lobster (Galathea strigosa) from the front and slightly above: a flattened,
/// spiny orange-red carapace with a toothed rostrum, long slender spiny chelipeds held
/// forward, three pairs of jointed walking legs, the abdomen curled under, and the
/// diagnostic muted steel-blue transverse bands across carapace, legs and claws.
private func draw(_ a: Art) {
    let red = hex(0xb04634)      // muted orange-red body
    let redHi = hex(0xca5c3f)    // lit highlight
    let redDk = hex(0x6f2b21)    // shadow / rim
    let blue = hex(0x5c82b2)     // restrained steel/cornflower blue bands
    let spine = hex(0xd68a5c)    // warm spine tips
    let cx = 500.0, cy = 334.0

    // Walking legs fan out behind the carapace (drawn first so the shell covers their roots).
    for side in [-1.0, 1.0] {
        let legs: [(XY, XY, XY, Double)] = [
            ((cx + side * 92, cy - 24), (cx + side * 214, cy - 74), (cx + side * 312, cy + 2), 21),
            ((cx + side * 104, cy + 34), (cx + side * 226, cy + 24), (cx + side * 330, cy + 86), 20),
            ((cx + side * 100, cy + 88), (cx + side * 206, cy + 120), (cx + side * 288, cy + 196), 18),
        ]
        for (root, knee, foot, w) in legs {
            jointLeg(a, root, knee, foot, w: w, red: red, redDk: redDk, blue: blue, spine: spine, side: side)
        }
    }

    // Chelipeds: long, slender, spiny, held forward and out.
    for side in [-1.0, 1.0] {
        cheliped(a, side: side, cx: cx, cy: cy, red: red, redDk: redDk, redHi: redHi, blue: blue, spine: spine)
    }

    // Abdomen curled under: a few segmented plates peeking below the shell rear.
    for i in 0..<3 {
        let yy = cy + 118 + Double(i) * 40
        let wd = 150.0 - Double(i) * 36
        let shade = Float(1.0 - 0.07 * Double(i))
        a.fill([(cx - wd, yy - 10), (cx - wd * 0.72, yy + 20), (cx, yy + 28),
                (cx + wd * 0.72, yy + 20), (cx + wd, yy - 10), (cx, yy - 2)], red * shade)
        a.line([(cx - wd * 0.92, yy + 1), (cx, yy + 10), (cx + wd * 0.92, yy + 1)], blue, 0.75, 5)
        a.line([(cx - wd, yy - 10), (cx, yy - 2), (cx + wd, yy - 10)], redDk, 0.5, 3)
    }

    // Flattened carapace with spiny margins and blue transverse bands.
    a.polar(cx: cx, cy: cy, sy: 1.08, maxR: 152, radius: { th in
        let f = sin(th)            // +1 toward back/down, -1 toward front/up
        var R = 126 + 9 * f        // broader at the back
        R -= 12 * max(0, -f)       // narrows toward the rostrum
        let margin = smooth(0.55, -0.85, f)          // 1 at front edges, 0 at back
        R += (2.6 + 3.2 * margin) * max(0, sin(th * 12))   // marginal spines
        return R
    }) { r, th, x, y in
        var c = mix(red * 1.05, red * 0.94, smooth(0.1, 0.92, r))   // flat, lightly domed
        c = mix(c, redDk, smooth(0.88, 1.0, r))
        let f = sin(th)
        let lit = 1.05 - 0.15 * f * smooth(0.1, 1.0, r)      // darker toward the rear rim
        c *= 0.92 + 0.15 * artNoise.fbm(x * 0.05, y * 0.05, 3)
        let pit = spots(x, y, cell: 19, radius: 2.4, keep: 0.58)
        c = mix(c, redDk, pit * 0.3)
        let spk = spots(x, y, cell: 46, radius: 3.0, keep: 0.5)  // scattered tubercles
        c = mix(c, spine, spk * 0.18 * (1 - smooth(0.75, 1.0, r)))
        // Transverse blue bands, gently arched, fading into the rim.
        let yy = (y - Float(cy)) + 15 * cos((x - Float(cx)) * 0.012)
        let band = clamp01(1 - abs(sin(yy * 0.05)) * 3.0) * (1 - smooth(0.8, 1.0, r))
        c = mix(c, blue, band * 0.8)
        return rgba(c * lit)
    }
    // Faint specular on the upper-left of the shell (kept low so it reads flat).
    a.softDot(cx - 30, cy - 46, 118, redHi, 0.13, sy: 0.82)

    // Rostrum: a toothed spike projecting forward between the eyes.
    let rBase = cy - 142.0, rTip = cy - 244.0
    a.taper([(cx, rBase), (cx, rTip)], 42, 5, red)
    a.line([(cx, rBase + 6), (cx, rTip)], redDk, 0.4, 3)       // median groove
    a.line([(cx, rBase - 26), (cx, rTip + 6)], blue, 0.4, 3)   // blue median line
    for side in [-1.0, 1.0] {
        // marginal teeth down the rostrum edge
        for t in stride(from: 0.2, through: 0.78, by: 0.28) {
            let yy = rBase + (rTip - rBase) * t
            let hw = (18.0 * (1 - t)) + 3
            a.line([(cx + side * hw, yy), (cx + side * (hw + 11), yy - 7)], spine, 0.9, 3)
        }
        // supraorbital spines flanking the base
        a.line([(cx + side * 26, rBase - 2), (cx + side * 44, rBase - 30)], spine, 0.9, 4)
    }

    // Stalked eyes at the rostrum base.
    for side in [-1.0, 1.0] {
        let b = (cx + side * 30, cy - 136), eb = (cx + side * 54, cy - 170)
        a.line([b, eb], red, 1, 16, smooth: false)
        a.line([b, eb], redHi, 0.45, 7, smooth: false)
        a.disc(eb.0, eb.1, 15, redDk)
        a.disc(eb.0, eb.1, 12, hex(0x130a09))
        a.softDot(eb.0, eb.1, 12, hex(0x3c201a), 0.55)
        a.disc(eb.0 - side * 3.5, eb.1 - 4, 3.6, C3(1, 1, 1), 0.5)
    }
}

/// A short blue cross-band on a limb at parameter t, half-width `half`.
private func limbBand(_ a: Art, _ p0: XY, _ p1: XY, _ t: Double, _ half: Double, _ blue: C3, _ w: Double) {
    let px = p0.0 + (p1.0 - p0.0) * t, py = p0.1 + (p1.1 - p0.1) * t
    var dx = p1.0 - p0.0, dy = p1.1 - p0.1
    let L = max(1e-6, (dx * dx + dy * dy).squareRoot()); dx /= L; dy /= L
    let nx = -dy, ny = dx
    a.line([(px - nx * half, py - ny * half), (px + nx * half, py + ny * half)], blue, 0.85, w, smooth: false)
}

/// Short outward-raked spines along the outer edge of a limb segment.
private func limbSpines(_ a: Art, _ p0: XY, _ p1: XY, side: Double, _ c: C3, _ n: Int, len: Double) {
    var dx = p1.0 - p0.0, dy = p1.1 - p0.1
    let L = max(1e-6, (dx * dx + dy * dy).squareRoot()); dx /= L; dy /= L
    let nx = -dy * side, ny = dx * side
    for i in 1...n {
        let t = Double(i) / Double(n + 1)
        let px = p0.0 + (p1.0 - p0.0) * t, py = p0.1 + (p1.1 - p0.1) * t
        a.line([(px, py), (px + nx * len - dx * len * 0.35, py + ny * len - dy * len * 0.35)], c, 0.9, 3, smooth: false)
    }
}

/// A jointed, tapered walking leg with a blue band, spines and a dark pointed tip.
private func jointLeg(_ a: Art, _ root: XY, _ knee: XY, _ foot: XY, w: Double,
                      red: C3, redDk: C3, blue: C3, spine: C3, side: Double) {
    a.line([root, knee], redDk, 1, w + 5, smooth: false)
    a.line([knee, foot], redDk, 1, w * 0.72 + 4, smooth: false)
    a.line([root, knee], red, 1, w, smooth: false)
    a.line([knee, foot], red, 1, w * 0.68, smooth: false)
    a.line([root, knee], red * 1.14, 0.45, w * 0.38, smooth: false)   // top light
    limbBand(a, root, knee, 0.6, w * 0.66, blue, 4)
    limbSpines(a, root, knee, side: side, spine, 2, len: 7)
    let tip = (foot.0 + (foot.0 - knee.0) * 0.17, foot.1 + (foot.1 - knee.1) * 0.17)
    a.line([foot, tip], hex(0x251511), 1, w * 0.42, smooth: false)
}

/// A long, slender, spiny cheliped with a pincer, blue bands and a dark-tipped grip.
private func cheliped(_ a: Art, side: Double, cx: Double, cy: Double,
                      red: C3, redDk: C3, redHi: C3, blue: C3, spine: C3) {
    let base = (cx + side * 70, cy - 78)
    let elbow = (cx + side * 172, cy - 150)
    let wrist = (cx + side * 262, cy - 196)
    let hand = (cx + side * 312, cy - 216)      // base of the fingers

    // Underlying shadow, then the tapered merus + carpus.
    a.line([base, elbow], redDk, 1, 40, smooth: false)
    a.line([elbow, wrist], redDk, 1, 33, smooth: false)
    a.taper([base, elbow, wrist], 33, 23, red)
    a.line([base, elbow, wrist], redHi, 0.5, 9, smooth: false)
    limbSpines(a, base, elbow, side: side, spine, 3, len: 10)
    limbSpines(a, elbow, wrist, side: side, spine, 3, len: 9)
    limbBand(a, base, elbow, 0.5, 19, blue, 5)
    limbBand(a, elbow, wrist, 0.5, 15, blue, 5)

    // Propodus (palm), then the two slender pincer fingers, open in a V.
    a.taper([wrist, hand], 23, 22, red)
    a.softDot(hand.0, hand.1, 20, redHi, 0.3, sy: 1)      // palm swelling
    limbBand(a, wrist, hand, 0.46, 16, blue, 4)
    let mid = (wrist.0 * 0.2 + hand.0 * 0.8, wrist.1 * 0.2 + hand.1 * 0.8)
    let fix = (hand.0 + side * 74, hand.1 - 46)     // fixed finger (outer)
    let dac = (hand.0 + side * 20, hand.1 - 68)     // dactyl (inner)
    a.taper([mid, fix], 22, 2, red)
    a.taper([(hand.0 + side * 2, hand.1 - 2), dac], 18, 2, redHi)
    a.line([mid, fix], redHi, 0.4, 5, smooth: false)
    limbSpines(a, hand, fix, side: side, spine, 2, len: 8)
    a.disc(fix.0, fix.1, 5, hex(0x2a1712))
    a.disc(dac.0, dac.1, 5, hex(0x2a1712))
}
