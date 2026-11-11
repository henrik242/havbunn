import CoreGraphics
import Foundation

extension Species {
    static let sjonellik = SpeciesInfo(
        key: "sjonellik", norsk: "Sjønellik", latin: "Metridium senile", english: "Plumose anemone",
        sprites: [
            SpriteDef(name: "sjonellik", w: 280, h: 280) { draw($0, column: hex(0xe9e1d0), crown: hex(0xf8f4e7)) },
            SpriteDef(name: "sjonellik-o", w: 280, h: 280) { draw($0, column: hex(0xdf8c43), crown: hex(0xf7a95c)) },
        ],
        place: { scene in
            // Clusters, each all white or all orange.
            for _ in 0..<6 {
                guard let c = scene.findSpot(z: 4.2...16, rock: 0.5...1.01) else { continue }
                let orange = scene.rng.chance(0.3)
                for _ in 0..<scene.rng.int(3, 6) {
                    let x = c.0 + scene.rng.float(-0.35, 0.35), z = c.2 + scene.rng.float(-0.25, 0.25)
                    guard let spot = scene.ground(x, z, rockAbove: 0.4) else { continue }
                    scene.addFixture(orange ? "sjonellik-o" : "sjonellik", spot: spot,
                                     height: scene.rng.float(0.18, 0.34), mode: 5, amp: 0.05, shadowW: 0.12)
                }
            }
        })
}

/// Plumose anemone: a smooth column with a slight collar, topped by a dense, lobed
/// cauliflower crown of very many fine feathery tentacles.
private func draw(_ a: Art, column: C3, crown: C3) {
    let h = a.unitH
    var rng = a.rng
    let cx = 500.0
    // Cool, slightly desaturated shadow tone used in the crown's recesses and base.
    let shadow = mix(crown, hex(0x27333a), 0.44)

    // ---------- Column ----------
    // Smooth columnar trunk: spreading foot, gently swelling middle, slight collar flare up top.
    let spine: [(Double, Double)] = [
        (438, 148), (470, 126), (520, 117), (610, 120),
        (720, 129), (850, 143), (940, 164), (h, 198),
    ]
    var left: [XY] = [], right: [XY] = []
    for (y, w) in spine { left.append((cx - w, y)); right.append((cx + w, y)) }
    let colPath = a.path(left + right.reversed())
    a.gradient(colPath, [
        (column * 0.5, 1, 0), (column * 0.84, 1, 0.26),
        (column * 1.02, 1, 0.47), (column * 0.9, 1, 0.66), (column * 0.46, 1, 1),
    ], from: (cx - 150, 0), to: (cx + 155, 0))

    a.ctx.saveGState(); a.ctx.addPath(colPath); a.ctx.clip()
    // Soft vertical striations, splaying a little toward the foot.
    for i in 0..<10 {
        let fx = cx - 128 + Double(i) * 28 + rng.range(-5, 5)
        let shade = column * Float(rng.range(0.72, 0.9))
        a.line([(fx, 456), (fx + (fx - cx) * 0.2, h)], shade, 0.16, rng.range(5, 9))
    }
    // Shadow just under the crown, and a pale highlight on the collar lip.
    a.line([(cx - 150, 450), (cx, 470), (cx + 150, 450)], shadow, 0.5, 30)
    a.line([(cx - 118, 502), (cx, 514), (cx + 118, 502)], column * 1.07, 0.22, 15)
    a.ctx.restoreGState()

    // ---------- Crown ----------
    // Bumpy dome radius r(theta): theta 0 = right, pi = left, over the upper half.
    let cyb = 454.0, Rx = 254.0, Ry = 326.0
    func domeR(_ th: Double) -> (Double, Double) {
        let b = 1 + 0.05 * cos(th * 6) + 0.03 * cos(th * 11 + 1.3)
        return (Rx * b, Ry * b)
    }
    // Solid dark base mass, so gaps between tentacles read as depth, not open water.
    var dome: [XY] = []
    let n = 64
    for i in 0...n {
        let th = Double.pi * Double(i) / Double(n)
        let (rx, ry) = domeR(th)
        dome.append((cx + cos(th) * rx, cyb - sin(th) * ry))
    }
    dome.append((cx + Rx * 0.72, cyb + 34))
    dome.append((cx, cyb + 52))
    dome.append((cx - Rx * 0.72, cyb + 34))
    a.fill(dome, shadow, 1)
    // Broad diffuse modelling: lit from the upper left, occluded low and front.
    a.softDot(cx - 66, cyb - 168, 258, crown * 0.82, 0.5, sy: 0.92)
    a.softDot(cx, cyb - 28, 250, shadow, 0.42, sy: 0.58)
    // A ring of soft lobes gives the cauliflower its lumpy relief.
    for i in 0..<7 {
        let th = Double.pi * (0.08 + 0.84 * Double(i) / 6)
        let (rx, ry) = domeR(th)
        a.softDot(cx + cos(th) * rx * 0.78, cyb - sin(th) * ry * 0.78, 74, crown * 0.8, 0.4)
    }

    // Dense feathery tentacles. Roots spread across the whole dome, each a short,
    // slightly curved, outward-pointing wisp; drawn darkest-first so highlights sit on top.
    let origin = (cx, cyb - 34.0)
    var tufts: [(p: [XY], c: C3, w: Double, b: Float)] = []
    tufts.reserveCapacity(2400)
    for _ in 0..<2400 {
        let th = rng.range(-0.17 * .pi, 1.17 * .pi)
        let (rx, ry) = domeR(max(0, min(.pi, th)))
        let sx = cx + cos(th) * rx, sy = cyb - sin(th) * ry
        let frac = rng.range(0.48, 1.0)
        let rootx = origin.0 + (sx - origin.0) * frac + rng.range(-22, 22)
        let rooty = origin.1 + (sy - origin.1) * frac + rng.range(-15, 15)
        var dx = sx - origin.0, dy = sy - origin.1
        let dl = max(1e-6, (dx * dx + dy * dy).squareRoot()); dx /= dl; dy /= dl
        // Jitter the direction so tentacles tuft outward rather than comb from one point.
        let ja = rng.range(-0.3, 0.3), cj = cos(ja), sj = sin(ja)
        let ndx = dx * cj - dy * sj, ndy = dx * sj + dy * cj
        let len = rng.range(38, 80)
        let tipx = rootx + ndx * len, tipy = rooty + ndy * len
        let wob = rng.range(-16, 16)
        let midx = (rootx + tipx) / 2 - ndy * wob, midy = (rooty + tipy) / 2 + ndx * wob
        // Shading from surface angle: bright on top and toward the key light.
        let upn = Float(max(0, sin(th)))
        let key = Float(max(0, cos(th - 2.25)))
        let front = th < 0 || th > .pi
        var bright = 0.58 + 0.36 * upn + 0.14 * key
        if front { bright *= 0.7 }
        bright = min(1.18, bright * Float(rng.range(0.9, 1.1)))
        tufts.append((p: [(rootx, rooty), (midx, midy), (tipx, tipy)],
                      c: crown * bright, w: rng.range(5, 8.5), b: bright))
    }
    // Front drape: tentacles rooted across the near face, fountaining down from a high
    // point so they curtain over the oral disc instead of leaving the centre bare.
    let src = (cx, cyb - 326.0)
    for _ in 0..<1700 {
        let ang = rng.range(0, 2 * .pi)
        let rad = rng.unit().squareRoot()
        let rootx = cx + cos(ang) * rad * (Rx * 0.84)
        let rooty = (cyb - 156) + sin(ang) * rad * (Ry * 0.74)
        let thc = atan2(cyb - rooty, rootx - cx)
        let (rx, ry) = domeR(min(.pi, max(0, thc)))
        let nx = (rootx - cx) / rx, ny = (cyb - rooty) / ry
        if nx * nx + ny * ny > 0.9 * 0.9 { continue }   // rim is the radial pass's job
        var dx = rootx - src.0, dy = rooty - src.1
        let dl = max(1e-6, (dx * dx + dy * dy).squareRoot()); dx /= dl; dy /= dl
        let len = rng.range(34, 70)
        let tipx = rootx + dx * len, tipy = rooty + dy * len
        let wob = rng.range(-13, 13)
        let midx = (rootx + tipx) / 2 - dy * wob, midy = (rooty + tipy) / 2 + dx * wob
        let hn = Float(clamp01(Float((cyb - rooty) / Ry)))
        let keyx = Float(clamp01(0.5 - Float((rootx - cx) / (Rx * 2))))
        let bright = min(1.12, (0.5 + 0.3 * hn + 0.16 * keyx) * Float(rng.range(0.9, 1.08)))
        tufts.append((p: [(rootx, rooty), (midx, midy), (tipx, tipy)],
                      c: crown * bright, w: rng.range(5, 8), b: bright))
    }
    tufts.sort { $0.b < $1.b }
    for t in tufts { a.line(t.p, t.c, 0.5, t.w) }
    // Faint sheen catching the very top tips.
    a.softDot(cx - 40, cyb - 250, 150, crown * 1.06, 0.18, sy: 0.7)
    a.rng = rng
}
