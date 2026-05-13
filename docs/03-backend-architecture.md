# 03 · Backend Architecture

This document describes the backend that powers both the **Pro‑Enroll**
(professional) and **Pro‑User** (customer) Flutter apps, plus the admin
web panel.

The architecture is intentionally **modular monolith first**, not
micro‑services. At the scale of Pondicherry + Karaikal (a few thousand
bookings/day at most in year 1) a single well‑structured backend will be
faster to build, cheaper to run, and easier to debug than micro‑services.
Module boundaries are clean so we can split later if we ever need to.

---

## 1. High‑level diagram

```
        ┌─────────────────────┐        ┌─────────────────────┐
        │   Pro-Enroll App    │        │    Pro-User App     │
        │   (Flutter, pros)   │        │ (Flutter, customers)│
        └─────────┬───────────┘        └─────────┬───────────┘
                  │ HTTPS / JSON                  │ HTTPS / JSON
                  │ WebSocket (live track)        │ WebSocket
                  ▼                                ▼
        ┌──────────────────────────────────────────────────┐
        │           Cloudflare  (DNS + WAF + CDN)          │
        └──────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌──────────────────────────────────────────────────┐
        │          NGINX / Caddy reverse proxy             │
        │          (TLS termination, rate limit)           │
        └──────────────────────┬───────────────────────────┘
                               │
              ┌────────────────┼────────────────────┐
              ▼                ▼                    ▼
     ┌────────────────┐ ┌────────────────┐ ┌─────────────────┐
     │  REST API      │ │  WebSocket /   │ │  Admin Web App  │
     │  (Node.js,     │ │  Socket.IO     │ │  (Next.js or    │
     │  NestJS)       │ │  Gateway       │ │  React)         │
     └───┬────────────┘ └───┬────────────┘ └───┬─────────────┘
         │                  │                  │
         ▼                  ▼                  ▼
   ┌─────────────────────────────────────────────────────┐
   │                Application services                 │
   │ ───────────────────────────────────────────────────│
   │  auth │ users │ pros │ kyc │ catalog │ search /    │
   │  geo  │ booking │ chat │ payment │ wallet │        │
   │  notification │ rating │ admin │ analytics         │
   └────────────────────────┬────────────────────────────┘
                            │
   ┌────────────────────────┼────────────────────────────┐
   ▼                        ▼                            ▼
 PostgreSQL 16          Redis 7                  Object storage
 + PostGIS              (cache, queues,           (AWS S3 /
 (primary DB)            pub-sub, locks)           DO Spaces)
                            │
                            ▼
                       BullMQ workers
                       (notifications,
                        invoices, payouts,
                        OTP, KYC)
                            │
                            ▼
       External services: MSG91 (SMS), WhatsApp Business API,
       Razorpay / Cashfree (payments), Google Maps / Mapbox,
       Karza / Digio / Hyperverge (Aadhaar+selfie KYC),
       Firebase Cloud Messaging (push), Exotel (call masking),
       Sentry (errors), Grafana Cloud (metrics + logs).
```

---

## 2. Recommended tech stack

| Layer                    | Choice                                                  | Why                                                                 |
| ------------------------ | ------------------------------------------------------- | ------------------------------------------------------------------- |
| Mobile apps              | **Flutter 3.x** (Dart)                                  | One codebase for Android + iOS, fast UI, great offline support.     |
| API server               | **Node.js 20 + NestJS** (TypeScript)                    | Strong typing, modules map to business domains, good ecosystem.     |
| Realtime (live tracking, chat) | **Socket.IO** on the same Node service or separate small service | Simple, battle‑tested, works over websocket + fallback.       |
| Primary DB               | **PostgreSQL 16 + PostGIS extension**                   | ACID, JSONB, and PostGIS gives us `ST_DWithin` for geo‑search.      |
| Cache + queues + pub-sub | **Redis 7**                                             | Rate limiting, OTP store, BullMQ job queue, socket scaling.         |
| Object storage           | **AWS S3** or **DigitalOcean Spaces** or **Cloudflare R2** | Profile photos, KYC docs, job before/after photos & videos.       |
| CDN / WAF                | **Cloudflare** (free tier OK to start)                  | DDoS protection, image transforms, edge cache.                      |
| Search (Phase 2)         | **Meilisearch** or Postgres full‑text                   | Tamil tokenizer, typo tolerant, fast.                               |
| Admin panel              | **Next.js 14** + Tailwind + shadcn/ui                   | Fast to build, server actions for admin tasks.                      |
| Auth                     | OTP via **MSG91** + **JWT** access / refresh tokens     | Phone‑first market.                                                 |
| Payments                 | **Razorpay** (primary), Cashfree as backup              | UPI, cards, netbanking, payouts to pros.                            |
| Maps                     | **Google Maps SDK** (Flutter) + **Mapbox** as fallback  | Routing, ETA, place autocomplete.                                   |
| KYC                      | **Karza / Hyperverge / Digio**                          | Aadhaar OKYC, selfie liveness, face match.                          |
| Notifications            | **FCM** (push), **MSG91** (SMS), **WhatsApp BSP** (Gupshup / AiSensy) | Triple‑channel reach.                                  |
| Observability            | **Sentry** + **Grafana Cloud** (Loki + Prometheus)      | Errors, metrics, logs in one place.                                 |
| CI/CD                    | **GitHub Actions** + Docker + **Ansible** or Coolify    | Cheap, reliable, automated deploys.                                 |
| Hosting                  | **Hetzner Cloud** or **AWS Mumbai (ap-south-1)**        | Hetzner is cheapest with great network; AWS for India data residency. |

### Why NestJS over Django / Laravel / Go?

- Same language (TypeScript) as the admin panel and similar to Dart used
  in Flutter → smaller mental switch for the team.
- Excellent module / dependency‑injection pattern → modular monolith.
- Mature ecosystem for queues (BullMQ), websockets (Socket.IO), validation
  (class‑validator), ORM (Prisma / TypeORM).

If the team strongly prefers Python, **Django + DRF + Celery** is an
equally valid choice with the same architecture.

---

## 3. Module breakdown (modular monolith)

Each module is a folder under `src/modules/`. They expose internal
services and HTTP controllers.

| Module          | Responsibilities                                                                                            |
| --------------- | ----------------------------------------------------------------------------------------------------------- |
| `auth`          | OTP send/verify, JWT issue/refresh, device sessions, force‑logout, role gating (customer / pro / admin).    |
| `users`         | Customer profile, addresses, saved pros, family sub‑profiles.                                               |
| `pros`          | Pro profile, skills, work radius, availability toggle, live location updates, earnings summary.             |
| `kyc`           | Aadhaar OKYC, selfie + liveness, document uploads, admin approval, status webhooks.                         |
| `catalog`       | Categories, sub‑categories, pricing bands, service icons, supported cities.                                 |
| `search`        | Geo + category + filter search; uses PostGIS + Redis cache; returns ranked pro list.                        |
| `booking`       | Create / accept / start / complete / cancel booking, slot mgmt, status machine, before/after photos.        |
| `chat`          | In‑booking text chat with attachment support; stored in Postgres; realtime via Socket.IO.                   |
| `calls`         | Call masking via Exotel; routes pro<->customer through a virtual number.                                    |
| `payment`       | Razorpay orders, refunds, escrow hold, commission split, wallet topup, payout to pro bank/UPI.              |
| `wallet`        | Pro earnings wallet, customer cashback wallet, ledger entries.                                              |
| `rating`        | Post‑service rating + review; recalculates pro aggregate rating; fraud flagging.                            |
| `notification`  | Templates, send via FCM / SMS / WhatsApp; dedupe; user preferences.                                          |
| `admin`         | Internal API consumed by the admin web panel; KYC review, dispute, refund, broadcast.                       |
| `analytics`     | Funnel events, business KPIs, exported daily to data lake.                                                  |
| `geo`           | Reverse geocoding, distance calc, geofencing per city, service‑area checks.                                 |
| `webhook`       | Inbound webhooks from Razorpay, MSG91 DLR, KYC provider; verified by signature.                             |

---

## 4. Key flows

### 4.1 Pro onboarding

1. `POST /v1/auth/otp/send` → MSG91 → SMS OTP.
2. `POST /v1/auth/otp/verify` → returns JWT + role=`pro_pending`.
3. `POST /v1/pros/profile` → personal info, languages, skills.
4. `POST /v1/kyc/aadhaar` → KYC provider OKYC; status `pending`.
5. `POST /v1/kyc/selfie` → selfie + liveness; provider returns match score.
6. Admin reviews in web panel → `kyc.status=verified` → role becomes `pro`.
7. App receives push: "You are now live. Turn on availability."

### 4.2 Customer booking

1. `GET /v1/categories` (cached at edge).
2. `GET /v1/search/pros?cat=ac&lat=..&lng=..&radius=5` → ranked pros.
3. `GET /v1/pros/:id` → full profile.
4. `POST /v1/bookings` → creates booking, status=`pending_pro_acceptance`,
   sends FCM push to top 3 nearest matching pros.
5. First pro to tap *Accept* gets it (Redis lock on booking id).
6. Customer sees pro on map (Socket.IO room `booking:<id>`).
7. Pro taps *Start* → state=`in_progress`. Uploads before photo.
8. Pro taps *Complete*, enters final amount, uploads after photo.
9. Customer pays via Razorpay or marks "Paid in cash" → Razorpay holds
   funds in escrow for 4 hours (or instant for COD acknowledgement).
10. Customer rates the pro → ratings recalculated.
11. T+4h: commission deducted, balance moved to pro wallet → daily payout.

### 4.3 Live location tracking

- Pro app sends location every **10 s** while a booking is `accepted` or
  `in_progress` via Socket.IO event `pro:location`.
- API server pushes it to room `booking:<id>` so the customer app sees
  movement.
- Idle pros (no booking) send location only every **2 minutes** to save
  battery; used only for search index, not realtime.

### 4.4 Payments & payouts

- Customer pays → Razorpay → webhook → `payment.success`.
- Platform commission (e.g. 12 %) and GST are deducted; rest is credited
  to pro wallet ledger.
- Daily 19:00 IST: payout worker batches pro wallet balances ≥ ₹100 and
  initiates Razorpay Payouts to their UPI/bank.
- Reconciliation report generated daily and emailed to finance.

---

## 5. Background jobs (BullMQ)

| Queue                | Purpose                                                       | Frequency / trigger              |
| -------------------- | ------------------------------------------------------------- | -------------------------------- |
| `otp.send`           | Send SMS OTP                                                  | On `auth/otp/send`               |
| `notification.push`  | FCM push                                                      | On booking events                |
| `notification.wa`    | WhatsApp templated message                                    | On booking confirm / reminder    |
| `kyc.poll`           | Poll KYC provider for async status                            | Every 60 s for pending KYCs      |
| `payout.daily`       | Pay pros their wallet balance                                 | Cron 19:00 IST daily             |
| `invoice.generate`   | Generate GST invoice PDF, upload to S3                        | After payment success            |
| `analytics.export`   | Push events to data warehouse                                 | Cron hourly                      |
| `search.reindex`     | Rebuild Meilisearch index                                     | Cron nightly + on pro update     |
| `dispute.sla`        | Escalate disputes older than 4 h to senior support            | Cron every 15 min                |

---

## 6. Security

- **TLS everywhere** (Cloudflare → NGINX → app); HSTS enabled.
- **JWT** access token (15 min) + refresh token (30 days, rotating).
- **OWASP top‑10** controls: input validation (class‑validator), output
  encoding, parameterised SQL via Prisma, rate limiting (Redis token
  bucket), CSRF for admin web only.
- **PII at rest**: Aadhaar number is stored only as last 4 digits + a
  hash; full number never persisted. KYC documents in private S3 bucket
  with KMS encryption and signed‑URL access.
- **App attestation**: Play Integrity / App Attest token verified on
  login to deter rooted‑device fraud.
- **Audit log**: every admin action (KYC approval, refund, manual
  payout) is written to an append‑only `audit_log` table.
- **DPDP Act 2023 compliance**: explicit consent screen for KYC, data
  retention policy (KYC docs deleted 7 days after pro leaves the
  platform), nominated Data Protection Officer.
- **Webhook signature verification** for Razorpay & KYC callbacks.
- **WAF rules**: Cloudflare blocks scrapers, brute‑force OTP, etc.

---

## 7. Scaling roadmap

| Stage | Bookings / day | Architecture changes                                                                                  |
| ----: | -------------: | ----------------------------------------------------------------------------------------------------- |
|  MVP  |       0 – 200  | Single VM (4 vCPU / 8 GB) running API + workers + Postgres + Redis. Daily backups.                    |
| Pilot |   200 – 2 000  | Split DB to its own VM, add managed Postgres, separate worker VM, Cloudflare in front.                |
| Scale |  2 000 – 10 000 | 2× API behind load balancer, managed Postgres with read replica, Redis Cluster, S3 + CDN, autoscale. |
| Multi-city | > 10 000   | Region sharding by city, Meilisearch cluster, data warehouse (BigQuery / Redshift), feature flags.    |

See [`04-server-cost-and-specifications.md`](04-server-cost-and-specifications.md)
for concrete VM specifications and prices.

---

## 8. Why not Firebase / Supabase only?

We **can** use Firebase Auth + Firestore for the MVP, and it would ship
fast. But for this product we recommend a real backend because:

- **Geo search with radius** is awkward in Firestore (no native geo
  index that supports `ST_DWithin`). PostGIS makes it trivial.
- **Server‑side commission + payout logic** needs careful transaction
  handling. Postgres is much safer than client‑side rules.
- **Aadhaar / KYC** requires server‑side calls with private API keys.
- **Cost at scale** — Firestore charges per read; a category list with
  100 pros viewed 100 K times/day = 10 M reads, expensive.
- **Vendor lock‑in** — we want to keep control of pro & booking data.

We still use **FCM** (Firebase Cloud Messaging) for push because it’s the
de‑facto standard and free.
