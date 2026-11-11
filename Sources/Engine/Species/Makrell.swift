import CoreGraphics
import Foundation

extension Species {
    static let makrell = SpeciesInfo(
        key: "makrell", norsk: "Makrell", latin: "Scomber scombrus", english: "Atlantic mackerel",
        sprites: [SpriteDef(name: "makrell", w: 400, h: 144, paint: draw)],
        place: { scene in
            scene.addSchool(SwimmerSpec(length: 0.38, speed: 1.25, z: 7...17, alt: 3...7, amp: 0.42, wave: 8, count: 10))
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x274751), finD = hex(0x51757a)
    // Deeply forked caudal fin on a slender keeled peduncle.
    a.fin(base: [(74, 170), (54, 180), (74, 190)], edge: [(2, 38), (36, 180), (2, 322)], root: finC, tip: finD, rays: 15)
    // Two well-separated dorsal fins.
    a.fin(base: [(560, 100), (690, 92)], edge: [(575, 36), (628, 16), (700, 70)], root: finC, tip: finD, alpha: 0.82, rays: 10)
    a.fin(base: [(300, 124), (432, 106)], edge: [(310, 56), (356, 38), (440, 90)], root: finC, tip: finD, alpha: 0.85, rays: 10)
    // Pelvic and anal fins below.
    a.fin(base: [(300, 240), (432, 254)], edge: [(310, 298), (356, 312), (442, 262)], root: finD, tip: finD, alpha: 0.72, rays: 8)
    a.fin(base: [(636, 262), (700, 262)], edge: [(600, 302), (648, 314), (700, 288)], root: finD, tip: finD, alpha: 0.72, rays: 6)
    let top: [XY] = [(72, 172), (150, 164), (300, 124), (470, 96), (650, 86), (800, 102), (910, 136), (990, 178)]
    let bottom: [XY] = [(72, 188), (150, 198), (300, 236), (470, 262), (650, 270), (800, 256), (910, 226), (990, 186)]
    let back = hex(0x1d6f7a), mid = hex(0xaad0c3), belly = hex(0xf2f6ee)
    let barC = hex(0x14323b), iridG = hex(0x2f8a72), iridB = hex(0x2a6f93)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: mid, belly: belly, split: 0.46)
        // Metallic blue-green iridescence shimmering across the back.
        let back01 = 1 - smooth(0.30, 0.52, v)
        let shimmer = artNoise.fbm(x * 0.018 + v * 3, y * 0.012, 3)
        c = mix(c, iridG, clamp01(shimmer - 0.52) * 0.5 * back01)
        c = mix(c, iridB, clamp01(0.48 - shimmer) * 0.45 * back01)
        // Dark wavy tiger bars: crisp, numerous, never crossing the midline.
        let wob = (artNoise.fbm(x * 0.013, y * 0.022, 2) - 0.5) * 58
        let band = sin((x + y * 0.66 + wob) * 0.112)
        let reach = 1 - smooth(0.30, 0.50, v + (artNoise.value(x * 0.03, 8) - 0.5) * 0.12)
        let onBody = smooth(0.07, 0.2, t) * (1 - smooth(0.9, 0.99, t))
        let stripe = smooth(0.28, 0.60, band) * reach * onBody
        // Faint green-gold sheen on the leading edge of each bar.
        let edge = smooth(0.1, 0.34, band) * (1 - smooth(0.34, 0.5, band)) * reach * onBody
        c = mix(c, iridG * 1.12, edge * 0.3)
        c = mix(c, barC, stripe * 0.9)
        c += C3(0.05, 0.10, 0.09) * pow(clamp01(1 - abs(v - 0.3) * 4), 2)
        c += C3(0.12, 0.10, 0.14) * pow(clamp01(1 - abs(v - 0.62) * 5), 3)
        return rgba(c * (0.68 + 0.38 * roundLight(v)))
    }
    // Row of small finlets between the rear fins and the tail.
    for i in 0..<5 {
        let x = 112 + Double(i) * 40, drop = Double(i) * 5
        let ty = 162.0 - drop
        a.fill([(x, ty), (x + 11, ty - 22), (x + 22, ty - 2), (x + 14, ty + 2)], finC, 0.95)
        let by = 200.0 + drop
        a.fill([(x, by), (x + 11, by + 22), (x + 22, by + 2), (x + 14, by - 2)], finC, 0.95)
    }
    // Keel ridge on the slender caudal peduncle.
    a.line([(88, 181), (124, 181), (152, 180)], hex(0x1a343d), 0.35, 2.5)
    // Low swept-back pectoral fin, set just behind the gill, pointing down and back.
    a.fin(base: [(802, 172), (800, 196)], edge: [(720, 206), (698, 214), (722, 210)], root: finC, tip: finD, alpha: 0.5, rays: 6)
    gill(a, 818, 108, 246, bow: 30, 0.4)
    a.line([(990, 182), (940, 200), (905, 196)], hex(0x101820), 0.8, 5)
    a.eye(912, 150, 20, iris: hex(0xd5d9c4))
}
