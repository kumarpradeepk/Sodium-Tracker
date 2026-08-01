//
//  SharedComponents.swift
//  Sodium Tracker
//
//  Small reusable pieces of the Pinch design language: cards, kickers,
//  switches, segmented controls, radio cards, CTAs, sheet scaffolding.
//

import SwiftUI

// MARK: - Press feedback

/// Scale-down press feedback used on nearly every button in the design.
struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressScaleStyle {
    static var pressScale: PressScaleStyle { PressScaleStyle() }
    static func pressScale(_ scale: CGFloat) -> PressScaleStyle { PressScaleStyle(scale: scale) }
}

// MARK: - Card

/// Standard Pinch card: card bg, hairline border, radius 18 (20 for large).
struct PinchCard<Content: View>: View {
    @Environment(\.pinch) private var p
    var radius: CGFloat = 18
    var padding: EdgeInsets?
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding ?? EdgeInsets())
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(p.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(p.line, lineWidth: 1)
            )
    }
}

// MARK: - Section kicker

/// "USUAL SUSPECTS"-style section label.
struct SectionKicker: View {
    @Environment(\.pinch) private var p
    let text: String

    var body: some View {
        Text(text)
            .pinchKicker()
            .foregroundStyle(p.ink3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
    }
}

// MARK: - Stat card

/// Small stat card: big Bricolage number + caption.
struct StatCard: View {
    @Environment(\.pinch) private var p
    let value: String
    let caption: String
    var valueColor: Color?
    var valueSize: CGFloat = 22

    var body: some View {
        PinchCard(padding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(PinchFonts.display(valueSize, .bold))
                    .monospacedDigit()
                    .foregroundStyle(valueColor ?? p.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(caption)
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Switch

/// The design's 46×28 switch: brand track when on, sunk when off.
struct PinchSwitch: View {
    @Environment(\.pinch) private var p
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isOn ? p.brand : p.sunk)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(p.line, lineWidth: 1)
                    )
                Circle()
                    .fill(p.knob)
                    .shadow(color: .black.opacity(0.28), radius: 1.5, y: 1)
                    .frame(width: 22, height: 22)
                    .padding(2)
            }
            .frame(width: 46, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

// MARK: - Segmented control

struct PinchSegment<Value: Hashable>: Identifiable {
    let value: Value
    let label: String
    var id: Value { value }
}

/// Sunken segmented control: sunk track (radius 12, 3px padding), active
/// segment is a card-bg pill (radius 10) with a small shadow.
struct PinchSegmented<Value: Hashable>: View {
    @Environment(\.pinch) private var p
    let segments: [PinchSegment<Value>]
    @Binding var selection: Value
    var bordered = true
    var fontSize: CGFloat = 12.5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(segments) { segment in
                let active = segment.value == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = segment.value }
                } label: {
                    Text(segment.label)
                        .pinchBody(fontSize, .semibold)
                        .foregroundStyle(active ? p.ink : p.ink3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(active ? p.card : .clear)
                                .shadow(
                                    color: active ? p.segShadow.color : .clear,
                                    radius: p.segShadow.radius,
                                    y: p.segShadow.y
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.sunk)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(bordered ? p.line : .clear, lineWidth: 1)
        )
    }
}

// MARK: - Radio card

/// Selectable card with a radio dot (onboarding, goal picker, plans).
struct RadioCard<Content: View>: View {
    @Environment(\.pinch) private var p
    let selected: Bool
    let action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .strokeBorder(selected ? p.brand : p.grain, lineWidth: selected ? 6 : 2)
                    .background(Circle().fill(p.card))
                    .frame(width: 18, height: 18)
                content
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? p.brandSoft : p.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? p.brand : p.line, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: selected)
    }
}

// MARK: - CTA button

/// Full-width primary CTA: brand pill with the colored glow shadow.
struct PinchCTA: View {
    @Environment(\.pinch) private var p
    let title: String
    var height: CGFloat = 54
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .pinchBody(height >= 54 ? 16 : 15.5, .bold)
                .foregroundStyle(p.onBrand)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Capsule().fill(p.brand))
                .shadow(color: p.brand.opacity(0.55), radius: 11, y: 6)
                .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(.pressScale(0.98))
    }
}

// MARK: - Round icon buttons

/// 30px round × close button on sheets.
struct SheetCloseButton: View {
    @Environment(\.pinch) private var p
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("×")
                .font(.system(size: 16))
                .foregroundStyle(p.ink2)
                .frame(width: 30, height: 30)
                .background(Circle().fill(p.sunk))
        }
        .buttonStyle(.pressScale)
        .accessibilityLabel("Close")
    }
}

/// Small circled chevron (day/week navigation).
struct ChevronButton: View {
    @Environment(\.pinch) private var p
    let direction: Edge
    var enabled = true
    var filled = true
    var size: CGFloat = 30
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SVGShape(direction == .leading ? "M7 1 L1 7 L7 13" : "M1 1 L7 7 L1 13",
                     viewBox: CGSize(width: 8, height: 14))
                .stroke(p.ink2, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 7, height: 12)
                .frame(width: size, height: size)
                .background(
                    Circle().fill(filled ? p.chip : .clear)
                )
                .overlay(
                    Circle().strokeBorder(filled ? p.line : .clear, lineWidth: 1)
                )
                .opacity(enabled ? 1 : 0.25)
        }
        .buttonStyle(.pressScale(0.92))
        .disabled(!enabled)
    }
}

// MARK: - Food icon tile

/// 34px chip-bg tile with the category's line icon.
struct FoodIconTile: View {
    @Environment(\.pinch) private var p
    let category: FoodCategory

    var body: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(p.chip)
            .frame(width: 34, height: 34)
            .overlay(LineIcon(d: category.iconPath, size: 19, color: p.ink2))
    }
}

// MARK: - Sunken text field

/// Labelled input on a sunk tile (Quick log / New food forms).
struct SunkField: View {
    @Environment(\.pinch) private var p
    let label: String
    let placeholder: String
    @Binding var text: String
    var numeric = false
    var labelColor: Color?
    var highlighted = false
    var focused: FocusState<Bool>.Binding?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .pinchBody(10, .bold, tracking: 0.1)
                .foregroundStyle(labelColor ?? p.ink3)
            Group {
                if let focused {
                    TextField("", text: $text, prompt: prompt)
                        .focused(focused)
                } else {
                    TextField("", text: $text, prompt: prompt)
                }
            }
            .pinchBody(15, numeric ? .bold : .semibold)
            .foregroundStyle(p.ink)
            .monospacedDigit()
            .keyboardType(numeric ? .numberPad : .default)
            .onChange(of: text) { _, newValue in
                if numeric {
                    let filtered = newValue.filter(\.isNumber)
                    if filtered != newValue { text = filtered }
                }
            }
        }
        .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.sunk)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(highlighted ? p.brandSoft : .clear, lineWidth: 1.5)
        )
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(p.ink.opacity(0.38))
    }
}

// MARK: - Sheet scaffold

/// Bottom sheet in the design's style: scrim, top radius 26, grab handle,
/// slide-up entrance.
struct PinchSheet<Content: View>: View {
    @Environment(\.pinch) private var p
    var topInset: CGFloat?      // nil → hugs content at the bottom
    let onClose: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            p.scrim
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                Capsule()
                    .fill(p.grain)
                    .frame(width: 38, height: 5)
                    .padding(.top, 9)
                content
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: topInset == nil ? nil : .infinity, alignment: .top)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 26,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 26,
                    style: .continuous
                )
                .fill(p.bg)
                .ignoresSafeArea(edges: .bottom)
            )
            .pinchCardShadow(p)
            .padding(.top, topInset ?? 0)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

/// Header row inside a sheet: Bricolage title + round close button.
struct SheetHeader: View {
    @Environment(\.pinch) private var p
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(PinchFonts.display(22, .bold))
                .foregroundStyle(p.ink)
            Spacer()
            SheetCloseButton(action: onClose)
        }
    }
}
