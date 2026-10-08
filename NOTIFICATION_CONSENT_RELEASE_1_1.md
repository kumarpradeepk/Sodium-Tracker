# Notification consent and version 1.1 release fix

## Validation fix

Apple rejected the old archive because marketing version 1.0 is already approved and closed to new submissions. The application and embedded widget now both use marketing version 1.1 and build 5. Added a shared Sodium Tracker scheme for app builds, tests and archives; retained the existing widget scheme.

Final archive: `/private/tmp/Pinch-1.1-5-final.xcarchive`. A fresh archive is required; the existing 1.0 archive cannot be repaired by changing project settings afterwards. Archive creation is not an App Store upload, validation acceptance or review submission. Existing paywall/store rollout gates in `PAYWALL_ROLLOUT_STATUS.md` remain unresolved.

## Permission behavior

- Scheduling only reads permission; it never asks for authorization.
- The system prompt is reachable only from Continue in `NotificationPrimerSheet`.
- Five deterministic copy variants share the same illustrated reminder card and layout: remembering, busy days, food-diary details, personal routine, and starting again. Trial reminders retain a dedicated explanation within the same visual system.
- The first automatic invitation appears after onboarding completes (including Skip the tour), with no food log required. Existing users with no invitation history are eligible on launch too. It waits for the active app and a clear screen; no system permission request occurs until Continue.
- Subsequent invitations appear only while the app is active, at least 24 hours apart, using different copy. No notification is sent to solicit notification permission.
- Limit: five automatic invitations. Not now/swipe dismissal starts the cooldown. The sheet does not show Don't ask again. Previously saved opt-outs and turning meal check-ins off in Settings remain respected; explicit Settings requests remain available.
- Manual Settings/trial explanations do not consume the five automatic variants. The same sheet is recorded only once, including a return from iOS Settings.
- The compact sheet keeps Continue and Not now in a fixed action area; longer content scrolls and the sheet can expand.
- Authorized users are not re-prompted automatically. Denied users see Open Settings, not a repeated iOS permission alert.
- Settings and Nudges display actual system authorization as well as the app's preference.
- Opting into a trial heads-up while notifications were off does not silently enable meal notifications.
- No invented health outcomes or guaranteed notification delivery; graphics that resemble data are labeled illustrative.

## Current verification — five-copy design, 6 September 2026

- 9 targeted tests passed: 8 permission-policy tests and a fresh-install UI journey on iPhone 17 Pro / iOS 26.3.1.
- Verified onboarding completion without a food log, no automatic Apple permission alert, all five distinct messages with stable headline/button positions, no Don't ask again button, persisted 24-hour cooldown, invitation cap, existing opt-out, explicit Continue → Apple prompt, and denied → Open Settings.
- Results: `/private/tmp/PinchNotificationFiveCopyFinal.xcresult`.
- Eight actual simulator captures: `QA/NotificationConsentFiveCopy/` (see the export manifest for named scenarios).
- English source inventory and the app/widget runtime catalogs match. This does not claim the pending full translation rollout is complete.
- These source changes require a new device/release build. They are not in the older archive above and have not been uploaded or submitted to App Store Connect in this task.

## Earlier verification (before the launch-trigger correction)

- 95 tests passed: all 94 unit tests plus the four-variant notification UI test on iPhone 17 Pro / iOS 26.3.1.
- Results: `/private/tmp/PinchNotificationFinalAudit.xcresult`.
- Screenshots: `/private/tmp/PinchNotificationVerifiedScreens`.
- Release archive built successfully; app and widget version/build inspected.
- Existing unrelated compiler warnings remain (asset icon slots and older actor/text APIs).
- Live App Store validation, physical-device permission/Settings round-trip and real delayed notification delivery are not claimed as tested.

Design follows Apple's contextual permission guidance: https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
