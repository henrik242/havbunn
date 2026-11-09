// Offscreen frame renderer for checking the look without the screen saver host.
// Usage: havbunn-render <Shaders.metal> <out-prefix> [--seed N] [--size WxH] [--warm SECONDS] [--frames N] [--gap SECONDS] [--rare]
import AppKit
import Foundation
import Metal

@main
struct Main {
    static func main() throws {
        var args = Array(CommandLine.arguments.dropFirst())
        guard args.count >= 2 else { fatalError("usage") }
        let lib = URL(fileURLWithPath: args.removeFirst())
        let prefix = args.removeFirst()
        var seed: UInt64 = 7, w = 2560, h = 1600, warm = 30.0, frames = 1, gap = 5.0, forceRare = false, dumpAtlas = false
        while !args.isEmpty {
            let a = args.removeFirst()
            switch a {
            case "--seed": seed = UInt64(args.removeFirst())!
            case "--size":
                let p = args.removeFirst().split(separator: "x")
                w = Int(p[0])!; h = Int(p[1])!
            case "--warm": warm = Double(args.removeFirst())!
            case "--frames": frames = Int(args.removeFirst())!
            case "--gap": gap = Double(args.removeFirst())!
            case "--rare": forceRare = true
            case "--atlas": dumpAtlas = true
            default: fatalError("unknown \(a)")
            }
        }
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("no metal") }
        let t0 = CFAbsoluteTimeGetCurrent()
        let r = try Renderer(device: device, shaderSource: lib, seed: seed)
        r.prepare(width: w, height: h)
        print(String(format: "prepare: %.2fs, atlas used height %d of %d", CFAbsoluteTimeGetCurrent() - t0, Atlas.usedHeight, Atlas.side))
        r.fadeOverride = 1
        if dumpAtlas {
            let tex = Atlas.shared(device: device).texture
            var px = [UInt8](repeating: 0, count: Atlas.side * Atlas.side * 4)
            tex.getBytes(&px, bytesPerRow: Atlas.side * 4, from: MTLRegionMake2D(0, 0, Atlas.side, Atlas.side), mipmapLevel: 0)
            let c = CGContext(data: &px, width: Atlas.side, height: Atlas.side, bitsPerComponent: 8, bytesPerRow: Atlas.side * 4,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            // Flat grey matte so alpha edges are easy to judge.
            let out = CGContext(data: nil, width: Atlas.side, height: Atlas.side, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            out.setFillColor(CGColor(srgbRed: 0.2, green: 0.36, blue: 0.42, alpha: 1))
            out.fill(CGRect(x: 0, y: 0, width: Atlas.side, height: Atlas.side))
            out.draw(c.makeImage()!, in: CGRect(x: 0, y: 0, width: Atlas.side, height: Atlas.side))
            try NSBitmapImageRep(cgImage: out.makeImage()!).representation(using: .png, properties: [:])!
                .write(to: URL(fileURLWithPath: "\(prefix)-atlas.png"))
        }
        if forceRare { r.forceHaakjerring() }

        let simStart = CFAbsoluteTimeGetCurrent()
        var simulated = 0.0
        while simulated < warm { r.step(1.0 / 30.0); simulated += 1.0 / 30.0 }
        let simSeconds = CFAbsoluteTimeGetCurrent() - simStart
        print(String(format: "sim cost: %.2f ms per step", simSeconds / max(1, warm * 30) * 1000))

        let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: w, height: h, mipmapped: false)
        td.usage = [.renderTarget, .shaderRead]
        td.storageMode = .shared
        guard let tex = device.makeTexture(descriptor: td) else { fatalError("no texture") }

        var gpuTotal = 0.0
        for i in 0..<frames {
            if i > 0 {
                var s = 0.0
                while s < gap { r.step(1.0 / 30.0); s += 1.0 / 30.0 }
            }
            // Second draw lets the caustic tile exist before the frame we keep.
            var done: MTLCommandBuffer?
            for _ in 0..<2 {
                r.draw(to: tex, dt: 1.0 / 60.0) { cmd in
                    cmd.commit()
                    done = cmd
                }
                done?.waitUntilCompleted()
            }
            if let d = done, d.gpuEndTime > d.gpuStartTime { gpuTotal += d.gpuEndTime - d.gpuStartTime }
            var bytes = [UInt8](repeating: 0, count: w * h * 4)
            tex.getBytes(&bytes, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
            let cs = CGColorSpace(name: CGColorSpace.sRGB)!
            let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
            let ctx = CGContext(data: &bytes, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: cs, bitmapInfo: info.rawValue)!
            let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
            let path = "\(prefix)-\(i).png"
            try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
            print("wrote", path)
        }
        print(String(format: "gpu frame: %.2f ms", gpuTotal / Double(frames) * 1000))
    }
}
