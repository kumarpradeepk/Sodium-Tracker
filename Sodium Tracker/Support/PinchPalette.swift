//
//  PinchPalette.swift
//  Sodium Tracker
//
//  Design tokens from the Pinch design system (Pinch Sodium Tracker.dc.html).
//  Two fully specified palettes; every color in the app comes from here.
//

import SwiftUI

extension Color {
    /// Color from a 24-bit hex value, e.g. `Color(hex: 0x12867A)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// One theme's worth of Pinch color tokens.
struct PinchPalette: Equatable {
    let isDark: Bool

    let page: Color        // presentation background behind the app
    let bg: Color          // screen background
    let card: Color        // cards, sheets, segmented active pill
    let sunk: Color        // sunken surfaces: fields, segmented tracks, steppers
    let chip: Color        // icon tiles, small pills
    let dock: Color        // floating tab dock (over blur)
    let scrim: Color       // modal underlay
    let ink: Color         // primary text
    let ink2: Color        // secondary text
    let ink3: Color        // tertiary text / placeholders / inactive tabs
    let line: Color        // hairline borders and dividers
    let brand: Color       // primary teal
    let brandDeep: Color   // pressed brand / mascot cap band
    let brandSoft: Color   // brand tint fills
    let onBrand: Color     // text on brand
    let coral: Color       // over budget / ≥700 mg
    let coralSoft: Color
    let amber: Color       // warning zone / 300–699 mg
    let amberSoft: Color
    let shaker: Color      // mascot body
    let shakerLine: Color  // mascot outline
    let grain: Color       // ring track dots, dashes, grab handles
    let capHole: Color     // holes in the mascot's cap
    let pinchInk: Color    // mascot facial features (dark in both themes)
    let knob: Color        // switch knob

    static let light = PinchPalette(
        isDark: false,
        page: Color(hex: 0xEFE9DC),
        bg: Color(hex: 0xF7F3EA),
        card: Color(hex: 0xFFFFFF),
        sunk: Color(hex: 0xECE4D3),
        chip: Color(hex: 0xF1EBDD),
        dock: Color(hex: 0xFFFFFF, opacity: 0.86),
        scrim: Color(hex: 0x142825, opacity: 0.38),
        ink: Color(hex: 0x1B3431),
        ink2: Color(hex: 0x546965),
        ink3: Color(hex: 0x94A29D),
        line: Color(hex: 0x1B3431, opacity: 0.12),
        brand: Color(hex: 0x12867A),
        brandDeep: Color(hex: 0x0B6A5F),
        brandSoft: Color(hex: 0xDEEDE7),
        onBrand: Color(hex: 0xFFFFFF),
        coral: Color(hex: 0xE25A3A),
        coralSoft: Color(hex: 0xF8E3DB),
        amber: Color(hex: 0xC4880F),
        amberSoft: Color(hex: 0xF4E8CE),
        shaker: Color(hex: 0xFFFDF7),
        shakerLine: Color(hex: 0xE3DCCB),
        grain: Color(hex: 0xD8CFBB),
        capHole: Color(hex: 0x0A5A50),
        pinchInk: Color(hex: 0x1B3431),
        knob: Color(hex: 0xFFFFFF)
    )

    static let dark = PinchPalette(
        isDark: true,
        page: Color(hex: 0x081211),
        bg: Color(hex: 0x0C1917),
        card: Color(hex: 0x142523),
        sunk: Color(hex: 0x0E1C1A),
        chip: Color(hex: 0x172A27),
        dock: Color(red: 16 / 255, green: 30 / 255, blue: 28 / 255, opacity: 0.88),
        scrim: Color(hex: 0x000000, opacity: 0.55),
        ink: Color(hex: 0xF0EBE0),
        ink2: Color(hex: 0xA9B8B2),
        ink3: Color(hex: 0x6E807B),
        line: Color(hex: 0xF0EBE0, opacity: 0.10),
        brand: Color(hex: 0x38C9B7),
        brandDeep: Color(hex: 0x5CD9C9),
        brandSoft: Color(hex: 0x38C9B7, opacity: 0.13),
        onBrand: Color(hex: 0x04211D),
        coral: Color(hex: 0xFF7E5A),
        coralSoft: Color(hex: 0xFF7E5A, opacity: 0.14),
        amber: Color(hex: 0xEFB544),
        amberSoft: Color(hex: 0xEFB544, opacity: 0.12),
        shaker: Color(hex: 0xF2EDE2),
        shakerLine: Color(hex: 0xC9C2B0),
        grain: Color(hex: 0x2A4540),
        capHole: Color(hex: 0x0B4A42),
        pinchInk: Color(hex: 0x233B37),
        knob: Color(hex: 0xE9E4D8)
    )

    // MARK: - Sodium tone scale

    /// Tone color for a milligram amount: <300 brand, 300–699 amber, ≥700 coral.
    func tone(_ mg: Int) -> Color {
        if mg >= 700 { return coral }
        if mg >= 300 { return amber }
        return brand
    }

    /// Ring color by percent of daily goal consumed: <78 brand, 78–99 amber, ≥100 coral.
    func ringColor(pct: Double) -> Color {
        if pct >= 100 { return coral }
        if pct >= 78 { return amber }
        return brand
    }

    /// Drop-shadow glow that matches the ring color.
    func ringGlow(pct: Double) -> Color {
        if pct >= 100 { return coral.opacity(0.42) }
        if pct >= 78 { return amber.opacity(0.35) }
        return brand.opacity(0.35)
    }

    /// Color for the "remaining" figures: over → coral, near limit → amber, else brand.
    func remainColor(remain: Int, pct: Double) -> Color {
        if remain < 0 { return coral }
        if pct >= 78 { return amber }
        return brand
    }

    // MARK: - Shadows (CSS blur ≈ 2 × SwiftUI radius)

    var cardShadow1: (color: Color, radius: CGFloat, y: CGFloat) {
        isDark ? (Color.black.opacity(0.35), 2, 2) : (Color(hex: 0x1B3431, opacity: 0.05), 1, 1)
    }
    var cardShadow2: (color: Color, radius: CGFloat, y: CGFloat) {
        isDark ? (Color.black.opacity(0.5), 22, 18) : (Color(hex: 0x1B3431, opacity: 0.10), 17, 14)
    }
    var segShadow: (color: Color, radius: CGFloat, y: CGFloat) {
        isDark ? (Color.black.opacity(0.5), 1.5, 1) : (Color(hex: 0x1B3431, opacity: 0.14), 1.5, 1)
    }
}

// MARK: - Environment plumbing

private struct PinchPaletteKey: EnvironmentKey {
    static let defaultValue = PinchPalette.light
}

extension EnvironmentValues {
    var pinch: PinchPalette {
        get { self[PinchPaletteKey.self] }
        set { self[PinchPaletteKey.self] = newValue }
    }
}

extension View {
    /// The design's two-layer card shadow.
    func pinchCardShadow(_ p: PinchPalette) -> some View {
        let s1 = p.cardShadow1
        let s2 = p.cardShadow2
        return self
            .shadow(color: s1.color, radius: s1.radius, x: 0, y: s1.y)
            .shadow(color: s2.color, radius: s2.radius, x: 0, y: s2.y)
    }

    /// The design's small-element shadow (segmented pills, chips).
    func pinchSegShadow(_ p: PinchPalette) -> some View {
        let s = p.segShadow
        return self.shadow(color: s.color, radius: s.radius, x: 0, y: s.y)
    }
}
