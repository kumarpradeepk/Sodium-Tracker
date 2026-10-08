//
//  NudgeHost.swift
//  Sodium Tracker
//
//  Asks `NudgeEngine` whether this moment deserves a re-ask, and presents the
//  matching surface if so. This is the only place the cadence is consulted —
//  it runs once when the Today screen appears, never mid-session, so a nudge
//  can't interrupt something the user is doing.
//
//  Spec: Pinch Onboarding + Settings.dc.html — "Re-ask A/B/C/D".
//

import SwiftUI
import SwiftData

struct NudgeHost: ViewModifier {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(PinchDefaults.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PinchDefaults.notif) private var notif = true
    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    @State private var active: Nudge?

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    private var context: NudgeContext {
        NudgeContext(
            goal: goal,
            consumed: DayEngine.total(entries, on: .now, customFoods: customFoods),
            streak: DayEngine.streak(entries),
            breakfastTime: PinchFormat.clock(hour: 8, minute: 0),
            lunchTime: PinchFormat.clock(hour: 12, minute: 30),
            dinnerTime: PinchFormat.clock(hour: 18, minute: 30)
        )
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if let nudge = active {
                    NudgeSurface(
                        nudge: nudge,
                        onAccept: { accept(nudge) },
                        onDismiss: { decline() }
                    )
                    .transition(.opacity)
                    .zIndex(90)
                }
            }
            .animation(.easeOut(duration: 0.3), value: active?.segment)
            .task { evaluate() }
    }

    /// One consultation per appearance. Everything that decides whether to show
    /// anything lives in the engine; this only supplies live facts.
    private func evaluate() {
        guard hasOnboarded, active == nil else { return }
        let state = NudgeState.load()
        guard let segment = NudgeEngine.segment(
            remindersEnabled: notif,
            state: state,
            context: context
        ) else { return }

        NudgeEngine.recordShown(segment, state: state).save()
        active = NudgeEngine.nudge(for: segment, context: context)
    }

    private func accept(_ nudge: Nudge) {
        notif = true
        // Switch on the reminder this surface actually promised.
        switch nudge.segment.meal {
        case .breakfast: UserDefaults.standard.set(true, forKey: PinchDefaults.mealRemBreakfast)
        case .lunch: UserDefaults.standard.set(true, forKey: PinchDefaults.mealRemLunch)
        default: UserDefaults.standard.set(true, forKey: PinchDefaults.mealRemDinner)
        }
        NotificationManager.refresh(remaining: goal - context.consumed)
        NudgeEngine.recordAccepted(state: NudgeState.load()).save()
        active = nil
    }

    private func decline() {
        NudgeEngine.recordDeclined(state: NudgeState.load()).save()
        active = nil
    }
}

extension View {
    /// Lets `NudgeEngine` re-ask for notification permission on this screen.
    func nudgeHost() -> some View { modifier(NudgeHost()) }
}
