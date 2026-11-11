import CoreGraphics
import Foundation

extension Species {
    static let brennmanet = SpeciesInfo(
        key: "brennmanet", norsk: "Brennmanet", latin: "Cyanea capillata", english: "Lion's mane jellyfish",
        sprites: [SpriteDef(name: "brennmanet", w: 400, h: 400, paint: draw)],
        place: { scene in
            scene.addJellies(JellySpec(count: 1, z: 6...20, y: 2.5...7, width: 0.5...0.75, drift: 0.05, rate: 0.8...1.1))
        })
}

private func draw(_ a: Art) {
    for i in 0..<100 {
        let t = Double(i) / 99
        let x = 150 + t * 700
        let y0 = 215 + 28 * sin(t * .pi)
        let len = a.rng.range(380, 760)
        let sway = a.rng.range(-45, 45)
        let col = i % 3 == 0 ? hex(0xebb04f) : hex(0xb0502e)
        a.line([(x, y0), (x + sway * 0.4, y0 + len * 0.35), (x + sway, y0 + len * 0.7), (x + sway * 0.6, y0 + len)], col, 0.48, 2.3)
    }
    for i in 0..<9 {
        let t = Double(i) / 8
        let x = 320 + t * 360
        let wig = a.rng.range(-26, 26)
        a.taper([(x, 210), (x + wig, 360), (x - wig, 520), (x + wig * 0.5, 680)], 40, 4, i % 2 == 0 ? hex(0xd05b2e) : hex(0xe69a43), 0.60)
    }
    a.polar(cx: 500, cy: 200, sy: 0.54, maxR: 372, radius: { th in
        let lobes = 15 * abs(sin(th * 8))
        return th > 0 ? 350 * (1 - 0.72 * sin(th)) + lobes : 350 + lobes
    }) { r, th, x, y in
        let radial = abs(sin(th * 24))
        var c = mix(hex(0xe5a23f), hex(0x8e2f1d), smooth(0.25, 0.92, r))
        c = mix(c, hex(0x651b13), radial * pow(r, 2) * 0.55)
        c *= 0.88 + 0.26 * artNoise.fbm(x * 0.02, y * 0.02, 2)
        return rgba(c, 0.86)
    }
    a.softDot(420, 130, 150, hex(0xffe0a8), 0.42, sy: 0.5)
}
