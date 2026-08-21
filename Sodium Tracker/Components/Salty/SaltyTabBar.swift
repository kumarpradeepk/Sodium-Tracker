//
//  SaltyTabBar.swift
//  Sodium Tracker
//
//  The design's bottom bar: four tabs in a 1fr 1fr 84 1fr 1fr grid around a
//  66pt FAB that hangs 30pt above the bar. Icons are drawn from the design's
//  26-unit viewBox paths.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §11.1
//

import SwiftUI

struct SaltyTabBar: View {
    @Environment(\.salty) private var s
    @Binding var tab: PinchTab
    let sheetOpen: Bool
    let onFab: () -> Void

    /// Drives the 1 → 1.22 → 1 pop when a tab becomes active.
    @State private var popping: PinchTab?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            tabItem(.today, "Today")
            tabItem(.trends, "Trends")
            fab
            tabItem(.awards, "Awards")
            tabItem(.settings, "Settings")
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .background(alignment: .top) {
            ZStack(alignment: .top) {
                Rectangle().fill(s.tabBarBg).background(.ultraThinMaterial)
                Rectangle().fill(s.tabBarLine).frame(height: 1)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Tabs

    private func tabItem(_ target: PinchTab, _ label: String) -> some View {
        let active = tab == target
        let color = active ? s.blue : s.tabInactive
        return Button {
            guard tab != target else { return }
            tab = target
            popping = target
        } label: {
            VStack(spacing: 3) {
                SaltyTabIcon(tab: target, active: active)
                    .frame(width: 26, height: 26)
                    .foregroundStyle(color)
                    .scaleEffect(popping == target ? 1.22 : 1)
                    .animation(.timingCurve(0.3, 1.5, 0.4, 1, duration: 0.32), value: popping)
                PinchText(label)
                    .salty(12.5, .bold)
                    .foregroundStyle(color)
            }
            .padding(.top, 4)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.saltyPress(opacity: 0.6))
        .accessibilityAddTraits(active ? [.isSelected] : [])
        .onChange(of: popping) { _, new in
            guard new == target else { return }
            // Return to rest so the pop can fire again next time.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                if popping == target { popping = nil }
            }
        }
    }

    // MARK: - FAB

    private var fab: some View {
        Button(action: onFab) {
            SaltyPlusIcon()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
                .frame(width: 26, height: 26)
                .rotationEffect(.degrees(sheetOpen ? 45 : 0))
                .animation(.timingCurve(0.3, 1.5, 0.4, 1, duration: 0.3), value: sheetOpen)
                .frame(width: 66, height: 66)
                .background(Circle().fill(s.blue))
                .shadow(color: s.blue.opacity(0.38), radius: 10, y: 8)
        }
        .buttonStyle(.saltyPress(scale: 0.88))
        .frame(width: 84)
        .offset(y: -30)
        // The FAB overhangs the bar; keep its slot from adding height.
        .frame(height: 44, alignment: .top)
        .accessibilityLabel("Quick add")
    }
}

// MARK: - Icons (design's 26-unit viewBox)

private struct SaltyTabIcon: View {
    let tab: PinchTab
    let active: Bool

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / 26
            ZStack {
                switch tab {
                case .today:
                    Circle()
                        .strokeBorder(Color.primary, lineWidth: 2.2 * k)
                        .frame(width: 18 * k, height: 18 * k)
                    // Filled half-disc: M13 4 A 9 9 0 0 1 13 22 Z
                    Path { p in
                        p.move(to: CGPoint(x: 13 * k, y: 4 * k))
                        p.addArc(center: CGPoint(x: 13 * k, y: 13 * k), radius: 9 * k,
                                 startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                        p.closeSubpath()
                    }
                    .fill(Color.primary)
                case .trends:
                    Path { p in
                        p.addRoundedRect(in: CGRect(x: 5 * k, y: 13 * k, width: 4 * k, height: 8 * k), cornerSize: CGSize(width: 2 * k, height: 2 * k))
                        p.addRoundedRect(in: CGRect(x: 11 * k, y: 8 * k, width: 4 * k, height: 13 * k), cornerSize: CGSize(width: 2 * k, height: 2 * k))
                        p.addRoundedRect(in: CGRect(x: 17 * k, y: 4 * k, width: 4 * k, height: 17 * k), cornerSize: CGSize(width: 2 * k, height: 2 * k))
                    }
                    .fill(Color.primary)
                case .awards:
                    Circle()
                        .strokeBorder(Color.primary, lineWidth: 2.2 * k)
                        .frame(width: 12 * k, height: 12 * k)
                        .position(x: 13 * k, y: 10 * k)
                    Path { p in
                        p.move(to: CGPoint(x: 9.5 * k, y: 15 * k))
                        p.addLine(to: CGPoint(x: 7.5 * k, y: 22 * k))
                        p.addLine(to: CGPoint(x: 13 * k, y: 19.2 * k))
                        p.addLine(to: CGPoint(x: 18.5 * k, y: 22 * k))
                        p.addLine(to: CGPoint(x: 16.5 * k, y: 15 * k))
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.2 * k, lineJoin: .round))
                case .settings:
                    Path { p in
                        p.move(to: CGPoint(x: 4 * k, y: 9 * k)); p.addLine(to: CGPoint(x: 22 * k, y: 9 * k))
                        p.move(to: CGPoint(x: 4 * k, y: 18 * k)); p.addLine(to: CGPoint(x: 22 * k, y: 18 * k))
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.2 * k, lineCap: .round))
                    Circle().fill(Color.primary)
                        .frame(width: 6.8 * k, height: 6.8 * k)
                        .position(x: 16 * k, y: 9 * k)
                    Circle().fill(Color.primary)
                        .frame(width: 6.8 * k, height: 6.8 * k)
                        .position(x: 9 * k, y: 18 * k)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// The FAB's plus: `M13 3.5 V22.5 M3.5 13 H22.5` in a 26 viewBox.
struct SaltyPlusIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let k = rect.width / 26
        return Path { p in
            p.move(to: CGPoint(x: 13 * k, y: 3.5 * k))
            p.addLine(to: CGPoint(x: 13 * k, y: 22.5 * k))
            p.move(to: CGPoint(x: 3.5 * k, y: 13 * k))
            p.addLine(to: CGPoint(x: 22.5 * k, y: 13 * k))
        }
    }
}

// MARK: - Press styles (spec §5, §11)

struct SaltyPressStyle: ButtonStyle {
    var scale: CGFloat = 1
    var opacity: Double = 1
    var duration: Double = 0.15
    var curve: (Double, Double, Double, Double)?

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .scaleEffect(pressed ? scale : 1)
            .opacity(pressed ? opacity : 1)
            .animation(
                curve.map { .timingCurve($0.0, $0.1, $0.2, $0.3, duration: duration) }
                    ?? .easeOut(duration: duration),
                value: pressed
            )
    }
}

extension ButtonStyle where Self == SaltyPressStyle {
    /// Press feedback with the design's scale/opacity and optional bouncy curve.
    static func saltyPress(
        scale: CGFloat = 1,
        opacity: Double = 1,
        duration: Double = 0.15,
        curve: (Double, Double, Double, Double)? = nil
    ) -> SaltyPressStyle {
        SaltyPressStyle(scale: scale, opacity: opacity, duration: duration, curve: curve)
    }
}
