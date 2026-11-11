import CoreGraphics
import Foundation

extension Species {
    static let sjotre = SpeciesInfo(
        key: "sjotre", norsk: "Sjøtre", latin: "Paragorgia arborea", english: "Bubblegum coral",
        sprites: [
            SpriteDef(name: "sjotre-1", w: 500, h: 560) { draw($0, base: hex(0x98202c), tip: hex(0xdf5661), seed: 5) },
            SpriteDef(name: "sjotre-2", w: 440, h: 500) { draw($0, base: hex(0xcc7c86), tip: hex(0xf4c8c7), seed: 8) },
        ],
        place: { scene in
            for _ in 0..<5 {
                guard let s = scene.findSpot(z: 8...20, rock: 0.55...1.01) else { continue }
                scene.addFixture(scene.rng.chance(0.6) ? "sjotre-1" : "sjotre-2", spot: s, height: scene.rng.float(0.8, 1.35), mode: 2, amp: 0.018, shadowW: 0.5)
            }
        })
}

/// One grown length of coral: a smoothed centreline that tapers from w0 to w1.
/// Terminal segments carry a swollen, knobbly "bubblegum" lobe at their tip.
private struct CoralSeg {
    var pts: [XY]
    var w0: Double
    var w1: Double
    var depth: Int
    var tip: Bool
    var tipR: Double
}

/// Bubblegum coral, Paragorgia arborea: a stout soft-coral tree whose thick
/// trunk forks into tapering boughs ending in rounded, knobbly lobes, the whole
/// surface lightly furred with tiny pale polyps. Dusky pink/red for fjord twilight.
private func draw(_ a: Art, base: C3, tip: C3, seed: UInt64) {
    var rng = RNG(seed)
    let maxDepth = 5

    // --- grow the tree in natural coordinates (root at origin, up is -y) ---
    var segs: [CoralSeg] = []
    func grow(_ x: Double, _ y: Double, _ ang: Double, _ w: Double, _ depth: Int) {
        var pts: [XY] = [(x, y)]
        var px = x, py = y, th = ang
        let nSeg = depth == 0 ? 3 : rng.int(2, 3)
        for _ in 0..<nSeg {
            // Gentle sway, pulled a little back towards vertical so boughs sweep up.
            th += rng.range(-0.20, 0.20) + (-.pi / 2 - th) * 0.05
            let len = rng.range(40, 62) * (0.7 + w / 120)
            px += cos(th) * len; py += sin(th) * len
            pts.append((px, py))
        }
        let terminal = depth >= maxDepth || w < 34
        segs.append(CoralSeg(pts: pts, w0: w, w1: w * (terminal ? 0.92 : 0.9),
                             depth: depth, tip: terminal,
                             tipR: terminal ? w * rng.range(1.5, 2.1) : 0))
        if terminal { return }
        let kids = rng.int(2, 3)
        let spread = 0.46 + Double(depth) * 0.12
        for i in 0..<kids {
            let f = kids == 1 ? 0 : Double(i) / Double(kids - 1) - 0.5
            grow(px, py, th + f * spread * 2 + rng.range(-0.12, 0.12),
                 w * rng.range(0.68, 0.80), depth + 1)
        }
    }
    grow(0, 0, -.pi / 2, 120, 0)

    // --- fit the colony to its cell, rooted at the bottom centre ---
    var minX = Double.infinity, maxX = -Double.infinity
    var minY = Double.infinity, maxY = -Double.infinity
    for s in segs {
        let pad = s.tip ? s.tipR : s.w0
        for q in s.pts {
            minX = min(minX, q.0 - pad); maxX = max(maxX, q.0 + pad)
            minY = min(minY, q.1 - pad); maxY = max(maxY, q.1 + pad * 0.3)
        }
    }
    let s = min(964 / (maxX - minX), (a.unitH - 18) / (maxY - minY))
    let cx = (minX + maxX) / 2
    func T(_ p: XY) -> XY { (500 + (p.0 - cx) * s, a.unitH - 6 - (maxY - p.1) * s) }
    for i in segs.indices {
        segs[i].pts = segs[i].pts.map(T)
        segs[i].w0 *= s; segs[i].w1 *= s; segs[i].tipR *= s
    }

    // --- palette: dusky flesh, pale diffuse sheen, soft polyps ---
    let rim = base * 0.40                        // dark contact shadow / outline
    let lit = mix(tip, hex(0xf3e6df), 0.42)       // warm pale sheen, kept muted
    let polyp = mix(tip, hex(0xf7ede7), 0.6)      // tiny surface polyps

    func bodyColor(_ depth: Int) -> C3 {
        mix(base, tip, clamp01(Float(depth) / Float(maxDepth)) * 0.8)
    }

    // Tiny pale polyps furring a shape, clipped to its silhouette.
    func furr(_ clip: CGPath, _ pts: [XY], spread: Double, count: Int) {
        a.ctx.saveGState()
        a.ctx.addPath(clip); a.ctx.clip()
        let line = pts.count > 2 ? chaikin(pts, iterations: 2) : pts
        for _ in 0..<count {
            let q = line[rng.int(0, line.count - 1)]
            let dx = rng.range(-spread, spread), dy = rng.range(-spread, spread)
            let r = max(0.7, spread * rng.range(0.05, 0.12))
            a.disc(q.0 + dx, q.1 + dy + r * 0.7, r * 1.1, rim, 0.11)    // micro shadow
            a.disc(q.0 + dx, q.1 + dy, r * 0.8, polyp, 0.4)             // polyp head
        }
        a.ctx.restoreGState()
    }

    // A fleshy, softly lit branch: dark halo, body, then an upper-left sheen ridge.
    func branch(_ sg: CoralSeg) {
        let body = bodyColor(sg.depth)
        a.taper(sg.pts, sg.w0 * 1.1, sg.w1 * 1.1, rim)
        a.taper(sg.pts, sg.w0, sg.w1, body)
        let hi = sg.pts.map { ($0.0 - sg.w0 * 0.26, $0.1 - sg.w0 * 0.28) }
        a.taper(hi, sg.w0 * 0.42, sg.w1 * 0.34, mix(body, lit, 0.55), 0.38)
        // Round every joint so forks read as fleshy, not jointed sticks.
        let j = sg.pts.last!
        a.disc(j.0, j.1, sg.w1 * 0.62, body)
        a.softDot(j.0 - sg.w1 * 0.26, j.1 - sg.w1 * 0.3, sg.w1 * 0.5, lit, 0.35)
        furr(a.path(a.taperPolygon(sg.pts, sg.w0 * 1.04, sg.w1 * 1.04)),
             sg.pts, spread: sg.w0 * 0.72, count: Int(sg.w0 * 0.85))
    }

    // A swollen, knobbly bubblegum lobe: a clump of rounded bumps.
    func lobe(_ c: XY, _ r: Double, _ depth: Int) {
        let body = mix(bodyColor(depth), tip, 0.35)
        var bumps: [(XY, Double)] = [(c, r)]
        for _ in 0..<rng.int(3, 5) {
            let an = rng.range(0, 2 * .pi), d = r * rng.range(0.35, 0.85)
            bumps.append(((c.0 + cos(an) * d, c.1 + sin(an) * d), r * rng.range(0.46, 0.82)))
        }
        for (p, br) in bumps { a.disc(p.0 + br * 0.08, p.1 + br * 0.12, br * 1.14, rim) }
        for (p, br) in bumps { a.disc(p.0, p.1, br, body) }
        for (p, br) in bumps {
            a.softDot(p.0 - br * 0.3, p.1 - br * 0.34, br * 0.66, lit, 0.5)
            a.softDot(p.0 + br * 0.28, p.1 + br * 0.38, br * 0.6, rim, 0.28)   // crease AO
        }
        let clip = CGMutablePath()
        for (p, br) in bumps {
            clip.addEllipse(in: CGRect(x: p.0 - br, y: p.1 - br, width: br * 2, height: br * 2))
        }
        furr(clip, bumps.map { $0.0 }, spread: r, count: Int(r * 1.9))
    }

    // --- paint: a stout base buttress, boughs trunk-first, then the lobes on top ---
    let root = segs[0].pts[0], rw = segs[0].w0
    a.disc(root.0, root.1 + rw * 0.2, rw * 1.3, rim, 1, sy: 0.7)
    a.disc(root.0, root.1, rw * 1.08, bodyColor(0), 1, sy: 0.82)

    for sg in segs.sorted(by: { $0.depth < $1.depth }) { branch(sg) }
    for sg in segs where sg.tip { lobe(sg.pts.last!, sg.tipR, sg.depth) }
}
