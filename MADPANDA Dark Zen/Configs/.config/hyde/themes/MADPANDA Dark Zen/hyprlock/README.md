# Hyprlock

MADPANDA Dark Zen uses a theme-owned transparent widget lock path through
`mad-lock-session`.

At lock start, `mad-lock-session` plays the lock sound immediately, hides
normal tiled windows in place, preserves animated/high-res `awww` wallpaper
tiers, and starts Hyprlock with the transparent media/weather widget layout.
Legacy standard wallpapers can still swap to matching static doubles under
`wallpapers/lock-screen/`. On unlock it restores the original per-output
wallpapers and window properties.

The active widget layout keeps native Hyprlock background blur disabled. The
blurred look comes from the temporary wallpaper doubles plus the gunmetal
transparent veil, which avoids the previous black-background widget failure.

`MADPANDA-Dark-Zen-widgets-preview.conf` remains a separate preview layout for
manual widget experiments. It reads only prebuilt cache files through
`mad-lock-widgets` and is launched with `mad-lock-preview-widgets`.

The packaged `hyprlock/dark-zen-lock.png` remains as a static fallback asset.
