//
//  SettingsSheetView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 08/02/2026.
//

import SwiftUI
import UIKit

/// Form used in the bottom sheet to tweak halo and background effects.
struct SettingsSheetView: View {
    /// Editing this binding updates the live renderers immediately.
    @Binding var settings: ViewPersonalizationSettings
    @Environment(\.dismiss) private var dismiss
    @State private var isHaloExpanded = true
    @State private var isBackgroundExpanded = true

    var body: some View {
        NavigationStack {
            Form {
                // Controls mapped to `HaloEffectSettings`.
                DisclosureGroup("Halo", isExpanded: $isHaloExpanded) {
                    Toggle("Show Halo", isOn: $settings.halo.isVisible)
                    SliderRowView(title: "Corner Radius", description: "Rounds the halo border corners.", value: $settings.halo.cornerRadius, range: 28...200, step: 1)
                    SliderRowView(title: "Edge Inset", description: "Moves the halo farther from screen edges.", value: $settings.halo.edgeInset, range: 0...12, step: 0.5)
                    SliderRowView(title: "Core Width", description: "Thickness of the bright inner line.", value: $settings.halo.coreWidth, range: 1...16, step: 0.5)
                    SliderRowView(title: "Glow Width", description: "Size of the main glow around the line.", value: $settings.halo.glowWidth, range: 4...48, step: 0.5)
                    SliderRowView(title: "Mist Width", description: "Soft outer haze spread.", value: $settings.halo.mistWidth, range: 10...90, step: 1)
                    SliderRowView(title: "Strength", description: "Overall halo brightness.", value: $settings.halo.haloStrength, range: 0.1...1.4, step: 0.01)
                    SliderRowView(title: "Pulse Base", description: "Baseline intensity before pulsing.", value: $settings.halo.pulseBase, range: 0...1.2, step: 0.01)
                    SliderRowView(title: "Pulse Amount", description: "How much the pulse varies over time.", value: $settings.halo.pulseAmount, range: 0...0.9, step: 0.01)
                    SliderRowView(title: "Pulse Speed", description: "Pulse animation speed.", value: $settings.halo.pulseSpeed, range: 0...8, step: 0.05)
                    SliderRowView(title: "Color Shift", description: "Speed of color cycling around the border.", value: $settings.halo.colorShiftSpeed, range: 0...0.25, step: 0.005)
                }

                // Controls mapped to `BackgroundEffectSettings`.
                DisclosureGroup("Background", isExpanded: $isBackgroundExpanded) {
                    Toggle("Show Soft Glow", isOn: $settings.background.softGlowEnabled)
                    ColorPicker("Background Color", selection: customBackgroundColor)
                    SliderRowView(title: "Wave Amplitude", description: "Height of the wave distortion.", value: $settings.background.waveAmplitude, range: 0...0.22, step: 0.005)
                    SliderRowView(title: "Wave Frequency", description: "Number of wave bands across the screen.", value: $settings.background.waveFrequency, range: 0...20, step: 0.1)
                    SliderRowView(title: "Wave Speed", description: "How fast the waves move horizontally.", value: $settings.background.waveSpeed, range: 0...1.4, step: 0.01)
                    SliderRowView(title: "Glow Radius", description: "Size of the touch glow area.", value: $settings.background.touchGlowRadius, range: 0.05...0.9, step: 0.01)
                    SliderRowView(title: "Glow Intensity", description: "Brightness of the touch glow.", value: $settings.background.touchGlowIntensity, range: 0...2.6, step: 0.01)
                    SliderRowView(title: "Touch Follow", description: "How quickly glow follows finger movement.", value: $settings.background.touchFollowSpeed, range: 0.01...0.3, step: 0.005)
                }
            }
            .navigationTitle("Personalize")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        // Restore both effect groups to project defaults.
                        settings = .default
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var customBackgroundColor: Binding<Color> {
        Binding(
            get: {
                let color = settings.background.customColor
                return Color(
                    red: color.red,
                    green: color.green,
                    blue: color.blue,
                    opacity: color.alpha
                )
            },
            set: { newValue in
                let uiColor = UIColor(newValue)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                    return
                }
                settings.background.customColor = RGBAColor(
                    red: Double(red),
                    green: Double(green),
                    blue: Double(blue),
                    alpha: Double(alpha)
                )
            }
        )
    }
}

#Preview {
    SettingsSheetView(settings: .constant(.default))
}
