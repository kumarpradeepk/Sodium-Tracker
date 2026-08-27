//
//  OnboardingFlow.swift
//  Sodium Tracker
//
//  Nine-step welcome shared with Android. Replayable from Settings.
//

import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui

    /// Shared with Android: setup, label education, permission, and logging.
    static let stepCount = 9

    @AppStorage(PinchDefaults.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault
    @AppStorage(PinchDefaults.notif) private var notif = true
    @AppStorage(PinchDefaults.mealRemBreakfast) private var remBreakfast = true
    @AppStorage(PinchDefaults.mealRemLunch) private var remLunch = false
    @AppStorage(PinchDefaults.mealRemDinner) private var remDinner = true
    @AppStorage(PinchDefaults.obWhy) private var storedWhy = ""
    @AppStorage(PinchDefaults.obDiet) private var storedDiet = ""
    @State private var showHealthSources = false

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    private var goalChoice: GoalChoice { GoalChoice(rawValue: goalChoiceRaw) ?? .fda }
    private var goal: Int { goalChoice.milligrams(custom: customGoal) }

    var body: some View {
        ZStack {
            // The oversized radial glow is decoration only — it lives in an
            // overlay so its 460pt frame can never widen the layout (a layout
            // child here pushes every step ~33pt off-screen).
            p.bg
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [p.brandSoft, p.brandSoft.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 230 * 0.66
                            )
                        )
                        .frame(width: 460, height: 460)
                        .offset(y: -120)
                }

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    step
                        .id(ui.obStep)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.scale(scale: 0.86).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: ui.obStep)

                    // Back button
                    if ui.obStep > 0 && ui.obStep != 6 {
                        HStack {
                            Button {
                                ui.obStep = max(0, ui.obStep - 1)
                            } label: {
                                SVGShape("M7 1 L1 7 L7 13", viewBox: CGSize(width: 8, height: 14))
                                    .stroke(p.ink2, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    .frame(width: 8, height: 13)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(p.sunk))
                            }
                            .buttonStyle(.pressScale(0.92))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                    }
                }

                // The notifications screen owns its header and progress.
                if ui.obStep != 6 {
                    HStack(spacing: 6) {
                        ForEach(0..<Self.stepCount, id: \.self) { i in
                            Capsule()
                                .fill(ui.obStep == i ? p.brand : p.grain)
                                .frame(width: ui.obStep == i ? 18 : 6, height: 6)
                                .animation(.easeInOut(duration: 0.3), value: ui.obStep)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
        }
        .transition(.opacity)
        .sheet(isPresented: $showHealthSources) {
            HealthSourcesSheet()
                .presentationDetents([.large])
        }
    }

    // MARK: - Steps

    @ViewBuilder private var step: some View {
        switch ui.obStep {
        case 0: welcome
        case 1: whyStep
        case 2: dietStep
        case 3: budgetStep
        case 4: checkinsStep
        case 5: labelStep
        case 6: notificationsStep
        case 7: fastLoggingStep
        default: allSetStep
        }
    }

    /// The design's permission ask. `checkinsStep` above chooses *which*
    /// reminders; this one asks for the system permission to send them, and a
    /// decline hands off to `NudgeEngine` to re-ask later in the app.
    private var notificationsStep: some View {
        NotificationsOnboardingScreen(
            context: nudgeContext,
            step: ui.obStep + 1,
            totalSteps: Self.stepCount,
            onBack: { ui.obStep = max(0, ui.obStep - 1) },
            onAllow: {
                notif = true
                // `refresh` is what actually prompts for authorization.
                let today = DayEngine.total(entries, on: .now, customFoods: customFoods)
                NotificationManager.refresh(remaining: goal - today)
                NudgeEngine.recordAccepted(state: NudgeState.load()).save()
                advance()
            },
            onLater: {
                // Deferring a system permission must not prompt later as a
                // side effect of entering the dashboard. Start the normal
                // re-ask cooldown from today instead.
                notif = false
                var state = NudgeState.load()
                state.lastAskDay = Calendar.current.startOfDay(for: .now).timeIntervalSinceReferenceDate
                state.save()
                advance()
            }
        )
    }

    /// Live numbers for the preview rows, so onboarding promises what the app
    /// will actually send.
    private var nudgeContext: NudgeContext {
        NudgeContext(
            goal: (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal),
            consumed: 0,
            streak: 0,
            breakfastTime: "8:00 AM",
            lunchTime: "12:30 PM",
            dinnerTime: "6:30 PM"
        )
    }

    private var welcome: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 64)
            ZStack {
                PinchFigure(width: 170)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(p.amber)
                    .offset(x: -82, y: -47)
                Image(systemName: "sparkle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(p.brand)
                    .offset(x: 80, y: -62)
            }
            PinchText("Meet Pinch")
                .pinchDisplay(34, .heavy)
                .foregroundStyle(p.ink)
                .padding(.top, 26)
            PinchText("The kindest way to watch your sodium. One number a day, a friend who keeps count with you.")
                .pinchBody(15)
                .foregroundStyle(p.ink2)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .frame(maxWidth: 280)
                .padding(.top, 10)
            Spacer()
            PinchCTA(title: "Nice to meet you") { advance() }
            Button {
                if !hasOnboarded { notif = false }
                finish()
            } label: {
                PinchText("Skip the tour")
                    .pinchBody(13, .semibold)
                    .foregroundStyle(p.ink3)
            }
            .padding(.top, 14)
        }
        .padding(EdgeInsets(top: 40, leading: 32, bottom: 24, trailing: 32))
    }

    // Step 1 — why

    private struct Choice: Identifiable {
        let id: String
        let title: String
        let sub: String
    }

    private let whyChoices: [Choice] = [
        Choice(id: "doctor", title: "Doctor recommended", sub: "A clinician gave me a number"),
        Choice(id: "bp", title: "Blood pressure", sub: "Keeping BP in a friendly range"),
        Choice(id: "healthy", title: "Healthy lifestyle", sub: "Just eating smarter"),
        Choice(id: "curious", title: "Curious", sub: "Exploring what I actually eat"),
    ]

    private var whyStep: some View {
        stepScaffold(
            title: "Why count sodium?",
            sub: "So Pinch knows how to help — and what to suggest.",
            ctaTitle: "Continue",
            ctaEnabled: ui.obWhy != nil
        ) {
            VStack(spacing: 10) {
                ForEach(whyChoices) { choice in
                    RadioCard(selected: ui.obWhy == choice.id, action: {
                        ui.obWhy = choice.id
                        storedWhy = choice.id
                        goalChoiceRaw = (choice.id == "doctor" || choice.id == "bp")
                            ? GoalChoice.aha.rawValue
                            : GoalChoice.fda.rawValue
                    }) {
                        choiceLabel(choice)
                    }
                }
            }
        }
    }

    private let dietChoices: [Choice] = [
        Choice(id: "work", title: "Could use some work", sub: "Lots of takeout and quick fixes"),
        Choice(id: "mid", title: "Somewhere in the middle", sub: "Trying, most days"),
        Choice(id: "good", title: "Pretty healthy", sub: "Mostly home-cooked"),
    ]

    private var dietStep: some View {
        stepScaffold(
            title: "How's the plate lately?",
            sub: "No judgment — it just tunes Pinch's tips.",
            ctaTitle: "Continue",
            ctaEnabled: ui.obDiet != nil
        ) {
            VStack(spacing: 10) {
                ForEach(dietChoices) { choice in
                    RadioCard(selected: ui.obDiet == choice.id, action: {
                        ui.obDiet = choice.id
                        storedDiet = choice.id
                    }) {
                        choiceLabel(choice)
                    }
                }
            }
        }
    }

    private func choiceLabel(_ choice: Choice) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            PinchText(choice.title)
                .pinchBody(15, .bold)
                .foregroundStyle(p.ink)
            PinchText(choice.sub)
                .pinchBody(12)
                .foregroundStyle(p.ink3)
        }
    }

    // Step 3 — budget

    private var suggested: GoalChoice {
        (ui.obWhy == "doctor" || ui.obWhy == "bp") ? .aha : .fda
    }

    private var budgetStep: some View {
        stepScaffold(
            title: "Set your salt budget",
            sub: "Milligrams of sodium per day. You can change it anytime.",
            ctaTitle: "Set my budget · \(PinchFormat.mg(goal)) mg",
            ctaEnabled: true,
            footnote: "Not medical advice — ask your doctor what's right for you."
        ) {
            VStack(spacing: 10) {
                goalCard(.aha, mg: "1,500", title: "Lower target", sub: "General AHA guidance")
                goalCard(.fda, mg: "2,300", title: "Standard target", sub: "General FDA guidance")
                goalCard(.custom, mg: PinchFormat.mg(customGoal), title: "Custom", sub: "Slide to your prescribed number")

                if goalChoice == .custom {
                    VStack(spacing: 4) {
                        Slider(
                            value: Binding(
                                get: { Double(customGoal) },
                                set: { customGoal = Int($0 / 50) * 50 }
                            ),
                            in: Double(PinchDefaults.customGoalRange.lowerBound)...Double(PinchDefaults.customGoalRange.upperBound)
                        )
                        .tint(p.brand)
                        HStack {
                            PinchText("500")
                            Spacer()
                            PinchText("4,000")
                        }
                        .pinchBody(11)
                        .foregroundStyle(p.ink3)
                    }
                    .padding(.top, 6)
                    .padding(.horizontal, 6)
                }

                Button {
                    showHealthSources = true
                } label: {
                    HStack(spacing: 6) {
                        PinchText("Sources & health information")
                            .pinchBody(12, .bold)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(p.brand)
                    .padding(.top, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func goalCard(_ choice: GoalChoice, mg: String, title: String, sub: String) -> some View {
        RadioCard(selected: goalChoice == choice, action: { goalChoiceRaw = choice.rawValue }) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        PinchText(title)
                            .pinchBody(15, .bold)
                            .foregroundStyle(p.ink)
                        if ui.obWhy != nil && choice == suggested {
                            PinchText("SUGGESTED")
                                .pinchBody(8.5, .heavy, tracking: 0.09)
                                .foregroundStyle(p.amber)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(p.amberSoft))
                        }
                    }
                    PinchText(sub)
                        .pinchBody(12)
                        .foregroundStyle(p.ink3)
                }
                Spacer(minLength: 4)
                PinchText(mg)
                    .font(PinchFonts.display(20, .heavy))
                    .monospacedDigit()
                    .foregroundStyle(p.ink)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // Step 4 — check-ins

    private var checkinsStep: some View {
        stepScaffold(
            title: "Meal check-ins",
            sub: "Pick when Pinch should wave. No streak-shaming, no red badges.",
            ctaTitle: "Save check-ins",
            ctaEnabled: true
        ) {
            VStack(alignment: .leading, spacing: 0) {
                PinchCard {
                    VStack(spacing: 0) {
                        checkinRow("Breakfast", time: "8:00 AM", isOn: $remBreakfast, first: true)
                        checkinRow("Lunch", time: "12:30 PM", isOn: $remLunch)
                        checkinRow("Dinner", time: "6:30 PM", isOn: $remDinner)
                    }
                }
                PinchText("Quiet hours respected, always. Tune times later in Settings.")
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func checkinRow(_ name: String, time: String, isOn: Binding<Bool>, first: Bool = false) -> some View {
        HStack(spacing: 10) {
            PinchText(name)
                .pinchBody(14, .semibold)
                .foregroundStyle(p.ink)
            Spacer()
            PinchText(time)
                .pinchBody(12, .bold)
                .monospacedDigit()
                .foregroundStyle(p.ink2)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Capsule().fill(p.sunk))
            PinchSwitch(isOn: isOn)
        }
        .padding(EdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16))
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    // Step 5 — label units

    private var labelStep: some View {
        stepScaffold(
            title: "Read either label unit",
            sub: "Pinch stores sodium in milligrams, even when the label gives salt in grams.",
            ctaTitle: "Got it",
            ctaEnabled: true
        ) {
            PinchCard(padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)) {
                VStack(spacing: 0) {
                    Circle()
                        .fill(p.brandSoft)
                        .frame(width: 52, height: 52)
                        .overlay(
                            LineIcon(
                                d: "M4 15 H16 M6 15 L8 5 H12 L14 15 M7 8 H13",
                                size: 24,
                                stroke: 1.9,
                                color: p.brand
                            )
                        )
                    PinchText("1 g salt ≈ 393 mg sodium")
                        .pinchDisplay(22, .bold)
                        .foregroundStyle(p.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 14)
                    PinchText("Choose Sodium mg or Salt g in Quick log and New food. Pinch does the conversion before saving.")
                        .pinchBody(12.5)
                        .foregroundStyle(p.ink2)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
        }
    }

    private func benefitRow(tile: Color, icon: String, color: Color, text: String, strokeWidth: CGFloat = 1.7) -> some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tile)
                .frame(width: 32, height: 32)
                .overlay(LineIcon(d: icon, size: 16, stroke: strokeWidth, color: color))
            PinchText(text)
                .pinchBody(13.5, .semibold)
                .foregroundStyle(p.ink)
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 13, leading: 15, bottom: 13, trailing: 15))
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(p.line, lineWidth: 1)
        )
    }

    // Step 7 — fast logging

    private var fastLoggingStep: some View {
        stepScaffold(
            title: "Logging stays quick",
            sub: "Use the path that matches what's in front of you.",
            ctaTitle: "One more step",
            ctaEnabled: true
        ) {
            VStack(spacing: 10) {
                loggingBenefit(
                    icon: "M8.5 14.5 A6 6 0 1 1 14.5 8.5 M13 13 L18 18",
                    title: "Search the shelf",
                    sub: "Pick a serving and meal"
                )
                loggingBenefit(
                    icon: "M10 3 V17 M3 10 H17",
                    title: "Quick log",
                    sub: "Enter the number from a label",
                    strokeWidth: 2.0
                )
                loggingBenefit(
                    icon: "M10 17 C10 17 2.5 12.5 2.5 7.5 C2.5 5 4.5 3 7 3 C8.3 3 9.4 3.6 10 4.5 C10.6 3.6 11.7 3 13 3 C15.5 3 17.5 5 17.5 7.5 C17.5 12.5 10 17 10 17 Z",
                    title: "Pin regulars",
                    sub: "Keep everyday foods one tap away"
                )
            }
        }
    }

    private func loggingBenefit(icon: String, title: String, sub: String, strokeWidth: CGFloat = 1.7) -> some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(p.brandSoft)
                .frame(width: 38, height: 38)
                .overlay(LineIcon(d: icon, size: 18, stroke: strokeWidth, color: p.brand))
            VStack(alignment: .leading, spacing: 2) {
                PinchText(title)
                    .pinchBody(14, .bold)
                    .foregroundStyle(p.ink)
                PinchText(sub)
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(p.line, lineWidth: 1)
        )
    }

    // Step 7 — all set

    private var allSetStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 54)
            PinchFigure(width: 140)
            PinchText("You're all set")
                .pinchDisplay(32, .heavy)
                .foregroundStyle(p.ink)
                .padding(.top, 22)
            PinchText("A clean page, a clear number, and Pinch beside you.")
                .pinchBody(14)
                .foregroundStyle(p.ink2)
                .padding(.top, 8)

            PinchCard {
                VStack(spacing: 0) {
                    summaryRow("Daily budget", value: "\(PinchFormat.mg(goal)) mg", first: true)
                    summaryRow("Why", value: whyLabel)
                    summaryRow("Check-ins", value: "\(checkinCount)")
                }
            }
            .padding(.top, 20)

            Spacer()
            PinchCTA(title: "Start tracking") { finish() }
        }
        .padding(EdgeInsets(top: 40, leading: 28, bottom: 24, trailing: 28))
    }

    private var whyLabel: String {
        whyChoices.first { $0.id == ui.obWhy }?.title ?? "—"
    }

    private var checkinCount: Int {
        [remBreakfast, remLunch, remDinner].filter { $0 }.count
    }

    private func summaryRow(_ label: String, value: String, first: Bool = false) -> some View {
        HStack {
            PinchText(label)
                .pinchBody(13)
                .foregroundStyle(p.ink3)
            Spacer()
            PinchText(value)
                .pinchBody(13, .bold)
                .monospacedDigit()
                .foregroundStyle(p.ink)
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    // MARK: - Scaffold & flow

    private func stepScaffold<Content: View>(
        title: String,
        sub: String,
        ctaTitle: String,
        ctaEnabled: Bool,
        footnote: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 44)
            PinchText(title)
                .pinchDisplay(28, .heavy)
                .foregroundStyle(p.ink)
            PinchText(sub)
                .pinchBody(13.5)
                .foregroundStyle(p.ink2)
                .lineSpacing(3)
                .padding(.top, 6)

            ScrollView {
                content()
                    .padding(.top, 20)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            if let footnote {
                PinchText(footnote)
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 14)
            }
            PinchCTA(title: ctaTitle, enabled: ctaEnabled) {
                advance()
            }
        }
        .padding(EdgeInsets(top: 40, leading: 24, bottom: 24, trailing: 24))
    }

    private func advance() {
        if ui.obStep == 1, ui.obWhy == nil { return }
        if ui.obStep == 2, ui.obDiet == nil { return }
        if ui.obStep < Self.stepCount - 1 {
            ui.obStep += 1
        } else {
            finish()
        }
    }

    private func finish() {
        hasOnboarded = true
        ui.showOnboarding = false
        ui.tab = .today
        ui.selOffset = 0
        let remaining = goal - DayEngine.total(entries, on: .now, customFoods: customFoods)
        if notif {
            NotificationManager.refresh(remaining: remaining)
        }
    }
}
