//
//  SplashTimeline.swift
//  Sodium Tracker
//
//  Timing primitives for the launch splash. The design is a pile of CSS
//  keyframe animations on one shared clock, so the port drives everything from
//  a single elapsed time and evaluates each track as a pure function of it.
//
//  Two details that matter for fidelity:
//   • CSS applies `animation-timing-function` between *each adjacent pair* of
//     keyframes, not once across the whole animation. `Keyframes.value` does
//     the same — easing the local interval, not the global progress.
//   • `both` fill mode holds the first keyframe before the delay and the last
//     one after the end, which is what every track in the design uses.
//
//  Spec: Pinch Onboarding + Settings.dc.html — "Splash" screen.
//

import Foundation

// MARK: - Easing

/// A CSS timing function.
struct Easing {
    let x1, y1, x2, y2: Double

    static let linear = Easing(x1: 0, y1: 0, x2: 1, y2: 1)
    static let ease = Easing(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1)
    static let easeIn = Easing(x1: 0.42, y1: 0, x2: 1, y2: 1)
    static let easeOut = Easing(x1: 0, y1: 0, x2: 0.58, y2: 1)
    static let easeInOut = Easing(x1: 0.42, y1: 0, x2: 0.58, y2: 1)

    /// The design's signature curves.
    static let outQuint = Easing(x1: 0.22, y1: 1, x2: 0.36, y2: 1)
    static let inOutSine = Easing(x1: 0.45, y1: 0, x2: 0.55, y2: 1)
    static let capBounce = Easing(x1: 0.3, y1: 0.7, x2: 0.4, y2: 1)
    static let grainOut = Easing(x1: 0.5, y1: 0, x2: 0.8, y2: 0.4)
    static let pourIn = Easing(x1: 0.4, y1: 0, x2: 0.9, y2: 0.6)

    func callAsFunction(_ t: Double) -> Double {
        guard t > 0 else { return 0 }
        guard t < 1 else { return 1 }
        if x1 == 0 && y1 == 0 && x2 == 1 && y2 == 1 { return t }

        // Solve x(u) = t for u by Newton–Raphson, then evaluate y(u).
        func bezier(_ a: Double, _ b: Double, _ u: Double) -> Double {
            let v = 1 - u
            return 3 * v * v * u * a + 3 * v * u * u * b + u * u * u
        }
        func slope(_ a: Double, _ b: Double, _ u: Double) -> Double {
            let v = 1 - u
            return 3 * v * v * a + 6 * v * u * (b - a) + 3 * u * u * (1 - b)
        }

        var u = t
        for _ in 0..<8 {
            let x = bezier(x1, x2, u) - t
            if abs(x) < 1e-6 { break }
            let d = slope(x1, x2, u)
            if abs(d) < 1e-6 { break }
            u -= x / d
        }
        return bezier(y1, y2, min(max(u, 0), 1))
    }
}

// MARK: - Keyframes

/// A CSS `@keyframes` value track: stop percentages (0…1) paired with values.
struct Keyframes {
    let stops: [(Double, Double)]

    init(_ stops: [(Double, Double)]) { self.stops = stops }

    /// Value at overall progress `p`, easing each interval independently.
    func value(_ p: Double, _ easing: Easing) -> Double {
        guard let first = stops.first else { return 0 }
        if p <= first.0 { return first.1 }
        guard let last = stops.last else { return 0 }
        if p >= last.0 { return last.1 }

        for i in 0..<(stops.count - 1) {
            let (p0, v0) = stops[i], (p1, v1) = stops[i + 1]
            guard p >= p0, p <= p1 else { continue }
            guard p1 > p0 else { return v1 }
            return v0 + (v1 - v0) * easing((p - p0) / (p1 - p0))
        }
        return last.1
    }
}

// MARK: - Track

/// One `animation: name duration easing delay fill` declaration.
struct Track {
    let start: Double
    let duration: Double
    let easing: Easing
    let repeats: Bool

    init(start: Double, duration: Double, easing: Easing = .linear, repeats: Bool = false) {
        self.start = start
        self.duration = duration
        self.easing = easing
        self.repeats = repeats
    }

    /// Progress 0…1 at elapsed time `t`, honouring `both` fill.
    func progress(_ t: Double) -> Double {
        guard duration > 0 else { return 1 }
        let e = t - start
        if e <= 0 { return 0 }
        if repeats { return (e / duration).truncatingRemainder(dividingBy: 1) }
        return min(e / duration, 1)
    }

    /// Convenience: evaluate a keyframe track at `t`.
    func callAsFunction(_ t: Double, _ frames: Keyframes) -> Double {
        frames.value(progress(t), easing)
    }

    /// Convenience: a simple 0→1 eased ramp.
    func ramp(_ t: Double) -> Double { easing(progress(t)) }
}
