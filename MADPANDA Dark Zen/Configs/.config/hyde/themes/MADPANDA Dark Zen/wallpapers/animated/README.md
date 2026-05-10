# Dark Zen Animated Wallpaper Pilots

`landscape/18.gif` is the regular animated wallpaper pilot.
`portrait/18.gif` is the regular vertical animated wallpaper pilot.
`hires/landscape/18.gif` is the high-res animated wallpaper pilot.
`hires/portrait/18.gif` is the high-res vertical animated wallpaper pilot.

Both are six-second VEO 3.1 Fast loops generated from matching start/end
frames. The regular landscape pilot is an opaque `1280x720`, 20 FPS GIF. The
regular portrait pilot is an opaque `720x1280`, 20 FPS GIF. The high-res
landscape pilot is an opaque `2560x1440`, 24 FPS GIF. The high-res portrait
pilot is an opaque `1440x2560`, 24 FPS GIF and is selected on vertical outputs
when animated, high-res, and vertical wallpaper features are enabled.

Portrait pilots are FFmpeg crops from the accepted VEO MP4, not regenerated
videos. For `18.gif`, the portrait crop uses source crop `608:1080:900:0`,
which matches the corrected static portrait focal rule and keeps Vader centered.
SDDM keeps the landscape animated background; portrait animated assets are for
desktop and lock preservation.

The animation uses a locked camera and background-only ambient motion: drifting
leaves, subtle sky/atmosphere movement, soft light flicker, and light cape
movement.

Do not re-optimize this pilot with ImageMagick. The accepted conversion path
uses FFmpeg palette generation with transparent palette entries disabled and
transparent-difference GIF optimization disabled; otherwise some viewers can
show checkerboard artifacts instead of the image.

Prompt method:

```text
Animate this image as a seamless looping animated wallpaper. Keep the camera
locked with no zoom, no pan, and no scene change. Preserve the original
composition and character exactly. Only add subtle ambient motion: leaves
drifting gently, sky and background atmosphere moving slightly, soft light
flicker, and the character's cape moving lightly in the wind. The first and
last frame should look nearly identical so the animation can repeat smoothly
without looking like it restarts.

no camera movement, no zoom, no pan, no scene cut, no new characters, no
walking, no fighting, no large body movement, no face change, no pose change,
no style change, no flickering jump, no sudden motion
```

Plymouth animation is follow-up work after the desktop and SDDM pilot paths are
accepted.
