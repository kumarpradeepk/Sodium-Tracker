//
//  SettingsScreen.swift
//  Sodium Tracker
//
//  "Your setup": Pinch Plus, the daily salt budget, appearance, nudges,
//  data & extras, and the account row.
//

import SwiftUI
import SwiftData
import UIKit

struct SettingsScreen: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(\.modelContext) private var modelContext

    @AppStorage(PinchDefaults.theme) private var theme = "light"
    @AppStorage(PinchDefaults.palette) private var palettePick = PalettePick.salty.rawValue
    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault
    @AppStorage(PinchDefaults.chatty) private var chatty = true
    @AppStorage(PinchDefaults.notif) private var notif = true
    @AppStorage(PinchDefaults.plus) private var plus = false
    @AppStorage(PinchDefaults.mealRemBreakfast) private var remBreakfast = true
    @AppStorage(PinchDefaults.mealRemLunch) private var remLunch = false
    @AppStorage(PinchDefaults.mealRemDinner) private var remDinner = true
    @AppStorage(PinchDefaults.hasOnboarded) private var hasOnboarded = false

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var showHealthSources = false

    private var goalChoice: GoalChoice {
        get { GoalChoice(rawValue: goalChoiceRaw) ?? .fda }
    }

    private var goal: Int { goalChoice.milligrams(custom: customGoal) }

    private var todayRemain: Int {
        goal - DayEngine.total(entries, on: .now, customFoods: customFoods)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PinchText("YOUR SETUP")
                    .pinchBody(11, .bold, tracking: 0.14)
                    .foregroundStyle(p.ink3)
                PinchText("Settings")
                    .pinchDisplay(30, .bold)
                    .foregroundStyle(p.ink)
                    .padding(.top, 2)

                plusCard.padding(.top, 16)

                SectionKicker(text: "DAILY SALT BUDGET")
                    .padding(.top, 18).padding(.bottom, 8)
                budgetCard

                SectionKicker(text: "APPEARANCE")
                    .padding(.top, 18).padding(.bottom, 8)
                appearanceCard

                SectionKicker(text: "PINCH & NUDGES")
                    .padding(.top, 18).padding(.bottom, 8)
                nudgesCard

                SectionKicker(text: "DATA & EXTRAS")
                    .padding(.top, 18).padding(.bottom, 8)
                dataCard

                SectionKicker(text: "ACCOUNT")
                    .padding(.top, 18).padding(.bottom, 8)
                accountCard

                PinchText("Pinch 1.0 · made with a pinch of love")
                    .pinchBody(11)
                    .foregroundStyle(p.ink3)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)

                if FatSecretConfig.isEnabled {
                    PinchText("Nutrition search powered by FatSecret")
                        .pinchBody(10.5)
                        .foregroundStyle(p.ink3)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showShare) {
            if let exportURL {
                ActivityShareSheet(items: [exportURL])
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showHealthSources) {
            HealthSourcesSheet()
                .presentationDetents([.large])
        }
        .onChange(of: notif) { refreshNotifications() }
        .onChange(of: remBreakfast) { refreshNotifications() }
        .onChange(of: remLunch) { refreshNotifications() }
        .onChange(of: remDinner) { refreshNotifications() }
    }

    private func refreshNotifications() {
        NotificationManager.refresh(remaining: todayRemain)
    }

    // MARK: - Pinch Plus

    private var plusCard: some View {
        PinchCard {
            HStack(spacing: 12) {
                PinchPlusMark(width: 34)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        PinchText("Pinch Plus")
                            .pinchBody(14.5, .bold)
                            .foregroundStyle(p.ink)
                        if plus {
                            PinchText("ON")
                                .pinchBody(9, .heavy, tracking: 0.1)
                                .foregroundStyle(p.onBrand)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(p.brand))
                        }
                    }
                    PinchText(plus
                         ? "Active — thanks for keeping Pinch fed."
                         : "The extras: month view, widget, your shelf, export.")
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                        .lineSpacing(2)
                }

                Spacer(minLength: 8)

                Button {
                    ui.payOpen = true
                } label: {
                    PinchText(plus ? "Manage plan" : "See what's inside")
                        .pinchBody(12, .bold)
                        .foregroundStyle(p.brand)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(p.brandSoft))
                }
                .buttonStyle(.pressScale)
            }
            .padding(EdgeInsets(top: 15, leading: 16, bottom: 15, trailing: 16))
            .background(alignment: .topLeading) {
                RadialGradient(
                    colors: [p.brandSoft, p.brandSoft.opacity(0)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 200
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Budget

    private var budgetCard: some View {
        PinchCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    PinchText(PinchFormat.mg(goal))
                        .font(PinchFonts.display(34, .heavy))
                        .tracking(34 * -0.02)
                        .monospacedDigit()
                        .foregroundStyle(p.ink)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: goal)
                    PinchText("mg / day")
                        .pinchBody(13)
                        .foregroundStyle(p.ink3)
                }

                PinchSegmented(
                    segments: [
                        PinchSegment(value: GoalChoice.aha.rawValue, label: "1,500 strict"),
                        PinchSegment(value: GoalChoice.fda.rawValue, label: "2,300 standard"),
                        PinchSegment(value: GoalChoice.custom.rawValue, label: "Custom"),
                    ],
                    selection: $goalChoiceRaw,
                    bordered: false
                )
                .padding(.top, 12)

                if goalChoice == .custom {
                    HStack(spacing: 14) {
                        stepButton("−") {
                            customGoal = max(PinchDefaults.customGoalRange.lowerBound, customGoal - PinchDefaults.customGoalStep)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(customGoal) },
                                set: { customGoal = Int($0 / 50) * 50 }
                            ),
                            in: Double(PinchDefaults.customGoalRange.lowerBound)...Double(PinchDefaults.customGoalRange.upperBound)
                        )
                        .tint(p.brand)
                        stepButton("+") {
                            customGoal = min(PinchDefaults.customGoalRange.upperBound, customGoal + PinchDefaults.customGoalStep)
                        }
                    }
                    .padding(.top, 14)
                }

                PinchText(goalChoice == .aha
                    ? "The 1,500 mg option reflects general AHA guidance. Individual needs vary—ask your clinician what is right for you."
                    : "The 2,300 mg option reflects FDA general guidance. Individual needs vary—ask your clinician what is right for you.")
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
                    .lineSpacing(3)
                    .padding(.top, 12)

                Button {
                    showHealthSources = true
                } label: {
                    HStack(spacing: 6) {
                        PinchText("Sources & health information")
                            .pinchBody(12, .bold)
                        SVGShape("M1 1 L7 7 L1 13", viewBox: CGSize(width: 8, height: 14))
                            .stroke(p.brand, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 7, height: 12)
                    }
                    .foregroundStyle(p.brand)
                    .padding(.top, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PinchText(symbol)
                .pinchBody(19, .bold)
                .foregroundStyle(p.ink2)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.sunk))
        }
        .buttonStyle(.pressScale(0.93))
    }

    // MARK: - Appearance

    private var appearanceCard: some View {
        PinchCard {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 11) {
                        SettingsIconTile(color: SettingsTileColors.theme, glyph: .moon)
                        PinchText("Theme")
                            .pinchBody(14, .semibold)
                            .foregroundStyle(p.ink)
                    }
                    Spacer()
                    PinchSegmented(
                        segments: [
                            PinchSegment(value: "light", label: "Light"),
                            PinchSegment(value: "dark", label: "Dark"),
                        ],
                        selection: $theme,
                        bordered: false
                    )
                    .frame(width: 150)
                }
                .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))

                // The design's Ocean/Sage/Iris palettes, surfaced in-app.
                HStack {
                    PinchText("Palette")
                        .pinchBody(14, .semibold)
                        .foregroundStyle(p.ink)
                    Spacer()
                    PinchSegmented(
                        segments: PalettePick.allCases.map {
                            PinchSegment(value: $0.rawValue, label: $0.label)
                        },
                        selection: $palettePick,
                        bordered: false
                    )
                    .frame(width: 210)
                }
                .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                .overlay(alignment: .top) {
                    Rectangle().fill(p.line).frame(height: 1)
                }
            }
        }
    }

    // MARK: - Nudges

    private var nudgesCard: some View {
        PinchCard {
            VStack(spacing: 0) {
                toggleRow(
                    title: "Pinch's chatter",
                    sub: "Little encouragements under the ring",
                    isOn: $chatty,
                    tile: SettingsIconTile(color: SettingsTileColors.chatter, glyph: .bubble),
                    first: true
                )
                toggleRow(
                    title: "Meal check-ins",
                    sub: "Gentle waves at mealtimes. Never guilt.",
                    isOn: $notif,
                    tile: SettingsIconTile(color: SettingsTileColors.checkins, glyph: .bell)
                )

                if notif {
                    mealRow("Breakfast", time: "8:00 AM", isOn: $remBreakfast)
                    mealRow("Lunch", time: "12:30 PM", isOn: $remLunch)
                    mealRow("Dinner", time: "6:30 PM", isOn: $remDinner)

                    notificationPreview
                        .padding(EdgeInsets(top: 4, leading: 16, bottom: 14, trailing: 16))
                }
            }
        }
    }

    private func toggleRow(
        title: String,
        sub: String,
        isOn: Binding<Bool>,
        tile: SettingsIconTile? = nil,
        first: Bool = false
    ) -> some View {
        HStack(spacing: 11) {
            if let tile { tile }
            VStack(alignment: .leading, spacing: 2) {
                PinchText(title)
                    .pinchBody(14, .semibold)
                    .foregroundStyle(p.ink)
                PinchText(sub)
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
            }
            Spacer()
            PinchSwitch(isOn: isOn)
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    private func mealRow(_ name: String, time: String, isOn: Binding<Bool>) -> some View {
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
        .padding(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16))
        .overlay(alignment: .top) {
            Rectangle().fill(p.line).frame(height: 1)
        }
    }

    private var notificationPreview: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(p.brand)
                .frame(width: 28, height: 28)
                .overlay(PinchGlyph(width: 13))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    PinchText("PINCH")
                        .pinchBody(11, .bold, tracking: 0.06)
                        .foregroundStyle(p.ink2)
                    Spacer()
                    PinchText("6:30 PM")
                        .pinchBody(10.5)
                        .foregroundStyle(p.ink3)
                }
                PinchText("Dinner check-in — \(PinchFormat.mg(max(0, todayRemain))) mg still in the budget. You've got this.")
                    .pinchBody(12)
                    .foregroundStyle(p.ink2)
                    .lineSpacing(3)
            }
        }
        .padding(EdgeInsets(top: 11, leading: 13, bottom: 11, trailing: 13))
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.sunk))
    }

    // MARK: - Data & extras

    private var dataCard: some View {
        PinchCard {
            VStack(spacing: 0) {
                navRow(
                    title: "Home-screen widget",
                    sub: "The ring, at a glance",
                    tile: SettingsIconTile(color: SettingsTileColors.widget, glyph: .widgetGrid),
                    divider: false
                ) {
                    if PremiumAccessPolicy.allows(.widgets, isPremium: plus) {
                        ui.widgetOpen = true
                    } else {
                        ui.payOpen = true
                    }
                }

                Button {
                    if PremiumAccessPolicy.allows(.csvExport, isPremium: plus) {
                        exportCSV()
                    } else {
                        ui.payOpen = true
                    }
                } label: {
                    HStack(spacing: 11) {
                        SettingsIconTile(color: SettingsTileColors.export, glyph: .exportArrow)
                        VStack(alignment: .leading, spacing: 2) {
                            PinchText("Export my data")
                                .pinchBody(14, .semibold)
                                .foregroundStyle(p.ink)
                            PinchText("Every entry, as a CSV")
                                .pinchBody(11.5)
                                .foregroundStyle(p.ink3)
                        }
                        Spacer()
                        LineIcon(
                            d: "M10 3 V13 M6 9.5 L10 13.5 L14 9.5 M4 16.5 H16",
                            size: 15, stroke: 1.8, color: p.ink3
                        )
                    }
                    .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) { Rectangle().fill(p.line).frame(height: 1) }

                Button {
                    ui.beginOnboarding()
                } label: {
                    HStack(spacing: 11) {
                        SettingsIconTile(color: SettingsTileColors.replay, glyph: .play)
                        PinchText("Replay welcome")
                            .pinchBody(14, .semibold)
                            .foregroundStyle(p.ink)
                        Spacer()
                        SVGShape("M1 1 L7 7 L1 13", viewBox: CGSize(width: 8, height: 14))
                            .stroke(p.ink3, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 7, height: 12)
                    }
                    .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) { Rectangle().fill(p.line).frame(height: 1) }

                navRow(
                    title: "Health information & sources",
                    sub: "Guidance, limitations, and citations",
                    tile: SettingsIconTile(color: SettingsTileColors.chatter, glyph: .heart),
                    divider: true
                ) {
                    showHealthSources = true
                }
            }
        }
    }

    private func navRow(
        title: String,
        sub: String,
        tile: SettingsIconTile? = nil,
        divider: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                if let tile { tile }
                VStack(alignment: .leading, spacing: 2) {
                    PinchText(title)
                        .pinchBody(14, .semibold)
                        .foregroundStyle(p.ink)
                    PinchText(sub)
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                }
                Spacer()
                SVGShape("M1 1 L7 7 L1 13", viewBox: CGSize(width: 8, height: 14))
                    .stroke(p.ink3, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 7, height: 12)
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if divider { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    private func exportCSV() {
        if let url = CSVExporter.writeTempFile(entries: entries, customFoods: customFoods) {
            exportURL = url
            showShare = true
        } else {
            ui.showToast("Export hit a snag", "Could not write the CSV. Try again.")
        }
    }

    // MARK: - Account

    private var accountCard: some View {
        let id = SeedData.userID()
        return PinchCard(padding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)) {
            HStack(spacing: 11) {
                SettingsIconTile(color: SettingsTileColors.user, glyph: .person)
                VStack(alignment: .leading, spacing: 2) {
                    PinchText("User ID")
                        .pinchBody(14, .semibold)
                        .foregroundStyle(p.ink)
                    PinchText(id)
                        .pinchBody(11.5)
                        .monospacedDigit()
                        .foregroundStyle(p.ink3)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = id
                    ui.showToast("User ID copied", "\(id) — handy for support chats.")
                } label: {
                    PinchText("Copy")
                        .pinchBody(12, .bold)
                        .foregroundStyle(p.ink2)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(p.sunk))
                }
                .buttonStyle(.pressScale)
            }
        }
    }
}
