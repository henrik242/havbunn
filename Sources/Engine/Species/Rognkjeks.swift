import CoreGraphics
import Foundation

extension Species {
    static let rognkjeks = SpeciesInfo(
        key: "rognkjeks", norsk: "Rognkjeks", latin: "Cyclopterus lumpus", english: "Lumpfish",
        sprites: [SpriteDef(name: "rognkjeks", w: 400, h: 248, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.34, speed: 0.10, z: 3.8...9, alt: 0.15...0.9, amp: 0.16, wave: 5, hover: 0.9))
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x45606b), finD = hex(0x7d98a0)
    // Small rounded caudal fin, and the small soft second-dorsal and anal lobes set far back
    // near the tail (the first dorsal is buried under the skin as the humped crest).
    a.fin(base: [(100, 300), (84, 340), (100, 380)], edge: [(10, 280), (0, 340), (10, 400)], root: finC, tip: finD, rays: 10)
    a.fin(base: [(170, 214), (322, 150)], edge: [(168, 158), (238, 118), (322, 118)], root: finC, tip: finD, alpha: 0.82, rays: 8)
    a.fin(base: [(190, 450), (344, 528)], edge: [(176, 512), (254, 556), (352, 560)], root: finC, tip: finD, alpha: 0.82, rays: 8)
    // High-backed, almost globular silhouette.
    let top: [XY] = [(95, 306), (160, 214), (290, 112), (480, 56), (650, 58), (800, 118), (910, 230), (965, 330)]
    let bottom: [XY] = [(95, 372), (160, 440), (290, 548), (480, 612), (650, 606), (800, 550), (910, 462), (965, 378)]
    let back = hex(0x36525f), side = hex(0x6d8f96), belly = hex(0xc6b29a)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.58)
        // Broad, soft tonal mottling over the rotund flank.
        let m = artNoise.fbm(x * 0.016, y * 0.016, 3)
        c *= 0.86 + 0.26 * m
        let blotch = smooth(0.52, 0.74, artNoise.fbm(x * 0.009 + 5, y * 0.012, 3))
        c = mix(c, c * 0.8, blotch * (1 - smooth(0.6, 0.9, v)) * 0.4)
        // Rough, warty skin: dense fine bumps, some catching light, some in shadow.
        let hi = spots(x, y, cell: 17, radius: 5.2, keep: 0.72, seed: 3)
        c = mix(c, mix(c, hex(0xaebfbf), 0.7), hi * 0.16 * (1 - smooth(0.62, 0.9, v)))
        let lo = spots(x, y, cell: 23, radius: 5.8, keep: 0.6, seed: 9)
        c = mix(c, c * 0.78, lo * 0.2)
        // Faint cool sheen high on the arched back.
        c = mix(c, hex(0x9fb6b8), (1 - smooth(0.0, 0.3, v)) * 0.1)
        return rgba(c * roundLight(v))
    }

    // Longitudinal rows of bony knobbly tubercles, drawn as discrete raised cones that
    // follow the body contour: a tall dorsal crest plus three flank rows.
    let T = Curve(top), B = Curve(bottom)
    let coneBody = hex(0x7e969c), coneWarm = hex(0xa58b73)
    func bump(_ cx: Double, _ cy: Double, _ r: Double, warm: Double = 0, crest: Bool = false) {
        a.softDot(cx + r * 0.1, cy + r * 0.5, r * 1.15, hex(0x1d2d35), 0.24, sy: 0.9)     // cast shadow
        a.disc(cx, cy, r, mix(coneBody, coneWarm, Float(warm)), crest ? 0.9 : 0.82)        // matte cone
        a.softDot(cx + r * 0.05, cy + r * 0.32, r * 0.8, hex(0x233742), 0.26)             // lower shading
        a.softDot(cx - r * 0.26, cy - r * 0.3, r * 0.62, hex(0xb3c0bd), 0.36)             // soft lit crown
    }
    func flankRow(_ f: Double, _ x0: Double, _ x1: Double, _ step: Double, _ baseR: Double,
                  warm: Double = 0, seed: Int32 = 0) {
        var x = x0, i: Int32 = 0
        while x <= x1 {
            let jx = Double(artNoise.hash(i &* 13 &+ seed, seed &+ 5) - 0.5) * step * 0.5
            let jy = Double(artNoise.hash(seed &+ 3, i &* 7) - 0.5) * 12
            let xx = x + jx
            let yt = T.value(xx), yb = B.value(xx), span = yb - yt
            if span > 64 {
                let tt = (xx - x0) / (x1 - x0)
                let fade = sin(Double.pi * min(1, max(0, tt)))
                let r = baseR * (0.45 + 0.55 * fade) * (0.82 + 0.4 * Double(artNoise.hash(i, seed)))
                bump(xx, yt + span * f + jy, r, warm: warm)
            }
            x += step; i += 1
        }
    }
    // Flank rows, back to front; the mid-lateral row carries the largest tubercles.
    flankRow(0.74, 210, 830, 66, 11.5, warm: 0.4, seed: 31)
    flankRow(0.52, 175, 885, 62, 15.0, warm: 0.12, seed: 17)
    flankRow(0.31, 190, 865, 60, 13.0, seed: 5)
    // Dorsal crest: larger tubercles riding the top ridge, poking above the outline.
    do {
        var x = 300.0, i: Int32 = 0
        while x <= 822 {
            let jx = Double(artNoise.hash(i &* 5 &+ 71, 9) - 0.5) * 14
            let xx = x + jx
            let yt = T.value(xx)
            let tt = (xx - 300) / 522
            let fade = sin(Double.pi * min(1, max(0, tt)))
            let r = 10.0 + 6.0 * fade
            bump(xx, yt + r * 0.3, r, crest: true)
            x += 47; i += 1
        }
    }

    // Ventral sucker disc (the fused pelvic fins), bulging below the belly, seen at a low angle.
    a.softDot(556, 616, 100, hex(0x16242b), 0.32, sy: 0.4)
    a.disc(556, 600, 80, hex(0x5f5346), 0.92, sy: 0.42)          // outer rim shadow
    a.disc(556, 598, 72, hex(0x857667), 0.95, sy: 0.42)          // fleshy rim
    a.disc(556, 600, 52, hex(0x6c5f50), 0.85, sy: 0.42)          // cup wall
    a.disc(553, 602, 34, hex(0x4e4538), 0.8, sy: 0.42)           // cup centre
    a.softDot(544, 590, 30, hex(0xa8977f), 0.4, sy: 0.42)        // rim highlight

    // Large rounded pectoral fin sweeping down toward the sucker.
    a.fin(base: [(712, 300), (706, 404)], edge: [(584, 296), (548, 372), (602, 452)], root: finC, tip: finD, rays: 12)
    // Gill opening behind the head, and a small terminal mouth.
    gill(a, 792, 206, 356, bow: 28, 0.2)
    a.line([(963, 352), (922, 372), (884, 366)], hex(0x101a1f), 0.85, 6)
    a.softDot(905, 300, 60, hex(0x2a3b41), 0.14, sy: 0.9)        // soft cheek shading
    a.eye(846, 252, 21, iris: hex(0xb08a52))
}
