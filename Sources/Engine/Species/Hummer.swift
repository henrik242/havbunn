import CoreGraphics
import Foundation

extension Species {
    static let hummer = SpeciesInfo(
        key: "hummer", norsk: "Hummer", latin: "Homarus gammarus", english: "European lobster",
        sprites: (0..<4).map { f in
            SpriteDef(name: "hummer-\(f)", w: 480, h: 200) { BenthosArt.lobster($0, frame: f, palette: palette) }
        },
        place: { scene in
            // By day: in or at the mouth of a crevice, rarely venturing out.
            scene.addWalkers(WalkerSpec(gait: .walk, length: 0.30, speed: 0.04, z: 4...8, rock: 0.3...0.6, range: 0.5, maxRock: 0.75,
                                        rest: (20, 70)))
        })
}

private let palette = BenthosArt.LobsterPalette(
    back: hex(0x16243a), side: hex(0x2f4a68), belly: hex(0xb8ae90), dark: hex(0x0a1220),
    leg: hex(0x34506f), claw: hex(0x22385a), highlight: hex(0x7d97b5),
    speckle: 0.9, clawScale: 1.22, clawDepth: 1.0, banded: false, eye: 13, bodyY: 235, thickness: 1.0)
