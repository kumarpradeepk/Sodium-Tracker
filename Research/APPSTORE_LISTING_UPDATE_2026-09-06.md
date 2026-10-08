# App Store listing update — verified

Verified at 2026-09-06 17:37 UTC for Sodium Tracker: Pinch Daily, app 6800595930.

Follow-up: the user subsequently requested submission using the latest build. Build 1.1 (5) was attached, but submission was paused after verifying incomplete in-app localization in its matching archive. See `RELEASE_PREFLIGHT_1_1_BUILD_5.md`. The outcome below records the completed listing-update stage.

## Saved outcome

Created the editable iOS 1.1 draft matching the project's marketing version. Its state remains **PREPARE_FOR_SUBMISSION**; nothing was submitted or released. Version ID: `1f016dcd-1be3-451c-b89a-9c08a242288f`.

- 17 listing locales, covering 13 languages.
- Localized names verified or corrected; descriptions and keywords updated in all 17.
- Localized subtitles and privacy links supplied for the eight new locales. Existing subtitle/privacy fields preserved.
- Required support links filled for new locales using the existing Pinch support page.
- 85 iPhone screenshots uploaded from 65 unique user-supplied images, five per locale.
- Every image independently read back as COMPLETE, 1260×2736, with matching checksum and the requested order.
- 45 old draft iPhone images replaced after replacement processing completed. The old images remain represented in live 1.0 and in the original local export collection; the live listing was not deleted or changed.
- Existing iPad screenshots preserved. No replacement iPad images were supplied.

## Locale and asset mapping

| App Store locale | Language/region | Source folder | Screenshots |
| --- | --- | --- | ---: |
| en-US | English, US | en-US | 5 |
| en-GB | English, UK | en-US | 5 |
| en-AU | English, Australia | en-US | 5 |
| en-CA | English, Canada | en-US | 5 |
| fr-FR | French | fr-FR | 5 |
| fr-CA | French, Canada | fr-FR | 5 |
| de-DE | German | de-DE | 5 |
| nl-NL | Dutch | nl-NL | 5 |
| it | Italian | it-IT | 5 |
| ja | Japanese | ja-JP | 5 |
| es-ES | Spanish, Spain | es-ES | 5 |
| sv | Swedish | sv-SE | 5 |
| zh-Hans | Simplified Chinese | zh-Hans | 5 |
| ms | Malay | ms-MY | 5 |
| hi | Hindi | hi-IN | 5 |
| ta-IN | Tamil | ta-IN | 5 |
| te-IN | Telugu | te-IN | 5 |

Apple's API locale codes were checked against its official shortcode documentation. Irish, Māori and Romansh are not separate supported App Store listing locales; their 15 supplied images remain reference-only. Country availability was not changed.

## Text and ASO checks

Copy is in `listing-copy-1.1.mjs`; saved field values, resource IDs and verification results are in `appstore-update-2026-09-06/final-verification.json` and the per-locale evidence files.

The keyword selections use the saved Astro research in `KEYWORD_LOCALIZATION_CHECK_2026-09-06.md`. Relevant native-language intent is retained; Germany also uses the relevant English term “sodium”. Already-covered title/subtitle terms are generally omitted from keyword fields. Competitor names, unverifiable ratings/testimonials and unsupported medical outcome promises were not added. Each keyword field is within both 100 characters and 100 UTF-8 bytes, and Apple accepted the fields. All names/subtitles are within 30 characters and descriptions within 4,000.

The research is not proof of high demand or conversion: several native probes had low popularity, and native-language validation remains incomplete for Chinese, Malay, Hindi, Tamil, Telugu and Canadian French. No new Astro tracking changes were made in this update.

Descriptions separate subscription-only features from everyday tracking, explain that totals depend on logged foods, retain FatSecret attribution and medical disclaimers, and include the user's legal URLs. They do not advertise the unverified proposed prices or trial, nor claim a fully translated app binary.

## Important limits before release

- Screenshot marketing headlines are localized, but the supplied screenshots still picture English app UI. The artwork was preserved, not regenerated.
- These are upscaled source images, not newly captured native-resolution simulator screenshots. Acceptance by Apple's image processor is not an App Review approval or a release-build fidelity audit.
- The full app-language rollout and price/trial/paywall work are separate, incomplete release tasks. This metadata update does not finish those tasks.
- No new binary was uploaded or selected, no release notes were invented, and no submission/release action was taken.

The final verification also compared live 1.0 app-info fields, version-localization fields and screenshot-set/image IDs with the before-state: unchanged.

API credentials remain outside Git. Audit JSON omits transient upload credentials and asset tokens.

## References

- [Apple locale shortcodes](https://developer.apple.com/documentation/appstoreconnectapi/managing-metadata-in-your-app-by-using-locale-shortcodes)
- [Apple supported store localizations](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations)
- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Apple product-page guidance](https://developer.apple.com/app-store/product-page/)
