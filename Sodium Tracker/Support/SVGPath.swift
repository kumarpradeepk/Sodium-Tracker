//
//  SVGPath.swift
//  Sodium Tracker
//
//  Minimal SVG path-data parser covering the subset used by the Pinch design:
//  absolute M, L, H, V, C, Q, A and Z. All mascot faces and food/badge icons
//  in the design are authored with these commands.
//

import SwiftUI

enum SVGPath {
    /// Parses an SVG `d` attribute into a SwiftUI Path (in the SVG's own units).
    /// Parsing is cheap enough to run per layout pass; no shared cache so this
    /// stays safe from any thread SwiftUI calls Shape.path(in:) on.
    static func path(_ d: String) -> Path {
        build(d)
    }

    private static func build(_ d: String) -> Path {
        var path = Path()
        var current = CGPoint.zero
        var start = CGPoint.zero

        let tokens = tokenize(d)
        var i = 0

        func take(_ count: Int) -> [CGFloat]? {
            var values: [CGFloat] = []
            var j = i
            while values.count < count, j < tokens.count {
                if case .number(let v) = tokens[j] {
                    values.append(v)
                    j += 1
                } else {
                    return nil
                }
            }
            guard values.count == count else { return nil }
            i = j
            return values
        }

        func hasNumber() -> Bool {
            if i < tokens.count, case .number = tokens[i] { return true }
            return false
        }

        while i < tokens.count {
            guard case .command(let cmd) = tokens[i] else { i += 1; continue }
            i += 1
            switch cmd {
            case "M":
                if let n = take(2) {
                    current = CGPoint(x: n[0], y: n[1])
                    start = current
                    path.move(to: current)
                }
                while hasNumber(), let n = take(2) {  // implicit linetos
                    current = CGPoint(x: n[0], y: n[1])
                    path.addLine(to: current)
                }
            case "L":
                while hasNumber(), let n = take(2) {
                    current = CGPoint(x: n[0], y: n[1])
                    path.addLine(to: current)
                }
            case "H":
                while hasNumber(), let n = take(1) {
                    current = CGPoint(x: n[0], y: current.y)
                    path.addLine(to: current)
                }
            case "V":
                while hasNumber(), let n = take(1) {
                    current = CGPoint(x: current.x, y: n[0])
                    path.addLine(to: current)
                }
            case "C":
                while hasNumber(), let n = take(6) {
                    let c1 = CGPoint(x: n[0], y: n[1])
                    let c2 = CGPoint(x: n[2], y: n[3])
                    current = CGPoint(x: n[4], y: n[5])
                    path.addCurve(to: current, control1: c1, control2: c2)
                }
            case "Q":
                while hasNumber(), let n = take(4) {
                    let c = CGPoint(x: n[0], y: n[1])
                    current = CGPoint(x: n[2], y: n[3])
                    path.addQuadCurve(to: current, control: c)
                }
            case "A":
                while hasNumber(), let n = take(7) {
                    let target = CGPoint(x: n[5], y: n[6])
                    addArc(&path, from: current, to: target, rx: n[0], ry: n[1],
                           rotationDegrees: n[2], largeArc: n[3] != 0, sweep: n[4] != 0)
                    current = target
                }
            case "Z":
                path.closeSubpath()
                current = start
            default:
                break
            }
        }
        return path
    }

    private enum Token {
        case command(Character)
        case number(CGFloat)
    }

    private static func tokenize(_ d: String) -> [Token] {
        var tokens: [Token] = []
        var index = d.startIndex
        while index < d.endIndex {
            let ch = d[index]
            if "MLHVCQAZ".contains(ch) {
                tokens.append(.command(ch))
                index = d.index(after: index)
            } else if ch == "-" || ch == "." || ch.isNumber {
                var end = d.index(after: index)
                var seenDot = ch == "."
                while end < d.endIndex {
                    let c = d[end]
                    if c.isNumber {
                        end = d.index(after: end)
                    } else if c == ".", !seenDot {
                        seenDot = true
                        end = d.index(after: end)
                    } else {
                        break
                    }
                }
                if let value = Double(d[index..<end]) {
                    tokens.append(.number(CGFloat(value)))
                }
                index = end
            } else {
                index = d.index(after: index)
            }
        }
        return tokens
    }

    /// SVG endpoint parameterization → center parameterization (W3C spec F.6.5),
    /// emitted as cubic segments.
    private static func addArc(
        _ path: inout Path, from p1: CGPoint, to p2: CGPoint,
        rx rxIn: CGFloat, ry ryIn: CGFloat,
        rotationDegrees: CGFloat, largeArc: Bool, sweep: Bool
    ) {
        var rx = abs(rxIn), ry = abs(ryIn)
        guard rx > 0, ry > 0, p1 != p2 else {
            path.addLine(to: p2)
            return
        }
        let phi = rotationDegrees * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)

        let dx = (p1.x - p2.x) / 2, dy = (p1.y - p2.y) / 2
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy

        // Scale radii up if they cannot span the endpoints.
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            let s = sqrt(lambda)
            rx *= s
            ry *= s
        }

        let rx2 = rx * rx, ry2 = ry * ry
        let num = rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p
        let den = rx2 * y1p * y1p + ry2 * x1p * x1p
        var factor = den == 0 ? 0 : sqrt(max(0, num / den))
        if largeArc == sweep { factor = -factor }

        let cxp = factor * (rx * y1p / ry)
        let cyp = factor * (-ry * x1p / rx)
        let cx = cosPhi * cxp - sinPhi * cyp + (p1.x + p2.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (p1.y + p2.y) / 2

        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let dot = ux * vx + uy * vy
            let len = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
            guard len > 0 else { return 0 }
            var a = acos(min(1, max(-1, dot / len)))
            if ux * vy - uy * vx < 0 { a = -a }
            return a
        }

        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep, delta > 0 { delta -= 2 * .pi }
        if sweep, delta < 0 { delta += 2 * .pi }

        let segments = max(1, Int(ceil(abs(delta) / (.pi / 2))))
        let step = delta / CGFloat(segments)
        var t = theta1

        func point(_ a: CGFloat) -> CGPoint {
            CGPoint(
                x: cx + rx * cos(a) * cosPhi - ry * sin(a) * sinPhi,
                y: cy + rx * cos(a) * sinPhi + ry * sin(a) * cosPhi
            )
        }
        func derivative(_ a: CGFloat) -> CGPoint {
            CGPoint(
                x: -rx * sin(a) * cosPhi - ry * cos(a) * sinPhi,
                y: -rx * sin(a) * sinPhi + ry * cos(a) * cosPhi
            )
        }

        for _ in 0..<segments {
            let t2 = t + step
            let alpha = (4.0 / 3.0) * tan(step / 4)
            let s = point(t), e = point(t2)
            let ds = derivative(t), de = derivative(t2)
            let c1 = CGPoint(x: s.x + alpha * ds.x, y: s.y + alpha * ds.y)
            let c2 = CGPoint(x: e.x - alpha * de.x, y: e.y - alpha * de.y)
            path.addCurve(to: e, control1: c1, control2: c2)
            t = t2
        }
    }
}

/// A SwiftUI Shape that renders SVG path data scaled from its viewBox into the
/// available rect.
struct SVGShape: Shape {
    let d: String
    let viewBox: CGSize

    init(_ d: String, viewBox: CGSize = CGSize(width: 20, height: 20)) {
        self.d = d
        self.viewBox = viewBox
    }

    func path(in rect: CGRect) -> Path {
        SVGPath.path(d).applying(
            CGAffineTransform(translationX: rect.minX, y: rect.minY)
                .scaledBy(x: rect.width / viewBox.width, y: rect.height / viewBox.height)
        )
    }
}

/// Stroked line icon in the design's style: 1.6px round-capped strokes on a
/// 20×20 viewBox, scaled to the given point size.
struct LineIcon: View {
    let d: String
    var size: CGFloat = 19
    var stroke: CGFloat = 1.6
    var color: Color

    var body: some View {
        SVGShape(d)
            .stroke(color, style: StrokeStyle(
                lineWidth: stroke * size / 20,
                lineCap: .round,
                lineJoin: .round
            ))
            .frame(width: size, height: size)
    }
}
