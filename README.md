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











