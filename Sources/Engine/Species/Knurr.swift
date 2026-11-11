import CoreGraphics
import Foundation

extension Species {
    static let knurr = SpeciesInfo(
        key: "knurr", norsk: "Knurr", latin: "Eutrigla gurnardus", english: "Grey gurnard",
        sprites: [SpriteDef(name: "knurr", w: 420, h: 170, paint: draw)],
        place: { scene in
            // Walks the sand on its free pectoral rays.
            scene.addRester(ResterSpec(length: 0.3, mode: 1, amp: 0.03, glide: 0.08, rest: (4, 14), z: 3.8...8, rock: 0...0.1, lift: 0,
                                       crawls: true))
        })
}

/// Grey gurnard (Eutrigla gurnardus): a bottom-walker with a big bony armoured head and steep
/// blunt snout, muted grey-brown flanks scattered with small white spots and a white-dotted
/// lateral line, a spiny first dorsal carrying a dark blotch, a long low soft second dorsal,
/// wide wing-like pectorals, and three free finger-like rays it walks on.
private func draw(_ a: Art) {
    let finC = hex(0x565146), finD = hex(0x857f72)
    let membrane = hex(0x514d43), spineCol = hex(0xcac2b0)

    let top: [XY] = [(80, 178), (190, 150), (370, 120), (560, 104), (700, 100), (820, 112), (912, 150), (972, 194)]
    let bottom: [XY] = [(80, 198), (190, 218), (370, 246), (560, 264), (700, 274), (820, 276), (912, 256), (972, 212)]
    let topCurve = Curve(top), botCurve = Curve(bottom)
    func topY(_ x: Double) -> Double { topCurve.value(x) }
    func botY(_ x: Double) -> Double { botCurve.value(x) }

    // ---- Far-side & behind-body structure (drawn first; body paints over the roots) ----

    // Slightly forked caudal fin.
    a.fin(base: [(86, 182), (62, 194), (86, 210)], edge: [(2, 140), (28, 194), (2, 250)], root: finC, tip: finD, alpha: 0.82, rays: 11)

    // Long low soft second dorsal running along the back toward the tail.
    buildDorsalSoft(a, topY: topY, x0: 170, x1: 600, membrane: membrane, spineCol: spineCol)

    // Spiny first dorsal right behind the head, with the dark blotch.
    buildDorsalSpiny(a, topY: topY, x0: 628, x1: 782, membrane: membrane, spineCol: spineCol)

    // Long low anal fin mirroring the second dorsal along the belly.
    buildAnal(a, botY: botY, x0: 250, x1: 640, membrane: membrane, spineCol: spineCol)

    // ---- Body ----
    let back = hex(0x6a6052), side = hex(0x8c8678), belly = hex(0xdcd7c7)
    let warm = hex(0x7a6350)
    a.body(top: top, bottom: bottom) { t, v, x, y in
        var c = flank(v, back: back, side: side, belly: belly, split: 0.54)
        // Restrained warm reddish-grey cast over the upper flank.
        c = mix(c, warm, (1 - smooth(0.30, 0.66, v)) * 0.22)
        // Soft dusky mottling, low contrast and brownish.
        let m = smooth(0.56, 0.82, artNoise.fbm(x * 0.021, y * 0.03 + 3, 3)) * (1 - smooth(0.52, 0.86, v))
        c = mix(c, hex(0x55493b), m * 0.3)
        // Scattered small white/cream spots, denser up the flank.
        let sp = spots(x, y, cell: 20, radius: 2.6, keep: 0.62) * (1 - smooth(0.46, 0.72, v))
        c = mix(c, hex(0xe8e4d8), sp * 0.9)
        // White-dotted lateral line along the upper flank.
        let llY: Float = 182 - (x - 80) * 0.028
        let ll = clamp01(1 - abs(y - llY) * 0.16)
        c = mix(c, hex(0x403a30), ll * 0.22)
        let llDots = spots(x, y, cell: 15, radius: 2.0, keep: 0.72, seed: 11) * clamp01(1 - abs(y - llY) * 0.2)
        c = mix(c, hex(0xf0ece0), llDots * 0.85)
        // Bony armoured plating over the big head.
        if t > 0.72 {
            let h = clamp01((t - 0.72) / 0.28)
            c = mix(c, c * (0.9 + 0.16 * artNoise.fbm(x * 0.06, y * 0.06, 2)), h)
            c = mix(c, hex(0x60564a), h * 0.18)
        }
        c *= 1 - scales(x, y, size: 22) * 0.05
        return rgba(c * roundLight(v))
    }

    // ---- Near-side fins and head details (over the body) ----

    // Wide wing-like pectoral, draped down and back, with a faintly cool inner wash.
    a.fin(base: [(766, 208), (786, 272)], edge: [(600, 250), (505, 336), (660, 372)],
          root: hex(0x615c51), tip: hex(0x8ba0ac), alpha: 0.78, rays: 14)
    a.softDot(650, 300, 70, hex(0x3f4a4e), 0.14, sy: 1.1)

    // Three free finger-like rays it walks on, splayed from the pectoral base to the sand.
    walkingRays(a)

    // Armoured head: gill-plate edge, bony cheek ridges, snout spines.
    headArmour(a, topY: topY, botY: botY)

    a.eye(890, 164, 23, iris: hex(0xb9a569))
}

/// Long low soft dorsal: rounded membrane with fine soft rays, anchored on the back ridge.
private func buildDorsalSoft(_ a: Art, topY: (Double) -> Double, x0: Double, x1: Double,
                             membrane: C3, spineCol: C3) {
    let n = 16
    func lift(_ t: Double) -> Double { 20 * sin(t * Double.pi).magnitude.squareRoot() + 4 }
    var base: [XY] = [], edge: [XY] = []
    for i in 0...n {
        let t = Double(i) / Double(n)
        let x = x0 + (x1 - x0) * t
        base.append((x, topY(x)))
        edge.append((x, topY(x) - lift(t)))
    }
    a.fill(base + edge.reversed(), membrane, 0.9, raw: true)
    for i in 0...n {
        let t = Double(i) / Double(n)
        let x = x0 + (x1 - x0) * t
        a.line([(x, topY(x) + 2), (x, topY(x) - lift(t) + 3)], spineCol * 0.8, 0.22, 1.1, smooth: false)
    }
}

/// Spiny first dorsal: tall triangular membrane with stiff spines and a dark blotch between
/// the rear rays, typical of the grey gurnard.
private func buildDorsalSpiny(_ a: Art, topY: (Double) -> Double, x0: Double, x1: Double,
                              membrane: C3, spineCol: C3) {
    let n = 7
    // A triangular sail, tallest near the front (head side), trailing edge sloping back.
    func spineLen(_ t: Double) -> Double { 20 + 36 * (t * t * (3 - 2 * t)) }
    var base: [XY] = [], edge: [XY] = []
    for i in 0...n {
        let t = Double(i) / Double(n)
        let x = x0 + (x1 - x0) * t
        base.append((x, topY(x)))
        if i > 0 {
            let xn = x - (x1 - x0) / Double(n) * 0.5
            edge.append((xn, topY(xn) - (spineLen(t) + spineLen(t - 1.0 / Double(n))) * 0.5 + 6))
        }
        edge.append((x, topY(x) - spineLen(t)))
    }
    a.fill(base + edge.reversed(), membrane, 0.95, raw: true)
    // Dark blotch across the upper-rear membrane, the diagnostic first-dorsal mark.
    let xb = x0 + (x1 - x0) * 0.62
    a.softDot(xb, topY(xb) - spineLen(0.62) * 0.62, 26, hex(0x15120a), 0.85, sy: 1.25)
    a.softDot(xb + 18, topY(xb + 18) - spineLen(0.7) * 0.6, 18, hex(0x15120a), 0.7, sy: 1.25)
    // Stiff spines.
    for i in 0...n {
        let t = Double(i) / Double(n)
        let x = x0 + (x1 - x0) * t
        a.line([(x, topY(x) + 2), (x, topY(x) - spineLen(t))], spineCol, 0.6, 2.1, smooth: false)
    }
}

/// Long low anal fin along the belly, mirroring the second dorsal.
private func buildAnal(_ a: Art, botY: (Double) -> Double, x0: Double, x1: Double,
                       membrane: C3, spineCol: C3) {
    let n = 14
    func drop(_ t: Double) -> Double { 18 * sin(t * Double.pi).magnitude.squareRoot() + 4 }
    var base: [XY] = [], edge: [XY] = []
    for i in 0...n {
        let t = Double(i) / Double(n)
        let x = x0 + (x1 - x0) * t
        base.append((x, botY(x)))
        edge.append((x, botY(x) + drop(t)))
    }
    a.fill(base + edge.reversed(), membrane, 0.88, raw: true)
    for i in 0...n {
        let t = Double(i) / Double(n)
        let x = x0 + (x1 - x0) * t
        a.line([(x, botY(x) - 2), (x, botY(x) + drop(t) - 1)], spineCol * 0.85, 0.28, 1.2, smooth: false)
    }
}

/// Three free pectoral rays the gurnard walks on: thick segmented feelers splayed to the sand.
private func walkingRays(_ a: Art) {
    let paths: [[XY]] = [
        [(772, 270), (784, 336), (766, 398)],
        [(794, 268), (818, 338), (812, 404)],
        [(814, 262), (852, 330), (858, 392)],
    ]
    for p in paths {
        a.taper(p, 10, 4, hex(0x3b362d), 0.5)          // soft shadow
        a.taper(p, 7, 2.5, hex(0xc9c2b0), 0.95)        // ray
        // Segment ticks for a jointed, finger-like look.
        for s in stride(from: 0.3, through: 0.85, by: 0.22) {
            let i = Int(s * Double(p.count - 1))
            let q = p[min(i, p.count - 1)]
            a.disc(q.0, q.1, 2.2, hex(0x8f897a), 0.8)
        }
    }
}

/// Bony armoured head: gill-plate edge, radiating cheek ridges, snout spines, nostril, mouth.
private func headArmour(_ a: Art, topY: (Double) -> Double, botY: (Double) -> Double) {
    let bone = hex(0x474036), boneLit = hex(0xc9c0ac)
    // Preopercular (gill-cover) edge sweeping down behind the eye.
    a.line([(838, 138), (826, 196), (806, 258)], bone, 0.5, 3.5)
    a.line([(842, 140), (830, 198), (810, 258)], boneLit, 0.28, 1.4)
    // Bony cheek ridges radiating forward-down from under the eye toward the snout.
    for i in 0..<4 {
        let dy = Double(i) * 15
        a.line([(866, 190 + dy), (922 + dy * 0.4, 206 + dy * 0.9)], bone, 0.42, 2.6)
    }
    // Low bony ridge along the top of the snout.
    a.line([(912, 150), (948, 170), (968, 194)], bone, 0.4, 2.4)
    // Small snout spines at the blunt tip, pointing forward.
    for i in 0..<3 {
        let yy = 182.0 + Double(i) * 10
        a.fill([(970, yy), (986, yy + 3), (970, yy + 8)], hex(0x9c9484), 0.85, raw: true)
    }
    // Nostril.
    a.disc(934, 180, 3.2, hex(0x201c15), 0.7)
    // Wide, slightly inferior mouth at the blunt snout.
    a.line([(972, 206), (930, 222), (900, 226)], hex(0x241f18), 0.6, 4)
    a.line([(972, 208), (932, 224)], hex(0xcac2b0), 0.35, 1.4)
}
