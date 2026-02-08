//
//  ContentView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 07/02/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var fps: Double = 0
    @State private var backgroundStyle: BackgroundStyle = .deepBlueCurtains

    private let phoneCornerRadius: CGFloat = 60

    var body: some View {
        CurtainsBackgroundView(fps: $fps, style: backgroundStyle)
            .ignoresSafeArea()
            .overlay {
                SiriHaloBorderView(cornerRadius: phoneCornerRadius)
                    .ignoresSafeArea()
            }
            .overlay(alignment: .topLeading) {
                Text("FPS \(Int(fps.rounded()))")
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 8, style: .continuous))
                    .padding(.top, 16)
                    .padding(.leading, 16)
                    .contentTransition(.numericText(value: fps))
            }
            .overlay(alignment: .bottom) {
                Picker("Background", selection: $backgroundStyle) {
                    ForEach(BackgroundStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .padding()
            }
    }
}

#Preview {
    ContentView()
}
