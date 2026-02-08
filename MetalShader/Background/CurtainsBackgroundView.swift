//
//  CurtainsBackgroundView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import MetalKit
import SwiftUI
import UIKit

/// SwiftUI wrapper around an `MTKView` that renders the animated background.
struct CurtainsBackgroundView: UIViewRepresentable {
    @Binding var fps: Double
    let settings: BackgroundEffectSettings
    let preferredFramesPerSecond: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(fps: $fps)
    }

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView()
        }

        let view = MTKView(frame: .zero, device: device)
        // Keep clear color aligned with the shader palette for clean edges.
        view.clearColor = resolvedPalette.clearColor
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.preferredFramesPerSecond = preferredFramesPerSecond
        view.isPaused = false
        view.enableSetNeedsDisplay = false

        let renderer = CurtainsRenderer(device: device, initialPalette: resolvedPalette)
        renderer?.apply(settings: settings, palette: resolvedPalette)
        context.coordinator.renderer = renderer
        renderer?.onFPSUpdate = { [weak coordinator = context.coordinator] value in
            DispatchQueue.main.async {
                coordinator?.fps.wrappedValue = value
            }
        }
        view.delegate = renderer

        // Touch input controls the shader glow hotspot.
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        context.coordinator.mtkView = view

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Keep UI-level state and renderer state synchronized on every SwiftUI update.
        uiView.preferredFramesPerSecond = preferredFramesPerSecond
        uiView.clearColor = resolvedPalette.clearColor
        context.coordinator.renderer?.apply(settings: settings, palette: resolvedPalette)
    }

    private var resolvedPalette: BackgroundPalette {
        BackgroundPalette.custom(baseColor: SIMD4<Float>(
            Float(settings.customColor.red),
            Float(settings.customColor.green),
            Float(settings.customColor.blue),
            Float(settings.customColor.alpha)
        ))
    }

    /// Bridges UIKit gestures and renderer lifetime into SwiftUI.
    final class Coordinator {
        let fps: Binding<Double>
        weak var mtkView: MTKView?
        var renderer: CurtainsRenderer?

        init(fps: Binding<Double>) {
            self.fps = fps
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard
                let view = mtkView,
                let renderer
            else {
                return
            }

            let point = gesture.location(in: view)
            // Renderer converts this point to normalized UV coordinates.
            renderer.updateTouchPosition(point: point, in: view.bounds.size)
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard
                let view = mtkView,
                let renderer
            else {
                return
            }

            let point = gesture.location(in: view)
            renderer.updateTouchPosition(point: point, in: view.bounds.size)
        }
    }
}
