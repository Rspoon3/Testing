# Features

## Badge 3D Effects Spike (`spike/badge-3d-effects`)

Five ways to render an Apple Fitness-style spinning badge, one per tab, all on
identical artwork so the only variable is the rendering technique. Built to decide
how SyncStairs should draw landmark badges ("you climbed the Empire State Building
×8").

Every tab shares the same badge model, palette, artwork, reverse face, spin gesture
and release momentum. Drag to spin; on a device, tilting also moves the highlight.

| # | Tab | Technique | Verdict |
|---|-----|-----------|---------|
| 1 | Flat | `rotation3DEffect` + masked gradient sheen | **Ship this for grids.** Reads as struck metal, costs nothing. |
| 2 | Glass | iOS 26 `.glassEffect(.regular.interactive())` | **Rejected.** Detaches from rotated content past ~30°. |
| 3 | Shader | Stitchable Metal `layerEffect` faking IBL | Best flat option. Machined metal, grid-safe. |
| 4 | RealityView | Generated geometry + procedural IBL | **Ship this for detail screens.** The only real silhouette. |
| 5 | ARView | The Medium article's `UIViewRepresentable` + a generated badge USDZ | Works, but duller and one file per finish. |

### Findings

- **No USDZ needed for real 3D.** A `generateCylinder` rim plus two textured
  `generatePlane` quads builds a medallion from the same 2D art the flat tabs use.
  The faces are SwiftUI views rasterized with `ImageRenderer`.
- **Image-based lighting is the whole ballgame.** A metallic PBR material with
  nothing to reflect renders near-black. `EnvironmentResource(equirectangular:)`
  accepts a runtime-drawn `CGImage`, so the studio lighting is generated in code —
  no HDR asset. First render came back a dim olive purely because the panorama was
  too dark to be worth reflecting.
- **Keep the light rig and the badge on separate entities.** The medallion's
  rotation sweeps reflections across it; the rig's rotation (driven by CoreMotion)
  slides highlights while the badge is still. Putting the
  `ImageBasedLightComponent` on the badge itself makes the environment travel with
  it, which cancels the sweep and makes reflections look like decals.
- **Liquid Glass does not survive `rotation3DEffect`.** The material resolves
  against the window, not the rotated content, so it visibly slides off the
  artwork. Fine face-on, unusable for a badge that turns.
- **Design canvas, not fixed point sizes.** The faces use fixed-size type, so
  rendering them into a 1024px texture halved the artwork's apparent scale.
  `badgeCanvas(scaledTo:)` lays out at a fixed 300pt and scales, keeping texture
  resolution and artwork proportion independent.
- **Fit models by bounds, not magic numbers.** The article's `scale *= 1.6` has to
  be retuned per asset. Measuring `visualBounds` and normalizing means any USDZ
  frames correctly. Centre the offset on a child and rotate the parent, or the
  model orbits instead of spinning.
- **Real USDZ assets are heavy.** Apple's sample teapot is 9MB and the baseball is
  10.5MB, against the article's own "1–5MB" advice. Five badges would be ~50MB.
- **The badge USDZ is generated, not downloaded.** The article's `rozet.usdz` is
  not public, Apple's AR Quick Look gallery has no medal, and every free medal USDZ
  found needed an account. `Tools/make-badge-usdz.py` authors the geometry in USDA
  and wraps it around the artwork `ArtworkExporter` dumps from the live SwiftUI
  views, then packages it with `/usr/bin/usdzip`. So the USDZ and the on-screen
  badge cannot drift apart, and approach 5 loads a real *badge* through the real
  `ModelEntity(named:)` path rather than displaying a stand-in object.
- **A USDZ bakes its textures in, so it is one file per design.** 1.9MB for the gold
  finish; four finishes would be four files and ~7.6MB. Approach 4 builds all four
  at runtime from one set of SwiftUI views. That asymmetry, not the visual quality,
  is the strongest argument against shipping USDZ badges.
- **The article's `-90°` yaw fix is a property of its asset, not of the technique.**
  The generated medallion is authored facing +z and needs no correction; applying
  the article's constant turns it edge-on. It belongs beside the asset.
- `usdzip --arkitAsset <layer>` is the mode that embeds dependencies. Passing the
  layer positionally with `-r` produced a 60KB package with the PNGs silently left
  out, which loads as an untextured grey coin — the script now fails on a
  suspiciously small output. Its `-c` compliance check dies with SIGBUS on this
  input, so it is skipped.
- Authoring the disc at 128 segments removes the faceting that
  `MeshResource.generateCylinder` shows at full-screen size.

### Regenerating the badge USDZ

```bash
# 1. Dump the artwork from the live SwiftUI views.
xcrun simctl launch <device> com.rspoon3.TestDrive -exportBadgeArtwork 1
CONTAINER=$(xcrun simctl get_app_container <device> com.rspoon3.TestDrive data)

# 2. Author the geometry and package it.
python3 Tools/make-badge-usdz.py "$CONTAINER/Documents" \
    TestDrive/BadgeSpike/ArticleARView/Models/badge_medallion.usdz --finish gold
```

### Evaluating

`-badgeTab` and `-badgeAngle` launch arguments (DEBUG only) open a chosen tab at a
frozen angle, which is how the comparison screenshots were captured:

```bash
xcrun simctl launch <device> com.rspoon3.TestDrive -badgeTab realityView -badgeAngle 55
```

Angles worth looking at: `0` (face), `55` (edge), `180` (reverse, with the earned
date).

### Not covered

- CoreMotion tilt is untested — the simulator has no gyroscope, so the tabs fall
  back to a slow automatic drift. Needs a device.
- Approach 4's runtime cylinder is still faintly faceted at large sizes (the USDZ
  in approach 5 is not, being authored at 128 segments). `MeshResource(extruding:)`
  over a circular path would fix it in one mesh.
- Only the gold finish is baked to USDZ. The other three fall back to the
  procedural medallion in approach 5, which demonstrates the one-file-per-design
  cost rather than hiding it.
- Nothing here is wired to real data; badges are hardcoded samples.
