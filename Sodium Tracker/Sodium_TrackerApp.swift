//
//  Sodium_TrackerApp.swift
//  Sodium Tracker
//
//  Created by pradeep.kumar1 on 01/08/26.
//

import SwiftUI
import SwiftData

@main
struct Sodium_TrackerApp: App {
    @State private var purchases = PurchaseManager()

    init() {
        // Defaults for keys read outside @AppStorage (NotificationManager
        // reads UserDefaults directly).
        UserDefaults.standard.register(defaults: [
            PinchDefaults.chatty: true,
            PinchDefaults.notif: true,
            PinchDefaults.health: true,
            PinchDefaults.mealRemBreakfast: true,
            PinchDefaults.mealRemLunch: false,
            PinchDefaults.mealRemDinner: true,
        ])
        PinchFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchases)
                .task { await purchases.start() }
        }
        .modelContainer(for: [LogEntry.self, CustomFood.self, Favorite.self])
    }
}
