# iOS data and food-flow audit — 2026-09-06

## Scope

Reviewed the active SwiftUI screen stack (Today, Trends, Awards, Settings,
food picker, Quick Add, portion/manual/custom logging, calendar, reminders,
onboarding and paywall entry points), its SwiftData derivations, widget snapshot,
and FatSecret proxy contract. This is an iOS audit, not an Android parity or
App Store release certification.

## Implemented corrections

- One recommendation engine supplies Today, Quick Add and the food picker:
  favorites first, then log frequency, recency as a tie-breaker. Stable food IDs,
  serving labels and sodium snapshots are retained. Repeated manual logs merge
  with a matching saved favorite. Fresh accounts get catalog suggestions, not
  fabricated meal presets.
- The actual per-meal log is now rendered on Today. Repeat logging respects the
  selected date and does not mistake an ordinary portion label for a paid remote
  food. Portion logging uses the same snapshot constructor as Quick Add.
- Favorites created from manual recommendations are saved to the shelf so they
  remain resolvable. Quick-log favorite saving reuses matching shelf foods.
- Empty days are not counted as successful under-budget days. Averages use logged
  days; missing comparisons and missing-day chart values are shown as unavailable.
  Trend copy explains that unlogged meals are not included. Four-week summaries
  use the displayed four-week grid, not all dates since installation.
- Four-week day selection no longer silently clamps older dates to two weeks.
  Calendar dots distinguish logged days from days without entries.
- Historical streak milestones remain earned after a later gap. A new account no
  longer receives copy claiming the First Pinch badge is already earned.
- Main scroll surfaces are clipped away from the status area. Dock tab hit areas
  cover the entire button. Existing sheet/FAB stacking fixes are preserved.
- Custom budget copy describes the custom value rather than the 2,300 mg preset.
  Built-in food values are identified as estimates, not brand-specific measurements.
- Repeating notifications no longer freeze today's remaining sodium into future
  reminders. The settings preview matches the new notification copy.
- Widget snapshots carry their capture date and last logged day; stale consumption
  resets at a new day. The foreground app refreshes day-derived UI and widgets.
- CSV portion fields are escaped for decimal-comma locales. Unsafe numeric input
  no longer traps on floating-point-to-integer conversion.
- New main-screen copy includes German and Japanese translations. This does not
  certify every existing localization string or every device/text-size combination.

## FatSecret findings and verification

The installed iOS build had the correct proxy URL but an empty app proxy key,
which disabled online search. The existing app-scoped proxy key was provisioned
in a gitignored resource; OAuth credentials were not copied into the new config.

Live authenticated production requests returned HTTP 200 for idli, avocado and
McDonald's fries, including food details with serving-specific sodium. Simulator
UI checks also returned real idli and avocado results under FROM FATSECRET.
Saved/built-in matches are a separate section, after online results. Remote
logging still honors the existing Plus entitlement policy.

Search debouncing now isolates each query, clears stale results and protects
newer loading state from cancelled requests. Failures show a retry instead of
silently appearing to be local-only search. Missing sodium permits explicitly
explained manual entry; network failures no longer masquerade as missing nutrition.

Both parsers reject missing, negative, non-finite and unsafe sodium values while
allowing true zero sodium. The Vercel parser fix has six passing local Node tests.

## Release follow-up / verification limits

- **Production proxy deployment is still required** for the server-side parser
  hardening. Calling the current production API does not deploy local code.
- An unused legacy `FatSecretSecrets.plist` was found in the built app. It is now
  excluded from the target, and the rebuilt bundle contains only the app-scoped
  `PinchProxyConfig.plist`. If any distributed build contained real OAuth secrets,
  rotate the OAuth secret and update the server in a coordinated operation. This
  audit did not rotate production credentials or inspect every historical archive.
- Provision the ignored proxy configuration for clean CI/archive builds; see
  `vercel-proxy/README.md` and `PinchProxyConfig.sample.plist`.
- No production purchase was made. Paid calendar/widget behavior has code review
  and build coverage, not a physical-device purchase/end-to-end certification.
- No backend deployment, commit, push, or App Store submission was performed.
  Existing unrelated store-screenshot changes were preserved.

## Evidence

- iPhone 17 Pro simulator, iOS 26.3.1.
- Passing main-screen/live-search/favorites run:
  `/private/tmp/SodiumLiveScreensAudit3.xcresult` (2 UI tests).
- Screenshots: `/private/tmp/SodiumLiveScreensEvidence3/manifest.json`.
- Initial data regression run: `/private/tmp/SodiumDataAuditTests.xcresult`.
- Final expanded regression result: `/private/tmp/SodiumFinalDataAudit2.xcresult`
  — **93 passed, 0 failed, 0 skipped** (88 unit tests and 5 UI tests).
- Final screenshots: `/private/tmp/SodiumFinalAuditEvidence/manifest.json`.
- Backend contract: **6 passed, 0 failed** using `node --test test/proxy.test.mjs`.
- `git diff --check` passes; the app proxy config is confirmed gitignored and
  the legacy OAuth resource is absent from the rebuilt simulator app bundle.
