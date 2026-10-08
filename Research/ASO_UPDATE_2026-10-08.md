# App Store ASO update — iOS 1.4 draft

**Superseded later on 8 October 2026:** the user requested a comprehensive update across all 17 locales. The subtitle experiment below was reverted to “Salt Counter & Intake”; keyword fields, description openings and release notes were revised across all locales. The final saved state, raw research and API verification are in [the comprehensive update](aso-improvements-2026-10-08/README.md). This file records the earlier experiment rather than the current draft.

Checked and saved 2026-10-08 for Sodium Tracker: Pinch Daily, App Store ID 6800595930, iPhone.

## Current search evidence

Fresh Astro MCP `search_app_store` snapshots returned these app positions (the search tool checks Apple storefront results; position is not a search-volume estimate):

| Query | Storefront | Pinch position |
|---|---|---:|
| sodium tracker | US | 8 / 50 |
| salt tracker | US | 18 / 50 |
| salt counter | US | Not in first 20 |
| sodium intake | US | 17 / 50 |
| sodium calculator | US | 13 / 50 |
| salt tracker | Canada | Not in first 20 |
| salt tracker | United Kingdom | Not in first 20 |
| salt tracker | Australia | 39 / 50 |
| sodium tracker | India | 6 / 50 |
| sodium tracker | Japan | 13 / 50 |
| natrium tracker | Germany | 5 / 19 |
| suivi sodium | France | 4 / 17 |
| natrium tracker | Netherlands | 1 / 10 |

The leading US results for “sodium tracker” included Sodium Tracker: Sodio (1,616 ratings) and My Dash Diet: Sodium Tracker (1,871 ratings). Pinch showed zero ratings in the same Astro search response. Counts and positions are a single storefront snapshot and can move; they do not prove why an app ranks where it does. Apple says ratings and reviews influence search ranking, alongside metadata and other factors: https://developer.apple.com/app-store/product-page/.

Astro's separate tracked-keyword data for US reported “sodium tracker” at 93 on the same date while its direct search result returned Pinch at 8. These are different Astro data paths; direct search results were used for the position table, and the discrepancy remains unresolved. Popularity was not returned for the queries above, so no search-volume claims are made.

## Draft change

Only the editable 1.4 draft was changed. App Store Connect returned version 1.4 as `PREPARE_FOR_SUBMISSION`; versions 1.0–1.3 remained `READY_FOR_SALE`.

| Locale | Before subtitle | Draft subtitle |
|---|---|---|
| en-US | Salt Counter & Intake | Salt Tracker & Intake |
| en-GB | Salt Counter & Intake | Salt Tracker & Intake |
| en-AU | Salt Counter & Intake | Salt Tracker & Intake |
| en-CA | Daily Salt Counter & Intake | Daily Salt Tracker & Intake |

The four matching keyword fields changed `habits` to `counter`; all other keyword tokens were preserved:

`food,diary,nutrition,meal,log,milligrams,budget,reminder,low,diet,counter,calculator,converter`

The keyword field is 94 UTF-8 bytes. Names remain “Sodium Tracker: Pinch Daily.” No description, promotional text, screenshot, price, territory, build, submission, or release field was changed. The change keeps “salt” and “intake” in the subtitle, adds “tracker” to the subtitle, and retains “counter” through the keyword field. This is an evidence-based metadata experiment, not a guaranteed ranking improvement.

## Validation and sources

- API read-back verified all eight changed fields in version 1.4. App name, subtitle, and keywords match the intended values.
- Subtitle values are 21 characters (en-US/en-GB/en-AU) and 27 characters (en-CA); both are below Apple's 30-character limit.
- Keyword fields are 94 UTF-8 bytes and 94 characters. Apple describes keywords as a 100-character field and advises relevant, nonduplicative terms: https://developer.apple.com/app-store/product-page/.
- Storefront ranking data: Astro MCP `search_app_store`, iPhone, queries and storefronts recorded above, checked 2026-10-08. These are observed result positions, not private competitor keywords or search-volume measurements.
- User-facing copy remains feature-aligned: sodium and salt logging, daily goals, meal tracking, and salt/sodium conversion are verified in the app listing and repository research. No blood-pressure, DASH-plan, AI-scan, or medical-outcome terms were added.

## Uncertainty and next measure

Apple Search results can vary over time, by storefront, device, account and personalization. This change is not submitted or live. After the user submits version 1.4 and it is released, compare US/CA/UK/AU search positions for “salt tracker,” “salt counter,” and “sodium tracker,” and compare App Store Connect search impressions and downloads. Do not attribute any movement to this edit alone without accounting for downloads, ratings, and other concurrent changes.
