import CoreGraphics
import Foundation

extension Species {
    static let laks = SpeciesInfo(
        key: "laks", norsk: "Laks", latin: "Salmo salar", english: "Atlantic salmon",
        sprites: [SpriteDef(name: "laks", w: 720, h: 244, paint: draw)],
        place: { scene in
            // Passes through more often than the other rare visitors, beating its tail fast.
            scene.addRareVisitor(SwimmerSpec(length: 0.8, speed: 0.95, z: 6...12, alt: 2.5...6, amp: 0.3, wave: 6.5, beat: 4.5),
                                 weight: 0.5)
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x3c4a52), finD = hex(0x71808a)
    a.fin(base: [(88, 162), (60, 182), (88, 202)], edge: [(0, 60), (28, 182), (0, 304)], root: finC, tip: finD, rays: 16)
    a.fin(base: [(450, 82), (570, 76)], edge: [(455, 26), (495, 10), (585, 66)], root: finC, tip: finD, rays: 10)
    // Small fleshy adipose fin on the ridge between dorsal and tail; a low flap leaning
    // toward the tail, with its base hidden by the body.
    a.fill([(236, 158), (250, 124), (278, 113), (298, 122), (304, 158)], finC, 0.95)
    a.fill([(252, 134), (266, 120), (284, 118)], finD, 0.35)
    a.fin(base: [(235, 228), (330, 248)], edge: [(240, 276), (285, 300), (345, 262)], root: finD, tip: finD, rays: 8)
    a.fin(base: [(490, 268), (560, 276)], edge: [(480, 318), (525, 334), (568, 298)], root: finD, tip: finD, rays: 7)
    let top: [XY] = [(82, 170), (170, 152), (300, 112), (480, 78), (650, 70), (790, 86), (900, 124), (985, 178)]
    let bottom: [XY] = [(82, 194), (170, 208), (300, 236), (480, 268), (650, 276), (790, 262), (900, 226), (985, 188)]
    let back = hex(0x3d5159), green = hex(0x44584c), side = hex(0xbfcdcf), belly = hex(0xf7f8f3)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.38)
        // Greenish-steel sheen on the dorsal ridge, silver highlight along the flank.
        c = mix(c, green, (1 - smooth(0.0, 0.26, v)) * 0.32)
        c += C3(0.12, 0.10, 0.13) * pow(clamp01(1 - abs(v - 0.55) * 3.8), 3)
        // Lateral line: a faint silver seam running nearly straight down the flank.
        let llY: Float = 0.46 - 0.03 * smooth(0.6, 0.95, t)
        let ll = clamp01(1 - abs(v - llY) * 46)
        c = mix(c, side * 1.08, ll * 0.3)
        c = mix(c, c * 0.84, clamp01(1 - abs(v - llY - 0.028) * 80) * 0.6)
        // Fine dark freckling above the lateral line, thinning toward tail and head.
        let aboveLL = 1 - smooth(0.30, 0.46, v)
        let span = smooth(0.24, 0.32, t) * (1 - smooth(0.82, 0.92, t))
        c = mix(c, hex(0x141a1d), spots(x, y, cell: 30, radius: 4.4, keep: 0.34) * aboveLL * span * 0.9)
        c *= 1 - scales(x, y, size: 12) * 0.07
        return rgba(c * (0.7 + 0.36 * roundLight(v)))
    }
    // Characteristic black X / cross-shaped spots, mostly above the lateral line and on the gill cover.
    let spotC = hex(0x15191c)
    func xspot(_ cx: Double, _ cy: Double, _ r: Double, _ a2: Double = 0.82) {
        a.line([(cx - r, cy - r * 0.8), (cx + r, cy + r * 0.8)], spotC, a2, r * 0.6)
        a.line([(cx - r, cy + r * 0.8), (cx + r, cy - r * 0.8)], spotC, a2, r * 0.6)
    }
    func dot(_ cx: Double, _ cy: Double, _ r: Double, _ a2: Double = 0.82) {
        a.disc(cx, cy, r, spotC, a2)
        a.disc(cx + r * 0.28, cy + r * 0.2, r * 0.55, spotC, a2 * 0.6)
    }
    xspot(372, 128, 8.5); dot(420, 150, 5.2); xspot(466, 118, 7.5)
    dot(508, 142, 5.6); xspot(556, 112, 8.0); dot(598, 138, 4.8)
    xspot(640, 122, 7.8); dot(688, 150, 5.4); xspot(712, 118, 7.2)
    dot(752, 140, 5.0); xspot(792, 126, 6.8)
    // A few on the gill cover, smaller.
    dot(846, 164, 4.6); xspot(872, 148, 6.0); dot(892, 182, 4.2); dot(864, 196, 3.8)
    a.fin(base: [(758, 178), (758, 215)], edge: [(675, 196), (650, 226), (690, 262)], root: finC, tip: finD, rays: 8)
    gill(a, 802, 98, 246)
    // Operculum (gill-cover) margin for a crisper head.
    a.line([(852, 112), (838, 180), (858, 238)], hex(0x20262a), 0.3, 3)
    a.line([(985, 186), (935, 204), (884, 198)], hex(0x181a1e), 0.85, 5)
    a.eye(905, 146, 17, iris: hex(0xd7cda9))
}
