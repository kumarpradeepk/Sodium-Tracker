//
//  TrendsScreen.swift
//  Sodium Tracker
//
//  "The long game": weekly bar chart with goal/average lines, stat quad,
//  day-by-day list, and the month salt calendar.
//

import SwiftUI
import SwiftData

struct TrendsScreen: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(SubscriptionStore.self) private var subscriptions

    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                if shownMode == .week {
                    weekNav
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                    chartCard
                        .padding(.top, 12)
                    PinchText("Based on logged foods. Unlogged meals aren’t included.")
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                        .padding(.top, 10)
                    statQuad
                        .padding(.top, 12)
                    SectionKicker(text: "DAY BY DAY: TAP TO REVISIT")
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    historyCard
                } else {
                    monthCard
                        .padding(.top, 14)
                    monthStats
                        .padding(.top, 12)
                    PinchText("Tap any tracked day to revisit its log.")
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
        .clipped()
    }

    // MARK: - Header

    private var shownMode: TrendsMode {
        PremiumAccessPolicy.allows(.monthTrends, isPremium: subscriptions.isPremium)
            ? ui.trMode
            : .week
    }

    private var header: some View {
        @Bindable var ui = ui
        return HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                PinchText("THE LONG GAME")
                    .pinchBody(11, .bold, tracking: 0.14)
                    .foregroundStyle(p.ink3)
                PinchText("Trends")
                    .pinchDisplay(30, .bold)
                    .foregroundStyle(p.ink)
            }
            Spacer()
            PinchSegmented(
                segments: [
                    PinchSegment(value: TrendsMode.week, label: "Week"),
                    PinchSegment(value: TrendsMode.month, label: "Month"),
                ],
                selection: Binding(
                    get: { shownMode },
                    set: { newMode in
                        if newMode == .month,
                           !PremiumAccessPolicy.allows(.monthTrends, isPremium: subscriptions.isPremium) {
                            ui.payOpen = true
                        } else {
                            ui.trMode = newMode
                        }
                    }
                )
            )
            .frame(width: 150)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Week mode

    private var thisWeek: DayEngine.WeekStats {
        DayEngine.week(entries, customFoods: customFoods, goal: goal, endOffset: 0)
    }

    private var lastWeek: DayEngine.WeekStats {
        DayEngine.week(entries, customFoods: customFoods, goal: goal, endOffset: -7)
    }

    private var shownWeek: DayEngine.WeekStats { ui.weekSel == 0 ? thisWeek : lastWeek }

    private var weekNav: some View {
        HStack(spacing: 10) {
            ChevronButton(direction: .leading, enabled: ui.weekSel == 0) {
                ui.weekSel = 1
            }
            PinchText(PinchFormat.weekRange(
                from: shownWeek.dayDates.first ?? .now,
                to: shownWeek.dayDates.last ?? .now
            ))
            .pinchBody(13, .bold)
            .foregroundStyle(p.ink)
            .frame(minWidth: 110)
            ChevronButton(direction: .trailing, enabled: ui.weekSel == 1) {
                ui.weekSel = 0
            }
        }
    }

    private var chartCard: some View {
        let week = shownWeek
        let maxBar = Double(max(goal, week.dayTotals.max() ?? goal)) * 1.06
        let letters = week.dayDates.map { dayLetter($0) }

        return PinchCard(radius: 20, padding: EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16)) {
            VStack(spacing: 0) {
                // Legend — above the plot, never inside it
                HStack(spacing: 14) {
                    Spacer()
                    legendSwatch(dash: [4, 3], label: PinchLocalization.format("GOAL {0}", [String(describing: PinchFormat.mg(goal))]))
                    if week.loggedDayCount > 0 {
                        legendSwatch(dash: [1.5, 2.5], label: PinchLocalization.format("AVG {0}", [String(describing: PinchFormat.mg(week.average))]), dotted: true)
                    }
                }
                .padding(.bottom, 10)

                // Plot
                GeometryReader { geo in
                    let h = geo.size.height
                    ZStack(alignment: .bottomLeading) {
                        line(dash: [4, 3], color: p.grain)
                            .offset(y: -h * CGFloat(Double(goal) / maxBar))
                        if week.loggedDayCount > 0 {
                            line(dash: [1.5, 2.5], color: p.ink3.opacity(0.5))
                                .offset(y: -h * CGFloat(week.average / maxBar))
                        }

                        HStack(alignment: .bottom, spacing: 9) {
                            ForEach(week.dayTotals.indices, id: \.self) { i in
                                bar(
                                    mg: week.dayTotals[i],
                                    logged: week.loggedDays[i],
                                    maxBar: maxBar,
                                    plotHeight: h,
                                    isLive: ui.weekSel == 0 && i == week.dayTotals.count - 1
                                )
                            }
                        }
                    }
                }
                .frame(height: 138)

                // Day letters
                HStack(spacing: 9) {
                    ForEach(letters.indices, id: \.self) { i in
                        let live = ui.weekSel == 0 && i == letters.count - 1
                        PinchText(letters[i])
                            .pinchBody(10.5, .bold)
                            .foregroundStyle(live ? p.brand : p.ink3)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
                .overlay(alignment: .top) {
                    Rectangle().fill(p.line).frame(height: 1)
                }
                .padding(.top, 0)
            }
        }
    }

    private func legendSwatch(dash: [CGFloat], label: String, dotted: Bool = false) -> some View {
        HStack(spacing: 6) {
            Line()
                .stroke(dotted ? p.ink3 : p.grain, style: StrokeStyle(lineWidth: 1.5, dash: dash))
                .frame(width: 20, height: 1.5)
            PinchText(label)
                .pinchBody(9.5, .bold, tracking: 0.08)
                .foregroundStyle(p.ink3)
        }
    }

    private func line(dash: [CGFloat], color: Color) -> some View {
        Line()
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: dash))
            .frame(height: 1.5)
            .frame(maxWidth: .infinity)
    }

    private func bar(mg: Int, logged: Bool, maxBar: Double, plotHeight: CGFloat, isLive: Bool) -> some View {
        let over = mg > goal
        let height = max(3, plotHeight * CGFloat(Double(mg) / maxBar))
        return VStack(spacing: 5) {
            PinchText(!logged ? "—" : isLive ? "now" : PinchFormat.thousands(Double(mg)))
                .pinchBody(9, .semibold)
                .monospacedDigit()
                .foregroundStyle(isLive ? p.brand : p.ink3)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(logged ? p.barFill(over: over, live: isLive).gradient : p.barFill(over: false, live: false).gradient)
                .opacity(logged ? 1 : 0)
                .frame(maxWidth: 30)
                .frame(height: height)
                .overlay {
                    if isLive && logged {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(p.bg, lineWidth: 2.5)
                            .padding(-2.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(over ? p.coral : p.brand, lineWidth: 2)
                                    .padding(-4.5)
                            )
                    }
                }
                .animation(.easeOut(duration: 0.6), value: height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func dayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = PinchFormat.locale
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    private var statQuad: some View {
        let this = thisWeek
        let last = lastWeek
        let delta = this.loggedDayCount > 0 && last.loggedDayCount > 0
            ? DayEngine.weekDelta(thisAvg: this.average, lastAvg: last.average) : nil
        let deltaLabel: String = {
            guard let delta else { return "—" }
            if delta > 0 { return "+\(delta)%" }
            if delta < 0 { return "−\(abs(delta))%" }
            return "0%"
        }()
        let week = shownWeek

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatCard(value: week.loggedDayCount == 0 ? "—" : PinchFormat.mg(week.average), caption: "average per logged day")
                StatCard(
                    value: deltaLabel,
                    caption: "this week vs last",
                    valueColor: (delta ?? 0) > 0 ? p.amber : p.brand
                )
            }
            HStack(spacing: 10) {
                StatCard(value: PinchLocalization.format("{0} of {1}", [String(describing: week.underCount), String(describing: week.loggedDayCount)]), caption: "logged days under budget")
                StatCard(
                    value: week.lightestDate.map { shortWeekday($0) } ?? "—",
                    caption: "lightest day"
                )
            }
        }
    }

    private func shortWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = PinchFormat.locale
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private var historyCard: some View {
        let week = shownWeek
        let rows = Array(zip(week.dayDates, week.dayTotals)).reversed()

        return PinchCard {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, pair in
                    let (date, mg) = pair
                    let over = mg > goal
                    Button {
                        jump(to: date)
                    } label: {
                        HStack(spacing: 12) {
                            PinchText(Calendar.current.isDateInToday(date) ? "Today" : PinchFormat.shortDay(date))
                                .pinchBody(13, .semibold)
                                .foregroundStyle(p.ink)
                                .frame(width: 86, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(p.sunk)
                                    Capsule()
                                        .fill(over ? p.coral : p.brand)
                                        .opacity(0.88)
                                        .frame(width: geo.size.width * CGFloat(min(1, Double(mg) / Double(goal))))
                                }
                            }
                            .frame(height: 5)

                            PinchText(entries.contains { Calendar.current.isDate($0.loggedAt, inSameDayAs: date) } ? PinchFormat.mg(mg) : "—")
                                .pinchBody(12.5, .bold)
                                .monospacedDigit()
                                .foregroundStyle(over ? p.coral : p.ink2)
                                .frame(width: 52, alignment: .trailing)

                            SVGShape("M1 1 L7 7 L1 13", viewBox: CGSize(width: 8, height: 14))
                                .stroke(p.ink3, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .frame(width: 6, height: 10)
                        }
                        .padding(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        if index > 0 {
                            Rectangle().fill(p.line).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func jump(to date: Date) {
        let start = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.startOfDay(for: date)
        let offset = Calendar.current.dateComponents([.day], from: start, to: target).day ?? 0
        ui.selOffset = max(UIState.minOffset, min(0, offset))
        withAnimation(.easeOut(duration: 0.35)) { ui.tab = .today }
    }

    // MARK: - Month mode

    /// Four rows ending on the region's last weekday.
    private var monthCells: [MonthCell] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        let weekday = PinchFormat.weekdayColumn(for: todayStart, calendar: calendar)
        let end = calendar.date(byAdding: .day, value: 6 - weekday, to: todayStart) ?? todayStart

        return (0..<28).map { i in
            let date = calendar.date(byAdding: .day, value: i - 27, to: end) ?? end
            let future = date > todayStart
            let tracked = !future && entries.contains { calendar.isDate($0.loggedAt, inSameDayAs: date) }
            let mg = tracked ? DayEngine.total(entries, on: date, customFoods: customFoods) : 0
            return MonthCell(
                date: date,
                number: calendar.component(.day, from: date),
                tracked: tracked,
                future: future,
                isToday: calendar.isDate(date, inSameDayAs: todayStart),
                isSelected: calendar.isDate(date, inSameDayAs: ui.selectedDay()),
                mg: mg
            )
        }
    }

    private struct MonthCell: Identifiable {
        let date: Date
        let number: Int
        let tracked: Bool
        let future: Bool
        let isToday: Bool
        let isSelected: Bool
        let mg: Int
        var id: Date { date }
    }

    private var monthCard: some View {
        let cells = monthCells
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return PinchCard(radius: 20, padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    PinchText("Salt calendar")
                        .pinchBody(13, .bold)
                        .foregroundStyle(p.ink)
                    Spacer()
                    PinchText("LAST 4 WEEKS")
                        .pinchBody(11, .bold, tracking: 0.1)
                        .foregroundStyle(p.ink3)
                }
                .padding(.bottom, 12)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(PinchFormat.weekdaySymbols.indices, id: \.self) { i in
                        PinchText(dayLetter(cells[i].date))
                            .pinchBody(9.5, .bold)
                            .foregroundStyle(p.ink3)
                    }
                }
                .padding(.bottom, 2)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(cells) { cell in
                        monthCellView(cell)
                    }
                }

                // Legend
                HStack(spacing: 12) {
                    legendDot(p.brand, "under")
                    legendDot(p.amber, "close")
                    legendDot(p.coral, "over")
                    HStack(spacing: 5) {
                        Circle()
                            .strokeBorder(p.grain, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                            .frame(width: 8, height: 8)
                        PinchText("No logs")
                            .pinchBody(10.5)
                            .foregroundStyle(p.ink3)
                    }
                }
                .padding(.top, 14)
                .overlay(alignment: .top) {
                    Rectangle().fill(p.line).frame(height: 1).offset(y: 3)
                }
            }
        }
    }

    private func monthCellView(_ cell: MonthCell) -> some View {
        Button {
            guard cell.tracked else { return }
            jump(to: cell.date)
        } label: {
            VStack(spacing: 4) {
                PinchText("\(cell.number)")
                    .pinchBody(11.5, .bold)
                    .monospacedDigit()
                    .foregroundStyle(cell.tracked ? p.ink : p.ink3)
                    .opacity(cell.future ? 0.35 : 1)
                if cell.tracked {
                    Circle()
                        .fill(dotColor(mg: cell.mg))
                        .frame(width: 8, height: 8)
                } else if cell.future {
                    Circle().fill(.clear).frame(width: 8, height: 8)
                } else {
                    Circle()
                        .strokeBorder(p.grain, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(cell.isSelected ? p.brandSoft : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(cell.isToday ? p.brandDeep : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!cell.tracked)
    }

    private func dotColor(mg: Int) -> Color {
        if mg > goal { return p.coral }
        if Double(mg) > Double(goal) * 0.85 { return p.amber }
        return p.brand
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            PinchText(label)
                .pinchBody(10.5)
                .foregroundStyle(p.ink3)
        }
    }

    private var monthStats: some View {
        let totals = monthCells.filter(\.tracked).map(\.mg)
        let count = max(totals.count, 1)
        let avg = Double(totals.reduce(0, +)) / Double(count)
        let under = totals.filter { $0 <= goal }.count
        let over = totals.filter { $0 > goal }.count

        return HStack(spacing: 10) {
            StatCard(value: totals.isEmpty ? "—" : PinchFormat.mg(avg), caption: "average per logged day", valueSize: 20)
            StatCard(value: PinchLocalization.format("{0} of {1}", [String(describing: under), String(describing: totals.count)]), caption: "days under", valueSize: 20)
            StatCard(value: "\(over)", caption: "salty days", valueColor: p.coral, valueSize: 20)
        }
    }
}

/// A simple horizontal line shape for dashed rules.
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
