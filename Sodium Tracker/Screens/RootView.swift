//
//  RootView.swift
//  Sodium Tracker
//
//  The app shell: theme, tab screens, floating dock, and the full overlay
//  stack (sheets, scanner, toast, onboarding, paywall) in the design's
//  z-order.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(PinchDefaults.theme) private var theme = "light"
    @AppStorage(PinchDefaults.palette) private var palettePick = PalettePick.ocean.rawValue
    @AppStorage(PinchDefaults.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    @State private var ui = UIState()

    private var palette: PinchPalette {
        PinchPalette.resolve(PalettePick(rawValue: palettePick) ?? .ocean, dark: theme == "dark")
    }

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    var body: some View {
        ZStack {
            palette.bg.ignoresSafeArea()

            screens
            dock
            ZStack { overlays }
                .animation(.pinchSheet, value: ui.logOpen)
                .animation(.pinchSheet, value: ui.notifCenterOpen)
                .animation(.pinchSheet, value: ui.calOpen)
                .animation(.pinchSheet, value: ui.picked)
                .animation(.pinchSheet, value: ui.qlOpen)
                .animation(.pinchSheet, value: ui.cfOpen)
                .animation(.easeInOut(duration: 0.25), value: ui.scanOpen)
                .animation(.timingCurve(0.2, 0.9, 0.3, 1, duration: 0.35), value: ui.toast)
                .animation(.easeInOut(duration: 0.3), value: ui.showOnboarding)
                .animation(.pinchSheet, value: ui.payOpen)
                .animation(.pinchSheet, value: ui.widgetOpen)
        }
        .environment(\.pinch, palette)
        .environment(ui)
        .preferredColorScheme(theme == "dark" ? .dark : .light)
        .animation(.easeInOut(duration: 0.4), value: theme)
        .animation(.easeInOut(duration: 0.4), value: palettePick)
        .task(id: ui.toast?.id) {
            guard ui.toast != nil else { return }
            try? await Task.sleep(for: .seconds(2.8))
            withAnimation(.easeOut(duration: 0.3)) { ui.toast = nil }
        }
        .onAppear {
            PinchFonts.register()
            SeedData.seedIfNeeded(context: modelContext)
            if !hasOnboarded {
                ui.beginOnboarding()
            }
            refreshNotifications()
        }
    }

    // MARK: - Screens

    @ViewBuilder private var screens: some View {
        Group {
            switch ui.tab {
            case .today: TodayScreen()
            case .trends: TrendsScreen()
            case .awards: AwardsScreen()
            case .settings: SettingsScreen()
            }
        }
        .id(ui.tab)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: 12)),
            removal: .opacity
        ))
        .animation(.easeOut(duration: 0.35), value: ui.tab)
    }

    // MARK: - Dock

    private var dock: some View {
        VStack {
            Spacer()
            DockBar(tab: Binding(get: { ui.tab }, set: { ui.tab = $0 })) {
                ui.search = ""
                ui.logOpen = true
            }
            .padding(.bottom, 26)
        }
        .ignoresSafeArea(edges: .bottom)
        .opacity(ui.showOnboarding ? 0 : 1)
    }

    // MARK: - Overlays (design z-order)

    @ViewBuilder private var overlays: some View {
        // z40 — log a food
        if ui.logOpen {
            LogSheet().zIndex(40)
        }
        // z44 — nudges center
        if ui.notifCenterOpen {
            NudgesSheet().zIndex(44)
        }
        // z46 — jump to a day
        if ui.calOpen {
            CalendarSheet().zIndex(46)
        }
        // z50 — portion / quick log / create food
        if ui.picked != nil {
            PortionSheet().zIndex(50)
        }
        if ui.qlOpen {
            QuickLogSheet().zIndex(50)
        }
        if ui.cfOpen {
            CreateFoodSheet().zIndex(50)
        }
        // z52 — scanner
        if ui.scanOpen {
            ScannerScreen().zIndex(52)
        }
        // z60 — toast
        if let toast = ui.toast {
            VStack {
                ToastView(toast: toast)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Spacer()
            }
            .zIndex(60)
        }
        // z70 — onboarding
        if ui.showOnboarding {
            OnboardingFlow().zIndex(70)
        }
        // z80 — paywall & widget promo
        if ui.payOpen {
            PaywallSheet().zIndex(80)
        }
        if ui.widgetOpen {
            WidgetSheet().zIndex(80)
        }
    }

    private func refreshNotifications() {
        let todayTotal = DayEngine.total(entries, on: .now, customFoods: customFoods)
        NotificationManager.refresh(remaining: goal - todayTotal)
    }
}

// MARK: - Shared sheet-presentation animation

extension Animation {
    /// The design's sheet timing: 320 ms cubic-bezier(.2,.9,.3,1).
    static var pinchSheet: Animation {
        .timingCurve(0.2, 0.9, 0.3, 1, duration: 0.32)
    }
}
