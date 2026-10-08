# Sodium Tracker 1.3 (9) — submitted

Apple confirmed **WAITING_FOR_REVIEW** for both version 1.3 and its review submission at 2026-09-09T10:53:44.649308+00:00. The release uses **AFTER_APPROVAL**, matching version 1.2: Apple will release it automatically after approval. It is not yet approved or live.

The previous uploaded build, 1.2 (8), was already released. A fresh 1.3 (9) archive was built from the current working tree, distribution-signed, uploaded, processed as VALID and selected. App and widget version/build numbers were verified. Version numbers were supplied as Xcode build-setting overrides; the project file remains at 1.2 (8), and no app source files were edited during this task.

All **17 promotional texts** and **17 release notes** match version 1.2 exactly. Names, subtitles, descriptions and URLs were preserved. The standalone `dash` token was removed from the ten intended keyword fields; the other seven keyword fields were preserved. All **86 screenshots** retain their content and order, across 17 localizations, and are processed. There are no app previews. Pricing was preserved.

The unit suite passed **118 tests**. Four UI checks passed initially: onboarding/navigation, live FatSecret search, manual logging and paywall legal links. The fifth, favorites synchronization, failed at its initial menu interaction and then passed unchanged on a focused rerun against the same compiled app. Startup timing is suspected; that cause was not proven. The original run therefore remains recorded as 122 passed and 1 failed, with the separate successful rerun retained. No real-money purchase was performed.

Offline metadata validation has **zero hard errors** and 156 review advisories about inferred keyword demand and language-sensitive tokenization. Exact API read-back was verified after submission. These checks do not constitute App Review approval.

[Verification summary](</Users/pradeep.kumar1/Indie/iOS/Sodium Tracker/Sodium Tracker/Research/appstore-release-1.3-2026-09-09/verification-summary.json>) contains identifiers, per-locale promotional-text hashes and test counts. [Apple submission response](</Users/pradeep.kumar1/Indie/iOS/Sodium Tracker/Sodium Tracker/Research/appstore-release-1.3-2026-09-09/apple-review-submission.json>) records the confirmed review state. [Metadata read-back](</Users/pradeep.kumar1/Indie/iOS/Sodium Tracker/Sodium Tracker/Research/appstore-release-1.3-2026-09-09/metadata-readback.json>) contains the saved listing text.

The signed archive, IPA, detailed Xcode results and raw API evidence are under `/private/tmp/sodium-release-2026-09-09`. No App Store Connect private-key contents were copied into the repository.
