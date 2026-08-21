//
//  PinchFigure.swift
//  Sodium Tracker
//
//  Pinch standing still — the settled pose the notification screens use, as
//  opposed to the splash's pour-in. Same 120×131 viewBox and the same body
//  geometry; the difference is the raised hand, which can hold a bell that
//  rings on a 5 s cycle.
//
//  Spec: Pinch Onboarding + Settings.dc.html — "Onboarding Notifications".
//

import SwiftUI

struct PinchFigure: View {
    @Environment(\.pinch) private var p
    @Environment(\.salty) private var s

    /// Puts a ringing bell in the raised hand.
    var holdingBell = false
    var width: CGFloat = 130

    @State private var start = Date()

    private static let shell = Color(hex: 0xFDFCF8)
    private static let shellLine = Color(hex: 0xE3E0D6)
    private static let ink = Color(hex: 0x22314A)
    private static let bellFill = Color(hex: 0xF3C94E)
    private static let bellLine = Color(hex: 0xC9962E)

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { ctx, size in
                let k = size.width / 120
                ctx.scaleBy(x: k, y: k)
                draw(&ctx, t: t)
            }
        }
        .frame(width: width, height: width * 142 / 130)
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, t: Double) {
        // Idle loops run continuously here — the figure is already settled.
        let bobP = Track(start: 0, duration: 3.6, easing: .inOutSine, repeats: true).progress(t)
        let bob = Keyframes([(0, 0), (0.5, -4), (1, 0)]).value(bobP, .inOutSine)
        let shadowScale = Keyframes([(0, 1), (0.5, 0.94), (1, 1)]).value(bobP, .inOutSine)
        let shadowAlpha = Keyframes([(0, 0.10), (0.5, 0.08), (1, 0.10)]).value(bobP, .inOutSine)

        // Ground shadow
        var sh = ctx
        sh.translateBy(x: 60, y: 124)
        sh.scaleBy(x: shadowScale, y: 1)
        sh.translateBy(x: -60, y: -124)
        sh.opacity = shadowAlpha
        sh.fill(Path(ellipseIn: CGRect(x: 26, y: 119, width: 68, height: 10)),
                with: .color(Color(hex: 0x1B2B40)))

        var c = ctx
        c.translateBy(x: 0, y: bob)

        // Feet
        for x in [38.0, 66.0] {
            c.fill(Path(roundedRect: CGRect(x: x, y: 114, width: 16, height: 9), cornerRadius: 4.5),
                   with: .color(p.brandDeep))
        }

        // Left arm, angled down
        arm(&c, x: 22, y: 66, rotation: 18, pivot: CGPoint(x: 28, y: 79))

        // Right arm — jitters sideways as the bell rings.
        let ringP = Track(start: 0, duration: 5.0, easing: .easeInOut, repeats: true).progress(t)
        let shake = holdingBell
            ? Keyframes([(0, 0), (0.55, 0), (0.62, 2.4), (0.69, -2.4),
                         (0.76, 1.6), (0.82, -1), (0.88, 0), (1, 0)])
                .value(ringP, .easeInOut)
            : 0
        var armCtx = c
        armCtx.translateBy(x: shake, y: 0)
        arm(&armCtx, x: 88, y: 42, rotation: -136, pivot: CGPoint(x: 94, y: 55))

        // Bell, swinging from the hand
        if holdingBell {
            let swing = Keyframes([
                (0, 0), (0.54, 0), (0.62, 14), (0.70, -11),
                (0.78, 7), (0.86, -3), (0.92, 1), (1, 0),
            ]).value(ringP, .easeInOut)
            var b = c
            b.translateBy(x: 99, y: 34)
            b.rotate(by: .degrees(swing))
            b.translateBy(x: -99, y: -34)
            let bell = Path { pth in
                pth.move(to: CGPoint(x: 99, y: 24))
                pth.addCurve(to: CGPoint(x: 87.5, y: 35.5),
                             control1: CGPoint(x: 92, y: 24), control2: CGPoint(x: 87.5, y: 29))
                pth.addLine(to: CGPoint(x: 87.5, y: 43))
                pth.addLine(to: CGPoint(x: 84.5, y: 48.5))
                pth.addCurve(to: CGPoint(x: 85.8, y: 50.5),
                             control1: CGPoint(x: 84, y: 49.5), control2: CGPoint(x: 84.7, y: 50.5))
                pth.addLine(to: CGPoint(x: 112.2, y: 50.5))
                pth.addCurve(to: CGPoint(x: 113.5, y: 48.5),
                             control1: CGPoint(x: 113.3, y: 50.5), control2: CGPoint(x: 114, y: 49.5))
                pth.addLine(to: CGPoint(x: 110.5, y: 43))
                pth.addLine(to: CGPoint(x: 110.5, y: 35.5))
                pth.addCurve(to: CGPoint(x: 99, y: 24),
                             control1: CGPoint(x: 110.5, y: 29), control2: CGPoint(x: 106, y: 24))
                pth.closeSubpath()
            }
            b.fill(bell, with: .color(Self.bellFill))
            b.stroke(bell, with: .color(Self.bellLine),
                     style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            b.fill(Path(ellipseIn: CGRect(x: 96, y: 51, width: 6, height: 6)),
                   with: .color(Self.bellLine))
        }

        // Body + cap
        let shell = Path(roundedRect: CGRect(x: 30, y: 34, width: 60, height: 84), cornerRadius: 24)
        c.fill(shell, with: .color(Self.shell))
        c.stroke(shell, with: .color(Self.shellLine), lineWidth: 1.5)
        c.fill(Path(roundedRect: CGRect(x: 34, y: 8, width: 52, height: 22), cornerRadius: 10),
               with: .color(p.brand))
        c.fill(Path(roundedRect: CGRect(x: 26, y: 26, width: 68, height: 10), cornerRadius: 5),
               with: .color(p.brandDeep))
        for (hx, hy) in [(46.0, 17.0), (55.0, 14.0), (65.0, 14.0), (74.0, 17.0)] {
            c.fill(Path(ellipseIn: CGRect(x: hx - 2, y: hy - 2, width: 4, height: 4)),
                   with: .color(.black.opacity(0.35)))
        }

        // Brows
        var brows = c
        brows.opacity = 0.6
        for bx in [42.0, 70.0] {
            let brow = Path { pth in
                pth.move(to: CGPoint(x: bx, y: 56))
                pth.addQuadCurve(to: CGPoint(x: bx + 8, y: 56), control: CGPoint(x: bx + 4, y: 52))
            }
            brows.stroke(brow, with: .color(Color(hex: 0x39465C)),
                         style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // Eyes, blinking on the shared 6 s cycle
        let blinkP = Track(start: 0, duration: 6.0, easing: .linear, repeats: true).progress(t)
        let blink = Keyframes([
            (0, 1), (0.40, 1), (0.42, 0.06), (0.44, 1),
            (0.90, 1), (0.92, 0.06), (0.94, 1), (1, 1),
        ]).value(blinkP, .linear)
        for cx in [48.0, 72.0] {
            var e = c
            e.translateBy(x: cx, y: 64)
            e.scaleBy(x: 1, y: max(blink, 0.0001))
            e.translateBy(x: -cx, y: -64)
            e.fill(Path(ellipseIn: CGRect(x: cx - 3.3, y: 59.8, width: 6.6, height: 8.4)),
                   with: .color(Self.ink))
            e.opacity = 0.9
            e.fill(Path(ellipseIn: CGRect(x: cx - 2.4, y: 61, width: 2.4, height: 2.4)),
                   with: .color(.white))
        }

        // Blush, mouth, tongue, chest diamond
        var blush = c
        blush.opacity = 0.85
        for cx in [38.0, 82.0] {
            blush.fill(Path(ellipseIn: CGRect(x: cx - 4, y: 68, width: 8, height: 8)),
                       with: .color(Color(hex: 0xF3C8C2)))
        }
        let mouth = Path { pth in
            pth.move(to: CGPoint(x: 48, y: 76))
            pth.addQuadCurve(to: CGPoint(x: 72, y: 76), control: CGPoint(x: 60, y: 92))
            pth.addQuadCurve(to: CGPoint(x: 48, y: 76), control: CGPoint(x: 60, y: 83))
            pth.closeSubpath()
        }
        c.fill(mouth, with: .color(Self.ink))
        c.fill(Path(ellipseIn: CGRect(x: 54, y: 78.6, width: 12, height: 6.8)),
               with: .color(Color(hex: 0xD95F43)))

        var d = c
        d.translateBy(x: 60, y: 102)
        d.rotate(by: .degrees(45))
        d.translateBy(x: -60, y: -102)
        d.fill(Path(roundedRect: CGRect(x: 56, y: 98, width: 8, height: 8), cornerRadius: 2),
               with: .color(s.blueSoft))
    }

    private func arm(_ ctx: inout GraphicsContext, x: Double, y: Double,
                     rotation: Double, pivot: CGPoint) {
        var c = ctx
        c.translateBy(x: pivot.x, y: pivot.y)
        c.rotate(by: .degrees(rotation))
        c.translateBy(x: -pivot.x, y: -pivot.y)
        let a = Path(roundedRect: CGRect(x: x, y: y, width: 12, height: 26), cornerRadius: 6)
        c.fill(a, with: .color(Self.shell))
        c.stroke(a, with: .color(Self.shellLine), lineWidth: 1.5)
    }
}
