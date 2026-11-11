import CoreGraphics
import Foundation

extension Species {
    /// Green sea urchin: a dark olive test under dense, fine green spines.
    static let drobak = SpeciesInfo(
        key: "drobak", norsk: "Drøbaksjøpiggsvin", latin: "Strongylocentrotus droebachiensis", english: "Green sea urchin",
        sprites: [
            SpriteDef(name: "drobak", w: 240, h: 170) {
                BenthosArt.urchin($0, deep: hex(0x2c3f25), light: hex(0x7f9861), spine: hex(0x94a66e), length: 170, count: 300, width: 8)
            },
        ],
        place: { scene in
            for _ in 0..<9 {
                guard let s = scene.findSpot(z: 3.6...14, rock: 0.25...1.01) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.07, 0.11), mode: 0, amp: 0, shadowW: 0.12, flip: false)
            }
        })
}
