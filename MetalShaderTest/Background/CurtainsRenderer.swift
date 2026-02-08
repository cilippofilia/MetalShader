//
//  CurtainsRenderer.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import Foundation
import MetalKit

/// Metal renderer for the full-screen animated "curtains" background.
/// Compiles shader source at runtime and drives touch-driven glow.
final class CurtainsRenderer: NSObject, MTKViewDelegate {
    /// Uniform block for palette colors consumed by the shader.
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

    /// Uniform block that controls wave and glow behavior.
    private struct EffectUniforms {
        var waveAmplitude: Float
        var waveFrequency: Float
        var waveSpeed: Float
        var touchGlowRadius: Float
        var touchGlowIntensity: Float
        var softGlowEnabled: Float
        var padding: SIMD2<Float> = .zero
    }

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    /// Shared time origin for deterministic animation.
    private let startTime = CACurrentMediaTime()

    /// Smoothed touch point used by shader.
    private var touchUV = SIMD2<Float>(0.5, 0.5)
    /// Latest raw touch target, approached over time.
    private var targetTouchUV = SIMD2<Float>(0.5, 0.5)

    private var palette: BackgroundPalette
    private var settings = BackgroundEffectSettings()

    var onFPSUpdate: ((Double) -> Void)?
    private var frameCount: Int = 0
    private var fpsWindowStart = CACurrentMediaTime()

    init?(device: MTLDevice, initialPalette: BackgroundPalette) {
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        do {
            // Compile shader code embedded in this file.
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

        self.palette = initialPalette
        self.commandQueue = commandQueue
    }

    /// Applies the latest UI settings used by subsequent frames.
    func apply(settings: BackgroundEffectSettings, palette: BackgroundPalette) {
        self.settings = settings
        self.palette = palette
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
        // Smooth input to avoid abrupt glow jumps while dragging.
        touchUV += (targetTouchUV - touchUV) * Float(settings.touchFollowSpeed)
        var touch = touchUV

        // Palette transition uniforms.
        var transitionUniforms = TransitionUniforms(
            fromTopColor: palette.topColor,
            fromBottomColor: palette.bottomColor,
            fromGlowColor: palette.glowColor,
            toTopColor: palette.topColor,
            toBottomColor: palette.bottomColor,
            toGlowColor: palette.glowColor,
            progress: 1.0
        )

        // Effect tuning uniforms controlled by the settings sheet.
        var effectUniforms = EffectUniforms(
            waveAmplitude: Float(settings.waveAmplitude),
            waveFrequency: Float(settings.waveFrequency),
            waveSpeed: Float(settings.waveSpeed),
            touchGlowRadius: Float(settings.touchGlowRadius),
            touchGlowIntensity: Float(settings.touchGlowIntensity),
            softGlowEnabled: settings.softGlowEnabled ? 1.0 : 0.0
        )

        encoder.setRenderPipelineState(pipelineState)
        // Fragment buffers:
        // 0 time, 1 touch uv, 2 transition colors, 3 effect settings.
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&touch, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.setFragmentBytes(&transitionUniforms, length: MemoryLayout<TransitionUniforms>.stride, index: 2)
        encoder.setFragmentBytes(&effectUniforms, length: MemoryLayout<EffectUniforms>.stride, index: 3)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()

        frameCount += 1
        let elapsed = now - fpsWindowStart
        if elapsed >= 0.5 {
            // Average over a small window to reduce FPS noise.
            onFPSUpdate?(Double(frameCount) / elapsed)
            frameCount = 0
            fpsWindowStart = now
        }
    }

    /// Converts touch coordinates to normalized UV space for shader input.
    func updateTouchPosition(point: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            return
        }

        let x = Float(point.x / size.width)
        let y = Float(1.0 - point.y / size.height)
        targetTouchUV = SIMD2<Float>(simd_clamp(x, 0.0, 1.0), simd_clamp(y, 0.0, 1.0))
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

    struct EffectUniforms {
        float waveAmplitude;
        float waveFrequency;
        float waveSpeed;
        float touchGlowRadius;
        float touchGlowIntensity;
        float softGlowEnabled;
        float2 padding;
    };

    vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
        // Full-screen triangle (faster than a quad, no diagonal seam).
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
        constant TransitionUniforms &transition [[buffer(2)]],
        constant EffectUniforms &effects [[buffer(3)]]
    ) {
        // Blend palettes so style switches are animated, not abrupt.
        float3 topColor = mix(transition.fromTopColor.rgb, transition.toTopColor.rgb, transition.progress);
        float3 bottomColor = mix(transition.fromBottomColor.rgb, transition.toBottomColor.rgb, transition.progress);
        float3 glowColor = mix(transition.fromGlowColor.rgb, transition.toGlowColor.rgb, transition.progress);

        // Distort gradient with a horizontal sine wave.
        float wave = effects.waveAmplitude * sin((in.uv.x + time * effects.waveSpeed) * effects.waveFrequency);
        float t = clamp(in.uv.y + wave, 0.0, 1.0);
        float3 color = mix(bottomColor, topColor, t);

        // Radial glow that follows the latest touch point.
        float dist = distance(in.uv, touch);
        float glow = smoothstep(effects.touchGlowRadius, 0.0, dist) * effects.touchGlowIntensity * effects.softGlowEnabled;
        color += glowColor * glow;
        return float4(color, 1.0);
    }
    """
}
