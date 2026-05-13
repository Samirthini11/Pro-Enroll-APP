# 02 · Feature Suggestions — Maximize the Idea

This document lists concrete ideas to push the basic Pro‑Enroll / Pro‑User
concept into a strong, defensible product for the Pondicherry / Karaikal
market. Items are grouped into **Must‑have (MVP)**, **Differentiators (v1.x)**
and **Growth / moat (v2 and beyond)**.

---

## A. Must‑have (MVP, ship in v1)

These are the minimum features for the platform to be useful and safe.

### Both apps
- Phone OTP login (MSG91 / Firebase Auth).
- Tamil + English UI from day one. French as a stretch goal for Pondy.
- Push notifications (Firebase Cloud Messaging).
- In‑app chat (text only) between customer and pro for the active booking.
- In‑app calling via masked phone numbers (Exotel / Knowlarity) so the
  pro’s real number is not exposed.
- Crash reporting (Sentry / Firebase Crashlytics).
- Force‑update screen for old app versions.

### Pro‑Enroll App
- Aadhaar + selfie KYC with face match.
- Category + sub‑skill picker (multi‑select).
- Set work radius (3 / 5 / 10 / 20 km).
- Online / Offline toggle.
- Live location (background, with battery‑safe defaults).
- Job feed → accept / reject within 60 seconds (auto‑reject after that).
- Earnings page (today / week / month).
- Bank account + UPI for payouts.

### Pro‑User App
- Browse by category with big icons (Tamil + English labels).
- Search box with auto‑complete (“AC”, “Plumber”, “குளிர்சாதனம்”…).
- Map view + list view of nearby pros.
- Pro profile with verified badge, ratings, sample photos.
- Book a visit with date/time slot + problem description + photos.
- Razorpay / UPI payment + cash on service.
- 5‑star rating + text review post‑service.

### Admin Web Panel
- KYC approval queue.
- Booking and dispute view.
- Refund / cancel.
- Push‑notification broadcaster.
- Revenue dashboard.

---

## B. Differentiators (v1.x, ship within 3 months of launch)

These are the “why us, not Justdial / Sulekha” features.

1. **Transparent fixed visit fee.** Every pro publishes a base visit fee
   (e.g. AC mechanic ₹150). Customer sees it before booking. No haggling.
2. **Price estimator.** For common jobs (AC gas refill, RO filter change,
   tap leak, fridge gas, bike puncture) the app shows a typical price
   range derived from past completed jobs in the area. Builds trust.
3. **Job photo + video proof.** Pro uploads a “before” and “after” photo
   of the job. Stored as evidence in case of disputes.
4. **Tamil voice search.** Use device speech‑to‑text → match to category
   keywords. Huge for semi‑literate users.
5. **WhatsApp booking confirmation.** Send the confirmation, OTP and
   tracking link via WhatsApp Business API. Reduces no‑shows.
6. **One‑tap rebook.** “Book the same Murugan again” shortcut on the
   home screen.
7. **SOS button** on the customer side that calls a local support agent
   if the pro misbehaves or doesn’t show up.
8. **Pro Score** (internal) — a 0‑100 score from rating, on‑time arrival,
   acceptance rate, completion rate. Top‑scored pros get priority.
9. **Service warranty.** Customer can buy a 7 / 15 / 30‑day warranty on
   the job for ₹19 / ₹39 / ₹79. If the same problem recurs, the same pro
   re‑does it free; platform reimburses pro.
10. **“Today only” deals.** Discount on slow categories (e.g. AC service
    in monsoon) to balance demand.

---

## C. Growth & moat (v2 and beyond)

Things that make the platform hard to copy and create long‑term value.

### C.1 Supply side (pros)

1. **Pro Academy** — short Tamil video courses on AC servicing, RO
   troubleshooting, customer manners, billing, GST. Free for pros on
   ₹99 subscription. Builds skill and loyalty.
2. **Tools / spare‑parts marketplace.** Pros buy genuine spares at
   wholesale through the app. Reduces their cost, increases stickiness.
3. **Equipment loan partner** — tie up with a local NBFC for ₹10 K – ₹50 K
   loans for tools. Platform forwards verified KYC + earnings history.
4. **Health & accident insurance** — group cover at ₹30 / month for
   verified pros.
5. **Pro of the month** — local newspaper / Instagram feature for top
   pros. Almost free, gives pride.
6. **Referral bonus** — pro refers another pro → ₹100 once the new pro
   completes 5 jobs.
7. **Bilingual training certificates** that pros can show physically.

### C.2 Demand side (customers)

1. **Annual home maintenance plan (AMC).** ₹999 / year covers 2 AC
   services + 2 RO filter changes + 1 plumbing visit. High retention.
2. **Society / apartment partnerships.** A single QR code at the gate of
   a residential association → all residents get a small discount.
3. **Loyalty cashback wallet.** 2 % cashback into in‑app wallet, usable
   on next booking.
4. **WhatsApp chat‑bot** as an alternative entry point — search,
   booking, status — all from WhatsApp. Massive for non‑app users.
5. **Multi‑lingual UI** (Tamil, English, French, Telugu) — French for
   Pondy expats, Telugu for Cuddalore migrants.

### C.3 Operations / trust

1. **Background check tier.** Beyond Aadhaar, run an optional police
   verification via a 3rd party for ₹300 (paid by pro). Premium badge.
2. **GST invoice.** Auto‑generate a GST invoice for the customer. Useful
   for shops, offices, rentals.
3. **Dispute resolution SLA** — promised response in 4 hours, refund
   decision in 24 hours.
4. **Service quality audit.** Random anonymous test bookings every month.

### C.4 New verticals after pilot

Same supply pool can serve more demand:
- Construction labour (mason, helper, painter).
- Tutoring at home (school + Bharatanatyam + music).
- Beauty at home (haircut, threading, bridal).
- Home cleaning, deep cleaning, pest control.
- Event electricians (Pongal, Diwali, wedding).
- Tourist‑rental maintenance (very relevant in Pondy).

### C.5 B2B layer (Phase 3)

- **For property managers / Airbnb hosts in Pondy:** one‑click access to
  cleaning + AC + plumber + electrician. Monthly invoice.
- **For small offices and shops:** AMC for AC, RO, CCTV.
- **For schools / hostels in Karaikal:** scheduled inspection of RO,
  fans, ACs, washing machines.

### C.6 Data & AI (defensible long‑term)

- **Smart matching** — match customer to pro using rating + distance +
  acceptance rate + skill match. Re‑rank with ML once we have data.
- **Demand forecasting** — predict that AC bookings will spike in
  April–June; suggest pros to upskill in AC.
- **Fraud detection** — flag fake reviews, fake profiles, payment fraud.
- **Image quality check** — on uploaded job photos, auto‑detect blur or
  irrelevant images (TF Lite on device or server).

---

## D. UX / design suggestions specific to this market

1. **Big icons, big text.** Many users are 40+ and Tamil readers. Avoid
   tiny fonts.
2. **Tamil first, English secondary** on the same screen for important
   words (₹, OTP, Book Now → “Book செய்”).
3. **Offline‑friendly.** Cache the home screen, category list and the
   user’s last booking so the app opens even on 2G or in elevators.
4. **Low‑bandwidth images.** Use AVIF / WebP, lazy load, hold thumbnails.
5. **Bottom‑nav with 4 tabs** only: Home, Bookings, Wallet, Profile.
   Anything more is overwhelming.
6. **Voice search button** clearly visible — mic icon next to search.
7. **Trust banners on every screen** — “All pros are Aadhaar verified”
   and “Pay only after work is done.”
8. **Family sharing.** A senior citizen can let a son/daughter book on
   their behalf using a sub‑profile.

---

## E. Compliance & legal must‑haves

- T&C + Privacy Policy compliant with DPDP Act 2023.
- KYC stored encrypted; Aadhaar masked except last 4 digits.
- Payment via PA / PG licensed by RBI (Razorpay, Cashfree).
- GST registration for the platform.
- Shram Suvidha registration if employing more than 10 pros directly
  (we don’t; they are partners).
- Insurance disclosure (when added).
- Clear pro‑customer contract: platform is a marketplace, not an
  employer; pro is an independent contractor.

---

## F. Risks & mitigations

| Risk                                            | Mitigation                                                                |
| ----------------------------------------------- | ------------------------------------------------------------------------- |
| Pros go off‑platform after first job            | Masked numbers, loyalty wallet, AMC plans, insurance benefits, training.  |
| Fake reviews                                    | Only customers with completed paid bookings can review; ML fraud check.   |
| No‑shows by pros                                | Strikes system: 3 strikes = suspension; auto‑refund + reassign.           |
| Payment disputes                                | Escrow‑style hold for 4 hours; in‑app dispute flow with photo evidence.   |
| Low smartphone literacy of pros                 | 1‑hour onboarding by field agent in Tamil; printed quick‑start card.      |
| Seasonal demand (AC peaks summer)               | Cross‑train pros, push complementary categories in off‑season.            |
| Big player enters market                        | We already own verified supply + Tamil‑first UX + AMC subscribers.        |
