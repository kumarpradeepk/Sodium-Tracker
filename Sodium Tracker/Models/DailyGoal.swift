//
//  DailyGoal.swift
//  Sodium Tracker
//

import SwiftUI

/// Keys and defaults for user preferences.
enum AppSettings {
    static let dailyGoalKey = "dailyGoalMilligrams"

    /// The FDA Daily Value for sodium, and the app's default ceiling.
    static let defaultGoalMilligrams = 2300

    static let minimumGoalMilligrams = 500
    static let maximumGoalMilligrams = 6000
}

/// Well-known daily sodium ceilings a user can pick from.
enum GoalPreset: Int, CaseIterable, Identifiable {
    case idealLimit = 1500
    case dailyValue = 2300

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .idealLimit: return "Ideal limit"
        case .dailyValue: return "Daily Value"
        }
    }

    var subtitle: String {
        switch self {
        case .idealLimit:
            return "American Heart Association ideal limit for most adults"
        case .dailyValue:
            return "FDA Daily Value — the general upper limit"
        }
    }
}

/// How a day's running total compares to the goal.
enum IntakeStatus {
    case onTrack
    case closeToLimit
    case overLimit

    init(total: Int, goal: Int) {
        guard goal > 0 else {
            self = .onTrack
            return
        }
        let ratio = Double(total) / Double(goal)
        switch ratio {
        case ..<0.75: self = .onTrack
        case ..<1.0: self = .closeToLimit
        default: self = .overLimit
        }
    }

    var tint: Color {
        switch self {
        case .onTrack: return Theme.good
        case .closeToLimit: return Theme.caution
        case .overLimit: return Theme.over
        }
    }

    var label: String {
        switch self {
        case .onTrack: return "On track"
        case .closeToLimit: return "Close to limit"
        case .overLimit: return "Over limit"
        }
    }

    var symbol: String {
        switch self {
        case .onTrack: return "checkmark.circle.fill"
        case .closeToLimit: return "exclamationmark.circle.fill"
        case .overLimit: return "exclamationmark.triangle.fill"
        }
    }
}
