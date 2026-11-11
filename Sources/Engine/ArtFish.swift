import CoreGraphics
import Foundation

// Shared parts for fish, which are drawn in profile, head to the right, on a 1000-unit wide cell.

func flank(_ v: Float, back: C3, side: C3, belly: C3, split: Float = 0.42) -> C3 {
    v < split ? mix(back, side, smooth(0.04, split, v)) : mix(side, belly, smooth(split, min(0.98, split + 0.36), v))
}

func gill(_ a: Art, _ x: Double, _ y0: Double, _ y1: Double, bow: Double = 34, _ alpha: Double = 0.2) {
    a.line([(x, y0), (x - bow, (y0 + y1) * 0.5), (x, y1)], hex(0x14100c), min(alpha, 0.22), 3)
}

enum FishArt {
    /// Body and fins shared by the wrasses: berggylt, blåstål and bergnebb.
    static func wrasseBody(_ a: Art, shader: @escaping (Float, Float, Float, Float) -> RGBA, finC: C3, finD: C3) {
        a.fin(base: [(100, 200), (80, 240), (100, 280)], edge: [(5, 150), (0, 240), (5, 330)], root: finC, tip: finD, rays: 14)
        a.fin(base: [(150, 170), (760, 94)], edge: [(135, 110), (260, 56), (520, 18), (780, 46)], root: finC, tip: finD, rays: 26)
        a.fin(base: [(150, 312), (420, 396)], edge: [(135, 362), (240, 442), (430, 462)], root: finC, tip: finD, rays: 14)
        let top: [XY] = [(92, 206), (170, 172), (340, 122), (520, 92), (690, 88), (830, 118), (920, 180), (975, 252)]
        let bottom: [XY] = [(92, 276), (170, 308), (340, 372), (520, 408), (690, 414), (830, 386), (920, 330), (975, 272)]
        a.body(top: top, bottom: bottom, shader)
        a.fin(base: [(690, 396), (735, 392)], edge: [(640, 450), (680, 462), (730, 430)], root: finC, tip: finD, alpha: 0.75, rays: 6)
    }
}
