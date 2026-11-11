import AppKit
import ScreenSaver

// The screen saver app extension. Info.plist names these classes; the system loads the
// extension in its own sandboxed process for each display and for the Options sheet.

@objc(HavbunnExtension)
final class HavbunnExtension: ScreenSaverExtension {}

@objc(HavbunnViewController)
final class HavbunnViewController: ScreenSaverViewController {
    /// The host sizes the view after attaching it, so it starts at zero and follows.
    override func loadView() {
        guard let v = HavbunnView(frame: .zero, isPreview: false) else {
            view = NSView(frame: .zero)
            return
        }
        v.autoresizingMask = [.width, .height]
        view = v
    }
}

@objc(HavbunnConfigurationViewController)
final class HavbunnConfigurationViewController: ScreenSaverConfigurationViewController {
    private let names = NSPopUpButton(frame: NSRect(x: 136, y: 66, width: 200, height: 28), pullsDown: false)

    override func loadView() {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 120))
        let label = NSTextField(labelWithString: "Species names:")
        label.alignment = .right
        label.frame = NSRect(x: 20, y: 72, width: 110, height: 20)
        content.addSubview(label)
        names.addItems(withTitles: ["Off", "Automatic", "Norwegian", "English"])
        names.selectItem(at: Settings.captionLanguage)
        content.addSubview(names)
        let ok = NSButton(title: "OK", target: self, action: #selector(save))
        ok.keyEquivalent = "\r"
        ok.frame = NSRect(x: 256, y: 16, width: 84, height: ok.intrinsicContentSize.height)
        content.addSubview(ok)
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancel.keyEquivalent = "\u{1b}"
        cancel.frame = NSRect(x: 160, y: 16, width: 84, height: cancel.intrinsicContentSize.height)
        content.addSubview(cancel)
        view = content
    }

    override func configureSheetWillPresent() {
        super.configureSheetWillPresent()
        names.selectItem(at: Settings.captionLanguage)
    }

    // Takes effect the next time the saver starts.
    @objc private func save() {
        Settings.captionLanguage = names.indexOfSelectedItem
        configureSheetDidEnd()
    }

    @objc private func cancel() {
        configureSheetDidEnd()
    }
}
