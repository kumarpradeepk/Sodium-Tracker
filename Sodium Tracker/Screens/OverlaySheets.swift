//
//  OverlaySheets.swift
//  Sodium Tracker
//
//  "Jump to a day" calendar, the Nudges center, and the Pinch Plus paywall.
//

import SwiftUI
import SwiftData
import StoreKit

// MARK: - Jump to a day (z46)

struct CalendarSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui

    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    private struct Cell: Identifiable {
        let id: Int          // offset; > 0 used for leading pads
        let offset: Int?
        let number: Int
        let mg: Int
    }

    private var cells: [Cell] {
        let calendar = Calendar.current
        var result: [Cell] = []
        let first = DayEngine.day(offset: UIState.minOffset)
        let pad = PinchFormat.weekdayColumn(for: first, calendar: calendar)
        for i in 0..<pad {
            result.append(Cell(id: 1000 + i, offset: nil, number: 0, mg: 0))
        }
        for offset in UIState.minOffset...0 {
            let date = DayEngine.day(offset: offset)
            result.append(Cell(
                id: offset,
                offset: offset,
                number: calendar.component(.day, from: date),
                mg: DayEngine.total(entries, on: date, customFoods: customFoods)
            ))
        }
        return result
    }

    var body: some View {
        PinchSheet(onClose: { ui.calOpen = false }) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Jump to a day") { ui.calOpen = false }
                PinchText("Last four weeks: colored dots show logged days")
                    .pinchBody(12.5)
                    .foregroundStyle(p.ink3)
                    .padding(.top, 2)

                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(PinchFormat.weekdaySymbols.indices, id: \.self) { i in
                        PinchText(PinchFormat.weekdaySymbols[i])
                            .pinchBody(9.5, .bold)
                            .foregroundStyle(p.ink3)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 2)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(cells) { cell in
                        cellView(cell)
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        ui.selOffset = -1
                        ui.calOpen = false
                    } label: {
                        PinchText("Yesterday")
                            .pinchBody(14, .bold)
                            .foregroundStyle(p.ink2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Capsule().fill(p.sunk))
                    }
                    .buttonStyle(.pressScale(0.97))

                    Button {
                        ui.selOffset = 0
                        ui.calOpen = false
                    } label: {
                        PinchText("Today")
                            .pinchBody(14, .bold)
                            .foregroundStyle(p.onBrand)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Capsule().fill(p.brand))
                            .shadow(color: p.brand.opacity(0.55), radius: 11, y: 6)
                    }
                    .buttonStyle(.pressScale(0.97))
                }
                .padding(.top, 16)
            }
            .padding(EdgeInsets(top: 14, leading: 20, bottom: 34, trailing: 20))
        }
    }

    @ViewBuilder private func cellView(_ cell: Cell) -> some View {
        if let offset = cell.offset {
            let selected = offset == ui.selOffset
            let isToday = offset == 0
            Button {
                ui.selOffset = offset
                ui.calOpen = false
            } label: {
                VStack(spacing: 4) {
                    PinchText("\(cell.number)")
                        .pinchBody(13, .bold)
                        .monospacedDigit()
                        .foregroundStyle(selected ? p.onBrand : p.ink)
                    Circle()
                        .fill(selected ? p.onBrand : dotColor(mg: cell.mg))
                        .frame(width: 7, height: 7)
                        .opacity(entries.contains { Calendar.current.isDate($0.loggedAt, inSameDayAs: DayEngine.day(offset: offset)) } ? 1 : 0)
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 7, trailing: 0))
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? p.brand : .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isToday && !selected ? p.brandDeep : .clear, lineWidth: 1.5)
                )
            }
            .buttonStyle(.pressScale(0.93))
        } else {
            Color.clear.frame(height: 44)
        }
    }

    private func dotColor(mg: Int) -> Color {
        if mg > goal { return p.coral }
        if Double(mg) > Double(goal) * 0.85 { return p.amber }
        return p.brand
    }
}

// MARK: - Nudges center (z44)

struct NudgesSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationAuthorized = false

    @AppStorage(PinchDefaults.notif) private var notif = true
    @AppStorage(PinchDefaults.mealRemBreakfast) private var remBreakfast = true
    @AppStorage(PinchDefaults.mealRemLunch) private var remLunch = false
    @AppStorage(PinchDefaults.mealRemDinner) private var remDinner = true
    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    var body: some View {
        PinchSheet(onClose: { ui.notifCenterOpen = false }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SheetHeader(title: "Nudges") { ui.notifCenterOpen = false }

                    if notif && notificationAuthorized {
                        onContent
                    } else {
                        offContent
                    }
                }
                .padding(EdgeInsets(top: 14, leading: 20, bottom: 34, trailing: 20))
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 640)
            .fixedSize(horizontal: false, vertical: true)
        }
        .onChange(of: notif) { refresh() }
        .onChange(of: remBreakfast) { refresh() }
        .onChange(of: remLunch) { refresh() }
        .onChange(of: remDinner) { refresh() }
        .task { notificationAuthorized = await NotificationManager.isAuthorized() }
        .onChange(of: ui.notificationPrompt?.id) { _, _ in
            Task { notificationAuthorized = await NotificationManager.isAuthorized() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { notificationAuthorized = await NotificationManager.isAuthorized() } }
        }
    }

    private func refresh() {
        let remaining = goal - DayEngine.total(entries, on: .now, customFoods: customFoods)
        NotificationManager.refresh(remaining: remaining)
    }

    private var offContent: some View {
        VStack(spacing: 0) {
            LineIcon(
                d: "M10 3 C7 3 5.5 5.2 5.5 8 C5.5 11.4 4.5 12.6 3.8 13.6 C3.5 14.1 3.8 14.8 4.4 14.8 L15.6 14.8 C16.2 14.8 16.5 14.1 16.2 13.6 C15.5 12.6 14.5 11.4 14.5 8 C14.5 5.2 13 3 10 3 Z M8.4 16.6 C8.7 17.4 9.3 17.9 10 17.9 C10.7 17.9 11.3 17.4 11.6 16.6 M3 3 L17 17",
                size: 26, color: p.ink3
            )
            .padding(.bottom, 8)
            PinchText("Nudges are off")
                .pinchBody(14, .semibold)
                .foregroundStyle(p.ink2)
            PinchText("Pinch stays quiet. Flip them on for gentle mealtime waves.")
                .pinchBody(12)
                .foregroundStyle(p.ink3)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 4)
            Button {
                ui.notificationPrompt = NotificationPrompt(context: .settings)
            } label: {
                PinchText("Turn on nudges")
                    .pinchBody(12.5, .bold)
                    .foregroundStyle(p.brand)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(p.brandSoft))
            }
            .buttonStyle(.pressScale)
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20))
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.card))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(p.grain, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
        .padding(.top, 16)
    }

    @ViewBuilder private var onContent: some View {
        PinchText("MEAL CHECK-INS")
            .pinchBody(11, .bold, tracking: 0.13)
            .foregroundStyle(p.ink3)
            .padding(EdgeInsets(top: 16, leading: 2, bottom: 8, trailing: 2))

        PinchCard {
            VStack(spacing: 0) {
                checkinRow("Breakfast", time: PinchFormat.clock(hour: 8, minute: 0), isOn: $remBreakfast, first: true)
                checkinRow("Lunch", time: PinchFormat.clock(hour: 12, minute: 30), isOn: $remLunch)
                checkinRow("Dinner", time: PinchFormat.clock(hour: 18, minute: 30), isOn: $remDinner)
            }
        }

        PinchText("RECENT")
            .pinchBody(11, .bold, tracking: 0.13)
            .foregroundStyle(p.ink3)
            .padding(EdgeInsets(top: 16, leading: 2, bottom: 8, trailing: 2))

        VStack(spacing: 8) {
            recentCard(
                tileColor: p.brand,
                tile: AnyView(PinchGlyph(width: 13)),
                time: "Yesterday 6:30 PM",
                body: PinchLocalization.format("Dinner check-in — {0} mg still in the budget. Soup counts, I’m keeping track.", [String(describing: PinchFormat.mg(max(0, yesterdayRemain)))])
            )
            recentCard(
                tileColor: p.amber,
                tile: AnyView(
                    SVGShape("M10 1.5 L12.2 7.8 L18.5 10 L12.2 12.2 L10 18.5 L7.8 12.2 L1.5 10 L7.8 7.8 Z")
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 13, height: 13)
                ),
                time: streakCardDate,
                body: "Two weeks of logging, every single day. You and me both."
            )
        }

        PinchText("One wave per meal, quiet hours respected. Never guilt.")
            .pinchBody(11.5)
            .foregroundStyle(p.ink3)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.top, 14)
    }

    private var yesterdayRemain: Int {
        goal - DayEngine.total(entries, on: DayEngine.day(offset: -1), customFoods: customFoods)
    }

    private var streakCardDate: String {
        let f = DateFormatter()
        f.locale = PinchFormat.locale
        f.dateFormat = "MMM d"
        return f.string(from: DayEngine.day(offset: -1)) + ", 9:00 AM"
    }

    private func checkinRow(_ name: String, time: String, isOn: Binding<Bool>, first: Bool = false) -> some View {
        HStack(spacing: 10) {
            PinchText(name)
                .pinchBody(13.5, .semibold)
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
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    private func recentCard(tileColor: Color, tile: AnyView, time: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tileColor)
                .frame(width: 28, height: 28)
                .overlay(tile)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    PinchText("PINCH")
                        .pinchBody(11, .bold, tracking: 0.06)
                        .foregroundStyle(p.ink2)
                    Spacer()
                    PinchText(time)
                        .pinchBody(10.5)
                        .foregroundStyle(p.ink3)
                }
                PinchText(body)
                    .pinchBody(12)
                    .foregroundStyle(p.ink2)
                    .lineSpacing(3)
            }
        }
        .padding(EdgeInsets(top: 11, leading: 13, bottom: 11, trailing: 13))
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(p.line, lineWidth: 1)
        )
    }
}
