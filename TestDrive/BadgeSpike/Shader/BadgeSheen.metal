//
//  BadgeSheen.metal
//  TestDrive
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Approach 3 — a screen-space fake of image-based lighting.
//
// Samples the already-rasterized badge and adds a tilt-driven specular response:
// two sweeping highlight bands plus a Fresnel-ish rim. This is what you reach for
// when you want metal that reacts to the phone but cannot afford a renderer per
// cell.
//
// Layer samples arrive premultiplied, so every addition is scaled by alpha and
// clamped to it — otherwise the transparent surround outside the disc lights up
// as a grey square.
[[ stitchable ]] half4 badgeSheen(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 tilt,
    float spin
) {
    half4 color = layer.sample(position);
    if (color.a < 0.004h) {
        return color;
    }

    float2 uv = position / size;
    float2 centered = uv * 2.0 - 1.0;
    float radius = length(centered);

    // The highlight's position along a diagonal, pushed by tilt and spin. Both
    // inputs feed one band so the surface has a single coherent light source.
    float band = centered.x * 0.85
               + centered.y * 0.55
               - tilt.x * 1.7
               + tilt.y * 0.85
               - sin(spin) * 0.9;

    // A tight core inside a broad falloff: the tight one is the light itself, the
    // broad one is the sheen that makes it read as polished rather than wet.
    //
    // Every weight here was cut roughly 3x after the first render: at full strength
    // the specular saturated the whole disc and erased the engraving, which is the
    // failure mode to watch for when tuning this — additive light with no exposure
    // control clips fast against artwork that is already bright.
    float core = exp(-band * band * 14.0) * 0.42;
    float bloom = exp(-band * band * 1.1) * 0.10;

    // Brightening toward the rim, standing in for the grazing-angle reflectance a
    // real PBR material would compute.
    float rim = smoothstep(0.74, 0.99, radius) * 0.16;

    // Fine concentric rings, so the highlight travels over visible machining
    // instead of over a smooth gradient. Without this the metal looks like plastic.
    float machining = sin(radius * 190.0) * 0.010;

    half specular = half(core + bloom + rim + machining);
    half3 lit = color.rgb + specular * color.a;

    return half4(clamp(lit, 0.0h, color.a), color.a);
}
