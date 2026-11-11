import CoreGraphics
import Foundation

extension Species {
    static let uer = SpeciesInfo(
        key: "uer", norsk: "Lusuer", latin: "Sebastes viviparus", english: "Norway redfish",
        sprites: [SpriteDef(name: "uer", w: 460, h: 230, paint: draw)],
        place: { scene in
            // Favours the reef mound.
            scene.addLoners(SwimmerSpec(length: 0.22, speed: 0.08, z: 6...14, alt: 0.15...0.8, amp: 0.14, wave: 6, count: 10, hover: 0.9,
                                        homeRock: 0.6...1.01))
        })
}

/// Norway redfish (Sebastes viviparus): deep orange-red rockfish with a large head and
/// high-set eye, a big oblique mouth with a jutting lower jaw, bony head ridges and
/// preopercular spines, and one long dorsal fin: serrated spiny front, soft rounded rear.
private func draw(_ a: Art) {
    let finC = hex(0x9c3a24), finD = hex(0xc5633f)
    let membrane = hex(0x8a3420), spineCol = hex(0xe3bd97)

    let top: [XY] = [(90, 238), (170, 190), (300, 118), (470, 62), (620, 56), (780, 94), (880, 170), (960, 268)]
    let bottom: [XY] = [(90, 302), (170, 330), (300, 388), (470, 438), (620, 448), (780, 428), (880, 370), (960, 300)]
    let topCurve = Curve(top)
    func topY(_ x: Double) -> Double { topCurve.value(x) }

    // Rounded caudal fin.
    a.fin(base: [(96, 240), (70, 268), (96, 300)], edge: [(4, 178), (0, 270), (4, 362)], root: finC, tip: finD, rays: 13)
    // Pelvic/anal fins on the near side, low and forward.
    a.fin(base: [(200, 362), (330, 402)], edge: [(205, 420), (270, 475), (340, 462)], root: finC, tip: finD, rays: 9)

    // ---- Long dorsal fin, head to the right: soft rounded rear (tail side) then serrated
    // spiny front (head side), sitting on the back ridge. ----
    let xTail = 252.0, xMid = 478.0, xHead = 742.0
    var dBase: [XY] = [], dEdge: [XY] = []
    // Soft rounded rear lobe, tail (left) toward the junction.
    let nSo = 9
    func softLift(_ t: Double) -> Double { 2 + 36 * sin(min(1, t) * Double.pi * 0.55) }
    for i in 0...nSo {
        let t = Double(i) / Double(nSo)
        let x = xTail + (xMid - xTail) * t
        dBase.append((x, topY(x)))
        dEdge.append((x, topY(x) - softLift(t)))
    }
    // Spiny front lobe, junction toward the head (right).
    let nSp = 12
    func spineLen(_ t: Double) -> Double { 38 - 8 * t }
    for i in 0...nSp {
        let t = Double(i) / Double(nSp)
        let x = xMid + (xHead - xMid) * t
        dBase.append((x, topY(x)))
        if i > 0 {
            let xn = x - (xHead - xMid) / Double(nSp) * 0.5
            dEdge.append((xn, topY(xn) - spineLen(t) * 0.66))
        }
        dEdge.append((x, topY(x) - spineLen(t)))
    }
    a.fill(dBase + dEdge.reversed(), membrane, 0.95, raw: true)
    // Dusky wash darkening the spiny membrane near the head.
    a.fill([(xMid, topY(xMid)), (560, topY(560) - 24), (660, topY(660) - 26),
            (xHead, topY(xHead) - 18), (xHead, topY(xHead))], hex(0x5e2414), 0.2, raw: true)
    // Stiff spines in the front lobe.
    for i in 0...nSp {
        let t = Double(i) / Double(nSp)
        let x = xMid + (xHead - xMid) * t
        a.line([(x, topY(x) + 2), (x, topY(x) - spineLen(t))], spineCol, 0.7, 2.3, smooth: false)
    }
    // Soft curved rays in the rear lobe.
    for i in 1...nSo {
        let t = Double(i) / Double(nSo)
        let x = xTail + (xMid - xTail) * t
        a.line([(x, topY(x) + 2), (x, topY(x) - softLift(t) + 2)], spineCol * 0.9, 0.4, 1.6, smooth: false)
    }

    let back = hex(0x9a3a22), side = hex(0xc4572f), belly = hex(0xe8bea2)
    a.body(top: top, bottom: bottom) { _, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.5)
        // Subtle dusky mottling, kept brownish and low-contrast.
        let m = smooth(0.55, 0.80, artNoise.fbm(x * 0.02, y * 0.026 + 4, 3)) * (1 - smooth(0.52, 0.86, v))
        c = mix(c, hex(0x6a2c1a), m * 0.42)
        // Faint broad saddles over the back.
        let barPhase = sin(x * 0.0146 + (artNoise.fbm(x * 0.012, y * 0.012, 2) - 0.5) * 2.4)
        let bars = smooth(0.45, 0.98, barPhase) * (1 - smooth(0.40, 0.70, v))
        c = mix(c, hex(0x5a2616), bars * 0.3)
        // Faint high lateral line following the back.
        let ll = clamp01(1 - abs(v - 0.33) * 40)
        c = mix(c, hex(0xf0c9a8), ll * 0.16)
        c *= 1 - scales(x, y, size: 20) * 0.10
        return rgba(c * roundLight(v))
    }

    // Rounded pectoral fin just behind the gill cover.
    a.fin(base: [(700, 262), (710, 328)], edge: [(620, 296), (598, 356), (652, 404)], root: finC, tip: finD, rays: 13)
    // Rear anal fin.
    a.fin(base: [(640, 412), (700, 412)], edge: [(590, 470), (640, 495), (700, 455)], root: finC, tip: finD, rays: 6)

    gill(a, 738, 150, 390, bow: 44, 0.4)
    // Dusky opercular blotch, typical of the species.
    a.softDot(762, 256, 70, hex(0x5a2414), 0.26, sy: 1.15)
    // Bony cheek ridges radiating back from under the eye.
    for i in 0..<4 {
        let dx = Double(i) * 18
        a.line([(748 - dx, 214 + dx), (720 - dx, 202 + dx)], hex(0x54160e), 0.6, 4.5)
    }
    a.line([(806, 232), (770, 250)], hex(0x6e2416), 0.45, 3)
    // Preopercular spines pointing back along the gill-cover margin, above the pectoral.
    for i in 0..<3 {
        let yy = 206.0 + Double(i) * 26
        a.fill([(736, yy), (710, yy + 6), (736, yy + 14)], finD, 0.85, raw: true)
        a.line([(736, yy + 7), (712, yy + 6)], hex(0xe9c3a0), 0.5, 1.6, smooth: false)
    }
    // Big oblique mouth with the lower jaw jutting ahead.
    a.fill([(958, 286), (882, 316), (892, 332), (968, 302)], hex(0x3a0f08), 0.95, raw: true)
    a.line([(958, 286), (912, 302), (880, 316)], hex(0x4a130c), 0.95, 6)
    a.line([(968, 302), (914, 324), (884, 322)], hex(0x5a1a10), 0.95, 5)
    a.line([(968, 303), (916, 322)], hex(0xe4b596), 0.5, 2.5)
    a.eye(838, 190, 42, iris: hex(0xe3ad48))
}
