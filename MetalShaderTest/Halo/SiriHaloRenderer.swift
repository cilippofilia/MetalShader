//
//  SiriHaloRenderer.swift
//  MetalShaderTest
//
//  Created by Codex on 08/02/2026.
//

import Foundation
import MetalKit

/// Metal renderer for the rounded rectangular Siri-like halo border overlay.
final class SiriHaloRenderer: NSObject, MTKViewDelegate {
    /// Uniform block consumed by the halo fragment shader.
    private struct FragmentUniforms {
        var time: Float
        var viewSize: SIMD2<Float>
        var cornerRadius: Float
        var edgeInset: Float
        var coreWidth: Float
        var glowWidth: Float
        var mistWidth: Float
        var haloStrength: Float
        var pulseBase: Float
        var pulseAmount: Float
        var pulseSpeed: Float
        var colorShiftSpeed: Float
    }

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    /// Shared time origin for pulse and hue animation.
    private let startTime = CACurrentMediaTime()

    private var settings = HaloEffectSettings()

    init?(device: MTLDevice) {
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        do {
            // Compile inline Metal shader source.
            let library = try device.makeLibrary(source: Self.shaderSource, options: nil)
            guard
                let vertexFunction = library.makeFunction(name: "vertex_main"),
                let fragmentFunction = library.makeFunction(name: "fragment_main")
            else {
                return nil
            }

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            // Premultiplied-alpha style blending for smooth halo compositing.
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = .add
            descriptor.colorAttachments[0].alphaBlendOperation = .add
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            return nil
        }

        self.commandQueue = commandQueue
    }

    /// Applies current halo controls from the settings sheet.
    func apply(settings: HaloEffectSettings) {
        self.settings = settings
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
        let minDimension = max(Float(min(view.drawableSize.width, view.drawableSize.height)), 1.0)
        // Convert point-based controls into normalized units so behavior scales with screen size.
        var uniforms = FragmentUniforms(
            time: Float(now - startTime),
            viewSize: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            cornerRadius: Float(settings.cornerRadius) / minDimension,
            edgeInset: Float(settings.edgeInset) / minDimension,
            coreWidth: Float(settings.coreWidth) / minDimension,
            glowWidth: Float(settings.glowWidth) / minDimension,
            mistWidth: Float(settings.mistWidth) / minDimension,
            haloStrength: Float(settings.haloStrength),
            pulseBase: Float(settings.pulseBase),
            pulseAmount: Float(settings.pulseAmount),
            pulseSpeed: Float(settings.pulseSpeed),
            colorShiftSpeed: Float(settings.colorShiftSpeed)
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };

    struct FragmentUniforms {
        float time;
        float2 viewSize;
        float cornerRadius;
        float edgeInset;
        float coreWidth;
        float glowWidth;
        float mistWidth;
        float haloStrength;
        float pulseBase;
        float pulseAmount;
        float pulseSpeed;
        float colorShiftSpeed;
    };

    float sdRoundedBox(float2 p, float2 halfSize, float radius) {
        // Signed distance to a rounded rectangle centered at origin.
        float2 q = abs(p) - (halfSize - radius);
        return length(max(q, float2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    }

    float3 siriSpectrum(float t) {
        // Hand-tuned palette approximating Siri's neon gradient cycle.
        float3 c0 = float3(0.18, 0.88, 1.00);
        float3 c1 = float3(0.13, 0.53, 1.00);
        float3 c2 = float3(0.70, 0.33, 1.00);
        float3 c3 = float3(1.00, 0.40, 0.72);
        float3 c4 = float3(1.00, 0.63, 0.36);
        float3 c5 = float3(0.22, 0.92, 0.98);

        float u = fract(t) * 5.0;
        float i = floor(u);
        float f = fract(u);

        if (i < 1.0) return mix(c0, c1, f);
        if (i < 2.0) return mix(c1, c2, f);
        if (i < 3.0) return mix(c2, c3, f);
        if (i < 4.0) return mix(c3, c4, f);
        return mix(c4, c5, f);
    }

    vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
        // Full-screen triangle.
        float2 positions[3] = {
            float2(-1.0, -1.0),
            float2(3.0, -1.0),
            float2(-1.0, 3.0)
        };

        VertexOut out;
        out.position = float4(positions[vertexID], 0.0, 1.0);
        out.uv = positions[vertexID] * 0.5 + 0.5;
        return out;
    }

    fragment float4 fragment_main(
        VertexOut in [[stage_in]],
        constant FragmentUniforms &uniforms [[buffer(0)]]
    ) {
        float aspect = max(uniforms.viewSize.x / max(uniforms.viewSize.y, 1.0), 0.001);
        float2 p = in.uv - 0.5;
        p.x *= aspect;

        // Distance from current pixel to the rounded border path.
        float2 halfSize = float2(0.5 * aspect - uniforms.edgeInset, 0.5 - uniforms.edgeInset);
        float borderDistance = sdRoundedBox(p, halfSize, uniforms.cornerRadius);

        float angle = atan2(p.y, p.x) * 0.15915494309 + 0.5 + uniforms.time * uniforms.colorShiftSpeed;
        float3 haloColor = siriSpectrum(angle);

        // Three layered gaussian bands create a rich, soft halo.
        float pulse = uniforms.pulseBase + uniforms.pulseAmount * sin(uniforms.time * uniforms.pulseSpeed);
        float core = exp(-pow(borderDistance / max(uniforms.coreWidth, 0.0001), 2.0)) * 0.28;
        float mid = exp(-pow(borderDistance / max(uniforms.glowWidth, 0.0001), 2.0)) * 0.26 * pulse;
        float mist = exp(-pow(borderDistance / max(uniforms.mistWidth, 0.0001), 2.0)) * 0.16 * pulse;

        float innerFade = mix(smoothstep(-uniforms.mistWidth, 0.0, borderDistance), 1.0, step(0.0, borderDistance));
        float alpha = (core + mid + mist) * innerFade * uniforms.haloStrength;
        alpha = clamp(alpha, 0.0, 1.0);

        float3 premultiplied = haloColor * alpha;
        return float4(premultiplied, alpha);
    }
    """
}
