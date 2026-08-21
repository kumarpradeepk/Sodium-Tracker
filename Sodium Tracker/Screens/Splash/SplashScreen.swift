//
//  SplashScreen.swift
//  Sodium Tracker
//
//  The launch splash: Pinch pours himself into existence, the cap drops on, the
//  face wakes up, and the wordmark rises. Every element is a pure function of
//  one elapsed clock, so the whole ~3.5 s choreography stays frame-exact.
//
//  Geometry is authored in the design's own units — a 320pt stage, a 300 ring
//  viewBox and a 120×131 mascot viewBox rendered at 150×164.
//
//  Spec: Pinch Onboarding + Settings.dc.html — "Splash" screen.
//

import SwiftUI

struct SplashScreen: View {
    @Environment(\.salty) private var s
    @Environment(\.pinch) private var p
    let onFinish: () -> Void

    /// Elapsed seconds since the splash appeared.
    @State private var t: Double = 0
    @State private var start = Date()

    /// The loader keeps pulsing, so "done" is the end of the scripted beats.
    private static let duration: Double = 3.6

    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSince(start)
            content(t: now)
        }
        .background(s.screenBg.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { onFinish() }          // let impatient launches skip
        .task {
            start = Date()
            try? await Task.sleep(for: .seconds(Self.duration))
            onFinish()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pinch. One number a day.")
    }

    // MARK: - Layout

    private func content(t: Double) -> some View {
        VStack(spacing: 0) {
            ZStack {
                glow(t: t)
                driftingGrains(t: t)
                rings(t: t)
                mascot(t: t)
            }
            .frame(width: 320, height: 320)
            .padding(.top, 150)
            // The pour starts 240pt above its rest point, so it spills out of
            // the stage — drawn unclipped over everything above.
            .overlay(alignment: .top) { pour(t: t) }

            wordmark(t: t).padding(.top, 26)
            tagline(t: t).padding(.top, 8)

            Spacer(minLength: 0)
            loader(t: t).padding(.bottom, 56)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .clipped()
    }

    // MARK: - Glow  (glowIn 1s ease-out 0.1s both)

    private func glow(t: Double) -> some View {
        let a = Track(start: 0.1, duration: 1.0, easing: .easeOut).ramp(t)
        return RadialGradient(
            colors: [s.blueSoft, s.blueSoft.opacity(0)],
            center: .center, startRadius: 0, endRadius: 150 * 0.68
        )
        .frame(width: 300, height: 300)
        .clipShape(Circle())
        .opacity(a)
    }

    // MARK: - Drifting grains  (grainDrift, staggered, infinite)

    /// left %, top, size, isRound, drift x, opacity, period, phase offset
    private static let drifters: [(Double, Double, Double, Bool, Double, Double, Double, Double)] = [
        (0.12, 8, 4, true, -12, 0.85, 6.4, -2.0),
        (0.26, 0, 5, false, 9, 0.75, 7.6, -5.0),
        (0.41, 4, 3, true, -7, 0.90, 5.6, -1.0),
        (0.55, 0, 4, false, 13, 0.70, 8.2, -6.5),
        (0.68, 6, 5, true, -10, 0.85, 6.9, -3.4),
        (0.82, 0, 4, false, 8, 0.75, 7.2, -0.6),
        (0.90, 10, 3, true, -14, 0.70, 5.9, -4.2),
        (0.05, 2, 4, false, 11, 0.75, 8.6, -7.1),
    ]

    private func driftingGrains(t: Double) -> some View {
        Canvas { ctx, size in
            for (left, top, dim, round, gsx, go, period, phase) in Self.drifters {
                let track = Track(start: phase, duration: period, easing: .linear, repeats: true)
                let pr = track.progress(t)
                // grainDrift: y -12 → 260, x 0 → gsx, rot 0 → 170°, fade in/out.
                let y = -12 + (260 + 12) * pr
                let x = gsx * pr
                let rot = 170.0 * pr
                let op = Keyframes([(0, 0), (0.12, go), (0.82, go), (1, 0)])
                    .value(pr, .linear)
                guard op > 0.001 else { continue }

                var c = ctx
                c.translateBy(x: left * size.width + x, y: top + y)
                c.rotate(by: .degrees(rot))
                c.opacity = op
                let r = CGRect(x: -dim / 2, y: -dim / 2, width: dim, height: dim)
                let path = round
                    ? Path(ellipseIn: r)
                    : Path(roundedRect: r, cornerRadius: 1)
                c.fill(path, with: .color(.white))
                c.stroke(path, with: .color(Color(hex: 0xA8B4C4)), lineWidth: 1)
            }
        }
        .frame(width: 320, height: 320)
        .clipped()
    }

    // MARK: - Rings  (ringIn + two counter-rotating dashed circles)

    private func rings(t: Double) -> some View {
        let inTrack = Track(start: 0.15, duration: 0.9, easing: .outQuint)
        let pr = inTrack.progress(t)
        let scale = 0.72 + 0.28 * Easing.outQuint(pr)
        let opacity = Easing.outQuint(pr)
        let spin = (t / 80).truncatingRemainder(dividingBy: 1) * 360
        let spinBack = -(t / 55).truncatingRemainder(dividingBy: 1) * 360

        return Canvas { ctx, _ in
            func ring(radius: CGFloat, dash: CGFloat, alpha: Double, rotation: Double) {
                var c = ctx
                c.translateBy(x: 150, y: 150)
                c.rotate(by: .degrees(rotation))
                c.translateBy(x: -150, y: -150)
                c.opacity = alpha
                let rect = CGRect(x: 150 - radius, y: 150 - radius,
                                  width: radius * 2, height: radius * 2)
                c.stroke(
                    Path(ellipseIn: rect),
                    with: .color(s.ink3),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.5, dash])
                )
            }
            ring(radius: 122, dash: 10, alpha: 0.5, rotation: spin)
            ring(radius: 88, dash: 9, alpha: 0.3, rotation: spinBack)
        }
        .frame(width: 300, height: 300)
        .scaleEffect(scale)
        .opacity(opacity)
    }

    // MARK: - Mascot  (120×131 viewBox rendered at 150×164)

    private func mascot(t: Double) -> some View {
        // --- tracks ---
        let shadowIn = Track(start: 0.9, duration: 0.4, easing: .easeOut).ramp(t)
        let shadowPulse = Track(start: 3.4, duration: 3.6, easing: .inOutSine, repeats: true)
        let pulseP = t >= 3.4 ? shadowPulse.progress(t) : 0
        let shadowScaleX = Keyframes([(0, 1), (0.5, 0.94), (1, 1)]).value(pulseP, .inOutSine)
        let shadowAlpha = shadowIn * Keyframes([(0, 0.10), (0.5, 0.08), (1, 0.10)])
            .value(pulseP, .inOutSine) / 0.10 * 0.10

        let pileT = Track(start: 0.3, duration: 1.3, easing: .easeOut)
        let pileP = pileT.progress(t)
        let pileScale = Keyframes([(0, 0), (0.25, 1), (0.70, 1), (1, 1.12)]).value(pileP, .easeOut)
        let pileOp = Keyframes([(0, 0), (0.25, 1), (0.70, 1), (1, 0)]).value(pileP, .easeOut)

        let popT = Track(start: 0.5, duration: 1.0, easing: .outQuint)
        let popP = popT.progress(t)
        let popSY = Keyframes([(0, 0.06), (0.18, 0.31), (0.62, 1.06), (0.82, 0.97), (1, 1)])
            .value(popP, .outQuint)
        let popSX = Keyframes([(0, 0.5), (0.18, 0.62), (0.62, 0.98), (0.82, 1.01), (1, 1)])
            .value(popP, .outQuint)
        let popOp = Keyframes([(0, 0), (0.18, 1), (1, 1)]).value(popP, .outQuint)

        let bobP = t >= 3.4 ? Track(start: 3.4, duration: 3.6, easing: .inOutSine, repeats: true).progress(t) : 0
        let bob = Keyframes([(0, 0), (0.5, -4), (1, 0)]).value(bobP, .inOutSine)

        let armP = t >= 3.4 ? Track(start: 3.4, duration: 6.0, easing: .easeInOut, repeats: true).progress(t) : 0
        let armSway = Keyframes([(0, 0), (0.5, 6), (1, 0)]).value(armP, .easeInOut)

        let capT = Track(start: 1.5, duration: 0.65, easing: .capBounce)
        let capP = capT.progress(t)
        let capY = Keyframes([(0, -44), (0.55, 0), (0.72, -5), (0.86, 1.5), (1, 0)])
            .value(capP, .capBounce)
        let capOp = Keyframes([(0, 0), (0.55, 1), (1, 1)]).value(capP, .capBounce)

        let faceOp = Track(start: 2.0, duration: 0.4, easing: .easeOut).ramp(t)

        let eyesIn = Track(start: 1.95, duration: 0.3, easing: .outQuint).ramp(t)
        let blinkP = t >= 3.9
            ? Track(start: 3.9, duration: 6.0, easing: .linear, repeats: true).progress(t) : 0
        let blink = Keyframes([
            (0, 1), (0.40, 1), (0.42, 0.06), (0.44, 1),
            (0.90, 1), (0.92, 0.06), (0.94, 1), (1, 1),
        ]).value(blinkP, .linear)
        let eyeScaleY = eyesIn * (t >= 3.9 ? blink : 1)

        let mouthT = Track(start: 2.1, duration: 0.35, easing: .outQuint)
        let mouthP = mouthT.progress(t)
        let mouthScale = Keyframes([(0, 0.4), (0.7, 1.12), (1, 1)]).value(mouthP, .outQuint)
        let mouthOp = Keyframes([(0, 0), (0.7, 1), (1, 1)]).value(mouthP, .outQuint)

        // Grain burst out of the open shaker, just before the cap lands.
        let bursts: [(Double, Double, Double)] = [(46, 1.85, -18), (60, 1.94, 3), (74, 2.02, 19)]

        return Canvas { ctx, size in
            let k = size.width / 120          // 150 / 120
            ctx.scaleBy(x: k, y: k)

            // Ground shadow
            if shadowAlpha > 0.001 {
                var c = ctx
                c.translateBy(x: 60, y: 124)
                c.scaleBy(x: shadowScaleX, y: 1)
                c.translateBy(x: -60, y: -124)
                c.opacity = shadowAlpha
                c.fill(Path(ellipseIn: CGRect(x: 26, y: 119, width: 68, height: 10)),
                       with: .color(Color(hex: 0x1B2B40)))
            }

            // Salt pile he pours himself out of
            if pileOp > 0.001 {
                var c = ctx
                c.translateBy(x: 60, y: 118)
                c.scaleBy(x: pileScale, y: pileScale)
                c.translateBy(x: -60, y: -118)
                c.opacity = pileOp
                let pile = Path(ellipseIn: CGRect(x: 43, y: 112.5, width: 34, height: 11))
                c.fill(pile, with: .color(Color(hex: 0xF4F2EC)))
                c.stroke(pile, with: .color(Color(hex: 0xDCD8CC)), lineWidth: 1)
            }

            guard popOp > 0.001 else { return }

            var body = ctx
            body.translateBy(x: 60, y: 118)
            body.scaleBy(x: popSX, y: popSY)
            body.translateBy(x: -60, y: -118)
            body.translateBy(x: 0, y: bob)
            body.opacity = popOp

            // Feet
            for x in [38.0, 66.0] {
                body.fill(
                    Path(roundedRect: CGRect(x: x, y: 114, width: 16, height: 9), cornerRadius: 4.5),
                    with: .color(p.brandDeep)
                )
            }

            // Arms — the right one sways once he's settled.
            drawArm(&body, x: 22, y: 66, rotation: 18, pivot: CGPoint(x: 28, y: 79))
            var armCtx = body
            armCtx.translateBy(x: 94, y: 60)
            armCtx.rotate(by: .degrees(armSway))
            armCtx.translateBy(x: -94, y: -60)
            drawArm(&armCtx, x: 88, y: 42, rotation: -136, pivot: CGPoint(x: 94, y: 55))

            // Body
            let shell = Path(roundedRect: CGRect(x: 30, y: 34, width: 60, height: 84), cornerRadius: 24)
            body.fill(shell, with: .color(Color(hex: 0xFDFCF8)))
            body.stroke(shell, with: .color(Color(hex: 0xE3E0D6)), lineWidth: 1.5)

            // Grains puffing out of the neck
            for (x, delay, gx) in bursts {
                let tr = Track(start: delay, duration: 0.7, easing: .grainOut)
                let pr = tr.progress(t)
                let op = Keyframes([(0, 0), (0.2, 1), (1, 0)]).value(pr, .grainOut)
                guard op > 0.001 else { continue }
                let e = Easing.grainOut(pr)
                var c = body
                c.opacity = op
                c.translateBy(x: gx * e, y: 32 * e)
                let sc = 0.6 + 0.4 * e
                c.fill(Path(ellipseIn: CGRect(x: x - 1.8 * sc, y: 32 - 1.8 * sc,
                                              width: 3.6 * sc, height: 3.6 * sc)),
                       with: .color(Color(hex: 0xDFE6EE)))
            }

            // Cap
            if capOp > 0.001 {
                var c = body
                c.opacity = capOp
                c.translateBy(x: 0, y: capY)
                c.fill(Path(roundedRect: CGRect(x: 34, y: 8, width: 52, height: 22), cornerRadius: 10),
                       with: .color(p.brand))
                c.fill(Path(roundedRect: CGRect(x: 26, y: 26, width: 68, height: 10), cornerRadius: 5),
                       with: .color(p.brandDeep))
                for (hx, hy) in [(46.0, 17.0), (55.0, 14.0), (65.0, 14.0), (74.0, 17.0)] {
                    c.fill(Path(ellipseIn: CGRect(x: hx - 2, y: hy - 2, width: 4, height: 4)),
                           with: .color(.black.opacity(0.35)))
                }
            }

            // Brows + blush
            if faceOp > 0.001 {
                var c = body
                c.opacity = faceOp * 0.6
                for bx in [42.0, 70.0] {
                    let brow = Path { pth in
                        pth.move(to: CGPoint(x: bx, y: 56))
                        pth.addQuadCurve(to: CGPoint(x: bx + 8, y: 56),
                                         control: CGPoint(x: bx + 4, y: 52))
                    }
                    c.stroke(brow, with: .color(Color(hex: 0x39465C)),
                             style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                var blush = body
                blush.opacity = faceOp * 0.85
                for cx in [38.0, 82.0] {
                    blush.fill(Path(ellipseIn: CGRect(x: cx - 4, y: 68, width: 8, height: 8)),
                               with: .color(Color(hex: 0xF3C8C2)))
                }
            }

            // Eyes
            if eyeScaleY > 0.001 {
                for cx in [48.0, 72.0] {
                    var c = body
                    c.translateBy(x: cx, y: 64)
                    c.scaleBy(x: 1, y: max(eyeScaleY, 0.0001))
                    c.translateBy(x: -cx, y: -64)
                    c.fill(Path(ellipseIn: CGRect(x: cx - 3.3, y: 64 - 4.2, width: 6.6, height: 8.4)),
                           with: .color(Color(hex: 0x22314A)))
                    c.opacity = 0.9
                    c.fill(Path(ellipseIn: CGRect(x: cx - 1.2 - 1.2, y: 62.2 - 1.2,
                                                  width: 2.4, height: 2.4)),
                           with: .color(.white))
                }
            }

            // Mouth + tongue
            if mouthOp > 0.001 {
                var c = body
                c.translateBy(x: 60, y: 79)
                c.scaleBy(x: mouthScale, y: mouthScale)
                c.translateBy(x: -60, y: -79)
                c.opacity = mouthOp
                let mouth = Path { pth in
                    pth.move(to: CGPoint(x: 48, y: 76))
                    pth.addQuadCurve(to: CGPoint(x: 72, y: 76), control: CGPoint(x: 60, y: 92))
                    pth.addQuadCurve(to: CGPoint(x: 48, y: 76), control: CGPoint(x: 60, y: 83))
                    pth.closeSubpath()
                }
                c.fill(mouth, with: .color(Color(hex: 0x22314A)))
                c.fill(Path(ellipseIn: CGRect(x: 54, y: 78.6, width: 12, height: 6.8)),
                       with: .color(Color(hex: 0xD95F43)))
            }

            // Chest diamond
            var diamond = body
            diamond.translateBy(x: 60, y: 102)
            diamond.rotate(by: .degrees(45))
            diamond.translateBy(x: -60, y: -102)
            diamond.fill(
                Path(roundedRect: CGRect(x: 56, y: 98, width: 8, height: 8), cornerRadius: 2),
                with: .color(s.blueSoft)
            )
        }
        .frame(width: 150, height: 164)
    }

    private func drawArm(_ ctx: inout GraphicsContext, x: Double, y: Double,
                         rotation: Double, pivot: CGPoint) {
        var c = ctx
        c.translateBy(x: pivot.x, y: pivot.y)
        c.rotate(by: .degrees(rotation))
        c.translateBy(x: -pivot.x, y: -pivot.y)
        let arm = Path(roundedRect: CGRect(x: x, y: y, width: 12, height: 26), cornerRadius: 6)
        c.fill(arm, with: .color(Color(hex: 0xFDFCF8)))
        c.stroke(arm, with: .color(Color(hex: 0xE3E0D6)), lineWidth: 1.5)
    }

    // MARK: - Pour  (14 falling grains + 4 splash grains)

    /// left offset, size, isRound, jitter x, delay
    private static let falling: [(Double, Double, Bool, Double, Double)] = [
        (-7, 5, true, 4, 0.02), (1, 4, false, -5, 0.10), (-3, 6, true, 2, 0.17),
        (5, 4, true, -3, 0.24), (-9, 5, false, 6, 0.32), (2, 5, true, -6, 0.39),
        (-5, 4, false, 3, 0.47), (6, 6, true, -4, 0.54), (-8, 4, true, 5, 0.62),
        (0, 5, false, -2, 0.70), (-4, 4, true, 4, 0.78), (4, 5, true, -5, 0.86),
        (-6, 4, false, 2, 0.94), (1, 5, true, -3, 1.02),
    ]

    /// left offset, isRound, splash x, delay
    private static let splashes: [(Double, Bool, Double, Double)] = [
        (-2, true, -20, 0.75), (0, false, -9, 0.92), (2, true, 12, 1.08), (4, false, 22, 1.22),
    ]

    private func pour(t: Double) -> some View {
        Canvas { ctx, size in
            let originX = size.width / 2
            let originY: CGFloat = 150       // rest point inside the stage

            for (left, dim, round, jx, delay) in Self.falling {
                let tr = Track(start: delay, duration: 0.55, easing: .pourIn)
                let pr = tr.progress(t)
                guard pr > 0, pr < 1 else { continue }
                let e = Easing.pourIn(pr)
                let op = Keyframes([(0, 0), (0.10, 1), (0.88, 1), (1, 0)]).value(pr, .pourIn)
                let x = originX + left + jx * (1 - e)
                let y = originY - 240 * (1 - e)
                draw(&ctx, x: x, y: y, dim: dim, round: round, opacity: op)
            }

            for (left, round, sx, delay) in Self.splashes {
                let tr = Track(start: delay, duration: 0.5, easing: .easeOut)
                let pr = tr.progress(t)
                guard pr > 0, pr < 1 else { continue }
                let pos = Keyframes([(0, 0), (0.30, sx * 0.6), (1, sx)]).value(pr, .easeOut)
                let dy = Keyframes([(0, 0), (0.30, -9), (1, 5)]).value(pr, .easeOut)
                let op = Keyframes([(0, 0), (0.30, 1), (1, 0)]).value(pr, .easeOut)
                let sc = Keyframes([(0, 0.7), (0.30, 1), (1, 1)]).value(pr, .easeOut)
                draw(&ctx, x: originX + left + pos, y: originY + 18 + dy,
                     dim: 4 * sc, round: round, opacity: op)
            }
        }
        .frame(width: 320, height: 320)
        .allowsHitTesting(false)
    }

    private func draw(_ ctx: inout GraphicsContext, x: Double, y: Double,
                      dim: Double, round: Bool, opacity: Double) {
        guard opacity > 0.001 else { return }
        var c = ctx
        c.opacity = opacity
        let r = CGRect(x: x - dim / 2, y: y - dim / 2, width: dim, height: dim)
        let path = round ? Path(ellipseIn: r) : Path(roundedRect: r, cornerRadius: 1)
        c.fill(path, with: .color(.white))
        c.stroke(path, with: .color(Color(hex: 0xAAB6C6)), lineWidth: 1)
    }

    // MARK: - Wordmark, tagline, loader

    private func wordmark(t: Double) -> some View {
        let letters = Array("Pinch")
        return ZStack(alignment: .top) {
            // Three grains season the word as it lands.
            ForEach(Array([(0.28, -16.0, 4.0, false, 2.70),
                           (0.50, -20.0, 3.0, true, 2.82),
                           (0.68, -15.0, 4.0, false, 2.94)].enumerated()),
                    id: \.offset) { _, g in
                let (leftFrac, top, dim, round, delay) = g
                let tr = Track(start: delay, duration: 0.6, easing: .easeIn)
                let pr = tr.progress(t)
                let op = Keyframes([(0, 0), (0.25, 0.9), (1, 0)]).value(pr, .easeIn)
                let dy = Keyframes([(0, 0), (1, 22)]).value(pr, .easeIn)
                Group {
                    if round {
                        Circle().fill(.white).overlay(Circle().strokeBorder(Color(hex: 0xA8B4C4), lineWidth: 1))
                    } else {
                        RoundedRectangle(cornerRadius: 1).fill(.white)
                            .overlay(RoundedRectangle(cornerRadius: 1).strokeBorder(Color(hex: 0xA8B4C4), lineWidth: 1))
                    }
                }
                .frame(width: dim, height: dim)
                .opacity(op)
                .offset(x: (leftFrac - 0.5) * 130, y: top + dy)
            }

            HStack(spacing: 0) {
                ForEach(Array(letters.enumerated()), id: \.offset) { i, ch in
                    let tr = Track(start: 2.2 + Double(i) * 0.07, duration: 0.5, easing: .outQuint)
                    let pr = tr.ramp(t)
                    PinchText(String(ch))
                        .font(.system(size: 46, weight: .heavy))
                        .tracking(46 * -0.02)
                        .foregroundStyle(s.ink)
                        .opacity(pr)
                        .offset(y: 14 * (1 - pr))
                }
            }
        }
    }

    private func tagline(t: Double) -> some View {
        let pr = Track(start: 2.75, duration: 0.5, easing: .outQuint).ramp(t)
        return PinchText("One number a day.")
            .font(.system(size: 16))
            .foregroundStyle(s.ink2)
            .opacity(pr)
            .offset(y: 14 * (1 - pr))
    }

    private func loader(t: Double) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { i in
                let delay = 2.9 + Double(i) * 0.15
                let pr = t >= delay
                    ? Track(start: delay, duration: 1.2, easing: .easeInOut, repeats: true).progress(t)
                    : 0
                let op = t >= delay
                    ? Keyframes([(0, 0.25), (0.5, 0.9), (1, 0.25)]).value(pr, .easeInOut) : 0
                let sc = t >= delay
                    ? Keyframes([(0, 0.8), (0.5, 1), (1, 0.8)]).value(pr, .easeInOut) : 0.8
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white)
                    .overlay(RoundedRectangle(cornerRadius: 1.5)
                        .strokeBorder(Color(hex: 0xB6BFCB), lineWidth: 1))
                    .frame(width: 7, height: 7)
                    .rotationEffect(.degrees(45))
                    .scaleEffect(sc)
                    .opacity(op)
            }
        }
    }
}
