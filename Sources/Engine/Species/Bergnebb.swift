import CoreGraphics
import Foundation

extension Species {
    static let bergnebb = SpeciesInfo(
        key: "bergnebb", norsk: "Bergnebb", latin: "Ctenolabrus rupestris", english: "Goldsinny wrasse",
        sprites: [SpriteDef(name: "bergnebb", w: 260, h: 126, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.15, speed: 0.22, z: 3.8...8, alt: 0.15...0.9, amp: 0.24, wave: 6, count: 5, hover: 0.6))
        })
}

/// Goldsinny wrasse: small, slim, red-brown to gold, with a dark spot on top of the tail stalk
/// and another at the front of the dorsal fin.
private func draw(_ a: Art) {
    let back = hex(0x864626), side = hex(0xba7a3c), belly = hex(0xe2c188)
    let rust = hex(0x7a3a1c), paleC = hex(0xe4d098)
    FishArt.wrasseBody(a, shader: { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.5)
        // Faint reddish mottling concentrated along the back.
        let m = smooth(0.50, 0.72, artNoise.fbm(x * 0.02, y * 0.03, 3))
        c = mix(c, rust, m * 0.36 * (1 - smooth(0.58, 0.90, v)))
        // Scale network and pale scale centres.
        c *= 1 - scales(x, y, size: 20) * 0.15
        let net = spots(x, y, cell: 20, radius: 3.0, keep: 0.6)
        c = mix(c, paleC, net * 0.28 * (1 - smooth(0.82, 1.0, v)))
        // Pale line following the back.
        let ll = clamp01(1 - abs(v - (0.36 + 0.05 * sin(Float(t) * 3))) * 38)
        c = mix(c, paleC, ll * 0.16)
        return rgba(c * roundLight(v))
    }, finC: hex(0x94461f), finD: hex(0xc9833f))
    a.fin(base: [(705, 256), (705, 320)], edge: [(600, 262), (570, 310), (612, 368)], root: hex(0xb06a34), tip: hex(0xd8a066), rays: 9)
    gill(a, 792, 140, 372, bow: 40)
    a.line([(978, 262), (940, 271), (905, 276)], hex(0x2a1608), 0.6, 4)
    a.eye(872, 190, 24, iris: hex(0xc58a3a))
    // Diagnostic dark blotches: upper base of the tail stalk, and the front of the dorsal fin.
    a.softDot(138, 182, 30, hex(0x160f08), 0.5)
    a.disc(138, 182, 18, hex(0x18110a), 0.92)
    a.softDot(744, 96, 24, hex(0x160f08), 0.42)
    a.disc(744, 98, 14, hex(0x18110a), 0.85)
}
