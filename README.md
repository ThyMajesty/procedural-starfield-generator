# Procedural Starfield Generator

A GPU-accelerated tool for generating tileable(questionable) starfield/nebula textures in Godot 4, driven by compute shaders. Built for producing high-resolution flat sky textures with control over star distribution, brightness, color, and nebula appearance.

## Features

- **GPU compute pipeline** — nebula and star generation run on the GPU via compute shaders.
- **Star generation**
  - Density-weighted placement via Perlin noise, with adjustable clumping bias
  - Magnitude-style brightness distribution (power curve, skews toward dim stars)
  - Independent size control with rare "giant star" population (separate roll + size multiplier)
  - Optional color temperature variation (warm/blue-white/neutral)
  - Additive light blending — stars brighten the sky, never darken it
- **Nebula generation**
  - Multi-stop color gradient (potentially arbitrary number of nebula colors + background)
  - Density-noise "patch" distribution so colors cluster into distinct regions instead of blending uniformly
  - TODO: Domain warp (stretch-based) for organic distortion
  - TODO: Curl noise for rotational swirl/eddy effects
  - All fields independently seeded, scaled, and octave-controlled
- **Live preview** — pan/zoom via SubViewport + Camera2D, decoupled from generation resolution
- **Auto-generated settings UI** — driven by a config array, built at runtime using [ui_widget](https://github.com/ThyMajesty/ui_widget)
- **PNG export** via native file dialog

## Preview

¯\_(ツ)_/¯

## Requirements

- Godot 4.x
- GPU with compute shader support (developed against GTX 1080)
- [ui_widget](https://github.com/ThyMajesty/ui_widget) plugin (see Setup)

## Setup

1. Clone the repo
2. Init submodules (symlinked into a proper folder layout)
3. Enable the `ui_widget` plugin in Project Settings → Plugins
4. Open the main scene, hit Generate

## Architecture

- `main.gd` — settings state, widget auto-generation, RenderingDevice orchestration
- `shaders/compute/nebula.glsl` — background + nebula gradient, patch distribution, domain warp, curl swirl
- `shaders/compute/stars_generate.glsl` — GPU-side star generation with atomic-counter compaction into a storage buffer
- `shaders/compute/stars.glsl` — additive star blitting onto the shared output image
- `shaders/compute/libs/FastNoiseLite.glsl` — GLSL port of FastNoiseLite, from [FastNoiseLite](https://github.com/Auburn/FastNoiseLite/tree/master/GLSL)

Generation pipeline per `generate()` call:
1. Nebula pass writes background + nebula gradient into a shared `image2D`
2. Star generation pass (atomic-counter compaction) produces a compacted star buffer
3. Star blit pass reads the star buffer, additively blends onto the same image
4. Final image read back to CPU, converted to `Texture2D` for preview / PNG export

## TODO

- [ ] Trig-based domain turbulence (From [Protean Clouds](https://www.shadertoy.com/view/3l23Rh) iterative `sin`/`cos` warp) as an alternative/supplement to curl noise
- [ ] Verify curl noise `eps` scaling — should track `curl_scale`'s actual noise period, not a fixed pixel value
- [ ] Consider blending curl + stretch-warp + trig-turbulence with individual weight knobs instead of a flat sum
- [ ] Multi-octave domain warp (warp the warp) for more layered turbulence
- [ ] Investigate whether visibility field (`n`) should also be warped, not just the color-sample field
- [ ] Look into vortex-center-based swirl (explicit seed-derived rotation points) as an art-directable alternative to curl
- [ ] Nebula color count currently capped at 5 flat widget slots — need to be reimplemented to dynamically build and wire colors array
- [ ] Refine UI scaling
- [ ] Revisit overall structure; Divide into proper classes