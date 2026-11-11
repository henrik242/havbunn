import CoreGraphics
import Foundation

extension Species {
    static let lomre = SpeciesInfo(
        key: "lomre", norsk: "Lomre", latin: "Microstomus kitt", english: "Lemon sole",
        sprites: [SpriteDef(name: "lomre", w: 380, h: 152, paint: draw)],
        place: { scene in
            scene.addRester(ResterSpec(length: 0.3, mode: 3, amp: 0.05, glide: 0.35, rest: (20, 70), z: 4...8, rock: 0...0.08, lift: 0))
        })
}

/// Lemon sole: a right-eyed flatfish seen from above. A broad smooth oval with a small head
/// at the right, both eyes on top, a continuous dorsal + anal fin fringe round almost the whole
/// rim, and skin richly marbled in warm brown, orange, yellow and muted green.
private func draw(_ a: Art) {
    let top: [XY] = [(150, 172), (280, 120), (470, 74), (660, 58), (830, 76), (925, 124), (978, 190)]
    let bottom: [XY] = [(150, 220), (280, 272), (470, 320), (660, 338), (830, 318), (925, 268), (978, 202)]
    let topC = Curve(top), botC = Curve(bottom)

    // Soft translucent fin fringe. Built as a scalloped frill that follows the rim, fuller at
    // mid-body and slimming to nothing at head and tail, with many fine rays.
    let fRoot = hex(0x7a5f36), fTip = hex(0xbb9864)
    func fringe(lower: Bool) {
        var base: [XY] = [], edge: [XY] = []
        for i in 0...22 {
            let s = Double(i) / 22
            let x = 150 + s * 700
            let rim = (lower ? botC.value(min(x, 975)) : topC.value(min(x, 975))) + (lower ? 1 : -1)
            let depth = 15 + 42 * sin(Double.pi * s)
            let scallop = 5 * sin(s * Double.pi * 12 + (lower ? 1.3 : 0))
            base.append((x, rim))
            edge.append((x, rim + (lower ? depth - scallop : -depth + scallop)))
        }
        a.fin(base: base, edge: edge, root: fRoot, tip: fTip, alpha: 0.82, rays: 56)
    }
    fringe(lower: false)
    fringe(lower: true)
    // Rounded tail fan at the left, continuous with the fringe.
    a.fin(base: [(172, 150), (150, 196), (172, 242)],
          edge: [(42, 130), (6, 196), (42, 262)], root: fRoot, tip: fTip, alpha: 0.85, rays: 18)

    let back = hex(0x8a7340), side = hex(0xa58d58), belly = hex(0xb49c66)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        // Domed base tone, lighter toward the raised midline.
        var c = flank(v, back: back, side: side, belly: belly, split: 0.5)
        // Large warm marbling: orange-brown then deep reddish-brown blotches.
        c = mix(c, hex(0xab7236), smooth(0.5, 0.72, artNoise.fbm(x * 0.012, y * 0.02, 4)) * 0.5)
        c = mix(c, hex(0x6d4225), smooth(0.56, 0.8, artNoise.fbm(x * 0.02 + 5, y * 0.03 + 2, 4)) * 0.55)
        // Muted greenish mottle, as on a real lemon sole.
        c = mix(c, hex(0x6b6a3c), smooth(0.6, 0.82, artNoise.fbm(x * 0.034 + 9, y * 0.04 + 7, 3)) * 0.3)
        // Pale yellow marbled patches, then warm and cream freckles.
        c = mix(c, hex(0xd8c590), smooth(0.62, 0.84, artNoise.fbm(x * 0.05 + 2, y * 0.055, 3)) * 0.42)
        c = mix(c, hex(0x4a3720), spots(x, y, cell: 28, radius: 3, keep: 0.5, seed: 4) * 0.3)
        c = mix(c, hex(0xc98a46), spots(x, y, cell: 40, radius: 3.4, keep: 0.4, seed: 9) * 0.28)
        c = mix(c, hex(0xe4d3a2), spots(x, y, cell: 66, radius: 4, keep: 0.3, seed: 7) * 0.3)
        return rgba(c * (0.82 + 0.22 * roundLight(v)))
    }

    // Faint lateral line, a shade lighter, gently arched over the pectoral near the head.
    var lat: [XY] = []
    for i in 0...12 {
        let x = 220 + Double(i) / 12 * 690
        let mid = (topC.value(min(x, 975)) + botC.value(min(x, 975))) / 2
        let arch = x > 740 ? -11 * Double(smooth(740, 900, Float(x))) : 0
        lat.append((x, mid + arch))
    }
    a.line(lat, hex(0xd0bc8c), 0.2, 2.5)

    // Small head: gill crease, a short down-turned mouth and the paired eyes on top.
    a.line([(940, 120), (922, 158), (930, 200)], hex(0x4a3a24), 0.25, 3)
    a.line([(978, 188), (960, 198), (944, 200)], hex(0x33281a), 0.55, 3)
    a.eye(903, 150, 11, iris: hex(0xb79a50))
    a.eye(910, 183, 10, iris: hex(0xb79a50))
}
