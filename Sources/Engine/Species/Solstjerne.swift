import CoreGraphics
import Foundation

extension Species {
    static let solstjerne = SpeciesInfo(
        key: "solstjerne", norsk: "Piggsolstjerne", latin: "Crossaster papposus", english: "Common sunstar",
        sprites: [SpriteDef(name: "solstjerne", w: 320, h: 198, paint: draw)],
        place: { scene in
            // Crawls far too slowly to need walk frames.
            for _ in 0..<3 {
                guard let s = scene.findSpot(z: 3.5...10, rock: 0...0.8) else { continue }
                scene.addFlat(spot: s, halfW: scene.rng.float(0.15, 0.21), halfH: 0.09, flip: false, tint: 0.92...1.05, shadowW: 0.14)
            }
        })
}

private let sunArms: Float = 12

/// Scalloped margin: many short, broad arms around a large central disc.
private func sunRadius(_ th: Float) -> Float {
    let u = (cos(sunArms * th) + 1) * 0.5           // 1 at arm tip, 0 at notch
    let arm = pow(u, 1.2)                             // broad arms, rounded notches
    // Gentle per-arm irregularity so the outline isn't a perfect cog.
    let wob = (artNoise.value(cos(th) * 2.3 + 11, sin(th) * 2.3 + 4) - 0.5) * 24
    return 312 + 132 * arm + wob
}

/// Concentric colour rings (bullseye), muted for fjord twilight — never pure white.
private func sunBands(_ r: Float) -> C3 {
    let stops: [(Float, C3)] = [
        (0.00, hex(0xcab08f)),   // pale centre around the madreporite
        (0.10, hex(0x8a3b2f)),   // dark red ring hugging the centre
        (0.25, hex(0xc4a985)),   // cream band
        (0.38, hex(0xb0492f)),   // red band
        (0.53, hex(0xc3a582)),   // cream band
        (0.67, hex(0xb9542f)),   // warm orange-red band
        (0.81, hex(0xc6aa88)),   // cream band
        (1.00, hex(0x973d29)),   // deep red margin
    ]
    var c = stops[0].1
    for i in 1..<stops.count {
        c = mix(c, stops[i].1, smooth(stops[i - 1].0, stops[i].0, r))
    }
    return c
}

private func draw(_ a: Art) {
    let cx = 500.0, cy = 310.0
    a.polar(cx: cx, cy: cy, sy: 0.62, maxR: 480, radius: { th in
        sunRadius(th)
    }) { r, th, x, y in
        // Bands bow outward over each arm, so the rings read as chevrons along the arms.
        // The bow fades out near the centre, leaving the disc as clean concentric rings
        // (no pinwheel / starburst at the core).
        let u = (cos(sunArms * th) + 1) * 0.5
        let rr = clamp01(r - 0.055 * Float(u) * smooth(0.18, 0.55, r))
        var c = sunBands(rr)

        // Felted paxillae: dense tufts of fine spines, each a lit crown over a shadowed pit.
        let felt = spots(x, y, cell: 9, radius: 3.1, keep: 1, seed: 1)
        let felt2 = spots(x, y, cell: 13, radius: 4.3, keep: 0.85, seed: 7)
        let pit = (1 - felt) * (1 - felt2)
        c = mix(c, c * 0.8, pit * 0.5)                       // shadowed pits between tufts
        let crown = max(felt, felt2 * 0.8)
        c = mix(c, mix(c, hex(0xd7c29f), 0.55), crown * 0.5) // pale warm lit crowns
        // Micro grain over the whole felt.
        let g = artNoise.fbm(x * 0.12, y * 0.2, 3)
        c = mix(c, c * (0.9 + 0.2 * g), 0.5)

        // Gentle dome and a soft overhead light from the upper-left — no harsh starburst.
        let dome = 1.06 - 0.24 * r * r
        let ly = (y - Float(cy)) / 300, lx = (x - Float(cx)) / 300
        let lit = 1 + 0.07 * (-ly - lx * 0.5)
        return rgba(c * dome * lit)
    }
}
