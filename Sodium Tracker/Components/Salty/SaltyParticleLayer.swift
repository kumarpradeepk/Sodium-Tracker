//
//  SaltyParticleLayer.swift
//  Sodium Tracker
//
//  Flying "+N mg" pills and sparkle bursts. Sits above the screen content and
//  below nothing, non-interactive, clipped to the screen — the prototype's
//  `fxEl` layer.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §10
//

import SwiftUI

struct SaltyParticleLayer: View {
    @Environment(\.salty) private var s
    let engine: SaltyEngine

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(engine.particles) { particle in
                switch particle.kind {
                case let .fly(from, control, to, label):
                    flyPill(particle, from: from, control: control, to: to, label: label)
                case let .spark(colorIndex, size):
                    spark(particle, colorIndex: colorIndex, size: size)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Fly pill

    private func flyPill(
        _ p: SaltyParticle,
        from source: CGPoint,
        control: CGPoint,
        to target: CGPoint,
        label: String
    ) -> some View {
        let u = engine.progress(of: p)
        // The prototype eases the curve with smoothstep, not the named easing.
        let e = u * u * (3 - 2 * u)
        let i = 1 - e
        let x = i * i * source.x + 2 * i * e * control.x + e * e * target.x
        let y = i * i * source.y + 2 * i * e * control.y + e * e * target.y

        return PinchText(label)
            .saltyNum(15, .heavy)
            .foregroundStyle(s.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(s.card))
            .shadow(color: s.shadowTint.opacity(0.25), radius: 9, y: 6)
            .scaleEffect(1 - 0.3 * e)
            // Holds full opacity, then fades over the last 15%.
            .opacity(u > 0.85 ? (1 - u) / 0.15 : 1)
            .position(x: x, y: y)
    }

    // MARK: - Sparkle

    private func spark(_ p: SaltyParticle, colorIndex: Int, size: CGFloat) -> some View {
        let u = engine.progress(of: p)
        return PinchText("✦")
            .font(.system(size: size))
            .foregroundStyle(s.sparkleColors[colorIndex])
            .rotationEffect(.degrees(p.rotation))
            .opacity(max(0, 1 - u))
            .position(x: p.position.x, y: p.position.y)
    }
}
