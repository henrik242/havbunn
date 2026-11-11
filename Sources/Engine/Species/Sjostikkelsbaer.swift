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

/// Sea gooseberry, a comb jelly: a clear oval with eight rows of iridescent combs and two
/// trailing, side-branched tentacles.
private func draw(_ a: Art) {
    let cx = 500.0, cy = 280.0, rx = 230.0, ry = 260.0
    let tentacle = C3(0.95, 0.90, 0.85)
    for side in [-1.0, 1.0] {
        var pts: [XY] = []
        for i in 0...8 {
            let t = Double(i) / 8
            pts.append((cx + side * 40 + sin(t * 5 + side) * 70 * t, cy + ry * 0.8 + t * (a.unitH - 20 - cy - ry * 0.8)))
        }
        a.line(pts, tentacle, 0.45, 10)
        for i in 1..<8 { a.line([pts[i], (pts[i].0 + side * 60, pts[i].1 + 30)], tentacle, 0.3, 6) }
    }
    a.polar(cx: cx, cy: cy, sy: ry / rx, maxR: rx, radius: { _ in Float(rx) }) { r, _, _, _ in
        rgba(mix(hex(0xd9ece7), hex(0xf6fbfa), r), 0.10 + 0.42 * pow(r, 4))
    }
    let combs: [C3] = [hex(0x8fe3ff), hex(0xffa6dc), hex(0xfff09e), hex(0xa6ffc2)]
    for k in -3...3 where k != 0 {
        let xo = Double(k) / 3.6 * rx
        let span = ry * (1 - (xo / rx) * (xo / rx)).squareRoot() * 0.85
        var i = 0
        var y = cy - span
        while y < cy + span {
            a.disc(cx + xo, y, 13, combs[(i + k + 8) % combs.count], 0.55)
            y += 34
            i += 1
        }
    }
}
