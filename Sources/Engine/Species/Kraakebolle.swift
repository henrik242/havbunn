import CoreGraphics
import Foundation

extension Species {
    /// Edible sea urchin: a big rosy globe with short, pale spines.
    static let kraakebolle = SpeciesInfo(
        key: "kraakebolle", norsk: "Svabergsjøpiggsvin", latin: "Echinus esculentus", english: "Edible sea urchin",
        sprites: [
            SpriteDef(name: "kraakebolle", w: 280, h: 220) {
                BenthosArt.urchin($0, deep: hex(0x9f4154), light: hex(0xe89fa9), spine: hex(0xd7a7a0),
                                  length: 82, count: 230, width: 11,
                                  tipWidth: 4.0, tipPale: 0.55,
                                  tubercleN: 160, tubercleR: 12, tubercleA: 0.5)
            },
        ],
        place: { scene in
            for _ in 0..<5 {
                guard let s = scene.findSpot(z: 3.6...14, rock: 0.25...1.01) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.11, 0.16), mode: 0, amp: 0, shadowW: 0.15, flip: false)
            }
        })
}
