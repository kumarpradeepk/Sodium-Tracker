# Release preflight — 1.1 (5)

The user requested the latest uploaded build and submission for release after the localized listing update.

## Completed

- Latest uploaded build: `28289b00-9699-4b05-b7eb-ea0f7b05e7d5`, version 1.1, build 5, uploaded 2026-09-06 16:50 UTC.
- Apple reports VALID, APP_STORE_ELIGIBLE, not expired.
- Attached this build to draft version `1f016dcd-1be3-451c-b89a-9c08a242288f` and independently read back the relationship.
- Matched the build ID to the successful distribution record in the local archive at `/Users/pradeep.kumar1/Library/Developer/Xcode/Archives/2026-09-06/Sodium Tracker 06-09-26, 10.15 PM.xcarchive`.
- Privacy and terms URLs both returned HTTP 200.
- Food backend health returned OK. Using the actual bundled proxy configuration, a food-search request returned HTTP 200 and a result; the detail request returned HTTP 200 with sodium data. No credentials were printed or saved in the audit.

## Submission paused: binary localization is incomplete

The archive Info.plist declares 14 languages: en, de, ja, fr, nl, it, es, sv, zh-Hans, ms, ta, ga, mi, rm.

Its bundled PinchStrings.json contains only:

| Catalog | Entries | Missing English keys |
| --- | ---: | ---: |
| English | 511 | 0 |
| German | 209 | 302 |
| Japanese | 190 | 321 |

The other 11 declared language catalogs are absent. This does not meet the user's earlier requirement for complete in-app localization. Store metadata localization does not repair a binary's missing translations. Fixing the archive requires a new build; the latest existing build cannot be edited in place.

The selected build remains in the draft; no new review submission was created and no release action was taken. The existing release setting is AFTER_APPROVAL, unchanged. Pending user direction on completing translations and replacing the build before submission.

## Other preparation still needed before a submission attempt

- Build 5's usesNonExemptEncryption is unset. Complete export compliance based on the actual app's encryption use; no declaration was guessed or submitted.
- New 1.1 release notes are not yet filled in the 17 locales.
- Copied review notes still describe build 4 and its previous rejection response. They must be updated for the selected release; no stale build-4 claims were sent to Apple in a new submission.
- The uploaded user-supplied screenshots have localized headlines but English app UI and have not been certified to match every screen of this archive.
- Price/trial/paywall alignment remains separate outstanding release work documented in PAYWALL_ROLLOUT_STATUS.md; it was not modified during the listing update.

The 85 screenshots and localized listing text remain safely saved and verified in draft 1.1. Live 1.0 was unchanged by the listing update.
