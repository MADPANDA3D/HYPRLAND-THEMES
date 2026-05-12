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

Useful options:

```bash
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --profile laptop-light
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --profile desktop
curl -fsSL https://raw.githubusercontent.com/MADPANDA3D/HYPRLAND-THEMES/main/install.sh | bash -s -- --dry-run
```

Do not run the bootstrap with `sudo`; HyDE must run as the normal user.
