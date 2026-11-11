import AppKit
import IOSurface
import OpenGL.GL

/// Shows the latest rendered IOSurface through OpenGL, the way Apple's own OpenGL savers
/// draw. As the view's backing layer, the remote host composites it at each display's own
/// scale, unlike CAMetalLayer presents, contents swaps or OpenGL sublayers.
final class SurfaceGLLayer: CAOpenGLLayer {
    private let lock = NSLock()
    private var surface: IOSurface?
    private var texture: GLuint = 0

    override init() {
        super.init()
        // Redrawn on each new frame by the view, on the saver's own timer.
        isAsynchronous = false
        isOpaque = true
        needsDisplayOnBoundsChange = true
        colorspace = CGColorSpace(name: CGColorSpace.sRGB)
    }

    override init(layer: Any) { super.init(layer: layer) }
    required init?(coder: NSCoder) { fatalError("unused") }

    /// Called on the main thread once the GPU has finished writing `surface`.
    func publish(_ surface: IOSurface?) {
        lock.lock()
        self.surface = surface
        lock.unlock()
    }

    override func draw(inCGLContext ctx: CGLContextObj, pixelFormat pf: CGLPixelFormatObj,
                       forLayerTime t: CFTimeInterval, displayTime ts: UnsafePointer<CVTimeStamp>?) {
        lock.lock()
        let surface = self.surface
        lock.unlock()

        CGLSetCurrentContext(ctx)
        glClearColor(0.016, 0.1, 0.15, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        if let surface {
            let w = surface.width, h = surface.height
            let target = GLenum(GL_TEXTURE_RECTANGLE_ARB)
            if texture == 0 { glGenTextures(1, &texture) }
            glEnable(target)
            glBindTexture(target, texture)
            CGLTexImageIOSurface2D(ctx, target, GLenum(GL_RGBA), GLsizei(w), GLsizei(h),
                                   GLenum(GL_BGRA), GLenum(GL_UNSIGNED_INT_8_8_8_8_REV), surface, 0)
            glTexParameteri(target, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
            glTexParameteri(target, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
            glMatrixMode(GLenum(GL_PROJECTION)); glLoadIdentity()
            glMatrixMode(GLenum(GL_MODELVIEW)); glLoadIdentity()
            // Rectangle textures use pixel coordinates; the surface's first row is the top.
            let fw = GLfloat(w), fh = GLfloat(h)
            glBegin(GLenum(GL_QUADS))
            glTexCoord2f(0, fh); glVertex2f(-1, -1)
            glTexCoord2f(fw, fh); glVertex2f(1, -1)
            glTexCoord2f(fw, 0); glVertex2f(1, 1)
            glTexCoord2f(0, 0); glVertex2f(-1, 1)
            glEnd()
            glBindTexture(target, 0)
            glDisable(target)
        }
        super.draw(inCGLContext: ctx, pixelFormat: pf, forLayerTime: t, displayTime: ts)
    }
}
