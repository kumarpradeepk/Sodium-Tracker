//
//  ProgressRing.swift
//  Sodium Tracker
//
//  The Today ring: a dotted "salt grain" track (r 96 in a 230 viewBox, dash
//  0.1/7.4) with an 11px round-cap progress arc that colors and glows by zone,
//  over a soft radial halo.
//

import SwiftUI

struct ProgressRing: View {
    @Environment(\.pinch) private var p
    let consumed: Int
    let goal: Int
    var size: CGFloat = 250

    private var pct: Double {
        guard goal > 0 else { return 0 }
        return Double(consumed) / Double(goal) * 100
    }

    private var scale: CGFloat { size / 230 }

    var body: some View {
        ZStack {
            // Radial halo (design: inset -30, brandSoft → transparent 68%)
            RadialGradient(
                colors: [p.brandSoft, p.brandSoft.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: (size + 60) / 2 * 0.68
            )
            .frame(width: size + 60, height: size + 60)
            .clipShape(Circle())

            // Dotted track
            Circle()
                .stroke(p.grain, style: StrokeStyle(
                    lineWidth: 3 * scale,
                    lineCap: .round,
                    dash: [0.1 * scale, 7.4 * scale]
                ))
                .frame(width: 192 * scale, height: 192 * scale)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(pct, 100) / 100)
                .stroke(p.ringColor(pct: pct), style: StrokeStyle(
                    lineWidth: 11 * scale,
                    lineCap: .round
                ))
                .frame(width: 192 * scale, height: 192 * scale)
                .rotationEffect(.degrees(-90))
                .shadow(color: p.ringGlow(pct: pct), radius: 4, y: 2)
                .animation(.timingCurve(0.25, 0.9, 0.3, 1, duration: 0.8), value: pct)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sodium progress")
        .accessibilityValue("\(PinchFormat.mg(consumed)) of \(PinchFormat.mg(goal)) milligrams")
    }
}
