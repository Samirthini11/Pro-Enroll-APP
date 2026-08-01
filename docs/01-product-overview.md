# 01 · Product Overview & Market

## 1. Vision

> Build the most trusted hyperlocal marketplace for blue‑collar professionals
> in Pondicherry, Karaikal and the surrounding Tamil Nadu region — starting
> with home‑service categories (AC, plumbing, electrical, RO water, fridge,
> washing machine, 2‑wheeler & car mechanic) and expanding to construction,
> carpentry, painting, pest control and beauty services.

The platform is built as **two Flutter mobile applications** sharing one
backend:

- **Pro‑Enroll App** — for the service professional (the “Pro”).
- **Pro‑User App** — for the end customer.

## 2. Problem

| For customers                                                                                                                              | For professionals                                                                          |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------ |
| No reliable way to find a verified AC mechanic, plumber, RO technician.                                                                    | No digital identity, no steady job flow.                                                   |
| Price is unpredictable and often inflated.                                                                                                 | Heavy dependence on middlemen / agents who take 30–40% cut.                                |
| No accountability — pro may not turn up, may overcharge, may damage things.                                                                | No way to prove “I am genuine, I have done 200 jobs, I have 4.7 stars.”                    |
| Hard to compare options. Word‑of‑mouth is the only tool.                                                                                   | Cannot reach customers outside their own street / village.                                 |

## 3. Solution — Two‑App Marketplace

### 3.1 Pro‑Enroll App (Professional side)

Key flows:
1. **Sign up** with mobile number + OTP.
2. **KYC**: Aadhaar number, selfie + auto face match, address proof.
3. **Skill profile**: choose category (AC, plumber, bike mechanic, …),
   sub‑skills, years of experience, work radius (km).
4. **Document upload**: ID proof, optional certificate/training proof,
   shop photo, tools photo.
5. **Admin verification** → status: Pending / Verified / Rejected.
6. **Go live**: toggle availability (Online / Offline), share live GPS so
   only nearby customers see them.
7. **Receive jobs**: accept / reject, navigate via Google Maps, mark
   started, mark completed, collect payment.
8. **Earnings dashboard**: today / week / month, payouts, ratings.
9. **Boost / Featured listing** (paid) to appear on top of search results.

### 3.2 Pro‑User App (Customer side)

Key flows:
1. **Sign up / Login** with mobile + OTP.
2. **Set location** (auto‑detect or pick on map). City: Pondicherry,
   Karaikal, Cuddalore, Villupuram, Thirubuvanai, etc.
3. **Browse categories**: AC, Plumber, Electrician, Car Mechanic, Bike
   Mechanic, RO Water Service, Fridge, Washing Machine, Carpenter,
   Painter, Pest Control, Cleaning.
4. **Search & filter**: distance, rating, price band, availability now,
   language (Tamil / English / French).
5. **Pro profile**: photo, verified badge, ratings, completed jobs,
   sample work photos, base visit fee, languages.
6. **Book a visit**: pick date + time slot, write problem description,
   attach photos / short video of the broken appliance.
7. **Live tracking**: see pro on the map when on the way.
8. **Pay**: UPI (Razorpay / PhonePe / GPay) or cash on service.
9. **Rate & review** after the job.
10. **Re‑book the same pro** with one tap.

### 3.3 Admin Web Panel (3rd surface, not a mobile app)

For internal staff:
- Approve / reject KYC.
- Manage categories, price bands, cities.
- Resolve disputes, refunds.
- View revenue, commissions, payouts.
- Push notifications & promo campaigns.

## 4. Target market — Pondicherry, Karaikal & nearby

| City              | Approx. population | Why a good fit                                                       |
| ----------------- | -----------------: | -------------------------------------------------------------------- |
| Pondicherry (UT)  | ~ 950 K            | Tourists, rentals, French quarter, high AC density, dense housing.   |
| Karaikal          | ~ 220 K            | Coastal, fishing + agriculture + middle class, low competition.      |
| Cuddalore         | ~ 175 K            | Industrial belt, repair demand for appliances & 2‑wheelers.          |
| Villupuram        | ~ 110 K            | District HQ, growing residential.                                    |
| Tindivanam, Panruti, Neyveli, Thirubuvanai, Bahour | various | Daily commuter towns, RO & fridge demand. |

Why this region is ideal for a pilot:
- **Compact geography** — most areas are within a 30–60 km radius.
- **High UPI / smartphone adoption** even in semi‑urban areas.
- **Bilingual users** (Tamil + English, some French in Pondy) — Flutter’s
  i18n makes this easy.
- **Low CAC** — local Tamil radio, FM, auto‑rickshaw branding, temple
  notice boards, college campuses are cheap to advertise on.
- **No strong incumbent.** UrbanCompany / Housejoy / NoBroker do not serve
  these towns with verified pros.

## 5. Personas

### 5.1 “Murugan” — AC Mechanic, 34, Pondicherry
Owns a Bajaj bike, works alone, gets jobs from 2 local shops who take
30%. Has a feature phone + a basic Android. Wants more direct customers
and proof of his skill.

### 5.2 “Saraswathi” — Homemaker, 42, Karaikal
Her RO water purifier stopped working. Doesn’t know whom to call. Asks
neighbours, gets 3 phone numbers. Two don’t pick up, one quotes ₹1500
without seeing the unit. She wants someone verified, with a fixed visit
fee.

### 5.3 “Ravi” — College student, 21, Pondicherry
His bike has a starting problem. Wants a mechanic to come to the hostel
because pushing the bike 4 km is hard. Pays via UPI.

### 5.4 “Anjali” — Working professional, 29, Pondicherry
Owns a 2BHK flat. Needs a plumber on Sunday morning. Will pay extra for
guaranteed time slot.

## 6. Revenue model

Multiple streams, all small and stackable:

1. **Commission per completed job** — 10 – 15 % of the final amount.
2. **Pro subscription** (optional) — ₹ 99 / month for unlimited leads;
   free plan limited to 10 leads / month.
3. **Featured / Boost listing** — ₹ 20 – ₹ 50 per day to appear on top.
4. **Visit fee share** — pro charges a fixed inspection fee (e.g. ₹150);
   platform keeps ₹20.
5. **Spare parts marketplace (Phase 2)** — sell genuine spares (AC gas,
   RO membrane, fridge gas, bike parts) to pros at wholesale + 5 %.
6. **Insurance / warranty add‑on (Phase 2)** — customer pays ₹49 extra
   to get a 30‑day service warranty.
7. **Ads** — local hardware shops, AC dealers, two‑wheeler showrooms
   pay for in‑app banners.

## 7. Key differentiators

- **Verified pros only.** Aadhaar + selfie face match + admin review.
- **Hyperlocal radius.** Pros set 3 / 5 / 10 / 20 km work radius.
- **Tamil‑first UI** with English & French toggles.
- **Transparent visit fee** — shown before booking, no surprises.
- **One‑tap rebook** of the same pro — drives loyalty.
- **Offline‑friendly** — Flutter app caches profile, last jobs, OTP so it
  works on weak rural networks.
- **Female‑pro filter** for households that prefer a woman technician
  (cleaning, beauty, RO).
- **Tamil voice search** for users who can’t type — “AC sariya illa” →
  shows AC mechanics nearby.

## 8. Success metrics (first 6 months in pilot region)

| Metric                                  | Target  |
| --------------------------------------- | ------: |
| Verified pros onboarded                 | 1 500   |
| Active customers (monthly)              | 25 000  |
| Bookings / month                        | 6 000   |
| Avg. rating per completed job           | ≥ 4.4   |
| Repeat‑booking rate                     | ≥ 30 %  |
| Gross merchandise value (GMV) / month   | ₹ 30 L  |
| Net commission revenue / month          | ₹ 3.5 L |
