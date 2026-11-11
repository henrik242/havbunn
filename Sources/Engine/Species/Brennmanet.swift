import CoreGraphics
import Foundation

extension Species {
    static let brennmanet = SpeciesInfo(
        key: "brennmanet", norsk: "Brennmanet", latin: "Cyanea capillata", english: "Lion's mane jellyfish",
        sprites: [SpriteDef(name: "brennmanet", w: 400, h: 400, paint: draw)],
        place: { scene in
            scene.addJellies(JellySpec(count: 1, z: 6...20, y: 2.5...7, width: 0.5...0.75, drift: 0.05, rate: 0.8...1.1))
        })
}

// Muted "fjord twilight" lion's mane palette: brownish reds and ochres, nothing primary.
private let bellCore = hex(0x622530)    // deep maroon-red centre
private let bellMid = hex(0xa6512c)     // warm rust
private let bellEdge = hex(0xd3a05c)    // pale ochre scalloped margin
private let bellRim = hex(0xe7c88a)     // soft lit rim
private let tentDark = hex(0x9a4328)
private let tentWarm = hex(0xc8723c)
private let tentPale = hex(0xdfa96a)
private let armRoot = hex(0x993a2f)     // folded oral arms, slightly pinker
private let armTip = hex(0xcf7a60)

private func draw(_ a: Art) {
    let cx = 500.0

    // 1. Deep veil of very fine, faint tentacles for the dense trailing mane and depth.
    for _ in 0..<80 {
        let x = a.rng.range(190, 810)
        let topY = a.rng.range(240, 300)
        let len = a.rng.range(560, 980)
        let drift = a.rng.range(-70, 70)
        let col = mix(tentDark, tentWarm, Float(a.rng.range(0, 1)))
        filament(a, x: x, topY: topY, len: len, drift: drift,
                 waveAmp: a.rng.range(18, 46), waveFreq: a.rng.range(2.5, 5.5),
                 phase: a.rng.range(0, 6.3), col: col, alpha: a.rng.range(0.10, 0.20), w: a.rng.range(1.0, 1.6))
    }

    // 2. Eight bunched clusters — the signature mane. Longest bunches hang from the centre.
    for c in 0..<8 {
        let ct = Double(c) / 7
        let clusterX = 210 + ct * 580 + a.rng.range(-18, 18)
        let lengthBias = 0.45 + 0.55 * sin(.pi * (clusterX - 150) / 700)   // centre bunches longest
        let baseLen = 560 + 420 * lengthBias
        let clusterDrift = a.rng.range(-55, 55)
        for j in 0..<16 {
            let primary = j % 6 == 0
            let xOff = a.rng.range(-36, 36)
            let topY = a.rng.range(250, 302)
            let len = baseLen * a.rng.range(0.62, 1.06)
            let drift = clusterDrift + a.rng.range(-26, 26)
            let col = primary ? tentPale : mix(tentDark, tentWarm, Float(a.rng.range(0, 1)))
            filament(a, x: clusterX + xOff, topY: topY, len: len, drift: drift,
                     waveAmp: a.rng.range(22, 58), waveFreq: a.rng.range(2.2, 5.0),
                     phase: a.rng.range(0, 6.3), col: col,
                     alpha: primary ? a.rng.range(0.34, 0.46) : a.rng.range(0.18, 0.34),
                     w: primary ? a.rng.range(2.1, 2.8) : a.rng.range(1.2, 2.0))
        }
    }

    // 3. Large frilly folded oral arms hanging centrally, shorter than the tentacles, translucent.
    for k in 0..<5 {
        let kt = Double(k) / 4 - 0.5
        let x0 = cx + kt * 150 + a.rng.range(-14, 14)
        let botY = a.rng.range(560, 700)
        let drift = kt * 120 + a.rng.range(-30, 30)
        oralArm(a, x0: x0, topY: 250, botY: botY,
                baseW: a.rng.range(118, 170), drift: drift,
                frillFreq: a.rng.range(7, 11), phase: a.rng.range(0, 6.3),
                alpha: a.rng.range(0.42, 0.56))
    }

    // 4. A few brighter foreground strands crossing in front for layered depth.
    for _ in 0..<16 {
        let x = a.rng.range(240, 760)
        let len = a.rng.range(640, 980)
        filament(a, x: x, topY: a.rng.range(258, 306), len: len, drift: a.rng.range(-80, 80),
                 waveAmp: a.rng.range(26, 60), waveFreq: a.rng.range(2.4, 5.0), phase: a.rng.range(0, 6.3),
                 col: mix(tentWarm, tentPale, Float(a.rng.range(0, 1))),
                 alpha: a.rng.range(0.26, 0.42), w: a.rng.range(1.8, 2.6))
    }

    // 5. The domed, flattened, lobed bell — deep red centre fading to a pale scalloped margin.
    a.polar(cx: cx, cy: 196, sy: 0.52, maxR: 376, radius: { th in
        let lobes = 13 * abs(sin(th * 4)) + 5 * abs(sin(th * 8))   // 8 lobes, each sub-scalloped
        return th > 0 ? 348 * (1 - 0.70 * sin(th)) + lobes : 348 + lobes
    }) { r, th, x, y in
        // Rich rust over most of the bell, paling only in the outer scalloped margin.
        var c = mix(bellMid, bellEdge, smooth(0.80, 1.0, r))
        // Deep red-brown concentrated over the domed apex (upper-central region).
        let apex = clamp01((1 - smooth(0.0, 0.72, r)) * smooth(310, 60, Float(y)))
        c = mix(c, bellCore, apex * 0.9)
        // Faint radial canals radiating from the centre — structure, not a sunburst.
        let canal = 0.5 + 0.5 * cos(th * 16)
        c = mix(c, bellCore, Float(canal) * smooth(0.15, 0.82, r) * 0.16)
        c *= 0.94 + 0.12 * artNoise.fbm(x * 0.016, y * 0.03, 2)
        // Dome volume: upper surface catches the diffuse light, the low rim falls into shadow.
        c *= mixf(1.12, 0.78, smooth(40, 300, Float(y)))
        // Translucent: fuller opacity over the thick core, thinning toward the margin.
        let alpha = mixf(0.90, 0.48, pow(r, 1.5))
        return rgba(c, alpha)
    }

    // 6. Soft lit rim near the top of the dome and a faint translucent sheen — delicate, not glaring.
    a.polar(cx: cx, cy: 196, sy: 0.52, maxR: 376, radius: { th in
        let lobes = 13 * abs(sin(th * 4)) + 5 * abs(sin(th * 8))
        return th > 0 ? 348 * (1 - 0.70 * sin(th)) + lobes : 348 + lobes
    }) { r, th, _, _ in
        let top = max(0, -sin(th))          // brighter on the upper surface
        let band = smooth(0.80, 1.0, r)     // only near the margin
        return rgba(bellRim, band * top * 0.30)
    }
    a.softDot(cx - 36, 150, 196, bellRim, 0.14, sy: 0.5)
}

/// One fine, trailing tentacle whose wave grows toward the drifting tip.
private func filament(_ a: Art, x: Double, topY: Double, len: Double, drift: Double,
                      waveAmp: Double, waveFreq: Double, phase: Double,
                      col: C3, alpha: Double, w: Double) {
    let seg = 8
    var pts: [XY] = []
    for i in 0...seg {
        let t = Double(i) / Double(seg)
        let yy = topY + len * t
        let s = drift * t * t + waveAmp * t * sin(t * waveFreq + phase)
        pts.append((x + s, yy))
    }
    a.line(pts, col, alpha, w)
}

/// A broad, folded, ruffled oral arm: a translucent ribbon with scalloped edges and a fold line.
private func oralArm(_ a: Art, x0: Double, topY: Double, botY: Double, baseW: Double,
                     drift: Double, frillFreq: Double, phase: Double, alpha: Double) {
    let seg = 12
    var center: [XY] = []
    for i in 0...seg {
        let t = Double(i) / Double(seg)
        let yy = topY + (botY - topY) * t
        let xx = x0 + drift * t * t + 20 * sin(t * 4.3 + phase)
        center.append((xx, yy))
    }
    let line = chaikin(center, iterations: 2)
    let n = line.count
    var left: [XY] = [], right: [XY] = []
    for i in 0..<n {
        let p = line[max(0, i - 1)], q = line[min(n - 1, i + 1)]
        var nx = -(q.1 - p.1), ny = q.0 - p.0
        let d = max(1e-6, (nx * nx + ny * ny).squareRoot()); nx /= d; ny /= d
        let t = Double(i) / Double(n - 1)
        let frill = 1 + 0.32 * sin(t * frillFreq + phase) + 0.18 * sin(t * frillFreq * 2.4)
        let w = baseW * (1 - 0.72 * t) * frill * 0.5
        left.append((line[i].0 + nx * w, line[i].1 + ny * w))
        right.append((line[i].0 - nx * w, line[i].1 - ny * w))
    }
    let outline = left + right.reversed()
    let path = a.path(outline, closed: true, smooth: true)
    a.gradient(path, [(armRoot, alpha, 0), (armTip, alpha * 0.45, 1)],
               from: center.first!, to: center.last!)
    // Central fold and a couple of ruffle creases.
    a.line(center, armRoot * 0.78, alpha * 0.5, 2.2)
    a.line(left, armTip, alpha * 0.3, 1.4)
    a.line(right, armRoot * 0.7, alpha * 0.3, 1.4)
}
