import CoreGraphics
import Foundation

extension Species {
    static let oskjell = SpeciesInfo(
        key: "oskjell", norsk: "O-skjell", latin: "Modiolus modiolus", english: "Horse mussel",
        sprites: [SpriteDef(name: "oskjell", w: 300, h: 150, paint: draw)],
        place: { scene in
            for _ in 0..<6 {
                guard let s = scene.findSpot(z: 3.6...14, rock: 0.2...1.01) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.09, 0.14), mode: 0, amp: 0, shadowW: 0.22)
            }
        })
}

private func draw(_ a: Art) {
    // Cluster of horse mussels half buried, with byssus threads.
    for _ in 0..<7 {
        let cx = a.rng.range(130, 870), cy = a.rng.range(180, 340)
        let ang = a.rng.range(-0.8, 0.8)
        a.ctx.saveGState()
        a.ctx.translateBy(x: cx, y: cy)
        a.ctx.rotate(by: CGFloat(ang))
        let shell: [XY] = [(-150, 14), (-80, -60), (60, -86), (160, -24), (150, 40), (40, 72), (-100, 64)]
        a.fill(shell, hex(0x1d1a27))
        a.gradient(a.path(shell), [(hex(0x52466b), 0.9, 0), (hex(0x141219), 0.9, 1)], from: (0, -80), to: (0, 70))
        for i in 1...4 {
            let f = Double(i) * 0.2
            a.line(shell.prefix(5).map { ($0.0 * f, $0.1 * f) }, hex(0x8678a1), 0.25, 4)
        }
        a.line([(-146, 26), (20, 18), (150, 38)], hex(0x0c0a12), 0.7, 4)
        a.ctx.restoreGState()
    }
}
