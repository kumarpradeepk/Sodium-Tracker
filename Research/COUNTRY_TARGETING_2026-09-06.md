# Pinch: 15-country targeting shortlist
Research date: 6 September 2026. Platform: iPhone / App Store. App: Sodium Tracker: Pinch Daily (6800595930).

## Decision
Start with United States, Canada, United Kingdom and Australia. Make Germany the next localization investment. Use the remaining ten countries as staged validation markets, not equal-budget launches.

This is a practical priority order among 20 researched candidates, not a proven global top 15. Only five countries showed popularity above 5 for the shared “sodium tracker” query. The order below combines query relevance, Astro popularity/difficulty, existing visibility, regional subscription benchmarks, and translation effort; it is not a computed market-size ranking.

## Recommended order

Popularity and difficulty below refer to the SAME “sodium tracker” query in each storefront. Higher popularity and lower difficulty are directionally favorable. — means no ranking supplied, not a verified absence.

| Priority | Country | Popularity / difficulty | Pinch rank | Why test it / language requirement |
|---|---|---|---|---|
| 1 | United States | 11 / 35 | 30 | Strongest shared-query demand signal in this sample; established niche competitors. English. |
| 2 | Canada | 9 / 13 | — | Better demand signal than most candidates and less keyword competition than US. English first; French needed for a French-speaking campaign. |
| 3 | United Kingdom | 6 / 13 | — | English-first launch with a small positive demand signal. Test salt versus sodium messaging; tested salt terms only scored 5. |
| 4 | Australia | 6 / 13 | — | English-first launch with the same measured query scores as UK; ordering between them is provisional. |
| 5 | Germany | 9 / 13 | 7 | Strongest non-English shared-query signal. “natrium tracker” already ranks 2, but popularity is only 5. Finish German app localization first. |
| 6 | Japan | 5 / 5 | 24 | Conditional localization test using the existing Japanese catalog, not a proven demand winner. “減塩” ranks 46 (5 / 21); “塩分 記録” ranks 64 (5 / 13). Finish Japanese and validate local food coverage. |
| 7 | France | 5 / 11 | 7 | Existing visibility: “suivi sodium” ranks 1 (5 / 11). Low score prevents a high-volume claim. Requires French app localization. |
| 8 | Netherlands | 5 / 11 | 2 | Visibility is promising: “natrium tracker” ranks 1 and “zout tracker” ranks 3, both 5 / 5. Requires Dutch localization; rankings alone do not establish demand. |
| 9 | New Zealand | 5 / 5 | — | Low-effort English extension to Australia. Weak measured demand; keep it an inexpensive validation market. |
| 10 | Ireland | 5 / 11 | 15 | Low-effort English extension to UK; weak measured demand. |
| 11 | Switzerland | 5 / 11 | 25 | Reuse validated German/French localization, adding Italian for an Italian-speaking campaign. “suivi sodium” ranks 10 (5 / 11). Broad country targeting needs language segmentation. |
| 12 | Italy | 5 / 11 | 12 | “dieta iposodica” ranks 3 (5 / 5), but does not prove demand. Requires Italian localization and copy that describes tracking rather than a prescribed diet program. |
| 13 | Spain | 5 / 11 | 5 | Existing visibility with weak demand evidence. Requires Spanish localization; local food and serving support needs validation. |
| 14 | Sweden | 5 / 11 | 4 | Existing visibility but all three tested terms score 5. Requires Swedish localization before a Swedish-language campaign. |
| 15 | Singapore | 5 / 9 | 117 | English-first product test with low marginal translation effort, but weak search visibility and demand evidence. Do not infer Singapore performance from regional averages. |

Ranks 6–15 are low-confidence sequencing decisions. Swapping their order based on actual installs, food-search success, retention, or localization cost would be reasonable. UK versus Australia is also not statistically distinguished by this research.

## Other countries tested

- South Korea: shared query 5 / 9, rank 19; both local terms also popularity 5. Korean implementation is additional work with no stronger sampled demand signal.
- Denmark: 5 / 11, rank 6; Norwegian/Swedish/Danish markets should not be collapsed into one localization. All Danish terms scored 5.
- Norway: 5 / 5, rank 20; all sampled terms scored 5.
- Brazil: 5 / 5, rank 22; Portuguese work and regional pricing validation needed. No stronger sampled demand signal.
- India: 5 / 5, rank 29; English-first experiments remain possible, but this sample does not justify prioritizing it for paid iOS subscriptions.

These exclusions do not mean there is no opportunity. No direct country revenue, Apple Ads cost, or install-to-paid data was collected.

## What the scores actually show
The 60-entry comparable research set contains only five entries above popularity 5: the shared query in US (11), Canada (9), Germany (9), UK (6), Australia (6). All 40 alternative/local-language entries scored 5. This is a narrow, low-volume-keyword starting point; three keywords cannot establish the full addressable demand of a country.

Existing US tracking also contains “sodium tracker free” at popularity 22 / difficulty 38. Its free intent must not be treated as evidence of willingness to subscribe. The existing competitor-branded query was preserved, but is not recommended for store metadata.

Astro says popularity comes from Apple Ads, while difficulty uses Astro's own algorithm; it recommends popularity above 25 for keyword selection. None of our tested terms reach that guideline. Scores are not monthly search counts; a score of 5 is not proof of zero searches. [Astro metric definitions](https://tryastro.app/docs/data-overview-keywords/)

A regional monetization cross-check favors North America as a starting point: RevenueCat reports median day-35 download-to-paid conversion of 2.6% in North America, 2.0% in Western Europe, and 1.4% in India/Southeast Asia. These are broad subscription-app benchmarks, not Pinch predictions or individual-country results. [RevenueCat 2026 report](https://www.revenuecat.com/state-of-subscription-apps/)

## Launch gates

1. Wave 1: US, Canada (English), UK, Australia. Measure storefront impressions, product-page conversion, first successful food log, return usage, eligible trial starts, trial-to-paid conversion and refunds. Do not optimize only for trial starts.
2. Germany next: complete German text and validate onboarding, food search/logging, favorites, notifications, paywall, restore, cancellation explanations and accessibility. Current source routing includes English, German and Japanese only, with fallback English; having a translated listing does not mean the app is translated.
3. Validate Japan and localized European markets in small batches. Native review of keyword idiom and all screenshots is still required. The research terms are probes, not approved final ASO copy.
4. Keep NZ/Ireland/Singapore as low-cost English experiments when operationally convenient; their lower planning rank need not prevent passive store availability.
5. Before scaling any country, verify FatSecret coverage and relevant local foods, correct sodium versus salt units, StoreKit-localized price/trial eligibility, and actual user retention. These were not country-tested in this research.
6. Expand keyword discovery before paid acquisition. Consider adjacent intent only where supported by real features; do not promise medical outcomes, blood-pressure tracking, or a diet program merely because a keyword is popular.

## Saved changes and provenance
With explicit approval, added 59 new keyword-country entries (one of the 60 requested entries was already tracked). Preserved the original three, giving 62 tracked entries across 20 storefronts. All additions reported success with zero failures, and a final list_apps read confirmed the count and countries.

Only Astro research tracking changed. No store metadata, subscriptions, RevenueCat configuration, code, ads or spending changed.

Raw response evidence: [astro-country-evidence-2026-09-06.json](astro-country-evidence-2026-09-06.json).
