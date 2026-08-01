//
//  EntryRow.swift
//  Sodium Tracker
//

import SwiftUI

/// One logged item in a day's list.
struct EntryRow: View {
    let entry: SodiumEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body)

                Text(
                    Format.entrySubtitle(
                        servings: entry.servings,
                        milligramsPerServing: entry.milligramsPerServing
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.milligrams(entry.totalMilligrams))
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()

                Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
