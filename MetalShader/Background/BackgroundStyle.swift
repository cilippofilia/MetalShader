//
//  BackgroundPalette.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import Foundation
import Metal

/// Color set used by the background shader and the view clear color.
struct BackgroundPalette {
    let topColor: SIMD4<Float>
    let bottomColor: SIMD4<Float>
    let glowColor: SIMD4<Float>
    let clearColor: MTLClearColor
}

extension BackgroundPalette {
    /// Builds a full palette from a single user-selected base color.
    static func custom(baseColor: SIMD4<Float>) -> BackgroundPalette {
        let top = clamp(baseColor * SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
        let bottom = clamp(baseColor * SIMD4<Float>(0.16, 0.16, 0.16, 1.0))
        let glow = clamp(baseColor * SIMD4<Float>(0.42, 0.42, 0.42, 1.0))
        return BackgroundPalette(
            topColor: top,
            bottomColor: bottom,
            glowColor: glow,
            clearColor: MTLClearColor(
                red: Double(bottom.x),
                green: Double(bottom.y),
                blue: Double(bottom.z),
                alpha: 1.0
            )
        )
    }

    private static func clamp(_ color: SIMD4<Float>) -> SIMD4<Float> {
        SIMD4<Float>(
            min(max(color.x, 0.0), 1.0),
            min(max(color.y, 0.0), 1.0),
            min(max(color.z, 0.0), 1.0),
            min(max(color.w, 0.0), 1.0)
        )
    }
}
