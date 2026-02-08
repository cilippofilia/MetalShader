//
//  CurtainsBackgroundView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import MetalKit
import SwiftUI

struct CurtainsBackgroundView: UIViewRepresentable {
    @Binding var fps: Double
    let style: BackgroundStyle

    func makeCoordinator() -> Coordinator {
        Coordinator(fps: $fps)
    }

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView()
        }

        let view = MTKView(frame: .zero, device: device)
        view.clearColor = style.palette.clearColor
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false

        let renderer = CurtainsRenderer(device: device, initialStyle: style)
        context.coordinator.renderer = renderer
        renderer?.onFPSUpdate = { [weak coordinator = context.coordinator] value in
            DispatchQueue.main.async {
                withAnimation {
                    coordinator?.fps.wrappedValue = value
                }
            }
        }
        view.delegate = renderer

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        context.coordinator.mtkView = view

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.clearColor = style.palette.clearColor
        context.coordinator.renderer?.transition(to: style)
    }

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
