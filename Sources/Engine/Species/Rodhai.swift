import CoreGraphics
import Foundation

extension Species {
    static let rodhai = SpeciesInfo(
        key: "rodhai", norsk: "Småflekket rødhai", latin: "Scyliorhinus canicula", english: "Small-spotted catshark",
        sprites: [SpriteDef(name: "rodhai", w: 640, h: 170, paint: draw)],
        place: { scene in
            // Mostly lying still, now and then a slow swim along the bottom.
            scene.addRester(ResterSpec(length: 0.6, mode: 1, amp: 0.05, glide: 0.22, rest: (25, 80), z: 4...9, rock: 0...0.3, lift: 0))
        })
}

/// Small-spotted catshark: slender, sandy greyish-brown, densely covered in many small dark
/// spots, both dorsals set well back toward the tail, a long low heterocercal tail, broad
/// rounded pectorals, cat-like slit eyes with a brow ridge, and small nasal flaps at the snout.
private func draw(_ a: Art) {
    let back = hex(0x867049), side = hex(0xa7906b), belly = hex(0xe2d7bf)
    let spotDark = hex(0x362819)
    let finRoot = hex(0x8f7850), finTip = hex(0xc2ab84)
    let finFarRoot = hex(0x6d5c40), finFarTip = hex(0x8a784f)

    // Far-side pectoral, tucked behind the body.
    a.fin(base: [(858, 170), (792, 174)], edge: [(846, 196), (806, 228), (758, 228), (752, 202)],
          root: finFarRoot, tip: finFarTip, alpha: 0.8, rays: 7)

    // Long low heterocercal caudal: upper lobe reaches out nearly level, with a subterminal
    // notch and a small terminal and ventral lobe. Tail is at the LEFT (low x).
    let caudal: [XY] = [
        (82, 120), (58, 113), (34, 105), (14, 99), (3, 97),     // top margin of upper lobe to tip
        (6, 106), (4, 116),                                     // subterminal notch + terminal tip
        (20, 124), (42, 134), (60, 141), (72, 139), (82, 132),  // ventral margin + small lower lobe
    ]
    let cpath = a.path(caudal)
    a.gradient(cpath, [(finRoot, 0.96, 0), (finTip, 0.74, 1)], from: (78, 128), to: (6, 102))
    a.ctx.saveGState()
    a.ctx.addPath(cpath); a.ctx.clip()
    for i in 0...8 {
        let t = Double(i) / 8
        a.line([(80, 122 + t * 12), (5 + t * 58, 100 + t * 36)], finRoot * 0.6, 0.22, 1.3, smooth: false)
    }
    a.ctx.restoreGState()
    finSpots(a, caudal, 3, 96, 80, 141, 31)

    // Two dorsals, both set well back toward the tail, the rear one a touch smaller.
    a.fin(base: [(360, 101), (300, 103)], edge: [(344, 70), (318, 62), (302, 80)],
          root: finRoot, tip: finTip, alpha: 0.95, rays: 8)
    a.fin(base: [(232, 111), (176, 113)], edge: [(216, 82), (194, 77), (180, 95)],
          root: finRoot, tip: finTip, alpha: 0.95, rays: 7)
    // Anal fin between the dorsals, and the pelvics.
    a.fin(base: [(280, 170), (218, 172)], edge: [(264, 194), (240, 198), (222, 182)],
          root: finRoot, tip: finTip, alpha: 0.9, rays: 6)
    a.fin(base: [(466, 176), (406, 178)], edge: [(450, 198), (424, 204), (410, 186)],
          root: finRoot, tip: finTip, alpha: 0.9, rays: 6)

    let top: [XY] = [(80, 123), (160, 115), (320, 101), (500, 88), (680, 82), (820, 86), (910, 100), (965, 116), (998, 131)]
    let bottom: [XY] = [(80, 137), (160, 150), (320, 166), (500, 178), (680, 182), (820, 180), (910, 168), (965, 152), (998, 137)]
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.58)
        // Soft tonal mottling of rough shagreen skin.
        c *= 0.93 + 0.12 * artNoise.fbm(x * 0.05, y * 0.09, 4)
        let upper = 1 - smooth(0.52, 0.74, v)
        // Dense, small, dark brown spots in two overlaid scales.
        let s1 = spots(x, y, cell: 9, radius: 2.3, keep: 0.82)
        let s2 = spots(x, y, cell: 15, radius: 2.0, keep: 0.6, seed: 5)
        c = mix(c, spotDark, max(s1, s2 * 0.9) * (0.35 + 0.65 * upper))
        // A few scattered pale spots.
        c = mix(c, hex(0xe8dec6), spots(x, y, cell: 46, radius: 3.2, keep: 0.3, seed: 11) * upper * 0.6)
        // Fine denticle sheen.
        c *= 0.98 + 0.05 * artNoise.hash(Int32(x * 1.3), Int32(y * 1.3))
        return rgba(c * roundLight(v))
    }

    // Faint lateral line.
    a.line([(120, 131), (400, 123), (700, 116), (884, 120)], hex(0x6a563a), 0.28, 2)

    // Near-side pectoral, broad and rounded, in front of the body.
    a.fin(base: [(880, 168), (804, 172)], edge: [(872, 196), (828, 232), (770, 236), (758, 206)],
          root: finRoot, tip: finTip, alpha: 0.95, rays: 9)

    // Dark spotting carried onto the fins.
    finSpots(a, [(360, 101), (300, 103), (302, 80), (318, 62), (344, 70)], 300, 60, 360, 104, 7)
    finSpots(a, [(232, 111), (176, 113), (180, 95), (194, 77), (216, 82)], 176, 76, 232, 114, 13)
    finSpots(a, [(880, 168), (804, 172), (758, 206), (770, 236), (828, 232), (872, 196)], 758, 168, 880, 236, 19)

    // Five gill slits just ahead of the pectoral.
    for i in 0..<5 {
        let x = 904 - Double(i) * 12
        a.line([(x, 118 + Double(i) * 1.6), (x - 5, 150)], hex(0x493922), 0.5, 2.4)
    }

    // Snout with small paired nasal flaps.
    a.softDot(978, 140, 7, hex(0x5a4830), 0.45, sy: 0.8)
    a.disc(974, 141, 3.2, finRoot, 0.9)
    a.disc(982, 139, 2.6, finRoot, 0.85)
    a.line([(970, 144), (984, 141)], hex(0x4a3a26), 0.5, 1.8)
    // Arched mouth beneath the snout.
    a.line([(990, 140), (966, 150), (944, 149)], hex(0x3a2c1c), 0.55, 2.5)

    // Cat-like slit eye with a brow ridge.
    a.line([(886, 101), (904, 98), (921, 103)], hex(0x5e4b31), 0.5, 4)
    a.disc(903, 111, 12, hex(0x0f0d09), 0.4)
    a.disc(903, 111, 10, hex(0xad924f))
    a.softDot(900, 108, 9, hex(0x6b5529), 0.55)
    a.line([(898, 118), (909, 104)], hex(0x08070a), 0.95, 4)
    a.disc(900, 114, 1.4, C3(1, 1, 1), 0.5)
}

/// Scatters small dark denticle-spots inside a fin polygon.
private func finSpots(_ a: Art, _ poly: [XY], _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ seed: Int32) {
    a.ctx.saveGState()
    a.ctx.addPath(a.path(poly))
    a.ctx.clip()
    var i = seed
    var y = y0
    while y <= y1 {
        var x = x0
        while x <= x1 {
            if artNoise.hash(i, i &* 3 &+ 1) < 0.42 {
                let jx = (Double(artNoise.hash(i &+ 5, i)) - 0.5) * 9
                let jy = (Double(artNoise.hash(i, i &+ 9)) - 0.5) * 9
                a.disc(x + jx, y + jy, 1.5, hex(0x3a2c1c), 0.5)
            }
            i &+= 1
            x += 9
        }
        y += 9
    }
    a.ctx.restoreGState()
}
