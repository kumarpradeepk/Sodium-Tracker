//
//  SpringValue.swift
//  Sodium Tracker
//
//  The prototype's spring integrator, ported literally. The design drives every
//  motion through `accel = k(target − x) − c·v`, integrated with semi-implicit
//  Euler at a capped timestep — and it both injects raw velocity impulses and
//  reads velocity back out (the mascot's lean is a function of arc velocity).
//  Neither is expressible with SwiftUI's spring animations, so we run the same
//  loop the prototype runs.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §7
//

import Foundation

/// One critically-parameterised spring: position, velocity, target, k and c.
struct SpringValue {
    /// Current position.
    var x: Double
    /// Current velocity.
    var v: Double = 0
    /// Where the spring is pulling toward.
    var target: Double
    /// Stiffness.
    var k: Double
    /// Damping.
    var c: Double

    init(_ x: Double, k: Double, c: Double) {
        self.x = x
        self.target = x
        self.k = k
        self.c = c
    }

    /// One integration step. Order matters — accel, then velocity, then
    /// position (semi-implicit Euler), exactly as the prototype's rAF loop.
    mutating func step(_ dt: Double) {
        let a = k * (target - x) - c * v
        v += a * dt
        x += v * dt
    }

    /// Kick the spring without moving it — the design's `S.hop.v -= 230` idiom.
    mutating func impulse(_ dv: Double) {
        v += dv
    }

    /// Jump straight to a value, killing motion (reduced-motion / cold start).
    mutating func settle(at value: Double) {
        x = value
        target = value
        v = 0
    }
}

// MARK: - Spring constants (spec §7.2)

enum SaltySpring {
    static let fracK = 40.0,     fracC = 8.5
    static let fracReducedK = 300.0, fracReducedC = 34.0
    static let hopK = 190.0,     hopC = 12.0
    static let pulseK = 160.0,   pulseC = 10.0
    static let tiltK = 120.0,    tiltC = 11.0
    static let capK = 200.0,     capC = 12.0
    static let armK = 90.0,      armC = 7.0

    /// The arm's resting angle; waving swings it to −58° ± 28°.
    static let armRest = 30.0
    /// Largest timestep the integrator will accept (prototype caps at 33 ms).
    static let maxTimestep = 0.033
    /// The ring holds at zero for this long before springing to the live value.
    static let loadInDelay = 0.42
}

// MARK: - Moods (spec §6)

/// The mascot's expression. Distinct from `Mood` (percent-banded, used by the
/// rest of the app) — Salty's five faces are event-driven.
enum SaltyMood: String, CaseIterable {
    case happy, joy, concern, worried, shock

    var features: MoodFeatures {
        switch self {
        case .happy:
            return MoodFeatures(
                mouth: MouthCurve(x0: -6, y0: 5, cx: 0, cy: 10.5, x1: 6, y1: 5),
                mouthOp: 1, eyeOp: 1, joyOp: 0, browOp: 0, blushOp: 0.45, sweatOp: 0, shockOp: 0
            )
        case .joy:
            return MoodFeatures(
                mouth: MouthCurve(x0: -7.5, y0: 4, cx: 0, cy: 13, x1: 7.5, y1: 4),
                mouthOp: 1, eyeOp: 0, joyOp: 1, browOp: 0, blushOp: 0.8, sweatOp: 0, shockOp: 0
            )
        case .concern:
            return MoodFeatures(
                mouth: MouthCurve(x0: -5.5, y0: 8, cx: 0, cy: 5.5, x1: 5.5, y1: 8),
                mouthOp: 1, eyeOp: 1, joyOp: 0, browOp: 0.9, blushOp: 0.3, sweatOp: 0, shockOp: 0
            )
        case .worried:
            return MoodFeatures(
                mouth: MouthCurve(x0: -5.5, y0: 8, cx: 0, cy: 5.5, x1: 5.5, y1: 8),
                mouthOp: 1, eyeOp: 1, joyOp: 0, browOp: 0.9, blushOp: 0.25, sweatOp: 0.9, shockOp: 0
            )
        case .shock:
            return MoodFeatures(
                mouth: MouthCurve(x0: -5.5, y0: 8, cx: 0, cy: 5.5, x1: 5.5, y1: 8),
                mouthOp: 0, eyeOp: 1, joyOp: 0, browOp: 0.9, blushOp: 0.2, sweatOp: 0.9, shockOp: 1
            )
        }
    }
}

/// The mouth quadratic, in the mascot's local (ring-320) space.
struct MouthCurve: Equatable {
    var x0, y0, cx, cy, x1, y1: Double

    static func lerp(_ a: MouthCurve, _ b: MouthCurve, _ u: Double) -> MouthCurve {
        func l(_ p: Double, _ q: Double) -> Double { p + (q - p) * u }
        return MouthCurve(
            x0: l(a.x0, b.x0), y0: l(a.y0, b.y0),
            cx: l(a.cx, b.cx), cy: l(a.cy, b.cy),
            x1: l(a.x1, b.x1), y1: l(a.y1, b.y1)
        )
    }
}

/// Everything that varies between faces. Interpolated during a mood change so
/// features cross-fade rather than snap (spec §6, §15.4).
struct MoodFeatures: Equatable {
    var mouth: MouthCurve
    var mouthOp, eyeOp, joyOp, browOp, blushOp, sweatOp, shockOp: Double

    static func lerp(_ a: MoodFeatures, _ b: MoodFeatures, _ u: Double) -> MoodFeatures {
        func l(_ p: Double, _ q: Double) -> Double { p + (q - p) * u }
        return MoodFeatures(
            mouth: MouthCurve.lerp(a.mouth, b.mouth, u),
            mouthOp: l(a.mouthOp, b.mouthOp),
            eyeOp: l(a.eyeOp, b.eyeOp),
            joyOp: l(a.joyOp, b.joyOp),
            browOp: l(a.browOp, b.browOp),
            blushOp: l(a.blushOp, b.blushOp),
            sweatOp: l(a.sweatOp, b.sweatOp),
            shockOp: l(a.shockOp, b.shockOp)
        )
    }
}
