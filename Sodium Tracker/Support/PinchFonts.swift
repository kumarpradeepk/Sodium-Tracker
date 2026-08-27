//
//  PinchFonts.swift
//  Sodium Tracker
//
//  The current Salty design uses the native Apple system stack (SF Pro on
//  iOS), which keeps text crisp, Dynamic Type friendly, and consistent with
//  system sheets and controls.
//

import SwiftUI
import CoreText

enum PinchFonts {
    static let displayFamily = "Bricolage Grotesque"
    static let bodyFamily = "Instrument Sans"

    private static var registered = false
    private static var displayAvailable = false
    private static var bodyAvailable = false

    /// Registers the bundled fonts with Core Text. Safe to call repeatedly.
    static func register() {
        guard !registered else { return }
        registered = true

        for name in ["BricolageGrotesque", "InstrumentSans"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        displayAvailable = UIFont(name: displayFamily, size: 12) != nil
            || UIFont.familyNames.contains(displayFamily)
        bodyAvailable = UIFont(name: bodyFamily, size: 12) != nil
            || UIFont.familyNames.contains(bodyFamily)
    }

    /// Display face — screen titles, big numbers.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Body face — everything else.
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

extension View {
    /// Bricolage Grotesque with em-based tracking (CSS letter-spacing).
    func pinchDisplay(_ size: CGFloat, _ weight: Font.Weight = .bold, tracking em: CGFloat = -0.02) -> some View {
        font(PinchFonts.display(size, weight)).tracking(size * em)
    }

    /// Instrument Sans with optional em-based tracking.
    func pinchBody(_ size: CGFloat, _ weight: Font.Weight = .regular, tracking em: CGFloat = 0) -> some View {
        font(PinchFonts.body(size, weight)).tracking(em == 0 ? 0 : size * em)
    }

    /// Eyebrow/kicker style: 11px 700, letter-spacing .13em, uppercase is the caller's job.
    func pinchKicker(_ size: CGFloat = 11, tracking em: CGFloat = 0.13) -> some View {
        font(PinchFonts.body(size, .bold)).tracking(size * em)
    }
}
