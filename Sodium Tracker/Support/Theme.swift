//
//  Theme.swift
//  Sodium Tracker
//

import SwiftUI

/// Brand colors. Chosen to read clearly in both light and dark appearance.
enum Theme {
    /// Primary brand color — a salt-water teal.
    static let brand = Color(red: 0.11, green: 0.53, blue: 0.60)
    static let brandDeep = Color(red: 0.04, green: 0.34, blue: 0.44)

    static let good = Color(red: 0.15, green: 0.66, blue: 0.51)
    static let caution = Color(red: 0.93, green: 0.62, blue: 0.16)
    static let over = Color(red: 0.87, green: 0.31, blue: 0.31)

    /// Track color for rings and bars.
    static let track = Color.primary.opacity(0.09)
}
