import CoreGraphics
import Foundation

extension Species {
    static let breiflabb = SpeciesInfo(
        key: "breiflabb", norsk: "Breiflabb", latin: "Lophius piscatorius", english: "Angler",
        sprites: [SpriteDef(name: "breiflabb", w: 640, h: 352, paint: draw)],
        place: { scene in
            // Lies in wait and never moves off.
            scene.addRester(ResterSpec(length: 0.85, mode: 1, amp: 0.02, glide: 0, rest: (9999, 9999), z: 4.3...7, rock: 0.05...0.3, lift: -0.03))
        })
}

/// Anglerfish seen from above, lying on the bottom: enormous broad flat head dominated by a
/// wide upward gaping mouth ringed with slender back-curved teeth, a dorsal illicium tipped
/// with an esca lure over the snout, tiny eyes high on the head, broad limb-like pectorals,
/// a tassel fringe breaking the whole body margin, and mottled brown camouflage.
private func draw(_ a: Art) {
    let skin = hex(0x6f5a3f), dark = hex(0x332a18), pale = hex(0xb3a079)
    let marble = hex(0x2a2213), lureC = hex(0xbcac84)

    // Tail and the soft second dorsal / anal pair, muted so the head carries the shape.
    a.fin(base: [(150, 358), (128, 388), (150, 418)], edge: [(8, 300), (0, 388), (16, 462)], root: dark, tip: skin, alpha: 0.8, rays: 12)
    a.fin(base: [(300, 318), (440, 304)], edge: [(300, 262), (372, 240), (448, 266)], root: dark, tip: skin, alpha: 0.6, rays: 9)
    a.fin(base: [(300, 432), (440, 446)], edge: [(300, 486), (372, 508), (448, 482)], root: dark, tip: skin, alpha: 0.6, rays: 9)

    // Broad body: widest across the head on the right, tapering to a slim tail on the left.
    let top: [XY] = [(140, 350), (220, 328), (330, 310), (460, 282), (590, 252), (710, 234), (812, 230), (902, 244), (966, 288)]
    let bottom: [XY] = [(140, 392), (220, 412), (330, 432), (460, 458), (590, 476), (710, 482), (812, 478), (902, 452), (970, 392)]
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = skin
        // Large marbled dark blotches, the angler's camouflage.
        let m = artNoise.fbm(x * 0.0095, y * 0.012, 5)
        c = mix(c, marble, smooth(0.40, 0.70, m) * 0.62)
        c = mix(c, dark, smooth(0.52, 0.80, artNoise.fbm(x * 0.02 + 5, y * 0.026, 4)) * 0.4)
        // Paler mottling in the gaps, then fine freckles.
        c = mix(c, pale, smooth(0.60, 0.82, artNoise.fbm(x * 0.03 + 9, y * 0.04, 3)) * 0.42)
        c *= 1 - spots(x, y, cell: 16, radius: 3.2, keep: 0.42) * 0.18
        c = mix(c, pale * 0.5, spots(x + 7, y - 4, cell: 34, radius: 4.5, keep: 0.8) * 0.3)
        // Thin translucent paling right at the outer margin, where the fringe grows.
        let edge = min(v, 1 - v)
        c = mix(mix(pale, skin, 0.4), c, smooth(0.0, 0.16, edge))
        return rgba(c * (0.72 + 0.30 * roundLight(v)))
    }

    // Tassel fringe breaking the outline all the way around.
    fringe(a, top, outward: -1, seed: 3)
    fringe(a, bottom, outward: 1, seed: 17)

    // Broad limb-like pectoral splayed out behind the head.
    a.fin(base: [(560, 448), (648, 456)], edge: [(520, 516), (602, 536), (666, 500)], root: skin * 0.82, tip: hex(0x8c7a58), alpha: 0.85, rays: 8)
    // The far-side pectoral just showing above the back behind the head.
    a.fin(base: [(548, 292), (628, 282)], edge: [(548, 246), (592, 232), (636, 254)], root: skin * 0.72, tip: hex(0x80704f), alpha: 0.5, rays: 6)

    // The enormous upward gape: a dark cavity ringed with teeth, lower jaw jutting forward.
    mouth(a)

    // Illicium (mobile dorsal spine) tipped with a fleshy esca lure over the snout.
    a.line([(846, 256), (864, 206), (892, 172), (916, 160)], lureC, 0.95, 4.5)
    a.softDot(918, 156, 17, hex(0xd2c4a0), 0.5)
    a.disc(918, 156, 8.5, lureC)
    a.taper([(918, 156), (928, 142), (922, 128)], 7, 1.5, lureC, 0.9)
    a.taper([(918, 156), (906, 143), (910, 130)], 6, 1.5, lureC, 0.9)
    // A shorter second cephalic spine behind it.
    a.line([(770, 236), (782, 206), (800, 192)], lureC, 0.8, 3.2)

    // Tiny eyes set high on the head.
    a.eye(792, 298, 11, iris: hex(0xa6904f))
    a.eye(758, 292, 9.5, iris: hex(0x8b7644))
}

/// Tasselled dermal fringe along a body-margin polyline, flaps pointing outward.
private func fringe(_ a: Art, _ margin: [XY], outward: Double, seed: Int32) {
    let cv = chaikin(margin, closed: false, iterations: 2)
    let n = 34
    for i in 0..<n {
        let idx = Double(i) / Double(n - 1) * Double(cv.count - 1)
        let lo = Int(idx), hi = min(cv.count - 1, lo + 1)
        let f = idx - Double(lo)
        let x = cv[lo].0 + (cv[hi].0 - cv[lo].0) * f
        let y = cv[lo].1 + (cv[hi].1 - cv[lo].1) * f
        let h = artNoise.hash(Int32(i) &+ seed, seed &* 7)
        let len = 7 + Double(h) * 16 + (i % 4 == 0 ? 9 : 0)
        let wig = (Double(artNoise.hash(Int32(i) &+ 5, seed)) - 0.5) * 12
        let col = h > 0.55 ? hex(0x9a8862) : hex(0x5a4a32)
        a.taper([(x, y), (x + wig, y + outward * len * 0.55), (x + wig * 1.4, y + outward * len)], 6.5, 1.2, col, 0.85)
    }
}

/// The wide gaping mouth: dark throat, jaw rim and many slender back-curved teeth.
private func mouth(_ a: Art) {
    let mouthC = hex(0x120f0a), throat = hex(0x5f4537), teethC = hex(0xc7bc9b)
    // Cavity bulging forward, lower jaw jutting past the snout on the right.
    let rim: [XY] = [
        (846, 300), (882, 270), (938, 258), (992, 274), (1018, 316),
        (1022, 352), (1018, 390), (992, 432), (938, 448), (882, 436), (846, 404), (856, 352),
    ]
    a.fill(rim, mouthC, 0.96)
    // Glistening throat deep in the gape, off-centre so it doesn't read as a wheel.
    a.softDot(942, 352, 62, throat, 0.5, sy: 1.08)
    a.softDot(966, 352, 34, hex(0x241810), 0.6, sy: 1.12)
    // Pale rim/lip just inside the jaw line, top and bottom.
    a.line([(882, 270), (938, 262), (992, 278)], hex(0x493929), 0.5, 5)
    a.line([(882, 436), (938, 444), (992, 428)], hex(0x493929), 0.5, 5)
    // A palisade of irregular, slender, back-curved teeth around the front and sides.
    toothRing(a, 930, 352, rx: 92, ry: 95, count: 26, from: -2.0, to: 2.0, col: teethC, seed: 1)
    // A sparse scatter of longer fangs breaking the row.
    toothRing(a, 930, 352, rx: 90, ry: 93, count: 9, from: -1.6, to: 1.6, col: teethC * 0.95, seed: 40)
}

/// One ring of teeth on an elliptical jaw rim. Angle, radius and length are jittered so the
/// row reads as an irregular palisade of fangs, each swept back toward the throat.
private func toothRing(_ a: Art, _ cx: Double, _ cy: Double, rx: Double, ry: Double,
                       count: Int, from: Double, to: Double, col: C3, seed: Int32) {
    for i in 0...count {
        let h1 = artNoise.hash(Int32(i) &+ seed, seed &* 3)
        let h2 = artNoise.hash(Int32(i) &* 2 &+ seed, seed &+ 11)
        let h3 = artNoise.hash(Int32(i) &+ 7, seed &* 5)
        let th = from + (to - from) * (Double(i) + (Double(h1) - 0.5) * 0.7) / Double(count)
        let rr = 1 + (Double(h2) - 0.5) * 0.14
        let lenF = 0.34 + Double(h3) * 0.30                 // tip radius: varies fang length
        let bx = cx + cos(th) * rx * rr, by = cy + sin(th) * ry * rr
        // Tip swept inward and back toward the throat (toward the body, -x).
        let tx = cx + cos(th) * rx * lenF - 16, ty = cy + sin(th) * ry * lenF + sin(th) * 6
        let mx = cx + cos(th) * rx * 0.68 - 6, my = cy + sin(th) * ry * 0.68 + sin(th) * 4
        let w = 6.5 + Double(h1) * 4
        a.taper([(bx, by), (mx, my), (tx, ty)], w, 1.2, col, 0.9)
    }
}
