//
//  ContentView.swift
//  Sodium Tracker
//
//  Created by pradeep.kumar1 on 01/08/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "drop.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Theme.brand)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SodiumEntry.self, inMemory: true)
}
