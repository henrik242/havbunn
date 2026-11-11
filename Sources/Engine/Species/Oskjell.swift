import CoreGraphics
import Foundation

extension Species {
    static let oskjell = SpeciesInfo(
        key: "oskjell", norsk: "O-skjell", latin: "Modiolus modiolus", english: "Horse mussel",
        sprites: [SpriteDef(name: "oskjell", w: 300, h: 150, paint: draw)],
        place: { scene in
            for _ in 0..<6 {
                guard let s = scene.findSpot(z: 3.6...14, rock: 0.2...1.01) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.09, 0.14), mode: 0, amp: 0, shadowW: 0.22)
            }
        })
}

// Elongate-oval horse-mussel outline in a local frame, long axis horizontal,
// umbo (beak) subterminal near the narrow anterior (left) end, shell broadening
// to a high rounded posterior (right). y is down, so negative y is the dorsal
// hinge side. Index 1 is the umbo; indices 2...8 trace the growing margin.
private let oskjellOutline: [XY] = [
    (-150, 12),    // 0 anterior tip (rounded)
    (-122, -42),   // 1 umbo / beak (subterminal, a little back from the tip)
    (-34, -64),    // 2 dorsal, just behind the umbo
    (78, -60),     // 3 dorsal mid
    (146, -32),    // 4 posterior shoulder
    (168, 8),      // 5 posterior end (broad, high, rounded)
    (132, 46),     // 6 posterior-ventral
    (26, 62),      // 7 ventral mid
    (-92, 52),     // 8 ventral, near anterior
]
private let oskjellUmbo: XY = (-122, -38)

// Scale a margin strip toward the umbo to get a concentric growth contour.
private func oskjellGrow(_ pts: [XY], _ f: Double) -> [XY] {
    let u = oskjellUmbo
    return pts.map { (u.0 + ($0.0 - u.0) * f, u.1 + ($0.1 - u.1) * f) }
}

private func draw(_ a: Art) {
    // A half-buried cluster of horse mussels, drawn back to front so the near
    // shells overlap the far ones.
    for _ in 0..<7 {
        let cx = a.rng.range(150, 850), cy = a.rng.range(188, 332)
        let ang = a.rng.range(-0.52, 0.52)
        let s = a.rng.range(0.80, 1.10)
        let flip = a.rng.unit() > 0.5
        let tone = Float(a.rng.range(-0.08, 0.10))
        a.ctx.saveGState()
        a.ctx.translateBy(x: cx, y: cy)
        a.ctx.rotate(by: CGFloat(ang))
        a.ctx.scaleBy(x: s * (flip ? -1 : 1), y: s)
        oskjellShell(a, tone: tone)
        a.ctx.restoreGState()
    }
}

private func oskjellShell(_ a: Art, tone: Float) {
    let t = 1 + tone
    let outline = oskjellOutline
    let path = a.path(outline)

    // Dark blue-black shell, worn a touch bluer along the dorsal edge and
    // browner toward the ventral margin where the periostracum is thickest.
    a.fill(outline, hex(0x15141b) * t)
    a.gradient(path, [
        (hex(0x201d28) * t, 1, 0.0),   // dorsal edge, dark
        (hex(0x3a3444) * t, 1, 0.24),  // lit upper flank (cool, worn)
        (hex(0x2b2530) * t, 1, 0.52),  // mid flank
        (hex(0x1a1319) * t, 1, 0.80),  // lower flank, warming
        (hex(0x100c11) * t, 1, 1.0),   // ventral, dark
    ], from: (-2, -74), to: (10, 70))

    // Broad glossy sheen on the upper flank, soft and low-contrast.
    a.ctx.saveGState()
    a.ctx.addPath(path)
    a.ctx.clip()
    a.softDot(2, -20, 150, hex(0x5a5668) * t, 0.22, sy: 0.5)
    a.softDot(-50, -26, 70, hex(0x6a6678) * t, 0.16, sy: 0.55)
    a.ctx.restoreGState()

    // Concentric growth lines, closely packed toward the margin like real shell.
    let margin = Array(outline[2...8])
    a.ctx.saveGState()
    a.ctx.addPath(path)
    a.ctx.clip()
    let factors = [0.30, 0.42, 0.53, 0.62, 0.70, 0.77, 0.83, 0.88, 0.92, 0.955]
    for (i, f) in factors.enumerated() {
        let g = oskjellGrow(margin, f)
        // soft lighter ridge just outside the incised dark line
        a.line(oskjellGrow(margin, f + 0.012), hex(0x4a4557) * t, 0.12, 2.4)
        let dark = 0.30 + 0.10 * Double(i) / Double(factors.count - 1)
        a.line(g, hex(0x0c0a10), dark, 2.0)
    }
    a.ctx.restoreGState()

    // Worn pale bluish umbo: the periostracum is eroded off the beak, leaving a
    // matte chalky patch (kept dull, not a specular glint).
    let u = oskjellUmbo
    a.ctx.saveGState()
    a.ctx.addPath(path)
    a.ctx.clip()
    a.softDot(u.0 + 7, u.1 + 7, 44, hex(0x767b8a) * t, 0.30, sy: 0.80)
    a.softDot(u.0 + 3, u.1 + 4, 23, hex(0x8f93a1) * t, 0.28, sy: 0.82)
    a.softDot(u.0, u.1 + 1, 10, hex(0xa6a9b5) * t, 0.26)
    a.ctx.restoreGState()

    // Frayed brown periostracum: coarse bristles radiating from the growing
    // posterior and ventral margin, strongest at the lower edge.
    let fringe = chaikin(Array(outline[3...8]), iterations: 3)
    for (i, p) in fringe.enumerated() where i % 2 == 0 {
        if a.rng.unit() > 0.82 { continue }
        var dx = p.0 - u.0, dy = p.1 - u.1
        let len = (dx * dx + dy * dy).squareRoot()
        dx /= len; dy /= len
        let px = -dy, py = dx                       // tangent, for curl
        let L = a.rng.range(10, 26)
        let curl = a.rng.range(-0.5, 0.5)
        let a0: XY = (p.0 - dx * 3, p.1 - dy * 3)
        let mid: XY = (p.0 + dx * L * 0.55 + px * L * 0.18 * curl,
                       p.1 + dy * L * 0.55 + py * L * 0.18 * curl)
        let tip: XY = (p.0 + dx * L + px * L * 0.42 * curl,
                       p.1 + dy * L + py * L * 0.42 * curl)
        let brown = mix(hex(0x3c2e1f), hex(0x6b5338), Float(a.rng.unit()))
        a.line([a0, mid, tip], brown * t, a.rng.range(0.28, 0.5), a.rng.range(1.3, 2.1))
    }

    // Dark commissure where the two valves meet near the ventral margin.
    a.line(oskjellGrow(Array(outline[2...8]), 0.985), hex(0x090709), 0.5, 2.2)
    // Thin dark outline to seat the shell against the water and its neighbours.
    a.line(outline + [outline[0]], hex(0x0b0910), 0.42, 1.6)
}
