# Pinch Plus paywall rollout — September 6, 2026

## Requested target

- Yearly: USD 29.99, eligible customers receive a three-day introductory free trial, then annual auto-renewal.
- Monthly: USD 7.99, no trial, monthly auto-renewal.
- No weekly option for new purchases. Preserve existing verified subscribers' access.
- Localized StoreKit prices, not hardcoded USD copy.

## Completed locally

- Native paywall rebuilt in `Screens/PaywallSheet.swift`: pale background, navy example chart, trial timeline, pinned annual/monthly cards, dynamic savings, purchase/restore/legal links.
- Monthly and trial-ineligible annual customers see immediate-billing copy and no trial timeline.
- Three-day trial messaging requires an actual three-day free introductory offer and StoreKit eligibility.
- Permission-aware reminder toggle; schedules from a verified annual introductory purchase, 48 hours before expiration. Sandbox purchase/reminder testing remains necessary.
- Legacy weekly transactions still grant access but weekly is not fetched or offered.
- Removed unverifiable testimonial/rating; chart explicitly labeled as an example.
- Initial iPhone 17 Pro simulator legal-link test passed; evidence in `/private/tmp/PinchPaywallDesignCheck.xcresult`.
- Final expanded simulator test passed after fixing plan-button accessibility: annual/monthly selection, absence of trial copy/reminder in monthly, and hittable Privacy/Terms links. Result: `/private/tmp/PinchPaywallDesignVerified.xcresult`. Verified displayed prices still reflect Apple's current USD 24.99/14.99, not the unconfigured target prices.

## Dashboard state — not live yet

- RevenueCat project `c78f6196`, offering `pinch_plus`, paywall `wfd665744aaddf4efe`.
- New design saved as a RevenueCat draft using the in-app browser. Not published.
- Weekly removed from the paywall draft, but remains in the offering. Offering cleanup is pending.
- RevenueCat draft has no functional reminder toggle. Native reminder and hosted paywall still need integration/alignment.
- Existing iOS purchase implementation is StoreKit 2, not RevenueCat SDK/RevenueCatUI. Dashboard publication alone will NOT update this native paywall.
- Fresh Apple reads: annual USD 24.99; monthly USD 14.99; annual introductory offers 0; 175 available countries/regions.
- No Apple prices, offers, availability, or submissions changed in this session.

## Release gate

The RevenueCat store-state skill requires explicit confirmation after the live before/after summary. Asked to confirm USD 24.99 → 29.99 yearly + three-day trial, USD 14.99 → 7.99 monthly without trial, local equivalents across 175 storefronts, and hiding weekly from new purchases while preserving existing access/pricing where applicable.

After confirmation: apply and re-read Apple pricing/intro offers; inspect and clean up RevenueCat offering; independently inspect conditional rules, localization and savings (do not rely on the AI editor's summary); finish SDK/hosted-paywall alignment; verify actual eligible/ineligible annual and monthly sandbox purchases, restore, cancellation, pending approval, reminder permissions, and large text; then publish only the verified paywall and prepare the app build. No claim of pixel-exact parity or release readiness yet.
