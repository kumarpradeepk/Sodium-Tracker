//
//  HistoryView.swift
//  Sodium Tracker
//

import SwiftUI
import SwiftData

/// One calendar day's worth of entries.
private struct DaySummary: Identifiable {
    let date: Date
    let entries: [SodiumEntry]

    var id: Date { date }
    var total: Int { entries.totalMilligrams }
}

/// Past days, newest first, with a rolling average.
struct HistoryView: View {
    @Query(sort: \SodiumEntry.loggedAt, order: .reverse) private var allEntries: [SodiumEntry]
    @AppStorage(AppSettings.dailyGoalKey) private var dailyGoal = AppSettings.defaultGoalMilligrams

    private var days: [DaySummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allEntries) { entry in
            calendar.startOfDay(for: entry.loggedAt)
        }
        return grouped
            .map { date, entries in
                DaySummary(date: date, entries: entries.sorted { $0.loggedAt > $1.loggedAt })
            }
            .sorted { $0.date > $1.date }
    }

    /// Mean daily total across the most recent seven logged days.
    private var recentAverage: Int? {
        let recent = days.prefix(7)
        guard !recent.isEmpty else { return nil }
        return recent.map(\.total).reduce(0, +) / recent.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if days.isEmpty {
                    ContentUnavailableView(
                        "No history yet",
                        systemImage: "calendar",
                        description: Text("Days you log sodium will show up here.")
                    )
                } else {
                    List {
                        if let recentAverage {
                            Section("Recent average") {
                                averageRow(recentAverage)
                            }
                        }

                        Section("By day") {
                            ForEach(days) { day in
                                NavigationLink {
                                    DayDetailView(date: day.date)
                                } label: {
                                    dayRow(day)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func averageRow(_ average: Int) -> some View {
        let status = IntakeStatus(total: average, goal: dailyGoal)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Format.milligrams(average))
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                Text("per day over the last \(min(days.count, 7)) logged days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            StatusPill(status: status)
        }
        .padding(.vertical, 4)
    }

    private func dayRow(_ day: DaySummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Format.dayHeading(for: day.date))
                    .font(.body.weight(.medium))
                Spacer()
                Text(Format.milligrams(day.total))
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(IntakeStatus(total: day.total, goal: dailyGoal).tint)
            }

            DayBar(total: day.total, goal: dailyGoal)

            Text("\(day.entries.count) \(day.entries.count == 1 ? "item" : "items")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

/// Slim horizontal bar comparing a day's total to the goal.
struct DayBar: View {
    let total: Int
    let goal: Int

    var body: some View {
        GeometryReader { proxy in
            let fraction = goal > 0 ? min(Double(total) / Double(goal), 1) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule()
                    .fill(IntakeStatus(total: total, goal: goal).tint)
                    .frame(width: max(4, proxy.size.width * fraction))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

/// All entries for one past day.
struct DayDetailView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SodiumEntry.loggedAt, order: .reverse) private var allEntries: [SodiumEntry]
    @AppStorage(AppSettings.dailyGoalKey) private var dailyGoal = AppSettings.defaultGoalMilligrams

    private var entries: [SodiumEntry] {
        allEntries.onSameDay(as: date)
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 14) {
                    SodiumRing(total: entries.totalMilligrams, goal: dailyGoal, lineWidth: 16)
                        .frame(maxWidth: 190)
                        .frame(height: 190)

                    StatusPill(status: IntakeStatus(total: entries.totalMilligrams, goal: dailyGoal))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section("Log") {
                ForEach(entries) { entry in
                    EntryRow(entry: entry)
                }
                .onDelete(perform: deleteEntries)
            }
        }
        .navigationTitle(Format.dayHeading(for: date))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteEntries(at offsets: IndexSet) {
        let entries = self.entries
        for index in offsets where entries.indices.contains(index) {
            modelContext.delete(entries[index])
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: SodiumEntry.self, inMemory: true)
}
