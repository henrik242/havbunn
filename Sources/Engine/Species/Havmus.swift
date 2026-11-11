import CoreGraphics
import Foundation

extension Species {
    static let havmus = SpeciesInfo(
        key: "havmus", norsk: "Havmus", latin: "Chimaera monstrosa", english: "Rabbit fish",
        sprites: [SpriteDef(name: "havmus", w: 720, h: 260, paint: draw)],
        place: { scene in
            // Comes up from deeper water now and then.
            scene.addRareVisitor(SwimmerSpec(length: 0.9, speed: 0.22, z: 7...12, alt: 0.6...2.0, amp: 0.2, wave: 5),
                                 weight: 0.25)
        })
}

/// Rabbit fish (chimaera): a big blunt head with a large green-reflecting eye, broad wing-like
/// pectorals, a tall first dorsal preceded by a stout erect venomous spine, a long low second
/// dorsal, wavy sensory canal lines on the head and a body tapering to a long whip-like tail.
private func draw(_ a: Art) {
    let back = hex(0x6a5848), side = hex(0xa6927a), belly = hex(0xcfc7ba)
    let bronze = hex(0x8c6a40), irid = hex(0x6d7b62)
    let finRoot = hex(0x5a5143), finTip = hex(0x8a8173)

    // Long whip-like tail filament, drooping to a fine point, with a very low fin fold at its base.
    let tailLine: [XY] = [(400, 198), (300, 206), (190, 214), (90, 222), (0, 230)]
    a.taper(tailLine, 30, 1.2, mix(side, back, 0.45))
    a.fin(base: [(400, 205), (300, 213), (210, 220)], edge: [(398, 215), (300, 221), (212, 225)], root: finRoot, tip: finTip, alpha: 0.4, rays: 0)

    // Long low second dorsal fin hugging the back from behind the first dorsal to the tail joint.
    // The base is tucked a little into the back so the membrane emerges flush under the body.
    let d2base: [XY] = [(730, 114), (600, 140), (480, 170), (412, 194)]
    let d2edge: [XY] = [(730, 84), (600, 110), (480, 142), (412, 172)]
    a.fin(base: d2base, edge: d2edge, root: finRoot, tip: finTip, alpha: 0.55, rays: 20)

    // Tall triangular first dorsal fin, trailing behind the spine.
    a.fin(base: [(802, 94), (862, 112)], edge: [(804, 24), (834, 40), (862, 110)], root: finRoot, tip: finTip, alpha: 0.82, rays: 11)
    // Stout erect venomous spine at the leading edge of the first dorsal.
    a.fill([(770, 100), (780, 18), (794, 20), (802, 100)], hex(0x675c4b), 0.96)
    a.line([(783, 96), (786, 22)], hex(0xeae3d5), 0.85, 3, smooth: false)
    a.line([(794, 96), (793, 28)], hex(0x332c22), 0.55, 2.4, smooth: false)

    let top: [XY] = [(380, 188), (480, 152), (600, 120), (720, 98), (820, 94), (900, 112), (960, 150), (990, 190)]
    let bottom: [XY] = [(380, 204), (480, 228), (600, 252), (720, 262), (820, 262), (900, 250), (960, 230), (990, 206)]
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.5)
        let upper = 1 - smooth(0.42, 0.72, v)
        // Marbled darker blotches over the back.
        let marble = smooth(0.5, 0.66, artNoise.fbm(x * 0.013, y * 0.05, 4))
        c = mix(c, hex(0x4a3828), marble * 0.5 * upper)
        // Cool bronze iridescent sheen along the mid-flank, greener toward the head.
        let sheen = pow(clamp01(1 - abs(v - 0.47) * 2.6), 2)
        c = mix(c, bronze, sheen * 0.24)
        c = mix(c, irid, sheen * 0.12 * clamp01(t * 1.3 - 0.2))
        // Scattered pale spots along the flank.
        let pale = spots(x, y, cell: 46, radius: 4.0, keep: 0.38, seed: 2) * (1 - smooth(0.74, 0.92, v))
        c = mix(c, hex(0xd4ccbc), pale * 0.42)
        return rgba(c * roundLight(v))
    }

    // Large wing-like pectoral fin, sweeping down and back from behind the head.
    a.fin(base: [(878, 198), (908, 250)], edge: [(700, 300), (628, 352), (776, 358)], root: finRoot, tip: finTip, alpha: 0.84, rays: 15)
    // Smaller pelvic fin, lower and further back.
    a.fin(base: [(752, 250), (778, 258)], edge: [(672, 300), (640, 332), (716, 334)], root: finRoot, tip: finTip, alpha: 0.72, rays: 8)

    // Single gill opening in front of the pectoral.
    a.line([(856, 148), (846, 196), (856, 238)], hex(0x221b13), 0.5, 4)

    // Wavy sensory-canal lines on the head, the hallmark of a chimaera.
    let canal = hex(0xd6cebd)
    a.line([(986, 174), (950, 168), (916, 178), (890, 194)], canal, 0.5, 2.4)
    a.line([(984, 196), (948, 200), (920, 214)], canal, 0.45, 2.3)
    a.line([(972, 232), (946, 240), (924, 252)], canal, 0.4, 2.1)
    a.line([(934, 130), (910, 150), (898, 178)], canal, 0.4, 2.1)

    // Small beak-like mouth under the blunt snout.
    a.fill([(990, 208), (964, 214), (956, 224), (984, 226)], hex(0x281f18), 0.85)
    a.line([(986, 216), (960, 220)], hex(0xd8d0c0), 0.55, 2, smooth: false)

    // Large iridescent green-reflecting eye on the big blunt head.
    a.eye(912, 150, 28, iris: hex(0x4e7d58))
}
