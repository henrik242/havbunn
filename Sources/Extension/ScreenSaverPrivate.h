// Classes a screen saver app extension subclasses. ScreenSaver.framework exports them, and
// Apple's own savers in /System/Library/ExtensionKit/Extensions use them, but the public
// headers do not declare them. Worked out by the AppexSaverMinimal sample
// (github.com/AerialScreensaver/AppexSaverMinimal, MIT). Undocumented: any macOS release
// may change them.

#import <ScreenSaver/ScreenSaver.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// NSExtensionPrincipalClass. Created per request; Apple's savers override only init.
@interface ScreenSaverExtension : NSObject
- (instancetype)init;
@end

/// ScreenSaverViewControllerClass: provides the saver's view, one per display.
@interface ScreenSaverViewController : NSViewController
- (void)startAnimation;
- (void)stopAnimation;
@end

/// ScreenSaverConfigurationSheetViewControllerClass: the Options sheet in System Settings.
@interface ScreenSaverConfigurationViewController : NSViewController
/// Called before the sheet shows; refresh controls from the stored settings.
- (void)configureSheetWillPresent;
/// Closes the sheet, which belongs to System Settings.
- (void)configureSheetDidEnd;
@end

NS_ASSUME_NONNULL_END
