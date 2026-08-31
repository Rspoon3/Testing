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
| 5 | ARView | The Medium article's `UIViewRepresentable` + USDZ | Works, but duller and needs heavy assets. |

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
- Apple's AR Quick Look gallery has no medal or badge, and every free medal USDZ
  found required an account. The teapot and baseball are stand-ins that exercise
  the real `ModelEntity(named:)` path.

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
- The generated cylinder's silhouette is faintly faceted at large sizes.
  `MeshResource(extruding:)` over a circular path would give a smooth, chamfered
  coin in one mesh.
- Nothing here is wired to real data; badges are hardcoded samples.
