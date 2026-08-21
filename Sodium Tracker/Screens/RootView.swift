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

    @AppStorage(PinchDefaults.theme) private var theme = "light"
    @AppStorage(PinchDefaults.palette) private var palettePick = PalettePick.salty.rawValue
    @AppStorage(PinchDefaults.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault
    @AppStorage(PinchDefaults.plus) private var plus = false

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    @State private var ui = UIState()
    @State private var engine = SaltyEngine()
    /// The launch splash covers everything until its choreography finishes.
    @State private var splashDone = false

    private var pick: PalettePick { PalettePick(rawValue: palettePick) ?? .salty }

    private var palette: PinchPalette {
        PinchPalette.resolve(pick, dark: theme == "dark")
    }

    private var saltyTokens: SaltyTokens {
        SaltyTokens.resolve(pick, dark: theme == "dark")
    }

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    var body: some View {
        ZStack {
            saltyTokens.screenBg.ignoresSafeArea()

            screens
            quickAddLayer
            dock
            // The design's fx layer: fly pills and sparkles, above everything
            // on the screen but below modal sheets.
            SaltyParticleLayer(engine: engine)
                .ignoresSafeArea()
                .zIndex(30)
            if !splashDone {
                SplashScreen {
                    withAnimation(.easeOut(duration: 0.45)) { splashDone = true }
                }
                .transition(.opacity)
                .zIndex(100)
            }
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
        .environment(\.salty, saltyTokens)
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
            engine.reducedMotion = reduceMotion
            engine.start()
            scheduleReveals()
        }
        .onDisappear { engine.stop() }
        .onChange(of: reduceMotion) { _, new in engine.reducedMotion = new }
        .task(id: widgetSnapshot) {
            PinchWidgetSnapshotStore.write(
                consumed: widgetSnapshot.consumed,
                goal: widgetSnapshot.goal,
                streak: widgetSnapshot.streak,
                isPremium: widgetSnapshot.premium
            )
        }
    }

    private var widgetSnapshot: WidgetSnapshotInput {
        WidgetSnapshotInput(
            consumed: DayEngine.total(entries, on: .now, customFoods: customFoods),
            goal: goal,
            streak: DayEngine.streak(entries),
            premium: plus
        )
    }

    // MARK: - Screens

    @ViewBuilder private var screens: some View {
        Group {
            switch ui.tab {
            case .today: SaltyTodayScreen(engine: engine).nudgeHost()
            case .trends: TrendsScreen()
            case .awards: AwardsScreen()
            case .settings: SettingsScreen()
            }
        }
        .id(ui.tab)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(x: 36)),
            removal: .opacity.combined(with: .offset(x: -36))
        ))
        .animation(.timingCurve(0.22, 0.9, 0.3, 1, duration: 0.32), value: ui.tab)
    }

    // MARK: - Quick add

    @ViewBuilder private var quickAddLayer: some View {
        if !ui.showOnboarding {
            ZStack(alignment: .bottom) {
                // Scrim sits below the tab bar, per the prototype's z-order.
                // The design's flat 16% navy was too weak once real content sat
                // behind it, so this adds a blur and deepens the tint — the
                // sheet has to read as the foreground layer (spec §15.13).
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    // ~54% navy, matching Android's scrim so the two platforms
                    // read the same. The design's flat 16% vanished behind real
                    // content (spec §15.13).
                    saltyTokens.scrim.opacity(3.4)
                }
                .opacity(ui.quickAddOpen ? 1 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(ui.quickAddOpen)
                .onTapGesture { closeQuickAdd() }

                QuickAddSheet(
                    items: SaltyModel.quickAdds(from: entries, customFoods: customFoods),
                    onPick: quickAdd,
                    onFullLog: {
                        closeQuickAdd()
                        ui.search = ""
                        ui.logOpen = true
                    }
                )
                .padding(.bottom, 122)
                .scaleEffect(ui.quickAddOpen ? 1 : 0.9, anchor: .bottom)
                .offset(y: ui.quickAddOpen ? 0 : 16)
                .opacity(ui.quickAddOpen ? 1 : 0)
                .allowsHitTesting(ui.quickAddOpen)
            }
            .animation(.timingCurve(0.3, 1.5, 0.4, 1, duration: 0.3), value: ui.quickAddOpen)
            .zIndex(20)
        }
    }

    // MARK: - Tab bar

    private var dock: some View {
        VStack {
            Spacer()
            SaltyTabBar(
                tab: Binding(get: { ui.tab }, set: { ui.tab = $0 }),
                sheetOpen: ui.quickAddOpen,
                onFab: { ui.quickAddOpen.toggle() }
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .opacity(ui.showOnboarding ? 0 : 1)
        .zIndex(25)
    }

    private func closeQuickAdd() {
        ui.quickAddOpen = false
    }

    /// Fires the load-in reveals once per launch (spec §8). Held at the shell
    /// so returning to the Today tab never replays the choreography.
    private func scheduleReveals() {
        guard ui.revealed.isEmpty else { return }
        guard !reduceMotion else {
            ui.revealed = Set(SaltyReveal.allCases)
            return
        }
        for stage in SaltyReveal.allCases {
            DispatchQueue.main.asyncAfter(deadline: .now() + stage.rawValue) {
                ui.revealed.insert(stage)
            }
        }
        // The design's unprompted hello at 1.9 s.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            engine.wave(1.3)
            engine.flash(.joy, seconds: 1.5)
        }
    }

    /// Quick-add routes back to Today (and to today's date) before logging,
    /// exactly as the prototype does (spec §9).
    private func quickAdd(_ item: QuickAddItem, from source: CGPoint) {
        closeQuickAdd()

        let fly = {
            engine.spawnFly(
                from: source,
                to: CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 60),
                label: "+\(PinchFormat.mg(item.mg)) mg"
            ) {
                applyQuickAdd(item)
            }
        }

        if ui.tab != .today {
            withAnimation(.timingCurve(0.22, 0.9, 0.3, 1, duration: 0.32)) { ui.tab = .today }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34, execute: fly)
        } else if ui.selOffset != 0 {
            ui.selOffset = 0
            engine.settleFraction()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42, execute: fly)
        } else {
            fly()
        }
    }

    private func applyQuickAdd(_ item: QuickAddItem) {
        let goalNow = goal
        let consumedNow = DayEngine.total(entries, on: .now, customFoods: customFoods)
        let before = goalNow - consumedNow
        let after = before - item.mg

        let entry: LogEntry = if let food = item.food {
            LogEntry(foodID: food.id, servings: 1, meal: Meal.auto())
        } else {
            LogEntry(adhocName: item.name, adhocMg: item.mg, servings: 1, meal: Meal.auto())
        }
        modelContext.insert(entry)
        ui.undoStack.append(entry.persistentModelID)

        engine.impulse(pulse: 2.4)
        if after < 0 && before >= 0 {
            engine.flash(.shock, seconds: 1.6)
            if engine.energyFull { engine.impulse(hop: -130, cap: -130, tilt: 200) }
        } else if after < 0 {
            engine.flash(.worried, seconds: 1.4)
            if engine.energyFull { engine.impulse(tilt: 160) }
        } else {
            engine.flash(.joy, seconds: 1.7)
            engine.impulse(hop: engine.energyFull ? -230 : -90)
            engine.wave(1.0)
        }
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
        // Never prompt before onboarding has asked in its own words — the system
        // alert otherwise fires over the splash and steals the first tap.
        guard hasOnboarded else { return }
        let todayTotal = DayEngine.total(entries, on: .now, customFoods: customFoods)
        NotificationManager.refresh(remaining: goal - todayTotal)
    }
}

private struct WidgetSnapshotInput: Hashable {
    let consumed: Int
    let goal: Int
    let streak: Int
    let premium: Bool
}

// MARK: - Shared sheet-presentation animation

extension Animation {
    /// The design's sheet timing: 320 ms cubic-bezier(.2,.9,.3,1).
    static var pinchSheet: Animation {
        .timingCurve(0.2, 0.9, 0.3, 1, duration: 0.32)
    }
}
