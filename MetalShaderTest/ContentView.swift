//
//  ContentView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import Foundation
import SwiftUI

/// Root screen composition:
/// - Metal background
/// - Optional Siri-like border halo
/// - Live FPS and personalization controls
/// Settings are persisted with `@AppStorage` as JSON.
struct ContentView: View {
    /// JSON blob containing `ViewPersonalizationSettings`.
    /// Stored in user defaults via `@AppStorage`.
    @AppStorage("viewPersonalizationSettingsData") private var personalizationData: Data = Data()
    /// Updated by `CurtainsRenderer` every ~0.5 seconds.
    @State private var fps: Double = 0
    @State private var showSettingsSheet = false
    /// Single source of truth for all user-adjustable visual parameters.
    @State private var personalization = ViewPersonalizationSettings.default

    var body: some View {
        CurtainsBackgroundView(
            fps: $fps,
            settings: personalization.background
        )
        .ignoresSafeArea()
        .overlay {
            // Halo is rendered in a separate transparent MTKView above the background.
            if personalization.halo.isVisible {
                SiriHaloBorderView(settings: personalization.halo)
                    .ignoresSafeArea()
                    // Overlay is visual only; touches should pass through to the background view.
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topLeading) {
            // Lightweight performance indicator for shader tuning.
            Text("FPS \(Int(fps.rounded()))")
                .font(.system(.subheadline, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 8, style: .continuous))
                .padding(.top, 16)
                .padding(.leading, 16)
                .contentTransition(.numericText(value: fps))
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showSettingsSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(11)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheetView(settings: $personalization)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear(perform: loadPersonalization)
        .onChange(of: personalization) { _, newValue in
            savePersonalization(newValue)
        }
    }

    /// Loads saved settings if available; keeps defaults if decode fails.
    private func loadPersonalization() {
        guard
            !personalizationData.isEmpty,
            let decoded = try? JSONDecoder().decode(
                ViewPersonalizationSettings.self,
                from: personalizationData
            )
        else {
            return
        }
        personalization = decoded
    }

    /// Persists settings after each user change.
    private func savePersonalization(_ value: ViewPersonalizationSettings) {
        guard let encoded = try? JSONEncoder().encode(value) else {
            return
        }
        personalizationData = encoded
    }
}

#Preview {
    ContentView()
}
