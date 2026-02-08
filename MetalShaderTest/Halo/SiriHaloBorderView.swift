//
//  SiriHaloBorderView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 08/02/2026.
//

import MetalKit
import SwiftUI

/// Transparent Metal overlay that renders the Siri-style animated halo border.
struct SiriHaloBorderView: UIViewRepresentable {
    let settings: HaloEffectSettings

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView()
        }

        let view = MTKView(frame: .zero, device: device)
        // Transparent surface so only halo pixels appear over the background.
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = min(60, 120)
        view.enableSetNeedsDisplay = false
        view.isPaused = false

        let renderer = SiriHaloRenderer(device: device)
        renderer?.apply(settings: settings)
        context.coordinator.renderer = renderer
        view.delegate = renderer
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Settings are pushed every SwiftUI update for immediate visual feedback.
        context.coordinator.renderer?.apply(settings: settings)
    }

    /// Holds the renderer instance across SwiftUI view updates.
    final class Coordinator {
        var renderer: SiriHaloRenderer?
    }
}
