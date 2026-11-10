import AppKit
import Metal
import QuartzCore
import ScreenSaver
import os

// NSLog output from the system host does not reach the unified log; Logger does.
private let saverLog = Logger(subsystem: "no.havbunn.screensaver", category: "saver")

@objc(HavbunnView)
public final class HavbunnView: ScreenSaverView {
    private static let moduleName = "no.havbunn.screensaver"
    private static let showNamesKey = "showNames"

    private var renderer: Renderer?
    private let metalLayer = CAMetalLayer()
    private var lastTime: CFTimeInterval = 0
    private var preparing = false
    private var stopped = false
    private var sheet: NSWindow?
    private var namesCheckbox: NSButton?
    /// Read by the preview tool to confirm frames reach the layer.
    @objc public private(set) var framesPresented = 0

    // The host creates new views at each activation and never releases the old ones.
    private static let instances = NSHashTable<HavbunnView>.weakObjects()
    private static var nextID = 1
    private static let generationWindow: CFTimeInterval = 2
    private let instanceID: Int = {
        defer { HavbunnView.nextID += 1 }
        return HavbunnView.nextID
    }()
    private var startedAt: CFTimeInterval = 0

    // A stalled drawable wait blocks the main thread that every view shares, so back off.
    private var drawableStalls = 0
    private var nextDrawableAttempt: CFTimeInterval = 0

    // Timing since the last report.
    private var reportAt: CFTimeInterval = 0
    private var ticks = 0
    private var reportFrames = 0
    private var waitTotal: CFTimeInterval = 0
    private var waitMax: CFTimeInterval = 0
    private var nilDrawables = 0
    private var skippedForStall = 0

    private static var defaults: UserDefaults {
        ScreenSaverDefaults(forModuleWithName: moduleName) ?? .standard
    }

    private static var showNames: Bool {
        get { defaults.object(forKey: showNamesKey) as? Bool ?? true }
        set {
            defaults.set(newValue, forKey: showNamesKey)
            defaults.synchronize()
        }
    }

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setUp()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        wantsLayer = true
        layer?.backgroundColor = CGColor(srgbRed: 0.016, green: 0.1, blue: 0.15, alpha: 1)
        // A sublayer, not the backing layer: AppKit and the host manage the backing layer's
        // scale, and on mixed-DPI setups that can disagree with the drawable. The resize
        // gravity makes the picture fill the layer whatever the drawable size is.
        metalLayer.pixelFormat = Renderer.pixelFormat
        metalLayer.framebufferOnly = true
        metalLayer.isOpaque = true
        metalLayer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        metalLayer.contentsGravity = .resize
        metalLayer.frame = bounds
        layer?.addSublayer(metalLayer)
        animationTimeInterval = 1.0 / 60.0
        // legacyScreenSaver can keep stopped instances alive, so release GPU work explicitly.
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(hostWillStop),
            name: NSNotification.Name("com.apple.screensaver.willstop"), object: nil)
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    public override func startAnimation() {
        stopped = false
        startedAt = CACurrentMediaTime()
        retireEarlierGenerations()
        HavbunnView.instances.add(self)
        saverLog.notice("start #\(self.instanceID, privacy: .public) live=\(HavbunnView.liveCount, privacy: .public) \(self.diagnostics, privacy: .public)")
        super.startAnimation()
        prepareIfNeeded()
    }

    public override func stopAnimation() {
        super.stopAnimation()
    }

    private static var liveCount: Int { instances.allObjects.filter { !$0.stopped }.count }

    /// Views started together belong to one activation, one per display. Anything of the
    /// same kind from an earlier activation is no longer on screen.
    private func retireEarlierGenerations() {
        for other in HavbunnView.instances.allObjects where other !== self && other.isPreview == isPreview && !other.stopped {
            if startedAt - other.startedAt > HavbunnView.generationWindow {
                saverLog.notice("retiring #\(other.instanceID, privacy: .public)")
                other.hostWillStop()
            }
        }
    }

    @objc private func hostWillStop() {
        stopped = true
        super.stopAnimation()
        let r = renderer
        renderer = nil
        preparing = false
        r?.tearDown()
    }

    /// The system host runs the view in a proxy window with no screen, whose backing scale
    /// comes from the main display. Find the real display by size.
    private var hostedScreen: NSScreen? {
        guard let w = window, w.screen == nil else { return nil }
        return NSScreen.screens.first { $0.frame.size == bounds.size }
    }

    private var displayScale: CGFloat {
        hostedScreen?.backingScaleFactor ?? window?.screen?.backingScaleFactor ?? window?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor ?? 2
    }

    private func pixelSize() -> (Int, Int) {
        (Int(bounds.width * displayScale), Int(bounds.height * displayScale))
    }

    /// One line describing the geometry, logged at each start and read by the preview tool.
    @objc public var diagnostics: String {
        let screen = window?.screen
        return "preview=\(isPreview) bounds=\(bounds.size) superview=\(superview?.bounds.size ?? .zero) "
            + "window=\(window?.frame.size ?? .zero) screen=\(screen?.localizedName ?? "nil") "
            + "screenFrame=\(screen?.frame.size ?? .zero) scale=\(displayScale) "
            + "layer=\(metalLayer.frame.size) contentsScale=\(metalLayer.contentsScale) drawable=\(metalLayer.drawableSize)"
    }

    /// The host can hand a view the wrong frame on a display whose scale differs from the
    /// main display, so follow the container when it is larger.
    private func matchContainer() {
        guard !isPreview, let container = superview?.bounds, container.width > bounds.width || container.height > bounds.height else { return }
        frame = container
    }

    private func prepareIfNeeded() {
        guard renderer == nil, !preparing, !stopped else { return }
        let (w, h) = pixelSize()
        guard w > 0, h > 0 else { return }
        let bundle = Bundle(for: HavbunnView.self)
        guard let device = MTLCreateSystemDefaultDevice(),
              let url = bundle.url(forResource: "Shaders", withExtension: "metal") else {
            saverLog.error("no Metal device or shader source")
            return
        }
        metalLayer.device = device
        preparing = true
        let seed = UInt64.random(in: 1...UInt64.max)
        // Captions are unreadable at preview size.
        let names = HavbunnView.showNames && !isPreview
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let r = try Renderer(device: device, shaderSource: url, seed: seed)
                r.showNames = names
                r.prepare(width: w, height: h)
                DispatchQueue.main.async {
                    guard let self = self, self.preparing else {
                        r.tearDown()
                        return
                    }
                    self.renderer = r
                    self.preparing = false
                    self.lastTime = 0
                }
            } catch {
                saverLog.error("renderer setup failed: \(String(describing: error), privacy: .public)")
                DispatchQueue.main.async { self?.preparing = false }
            }
        }
    }

    public override func animateOneFrame() {
        guard !stopped else { return }
        matchContainer()
        let ml = metalLayer
        let scale = displayScale
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let target = bounds
        if ml.frame != target || ml.contentsScale != scale || ml.drawableSize != size {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            ml.frame = target
            ml.contentsScale = scale
            if size.width > 0, size.height > 0 { ml.drawableSize = size }
            CATransaction.commit()
            saverLog.notice("geometry #\(self.instanceID, privacy: .public) \(self.diagnostics, privacy: .public)")
        }
        guard size.width > 0, size.height > 0 else { return }
        guard let r = renderer, r.isPrepared else {
            prepareIfNeeded()
            return
        }
        // The seabed is baked for one aspect ratio, so a late resize needs a new bake.
        if abs(r.preparedAspect - Float(size.width / size.height)) > 0.02 {
            renderer = nil
            r.tearDown()
            prepareIfNeeded()
            return
        }

        let now = CACurrentMediaTime()
        ticks += 1
        report(now)
        if now < nextDrawableAttempt {
            skippedForStall += 1
            return
        }
        let dt = lastTime == 0 ? 1.0 / 60.0 : now - lastTime
        lastTime = now

        autoreleasepool {
            let waitStart = CACurrentMediaTime()
            let next = ml.nextDrawable()
            let wait = CACurrentMediaTime() - waitStart
            waitTotal += wait
            waitMax = max(waitMax, wait)
            if wait > 0.1 || next == nil {
                drawableStalls += 1
                nextDrawableAttempt = waitStart + wait + min(8, 0.25 * pow(2, Double(drawableStalls)))
            } else {
                drawableStalls = 0
            }
            guard let drawable = next else {
                nilDrawables += 1
                return
            }
            r.draw(to: drawable.texture, dt: dt) { cmd in
                cmd.present(drawable)
                cmd.commit()
            }
            framesPresented += 1
            reportFrames += 1
        }
    }

    private func report(_ now: CFTimeInterval) {
        if reportAt == 0 { reportAt = now }
        let span = now - reportAt
        guard span >= 5 else { return }
        let visible = window?.occlusionState.contains(.visible) ?? false
        let attached = window != nil && superview != nil
        saverLog.debug("perf #\(self.instanceID, privacy: .public) preview=\(self.isPreview, privacy: .public) live=\(HavbunnView.liveCount, privacy: .public) attached=\(attached, privacy: .public) visible=\(visible, privacy: .public) ticks/s=\(Int(Double(self.ticks) / span), privacy: .public) fps=\(Int(Double(self.reportFrames) / span), privacy: .public) waitAvgMs=\(Int(self.waitTotal / max(1, Double(self.ticks)) * 1000), privacy: .public) waitMaxMs=\(Int(self.waitMax * 1000), privacy: .public) nil=\(self.nilDrawables, privacy: .public) skipped=\(self.skippedForStall, privacy: .public)")
        reportAt = now
        ticks = 0
        reportFrames = 0
        waitTotal = 0
        waitMax = 0
        nilDrawables = 0
        skippedForStall = 0
    }

    public override func draw(_ rect: NSRect) {}

    // MARK: options sheet

    public override var hasConfigureSheet: Bool { true }

    public override var configureSheet: NSWindow? {
        let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 120),
                             styleMask: [.titled], backing: .buffered, defer: true)
        panel.isReleasedWhenClosed = false
        let content = panel.contentView!
        let box = NSButton(checkboxWithTitle: "Show species names", target: nil, action: nil)
        box.state = HavbunnView.showNames ? .on : .off
        box.frame = NSRect(x: 24, y: 70, width: 300, height: 24)
        content.addSubview(box)
        let ok = NSButton(title: "OK", target: self, action: #selector(closeSheet))
        ok.keyEquivalent = "\r"
        ok.frame = NSRect(x: 256, y: 16, width: 84, height: ok.intrinsicContentSize.height)
        content.addSubview(ok)
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelSheet))
        cancel.keyEquivalent = "\u{1b}"
        cancel.frame = NSRect(x: 160, y: 16, width: 84, height: cancel.intrinsicContentSize.height)
        content.addSubview(cancel)
        namesCheckbox = box
        sheet = panel
        return panel
    }

    @objc private func cancelSheet() {
        namesCheckbox = nil
        closeSheet()
    }

    @objc private func closeSheet() {
        if let box = namesCheckbox {
            let on = box.state == .on
            HavbunnView.showNames = on
            renderer?.showNames = on && !isPreview
        }
        guard let s = sheet else { return }
        if let parent = s.sheetParent { parent.endSheet(s) } else { s.close() }
        sheet = nil
    }
}
