import CoreGraphics
import Foundation

extension Species {
    static let haakjerring = SpeciesInfo(
        key: "haakjerring", norsk: "Håkjerring", latin: "Somniosus microcephalus", english: "Greenland shark",
        sprites: [SpriteDef(name: "haakjerring", w: 1024, h: 276, paint: draw)],
        place: { scene in
            // Comes up from deeper water now and then.
            scene.addRareVisitor(SwimmerSpec(length: 3.2, speed: 0.34, z: 11...16, alt: 1.5...3, amp: 0.18, wave: 5),
                                 weight: 0.25)
        })
}

// Fleshy, rayless shark fin: a smoothed blade filled with a soft base->tip gradient.
// Greenland-shark fins are low, rounded and have no visible rays.
private func finBlade(_ a: Art, _ pts: [XY], from: XY, to: XY, root: C3, tip: C3, alpha: Double = 1) {
    a.gradient(a.path(pts), [(root, alpha, 0.0), (tip, alpha, 1.0)], from: from, to: to)
}

private func draw(_ a: Art) {
    let back = hex(0x2d2e29), side = hex(0x44443d), belly = hex(0x5f5d52)
    let finRoot = hex(0x34342e), finTip = hex(0x202019), finFar = hex(0x26261f)
    let darkLine = hex(0x14140f)

    // ---- Off-side fins and tail, behind the body so only their edges show. ----
    // Broad heterocercal caudal: a long upper lobe and a shorter, broad lower lobe, forked.
    let caudal: [XY] = [(116, 114), (60, 62), (20, 34), (50, 78), (84, 118),
                        (52, 180), (100, 150), (120, 144)]
    finBlade(a, caudal, from: (112, 128), to: (24, 44), root: finRoot, tip: finTip)
    // Faint off-side pectoral peeking under the belly for depth.
    finBlade(a, [(876, 206), (838, 226), (808, 250), (832, 230), (868, 212)],
             from: (862, 214), to: (812, 246), root: finFar, tip: finFar, alpha: 0.5)
    // Two small, low, rounded dorsals, set well back; first (anterior) slightly larger.
    finBlade(a, [(690, 70), (654, 52), (622, 46), (596, 56), (584, 76)],
             from: (636, 74), to: (624, 48), root: finRoot, tip: finTip)
    finBlade(a, [(520, 78), (492, 60), (466, 54), (444, 62), (434, 80)],
             from: (478, 80), to: (470, 54), root: finRoot, tip: finTip)

    // ---- Massive cylindrical body with a small, blunt, rounded snout. ----
    let top: [XY] = [(112, 120), (190, 100), (360, 80), (560, 68), (730, 66),
                     (850, 76), (935, 100), (978, 128), (996, 150)]
    let bottom: [XY] = [(112, 150), (190, 172), (360, 204), (560, 226), (730, 228),
                        (850, 216), (935, 184), (978, 160), (996, 150)]
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.60)
        // Broad, soft mottling and faint darker banding across the back.
        let m = artNoise.fbm(x * 0.013, y * 0.022, 4)
        c *= 0.90 + 0.22 * m
        let band = artNoise.fbm(x * 0.03 + 5, y * 0.05 + 2, 3)
        c = mix(c, c * 0.80, clamp01((band - 0.54) * 3.4) * 0.55)
        // Fine dermal-denticle grain (sandpaper skin).
        let grain = artNoise.fbm(x * 0.45, y * 0.55, 2)
        c *= 0.95 + 0.10 * grain
        c = mix(c, c * 0.90, spots(x, y, cell: 7, radius: 1.9, keep: 0.6) * 0.30)
        // A few faint old scars/blotches, muted and soft (not sharp lines).
        let s = clamp01(1 - abs(artNoise.fbm(x * 0.012, y * 0.05 + 8, 2) - 0.52) * 34)
        c = mix(c, hex(0x63655d), s * 0.07)
        return rgba(c * roundLight(v))
    }

    // ---- Near-side fins, in front of the body: low, rounded, drab, clearly below the belly. ----
    finBlade(a, [(874, 214), (838, 238), (790, 264), (758, 258), (786, 232), (842, 216)],
             from: (852, 222), to: (778, 258), root: finRoot, tip: finTip)
    finBlade(a, [(392, 206), (356, 228), (320, 242), (298, 236), (328, 216), (382, 210)],
             from: (372, 214), to: (314, 238), root: finRoot, tip: finTip, alpha: 0.95)

    // ---- Head details. ----
    // Five small gill slits just ahead of the pectoral.
    for i in 0..<5 {
        let x = 906 - Double(i) * 6.5
        a.line([(x, 150 + Double(i) * 1.0), (x - 2, 172)], hex(0x1a1b16), 0.6, 2.2)
    }
    // Small sub-terminal mouth, a shallow down-curve under the blunt snout.
    a.line([(956, 176), (972, 180), (988, 175)], darkLine, 0.75, 2.6)
    // Nostril on the snout, ahead of the eye.
    a.disc(970, 158, 2.4, darkLine, 0.7, sy: 0.8)
    // Small spiracle behind the eye.
    a.disc(906, 120, 3.6, hex(0x111510), 0.7, sy: 0.75)
    // Small, dull eye.
    a.eye(930, 132, 5.5, iris: hex(0x3f4c50))
    // Parasitic copepod (Ommatokoita elongata) trailing from the cornea: a pale
    // thread ending in a small body, a famous Greenland-shark detail.
    a.line([(930, 137), (934, 150), (930, 162), (934, 172)], hex(0xcfc9ad), 0.85, 2.0)
    a.disc(935, 174, 3.0, hex(0xd8d2b7), 0.85, sy: 1.1)
    a.line([(929, 137), (924, 149), (927, 158)], hex(0xcfc9ad), 0.6, 1.6)
}
