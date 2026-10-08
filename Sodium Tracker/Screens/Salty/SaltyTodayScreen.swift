//
//  SaltyTodayScreen.swift
//  Sodium Tracker
//
//  The Salty dashboard. Everything above the tab bar: day nav, streak pill, the
//  316pt ring with Salty riding its tip, the tail-tracking speech bubble, stat
//  cards, FITS / WON'T FIT chips, and the day's log.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §5, §8, §9
//

import SwiftUI
import SwiftData

struct SaltyTodayScreen: View {
    @Environment(\.salty) private var s
    @Environment(UIState.self) private var ui
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext

    let engine: SaltyEngine

    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault
    @AppStorage(PinchDefaults.chatty) private var chatty = true
    @AppStorage(PinchDefaults.notif) private var notif = true

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    /// Bell swing, driven by a keyframe animation on tap.
    @State private var bellSwing = 0
    @State private var streakPop = false

    // MARK: - Derived

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }
    private var day: Date { ui.selectedDay() }
    private var isToday: Bool { ui.selOffset == 0 }
    private var suspects: [FoodItem] { UsualSuspects.ids.compactMap { FoodItem.builtIn($0) } }

    /// Everything the screen derives from the log, resolved in a single pass.
    /// Resolving entries is O(n); the naive computed-property version ran it
    /// dozens of times per body evaluation, which at 60 Hz pinned the CPU.
    private struct DayData {
        var rows: [ResolvedEntry] = []
        var consumed = 0
        var remaining = 0
        var streak = 0
        var underCount = 0
        var fits = 0
    }

    private func makeDayData() -> DayData {
        var d = DayData()
        d.rows = DayEngine.entries(entries, on: day, customFoods: customFoods)
        d.consumed = d.rows.reduce(0) { $0 + $1.totalMg }
        d.remaining = goal - d.consumed
        d.streak = DayEngine.streak(entries)
        d.underCount = DayEngine.week(entries, customFoods: customFoods, goal: goal).underCount
        d.fits = SaltyModel.fitCount(suspects, remaining: d.remaining)
        return d
    }

    // MARK: - Body

    var body: some View {
        // Resolved once per pass and threaded down. Nothing in this body reads
        // a per-frame engine value — the ring, counter and bubble tail are leaf
        // views that observe the engine on their own, so 60 Hz motion never
        // invalidates the whole screen.
        let d = makeDayData()
        let ringSize = min(316, screenWidth - 40)

        // ScrollView is the root deliberately: a GeometryReader here would
        // swallow the top safe-area inset and slide the nav row under the
        // status bar. Width comes from a background probe instead.
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navRow
                titleRow(streak: d.streak).padding(.top, 12)
                ringBlock(size: ringSize, data: d)
                    .padding(.top, 8)

                if chatty {
                    bubble(ringSize: ringSize, screenWidth: screenWidth, data: d)
                        .padding(.top, 10)
                        .saltyReveal(ui, .bubble, offset: 12, scale: 0.94)
                }

                statCards(data: d)
                    .padding(.top, 16)
                    .saltyReveal(ui, .cards, offset: 14)

                sectionHeader(data: d)
                    .padding(.top, 24)
                    .saltyReveal(ui, .sectionHeader, offset: 14)

                chipsRow(data: d)
                    .padding(.top, 12)
                    .saltyReveal(ui, .chips, offset: 16)

                loggedSection(data: d)
                    .padding(.top, 20)
                    .saltyReveal(ui, .chips, offset: 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 150)
            .offset(x: ui.daySlide)
            .opacity(ui.daySlideOpacity)
            .background(GeometryReader { g in
                Color.clear.preference(key: ScreenWidthKey.self, value: g.size.width + 40)
            })
        }
        .scrollIndicators(.hidden)
        .onPreferenceChange(ScreenWidthKey.self) { screenWidth = $0 }
        .onPreferenceChange(ChipFrameKey.self) { chipFrames = $0 }
        .onAppear { syncEngine(d) }
        .onChange(of: d.consumed) { _, _ in syncEngine(d) }
        .onChange(of: goal) { _, _ in
            syncEngine(d)
            engine.impulse(pulse: 1.2)
        }
        .onChange(of: ui.selOffset) { _, _ in syncEngine(d) }
    }

    /// Pushes live data into the motion engine (spec §7.2, §6).
    private func syncEngine(_ d: DayData) {
        engine.fracTarget = goal > 0 ? Double(d.consumed) / Double(goal) : 0
        engine.setRestingMood(SaltyModel.restingMood(remaining: d.remaining, isToday: isToday))
    }

    // MARK: - Nav row

    private var navRow: some View {
        HStack(spacing: 0) {
            chevron(leading: true, enabled: ui.selOffset > UIState.minOffset) {
                switchDay(-1)
            }
            .padding(.leading, -12)

            Button {
                if PremiumAccessPolicy.allows(.historyCalendar, isPremium: subscriptions.isPremium) {
                    ui.calOpen = true
                } else {
                    ui.payOpen = true
                }
            } label: {
                PinchText(PinchFormat.kicker(day).uppercased())
                    .salty(13.5, .heavy, tracking: 0.14)
                    .foregroundStyle(s.ink)
                    .frame(minWidth: 172)
            }
            .buttonStyle(.plain)

            chevron(leading: false, enabled: ui.selOffset < 0) {
                switchDay(1)
            }

            Spacer()
            bell
        }
        .frame(height: 44)
    }

    private func chevron(leading: Bool, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SaltyChevron(leading: leading)
                .stroke(s.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 11, height: 18)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.saltyPress(scale: 0.82))
        .opacity(enabled ? 1 : 0.22)
        .disabled(!enabled)
        .accessibilityLabel(PinchLocalization.resolve(leading ? "Previous day" : "Next day"))
    }

    private var bell: some View {
        Button {
            engine.impulse(hop: -90)
            engine.flash(.joy, seconds: 0.9)
            withAnimation(.easeInOut(duration: 0.65)) { bellSwing += 1 }
            ui.notifCenterOpen = true
        } label: {
            ZStack(alignment: .topTrailing) {
                SaltyBellIcon()
                    .stroke(s.ink, style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 22)
                    .modifier(BellSwing(trigger: bellSwing))
                if notif {
                    Circle().fill(s.alertRed)
                        .frame(width: 9, height: 9)
                        .offset(x: -1, y: 1)
                }
            }
            .frame(width: 46, height: 46)
            .background(Circle().fill(s.card))
            .saltyBellShadow(s)
        }
        .buttonStyle(.saltyPress(scale: 0.86))
        .accessibilityLabel(PinchLocalization.resolve("Nudges"))
    }

    // MARK: - Title row

    private func titleRow(streak: Int) -> some View {
        HStack {
            PinchText(PinchFormat.dayTitle(day))
                .salty(45, .black, tracking: -0.02)
                .foregroundStyle(s.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 8)
            Button {
                engine.impulse(hop: -170)
                engine.wave(1.0)
                engine.flash(.joy, seconds: 1.4)
                burstAtStreak()
                streakPop = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { streakPop = false }
            } label: {
                HStack(spacing: 7) {
                    SaltyStar()
                        .fill(s.star)
                        .frame(width: 15, height: 15)
                    PinchText(PinchLocalization.format("{0}-day streak", [String(describing: streak)]))
                        .salty(15.5, .heavy)
                        .foregroundStyle(s.amberStreak)
                        .lineLimit(1)
                        .fixedSize()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(s.amberSoft))
                .scaleEffect(streakPop ? 1.12 : 1)
                .animation(.timingCurve(0.3, 1.6, 0.4, 1, duration: 0.36), value: streakPop)
            }
            .buttonStyle(.saltyPress(scale: 0.9, duration: 0.2, curve: (0.3, 1.6, 0.4, 1)))
            .background(GeometryReader { g in
                Color.clear.preference(key: StreakFrameKey.self, value: g.frame(in: .global))
            })
        }
        .onPreferenceChange(StreakFrameKey.self) { streakFrame = $0 }
    }

    @State private var streakFrame: CGRect = .zero
    @State private var ringCenterFrame: CGRect = .zero
    @State private var chipFrames: [String: CGRect] = [:]
    /// Full screen width, recovered from the content probe (content + padding).
    @State private var screenWidth: CGFloat = 393

    private func burstAtStreak() {
        guard streakFrame != .zero else { return }
        engine.burst(at: CGPoint(x: streakFrame.midX, y: streakFrame.midY), count: 10)
    }

    // MARK: - Ring

    private func ringBlock(size ringSize: CGFloat, data d: DayData) -> some View {
        ZStack {
            SaltyRingCanvas(engine: engine, size: ringSize)

            VStack(spacing: 3) {
                // Leaf view: the counter is the spring, so only this re-renders
                // per frame — not the screen around it.
                RingCounter(engine: engine, goal: goal, color: s.ink)

                Button {
                    withAnimation(.easeOut(duration: 0.35)) { ui.tab = .settings }
                } label: {
                    PinchText(PinchLocalization.format("of {0} mg", [String(describing: PinchFormat.mg(goal))]))
                        .salty(16, .medium)
                        .foregroundStyle(s.inkCenterSub)
                        .padding(.bottom, 3)
                        .overlay(alignment: .bottom) {
                            SaltyDottedRule().stroke(
                                s.dottedUnderline,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 3])
                            )
                            .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)

                PinchText(d.remaining >= 0
                     ? PinchLocalization.format("{0} mg left", [String(describing: PinchFormat.mg(d.remaining))])
                     : PinchLocalization.format("{0} mg over", [String(describing: PinchFormat.mg(-d.remaining))]))
                    .saltyNum(19, .heavy)
                    .foregroundStyle(d.remaining >= 0 ? s.blue : s.amberText)
                    .padding(.top, 4)
            }
            .background(GeometryReader { g in
                Color.clear.preference(key: RingCenterKey.self, value: g.frame(in: .global))
            })
        }
        .frame(maxWidth: .infinity)
        .frame(height: ringSize)
        .onPreferenceChange(RingCenterKey.self) { ringCenterFrame = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PinchLocalization.resolve("Sodium progress"))
        .accessibilityValue(PinchLocalization.format("{0} of {1} milligrams", [String(describing: PinchFormat.mg(d.consumed)), String(describing: PinchFormat.mg(goal))]))
    }

    // MARK: - Bubble

    private func bubble(ringSize: CGFloat, screenWidth: CGFloat, data d: DayData) -> some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                PinchText(SaltyModel.bubble(
                    total: d.consumed,
                    remaining: d.remaining,
                    isToday: isToday,
                    isEmpty: d.rows.isEmpty,
                    fits: d.fits
                ))
                .salty(16.5, .medium)
                .foregroundStyle(s.inkBody)
                .lineSpacing(16.5 * 0.45)
                .multilineTextAlignment(.center)

                if isToday && !ui.undoStack.isEmpty {
                    Button {
                        undoLast(data: d)
                    } label: {
                        PinchText("Undo")
                            .salty(16.5, .heavy)
                            .foregroundStyle(s.blue)
                            .padding(.leading, 6)
                    }
                    .buttonStyle(.saltyPress(opacity: 0.55))
                    .accessibilityLabel(PinchLocalization.resolve("Undo last log"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(s.card))
            .saltyBubbleShadow(s)

            // Leaf view: the tail tracks the mascot every frame (spec §5.4).
            BubbleTail(engine: engine, ringSize: ringSize, screenWidth: screenWidth, color: s.card)
        }
    }

    // MARK: - Stat cards

    private func statCards(data d: DayData) -> some View {
        HStack(spacing: 12) {
            statCard(
                value: PinchFormat.mg(abs(d.remaining)),
                caption: d.remaining >= 0
                    ? (isToday ? "mg left today" : "mg left that day")
                    : (isToday ? "mg over today" : "mg over that day"),
                color: d.remaining >= 0 ? s.blue : s.amberText
            )
            statCard(
                value: PinchLocalization.format("{0} of 7", [String(describing: d.underCount)]),
                caption: "days under budget this week",
                color: s.ink
            )
        }
    }

    private func statCard(value: String, caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            PinchText(value)
                .saltyNum(34, .heavy, tracking: -0.01)
                .foregroundStyle(color)
            PinchText(caption)
                .salty(15, .semibold)
                .foregroundStyle(s.ink2)
                .lineSpacing(15 * 0.3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(s.card))
        .saltyCardShadow(s)
    }

    // MARK: - Chips

    private func sectionHeader(data d: DayData) -> some View {
        HStack(alignment: .firstTextBaseline) {
            PinchText("USUAL SUSPECTS")
                .salty(13, .heavy, tracking: 0.13)
                .foregroundStyle(s.ink3)
            Spacer(minLength: 8)
            PinchText(PinchLocalization.format("vs. {0} mg left", [String(describing: PinchFormat.mg(max(d.remaining, 0)))]))
                .saltyNum(13.5, .semibold)
                .foregroundStyle(s.inkFaint)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 2)
    }

    private func chipsRow(data d: DayData) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(suspects) { food in
                    chip(food, data: d)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -20)
        .opacity(isToday ? 1 : 0.45)
        .disabled(!isToday)
    }

    private func chip(_ food: FoodItem, data d: DayData) -> some View {
        let fits = SaltyModel.fits(mg: food.mg, remaining: d.remaining, isToday: isToday)
        return Button {
            logFood(food, data: d)
        } label: {
                HStack(spacing: 11) {
                    PinchText("+")
                        .salty(20, .bold)
                        .foregroundStyle(s.blue)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(s.blueSoft))
                    Text(verbatim: food.displayName)
                        .salty(16.5, .heavy)
                        .foregroundStyle(s.ink)
                        .fixedSize()
                    PinchText(PinchFormat.mg(food.mg))
                        .saltyNum(15.5, .heavy)
                        .foregroundStyle(fits ? s.blue : s.amberText)
                    PinchText(fits ? "FITS" : "WON'T FIT")
                        .salty(11, .heavy, tracking: 0.06)
                        .foregroundStyle(fits ? s.blue : s.amberBadge)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(fits ? s.fitsBg : s.amberSoft))
                        .fixedSize()
                }
                .padding(.leading, 12)
                .padding(.trailing, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(s.card))
                .saltyCardShadow(s)
        }
        .buttonStyle(.saltyPress(scale: 0.93, duration: 0.16, curve: (0.3, 1.5, 0.4, 1)))
        .accessibilityLabel(PinchLocalization.format("Log {0}, {1} milligrams", [food.displayName, String(describing: food.mg)]))
        // Reported without affecting layout, so the fly pill can launch from
        // wherever the chip actually sits after scrolling.
        .background(GeometryReader { g in
            Color.clear.preference(key: ChipFrameKey.self, value: [food.id: g.frame(in: .global)])
        })
    }

    // MARK: - Logged list (spec §15.1)

    @ViewBuilder private func loggedSection(data d: DayData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PinchText(isToday ? "LOGGED TODAY" : "LOGGED THIS DAY")
                .salty(13, .heavy, tracking: 0.13)
                .foregroundStyle(s.ink3)
                .padding(.horizontal, 2)
                .padding(.bottom, 12)

            if d.rows.isEmpty {
                PinchText("Nothing logged this day")
                    .salty(15, .semibold)
                    .foregroundStyle(s.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(s.track, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    )
            } else {
                VStack(spacing: 12) {
                    ForEach(Meal.allCases) { meal in
                        let rows = d.rows.filter { $0.entry.meal == meal }
                        if !rows.isEmpty { mealCard(meal, rows: rows) }
                    }
                }
            }
        }
    }

    private func mealCard(_ meal: Meal, rows: [ResolvedEntry]) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                PinchText(meal.rawValue)
                    .salty(15, .heavy)
                    .foregroundStyle(s.ink)
                Spacer()
                PinchText(PinchLocalization.format("{0} mg", [String(describing: PinchFormat.mg(rows.reduce(0) { $0 + $1.totalMg }))]))
                    .saltyNum(13.5, .semibold)
                    .foregroundStyle(s.ink3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ForEach(Array(rows.enumerated()), id: \.offset) { _, resolved in
                HStack(spacing: 11) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: resolved.displayName)
                            .salty(15, .semibold)
                            .foregroundStyle(s.ink)
                            .lineLimit(1)
                        PinchText(PinchFormat.time(resolved.entry.loggedAt))
                            .salty(12.5, .regular)
                            .foregroundStyle(s.ink3)
                    }
                    Spacer(minLength: 8)
                    PinchText(PinchFormat.mg(resolved.totalMg))
                        .saltyNum(15, .heavy)
                        .foregroundStyle(s.ink)
                    Button {
                        delete(resolved)
                    } label: {
                        PinchText("×")
                            .font(.system(size: 17))
                            .foregroundStyle(s.ink3)
                            .frame(width: 28, height: 28)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.saltyPress(scale: 0.85))
                    .accessibilityLabel(PinchLocalization.format("Remove {0}", [resolved.displayName]))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .padding(.bottom, 6)
        }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(s.card))
        .saltyCardShadow(s)
    }

    // MARK: - Actions (spec §9)

    private func logFood(_ food: FoodItem, data d: DayData) {
        guard isToday else { return }
        let source = chipFrames[food.id].map { CGPoint(x: $0.midX, y: $0.midY) }
            ?? CGPoint(x: ringCenterFrame.midX, y: ringCenterFrame.midY)
        let target = ringCenterFrame == .zero
            ? source
            : CGPoint(x: ringCenterFrame.midX, y: ringCenterFrame.midY)

        engine.spawnFly(from: source, to: target, label: PinchLocalization.format("+{0} mg", [String(describing: PinchFormat.mg(food.mg))])) {
            applyAdd(mg: food.mg, remainingBefore: d.remaining) {
                LogEntry(foodID: food.id, servings: 1, meal: Meal.auto(), loggedAt: timestamp(for: day))
            }
        }
    }

    /// Shared add path — chips and quick-add both land here (spec §9 applyAdd).
    private func applyAdd(mg: Int, remainingBefore before: Int, makeEntry: () -> LogEntry) {
        let after = before - mg

        let entry = makeEntry()
        modelContext.insert(entry)
        ui.undoStack.append(entry.persistentModelID)

        engine.impulse(pulse: 2.4)

        if after < 0 && before >= 0 {
            engine.flash(.shock, seconds: 1.6)
            if engine.energyFull {
                engine.impulse(hop: -130, cap: -130, tilt: 200)
            }
        } else if after < 0 {
            engine.flash(.worried, seconds: 1.4)
            if engine.energyFull { engine.impulse(tilt: 160) }
        } else {
            engine.flash(.joy, seconds: 1.7)
            engine.impulse(hop: engine.energyFull ? -230 : -90)
            engine.wave(1.0)
        }
    }

    private func undoLast(data d: DayData) {
        guard let id = ui.undoStack.popLast() else { return }
        // Removing this entry gives back its milligrams.
        let restored = d.rows.first { $0.entry.persistentModelID == id }?.totalMg ?? 0
        if let entry = entries.first(where: { $0.persistentModelID == id }) {
            modelContext.delete(entry)
        }
        engine.impulse(hop: engine.energyFull ? -150 : -60, pulse: 1.4)

        let after = d.remaining + restored
        engine.flash(after >= 0 ? .joy : .worried, seconds: 1.3)
        if after >= 0, ringCenterFrame != .zero {
            engine.burst(at: CGPoint(x: ringCenterFrame.midX, y: ringCenterFrame.midY), count: 7)
        }
    }

    private func delete(_ resolved: ResolvedEntry) {
        ui.undoStack.removeAll { $0 == resolved.entry.persistentModelID }
        withAnimation(.easeOut(duration: 0.25)) {
            modelContext.delete(resolved.entry)
        }
    }

    /// Slide the content out, swap the day, slide it back (spec §9.1).
    private func switchDay(_ direction: Int) {
        guard !ui.daySwitching else { return }
        let target = ui.selOffset + direction
        guard target >= UIState.minOffset, target <= 0 else { return }
        ui.daySwitching = true

        withAnimation(.easeOut(duration: 0.26)) { ui.daySlideOpacity = 0 }
        withAnimation(.timingCurve(0.22, 0.9, 0.3, 1, duration: 0.32)) {
            ui.daySlide = CGFloat(-direction) * 38
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.23) {
            ui.selOffset = target
            // The new day's arc should not sweep from the old value.
            engine.settleFraction()

            var jump = Transaction(); jump.disablesAnimations = true
            withTransaction(jump) { ui.daySlide = CGFloat(direction) * 38 }

            withAnimation(.easeOut(duration: 0.26)) { ui.daySlideOpacity = 1 }
            withAnimation(.timingCurve(0.22, 0.9, 0.3, 1, duration: 0.32)) { ui.daySlide = 0 }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) { ui.daySwitching = false }
        }
    }
}

// MARK: - Reveal choreography (spec §8)

private struct SaltyRevealModifier: ViewModifier {
    let ui: UIState
    let stage: SaltyReveal
    let offset: CGFloat
    let scale: CGFloat

    func body(content: Content) -> some View {
        // Reads a set that changes four times total, not a 60 Hz clock.
        let shown = ui.revealed.contains(stage)
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : offset)
            .scaleEffect(shown ? 1 : scale)
            .animation(.easeOut(duration: 0.5), value: shown)
            .animation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.6), value: shown)
    }
}

extension View {
    func saltyReveal(
        _ ui: UIState,
        _ stage: SaltyReveal,
        offset: CGFloat,
        scale: CGFloat = 1
    ) -> some View {
        modifier(SaltyRevealModifier(ui: ui, stage: stage, offset: offset, scale: scale))
    }
}

// MARK: - Per-frame leaf views
//
// These are the only views that observe the engine's 60 Hz state. Keeping them
// separate means a frame tick repaints a number and a 15pt triangle, not the
// entire screen (which would re-resolve the whole day's log every frame).

/// The counter under the ring. The design ties it to the arc spring, so it
/// counts up as a side-effect of the ring filling rather than its own tween.
private struct RingCounter: View {
    let engine: SaltyEngine
    let goal: Int
    let color: Color

    var body: some View {
        PinchText(PinchFormat.mg(engine.shown(budget: goal)))
            .saltyNum(58, .heavy, tracking: -0.02)
            .foregroundStyle(color)
    }
}

/// The bubble's tail, which tracks the mascot's x position around the ring.
private struct BubbleTail: View {
    let engine: SaltyEngine
    let ringSize: CGFloat
    let screenWidth: CGFloat
    let color: Color

    var body: some View {
        let scale = ringSize / 320
        let x = min(
            max((screenWidth - ringSize) / 2 + engine.mascotPoint.x * scale - 20 - 7.5, 18),
            screenWidth - 73
        )
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: 15, height: 15)
            .rotationEffect(.degrees(45))
            .offset(x: x, y: -6)
    }
}

// MARK: - Bell swing (spec §9)

private struct BellSwing: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, angle in
            view.rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: 0.12))
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(16, duration: 0.13)
                CubicKeyframe(-13, duration: 0.13)
                CubicKeyframe(9, duration: 0.13)
                CubicKeyframe(-6, duration: 0.13)
                CubicKeyframe(0, duration: 0.13)
            }
        }
    }
}

// MARK: - Shapes

private struct SaltyChevron: Shape {
    let leading: Bool
    func path(in rect: CGRect) -> Path {
        let kx = rect.width / 11, ky = rect.height / 18
        return Path { p in
            if leading {
                p.move(to: CGPoint(x: 9.5 * kx, y: 1.5 * ky))
                p.addLine(to: CGPoint(x: 2 * kx, y: 9 * ky))
                p.addLine(to: CGPoint(x: 9.5 * kx, y: 16.5 * ky))
            } else {
                p.move(to: CGPoint(x: 1.5 * kx, y: 1.5 * ky))
                p.addLine(to: CGPoint(x: 9 * kx, y: 9 * ky))
                p.addLine(to: CGPoint(x: 1.5 * kx, y: 16.5 * ky))
            }
        }
    }
}

private struct SaltyBellIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let kx = rect.width / 20, ky = rect.height / 22
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * kx, y: y * ky) }
        return Path { p in
            p.move(to: pt(10, 1.6))
            p.addCurve(to: pt(4.2, 7.8), control1: pt(6.2, 1.6), control2: pt(4.2, 4.6))
            p.addLine(to: pt(4.2, 11.8))
            p.addLine(to: pt(2.6, 14.8))
            p.addLine(to: pt(17.4, 14.8))
            p.addLine(to: pt(15.8, 11.8))
            p.addLine(to: pt(15.8, 7.8))
            p.addCurve(to: pt(10, 1.6), control1: pt(15.8, 4.6), control2: pt(13.8, 1.6))
            p.closeSubpath()

            p.move(to: pt(7.8, 17.8))
            p.addCurve(to: pt(10, 20), control1: pt(8.1, 19.2), control2: pt(9, 20))
            p.addCurve(to: pt(12.2, 17.8), control1: pt(11, 20), control2: pt(11.9, 19.2))
        }
    }
}

private struct SaltyStar: Shape {
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

private struct SaltyDottedRule: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        }
    }
}

// MARK: - Frame reporting

private struct StreakFrameKey: PreferenceKey {
    static let defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct RingCenterKey: PreferenceKey {
    static let defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct ScreenWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 393
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Chip frames by food id, so a fly pill launches from the tapped chip.
private struct ChipFrameKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
