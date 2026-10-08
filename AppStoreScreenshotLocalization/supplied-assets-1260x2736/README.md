# Corrected screenshot exports

Source: `/Users/pradeep.kumar1/Downloads/pinch-screenshots-localized/`.

Exported and verified 6 September 2026: 80 PNGs, each 1260×2736, RGB/sRGB with no alpha channel. Source-file SHA-256 values were checked before and after export; originals were not modified. Screenshot order remains 01_today, 02_fits, 03_reminders, 04_favorites, 05_streaks.

- `store-candidates/`: 65 images across 13 languages whose languages are supported for App Store metadata. Folder names are preserved from the source and must be matched to Apple's actual API locale IDs before upload.
- `reference-only/`: 15 images for Irish, Māori and Romansh, which are not separate App Store listing locales. Do not upload them under unrelated locale IDs.
- `manifest.json`: source/output paths, dimensions, hashes and checks for every image.

## Scope and remaining limitations

This is a format correction, not new artwork or full localization. The export resamples the supplied images and retains all original content, with an aspect-ratio adjustment below 0.3% to avoid cropping. Upscaling cannot restore detail missing from the supplied 851/852-pixel-wide sources. Sample French and Tamil exports were visually inspected; their marketing headings are translated but the pictured app interface remains English.

The 65 candidate images meet the checked pixel/format conditions, but they are not certified App Review-ready. Language correctness, fidelity to the release build, device-set selection and existing live metadata still require verification. These static PNGs are screenshots, not video app previews.

## Upload status: VERIFIED IN 1.1 DRAFT

Uploaded via the store-metadata API workflow on 6 September 2026. All 65 unique supported-language images were used across 17 listing locales (85 screenshots, including regional English and French reuse). Apple reports every image COMPLETE at 1260×2736. Image order and source checksums were verified by a separate final read-back.

App: 6800595930. Draft version: 1.1, resource `1f016dcd-1be3-451c-b89a-9c08a242288f`, state PREPARE_FOR_SUBMISSION. The previous five iPhone screenshots were replaced only in the draft's existing nine locales, after each replacement finished processing. Live 1.0 metadata and screenshot references were compared with the backup and are unchanged. Existing iPad assets were preserved.

Localized names, descriptions and keywords are saved across all 17 locales. See `Research/APPSTORE_LISTING_UPDATE_2026-09-06.md` and `Research/appstore-update-2026-09-06/final-verification.json` in the project for the locale mappings and evidence. No build upload, pricing change, submission or release was performed. The English UI and source-resolution limitations above still apply; this upload is not certification that the app is ready for review.

Specification: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications

Supported locales: https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations
