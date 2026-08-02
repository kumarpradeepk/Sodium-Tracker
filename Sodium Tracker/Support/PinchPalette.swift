//
//  PinchPalette.swift
//  Sodium Tracker
//
//  Design tokens from the Pinch design system v2 (Pinch Sodium Tracker v2.dc.html).
//  Three palette families — Ocean (default), Sage, Iris — each fully specified
//  for light and dark. Every color in the app comes from here.
//

import SwiftUI

extension Color {
    /// Color from a 24-bit hex value, e.g. `Color(hex: 0x1668A8)`.
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

/// Which palette family the app wears. Persisted in AppStorage("palette").
enum PalettePick: String, CaseIterable, Identifiable {
    case ocean, sage, iris

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ocean: return "Ocean"
        case .sage: return "Sage"
        case .iris: return "Iris"
        }
    }
}

/// Top→bottom gradient pair for the trends bars.
struct BarFill: Equatable {
    let top: Color
    let bottom: Color

    var gradient: LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
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
    let brand: Color       // primary accent
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

    // v2: gradient fills for the trends bars
    let barNow: BarFill
    let barNowOver: BarFill
    let barUnder: BarFill
    let barOver: BarFill

    // v2: scanner accents (scanner chrome itself stays fixed dark)
    let scanAcc: Color
    let scanAccGlow: Color
    let scanAccSoft: Color
    let scanInk: Color

    // v2: ring glows, fixed per palette family (same in light and dark)
    let glowBrand: Color
    let glowAmber: Color
    let glowCoral: Color

    /// Hue that light-mode shadows are tinted with (dark mode uses black).
    let shadowTint: Color

    // MARK: - Resolution

    static func resolve(_ pick: PalettePick, dark: Bool) -> PinchPalette {
        switch (pick, dark) {
        case (.ocean, false): return oceanLight
        case (.ocean, true): return oceanDark
        case (.sage, false): return sageLight
        case (.sage, true): return sageDark
        case (.iris, false): return irisLight
        case (.iris, true): return irisDark
        }
    }

    /// Default look: Ocean light.
    static let fallback = oceanLight

    // MARK: - Ocean

    static let oceanLight = PinchPalette(
        isDark: false,
        page: Color(hex: 0xEDF0F3),
        bg: Color(hex: 0xF6F8F9),
        card: Color(hex: 0xFFFFFF),
        sunk: Color(hex: 0xE7EBEE),
        chip: Color(hex: 0xEFF2F4),
        dock: Color(hex: 0xFFFFFF, opacity: 0.88),
        scrim: Color(hex: 0x0F1A22, opacity: 0.42),
        ink: Color(hex: 0x0F1E26),
        ink2: Color(hex: 0x4E6270),
        ink3: Color(hex: 0x8FA1AC),
        line: Color(hex: 0x0F1E26, opacity: 0.11),
        brand: Color(hex: 0x1668A8),
        brandDeep: Color(hex: 0x0F5288),
        brandSoft: Color(hex: 0xE1EDF6),
        onBrand: Color(hex: 0xF7FBFE),
        coral: Color(hex: 0xD96545),
        coralSoft: Color(hex: 0xF8E6DE),
        amber: Color(hex: 0xC08A1E),
        amberSoft: Color(hex: 0xF5EBD3),
        shaker: Color(hex: 0xFDFDFB),
        shakerLine: Color(hex: 0xDFE4E4),
        grain: Color(hex: 0xCFD8DC),
        capHole: Color(hex: 0x0C3A5C),
        pinchInk: Color(hex: 0x14242E),
        knob: Color(hex: 0xFFFFFF),
        barNow: BarFill(top: Color(hex: 0x3D8FC9), bottom: Color(hex: 0x1668A8)),
        barNowOver: BarFill(top: Color(hex: 0xE67C52), bottom: Color(hex: 0xD96545)),
        barUnder: BarFill(top: Color(hex: 0xA6C8E0), bottom: Color(hex: 0x7FAFD2)),
        barOver: BarFill(top: Color(hex: 0xEFB39B), bottom: Color(hex: 0xE28E68)),
        scanAcc: Color(hex: 0x5CB3E8),
        scanAccGlow: Color(hex: 0x5CB3E8, opacity: 0.7),
        scanAccSoft: Color(hex: 0x5CB3E8, opacity: 0.15),
        scanInk: Color(hex: 0x04121C),
        glowBrand: Color(hex: 0x1668A8, opacity: 0.35),
        glowAmber: Color(hex: 0xC08A1E, opacity: 0.35),
        glowCoral: Color(hex: 0xD96545, opacity: 0.42),
        shadowTint: Color(hex: 0x0F1E26)
    )

    static let oceanDark = PinchPalette(
        isDark: true,
        page: Color(hex: 0x05090D),
        bg: Color(hex: 0x0A1118),
        card: Color(hex: 0x131C25),
        sunk: Color(hex: 0x0D141B),
        chip: Color(hex: 0x16212B),
        dock: Color(hex: 0x0F171F, opacity: 0.88),
        scrim: Color(hex: 0x000000, opacity: 0.58),
        ink: Color(hex: 0xEAF0F4),
        ink2: Color(hex: 0xA2B3BF),
        ink3: Color(hex: 0x677985),
        line: Color(hex: 0xEAF0F4, opacity: 0.10),
        brand: Color(hex: 0x5CB3E8),
        brandDeep: Color(hex: 0x83C7F0),
        brandSoft: Color(hex: 0x5CB3E8, opacity: 0.13),
        onBrand: Color(hex: 0x04121C),
        coral: Color(hex: 0xFF8B64),
        coralSoft: Color(hex: 0xFF8B64, opacity: 0.14),
        amber: Color(hex: 0xE8B44C),
        amberSoft: Color(hex: 0xE8B44C, opacity: 0.12),
        shaker: Color(hex: 0xE9EDEF),
        shakerLine: Color(hex: 0xC2CBD1),
        grain: Color(hex: 0x24333F),
        capHole: Color(hex: 0x17537F),
        pinchInk: Color(hex: 0x1A2A34),
        knob: Color(hex: 0xE6ECF0),
        barNow: BarFill(top: Color(hex: 0x79C6F2), bottom: Color(hex: 0x4AA3DC)),
        barNowOver: BarFill(top: Color(hex: 0xFFA47F), bottom: Color(hex: 0xF27B52)),
        barUnder: BarFill(top: Color(hex: 0x28455C), bottom: Color(hex: 0x1F3749)),
        barOver: BarFill(top: Color(hex: 0x8A4C38), bottom: Color(hex: 0x6F3A29)),
        scanAcc: Color(hex: 0x5CB3E8),
        scanAccGlow: Color(hex: 0x5CB3E8, opacity: 0.7),
        scanAccSoft: Color(hex: 0x5CB3E8, opacity: 0.15),
        scanInk: Color(hex: 0x04121C),
        glowBrand: Color(hex: 0x1668A8, opacity: 0.35),
        glowAmber: Color(hex: 0xC08A1E, opacity: 0.35),
        glowCoral: Color(hex: 0xD96545, opacity: 0.42),
        shadowTint: Color(hex: 0x000000)
    )

    // MARK: - Sage

    static let sageLight = PinchPalette(
        isDark: false,
        page: Color(hex: 0xEDEFE8),
        bg: Color(hex: 0xF6F7F2),
        card: Color(hex: 0xFFFFFF),
        sunk: Color(hex: 0xE7EAE0),
        chip: Color(hex: 0xEFF1EA),
        dock: Color(hex: 0xFFFFFF, opacity: 0.88),
        scrim: Color(hex: 0x121C16, opacity: 0.42),
        ink: Color(hex: 0x16211A),
        ink2: Color(hex: 0x526057),
        ink3: Color(hex: 0x909D94),
        line: Color(hex: 0x16211A, opacity: 0.11),
        brand: Color(hex: 0x35705A),
        brandDeep: Color(hex: 0x285944),
        brandSoft: Color(hex: 0xE2EDE5),
        onBrand: Color(hex: 0xF6FBF7),
        coral: Color(hex: 0xC4643F),
        coralSoft: Color(hex: 0xF6E4DA),
        amber: Color(hex: 0xAD852A),
        amberSoft: Color(hex: 0xF2ECD6),
        shaker: Color(hex: 0xFCFCF9),
        shakerLine: Color(hex: 0xDFE3DB),
        grain: Color(hex: 0xCBD3C9),
        capHole: Color(hex: 0x1B4534),
        pinchInk: Color(hex: 0x16211A),
        knob: Color(hex: 0xFFFFFF),
        barNow: BarFill(top: Color(hex: 0x5C977E), bottom: Color(hex: 0x35705A)),
        barNowOver: BarFill(top: Color(hex: 0xD77E52), bottom: Color(hex: 0xC4643F)),
        barUnder: BarFill(top: Color(hex: 0xB3CDBB), bottom: Color(hex: 0x8CB49A)),
        barOver: BarFill(top: Color(hex: 0xE8B49A), bottom: Color(hex: 0xD9926B)),
        scanAcc: Color(hex: 0x8CC3A6),
        scanAccGlow: Color(hex: 0x8CC3A6, opacity: 0.7),
        scanAccSoft: Color(hex: 0x8CC3A6, opacity: 0.15),
        scanInk: Color(hex: 0x0A1D14),
        glowBrand: Color(hex: 0x35705A, opacity: 0.35),
        glowAmber: Color(hex: 0xAD852A, opacity: 0.35),
        glowCoral: Color(hex: 0xC4643F, opacity: 0.42),
        shadowTint: Color(hex: 0x16211A)
    )

    static let sageDark = PinchPalette(
        isDark: true,
        page: Color(hex: 0x060907),
        bg: Color(hex: 0x0B100D),
        card: Color(hex: 0x141A16),
        sunk: Color(hex: 0x0E1410),
        chip: Color(hex: 0x171E19),
        dock: Color(hex: 0x111814, opacity: 0.88),
        scrim: Color(hex: 0x000000, opacity: 0.58),
        ink: Color(hex: 0xECF1EC),
        ink2: Color(hex: 0xA7B4AA),
        ink3: Color(hex: 0x6C7A70),
        line: Color(hex: 0xECF1EC, opacity: 0.10),
        brand: Color(hex: 0x8CC3A6),
        brandDeep: Color(hex: 0xA8D4BC),
        brandSoft: Color(hex: 0x8CC3A6, opacity: 0.13),
        onBrand: Color(hex: 0x0A1D14),
        coral: Color(hex: 0xF2925F),
        coralSoft: Color(hex: 0xF2925F, opacity: 0.14),
        amber: Color(hex: 0xDDB258),
        amberSoft: Color(hex: 0xDDB258, opacity: 0.12),
        shaker: Color(hex: 0xE9EDE8),
        shakerLine: Color(hex: 0xC3CBC2),
        grain: Color(hex: 0x273229),
        capHole: Color(hex: 0x35604A),
        pinchInk: Color(hex: 0x1A241D),
        knob: Color(hex: 0xE7ECE7),
        barNow: BarFill(top: Color(hex: 0xA5D4BB), bottom: Color(hex: 0x7BB799)),
        barNowOver: BarFill(top: Color(hex: 0xFFA878), bottom: Color(hex: 0xE8814F)),
        barUnder: BarFill(top: Color(hex: 0x33473A), bottom: Color(hex: 0x28382E)),
        barOver: BarFill(top: Color(hex: 0x7E4A32), bottom: Color(hex: 0x653823)),
        scanAcc: Color(hex: 0x8CC3A6),
        scanAccGlow: Color(hex: 0x8CC3A6, opacity: 0.7),
        scanAccSoft: Color(hex: 0x8CC3A6, opacity: 0.15),
        scanInk: Color(hex: 0x0A1D14),
        glowBrand: Color(hex: 0x35705A, opacity: 0.35),
        glowAmber: Color(hex: 0xAD852A, opacity: 0.35),
        glowCoral: Color(hex: 0xC4643F, opacity: 0.42),
        shadowTint: Color(hex: 0x000000)
    )

    // MARK: - Iris

    static let irisLight = PinchPalette(
        isDark: false,
        page: Color(hex: 0xEFEEF4),
        bg: Color(hex: 0xF7F6FA),
        card: Color(hex: 0xFFFFFF),
        sunk: Color(hex: 0xE9E7F0),
        chip: Color(hex: 0xF1F0F6),
        dock: Color(hex: 0xFFFFFF, opacity: 0.88),
        scrim: Color(hex: 0x181628, opacity: 0.42),
        ink: Color(hex: 0x1B1A2B),
        ink2: Color(hex: 0x565471),
        ink3: Color(hex: 0x9795A8),
        line: Color(hex: 0x1B1A2B, opacity: 0.11),
        brand: Color(hex: 0x5A52C4),
        brandDeep: Color(hex: 0x4740A4),
        brandSoft: Color(hex: 0xE7E5F8),
        onBrand: Color(hex: 0xF9F8FE),
        coral: Color(hex: 0xC95877),
        coralSoft: Color(hex: 0xF7E1E7),
        amber: Color(hex: 0xB98A1E),
        amberSoft: Color(hex: 0xF4EAD1),
        shaker: Color(hex: 0xFDFCFC),
        shakerLine: Color(hex: 0xE2E0E8),
        grain: Color(hex: 0xCFCCDC),
        capHole: Color(hex: 0x322C7A),
        pinchInk: Color(hex: 0x1E1C30),
        knob: Color(hex: 0xFFFFFF),
        barNow: BarFill(top: Color(hex: 0x7B74D8), bottom: Color(hex: 0x5A52C4)),
        barNowOver: BarFill(top: Color(hex: 0xDA7A93), bottom: Color(hex: 0xC95877)),
        barUnder: BarFill(top: Color(hex: 0xBEBAE8), bottom: Color(hex: 0x9C96DC)),
        barOver: BarFill(top: Color(hex: 0xEAB3C2), bottom: Color(hex: 0xDB8FA4)),
        scanAcc: Color(hex: 0xA29BEE),
        scanAccGlow: Color(hex: 0xA29BEE, opacity: 0.7),
        scanAccSoft: Color(hex: 0xA29BEE, opacity: 0.15),
        scanInk: Color(hex: 0x14113A),
        glowBrand: Color(hex: 0x5A52C4, opacity: 0.35),
        glowAmber: Color(hex: 0xB98A1E, opacity: 0.35),
        glowCoral: Color(hex: 0xC95877, opacity: 0.42),
        shadowTint: Color(hex: 0x1B1A2B)
    )

    static let irisDark = PinchPalette(
        isDark: true,
        page: Color(hex: 0x070610),
        bg: Color(hex: 0x0C0B16),
        card: Color(hex: 0x16151F),
        sunk: Color(hex: 0x100F1A),
        chip: Color(hex: 0x191824),
        dock: Color(hex: 0x14131E, opacity: 0.88),
        scrim: Color(hex: 0x000000, opacity: 0.6),
        ink: Color(hex: 0xEDECF4),
        ink2: Color(hex: 0xA9A7BC),
        ink3: Color(hex: 0x6E6C82),
        line: Color(hex: 0xEDECF4, opacity: 0.10),
        brand: Color(hex: 0xA29BEE),
        brandDeep: Color(hex: 0xBCB6F4),
        brandSoft: Color(hex: 0xA29BEE, opacity: 0.13),
        onBrand: Color(hex: 0x14113A),
        coral: Color(hex: 0xF585A3),
        coralSoft: Color(hex: 0xF585A3, opacity: 0.14),
        amber: Color(hex: 0xE3B75C),
        amberSoft: Color(hex: 0xE3B75C, opacity: 0.12),
        shaker: Color(hex: 0xEBEAEF),
        shakerLine: Color(hex: 0xC6C4CE),
        grain: Color(hex: 0x2A2838),
        capHole: Color(hex: 0x4A4390),
        pinchInk: Color(hex: 0x201E32),
        knob: Color(hex: 0xE9E8EF),
        barNow: BarFill(top: Color(hex: 0xB7B1F2), bottom: Color(hex: 0x8F88E4)),
        barNowOver: BarFill(top: Color(hex: 0xFF9DB6), bottom: Color(hex: 0xEE7495)),
        barUnder: BarFill(top: Color(hex: 0x3B3854), bottom: Color(hex: 0x2E2B42)),
        barOver: BarFill(top: Color(hex: 0x7C3F51), bottom: Color(hex: 0x622F3F)),
        scanAcc: Color(hex: 0xA29BEE),
        scanAccGlow: Color(hex: 0xA29BEE, opacity: 0.7),
        scanAccSoft: Color(hex: 0xA29BEE, opacity: 0.15),
        scanInk: Color(hex: 0x14113A),
        glowBrand: Color(hex: 0x5A52C4, opacity: 0.35),
        glowAmber: Color(hex: 0xB98A1E, opacity: 0.35),
        glowCoral: Color(hex: 0xC95877, opacity: 0.42),
        shadowTint: Color(hex: 0x000000)
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

    /// Drop-shadow glow that matches the ring zone (fixed per palette family).
    func ringGlow(pct: Double) -> Color {
        if pct >= 100 { return glowCoral }
        if pct >= 78 { return glowAmber }
        return glowBrand
    }

    /// Color for the "remaining" figures: over → coral, near limit → amber, else brand.
    func remainColor(remain: Int, pct: Double) -> Color {
        if remain < 0 { return coral }
        if pct >= 78 { return amber }
        return brand
    }

    /// Trends bar fill by state.
    func barFill(over: Bool, live: Bool) -> BarFill {
        if live { return over ? barNowOver : barNow }
        return over ? barOver : barUnder
    }

    // MARK: - Shadows (CSS blur ≈ 2 × SwiftUI radius)

    var cardShadow1: (color: Color, radius: CGFloat, y: CGFloat) {
        isDark ? (Color.black.opacity(0.35), 2, 2) : (shadowTint.opacity(0.05), 1, 1)
    }
    var cardShadow2: (color: Color, radius: CGFloat, y: CGFloat) {
        isDark ? (Color.black.opacity(0.5), 22, 18) : (shadowTint.opacity(0.10), 17, 14)
    }
    var segShadow: (color: Color, radius: CGFloat, y: CGFloat) {
        isDark ? (Color.black.opacity(0.5), 1.5, 1) : (shadowTint.opacity(0.14), 1.5, 1)
    }
}

// MARK: - Environment plumbing

private struct PinchPaletteKey: EnvironmentKey {
    static let defaultValue = PinchPalette.fallback
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
