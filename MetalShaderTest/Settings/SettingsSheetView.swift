//
//  SettingsSheetView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 08/02/2026.
//

import SwiftUI

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
                    SliderRowView(title: "Corner Radius", value: $settings.halo.cornerRadius, range: 28...200, step: 1)
                    SliderRowView(title: "Edge Inset", value: $settings.halo.edgeInset, range: 0...12, step: 0.5)
                    SliderRowView(title: "Core Width", value: $settings.halo.coreWidth, range: 1...16, step: 0.5)
                    SliderRowView(title: "Glow Width", value: $settings.halo.glowWidth, range: 4...48, step: 0.5)
                    SliderRowView(title: "Mist Width", value: $settings.halo.mistWidth, range: 10...90, step: 1)
                    SliderRowView(title: "Strength", value: $settings.halo.haloStrength, range: 0.1...1.4, step: 0.01)
                    SliderRowView(title: "Pulse Base", value: $settings.halo.pulseBase, range: 0...1.2, step: 0.01)
                    SliderRowView(title: "Pulse Amount", value: $settings.halo.pulseAmount, range: 0...0.9, step: 0.01)
                    SliderRowView(title: "Pulse Speed", value: $settings.halo.pulseSpeed, range: 0...8, step: 0.05)
                    SliderRowView(title: "Color Shift", value: $settings.halo.colorShiftSpeed, range: 0...0.25, step: 0.005)
                }

                // Controls mapped to `BackgroundEffectSettings`.
                DisclosureGroup("Background", isExpanded: $isBackgroundExpanded) {
                    Toggle("Show Soft Glow", isOn: $settings.background.softGlowEnabled)
                    SliderRowView(title: "Wave Amplitude", value: $settings.background.waveAmplitude, range: 0...0.22, step: 0.005)
                    SliderRowView(title: "Wave Frequency", value: $settings.background.waveFrequency, range: 0...20, step: 0.1)
                    SliderRowView(title: "Wave Speed", value: $settings.background.waveSpeed, range: 0...1.4, step: 0.01)
                    SliderRowView(title: "Glow Radius", value: $settings.background.touchGlowRadius, range: 0.05...0.9, step: 0.01)
                    SliderRowView(title: "Glow Intensity", value: $settings.background.touchGlowIntensity, range: 0...2.6, step: 0.01)
                    SliderRowView(title: "Touch Follow", value: $settings.background.touchFollowSpeed, range: 0.01...0.3, step: 0.005)
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
}

#Preview {
    SettingsSheetView(settings: .constant(.default))
}
