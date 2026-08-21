//
//  OverlaySheets.swift
//  Sodium Tracker
//
//  Scanner, "Jump to a day" calendar, the Nudges center, the Pinch Plus
//  paywall, and the widget promo sheet.
//

import SwiftUI
import SwiftData
import StoreKit

// MARK: - Scanner (z52)
// The design's scanner is a guided simulation: scanline for ~1.7 s, then a
// found card. Barcode mode resolves to the canned soup; label mode hands the
// printed number to Quick log.

struct ScannerScreen: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui

    // The scanner chrome is always dark, regardless of theme (per the design);
    // v2 draws its accents from the palette's scan tokens.
    private let bg = Color(hex: 0x0B1412)
    private let ink = Color(hex: 0xF0EBE0)
    private let amber = Color(hex: 0xEFB544)
    private let cardBg = Color(hex: 0x142523)
    private var acc: Color { p.scanAcc }

    private var isBarcode: Bool { ui.scanMode == .barcode }
    private var frameHeight: CGFloat { isBarcode ? 150 : 280 }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    PinchText("Point & log")
                        .font(PinchFonts.display(19, .bold))
                        .foregroundStyle(ink)
                    Spacer()
                    Button {
                        ui.scanOpen = false
                    } label: {
                        PinchText("×")
                            .font(.system(size: 16))
                            .foregroundStyle(ink)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(ink.opacity(0.12)))
                    }
                    .buttonStyle(.pressScale)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                modePicker
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                Spacer()

                scanFrame
                PinchText(caption)
                    .pinchBody(13)
                    .foregroundStyle(ink.opacity(0.65))
                    .padding(.top, 18)

                Spacer()
                Spacer()
            }

            if ui.scanPhase == .found {
                VStack {
                    Spacer()
                    foundCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .transition(.opacity)
        .animation(.pinchSheet, value: ui.scanPhase)
        .task(id: ui.scanToken) {
            guard ui.scanPhase == .scanning else { return }
            try? await Task.sleep(for: .seconds(1.7))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) { ui.scanPhase = .found }
        }
    }

    private var caption: String {
        if ui.scanPhase == .found { return "Got it." }
        return isBarcode ? "Center the barcode in the frame" : "Frame the Nutrition Facts panel"
    }

    private var modePicker: some View {
        HStack(spacing: 2) {
            modeButton("Barcode", mode: .barcode)
            modeButton("Nutrition label", mode: .label)
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ink.opacity(0.1)))
    }

    private func modeButton(_ label: String, mode: ScanMode) -> some View {
        let active = ui.scanMode == mode
        return Button {
            ui.startScan(mode)
        } label: {
            PinchText(label)
                .pinchBody(12.5, .semibold)
                .foregroundStyle(active ? Color(hex: 0x0C1917) : ink.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(active ? ink : .clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: active)
    }

    private var scanFrame: some View {
        ZStack {
            corners
            if ui.scanPhase == .scanning {
                scanline
            }
            if ui.scanPhase == .found {
                ZStack {
                    Circle()
                        .fill(p.scanAccSoft)
                        .overlay(Circle().strokeBorder(acc, lineWidth: 2))
                    SVGShape("M14 22.5 L19.5 28 L30 16.5", viewBox: CGSize(width: 44, height: 44))
                        .stroke(acc, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
                .frame(width: 44, height: 44)
                .transition(.scale(scale: 0.86).combined(with: .opacity))
            }
        }
        .frame(width: 240, height: frameHeight)
        .animation(.easeInOut(duration: 0.3), value: frameHeight)
    }

    private var corners: some View {
        ZStack {
            cornerMark
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            cornerMark.rotationEffect(.degrees(90))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            cornerMark.rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            cornerMark.rotationEffect(.degrees(270))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    private var cornerMark: some View {
        SVGShape("M0 26 V8 C0 3.6 3.6 0 8 0 H26", viewBox: CGSize(width: 26, height: 26))
            .stroke(acc, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 26, height: 26)
    }

    private var scanline: some View {
        KeyframeAnimator(initialValue: 0.1, repeating: true) { fraction in
            GeometryReader { geo in
                LinearGradient(
                    colors: [acc.opacity(0), acc, acc.opacity(0)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 2)
                .clipShape(Capsule())
                .shadow(color: p.scanAccGlow, radius: 6)
                .padding(.horizontal, 10)
                .offset(y: geo.size.height * fraction)
            }
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(0.86, duration: 1.1)
                CubicKeyframe(0.1, duration: 1.1)
            }
        }
    }

    private var foundCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(p.scanAccSoft)
                    .frame(width: 38, height: 38)
                    .overlay(LineIcon(d: FoodCategory.meal.iconPath, size: 20, color: acc))

                VStack(alignment: .leading, spacing: 1) {
                    PinchText(isBarcode ? "Campbell's chicken noodle" : "From the label")
                        .pinchBody(14.5, .bold)
                        .foregroundStyle(ink)
                        .lineLimit(1)
                    PinchText(isBarcode ? "1 cup · canned soup" : "sodium per serving, as printed")
                        .pinchBody(11.5)
                        .foregroundStyle(ink.opacity(0.55))
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    PinchText(isBarcode ? "870" : "470")
                        .pinchBody(17, .heavy)
                        .monospacedDigit()
                        .foregroundStyle(amber)
                    PinchText("MG")
                        .pinchBody(9.5, .bold, tracking: 0.08)
                        .foregroundStyle(ink.opacity(0.5))
                }
            }

            HStack(spacing: 8) {
                Button {
                    ui.startScan(ui.scanMode)
                } label: {
                    PinchText("Scan again")
                        .pinchBody(13.5, .bold)
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Capsule().fill(ink.opacity(0.1)))
                }
                .buttonStyle(.pressScale(0.97))

                Button {
                    useResult()
                } label: {
                    PinchText("Use this")
                        .pinchBody(13.5, .bold)
                        .foregroundStyle(p.scanInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Capsule().fill(acc))
                }
                .buttonStyle(.pressScale(0.97))
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(cardBg))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(hex: 0xF0EBE0, opacity: 0.12), lineWidth: 1)
        )
    }

    private func useResult() {
        ui.scanOpen = false
        if isBarcode {
            if let soup = FoodItem.builtIn("soup") {
                ui.pick(soup)
            }
        } else {
            ui.openQuickLog(prefillName: "From a label", prefillMg: "470")
        }
    }
}

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
        let pad = calendar.component(.weekday, from: first) - 1
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
                PinchText("Last two weeks · dot shows how salty it ran")
                    .pinchBody(12.5)
                    .foregroundStyle(p.ink3)
                    .padding(.top, 2)

                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"].indices, id: \.self) { i in
                        PinchText(["S", "M", "T", "W", "T", "F", "S"][i])
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

                    if notif {
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
                withAnimation(.easeInOut(duration: 0.25)) { notif = true }
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
                checkinRow("Breakfast", time: "8:00 AM", isOn: $remBreakfast, first: true)
                checkinRow("Lunch", time: "12:30 PM", isOn: $remLunch)
                checkinRow("Dinner", time: "6:30 PM", isOn: $remDinner)
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
                body: "Dinner check-in — \(PinchFormat.mg(max(0, yesterdayRemain))) mg still in the budget. Soup counts, I'm watching."
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
        return f.string(from: DayEngine.day(offset: -1)) + " · 9:00 AM"
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

// MARK: - Paywall (z80)

struct PaywallSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.openURL) private var openURL

    @AppStorage(PinchDefaults.plus) private var plus = false

    var body: some View {
        PinchSheet(onClose: { ui.payOpen = false }) {
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        SheetCloseButton { ui.payOpen = false }
                    }

                    PinchMascot(variant: .party, width: 86)
                        .padding(.top, -8)

                    PinchText("Pinch Plus")
                        .pinchDisplay(26, .heavy)
                        .foregroundStyle(p.ink)
                        .padding(.top, 6)
                    PinchText("Tracking is free forever. Plus adds the extras.")
                        .pinchBody(13)
                        .foregroundStyle(p.ink2)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        perk("Four-week trends and calendar")
                        perk("Home-screen widget")
                        perk("Unlimited custom shelf foods")
                        perk("CSV export for every logged entry")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)

                    VStack(spacing: 10) {
                        planCard(
                            plan: .yearly,
                            title: "Yearly",
                            tag: "BEST VALUE",
                            sub: planSubtitle(.yearly, fallback: "Loading yearly price…")
                        )
                        planCard(
                            plan: .monthly,
                            title: "Monthly",
                            tag: nil,
                            sub: planSubtitle(.monthly, fallback: "Loading monthly price…")
                        )
                    }
                    .padding(.top, 16)

                    PinchCTA(
                        title: ctaTitle,
                        height: 52,
                        enabled: plus || (!purchases.isLoading && purchases.product(for: ui.plan) != nil && !purchases.isPurchasing)
                    ) {
                        if plus {
                            openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                        } else {
                            startPurchase()
                        }
                    }
                    .padding(.top, 14)

                    if let error = purchases.errorMessage {
                        PinchText(error)
                            .pinchBody(11)
                            .foregroundStyle(p.coral)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                    }

                    HStack(spacing: 14) {
                        Button("Restore purchases") { Task { await purchases.restore() } }
                        Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                    .pinchBody(11, .semibold)
                    .foregroundStyle(p.ink3)
                    .padding(.top, 12)

                    PinchText("Payment and renewal are handled by the App Store. Cancel anytime in Apple Account subscriptions.")
                        .pinchBody(10.5)
                        .foregroundStyle(p.ink3)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 20))
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 700)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func perk(_ text: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(p.brandSoft)
                SVGShape("M6.5 10.2 L9 12.7 L13.5 7.6")
                    .stroke(p.brand, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 16, height: 16)
            }
            .frame(width: 16, height: 16)
            PinchText(text)
                .pinchBody(13.5)
                .foregroundStyle(p.ink2)
        }
    }

    private func planCard(plan: PlusPlan, title: String, tag: String?, sub: String) -> some View {
        RadioCard(selected: ui.plan == plan, action: { ui.plan = plan }) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 7) {
                    PinchText(title)
                        .pinchBody(15, .bold)
                        .foregroundStyle(p.ink)
                    if let tag {
                        PinchText(tag)
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
        }
    }

    private var ctaTitle: String {
        if plus { return "Manage subscription" }
        if purchases.isPurchasing { return "Working…" }
        if purchases.isLoading { return "Loading plans…" }
        return "Continue with Plus"
    }

    private func planSubtitle(_ plan: PlusPlan, fallback: String) -> String {
        guard let product = purchases.product(for: plan) else { return fallback }
        return plan == .yearly
            ? "\(product.displayPrice) / year · cancel anytime"
            : "\(product.displayPrice) / month · cancel anytime"
    }

    private func startPurchase() {
        Task {
            if await purchases.purchase(ui.plan) {
                ui.payOpen = false
                ui.showToast("Pinch Plus is active", "Your premium tools are unlocked.")
            }
        }
    }
}

// MARK: - Widget promo (z80)

struct WidgetSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui

    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    var body: some View {
        PinchSheet(onClose: { ui.widgetOpen = false }) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Home-screen widget") { ui.widgetOpen = false }

                WidgetMock(goal: goal, entries: entries, customFoods: customFoods)
                    .padding(.top, 16)

                WidgetSteps()
                    .padding(.top, 16)
                    .padding(.horizontal, 4)

                PinchCTA(title: "Got it", height: 50) {
                    ui.widgetOpen = false
                }
                .padding(.top, 18)
            }
            .padding(EdgeInsets(top: 14, leading: 20, bottom: 30, trailing: 20))
        }
    }
}

/// The fake home screen with the Pinch widget card (shared with onboarding).
struct WidgetMock: View {
    @Environment(\.pinch) private var p
    let goal: Int
    let entries: [LogEntry]
    let customFoods: [CustomFood]

    private var consumed: Int {
        DayEngine.total(entries, on: .now, customFoods: customFoods)
    }
    private var remain: Int { max(0, goal - consumed) }
    private var pct: Double {
        goal > 0 ? min(1, Double(consumed) / Double(goal)) : 0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.sunk)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(p.line, lineWidth: 1)

            VStack {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 7).fill(p.grain).opacity(0.5)
                        .frame(width: 22, height: 22)
                    RoundedRectangle(cornerRadius: 7).fill(p.grain).opacity(0.35)
                        .frame(width: 22, height: 22)
                    Spacer()
                }
                Spacer()
                HStack(spacing: 10) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 7).fill(p.grain).opacity(0.35)
                        .frame(width: 22, height: 22)
                    RoundedRectangle(cornerRadius: 7).fill(p.grain).opacity(0.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    PinchLogo(width: 12, bodyStroke: 4)
                    PinchText("PINCH")
                        .pinchBody(9.5, .heavy, tracking: 0.1)
                        .foregroundStyle(p.ink3)
                }
                PinchText(PinchFormat.mg(remain))
                    .font(PinchFonts.display(26, .heavy))
                    .tracking(26 * -0.02)
                    .monospacedDigit()
                    .foregroundStyle(p.ink)
                    .padding(.top, 8)
                PinchText("mg left today")
                    .pinchBody(10.5)
                    .foregroundStyle(p.ink3)
                    .padding(.top, 1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(p.sunk)
                        Capsule().fill(p.brand)
                            .frame(width: geo.size.width * pct)
                    }
                }
                .frame(height: 6)
                .padding(.top, 10)
            }
            .padding(14)
            .frame(width: 160)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(p.card))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(p.line, lineWidth: 1)
            )
            .pinchCardShadow(p)
            .padding(.vertical, 20)
        }
    }
}

/// The 1-2-3 widget instructions (shared with onboarding).
struct WidgetSteps: View {
    @Environment(\.pinch) private var p

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            step(1, "Press and hold anywhere on your Home Screen")
            step(2, "Tap the + in the top corner")
            step(3, "Search \"Pinch\", add the widget")
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(spacing: 10) {
            PinchText("\(n)")
                .pinchBody(11, .heavy)
                .foregroundStyle(p.brand)
                .frame(width: 20, height: 20)
                .background(Circle().fill(p.brandSoft))
            PinchText(text)
                .pinchBody(13)
                .foregroundStyle(p.ink2)
        }
    }
}
