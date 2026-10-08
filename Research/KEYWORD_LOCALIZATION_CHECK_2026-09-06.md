# Astro keyword-localization double-check

Checked 6 September 2026 for Sodium Tracker: Pinch Daily, App Store ID 6800595930. Read-only Astro MCP calls; no App Store listing or Astro tracking changes.

## Decision

Localize the keyword strategy, not just the English words. Apple explicitly recommends localizing keywords and tailoring them to each market. Astro supports testing both native and English search terms: Germany's English “sodium tracker” has a higher popularity score than the two tracked German-language alternatives. Do not remove a relevant English term purely because the storefront is non-English.

These are research candidates, not approved final comma-separated keyword fields. The current App Store Connect keyword fields and localized names/subtitles could not be read without configured API credentials. Astro rankings cannot prove which terms are currently saved in the private keyword field or that localization caused a ranking.

## Evidence from 62 tracked entries across 20 storefronts

Astro's stored ranking observations were last updated on 6 September, approximately 10:51–11:03 UTC. This check retrieved those observations; it did not force a ranking refresh.

| Market | Tracked query | Popularity | Difficulty | Pinch rank |
|---|---|---:|---:|---:|
| Germany | sodium tracker | 9 | 13 | 7 |
| Germany | natrium tracker | 5 | 5 | 2 |
| Germany | salz tracker | 5 | 9 | 41 |
| France | suivi sodium | 5 | 11 | 1 |
| Netherlands | natrium tracker | 5 | 5 | 1 |
| Netherlands | zout tracker | 5 | 5 | 3 |
| Italy | dieta iposodica | 5 | 5 | 3 |
| Japan | 減塩 | 5 | 21 | 46 |
| Japan | 塩分 記録 | 5 | 13 | 64 |
| Switzerland | suivi sodium | 5 | 11 | 10 |

These low popularity scores are not monthly search counts or proof of zero demand. High rank on a low-popularity query is not evidence of substantial downloads or subscription conversion. Astro says its popularity comes from Apple Ads, difficulty is proprietary, and suggests popularity above 25 as a selection guideline. None of the tracked native-language probes reaches that guideline.

## Coverage and remaining gaps

- US, UK, Australia, New Zealand, Ireland and Singapore have English probes. Canada also needs French-language validation: the tracked Canadian probes are English only.
- Germany, France, Netherlands, Italy, Japan, Spain and Sweden have native-language probes. They establish initial relevance/visibility only, not comprehensive coverage.
- Switzerland has German/French probes but no Italian probe.
- Simplified Chinese and Malay have no tracked local-language probes in this app. India's tracked probes are English, not Tamil, Hindi or Telugu. Those localizations cannot be certified as Astro-validated.
- Irish, Māori and Romansh can be app languages but are not separate App Store listing locales in Apple's published supported-locale list. Do not put those assets or terms into unrelated language fields.

## Additional suggestion checks

Queried Astro suggestions for Germany, France, Japan, China, Malaysia, India, Spain, Italy, Netherlands and Sweden. Germany returned “sodium tracker” (popularity 9, difficulty 13). Japan returned “sodium tracker free” (23, 11). The other eight returned no suggestions. An empty response is a discovery gap, not evidence of no market demand. The Japanese result has free intent and is not evidence of willingness to subscribe; it is not automatically approved for metadata.

## Before applying final metadata

1. Read each live localized name, subtitle and keyword field, then avoid wasting keyword space on already-covered terms.
2. Use relevant local search intent, not competitor names, unsupported health claims, keyword stuffing or blind literal translations. The existing tracked competitor-branded US query is for research only.
3. Keep the description natural and feature-accurate. Apple says unnecessary keywords in the description should be avoided.
4. Validate field limits and locale codes against Apple's API. Apple's product-page guide says 100 characters for keywords, while its platform-version reference says 100 bytes; conservatively validate both and verify server acceptance, particularly for multibyte scripts.
5. Expand native-language research where the evidence is missing before calling every localization complete. Keep store metadata unchanged until access and asset issues are resolved.

## Sources

- [Apple product-page guidance](https://developer.apple.com/app-store/product-page/)
- [Apple localizing app information](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information)
- [Apple supported listing locales](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations)
- [Apple platform-version keyword field](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Astro metric definitions](https://tryastro.app/docs/data-overview-keywords/)
- Local raw MCP evidence: `astro-keyword-localization-check-2026-09-06.json`.
