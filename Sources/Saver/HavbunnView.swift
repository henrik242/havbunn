import AppKit
import IOSurface
import Metal
import QuartzCore
import ScreenSaver

/// The scene on one display, run by the screen saver extension and by the preview tool.
@objc(HavbunnView)
public final class HavbunnView: ScreenSaverView {
    /// The preview tool has no bundle and points this at the source tree.
    static var shaderURL = Bundle(for: HavbunnView.self).url(forResource: "Shaders", withExtension: "metal")

    private var renderer: Renderer?
    /// Frames render with Metal into IOSurfaces, and an OpenGL backing layer shows them, the
    /// way Apple's OpenGL savers draw. The system hosts the view remotely at the main display's
    /// scale; a CAMetalLayer, a contents swap or an OpenGL sublayer then updates only a quarter
    /// of a 1x display beside a 2x one.
    private let surfaceLayer = SurfaceGLLayer()
    private var device: MTLDevice?
    private var surfaces: [(surface: IOSurface, texture: MTLTexture)] = []
    private var nextSurface = 0
    private var running = false
    private var preparing = false
    private var lastTime: CFTimeInterval = 0
    private var loggedBounds = NSRect.zero
    /// Read by the preview tool to confirm frames reach the layer.
    @objc public private(set) var framesPresented = 0

    private static var nextID = 1
    private let instanceID: Int = {
        defer { HavbunnView.nextID += 1 }
        return HavbunnView.nextID
    }()

    // Timing since the last report.
    private var reportAt: CFTimeInterval = 0
    private var reportFrames = 0
    private var waitTotal: CFTimeInterval = 0
    private var waitMax: CFTimeInterval = 0

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setUp()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    /// The OpenGL layer is the view's own backing layer, so AppKit and the host size it and
    /// set its scale.
    public override func makeBackingLayer() -> CALayer { surfaceLayer }

    private func setUp() {
        wantsLayer = true
        animationTimeInterval = 1.0 / 60.0
    }

    // The host calls startAnimation once per view, but releases views without stopAnimation,
    // so the window decides too.
    public override func startAnimation() {
        super.startAnimation()
        start()
    }

    public override func stopAnimation() {
        stop()
        super.stopAnimation()
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { stop() } else { start() }
    }

    private func start() {
        guard !running else { return }
        running = true
        saverLog.notice("start #\(self.instanceID, privacy: .public) \(self.diagnostics, privacy: .public)")
        prepareIfNeeded()
    }

    private func stop() {
        guard running else { return }
        running = false
        let r = renderer
        renderer = nil
        preparing = false
        r?.tearDown()
        surfaces = []
        surfaceLayer.publish(nil)
    }

    /// The host runs the view in a proxy window with no screen, whose backing scale comes
    /// from the main display. Find the real display by size.
    private var hostedScreen: NSScreen? {
        guard let w = window, w.screen == nil else { return nil }
        return NSScreen.screens.first { $0.frame.size == bounds.size }
    }

    /// The scene renders at the display's real scale; the layer scales it to the host's.
    private var displayScale: CGFloat {
        hostedScreen?.backingScaleFactor ?? window?.screen?.backingScaleFactor ?? window?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor ?? 2
    }

    /// The host does not say whether a view is the System Settings preview, so judge by size.
    private var isSmall: Bool { bounds.width < 800 }

    /// One line describing the geometry, logged at each start and read by the preview tool.
    @objc public var diagnostics: String {
        let screen = window?.screen
        return "bounds=\(bounds.size) window=\(window?.frame.size ?? .zero) screen=\(screen?.localizedName ?? hostedScreen.map { "\($0.localizedName) (by size)" } ?? "nil") "
            + "scale=\(displayScale) windowScale=\(window?.backingScaleFactor ?? 0) fps=\(Int((1 / animationTimeInterval).rounded())) "
            + "surface=\(surfaces.first.map { "\($0.texture.width)x\($0.texture.height)" } ?? "none")"
    }

    private func prepareIfNeeded() {
        guard running, renderer == nil, !preparing else { return }
        let w = Int(bounds.width * displayScale), h = Int(bounds.height * displayScale)
        guard w > 0, h > 0 else { return }
        guard let device = MTLCreateSystemDefaultDevice(), let url = HavbunnView.shaderURL else {
            saverLog.error("no Metal device or shader source")
            return
        }
        self.device = device
        preparing = true
        let seed = UInt64.random(in: 1...UInt64.max)
        // Captions are unreadable at preview size.
        let names = Settings.captionLanguage != 0 && !isSmall
        let english = Settings.englishNames
        // Shader compile, atlas and terrain bake take a fraction of a second; keep them off the main thread.
        Task { [weak self] in
            let built = await Task.detached(priority: .userInitiated) { () -> Renderer? in
                do {
                    let r = try Renderer(device: device, shaderSource: url, seed: seed)
                    r.showNames = names
                    r.english = english
                    r.prepare(width: w, height: h)
                    return r
                } catch {
                    saverLog.error("renderer setup failed: \(String(describing: error), privacy: .public)")
                    return nil
                }
            }.value
            guard let self, self.preparing, let built else {
                built?.tearDown()
                self?.preparing = false
                return
            }
            self.renderer = built
            self.preparing = false
            self.lastTime = 0
        }
    }

    public override func animateOneFrame() {
        super.animateOneFrame()
        guard running else { return }
        let scale = displayScale
        let w = Int(bounds.width * scale), h = Int(bounds.height * scale)
        if bounds != loggedBounds {
            loggedBounds = bounds
            // On a display whose scale differs from the host's, the host keeps up with full
            // updates at 30 fps but at 60 refreshes only a quarter of the display live.
            animationTimeInterval = scale == (window?.backingScaleFactor ?? scale) ? 1.0 / 60.0 : 1.0 / 30.0
            saverLog.notice("geometry #\(self.instanceID, privacy: .public) \(self.diagnostics, privacy: .public)")
        }
        guard w > 0, h > 0 else { return }
        guard let r = renderer, r.isPrepared else {
            prepareIfNeeded()
            return
        }
        // The seabed is baked for one aspect ratio, so a late resize needs a new bake.
        if abs(r.preparedAspect - Float(w) / Float(h)) > 0.02 {
            renderer = nil
            r.tearDown()
            prepareIfNeeded()
            return
        }

        let now = CACurrentMediaTime()
        report(now)
        let dt = lastTime == 0 ? 1.0 / 60.0 : now - lastTime
        lastTime = now

        if surfaces.first.map({ $0.texture.width != w || $0.texture.height != h }) ?? true {
            surfaces = makeSurfaces(width: w, height: h)
            nextSurface = 0
        }
        guard !surfaces.isEmpty else { return }
        let frame = surfaces[nextSurface]
        nextSurface = (nextSurface + 1) % surfaces.count

        autoreleasepool {
            let waitStart = CACurrentMediaTime()
            var drew = false
            r.draw(to: frame.texture, dt: dt) { cmd in
                cmd.commit()
                // The layer must not show a surface the GPU is still writing.
                cmd.waitUntilCompleted()
                drew = true
            }
            let wait = CACurrentMediaTime() - waitStart
            waitTotal += wait
            waitMax = max(waitMax, wait)
            guard drew else { return }
            surfaceLayer.publish(frame.surface)
            surfaceLayer.setNeedsDisplay()
            framesPresented += 1
            reportFrames += 1
        }
    }

    /// Three surfaces, so the one on screen is never the one being drawn.
    private func makeSurfaces(width: Int, height: Int) -> [(surface: IOSurface, texture: MTLTexture)] {
        guard let device, width > 0, height > 0 else { return [] }
        let srgb = CGColorSpace(name: CGColorSpace.sRGB)?.copyPropertyList()
        return (0..<3).compactMap { _ in
            guard let surface = IOSurface(properties: [
                .width: width, .height: height, .bytesPerElement: 4,
                .pixelFormat: UInt32(0x42475241),  // 'BGRA', matching Renderer.pixelFormat
            ]) else { return nil }
            if let srgb { IOSurfaceSetValue(surface, kIOSurfaceColorSpace, srgb) }
            let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Renderer.pixelFormat, width: width, height: height, mipmapped: false)
            td.usage = [.renderTarget]
            td.storageMode = .shared
            guard let texture = device.makeTexture(descriptor: td, iosurface: surface, plane: 0) else { return nil }
            return (surface, texture)
        }
    }

    private func report(_ now: CFTimeInterval) {
        if reportAt == 0 { reportAt = now }
        let span = now - reportAt
        guard span >= 5 else { return }
        saverLog.debug("perf #\(self.instanceID, privacy: .public) fps=\(Int(Double(self.reportFrames) / span), privacy: .public) gpuWaitAvgMs=\(Int(self.waitTotal / max(1, Double(self.reportFrames)) * 1000), privacy: .public) gpuWaitMaxMs=\(Int(self.waitMax * 1000), privacy: .public)")
        reportAt = now
        reportFrames = 0
        waitTotal = 0
        waitMax = 0
    }

    public override func draw(_ rect: NSRect) {}
}
