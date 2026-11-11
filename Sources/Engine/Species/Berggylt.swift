import CoreGraphics
import Foundation

extension Species {
    static let berggylt = SpeciesInfo(
        key: "berggylt", norsk: "Berggylte", latin: "Labrus bergylta", english: "Ballan wrasse",
        sprites: [SpriteDef(name: "berggylt", w: 500, h: 240, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.38, speed: 0.18, z: 3.9...10, alt: 0.3...1.4, amp: 0.2, wave: 6, count: 2, hover: 0.7))
        })
}

private func draw(_ a: Art) {
    let back = hex(0x46602f), side = hex(0x7e8a4e), belly = hex(0xd6c48c)
    let rust = hex(0x8a5226), paleG = hex(0xb4bd7c), cream = hex(0xe2d9a6)
    FishArt.wrasseBody(a, shader: { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.50)
        // Broad reddish-brown blotching over the green back, coarse then finer.
        let big = smooth(0.46, 0.70, artNoise.fbm(x * 0.013, y * 0.018, 3))
        c = mix(c, rust, big * 0.50 * (1 - smooth(0.74, 0.96, v)))
        let fine = smooth(0.52, 0.72, artNoise.fbm(x * 0.05 + 7, y * 0.06, 3))
        c = mix(c, c * 0.80, fine * 0.32)
        // Reticulation: a dark net between scales with a pale spot at each scale centre.
        c = mix(c, c * 0.72, scales(x, y, size: 25) * 0.26)
        let spotCol = mix(paleG, cream, artNoise.fbm(x * 0.03, y * 0.03 + 3, 2))
        let dens = 0.35 + 0.55 * artNoise.fbm(x * 0.02 + 1, y * 0.02, 2)
        let net = spots(x, y, cell: 25, radius: 3.5, keep: 0.72) * dens
        c = mix(c, spotCol, net * (1 - smooth(0.80, 0.98, v)) * 0.82)
        return rgba(c * roundLight(v))
    }, finC: hex(0x4c6236), finD: hex(0x868950))
    a.fin(base: [(705, 256), (705, 320)], edge: [(590, 262), (560, 310), (605, 372)], root: hex(0x7c7c4c), tip: hex(0xb4a668), rays: 10)
    gill(a, 792, 140, 372, bow: 40)
    // Big fleshy lips, the wrasse's most obvious feature.
    a.taper([(987, 259), (969, 263), (948, 267)], 20, 11, hex(0xbf9570))
    a.taper([(986, 281), (967, 282), (946, 283)], 16, 10, hex(0xb5885f))
    a.softDot(983, 271, 15, hex(0xc9a074), 0.5)
    a.line([(986, 271), (951, 275), (919, 279)], hex(0x241a10), 0.85, 3.2)
    a.eye(872, 188, 22, iris: hex(0xd29545))
}
