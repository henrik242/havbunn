import CoreGraphics
import Foundation

extension Species {
    static let lyr = SpeciesInfo(
        key: "lyr", norsk: "Lyr", latin: "Pollachius pollachius", english: "Pollack",
        sprites: [SpriteDef(name: "lyr", w: 620, h: 216, paint: draw)],
        place: { scene in
            scene.addLoners(SwimmerSpec(length: 0.55, speed: 0.24, z: 5...12, alt: 0.8...2.6, amp: 0.30, wave: 6.5, count: 4, hover: 0.7))
        })
}

/// Pollack: like saithe but bronze-olive, with a lateral line arching strongly over the
/// pectoral and a jutting lower jaw. No barbel.
private func draw(_ a: Art) {
    let finC = hex(0x45432d), finD = hex(0x797048)
    // Caudal (slightly forked), three dorsals, then two anals, drawn before the body.
    a.fin(base: [(92, 172), (60, 186), (92, 200)], edge: [(0, 80), (30, 186), (0, 294)], root: finC, tip: finD, alpha: 0.82, rays: 16)
    a.fin(base: [(130, 165), (280, 122)], edge: [(140, 118), (212, 78), (290, 82)], root: finC, tip: finD, alpha: 0.78, rays: 11)
    a.fin(base: [(300, 116), (460, 82)], edge: [(310, 64), (386, 28), (470, 40)], root: finC, tip: finD, alpha: 0.78, rays: 12)
    a.fin(base: [(485, 78), (630, 70)], edge: [(495, 30), (572, 14), (640, 32)], root: finC, tip: finD, alpha: 0.78, rays: 11)
    a.fin(base: [(150, 206), (310, 246)], edge: [(160, 250), (226, 290), (320, 296)], root: finC, tip: finD, alpha: 0.72, rays: 11)
    a.fin(base: [(340, 254), (510, 278)], edge: [(355, 298), (432, 328), (520, 318)], root: finC, tip: finD, alpha: 0.72, rays: 12)
    a.fin(base: [(810, 262), (845, 258)], edge: [(770, 312), (800, 318), (840, 292)], root: finC, tip: finD, alpha: 0.72, rays: 5)
    let top: [XY] = [(85, 176), (170, 160), (300, 116), (480, 80), (650, 68), (790, 80), (900, 118), (975, 166)]
    let bottom: [XY] = [(85, 196), (170, 206), (300, 236), (480, 270), (650, 280), (790, 270), (900, 236), (985, 200)]
    let back = hex(0x474a2b), side = hex(0xa79a5e), belly = hex(0xe7e1c8)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.48)
        // Brassy sheen along the mid-flank.
        c += C3(0.06, 0.05, 0.018) * pow(clamp01(1 - abs(v - 0.56) * 2.7), 2)
        // Dorsal mottling: broken greenish-brown marbling, strongest on the back.
        let dorsal = 1 - smooth(0.24, 0.52, v)
        let marble = smooth(0.52, 0.72, artNoise.fbm(x * 0.032, y * 0.05, 3))
        c = mix(c, hex(0x3b4023), marble * dorsal * 0.46)
        let fleck = spots(x, y, cell: 16, radius: 3.9, keep: 0.52, seed: 5)
        c = mix(c, hex(0x33371d), fleck * dorsal * 0.36)
        c *= 1 - scales(x, y, size: 11) * 0.06
        _ = t
        return rgba(c * roundLight(v))
    }
    // Lateral line: dark, arching high over the pectoral then running to the tail.
    let llPts: [XY] = [(128, 181), (280, 171), (440, 158), (600, 142),
                       (720, 128), (790, 120), (842, 124), (886, 140), (912, 154)]
    a.line(llPts, hex(0x262514), 0.3, 5)
    a.line(llPts, hex(0x201f10), 0.62, 2.6)
    a.fin(base: [(760, 172), (760, 214)], edge: [(675, 176), (645, 210), (685, 248)], root: finC, tip: finD, alpha: 0.72, rays: 9)
    gill(a, 795, 96, 252, bow: 30, 0.2)
    // Gill cover (operculum) edge and a faint cheek shade.
    a.line([(858, 114), (877, 170), (863, 224)], hex(0x2b2816), 0.22, 3)
    a.softDot(878, 198, 38, hex(0x7d7446), 0.14)
    // Terminal mouth with a jutting lower jaw.
    a.line([(905, 199), (952, 200), (984, 193)], hex(0x22200f), 0.52, 3.5)
    a.fill([(970, 200), (997, 192), (995, 203), (968, 210)], hex(0xc0b588))
    a.line([(975, 168), (946, 180), (912, 180)], hex(0x22200f), 0.36, 3)
    a.eye(905, 146, 19, iris: hex(0x8f8452))
}
