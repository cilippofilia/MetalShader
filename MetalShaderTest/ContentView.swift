//
//  ContentView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import Metal
import MetalKit
import QuartzCore
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var fps: Double = 0

    var body: some View {
        VStack {
            MetalBackgroundView(fps: $fps)
                .ignoresSafeArea()
        }
        .overlay(alignment: .topLeading) {
            Text("FPS \(Int(fps.rounded()))")
                .font(.system(.subheadline, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 8, style: .continuous))
                .padding(.top, 16)
                .padding(.leading, 16)
                .contentTransition(.numericText(value: fps))
        }
    }
}

#Preview {
    ContentView()
}

struct MetalBackgroundView: UIViewRepresentable {
    @Binding var fps: Double

    func makeCoordinator() -> Coordinator {
        Coordinator(fps: $fps)
    }

    func makeUIView(context: Context) -> MTKView {
        // The MTLDevice represents the GPU we submit work to.
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView()
        }

        let view = MTKView(frame: .zero, device: device)
        // Fallback clear color used before/if our draw pass doesn't write pixels.
        view.clearColor = MTLClearColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 1.0)
        // Pixel format must match what the render pipeline expects.
        view.colorPixelFormat = .bgra8Unorm
        // Continuously render at ~60 FPS so the time-based animation updates.
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false

        // Keep the delegate alive through a coordinator and let it render each frame.
        let renderer = Renderer(device: device)
        context.coordinator.renderer = renderer
        renderer?.onFPSUpdate = { [weak coordinator = context.coordinator] value in
            DispatchQueue.main.async {
                withAnimation {
                    coordinator?.fps.wrappedValue = value
                }
            }
        }
        view.delegate = renderer

        // Track finger movement and forward it to the renderer as a shader uniform.
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        context.coordinator.mtkView = view

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    final class Coordinator {
        let fps: Binding<Double>
        weak var mtkView: MTKView?
        var renderer: Renderer?

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

final class Renderer: NSObject, MTKViewDelegate {
    // A command queue creates command buffers (units of GPU work).
    private let commandQueue: MTLCommandQueue
    // The pipeline bundles shaders + fixed render configuration.
    private let pipelineState: MTLRenderPipelineState
    // We animate based on seconds elapsed since renderer creation.
    private let startTime = CACurrentMediaTime()
    // Current animated touch location in UV space (0...1, with 0 at left/bottom).
    private var touchUV = SIMD2<Float>(0.5, 0.5)
    // Latest input position; touchUV eases toward this for smoother motion.
    private var targetTouchUV = SIMD2<Float>(0.5, 0.5)
    // Callback used to publish measured FPS to SwiftUI.
    var onFPSUpdate: ((Double) -> Void)?
    private var frameCount: Int = 0
    private var fpsWindowStart = CACurrentMediaTime()

    init?(device: MTLDevice) {
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        do {
            // Compile shader source into a Metal library at runtime.
            let library = try device.makeLibrary(source: Self.shaderSource, options: nil)

            guard
                let vertexFunction = library.makeFunction(name: "vertex_main"),
                let fragmentFunction = library.makeFunction(name: "fragment_main")
            else {
                return nil
            }

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            // Must match MTKView.colorPixelFormat.
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            return nil
        }

        self.commandQueue = commandQueue
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        // Get everything required to record a render pass for the current frame.
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        // Pass elapsed time to the fragment shader so background can animate.
        var time = Float(CACurrentMediaTime() - startTime)
        // Smooth transition of the glow center when touch input changes.
        touchUV += (targetTouchUV - touchUV) * 0.05
        var touch = touchUV
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&touch, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        // Draw one fullscreen triangle (cheaper than a quad with 2 triangles).
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        // Present rendered image and submit the command buffer to the GPU.
        commandBuffer.present(drawable)
        commandBuffer.commit()

        // Estimate FPS over short windows to avoid noisy per-frame updates.
        frameCount += 1
        let now = CACurrentMediaTime()
        let elapsed = now - fpsWindowStart
        if elapsed >= 0.5 {
            let measuredFPS = Double(frameCount) / elapsed
            onFPSUpdate?(measuredFPS)
            frameCount = 0
            fpsWindowStart = now
        }
    }

    func updateTouchPosition(point: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            return
        }

        // UIKit has origin at top-left; shader UV uses bottom-left.
        let x = Float(point.x / size.width)
        let y = Float(1.0 - point.y / size.height)
        targetTouchUV = SIMD2<Float>(simd_clamp(x, 0.0, 1.0), simd_clamp(y, 0.0, 1.0))
    }

    private static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
        float4 position [[position]];
        // UV coordinates (0...1 range) used by the fragment shader.
        float2 uv;
    };

    vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
        // Fullscreen triangle in clip-space coordinates.
        float2 positions[3] = {
            float2(-1.0, -1.0),
            float2( 3.0, -1.0),
            float2(-1.0,  3.0)
        };

        VertexOut out;
        out.position = float4(positions[vertexID], 0.0, 1.0);
        out.uv = positions[vertexID] * 0.5 + 0.5;
        return out;
    }

    fragment float4 fragment_main(
        VertexOut in [[stage_in]],
        constant float &time [[buffer(0)]],
        constant float2 &touch [[buffer(1)]]
    ) {
        // Vertical gradient colors.
        float3 topColor = float3(0.14, 0.34, 0.72);
        float3 bottomColor = float3(0.05, 0.06, 0.10);
        // Gentle horizontal sine wave animated with `time`.
        float wave = 0.08 * sin((in.uv.x + time * 0.2) * 8.0);
        float t = clamp(in.uv.y + wave, 0.0, 1.0);
        float3 color = mix(bottomColor, topColor, t);

        // Add a soft spotlight around the latest touch point.
        float dist = distance(in.uv, touch);
        float glow = smoothstep(0.35, 0.0, dist);
        color += float3(0.20, 0.12, 0.08) * glow;
        return float4(color, 1.0);
    }
    """
}
