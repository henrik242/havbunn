# Havbunn

A native macOS screen saver showing a Norwegian fjord seabed. Everything is drawn
procedurally with Metal and Core Graphics, so there are no image assets. Each start
generates a new seabed.

It ships as `Havbunn.app`, which carries the screen saver as an app extension, the way
Apple's own savers are built. Launching the app once registers it.

## Build and install

Needs Xcode and macOS 27 on Apple Silicon. No other dependencies.

    make install SIGN_IDENTITY="Developer ID Application"   # build, copy to ~/Applications, launch
    make uninstall

Then pick Havbunn in System Settings > Wallpaper, under Screen Saver. Its Options set the
species names: off, automatic (Norwegian when the system language is Norwegian, otherwise
English), Norwegian or English. Latin names are always shown.

System Settings lists an ad-hoc signed build but will not use it, so sign local builds with
a Developer ID as above. Keep only one copy registered: with several, the system may load
a stale one. `make install` unregisters the previous copy first.

    make run          # run the saver view in a window
    make tools        # build the offscreen renderer and other tools below
    make check        # confirm the scene is unchanged, after a refactor
    make golden       # accept an intended change to the scene

Tools, in `build/` after `make tools`:

- `havbunn-sprite <name|all> <out-dir>`: draws one sprite, such as `torsk` or `hummer-0`,
  to a PNG.
- `havbunn-render <Shaders.metal> <out-prefix> [--seed N] ...`: renders frames of the
  whole scene. Run it without arguments for the options.
- `havbunn-trace`: the GPU-free scene fingerprint that `make check` compares with
  `Tools/trace.golden`.

`make icon` redraws the app icon from the species sprites into
`Resources/AppAssets.xcassets`, using `Tools/icon.swift`. The PNGs are committed.

To share a build, also notarize it.

## Downloads

Every push builds `Havbunn.app` for Apple Silicon Macs on macOS 27 or later, attached to
its GitHub Actions run as an artifact. Pushing a tag like `v1.2.3` also publishes a GitHub
release with the zip.

Unzip, move `Havbunn.app` to Applications and open it once. Then pick Havbunn in System
Settings > Wallpaper, under Screen Saver. Remove any older `Havbunn.saver` from
`~/Library/Screen Savers`.

Every CI build, branch or tag, is signed with the same Developer ID, checked against the
team ID, and notarized, so it installs without warnings. CI checks the app and the
extension inside it. A release ships the exact zip its
tag build produced. CI fails if any of these repository secrets is missing:

- `MACOS_CERT_P12_BASE64`, `MACOS_CERT_PASSWORD`: the Developer ID Application certificate
  and its private key, exported as .p12 and base64-encoded
- `APPLE_TEAM_ID`: the team the signature must belong to
- `APPLE_API_KEY_P8`, `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`: an App Store Connect API
  key (the .p8 file's contents), used by `notarytool`

To build the release zip locally with the same identity:

    make dist SIGN_IDENTITY="Developer ID Application: <name> (<team>)" \
        CODESIGN_FLAGS="--options runtime --timestamp"

## Why an app extension

macOS hosts every screen saver remotely and composites it at the main display's scale. A
legacy `.saver` bundle on a display whose scale differs, such as a non-Retina display next to
a Retina main display, then updates only the bottom-left quarter of that display live, and the
rest every few seconds. No drawing method gets around that inside the legacy host.

As an app extension, Havbunn draws the way Apple's OpenGL savers (Shell, Arabesque) do:
Metal renders each frame into an IOSurface, and an OpenGL backing layer shows it. On a
display whose scale differs from the main display's, the host keeps up with that at 30 fps
but not at 60, so Havbunn runs at 30 fps there and 60 elsewhere.

The screen saver extension API is private and undocumented, so a macOS update may break
it. `Sources/Extension/ScreenSaverPrivate.h` declares the classes, as worked out by
[AppexSaverMinimal](https://github.com/AerialScreensaver/AppexSaverMinimal) (MIT).

## The scene

A slope like the Tautra reef in Trondheimsfjord, a moraine sill where cold-water coral
grows from about 39 m. The look is fjord twilight: green water darkened by runoff, soft
diffuse light, and colours muted with depth. Kelp is sparse, as it is near its depth limit.

Animals are drawn 1.15 times life size so they read on screen.

All species are native to Norwegian waters. Names were checked against Artsdatabanken's
Artskart and WoRMS. The list is in `Sources/Engine/Species.swift`, and each species has
its own file in `Sources/Engine/Species/` with its names, sprites, drawing and placement.

## Adding a species

Copy the file of a species that behaves like the new one, change the names, sprites and
`draw`, and add it to `Species.all`. The key names its main sprite, or `<key>-1` and up for
variants. The `place` closure picks a behaviour:

- `addLoners`: fish on their own, optionally keeping to a home patch (`Torsk.swift`)
- `addSchool`: a school (`Sild.swift`)
- `addRareVisitor`: a fish that now and then passes through (`Laks.swift`)
- `addJellies`: drifting jellies (`Glassmanet.swift`)
- `addWalkers`: crustaceans, with sprites `<key>-0` to `<key>-3` as the walk cycle
  (`Hummer.swift`)
- `addRester`: bottom animals that rest and now and then move (`Rodspette.swift`)
- `addFixture`, `addFlat`: rooted or still life (`Sjonellik.swift`, `Korstroll.swift`)

Every species draws from one random sequence in list order, so adding one anywhere changes
the scene of every seed. That is fine, but run `make golden` afterwards. Check the drawing
with `build/havbunn-sprite <key> out/`.

## Layout

- `Sources/Shaders/Shaders.metal`: terrain raymarch (baked once), caustics, sprite
  deformation, marine snow, light shafts. Compiled by Metal at load, so building needs
  no Metal toolchain.
- `Sources/Engine/Terrain.swift`: heightfield, shared by the raymarch and animal placement.
- `Sources/Engine/World.swift`: behaviour, schooling, and the placement calls species use.
- `Sources/Engine/Species/*.swift`: one file per species.
- `Sources/Engine/Art*.swift`: the texture atlas and drawing shared between species.
- `Sources/Saver/HavbunnView.swift`: the `ScreenSaverView`, and `SurfaceGLLayer.swift`
  the OpenGL layer that shows its frames.
- `Sources/Extension/`: the app extension's classes and the private header.
- `Sources/App/main.swift`: the app that carries the extension.
- `Resources/`: Info.plists, the extension's entitlements, the thumbnail and the app icon.
