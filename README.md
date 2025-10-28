# SplitPay_Promo_Performance_Drop

## Business background

The company operates a decentralized ride-hailing platform, connecting passengers and drivers directly through a multi-channel digital ecosystem - mobile apps (iOS & Android) and a web interface. Riders can pay either by card or via SplitPay, a newly launched deferred payment service.

In October 2025 **a new promotion was launched**: "20% off for rides paid via the new SplitPay in-app direct transfer".

The **business objective** was to increase SplitPay’s share among all completed rides from 25% to 40% by the end of Q4.

However, two weeks after launch, the analytics and product teams detected an **anomaly** - SplitPay transactions dropped sharply:

- the number of completed rides remained stable,

- while successful payments collapsed by ~ 3×

## Questions clarifying the context

The analyst is tasked with finding out:

- Where in the ride funnel the conversion breaks (done → pay)?

- Who is affected (device, platform, payment provider)?

- Why it happens - is this a technical failure, a discount logic bug, or a user behavior shift?

## Hypotheses ("Why SplitPay payments suddenly dropped?")

**1. UX / Product**

📌 Payment button or discount banner is missing after SDK update;

📌 Discount is not displayed correctly - users see full price and abandon payment;

📌 The checkout session is lost when switching between SplitPay and the ride app;

**2. Technical / Integration**

📌 SplitPay SDK on iOS returns an error on applyDiscount() or initPayment();

📌 Timeout or API error in SplitPay service for mobile requests → payment fails silently;

📌 Post–October release introduced a change in eligibility or discount logic breaking iOS calls;

**3. Analytical / Data Tracking**

📌 The event payment_success is missing from iOS logs;

📌 Session ID mismatch after redirect into SplitPay → completed payments not attributed correctly;

**4. Behavioral (control)**

📌 Users intentionally delay SplitPay payments or switch to another payment method (minor contributor).

## Data Mart Schema

The architecture of the data mart includes **four layers**:

1. stg_ (**Staging**)

- **stg_ride_events**(session_id, ride_id, user_id, city_id, device_type, platform, payment_provider, event_type, event_ts);

- **stg_splitpay_logs**(ride_id, session_id, event_type, event_ts);

- **stg_driver_supply**(city_id, snapshot_ts, active_drivers, avg_eta);

2. dim_ (**Dimensions**)

- **dim_device**(device_type, platform);

- **dim_payment_provider**(payment_provider);

- **dim_period**(pre_from, pre_to, post_from, post_to)

Contains reference tables for consistent dimension data.

3. fact_ (**Facts**)

- **labeled**(session_id, ride_id, user_id, device_type, platform, payment_provider, ts_search, ts_req, ts_acc, ts_start, ts_done, ts_pay, grp, period);

- **fact_splitpay_status**(ride_id, session_id, has_discount, has_error, has_fail)

Contains fact tables with normalized funnel steps per session and splitpay_status data.

4. marts_ (**Analytics Marts**)

- **ride_funnel_metrics**(event_date, device_type, platform, payment_provider, period, cnt_search, cnt_req, cnt_done, cnt_pay, cnt_discount, cnt_error, cnt_fail, r_search_to_req, r_req_to_done, r_done_to_pay, p_discount_applied, p_discount_error, p_transfer_fail)

Contains aggregated summary tables for reporting and visualization.

## SQL-analysis

1) Preparation step: normalize funnel steps per session;

2) Difference-in-Differences (SplitPay vs Card);

3) Device / Platform breakdown;

4) Verifying the correct application of discounts (SplitPay logs)

## Creating a Dashboard in Tableau 

["Dashboard"](tableau/dashboard.pdf), also available via public link: https://public.tableau.com/views/SplitPayPaymentConversion-DiagnosticDashboard/SplitPayPaymentConversionDiagnosticDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link:

1) **Trend Over Time** (conversion "done → pay") - line chart visualizes daily payment conversion rates across platforms. The chart highlights a sharp decline on October 1 (promo launch date) specifically for iOS App, while Android and Desktop remain stable. The constant line marks the launch of the SplitPay promotion, confirming the timing of the anomaly;

2) **Funnel Overview** (conversion per step (after promotion launch)) - stacked bar chart shows funnel performance for each stage: "search → request → done → pay". Conversion drops significantly at the final step for SplitPay users compared to card payments, showing payment completion issues rather than upstream funnel drop-offs;

3) **Discount Health - SplitPay (post period)** - horizontal bars compare Discount Applied and Discount Error rates by device and platform. All non-iOS channels perform consistently, while iOS App shows degraded discount health - only 88.4% applied and 64.6% error rate;

4) **Provider × Platform × Device Diff** - clustered bar chart compares final "done → pay" conversion rates by payment method, platform, and device. SplitPay underperforms across all, but the gap is most critical for iOS App, while Card and Web maintain normal levels.

## Interpretation of findings & Business insights & Recommendations

1) **Diff-in-Diff** shows a clear drop only for SplitPay on the "done → pay" step;

2) In the device and platform breakdown, *desktop* and *android* remain stable, while *iOS* - particularly the *iOS App* - shows a sharp decline in conversion (r_done_to_pay ≈ 0.2). *iOS Web* version has a mild decline (r_done_to_pay ≈ 0.4), so the issue is localized to the iOS App SDK, not the global API;

3) SplitPay logs show much higher discount_error share (≈ 0.7) for *iOS App* users → the issue originates from the SplitPay SDK rather than from user behavior;

4) **Recommendations**:

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
