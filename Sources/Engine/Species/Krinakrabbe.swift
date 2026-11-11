import CoreGraphics
import Foundation

extension Species {
    static let krinakrabbe = SpeciesInfo(
        key: "krinakrabbe", norsk: "Krinakrabbe", latin: "Galathea strigosa", english: "Spiny squat lobster",
        sprites: [SpriteDef(name: "krinakrabbe", w: 260, h: 150, paint: draw)],
        place: { scene in
            // Keeps to crevices at the reef foot.
            for _ in 0..<5 {
                guard let s = scene.findSpot(z: 4...10, rock: 0.4...0.8) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.09, 0.12), mode: 0, amp: 0, shadowW: 0.07)
            }
        })
}

/// Spiny squat lobster from the front and above: a flattened red carapace with blue
/// transverse lines, long spiny claws held forward, tail tucked under.
private func draw(_ a: Art) {
    let red = hex(0xb8352a), blue = hex(0x3a7ad6)
    let cx = 500.0, cy = 380.0
    for side in [-1.0, 1.0] {
        for i in 0..<3 {
            let x0 = cx + side * (110 + Double(i) * 30), y0 = cy + 40 + Double(i) * 30
            a.line([(x0, y0), (x0 + side * 120, y0 - 30), (x0 + side * 170, y0 + 80)], red * 0.8, 1, 16, smooth: false)
        }
        // Long claws reaching forward and out.
        let arm: [XY] = [(cx + side * 100, cy - 40), (cx + side * 220, cy - 170), (cx + side * 330, cy - 300)]
        a.taper(arm, 46, 30, red)
        for t in stride(from: 0.2, through: 0.9, by: 0.23) {
            let p = (arm[0].0 + (arm[2].0 - arm[0].0) * t, arm[0].1 + (arm[2].1 - arm[0].1) * t)
            a.line([(p.0 - 14, p.1), (p.0 + 14, p.1 + 4)], blue, 0.85, 6, smooth: false)
        }
        let tip = arm[2]
        a.taper([tip, (tip.0 + side * 40, tip.1 - 120)], 30, 6, red * 1.1)
        a.taper([tip, (tip.0 + side * 80, tip.1 - 90)], 26, 6, red * 0.9)
    }
    a.polar(cx: cx, cy: cy, sy: 0.9, maxR: 140, radius: { th in 128 + 6 * abs(sin(th * 9)) }) { r, _, x, y in
        var c = mix(red * 1.12, red * 0.75, r)
        let band = clamp01(1 - abs(sin(y * 0.11)) * 4) * (1 - smooth(0.85, 1, r))
        c = mix(c, blue, band * 0.85)
        c *= 0.9 + 0.2 * artNoise.fbm(x * 0.04, y * 0.04, 2)
        return rgba(c)
    }
    a.disc(cx - 40, cy - 120, 12, hex(0x111111))
    a.disc(cx + 40, cy - 120, 12, hex(0x111111))
}
