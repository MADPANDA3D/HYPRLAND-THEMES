# SDDM

Dark Zen ships a complete SDDM theme at:

`sddm/MADPANDA-Dark-Zen/`

The theme is a Corners-derived wrapper. Runtime install does not depend on the
machine's currently active SDDM theme.

`mad-theme-pack sddm` selects the background from the active Dark Zen feature
flags. Animated wallpapers win when enabled and available, then high-res
landscape wallpapers, then the standard active wallpaper. The QML background
uses `AnimatedImage` for GIF-style backgrounds and `Image` for static assets.

When the SDDM adapter is enabled, `mad-theme-pack` copies the bundled theme to:

`/usr/share/sddm/themes/MADPANDA-Dark-Zen`

Then it updates the detected SDDM config to:

`Current=MADPANDA-Dark-Zen`

Before changing `Current=`, the helper records the previous SDDM value under
`~/.local/state/madpanda/theme-pack/sddm/`. When Dark Zen is deactivated through
the theme runtime, the previous SDDM `Current=` is restored.

If SDDM is not installed, the guided installer asks whether to install and use
SDDM as the login manager. In noninteractive mode, missing SDDM leaves this
adapter disabled.
