//
//  SiriHaloRenderer.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 08/02/2026.
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
        var waveInsetPixels: Float
        var waveAmplitudePixels: Float
        var waveCount: Float
        var waveSpeedMultiplier: Float
        var waveSpeedOffset: Float
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
            guard
                let library = device.makeDefaultLibrary(),
                let vertexFunction = library.makeFunction(name: "fullscreen_vertex"),
                let fragmentFunction = library.makeFunction(name: "halo_fragment")
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
            waveInsetPixels: Float(settings.waveInsetPixels),
            waveAmplitudePixels: Float(settings.waveAmplitudePixels),
            waveCount: Float(settings.waveCount),
            waveSpeedMultiplier: Float(settings.waveSpeedMultiplier),
            waveSpeedOffset: Float(settings.waveSpeedOffset),
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

}
