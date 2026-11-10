// Renders one named sprite (or all) from the species atlas to a PNG, on a matte
// background so alpha edges are easy to judge. No Metal needed: sprites are drawn
// with Core Graphics only.
//
// Usage: havbunn-sprite <name|all> <out-dir> [--scale S] [--english]
//        name matches a SpriteDef name, e.g. "torsk", "hummer-0", "oyekorall-1".
import AppKit
import Foundation

@main
struct Main {
    static func main() throws {
        var args = Array(CommandLine.arguments.dropFirst())
        guard args.count >= 2 else { fatalError("usage: havbunn-sprite <name|all> <out-dir> [--scale S] [--english]") }
        let want = args.removeFirst()
        let outDir = args.removeFirst()
        var scale = 2.0, english = false
        while !args.isEmpty {
            let a = args.removeFirst()
            switch a {
            case "--scale": scale = Double(args.removeFirst())!
            case "--english": english = true
            default: fatalError("unknown \(a)")
            }
        }
        try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

        let defs = Species.spriteDefs(english: english)
        let picked = want == "all" ? defs : defs.filter { $0.name == want }
        if picked.isEmpty { fatalError("no sprite named \(want)") }

        for d in picked {
            let w = Int(Double(d.w) * scale), h = Int(Double(d.h) * scale)
            let cs = CGColorSpace(name: CGColorSpace.sRGB)!
            // Transparent layer the sprite paints into.
            let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.translateBy(x: 0, y: CGFloat(h))
            ctx.scaleBy(x: 1, y: -1)
            ctx.interpolationQuality = .high
            let art = Art(ctx: ctx, ox: 0, oy: 0, pxW: w, pxH: h, seed: 1)
            ctx.scaleBy(x: art.k, y: art.k)
            d.paint(art)

            // Composite over a mid fjord-water matte, like the atlas dump does.
            let out = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            out.setFillColor(CGColor(srgbRed: 0.10, green: 0.22, blue: 0.26, alpha: 1))
            out.fill(CGRect(x: 0, y: 0, width: w, height: h))
            out.draw(ctx.makeImage()!, in: CGRect(x: 0, y: 0, width: w, height: h))
            let path = "\(outDir)/\(d.name).png"
            try NSBitmapImageRep(cgImage: out.makeImage()!).representation(using: .png, properties: [:])!
                .write(to: URL(fileURLWithPath: path))
            print("wrote", path)
        }
    }
}
