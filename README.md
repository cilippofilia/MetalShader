# MetalShader

SwiftUI + Metal iOS demo app with real-time shader visuals:
- Animated full-screen "curtains" background.
- Optional Siri-style glowing halo border overlay.

All visual parameters are adjustable from a settings sheet and persisted across launches.

## Quick Start

1. Open `MetalShader.xcodeproj` in Xcode.
2. Select an iOS simulator or device.
3. Run the `MetalShader` scheme.

## Features

- Live Metal-rendered background (`CurtainsRenderer`).
- Live Metal-rendered transparent halo overlay (`SiriHaloRenderer`).
- In-app settings sheet for halo and background tuning.
- Geometric halo wave animation with configurable shape/speed parameters.
- Touch-driven soft glow with inertial glide and wall-bounce behavior.
- Persisted personalization via `@AppStorage`.
- FPS readout for quick shader tuning feedback.

## Examples

### Halo Effect


https://github.com/user-attachments/assets/70f2f922-d9c8-47cb-b556-37686fe2f8aa

### Soft Glow Background

https://github.com/user-attachments/assets/41921930-2749-4b5d-a564-0d4622423b2a

## Project Structure

- `MetalShader/MetalShaderTestApp.swift`: app entry point.
- `MetalShader/ContentView.swift`: root composition, settings persistence, and sheet presentation.
- `MetalShader/Background/CurtainsBackgroundView.swift`: `MTKView` wrapper for background rendering.
- `MetalShader/Background/CurtainsRenderer.swift`: background shader + render loop.
- `MetalShader/Halo/SiriHaloBorderView.swift`: transparent `MTKView` overlay wrapper.
- `MetalShader/Halo/SiriHaloRenderer.swift`: halo shader + blend pipeline.
- `MetalShader/Settings/SettingsSheetView.swift`: personalization UI.
- `MetalShader/Settings/ViewPersonalizationSettings.swift`: codable settings model.
- `MetalShader/Settings/SliderRowView.swift`: reusable slider row component.

## Settings Overview

Halo controls include:
- Visibility, corner radius, edge inset.
- Wave inset/amplitude/count/speed controls.
- Core/glow/mist widths.
- Strength, pulse base/amount/speed.
- Color shift speed.

Background controls include:
- Soft glow toggle.
- Custom base color.
- Wave amplitude/frequency/speed.
- Touch glow radius/intensity.
- Touch follow smoothing.
- Inertia strength and damping for post-touch motion.

## Performance Notes

- Setting changes update the shaders immediately.
- Settings persistence is debounced to avoid writing on every slider tick.
- Renderer FPS is reduced while the sheet is open to improve interaction smoothness.
- Shaders are embedded as Swift multiline strings and compiled at runtime.
- Soft glow inertia reflects at screen bounds and loses energy over time.
