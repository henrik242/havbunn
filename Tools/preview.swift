// Runs the saver view in a window, the way the system hosts it. Run from the repository root,
// since it reads the shader source from Sources/Shaders.
// Usage: havbunn-preview [--seconds N] [--screen I] [--all-screens]
// --screen covers that display with a borderless window.
// --all-screens runs one view per display in this process, as the system host does.
// With --seconds it quits by itself and reports whether frames were produced.
import AppKit
import ScreenSaver

@main
struct Main {
    static func main() {
        var args = Array(CommandLine.arguments.dropFirst())
        var seconds: Double? = nil
        var screenIndex: Int? = nil, allScreens = false
        while !args.isEmpty {
            let a = args.removeFirst()
            switch a {
            case "--seconds": seconds = Double(args.removeFirst())
            case "--screen": screenIndex = Int(args.removeFirst())
            case "--all-screens": allScreens = true
            default: print("unknown \(a)"); exit(2)
            }
        }

        HavbunnView.shaderURL = URL(fileURLWithPath: "Sources/Shaders/Shaders.metal")
        let cls: ScreenSaverView.Type = HavbunnView.self

        let app = NSApplication.shared
        app.setActivationPolicy(seconds == nil ? .regular : .accessory)
        if allScreens {
            var keep: [(NSWindow, ScreenSaverView)] = []
            for screen in NSScreen.screens {
                let w = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                w.setFrame(screen.frame, display: false)
                w.level = .screenSaver
                guard let v = cls.init(frame: NSRect(origin: .zero, size: screen.frame.size), isPreview: false) else { exit(1) }
                w.contentView = v
                w.orderFrontRegardless()
                v.startAnimation()
                keep.append((w, v))
            }
            let total = seconds ?? 8
            Timer.scheduledTimer(withTimeInterval: total, repeats: false) { _ in
                for (w, v) in keep {
                    let n = v.value(forKey: "framesPresented") as? Int ?? -1
                    print("\(w.screen?.localizedName ?? "?") \(Int(w.frame.width))x\(Int(w.frame.height)): \(n) frames, \(Int(Double(n) / total)) fps")
                }
                exit(0)
            }
            app.run()
        }

        let target = screenIndex.flatMap { $0 < NSScreen.screens.count ? NSScreen.screens[$0] : nil }
        let frame = NSRect(origin: .zero, size: target?.frame.size ?? NSSize(width: 1280, height: 800))
        let window: NSWindow
        if let target = target {
            window = NSWindow(contentRect: target.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.setFrame(target.frame, display: false)
            window.level = .screenSaver
        } else {
            window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            window.title = "Havbunn preview"
        }
        guard let view = cls.init(frame: frame, isPreview: false) else {
            print("FAIL: view init returned nil")
            exit(1)
        }
        window.contentView = view
        if target == nil { window.center() }
        print("window number:", window.windowNumber)
        window.makeKeyAndOrderFront(nil)
        view.startAnimation()

        if let seconds = seconds {
            let start = Date()
            var ticks = 0
            Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { t in
                ticks += 1
                if Date().timeIntervalSince(start) > seconds {
                    t.invalidate()
                    let mem = residentMB()
                    let frames = view.value(forKey: "framesPresented") as? Int ?? -1
                    var u = rusage()
                    getrusage(RUSAGE_SELF, &u)
                    let cpu = Double(u.ru_utime.tv_sec + u.ru_stime.tv_sec) + Double(u.ru_utime.tv_usec + u.ru_stime.tv_usec) / 1e6
                    print("ran \(ticks) timer ticks, presented \(frames) frames (\(Int(Double(frames) / seconds)) fps), resident \(mem) MB")
                    print(String(format: "cpu: %.1f%% of one core, startup included", cpu / seconds * 100))
                    print("geometry:", view.value(forKey: "diagnostics") as? String ?? "?")
                    view.stopAnimation()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.5))
                    print("after stop, resident \(residentMB()) MB")
                    exit(0)
                }
            }
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        app.run()
    }

    static func residentMB() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kr == KERN_SUCCESS ? Int(info.resident_size / 1_048_576) : -1
    }
}
