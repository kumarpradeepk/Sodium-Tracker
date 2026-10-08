//
//  QuickAddSheet.swift
//  Sodium Tracker
//
//  The FAB's QUICK ADD sheet: three shortcut rows that spring up from the FAB.
//  A fourth row reaches the full log sheet, which the design's FAB no longer
//  opens (spec §15.2).
//
//  The sheet sizes to its content and stays inset from the screen edges; rows
//  report their position through a preference rather than a GeometryReader, so
//  measuring never stretches them to fill the width.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §11.2
//

import SwiftUI

struct SaltyQuickAddSheet: View {
    @Environment(\.salty) private var s
    let items: [QuickAddItem]
    let onPick: (QuickAddItem, CGPoint) -> Void
    let onFullLog: () -> Void

    @State private var rowFrames: [String: CGRect] = [:]

    var body: some View {
        VStack(spacing: 8) {
            PinchText("QUICK ADD")
                .salty(11.5, .heavy, tracking: 0.13)
                // On the scrim, not on the screen — ink3 disappears into it.
                .foregroundStyle(.white.opacity(0.92))
                .padding(.bottom, 2)

            ForEach(items) { item in
                row(item)
            }

            // Extension: keeps search / scanner / custom foods reachable.
            sheetRow {
                onFullLog()
            } content: {
                HStack(spacing: 18) {
                    PinchText("Log a food…")
                        .salty(16, .heavy)
                        .foregroundStyle(s.blue)
                    Spacer(minLength: 0)
                    SaltyPlusIcon()
                        .stroke(s.blue, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 260)
        .padding(.horizontal, 20)
        .onPreferenceChange(QuickRowFrameKey.self) { rowFrames = $0 }
    }

    private func row(_ item: QuickAddItem) -> some View {
        sheetRow {
            let frame = rowFrames[item.id] ?? .zero
            onPick(item, CGPoint(x: frame.midX, y: frame.midY))
        } content: {
            HStack(spacing: 18) {
                PinchText(item.name)
                    .salty(16, .heavy)
                    .foregroundStyle(s.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
                PinchText(PinchLocalization.format("+{0} mg", [String(describing: PinchFormat.mg(item.mg))]))
                    .saltyNum(15, .heavy)
                    .foregroundStyle(s.blue)
            }
        }
        .background(GeometryReader { g in
            Color.clear.preference(key: QuickRowFrameKey.self, value: [item.id: g.frame(in: .global)])
        })
        .accessibilityLabel(PinchLocalization.format("Quick add {0}, {1} milligrams", [String(describing: item.name), String(describing: item.mg)]))
    }

    /// One sheet row: opaque card, comfortable hit area, springy press.
    private func sheetRow<Content: View>(
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: action) {
            content()
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(s.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(s.ink.opacity(s.isDark ? 0.14 : 0.05), lineWidth: 1)
                )
                .saltySheetShadow(s)
        }
        .buttonStyle(.saltyPress(scale: 0.95))
    }
}

/// Row frames by item id, so a fly pill launches from the tapped row.
private struct QuickRowFrameKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
