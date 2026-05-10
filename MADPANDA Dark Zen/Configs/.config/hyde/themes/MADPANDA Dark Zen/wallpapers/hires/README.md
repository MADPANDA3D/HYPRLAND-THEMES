# Dark Zen Wallpaper Tiers

The canonical wallpaper IDs are the 22 PNG files in `wallpapers/`.

Generated tiers:

- `landscape/NN.png`: local 4K landscape upscale, `3840x2160`.
- `portrait/NN.png`: local portrait crop, `2160x3840`, generated from the 4K landscape source.

Portrait crop policy:

- Keep the central figure, helmet, face, weapon, or silhouette visible.
- Prefer the crop that reads best on a vertical monitor over a mechanically centered crop.
- Use the standard landscape wallpaper as fallback if a high-res or portrait asset is missing.

Current portrait crop map:

```text
04 X1800  05 X1800  07 C      09 C      10 X1800  12 C
14 C      15 C      16 C      17 X1800  18 X1800  19 X1800
20 X1800  21 C      22 C      23 R      24 C      25 C
26 C      27 C      28 X700   29 C
```

`C` means center crop from the 4K landscape source. `R` means right crop.
`XNNNN` means a manually chosen crop offset in pixels from the 4K landscape
source, used to keep the intended character/focal point centered.
