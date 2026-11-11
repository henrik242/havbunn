import CoreGraphics
import Foundation

extension Species {
    static let solstjerne = SpeciesInfo(
        key: "solstjerne", norsk: "Piggsolstjerne", latin: "Crossaster papposus", english: "Common sunstar",
        sprites: [SpriteDef(name: "solstjerne", w: 320, h: 198, paint: draw)],
        place: { scene in
            // Crawls far too slowly to need walk frames.
            for _ in 0..<3 {
                guard let s = scene.findSpot(z: 3.5...10, rock: 0...0.8) else { continue }
                scene.addFlat(spot: s, halfW: scene.rng.float(0.15, 0.21), halfH: 0.09, flip: false, tint: 0.92...1.05, shadowW: 0.14)
            }
        })
}

private func draw(_ a: Art) {
    let arms: Float = 11
    a.polar(cx: 500, cy: 310, sy: 0.62, maxR: 490, radius: { th in
        260 + 215 * pow(abs(cos(arms * 0.5 * th)), 2.2)
    }) { r, th, x, y in
        let inner = r < 0.52
        var c = inner ? hex(0xe35f4a) : hex(0xc73224)
        c = mix(c, hex(0xf6e1cf), smooth(0.34, 0.5, r) * (1 - smooth(0.52, 0.70, r)))
        let arm = pow(abs(cos(arms * 0.5 * th)), 8)
        if !inner { c = mix(c, hex(0xf9dfc9), arm * 0.3) }
        c = mix(c, hex(0xf4c7b0), spots(x, y, cell: 16, radius: 4.5, keep: 0.8) * 0.65)
        return rgba(c * (1.12 - 0.36 * r))
    }
}
