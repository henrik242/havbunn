import CoreGraphics
import Foundation

extension Species {
    static let stortare = SpeciesInfo(
        key: "stortare", norsk: "Stortare", latin: "Laminaria hyperborea", english: "Forest kelp",
        sprites: [
            SpriteDef(name: "stortare-1", w: 340, h: 760) { draw($0, seed: 3) },
            SpriteDef(name: "stortare-2", w: 340, h: 760) { draw($0, seed: 17) },
            SpriteDef(name: "stortare-3", w: 340, h: 760) { draw($0, seed: 41) },
        ],
        place: { scene in
            // Kelp thins out to scattered plants at this depth, on the higher rock only.
            for _ in 0..<7 {
                guard let s = scene.findSpot(z: 9...24, rock: 0.6...1.01), s.1 > 1.2 else { continue }
                scene.addFixture("stortare-\(scene.rng.int(1, 3))", spot: s, height: scene.rng.float(1.2, 2.0), mode: 2, amp: 0.045,
                                 shadowW: 0.3, tint: kelpTint)
            }
        })
}

/// Laminaria hyperborea: stiff stipe holding a broad blade split into straps.
private func draw(_ a: Art, seed: UInt64) {
    var rng = RNG(seed)
    let h = a.unitH
    let crown: XY = (500 + rng.range(-30, 30), h * 0.56)
    // The whole blade streams one way in the current, so it never reads as a symmetric cup.
    let sweep = (rng.chance(0.5) ? 1.0 : -1.0) * rng.range(170, 300)
    let straps = 17
    var order = Array(0..<straps)
    for i in order.indices.reversed() { order.swapAt(i, rng.int(0, i)) }
    for (rank, i) in order.enumerated() {
        let t = Double(i) / Double(straps - 1)
        let spread = t - 0.5
        let startX = crown.0 + spread * 300
        let startY = crown.1 - 120 - (0.25 - spread * spread) * 300
        let len = rng.range(0.72, 1.0) * (crown.1 - 40)
        let tipX = startX + spread * 340 + sweep * rng.range(0.7, 1.2)
        let tipY = max(14, crown.1 - len)
        let wig = rng.range(30, 90) * (rng.chance(0.5) ? 1 : -1)
        let pts: [XY] = [(crown.0 + spread * 90, crown.1 - 30), (startX, startY),
                         (startX + (tipX - startX) * 0.28 + wig, startY + (tipY - startY) * 0.35),
                         (startX + (tipX - startX) * 0.66 - wig, startY + (tipY - startY) * 0.68), (tipX, tipY)]
        let depth = Float(rank) / Float(straps - 1)
        let c = mix(hex(0x5a3f17), hex(0xa98336), depth * 0.75 + Float(rng.unit()) * 0.25)
        a.taper(pts, rng.range(78, 118), rng.range(18, 34), c)
        a.taper(pts.map { ($0.0 - 7, $0.1) }, 14, 5, hex(0xd7b464), 0.2)
    }
    let palm: [XY] = [(crown.0, crown.1 + 6), (crown.0 - 110, crown.1 - 70), (crown.0 - 170, crown.1 - 210),
                      (crown.0, crown.1 - 280), (crown.0 + 170, crown.1 - 210), (crown.0 + 110, crown.1 - 70)]
    a.gradient(a.path(palm), [(hex(0x4a3211), 1, 0), (hex(0x7c5f27), 0.9, 0.6), (hex(0x7c5f27), 0, 1)],
               from: (crown.0, crown.1), to: (crown.0, crown.1 - 280))
    let st: [XY] = [(500, h - 2), (520 + rng.range(-20, 20), h * 0.76), crown]
    a.taper(st, 74, 40, hex(0x4e3b1c))
    a.taper(st.map { ($0.0 - 9, $0.1) }, 30, 14, hex(0x7d6333), 0.8)
    for _ in 0..<34 {
        let t = rng.range(0.70, 0.98)
        let x = 500 + rng.range(-38, 38), y = h * t
        a.line([(x, y), (x + rng.range(-46, 46), y - rng.range(16, 44))], hex(0x8d2d38), 0.85, 6)
    }
    for i in 0..<9 {
        let x = 500 + (Double(i) - 4) * 40
        a.taper([(500, h - 50), (x, h - 24), (x + (x - 500) * 0.3, h - 1)], 26, 12, hex(0x3d2d13))
    }
}
