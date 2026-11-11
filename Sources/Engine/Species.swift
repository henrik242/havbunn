import CoreGraphics
import CoreText
import Foundation

struct SpeciesInfo {
    let key: String
    let norsk: String
    let latin: String
    let english: String
    /// Atlas sprites; the main one is named after the key.
    let sprites: [SpriteDef]
    /// Adds this species to a new scene. Draws from the scene's one RNG, so list order matters.
    let place: (Placement) -> Void
}

/// Every organism in the scene. All are native to Norwegian waters. Norwegian names follow
/// Artsdatabanken (Artskart) where it has one, otherwise the majority of other references.
/// Each species lives in its own file under Species/.
enum Species {
    /// Placement order: changing it reshuffles every seed's scene.
    static let all: [SpeciesInfo] = [
        // Rooted and still life, the reef coral first so nothing else crowds it out.
        oyekorall, sjotre, stortare, sukkertare, sjonellik, dodningehand, oskjell, drobak, kraakebolle,
        sjofjaer, kamskjell, krinakrabbe, rodpolse,
        // Fish on their own, mostly keeping to a home patch.
        torsk, lyr, uer, berggylt, blaastaal, rognkjeks, bergnebb, brosme, lange, pigghaa,
        // Schools.
        sild, sei, makrell, hvitting,
        // Rare visitors.
        haakjerring, havmus, laks,
        // Jellies.
        brennmanet, glassmanet, sjostikkelsbaer,
        // Walking crustaceans.
        hummer, sjokreps, taskekrabbe,
        // Bottom dwellers that rest and now and then move.
        breiflabb, rodspette, lomre, rodhai, knurr, kongsnegl, piggskate, steinbit,
        // Starfish.
        korstroll, solstjerne,
    ]

    /// Shade shared by both kelps.
    static let kelpTint = C3(0.58, 0.62, 0.50)

    static func spriteDefs(english: Bool) -> [SpriteDef] {
        var d = all.flatMap(\.sprites)
        // Catches a species file whose key and sprites disagree, before anything is drawn.
        var keys = Set<String>()
        for s in all {
            if !keys.insert(s.key).inserted { fatalError("species \(s.key) is listed twice") }
            if !s.sprites.contains(where: { $0.name == s.key || $0.name.hasPrefix(s.key + "-") }) {
                fatalError("species \(s.key) has no sprite named \(s.key) or \(s.key)-<n>")
            }
        }
        d += [
            .init(name: "shadow", w: 128, h: 48) { a in a.softDot(500, a.unitH / 2, 495, C3(0, 0, 0), 0.72, sy: a.unitH / 1000) },
            .init(name: "puff", w: 128, h: 64) { a in a.softDot(500, a.unitH / 2, 495, C3(0.86, 0.88, 0.82), 0.9, sy: a.unitH / 1000) },
            .init(name: "pointer-line", w: 64, h: 16) { a in a.fill([(0, a.unitH * 0.3), (1000, a.unitH * 0.3), (1000, a.unitH * 0.7), (0, a.unitH * 0.7)], C3(1, 1, 1), 1, raw: true) },
            .init(name: "pointer-head", w: 48, h: 48) { a in a.fill([(40, 120), (960, 500), (40, 880), (220, 500)], C3(1, 1, 1), 1, raw: true) },
        ]
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
