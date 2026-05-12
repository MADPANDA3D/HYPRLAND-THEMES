# HYPRLAND-THEMES

MADPANDA3D Hyprland theme collection.

## One-Command Install

For a fresh EndeavourOS or Arch-like Hyprland system:

```bash
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash
```

The bootstrap installs prerequisites, installs official HyDE if it is missing,
imports `MADPANDA Dark Zen`, detects laptop versus desktop, and runs the theme
installer with the matching profile.

The guided Dark Zen installer asks before applying user-sensitive options such
as keybindings, dictation backend, SDDM, Plymouth, RGB, high-res wallpapers, and
animated wallpapers. The `laptop-light` profile keeps static standard wallpapers
and disables RGB/high-res/animated wallpaper tiers by default.

Useful options:

```bash
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --profile laptop-light
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --profile desktop
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --dry-run
```

Do not run the bootstrap with `sudo`; HyDE must run as the normal user.

## Restore Helpers

Once Dark Zen is installed, local safety helpers are available:

```bash
mad-system-safety status
mad-system-safety snapshot "before risky change"
mad-system-safety export-manifest
```

USB/offline artifacts for travel installs are planned as a later package. For
now the public curl path is the supported bootstrap.
