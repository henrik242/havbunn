import CoreGraphics
import CoreText
import Foundation

struct SpeciesInfo {
    let key: String
    let norsk: String
    let latin: String
    let english: String
}

/// Every organism in the scene. All are native to Norwegian waters. Norwegian names follow
/// Artsdatabanken (Artskart) where it has one, otherwise the majority of other references.
enum Species {
    static let all: [SpeciesInfo] = [
        .init(key: "torsk", norsk: "Torsk", latin: "Gadus morhua", english: "Atlantic cod"),
        .init(key: "sei", norsk: "Sei", latin: "Pollachius virens", english: "Saithe"),
        .init(key: "lyr", norsk: "Lyr", latin: "Pollachius pollachius", english: "Pollack"),
        .init(key: "sild", norsk: "Sild", latin: "Clupea harengus", english: "Atlantic herring"),
        .init(key: "makrell", norsk: "Makrell", latin: "Scomber scombrus", english: "Atlantic mackerel"),
        .init(key: "laks", norsk: "Laks", latin: "Salmo salar", english: "Atlantic salmon"),
        .init(key: "uer", norsk: "Lusuer", latin: "Sebastes viviparus", english: "Norway redfish"),
        .init(key: "berggylt", norsk: "Berggylte", latin: "Labrus bergylta", english: "Ballan wrasse"),
        .init(key: "blaastaal", norsk: "Blåstål", latin: "Labrus mixtus", english: "Cuckoo wrasse"),
        .init(key: "rognkjeks", norsk: "Rognkjeks", latin: "Cyclopterus lumpus", english: "Lumpfish"),
        .init(key: "bergnebb", norsk: "Bergnebb", latin: "Ctenolabrus rupestris", english: "Goldsinny wrasse"),
        .init(key: "brosme", norsk: "Brosme", latin: "Brosme brosme", english: "Tusk"),
        .init(key: "havmus", norsk: "Havmus", latin: "Chimaera monstrosa", english: "Rabbit fish"),
        .init(key: "lomre", norsk: "Lomre", latin: "Microstomus kitt", english: "Lemon sole"),
        .init(key: "krinakrabbe", norsk: "Krinakrabbe", latin: "Galathea strigosa", english: "Spiny squat lobster"),
        .init(key: "rodpolse", norsk: "Rødpølse", latin: "Parastichopus tremulus", english: "Red sea cucumber"),
        .init(key: "pigghaa", norsk: "Pigghå", latin: "Squalus acanthias", english: "Spiny dogfish"),
        .init(key: "haakjerring", norsk: "Håkjerring", latin: "Somniosus microcephalus", english: "Greenland shark"),
        .init(key: "breiflabb", norsk: "Breiflabb", latin: "Lophius piscatorius", english: "Angler"),
        .init(key: "steinbit", norsk: "Gråsteinbit", latin: "Anarhichas lupus", english: "Atlantic wolffish"),
        .init(key: "rodspette", norsk: "Rødspette", latin: "Pleuronectes platessa", english: "European plaice"),
        .init(key: "piggskate", norsk: "Piggskate", latin: "Raja clavata", english: "Thornback ray"),
        .init(key: "glassmanet", norsk: "Glassmanet", latin: "Aurelia aurita", english: "Moon jelly"),
        .init(key: "brennmanet", norsk: "Brennmanet", latin: "Cyanea capillata", english: "Lion's mane jellyfish"),
        .init(key: "sjostikkelsbaer", norsk: "Kulekammanet", latin: "Pleurobrachia pileus", english: "Sea gooseberry"),
        .init(key: "hummer", norsk: "Hummer", latin: "Homarus gammarus", english: "European lobster"),
        .init(key: "sjokreps", norsk: "Sjøkreps", latin: "Nephrops norvegicus", english: "Norway lobster"),
        .init(key: "taskekrabbe", norsk: "Taskekrabbe", latin: "Cancer pagurus", english: "Brown crab"),
        .init(key: "korstroll", norsk: "Vanlig korstroll", latin: "Asterias rubens", english: "Common starfish"),
        .init(key: "solstjerne", norsk: "Piggsolstjerne", latin: "Crossaster papposus", english: "Common sunstar"),
        .init(key: "drobak", norsk: "Drøbaksjøpiggsvin", latin: "Strongylocentrotus droebachiensis", english: "Green sea urchin"),
        .init(key: "kraakebolle", norsk: "Svabergsjøpiggsvin", latin: "Echinus esculentus", english: "Edible sea urchin"),
        .init(key: "kamskjell", norsk: "Stort kamskjell", latin: "Pecten maximus", english: "King scallop"),
        .init(key: "oskjell", norsk: "O-skjell", latin: "Modiolus modiolus", english: "Horse mussel"),
        .init(key: "sjonellik", norsk: "Sjønellik", latin: "Metridium senile", english: "Plumose anemone"),
        .init(key: "dodningehand", norsk: "Dødmannshånd", latin: "Alcyonium digitatum", english: "Dead man's fingers"),
        .init(key: "oyekorall", norsk: "Øyekorall", latin: "Desmophyllum pertusum", english: "Cold-water coral"),
        .init(key: "sjotre", norsk: "Sjøtre", latin: "Paragorgia arborea", english: "Bubblegum coral"),
        .init(key: "sjofjaer", norsk: "Stor piperenser", latin: "Funiculina quadrangularis", english: "Tall sea pen"),
        .init(key: "stortare", norsk: "Stortare", latin: "Laminaria hyperborea", english: "Forest kelp"),
        .init(key: "sukkertare", norsk: "Sukkertare", latin: "Saccharina latissima", english: "Sugar kelp"),
    ]

    static func spriteDefs(english: Bool) -> [SpriteDef] {
        var d: [SpriteDef] = [
            .init(name: "torsk", w: 720, h: 306) { FishArt.torsk($0) },
            .init(name: "sei", w: 680, h: 226) { FishArt.sei($0) },
            .init(name: "lyr", w: 620, h: 216) { FishArt.lyr($0) },
            .init(name: "sild", w: 300, h: 96) { FishArt.sild($0) },
            .init(name: "makrell", w: 400, h: 144) { FishArt.makrell($0) },
            .init(name: "laks", w: 720, h: 244) { FishArt.laks($0) },
            .init(name: "uer", w: 460, h: 230) { FishArt.uer($0) },
            .init(name: "berggylt", w: 500, h: 240) { FishArt.berggylt($0) },
            .init(name: "blaastaal", w: 400, h: 192) { FishArt.blaastaal($0) },
            .init(name: "rognkjeks", w: 400, h: 248) { FishArt.rognkjeks($0) },
            .init(name: "bergnebb", w: 260, h: 126) { FishArt.bergnebb($0) },
            .init(name: "brosme", w: 640, h: 200) { FishArt.brosme($0) },
            .init(name: "havmus", w: 720, h: 260) { FishArt.havmus($0) },
            .init(name: "lomre", w: 380, h: 152) { FishArt.lomre($0) },
            .init(name: "krinakrabbe", w: 260, h: 150) { BenthosArt.krinakrabbe($0) },
            .init(name: "rodpolse", w: 320, h: 120) { BenthosArt.rodpolse($0) },
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
            .init(name: "puff", w: 128, h: 64) { a in a.softDot(500, a.unitH / 2, 495, C3(0.86, 0.88, 0.82), 0.9, sy: a.unitH / 1000) },
            .init(name: "sjostikkelsbaer", w: 120, h: 150) { BenthosArt.seaGooseberry($0) },
            .init(name: "pointer-line", w: 64, h: 16) { a in a.fill([(0, a.unitH * 0.3), (1000, a.unitH * 0.3), (1000, a.unitH * 0.7), (0, a.unitH * 0.7)], C3(1, 1, 1), 1, raw: true) },
            .init(name: "pointer-head", w: 48, h: 48) { a in a.fill([(40, 120), (960, 500), (40, 880), (220, 500)], C3(1, 1, 1), 1, raw: true) },
        ]
        for f in 0..<4 {
            d.append(.init(name: "hummer-\(f)", w: 480, h: 200) { BenthosArt.lobster($0, frame: f, palette: BenthosArt.hummerPalette) })
            d.append(.init(name: "sjokreps-\(f)", w: 400, h: 166) { BenthosArt.lobster($0, frame: f, palette: BenthosArt.sjokrepsPalette) })
            d.append(.init(name: "taskekrabbe-\(f)", w: 380, h: 170) { BenthosArt.taskekrabbe($0, frame: f) })
        }
        for s in all {
            d.append(.init(name: "cap-\(s.key)", w: captionWidth(s, english: english), h: 96) { a in caption(a, s, english: english) })
        }
        return d
    }

    /// Caption text, with fonts sized in cell pixels; `px` converts pixels to drawing units.
    private static func captionLine(_ s: SpeciesInfo, english: Bool, px: Double) -> CTLine {
        let head = CTFontCreateWithName("AvenirNext-Medium" as CFString, 50 * px, nil)
        let sub = CTFontCreateWithName("IowanOldStyle-Italic" as CFString, 44 * px, nil)
        let text = NSMutableAttributedString(string: english ? s.english : s.norsk, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: head,
            kCTForegroundColorAttributeName as NSAttributedString.Key: CGColor(srgbRed: 0.86, green: 0.92, blue: 0.91, alpha: 1),
            kCTKernAttributeName as NSAttributedString.Key: 0.5 * px,
        ])
        text.append(NSAttributedString(string: "   " + s.latin, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: sub,
            kCTForegroundColorAttributeName as NSAttributedString.Key: CGColor(srgbRed: 0.76, green: 0.85, blue: 0.85, alpha: 0.95),
        ]))
        return CTLineCreateWithAttributedString(text)
    }

    /// Cell width that fits the text plus the left inset and the scrim's soft edge.
    private static func captionWidth(_ s: SpeciesInfo, english: Bool) -> Int {
        let w = CTLineGetTypographicBounds(captionLine(s, english: english, px: 1), nil, nil, nil)
        return Int(w.rounded(.up)) + 26 + 70
    }

    private static func caption(_ a: Art, _ s: SpeciesInfo, english: Bool) {
        let px = 1 / a.k
        let c = a.ctx
        let line = captionLine(s, english: english, px: px)
        let width = Double(CTLineGetTypographicBounds(line, nil, nil, nil))
        let x0 = 26 * px
        // Soft scrim keeps the text legible over bright sand.
        a.softDot(x0 + width / 2, a.unitH * 0.5, width / 2 + 40 * px, C3(0.01, 0.07, 0.10), 0.5, sy: (a.unitH * 0.62) / (width / 2 + 40 * px))
        c.saveGState()
        c.textMatrix = .identity
        c.translateBy(x: x0, y: a.unitH * 0.68)
        c.scaleBy(x: 1, y: -1)
        c.setShadow(offset: .zero, blur: 3 * px, color: CGColor(srgbRed: 0, green: 0.04, blue: 0.07, alpha: 0.8))
        CTLineDraw(line, c)
        c.restoreGState()
    }
}
