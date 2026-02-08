//
//  CurtainsRenderer.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import Foundation
import MetalKit

final class CurtainsRenderer: NSObject, MTKViewDelegate {
    private struct TransitionUniforms {
        var fromTopColor: SIMD4<Float>
        var fromBottomColor: SIMD4<Float>
        var fromGlowColor: SIMD4<Float>
        var toTopColor: SIMD4<Float>
        var toBottomColor: SIMD4<Float>
        var toGlowColor: SIMD4<Float>
        var progress: Float
        var padding: SIMD3<Float> = .zero
    }

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let startTime = CACurrentMediaTime()

    private var touchUV = SIMD2<Float>(0.5, 0.5)
    private var targetTouchUV = SIMD2<Float>(0.5, 0.5)

    private var fromPalette: BackgroundPalette
    private var toPalette: BackgroundPalette
    private var destinationStyle: BackgroundStyle
    private var transitionStartTime: CFTimeInterval?
    private let transitionDuration: Float = 0.45

    var onFPSUpdate: ((Double) -> Void)?
    private var frameCount: Int = 0
    private var fpsWindowStart = CACurrentMediaTime()

    init?(device: MTLDevice, initialStyle: BackgroundStyle) {
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        do {
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
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            return nil
        }

        let initialPalette = initialStyle.palette
        self.fromPalette = initialPalette
        self.toPalette = initialPalette
        self.destinationStyle = initialStyle
        self.commandQueue = commandQueue
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        let now = CACurrentMediaTime()
        var time = Float(now - startTime)
        touchUV += (targetTouchUV - touchUV) * 0.05
        var touch = touchUV

        var uniforms = TransitionUniforms(
            fromTopColor: fromPalette.topColor,
            fromBottomColor: fromPalette.bottomColor,
            fromGlowColor: fromPalette.glowColor,
            toTopColor: toPalette.topColor,
            toBottomColor: toPalette.bottomColor,
            toGlowColor: toPalette.glowColor,
            progress: transitionProgress(at: now)
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&touch, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<TransitionUniforms>.stride, index: 2)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()

        frameCount += 1
        let elapsed = now - fpsWindowStart
        if elapsed >= 0.5 {
            onFPSUpdate?(Double(frameCount) / elapsed)
            frameCount = 0
            fpsWindowStart = now
        }
    }

    func transition(to style: BackgroundStyle) {
        guard style != destinationStyle else {
            return
        }

        destinationStyle = style
        let newPalette = style.palette
        let now = CACurrentMediaTime()
        let displayedPalette = interpolatedPalette(at: now)

        fromPalette = displayedPalette
        toPalette = newPalette
        transitionStartTime = now
    }

    func updateTouchPosition(point: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            return
        }

        let x = Float(point.x / size.width)
        let y = Float(1.0 - point.y / size.height)
        targetTouchUV = SIMD2<Float>(simd_clamp(x, 0.0, 1.0), simd_clamp(y, 0.0, 1.0))
    }

    private func transitionProgress(at now: CFTimeInterval) -> Float {
        guard let start = transitionStartTime else {
            return 1.0
        }

        let linear = min(Float((now - start) / Double(transitionDuration)), 1.0)
        let eased = linear * linear * (3.0 - 2.0 * linear)
        if linear >= 1.0 {
            fromPalette = toPalette
            transitionStartTime = nil
        }
        return eased
    }

    private func interpolatedPalette(at now: CFTimeInterval) -> BackgroundPalette {
        let t = transitionProgress(at: now)
        return fromPalette.interpolated(to: toPalette, progress: t)
    }

    private static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };

    struct TransitionUniforms {
        float4 fromTopColor;
        float4 fromBottomColor;
        float4 fromGlowColor;
        float4 toTopColor;
        float4 toBottomColor;
        float4 toGlowColor;
        float progress;
        float3 padding;
    };

    vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
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
        constant float2 &touch [[buffer(1)]],
        constant TransitionUniforms &transition [[buffer(2)]]
    ) {
        float3 topColor = mix(transition.fromTopColor.rgb, transition.toTopColor.rgb, transition.progress);
        float3 bottomColor = mix(transition.fromBottomColor.rgb, transition.toBottomColor.rgb, transition.progress);
        float3 glowColor = mix(transition.fromGlowColor.rgb, transition.toGlowColor.rgb, transition.progress);

        float wave = 0.08 * sin((in.uv.x + time * 0.2) * 8.0);
        float t = clamp(in.uv.y + wave, 0.0, 1.0);
        float3 color = mix(bottomColor, topColor, t);

        float dist = distance(in.uv, touch);
        float glow = smoothstep(0.35, 0.0, dist);
        color += glowColor * glow;
        return float4(color, 1.0);
    }
    """
}
