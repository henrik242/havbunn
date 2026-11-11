import CoreGraphics
import Foundation

extension Species {
    static let taskekrabbe = SpeciesInfo(
        key: "taskekrabbe", norsk: "Taskekrabbe", latin: "Cancer pagurus", english: "Brown crab",
        sprites: (0..<4).map { f in
            SpriteDef(name: "taskekrabbe-\(f)", w: 380, h: 170) { draw($0, frame: f) }
        },
        place: { scene in
            scene.addWalkers(WalkerSpec(gait: .sideways, length: 0.24, speed: 0.07, z: 3.6...8, rock: 0...0.4, range: 1.5,
                                        maxRock: 0.5, rest: (5, 25), count: 2))
        })
}

/// Edible crab from the front and slightly above.
private func draw(_ a: Art, frame: Int) {
    let phase = Double(frame) / 4 * 2 * .pi
    let shell = hex(0x9d5332), edge = hex(0x6c3119), leg = hex(0x8d4a2b)
    let cx = 500.0, cy = 170.0
    for side in [-1.0, 1.0] {
        for i in 0..<4 {
            let ph = phase + Double(i) * .pi / 2 + (side < 0 ? .pi : 0)
            let lift = max(0, sin(ph)) * 22
            let sw = cos(ph) * 20
            let x0 = cx + side * (170 + Double(i) * 28), y0 = cy + 40 + Double(i) * 12
            let knee = (x0 + side * (88 + Double(i) * 22) + sw * 0.4, y0 - 26 - lift * 0.4)
            let foot = (x0 + side * (150 + Double(i) * 26) + sw, y0 + 96 - lift - Double(i) * 8)
            let c = i % 2 == 0 ? leg : leg * 0.82
            a.line([(x0, y0), knee], c * 0.6, 1, 20, smooth: false)
            a.line([knee, foot], c * 0.6, 1, 14, smooth: false)
            a.line([(x0, y0), knee], c, 1, 15, smooth: false)
            a.line([knee, foot], c, 1, 10, smooth: false)
            a.line([foot, (foot.0 + side * 6, foot.1 + 14)], hex(0x151110), 1, 6, smooth: false)
        }
    }
    // Claws in front, with black tips.
    for side in [-1.0, 1.0] {
        let x = cx + side * 150, y = cy + 90
        a.taper([(cx + side * 90, cy + 66), (x, y + 8), (x + side * 8, y + 28)], 44, 34, leg)
        a.fill([(x - 42, y + 12), (x + 42, y + 8), (x + 56, y + 56), (x + 14, y + 96), (x - 40, y + 68)], shell * 1.1)
        a.softDot(x - side * 6, y + 34, 38, hex(0xdc9264), 0.55)
        a.fill([(x + 10, y + 84), (x - 16, y + 118), (x - 26, y + 72)], hex(0x14100e))
        a.fill([(x - 26, y + 72), (x - 36, y + 106), (x - 46, y + 62)], hex(0x14100e))
    }
    // Carapace with pie-crust front edge.
    a.polar(cx: cx, cy: cy, sy: 0.54, maxR: 236, radius: { th in
        let crust = th > 0 ? 8 * abs(sin(th * 11)) : 0
        return 212 + crust
    }) { r, th, x, y in
        var c = mix(hex(0xbb6d44), shell, smooth(0.0, 0.9, r))
        c = mix(c, edge, smooth(0.88, 1, r))
        c *= 0.9 + 0.2 * artNoise.fbm(x * 0.03, y * 0.03, 3)
        let lit = 1.06 - 0.26 * sin(th) * r
        let pits = spots(x, y, cell: 22, radius: 3.2, keep: 0.7)
        c = mix(c, edge, pits * 0.35)
        return rgba(c * lit)
    }
    a.softDot(cx - 40, cy - 40, 110, hex(0xefb48a), 0.32, sy: 0.5)
    a.line([(cx - 34, cy - 34), (cx - 14, cy + 22), (cx + 14, cy + 22), (cx + 34, cy - 34)], edge, 0.35, 4)
    a.disc(cx - 34, cy + 92, 6, hex(0x120d0a), 0.95, sy: 0.6)
    a.disc(cx + 34, cy + 92, 6, hex(0x120d0a), 0.95, sy: 0.6)
}
