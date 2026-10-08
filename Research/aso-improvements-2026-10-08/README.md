# Sodium Tracker ASO improvements — saved and verified

**Date:** 8 October 2026. **App:** Sodium Tracker: Pinch Daily. **App Store ID:** 6800595930. **Destination:** editable iOS 1.4, `PREPARE_FOR_SUBMISSION`.

All 17 existing App Store listing locales were updated through the store-metadata API client. There were 21 resource updates and 55 changed field values: 17 keyword fields, 17 description openings, 17 release-note fields, and four English subtitles. Every changed field was verified by a fresh GET. Live 1.3 attributes were compared before and after and are identical. Version 1.4 has no build attached and was not submitted.

## Strategy and exact outcome

The English name remains **Sodium Tracker: Pinch Daily**. All four English subtitles now read **Salt Counter & Intake**. This restores complementary “counter” coverage after the earlier subtitle experiment repeated “tracker,” which was already in the name. Canada also drops a second “Daily,” already present in the name. The old keyword `counter` is consequently removed from the keyword slot.

English keywords now cover food diary/journal, meal logging, sodium goals, salt/sodium unit entry, low-sodium diet tracking and conversion. The singular `milligram` matches the returned US/UK Astro suggestion; `gram`, `goal` and `journal` are feature-aligned additions with inferred demand. Calculator/converter remain relevant provisional terms; US “sodium calculator” currently returns Pinch at 13, but its search volume was not obtained.

In other locales, relevant native logging/nutrition/low-salt terms remain. English “sodium tracker” coverage was added through keyword components where a localized name/subtitle does not already cover it. The English query returned relevant niche apps in each represented storefront. This supports query relevance, not the claim that it has high local search volume. German/Dutch names already contain “Tracker,” so their keyword fields avoid repeating it; French names already contain “Sodium,” so only “tracker” is added there.

Descriptions now open with the concrete task: daily sodium logging, sodium in milligrams or salt in grams, and a self-chosen goal. The existing feature lists, Plus boundaries, medical caveats, FatSecret attribution, legal links and promotional text were preserved. Description work targets clarity and conversion; it is not keyword stuffing or a claimed indexing boost.

Hindi and Telugu descriptions explicitly disclose that the app interface is not currently available in those languages and can fall back to another supported language or English. Listing translation is not presented as UI translation. The reused release notes claiming a new 14-language rollout were replaced with localized, factual notes about the App Store information update.

## Final keyword fields

| Locale | UTF-8 bytes | Saved keywords |
|---|---:|---|
| de-DE | 87 | `sodium,salzarm,ernährung,lebensmittel,tagebuch,mahlzeit,salzaufnahme,rechner,umrechner` |
| en-AU | 96 | `food,diary,nutrition,meal,log,milligram,gram,goal,reminder,low,diet,journal,calculator,converter` |
| en-CA | 96 | `food,diary,nutrition,meal,log,milligram,gram,goal,reminder,low,diet,journal,calculator,converter` |
| en-GB | 96 | `food,diary,nutrition,meal,log,milligram,gram,goal,reminder,low,diet,journal,calculator,converter` |
| en-US | 96 | `food,diary,nutrition,meal,log,milligram,gram,goal,reminder,low,diet,journal,calculator,converter` |
| es-ES | 91 | `dieta,baja,alimentos,comidas,nutrición,ingesta,calculadora,consumo,contador,sodium,tracker` |
| fr-CA | 88 | `journal,alimentaire,repas,apport,nutrition,régime,pauvre,tracker,calculateur,conversion` |
| fr-FR | 88 | `journal,alimentaire,repas,apport,nutrition,régime,pauvre,tracker,calculateur,conversion` |
| hi | 87 | `भोजन,पोषण,मिलीग्राम,ट्रैकर,sodium,tracker` |
| it | 84 | `sale,alimentare,pasti,apporto,nutrizione,registro,calcolatore,consumo,sodium,tracker` |
| ja | 73 | `食事,日記,栄養,食塩,摂取量,食品,計算,換算,sodium,tracker` |
| ms | 97 | `makanan,pemakanan,diari,hidangan,pengambilan,diet,rendah,kalkulator,penukaran,sodium,tracker,salt` |
| nl-NL | 77 | `zoutarm,dieet,zoutinname,dagboek,maaltijd,voeding,calculator,omrekenen,sodium` |
| sv | 81 | `saltintag,kost,måltid,näring,logg,saltfattig,räknare,omvandling,sodium,tracker` |
| ta-IN | 89 | `உணவு,ஊட்டச்சத்து,டிராக்கர்,sodium,tracker` |
| te-IN | 65 | `ఆహారం,పోషణ,ట్రాకర్,sodium,tracker` |
| zh-Hans | 76 | `减盐,低钠,食物,营养,食盐,摄取量,换算,计算器,sodium,tracker` |

All fields fit both the 100-byte and 100-character keyword limits. Unused bytes are deliberate; weak or unsupported terms were not added to fill space. All names and subtitles fit 30 characters.

## Current observed searches

Research covered 34 selected queries across 14 represented storefronts, including the Indian English/Hindi/Tamil/Telugu probes. Four requests initially hit Astro’s 30-request/minute rate limit and were retried successfully. Raw responses and the effective summary are saved. This is not a rank audit of every App Store country; 17 listing locales cannot create a separate language listing for every territory.

| Storefront | Query | Returned Pinch position | Search result count |
|---|---|---:|---:|
| us | sodium tracker | 8 | 50 |
| us | salt tracker | 18 | 50 |
| us | sodium calculator | 13 | 50 |
| gb | sodium tracker | 17 | 50 |
| gb | salt tracker | 50 | 50 |
| ca | sodium tracker | 10 | 50 |
| ca | suivi sodium | 32 | 50 |
| au | sodium tracker | 9 | 50 |
| au | salt tracker | 42 | 50 |
| de | natrium tracker | 5 | 19 |
| de | sodium tracker | 16 | 50 |
| fr | suivi sodium | 4 | 17 |
| fr | sodium tracker | 16 | 50 |
| es | control de sodio | 1 | 9 |
| es | sodium tracker | 5 | 50 |
| it | dieta iposodica | 1 | 3 |
| it | sodium tracker | 18 | 50 |
| nl | natrium tracker | 1 | 10 |
| nl | sodium tracker | 3 | 50 |
| se | saltintag | 1 | 2 |
| se | sodium tracker | 15 | 50 |
| jp | 塩分記録 | 25 | 50 |
| jp | sodium tracker | 13 | 50 |
| jp | ナトリウム | 3 | 36 |
| cn | 低钠 | No position returned | 50 |
| cn | 钠摄入 | 10 | 18 |
| cn | sodium tracker | 22 | 50 |
| my | jejak natrium | 1 | 1 |
| my | sodium tracker | 20 | 50 |
| in | sodium tracker | 6 | 50 |
| in | salt tracker | 17 | 50 |
| in | नमक ट्रैकर | 1 | 3 |
| in | உப்பு | No position returned | 0 |
| in | సోడియం | No position returned | 0 |

The #1 positions for several local phrases have very small result sets. For example, Malay “jejak natrium” returned one result, Swedish “saltintag” two, and Italian “dieta iposodica” three. Chinese “低钠” primarily returned unrelated apps; it is not a reliable demand or ranking signal. Tamil/Telugu probes returned no results, which does not prove there is no audience for the localized app.

## Competitors, demand and uncertainty

For the fresh US “sodium tracker” query, Sodium Tracker: Sodio (ID 1590169479) led at #1 with 1,616 ratings; My Dash Diet: Sodium Tracker (ID 1032110739) was #2 with 1,871. Their visible name/subtitle coverage already resembles Pinch’s core “Sodium Tracker” and “Salt Counter” wording. Their private keyword fields are unavailable; none is claimed to have been obtained. Pinch showed zero US ratings in the same direct-search response.

Astro’s tracked US “sodium tracker” position still says 93 while direct search returns 8. These are different data paths and the discrepancy remains unresolved. The October 6 audit’s direct position was 50; this movement cannot be attributed to the new draft changes, which are not live. Saved ranks and direct results are treated as dated observations.

Astro’s suggestions returned very little relevant measured coverage. Its popularity scores are Apple Ads-derived proxies according to its documentation; difficulty is proprietary. Neither is a monthly search count. “milligram” has a US popularity score of 10/difficulty 11 and UK 9/7. Canada and Australia adapt that unit term without a locally measured popularity claim. High-scoring AI/scan, POTS, blood-pressure, meal-planning, kidney-diet and competitor-brand concepts were rejected because the implemented product does not establish those capabilities or a medical program. Native synonyms and other retained keywords are explicitly marked inferred in metadata-proposed.json.

## Verification

- Offline validator: zero hard errors; 169 review advisories. Exit code 2 means advisories remain, not a failed size/schema/read-back check. Most advisories concern inferred demand; CJK short words and Indic token fragmentation were reviewed rather than auto-deleted. The flagged Indic entries do not duplicate complete literal name/subtitle tokens.
- API: all 55 requested field values verified by GET; all unrelated attributes preserved.
- App identity, platform and editable version checked before writing; field-value conflicts would stop the update.
- Live 1.3 version and app-information fields preserved by before/after comparison.
- Promotional text and public URLs preserved; names unchanged.
- No app code, image assets, prices, country availability, build selection or submission changed. No functional app tests were claimed.
- Model translation was reviewed for consistency and feature meaning, but no independent native-speaker review was performed.

## Remaining work that metadata cannot finish

1. **Release gate:** supply/test/select the intended 1.4 build before submission. A metadata draft cannot affect live discovery. No build is attached. These release notes describe metadata changes and should be revised if the future build introduces other user-facing changes.
2. **Public website trust gap:** the homepage still has an “app store — soon” placeholder; its support page falsely says there is no subscription and no restore/cancel flow. Current privacy and terms pages correctly describe Plus/RevenueCat. Fix the homepage and support copy before sending users there. See [public website findings and copy-ready corrections](public-website-findings.md).
3. **Ratings and conversion:** no StoreKit review-request call was found in the current app Swift source. A separate product task can add a neutral Apple review prompt after successful repeated logging, without incentives or gating. This is outside the metadata-only edit. Ratings/downloads affect ranking; metadata cannot create them.
4. **Measure actual results:** the API returned zero existing analyticsReportRequests; that does not mean App Analytics has no data. Search-source impressions, product-page views, downloads, conversion and territory metrics were not available through an existing API report. Use those metrics alongside rankings after release, separating Apple Ads traffic and other concurrent changes.
5. **Native screenshots and UI:** the October 6 audit identified translated screenshot headlines over English UI. Recapture matching supported-language UI after the intended build is available. Hindi/Telugu need actual UI implementation and QA before being advertised as supported languages.
6. **Tracking coverage:** Astro still has only seven saved rows across four stores, including unrelated “pill reminder.” A proposed query list is saved below; no watchlist mutation was made. Remove irrelevant terms only with the explicit deletion authorization required by Astro.
7. **Regional monetization:** the October 6 audit’s weekly/monthly/yearly price ladder and territory prices warrant a separate conversion/competitor-pricing review. This update makes no price judgment or change.

## Measurement plan

Use the query/storefront pairs in effective-search-summary.json as the baseline. Check ranks at 7, 14 and 28 days after 1.4 becomes live; compare search-source impressions and downloads/conversion over comparable periods. Track language-specific queries together with relevant English variants. Keep popularity/difficulty null when not returned. A rank rise without more impressions/downloads is not enough to claim growth, and concurrent ads/releases/seasonality prevent simple causal attribution.

## Sources and evidence

- [Apple App Store search](https://developer.apple.com/app-store/search/): title/subtitle/keyword relevance, downloads, ratings/reviews, keyword duplication and search metrics. Read 8 October 2026.
- [Apple product-page guidance](https://developer.apple.com/app-store/product-page/): accurate features, 30-character title/subtitle, conversion copy, promotional text and screenshots. Read 8 October 2026.
- [Apple platform version fields](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/): keyword byte limit. Read 8 October 2026.
- [Astro metric definitions](https://tryastro.app/docs/data-overview-keywords/): Apple Ads-derived popularity and proprietary difficulty. Read 8 October 2026.
- Raw source: astro-search-raw.json, astro-india-retry.json, astro-suggestions-raw.json, astro-tracked-raw.json.
- API evidence: before-/after- JSON snapshots, patches/, responses/, applied-checkpoints.json and verification-summary.json.
- Complete final copy and provenance: metadata-proposed.json; API-normalized final copy: metadata-readback.json; field diff: change-manifest.json.
- Source language support: Sodium Tracker/Sodium Tracker/Support/PinchLocalization.swift. Streak semantics: DayEngine.swift:188 (consecutive logged days, not days below a target).
- Support/marketing/legal pages were read in the browser because automated requests returned HTTP 406. They are reachable; the stale homepage/support copy is a content problem rather than a proven access failure.
