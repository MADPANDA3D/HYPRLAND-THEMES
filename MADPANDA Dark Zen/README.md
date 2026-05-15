# MADPANDA Dark Zen

MADPANDA Dark Zen is a HyDE theme package with a fan-made dark feudal Empire
visual identity. The theme is open source and non-monetized.

## Install

```bash
hydectl theme import --name "MADPANDA Dark Zen" --url "$(pwd)"
```

Or run the guided installer from the packaged theme directory:

```bash
~/.config/hyde/themes/MADPANDA Dark Zen/install.sh
```

The HyDE-compatible theme files live under:

```text
Configs/.config/hyde/themes/MADPANDA Dark Zen
```

Fresh installs also use the package-root `Source/` directory for GTK, icon,
and cursor archives.

HyDE also reads the package-root `restore_cfg.lst` during theme import. That
file is generated with the same seven core restore entries used by official
HyDE gallery themes.

The guided installer can also install the workstation package set expected by
the bundled shortcuts: Chrome/Chromium, VS Code, Kitty, Dolphin, screenshot,
recording, dictation, Eww/Waybar, dock, media, and theme helper packages.

MADPANDA helper features such as RGB, sounds, lock identity, notifications,
terminal stickers, and tile-close effects are declared by `theme.json`.
Helpers must skip unsupported features if a dependency is missing.
