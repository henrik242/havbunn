import CoreGraphics
import Foundation

extension Species {
    static let sjonellik = SpeciesInfo(
        key: "sjonellik", norsk: "Sjønellik", latin: "Metridium senile", english: "Plumose anemone",
        sprites: [
            SpriteDef(name: "sjonellik", w: 280, h: 280) { draw($0, column: hex(0xe9e1d0), crown: hex(0xf8f4e7)) },
            SpriteDef(name: "sjonellik-o", w: 280, h: 280) { draw($0, column: hex(0xdf8c43), crown: hex(0xf7a95c)) },
        ],
        place: { scene in
            // Clusters, each all white or all orange.
            for _ in 0..<6 {
                guard let c = scene.findSpot(z: 4.2...16, rock: 0.5...1.01) else { continue }
                let orange = scene.rng.chance(0.3)
                for _ in 0..<scene.rng.int(3, 6) {
                    let x = c.0 + scene.rng.float(-0.35, 0.35), z = c.2 + scene.rng.float(-0.25, 0.25)
                    guard let spot = scene.ground(x, z, rockAbove: 0.4) else { continue }
                    scene.addFixture(orange ? "sjonellik-o" : "sjonellik", spot: spot,
                                     height: scene.rng.float(0.18, 0.34), mode: 5, amp: 0.05, shadowW: 0.12)
                }
            }
        })
}

/// Plumose anemone: a stout column flaring into a broad, lobed plume of fine tentacles.
private func draw(_ a: Art, column: C3, crown: C3) {
    let h = a.unitH
    let neck = 470.0
    let col: [XY] = [(300, h), (330, h - 120), (380, h - 280), (330, neck), (670, neck), (620, h - 280), (670, h - 120), (700, h)]
    a.gradient(a.path(col), [(column * 0.55, 1, 0), (column * 0.95, 1, 0.35), (column * 1.02, 1, 0.55), (column * 0.5, 1, 1)],
               from: (300, 700), to: (700, 700))
    for i in 0..<8 {
        let x = 370 + Double(i) * 37
        a.line([(x + (x - 500) * 0.4, neck + 40), (x + (x - 500) * 0.3, h - 2)], column * 0.6, 0.25, 4)
    }
    var rng = a.rng
    // Lobes, back to front, each a dome of tentacles fanning out from the oral disc.
    let lobes: [(Double, Double, Double, Float)] = [
        (330, 330, 190, 0.62), (670, 330, 190, 0.62), (420, 270, 210, 0.78), (590, 265, 210, 0.78), (500, 300, 230, 0.95),
    ]
    for (lx, ly, r, tone) in lobes {
        for _ in 0..<130 {
            let th = rng.range(-.pi * 1.05, .pi * 0.05)
            let len = r * rng.range(0.55, 1.0)
            let x0 = lx + cos(th) * r * 0.25, y0 = ly + 60 + sin(th) * r * 0.12
            let x1 = lx + cos(th) * len, y1 = max(6, ly + sin(th) * len * 0.85)
            let c = crown * tone * Float(rng.range(0.88, 1.08))
            a.line([(x0, y0), ((x0 + x1) / 2 + rng.range(-8, 8), (y0 + y1) / 2 - 6), (x1, y1)], c, 0.5, 9, smooth: false)
        }
    }
    a.softDot(470, 200, 200, crown, 0.18, sy: 0.6)
    a.rng = rng
}
