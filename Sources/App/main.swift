import AppKit

// The app only carries the screen saver extension. Launching it registers the extension and
// says where to choose it.

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        register()
        buildMenu()

        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 150),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Havbunn"
        let content = w.contentView!
        let text = NSTextField(wrappingLabelWithString:
            "Havbunn is installed as a screen saver. Choose it in System Settings > Wallpaper, "
            + "under Screen Saver. Its Options set the species names.")
        text.frame = NSRect(x: 20, y: 64, width: 400, height: 66)
        content.addSubview(text)
        let open = NSButton(title: "Open Wallpaper Settings", target: self, action: #selector(openSettings))
        open.keyEquivalent = "\r"
        open.frame = NSRect(x: 220, y: 16, width: 200, height: open.intrinsicContentSize.height)
        content.addSubview(open)
        w.center()
        w.makeKeyAndOrderFront(nil)
        window = w
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// Registers the embedded extension with the system, in case LaunchServices has not yet.
    private func register() {
        guard let appex = Bundle.main.builtInPlugInsURL?.appendingPathComponent("Havbunn.appex") else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        p.arguments = ["-a", appex.path]
        try? p.run()
        p.waitUntilExit()
    }

    private func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Havbunn", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = main
    }

    @objc private func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
