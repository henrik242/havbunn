import CoreGraphics
import Foundation

extension Species {
    static let glassmanet = SpeciesInfo(
        key: "glassmanet", norsk: "Glassmanet", latin: "Aurelia aurita", english: "Moon jelly",
        sprites: [SpriteDef(name: "glassmanet", w: 360, h: 288, paint: draw)],
        place: { scene in
            scene.addJellies(JellySpec(count: 6, z: 6...20, y: 2.5...7, width: 0.2...0.32, drift: 0.05, rate: 1.3...1.9))
        })
}

// Centre and silhouette of the saucer-shaped bell, shared by every pass so the
// gonads, canals and tentacle fringe all line up with the same rim.
private let cx = 500.0, cy = 356.0, bellSy = 0.58, bellR = 338.0

/// Bell radius for a polar angle (y points down, so th>0 is the near/lower rim,
/// pulled in and flattened by foreshortening). Eight gentle marginal scallops.
private func bellRim(_ th: Double) -> Double {
    let scallop = 5.0 * sin(th * 8)
    return th > 0 ? bellR * (1 - 0.55 * sin(th)) + scallop : bellR + scallop
}

private func rimPoint(_ th: Double, _ frac: Double = 1) -> XY {
    let r = bellRim(th) * frac
    return (cx + cos(th) * r, cy + sin(th) * r * bellSy)
}

/// A horseshoe outline (open C) whose gap faces `opening`, squashed like the bell.
private func horseshoe(_ c: XY, _ r: Double, opening: Double, gap: Double) -> [XY] {
    let a0 = opening + gap / 2, a1 = opening + 2 * .pi - gap / 2
    let steps = 44
    return (0...steps).map { i -> XY in
        let ang = a0 + (a1 - a0) * Double(i) / Double(steps)
        return (c.0 + cos(ang) * r, c.1 + sin(ang) * r * bellSy)
    }
}

/// One frilly, nearly colourless oral arm hanging from the central mouth.
private func oralArm(_ a: Art, dir: Double, len: Double, sway: Double, seed: Double) {
    let n = 12
    var mid: [XY] = []
    for i in 0...n {
        let t = Double(i) / Double(n)
        let yy = cy + 6 + t * len
        let xx = cx + dir * len * 0.34 * t + sin(seed + t * 5.2) * sway * t
        mid.append((xx, yy))
    }
    // Soft translucent curtain of the arm.
    a.taper(mid, 50, 7, hex(0xe7edee), 0.12)
    // Ruffled edges: a wavy width gives the frilled curtain its torn outline.
    for s in [-1.0, 1.0] {
        let edge = mid.enumerated().map { (i, p) -> XY in
            let t = Double(i) / Double(n)
            let w = (24 - 20 * t) * (1 + 0.4 * sin(seed + t * 9 + (s < 0 ? 1.6 : 0)))
            return (p.0 + s * w, p.1)
        }
        a.line(edge, hex(0xdcbccb), 0.13, 1.5)
    }
    // Faint bright core strand.
    a.line(mid, hex(0xeef3f4), 0.13, 2.0)
}

private func draw(_ a: Art) {
    // 1. Far/upper rim fringe — behind the bell, so short and very faint.
    for i in 0..<48 {
        let th = -.pi + .pi * (Double(i) + 0.5) / 48
        let (px, py) = rimPoint(th)
        let len = a.rng.range(14, 30)
        a.line([(px, py), (px + a.rng.range(-5, 5), py + len * 0.5),
                (px + a.rng.range(-8, 8), py + len)], hex(0xbfd0d5), 0.16, 1.1)
    }

    // 2. Four frilly oral arms, seen under and through the translucent bell.
    oralArm(a, dir: -0.44, len: 214, sway: 15, seed: 0.3)
    oralArm(a, dir: 0.44, len: 210, sway: 15, seed: 2.1)
    oralArm(a, dir: -0.14, len: 244, sway: 10, seed: 4.0)
    oralArm(a, dir: 0.14, len: 240, sway: 10, seed: 5.6)

    // 3. The translucent saucer bell. Thin and watery in the centre, denser where
    //    the curved membrane stacks up toward the rim; faint radial striae.
    a.polar(cx: cx, cy: cy, sy: bellSy, maxR: 352, radius: { Float(bellRim(Double($0))) }) { r, th, x, y in
        let r2 = r * r, r4 = r2 * r2
        let rim = smooth(0.55, 1.0, r)
        var c = mix(hex(0xaec3cb), hex(0xeef5f6), smooth(0.0, 0.85, r))
        c = mix(c, hex(0xf4fafb), rim * 0.6)                 // brighter membrane at the edge
        c *= 0.97 + 0.05 * artNoise.fbm(x * 0.02, y * 0.02, 2)
        let striae = abs(sin(th * 24)) * r4 * 0.12           // radial muscle ribs
        let alpha = 0.12 + 0.46 * r2 * (0.5 + 0.5 * r) + striae
        return rgba(c, alpha)
    }

    // 4. Radial canals — fine pale spokes from the stomach out to the margin.
    for i in 0..<16 {
        let th = -.pi + 2 * .pi * (Double(i) + 0.5) / 16   // keep in (-pi, pi]
        let s = rimPoint(th, 0.09)
        let e = rimPoint(th, 0.96)
        let branched = i % 4 == 0        // perradial canals read a touch stronger
        a.line([s, e], hex(0xeaf3f5), branched ? 0.14 : 0.09, branched ? 1.5 : 1.1)
    }

    // 5. Faint central stomach disc where the oral arms attach.
    a.softDot(cx, cy, 70, hex(0xcfd9dd), 0.16, sy: bellSy)

    // 6. The diagnostic four-leaf clover of horseshoe gonads, pale rose-mauve,
    //    seen through the bell. Each horseshoe opens toward the centre.
    let gonadR = 88.0, ringR = 31.0, gap = 1.3
    for phi in stride(from: Double.pi / 4, to: 2 * .pi, by: .pi / 2) {
        let gc = (cx + cos(phi) * gonadR * 1.15, cy + sin(phi) * gonadR * bellSy)
        let shoe = horseshoe(gc, ringR, opening: phi + .pi, gap: gap)
        a.line(shoe, hex(0xc2a4b1), 0.15, 16, smooth: false)   // soft halo
        a.line(shoe, hex(0xcfa4b4), 0.36, 8.0, smooth: false)  // muted rose-mauve core
        a.line(shoe, hex(0xe2c7d2), 0.22, 2.6, smooth: false)  // pale inner highlight
    }

    // 7. Soft highlight on the dome for form.
    a.softDot(cx - 96, cy - 118, 165, C3(1, 1, 1), 0.22, sy: 0.5)

    // 8. Near/front marginal fringe — many fine hair-like tentacles around the rim.
    for i in 0..<104 {
        let th = .pi * (Double(i) + 0.5) / 104
        let (px, py) = rimPoint(th)
        let out = cos(th) * 0.28
        let len = a.rng.range(24, 50)
        let sway = a.rng.range(-7, 7)
        a.line([(px, py),
                (px + out * len * 0.5 + sway * 0.4, py + len * 0.5),
                (px + out * len + sway, py + len)],
               hex(0xcfdde1), a.rng.range(0.22, 0.4), a.rng.range(1.1, 1.7))
    }
}
