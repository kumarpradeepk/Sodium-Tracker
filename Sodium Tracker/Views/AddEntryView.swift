//
//  AddEntryView.swift
//  Sodium Tracker
//

import SwiftUI
import SwiftData

/// A group of catalog presets shown under one category heading.
private struct PresetGroup: Identifiable {
    let category: FoodPreset.Category
    let items: [FoodPreset]

    var id: String { category.rawValue }
}

/// Sheet for logging an item, either typed by hand or picked from the catalog.
struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var milligramsText = ""
    @State private var servings = 1.0
    @State private var searchText = ""

    private var milligrams: Int? {
        Int(milligramsText.trimmingCharacters(in: .whitespaces))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && (milligrams ?? 0) > 0
    }

    private var totalPreview: Int {
        Int((Double(milligrams ?? 0) * servings).rounded())
    }

    private var groups: [PresetGroup] {
        let matches = FoodPreset.matching(searchText)
        return FoodPreset.Category.allCases.compactMap { category in
            let items = matches.filter { $0.category == category }
            return items.isEmpty ? nil : PresetGroup(category: category, items: items)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)

                    HStack {
                        Text("Sodium")
                        Spacer()
                        TextField("0", text: $milligramsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .frame(maxWidth: 110)
                        Text("mg")
                            .foregroundStyle(.secondary)
                    }

                    Stepper(value: $servings, in: 0.25...20, step: 0.25) {
                        HStack {
                            Text("Servings")
                            Spacer()
                            Text(Format.servings(servings))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                if canSave && servings != 1 {
                    Section {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(Format.milligrams(totalPreview))
                                .font(.headline)
                                .monospacedDigit()
                        }
                    }
                }

                if groups.isEmpty {
                    Section {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    ForEach(groups) { group in
                        Section(group.category.rawValue) {
                            ForEach(group.items) { preset in
                                Button {
                                    apply(preset)
                                } label: {
                                    presetRow(preset)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log sodium")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search foods")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func presetRow(_ preset: FoodPreset) -> some View {
        HStack(spacing: 12) {
            Image(systemName: preset.category.symbol)
                .foregroundStyle(Theme.brand)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                Text(preset.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(Format.milligrams(preset.milligrams))
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Fills the form with this item")
    }

    // MARK: - Actions

    private func apply(_ preset: FoodPreset) {
        name = preset.name
        milligramsText = String(preset.milligrams)
        servings = 1
        searchText = ""
    }

    private func save() {
        guard canSave, let milligrams else { return }
        modelContext.insert(
            SodiumEntry(
                name: trimmedName,
                milligramsPerServing: milligrams,
                servings: servings
            )
        )
        dismiss()
    }
}

#Preview {
    AddEntryView()
        .modelContainer(for: SodiumEntry.self, inMemory: true)
}
