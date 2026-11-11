import CoreGraphics
import Foundation

extension Species {
    static let korstroll = SpeciesInfo(
        key: "korstroll", norsk: "Vanlig korstroll", latin: "Asterias rubens", english: "Common starfish",
        sprites: [SpriteDef(name: "korstroll", w: 300, h: 186, paint: draw)],
        place: { scene in
            // Crawls far too slowly to need walk frames.
            for _ in 0..<7 {
                guard let s = scene.findSpot(z: 3.4...10, rock: 0...0.6) else { continue }
                scene.addFlat(spot: s, halfW: scene.rng.float(0.13, 0.19), halfH: 0.08, flip: true, tint: 0.9...1.08, shadowW: 0.12)
            }
        })
}

private func draw(_ a: Art) {
    a.polar(cx: 500, cy: 310, sy: 0.62, maxR: 490, radius: { th in
        let arm = pow(abs(cos(2.5 * (th + 0.3))), 2.6)
        return 110 + 370 * arm
    }) { r, th, x, y in
        var c = mix(hex(0xd4792d), hex(0xbe5620), r)
        let arm = pow(abs(cos(2.5 * (th + 0.3))), 8)
        c = mix(c, hex(0xf0c583), arm * 0.55 * (1 - r * 0.3))
        let b = spots(x, y, cell: 20, radius: 5, keep: 0.86)
        c = mix(c, hex(0xf4dcae), b * 0.75)
        let h = 1.12 - 0.42 * pow(r, 2)
        return rgba(c * h)
    }
}
