# HYPRLAND-THEMES

MADPANDA3D Hyprland theme collection.

## One-Command Install

For a fresh EndeavourOS or Arch-like Hyprland system:

```bash
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash
```

The bootstrap installs prerequisites and official HyDE first. If HyDE was just
installed, it writes a one-shot Hyprland resume hook, asks for reboot, then
continues after the next login before applying `MADPANDA Dark Zen`.

The guided Dark Zen installer asks before applying user-sensitive options such
as workstation packages, Eww vs Waybar, keybindings, dictation backend, SDDM,
Plymouth, RGB, high-res wallpapers, and animated wallpapers. The `laptop-light`
profile keeps static standard wallpapers, disables RGB/high-res/animated
wallpaper tiers by default, and compacts the Eww runtime for smaller laptop
panels.

The workstation package option installs the apps and helpers expected by Dark
Zen shortcuts, including Chrome/Chromium, VS Code, Kitty, Dolphin, screenshot
helpers, recording, dictation, Eww/Waybar, docks, and media controls.

Useful options:

```bash
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --profile laptop-light
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --profile desktop
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --dry-run
```

Do not run the bootstrap with `sudo`; HyDE must run as the normal user.

For USB/offline installs, open `Install MADPANDA Dark Zen.desktop` or run:

```bash
./install-dark-zen.sh --profile laptop-light
```

The package includes the required GTK, icon, and cursor archives under
`MADPANDA Dark Zen/Source/` so fresh machines do not need a pre-existing Bad
Blood theme cache.

## Restore Helpers

Once Dark Zen is installed, local safety helpers are available:

```bash
mad-system-safety status
mad-system-safety snapshot "before risky change"
mad-system-safety export-manifest
```

The installer writes evidence under
`~/.local/state/madpanda/dark-zen-install/`.
