import CoreGraphics
import Foundation

extension Species {
    static let kamskjell = SpeciesInfo(
        key: "kamskjell", norsk: "Stort kamskjell", latin: "Pecten maximus", english: "King scallop",
        sprites: [SpriteDef(name: "kamskjell", w: 220, h: 158, paint: draw)],
        place: { scene in
            for _ in 0..<5 {
                guard let s = scene.findSpot(z: 3.4...10, rock: 0...0.2) else { continue }
                scene.addFixture(spot: s, height: scene.rng.float(0.06, 0.09), mode: 0, amp: 0, shadowW: 0.09)
            }
        })
}

// King scallop (Pecten maximus): a fan-shaped shell lying on the seabed, umbo (beak)
// and hinge low-centre, the fan opening upward with ~16 broad rounded radiating ribs,
// a pair of flat triangular ears at the hinge, and fine concentric growth lines.
private let umboX: Float = 500
private let umboY: Float = 530
private let kamSy: Double = 0.78
private let ribCount: Float = 16          // broad radiating ribs across the fan
private let fanR: Float = 460             // base shell radius

// Muted sandy pink-brown palette.
private let shellUmbo = hex(0xa86848)     // warmer, darker brown near the beak
private let shellMid = hex(0xc78a62)      // mid sandy pink-brown
private let shellMargin = hex(0xd9ab82)   // paler cream-pink toward the margin

// Radius of the fan outline for a given angle, with crenate (scalloped) rib crests
// and a notch at the bottom where the hinge sits.
private func kamRadius(_ th: Float) -> Float {
    let rib = abs(sin(th * ribCount))
    let wobble = artNoise.value(cos(th) * 2.4 + 11, sin(th) * 2.4 + 5) - 0.5
    // Fan profile: broad and rounded over the top, drawing in toward the hinge so the
    // shell is a fan rather than a flat half-disc.
    let up = -sin(th)
    let prof = 0.80 + 0.26 * smooth(-0.55, 0.95, up)
    let edge = fanR * prof + 12 * rib + 9 * wobble
    // down = +1 straight down (hinge), -1 straight up. Cut the lower half to a short
    // near-straight hinge line through the umbo.
    let down = sin(th)
    let gate = smooth(0.06, 0.34, down)
    return edge * (1 - gate) + 30 * gate
}

private func kamShade(_ r01: Float, _ th: Float, _ x: Float, _ y: Float) -> RGBA {
    // De-squashed distance from the umbo, for evenly spaced growth rings.
    let dx = x - umboX, dy = (y - umboY) / Float(kamSy)
    let rr = (dx * dx + dy * dy).squareRoot()

    // Base tone: warm brown at the umbo, paler pink toward the margin.
    var c = mix(shellUmbo, shellMargin, smooth(0.06, 0.92, r01))
    c = mix(c, shellMid, 0.25)

    // Broad rounded ribs. crest ~1 on a rib, ~0 in the groove between ribs. The relief
    // fades out near the umbo so the ribs don't collapse into a starburst at the centre.
    let relief = smooth(0.08, 0.42, r01)
    let s = sin(th * ribCount)
    let crest = pow(abs(s), 0.5)
    c *= 1 - (0.30 - 0.30 * crest) * relief
    // Directional sheen across each rib so the rounded relief catches the light.
    let slope = cos(th * ribCount)
    c *= 1 + (0.06 * clamp01(-slope) - 0.05 * clamp01(slope)) * relief

    // Concentric growth lines crossing the ribs, finer and tighter toward the margin.
    let gf = rr * 0.058 + rr * rr * 0.00007
    let grain = artNoise.value(x * 0.03, y * 0.03) - 0.5
    let ring = sin(gf + grain * 1.1)
    c *= 1 + 0.075 * ring * smooth(0.12, 0.5, r01)
    // A few stronger concentric growth checks (seasonal pauses in growth).
    let check = smooth(0.5, 1.0, sin(gf * 0.42 + 0.7))
    c *= 1 - 0.11 * check * smooth(0.2, 0.95, r01)

    // Soft diffuse top-lighting: brighter near the top of the fan, dim toward the hinge.
    let ly = clamp01((umboY + 150 - y) / 470)
    c *= 0.82 + 0.26 * ly

    // Umbo is a slightly shadowed knob; rim has faint ambient occlusion.
    c *= 0.86 + 0.14 * smooth(0.0, 0.22, r01)
    c *= 1 - 0.12 * smooth(0.86, 1.0, r01)

    // Settle into the muted fjord-twilight light: slight desaturation, gentle dimming.
    let luma = 0.30 * c.x + 0.59 * c.y + 0.11 * c.z
    c = mix(c, C3(repeating: luma), 0.12) * 0.94

    return rgba(c)
}

// A flat triangular ear (auricle) flanking the umbo at the hinge, poking out and down
// into the open space below the fan, with a couple of faint radiating ribs.
private func kamEar(_ a: Art, left: Bool) {
    let sx: Double = left ? -1 : 1
    let ux = Double(umboX), uy = Double(umboY)
    let root = (ux + sx * 18, uy - 34)      // attaches beside the umbo
    let tip = (ux + sx * 150, uy + 30)      // out and slightly down
    let low = (ux + sx * 44, uy + 64)       // lower hinge corner
    let ear: [XY] = [root, tip, low]
    a.fill(ear, hex(0x5c3a2b))
    a.gradient(a.path(ear),
               [(hex(0xa9775a), 0.96, 0), (hex(0x6b4231), 0.96, 1)],
               from: (ux, uy - 30), to: (tip.0, uy + 50))
    for i in 1...2 {
        let t = Double(i) / 3
        a.line([(ux + sx * 20, uy - 24 + 80 * t),
                (tip.0 * t + root.0 * (1 - t), uy + 28 * t)],
               hex(0x4a2e22), 0.35, 2)
    }
}

private func draw(_ a: Art) {
    // Contact shadow on the seabed under the shell.
    a.softDot(Double(umboX), 648, 230, hex(0x0a1418), 0.28, sy: 0.32)

    // Ears first, so the fan body overlaps their inner edge at the hinge.
    kamEar(a, left: true)
    kamEar(a, left: false)

    // Main fan body.
    a.polar(cx: Double(umboX), cy: Double(umboY), sy: kamSy, maxR: 500,
            radius: kamRadius, kamShade)

    // The umbo knob and a short hinge line for definition.
    a.softDot(Double(umboX), Double(umboY) + 4, 46, hex(0x6a4330), 0.5, sy: 0.7)
    a.line([(Double(umboX) - 150, Double(umboY) - 2), (Double(umboX) + 150, Double(umboY) - 2)],
           hex(0x3c241a), 0.35, 3)
}
