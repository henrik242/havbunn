import CoreGraphics
import Foundation

extension Species {
    static let haakjerring = SpeciesInfo(
        key: "haakjerring", norsk: "Håkjerring", latin: "Somniosus microcephalus", english: "Greenland shark",
        sprites: [SpriteDef(name: "haakjerring", w: 1024, h: 276, paint: draw)],
        place: { scene in
            // A huge, slow shark that cruises up from deeper water now and then, looming large.
            scene.addRareVisitor(SwimmerSpec(length: 5.6, speed: 0.3, z: 7.5...11, alt: 1.5...3.2, amp: 0.16, wave: 5.5),
                                 weight: 0.25)
        })
}

// Fleshy, rayless shark fin: a smoothed blade filled with a soft base->tip gradient.
// Greenland-shark fins are low, rounded and have no visible rays.
private func finBlade(_ a: Art, _ pts: [XY], from: XY, to: XY, root: C3, tip: C3, alpha: Double = 1) {
    a.gradient(a.path(pts), [(root, alpha, 0.0), (tip, alpha, 1.0)], from: from, to: to)
}

private func draw(_ a: Art) {
    let back = hex(0x34352f), side = hex(0x4d4d44), belly = hex(0x66645a)
    let finRoot = hex(0x3a3a33), finTip = hex(0x232320), finFar = hex(0x2a2a23)
    let darkLine = hex(0x14140f)

    // ---- Off-side fins and tail, behind the body so only their edges show. ----
    // Heterocercal caudal: a long dominant upper lobe swept up and back, a subterminal notch,
    // and a short lower lobe — the asymmetric Greenland-shark tail, not a symmetric fork.
    let caudal: [XY] = [(126, 110), (58, 64), (14, 36), (30, 70), (22, 100),
                        (46, 122), (66, 162), (110, 152), (126, 136)]
    finBlade(a, caudal, from: (118, 126), to: (18, 44), root: finRoot, tip: finTip)
    // Faint off-side pectoral peeking under the belly for depth.
    finBlade(a, [(878, 210), (840, 230), (810, 254), (834, 234), (870, 216)],
             from: (864, 218), to: (814, 250), root: finFar, tip: finFar, alpha: 0.5)
    // Two small, low, rounded spineless dorsals set well back; first (anterior) a touch larger.
    finBlade(a, [(700, 66), (660, 38), (624, 32), (598, 44), (584, 68)],
             from: (636, 70), to: (624, 34), root: finRoot, tip: finTip)
    finBlade(a, [(528, 72), (496, 46), (468, 42), (444, 52), (432, 74)],
             from: (478, 76), to: (470, 46), root: finRoot, tip: finTip)

    // ---- Massive, heavy, cylindrical body tapering to a small blunt head. ----
    let top: [XY] = [(120, 120), (200, 98), (370, 76), (560, 64), (720, 64),
                     (840, 76), (912, 100), (958, 126)]
    let bottom: [XY] = [(120, 150), (200, 174), (370, 206), (560, 228), (720, 228),
                        (840, 214), (912, 184), (958, 158)]
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.60)
        // Broad, soft mottling.
        let m = artNoise.fbm(x * 0.013, y * 0.022, 4)
        c *= 0.92 + 0.20 * m
        // Faint dark transverse bands, as many Greenland sharks show.
        let band = 0.5 + 0.5 * sin(x * 0.019 + artNoise.fbm(x * 0.01, y * 0.01, 2) * 3)
        c = mix(c, c * 0.82, smooth(0.62, 0.98, band) * 0.3 * (1 - smooth(0.78, 1, v)))
        // Fine dermal-denticle grain (sandpaper skin).
        let grain = artNoise.fbm(x * 0.45, y * 0.55, 2)
        c *= 0.96 + 0.09 * grain
        c = mix(c, c * 0.90, spots(x, y, cell: 7, radius: 1.9, keep: 0.6) * 0.28)
        // A few faint old scars/blotches, muted and soft.
        let s = clamp01(1 - abs(artNoise.fbm(x * 0.012, y * 0.05 + 8, 2) - 0.52) * 34)
        c = mix(c, hex(0x6c6e64), s * 0.08)
        return rgba(c * roundLight(v))
    }
    // Rounded, blunt snout cap so the head is bluntly rounded, not pointed.
    let snout: [XY] = [(958, 124), (980, 128), (994, 142), (988, 158), (966, 162), (958, 158)]
    a.gradient(a.path(snout), [(side, 1, 0), (mix(side, belly, 0.5), 1, 1)], from: (966, 126), to: (990, 160))
    a.softDot(970, 136, 20, hex(0x6a6c60), 0.3, sy: 0.7)

    // ---- Near-side fins, in front of the body: low, rounded, drab, clearly below the belly. ----
    finBlade(a, [(876, 214), (840, 238), (792, 264), (760, 258), (788, 232), (844, 216)],
             from: (854, 222), to: (780, 258), root: finRoot, tip: finTip)
    finBlade(a, [(394, 206), (358, 228), (322, 242), (300, 236), (330, 216), (384, 210)],
             from: (374, 214), to: (316, 238), root: finRoot, tip: finTip, alpha: 0.95)
    // Caudal keel on the slim peduncle.
    a.line([(150, 140), (124, 136)], hex(0x26261f), 0.5, 4)

    // ---- Head details. ----
    // Five small gill slits just ahead of the pectoral.
    for i in 0..<5 {
        let x = 902 - Double(i) * 6.5
        a.line([(x, 150 + Double(i) * 1.0), (x - 2, 172)], hex(0x1a1b16), 0.6, 2.2)
    }
    // Small sub-terminal mouth, a shallow down-curve under the blunt snout.
    a.line([(958, 168), (974, 172), (988, 166)], darkLine, 0.8, 2.6)
    // Nostril on the snout, ahead of the eye.
    a.disc(966, 150, 2.4, darkLine, 0.7, sy: 0.8)
    // Small spiracle behind the eye.
    a.disc(904, 120, 3.4, hex(0x111510), 0.7, sy: 0.75)
    // Small, dull eye.
    a.eye(928, 130, 5.5, iris: hex(0x3f4c50))
    // Parasitic copepod (Ommatokoita elongata) trailing from the cornea — a famous detail.
    a.line([(928, 135), (932, 148), (928, 160), (932, 170)], hex(0xcfc9ad), 0.85, 2.0)
    a.disc(933, 172, 3.0, hex(0xd8d2b7), 0.85, sy: 1.1)
    a.line([(927, 135), (922, 147), (925, 156)], hex(0xcfc9ad), 0.6, 1.6)
}
