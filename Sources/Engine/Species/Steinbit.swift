import CoreGraphics
import Foundation

extension Species {
    static let steinbit = SpeciesInfo(
        key: "steinbit", norsk: "Gråsteinbit", latin: "Anarhichas lupus", english: "Atlantic wolffish",
        sprites: [SpriteDef(name: "steinbit", w: 720, h: 216, paint: draw)],
        place: { scene in
            // Keeps to rockier ground than the other bottom fish.
            scene.addRester(ResterSpec(length: 0.7, mode: 1, amp: 0.08, glide: 0.15, rest: (40, 120), z: 4...8, rock: 0.3...0.7, lift: 0,
                                       glideRock: 0.8))
        })
}

private func draw(_ a: Art) {
    let finC = hex(0x3f4a57), finD = hex(0x65727d)
    a.fin(base: [(55, 158), (880, 62)], edge: [(0, 112), (250, 92), (640, 30), (890, 28)], root: finC, tip: finD, rays: 50)
    a.fin(base: [(55, 188), (470, 232)], edge: [(0, 212), (180, 264), (480, 288)], root: finC, tip: finD, rays: 22)
    let top: [XY] = [(40, 160), (200, 136), (450, 106), (680, 74), (830, 56), (920, 62), (975, 102), (995, 150)]
    let bottom: [XY] = [(40, 186), (200, 198), (450, 224), (680, 244), (830, 250), (920, 238), (975, 208), (995, 174)]
    let back = hex(0x43505d), side = hex(0x6e7d88), belly = hex(0xc8c9bb)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.58)
        let wob = (artNoise.fbm(x * 0.02, y * 0.03, 2) - 0.5) * 18
        let band = sin((x + wob) * 0.058 + 0.5)
        let bar = smooth(0.10, 0.45, band) * (1 - smooth(0.48, 0.72, v)) * (1 - smooth(0.82, 0.90, t))
        c = mix(c, hex(0x1b2129), bar * 0.88)
        c *= 0.96 + 0.08 * artNoise.fbm(x * 0.09, y * 0.1, 2)
        return rgba(c * roundLight(v))
    }
    a.fin(base: [(770, 170), (770, 225)], edge: [(680, 182), (660, 240), (705, 294)], root: finC, tip: finD, rays: 11)
    gill(a, 802, 90, 230, bow: 26)
    // Big canine teeth, the reason for the name.
    a.fill([(994, 150), (955, 168), (900, 165), (925, 196), (994, 188)], hex(0x1a1312), 0.95)
    for (x, y0, l) in [(978.0, 158.0, 22.0), (962, 164, 20), (946, 166, 15), (928, 166, 12)] {
        a.fill([(x - 5, y0), (x, y0 + l), (x + 5, y0)], hex(0xf2ecd5), 1, raw: true)
    }
    for (x, y0, l) in [(972.0, 190.0, 18.0), (952, 193, 15), (936, 192, 11)] {
        a.fill([(x - 5, y0), (x, y0 - l), (x + 5, y0)], hex(0xf2ecd5), 1, raw: true)
    }
    a.line([(994, 150), (955, 168), (900, 165)], hex(0x7e8892), 1, 5)
    a.eye(915, 118, 15, iris: hex(0xb7a56c))
}
