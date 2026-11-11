import CoreGraphics
import Foundation

extension Species {
    static let lange = SpeciesInfo(
        key: "lange", norsk: "Lange", latin: "Molva molva", english: "Ling",
        sprites: [SpriteDef(name: "lange", w: 720, h: 180, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 1.0, speed: 0.14, z: 5...12, alt: 0.2...0.9, amp: 0.22, wave: 7.5, hover: 0.9))
        })
}

/// Ling: a very long, slightly flattened cod relative. A short rounded first dorsal and a very
/// long low second dorsal run the back; a long anal fin runs the rear belly. Both median fins are
/// confluent with the body, edged by a dark submarginal line and a pale margin, and each carries
/// the diagnostic dark, pale-ringed blotch at its posterior tip. A single chin barbel, big head.
private func draw(_ a: Art) {
    let finRoot = hex(0x5c5330), finTip = hex(0x86794f)      // confluent olive-bronze membrane
    let rim = hex(0xe3dcc6), sub = hex(0x272212)             // pale margin + dark submarginal line

    // Rounded caudal fan.
    a.fin(base: [(64, 106), (48, 122), (64, 138)],
          edge: [(12, 90), (2, 106), (0, 122), (2, 140), (12, 154)],
          root: finRoot, tip: finTip, alpha: 0.9, rays: 12)
    a.line([(12, 90), (2, 106), (0, 122), (2, 140), (12, 154)], rim, 0.5, 3)

    // Second (long) dorsal: low, confluent, closing to the body at both ends, gently lobed edge.
    let d2Base: [XY] = [(626, 80), (520, 81), (400, 85), (280, 91), (190, 97), (128, 101), (96, 102)]
    let d2Edge: [XY] = [(626, 80), (540, 67), (440, 63), (320, 67), (230, 73), (160, 74), (120, 80), (100, 93), (96, 102)]
    lingMedian(a, base: d2Base, edge: d2Edge, root: finRoot, tip: finTip, rim: rim, sub: sub,
               rays: 34, blotch: (150, 89), blotchR: 9)

    // First dorsal: short rounded lobe just behind the head, its own rear-tip blotch.
    let d1Base: [XY] = [(772, 75), (716, 73), (662, 76)]
    let d1Edge: [XY] = [(772, 75), (744, 51), (704, 45), (676, 54), (662, 76)]
    lingMedian(a, base: d1Base, edge: d1Edge, root: finRoot, tip: finTip, rim: rim, sub: sub,
               rays: 9, blotch: (680, 61), blotchR: 7)

    // Anal fin: long and low along the rear belly, confluent, rear-tip blotch.
    let anBase: [XY] = [(504, 162), (400, 160), (300, 156), (210, 150), (140, 145), (110, 143)]
    let anEdge: [XY] = [(504, 162), (410, 175), (300, 179), (205, 173), (150, 172), (124, 166), (112, 156), (110, 143)]
    lingMedian(a, base: anBase, edge: anEdge, root: finRoot, tip: finTip, rim: rim, sub: sub,
               rays: 26, blotch: (140, 160), blotchR: 8)

    let top: [XY] = [(56, 110), (250, 94), (500, 82), (700, 76), (850, 80), (940, 98), (995, 126)]
    let bottom: [XY] = [(56, 134), (250, 150), (500, 162), (700, 166), (850, 160), (940, 146), (995, 134)]
    let back = hex(0x575030), side = hex(0x8a7d50), belly = hex(0xd7cfb6)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.52)
        let vis = 1 - smooth(0.50, 0.80, v)      // detail fades toward the pale belly
        // Fine marbled bronze clouding over the back: two overlaid noise scales, soft not blobby.
        let marb1 = smooth(0.50, 0.74, artNoise.fbm(x * 0.028, y * 0.05, 4))
        c = mix(c, mix(c * 0.70, hex(0x463d20), 0.5), marb1 * vis * 0.72)
        let marb2 = smooth(0.58, 0.82, artNoise.fbm(x * 0.012 + 7, y * 0.02 + 3, 3))
        c = mix(c, mix(c, hex(0x6d5c33), 0.6), marb2 * vis * 0.4)
        // Sparse small olive flecks for a bronzed, mottled grain.
        let sp = spots(x, y, cell: 20, radius: 3.2, keep: 0.6, seed: 3)
        c = mix(c, hex(0x3f371d), sp * vis * 0.5)
        // Darker olive dorsal ridge.
        c = mix(c, c * 0.84, (1 - smooth(0.02, 0.22, v)) * 0.5)
        // Faint pale lateral line arching high behind the head, easing down toward the tail.
        let llY = 0.34 + 0.12 * smooth(0.30, 0.95, 1 - t)
        let ll = clamp01(1 - abs(v - llY) * 55)
        c = mix(c, hex(0xe6dec3), ll * 0.32 * (0.4 + 0.6 * vis))
        c *= 1 - scales(x, y, size: 11) * 0.045 * (0.5 + 0.5 * vis)
        return rgba(c * roundLight(v))
    }

    // Rounded pectoral paddle behind the gill cover.
    a.fin(base: [(826, 122), (826, 150)], edge: [(758, 128), (736, 150), (760, 174)],
          root: finRoot, tip: finTip, alpha: 0.78, rays: 9)
    // Small thoracic pelvic fin, set well forward under the throat.
    a.fin(base: [(892, 150), (876, 155)], edge: [(852, 170), (866, 182), (884, 176)],
          root: finRoot, tip: finTip, alpha: 0.72, rays: 5)

    gill(a, 850, 84, 158, bow: 20)
    // Operculum fold, faint.
    a.line([(876, 90), (892, 122), (882, 150)], hex(0x332d19), 0.22, 4)
    // Big head: wide mouth with overhanging upper jaw, and a soft snout shade.
    a.softDot(976, 132, 34, hex(0x4a4227), 0.22, sy: 0.9)
    a.line([(995, 128), (958, 139), (930, 141)], hex(0x221f10), 0.6, 4)       // upper jaw / mouth
    a.line([(995, 124), (966, 130), (944, 134)], hex(0x6d6744), 0.4, 2.5)     // upper-lip highlight
    a.softDot(948, 118, 9, hex(0x2a2516), 0.35)                               // nostril ahead of eye
    // Single chin barbel hanging from the lower jaw tip.
    a.line([(958, 150), (960, 174), (950, 192)], hex(0x241c10), 0.5, 5)
    a.line([(958, 150), (960, 174), (950, 192)], hex(0xc9bf98), 1, 3)
    a.disc(950, 193, 4, hex(0xc9bf98), 1)
    a.eye(928, 106, 11, iris: hex(0x9a8e5c))
}

/// A confluent median fin: membrane tucked to the body, a dark submarginal line just inside a
/// pale margin, and the diagnostic dark pale-ringed blotch on the membrane at the posterior tip.
private func lingMedian(_ a: Art, base: [XY], edge: [XY], root: C3, tip: C3, rim: C3, sub: C3,
                        rays: Int, blotch: XY, blotchR: Double) {
    a.fin(base: base, edge: edge, root: root, tip: tip, alpha: 0.9, rays: rays)
    let subMargin = zip(edge, base).map { e, b in (e.0 * 0.80 + b.0 * 0.20, e.1 * 0.80 + b.1 * 0.20) }
    a.line(subMargin, sub, 0.45, 4)
    a.line(edge, rim, 0.65, 3.5)
    a.softDot(blotch.0, blotch.1, blotchR * 1.7, rim, 0.45, sy: 1.15)         // pale ring
    a.disc(blotch.0, blotch.1, blotchR, hex(0x16130b), 0.92, sy: 1.2)         // dark blotch on membrane
    a.softDot(blotch.0, blotch.1, blotchR * 1.25, hex(0x16130b), 0.35, sy: 1.2)
}
