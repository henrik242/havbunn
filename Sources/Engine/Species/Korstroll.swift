import CoreGraphics
import Foundation

extension Species {
    static let korstroll = SpeciesInfo(
        key: "korstroll", norsk: "Vanlig korstroll", latin: "Asterias rubens", english: "Common starfish",
        sprites: [SpriteDef(name: "korstroll", w: 300, h: 186, paint: draw)],
        place: { scene in
            // Crawls far too slowly to need walk frames.
            for _ in 0..<7 {
                guard let s = scene.findSpot(z: 3.4...10, rock: 0...0.6) else { continue }
                scene.addFlat(spot: s, halfW: scene.rng.float(0.13, 0.19), halfH: 0.08, flip: true, tint: 0.9...1.08, shadowW: 0.12)
            }
        })
}

private func draw(_ a: Art) {
    // Viewed from above. Five tapering arms radiate from a small central disc.
    let cx: Float = 500, cy: Float = 310, sy: Float = 0.62
    let phase: Float = 0.75                       // rotates the star so one arm points up

    // Muted "fjord twilight" orange-brown palette, paler along the raised midline ridge.
    let disc = hex(0xbd7338)                       // warm centre
    let mid = hex(0xb0632e)                        // arm interior
    let edge = hex(0x8c441f)                        // darker reddish-brown rim
    let ridgeC = hex(0xcea36d)                      // pale raised midline
    let spineC = hex(0xe4d2ab)                      // whitish spine knob
    let knobC = hex(0xd8b680)                      // pale granule
    let bumpC = hex(0x7e3c1b)                      // shaded granule pit

    a.polar(cx: Double(cx), cy: Double(cy), sy: Double(sy), maxR: 490, radius: { th in
        let arm = pow(abs(cos(2.5 * th + phase)), 2.15)
        return 88 + 388 * arm
    }) { rN, th, x, y in
        // Angular offset from the nearest arm axis: 0 on the midline, grows toward the gaps.
        let ph = 2.5 * th + phase
        let d = ph - (ph / Float.pi).rounded() * Float.pi     // [-pi/2, pi/2]
        let u = clamp01(abs(d) / 0.62)                        // 0 midline .. 1 arm flank

        // Base colour: warm disc fading to a darker rim out along the arms.
        var c = mix(disc, mid, smooth(0.10, 0.52, rN))
        c = mix(c, edge, smooth(0.52, 1.0, rN))

        // Rounded (tube-like) cross-section: arm sides sit in shade.
        let cross = 1 - 0.26 * smooth(0.15, 1.0, u)

        // Pale raised midline ridge running from disc to near the tip.
        let ridge = (1 - smooth(0.0, 0.34, u)) * smooth(0.14, 0.34, rN) * (1 - smooth(0.80, 1.0, rN))
        c = mix(c, ridgeC, ridge * 0.6)

        // Granular / knobbly surface: pale knobs plus a few darker pits.
        let knob = spots(x, y, cell: 13, radius: 3.6, keep: 0.80)
        c = mix(c, knobC, knob * 0.5 * (1 - 0.4 * rN))
        let pit = spots(x, y, cell: 17, radius: 3.0, keep: 0.86, seed: 9)
        c = mix(c, bumpC, pit * 0.22)

        // Whitish spines along the midline, with a scatter of fainter, offset flank spines.
        let jit = artNoise.hash(Int32(th * 9), 3) * 0.35      // uneven spine spacing per arm
        let b = rN * 15 + jit
        let sgap = abs(b - b.rounded()) * 2                    // 0 at a spine centre
        let bead = (1 - smooth(0.0, 0.7, sgap)) * smooth(0.16, 0.28, rN) * (1 - smooth(0.9, 1.0, rN))
        let midSpine = bead * (1 - smooth(0.0, 0.30, u))
        let b2 = rN * 11 + 0.5 + artNoise.hash(Int32(th * 13), 7)
        let lat = (1 - smooth(0.0, 0.6, abs(b2 - b2.rounded()) * 2))
        let latSpine = lat * (1 - smooth(0.30, 0.62, abs(u - 0.46))) * smooth(0.2, 0.4, rN) * (1 - smooth(0.82, 1.0, rN)) * 0.28
        c = mix(c, spineC, clamp01(midSpine + latSpine) * 0.6)

        // Diffuse doming: brighter near the centre, darker at tips and rim.
        let shade = (1.12 - 0.40 * rN) * cross
        return rgba(c * shade)
    }

    // Raised central disc: a soft dome of light sitting over the arm joins.
    a.softDot(Double(cx), Double(cy) - 10, 150, hex(0xd39a5c), 0.22, sy: Double(sy))

    // Madreporite: a small pale off-centre plate on the disc, between two arms.
    let ma: Float = 0.33
    let mx = Double(cx) + Double(cos(ma)) * 58, my = Double(cy) + Double(sin(ma)) * 58 * Double(sy)
    a.softDot(mx, my, 20, hex(0xe0cda2), 0.55, sy: Double(sy))
    a.disc(mx, my, 9, hex(0xd7c097), 0.8, sy: Double(sy))
    a.disc(mx - 2, my - 2 * Double(sy), 4, hex(0xf0e3c4), 0.6, sy: Double(sy))
}
