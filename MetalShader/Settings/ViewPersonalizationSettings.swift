//
//  ViewPersonalizationSettings.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 08/02/2026.
//

import Foundation

/// Codable RGBA container used for persisted color customization.
struct RGBAColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double = 1.0
}

/// Persisted root settings for the main visual components.
struct ViewPersonalizationSettings: Codable, Equatable {
    var halo = HaloEffectSettings()
    var background = BackgroundEffectSettings()

    static let `default` = ViewPersonalizationSettings()
}

/// User-tweakable parameters for the halo overlay renderer.
struct HaloEffectSettings: Codable, Equatable {
    /// Master visibility toggle for the halo overlay.
    var isVisible: Bool = true
    /// Rounded corner radius of the border path (points, normalized in renderer).
    var cornerRadius: Double = 88
    /// Inset from screen edge to the border path.
    var edgeInset: Double = 2
    /// Pixel offset that moves the animated wave inward toward screen center.
    var waveInsetPixels: Double = 4
    /// Geometric displacement amplitude of the halo wave in pixels.
    var waveAmplitudePixels: Double = 11
    /// Number of wave peaks around the halo perimeter.
    var waveCount: Double = 3
    /// Multiplier applied to pulse speed for wave travel speed.
    var waveSpeedMultiplier: Double = 1.2
    /// Constant speed term added to wave travel speed.
    var waveSpeedOffset: Double = 0.2
    /// Width of the bright inner line.
    var coreWidth: Double = 4
    /// Width of the main glow region.
    var glowWidth: Double = 14
    /// Width of the outer soft haze.
    var mistWidth: Double = 34
    /// Global alpha/intensity multiplier.
    var haloStrength: Double = 0.92
    /// Baseline pulse value.
    var pulseBase: Double = 0.78
    /// Additional pulse amount added by sine animation.
    var pulseAmount: Double = 0.22
    /// Pulse animation speed.
    var pulseSpeed: Double = 2.2
    /// Speed of hue cycling around the border.
    var colorShiftSpeed: Double = 0.04

    private enum CodingKeys: String, CodingKey {
        case isVisible
        case cornerRadius
        case edgeInset
        case waveInsetPixels
        case waveAmplitudePixels
        case waveCount
        case waveSpeedMultiplier
        case waveSpeedOffset
        case coreWidth
        case glowWidth
        case mistWidth
        case haloStrength
        case pulseBase
        case pulseAmount
        case pulseSpeed
        case colorShiftSpeed
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        cornerRadius = try container.decode(Double.self, forKey: .cornerRadius)
        edgeInset = try container.decode(Double.self, forKey: .edgeInset)
        waveInsetPixels = try container.decodeIfPresent(Double.self, forKey: .waveInsetPixels) ?? 4
        waveAmplitudePixels = try container.decodeIfPresent(Double.self, forKey: .waveAmplitudePixels) ?? 11
        waveCount = try container.decodeIfPresent(Double.self, forKey: .waveCount) ?? 3
        waveSpeedMultiplier = try container.decodeIfPresent(Double.self, forKey: .waveSpeedMultiplier) ?? 1.2
        waveSpeedOffset = try container.decodeIfPresent(Double.self, forKey: .waveSpeedOffset) ?? 0.2
        coreWidth = try container.decode(Double.self, forKey: .coreWidth)
        glowWidth = try container.decode(Double.self, forKey: .glowWidth)
        mistWidth = try container.decode(Double.self, forKey: .mistWidth)
        haloStrength = try container.decode(Double.self, forKey: .haloStrength)
        pulseBase = try container.decode(Double.self, forKey: .pulseBase)
        pulseAmount = try container.decode(Double.self, forKey: .pulseAmount)
        pulseSpeed = try container.decode(Double.self, forKey: .pulseSpeed)
        colorShiftSpeed = try container.decode(Double.self, forKey: .colorShiftSpeed)
    }
}

/// User-tweakable parameters for the curtains background renderer.
struct BackgroundEffectSettings: Codable, Equatable {
    /// Enables or disables touch-driven glow contribution.
    var softGlowEnabled: Bool = true
    /// Base color used to derive top/bottom/glow shades for the shader.
    var customColor: RGBAColor = RGBAColor(red: 0.14, green: 0.34, blue: 0.72, alpha: 1.0)
    /// Vertical displacement amount of the wave.
    var waveAmplitude: Double = 0.08
    /// Number of wave oscillations across the X axis.
    var waveFrequency: Double = 8.0
    /// Horizontal scrolling speed of the wave.
    var waveSpeed: Double = 0.2
    /// Radius of the touch glow area in UV space.
    var touchGlowRadius: Double = 0.35
    /// Brightness of the touch glow.
    var touchGlowIntensity: Double = 1.0
    /// Interpolation factor used to smooth touch movement.
    var touchFollowSpeed: Double = 0.05
}
