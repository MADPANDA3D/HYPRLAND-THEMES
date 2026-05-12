# Dark Zen Plymouth

This directory contains the first static Dark Zen Plymouth splash.

It is intentionally opt-in and rollback-first because Plymouth touches boot,
dracut, and GRUB on this EndeavourOS install.

Use:

```bash
mad-plymouth-theme status
mad-plymouth-theme apply --dry-run
mad-plymouth-theme apply
mad-plymouth-theme rollback --dry-run
mad-plymouth-theme rollback
```

The first implementation uses a static script theme with a Dark Zen logo,
progress bar, and LUKS password prompt support. Animated Plymouth is deferred
until the static boot path is proven on real reboot.
