//
//  SaltyTokens.swift
//  Sodium Tracker
//
//  The Salty dashboard's own token set, verbatim from the design prototype
//  (`Salty Dashboard - standalone.html`). The `salty` palette resolves to the
//  design's exact hexes; every other palette maps its own roles onto the same
//  slots so the screen stays themeable.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §4
//

import SwiftUI

/// Colors the Salty screen, tab bar and quick-add sheet draw from.
struct SaltyTokens: Equatable {
    let isDark: Bool

    // Surfaces
    let screenBg: Color
    let card: Color
    let disc: Color            // ring inner disc
    let track: Color           // dotted ring track

    // Ink
    let ink: Color             // titles, numbers, icons, mascot features
    let inkBody: Color         // bubble copy
    let ink2: Color            // card captions
    let ink3: Color            // section kickers
    let inkFaint: Color        // "vs. N mg left"
    let inkCenterSub: Color    // "of 1,500 mg"
    let dottedUnderline: Color

    // Blue family
    let blue: Color
    let blueSoft: Color        // chip "+" disc
    let fitsBg: Color          // FITS badge fill

    // Amber family
    let amberArc: Color
    let amberText: Color
    let amberBadge: Color
    let amberStreak: Color
    let amberSoft: Color
    let star: Color

    // Accents
    let sparkle2: Color
    let alertRed: Color
    let mascotBody: Color
    let mascotStroke: Color
    /// Facial features. Fixed dark in BOTH themes — the mascot body stays white,
    /// so following the theme ink would erase the face in dark mode.
    let mascotInk: Color
    let blush: Color
    let sweat: Color
    let capHole: Color

    // Chrome
    let tabInactive: Color
    let tabBarBg: Color
    let tabBarLine: Color
    let scrim: Color
    let shadowTint: Color

    /// Sparkle burst palette, cycled by index.
    var sparkleColors: [Color] { [star, sparkle2, blue] }

    // MARK: - Resolution

    static func resolve(_ pick: PalettePick, dark: Bool) -> SaltyTokens {
        switch (pick, dark) {
        case (.salty, false): return saltyLight
        case (.salty, true): return saltyDark
        default: return mapped(from: PinchPalette.resolve(pick, dark: dark))
        }
    }

    /// Design default — every value verbatim from the prototype.
    static let saltyLight = SaltyTokens(
        isDark: false,
        screenBg: Color(hex: 0xEDF1F6),
        card: Color(hex: 0xFFFFFF),
        disc: Color(hex: 0xDFE8F3),
        track: Color(hex: 0xC7D3E3),
        ink: Color(hex: 0x1F3A5C),
        inkBody: Color(hex: 0x33465F),
        ink2: Color(hex: 0x5B6B82),
        ink3: Color(hex: 0x7C8AA0),
        inkFaint: Color(hex: 0xA6B0C0),
        inkCenterSub: Color(hex: 0x8B96A8),
        dottedUnderline: Color(hex: 0xB9C3D2),
        blue: Color(hex: 0x2E6FBD),
        blueSoft: Color(hex: 0xE3ECF7),
        fitsBg: Color(hex: 0xE1EDF9),
        amberArc: Color(hex: 0xDFA32B),
        amberText: Color(hex: 0xC4841D),
        amberBadge: Color(hex: 0xB0821F),
        amberStreak: Color(hex: 0xA8761C),
        amberSoft: Color(hex: 0xF5E4C0),
        star: Color(hex: 0xD9A126),
        sparkle2: Color(hex: 0xE8B84B),
        alertRed: Color(hex: 0xE5484D),
        mascotBody: Color(hex: 0xFFFFFF),
        mascotStroke: Color(hex: 0xE3E9F2),
        mascotInk: Color(hex: 0x1F3A5C),
        blush: Color(hex: 0xF2A9B8),
        sweat: Color(hex: 0x6FA8E0),
        capHole: Color(hex: 0xEDF1F6),
        tabInactive: Color(hex: 0x93A1B5),
        tabBarBg: Color(hex: 0xFAFBFD, opacity: 0.90),
        tabBarLine: Color(hex: 0x1F3A5C, opacity: 0.05),
        scrim: Color(hex: 0x1F3A5C, opacity: 0.16),
        shadowTint: Color(hex: 0x1F3A5C)
    )

    /// Dark extension of the design (spec §4.2). The mascot keeps its identity
    /// colors in both themes — only the cap holes follow the card surface.
    static let saltyDark = SaltyTokens(
        isDark: true,
        screenBg: Color(hex: 0x0C1420),
        card: Color(hex: 0x16202E),
        disc: Color(hex: 0x17263A),
        track: Color(hex: 0x2C3D53),
        ink: Color(hex: 0xE8EEF6),
        inkBody: Color(hex: 0xC7D3E2),
        ink2: Color(hex: 0xA9B7C9),
        ink3: Color(hex: 0x8595AB),
        inkFaint: Color(hex: 0x5E7089),
        inkCenterSub: Color(hex: 0x8CA0B8),
        dottedUnderline: Color(hex: 0x3C4E66),
        blue: Color(hex: 0x5C9BE0),
        blueSoft: Color(hex: 0x1B3450),
        fitsBg: Color(hex: 0x173250),
        amberArc: Color(hex: 0xDFA32B),
        amberText: Color(hex: 0xE3B54E),
        amberBadge: Color(hex: 0xE3B54E),
        amberStreak: Color(hex: 0xE0B04A),
        amberSoft: Color(hex: 0x3A2F14),
        star: Color(hex: 0xD9A126),
        sparkle2: Color(hex: 0xE8B84B),
        alertRed: Color(hex: 0xE5484D),
        mascotBody: Color(hex: 0xFFFFFF),
        mascotStroke: Color(hex: 0xE3E9F2),
        mascotInk: Color(hex: 0x1F3A5C),
        blush: Color(hex: 0xF2A9B8),
        sweat: Color(hex: 0x6FA8E0),
        capHole: Color(hex: 0x16202E),
        tabInactive: Color(hex: 0x5E7089),
        tabBarBg: Color(hex: 0x101824, opacity: 0.90),
        tabBarLine: Color(hex: 0xFFFFFF, opacity: 0.06),
        scrim: Color(hex: 0x000000, opacity: 0.45),
        shadowTint: Color(hex: 0x000000)
    )

    /// Role mapping so ocean / sage / iris keep working on the Salty screen.
    static func mapped(from p: PinchPalette) -> SaltyTokens {
        SaltyTokens(
            isDark: p.isDark,
            screenBg: p.bg,
            card: p.card,
            disc: p.chip,
            track: p.grain,
            ink: p.ink,
            inkBody: p.ink2,
            ink2: p.ink2,
            ink3: p.ink3,
            inkFaint: p.ink3,
            inkCenterSub: p.ink2,
            dottedUnderline: p.grain,
            blue: p.brand,
            blueSoft: p.brandSoft,
            fitsBg: p.brandSoft,
            amberArc: p.amber,
            amberText: p.amber,
            amberBadge: p.amber,
            amberStreak: p.amber,
            amberSoft: p.amberSoft,
            star: p.amber,
            sparkle2: p.amber,
            alertRed: p.coral,
            mascotBody: p.shaker,
            mascotStroke: p.shakerLine,
            mascotInk: p.pinchInk,
            blush: Color(hex: 0xF2A9B8),
            sweat: Color(hex: 0x6FA8E0),
            capHole: p.capHole,
            tabInactive: p.ink3,
            tabBarBg: p.dock,
            tabBarLine: p.line,
            scrim: p.scrim,
            shadowTint: p.shadowTint
        )
    }
}

// MARK: - Shadows (spec §4.1)

extension View {
    /// 0 2 10 rgba(31,58,92,0.05) — chips, stat cards.
    func saltyCardShadow(_ s: SaltyTokens) -> some View {
        shadow(color: s.shadowTint.opacity(s.isDark ? 0.35 : 0.05), radius: 5, y: 2)
    }

    /// 0 4 16 rgba(31,58,92,0.05) — speech bubble.
    func saltyBubbleShadow(_ s: SaltyTokens) -> some View {
        shadow(color: s.shadowTint.opacity(s.isDark ? 0.35 : 0.05), radius: 8, y: 4)
    }

    /// 0 2 8 rgba(31,58,92,0.06) — bell button.
    func saltyBellShadow(_ s: SaltyTokens) -> some View {
        shadow(color: s.shadowTint.opacity(s.isDark ? 0.35 : 0.06), radius: 4, y: 2)
    }

    /// 0 6 22 rgba(31,58,92,0.14) — quick-add rows.
    func saltySheetShadow(_ s: SaltyTokens) -> some View {
        shadow(color: s.shadowTint.opacity(s.isDark ? 0.45 : 0.14), radius: 11, y: 6)
    }
}

// MARK: - Type (spec §4.4)

extension View {
    /// The design's system stack at an exact size/weight, with em tracking.
    func salty(_ size: CGFloat, _ weight: Font.Weight, tracking em: CGFloat = 0) -> some View {
        font(.system(size: size, weight: weight))
            .tracking(em == 0 ? 0 : size * em)
    }

    /// Same, with tabular figures — required on every number (spec §4.4).
    func saltyNum(_ size: CGFloat, _ weight: Font.Weight, tracking em: CGFloat = 0) -> some View {
        font(.system(size: size, weight: weight))
            .monospacedDigit()
            .tracking(em == 0 ? 0 : size * em)
    }
}

// MARK: - Environment

private struct SaltyTokensKey: EnvironmentKey {
    static let defaultValue = SaltyTokens.saltyLight
}

extension EnvironmentValues {
    var salty: SaltyTokens {
        get { self[SaltyTokensKey.self] }
        set { self[SaltyTokensKey.self] = newValue }
    }
}
