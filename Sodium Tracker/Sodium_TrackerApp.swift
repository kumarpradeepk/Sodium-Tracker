//
//  Sodium_TrackerApp.swift
//  Sodium Tracker
//
//  Created by pradeep.kumar1 on 01/08/26.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct Sodium_TrackerApp: App {
    @State private var subscriptions = SubscriptionStore()
    @AppStorage(PinchLocalization.preferenceKey) private var language = "system"

    init() {
        // Defaults for keys read outside @AppStorage (NotificationManager
        // reads UserDefaults directly).
        UserDefaults.standard.register(defaults: [
            PinchDefaults.chatty: true,
            PinchDefaults.notif: true,
            PinchDefaults.mealRemBreakfast: true,
            PinchDefaults.mealRemLunch: false,
            PinchDefaults.mealRemDinner: true,
        ])
        PinchFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(language)
                .environment(\.locale, PinchLocalization.locale)
                .environment(subscriptions)
                .task(id: language) {
                    UserDefaults(suiteName: PinchLocalization.appGroup)?.set(language, forKey: PinchLocalization.preferenceKey)
                    NotificationManager.refresh(remaining: 0)
                    await NotificationManager.refreshTrialLanguage()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .task { await subscriptions.prepare() }
        }
        .modelContainer(for: [LogEntry.self, CustomFood.self, Favorite.self])
    }
}
