import CoreGraphics
import Foundation

extension Species {
    static let sjokreps = SpeciesInfo(
        key: "sjokreps", norsk: "Sjøkreps", latin: "Nephrops norvegicus", english: "Norway lobster",
        sprites: (0..<4).map { f in
            SpriteDef(name: "sjokreps-\(f)", w: 400, h: 166) { BenthosArt.lobster($0, frame: f, palette: palette) }
        },
        place: { scene in
            // Near its burrows in the softer, deeper bottom.
            scene.addWalkers(WalkerSpec(gait: .walk, length: 0.15, speed: 0.04, z: 6...10, rock: 0...0.04, range: 0.4, maxRock: 0.1,
                                        rest: (10, 45), count: 2))
        })
}

private let palette = BenthosArt.LobsterPalette(
    back: hex(0xe48e6b), side: hex(0xf5bc9c), belly: hex(0xfbe5d4), dark: hex(0xa24a33),
    leg: hex(0xeca98a), claw: hex(0xf0a78a), highlight: hex(0xffe5d2),
    speckle: 0.2, clawScale: 0.98, clawDepth: 0.55, banded: true, eye: 18, bodyY: 240, thickness: 0.72)
