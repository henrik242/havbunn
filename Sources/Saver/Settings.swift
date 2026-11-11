import Foundation
import os

// NSLog output from the system host does not reach the unified log; Logger does.
let saverLog = Logger(subsystem: "no.synth.havbunn", category: "saver")

/// The saver's options, in a plist in the extension's sandbox home. The Options sheet and the
/// running saver are separate processes of the same extension, so both see this file.
enum Settings {
    private static let url = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("Library/Application Support/Havbunn/settings.plist")
    private static let languageKey = "captionLanguage"

    private static func value(_ key: String) -> Int? {
        (NSDictionary(contentsOf: url) as? [String: Any])?[key] as? Int
    }

    private static func set(_ key: String, _ value: Int) {
        var all = (NSDictionary(contentsOf: url) as? [String: Any]) ?? [:]
        all[key] = value
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try (all as NSDictionary).write(to: url)
        } catch {
            saverLog.error("settings not saved: \(String(describing: error), privacy: .public)")
        }
    }

    /// 0 off, 1 automatic, 2 Norwegian, 3 English.
    static var captionLanguage: Int {
        get { value(languageKey) ?? 1 }
        set { set(languageKey, newValue) }
    }

    static var englishNames: Bool {
        switch captionLanguage {
        case 2: return false
        case 3: return true
        default:
            let lang = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"
            return !["nb", "nn", "no"].contains(lang)
        }
    }
}
