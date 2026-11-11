import CoreGraphics
import Foundation

extension Species {
    static let rodpolse = SpeciesInfo(
        key: "rodpolse", norsk: "Rødpølse", latin: "Parastichopus tremulus", english: "Red sea cucumber",
        sprites: [SpriteDef(name: "rodpolse", w: 320, h: 120, paint: draw)],
        place: { scene in
            // Lies on the soft bottom.
            for _ in 0..<3 {
                guard let s = scene.findSpot(z: 4...9, rock: 0...0.08) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.08, 0.1), mode: 0, amp: 0, shadowW: 0.14)
            }
        })
}

/// Red sea cucumber lying on the bottom: a soft wrinkled sausage, dusky red above and paler
/// below, mottled, with rows of broad fleshy conical papillae breaking the back-and-side
/// outline and an irregular fringe of ventral tube feet.
private func draw(_ a: Art) {
    // Soft, tapering sausage: domed back, bulging belly, both ends drawn to rounded points.
    let top: [XY] = [(58, 212), (130, 182), (250, 164), (430, 156), (620, 156),
                     (780, 166), (880, 186), (946, 214)]
    let bottom: [XY] = [(58, 218), (150, 252), (320, 268), (520, 272), (710, 268),
                        (840, 254), (946, 216)]
    let T = Curve(top), B = Curve(bottom)

    let dorsal = hex(0x7f3a2b), flank = hex(0x9c4e38), belly = hex(0xc08a73)
    let blotch = hex(0x5a271e)

    a.body(top: top, bottom: bottom) { t, v, x, y in
        // Dusky red across the back, fading to a paler desaturated belly.
        var c = mix(dorsal, flank, smooth(0.0, 0.55, v))
        c = mix(c, belly, smooth(0.5, 1.0, v))
        // Large mottled patches: dark blotches and faint lighter clouds.
        let m = artNoise.fbm(x * 0.013, y * 0.03, 4)
        c = mix(c, blotch, 0.30 * clamp01((0.46 - m) * 3))
        c = mix(c, c * 1.14, 0.22 * clamp01((m - 0.56) * 3))
        // Fine skin grain.
        c *= 0.90 + 0.20 * artNoise.fbm(x * 0.06, y * 0.11, 3)
        // Soft transverse wrinkles of the body wall.
        let crease = Float(sin(Double(x) * 0.085 + Double(artNoise.fbm(x * 0.03, y * 0.05, 2)) * 6))
        c *= 0.965 + 0.05 * crease
        // Gentle diffuse form light, brighter along the upper flank.
        c *= 0.70 + 0.42 * roundLight(v)
        // Round the two ends off a little darker.
        let endf = Float(min(1, min(t, 1 - t) * 6))
        c *= 0.82 + 0.18 * endf
        return rgba(c)
    }

    let papBase = hex(0x8a3f2d), papLit = hex(0xa9633f), papTip = hex(0xbb7f62)
    var rng = a.rng

    // Dorso-lateral near-side row: shorter knobs seated on the flank, drawn first so the
    // taller back row overlaps their bases.
    var x = 150.0
    while x < 850 {
        let by = T.value(x) + rng.range(26, 42)
        papilla(a, x, by, rng.range(13, 24), rng.range(24, 36), rng.range(-5, 7),
                base: papBase * 0.9, lit: papLit * 0.9, tip: papTip, tipA: 0.28, shadow: false)
        x += rng.range(40, 60)
    }

    // Dorsal row: broad fleshy cones rising above the back, breaking the silhouette.
    x = 116.0
    while x < 882 {
        let by = T.value(x) + 7
        papilla(a, x, by, rng.range(26, 47), rng.range(34, 56), rng.range(-8, 10),
                base: papBase, lit: papLit, tip: papTip, tipA: 0.44, shadow: true)
        x += rng.range(44, 66)
    }

    // Ventral tube feet: an irregular, low-contrast fringe of small pale nubs along the sole.
    let podia = hex(0xc08f78)
    for _ in 0..<46 {
        let px = rng.range(96, 896)
        let by = B.value(px) + rng.range(-4, 7)
        a.softDot(px, by, rng.range(4.5, 8), podia, rng.range(0.22, 0.34), sy: 0.8)
    }
    a.rng = rng
}

/// One broad fleshy papilla: a rounded cone, vertically shaded, seated with a soft base
/// shadow and finished with a dusky (non-glowing) tip.
private func papilla(_ a: Art, _ x: Double, _ baseY: Double, _ h: Double, _ w: Double, _ lean: Double,
                     base: C3, lit: C3, tip: C3, tipA: Double, shadow: Bool) {
    let apexX = x + lean, apexY = baseY - h
    let pts: [XY] = [
        (x - w * 0.50, baseY + 2),
        (x - w * 0.34, baseY - h * 0.45),
        (apexX - w * 0.17, apexY + h * 0.15),
        (apexX, apexY),
        (apexX + w * 0.17, apexY + h * 0.15),
        (x + w * 0.34, baseY - h * 0.45),
        (x + w * 0.50, baseY + 2),
    ]
    if shadow {
        a.softDot(x, baseY + 1, w * 0.58, hex(0x3d1912), 0.2, sy: 0.45)
    }
    let p = a.path(pts)
    a.gradient(p, [(base * 0.72, 1, 0), (lit, 1, 1)], from: (x, baseY), to: (apexX, apexY))
    // Dusky tip glow, clipped to the cone so it never halos onto the water.
    a.ctx.saveGState()
    a.ctx.addPath(p)
    a.ctx.clip()
    a.softDot(apexX, apexY + h * 0.22, w * 0.34, tip, tipA)
    a.ctx.restoreGState()
}
