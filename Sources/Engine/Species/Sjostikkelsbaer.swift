import CoreGraphics
import Foundation

extension Species {
    static let sjostikkelsbaer = SpeciesInfo(
        key: "sjostikkelsbaer", norsk: "Kulekammanet", latin: "Pleurobrachia pileus", english: "Sea gooseberry",
        sprites: [SpriteDef(name: "sjostikkelsbaer", w: 120, h: 150, paint: draw)],
        place: { scene in
            scene.addJellies(JellySpec(count: 14, z: 3.6...8, y: 0.8...4, width: 0.035...0.05, drift: 0.02, rate: 0.3...0.6,
                                       pulse: 0.05, opacity: 0.5))
        })
}

/// Sea gooseberry, a comb jelly: a glassy, near-transparent ovoid crossed by eight meridional
/// comb rows that shimmer faintly, with two long, fine, side-branched trailing tentacles.
private func draw(_ a: Art) {
    let cx = 500.0, cy = 280.0, rx = 232.0, ry = 262.0
    let tent = C3(0.90, 0.93, 0.95)
    var rng = a.rng

    // Two long feathery tentacles trailing from pockets low on the body.
    for side in [-1.0, 1.0] {
        var pts: [XY] = []
        let n = 12
        for i in 0...n {
            let t = Double(i) / Double(n)
            let x = cx + side * 46 + sin(t * 4 + side) * 80 * t
            let y = cy + ry * 0.72 + t * (a.unitH - 24 - cy - ry * 0.72)
            pts.append((x, y))
        }
        a.line(pts, tent, 0.32, 3)
        // Fine side branchlets (pinnae) sweeping off each tentacle.
        for i in 2...n {
            let p = pts[i], q = pts[i - 1]
            let bx = p.0 - q.0, by = p.1 - q.1
            let m = max(1e-4, (bx * bx + by * by).squareRoot())
            let nx = -by / m
            let br = 26.0 + rng.range(-6, 8)
            a.line([p, (p.0 + nx * side * br - bx * 0.2, p.1 + 10)], tent, 0.22, 1.6)
        }
    }

    // Glassy, near-transparent ovoid body: thin in the centre, denser at the rim.
    a.polar(cx: cx, cy: cy, sy: ry / rx, maxR: rx + 4, radius: { _ in Float(rx) }) { r, _, _, _ in
        let c = mix(hex(0xd6e9ee), hex(0xf4fbfc), r)
        return rgba(c, 0.06 + 0.40 * pow(r, 5))
    }

    // Eight meridional comb rows: fine beating comb-plates with a faint shifting iridescence.
    let hues: [C3] = [hex(0xbfe6ff), hex(0xe9c4f0), hex(0xfde9b8), hex(0xc3f2d4)]
    for m in 0..<8 {
        let xo = -rx * 0.9 * cos(Double.pi * (Double(m) + 0.5) / 8)
        let frac = xo / rx
        let span = ry * (max(0, 1 - frac * frac)).squareRoot()
        let plateW = 15.0 * (0.5 + 0.5 * (1 - abs(frac)))      // narrower toward the rim
        var i = 0
        var y = cy - span * 0.92
        while y < cy + span * 0.92 {
            let plate = mix(C3(0.92, 0.95, 0.96), hues[(i + m) % hues.count], 0.5)
            a.line([(cx + xo - plateW, y), (cx + xo + plateW, y)], plate, 0.3, 3)
            y += 26
            i += 1
        }
    }
    // Cool highlight on the upper-left of the sphere.
    a.softDot(cx - rx * 0.4, cy - ry * 0.4, rx * 0.5, C3(1, 1, 1), 0.16, sy: ry / rx)
    a.rng = rng
}
