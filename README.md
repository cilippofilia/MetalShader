# MetalShaderTest

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
- Persisted personalization via `@AppStorage`.
- FPS readout for quick shader tuning feedback.

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
- Core/glow/mist widths.
- Strength, pulse base/amount/speed.
- Color shift speed.

Background controls include:
- Soft glow toggle.
- Custom base color.
- Wave amplitude/frequency/speed.
- Touch glow radius/intensity.
- Touch follow smoothing.

## Performance Notes

- Setting changes update the shaders immediately.
- Settings persistence is debounced to avoid writing on every slider tick.
- Renderer FPS is reduced while the sheet is open to improve interaction smoothness.
- Shaders are embedded as Swift multiline strings and compiled at runtime.
