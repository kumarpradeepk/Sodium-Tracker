//
//  ToastView.swift
//  Sodium Tracker
//
//  Top-of-screen toast with the smiling mini Pinch. Slides down, auto-dismisses
//  after ~2.8 s (the timer resets on rapid adds).
//

import SwiftUI

struct ToastView: View {
    @Environment(\.pinch) private var p
    let toast: PinchToast

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            PinchMascot(variant: .toastMini, width: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(toast.title)
                    .pinchBody(13.5, .bold)
                    .foregroundStyle(p.ink)
                    .lineLimit(1)
                Text(toast.sub)
                    .pinchBody(12)
                    .foregroundStyle(p.ink2)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 11, leading: 14, bottom: 11, trailing: 14))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(p.line, lineWidth: 1)
        )
        .pinchCardShadow(p)
        .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.96)))
        .allowsHitTesting(false)
    }
}
