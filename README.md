# MetalShader: Real-time SwiftUI and Metal shader playground

## About

MetalShader is an iOS SwiftUI demo app for experimenting with live Metal-rendered visuals. The app combines a full-screen animated background with an optional Siri-style halo overlay, then exposes the visual parameters through an in-app settings sheet so you can tune the effect in real time.

All personalization settings are persisted across launches, which makes the project useful both as a shader playground and as a reference for wiring Metal rendering into a SwiftUI app.

## Features

### Visuals

- Full-screen animated background rendered by `CurtainsRenderer`
- Optional transparent halo border rendered by `SiriHaloRenderer`
- Touch-driven glow with smoothing, inertia, and wall-bounce behavior
- Live animation updates as settings change

### Personalization

- Settings sheet for halo and background tuning
- Persisted settings stored through `@AppStorage` as encoded JSON
- Separate settings models for halo and background effects
- Automatic save coalescing to avoid writing on every slider tick

### Runtime Behavior

- FPS tracking surfaced from the background renderer
- Reduced preferred frame rate while the settings sheet is open
- Runtime shader compilation from bundled `.metal` sources

## Requirements

- Xcode 26 or later
- iOS 26.0+

The checked-in Xcode project currently uses iOS 26.0 deployment settings for the app target.

## Getting Started

1. Open the project in Xcode:

```bash
open MetalShader.xcodeproj
```

2. Select the `MetalShader` scheme.

3. Choose an iPhone simulator or device.

4. Build and run.

## Demos

- [Halo demo](examples/halo.mov)
- [Soft glow background demo](examples/softGlow.mov)
- [Additional recording](examples/Untitled.mov)

## Project Structure

```text
MetalShader/
├── MetalShader/
│   ├── Background/
│   ├── Halo/
│   ├── Settings/
│   ├── Assets.xcassets/
│   ├── ContentView.swift
│   ├── MetalShaderTestApp.swift
│   ├── Shared.metal
│   └── Fullscreen.metal
├── examples/
└── MetalShader.xcodeproj
```

Key files:

- `MetalShader/ContentView.swift` wires the background, halo overlay, settings sheet, FPS state, and persistence.
- `MetalShader/Background/CurtainsBackgroundView.swift` and `MetalShader/Background/CurtainsRenderer.swift` drive the background effect.
- `MetalShader/Halo/SiriHaloBorderView.swift` and `MetalShader/Halo/SiriHaloRenderer.swift` drive the transparent halo overlay.
- `MetalShader/Settings/ViewPersonalizationSettings.swift` defines the codable settings models for the app.
- `MetalShader/Settings/SettingsSheetView.swift` exposes the tuning UI.

## Settings Overview

Halo controls include:

- visibility
- corner radius and edge inset
- wave inset, amplitude, count, and speed controls
- core, glow, and mist widths
- strength, pulse base, pulse amount, and pulse speed
- color shift speed

Background controls include:

- soft glow enablement
- custom base color
- wave amplitude, frequency, and speed
- touch glow radius and intensity
- touch follow smoothing
- inertia strength and damping

## Development Notes

- The root app entry point is `MetalShader/MetalShaderTestApp.swift`.
- Settings are encoded from `ViewPersonalizationSettings` and persisted through `@AppStorage`.
- Save operations are debounced with a short async delay to reduce churn during slider drags.
- The halo overlay is rendered in a separate transparent `MTKView` layered above the background.
- Shader sources live in bundled `.metal` files rather than inline strings.
