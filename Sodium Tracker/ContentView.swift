//
//  ContentView.swift
//  Sodium Tracker
//
//  Created by pradeep.kumar1 on 01/08/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [LogEntry.self, CustomFood.self, Favorite.self], inMemory: true)
}
