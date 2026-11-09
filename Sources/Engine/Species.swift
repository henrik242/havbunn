import CoreGraphics
import CoreText
import Foundation

struct SpeciesInfo {
    let key: String
    let norsk: String
    let latin: String
}

/// Every organism in the scene. All are native to Norwegian waters.
enum Species {
    static let all: [SpeciesInfo] = [
        .init(key: "torsk", norsk: "Torsk", latin: "Gadus morhua"),
        .init(key: "sei", norsk: "Sei", latin: "Pollachius virens"),
        .init(key: "sild", norsk: "Sild", latin: "Clupea harengus"),
        .init(key: "makrell", norsk: "Makrell", latin: "Scomber scombrus"),
        .init(key: "laks", norsk: "Laks", latin: "Salmo salar"),
        .init(key: "uer", norsk: "Vanlig uer", latin: "Sebastes norvegicus"),
        .init(key: "berggylt", norsk: "Berggylt", latin: "Labrus bergylta"),
        .init(key: "blaastaal", norsk: "Blåstål", latin: "Labrus mixtus"),
        .init(key: "rognkjeks", norsk: "Rognkjeks", latin: "Cyclopterus lumpus"),
        .init(key: "pigghaa", norsk: "Pigghå", latin: "Squalus acanthias"),
        .init(key: "haakjerring", norsk: "Håkjerring", latin: "Somniosus microcephalus"),
        .init(key: "breiflabb", norsk: "Breiflabb", latin: "Lophius piscatorius"),
        .init(key: "steinbit", norsk: "Gråsteinbit", latin: "Anarhichas lupus"),
        .init(key: "rodspette", norsk: "Rødspette", latin: "Pleuronectes platessa"),
        .init(key: "piggskate", norsk: "Piggskate", latin: "Raja clavata"),
        .init(key: "glassmanet", norsk: "Glassmanet", latin: "Aurelia aurita"),
        .init(key: "brennmanet", norsk: "Brennmanet", latin: "Cyanea capillata"),
        .init(key: "hummer", norsk: "Hummer", latin: "Homarus gammarus"),
        .init(key: "sjokreps", norsk: "Sjøkreps", latin: "Nephrops norvegicus"),
        .init(key: "taskekrabbe", norsk: "Taskekrabbe", latin: "Cancer pagurus"),
        .init(key: "korstroll", norsk: "Korstroll", latin: "Asterias rubens"),
        .init(key: "solstjerne", norsk: "Solstjerne", latin: "Crossaster papposus"),
        .init(key: "drobak", norsk: "Drøbakkråkebolle", latin: "Strongylocentrotus droebachiensis"),
        .init(key: "kraakebolle", norsk: "Rød kråkebolle", latin: "Echinus esculentus"),
        .init(key: "kamskjell", norsk: "Stort kamskjell", latin: "Pecten maximus"),
        .init(key: "oskjell", norsk: "Oskjell", latin: "Modiolus modiolus"),
        .init(key: "sjonellik", norsk: "Sjønellik", latin: "Metridium senile"),
        .init(key: "dodningehand", norsk: "Dødningehånd", latin: "Alcyonium digitatum"),
        .init(key: "oyekorall", norsk: "Øyekorall", latin: "Desmophyllum pertusum"),
        .init(key: "sjotre", norsk: "Sjøtre", latin: "Paragorgia arborea"),
        .init(key: "sjofjaer", norsk: "Sjøfjær", latin: "Funiculina quadrangularis"),
        .init(key: "stortare", norsk: "Stortare", latin: "Laminaria hyperborea"),
        .init(key: "sukkertare", norsk: "Sukkertare", latin: "Saccharina latissima"),
    ]

    static func spriteDefs() -> [SpriteDef] {
        var d: [SpriteDef] = [
            .init(name: "torsk", w: 720, h: 306) { FishArt.torsk($0) },
            .init(name: "sei", w: 680, h: 226) { FishArt.sei($0) },
            .init(name: "sild", w: 300, h: 96) { FishArt.sild($0) },
            .init(name: "makrell", w: 400, h: 144) { FishArt.makrell($0) },
            .init(name: "laks", w: 720, h: 244) { FishArt.laks($0) },
            .init(name: "uer", w: 460, h: 230) { FishArt.uer($0) },
            .init(name: "berggylt", w: 500, h: 240) { FishArt.berggylt($0) },
            .init(name: "blaastaal", w: 400, h: 192) { FishArt.blaastaal($0) },
            .init(name: "rognkjeks", w: 400, h: 248) { FishArt.rognkjeks($0) },
            .init(name: "pigghaa", w: 720, h: 230) { FishArt.pigghaa($0) },
            .init(name: "haakjerring", w: 1024, h: 276) { FishArt.haakjerring($0) },
            .init(name: "breiflabb", w: 640, h: 352) { FishArt.breiflabb($0) },
            .init(name: "steinbit", w: 720, h: 216) { FishArt.steinbit($0) },
            .init(name: "rodspette", w: 420, h: 168) { FishArt.rodspette($0) },
            .init(name: "piggskate", w: 560, h: 340) { FishArt.piggskate($0) },
            .init(name: "glassmanet", w: 360, h: 288) { FishArt.jellyMoon($0) },
            .init(name: "brennmanet", w: 400, h: 400) { FishArt.jellyLion($0) },
            .init(name: "korstroll", w: 300, h: 186) { BenthosArt.korstroll($0) },
            .init(name: "solstjerne", w: 320, h: 198) { BenthosArt.solstjerne($0) },
            .init(name: "drobak", w: 240, h: 170) {
                BenthosArt.urchin($0, deep: hex(0x2c3f25), light: hex(0x7f9861), spine: hex(0x94a66e), length: 170, count: 300, width: 8)
            },
            .init(name: "kraakebolle", w: 280, h: 220) {
                BenthosArt.urchin($0, deep: hex(0x9f4154), light: hex(0xe89fa9), spine: hex(0xe6c4bb), length: 92, count: 420, width: 9)
            },
            .init(name: "kamskjell", w: 220, h: 158) { BenthosArt.kamskjell($0) },
            .init(name: "oskjell", w: 300, h: 150) { BenthosArt.oskjell($0) },
            .init(name: "sjonellik", w: 280, h: 280) {
                BenthosArt.sjonellik($0, column: hex(0xe9e1d0), crown: hex(0xf8f4e7))
            },
            .init(name: "sjonellik-o", w: 280, h: 280) {
                BenthosArt.sjonellik($0, column: hex(0xdf8c43), crown: hex(0xf7a95c))
            },
            .init(name: "dodningehand", w: 300, h: 180) { BenthosArt.dodningehand($0) },
            .init(name: "oyekorall-1", w: 760, h: 620) { BenthosArt.lophelia($0, base: hex(0xcbb7a4), tip: hex(0xf4ebdd), seed: 11) },
            .init(name: "oyekorall-2", w: 760, h: 620) { BenthosArt.lophelia($0, base: hex(0xcf7a47), tip: hex(0xf3b98c), seed: 29) },
            .init(name: "oyekorall-3", w: 620, h: 500) { BenthosArt.lophelia($0, base: hex(0xbdab9c), tip: hex(0xfaf2e7), seed: 47) },
            .init(name: "sjotre-1", w: 500, h: 560) { BenthosArt.sjotre($0, base: hex(0x98202c), tip: hex(0xdf5661), seed: 5) },
            .init(name: "sjotre-2", w: 440, h: 500) { BenthosArt.sjotre($0, base: hex(0xcc7c86), tip: hex(0xf4c8c7), seed: 8) },
            .init(name: "sjofjaer", w: 120, h: 760) { BenthosArt.sjofjaer($0) },
            .init(name: "stortare-1", w: 340, h: 760) { BenthosArt.stortare($0, seed: 3) },
            .init(name: "stortare-2", w: 340, h: 760) { BenthosArt.stortare($0, seed: 17) },
            .init(name: "stortare-3", w: 340, h: 760) { BenthosArt.stortare($0, seed: 41) },
            .init(name: "sukkertare-1", w: 240, h: 860) { BenthosArt.sukkertare($0, seed: 2) },
            .init(name: "sukkertare-2", w: 240, h: 860) { BenthosArt.sukkertare($0, seed: 23) },
            .init(name: "shadow", w: 128, h: 48) { BenthosArt.shadow($0) },
        ]
        for f in 0..<4 {
            d.append(.init(name: "hummer-\(f)", w: 480, h: 200) { BenthosArt.lobster($0, frame: f, palette: BenthosArt.hummerPalette) })
            d.append(.init(name: "sjokreps-\(f)", w: 400, h: 166) { BenthosArt.lobster($0, frame: f, palette: BenthosArt.sjokrepsPalette) })
            d.append(.init(name: "taskekrabbe-\(f)", w: 380, h: 170) { BenthosArt.taskekrabbe($0, frame: f) })
        }
        for s in all {
            d.append(.init(name: "cap-\(s.key)", w: 880, h: 64) { a in caption(a, s) })
        }
        return d
    }

    private static func caption(_ a: Art, _ s: SpeciesInfo) {
        let c = a.ctx
        let head = CTFontCreateWithName("Avenir Next Medium" as CFString, 34 / a.k * 1.0, nil)
        let sub = CTFontCreateWithName("Baskerville-Italic" as CFString, 32 / a.k * 1.0, nil)
        let text = NSMutableAttributedString(string: s.norsk, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: head,
            kCTForegroundColorAttributeName as NSAttributedString.Key: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.96),
        ])
        text.append(NSAttributedString(string: "   " + s.latin, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: sub,
            kCTForegroundColorAttributeName as NSAttributedString.Key: CGColor(srgbRed: 0.84, green: 0.93, blue: 0.93, alpha: 0.86),
        ]))
        let line = CTLineCreateWithAttributedString(text)
        c.saveGState()
        c.textMatrix = .identity
        c.translateBy(x: 0, y: a.unitH * 0.72)
        c.scaleBy(x: 1, y: -1)
        c.setShadow(offset: CGSize(width: 0, height: -1), blur: 7, color: CGColor(srgbRed: 0, green: 0.05, blue: 0.1, alpha: 0.85))
        c.textPosition = CGPoint(x: 0, y: 0)
        CTLineDraw(line, c)
        c.restoreGState()
    }
}
