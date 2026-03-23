# MetalShader

MetalShader is a small iOS SwiftUI playground for real-time Metal effects. It combines a full-screen animated background with an optional Siri-style halo overlay, then exposes both renderers through a live settings sheet so you can tune the visuals while the app is running.

It is useful as both a shader playground and a compact reference for layering Metal-backed views inside a SwiftUI app, handling touch-driven effects, and persisting visual personalization across launches.

## Demo

### Halo overlay

[examples/halo.mov](examples/halo.mov)

### Soft glow background

[examples/softGlow.mov](examples/softGlow.mov)

## What it shows

- Animated Metal background rendered in a full-screen `MTKView`
- Optional transparent halo border rendered in a second Metal layer above the background
- Touch-driven glow behavior with smoothing and inertia
- Live parameter editing from a SwiftUI sheet
- Persisted personalization stored as JSON with `@AppStorage`
- Runtime loading of bundled `.metal` shader sources

## Project structure

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

## Key files

- `MetalShader/ContentView.swift` composes the background, halo overlay, settings sheet, and persistence flow.
- `MetalShader/Background/CurtainsBackgroundView.swift` hosts the background `MTKView`.
- `MetalShader/Background/CurtainsRenderer.swift` drives the animated curtains effect, touch glow, and FPS reporting.
- `MetalShader/Halo/SiriHaloBorderView.swift` hosts the transparent halo overlay view.
- `MetalShader/Halo/SiriHaloRenderer.swift` draws the animated halo border.
- `MetalShader/Settings/SettingsSheetView.swift` exposes the live tuning UI.
- `MetalShader/Settings/ViewPersonalizationSettings.swift` defines the codable settings models used for persistence.

## Requirements

- Xcode 26 or later
- iOS 26.0 or later
- A simulator or device with Metal support

## Run locally

1. Open [`MetalShader.xcodeproj`](MetalShader.xcodeproj) in Xcode.
2. Select the `MetalShader` scheme.
3. Choose an iPhone simulator or device.
4. Build and run.

## Personalization controls

The settings sheet exposes two groups of controls:

- Halo settings for visibility, corner radius, wave shape, glow widths, pulse values, and color shift speed
- Background settings for base color, wave motion, soft glow, touch radius, follow speed, and inertia behavior

Changes are applied live and saved across launches.

## Notes

- The app entry point is `MetalShader/MetalShaderTestApp.swift`.
- The halo is rendered in a separate transparent `MTKView` layered above the background.
- Settings writes are coalesced with a short async delay to avoid saving on every slider update.
