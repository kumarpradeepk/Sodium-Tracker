//
//  PinchMascot.swift
//  Sodium Tracker
//
//  Pinch, the salt-shaker mascot. All geometry comes from the design's SVG
//  (viewBox 120×130): teal cap with three holes, cream body, dot eyes, blush,
//  mood-driven mouth/brows, sparkles when the day is fresh, a sweat drop when
//  it runs salty. Bobs gently; blinks about every 4.6 s.
//

import SwiftUI

// MARK: - Shared path data

private enum MascotArt {
    static let viewBox = CGSize(width: 120, height: 130)

    static let cap = "M39 31 C39 15 47 8 60 8 C73 8 81 15 81 31 L81 36 L39 36 Z"
    static let body = "M35 50 C35 45 42 43 60 43 C78 43 85 45 85 50 L87.5 95 C88.5 111 76 121 60 121 C44 121 32.5 111 32.5 95 Z"
    static let sweat = "M93 56 C93 56 98 62 98 66 C98 68.8 95.8 71 93 71 C90.2 71 88 68.8 88 66 C88 62 93 56 93 56 Z"
    static let sparkleAmber = "M22 30 L24.4 36.6 L31 39 L24.4 41.4 L22 48 L19.6 41.4 L13 39 L19.6 36.6 Z"
    static let sparkleBrand = "M99 14 L100.8 19 L105.8 20.8 L100.8 22.6 L99 27.6 L97.2 22.6 L92.2 20.8 L97.2 19 Z"
    // "All set" celebration extras
    static let sparkleBigAmber = "M18 22 L20.8 29 L28 31.5 L20.8 34 L18 41 L15.2 34 L8 31.5 L15.2 29 Z"
    static let sparkleSmallBrand = "M103 10 L105 15.5 L110.5 17.5 L105 19.5 L103 25 L101 19.5 L95.5 17.5 L101 15.5 Z"
    static let sparkleCoral = "M100 44 L101.6 48.4 L106 50 L101.6 51.6 L100 56 L98.4 51.6 L94 50 L98.4 48.4 Z"
    static let happyEyeLeft = "M44 71 Q48 67 52 71"
    static let happyEyeRight = "M68 71 Q72 67 76 71"
    static let happySmile = "M50 84 Q60 97 70 84"
    static let okSmile = "M50 85.5 Q60 96.5 70 85.5"
    // Party-hat variant (paywall) uses a lowered cap
    static let partyHat = "M44 13 L51 3 L60 12 L69 3 L76 13 Z"
    static let capLow = "M39 34 C39 21 47 15 60 15 C73 15 81 21 81 34 L81 38 L39 38 Z"
    static let bodyLow = "M35 52 C35 47 42 45 60 45 C78 45 85 47 85 52 L87.5 96 C88.5 112 76 122 60 122 C44 122 31.5 112 32.5 96 Z"
    static let smileLow = "M50 87.5 Q60 98.5 70 87.5"
}

// MARK: - Animation values

private struct BobValue {
    var y: CGFloat = 0
}

private struct TwinkleValue {
    var opacity: Double = 0.2
    var scale: CGFloat = 0.75
}

private struct BlinkValue {
    var scaleY: CGFloat = 1
}

private struct DripValue {
    var y: CGFloat = -3
    var opacity: Double = 0
}

// MARK: - Mascot

/// The full mascot. `width` fixes the size; height follows the 120:130 ratio.
struct PinchMascot: View {
    enum Variant {
        case hero(Mood)     // Today screen — full mood engine
        case welcome        // onboarding welcome — smiling, sparkles
        case allSet         // onboarding finale — closed happy eyes, 3 sparkles
        case party          // paywall — party hat
        case toastMini      // toast avatar — static smile
    }

    @Environment(\.pinch) private var p
    let variant: Variant
    var width: CGFloat = 104

    private var height: CGFloat { width * MascotArt.viewBox.height / MascotArt.viewBox.width }
    private var s: CGFloat { width / MascotArt.viewBox.width }

    private var animated: Bool {
        if case .toastMini = variant { return false }
        return true
    }

    var body: some View {
        Group {
            if animated {
                KeyframeAnimator(initialValue: BobValue(), repeating: true) { value in
                    core.offset(y: value.y)
                } keyframes: { _ in
                    KeyframeTrack(\.y) {
                        CubicKeyframe(-4 * s, duration: 1.7)
                        CubicKeyframe(0, duration: 1.7)
                    }
                }
            } else {
                core
            }
        }
        .frame(width: width, height: height)
    }

    // MARK: composition

    private var core: some View {
        ZStack {
            sparkles
            capAndBody
            face
            sweatDrop
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder private var sparkles: some View {
        switch variant {
        case .hero(let mood):
            if mood.showsSparkles {
                twinkle(MascotArt.sparkleAmber, color: p.amber, duration: 2.6, delay: 0.01)
                twinkle(MascotArt.sparkleBrand, color: p.brand, duration: 3.1, delay: 0.6)
            }
        case .welcome:
            twinkle(MascotArt.sparkleAmber, color: p.amber, duration: 2.6, delay: 0.01)
            twinkle(MascotArt.sparkleBrand, color: p.brand, duration: 3.1, delay: 0.6)
        case .allSet:
            twinkle(MascotArt.sparkleBigAmber, color: p.amber, duration: 2.2, delay: 0.01)
            twinkle(MascotArt.sparkleSmallBrand, color: p.brand, duration: 2.8, delay: 0.5)
            twinkle(MascotArt.sparkleCoral, color: p.coral, duration: 3.2, delay: 1)
        default:
            EmptyView()
        }
    }

    private func twinkle(_ d: String, color: Color, duration: Double, delay: Double) -> some View {
        KeyframeAnimator(initialValue: TwinkleValue(), repeating: true) { value in
            svg(d).fill(color)
                .opacity(value.opacity)
                .scaleEffect(value.scale)
        } keyframes: { _ in
            KeyframeTrack(\.opacity) {
                CubicKeyframe(0.2, duration: delay)
                CubicKeyframe(1, duration: duration / 2)
                CubicKeyframe(0.2, duration: duration / 2)
            }
            KeyframeTrack(\.scale) {
                CubicKeyframe(0.75, duration: delay)
                CubicKeyframe(1.15, duration: duration / 2)
                CubicKeyframe(0.75, duration: duration / 2)
            }
        }
    }

    private var usesLowGeometry: Bool {
        if case .party = variant { return true }
        return false
    }

    @ViewBuilder private var capAndBody: some View {
        let low = usesLowGeometry

        if case .party = variant {
            svg(MascotArt.partyHat).fill(p.amber)
            circleDot(cx: 51, cy: 3, r: 2.6, color: p.amber)
            circleDot(cx: 69, cy: 3, r: 2.6, color: p.amber)
        }

        // Cap + holes + band
        svg(low ? MascotArt.capLow : MascotArt.cap).fill(p.brand)
        Capsule()
            .fill(.white.opacity(0.22))
            .frame(width: 19 * s, height: 4 * s)
            .rotationEffect(.degrees(-8))
            .position(x: 53 * s, y: (low ? 24 : 18) * s)
        if !usesLowGeometry {
            circleDot(cx: 52, cy: 21, r: 2.6, color: p.capHole)
            circleDot(cx: 60, cy: 16.5, r: 2.6, color: p.capHole)
            circleDot(cx: 68, cy: 21, r: 2.6, color: p.capHole)
        }
        RoundedRectangle(cornerRadius: 3.5 * s)
            .fill(p.brandDeep)
            .frame(width: 48 * s, height: 7 * s)
            .position(x: 60 * s, y: (low ? 41.5 : 39.5) * s)

        // Arms (not on the party variant, matching the design)
        if !low {
            arm(cx: 30, cy: 84, rotation: 16)
            arm(cx: 90, cy: 84, rotation: -16)
        }

        // The canonical Android mascot has grounded little feet. Keeping them
        // here also prevents the larger onboarding figure from looking as if
        // it ends abruptly at the body outline.
        if !low {
            Capsule().fill(p.brandDeep)
                .frame(width: 17 * s, height: 8 * s)
                .position(x: 49 * s, y: 121 * s)
            Capsule().fill(p.brandDeep)
                .frame(width: 17 * s, height: 8 * s)
                .position(x: 71 * s, y: 121 * s)
        }

        // Body
        svg(low ? MascotArt.bodyLow : MascotArt.body).fill(p.shaker)
        svg(low ? MascotArt.bodyLow : MascotArt.body)
            .stroke(p.shakerLine, lineWidth: 1.5 * s)
    }

    private func arm(cx: CGFloat, cy: CGFloat, rotation: Double) -> some View {
        ZStack {
            Ellipse().fill(p.shaker)
            Ellipse().stroke(p.shakerLine, lineWidth: 1.5 * s)
        }
        .frame(width: 10.4 * s, height: 14.8 * s)
        .rotationEffect(.degrees(rotation))
        .position(x: cx * s, y: cy * s)
    }

    @ViewBuilder private var face: some View {
        let low = usesLowGeometry
        let eyeY: CGFloat = low ? 74 : 72
        let blushY: CGFloat = low ? 83 : 81

        switch variant {
        case .allSet:
            stroke(MascotArt.happyEyeLeft, width: 2.4)
            stroke(MascotArt.happyEyeRight, width: 2.4)
        default:
            blinkingEyes(y: eyeY)
        }

        // Blush
        Ellipse().fill(p.coral.opacity(0.28))
            .frame(width: 9.2 * s, height: 5.6 * s)
            .position(x: 41 * s, y: blushY * s)
        Ellipse().fill(p.coral.opacity(0.28))
            .frame(width: 9.2 * s, height: 5.6 * s)
            .position(x: 79 * s, y: blushY * s)

        // Brows + mouth by variant
        switch variant {
        case .hero(let mood):
            stroke(mood.browLeft, width: 2.2).opacity(mood.browOpacity)
            stroke(mood.browRight, width: 2.2).opacity(mood.browOpacity)
            stroke(mood.mouth, width: 2.6)
            naLabel
        case .welcome:
            stroke(MascotArt.okSmile, width: 2.6)
            naLabel
        case .allSet:
            stroke(MascotArt.happySmile, width: 2.6)
        case .party:
            stroke(MascotArt.smileLow, width: 2.6)
        case .toastMini:
            stroke(MascotArt.okSmile, width: 2.6)
        }
    }

    private func blinkingEyes(y: CGFloat) -> some View {
        let anchor = UnitPoint(x: 0.5, y: y / MascotArt.viewBox.height)
        return Group {
            if animated {
                KeyframeAnimator(initialValue: BlinkValue(), repeating: true) { value in
                    eyes(y: y).scaleEffect(x: 1, y: value.scaleY, anchor: anchor)
                } keyframes: { _ in
                    KeyframeTrack(\.scaleY) {
                        LinearKeyframe(1, duration: 4.18)
                        LinearKeyframe(0.1, duration: 0.14)
                        LinearKeyframe(1, duration: 0.28)
                    }
                }
            } else {
                eyes(y: y)
            }
        }
    }

    private func eyes(y: CGFloat) -> some View {
        ZStack {
            circleDot(cx: 48, cy: y, r: 3.6, color: p.pinchInk)
            circleDot(cx: 72, cy: y, r: 3.6, color: p.pinchInk)
        }
        .frame(width: width, height: height)
    }

    private var naLabel: some View {
        PinchText("Na")
            .font(PinchFonts.display(11 * s, .semibold))
            .foregroundStyle(p.ink3.opacity(0.55))
            .position(x: 60 * s, y: 104.5 * s)
    }

    @ViewBuilder private var sweatDrop: some View {
        if case .hero(let mood) = variant, mood.showsSweat {
            KeyframeAnimator(initialValue: DripValue(), repeating: true) { value in
                svg(MascotArt.sweat)
                    .fill(Color(hex: 0x8FD3E8))
                    .opacity(value.opacity)
                    .offset(y: value.y * s)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    LinearKeyframe(4.5, duration: 1.44)
                    LinearKeyframe(7, duration: 0.36)
                    LinearKeyframe(-3, duration: 0.01)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.95, duration: 0.45)
                    LinearKeyframe(0.85, duration: 0.99)
                    LinearKeyframe(0, duration: 0.37)
                }
            }
        }
    }

    // MARK: primitives

    private func svg(_ d: String) -> SVGShape {
        SVGShape(d, viewBox: MascotArt.viewBox)
    }

    private func stroke(_ d: String, width lineWidth: CGFloat) -> some View {
        svg(d).stroke(p.pinchInk, style: StrokeStyle(lineWidth: lineWidth * s, lineCap: .round))
    }

    private func circleDot(cx: CGFloat, cy: CGFloat, r: CGFloat, color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 2 * r * s, height: 2 * r * s)
            .position(x: cx * s, y: cy * s)
    }
}

// MARK: - Logo marks

/// The small cap-and-body logo (app header, widget mock).
struct PinchLogo: View {
    @Environment(\.pinch) private var p
    var width: CGFloat = 18
    var bodyStroke: CGFloat = 3

    private var height: CGFloat { width * 130 / 120 }
    private var s: CGFloat { width / 120 }

    var body: some View {
        ZStack {
            SVGShape(MascotArt.cap, viewBox: MascotArt.viewBox).fill(p.brand)
            RoundedRectangle(cornerRadius: 3.5 * s)
                .fill(p.brandDeep)
                .frame(width: 48 * s, height: 7 * s)
                .position(x: 60 * s, y: 39.5 * s)
            SVGShape(MascotArt.body, viewBox: MascotArt.viewBox).fill(p.shaker)
            SVGShape(MascotArt.body, viewBox: MascotArt.viewBox)
                .stroke(p.shakerLine, lineWidth: bodyStroke * s)
        }
        .frame(width: width, height: height)
    }
}

/// White-on-color shaker glyph used in notification avatars.
struct PinchGlyph: View {
    var width: CGFloat = 13

    private var height: CGFloat { width * 130 / 120 }

    var body: some View {
        ZStack {
            SVGShape(MascotArt.cap, viewBox: MascotArt.viewBox)
                .fill(Color.white.opacity(0.9))
            SVGShape(MascotArt.body, viewBox: MascotArt.viewBox)
                .fill(Color.white.opacity(0.9))
        }
        .frame(width: width, height: height)
    }
}

/// The Settings "Pinch Plus" mascot: crown + smiling shaker.
struct PinchPlusMark: View {
    @Environment(\.pinch) private var p
    var width: CGFloat = 34

    private var height: CGFloat { width * 130 / 120 }
    private var s: CGFloat { width / 120 }

    var body: some View {
        ZStack {
            SVGShape("M45 13 L52 3 L60 12 L68 3 L75 13 Z", viewBox: MascotArt.viewBox)
                .fill(p.amber)
            SVGShape(MascotArt.cap, viewBox: MascotArt.viewBox).fill(p.brand)
            RoundedRectangle(cornerRadius: 3.5 * s)
                .fill(p.brandDeep)
                .frame(width: 48 * s, height: 7 * s)
                .position(x: 60 * s, y: 39.5 * s)
            SVGShape(MascotArt.body, viewBox: MascotArt.viewBox).fill(p.shaker)
            SVGShape(MascotArt.body, viewBox: MascotArt.viewBox)
                .stroke(p.shakerLine, lineWidth: 1.5 * s)
            Circle().fill(p.pinchInk).frame(width: 7.2 * s, height: 7.2 * s)
                .position(x: 48 * s, y: 72 * s)
            Circle().fill(p.pinchInk).frame(width: 7.2 * s, height: 7.2 * s)
                .position(x: 72 * s, y: 72 * s)
            SVGShape(MascotArt.okSmile, viewBox: MascotArt.viewBox)
                .stroke(p.pinchInk, style: StrokeStyle(lineWidth: 2.6 * s, lineCap: .round))
        }
        .frame(width: width, height: height)
        .clipped()
    }
}
