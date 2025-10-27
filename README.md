# SplitPay_Promo_Performance_Drop

## Business background

The company operates a decentralized ride-hailing platform, connecting passengers and drivers directly via a multi-channel digital ecosystem - mobile apps (iOS & Android) and web interface. Riders can pay either by card or via SplitPay, a newly launched deferred payment service integrated in mid-September 2025.

SplitPay 2.0 introduced:

- a discount mechanism for eligible users;

- instant installment approvals through SDK integration;

- and a new promotion campaign encouraging SplitPay usage across channels.

The **business goal** was to increase SplitPay share among all completed rides from 25% → 40% by the end of Q4.

Two weeks after launch the analytics and product teams noticed an **anomaly**:

SplitPay transactions dropped sharply: completed rides remained stable, successful payments collapsed by ~3×, while other payment methods (card) stayed normal.

## Questions clarifying the context

The analyst is tasked with finding out:

- Where in the ride funnel the conversion breaks (done → pay)?

- Who is affected (device, platform, payment provider)?

- Why it happens - is this a technical failure, a discount logic bug, or a user behavior shift?

## Hypotheses ("Why SplitPay payments suddenly dropped?")

**1. UX / Product**

📌 Payment button or discount banner is missing after SDK update;

📌 Discount is not displayed correctly - users see full price and abandon payment;

📌 The checkout session is lost when switching between SplitPay and the ride app.

**2. Technical / Integration**

📌 SplitPay SDK on iOS returns an error on applyDiscount() or initPayment();

📌 Timeout or API error in SplitPay service for mobile requests → payment fails silently;

📌 Post–October release introduced a change in eligibility or discount logic breaking iOS calls.

**3. Analytical / Data Tracking**

📌 The event payment_success is missing from iOS logs;

📌 Session ID mismatch after redirect into SplitPay → completed payments not attributed correctly.

**4. Behavioral (control)**

📌 Users intentionally delay SplitPay payments or switch to another payment method (minor contributor).

## SQL-analysis

1) Preparation step: normalize funnel steps per session;

2) Difference-in-Differences (SplitPay vs Card);

3) Device / Platform breakdown;

4) Verifying the correct application of discounts (SplitPay logs)

## Interpretation of findings & Business insights & Recommendations

1) **Diff-in-Diff** shows a clear drop only for SplitPay on the "done → pay" step;

2) In the device and platform breakdown, *desktop* and *android* remain stable, while *iOS* - particularly the *iOS App* - shows a sharp decline in conversion (r_done_to_pay ≈ 0.2). *iOS Web* version has a mild decline (r_done_to_pay ≈ 0.4), so the issue is localized to the iOS App SDK, not the global API;

3) SplitPay logs show much higher discount_error share (≈ 0.7) for *iOS App* users → the issue originates from the SplitPay SDK rather than from user behavior;

4) Recommendations:

- **Fix & Verification**

📌 Escalate to SplitPay SDK / Checkout teams with full context:

- attach sessions and rides with discount_error, discount_applied, transfer_fail for (iOS App + SplitPay + post);

- include Diff-in-Diff comparison vs. Desktop;

📌 Validate the SDK release - check changes in applyDiscount() and API timeouts;

📌 Hotfix: 1) implement client-side fallback for discount calculation if discount_error occurs; 2) enable retry logic for transfer_init API calls;

- **Monitoring / Alerts**

📌 Dashboard: "Ride funnel by device & payment provider" (search → request → done → pay) with SplitPay filter;

📌 Alert when SplitPay r_done_to_pay on iOS App drops > X p.p. below Android/Desktop (2h rolling window);

📌 Synthetic test: every 10 min create a control ride from iOS App via SplitPay; verify discount_applied + payment_success logged;

- **Communication**

📌 E-com director: "Conversion drop isolated to SplitPay SDK on iOS App. Estimated lost GMV: Δ conversion × traffic × avg ticket (target segment, last 7 days)";

📌 SplitPay tech team: "Provide list of affected ride_ids with discount_error and transfer_fail";

📌 Product / Marketing team: "Promo itself is fine - issue is technical, not UX. Once fixed, metrics should rebound within 24–48h"

- **Post-Incident improvements**

📌 Add detailed logging for discount_applied / discount_error with error_code and platform fields;

📌 Introduce a pre-release checklist before SDK updates: 1) smoke tests on iOS/Android, web/app; 2) verify "done → pay" funnel; 3) simulate API timeout and error responses 
