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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SodiumEntry.self)
    }
}
