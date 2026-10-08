# Pinch Apple Ads: researched settings and draft verification

Research and browser verification: 9 September 2026. App: Sodium Tracker: Pinch Daily, App Store ID 6800595930, bundle com.kabi.sodium.tracker.Sodium-Tracker. Account currency: INR. Authorized total ceilings: US$13 for the US, US$7 for Canada. No launch or spending occurred in this work.

## What changed

Two separate, unsubmitted browser forms are populated. These are not server-saved campaigns and may be lost if the pages are reloaded. Both tabs were preserved for handoff. The prior unsubstantiated ₹25 keyword bids in the US form were corrected. The US default bid already read ₹123.27 when this research turn began; its two keyword overrides still read ₹25.

| Setting | US draft | Canada draft | Evidence / reason |
|---|---|---|---|
| Placement | Search Results | Search Results | Matches explicit food/sodium tracking intent |
| Bid strategy | Manage Bids | Manage Bids | Direct price ceiling and keyword control for a small delivery test |
| Default maximum CPT | ₹123.27 | ₹123.27 | Apple displayed this suggestion independently in both country forms; reference, not a profitability estimate |
| Keyword bids | ₹123.27 each | ₹123.27 each | Reopened both keyword editors and verified values |
| Keywords | sodium tracker; salt tracker | sodium tracker; salt tracker | Both Exact; directly describe implemented logging functionality |
| Search Match | Off | Off | Keeps this small initial test from exploring other searches |
| Daily budget | ₹300 | ₹160 | Derived from three-day spend envelopes below authorized total ceilings, with headroom |
| Start | Sep 10, 2026, 12:00 AM | Same | Asia/Kolkata account time zone |
| End | Sep 13, 2026, 12:00 AM | Same | Each UI explicitly reports TOTAL DAYS IN CAMPAIGN: 3 |
| Maximum scheduled ad spend | ₹900 | ₹480 | Three days multiplied by daily budget |
| CPA cap | Blank | Blank | No measured conversion rate or justified target CPA available |
| Audience | All eligible users | All eligible users | No evidence supports age/gender restrictions; no inferred health-status targeting |
| Creative | Default product page, English (US) | Default product page, English (Canada) | Matching default app-store assets shown in each form; no new creative fabricated |

Campaign names: `Pinch US Exact Search 13 USD Test`, `Pinch CA Exact Search 7 USD Test`. Ad group: `Sodium Intent Exact`. Names do not enforce limits; the dates and daily budgets do.

## Keyword evidence and exclusions

Reused the same-day raw Astro MCP capture in `astro-two-country-evidence-2026-09-09.json` rather than claiming a new fetch. Last metric updates were approximately 08:42 UTC on 9 September.

| Query | US popularity / organic difficulty | Canada popularity / organic difficulty | Decision |
|---|---|---|---|
| sodium tracker | 11 / 36 | 9 / 13 | Keep: strongest direct category intent among non-brand tracked terms |
| salt tracker | 5 / 15 | 5 / 5 | Keep: relevant alternative wording; low demand |
| sodium intake | 5 / 11 | 5 / 5 | Defer: less explicit app-seeking intent; avoid splitting this tiny test further |
| sodium tracker free | 22 / 38 | Not measured in this set | Defer to a separate free-intent test, not a claim it cannot convert; Pinch does have free functionality |
| my dash diet sodium tracker | 13 / 15 | Not measured in this set | Defer competitor-brand targeting |

The app tracks dietary sodium, food logs, favorites, and logging habits. It is not a blood-pressure measuring app or a medical treatment. Irrelevant generic suggestions in Apple's picker, including social-network names, were not added.

Astro popularity is a search-interest proxy, not monthly volume. Organic difficulty is not auction cost. Canada showing lower difficulty does not establish lower CPT: Apple's displayed suggested CPT was identical in these two drafts.

## What the bid does and does not establish

[Apple's bid guidance](https://ads.apple.com/app-store/help/bids-and-budget/0062-set-and-adjust-bids) says the displayed suggestion uses app/comparable-advertiser information and is only a reference. The maximum CPT is a ceiling; actual tap cost can be lower. A sustainable bid should ultimately be based on affordable acquisition cost multiplied by observed conversion probability.

No attributable paid-user conversion rate, country-specific net lifetime value, historical CPA, or keyword-level auction bid forecast was available for this app. Therefore ₹123.27 is an evidence-informed delivery-test starting point, not an optimized or profitable bid. Do not represent an Apple app-level suggestion as a keyword-specific clearing price.

If all taps cost the ceiling, ₹900 buys seven whole taps and ₹480 buys three whole taps. Lower actual prices could buy more; low search demand or auction eligibility may produce no taps at all. This is insufficient to establish conversion superiority or return on ad spend.

Illustrative arithmetic only, not forecasts: at ₹123.27 actual CPT, a 25%, 40%, or 60% tap-to-install rate would imply ₹493.08, ₹308.18, or ₹205.45 per install. Paid-subscriber acquisition would require an additional install-to-paid conversion factor. Neither observed rate is known here.

## Spend control and currency

[Apple's current budget rules](https://ads.apple.com/app-store/help/bids-and-budget/0016-manage-budgets) state that daily spend may vary and campaigns run continuously without an end date. With an end date, spend is bounded by campaign days multiplied by daily budget. Lifetime-budget campaigns were retired in June 2026. Dates were entered and the three-day count verified before budgets were filled. An initial budget entry was blocked by the safety review because there was no end date; the missing stop date was resolved before retrying.

[Investing.com's USD/INR history](https://www.investing.com/currencies/usd-inr-historical-data), retrieved today, showed 95.060 for Sep 9, 2026. This is an indicative market quote, not a guaranteed billing conversion. At that quote, ₹900 is about US$9.47 and ₹480 about US$5.05, below the US$13 / US$7 ceilings.

An illustrative 25% contingency on those ad-spend envelopes gives ₹1,125 and ₹600 (about US$11.83 and US$6.31 at that quote). This is budgeting headroom, NOT a tax-rate determination. [Apple excludes taxes from campaign budgets](https://ads.apple.com/app-store/help/billing/0034-tax-information). Exact taxes, payment charges, and exchange-rate effects remain unverified, so no unconditional all-in dollar guarantee is made. Do not activate before checking them. Reduce the budgets further if needed; never treat the reserve as permission to exceed US$20 total.

## Remaining launch gates

- Earlier India business-details flow required verified GST information. The user said they have no GSTIN. Being able to fill a campaign does not establish tax eligibility. Do not invent registration details or change billing country to bypass this.
- Confirm payment and tax readiness, applicable charges, and the final all-in spend envelope.
- Reconfirm the dates are still appropriate if launch occurs later; do not simply remove the end date.
- Click Create Campaign only after launch gates are satisfied. Neither form was submitted during this task.
- After any future authorized launch, check eligibility/status before interpreting zero impressions as low demand; report actual impressions, taps, spend, and installs. Do not promise automatic monitoring unless a monitoring task is explicitly configured.

Additional official sources: [keyword guidance](https://ads.apple.com/app-store/help/keywords/0014-add-and-manage-keywords), [campaign scheduling](https://ads.apple.com/app-store/help/campaigns/0080-schedule-campaigns), [India tax requirements](https://ads.apple.com/taxes).
