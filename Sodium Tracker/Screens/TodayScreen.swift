//
//  TodayScreen.swift
//  Sodium Tracker
//
//  The home screen: day navigation, streak pill, the salt ring with Pinch
//  underneath, quick-add chips, and the day's log grouped by meal.
//

import SwiftUI
import SwiftData

struct TodayScreen: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault
    @AppStorage(PinchDefaults.chatty) private var chatty = true
    @AppStorage(PinchDefaults.notif) private var notif = true

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]
    @Query private var favorites: [Favorite]

    @State private var displayedConsumed = 0.0
    @State private var revealBubble = false
    @State private var revealCards = false
    @State private var revealQuickHeader = false
    @State private var revealChips = false
    @State private var ringPulse: CGFloat = 1
    @State private var mascotHop: CGFloat = 0
    @State private var mascotTilt = 0.0
    @State private var mascotWaving = false
    @State private var mascotReaction = PinchMascot.Reaction.none
    @State private var bellSwing = 0.0
    @State private var bellDotDismissed = false
    @State private var streakBurst = false
    @State private var ringBurst = false
    @State private var lastAddedEntry: LogEntry?
    @State private var ringCenter = CGPoint.zero
    @State private var chipCenters: [String: CGPoint] = [:]
    @State private var flight: SodiumFlight?
    @State private var flightProgress: CGFloat = 0
    @State private var dayTransitionOffset: CGFloat = 0
    @State private var dayTransitionOpacity = 1.0

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    private var day: Date { ui.selectedDay() }
    private var isToday: Bool { ui.selOffset == 0 }

    private var dayEntries: [ResolvedEntry] {
        DayEngine.entries(entries, on: day, customFoods: customFoods)
    }

    private var consumed: Int { dayEntries.reduce(0) { $0 + $1.totalMg } }
    private var pct: Double { goal > 0 ? Double(consumed) / Double(goal) * 100 : 0 }
    private var remain: Int { goal - consumed }
    private var mood: Mood {
        if remain < 0 { return .over }
        if remain < 150 { return .wary }
        return pct < 40 ? .fresh : .ok
    }

    private var streak: Int { DayEngine.streak(entries) }

    private var bubbleLine: String {
        if isToday {
            if consumed == 0 {
                return "Fresh page — plenty of room today."
            }
            if remain < 0 {
                return PinchLocalization.format("{0} mg over budget. Ease up tonight — tomorrow resets.", [String(describing: PinchFormat.mg(-remain))])
            }
            if remain < 150 {
                return PinchLocalization.format("{0} mg left — a light bite still fits.", [String(describing: PinchFormat.mg(remain))])
            }
            let fits = usualFoods.filter { $0.mg <= remain }.count
            if fits == 0 {
                return PinchLocalization.format("{0} mg left — under every usual pick. Go fresh for dinner.", [String(describing: PinchFormat.mg(remain))])
            }
            return PinchLocalization.format("{0} mg left — {1} of your usual picks fit.", [String(describing: PinchFormat.mg(remain)), String(describing: fits)])
        }
        return Mood.pastLine(empty: dayEntries.isEmpty, over: remain < 0)
    }

    private var usualFoods: [FoodItem] {
        FoodRecommendations.foods(entries: entries, favorites: favorites, customFoods: customFoods)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                titleRow
                    .padding(.top, 10)
                ringBlock
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                if chatty {
                    speechBubble
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .opacity(revealBubble ? 1 : 0)
                        .offset(y: revealBubble ? 0 : 12)
                        .scaleEffect(revealBubble ? 1 : 0.96)
                }

                statDuo
                    .padding(.top, 16)
                    .opacity(revealCards ? 1 : 0)
                    .offset(y: revealCards ? 0 : 14)
                    .scaleEffect(revealCards ? 1 : 0.96)

                quickHeader
                    .padding(.top, 24)
                    .padding(.bottom, 12)
                    .opacity(revealQuickHeader ? 1 : 0)
                    .offset(y: revealQuickHeader ? 0 : 10)
                quickChips
                    .opacity(revealChips ? 1 : 0)
                    .offset(y: revealChips ? 0 : 12)
                    .scaleEffect(revealChips ? 1 : 0.97)
                loggedList
                    .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 150)
            .offset(x: dayTransitionOffset)
            .opacity(dayTransitionOpacity)
        }
        .scrollIndicators(.hidden)
        .clipped()
        .coordinateSpace(name: "todayStage")
        .onPreferenceChange(RingCenterPreferenceKey.self) { ringCenter = $0 }
        .onPreferenceChange(ChipCentersPreferenceKey.self) { chipCenters = $0 }
        .overlay(alignment: .topLeading) { flightOverlay }
        .background(p.bg.ignoresSafeArea())
        .task { await stageEntrance() }
        .task(id: ui.quickAddRequest?.id) {
            guard let request = ui.quickAddRequest else { return }
            await receiveQuickAdd(request)
        }
        .onChange(of: consumed) { oldValue, newValue in
            animateConsumption(from: oldValue, to: newValue)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 4) {
                ChevronButton(
                    direction: .leading,
                    enabled: ui.selOffset > UIState.minOffset,
                    filled: false,
                    size: 30
                ) {
                    changeDay(to: max(UIState.minOffset, ui.selOffset - 1))
                }
                Button {
                    if PremiumAccessPolicy.allows(.historyCalendar, isPremium: subscriptions.isPremium) {
                        ui.calOpen = true
                    } else {
                        ui.payOpen = true
                    }
                } label: {
                    PinchText(PinchFormat.kicker(day))
                        .pinchBody(13.5, .heavy, tracking: 0.14)
                        .foregroundStyle(p.ink2)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 3)
                }
                .buttonStyle(.plain)
                ChevronButton(
                    direction: .trailing,
                    enabled: ui.selOffset < 0,
                    filled: false,
                    size: 30
                ) {
                    changeDay(to: min(0, ui.selOffset + 1))
                }
            }
            .padding(.leading, -6)

            Spacer()

            Button {
                ringBell()
            } label: {
                ZStack(alignment: .topTrailing) {
                    LineIcon(
                        d: "M10 3 C7 3 5.5 5.2 5.5 8 C5.5 11.4 4.5 12.6 3.8 13.6 C3.5 14.1 3.8 14.8 4.4 14.8 L15.6 14.8 C16.2 14.8 16.5 14.1 16.2 13.6 C15.5 12.6 14.5 11.4 14.5 8 C14.5 5.2 13 3 10 3 Z M8.4 16.6 C8.7 17.4 9.3 17.9 10 17.9 C10.7 17.9 11.3 17.4 11.6 16.6",
                        size: 16,
                        color: p.ink2
                    )
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(bellSwing), anchor: .top)
                    .background(Circle().fill(p.card))
                    .overlay(Circle().strokeBorder(p.line.opacity(0.6), lineWidth: 1))
                    .pinchSegShadow(p)

                    Circle()
                        .fill(p.coral)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().strokeBorder(p.bg, lineWidth: 1.5))
                        .offset(x: -6, y: 6)
                        .opacity(notif && !bellDotDismissed ? 1 : 0)
                }
            }
            .buttonStyle(.pressScale(0.92))
            .accessibilityLabel(PinchLocalization.resolve("Open meal check-ins and nudges"))
        }
        .padding(.bottom, 2)
    }

    private var titleRow: some View {
        HStack(alignment: .top) {
            PinchText(PinchFormat.dayTitle(day))
                .pinchDisplay(45, .heavy, tracking: -0.035)
                .foregroundStyle(p.ink)
            Spacer()
            Button {
                playStreakBurst()
            } label: {
                HStack(spacing: 7) {
                    SVGShape("M10 1.5 L12.2 7.8 L18.5 10 L12.2 12.2 L10 18.5 L7.8 12.2 L1.5 10 L7.8 7.8 Z")
                        .fill(p.amber)
                        .frame(width: 15, height: 15)
                    PinchText(PinchLocalization.format("{0}-day streak", [String(describing: streak)]))
                        .pinchBody(16, .bold)
                        .foregroundStyle(p.amber)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(p.amberSoft))
                .scaleEffect(streakBurst ? 1.06 : 1)
                .overlay { streakSparkles }
            }
            .buttonStyle(.pressScale(0.96))
            .accessibilityLabel(PinchLocalization.resolve(PinchLocalization.format("{0} day streak", [String(describing: streak)])))
            .padding(.top, 3)
        }
    }

    // MARK: - Ring + mascot

    private var ringBlock: some View {
        let size: CGFloat = 316
        let radius: CGFloat = 134
        let rawFraction = goal > 0 ? max(displayedConsumed / Double(goal), 0) : 0
        let arcFraction = rawFraction > 1 ? min(rawFraction - 1, 1) : min(rawFraction, 1)
        let visualRemain = goal - Int(displayedConsumed.rounded())
        let radians = (-90 + (arcFraction * 360)) * Double.pi / 180
        let mascotPoint = CGPoint(
            x: size / 2 + radius * CGFloat(cos(radians)),
            y: size / 2 + radius * CGFloat(sin(radians))
        )

        return ZStack {
            ProgressRing(consumed: displayedConsumed, goal: goal, size: size, pulse: ringPulse)

            VStack(spacing: 0) {
                AnimatedMilligramText(value: displayedConsumed)
                    .font(PinchFonts.display(58, .heavy))
                    .tracking(58 * -0.02)
                    .monospacedDigit()
                    .foregroundStyle(p.ink)

                Button {
                    withAnimation(.interpolatingSpring(stiffness: 180, damping: 22)) {
                        ui.selectTab(.settings)
                    }
                } label: {
                    PinchText(PinchLocalization.format("of {0} mg", [String(describing: PinchFormat.mg(goal))]))
                        .pinchBody(16, .medium)
                        .foregroundStyle(p.ink2)
                        .underline(true, pattern: .dot, color: p.ink3)
                }
                .buttonStyle(.plain)
                .padding(.top, 1)

                PinchText(visualRemain >= 0
                     ? PinchLocalization.format("{0} mg left", [String(describing: PinchFormat.mg(visualRemain))])
                     : PinchLocalization.format("{0} mg over", [String(describing: PinchFormat.mg(-visualRemain))]))
                    .font(PinchFonts.body(19, .heavy))
                    .foregroundStyle(visualRemain < 0 ? p.amber : p.remainColor(remain: visualRemain, pct: rawFraction * 100))
                    .padding(.top, 9)
            }
            .offset(y: -2)

            PinchMascot(
                variant: .hero(mood),
                width: 52,
                energy: .full,
                waving: mascotWaving,
                reaction: mascotReaction
            )
                .rotationEffect(.degrees(mascotTilt))
                .offset(y: mascotHop)
                .position(mascotPoint)

            ringSparkles
        }
        .frame(width: size, height: size)
        .background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named("todayStage"))
                Color.clear.preference(
                    key: RingCenterPreferenceKey.self,
                    value: CGPoint(x: frame.midX, y: frame.midY)
                )
            }
        }
    }

    private var speechBubble: some View {
        let radius: CGFloat = 134
        let rawFraction = goal > 0 ? max(displayedConsumed / Double(goal), 0) : 0
        let arcFraction = rawFraction > 1 ? min(rawFraction - 1, 1) : min(rawFraction, 1)
        let radians = (-90 + (arcFraction * 360)) * Double.pi / 180
        let tailOffset = min(max(radius * CGFloat(cos(radians)), -132), 132)

        return ZStack(alignment: .top) {
            Rectangle()
                .fill(p.card)
                .frame(width: 13, height: 13)
                .rotationEffect(.degrees(45))
                .offset(x: tailOffset)
                .offset(y: -6)

            HStack(spacing: 12) {
                PinchText(bubbleLine)
                    .pinchBody(15.5, .medium)
                    .foregroundStyle(p.ink2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                if lastAddedEntry != nil, isToday {
                    Button { undoLastAdd() } label: { PinchText("Undo") }
                        .pinchBody(13, .bold)
                        .foregroundStyle(p.brand)
                        .buttonStyle(.pressScale(0.94))
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 72)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.card)
            )
            .shadow(color: p.shadowTint.opacity(p.isDark ? 0.22 : 0.05), radius: 8, y: 4)
        }
    }

    // MARK: - Stats

    private var statDuo: some View {
        HStack(spacing: 12) {
            todayStatCard(
                value: PinchFormat.mg(abs(remain)),
                caption: remain >= 0
                    ? (isToday ? "mg left today" : "mg was left over")
                    : "mg over budget",
                valueColor: remain < 0 ? p.amber : p.remainColor(remain: remain, pct: pct)
            )
            todayStatCard(
                value: PinchLocalization.format("{0} of {1}", [String(describing: underCountThisWeek), String(describing: DayEngine.week(entries, customFoods: customFoods, goal: goal).loggedDayCount)]),
                caption: "logged days under budget"
            )
        }
    }

    private func todayStatCard(value: String, caption: String, valueColor: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PinchText(value)
                .font(PinchFonts.display(34, .bold))
                .monospacedDigit()
                .foregroundStyle(valueColor ?? p.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            PinchText(caption)
                .pinchBody(15)
                .foregroundStyle(p.ink2)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.card)
        )
        .accessibilityElement(children: .combine)
    }

    private var underCountThisWeek: Int {
        DayEngine.week(entries, customFoods: customFoods, goal: goal).underCount
    }

    // MARK: - Quick chips

    private var quickHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionKicker(text: "RECOMMENDED")
            Spacer()
            PinchText(PinchLocalization.format("vs. {0} mg left", [String(describing: PinchFormat.mg(max(0, remain)))]))
                .pinchBody(13.5, .semibold)
                .foregroundStyle(p.ink3.opacity(0.68))
        }
    }

    private var quickChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(usualFoods) { food in
                        let fits = remain >= food.mg
                        Button {
                            quickAdd(food)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: favorites.contains(where: { $0.foodID == food.id }) ? "heart.fill" : "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(p.brand)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(p.brandSoft))
                                Text(verbatim: food.displayName)
                                    .pinchBody(16, .bold)
                                    .foregroundStyle(p.ink)
                                    .lineLimit(1)
                                PinchText(PinchFormat.mg(food.mg))
                                    .pinchBody(15, .semibold)
                                    .monospacedDigit()
                                    .foregroundStyle(fits ? p.brand : p.amber)
                                PinchText(fits ? "FITS" : "WON’T FIT")
                                        .pinchBody(10.5, .bold, tracking: 0.08)
                                        .foregroundStyle(fits ? p.brand : p.amber)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(fits ? p.brandSoft : p.amberSoft))
                            }
                            .padding(EdgeInsets(top: 8, leading: 9, bottom: 8, trailing: 14))
                            .background(Capsule().fill(p.card))
                            .shadow(color: p.shadowTint.opacity(p.isDark ? 0.24 : 0.06), radius: 8, y: 4)
                        }
                        .buttonStyle(.pressScale)
                        .disabled(flight != nil || ui.quickAddRequest != nil)
                        .background {
                            GeometryReader { proxy in
                                let frame = proxy.frame(in: .named("todayStage"))
                                Color.clear.preference(
                                    key: ChipCentersPreferenceKey.self,
                                    value: [food.id: CGPoint(x: frame.midX, y: frame.midY)]
                                )
                            }
                        }
                        .accessibilityLabel(PinchLocalization.resolve(PinchLocalization.format("{0}, {1} milligrams. {2}. Add to log", [food.displayName, String(describing: PinchFormat.mg(food.mg)), PinchLocalization.resolve(fits ? "Fits in today’s remaining budget" : "Does not fit in today’s remaining budget")])))
                        .accessibilityIdentifier("today-recommendation-\(food.id)")
                        .accessibilityValue(PinchLocalization.resolve(favorites.contains(where: { $0.foodID == food.id }) ? "Favorite" : "Recommended"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
            .padding(.bottom, 4)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -20)
    }

    private func quickAdd(_ food: FoodItem) {
        guard flight == nil, ui.quickAddRequest == nil else { return }
        if food.id.hasPrefix(FatSecretConfig.idPrefix), !subscriptions.isPremium {
            ui.payOpen = true
            return
        }
        let loggedAt = timestamp(for: day)

        let source = chipCenters[food.id] ?? CGPoint(x: ringCenter.x, y: ringCenter.y + 170)
        flight = SodiumFlight(
            title: PinchLocalization.format("+{0} mg", [String(describing: PinchFormat.mg(food.mg))]),
            source: source,
            destination: ringCenter
        )
        flightProgress = 0

        if reduceMotion {
            completeQuickAdd(food, loggedAt: loggedAt)
        } else {
            withAnimation(.easeInOut(duration: 0.62)) { flightProgress = 1 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(620))
                completeQuickAdd(food, loggedAt: loggedAt)
            }
        }
    }

    @MainActor private func completeQuickAdd(_ food: FoodItem, loggedAt: Date) {
        let wasOver = consumed > goal
        let willBeOver = consumed + food.mg > goal
        let entry = FoodRecommendations.entry(for: food, loggedAt: loggedAt)
        modelContext.insert(entry)
        lastAddedEntry = entry
        flight = nil
        flightProgress = 0
        playMascotReaction(wasOver: wasOver, willBeOver: willBeOver)
        ui.showToast(PinchLocalization.format("{0}, {1} mg", [food.displayName, String(describing: PinchFormat.mg(food.mg))]), ToastCopy.line(forAdded: food.mg))
    }

    @MainActor private func receiveQuickAdd(_ request: QuickAddRequest) async {
        defer {
            flight = nil
            flightProgress = 0
            if ui.quickAddRequest?.id == request.id { ui.quickAddRequest = nil }
        }
        // The menu closes and the Today tab settles before the pill launches,
        // matching the 340 ms tab handoff in the showcase prototype.
        if !reduceMotion {
            try? await Task.sleep(for: .milliseconds(340))
            guard !Task.isCancelled else { return }
        }

        let source = CGPoint(
            x: ringCenter.x,
            y: ringCenter.y + 305
        )
        flight = SodiumFlight(
            title: PinchLocalization.format("+{0} mg", [String(describing: PinchFormat.mg(request.milligrams))]),
            source: source,
            destination: ringCenter
        )
        flightProgress = 0

        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.62)) { flightProgress = 1 }
            try? await Task.sleep(for: .milliseconds(620))
            guard !Task.isCancelled else { return }
        }

        let wasOver = consumed > goal
        let willBeOver = consumed + request.milligrams > goal
        let entry = FoodRecommendations.entry(for: request.food, loggedAt: request.loggedAt)
        modelContext.insert(entry)
        lastAddedEntry = entry
        flight = nil
        flightProgress = 0
        playMascotReaction(wasOver: wasOver, willBeOver: willBeOver)
        ui.showToast(
            PinchLocalization.format("{0}, {1} mg", [String(describing: request.name), String(describing: PinchFormat.mg(request.milligrams))]),
            ToastCopy.line(forAdded: request.milligrams)
        )
    }

    // MARK: - Logged list

    @ViewBuilder private var loggedList: some View {
        if dayEntries.isEmpty {
            emptyState
        } else {
            VStack(spacing: 12) {
                ForEach(Meal.allCases) { meal in
                    let rows = dayEntries.filter { $0.entry.meal == meal }
                    if !rows.isEmpty {
                        mealCard(meal, rows: rows)
                    }
                }
            }
        }
    }

    private func mealCard(_ meal: Meal, rows: [ResolvedEntry]) -> some View {
        let total = rows.reduce(0) { $0 + $1.totalMg }
        return PinchCard {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    PinchText(meal.rawValue)
                        .pinchBody(13, .bold)
                        .foregroundStyle(p.ink)
                    Spacer()
                    PinchText(PinchLocalization.format("{0} mg", [String(describing: PinchFormat.mg(total))]))
                        .pinchBody(12, .semibold)
                        .monospacedDigit()
                        .foregroundStyle(p.ink3)
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))

                ForEach(Array(rows.enumerated()), id: \.offset) { _, resolved in
                    entryRow(resolved)
                }
            }
        }
    }

    private func entryRow(_ resolved: ResolvedEntry) -> some View {
        HStack(spacing: 11) {
            FoodIconTile(category: resolved.category)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: resolved.displayName)
                    .pinchBody(14, .semibold)
                    .foregroundStyle(p.ink)
                    .lineLimit(1)
                PinchText(entrySub(resolved))
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
            }

            Spacer(minLength: 8)

            PinchText(PinchFormat.mg(resolved.totalMg))
                .pinchBody(14, .bold)
                .monospacedDigit()
                .foregroundStyle(p.tone(resolved.totalMg))

            Button {
                logAgain(resolved)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(p.brand)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(p.brandSoft))
            }
            .buttonStyle(.pressScale(0.85))
            .accessibilityLabel(isToday ? PinchLocalization.format("Log {0} again today", [resolved.displayName]) : PinchLocalization.format("Log {0} again on this day", [resolved.displayName]))

            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    modelContext.delete(resolved.entry)
                }
            } label: {
                PinchText("×")
                    .font(.system(size: 15))
                    .foregroundStyle(p.ink3)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.clear))
            }
            .buttonStyle(.pressScale(0.85))
            .accessibilityLabel(PinchLocalization.resolve(PinchLocalization.format("Remove {0} from this day", [resolved.displayName])))
        }
        .padding(EdgeInsets(top: 9, leading: 16, bottom: 9, trailing: 16))
        .overlay(alignment: .top) {
            Rectangle().fill(p.line).frame(height: 1)
        }
    }

    private func entrySub(_ resolved: ResolvedEntry) -> String {
        let portion = resolved.entry.servings == 1
            ? resolved.displayServing
            : "\(PinchFormat.servings(resolved.entry.servings)) × \(resolved.displayServing)"
        return "\(portion), \(PinchFormat.time(resolved.entry.loggedAt))"
    }

    private func logAgain(_ resolved: ResolvedEntry) {
        let source = resolved.entry
        let isRemote = source.foodID?.hasPrefix(FatSecretConfig.idPrefix) == true
        guard !isRemote || PremiumAccessPolicy.allows(.remoteFoodLogging, isPremium: subscriptions.isPremium) else {
            ui.payOpen = true
            return
        }
        modelContext.insert(LogEntry(
            foodID: source.foodID,
            adhocName: source.adhocName,
            adhocMg: source.adhocMg,
            adhocServing: source.adhocServing,
            servings: source.servings,
            meal: Meal.auto(),
            loggedAt: timestamp(for: day),
            usesDefaultServing: source.usesDefaultServing
        ))
        ui.showToast(
            PinchLocalization.format("{0}, {1} mg", [resolved.displayName, String(describing: PinchFormat.mg(resolved.totalMg))]),
            isToday ? "Logged again." : "Logged again on this day."
        )
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Circle().fill(p.grain).frame(width: 5, height: 5)
                Circle().fill(p.grain).frame(width: 5, height: 5).offset(y: 4)
                Circle().fill(p.grain).frame(width: 5, height: 5)
            }
            .padding(.bottom, 10)
            PinchText("Nothing logged this day")
                .pinchBody(14, .semibold)
                .foregroundStyle(p.ink2)
            PinchText("The shaker stayed calm — or the log did.")
                .pinchBody(12)
                .foregroundStyle(p.ink3)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 26, leading: 20, bottom: 26, trailing: 20))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(p.grain, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }

    // MARK: - Motion and feedback

    @ViewBuilder private var flightOverlay: some View {
        if let flight {
            FlyingSodiumPill(flight: flight, progress: flightProgress)
                .allowsHitTesting(false)
                .zIndex(20)
        }
    }

    @ViewBuilder private var streakSparkles: some View {
        ForEach(0..<5, id: \.self) { index in
            SVGShape("M10 1.5 L12.2 7.8 L18.5 10 L12.2 12.2 L10 18.5 L7.8 12.2 L1.5 10 L7.8 7.8 Z")
                .fill(index.isMultiple(of: 2) ? p.amber : p.brand)
                .frame(width: 7, height: 7)
                .scaleEffect(streakBurst ? 1 : 0.2)
                .opacity(streakBurst ? 1 : 0)
                .offset(
                    x: CGFloat([-48, -22, 8, 35, 55][index]),
                    y: CGFloat([-16, -29, -34, -25, -8][index])
                )
        }
    }

    @ViewBuilder private var ringSparkles: some View {
        ForEach(0..<7, id: \.self) { index in
            let angle = Double(index) / 7 * Double.pi * 2
            let distance: CGFloat = ringBurst ? 62 : 10
            PinchText("✦")
                .font(.system(size: CGFloat(9 + (index % 3) * 2), weight: .bold))
                .foregroundStyle(index.isMultiple(of: 2) ? p.amber : p.brand)
                .offset(
                    x: cos(angle) * distance,
                    y: sin(angle) * distance + (ringBurst ? 12 : 0)
                )
                .rotationEffect(.degrees(ringBurst ? Double(index * 64) : 0))
                .scaleEffect(ringBurst ? 1 : 0.2)
                .opacity(ringBurst ? 0 : 1)
        }
        .allowsHitTesting(false)
    }

    @MainActor private func stageEntrance() async {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            displayedConsumed = 0
            revealBubble = false
            revealCards = false
            revealQuickHeader = false
            revealChips = false
            lastAddedEntry = nil
        }

        if reduceMotion {
            displayedConsumed = Double(consumed)
            revealBubble = true
            revealCards = true
            revealQuickHeader = true
            revealChips = true
            return
        }

        try? await Task.sleep(for: .milliseconds(420))
        guard !Task.isCancelled else { return }
        mascotTilt = 14
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 40, damping: 8.5, initialVelocity: 0)) {
            displayedConsumed = Double(consumed)
        }
        withAnimation(.interpolatingSpring(stiffness: 120, damping: 11)) {
            mascotTilt = 0
        }

        try? await Task.sleep(for: .milliseconds(530))
        guard !Task.isCancelled else { return }
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 19)) {
            revealBubble = true
        }

        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 19)) {
            revealCards = true
        }

        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }
        withAnimation(.interpolatingSpring(stiffness: 190, damping: 20)) {
            revealQuickHeader = true
        }

        try? await Task.sleep(for: .milliseconds(80))
        guard !Task.isCancelled else { return }
        withAnimation(.interpolatingSpring(stiffness: 190, damping: 20)) {
            revealChips = true
        }

        try? await Task.sleep(for: .milliseconds(520))
        guard !Task.isCancelled else { return }
        playMascotReaction(wasOver: false, willBeOver: remain < 0)
    }

    private func animateConsumption(from oldValue: Int, to newValue: Int) {
        guard oldValue != newValue else { return }
        if reduceMotion {
            displayedConsumed = Double(newValue)
            return
        }
        mascotTilt = newValue > oldValue ? 12 : -12
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 40, damping: 8.5, initialVelocity: 0)) {
            displayedConsumed = Double(newValue)
        }
        withAnimation(.interpolatingSpring(stiffness: 120, damping: 11).delay(0.08)) {
            mascotTilt = 0
        }
    }

    private func playMascotReaction(wasOver: Bool, willBeOver: Bool) {
        guard !reduceMotion else { return }
        mascotReaction = willBeOver ? .shock : .joy
        mascotWaving = !willBeOver

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            ringPulse = 1.045
            mascotHop = willBeOver ? -8 : -14
            mascotTilt = willBeOver ? 14 : -10
        }
        withAnimation(.interpolatingSpring(stiffness: 160, damping: 10)) {
            ringPulse = 1
            mascotHop = 0
            mascotTilt = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_000))
            mascotWaving = false
            try? await Task.sleep(for: .milliseconds(willBeOver ? 600 : 700))
            withAnimation(.easeInOut(duration: 0.28)) { mascotReaction = .none }
        }
    }

    private func undoLastAdd() {
        guard let entry = lastAddedEntry else { return }
        let amount = EntryResolver.resolve(entry, customFoods: customFoods).totalMg
        let returnsUnder = consumed > goal && consumed - amount <= goal
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) {
            modelContext.delete(entry)
            lastAddedEntry = nil
            if returnsUnder { streakBurst = true }
        }
        if returnsUnder {
            ringBurst = false
            withAnimation(.easeOut(duration: 0.85)) { ringBurst = true }
            playMascotReaction(wasOver: true, willBeOver: false)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(900))
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { ringBurst = false }
            }
        }
        ui.showToast("Entry removed", "Back to the number before that add.")
    }

    private func changeDay(to offset: Int) {
        guard offset != ui.selOffset else { return }
        lastAddedEntry = nil
        guard !reduceMotion else {
            ui.selOffset = offset
            return
        }
        let direction: CGFloat = offset > ui.selOffset ? 1 : -1
        withAnimation(.easeInOut(duration: 0.16)) {
            dayTransitionOffset = -direction * 38
            dayTransitionOpacity = 0.35
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                ui.selOffset = offset
                dayTransitionOffset = direction * 38
            }
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 22)) {
                dayTransitionOffset = 0
                dayTransitionOpacity = 1
            }
        }
    }

    private func ringBell() {
        guard !reduceMotion else {
            ui.notifCenterOpen = true
            return
        }
        bellDotDismissed.toggle()
        playMascotReaction(wasOver: false, willBeOver: false)
        withAnimation(.easeInOut(duration: 0.10)) { bellSwing = 16 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(110))
            withAnimation(.easeInOut(duration: 0.11)) { bellSwing = -13 }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeInOut(duration: 0.10)) { bellSwing = 9 }
            try? await Task.sleep(for: .milliseconds(110))
            withAnimation(.easeInOut(duration: 0.10)) { bellSwing = -6 }
            try? await Task.sleep(for: .milliseconds(110))
            withAnimation(.easeInOut(duration: 0.12)) { bellSwing = 0 }
            try? await Task.sleep(for: .milliseconds(100))
            ui.notifCenterOpen = true
        }
    }

    private func playStreakBurst() {
        guard !reduceMotion else { return }
        playMascotReaction(wasOver: false, willBeOver: false)
        streakBurst = false
        withAnimation(.easeOut(duration: 0.58)) { streakBurst = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(620))
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { streakBurst = false }
        }
    }
}

private struct SodiumFlight: Equatable {
    let id = UUID()
    let title: String
    let source: CGPoint
    let destination: CGPoint
}

private struct FlyingSodiumPill: View, Animatable {
    @Environment(\.pinch) private var p
    let flight: SodiumFlight
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let control = CGPoint(
            x: (flight.source.x + flight.destination.x) / 2,
            y: min(flight.source.y, flight.destination.y) - 92
        )
        let point = quadraticPoint(from: flight.source, control: control, to: flight.destination, t: progress)
        let fade = progress < 0.76 ? 1 : max(0, 1 - Double((progress - 0.76) / 0.24))

        PinchText(flight.title)
            .pinchBody(13, .bold)
            .monospacedDigit()
            .foregroundStyle(p.onBrand)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(p.brand))
            .shadow(color: p.glowBrand, radius: 7, y: 3)
            .position(point)
            .scaleEffect(1 - progress * 0.18)
            .opacity(fade)
    }

    private func quadraticPoint(from: CGPoint, control: CGPoint, to: CGPoint, t: CGFloat) -> CGPoint {
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * from.x + 2 * inverse * t * control.x + t * t * to.x,
            y: inverse * inverse * from.y + 2 * inverse * t * control.y + t * t * to.y
        )
    }
}

private struct AnimatedMilligramText: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        PinchText(PinchFormat.mg(Int(value.rounded())))
    }
}

private struct RingCenterPreferenceKey: PreferenceKey {
    static var defaultValue = CGPoint.zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { value = nextValue() }
}

private struct ChipCentersPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGPoint] = [:]
    static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - Shared timestamp helper

/// Timestamp for a new entry on `day`: now for today, midday-ish for past days.
func timestamp(for day: Date, calendar: Calendar = .current) -> Date {
    if calendar.isDateInToday(day) { return .now }
    let now = Date.now
    let hour = calendar.component(.hour, from: now)
    let minute = calendar.component(.minute, from: now)
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
}
