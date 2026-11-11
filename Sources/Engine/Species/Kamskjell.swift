import CoreGraphics
import Foundation

extension Species {
    static let kamskjell = SpeciesInfo(
        key: "kamskjell", norsk: "Stort kamskjell", latin: "Pecten maximus", english: "King scallop",
        sprites: [SpriteDef(name: "kamskjell", w: 220, h: 158, paint: draw)],
        place: { scene in
            for _ in 0..<5 {
                guard let s = scene.findSpot(z: 3.4...10, rock: 0...0.2) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.06, 0.09), mode: 0, amp: 0, shadowW: 0.09)
            }
        })
}

private func draw(_ a: Art) {
    a.polar(cx: 500, cy: 370, sy: 0.72, maxR: 460, radius: { th in
        let sc = 7 * abs(sin(th * 15))
        return (th > 1.1 && th < 2.04) ? 150 + (abs(th - 1.57) * 450) : 420 + sc
    }) { r, th, x, y in
        let ribs = abs(sin(th * 15))
        var c = mix(hex(0xd5a06a), hex(0xbe6c50), smooth(0.2, 1, r))
        c *= 0.76 + 0.34 * pow(ribs, 0.6)
        let growth = sin(r * 44 + artNoise.value(x * 0.01, y * 0.01) * 3)
        c *= 0.95 + 0.05 * growth
        return rgba(c * (0.96 + 0.15 * (1 - r)))
    }
    a.fill([(390, 620), (610, 620), (580, 670), (420, 670)], hex(0xb88358))
}
