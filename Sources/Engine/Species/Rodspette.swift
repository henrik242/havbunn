import CoreGraphics
import Foundation

extension Species {
    static let rodspette = SpeciesInfo(
        key: "rodspette", norsk: "Rødspette", latin: "Pleuronectes platessa", english: "European plaice",
        sprites: [SpriteDef(name: "rodspette", w: 420, h: 168, paint: draw)],
        place: { scene in
            scene.addRester(ResterSpec(length: 0.32, mode: 3, amp: 0.05, glide: 0.4, rest: (15, 60), z: 3.6...7, rock: 0...0.08, lift: 0))
        })
}

/// European plaice seen from above at a low angle: a right-eyed flatfish. A broad smooth oval,
/// head at the right with both eyes on top and a short row of bony knobs behind them, a continuous
/// scalloped dorsal + anal fin fringe round almost the whole rim, and a smooth greenish-brown eyed
/// side boldly scattered with well-separated muted orange spots over both body and fins.
private func draw(_ a: Art) {
    let top: [XY] = [(135, 170), (260, 120), (450, 70), (640, 52), (820, 70), (930, 120), (985, 190)]
    let bottom: [XY] = [(135, 222), (260, 268), (450, 325), (640, 350), (820, 330), (930, 276), (985, 210)]
    let topC = Curve(top), botC = Curve(bottom)

    // Continuous scalloped fin fringe: a frill that hugs the rim, fuller mid-body and tapering to
    // nothing at head and tail, with many fine rays. Followed by a rounded tail fan at the left.
    let fRoot = hex(0x6d5a35), fTip = hex(0x9c855a)
    func fringe(lower: Bool) {
        var base: [XY] = [], edge: [XY] = []
        for i in 0...24 {
            let s = Double(i) / 24
            let x = 165 + s * 700
            let rim = (lower ? botC.value(min(x, 978)) : topC.value(min(x, 978))) + (lower ? 1 : -1)
            let depth = 14 + 40 * sin(Double.pi * s)
            let scallop = 5 * sin(s * Double.pi * 13 + (lower ? 1.1 : 0))
            base.append((x, rim))
            edge.append((x, rim + (lower ? depth - scallop : -depth + scallop)))
        }
        a.fin(base: base, edge: edge, root: fRoot, tip: fTip, alpha: 0.82, rays: 60)
    }
    fringe(lower: false)
    fringe(lower: true)
    a.fin(base: [(160, 150), (138, 196), (160, 242)],
          edge: [(34, 128), (4, 196), (34, 264)], root: fRoot, tip: fTip, alpha: 0.85, rays: 18)

    // Muted orange spots that straddle the rim onto the fin membrane (drawn under the body so the
    // part over the body is overpainted, leaving a fringe-side crescent as on a real plaice).
    for i in 1...6 {
        let s = Double(i) / 7
        let x = 210 + s * 620
        plaiceSpot(a, x, topC.value(min(x, 978)) - 15, 7, 0.75)
        plaiceSpot(a, x, botC.value(min(x, 978)) + 15, 7, 0.75)
    }

    // Smooth greenish-brown eyed side, domed toward the midline, with soft subdued mottling.
    let back = hex(0x6c5c36), side = hex(0x7f6e41), belly = hex(0x89784b)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.5)
        c = mix(c, hex(0x5a4e2d), smooth(0.5, 0.82, artNoise.fbm(x * 0.012, y * 0.02, 4)) * 0.4)
        c = mix(c, hex(0x636439), smooth(0.58, 0.84, artNoise.fbm(x * 0.028 + 6, y * 0.035 + 3, 3)) * 0.24)
        c = mix(c, hex(0x8c7c4e), smooth(0.6, 0.85, artNoise.fbm(x * 0.05 + 2, y * 0.055, 3)) * 0.22)
        c = mix(c, hex(0x463a22), spots(x, y, cell: 26, radius: 2.6, keep: 0.45, seed: 4) * 0.22)
        return rgba(c * (0.82 + 0.22 * roundLight(v)))
    }

    // The diagnostic feature: many conspicuous, well-separated muted orange spots scattered evenly
    // over the body. Placed on a jittered grid and kept inside the oval, away from the eyes.
    for gi in 0...9 {
        for gj in 0...3 {
            let gx = 210.0 + Double(gi) * 72, gy = 92.0 + Double(gj) * 76
            let h1 = Double(artNoise.hash(Int32(gi) &* 7 &+ 1, Int32(gj) &* 3 &+ 5))
            let h2 = Double(artNoise.hash(Int32(gj) &* 11 &+ 2, Int32(gi) &* 5 &+ 9))
            let h3 = Double(artNoise.hash(Int32(gi) &+ 13, Int32(gj) &+ 17))
            let x = gx + (h1 - 0.5) * 62, y = gy + (h2 - 0.5) * 60
            if x < 185 || x > 905 { continue }
            let tv = topC.value(min(max(x, 136), 984)), bv = botC.value(min(max(x, 136), 984))
            if y < tv + 18 || y > bv - 18 { continue }
            if x > 845 && y > 112 && y < 206 { continue }   // keep clear of the eyes
            plaiceSpot(a, x, y, 7.5 + 6.5 * h3)
        }
    }

    // Faint lateral line, a shade lighter, arched gently over the pectoral near the head.
    var lat: [XY] = []
    for i in 0...12 {
        let x = 210 + Double(i) / 12 * 700
        let mid = (topC.value(min(x, 978)) + botC.value(min(x, 978))) / 2
        let arch = x > 720 ? -12 * Double(smooth(720, 900, Float(x))) : 0
        lat.append((x, mid + arch))
    }
    a.line(lat, hex(0xb7a470), 0.22, 2.5)

    // Short row of bony knobs on the head ridge, running back from between the eyes.
    for i in 0...3 {
        let t = Double(i) / 3
        knob(a, 852 - t * 66, 159 + t * 5, 6 - t * 1.4)
    }

    // Small head: gill crease and a short down-turned mouth at the snout.
    a.line([(946, 118), (926, 158), (934, 202)], hex(0x4a3a24), 0.28, 3.5)
    a.line([(985, 200), (958, 226), (918, 232)], hex(0x33281a), 0.6, 4)
    a.eye(895, 136, 15, iris: hex(0xc2a24c))
    a.eye(905, 182, 14, iris: hex(0xc2a24c))
}

/// A single plaice spot: muted burnt-orange with a faint dark halo and a warm highlight, soft-edged
/// so it reads over dark water without looking neon.
private func plaiceSpot(_ a: Art, _ x: Double, _ y: Double, _ r: Double, _ strength: Double = 1) {
    let orange = hex(0xbb6322)
    a.softDot(x, y, r * 1.85, hex(0x3d2f15), 0.26 * strength)
    a.disc(x, y, r, orange, 0.78 * strength)
    a.softDot(x, y, r * 1.2, orange, 0.5 * strength)
    a.softDot(x - r * 0.18, y - r * 0.2, r * 0.68, hex(0xcf7d37), 0.5 * strength)
}

/// A bony tubercle on the head: a small raised bump with a shadow below and a lit crown.
private func knob(_ a: Art, _ x: Double, _ y: Double, _ r: Double) {
    a.softDot(x + r * 0.3, y + r * 0.6, r * 1.5, hex(0x332816), 0.42)
    a.softDot(x, y, r * 1.05, hex(0x746239), 0.85)
    a.softDot(x - r * 0.3, y - r * 0.35, r * 0.7, hex(0x9d885c), 0.45)
}
