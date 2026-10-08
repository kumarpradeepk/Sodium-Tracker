# iOS app localization rollout — in progress

Scope: app screens, paywall, notifications, accessibility, widget and regional formatting only. No store listing or preview changes.

Requested languages: English, German, Japanese, French, Dutch, Italian, Spanish, Swedish, Simplified Chinese, Malay, Tamil, Irish, Māori and Romansh.

## Implemented

- Shared bundled-copy resolver for app and widget; translates templates before interpolating values.
- Routed paywall text, native controls and accessibility strings through localization.
- In-app language selection, separate from region formatting; language preference shared with widgets.
- Localized date/time templates and weekday headings.
- Translated built-in food display and search; custom/provider names remain verbatim.
- Notification language refresh preserves the original trial reminder date.
- Scrollable paywall footer and wrapping tab labels for longer copy.
- Source inventory, placeholder validation and app/widget parity checks.

## Not complete — do not release as fully localized

The reviewed source inventory contains 511 keys. Bundles currently contain English plus partial German (209 keys) and Japanese (190 keys), including migrated existing translations and additional manually translated templates. Other catalogs have not been generated. The language picker hides languages without any bundled catalog.

The complete-coverage test intentionally fails until all requested translations exist. No screenshot previews or store assets were edited for this task.

External draft translation was blocked by automatic security review: the full unpublished UI catalog requires explicit approval before sending to Google Translate. The user has been asked for this approval; it has not yet been received. Do not re-run translate-copy.mjs until approved. Only UI strings may be sent, never credentials, user data or other source code. Romansh is not supported by the tested Google endpoint and needs separate local translation work. Linguistic review remains necessary, especially for medical disclaimers and subscription terms.

## Verification

- App and widget builds succeeded during infrastructure work; later changes compiled in the simulator test build.
- Three localization infrastructure tests passed on the dedicated iPhone 17 Pro simulator (iOS 26.3.1).
- Result: /private/tmp/PinchLocalizationInfrastructureTests3.xcresult
- Simulator: Pinch Localization QA, 38B8E6A9-9875-4E78-8A43-76DAF075B465.
- Full translation coverage / every-language UI checks are pending, not passed.
- Run `node LocalizationTools/validate-catalogs.mjs` for the explicit missing-key report.

Preserve the existing dirty worktree and store-preview work. No commit, push, store submission or pricing changes were made in this task.
