//
//  ProgressRing.swift
//  Sodium Tracker
//
//  The Today ring: a soft tinted basin, dotted "salt grain" track, and a
//  substantial round-cap progress arc that colors and glows by zone.
//

import SwiftUI

struct ProgressRing: View {
    @Environment(\.pinch) private var p
    let consumed: Double
    let goal: Int
    var size: CGFloat = 316
    var pulse: CGFloat = 1

    private var pct: Double {
        guard goal > 0 else { return 0 }
        return Double(consumed) / Double(goal) * 100
    }

    private var baseFraction: Double { min(max(pct / 100, 0), 1) }
    private var overflowFraction: Double { min(max((pct - 100) / 100, 0), 1) }
    private var ringDiameter: CGFloat { size - 48 }
    private var discDiameter: CGFloat { size * (224.0 / 316.0) }
    private var strokeWidth: CGFloat { max(14, size * 0.073) }

    var body: some View {
        ZStack {
            Circle()
                .fill(p.isDark ? p.brandSoft.opacity(0.22) : Color(hex: 0xDFE8F3))
                .frame(width: discDiameter, height: discDiameter)
                .scaleEffect(pulse)

            // Dotted track
            Circle()
                .stroke(p.grain, style: StrokeStyle(
                    lineWidth: size * (5.0 / 316.0),
                    lineCap: .round,
                    dash: [0.1, size * (8.6 / 316.0)]
                ))
                .frame(width: ringDiameter, height: ringDiameter)

            // The blue arc always communicates the first budget. Anything
            // above 100% is a second amber lap from twelve o'clock.
            Circle()
                .trim(from: 0, to: baseFraction)
                .stroke(p.brand, style: StrokeStyle(
                    lineWidth: strokeWidth,
                    lineCap: .round
                ))
                .frame(width: ringDiameter, height: ringDiameter)
                .rotationEffect(.degrees(-90))

            if overflowFraction > 0 {
                Circle()
                    .trim(from: 0, to: overflowFraction)
                    .stroke(Color(hex: 0xDFA32B), style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    ))
                    .frame(width: ringDiameter, height: ringDiameter)
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sodium progress for the selected day")
        .accessibilityValue("\(PinchFormat.mg(Int(consumed.rounded()))) of \(PinchFormat.mg(goal)) milligrams")
    }
}
