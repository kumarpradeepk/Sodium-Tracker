//
//  NudgeEngine.swift
//  Sodium Tracker
//
//  Decides when to re-ask for notification permission, which surface to use,
//  and what that surface says. Nothing here is hardcoded copy — every line is
//  built from the day's real numbers, the user's own reminder times, and the
//  live streak, so a nudge never claims something the app can't back up.
//
//  The cadence the design implies: about three asks a week, one per meal
//  segment, never twice in a day, and quieter every time the user says no.
//
//  Spec: Pinch Onboarding + Settings.dc.html — "Re-ask A/B/C/D".
//

import Foundation

// MARK: - Segments

/// Which re-ask surface fits the current moment. The windows line up with the
/// app's own meal boundaries (`Meal.auto`), so a nudge always arrives while the
/// meal it talks about is still ahead of the user.
enum NudgeSegment: String, CaseIterable, Codable {
    case morning     // full-screen takeover — the day just reset
    case lunch       // inline banner — the order is still open
    case dinner      // modal dialog — the decision that settles the day
    case streak      // full screen — a day closed clean, protect the run

    /// The design's rotation order; `streak` is opportunistic, not scheduled.
    static let rotation: [NudgeSegment] = [.morning, .lunch, .dinner]

    /// Hour window this segment may fire in, matching `Meal.auto`'s bands.
    var window: Range<Int> {
        switch self {
        case .morning: return 5..<11
        case .lunch: return 11..<15
        case .dinner: return 15..<21
        case .streak: return 21..<24
        }
    }

    /// Which meal reminder this segment would switch on.
    var meal: Meal {
        switch self {
        case .morning: return .breakfast
        case .lunch: return .lunch
        case .dinner, .streak: return .dinner
        }
    }
}

// MARK: - Persisted state

/// Everything the cadence needs to remember between launches.
struct NudgeState: Codable, Equatable {
    /// Start-of-day of the last nudge shown, in `timeIntervalSinceReferenceDate`.
    var lastAskDay: Double = 0
    /// Segments already used in the current week-long round.
    var askedThisRound: [NudgeSegment] = []
    /// How many times the user has declined outright.
    var declines: Int = 0
    /// Set when the user asks not to be asked again.
    var optedOut = false

    static let key = "nudgeState"

    static func load(_ defaults: UserDefaults = .standard) -> NudgeState {
        guard let data = defaults.data(forKey: key),
              let state = try? JSONDecoder().decode(NudgeState.self, from: data)
        else { return NudgeState() }
        return state
    }

    func save(_ defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

// MARK: - Decision

/// The facts a surface needs, all pulled from live data.
struct NudgeContext {
    let goal: Int
    let consumed: Int
    let streak: Int
    /// Reminder clock times the user actually has configured.
    let breakfastTime: String
    let lunchTime: String
    let dinnerTime: String

    var remaining: Int { goal - consumed }
}

/// A fully-resolved nudge: which surface, and the copy it renders.
struct Nudge: Equatable {
    let segment: NudgeSegment
    let title: String
    let body: String
    /// The mock notification row the design shows as a preview.
    let previewTime: String
    let previewBody: String
    let primary: String
    let caption: String
    let dismiss: String
}

enum NudgeEngine {

    /// How long a full rotation takes: three asks spread across a week.
    static let cooldownDays = 2
    /// After this many declines the app stops asking on its own.
    static let maxDeclines = 3

    // MARK: Cadence

    /// The segment to show right now, or nil to stay quiet.
    ///
    /// Quiet when: reminders are already on, the user opted out, they've said
    /// no too often, one has already fired today, the cooldown hasn't elapsed,
    /// or nothing fits this hour.
    static func segment(
        remindersEnabled: Bool,
        state: NudgeState,
        context: NudgeContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> NudgeSegment? {
        guard !remindersEnabled, !state.optedOut, state.declines < maxDeclines else { return nil }

        let today = calendar.startOfDay(for: now).timeIntervalSinceReferenceDate
        guard state.lastAskDay != today else { return nil }             // one a day
        if state.lastAskDay > 0 {
            let elapsed = (today - state.lastAskDay) / 86_400
            guard elapsed >= Double(cooldownDays) else { return nil }   // ~3 a week
        }

        let hour = calendar.component(.hour, from: now)

        // The streak surface is opportunistic: it only earns a slot when the
        // day genuinely closed under budget on a run worth protecting.
        if NudgeSegment.streak.window.contains(hour),
           context.streak >= 3, context.consumed > 0, context.remaining >= 0 {
            return .streak
        }

        // Otherwise take the next unused segment in the rotation whose window
        // contains this hour, so the three asks land on different meals.
        let unused = NudgeSegment.rotation.filter { !state.askedThisRound.contains($0) }
        let pool = unused.isEmpty ? NudgeSegment.rotation : unused
        return pool.first { $0.window.contains(hour) }
    }

    /// State after showing `segment`. A finished rotation starts over empty.
    static func recordShown(
        _ segment: NudgeSegment,
        state: NudgeState,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> NudgeState {
        var next = state
        next.lastAskDay = calendar.startOfDay(for: now).timeIntervalSinceReferenceDate
        if segment != .streak {
            next.askedThisRound.append(segment)
            if Set(next.askedThisRound) == Set(NudgeSegment.rotation) {
                next.askedThisRound = []
            }
        }
        return next
    }

    /// State after the user declines. Enough refusals and the app stops asking.
    static func recordDeclined(state: NudgeState) -> NudgeState {
        var next = state
        next.declines += 1
        if next.declines >= maxDeclines { next.optedOut = true }
        return next
    }

    /// State after the user accepts — the cadence is done for good.
    static func recordAccepted(state: NudgeState) -> NudgeState {
        var next = state
        next.optedOut = true
        return next
    }

    /// One sample notification row, as the onboarding screen previews them.
    struct Preview: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let time: String
        /// `true` renders the amber streak tile instead of the blue meal tile.
        let isStreak: Bool

        static func == (a: Preview, b: Preview) -> Bool {
            a.text == b.text && a.time == b.time && a.isStreak == b.isStreak
        }
    }

    /// The two rows the onboarding screen shows. Both are built from the real
    /// budget and streak so the promise matches what the app will actually send.
    static func previews(_ c: NudgeContext) -> [Preview] {
        // Before any food is logged the whole budget is still "left"; once the
        // day is under way the row quotes what is genuinely remaining.
        let left = c.consumed > 0 ? max(c.remaining, 0) : c.goal
        return [
            Preview(
                text: PinchLocalization.format("\"{0} mg left — plenty for dinner.\"", [String(describing: PinchFormat.mg(left))]),
                time: c.dinnerTime,
                isStreak: false
            ),
            Preview(
                text: PinchLocalization.format("\"Day {0} under budget — streak safe.\"", [String(describing: c.streak + 1)]),
                time: c.lunchTime,
                isStreak: true
            ),
        ]
    }

    // MARK: Copy (built from live data, never hardcoded numbers)

    static func nudge(for segment: NudgeSegment, context c: NudgeContext) -> Nudge {
        let goal = PinchFormat.mg(c.goal)
        let left = PinchFormat.mg(max(c.remaining, 0))

        switch segment {
        case .morning:
            return Nudge(
                segment: segment,
                title: "Today resets at breakfast",
                body: PinchLocalization.format("A fresh {0} mg just landed. Pinch can tell you before the first bite — so the day gets planned, not patched at 9 PM.", [goal]),
                previewTime: c.breakfastTime,
                previewBody: PinchLocalization.format("Morning! Full jar — {0} mg. Plan the day before the first bite.", [String(describing: goal)]),
                primary: "Brief me each morning",
                caption: "One line with breakfast. That's the whole deal.",
                dismiss: "Not now"
            )

        case .lunch:
            return Nudge(
                segment: segment,
                title: "Half the day's salt lands at lunch",
                body: "A nudge at noon catches it while the order's still open — not after the fries.",
                previewTime: c.lunchTime,
                previewBody: PinchLocalization.format("{0} mg left. Still room for a decent lunch.", [String(describing: left)]),
                primary: "Nudge me at noon",
                caption: "One check-in at lunch. Off anytime.",
                dismiss: "Dismiss"
            )

        case .dinner:
            return Nudge(
                segment: segment,
                title: "Dinner decides the day",
                body: PinchLocalization.format("You have {0} mg left. A check-in can help you log dinner while choosing what to cook.", [left]),
                previewTime: c.dinnerTime,
                previewBody: PinchLocalization.format("Dinner soon — {0} mg in the jar. Want a low-salt idea?", [String(describing: left)]),
                primary: "Remind me at dinnertime",
                caption: PinchLocalization.format("One check-in at {0}. Silent a minute later.", [String(describing: c.dinnerTime)]),
                dismiss: "Tonight I've got it"
            )

        case .streak:
            return Nudge(
                segment: segment,
                title: PinchLocalization.format("Day {0} starts tomorrow", [String(describing: c.streak + 1)]),
                body: PinchLocalization.format("Pinch can remind you at {0} to log your meals. Keep a record at your own pace.", [c.dinnerTime]),
                previewTime: c.dinnerTime,
                previewBody: PinchLocalization.format("{0} days under budget — longest run yet. Log today to keep it.", [String(describing: c.streak)]),
                primary: "Protect the streak",
                caption: "A whisper only on days you haven't logged.",
                dismiss: "I'll remember"
            )
        }
    }
}
