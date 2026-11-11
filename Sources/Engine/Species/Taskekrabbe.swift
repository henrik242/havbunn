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
    // Big claws held forward, each a swollen hand ending in a black-tipped pincer.
    for side in [-1.0, 1.0] {
        let hx = cx + side * 156, hy = cy + 96      // hand (propodus) centre
        // Upper arm (merus) from the shell to the hand.
        a.taper([(cx + side * 96, cy + 58), (cx + side * 150, cy + 62), (hx + side * 4, hy - 30)], 46, 40, leg * 0.9)
        // Swollen hand.
        a.disc(hx, hy, 50, shell * 0.9, 1, sy: 0.92)
        a.disc(hx, hy, 45, shell * 1.06, 1, sy: 0.92)
        a.softDot(hx - side * 12, hy - 16, 28, hex(0xe0996b), 0.5)
        // Two pincer fingers, slightly agape, with the brown crab's black tips.
        let fixed = (hx + side * 8, hy + 94)        // fixed finger (lower)
        let dactyl = (hx - side * 26, hy + 82)      // movable finger (upper)
        let fBase = (hx + side * 10, hy + 28), dBase = (hx - side * 12, hy + 20)
        a.taper([fBase, ((fBase.0 + fixed.0) / 2 + side * 5, (fBase.1 + fixed.1) / 2), fixed], 30, 6, shell)
        a.taper([dBase, ((dBase.0 + dactyl.0) / 2 - side * 4, (dBase.1 + dactyl.1) / 2), dactyl], 24, 5, shell * 0.92)
        a.taper([((fBase.0 + fixed.0) / 2, (fBase.1 + fixed.1) / 2), fixed], 15, 4, hex(0x14100e))
        a.taper([((dBase.0 + dactyl.0) / 2, (dBase.1 + dactyl.1) / 2), dactyl], 12, 3, hex(0x14100e))
    }
    // Carapace with the diagnostic pie-crust scalloped front margin.
    a.polar(cx: cx, cy: cy, sy: 0.54, maxR: 240, radius: { th in
        // Lobes run along the antero-lateral (lower) margin, th in (0, pi).
        let front = smooth(0.12, 0.6, th) * (1 - smooth(2.54, 3.02, th))
        let crust = front * 22 * pow(abs(sin(th * 9)), Float(0.7))
        return 206 + crust
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
