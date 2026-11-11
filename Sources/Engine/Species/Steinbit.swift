import CoreGraphics
import Foundation

extension Species {
    static let steinbit = SpeciesInfo(
        key: "steinbit", norsk: "Gråsteinbit", latin: "Anarhichas lupus", english: "Atlantic wolffish",
        sprites: [SpriteDef(name: "steinbit", w: 720, h: 216, paint: draw)],
        place: { scene in
            // Keeps to rockier ground than the other bottom fish.
            scene.addRester(ResterSpec(length: 0.7, mode: 1, amp: 0.08, glide: 0.15, rest: (40, 120), z: 4...8, rock: 0.3...0.7, lift: 0,
                                       glideRock: 0.8))
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x454f59), finD = hex(0x6a7681), rim = hex(0xaeb3ac)
    let back = hex(0x434e57), side = hex(0x6c7680), belly = hex(0xa2a497)
    let darkBar = hex(0x20262c)

    // Small rounded caudal fin at the tapering rear (left), confluent with the median fins.
    a.fin(base: [(60, 160), (60, 186)], edge: [(26, 148), (10, 173), (26, 198)],
          root: finC, tip: finD, alpha: 0.85, rays: 7)

    // Single long dorsal fin running the whole back to the tail. Painted as a body strip so the
    // dark vertical bars carry up off the flank and onto the fin, as on a real wolffish.
    let dorsalBase: [XY] = [(72, 162), (190, 146), (330, 128), (470, 110), (610, 90),
                            (730, 74), (840, 64), (895, 66)]
    let dorsalEdge: [XY] = [(78, 142), (190, 114), (330, 94), (470, 76), (610, 54),
                            (730, 42), (840, 48), (893, 65)]
    a.body(top: dorsalEdge, bottom: dorsalBase) { _, v, x, y in
        var c = mix(finC, finD, 0.25 + 0.4 * v)
        c = mix(c, darkBar, wolfBar(x, y) * 0.72)
        c *= 0.9 + 0.14 * v
        // Translucent at the outer edge (v=0), opaque where it meets the back (v=1).
        return rgba(c, 0.52 + 0.46 * v)
    }
    // Faint rays and a defining edge line on the dorsal fin.
    let dOutline = chaikin(dorsalBase, iterations: 2) + chaikin(dorsalEdge, iterations: 2).reversed()
    a.ctx.saveGState()
    a.ctx.addPath(a.path(dOutline, closed: true, smooth: false))
    a.ctx.clip()
    let dB = Curve(dorsalBase), dE = Curve(dorsalEdge)
    var rx = 96.0
    while rx < 886 {
        a.line([(rx, dB.value(rx)), (rx - 4, dE.value(rx))], finD * 0.7, 0.3, 1.6, smooth: false)
        rx += 30
    }
    a.ctx.restoreGState()
    a.line(dorsalEdge, rim, 0.35, 2.5)

    // Long low anal fin along the rear belly.
    let analBase: [XY] = [(110, 190), (240, 204), (380, 216), (500, 224), (562, 228)]
    let analEdge: [XY] = [(110, 196), (240, 224), (380, 242), (500, 246), (560, 232)]
    a.fin(base: analBase, edge: analEdge, root: finC, tip: finD, alpha: 0.78, rays: 16)
    a.line(analEdge, rim, 0.25, 2.5)

    let top: [XY] = [(40, 160), (200, 136), (450, 106), (680, 74), (830, 56), (920, 62), (975, 102), (995, 150)]
    let bottom: [XY] = [(40, 186), (200, 198), (450, 224), (680, 244), (830, 250), (920, 238), (975, 208), (995, 174)]
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.58)
        // Vertical bars: strong on the upper flank, fading toward the pale belly.
        let bar = wolfBar(x, y) * (1 - smooth(0.52, 0.82, v))
        c = mix(c, darkBar, bar * 0.84)
        c *= 0.96 + 0.08 * artNoise.fbm(x * 0.09, y * 0.1, 2)
        return rgba(c * roundLight(v))
    }
    // Faint lateral line following the back.
    a.line([(880, 118), (620, 98), (360, 116), (150, 150)], hex(0x2d343b), 0.28, 2.5)

    // Large rounded pectoral fin, low behind the head.
    a.fin(base: [(818, 150), (818, 208)], edge: [(730, 168), (710, 216), (756, 256)],
          root: finC, tip: finD, alpha: 0.8, rays: 12)
    gill(a, 806, 92, 232, bow: 26)

    // Blunt snout and the big-jawed, toothy mouth that give the wolffish its name.
    a.softDot(976, 150, 40, back * 0.82, 0.22, sy: 0.95)
    a.fill([(995, 152), (958, 168), (905, 166), (912, 190), (960, 196), (995, 186)], hex(0x160f0e), 0.95)
    let ivory = hex(0xe7e1c9)
    // Upper-jaw canines (point down); the two front ones protrude.
    for (x, y0, l) in [(983.0, 160.0, 25.0), (968, 164, 22), (950, 166, 15), (931, 167, 11), (914, 167, 8)] {
        a.fill([(x - 5, y0), (x, y0 + l), (x + 5, y0)], ivory, 1, raw: true)
    }
    // Lower-jaw canines (point up).
    for (x, y0, l) in [(975.0, 194.0, 21.0), (957, 196, 16), (938, 195, 12), (920, 193, 8)] {
        a.fill([(x - 5, y0), (x, y0 - l), (x + 5, y0)], ivory, 1, raw: true)
    }
    // Lips framing the jaws.
    a.line([(995, 150), (958, 166), (905, 164)], hex(0x838c95), 1, 5)
    a.line([(912, 190), (958, 198), (995, 188)], hex(0x6b7681), 0.8, 4)
    // Nostril on the blunt snout.
    a.disc(958, 132, 3.2, hex(0x1b1510), 0.7)
    a.eye(917, 118, 14, iris: hex(0xb7a56c))
}

/// Irregular dark vertical cross-bars, ~10–12 along the body, used by both the flank and the
/// dorsal fin so they line up as one bar crossing back and fin.
private func wolfBar(_ x: Float, _ y: Float) -> Float {
    let wob = (artNoise.fbm(x * 0.02, y * 0.03, 2) - 0.5) * 16
    let band = sin((x + wob) * 0.072 - 0.3)
    return smooth(0.02, 0.5, band) * (1 - smooth(0.80, 0.90, x / 1000))
}
