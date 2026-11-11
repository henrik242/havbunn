import CoreGraphics
import Foundation

extension Species {
    static let sild = SpeciesInfo(
        key: "sild", norsk: "Sild", latin: "Clupea harengus", english: "Atlantic herring",
        sprites: [SpriteDef(name: "sild", w: 300, h: 96, paint: draw)],
        place: { scene in
            scene.addSchool(SwimmerSpec(length: 0.30, speed: 0.95, z: 8...18, alt: 3...7.5, amp: 0.4, wave: 7, count: 80))
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x51676f), finD = hex(0x90a3a7)
    // Deeply forked tail, single mid-body dorsal, small pelvic and anal fins.
    a.fin(base: [(85, 142), (55, 160), (85, 178)], edge: [(0, 42), (42, 160), (0, 278)], root: finC, tip: finD, rays: 12)
    a.fin(base: [(450, 80), (560, 75)], edge: [(465, 20), (510, 14), (575, 66)], root: finC, tip: finD, rays: 8)
    a.fin(base: [(205, 218), (320, 240)], edge: [(215, 262), (270, 282), (330, 258)], root: finD, tip: finD, rays: 7)
    a.fin(base: [(490, 262), (545, 266)], edge: [(470, 300), (510, 322), (548, 292)], root: finD, tip: finD, rays: 6)

    let top: [XY] = [(80, 150), (180, 126), (350, 90), (540, 70), (720, 72), (860, 96), (985, 150)]
    let bottom: [XY] = [(80, 172), (180, 192), (350, 236), (540, 270), (720, 268), (860, 226), (985, 166)]
    let back = hex(0x2b5159), ridge = hex(0x15313a), side = hex(0xb4cace), belly = hex(0xf1f6f4)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.30)
        // Crisp dark blue-green dorsal cap for a sharp countershade line.
        c = mix(c, ridge, clamp01(1 - v * 7) * 0.85)
        // Metallic blue-green to violet iridescence in a band under the back.
        let irid = pow(clamp01(1 - abs(v - 0.32) * 4.0), 2) * smooth(0.05, 0.2, t)
        let hue = artNoise.value(x * 0.009, 5.3)
        c += mix(C3(-0.03, 0.05, 0.01), C3(0.05, -0.01, 0.06), hue) * irid
        // Broad cool metallic sheen along the silver flank.
        let sheen = pow(clamp01(1 - abs(v - 0.5) * 2.6), 3)
        c += C3(0.10, 0.12, 0.12) * sheen
        // Fine along-body glint, softened so it stays legible when small.
        let glint = pow(artNoise.value(x * 0.009, 3.1), 3) * 0.07
        c += C3(glint, glint * 1.08, glint * 1.16)
        // Faint large scale rows, strongest on the upper silver flank, fading at belly and back.
        let scaleMask = smooth(0.14, 0.34, v) * (1 - smooth(0.66, 0.9, v))
        c *= 1 - scales(x, y, size: 30) * 0.075 * scaleMask
        _ = t
        return rgba(c * (0.74 + 0.32 * roundLight(v)))
    }
    // Pectoral fin, low behind the gill.
    a.fin(base: [(770, 214), (770, 238)], edge: [(700, 240), (680, 262), (712, 268)], root: finC, tip: finD, alpha: 0.6, rays: 5)
    // Keeled, light-catching belly edge.
    a.line([(150, 188), (350, 232), (540, 266), (720, 263), (868, 223)], hex(0xf8fbf9), 0.4, 3)
    // Silvery gill cover: soft highlight on the cheek, then the operculum rim and gill slit.
    a.softDot(852, 170, 48, hex(0xe1edec), 0.32, sy: 1.1)
    a.line([(820, 96), (792, 150), (812, 232)], hex(0xcddddc), 0.4, 3)
    a.line([(812, 96), (786, 150), (806, 236)], hex(0x203038), 0.3, 4)
    gill(a, 805, 112, 228, bow: 22, 0.3)
    a.softDot(800, 210, 26, hex(0x8f5a60), 0.22, sy: 1.1)
    a.line([(985, 157), (948, 186), (908, 182)], hex(0x101820), 0.7, 6)
    a.eye(905, 138, 25, iris: hex(0xc3d0cf))
}
