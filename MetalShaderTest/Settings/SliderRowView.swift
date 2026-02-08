//
//  SliderRowView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 08/02/2026.
//

import SwiftUI

/// Reusable labeled slider row with a monospaced numeric value.
struct SliderRowView: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                // Fixed precision keeps layout stable while dragging.
                Text(value.formatted(.number.precision(.fractionLength(2))))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

#Preview {
    SliderRowView(
        title: "Test title",
        value: .constant(0.0),
        range: 0.0...5.0,
        step: 1.0
    )
}
