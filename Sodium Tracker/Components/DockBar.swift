//
//  DockBar.swift
//  Sodium Tracker
//
//  The floating dock: blurred pill 26px from the bottom, four tabs around a
//  56px brand + FAB. Icons are the design's line glyphs.
//

import SwiftUI

struct DockBar: View {
    @Environment(\.pinch) private var p
    @Binding var tab: PinchTab
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            tabButton(.today, label: "Today") { color in
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [30, 16]))
                        .frame(width: 14.4, height: 14.4)
                        .rotationEffect(.degrees(-90))
                    Circle().fill(color).frame(width: 4.4, height: 4.4)
                }
                .frame(width: 21, height: 21)
            }

            tabButton(.trends, label: "Trends") { color in
                SVGShape("M4 16.5 V11 M10 16.5 V4.5 M16 16.5 V8")
                    .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .frame(width: 21, height: 21)
            }

            Button(action: onAdd) {
                SVGShape("M10 3.5 V16.5 M3.5 10 H16.5")
                    .stroke(p.onBrand, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .frame(width: 22, height: 22)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(p.brand))
                    .shadow(color: p.brand.opacity(0.55), radius: 11, y: 6)
            }
            .buttonStyle(.pressScale(0.92))
            .padding(.horizontal, 6)
            .accessibilityLabel("Log a food")

            tabButton(.awards, label: "Awards") { color in
                ZStack {
                    SVGShape("M10 3.2 A4.8 4.8 0 1 0 10 12.8 A4.8 4.8 0 1 0 10 3.2")
                        .stroke(color, lineWidth: 1.8)
                    SVGShape("M7.2 11.8 L6 17.5 L10 15 L14 17.5 L12.8 11.8")
                        .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                }
                .frame(width: 21, height: 21)
            }

            tabButton(.settings, label: "Settings") { color in
                // Two slider rails with offset knobs (design's settings glyph).
                ZStack {
                    SVGShape("M3 6.5 H17 M3 13.5 H17")
                        .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    Circle().fill(p.bg)
                        .frame(width: 4.8, height: 4.8)
                        .overlay(Circle().stroke(color, lineWidth: 1.8))
                        .offset(x: 2.6, y: -3.7)
                    Circle().fill(p.bg)
                        .frame(width: 4.8, height: 4.8)
                        .overlay(Circle().stroke(color, lineWidth: 1.8))
                        .offset(x: -2.6, y: 3.7)
                }
                .frame(width: 21, height: 21)
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
            VStack(spacing: 3) {
                icon(color)
                Text(label)
                    .pinchBody(9.5, .bold)
                    .foregroundStyle(color)
            }
            .frame(width: 58)
            .padding(.vertical, 5)
        }
        .buttonStyle(.pressScale(0.94))
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }
}
