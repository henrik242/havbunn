// Draws the app icon from the saver's own sprites and writes every size macOS asks for into
// an .appiconset. The PNGs are committed, so a normal build does not run this.
//
// Usage: havbunn-icon <out.appiconset>
import AppKit
import Foundation

@main
struct Main {
    static let side = 1024
    static let cs = CGColorSpace(name: CGColorSpace.sRGB)!

    static func bitmap(_ w: Int, _ h: Int) -> CGContext {
        CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                  space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    }

    /// One sprite on a transparent background, `width` pixels wide.
    static func sprite(_ name: String, width: Int) -> CGImage {
        guard let d = Species.spriteDefs(english: false).first(where: { $0.name == name }) else { fatalError("no sprite \(name)") }
        let w = width, h = Int((Double(width) * Double(d.h) / Double(d.w)).rounded())
        let ctx = bitmap(w, h)
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        ctx.interpolationQuality = .high
        let art = Art(ctx: ctx, ox: 0, oy: 0, pxW: w, pxH: h, seed: d.seed)
        ctx.scaleBy(x: art.k, y: art.k)
        d.paint(art)
        return ctx.makeImage()!
    }

    /// The macOS icon grid: an 824 pt rounded square centred on the 1024 canvas.
    static let plate = CGRect(x: 100, y: 100, width: 824, height: 824)

    static func drawIcon() -> CGImage {
        let ctx = bitmap(side, side)
        ctx.interpolationQuality = .high

        // Soft drop shadow under the plate, as on the standard grid.
        let shape = CGPath(roundedRect: plate, cornerWidth: 185, cornerHeight: 185, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: CGColor(gray: 0, alpha: 0.35))
        ctx.addPath(shape)
        ctx.setFillColor(CGColor(srgbRed: 0.03, green: 0.15, blue: 0.18, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()

        ctx.saveGState()
        ctx.addPath(shape)
        ctx.clip()

        // Fjord water: light near the surface, deep green-blue below. Core Graphics has y up.
        let water = CGGradient(colorsSpace: cs, colors: [
            CGColor(srgbRed: 0.02, green: 0.13, blue: 0.16, alpha: 1),
            CGColor(srgbRed: 0.07, green: 0.33, blue: 0.36, alpha: 1),
            CGColor(srgbRed: 0.24, green: 0.58, blue: 0.57, alpha: 1),
        ] as CFArray, locations: [0, 0.55, 1])!
        ctx.drawLinearGradient(water, start: CGPoint(x: 0, y: plate.minY), end: CGPoint(x: 0, y: plate.maxY), options: [])

        // Light shafts fanning down from the surface.
        for (x, spread, alpha) in [(300.0, 90.0, 0.10), (520.0, 140.0, 0.13), (700.0, 70.0, 0.08), (430.0, 50.0, 0.07)] {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: x - 20, y: plate.maxY))
            p.addLine(to: CGPoint(x: x + 20, y: plate.maxY))
            p.addLine(to: CGPoint(x: x + spread + 60, y: plate.minY + 120))
            p.addLine(to: CGPoint(x: x + 60 - spread, y: plate.minY + 120))
            p.closeSubpath()
            ctx.saveGState()
            ctx.addPath(p)
            ctx.clip()
            let shaft = CGGradient(colorsSpace: cs, colors: [
                CGColor(srgbRed: 0.8, green: 0.95, blue: 0.9, alpha: alpha),
                CGColor(srgbRed: 0.8, green: 0.95, blue: 0.9, alpha: 0),
            ] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(shaft, start: CGPoint(x: 0, y: plate.maxY), end: CGPoint(x: 0, y: plate.minY + 140), options: [])
            ctx.restoreGState()
        }

        // A school of herring far off, small and pale.
        let herring = sprite("sild", width: 70)
        var rng = RNG(7)
        for _ in 0..<14 {
            let w = CGFloat(rng.range(34, 54))
            let r = CGRect(x: rng.range(560, 860), y: rng.range(690, 820), width: w, height: w * CGFloat(herring.height) / CGFloat(herring.width))
            ctx.saveGState()
            ctx.setAlpha(0.55)
            ctx.draw(herring, in: r)
            ctx.restoreGState()
        }

        // Seabed: sand, then coral and kelp rising from it.
        let sand = CGMutablePath()
        sand.move(to: CGPoint(x: plate.minX, y: plate.minY + 210))
        sand.addCurve(to: CGPoint(x: plate.maxX, y: plate.minY + 170),
                      control1: CGPoint(x: 360, y: plate.minY + 140), control2: CGPoint(x: 680, y: plate.minY + 250))
        sand.addLine(to: CGPoint(x: plate.maxX, y: plate.minY))
        sand.addLine(to: CGPoint(x: plate.minX, y: plate.minY))
        sand.closeSubpath()
        ctx.saveGState()
        ctx.addPath(sand)
        ctx.clip()
        let sandGrad = CGGradient(colorsSpace: cs, colors: [
            CGColor(srgbRed: 0.10, green: 0.22, blue: 0.21, alpha: 1),
            CGColor(srgbRed: 0.33, green: 0.45, blue: 0.38, alpha: 1),
        ] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(sandGrad, start: CGPoint(x: 0, y: plate.minY), end: CGPoint(x: 0, y: plate.minY + 250), options: [])
        ctx.restoreGState()

        let kelp = sprite("stortare-2", width: 240)
        ctx.saveGState()
        ctx.setAlpha(0.85)
        ctx.draw(kelp, in: CGRect(x: 60, y: plate.minY + 150, width: 240, height: 240 * CGFloat(kelp.height) / CGFloat(kelp.width)))
        ctx.restoreGState()
        let coral = sprite("oyekorall-1", width: 300)
        ctx.draw(coral, in: CGRect(x: 120, y: plate.minY + 110, width: 300, height: 300 * CGFloat(coral.height) / CGFloat(coral.width)))
        let anemone = sprite("sjonellik", width: 110)
        for (x, y, w) in [(700.0, 150.0, 110.0), (775.0, 140.0, 90.0), (630.0, 162.0, 80.0)] {
            ctx.draw(anemone, in: CGRect(x: x, y: Double(plate.minY) + y, width: w, height: w * Double(anemone.height) / Double(anemone.width)))
        }

        // The cod, large enough to read at 16 px, rising slightly to the right.
        let cod = sprite("torsk", width: 760)
        ctx.saveGState()
        ctx.translateBy(x: 530, y: 540)
        ctx.rotate(by: 0.12)
        let cw: CGFloat = 700, ch = cw * CGFloat(cod.height) / CGFloat(cod.width)
        ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: CGColor(gray: 0, alpha: 0.35))
        ctx.draw(cod, in: CGRect(x: -cw / 2, y: -ch / 2, width: cw, height: ch))
        ctx.restoreGState()

        // Marine snow.
        for _ in 0..<60 {
            let r = CGFloat(rng.range(1.5, 4))
            ctx.setFillColor(CGColor(srgbRed: 0.85, green: 0.95, blue: 0.9, alpha: CGFloat(rng.range(0.15, 0.5))))
            ctx.fillEllipse(in: CGRect(x: rng.range(110, 910), y: rng.range(300, 910), width: Double(r), height: Double(r)))
        }

        // A thin highlight along the plate's top edge.
        ctx.restoreGState()
        ctx.addPath(shape)
        ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.12))
        ctx.setLineWidth(3)
        ctx.strokePath()
        return ctx.makeImage()!
    }

    static func main() throws {
        guard CommandLine.arguments.count == 2 else { fatalError("usage: havbunn-icon <out.appiconset>") }
        let dir = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let master = drawIcon()
        var images: [[String: String]] = []
        for pt in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let px = pt * scale
                let ctx = bitmap(px, px)
                ctx.interpolationQuality = .high
                ctx.draw(master, in: CGRect(x: 0, y: 0, width: px, height: px))
                let name = "icon_\(pt)x\(pt)\(scale == 2 ? "@2x" : "").png"
                try NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
                    .write(to: dir.appendingPathComponent(name))
                images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(pt)x\(pt)"])
            }
        }
        let json: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
        try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            .write(to: dir.appendingPathComponent("Contents.json"))
        print("wrote", dir.path)
    }
}
