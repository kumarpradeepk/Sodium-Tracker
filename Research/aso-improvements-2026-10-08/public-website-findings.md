# Public website verification — 8 October 2026

The public pages were readable in the in-app browser. Automated HTTP requests returned 406 and the web reader could not access them; those responses are not evidence that the pages are unavailable to users. No website edits were made.

## Confirmed conversion and support gaps

- https://tinkersmithstudio.com/pinch/ still labels its download CTA “app store — soon” and links to a `#` placeholder. The app is already live as App Store ID 6800595930. This prevents the page from completing its acquisition purpose.
- The landing-page footer describes zero third-party SDKs. Its current privacy policy correctly describes RevenueCat and online FatSecret search. Those public descriptions conflict.
- https://tinkersmithstudio.com/pinch/support.html says there is no subscription, no unlock, and nothing to restore or cancel; it also tells customers a payment prompt did not come from the developer. That directly contradicts implemented Pinch Plus and the current App Store description and terms.
- The homepage/support page describes streaks as days within the sodium target. `DayEngine.streak` instead counts consecutive days with at least one logged entry; the store description’s “streaks of logged days” wording is accurate.
- https://tinkersmithstudio.com/pinch/privacy.html correctly describes local food-log storage, online search requests and RevenueCat/Apple purchase processing.
- https://tinkersmithstudio.com/pinch/terms.html describes free core features, Pinch Plus, weekly/monthly/yearly plans, renewal, cancellation and restore. It aligns with the paid-feature boundaries used in the store copy.

These website gaps require changes in the website project. Changing the App Store Support URL to the current support.html page would worsen the contradiction, so the existing URLs were preserved.

## Copy-ready website corrections

1. Change the App Store CTA to **Download on the App Store**, linking to `https://apps.apple.com/app/id6800595930`.
2. Replace blanket free/no-SDK claims with: **Core sodium tracking is free. Pinch Plus unlocks online food search, four-week trends and calendar history, unlimited custom foods, CSV export and the Home Screen widget. Your personal food log stays on your device. Online food search and purchases use the services described in our Privacy Policy.**
3. Replace the support page’s Purchases section with: **Pinch includes free core tracking and optional Pinch Plus subscriptions. The app shows the available plan, price and billing period before purchase. Use Restore Purchases in the app to restore eligible access. Manage or cancel your subscription in Apple Account settings; deleting the app does not cancel it. Apple handles refund requests. If access does not restore, contact support with the plan and purchase date. Do not send payment-card details.**
4. Keep the privacy/terms links alongside the purchase explanation and match all public feature and data claims to those current policies.
5. Describe streaks as **consecutive days with at least one logged entry**. A quiet today can retain yesterday’s chain; remaining below the target is not required by the current streak calculation.

This is proposed website copy, not a published website change. Subscription prices and legal agreements were not changed.
