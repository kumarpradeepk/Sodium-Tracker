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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SubscriptionStore.self) private var subscriptions

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

            if ui.quickAddOpen {
                palette.scrim
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.pinchMenu) { ui.quickAddOpen = false }
                    }
                    .transition(.opacity)
                    .zIndex(24)
            }

            dock
                .zIndex(26)
            ZStack { overlays }
                .animation(reduceMotion ? nil : .pinchSheet, value: ui.logOpen)
                .animation(reduceMotion ? nil : .pinchSheet, value: ui.quickAddOpen)
                .animation(reduceMotion ? nil : .pinchSheet, value: ui.notifCenterOpen)
                .animation(reduceMotion ? nil : .pinchSheet, value: ui.calOpen)
                .animation(reduceMotion ? nil : .pinchSheet, value: ui.picked)
                .animation(reduceMotion ? nil : .pinchSheet, value: ui.qlOpen)
                .animation(reduceMotion ? nil : .pinchSheet, value: ui.cfOpen)
                .animation(.timingCurve(0.2, 0.9, 0.3, 1, duration: 0.35), value: ui.toast)
                .animation(.easeInOut(duration: 0.3), value: ui.showOnboarding)
                .animation(reduceMotion ? nil : .pinchSheet, value: ui.payOpen)
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
            publishWidgetSnapshot()
        }
        .onChange(of: entries.count) { _, _ in publishWidgetSnapshot() }
        .onChange(of: customFoods.count) { _, _ in publishWidgetSnapshot() }
        .onChange(of: goal) { _, _ in publishWidgetSnapshot() }
        .onChange(of: subscriptions.isPremium) { _, _ in publishWidgetSnapshot() }
        .onOpenURL { url in
            guard url.scheme == "sodiumtracker" else { return }
            if url.host == "paywall" { ui.payOpen = true }
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
            insertion: .opacity.combined(with: .offset(x: ui.tabDirection * 36)),
            removal: .opacity.combined(with: .offset(x: ui.tabDirection * -18))
        ))
        .animation(reduceMotion ? nil : .interpolatingSpring(stiffness: 180, damping: 22), value: ui.tab)
    }

    // MARK: - Dock

    private var dock: some View {
        VStack {
            Spacer()
            DockBar(
                tab: Binding(get: { ui.tab }, set: { ui.selectTab($0) }),
                isAddOpen: ui.quickAddOpen || ui.logOpen
            ) {
                withAnimation(.pinchMenu) {
                    ui.quickAddOpen.toggle()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .opacity(ui.showOnboarding ? 0 : 1)
    }

    // MARK: - Overlays (design z-order)

    @ViewBuilder private var overlays: some View {
        // z40 — log a food
        if ui.quickAddOpen {
            QuickAddSheet().zIndex(40)
        }
        if ui.logOpen {
            LogSheet().zIndex(42)
        }
        // z44 — nudges center
        if ui.notifCenterOpen {
            NudgesSheet().zIndex(44)
        }
        // z46 — jump to a day
        if ui.calOpen {
            if PremiumAccessPolicy.allows(.historyCalendar, isPremium: subscriptions.isPremium) {
                CalendarSheet().zIndex(46)
            } else {
                Color.clear
                    .onAppear {
                        ui.calOpen = false
                        ui.payOpen = true
                    }
                    .zIndex(46)
            }
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
        // z80 — verified StoreKit paywall
        if ui.payOpen {
            PaywallSheet().zIndex(80)
        }
    }

    private func refreshNotifications() {
        let todayTotal = DayEngine.total(entries, on: .now, customFoods: customFoods)
        NotificationManager.refresh(remaining: goal - todayTotal)
    }

    private func publishWidgetSnapshot() {
        PinchWidgetSnapshotStore.update(
            entries: entries,
            customFoods: customFoods,
            goal: goal,
            isPremium: subscriptions.isPremium
        )
    }
}

// MARK: - Shared sheet-presentation animation

extension Animation {
    /// The design's sheet timing: 320 ms cubic-bezier(.2,.9,.3,1).
    static var pinchSheet: Animation {
        .timingCurve(0.2, 0.9, 0.3, 1, duration: 0.32)
    }

    /// The floating quick menu uses the prototype's slightly overshooting
    /// bottom-origin pop instead of the taller sheet transition.
    static var pinchMenu: Animation {
        .timingCurve(0.3, 1.5, 0.4, 1, duration: 0.30)
    }
}
