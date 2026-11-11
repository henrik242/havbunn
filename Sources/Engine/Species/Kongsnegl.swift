import CoreGraphics
import Foundation

extension Species {
    static let kongsnegl = SpeciesInfo(
        key: "kongsnegl", norsk: "Kongsnegl", latin: "Buccinum undatum", english: "Common whelk",
        sprites: [SpriteDef(name: "kongsnegl", w: 220, h: 160, paint: draw)],
        place: { scene in
            // Creeps almost without pause.
            scene.addRester(ResterSpec(length: 0.1, mode: 0, amp: 0, glide: 0.012, rest: (1, 5), z: 3.6...7, rock: 0...0.2, lift: 0,
                                       crawls: true))
        })
}

/// One whorl of the shell, centre (cx,cy), outer radii (rx,ry).  `tone` ages the whorl toward
/// the apex, `phase` offsets its ribs so the axial folds do not line up between whorls.
private struct Whorl { let cx, cy, rx, ry, tone, phase: Double }

/// Shades a whorl as a solid rounded tube (a bead lit from the upper left) rather than a flat
/// disc, so the stacked whorls read as a 3-D cone with no radial sunburst.  Carries curved axial
/// ribs, fine spiral cords and a dark suture groove at the rim.
private func shellShade(_ rr: Float, _ th: Float, phase: Float, tone: Float, x: Float, y: Float) -> C3 {
    // Dull pale brown/grey, a touch lighter along the crown of the tube.
    var c = mix(hex(0xbfa577), hex(0x8a7048), smooth(0.1, 1.0, rr))
    // Bead lighting: the surface normal tilts outward as rr grows; light from upper-left-front.
    let nz = (1 - rr * rr).squareRoot()
    let nx = cos(th) * rr, ny = sin(th) * rr
    let dif = max(0, nx * -0.42 + ny * -0.54 + nz * 0.73)
    c *= 0.50 + 0.70 * dif
    // Curved axial ribs (undatum = "waved"): nine folds, skewed with radius so they curve.
    // Faded out near the coil centre so the whorl never shows a radial sunburst.
    c *= 1 + 0.10 * smooth(0.12, 0.72, rr) * sin(th * 9 + phase + rr * 1.6)
    // Fine spiral cords running around the coil.
    c *= 1 + 0.045 * smooth(0.1, 0.5, rr) * sin(rr * 34)
    // Suture groove: a dark seam just inside the rim where the next whorl laps on.
    c *= 1 - 0.34 * smooth(0.80, 1.0, rr)
    // Weathered grain.
    c *= 0.96 + 0.08 * artNoise.fbm(x * 0.04, y * 0.04, 2)
    return c * tone
}

/// Common whelk crawling: a tall multi-whorl spire of a dull pale shell above a muscular creeping
/// foot, with the siphon tube reaching forward and two short head tentacles.
private func draw(_ a: Art) {
    foot(a)
    // Shell: a cone of whorls, apex (upper left) first so the body whorl laps over it in front.
    let whorls: [Whorl] = [
        Whorl(cx: 530, cy: 428, rx: 322, ry: 236, tone: 1.00, phase: 0.0),
        Whorl(cx: 418, cy: 298, rx: 212, ry: 152, tone: 0.98, phase: 1.1),
        Whorl(cx: 338, cy: 212, rx: 140, ry: 101, tone: 0.95, phase: 2.0),
        Whorl(cx: 286, cy: 158, rx: 92, ry: 67, tone: 0.92, phase: 0.6),
        Whorl(cx: 250, cy: 120, rx: 60, ry: 44, tone: 0.89, phase: 1.7),
        Whorl(cx: 228, cy: 94, rx: 38, ry: 28, tone: 0.86, phase: 2.6),
    ]
    for w in whorls.reversed() {
        a.polar(cx: w.cx, cy: w.cy, sy: w.ry / w.rx, maxR: w.rx, radius: { _ in Float(w.rx) }) { rr, th, x, y in
            rgba(shellShade(rr, th, phase: Float(w.phase), tone: Float(w.tone), x: x, y: y))
        }
    }
    aperture(a)
    siphonAndHead(a)
}

/// The muscular creeping foot: a broad pale sole under and ahead of the shell, speckled, with a
/// soft trailing tail and a rounded leading edge.
private func foot(_ a: Art) {
    let sole: [XY] = [(150, 648), (300, 598), (560, 582), (760, 586), (912, 606), (968, 648),
                      (928, 690), (720, 700), (420, 700), (210, 692)]
    a.fill(sole, hex(0x6a5f49), 0.5)                         // soft contact shadow
    a.fill(sole.map { ($0.0, $0.1 - 6) }, hex(0xdfd4bb))
    a.gradient(a.path(sole.map { ($0.0, $0.1 - 6) }),
               [(hex(0xeee4cc), 1, 0), (hex(0xcebf9f), 1, 1)], from: (500, 560), to: (500, 700))
    // Pale creeping-sole line and the groove along the front margin.
    a.line([(230, 686), (520, 690), (840, 678)], hex(0x9a8c6e), 0.5, 5)
    // Mottled skin speckles.
    for _ in 0..<90 {
        let x = a.rng.range(190, 940), y = a.rng.range(590, 694)
        a.softDot(x, y, a.rng.range(5, 11), hex(0x7d6f52), a.rng.range(0.1, 0.26))
    }
}

/// The aperture on the body whorl: the shell's mouth, a shaded opening framed by a pale outer lip
/// and a smooth columella, with the siphonal canal notch at its front.
private func aperture(_ a: Art) {
    let mouth: [XY] = [(672, 356), (752, 378), (786, 456), (772, 556), (712, 606), (648, 558), (632, 452)]
    // Pale thickened outer lip framing the opening, in the shell's own muted tone.
    a.fill(mouth.map { ($0.0 + 20, $0.1 + 4) }, hex(0xb5a179))
    // The opening itself, darkest deep inside toward the columella.
    a.fill(mouth, hex(0x3a2a1a))
    a.gradient(a.path(mouth), [(hex(0x5e4328), 1, 0), (hex(0x1f140a), 1, 1)], from: (620, 430), to: (770, 540))
    // Smooth columella / inner lip catching a little light.
    a.line([(676, 384), (648, 468), (690, 574)], hex(0xcabb98), 0.55, 11)
    a.softDot(672, 476, 40, hex(0xd8ccae), 0.35, sy: 1.5)
}

/// Head parts reaching from the aperture: the siphon tube held forward, two tapering tentacles
/// with eye spots at their base, and the front edge of the extended foot.
private func siphonAndHead(_ a: Art) {
    // Siphon: a muscular tube with a darker dorsal groove, angled up and forward.
    a.taper([(778, 548), (868, 470), (946, 404), (978, 372)], 50, 24, hex(0xcfc2a4))
    a.taper([(786, 540), (872, 468), (950, 404)], 22, 8, hex(0x8c7e60), 0.5)
    a.softDot(978, 372, 22, hex(0x2a2013), 0.45)            // open siphon tip
    // Two head tentacles sweeping forward and down, with eye spots at the base.
    a.taper([(830, 606), (912, 592), (980, 604)], 17, 5, hex(0xdacdb0))
    a.taper([(822, 624), (902, 628), (962, 650)], 15, 4, hex(0xdacdb0))
    a.disc(846, 606, 7, hex(0x241a10), 0.8)
    a.disc(840, 626, 6, hex(0x241a10), 0.8)
}
