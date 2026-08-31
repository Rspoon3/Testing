#!/usr/bin/env python3
"""Builds a badge medallion USDZ from exported badge artwork.

Approach 5 loads a USDZ through the article's `ModelEntity(named:)` path. To be a
real comparison it has to load an actual *badge*, textured with the same artwork the
other tabs draw — not a stand-in object. So the SwiftUI faces are exported to PNG by
`ArtworkExporter` and this script wraps them around authored geometry.

The mesh is three separate meshes under one Xform rather than one mesh with
GeomSubsets: front disc, back disc, and the side wall. Each then gets its own
material binding directly, which avoids subset bookkeeping for no loss.

Written with plain text USDA and packaged with /usr/bin/usdzip (ships with macOS),
so it needs no pxr Python bindings.

Usage:
    python3 Tools/make-badge-usdz.py <artwork-dir> <output.usdz> [--finish gold]
"""

import argparse
import math
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RADIUS = 0.5
THICKNESS = 0.03
# 128 gives a silhouette with no visible faceting at full-screen size, which
# `MeshResource.generateCylinder` (used by the procedural tabs) does not.
SEGMENTS = 128
# The faces are inset so the rim reads as a raised lip, matching the procedural
# medallion's proportions.
FACE_RADIUS = RADIUS - 0.015


def disc(z, normal_z, mirror_u):
    """Builds a flat disc as a triangle fan.

    Returns points, face vertex counts, indices, normals and UVs. The centre vertex
    is index 0 and rim vertices follow, so the fan is trivial to index.

    `mirror_u` flips the horizontal texture coordinate, which the reverse needs: seen
    from behind, unmirrored text reads backwards.
    """
    points = [(0.0, 0.0, z)]
    uvs = [(0.5, 0.5)]

    for i in range(SEGMENTS):
        angle = 2.0 * math.pi * i / SEGMENTS
        x = FACE_RADIUS * math.cos(angle)
        y = FACE_RADIUS * math.sin(angle)
        points.append((x, y, z))

        # USD's texture origin is bottom-left, so v increases with y.
        u = 0.5 + 0.5 * math.cos(angle) * (-1 if mirror_u else 1)
        v = 0.5 + 0.5 * math.sin(angle)
        uvs.append((u, v))

    counts = []
    indices = []
    for i in range(SEGMENTS):
        nxt = 1 + (i + 1) % SEGMENTS
        counts.append(3)
        # Wound so the triangle faces the same way as its normal.
        if normal_z > 0:
            indices += [0, 1 + i, nxt]
        else:
            indices += [0, nxt, 1 + i]

    normals = [(0.0, 0.0, float(normal_z))] * len(points)
    return points, counts, indices, normals, uvs


def rim():
    """Builds the side wall as a quad strip between the two face edges."""
    points = []
    normals = []
    uvs = []

    for i in range(SEGMENTS):
        angle = 2.0 * math.pi * i / SEGMENTS
        cos_a, sin_a = math.cos(angle), math.sin(angle)
        x, y = RADIUS * cos_a, RADIUS * sin_a
        points.append((x, y, THICKNESS / 2))
        points.append((x, y, -THICKNESS / 2))
        # Pointing straight out from the axis, so the rim catches a grazing
        # highlight as the coin turns.
        normals.append((cos_a, sin_a, 0.0))
        normals.append((cos_a, sin_a, 0.0))
        uvs.append((i / SEGMENTS, 1.0))
        uvs.append((i / SEGMENTS, 0.0))

    counts = []
    indices = []
    for i in range(SEGMENTS):
        a = 2 * i
        b = 2 * i + 1
        c = 2 * ((i + 1) % SEGMENTS) + 1
        d = 2 * ((i + 1) % SEGMENTS)
        counts.append(4)
        indices += [a, b, c, d]

    return points, counts, indices, normals, uvs


def fmt_points(values):
    return ", ".join(f"({v[0]:.6f}, {v[1]:.6f}, {v[2]:.6f})" for v in values)


def fmt_uvs(values):
    return ", ".join(f"({v[0]:.6f}, {v[1]:.6f})" for v in values)


def fmt_ints(values):
    return ", ".join(str(v) for v in values)


def mesh_block(name, geometry, material):
    points, counts, indices, normals, uvs = geometry
    return f'''
    def Mesh "{name}"
    {{
        uniform bool doubleSided = 0
        uniform token subdivisionScheme = "none"
        int[] faceVertexCounts = [{fmt_ints(counts)}]
        int[] faceVertexIndices = [{fmt_ints(indices)}]
        point3f[] points = [{fmt_points(points)}]
        normal3f[] primvars:normals = [{fmt_points(normals)}] (
            interpolation = "vertex"
        )
        texCoord2f[] primvars:st = [{fmt_uvs(uvs)}] (
            interpolation = "vertex"
        )
        rel material:binding = </Medallion/Materials/{material}>
    }}
'''


def textured_material(name, texture, metallic, roughness):
    """A UsdPreviewSurface whose base colour comes from a texture."""
    return f'''
        def Material "{name}"
        {{
            token outputs:surface.connect = </Medallion/Materials/{name}/Surface.outputs:surface>

            def Shader "Surface"
            {{
                uniform token info:id = "UsdPreviewSurface"
                color3f inputs:diffuseColor.connect = </Medallion/Materials/{name}/Texture.outputs:rgb>
                float inputs:metallic = {metallic}
                float inputs:roughness = {roughness}
                token outputs:surface
            }}

            def Shader "Texture"
            {{
                uniform token info:id = "UsdUVTexture"
                asset inputs:file = @{texture}@
                float2 inputs:st.connect = </Medallion/Materials/{name}/UVReader.outputs:result>
                token inputs:wrapS = "clamp"
                token inputs:wrapT = "clamp"
                float3 outputs:rgb
            }}

            def Shader "UVReader"
            {{
                uniform token info:id = "UsdPrimvarReader_float2"
                token inputs:varname = "st"
                float2 outputs:result
            }}
        }}
'''


def plain_material(name, color, metallic, roughness):
    """A UsdPreviewSurface with a constant base colour, for the rim."""
    r, g, b = color
    return f'''
        def Material "{name}"
        {{
            token outputs:surface.connect = </Medallion/Materials/{name}/Surface.outputs:surface>

            def Shader "Surface"
            {{
                uniform token info:id = "UsdPreviewSurface"
                color3f inputs:diffuseColor = ({r}, {g}, {b})
                float inputs:metallic = {metallic}
                float inputs:roughness = {roughness}
                token outputs:surface
            }}
        }}
'''


# Rim colours, matching BadgeFinish.rimColor on the Swift side.
RIM_COLORS = {
    "gold": (0.62, 0.42, 0.08),
    "silver": (0.42, 0.45, 0.50),
    "bronze": (0.45, 0.24, 0.11),
    "cosmic": (0.20, 0.10, 0.45),
}


def build(artwork: Path, output: Path, finish: str) -> None:
    face_png = artwork / f"{finish}-face.png"
    back_png = artwork / f"{finish}-back.png"

    for path in (face_png, back_png):
        if not path.exists():
            sys.exit(f"missing artwork: {path}")

    front = disc(THICKNESS / 2, 1, mirror_u=False)
    back = disc(-THICKNESS / 2, -1, mirror_u=True)
    side = rim()

    usda = f'''#usda 1.0
(
    defaultPrim = "Medallion"
    metersPerUnit = 1
    upAxis = "Y"
)

def Xform "Medallion"
(
    kind = "component"
)
{{
{mesh_block("Front", front, "FaceMaterial")}
{mesh_block("Back", back, "BackMaterial")}
{mesh_block("Rim", side, "RimMaterial")}
    def Scope "Materials"
    {{
{textured_material("FaceMaterial", face_png.name, 0.85, 0.25)}
{textured_material("BackMaterial", back_png.name, 0.85, 0.25)}
{plain_material("RimMaterial", RIM_COLORS[finish], 1.0, 0.15)}
    }}
}}
'''

    with tempfile.TemporaryDirectory() as tmp:
        staging = Path(tmp)
        usda_path = staging / "badge_medallion.usda"
        usda_path.write_text(usda)
        shutil.copy(face_png, staging / face_png.name)
        shutil.copy(back_png, staging / back_png.name)

        # Validates the syntax before packaging, so a malformed USDA fails here with
        # a line number rather than silently producing a USDZ that loads as nothing.
        # Output goes to a real .usda path because usdcat infers the format from the
        # extension and rejects an extensionless target such as /dev/null.
        subprocess.run(
            [
                "/usr/bin/usdcat",
                "--flatten",
                "-o",
                str(staging / "flattened.usda"),
                str(usda_path),
            ],
            check=True,
        )
        (staging / "flattened.usda").unlink()

        output.parent.mkdir(parents=True, exist_ok=True)
        if output.exists():
            output.unlink()

        # --arkitAsset, not a bare file list: it walks the layer's dependencies and
        # embeds the referenced PNGs, flattens composition and conforms the data to
        # RealityKit's expectations. Passing the files positionally instead produced a
        # 60KB package with the textures left behind, which loads as an untextured
        # grey coin.
        #
        # No -c: the compliance checker in the usdzip that ships with macOS 26 dies
        # with SIGBUS on this input. The package it produces without the flag is fine
        # and loads correctly, so the check is skipped rather than worked around.
        subprocess.run(
            [
                "/usr/bin/usdzip",
                "--arkitAsset",
                usda_path.name,
                str(output.resolve()),
            ],
            cwd=staging,
            check=True,
        )

        # Guards against the failure this replaced: passing the layer positionally
        # with -r produced a 60KB package with the textures silently left out, which
        # loads as an untextured grey coin.
        size = output.stat().st_size
        if size < 500_000:
            sys.exit(f"package is only {size} bytes — textures were probably not embedded")

    size_mb = output.stat().st_size / 1_000_000
    print(f"wrote {output} ({size_mb:.2f} MB)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artwork", type=Path, help="directory of exported PNGs")
    parser.add_argument("output", type=Path, help="destination .usdz")
    parser.add_argument("--finish", default="gold", choices=sorted(RIM_COLORS))
    args = parser.parse_args()
    build(args.artwork, args.output, args.finish)


if __name__ == "__main__":
    main()
