//
//  CSVExporter.swift
//  Sodium Tracker
//
//  "Export my data — every entry, as a CSV."
//

import Foundation
import SwiftUI
import UIKit

enum CSVExporter {
    /// Builds the CSV text for every entry, oldest first.
    static func csv(entries: [LogEntry], customFoods: [CustomFood], calendar: Calendar = .current) -> String {
        var lines = ["date,time,meal,food,portion,servings,mg"]
        let dateF = DateFormatter()
        dateF.locale = PinchFormat.locale
        dateF.calendar = calendar
        dateF.dateFormat = "yyyy-MM-dd"

        for entry in entries.sorted(by: { $0.loggedAt < $1.loggedAt }) {
            let resolved = EntryResolver.resolve(entry, customFoods: customFoods)
            let fields = [
                dateF.string(from: entry.loggedAt),
                PinchFormat.time(entry.loggedAt, calendar: calendar),
                entry.meal.rawValue,
                escape(resolved.name),
                escape(resolved.serving),
                PinchFormat.servings(entry.servings),
                String(resolved.totalMg),
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    /// Writes the CSV to a temp file and returns its URL.
    static func writeTempFile(entries: [LogEntry], customFoods: [CustomFood]) -> URL? {
        let text = csv(entries: entries, customFoods: customFoods)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pinch-sodium-log.csv")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

/// UIKit share sheet wrapper for the exported file.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
