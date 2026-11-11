import CoreGraphics
import Foundation

extension Species {
    static let glassmanet = SpeciesInfo(
        key: "glassmanet", norsk: "Glassmanet", latin: "Aurelia aurita", english: "Moon jelly",
        sprites: [SpriteDef(name: "glassmanet", w: 360, h: 288, paint: draw)],
        place: { scene in
            scene.addJellies(JellySpec(count: 6, z: 6...20, y: 2.5...7, width: 0.2...0.32, drift: 0.05, rate: 1.3...1.9))
        })
}

private func draw(_ a: Art) {
    for i in 0..<34 {
        let t = Double(i) / 33
        let x = 170 + t * 660
        let len = 60 + a.rng.range(0, 60)
        let y0 = 370 + 40 * sin(t * .pi)
        a.line([(x, y0), (x + a.rng.range(-8, 8), y0 + len * 0.5), (x + a.rng.range(-14, 14), y0 + len)], hex(0xe5eef0), 0.42, 2.6)
    }
    for (x0, d) in [(420.0, -60.0), (580, 60), (500, 10)] {
        a.taper([(x0, 340), (x0 + d * 0.5, 480), (x0 + d, 650)], 36, 4, hex(0xe6eef2), 0.30)
    }
    let cx = 500.0, cy = 370.0
    a.polar(cx: cx, cy: cy, sy: 0.58, maxR: 350, radius: { th in
        // Lower half of the bell is cut flatter.
        let ripple = 3.5 * sin(th * 32)
        return th > 0 ? 340 * (1 - 0.55 * sin(th)) + ripple : 340 + ripple
    }) { r, th, _, _ in
        let a0 = 0.20 + 0.42 * r * r * r
        let c = mix(hex(0xd7e8ee), hex(0xf8fbfd), r)
        let seg = abs(sin(th * 32)) * pow(r, 3) * 0.1
        return rgba(c, a0 + seg)
    }
    // Four horseshoe gonads, the signature of this species.
    for (dx, dy) in [(-92.0, -58.0), (92, -58), (-82, 38), (82, 38)] {
        let x = cx + dx, y = cy + dy
        a.ctx.setStrokeColor(a.color(hex(0xc689c4), 0.92))
        a.ctx.setLineWidth(18)
        a.ctx.setLineCap(.round)
        a.ctx.addArc(center: CGPoint(x: x, y: y), radius: 42, startAngle: 0.5, endAngle: 5.8, clockwise: false)
        a.ctx.strokePath()
    }
    a.softDot(cx - 90, cy - 130, 150, C3(1, 1, 1), 0.3, sy: 0.5)
}
