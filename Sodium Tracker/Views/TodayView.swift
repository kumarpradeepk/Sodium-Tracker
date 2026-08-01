//
//  TodayView.swift
//  Sodium Tracker
//

import SwiftUI
import SwiftData

/// The home screen: today's running sodium total, quick logging, and the day's log.
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SodiumEntry.loggedAt, order: .reverse) private var allEntries: [SodiumEntry]
    @AppStorage(AppSettings.dailyGoalKey) private var dailyGoal = AppSettings.defaultGoalMilligrams

    @State private var isPresentingAdd = false
    @State private var quickAddCount = 0

    private var todayEntries: [SodiumEntry] {
        allEntries.onSameDay(as: .now)
    }

    private var total: Int {
        todayEntries.totalMilligrams
    }

    private var status: IntakeStatus {
        IntakeStatus(total: total, goal: dailyGoal)
    }

    /// A short, curated strip of the most commonly logged items.
    private var quickPicks: [FoodPreset] {
        let names = ["Pinch of salt", "Bread", "Pizza", "Canned soup", "Deli turkey", "Potato chips"]
        return names.compactMap { name in
            FoodPreset.catalog.first { $0.name == name }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section("Quick add") {
                    quickAddStrip
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Today's log") {
                    if todayEntries.isEmpty {
                        emptyLog
                    } else {
                        ForEach(todayEntries) { entry in
                            EntryRow(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Pinch")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Label("Add entry", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddEntryView()
            }
            .sensoryFeedback(.success, trigger: quickAddCount)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 16) {
            SodiumRing(total: total, goal: dailyGoal)
                .frame(maxWidth: 240)
                .frame(height: 240)

            StatusPill(status: status)

            Text(remainingDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var remainingDescription: String {
        if total > dailyGoal {
            return "\(Format.milligrams(total - dailyGoal)) over your daily goal."
        }
        if total == dailyGoal {
            return "You've hit your daily goal exactly."
        }
        return "\(Format.milligrams(dailyGoal - total)) left today."
    }

    private var quickAddStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(quickPicks) { preset in
                    Button {
                        quickAdd(preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)

                            Text(Format.milligrams(preset.milligrams))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(minWidth: 120, alignment: .leading)
                        .background(Theme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add \(preset.name), \(Format.milligrams(preset.milligrams))")
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyLog: some View {
        ContentUnavailableView(
            "Nothing logged yet",
            systemImage: "drop",
            description: Text("Use Quick add above, or tap + to log an item.")
        )
        .listRowBackground(Color.clear)
    }

    // MARK: - Actions

    private func quickAdd(_ preset: FoodPreset) {
        modelContext.insert(
            SodiumEntry(name: preset.name, milligramsPerServing: preset.milligrams)
        )
        quickAddCount += 1
    }

    private func deleteEntries(at offsets: IndexSet) {
        let entries = todayEntries
        for index in offsets where entries.indices.contains(index) {
            modelContext.delete(entries[index])
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: SodiumEntry.self, inMemory: true)
}
