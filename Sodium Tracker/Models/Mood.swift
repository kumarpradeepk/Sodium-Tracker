//
//  Mood.swift
//  Sodium Tracker
//
//  Pinch's mood engine. Thresholds and face path data verbatim from the design.
//

import Foundation

/// The mascot's mood, driven by percent of the daily budget consumed.
enum Mood: String, CaseIterable {
    case fresh   // < 40%
    case ok      // 40–77%
    case wary    // 78–99%
    case over    // ≥ 100%

    static func forPercent(_ pct: Double) -> Mood {
        if pct < 40 { return .fresh }
        if pct < 78 { return .ok }
        if pct < 100 { return .wary }
        return .over
    }

    /// Mouth path (SVG, 120×130 mascot space).
    var mouth: String {
        switch self {
        case .fresh: return "M52 87 Q60 93.5 68 87"
        case .ok: return "M50 85.5 Q60 96.5 70 85.5"
        case .wary: return "M53 90.5 Q60 88 67 90.5"
        case .over: return "M52 93.5 Q60 87.5 68 93.5"
        }
    }

    var browLeft: String {
        switch self {
        case .fresh, .ok: return "M42 63 Q48 60 54 63"
        case .wary: return "M42 64 Q48 60.5 54 62.5"
        case .over: return "M43 62.5 Q48.5 61.5 53.5 64"
        }
    }

    var browRight: String {
        switch self {
        case .fresh, .ok: return "M66 63 Q72 60 78 63"
        case .wary: return "M66 62.5 Q72 60.5 78 64"
        case .over: return "M66.5 64 Q71.5 61.5 77 62.5"
        }
    }

    /// Brow opacity — brows fade in as the day gets salty.
    var browOpacity: Double {
        switch self {
        case .fresh, .ok: return 0
        case .wary: return 0.9
        case .over: return 1
        }
    }

    var showsSweat: Bool { self == .wary || self == .over }
    var showsSparkles: Bool { self == .fresh }

    /// Speech-bubble line for the current day.
    var line: String {
        switch self {
        case .fresh: return "Fresh page — plenty of room today."
        case .ok: return "Nice pace. Steady shakes."
        case .wary: return "Careful — the shaker is getting warm."
        case .over: return "Over budget. Tomorrow is a clean slate — I kept notes."
        }
    }

    /// Speech line when viewing a past day instead of today.
    static func pastLine(empty: Bool, over: Bool) -> String {
        if empty { return "A quiet page in the log book." }
        if over { return "That day ran salty — all data, no judgment." }
        return "A good day on the books."
    }
}

/// Toast copy after logging, by the size of what was added.
enum ToastCopy {
    static func line(forAdded mg: Int) -> String {
        if mg >= 700 { return "Whew — a salty one. Pace the rest." }
        if mg >= 300 { return "Noted. Keeping count together." }
        return "Light touch. Nice pick."
    }
}
