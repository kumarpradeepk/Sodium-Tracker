//
//  StatusPill.swift
//  Sodium Tracker
//

import SwiftUI

/// Small colored badge summarizing where the day stands.
struct StatusPill: View {
    let status: IntakeStatus

    var body: some View {
        Label(status.label, systemImage: status.symbol)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(status.tint.opacity(0.14), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusPill(status: .onTrack)
        StatusPill(status: .closeToLimit)
        StatusPill(status: .overLimit)
    }
    .padding()
}
