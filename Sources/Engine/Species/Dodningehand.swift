import CoreGraphics
import Foundation

extension Species {
    static let dodningehand = SpeciesInfo(
        key: "dodningehand", norsk: "Dødmannshånd", latin: "Alcyonium digitatum", english: "Dead man's fingers",
        sprites: [SpriteDef(name: "dodningehand", w: 300, h: 180, paint: draw)],
        place: { scene in
            for _ in 0..<4 {
                guard let c = scene.findSpot(z: 4...14, rock: 0.45...1.01) else { continue }
                for _ in 0..<scene.rng.int(2, 4) {
                    let x = c.0 + scene.rng.float(-0.3, 0.3), z = c.2 + scene.rng.float(-0.2, 0.2)
                    guard let spot = scene.ground(x, z, rockAbove: 0.4) else { continue }
                    scene.addFixture(spot: spot, height: scene.rng.float(0.12, 0.2), mode: 0, amp: 0, shadowW: 0.12)
                }
            }
        })
}

private func draw(_ a: Art) {
    // Thick blunt lobes grown from a shared base, furred with tiny polyps.
    let h = a.unitH
    let base = hex(0xe8d8b6)
    let lobes: [[XY]] = [
        [(290, h - 30), (210, h - 190), (140, h - 300)],
        [(420, h - 30), (390, h - 240), (340, h - 450)],
        [(530, h - 30), (560, h - 220), (530, h - 420)],
        [(640, h - 30), (700, h - 200), (760, h - 340)],
        [(770, h - 20), (850, h - 110), (890, h - 180)],
    ]
    a.disc(500, h - 22, 370, base * 0.55, 1, sy: 0.16)
    for lobe in lobes {
        let line = chaikin(lobe, iterations: 4)
        for (i, q) in line.enumerated() {
            let t = Double(i) / Double(line.count - 1)
            a.disc(q.0, q.1, 88 - 18 * t, base * 0.62)
        }
        for (i, q) in line.enumerated() {
            let t = Double(i) / Double(line.count - 1)
            a.disc(q.0 - 7, q.1 - 4, 75 - 16 * t, base)
        }
        for (i, q) in line.enumerated() where i % 3 == 0 {
            let t = Double(i) / Double(line.count - 1)
            a.softDot(q.0 - 22, q.1 - 10, 44 - 10 * t, C3(1, 0.98, 0.92), 0.28)
        }
        for _ in 0..<130 {
            let q = line[a.rng.int(0, line.count - 1)]
            let px = q.0 + a.rng.range(-70, 70), py = q.1 + a.rng.range(-70, 70)
            a.disc(px, py, 3.0, hex(0xc09a62), 0.6)
            a.disc(px, py - 1, 1.5, C3(1, 0.99, 0.94), 0.95)
        }
    }
}
