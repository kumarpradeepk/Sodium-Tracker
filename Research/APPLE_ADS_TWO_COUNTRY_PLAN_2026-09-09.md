# Apple Ads: two-country exploratory test

## Recommendation

United States: US$13 total. Canada: US$7 total. Combined ceiling: US$20 total, not a daily budget. This incorporates the user's revised allocation and replaces the earlier five-country proposal.

Canada is the recommended second experiment, not a proven highest-converting market. Its same-query interest exceeds the UK and Australia. Germany ties Canada on this query, but Canada allows the small test to use English-language keywords and messaging alongside the US. That is an experimental-design judgment, not measured conversion superiority.

## Evidence

Read-only Astro MCP research on 9 September 2026, using the existing 62 tracked keywords across 20 stores for Sodium Tracker: Pinch Daily (6800595930). No tracking, store metadata, or advertising settings were changed.

Same query: `sodium tracker`.

| Store | Popularity | Organic difficulty | Proposed total spend |
|---|---:|---:|---:|
| US | 11 | 36 | US$13 |
| Canada | 9 | 13 | US$7 |
| Germany | 9 | 13 | — |
| UK | 6 | 13 | — |
| Australia | 6 | 19 | — |

Raw responses, query arguments, and retrieval timestamps: `astro-two-country-evidence-2026-09-09.json`.

[Astro's metric definitions](https://tryastro.app/docs/data-overview-keywords/): popularity is an Apple Ads-derived interest score, not a count of searches. Difficulty concerns organic ranking, not auction prices or paid acquisition cost. These are low popularity scores; do not interpret them as strong demand or sufficient volume for statistical conclusions.

Astro did not supply per-country installs, purchases, paid conversion rates, or bid estimates. Tracking returned a 1000 ranking value for the US and Canada; its meaning is unverified. Fresh search responses did not include Pinch among the ten returned apps in either store and omitted a specific Pinch ranking. Do not label 1000 as an actual measured position or infer that the app is unavailable.

## Proposed test, not launched

- Start with tightly relevant exact-match English queries such as `sodium tracker` and `salt tracker`; confirm actual auction availability and bids in Apple Ads.
- Avoid broad generic diet queries and competitor-brand queries for this tiny test.
- Review impressions, taps, spend, and attributed installs. Purchases may be too sparse to judge conversion; no guaranteed install or purchase count.
- Keep separate country budgets and verify controls that enforce the authorized total spend before activation. A daily budget alone is not authorization to spend repeatedly.
- Apple Ads signup was still incomplete at the last account inspection. Legal/billing details and any required terms approval remain prerequisites.

No campaigns were created or launched, and no advertising spend was initiated during this research.
