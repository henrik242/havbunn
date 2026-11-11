# Havbunn

A native macOS screen saver showing a Norwegian fjord seabed. Everything is drawn
procedurally with Metal and Core Graphics, so there are no image assets. Each start
generates a new seabed.

## Build and install

Needs Xcode and macOS 27 on Apple Silicon. No other dependencies.

    make install      # build and copy to ~/Library/Screen Savers
    make uninstall

Then pick Havbunn in System Settings > Screen Saver. Its options set the species names:
off, automatic (Norwegian when the system language is Norwegian, otherwise English),
Norwegian or English. Latin names are always shown.

    make run          # run the built bundle in a window
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

The bundle is ad-hoc signed, which is enough on the machine that built it. To share it,
build with `SIGN_IDENTITY="Developer ID Application: ..."` and notarize.

## Downloads

Every push builds `Havbunn.saver` for Apple Silicon Macs on macOS 27 or later, attached to its GitHub Actions run as an
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
- `Sources/Saver/HavbunnView.swift`: the `ScreenSaverView`.
