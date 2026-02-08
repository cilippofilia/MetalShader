//
//  CurtainsBackgroundView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import MetalKit
import SwiftUI

/// SwiftUI wrapper around an `MTKView` that renders the animated background.
struct CurtainsBackgroundView: UIViewRepresentable {
    @Binding var fps: Double
    let style: BackgroundStyle
    let settings: BackgroundEffectSettings

    func makeCoordinator() -> Coordinator {
        Coordinator(fps: $fps)
    }

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView()
        }

        let view = MTKView(frame: .zero, device: device)
        // Keep this clear color aligned with the selected style for clean transitions.
        view.clearColor = style.palette.clearColor
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = min(60, 120)
        view.isPaused = false
        view.enableSetNeedsDisplay = false

        let renderer = CurtainsRenderer(device: device, initialStyle: style)
        renderer?.apply(settings: settings)
        context.coordinator.renderer = renderer
        renderer?.onFPSUpdate = { [weak coordinator = context.coordinator] value in
            DispatchQueue.main.async {
                // Animate text changes to reduce visual jitter in the FPS badge.
                withAnimation {
                    coordinator?.fps.wrappedValue = value
                }
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
        uiView.clearColor = style.palette.clearColor
        context.coordinator.renderer?.transition(to: style)
        context.coordinator.renderer?.apply(settings: settings)
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
