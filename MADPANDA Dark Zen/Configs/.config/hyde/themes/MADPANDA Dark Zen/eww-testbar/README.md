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

Run:

```bash
mad-eww-bar start
mad-eww-bar rollback-waybar
mad-caffeine toggle
mad-eww-testbar start
mad-eww-testbar stop
mad-eww-testbar status
```
