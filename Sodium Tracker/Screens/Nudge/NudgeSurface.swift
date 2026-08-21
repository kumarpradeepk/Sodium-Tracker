//
//  NudgeSurface.swift
//  Sodium Tracker
//
//  The in-app re-ask. One view renders all four of the design's surfaces —
//  they share a body (title, copy, a preview of the notification itself, an
//  accept and a decline) and differ only in how they arrive:
//
//    Morning / Streak  full-screen takeover
//    Lunch             banner dropping from the top
//    Dinner            centred dialog over a scrim
//
//  All copy comes from `NudgeEngine.nudge(for:context:)`, so every number is
//  the user's own.
//
//  Spec: Pinch Onboarding + Settings.dc.html — "Re-ask A/B/C/D".
//

import SwiftUI

struct NudgeSurface: View {
    @Environment(\.salty) private var s
    @Environment(\.pinch) private var p

    let nudge: Nudge
    let onAccept: () -> Void
    let onDismiss: () -> Void

    @State private var shown = false

    /// How this segment enters, per the design.
    private enum Style { case fullScreen, banner, dialog }
    private var style: Style {
        switch nudge.segment {
        case .morning, .streak: return .fullScreen
        case .lunch: return .banner
        case .dinner: return .dialog
        }
    }

    var body: some View {
        Group {
            switch style {
            case .fullScreen: fullScreen
            case .banner: banner
            case .dialog: dialog
            }
        }
        .onAppear {
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.6)) { shown = true }
        }
    }

    // MARK: - Full screen (morning, streak)

    private var fullScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            PinchFigure(holdingBell: true, width: 130)
                .frame(maxWidth: .infinity)

            PinchText(nudge.title)
                .salty(32, .heavy, tracking: -0.02)
                .foregroundStyle(s.ink)
                .padding(.top, 22)

            PinchText(nudge.body)
                .salty(16.5, .regular)
                .foregroundStyle(s.ink2)
                .lineSpacing(16.5 * 0.5)
                .padding(.top, 10)

            preview.padding(.top, 20)

            Spacer(minLength: 12)
            actions
        }
        .padding(.horizontal, 24)
        .padding(.top, 70)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(s.screenBg.ignoresSafeArea())
        .opacity(shown ? 1 : 0)
    }

    // MARK: - Banner (lunch)

    private var banner: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    PinchFigure(width: 54)
                    VStack(alignment: .leading, spacing: 4) {
                        PinchText(nudge.title)
                            .salty(16, .heavy)
                            .foregroundStyle(s.ink)
                        PinchText(nudge.body)
                            .salty(14, .regular)
                            .foregroundStyle(s.ink2)
                            .lineSpacing(3)
                    }
                }
                HStack(spacing: 16) {
                    Button(action: onAccept) {
                        PinchText(nudge.primary)
                            .salty(14, .bold)
                            .foregroundStyle(p.brand)
                    }
                    .buttonStyle(.saltyPress(opacity: 0.6))
                    Button(action: onDismiss) {
                        PinchText(nudge.dismiss)
                            .salty(14, .semibold)
                            .foregroundStyle(s.ink3)
                    }
                    .buttonStyle(.saltyPress(opacity: 0.6))
                    Spacer()
                }
                .padding(.top, 12)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(s.card))
            .saltySheetShadow(s)
            .padding(.horizontal, 16)
            // bannerIn: translateY(-120%) → 0 with the fade.
            .offset(y: shown ? 0 : -220)
            .opacity(shown ? 1 : 0)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Dialog (dinner)

    private var dialog: some View {
        ZStack {
            s.scrim
                .opacity(shown ? 1 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 0) {
                PinchFigure(holdingBell: true, width: 104)

                PinchText(nudge.title)
                    .salty(24, .heavy)
                    .foregroundStyle(s.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                PinchText(nudge.body)
                    .salty(15, .regular)
                    .foregroundStyle(s.ink2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 8)

                preview.padding(.top, 16)
                actions.padding(.top, 18)
            }
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(s.screenBg))
            .saltySheetShadow(s)
            .padding(.horizontal, 24)
            // dialogIn: scale .88 + translateY 14 → identity.
            .scaleEffect(shown ? 1 : 0.88)
            .offset(y: shown ? 0 : 14)
            .opacity(shown ? 1 : 0)
        }
    }

    // MARK: - Shared parts

    /// The mock notification the design shows — Pinch's own row, with the
    /// pinging dot and the time this user would actually receive it.
    private var preview: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(p.brand)
                Circle().fill(.white).frame(width: 10, height: 10)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    PinchText("Pinch")
                        .salty(13, .heavy)
                        .foregroundStyle(s.ink)
                    Spacer()
                    PinchText(nudge.previewTime)
                        .salty(11, .regular)
                        .foregroundStyle(s.ink3)
                }
                PinchText(nudge.previewBody)
                    .salty(13.5, .regular)
                    .foregroundStyle(s.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(s.card))
        .saltyCardShadow(s)
    }

    private var actions: some View {
        VStack(spacing: 0) {
            Button(action: onAccept) {
                PinchText(nudge.primary)
                    .salty(17, .bold)
                    .foregroundStyle(p.onBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(p.brand))
            }
            .buttonStyle(.saltyPress(scale: 0.97))

            PinchText(nudge.caption)
                .salty(12.5, .regular)
                .foregroundStyle(s.ink3)
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            Button(action: onDismiss) {
                PinchText(nudge.dismiss)
                    .salty(15, .semibold)
                    .foregroundStyle(s.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
            }
            .buttonStyle(.saltyPress(opacity: 0.6))
        }
    }
}
