import CoreGraphics
import Foundation

extension Species {
    static let dodningehand = SpeciesInfo(
        key: "dodningehand", norsk: "Dødmannshånd", latin: "Alcyonium digitatum", english: "Dead man's fingers",
        sprites: [SpriteDef(name: "dodningehand", w: 300, h: 180, paint: draw)],
        place: { scene in
            for _ in 0..<4 {
                guard let c = scene.findSpot(z: 4...14, rock: 0.45...1.01) else { continue }
                for _ in 0..<scene.rng.int(2, 4) {
                    let x = c.0 + scene.rng.float(-0.3, 0.3), z = c.2 + scene.rng.float(-0.2, 0.2)
                    guard let spot = scene.ground(x, z, rockAbove: 0.4) else { continue }
                    scene.addFixture(spot: spot, height: scene.rng.float(0.12, 0.2), mode: 0, amp: 0, shadowW: 0.12)
                }
            }
        })
}

/// Alcyonium digitatum: a soft coral — a fleshy colony of thick, blunt, waxy finger lobes
/// rising from a common encrusting base, the whole surface studded with tiny eight-tentacled polyps.
private func draw(_ a: Art) {
    let h = a.unitH
    let cream = hex(0xe6dabd)   // waxy creamy flesh
    let pale  = hex(0xf4efe0)   // frosted translucent highlight
    let deep  = hex(0xb09975)   // shaded underside
    let edge  = hex(0x92805e)   // crevice between lobes
    let tent  = hex(0xcabd9d)   // muted polyp tentacles

    // Centerlines of the fat blunt finger lobes, splaying up from a shared base.
    let lobes: [[XY]] = [
        [(298, h - 24), (236, h - 150), (182, h - 252), (156, h - 304)],
        [(418, h - 24), (398, h - 226), (362, h - 398), (342, h - 452)],
        [(520, h - 22), (548, h - 206), (542, h - 378), (522, h - 430)],
        [(636, h - 22), (690, h - 178), (742, h - 298), (768, h - 344)],
        [(760, h - 20), (834, h - 108), (882, h - 166), (902, h - 190)],
    ]
    let wBase: [Double] = [92, 106, 102, 96, 80]
    let wTip:  [Double] = [66, 76, 72, 68, 54]

    // Soft contact shadow and the encrusting base the lobes grow from.
    a.softDot(502, h - 6, 430, hex(0x12202a), 0.30, sy: 0.22)
    a.disc(500, h - 18, 362, deep * 0.9, 1, sy: 0.17)
    a.disc(500, h - 26, 330, cream * 0.84, 1, sy: 0.15)

    let smoothed = lobes.map { chaikin($0, iterations: 4) }
    for (i, line) in smoothed.enumerated() {
        drawLobe(a, line, wBase[i], wTip[i], cream: cream, pale: pale, deep: deep, edge: edge)
    }
    for (i, line) in smoothed.enumerated() {
        drawPolyps(a, line, wBase[i], wTip[i], pale: pale, tent: tent, deep: deep)
    }
}

/// Fleshy blunt finger built from stacked discs, lit as a rounded waxy cylinder.
private func drawLobe(_ a: Art, _ line: [XY], _ wB: Double, _ wT: Double,
                      cream: C3, pale: C3, deep: C3, edge: C3) {
    let n = line.count
    func w(_ t: Double) -> Double { wB + (wT - wB) * t }

    // Soft dark edge/crevice so adjacent lobes read as separate fingers over dark water.
    for (i, q) in line.enumerated() {
        let t = Double(i) / Double(n - 1)
        a.disc(q.0 + 3, q.1 + 5, w(t) + 3, edge, 0.85)
    }
    // Base flesh, paler toward the translucent tip.
    for (i, q) in line.enumerated() {
        let t = Double(i) / Double(n - 1)
        let c = mix(deep, cream, Float(0.28 + 0.72 * t))
        a.disc(q.0, q.1, w(t), c)
    }
    // Rounded form light: stacked offsets toward the top-left, each smaller and brighter.
    for pass in 0..<3 {
        let off = Double(pass + 1) * 0.14
        let shrink = 0.08 + Double(pass) * 0.12
        for (i, q) in line.enumerated() {
            let t = Double(i) / Double(n - 1)
            let r = w(t)
            let c = mix(cream, pale, Float(0.22 + 0.22 * Double(pass) + 0.2 * t))
            a.disc(q.0 - r * off, q.1 - r * off * 0.8, r * (1 - shrink - off), c, 0.5)
        }
    }
    // Frosted translucent sheen down the lit flank.
    for (i, q) in line.enumerated() where i % 2 == 0 {
        let t = Double(i) / Double(n - 1)
        a.softDot(q.0 - w(t) * 0.5, q.1 - w(t) * 0.22, w(t) * 0.55, pale, 0.12)
    }
}

/// Scatter tiny eight-tentacled polyps across the lobe surface, following the centerline.
private func drawPolyps(_ a: Art, _ line: [XY], _ wB: Double, _ wT: Double,
                        pale: C3, tent: C3, deep: C3) {
    var rng = a.rng
    let n = line.count
    let count = Int(Double(n) * 2.3)
    for _ in 0..<count {
        // Thin the polyps near the base and leave occasional bare patches on the flesh.
        if rng.chance(0.14) { continue }
        let t = rng.range(0.03, 0.99)
        let fi = t * Double(n - 1)
        let i = min(n - 1, Int(fi))
        let q = line[i]
        let aPt = line[max(0, i - 1)], bPt = line[min(n - 1, i + 1)]
        var nx = -(bPt.1 - aPt.1), ny = bPt.0 - aPt.0
        let len = max(1e-6, (nx * nx + ny * ny).squareRoot())
        nx /= len; ny /= len
        let w = wB + (wT - wB) * t
        let u = rng.range(-0.84, 0.84)
        let px = q.0 + nx * u * w, py = q.1 + ny * u * w
        let s = w * 0.1 * rng.range(0.7, 1.4)
        let lit = Float(0.5 - u * 0.5)   // lit flank sits on the left
        polyp(a, px, py, s, &rng, pale: pale, tent: tent, deep: deep, lit: lit)
    }
    a.rng = rng
}

/// One polyp: a translucent bump, often open into an eight-rayed star of tentacles.
private func polyp(_ a: Art, _ x: Double, _ y: Double, _ s: Double, _ rng: inout RNG,
                   pale: C3, tent: C3, deep: C3, lit: Float) {
    a.softDot(x, y, s * 2.1, pale, 0.11)
    if rng.chance(0.66) {
        let base = rng.range(0, .pi / 2)
        let tc = mix(tent, deep, 0.25)
        for k in 0..<8 {
            let an = base + Double(k) / 8 * 2 * .pi
            let r1 = s * (1.5 + rng.range(-0.18, 0.28))
            a.line([(x + cos(an) * s * 0.45, y + sin(an) * s * 0.45 * 0.9),
                    (x + cos(an) * r1, y + sin(an) * r1 * 0.9)],
                   tc, 0.42, max(0.8, s * 0.22), smooth: false)
        }
    }
    a.disc(x, y, s * 0.6, mix(pale, deep, 0.38), 0.7)
    a.disc(x - s * 0.12, y - s * 0.14, s * 0.34, mix(pale, C3(1, 1, 1), 0.25 + 0.4 * lit), 0.75)
}
