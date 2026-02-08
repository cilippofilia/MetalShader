//
//  SiriHaloBorderView.swift
//  MetalShaderTest
//
//  Created by Filippo Cilia on 08/02/2026.
//

import SwiftUI

struct SiriHaloBorderView: View {
    let cornerRadius: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let rotation = Angle.degrees((time * 70).truncatingRemainder(dividingBy: 360))
            let pulse = 0.7 + (sin(time * 2.8) * 0.22)

            let gradient = AngularGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.18, green: 0.88, blue: 1.0), location: 0.00),
                    .init(color: Color(red: 0.13, green: 0.53, blue: 1.0), location: 0.20),
                    .init(color: Color(red: 0.70, green: 0.33, blue: 1.0), location: 0.44),
                    .init(color: Color(red: 1.00, green: 0.40, blue: 0.72), location: 0.62),
                    .init(color: Color(red: 1.00, green: 0.63, blue: 0.36), location: 0.80),
                    .init(color: Color(red: 0.22, green: 0.92, blue: 0.98), location: 1.00)
                ]),
                center: .center,
                angle: rotation
            )

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .inset(by: 1.5)
                    .stroke(gradient, lineWidth: 12)
                    .opacity(0.9)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .inset(by: 0.5)
                    .stroke(gradient, lineWidth: 12)
                    .blur(radius: 12)
                    .opacity(0.55 * pulse)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .inset(by: -3)
                    .stroke(gradient, lineWidth: 24)
                    .blur(radius: 28)
                    .opacity(0.24 * pulse)
            }
            .blendMode(.screen)
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    SiriHaloBorderView(cornerRadius: 12)
}
