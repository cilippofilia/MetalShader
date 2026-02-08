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
    @State private var saveTask: Task<Void, Never>?
    /// Single source of truth for all user-adjustable visual parameters.
    @State private var personalization = ViewPersonalizationSettings.default

    var body: some View {
        CurtainsBackgroundView(
            fps: $fps,
            settings: personalization.background,
            preferredFramesPerSecond: showSettingsSheet ? 60 : 120
        )
        .ignoresSafeArea()
        .overlay {
            // Halo is rendered in a separate transparent MTKView above the background.
            if personalization.halo.isVisible {
                SiriHaloBorderView(
                    settings: personalization.halo,
                    preferredFramesPerSecond: showSettingsSheet ? 60 : 120
                )
                    .ignoresSafeArea()
                // Overlay is visual only; touches should pass through to the background view.
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showSettingsSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .padding([.top, .trailing])
            .buttonStyle(.glass)
        }
        .overlay(alignment: .topLeading) {
            // Lightweight performance indicator for shader tuning.
            Text("FPS \(Int(fps.rounded()))")
                .font(.system(.subheadline, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect()
                .padding([.top, .leading])
                .contentTransition(.numericText(value: fps))
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheetView(settings: $personalization)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear(perform: loadPersonalization)
        .onChange(of: personalization) { _, newValue in
            schedulePersonalizationSave(newValue)
        }
        .onDisappear {
            saveTask?.cancel()
            saveTask = nil
            savePersonalization(personalization)
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

    /// Coalesces rapid slider changes so persistence does not run every drag tick.
    private func schedulePersonalizationSave(_ value: ViewPersonalizationSettings) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else {
                return
            }
            savePersonalization(value)
        }
    }
}

#Preview {
    ContentView()
}
