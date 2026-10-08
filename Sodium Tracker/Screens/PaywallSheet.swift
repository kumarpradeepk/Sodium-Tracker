import SwiftUI
import StoreKit

/// Store-provided prices and eligibility are authoritative; artwork is illustrative.
struct PaywallSheet: View {
    @Environment(UIState.self) private var ui
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.openURL) private var openURL
    @AppStorage(NotificationManager.trialReminderPreference) private var remindMe = false
    private let ink = Color(red: 0.098, green: 0.176, blue: 0.275)
    private let blue = Color(red: 0.18, green: 0.345, blue: 0.682)
    private let gold = Color(red: 0.937, green: 0.682, blue: 0.208)
    private let paper = Color(red: 0.961, green: 0.965, blue: 0.98)
    private var trial: Bool { ui.plan == .yearly && subscriptions.isEligibleForYearlyTrial }
    private var price: String { subscriptions.product(for: ui.plan)?.displayPrice ?? "—" }
    private var cadence: String { ui.plan == .yearly ? "year" : "month" }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PinchText("PINCH PLUS").font(.system(size: 11, weight: .bold)).tracking(1.5)
                    .accessibilityLabel(PinchLocalization.resolve("Pinch Plus"))
                Spacer()
                Button { ui.payOpen = false } label: {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                        .frame(width: 32, height: 32).background(ink.opacity(0.06), in: Circle())
                }.accessibilityLabel(PinchLocalization.resolve("Close paywall")).frame(width: 44, height: 44)
            }.foregroundStyle(ink.opacity(0.6)).padding(.horizontal, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    PinchText(trial ? "Try Plus free for 3 days" : "Make tracking easier with Plus")
                        .font(.system(size: 27, weight: .heavy, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    PinchText(trial
                         ? "See your whole month of salt, not just today. No payment now."
                         : PinchLocalization.format("See your whole month of salt, not just today. Billed {0}. Cancel anytime.", [PinchLocalization.resolve(ui.plan == .yearly ? "annually" : "monthly")]))
                        .font(.system(size: 14)).foregroundStyle(ink.opacity(0.75))
                    chart
                    if trial { timeline } else { benefits }
                    if let error = subscriptions.errorMessage {
                        PinchText(error).font(.footnote).foregroundStyle(.red)
                            .accessibilityIdentifier("paywall.error")
                    }
                }.padding(.horizontal, 20).padding(.bottom, 18)
                footer
            }.scrollIndicators(.hidden)
        }
        .foregroundStyle(ink).background(paper.ignoresSafeArea())
        .task { ui.plan = .yearly; await subscriptions.prepare() }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PinchText("EXAMPLE · 4-WEEK VIEW")
                Spacer()
                PinchText("MG SODIUM").foregroundStyle(gold)
            }.font(.system(size: 10, weight: .bold))
            ZStack(alignment: .trailing) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array([29,40,33,39,49,29,38,41,44,34,29,37,53,31,26,41,38,35,45,32,39,50,36,27,42,39,34,37].enumerated()), id: \.offset) { item in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.offset < 7 ? gold : Color.white.opacity(0.16))
                            .frame(height: CGFloat(item.element))
                    }
                }.frame(height: 55, alignment: .bottom)
                Label(PinchLocalization.resolve("Weeks 2–4 with Plus"), systemImage: "lock.fill")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(ink)
                    .padding(9).background(.white, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.trailing, 12)
            }.accessibilityHidden(true)
            PinchText("See patterns across your logged days.")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color.white.opacity(0.7)).padding(14)
        .background(ink, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            step("checkmark", title: "Today — everything unlocks", detail: "Four-week trends, salt calendar, food search, CSV export, the widget.", color: blue)
            step("2", title: "Stay in control", detail: "Manage or cancel in Apple subscription settings.", color: gold)
            step("3", title: PinchLocalization.format("After 3 days — {0}/year", [String(describing: price)]), detail: "Auto-renews unless canceled at least 24 hours before the trial ends. Keep the free tracker if you cancel.", color: ink.opacity(0.5))
            Divider()
            Toggle(PinchLocalization.resolve("Remind me before the trial ends"), isOn: Binding(get: { remindMe }, set: { enabled in
                if !enabled { remindMe = false; return }
                ui.notificationPrompt = NotificationPrompt(context: .trial)
            }))
            .font(.system(size: 13, weight: .semibold)).tint(blue)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private func step(_ icon: String, title: String, detail: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if icon == "checkmark" { Image(systemName: icon) } else { PinchText(icon) }
            }.font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                .frame(width: 26, height: 26).background(color, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                PinchText(title).font(.system(size: 14, weight: .bold))
                PinchText(detail).font(.system(size: 13)).foregroundStyle(ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            PinchText("Everything in Plus").font(.system(size: 16, weight: .bold))
            ForEach(["Four-week trends and salt calendar", "FatSecret food search and logging", "Unlimited custom shelf foods", "CSV export and Home Screen widget"], id: \.self) { benefit in
                Label(PinchLocalization.resolve(benefit), systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14)).foregroundStyle(ink)
            }
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                plan(.yearly, title: "Yearly")
                plan(.monthly, title: "Monthly")
            }.padding(.top, 10)
            Button(action: purchase) {
                VStack(spacing: 3) {
                    PinchText(cta).font(.system(size: 17, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    if !subscriptions.isPremium, subscriptions.product(for: ui.plan) != nil {
                        PinchText(trial ? PinchLocalization.format("then {0}/year · auto-renews · cancel anytime", [String(describing: price)]) : PinchLocalization.format("billed today · auto-renews {0}", [PinchLocalization.resolve(ui.plan == .yearly ? "annually" : "monthly")]))
                            .font(.system(size: 11))
                    }
                }.multilineTextAlignment(.center).padding(.horizontal, 12)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .foregroundStyle(.white).background(blue, in: RoundedRectangle(cornerRadius: 17))
            }
            .disabled(subscriptions.isPurchasing || (!subscriptions.isPremium && subscriptions.product(for: ui.plan) == nil))
            .opacity(subscriptions.product(for: ui.plan) == nil && !subscriptions.isPremium ? 0.6 : 1)
            .accessibilityIdentifier("paywall.purchase")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { legalActions }
                VStack(spacing: 0) { legalActions }
            }.font(.system(size: 12)).foregroundStyle(ink.opacity(0.75))
            PinchText(trial ? "No charge today. Cancel at least 24 hours before your trial ends to avoid renewal." : "Charged to your Apple Account. Cancel at least 24 hours before renewal in Apple subscription settings.")
                .font(.system(size: 10)).foregroundStyle(ink.opacity(0.7)).multilineTextAlignment(.center)
        }.padding(.horizontal, 20).padding(.bottom, 8).background(paper)
    }

    @ViewBuilder private var legalActions: some View {
        Button { Task { await subscriptions.restore() } } label: {
            PinchText("Restore").fixedSize().frame(minWidth: 44, minHeight: 44)
        }.disabled(subscriptions.isPurchasing).accessibilityIdentifier("paywall.restore")
        Link(destination: URL(string: "https://tinkersmithstudio.com/pinch/privacy.html")!) {
            PinchText("Privacy Policy").fixedSize().frame(minHeight: 44)
        }.accessibilityIdentifier("paywall.privacy")
        Link(destination: URL(string: "https://tinkersmithstudio.com/pinch/terms.html")!) {
            PinchText("Terms of Use").fixedSize().frame(minHeight: 44)
        }.accessibilityIdentifier("paywall.terms")
    }

    private func plan(_ value: PlusPlan, title: String) -> some View {
        let selected = ui.plan == value
        let product = subscriptions.product(for: value)
        return Button { ui.plan = value } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(selected ? blue : ink.opacity(0.25))
                    PinchText(title).font(.system(size: 13, weight: .bold))
                }
                // Keep the StoreKit price intact; a long cadence may move below it.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(verbatim: product?.displayPrice ?? "—").font(.system(size: 19, weight: .heavy)).fixedSize()
                        PinchText(value == .yearly ? "/year" : "/month").font(.system(size: 11)).fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: product?.displayPrice ?? "—").font(.system(size: 19, weight: .heavy))
                            .minimumScaleFactor(0.7).lineLimit(1)
                        PinchText(value == .yearly ? "/year" : "/month").font(.system(size: 11))
                    }
                }
                PinchText(value == .yearly ? annualEquivalent : "Cancel anytime")
                    .font(.system(size: 10)).foregroundStyle(ink.opacity(0.65))
            }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(selected ? blue : ink.opacity(0.12), lineWidth: selected ? 2 : 1))
                .overlay(alignment: .top) {
                    if value == .yearly, let savings {
                        PinchText(PinchLocalization.format("SAVE {0}%", [String(describing: savings)])).font(.system(size: 9, weight: .heavy))
                            .padding(.vertical, 4).frame(maxWidth: .infinity)
                            .background(gold, in: RoundedRectangle(cornerRadius: 6))
                            .padding(.horizontal, 10).offset(y: -10)
                    }
                }
        }.buttonStyle(.plain).disabled(subscriptions.isPurchasing)
            .accessibilityLabel(PinchLocalization.resolve(title))
            .accessibilityValue(PinchLocalization.format("{0} per {1}", [product?.displayPrice ?? PinchLocalization.resolve("Price unavailable"), PinchLocalization.resolve(value == .yearly ? "year" : "month")]))
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier(value == .yearly ? "paywall.yearly" : "paywall.monthly")
    }

    private var annualEquivalent: String {
        guard let product = subscriptions.product(for: .yearly) else { return "Price unavailable" }
        return PinchLocalization.format("{0}/mo · billed annually", [String(describing: (product.price / 12).formatted(product.priceFormatStyle))])
    }
    private var savings: Int? {
        guard let annual = subscriptions.product(for: .yearly), let monthly = subscriptions.product(for: .monthly),
              annual.priceFormatStyle.currencyCode == monthly.priceFormatStyle.currencyCode, monthly.price > 0 else { return nil }
        let amount = NSDecimalNumber(decimal: (1 - annual.price / (monthly.price * 12)) * 100).doubleValue
        return amount > 0 ? Int(amount.rounded()) : nil
    }
    private var cta: String {
        if subscriptions.isPremium { return "Manage subscription" }
        if subscriptions.isPurchasing { return "Working…" }
        if subscriptions.isLoading { return "Loading plans…" }
        if subscriptions.product(for: ui.plan) == nil { return "Plans unavailable" }
        return trial ? "Start my 3 free days" : PinchLocalization.format("Subscribe for {0}/{1}", [String(describing: price), PinchLocalization.resolve(cadence)])
    }
    private func purchase() {
        if subscriptions.isPremium {
            openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
            return
        }
        Task {
            if await subscriptions.purchase(ui.plan) {
                ui.payOpen = false
                ui.showToast("Pinch Plus is active", "Your premium tools are unlocked.")
            }
        }
    }
}
