//
//  SettingsView.swift
//  Sodium Tracker
//

import SwiftUI
import SwiftData

/// Daily goal configuration, data management, and the app's health disclaimer.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [SodiumEntry]
    @AppStorage(AppSettings.dailyGoalKey) private var dailyGoal = AppSettings.defaultGoalMilligrams

    @State private var isConfirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(GoalPreset.allCases) { preset in
                        Button {
                            dailyGoal = preset.rawValue
                        } label: {
                            goalPresetRow(preset)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Daily goal")
                } footer: {
                    Text("Most adults should stay under 2,300 mg a day. 1,500 mg is the ideal limit, especially with high blood pressure.")
                }

                Section("Custom goal") {
                    Stepper(
                        value: $dailyGoal,
                        in: AppSettings.minimumGoalMilligrams...AppSettings.maximumGoalMilligrams,
                        step: 100
                    ) {
                        HStack {
                            Text("Goal")
                            Spacer()
                            Text(Format.milligrams(dailyGoal))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                Section("Data") {
                    HStack {
                        Text("Entries logged")
                        Spacer()
                        Text(Format.number(allEntries.count))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Button("Delete all entries", role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .disabled(allEntries.isEmpty)
                }

                Section("About") {
                    Text("Sodium values in the quick-add catalog are typical estimates, not measurements of what you actually ate. Check product labels for accurate amounts.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Pinch is a tracking tool, not medical advice. Talk to a clinician about the right sodium target for you.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all entries?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete all", role: .destructive, action: deleteAll)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes every logged item. It cannot be undone.")
            }
        }
    }

    private func goalPresetRow(_ preset: GoalPreset) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(preset.title) · \(Format.milligrams(preset.rawValue))")
                    .foregroundStyle(.primary)
                Text(preset.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if dailyGoal == preset.rawValue {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.brand)
            }
        }
        .contentShape(Rectangle())
    }

    private func deleteAll() {
        for entry in allEntries {
            modelContext.delete(entry)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: SodiumEntry.self, inMemory: true)
}
