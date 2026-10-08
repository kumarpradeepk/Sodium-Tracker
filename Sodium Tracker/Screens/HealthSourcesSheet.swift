//
//  HealthSourcesSheet.swift
//  Sodium Tracker
//
//  In-app context and citations for sodium guidance shown in Pinch.
//

import SwiftUI

struct HealthSourcesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pinch) private var p

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        PinchText("SOURCES & HEALTH INFORMATION")
                            .pinchKicker()
                            .foregroundStyle(p.ink3)
                        PinchText("How Pinch uses sodium guidance")
                            .pinchDisplay(28, .bold)
                            .foregroundStyle(p.ink)
                    }

                    PinchCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
                        VStack(alignment: .leading, spacing: 8) {
                            PinchText("Pinch is an informational wellness tracker, not medical advice or a medical device.")
                                .pinchBody(14, .bold)
                                .foregroundStyle(p.ink)
                            PinchText("It helps you record sodium values and compare them with a target you choose. It does not diagnose, treat, prevent, or manage any condition. A clinician or dietitian should help determine a personal sodium target.")
                                .pinchBody(12.5)
                                .foregroundStyle(p.ink2)
                                .lineSpacing(3)
                        }
                    }

                    section("WHAT THE NUMBERS MEAN") {
                        PinchText("Pinch may show 1,500 mg and 2,300 mg as general educational examples. These are not a recommendation for your individual health needs. Your needs can differ because of a condition, medication, pregnancy, activity, heat exposure, or a clinician-directed plan.")
                            .pinchBody(12.5)
                            .foregroundStyle(p.ink2)
                            .lineSpacing(3)
                    }

                    section("SOURCES") {
                        VStack(spacing: 10) {
                            source(
                                title: "World Health Organization",
                                detail: "Guideline: Sodium intake for adults and children",
                                url: "https://iris.who.int/bitstream/handle/10665/77985/9789241504836_eng.pdf"
                            )
                            source(
                                title: "American Heart Association",
                                detail: "How Much Sodium Should I Eat Per Day?",
                                url: "https://www.heart.org/en/healthy-living/healthy-eating/eat-smart/sodium/how-much-sodium-should-i-eat-per-day"
                            )
                            source(
                                title: "U.S. Food and Drug Administration",
                                detail: "Sodium in Your Diet",
                                url: "https://www.fda.gov/food/nutrition-facts-label/sodium-your-diet"
                            )
                        }
                    }

                    section("FOOD VALUES") {
                        PinchText("Food values are estimates based on labels and available nutrition data. Brands, recipes, portions, and preparation vary. Check the current package label and serving size before relying on a value.")
                            .pinchBody(12.5)
                            .foregroundStyle(p.ink2)
                            .lineSpacing(3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(p.bg)
            .navigationTitle(PinchLocalization.resolve("Sources"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(PinchLocalization.resolve("Close")) { dismiss() }
                        .foregroundStyle(p.brand)
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PinchText(title)
                .pinchKicker()
                .foregroundStyle(p.ink3)
            content()
        }
    }

    private func source(title: String, detail: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(alignment: .top, spacing: 12) {
                SettingsIconTile(color: SettingsTileColors.chatter, glyph: .heart)
                VStack(alignment: .leading, spacing: 3) {
                    PinchText(title)
                        .pinchBody(13.5, .bold)
                        .foregroundStyle(p.ink)
                    PinchText(detail)
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                        .lineSpacing(2)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(p.brand)
            }
            .padding(EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14))
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
