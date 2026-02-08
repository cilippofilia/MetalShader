//
//  BackgroundStyle.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import Foundation
import Metal

enum BackgroundStyle: String, CaseIterable, Identifiable {
    case deepBlueCurtains = "Deep Blue"
    case deepRedCurtains = "Deep Red"
    case deepGreenCurtains = "Deep Green"

    var id: Self { self }

    var palette: BackgroundPalette {
        switch self {
        case .deepBlueCurtains:
            return BackgroundPalette(
                topColor: SIMD4<Float>(0.14, 0.34, 0.72, 1.0),
                bottomColor: SIMD4<Float>(0.05, 0.06, 0.10, 1.0),
                glowColor: SIMD4<Float>(0.20, 0.12, 0.08, 1.0),
                clearColor: MTLClearColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 1.0)
            )
        case .deepRedCurtains:
            return BackgroundPalette(
                topColor: SIMD4<Float>(0.58, 0.08, 0.13, 1.0),
                bottomColor: SIMD4<Float>(0.09, 0.01, 0.02, 1.0),
                glowColor: SIMD4<Float>(0.24, 0.07, 0.04, 1.0),
                clearColor: MTLClearColor(red: 0.14, green: 0.03, blue: 0.04, alpha: 1.0)
            )
        case .deepGreenCurtains:
            return BackgroundPalette(
                topColor: SIMD4<Float>(0.07, 0.46, 0.28, 1.0),
                bottomColor: SIMD4<Float>(0.01, 0.09, 0.06, 1.0),
                glowColor: SIMD4<Float>(0.14, 0.22, 0.12, 1.0),
                clearColor: MTLClearColor(red: 0.02, green: 0.12, blue: 0.08, alpha: 1.0)
            )
        }
    }
}

struct BackgroundPalette {
    let topColor: SIMD4<Float>
    let bottomColor: SIMD4<Float>
    let glowColor: SIMD4<Float>
    let clearColor: MTLClearColor

    func interpolated(to target: BackgroundPalette, progress: Float) -> BackgroundPalette {
        let p = max(0.0, min(1.0, progress))
        return BackgroundPalette(
            topColor: mix(topColor, target.topColor, t: p),
            bottomColor: mix(bottomColor, target.bottomColor, t: p),
            glowColor: mix(glowColor, target.glowColor, t: p),
            clearColor: MTLClearColor(
                red: Double(Float(clearColor.red) + (Float(target.clearColor.red) - Float(clearColor.red)) * p),
                green: Double(Float(clearColor.green) + (Float(target.clearColor.green) - Float(clearColor.green)) * p),
                blue: Double(Float(clearColor.blue) + (Float(target.clearColor.blue) - Float(clearColor.blue)) * p),
                alpha: Double(Float(clearColor.alpha) + (Float(target.clearColor.alpha) - Float(clearColor.alpha)) * p)
            )
        )
    }

    private func mix(_ a: SIMD4<Float>, _ b: SIMD4<Float>, t: Float) -> SIMD4<Float> {
        a + (b - a) * t
    }
}
