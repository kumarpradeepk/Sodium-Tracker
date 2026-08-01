//
//  SodiumRing.swift
//  Sodium Tracker
//

import SwiftUI

/// Circular gauge of the day's sodium against the goal.
///
/// Once the goal is passed, a thinner inner ring tracks the overflow so the
/// amount over the limit stays readable instead of pinning at full.
struct SodiumRing: View {
    let total: Int
    let goal: Int
    var lineWidth: CGFloat = 20

    private var status: IntakeStatus {
        IntakeStatus(total: total, goal: goal)
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return Double(total) / Double(goal)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.track, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    status.tint.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if progress > 1 {
                Circle()
                    .trim(from: 0, to: min(progress - 1, 1))
                    .stroke(
                        Theme.over,
                        style: StrokeStyle(lineWidth: lineWidth * 0.45, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(lineWidth * 0.8)
            }

            centerLabel
        }
        .animation(.snappy, value: total)
        .animation(.snappy, value: goal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sodium today")
        .accessibilityValue(
            "\(Format.milligrams(total)) of \(Format.milligrams(goal)). \(status.label)."
        )
    }

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text(Format.number(total))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("of \(Format.milligrams(goal))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, lineWidth * 2)
    }
}

#Preview("Under goal") {
    SodiumRing(total: 900, goal: 2300)
        .frame(width: 220, height: 220)
        .padding()
}

#Preview("Over goal") {
    SodiumRing(total: 3100, goal: 2300)
        .frame(width: 220, height: 220)
        .padding()
}
