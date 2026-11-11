import CoreGraphics
import Foundation

extension Species {
    static let brosme = SpeciesInfo(
        key: "brosme", norsk: "Brosme", latin: "Brosme brosme", english: "Tusk",
        sprites: [SpriteDef(name: "brosme", w: 640, h: 200, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.6, speed: 0.12, z: 4.5...11, alt: 0.15...0.7, amp: 0.2, wave: 7, count: 2, hover: 0.85))
        })
}

/// Tusk: a long cod relative with one continuous dorsal fin, a rounded tail, pale-edged fins
/// and a chin barbel.
private func draw(_ a: Art) {
    let finC = hex(0x4a3524), finD = hex(0x72583c), rim = hex(0xe6dfce), sub = hex(0x241a0f)
    // One continuous median fin: the single long dorsal runs the whole back, wraps the
    // rounded tail and continues as the long anal fin along the rear belly, all confluent.
    let medBase: [XY] = [
        (812, 112), (660, 88), (440, 94), (240, 116), (120, 140), (84, 150),
        (62, 158), (50, 168), (62, 182),
        (84, 190), (120, 196), (240, 214), (440, 232), (624, 246),
    ]
    let medEdge: [XY] = [
        (812, 112), (660, 54), (440, 56), (240, 80), (110, 104), (78, 118),
        (40, 130), (14, 168), (40, 206),
        (78, 220), (110, 232), (240, 256), (440, 268), (624, 246),
    ]
    a.fin(base: medBase, edge: medEdge, root: finC, tip: finD, alpha: 0.85, rays: 56)
    // Dark submarginal line, then the pale margin just outside it: the fin's defining edge.
    let subMargin = zip(medEdge, medBase).map { e, b in (e.0 * 0.80 + b.0 * 0.20, e.1 * 0.80 + b.1 * 0.20) }
    a.line(subMargin, sub, 0.55, 5)
    a.line(medEdge, rim, 0.85, 5)
    let top: [XY] = [(72, 150), (200, 124), (400, 98), (600, 86), (760, 88), (880, 106), (952, 134), (988, 164)]
    let bottom: [XY] = [(72, 180), (200, 206), (400, 230), (600, 240), (760, 238), (880, 220), (952, 196), (988, 172)]
    let back = hex(0x5a3e27), side = hex(0x8a6a48), belly = hex(0xd9c8a6)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.55)
        // Plain brownish body: only soft, fine clouding, kept to the upper flank.
        let cloud = smooth(0.56, 0.82, artNoise.fbm(x * 0.013, y * 0.05, 3)) * (1 - smooth(0.42, 0.72, v))
        c = mix(c, c * 0.86, cloud)
        // Faint juvenile cross-bars, barely there on the back.
        let bar = clamp01(cos(x * 0.040)) * (1 - smooth(0.46, 0.8, v))
        c = mix(c, c * 0.92, bar * 0.5)
        c *= 1 - scales(x, y, size: 10) * 0.05
        return rgba(c * roundLight(v))
    }
    // Pectoral fin, low behind the head.
    a.fin(base: [(802, 166), (802, 202)], edge: [(722, 176), (702, 208), (736, 236)], root: finC, tip: finD, alpha: 0.78, rays: 9)
    gill(a, 828, 100, 228, bow: 26)
    // Faint lateral line following the back's curve.
    a.line([(830, 140), (600, 128), (360, 132), (160, 148)], hex(0x3a2a1a), 0.3, 2.5)
    // Blunt snout shading and mouth.
    a.softDot(968, 150, 40, hex(0x4a3824), 0.28, sy: 0.9)
    a.line([(988, 172), (952, 184), (922, 182)], hex(0x241810), 0.55, 4)
    // Single chin barbel.
    a.line([(944, 192), (946, 220), (938, 240)], hex(0x241810), 0.4, 5)
    a.line([(944, 192), (946, 220), (938, 240)], hex(0xcabf9c), 1, 3)
    a.disc(936, 242, 4, hex(0xcabf9c), 1)
    a.eye(920, 138, 13, iris: hex(0x9a8656))
}
