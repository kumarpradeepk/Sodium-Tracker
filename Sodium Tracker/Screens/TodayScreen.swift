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
    @Environment(\.modelContext) private var modelContext

    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault
    @AppStorage(PinchDefaults.chatty) private var chatty = true
    @AppStorage(PinchDefaults.notif) private var notif = true

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

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
    private var mood: Mood { Mood.forPercent(pct) }

    private var streak: Int { DayEngine.streak(entries) }

    private var bubbleLine: String {
        if isToday { return mood.line }
        return Mood.pastLine(empty: dayEntries.isEmpty, over: remain < 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                titleRow
                ringBlock
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)

                if chatty {
                    speechBubble
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                }

                statDuo
                    .padding(.top, 18)

                SectionKicker(text: "USUAL SUSPECTS")
                    .padding(.top, 22)
                    .padding(.bottom, 10)
                quickChips

                SectionKicker(text: isToday ? "LOGGED TODAY" : "LOGGED THIS DAY")
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                loggedList
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 2) {
                ChevronButton(
                    direction: .leading,
                    enabled: ui.selOffset > UIState.minOffset,
                    filled: false,
                    size: 28
                ) {
                    ui.selOffset = max(UIState.minOffset, ui.selOffset - 1)
                }
                Button {
                    ui.calOpen = true
                } label: {
                    Text(PinchFormat.kicker(day))
                        .pinchBody(11, .bold, tracking: 0.14)
                        .foregroundStyle(p.ink3)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 3)
                }
                .buttonStyle(.plain)
                ChevronButton(
                    direction: .trailing,
                    enabled: ui.selOffset < 0,
                    filled: false,
                    size: 28
                ) {
                    ui.selOffset = min(0, ui.selOffset + 1)
                }
            }
            .padding(.leading, -6)

            Spacer()

            Button {
                ui.notifCenterOpen = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    LineIcon(
                        d: "M10 3 C7 3 5.5 5.2 5.5 8 C5.5 11.4 4.5 12.6 3.8 13.6 C3.5 14.1 3.8 14.8 4.4 14.8 L15.6 14.8 C16.2 14.8 16.5 14.1 16.2 13.6 C15.5 12.6 14.5 11.4 14.5 8 C14.5 5.2 13 3 10 3 Z M8.4 16.6 C8.7 17.4 9.3 17.9 10 17.9 C10.7 17.9 11.3 17.4 11.6 16.6",
                        size: 16,
                        color: p.ink2
                    )
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(p.chip))
                    .overlay(Circle().strokeBorder(p.line, lineWidth: 1))

                    Circle()
                        .fill(p.coral)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().strokeBorder(p.bg, lineWidth: 1.5))
                        .offset(x: -5, y: 5)
                        .opacity(notif ? 1 : 0)
                }
            }
            .buttonStyle(.pressScale(0.92))
            .accessibilityLabel("Nudges")
        }
        .padding(.bottom, 2)
    }

    private var titleRow: some View {
        HStack(alignment: .top) {
            Text(PinchFormat.dayTitle(day))
                .pinchDisplay(30, .bold)
                .foregroundStyle(p.ink)
            Spacer()
            HStack(spacing: 6) {
                SVGShape("M10 1.5 L12.2 7.8 L18.5 10 L12.2 12.2 L10 18.5 L7.8 12.2 L1.5 10 L7.8 7.8 Z")
                    .fill(p.amber)
                    .frame(width: 13, height: 13)
                Text("\(streak)-day streak")
                    .pinchBody(12.5, .bold)
                    .foregroundStyle(p.amber)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(p.amberSoft))
            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
            .padding(.top, 4)
        }
    }

    // MARK: - Ring + mascot

    private var ringBlock: some View {
        ZStack(alignment: .top) {
            ProgressRing(consumed: consumed, goal: goal, size: 250)

            VStack(spacing: 0) {
                Text(PinchFormat.mg(consumed))
                    .font(PinchFonts.display(46, .heavy))
                    .tracking(46 * -0.03)
                    .monospacedDigit()
                    .foregroundStyle(p.ink)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: consumed)

                Button {
                    withAnimation(.easeOut(duration: 0.35)) { ui.tab = .settings }
                } label: {
                    Text("of \(PinchFormat.mg(goal)) mg")
                        .pinchBody(13)
                        .foregroundStyle(p.ink2)
                        .underline(true, pattern: .dot, color: p.ink3)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Text(remain >= 0
                     ? "\(PinchFormat.mg(remain)) mg left"
                     : "over by \(PinchFormat.mg(-remain)) mg")
                    .pinchBody(11.5, .bold)
                    .foregroundStyle(p.remainColor(remain: remain, pct: pct))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(p.chip))
                    .padding(.top, 7)
            }
            .padding(.top, 62)

            PinchMascot(variant: .hero(mood), width: 104)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: 12)
        }
        .frame(width: 250, height: 250)
    }

    private var speechBubble: some View {
        ZStack(alignment: .top) {
            Text(bubbleLine)
                .pinchBody(13)
                .foregroundStyle(p.ink2)
                .multilineTextAlignment(.center)
                .padding(EdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14))
                .frame(maxWidth: 270)
                .fixedSize(horizontal: true, vertical: true)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(p.line, lineWidth: 1)
                )
                .pinchSegShadow(p)

            Rectangle()
                .fill(p.card)
                .frame(width: 9, height: 9)
                .rotationEffect(.degrees(45))
                .overlay(
                    Rectangle()
                        .strokeBorder(p.line, lineWidth: 1)
                        .rotationEffect(.degrees(45))
                        .mask(alignment: .top) { Rectangle().frame(height: 7) }
                )
                .offset(y: -4.5)
        }
    }

    // MARK: - Stats

    private var statDuo: some View {
        HStack(spacing: 10) {
            StatCard(
                value: remain >= 0 ? PinchFormat.mg(remain) : "−\(PinchFormat.mg(-remain))",
                caption: remain >= 0
                    ? (isToday ? "mg left today" : "mg was left over")
                    : "mg over budget",
                valueColor: p.remainColor(remain: remain, pct: pct)
            )
            StatCard(
                value: "\(underCountThisWeek) of 7",
                caption: "days under budget this week"
            )
        }
    }

    private var underCountThisWeek: Int {
        DayEngine.week(entries, customFoods: customFoods, goal: goal).underCount
    }

    // MARK: - Quick chips

    private var quickChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(UsualSuspects.ids, id: \.self) { id in
                    if let food = FoodItem.builtIn(id) {
                        Button {
                            quickAdd(food)
                        } label: {
                            HStack(spacing: 7) {
                                Text("+")
                                    .pinchBody(13, .bold)
                                    .foregroundStyle(p.brand)
                                    .frame(width: 18, height: 18)
                                    .background(Circle().fill(p.brandSoft))
                                Text(food.name)
                                    .pinchBody(13, .semibold)
                                    .foregroundStyle(p.ink)
                                Text(PinchFormat.mg(food.mg))
                                    .pinchBody(11.5, .semibold)
                                    .monospacedDigit()
                                    .foregroundStyle(p.ink3)
                            }
                            .padding(EdgeInsets(top: 9, leading: 11, bottom: 9, trailing: 14))
                            .background(Capsule().fill(p.card))
                            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                            .pinchSegShadow(p)
                        }
                        .buttonStyle(.pressScale)
                    }
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
        let meal = Meal.auto()
        let stamp = timestamp(for: day)
        modelContext.insert(LogEntry(foodID: food.id, servings: 1, meal: meal, loggedAt: stamp))
        ui.showToast("\(food.name) · \(PinchFormat.mg(food.mg)) mg", ToastCopy.line(forAdded: food.mg))
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
                    Text(meal.rawValue)
                        .pinchBody(13, .bold)
                        .foregroundStyle(p.ink)
                    Spacer()
                    Text("\(PinchFormat.mg(total)) mg")
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
                Text(resolved.name)
                    .pinchBody(14, .semibold)
                    .foregroundStyle(p.ink)
                    .lineLimit(1)
                Text(entrySub(resolved))
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
            }

            Spacer(minLength: 8)

            Text(PinchFormat.mg(resolved.totalMg))
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
            .accessibilityLabel("Log \(resolved.name) again today")

            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    modelContext.delete(resolved.entry)
                }
            } label: {
                Text("×")
                    .font(.system(size: 15))
                    .foregroundStyle(p.ink3)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.clear))
            }
            .buttonStyle(.pressScale(0.85))
            .accessibilityLabel("Remove \(resolved.name)")
        }
        .padding(EdgeInsets(top: 9, leading: 16, bottom: 9, trailing: 16))
        .overlay(alignment: .top) {
            Rectangle().fill(p.line).frame(height: 1)
        }
    }

    private func entrySub(_ resolved: ResolvedEntry) -> String {
        let portion = resolved.entry.servings == 1
            ? resolved.serving
            : "\(PinchFormat.servings(resolved.entry.servings)) × \(resolved.serving)"
        return "\(portion) · \(PinchFormat.time(resolved.entry.loggedAt))"
    }

    private func logAgain(_ resolved: ResolvedEntry) {
        let source = resolved.entry
        modelContext.insert(LogEntry(
            foodID: source.foodID,
            adhocName: source.adhocName,
            adhocMg: source.adhocMg,
            adhocServing: source.adhocServing,
            servings: source.servings,
            meal: Meal.auto(),
            loggedAt: .now
        ))
        ui.showToast(
            "\(resolved.name) · \(PinchFormat.mg(resolved.totalMg)) mg",
            isToday ? "Logged again." : "Logged again for today."
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
            Text("Nothing logged this day")
                .pinchBody(14, .semibold)
                .foregroundStyle(p.ink2)
            Text("The shaker stayed calm — or the log did.")
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
