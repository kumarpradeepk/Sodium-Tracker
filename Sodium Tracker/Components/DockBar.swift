//
//  DockBar.swift
//  Sodium Tracker
//
//  The floating dock: blurred pill 26px from the bottom, four tabs around a
//  64px brand + FAB. v2 sizing: 64pt tabs, 24pt icons, 11pt/800 labels.
//

import SwiftUI

struct DockBar: View {
    @Environment(\.pinch) private var p
    @Binding var tab: PinchTab
    let onAdd: () -> Void

    // v2 icon geometry: 20-unit viewBox rendered at 24pt.
    private let iconScale: CGFloat = 24 / 20

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            tabButton(.today, label: "Today") { color in
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(color, style: StrokeStyle(
                            lineWidth: 2.1 * iconScale,
                            lineCap: .round,
                            dash: [30, 16]
                        ))
                        .frame(width: 14.4 * iconScale, height: 14.4 * iconScale)
                        .rotationEffect(.degrees(-90))
                    Circle().fill(color)
                        .frame(width: 4.4 * iconScale, height: 4.4 * iconScale)
                }
                .frame(width: 24, height: 24)
            }

            tabButton(.trends, label: "Trends") { color in
                SVGShape("M4 16.5 V11 M10 16.5 V4.5 M16 16.5 V8")
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5 * iconScale, lineCap: .round))
                    .frame(width: 24, height: 24)
            }

            Button(action: onAdd) {
                SVGShape("M10 3.5 V16.5 M3.5 10 H16.5")
                    .stroke(p.onBrand, style: StrokeStyle(lineWidth: 2.6 * 25 / 20, lineCap: .round))
                    .frame(width: 25, height: 25)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(p.brand))
                    .shadow(color: p.brand.opacity(0.55), radius: 11, y: 6)
            }
            .buttonStyle(.pressScale(0.92))
            .padding(.horizontal, 6)
            .accessibilityLabel("Log a food")

            tabButton(.awards, label: "Awards") { color in
                ZStack {
                    SVGShape("M10 3.2 A4.8 4.8 0 1 0 10 12.8 A4.8 4.8 0 1 0 10 3.2")
                        .stroke(color, lineWidth: 2.1 * iconScale)
                    SVGShape("M7.2 11.8 L6 17.5 L10 15 L14 17.5 L12.8 11.8")
                        .stroke(color, style: StrokeStyle(
                            lineWidth: 2.1 * iconScale,
                            lineCap: .round,
                            lineJoin: .round
                        ))
                }
                .frame(width: 24, height: 24)
            }

            tabButton(.settings, label: "Settings") { color in
                // Two slider rails with offset knobs (design's settings glyph).
                ZStack {
                    SVGShape("M3 6.5 H17 M3 13.5 H17")
                        .stroke(color, style: StrokeStyle(lineWidth: 2.1 * iconScale, lineCap: .round))
                    Circle().fill(p.bg)
                        .frame(width: 4.6 * iconScale, height: 4.6 * iconScale)
                        .overlay(Circle().stroke(color, lineWidth: 2.1 * iconScale))
                        .offset(x: 2.5 * iconScale, y: -3.5 * iconScale)
                    Circle().fill(p.bg)
                        .frame(width: 4.6 * iconScale, height: 4.6 * iconScale)
                        .overlay(Circle().stroke(color, lineWidth: 2.1 * iconScale))
                        .offset(x: -2.5 * iconScale, y: 3.5 * iconScale)
                }
                .frame(width: 24, height: 24)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .background(
            Capsule().fill(p.dock)
                .background(.ultraThinMaterial, in: Capsule())
        )
        .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
        .pinchCardShadow(p)
    }

    private func tabButton<Icon: View>(
        _ target: PinchTab,
        label: String,
        @ViewBuilder icon: @escaping (Color) -> Icon
    ) -> some View {
        let active = tab == target
        let color = active ? p.brand : p.ink3
        return Button {
            withAnimation(.easeOut(duration: 0.35)) { tab = target }
        } label: {
            VStack(spacing: 4) {
                icon(color)
                Text(label)
                    .pinchBody(11, .heavy, tracking: 0.01)
                    .foregroundStyle(color)
            }
            .frame(width: 64)
            .padding(.vertical, 6)
        }
        .buttonStyle(.pressScale(0.94))
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }
}
