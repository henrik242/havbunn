import CoreGraphics
import Foundation

extension Species {
    static let piggskate = SpeciesInfo(
        key: "piggskate", norsk: "Piggskate", latin: "Raja clavata", english: "Thornback ray",
        sprites: [SpriteDef(name: "piggskate", w: 560, h: 340, paint: draw)],
        place: { scene in
            scene.addRester(ResterSpec(length: 0.6, mode: 3, amp: 0.05, glide: 0.45, rest: (25, 90), z: 4...9, rock: 0...0.12, lift: 0))
        })
}

/// Thornback ray (Raja clavata), rhombic disc seen from above at a low angle.
/// Snout points right, pectoral "wings" spread top and bottom, thorny tail trails left.
private func draw(_ a: Art) {
    // --- Tail: long, tapering, with a faint dark dorsal shade ---
    a.taper([(300, 300), (180, 299), (80, 304), (6, 299)], 52, 7, hex(0x6a5636))
    a.line([(290, 300), (180, 299), (80, 303), (18, 299)], hex(0x3f3119), 0.4, 7)
    // Two small dorsal finlets near the tail tip (skate hallmark).
    tailFin(a, 118, 300, 16)
    tailFin(a, 74, 300, 13)

    // --- Rhombic disc, marbled brown-grey ---
    let top: [XY] = [(250, 282), (300, 248), (405, 126), (520, 24), (652, 120), (800, 214), (906, 268), (996, 300)]
    let bottom: [XY] = [(250, 318), (300, 352), (405, 474), (520, 576), (652, 480), (800, 386), (906, 332), (996, 300)]
    a.body(top: top, bottom: bottom) { t, v, x, y in
        // Muted base, a touch darker toward the trailing (belly) margin.
        var c = mix(hex(0x8a734a), hex(0x72603c), v)
        // Marbled mottling: broad patches from low-freq noise, fine grain on top.
        let m1 = artNoise.fbm(x * 0.016, y * 0.016, 5)
        let m2 = artNoise.fbm(x * 0.05 + 40, y * 0.05, 3)
        c = mix(c, hex(0x56452a), clamp01((m1 - 0.5) * 2.4) * 0.8)   // dark marbling
        c = mix(c, hex(0xb6a06e), clamp01((0.46 - m1) * 2.1) * 0.55) // pale marbling
        c *= 0.9 + 0.2 * m2
        // Many small dark spots and scattered pale flecks.
        let ds = spots(x, y, cell: 29, radius: 4.8, keep: 0.6)
        c = mix(c, hex(0x322510), ds * 0.82)
        let ps = spots(x, y, cell: 47, radius: 5.4, keep: 0.42, seed: 11)
        c = mix(c, hex(0xd7c698), ps * 0.85)
        let ps2 = spots(x, y, cell: 94, radius: 9, keep: 0.3, seed: 5)
        c = mix(c, hex(0xe2d2a6), ps2 * 0.7)
        // Diffuse darker band tracing the spine.
        let spine = clamp01(1 - abs(v - 0.5) * 3.0)
        c = mix(c, hex(0x463718), spine * 0.17)
        // Low-angle doming: brighter crown, darker wing margins; snout/tail a shade darker.
        let lv: Float = 0.8 + 0.3 * roundLight(v)
        let lt: Float = 0.9 + 0.12 * (1 - min(1, abs(t - 0.4) * 1.7))
        return rgba(c * lv * lt)
    }

    // Soft marbled blotches to break up the surface (clipped visually by sitting inside the disc).
    for (x, y, r) in [(470.0, 210.0, 46.0), (610, 300, 56), (470, 392, 46), (720, 300, 40), (380, 300, 34)] {
        a.softDot(x, y, r, hex(0x3f3016), 0.22)
    }
    for (x, y) in [(560.0, 170.0), (560, 432), (690, 250), (690, 352), (430, 250), (430, 352)] {
        a.softDot(x, y, 26, hex(0xdfcfa2), 0.2)
    }

    // --- Thorny tail: median row plus a few laterals near the base ---
    var tx = 288.0, ts = 7.2
    while tx > 34 {
        thorn(a, tx, 300, ts)
        if tx > 150 {
            let off = (tx - 30) / 260 * 11 + 3
            thorn(a, tx - 14, 300 - off, ts * 0.72)
            thorn(a, tx - 14, 300 + off, ts * 0.72)
        }
        tx -= 34; ts = max(4.2, ts - 0.4)
    }

    // --- Thorns scattered over the disc ---
    let scatter: [(Double, Double, Double)] = [
        (470, 196, 8), (556, 158, 7), (646, 206, 8), (706, 258, 7), (430, 256, 7),
        (512, 232, 6.5), (600, 250, 7), (470, 404, 8), (556, 442, 7), (646, 394, 8),
        (706, 342, 7), (430, 344, 7), (600, 350, 7), (386, 300, 7.5), (680, 300, 7),
    ]
    for (x, y, s) in scatter { thorn(a, x, y, s) }

    // --- Prominent diagnostic midline row of large bucklers down the back ---
    for x in stride(from: 332.0, through: 782.0, by: 45.0) {
        let f = 1 - abs(x - 548) / 300
        thorn(a, x, 300, 9.5 + 6 * max(0, f))
    }

    // --- Eyes raised on top, with crescent spiracles just behind them ---
    for ey in [264.0, 336.0] {
        a.softDot(844, ey + 4, 20, hex(0x241a0c), 0.3)       // contact shadow
        a.disc(844, ey, 16, hex(0x6f5a38), 0.9)              // domed lid
        a.disc(840, ey - 3, 10, hex(0x8a7249), 0.7)          // lit crown
    }
    a.eye(844, 264, 11, iris: hex(0xa88f50))
    a.eye(844, 336, 11, iris: hex(0xa88f50))
    spiracle(a, 806, 272)
    spiracle(a, 806, 328)
}

/// Stout thorn/buckler: broad round base and a short two-toned spine with a pale tip,
/// lit from the upper left so it reads as a 3-D bump at small size.
private func thorn(_ a: Art, _ x: Double, _ y: Double, _ s: Double) {
    a.softDot(x + s * 0.45, y + s * 0.55, s * 1.9, hex(0x231a0c), 0.3)  // contact shadow
    a.disc(x, y, s * 1.25, hex(0x463719), 0.85)                        // broad base rim
    a.disc(x, y, s * 0.96, hex(0x6c5736), 0.95)                        // base top
    a.disc(x - s * 0.24, y - s * 0.26, s * 0.52, hex(0x9c8456), 0.8)   // base highlight
    // Stout, slightly back-leaning spine.
    let w = s * 0.78
    let tx = x - s * 0.34, ty = y - s * 1.35
    a.fill([(x - w, y + s * 0.1), (x, y), (tx, ty)], hex(0x927a52), 0.96, raw: true)   // lit face
    a.fill([(x, y), (x + w, y + s * 0.1), (tx, ty)], hex(0x4c3d24), 0.96, raw: true)   // shadow face
    a.line([(x - s * 0.08, y - s * 0.1), (tx, ty)], hex(0xbfa97b), 0.45, max(0.8, s * 0.3))
    a.disc(tx, ty, s * 0.26, hex(0xcdbb86), 0.9)                       // pale tip
}

/// Small dark crescent spiracle behind the eye.
private func spiracle(_ a: Art, _ x: Double, _ y: Double) {
    a.disc(x, y, 7, hex(0x17130c), 0.75)
    a.disc(x - 2.5, y - 2.5, 5, hex(0x6f5a38), 0.55)   // carve the crescent toward the light
}

/// A low, rounded dorsal finlet lobe near the tail tip.
private func tailFin(_ a: Art, _ x: Double, _ y: Double, _ s: Double) {
    a.fill([(x + s * 0.5, y + 2), (x + s * 0.1, y - s), (x - s * 0.6, y - s * 0.9),
            (x - s * 0.5, y + 2)], hex(0x5c4a2f), 0.95, raw: false)
    a.fill([(x + s * 0.5, y - 2), (x + s * 0.1, y + s), (x - s * 0.6, y + s * 0.9),
            (x - s * 0.5, y - 2)], hex(0x50401f), 0.95, raw: false)
}
