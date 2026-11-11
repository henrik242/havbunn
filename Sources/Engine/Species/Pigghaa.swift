import CoreGraphics
import Foundation

extension Species {
    static let pigghaa = SpeciesInfo(
        key: "pigghaa", norsk: "Pigghå", latin: "Squalus acanthias", english: "Spiny dogfish",
        sprites: [SpriteDef(name: "pigghaa", w: 720, h: 230, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.95, speed: 0.55, z: 5...15, alt: 0.9...3.2, amp: 0.45, wave: 7.5, count: 2))
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x434d54)         // membrane: slate, a touch darker than the back
    let finEdge = hex(0x2c343a)      // shaded trailing margin
    let finLit = hex(0x6d777c)       // soft leading sheen

    // Heterocercal caudal: a long, dominant upper lobe with a subterminal notch and a
    // shorter lower lobe — not a symmetric tuna fork.
    caudal(a, finC, finEdge, finLit)

    // Second dorsal (nearer the tail), a little smaller, with its short stout spine in front.
    dorsal(a, [(418, 82), (388, 48), (360, 30), (344, 56), (334, 92)],
           spineBase: (417, 78), spineTip: (410, 42), finC, finEdge, finLit)
    // First dorsal (just behind the pectoral), larger and swept, with its spine in front.
    dorsal(a, [(726, 58), (684, 20), (656, 10), (636, 40), (624, 66)],
           spineBase: (724, 54), spineTip: (717, 18), finC, finEdge, finLit)

    // Slim body: slate-grey back, paler flanks, near-white belly, pointed snout.
    let top: [XY] = [(105, 150), (200, 120), (360, 90), (520, 72), (690, 62),
                     (810, 70), (905, 110), (958, 138), (998, 160)]
    let bottom: [XY] = [(105, 172), (200, 188), (360, 214), (520, 232), (690, 236),
                        (810, 224), (905, 194), (958, 176), (998, 166)]
    let back = hex(0x434f56), side = hex(0x6b777d), belly = hex(0xd7dcd4)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.58)
        // Dermal denticle micro-texture.
        c *= 0.96 + 0.07 * artNoise.fbm(x * 0.13, y * 0.16, 2)
        // Scattering of small white spots: upper flank only, fading at snout and tail.
        let upper = 1 - smooth(0.40, 0.58, v)
        let along = smooth(0.06, 0.22, t) * (1 - smooth(0.80, 0.98, t))
        let sp = spots(x, y, cell: 60, radius: 4.4, keep: 0.5) * 0.9
            + spots(x, y, cell: 96, radius: 2.9, keep: 0.4, seed: 5) * 0.7
        c = mix(c, hex(0xdfe3dc), min(1, sp) * upper * along)
        // Darker dorsal ridge for a defined back.
        c = mix(c, back * 0.80, (1 - smooth(0, 0.13, v)) * 0.5)
        return rgba(c * roundLight(v))
    }

    // Near-side paired fins, drawn over the body so their bases sit on the flank.
    // Broad pectoral, right behind the gills.
    paired(a, [(808, 208), (742, 226), (660, 300), (700, 254), (730, 232)], finC, finEdge)
    // Smaller pelvic, between the dorsals.
    paired(a, [(520, 232), (470, 236), (440, 278), (482, 260), (506, 240)], finC, finEdge)

    // Five gill slits, just behind the head.
    for i in 0..<5 {
        let x = 860 - Double(i) * 12
        a.line([(x, 150 + Double(i) * 2.5), (x - 8, 196)], hex(0x232a2e), 0.75, 3)
    }

    // Underslung mouth set back from the pointed snout, plus a small nostril.
    a.line([(972, 182), (936, 194), (902, 192)], hex(0x20262a), 0.85, 4)
    a.line([(958, 156), (948, 154)], hex(0x20262a), 0.5, 2.4)
    // Large eye and the small spiracle behind it.
    a.eye(886, 120, 13, iris: hex(0x8ea596))
    a.line([(866, 108), (856, 110)], hex(0x1c2226), 0.7, 3)
}

/// Heterocercal shark tail: dominant upper lobe, subterminal notch, short lower lobe.
private func caudal(_ a: Art, _ finC: C3, _ edge: C3, _ lit: C3) {
    let outline: [XY] = [
        (118, 150),  // upper attach on the back
        (8, 58),     // long, tall upper-lobe tip
        (30, 84),    // cut of the subterminal notch
        (22, 106),   // small terminal lobe
        (74, 160),   // deep notch between the lobes
        (54, 214),   // shorter lower-lobe tip
        (120, 180),  // lower attach on the belly
    ]
    a.fill(outline, finC, 0.99)
    // Shade the trailing edge and brighten the leading edge of the upper lobe.
    a.line([(22, 106), (74, 160), (54, 214)], edge, 0.5, 4)
    a.line([(115, 150), (8, 58)], lit, 0.35, 3)
}

/// A dorsal fin plus its short, stout leading spine (horn-pale, never antenna-like).
private func dorsal(_ a: Art, _ pts: [XY], spineBase: XY, spineTip: XY,
                    _ finC: C3, _ edge: C3, _ lit: C3) {
    a.fill(pts, finC, 0.98)
    a.line([pts[0], pts[1], pts[2]], lit, 0.3, 2.4)              // leading sheen
    a.line([pts[2], pts[3], pts[4]], edge, 0.45, 3)             // shaded trailing edge
    let mid: XY = ((spineBase.0 + spineTip.0) * 0.5, (spineBase.1 + spineTip.1) * 0.5)
    a.taper([spineBase, spineTip], 10, 1.6, hex(0x868b82))      // stout horn base
    a.taper([mid, spineTip], 5, 1.0, hex(0xc3c6bc))            // lighter upper half
    a.line([spineBase, spineTip], hex(0xd6d9ce), 0.45, 1.1)    // faint front highlight
}

/// A near-side paired fin: flat slate membrane with a shaded trailing edge.
private func paired(_ a: Art, _ pts: [XY], _ finC: C3, _ edge: C3) {
    a.fill(pts, finC, 0.97)
    a.line([pts[1], pts[2], pts[3]], edge, 0.4, 3)
}
