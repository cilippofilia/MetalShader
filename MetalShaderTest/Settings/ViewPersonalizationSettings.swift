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
