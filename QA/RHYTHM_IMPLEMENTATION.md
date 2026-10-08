# Your rhythm — iOS implementation

Implemented 8 September 2026. The existing Awards route and automation identifier remain intact; its visible tab label is now Rhythm.

## Behavior

- A persistent, user-editable weekly logging goal of 3, 4 or 5 days (default 3). Days need not be consecutive. Changing the logging goal does not change the sodium target.
- Calendar-based local weeks, distinct logging days, and future-entry exclusion. The screen refreshes its time-dependent calculations every minute.
- Next-step suggestions require at least two actual logs of the same canonical food during the current week. Favorites and missing food references are excluded. Empty/insufficient history never receives a stock-food recommendation on this screen.
- Saving uses the same `FoodFavoriteStore` path as the portion sheet. Remote/manual foods retain an offline record. Existing premium access and shelf-capacity rules remain enforced. Repeated saves are idempotent.
- Food logging opens the existing, fresh-search Add Food sheet. No second logging workflow was introduced.
- Returning users receive nonjudgmental copy after a gap of at least three calendar days.
- The six milestones remain accessible in a scrollable collection. Historical streak awards remain earned after a streak breaks. The current-streak-based next-award banner was removed.
- Cool Cucumber now recognizes five distinct logging days, irrespective of sodium amount. Existing intake-rule award dates are captured once and preserved. A partially logged day is never represented as a successful intake target.
- No network requests, fabricated diary entries, ratings, health scores, or medical-outcome promises were introduced.

## Localization

33 new strings translated; 8 retired strings removed. App and widget bundles contain identical catalogs with 541 keys for each of 14 languages: en, de, ja, fr, nl, it, es, sv, zh-Hans, ms, ta, ga, mi, rm.

Exact key, nonempty-value and placeholder validation passes. Translations are not native-speaker certified. User/provider food names stay verbatim.

## Verification

- 118 unit tests passed, including eight new Rhythm test groups and the search-session regression tests.
- Simulator: iPhone 17 Pro, dedicated Pinch Localization QA device.
- UI checks cover all 14 languages (main screen, goal editor, collection), goal persistence across relaunch, and closing/reopening food search.
- A Release device build succeeds with signing disabled. This is a compilation check, not an archive or upload.
- Final verification: **TEST SUCCEEDED** in `/private/tmp/PinchRhythmFinal.xcresult`: 118 unit tests and 2 UI tests passed. The language UI test covers 42 screen/sheet states and verifies that every collection close button is tappable and dismisses its sheet.
- Final Release compilation including the header fix: **BUILD SUCCEEDED**, log `/private/tmp/PinchRhythmReleaseVerified.log`.

The first test build exposed a Swift Testing key-path macro issue, corrected in the test. Early UI runs required waiting for keyboard dismissal and scrolling the collection above the floating dock. Visual QA corrected the collection background clipping and long-title close-button layout.

## Release boundary

No App Store metadata, submitted version, uploaded build, pricing or subscription configuration was changed. These changes require a new archive and a build number higher than the already uploaded build 7. Android is unchanged.
