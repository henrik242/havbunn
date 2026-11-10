# Havbunn

A native macOS screen saver showing a Norwegian fjord seabed. Everything is drawn
procedurally with Metal and Core Graphics, so there are no image assets. Each start
generates a new seabed.

## Build and install

Needs Xcode. No other dependencies.

    make install      # build and copy to ~/Library/Screen Savers
    make uninstall

Then pick Havbunn in System Settings > Screen Saver. Its options set the species names:
off, automatic (Norwegian when the system language is Norwegian, otherwise English),
Norwegian or English. Latin names are always shown.

    make run          # run the built bundle in a window
    make tools        # also builds build/havbunn-render, an offscreen PNG renderer

The bundle is ad-hoc signed, which is enough on the machine that built it. To share it,
build with `SIGN_IDENTITY="Developer ID Application: ..."` and notarize.

## Downloads

Every push builds a universal `Havbunn.saver`, attached to its GitHub Actions run as an
artifact. Pushing a tag like `v1.2.3` also publishes a GitHub release with the zip.

Unzip, then double-click `Havbunn.saver` or copy it to `~/Library/Screen Savers`.

Every CI build, branch or tag, is signed with the same Developer ID, checked against the
team ID, and notarized, so it installs without warnings. A release ships the exact zip its
tag build produced. CI fails if any of these repository secrets is missing:

- `MACOS_CERT_P12_BASE64`, `MACOS_CERT_PASSWORD`: the Developer ID Application certificate
  and its private key, exported as .p12 and base64-encoded
- `APPLE_TEAM_ID`: the team the signature must belong to
- `APPLE_API_KEY_P8`, `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`: an App Store Connect API
  key (the .p8 file's contents), used by `notarytool`

Local builds are ad-hoc signed. To sign locally with the same identity:

    make dist SIGN_IDENTITY="Developer ID Application: <name> (<team>)" \
        CODESIGN_FLAGS="--options runtime --timestamp"

## Known issue

On a non-Retina display next to a Retina main display, macOS's legacy screen saver host
confines live output to the bottom-left quarter of the non-Retina display. A minimal saver
using only `draw(_:)` behaves the same way, so this is the host, not Havbunn.

## The scene

A slope like the Tautra reef in Trondheimsfjord, a moraine sill where cold-water coral
grows from about 39 m. The look is fjord twilight: green water darkened by runoff, soft
diffuse light, and colours muted with depth. Kelp is sparse, as it is near its depth limit.

Animals are drawn 1.15 times life size so they read on screen.

All species are native to Norwegian waters. Names were checked against Artsdatabanken's
Artskart and WoRMS. The list, with Norwegian and Latin names, is in
`Sources/Engine/Species.swift`.

## Layout

- `Sources/Shaders/Shaders.metal`: terrain raymarch (baked once), caustics, sprite
  deformation, marine snow, light shafts. Compiled by Metal at load, so building needs
  no Metal toolchain.
- `Sources/Engine/Terrain.swift`: heightfield, shared by the raymarch and animal placement.
- `Sources/Engine/World.swift`: behaviour, schooling, placement.
- `Sources/Engine/Art*.swift`: species painting into a texture atlas.
- `Sources/Saver/HavbunnView.swift`: the `ScreenSaverView`.
