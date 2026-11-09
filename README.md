# Havbunn

A native macOS screen saver showing a Norwegian fjord seabed. Everything is drawn
procedurally with Metal and Core Graphics, so there are no image assets. Each start
generates a new seabed.

## Build and install

Needs Xcode. No other dependencies.

    make install      # build and copy to ~/Library/Screen Savers
    make uninstall

Then pick Havbunn in System Settings > Screen Saver. Its options let you turn the
species names off.

    make run          # run the built bundle in a window
    make tools        # also builds build/havbunn-render, an offscreen PNG renderer

The bundle is ad-hoc signed, which is enough on the machine that built it. To share it,
build with `SIGN_IDENTITY="Developer ID Application: ..."` and notarize.

## The scene

A slope like the Tautra reef in Trondheimsfjord, where cold-water coral grows at about
40 m, shallow enough to meet the lower edge of the kelp forest. The coral sits in
slightly more light than it would have at most reefs.

Animals are drawn 1.3 times life size so they read on screen.

All species are native to Norwegian waters. The list, with Norwegian and Latin names, is
in `Sources/Engine/Species.swift`.

## Layout

- `Sources/Shaders/Shaders.metal`: terrain raymarch (baked once), caustics, sprite
  deformation, marine snow, light shafts. Compiled by Metal at load, so building needs
  no Metal toolchain.
- `Sources/Engine/Terrain.swift`: heightfield, shared by the raymarch and animal placement.
- `Sources/Engine/World.swift`: behaviour, schooling, placement.
- `Sources/Engine/Art*.swift`: species painting into a texture atlas.
- `Sources/Saver/HavbunnView.swift`: the `ScreenSaverView`.
