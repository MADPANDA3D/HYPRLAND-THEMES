# Dark Zen Eww Bar

Zenities-inspired Eww bar for Dark Zen.

The permanent helper `mad-eww-bar` syncs this directory into:

```text
$XDG_CONFIG_HOME/madpanda/eww-testbar/MADPANDA-Dark-Zen
```

`mad-eww-testbar` remains as a compatibility wrapper for visual testing.

The bar keeps power actions safe: app launch and lock are allowed, while
shutdown, reboot, suspend, and Hyprland exit only show a notification.

The layout mirrors the main Waybar information set while Dark Zen owns the
visible bar: active window title, time/date, CPU, memory, NVIDIA GPU, network,
output volume, microphone, Bluetooth, caffeine/autolock toggle, gamma, updates,
weather, clipboard, keybinds, theme picker, and wallpaper picker.

When used as the primary bar, `mad-eww-bar` opens one exclusive Eww window per
active Hyprland monitor so tiled windows reserve the same top work area they did
with Waybar.

Clicking the clock opens a focused-monitor calendar panel. `SUPER+X` toggles the
hidden right-side widget drawer with calendar, media, and Zenities-style CPU,
CPU temperature, GPU, GPU temperature, and memory meters. These widgets are
overlays and do not reserve work area.

The media card prefers normal MPRIS artwork from `playerctl`. If Chromium does
not expose Pandora artwork through MPRIS, Dark Zen can load its own minimal
`MADPANDA Pandora Media Bridge` Chrome extension via `mad-chrome-dark-zen`.
That bridge is local-only: it reads the current Pandora now-playing title,
artist, album, and album-art URL, then writes a tiny cache under
`$XDG_CACHE_HOME/madpanda/pandora-media` through the native host
`mad-pandora-native-host`. It does not store cookies, account data, or browsing
history. The downloaded third-party Pandora extension was used only as a
reference and is not bundled here. Dark Zen also installs a user-level
`google-chrome.desktop` override so normal launcher/browser-link opens route
through `mad-chrome-dark-zen`. `SUPER+E` opens a new Chrome window on the
current workspace.

Run:

```bash
mad-eww-bar start
mad-eww-widgets drawer-toggle
mad-eww-widgets calendar-toggle
mad-eww-bar rollback-waybar
mad-caffeine toggle
mad-chrome-dark-zen
mad-eww-testbar start
mad-eww-testbar stop
mad-eww-testbar status
```
