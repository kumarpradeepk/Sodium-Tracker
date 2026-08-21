//
//  SaltyEngine.swift
//  Sodium Tracker
//
//  The Salty screen's motion engine: one clock, six springs, and the blink /
//  wave / mood / particle bookkeeping. Lives at shell level for the app's
//  lifetime, exactly like the prototype's persistent screen — so returning to
//  the Today tab never replays the load-in or resets the mascot.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §7, §8, §10
//

import SwiftUI
import QuartzCore

// MARK: - Particles

/// A flying "+610 mg" pill or one sparkle glyph, in screen space.
struct SaltyParticle: Identifiable {
    enum Kind {
        /// Quadratic Bézier from source to the ring centre.
        case fly(from: CGPoint, control: CGPoint, to: CGPoint, label: String)
        /// Ballistic ✦ with gravity and spin.
        case spark(colorIndex: Int, size: CGFloat)
    }

    let id = UUID()
    let kind: Kind
    let born: Double
    let life: Double

    // spark state
    var position: CGPoint = .zero
    var velocity: CGVector = .zero
    var rotation: Double = 0
    var spin: Double = 0

    var onArrive: (() -> Void)?
}

/// Which load-in reveal a block belongs to; the raw value is its delay in
/// seconds from launch (spec §8).
enum SaltyReveal: Double, CaseIterable, Hashable {
    case bubble = 0.95
    case cards = 1.15
    case sectionHeader = 1.30
    case chips = 1.38
}

// MARK: - Engine

@Observable
final class SaltyEngine {

    // MARK: Inputs (set by the screen)

    /// consumed / goal for the selected day. The ring springs to this.
    var fracTarget: Double = 0 {
        didSet { if kicked || reducedMotion { frac.target = fracTarget } }
    }
    /// `false` disables hops, waves and lean (design's `mascotEnergy: "subtle"`).
    var energyFull = true
    /// Mirrors the system Reduce Motion setting.
    var reducedMotion = false {
        didSet {
            guard reducedMotion != oldValue else { return }
            if reducedMotion {
                frac.k = SaltySpring.fracReducedK
                frac.c = SaltySpring.fracReducedC
                frac.settle(at: fracTarget)
                kicked = true
            } else {
                frac.k = SaltySpring.fracK
                frac.c = SaltySpring.fracC
            }
        }
    }

    // MARK: Clock

    private(set) var t: Double = 0
    private var kicked = false
    private var link: CADisplayLink?
    private var lastFrame: CFTimeInterval = 0

    // MARK: Springs

    private var frac = SpringValue(0, k: SaltySpring.fracK, c: SaltySpring.fracC)
    private var hop = SpringValue(0, k: SaltySpring.hopK, c: SaltySpring.hopC)
    private var pulse = SpringValue(1, k: SaltySpring.pulseK, c: SaltySpring.pulseC)
    private var tiltS = SpringValue(0, k: SaltySpring.tiltK, c: SaltySpring.tiltC)
    private var capS = SpringValue(0, k: SaltySpring.capK, c: SaltySpring.capC)
    private var armS = SpringValue(SaltySpring.armRest, k: SaltySpring.armK, c: SaltySpring.armC)

    // MARK: Mood

    /// What the mascot returns to once any flash expires.
    private(set) var restingMood: SaltyMood = .happy
    private var flashMood: SaltyMood?
    private var flashUntil: Double = 0
    private var moodFrom = SaltyMood.happy.features
    private var moodTo = SaltyMood.happy.features
    private var moodStart: Double = -1
    private static let moodCrossfade = 0.25

    // MARK: Blink / wave

    private var blinkAt: Double = 1.8
    private var blinking = false
    private var blinkT0: Double = 0
    private(set) var eyeRy: Double = 2.7
    private var waveUntil: Double = 0

    // MARK: Particles

    private(set) var particles: [SaltyParticle] = []

    // MARK: - Outputs

    /// Clamped arc fraction (never negative).
    var fraction: Double { max(0, frac.x) }
    /// Blue arc sweep, 0…1.
    var arcFraction: Double { min(fraction, 1) }
    /// Amber overflow sweep, 0…1.
    var overFraction: Double { min(max(0, fraction - 1), 1) }
    /// The counter under the ring — the spring *is* the count-up.
    func shown(budget: Int) -> Int { Int((fraction * Double(budget)).rounded()) }

    /// Mascot position in the design's 320-unit ring space.
    var mascotPoint: CGPoint {
        let ang = fraction.truncatingRemainder(dividingBy: 1) * 2 * .pi
        return CGPoint(x: 160 + 134 * sin(ang), y: 160 - 134 * cos(ang))
    }
    /// Hop spring plus the idle bob.
    var hopOffset: Double { hop.x + sin(t * 2.2) * 1.6 }
    var tilt: Double { tiltS.x }
    var capOffset: Double { capS.x }
    var pulseScale: Double { pulse.x }
    var armAngle: Double { armS.x }

    /// Current face, mid-crossfade if a mood just changed.
    var features: MoodFeatures {
        guard moodStart >= 0 else { return moodTo }
        let u = min(1, max(0, (t - moodStart) / Self.moodCrossfade))
        return u >= 1 ? moodTo : MoodFeatures.lerp(moodFrom, moodTo, u)
    }

    // MARK: - Lifecycle

    func start() {
        guard link == nil else { return }
        lastFrame = CACurrentMediaTime()
        let l = CADisplayLink(target: DisplayLinkProxy { [weak self] in self?.frameTick() },
                              selector: #selector(DisplayLinkProxy.fire))
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    private func frameTick() {
        let now = CACurrentMediaTime()
        advance(min(now - lastFrame, SaltySpring.maxTimestep))
        lastFrame = now
    }

    // MARK: - Integration (pure — tests drive this directly)

    func advance(_ dt: Double) {
        t += dt

        // Load-in: the ring holds at zero, then springs to the live value.
        if !kicked && !reducedMotion && t > SaltySpring.loadInDelay {
            kicked = true
            frac.target = fracTarget
        }

        // Lean into travel — a function of arc *velocity* (spec §7.2).
        tiltS.target = energyFull ? min(16, max(-16, frac.v * 260)) : 0
        armS.target = t < waveUntil
            ? -58 + sin(t * 13) * 28
            : SaltySpring.armRest

        frac.step(dt)
        hop.step(dt)
        pulse.step(dt)
        tiltS.step(dt)
        capS.step(dt)
        armS.step(dt)

        stepBlink()
        stepMood()
        stepParticles(dt)
    }

    private func stepBlink() {
        if !blinking && t >= blinkAt {
            blinking = true
            blinkT0 = t
        }
        guard blinking else { return }
        let p = (t - blinkT0) / 0.16
        if p >= 1 {
            blinking = false
            blinkAt = t + 2.6 + Double.random(in: 0...2.4)
            eyeRy = 2.7
        } else {
            eyeRy = p < 0.5 ? 2.7 - 4.8 * p : 0.3 + 4.8 * (p - 0.5)
        }
    }

    private func stepMood() {
        if flashMood != nil, t >= flashUntil {
            flashMood = nil
            retarget(to: restingMood)
        }
    }

    private func stepParticles(_ dt: Double) {
        guard !particles.isEmpty else { return }
        var survivors: [SaltyParticle] = []
        survivors.reserveCapacity(particles.count)
        for var p in particles {
            let u = (t - p.born) / p.life
            if u >= 1 {
                p.onArrive?()
                continue
            }
            if case .spark = p.kind {
                p.position.x += p.velocity.dx * dt
                p.velocity.dy += 560 * dt
                p.position.y += p.velocity.dy * dt
                p.rotation += p.spin * dt
            }
            survivors.append(p)
        }
        particles = survivors
    }

    // MARK: - Commands

    /// Sets the face the mascot returns to (spec §6 resting-mood rule).
    func setRestingMood(_ mood: SaltyMood) {
        guard mood != restingMood else { return }
        restingMood = mood
        if flashMood == nil { retarget(to: mood) }
    }

    /// Show `mood` for `seconds`, then revert to the resting face.
    func flash(_ mood: SaltyMood, seconds: Double) {
        flashMood = mood
        flashUntil = t + seconds
        retarget(to: mood)
    }

    private func retarget(to mood: SaltyMood) {
        moodFrom = features
        moodTo = mood.features
        moodStart = t
    }

    func wave(_ seconds: Double) {
        guard energyFull else { return }
        waveUntil = t + seconds
    }

    func impulse(hop dHop: Double = 0, cap dCap: Double = 0, tilt dTilt: Double = 0, pulse dPulse: Double = 0) {
        if dHop != 0 { hop.impulse(dHop) }
        if dCap != 0 { capS.impulse(dCap) }
        if dTilt != 0 { tiltS.impulse(dTilt) }
        if dPulse != 0 { pulse.impulse(dPulse) }
    }

    /// Snap the ring to the live value without a spring — used when the day
    /// changes, so the new day's arc doesn't sweep across from the old value.
    func settleFraction() {
        frac.settle(at: fracTarget)
        kicked = true
    }

    // MARK: Particle spawning

    /// A "+N mg" pill arcing from a chip to the ring centre (spec §10.1).
    func spawnFly(from source: CGPoint, to target: CGPoint, label: String, onArrive: @escaping () -> Void) {
        guard !reducedMotion else { onArrive(); return }
        let control = CGPoint(
            x: (source.x + target.x) / 2 + (source.x > target.x ? 70 : -70),
            y: min(source.y, target.y) - 60
        )
        particles.append(SaltyParticle(
            kind: .fly(from: source, control: control, to: target, label: label),
            born: t,
            life: 0.62,
            onArrive: onArrive
        ))
    }

    /// A radial ✦ burst (spec §10.2).
    func burst(at center: CGPoint, count: Int) {
        guard !reducedMotion else { return }
        for i in 0..<count {
            particles.append(SaltyParticle(
                kind: .spark(colorIndex: i % 3, size: 9 + CGFloat.random(in: 0...9)),
                born: t,
                life: 0.7 + Double.random(in: 0...0.35),
                position: center,
                velocity: CGVector(dx: (Double.random(in: 0...1) - 0.5) * 300,
                                   dy: -90 - Double.random(in: 0...200)),
                rotation: Double.random(in: 0...360),
                spin: (Double.random(in: 0...1) - 0.5) * 720
            ))
        }
    }

    /// Progress 0…1 of a particle, for the render layer.
    func progress(of p: SaltyParticle) -> Double {
        min(1, max(0, (t - p.born) / p.life))
    }
}

/// CADisplayLink needs an ObjC target; this keeps the engine a plain class.
private final class DisplayLinkProxy: NSObject {
    private let handler: () -> Void
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    @objc func fire() { handler() }
}
