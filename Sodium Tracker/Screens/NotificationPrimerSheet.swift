import SwiftUI
import UserNotifications
import UIKit

struct NotificationPrimerSheet: View {
    @Environment(\.pinch) private var p
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    let prompt: NotificationPrompt
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var busy = true
    @State private var error: String?
    @State private var openedSettings = false

    private var isTrial: Bool { prompt.context == .trial }
    private var denied: Bool { status == .denied }
    private var authorized: Bool { status == .authorized || status == .provisional || status == .ephemeral }
    private var title: String {
        if isTrial { return "A heads-up before your trial ends" }
        switch prompt.context {
        case .firstLog: return "One less thing to remember"
        case .routine: return "A small pause for your day"
        case .history: return "Keep the little details"
        case .restart: return "Come back when you’re ready"
        default: return "Build a rhythm that fits"
        }
    }
    private var detail: String {
        if isTrial { return "If you start an eligible trial, Pinch can send a reminder before it ends. You still control your subscription in Apple Settings." }
        switch prompt.context {
        case .firstLog: return "You have enough on your mind. A gentle meal check-in can help you log while the details are still fresh."
        case .routine: return "Busy days move quickly. A quiet reminder gives you a moment to log your meal, then get back to your day."
        case .history: return "Small details are easy to forget. Logging near mealtime keeps your food diary easier to look back on."
        case .restart: return "Your diary doesn’t have to be perfect. A small reminder can help you pick up where you left off, at your own pace."
        default: return "Start with a meal that suits you. Choose your check-ins in Settings and change them as life changes."
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    graphic.foregroundStyle(p.ink).accessibilityHidden(true)
                    PinchText(title).pinchDisplay(28, .bold).foregroundStyle(p.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 66, alignment: .topLeading)
                        .accessibilityIdentifier("notification-primer.title")
                    PinchText(detail).pinchBody(15).foregroundStyle(p.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 58, alignment: .topLeading)
                    if denied {
                        PinchText("Notifications are off in iOS. You can change this in Settings; the app works either way.")
                            .pinchBody(12).foregroundStyle(p.ink2)
                    } else if !authorized {
                        PinchText("Next, iOS will let you choose whether to allow notifications.")
                            .pinchBody(12).foregroundStyle(p.ink2)
                    }
                    if let error { PinchText(error).pinchBody(12).foregroundStyle(p.coral) }
                }.padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 12)
            }.scrollBounceBehavior(.basedOnSize)

            // Actions stay visible at the compact detent, even with long copy.
            VStack(spacing: 4) {
                PinchCTA(title: busy ? "Checking…" : (denied ? "Open Settings" : (authorized ? "Enable reminders" : "Continue")), enabled: !busy) {
                    Task { await continueTapped() }
                }.accessibilityIdentifier("notification-primer.continue")
                Button { dismiss() } label: {
                    PinchText("Not now").pinchBody(14, .semibold)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.foregroundStyle(p.ink2).accessibilityIdentifier("notification-primer.not-now")
                PinchText("Optional. You can always change this in Settings.")
                    .pinchBody(11).foregroundStyle(p.ink3).multilineTextAlignment(.center)
            }.padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 16)
                .background(p.bg)
        }.background(p.bg)
            .task { await readStatus() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, openedSettings else { return }
                Task {
                    await readStatus()
                    if await NotificationManager.isAuthorized() { completePermission(); dismiss() }
                }
            }
    }

    // One stable visual system for all five invitations; only the copy changes.
    private var graphic: some View {
        HStack(spacing: 16) {
            PinchMascot(variant: .party, width: 42)
                .frame(width: 56, height: 72)
            VStack(alignment: .leading, spacing: 8) {
                Label(PinchLocalization.resolve("PINCH · EXAMPLE"), systemImage: isTrial ? "clock" : "bell")
                    .pinchBody(10, .bold).foregroundStyle(p.brand)
                PinchText(isTrial ? "Your Pinch Plus trial" : "A moment to log your meal?")
                    .pinchBody(15, .semibold).foregroundStyle(p.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(p.brandSoft, in: RoundedRectangle(cornerRadius: 22))
    }
    private func readStatus() async {
        status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        busy = false
    }
    private func continueTapped() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        // Keep the action disabled during both status lookup and the OS prompt.
        status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        // Consent to a trial heads-up must not silently enable meal check-ins.
        if isTrial && !authorized { UserDefaults.standard.set(false, forKey: PinchDefaults.notif) }
        if denied {
            openedSettings = true
            openURL(URL(string: UIApplication.openSettingsURLString)!)
            return
        }
        if authorized {
            completePermission()
        } else if await NotificationManager.requestPermissionAfterExplanation() {
            completePermission()
        }
        dismiss()
    }
    private func completePermission() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: NotificationPromptPolicy.optOutKey)
        if isTrial { defaults.set(true, forKey: NotificationManager.trialReminderPreference) }
        else {
            defaults.set(true, forKey: PinchDefaults.notif)
            NotificationManager.refresh(remaining: 0)
        }
    }
}
