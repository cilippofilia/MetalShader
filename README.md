# MetalShaderTest

A compact SwiftUI + Metal playground with two real-time effects:
- A full-screen animated "curtains" background.
- A Siri-like glowing border overlay.

Everything is configurable live from a settings sheet, and settings are persisted between launches.

## Quick Start

1. Open `MetalShaderTest.xcodeproj` in Xcode.
2. Select an iOS simulator or device.
3. Run the `MetalShaderTest` scheme.

## What You See On Screen

- Background: rendered by Metal (`CurtainsRenderer`).
- Halo border: optional transparent Metal overlay (`SiriHaloRenderer`).
- FPS label: shows current background renderer frame rate.
- Controls:
  - Top-right button opens the personalization sheet.
  - Bottom segmented picker switches background style/palette.

## Architecture

### UI Layer (SwiftUI)

- `MetalShaderTest/MetalShaderTestApp.swift`: app entry point.
- `MetalShaderTest/ContentView.swift`: composes the scene and binds settings/state.

### Rendering Layer (Metal)

- Background:
  - `MetalShaderTest/Background/CurtainsBackgroundView.swift`: `UIViewRepresentable` wrapper around `MTKView`.
  - `MetalShaderTest/Background/CurtainsRenderer.swift`: render loop + inline Metal shader.
  - `MetalShaderTest/Background/BackgroundStyle.swift`: style presets and palette interpolation.
- Halo:
  - `MetalShaderTest/Halo/SiriHaloBorderView.swift`: transparent `MTKView` overlay.
  - `MetalShaderTest/Halo/SiriHaloRenderer.swift`: halo shader + blend setup.

### Settings Layer

- `MetalShaderTest/Settings/ViewPersonalizationSettings.swift`: codable model for user-tunable parameters.
- `ContentView` persists this model in `@AppStorage("viewPersonalizationSettingsData")`.

## Frame Pipeline (Background)

For each frame:
1. `CurtainsRenderer.draw(in:)` reads time + current settings.
2. Touch position is smoothed (`touchFollowSpeed`) before sending to shader.
3. Style transition progress is computed (with easing).
4. Uniforms are uploaded to the fragment shader.
5. A full-screen triangle is drawn; the shader computes final pixel color.

## Shader Responsibilities

- `CurtainsRenderer` shader:
  - Blends from one color palette to another.
  - Applies a sine wave distortion to the vertical gradient.
  - Adds touch-driven glow near the current touch UV.
- `SiriHaloRenderer` shader:
  - Builds a rounded-rectangle distance field.
  - Creates layered glow bands (core/mid/mist).
  - Animates hue and pulse over time.

## Settings Guide

### Halo
- `cornerRadius`, `edgeInset`: border shape/layout.
- `coreWidth`, `glowWidth`, `mistWidth`: thickness of glow layers.
- `haloStrength`: overall visibility.
- `pulseBase`, `pulseAmount`, `pulseSpeed`: breathing animation.
- `colorShiftSpeed`: speed of hue rotation.

### Background
- `waveAmplitude`, `waveFrequency`, `waveSpeed`: curtain motion.
- `touchGlowRadius`, `touchGlowIntensity`: touch light behavior.
- `touchFollowSpeed`: smoothing of touch movement.
- `softGlowEnabled`: master switch for glow contribution.

## Common Customizations

- Add a new theme:
  - Add a new case in `BackgroundStyle`.
  - Return a new `BackgroundPalette` in `palette`.
- Change default visual tuning:
  - Update default values in `HaloEffectSettings` / `BackgroundEffectSettings`.
- Redesign visual logic:
  - Edit `shaderSource` in `CurtainsRenderer` and/or `SiriHaloRenderer`.

## Implementation Notes

- Shader source is embedded as Swift multiline strings and compiled at runtime.
- `MTKView` runs continuously (`isPaused = false`) at up to `min(120, device max FPS)`.
- Halo overlay uses alpha blending and a transparent clear color, so only glow pixels are visible.
