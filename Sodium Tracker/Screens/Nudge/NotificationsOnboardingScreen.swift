//
//  NotificationsOnboardingScreen.swift
//  Sodium Tracker
//
//  Step 7 of onboarding: the ask for notification permission. Pinch rings a
//  bell inside two expanding ripples, and two sample rows preview what a real
//  check-in looks like — built from the user's own budget, streak and reminder
//  times rather than fixed copy.
//
//  Declining here isn't the end: `NudgeEngine` picks the re-ask back up later.
//
//  Spec: Pinch Onboarding + Settings.dc.html — "Onboarding Notifications".
//

import SwiftUI

struct NotificationsOnboardingScreen: View {
    @Environment(\.salty) private var s
    @Environment(\.pinch) private var p

    let context: NudgeContext
    let step: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onAllow: () -> Void
    let onLater: () -> Void

    @State private var start = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            stage
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .padding(.top, 14)

            PinchText("A tap on the shoulder, not a siren")
                .salty(34, .heavy, tracking: -0.02)
                .foregroundStyle(s.ink)
                .padding(.top, 16)

            PinchText("Pinch checks in around meals so dinner doesn't spend what breakfast "
                 + "forgot. You stay under budget; he stays quiet the rest of the day.")
                .salty(17, .regular)
                .foregroundStyle(s.ink2)
                .lineSpacing(17 * 0.5)
                .padding(.horizontal, 6)
                .padding(.top, 10)

            VStack(spacing: 10) {
                ForEach(NudgeEngine.previews(context)) { preview in
                    previewRow(preview)
                }
            }
            .padding(.top, 22)

            Spacer(minLength: 12)

            Button(action: onAllow) {
                PinchText("Let Pinch check in")
                    .salty(17, .bold)
                    .foregroundStyle(p.onBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(p.brand))
            }
            .buttonStyle(.saltyPress(scale: 0.97))

            Button(action: onLater) {
                PinchText("Maybe later")
                    .salty(16, .semibold)
                    .foregroundStyle(s.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }
            .buttonStyle(.saltyPress(opacity: 0.6))

            stepDots.padding(.top, 18)
        }
        .padding(.horizontal, 24)
        .padding(.top, 62)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(s.screenBg.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                SaltyBackChevron()
                    .stroke(s.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .frame(width: 16, height: 16)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(s.card))
                    .saltyBellShadow(s)
            }
            .buttonStyle(.saltyPress(scale: 0.9))
            .accessibilityLabel("Back")

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(s.card.opacity(0.001).blended(over: s.track))
                    Capsule().fill(p.brand)
                        .frame(width: geo.size.width * CGFloat(step) / CGFloat(totalSteps))
                }
            }
            .frame(height: 6)

            PinchText("\(step) OF \(totalSteps)")
                .salty(12, .bold, tracking: 0.1)
                .foregroundStyle(s.ink3)
                .fixedSize()
        }
    }

    // MARK: - Stage

    private var stage: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            ZStack {
                RadialGradient(colors: [s.blueSoft, s.blueSoft.opacity(0)],
                               center: .center, startRadius: 0, endRadius: 105 * 0.68)
                    .frame(width: 210, height: 210)
                    .clipShape(Circle())

                // Two ripples on a 5 s cycle, the second a third of a beat behind.
                ForEach([0.0, 0.35], id: \.self) { delay in
                    let pr = Track(start: delay, duration: 5.0, easing: .easeOut, repeats: true)
                        .progress(t)
                    let scale = Keyframes([(0, 0.55), (0.5, 0.55), (1, 1.25)]).value(pr, .easeOut)
                    let op = Keyframes([(0, 0), (0.5, 0), (0.62, 0.55), (1, 0)]).value(pr, .easeOut)
                    Circle()
                        .strokeBorder(p.brand, lineWidth: 2)
                        .frame(width: 150, height: 150)
                        .scaleEffect(scale)
                        .opacity(op)
                }

                PinchFigure(holdingBell: true, width: 130)
            }
        }
    }

    // MARK: - Preview rows

    private func previewRow(_ preview: NudgeEngine.Preview) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(preview.isStreak ? s.amberSoft : s.blueSoft)
                if preview.isStreak {
                    SaltyStarGlyph()
                        .fill(s.star)
                        .frame(width: 15, height: 15)
                } else {
                    Circle().fill(p.brand).frame(width: 11, height: 11)
                }
            }
            .frame(width: 34, height: 34)

            PinchText(preview.text)
                .salty(15, .semibold)
                .foregroundStyle(s.ink2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            PinchText(preview.time)
                .salty(12, .bold)
                .foregroundStyle(s.ink3)
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(s.card))
        .saltyCardShadow(s)
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i == step ? p.brand : s.track)
                    .frame(width: i == step ? 20 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Glyphs

private struct SaltyBackChevron: Shape {
    func path(in rect: CGRect) -> Path {
        let k = rect.width / 16
        return Path { p in
            p.move(to: CGPoint(x: 10 * k, y: 3 * k))
            p.addLine(to: CGPoint(x: 5 * k, y: 8 * k))
            p.addLine(to: CGPoint(x: 10 * k, y: 13 * k))
        }
    }
}

private struct SaltyStarGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let k = rect.width / 16
        return Path { p in
            p.move(to: CGPoint(x: 8 * k, y: 0))
            p.addLine(to: CGPoint(x: 9.8 * k, y: 6.2 * k))
            p.addLine(to: CGPoint(x: 16 * k, y: 8 * k))
            p.addLine(to: CGPoint(x: 9.8 * k, y: 9.8 * k))
            p.addLine(to: CGPoint(x: 8 * k, y: 16 * k))
            p.addLine(to: CGPoint(x: 6.2 * k, y: 9.8 * k))
            p.addLine(to: CGPoint(x: 0, y: 8 * k))
            p.addLine(to: CGPoint(x: 6.2 * k, y: 6.2 * k))
            p.closeSubpath()
        }
    }
}

private extension Color {
    /// The design's track colour sits under the progress fill; this keeps the
    /// unfilled portion readable on both themes without a new token.
    func blended(over base: Color) -> Color { base }
}
