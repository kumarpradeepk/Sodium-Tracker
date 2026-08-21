//
//  SaltyRingCanvas.swift
//  Sodium Tracker
//
//  The ring and the mascot riding its tip, drawn together in one Canvas so a
//  single view invalidates per frame. Everything is authored in the design's
//  320-unit viewBox and scaled uniformly, so the mascot sits exactly on the arc
//  at any rendered size.
//
//  Two things worth knowing:
//   • Every engine value is read in `body`, not inside the Canvas closure.
//     Observation registers dependencies during body evaluation; a read that
//     happens later (at draw time) would never register and the ring would
//     freeze on its first frame.
//   • The canvas is drawn with `bleed` units of headroom on every side. The
//     mascot pokes outside the 320 viewBox near 12 o'clock — the prototype's
//     SVG sets `overflow: visible` for exactly this reason.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §5.3, §6
//

import SwiftUI

/// A frame's worth of mascot state, snapshotted in `body`.
private struct MascotFrame: Equatable {
    var point: CGPoint
    var hop: Double
    var tilt: Double
    var cap: Double
    var arm: Double
    var eyeRy: Double
    var features: MoodFeatures
}

struct SaltyRingCanvas: View {
    @Environment(\.salty) private var s
    let engine: SaltyEngine
    /// Rendered edge length of the ring itself. The design draws 316pt.
    var size: CGFloat = 316

    // Ring geometry in 320-space (spec: disc r112, track/arcs r134, stroke 23).
    private static let center = CGPoint(x: 160, y: 160)
    private static let arcRadius: CGFloat = 134
    private static let discRadius: CGFloat = 112
    private static let arcWidth: CGFloat = 23
    /// Headroom (in 320-space units) so the mascot is never clipped.
    private static let bleed: CGFloat = 44

    var body: some View {
        // --- Read every engine value here, so Observation tracks them. ---
        let arc = engine.arcFraction
        let over = engine.overFraction
        let pulse = engine.pulseScale
        let mascot = MascotFrame(
            point: engine.mascotPoint,
            hop: engine.hopOffset,
            tilt: engine.tilt,
            cap: engine.capOffset,
            arm: engine.armAngle,
            eyeRy: engine.eyeRy,
            features: engine.features
        )
        let tokens = s
        let k = size / 320
        let bleedPts = Self.bleed * k

        // The layout footprint is exactly the ring. The oversized canvas rides
        // in an overlay, which draws outside those bounds without widening the
        // parent — a plain oversized frame would push the whole screen wider.
        return Color.clear
            .frame(width: size, height: size)
            .overlay {
                Canvas { ctx, _ in
                    ctx.translateBy(x: bleedPts, y: bleedPts)
                    ctx.scaleBy(x: k, y: k)

                    drawDisc(&ctx, scale: pulse, tokens: tokens)
                    drawTrack(&ctx, tokens: tokens)
                    drawArc(&ctx, fraction: arc, color: tokens.blue)
                    if over > 0.001 {
                        drawArc(&ctx, fraction: over, color: tokens.amberArc)
                    }
                    drawMascot(&ctx, mascot, tokens: tokens)
                }
                .frame(width: size + bleedPts * 2, height: size + bleedPts * 2)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Ring

    private func drawDisc(_ ctx: inout GraphicsContext, scale: Double, tokens: SaltyTokens) {
        var c = ctx
        c.translateBy(x: Self.center.x, y: Self.center.y)
        c.scaleBy(x: scale, y: scale)
        c.translateBy(x: -Self.center.x, y: -Self.center.y)
        c.fill(Path(ellipseIn: rect(radius: Self.discRadius)), with: .color(tokens.disc))
    }

    /// Dotted salt-grain track: stroke 5, dash `0.1 8.6`, round caps.
    private func drawTrack(_ ctx: inout GraphicsContext, tokens: SaltyTokens) {
        ctx.stroke(
            Path(ellipseIn: rect(radius: Self.arcRadius)),
            with: .color(tokens.track),
            style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0.1, 8.6])
        )
    }

    /// Progress arc: starts at 12 o'clock, sweeps clockwise, round caps.
    private func drawArc(_ ctx: inout GraphicsContext, fraction: Double, color: Color) {
        guard fraction > 0 else { return }
        let path = Path { p in
            p.addArc(
                center: Self.center,
                radius: Self.arcRadius,
                startAngle: .degrees(-90),
                endAngle: .degrees(-90 + 360 * fraction),
                clockwise: false
            )
        }
        ctx.stroke(path, with: .color(color),
                   style: StrokeStyle(lineWidth: Self.arcWidth, lineCap: .round))
    }

    private func rect(radius: CGFloat) -> CGRect {
        CGRect(x: Self.center.x - radius, y: Self.center.y - radius,
               width: radius * 2, height: radius * 2)
    }

    // MARK: - Mascot

    private func drawMascot(_ ctx: inout GraphicsContext, _ m: MascotFrame, tokens: SaltyTokens) {
        var c = ctx
        // Transform stack: ride the arc → hop + bob → lean.
        c.translateBy(x: m.point.x, y: m.point.y)
        c.translateBy(x: 0, y: m.hop)
        c.rotate(by: .degrees(m.tilt))

        drawArm(&c, angle: m.arm, tokens: tokens)
        drawBody(&c, tokens: tokens)
        drawCap(&c, offset: m.cap, tokens: tokens)
        drawFace(&c, m.features, eyeRy: m.eyeRy, tokens: tokens)
    }

    /// Waving arm — drawn first so it sits behind the body.
    private func drawArm(_ ctx: inout GraphicsContext, angle: Double, tokens: SaltyTokens) {
        var c = ctx
        c.translateBy(x: 15, y: -2)
        c.rotate(by: .degrees(angle))
        c.translateBy(x: -15, y: 2)
        let arm = Path(roundedRect: CGRect(x: 12, y: -5, width: 15, height: 6.5), cornerRadius: 3.25)
        c.fill(arm, with: .color(tokens.mascotBody))
        c.stroke(arm, with: .color(tokens.mascotStroke), lineWidth: 1.5)
    }

    private func drawBody(_ ctx: inout GraphicsContext, tokens: SaltyTokens) {
        let body = Path(roundedRect: CGRect(x: -17, y: -15, width: 34, height: 33), cornerRadius: 12)
        ctx.fill(body, with: .color(tokens.mascotBody))
        ctx.stroke(body, with: .color(tokens.mascotStroke), lineWidth: 1.5)
    }

    /// Cap: crown + band + three holes. Pops upward on a shock impulse.
    private func drawCap(_ ctx: inout GraphicsContext, offset: Double, tokens: SaltyTokens) {
        var c = ctx
        c.translateBy(x: 0, y: offset)
        c.fill(Path(roundedRect: CGRect(x: -11, y: -31, width: 22, height: 13), cornerRadius: 6.5),
               with: .color(tokens.blue))
        c.fill(Path(roundedRect: CGRect(x: -16, y: -22, width: 32, height: 8), cornerRadius: 4),
               with: .color(tokens.blue))
        for (x, y) in [(-5.0, -26.0), (0.0, -25.0), (5.0, -26.0)] {
            c.fill(Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)),
                   with: .color(tokens.capHole))
        }
    }

    private func drawFace(
        _ ctx: inout GraphicsContext,
        _ f: MoodFeatures,
        eyeRy: Double,
        tokens: SaltyTokens
    ) {
        // Blush
        if f.blushOp > 0.001 {
            for x in [-11.0, 11.0] {
                ctx.fill(Path(ellipseIn: CGRect(x: x - 2.6, y: 3.5 - 2.6, width: 5.2, height: 5.2)),
                         with: .color(tokens.blush.opacity(f.blushOp)))
            }
        }

        // Open eyes — ry animates for the blink.
        if f.eyeOp > 0.001 {
            for x in [-6.5, 6.5] {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - 2.7, y: -3 - eyeRy, width: 5.4, height: eyeRy * 2)),
                    with: .color(tokens.mascotInk.opacity(f.eyeOp))
                )
            }
        }

        // ^^ joy eyes
        if f.joyOp > 0.001 {
            let joy = Path { p in
                p.move(to: CGPoint(x: -9.5, y: -2.5))
                p.addQuadCurve(to: CGPoint(x: -3.5, y: -2.5), control: CGPoint(x: -6.5, y: -6.5))
                p.move(to: CGPoint(x: 3.5, y: -2.5))
                p.addQuadCurve(to: CGPoint(x: 9.5, y: -2.5), control: CGPoint(x: 6.5, y: -6.5))
            }
            ctx.stroke(joy, with: .color(tokens.mascotInk.opacity(f.joyOp)),
                       style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
        }

        // Worried brows
        if f.browOp > 0.001 {
            let brows = Path { p in
                p.move(to: CGPoint(x: -9.5, y: -8)); p.addLine(to: CGPoint(x: -4, y: -10.3))
                p.move(to: CGPoint(x: 4, y: -10.3)); p.addLine(to: CGPoint(x: 9.5, y: -8))
            }
            ctx.stroke(brows, with: .color(tokens.mascotInk.opacity(f.browOp)),
                       style: StrokeStyle(lineWidth: 1.9, lineCap: .round))
        }

        // Mouth (quad curve, morphs between moods)
        if f.mouthOp > 0.001 {
            let m = f.mouth
            let mouth = Path { p in
                p.move(to: CGPoint(x: m.x0, y: m.y0))
                p.addQuadCurve(to: CGPoint(x: m.x1, y: m.y1), control: CGPoint(x: m.cx, y: m.cy))
            }
            ctx.stroke(mouth, with: .color(tokens.mascotInk.opacity(f.mouthOp)),
                       style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
        }

        // Shock "O"
        if f.shockOp > 0.001 {
            ctx.fill(Path(ellipseIn: CGRect(x: -3.1, y: 7.5 - 4, width: 6.2, height: 8)),
                     with: .color(tokens.mascotInk.opacity(f.shockOp)))
        }

        // Sweat drop — the prototype's relative `q` path, resolved to absolute.
        if f.sweatOp > 0.001 {
            let drop = Path { p in
                p.move(to: CGPoint(x: 16.5, y: -13))
                p.addQuadCurve(to: CGPoint(x: 16.5, y: -6.4), control: CGPoint(x: 19.9, y: -8.8))
                p.addQuadCurve(to: CGPoint(x: 16.5, y: -13), control: CGPoint(x: 13.1, y: -8.8))
                p.closeSubpath()
            }
            ctx.fill(drop, with: .color(tokens.sweat.opacity(f.sweatOp)))
        }
    }
}
