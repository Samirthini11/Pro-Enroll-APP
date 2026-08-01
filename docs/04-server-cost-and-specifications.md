# 04 · Server Cost & Specifications

This document gives concrete server **specifications** and **monthly cost
estimates** for three scale stages of the Pro‑Enroll / Pro‑User platform.

All prices are **indicative**, in **INR** at current 2026 rates, rounded
to the nearest ₹100. Use them for budgeting, not procurement quotes.

Region recommendation:

- **Hetzner Cloud (Falkenstein/Helsinki)** — cheapest, excellent network
  to India (~120 ms RTT). Best for MVP and pilot.
- **AWS Mumbai `ap-south-1`** or **DigitalOcean Bangalore** — lower
  latency (~30 ms), strong DPDP/data‑residency story. Recommended once
  bookings cross ~2 000 / day.

You can run **MVP on Hetzner**, then migrate to AWS Mumbai during Scale
stage. The architecture is portable.

---

## 1. Stage 1 — MVP (0 – 200 bookings/day)

**Goal:** ship to closed beta in Pondicherry with ~200 pros and ~1 000
customers. One technical owner managing infra.

| Component                  | Spec                                                                                  | Provider               | Monthly cost (₹) |
| -------------------------- | ------------------------------------------------------------------------------------- | ---------------------- | ---------------: |
| App server (API + workers + Postgres + Redis on one box) | **4 vCPU, 8 GB RAM, 80 GB NVMe** — Hetzner CPX31 (or DO 4GB) | Hetzner / DigitalOcean | 1 300 |
| Object storage (KYC docs, photos)  | 100 GB + 1 TB egress                                                          | Hetzner Storage Box / DO Spaces | 500 |
| Daily off‑site DB backups          | 50 GB                                                                         | Backblaze B2           | 200 |
| Domain + DNS + WAF + CDN           | Free tier                                                                     | Cloudflare             | 0 |
| TLS certificate                    | Free                                                                          | Let’s Encrypt          | 0 |
| Transactional SMS (10 K OTP)       | ₹0.18 / SMS × 10 000                                                          | MSG91                  | 1 800 |
| WhatsApp utility msgs (5 K)        | ₹0.115 / msg                                                                  | Gupshup / AiSensy      | 600 |
| Push notifications                 | Unlimited free                                                                | Firebase FCM           | 0 |
| Maps SDK + 28 K map loads / 5 K direction calls | within free monthly credit ($200)                                | Google Maps Platform   | 0 |
| KYC (Aadhaar OKYC + selfie liveness) — 300 KYC | ₹15 + ₹10 per KYC                                                | Karza / Hyperverge     | 7 500 |
| Payment gateway (Razorpay)         | 2 % MDR — variable, taken from GMV                                            | Razorpay               | passthrough |
| Call masking (Exotel) — 1 000 calls| ₹0.65 / min, ~3 min avg                                                       | Exotel                 | 2 000 |
| Error monitoring                   | Free dev plan                                                                 | Sentry                 | 0 |
| Logs & metrics                     | Free 50 GB                                                                    | Grafana Cloud Free     | 0 |
| Email (transactional)              | 5 K emails free                                                               | Resend / Brevo         | 0 |
| Admin web hosting                  | Free                                                                          | Vercel hobby           | 0 |
| **Total fixed monthly**            |                                                                               | **≈ ₹ 14 000 / month** |
| One‑time setup                     | Domain (₹900), Play & App Store accounts (₹2 000 + ₹8 800), Razorpay KYC (free) |                      | 11 700 one‑time |

> Realistic MVP burn: **~₹15 K – ₹20 K / month** including buffer for
> extra SMS / KYC.

### What that single 4 vCPU box can handle

- 200 – 400 bookings/day
- ~300 concurrent socket connections (live tracking)
- ~50 req/s API peak
- 10 K – 20 K daily active users

That is comfortably more than the closed‑beta phase needs.

### MVP server layout

```
Hetzner CPX31  (4 vCPU / 8 GB / 80 GB NVMe)
├── docker compose
│    ├── nginx          (reverse proxy + TLS)
│    ├── api            (NestJS, 2 instances via PM2 / cluster)
│    ├── ws             (Socket.IO, same image, different port)
│    ├── worker         (BullMQ, 1 instance)
│    ├── postgres-16    (with PostGIS) — local volume
│    └── redis-7        — local volume
└── cron: nightly pg_dump → Backblaze B2
```

---

## 2. Stage 2 — Pilot live launch (200 – 2 000 bookings/day)

**Goal:** Pondicherry + Karaikal open launch, marketing on, ~3 000 active
pros and ~50 K MAU. Add a junior DevOps.

| Component                              | Spec                                                          | Provider           | Monthly cost (₹) |
| -------------------------------------- | ------------------------------------------------------------- | ------------------ | ---------------: |
| API server #1 + #2                     | 2 × **4 vCPU / 8 GB**, behind load balancer                   | Hetzner / AWS      | 2 600 |
| Worker server                          | **2 vCPU / 4 GB**                                             | Hetzner            | 700 |
| Managed PostgreSQL (HA)                | **4 vCPU / 16 GB / 200 GB SSD**, daily PITR backups           | DO Managed Postgres / AWS RDS | 6 500 |
| Managed Redis                          | **2 GB plan**                                                 | DO Managed Redis / Upstash | 1 500 |
| Object storage                         | 500 GB + 5 TB egress                                          | S3 / DO Spaces     | 2 500 |
| Cloudflare Pro (WAF + image transforms)|                                                               | Cloudflare         | 1 700 |
| SMS (60 K OTP/month)                   | ₹0.18 × 60 000                                                | MSG91              | 10 800 |
| WhatsApp utility (40 K msgs)           |                                                               | Gupshup / AiSensy  | 4 600 |
| Google Maps (paid tier)                | Above $200 free credit                                        | Google             | 5 000 |
| KYC (1 500 KYC/month)                  |                                                               | Karza              | 37 500 |
| Call masking (8 K calls)               |                                                               | Exotel             | 16 000 |
| Sentry Team plan                       |                                                               | Sentry             | 2 500 |
| Grafana Cloud Pro                      |                                                               | Grafana            | 4 200 |
| Email transactional (50 K)             |                                                               | Brevo              | 1 800 |
| Backup storage (2 TB)                  |                                                               | Backblaze B2       | 1 200 |
| Admin & marketing site                 | Vercel Pro                                                    | Vercel             | 1 800 |
| Misc. (domain renewals, certs, DNS)    |                                                               |                    | 500 |
| **Total**                              |                                                               | **≈ ₹ 101 000 / month** |

> Realistic burn at pilot: **₹ 1.0 L – ₹ 1.3 L / month**. Most of the
> growth in cost is **KYC + SMS + call masking**, not servers.

### Pilot server layout

```
Cloudflare ──► LB ──► api-1, api-2 (NestJS, autoscale 2–4)
                          │
                          ├──► ws gateway (Socket.IO)
                          │
                          └──► worker (BullMQ, autoscale 1–3)

                  Managed Postgres HA (4 vCPU / 16 GB / 200 GB)
                          ├── read replica (analytics)
                          └── PITR backups → object storage
                  Managed Redis (2 GB)
                  S3 / Spaces (500 GB)
```

---

## 3. Stage 3 — Scale (2 000 – 10 000 bookings/day)

**Goal:** all of Tamil Nadu coastal belt + parts of Tamil Nadu interior;
~15 000 pros, ~500 K MAU, 8 person engineering team.

| Component                              | Spec                                                          | Monthly cost (₹) |
| -------------------------------------- | ------------------------------------------------------------- | ---------------: |
| API cluster (4 × 8 vCPU / 16 GB) + autoscale | Behind ALB                                              | 18 000 |
| Worker cluster (2 × 4 vCPU / 8 GB)     |                                                               | 5 000 |
| WebSocket dedicated (2 × 4 vCPU / 8 GB)| Sticky sessions                                               | 5 000 |
| Managed Postgres (8 vCPU / 32 GB / 500 GB) + 1 read replica | HA                                       | 35 000 |
| Managed Redis cluster                  | 8 GB                                                          | 6 500 |
| Meilisearch / OpenSearch (2 × 4 GB)    |                                                               | 6 000 |
| Object storage (3 TB + 50 TB egress)   |                                                               | 20 000 |
| Cloudflare Business                    |                                                               | 17 000 |
| SMS (300 K OTP)                        |                                                               | 54 000 |
| WhatsApp (250 K)                       |                                                               | 28 800 |
| Google Maps                            |                                                               | 35 000 |
| KYC (8 000/month)                      |                                                               | 2 00 000 |
| Call masking (60 K calls)              |                                                               | 1 20 000 |
| Sentry + Grafana + Datadog APM (Pro)   |                                                               | 25 000 |
| Email + WhatsApp marketing (500 K)     |                                                               | 18 000 |
| Backups + DR                           | 10 TB                                                         | 6 000 |
| Admin / marketing sites + microsites   | Vercel Enterprise                                             | 15 000 |
| Security tools (Snyk, Cloudflare Bot Mgmt) |                                                           | 12 000 |
| Data warehouse (BigQuery) + dashboards |                                                               | 20 000 |
| **Total**                              |                                                               | **≈ ₹ 6.5 L / month** |

> At Scale stage, **server cost is < 15 %** of total. The dominant cost
> is KYC, SMS, WhatsApp, calls and maps — i.e. per‑transaction costs
> that scale with revenue. This is expected and healthy.

---

## 4. Cost summary at a glance

| Stage  | Bookings/day | Infra ₹/month | Total ₹/month (incl. SMS/KYC/Maps) | Engineers |
| ------ | -----------: | ------------: | --------------------------------: | --------: |
| MVP    |      < 200   |       ~ 2 000 |                       ~ 15 000    |     1 – 2 |
| Pilot  | 200 – 2 000  |     ~ 14 000  |                     ~ 1 00 000    |     3 – 4 |
| Scale  | 2 000 – 10 000 |   ~ 80 000  |                      ~ 6 50 000   |     8 – 10 |

---

## 5. Per‑booking unit economics (illustrative)

Assume an average booking value of **₹500** with **12 % commission =
₹60** to the platform.

| Cost item per booking                          | INR     |
| ---------------------------------------------- | ------: |
| SMS OTP (avg 1.5 per booking)                  | 0.27 |
| WhatsApp confirmation + reminder               | 0.23 |
| Push notification                              | 0.00 |
| Call masking (avg 3 min × 1 call)              | 1.95 |
| Maps (geocode + 1 directions call)             | 0.40 |
| KYC amortised (one‑time per pro, ~10 jobs/mo)  | 2.50 |
| Payment gateway fees (2 % of ₹500)             | 10.00 |
| Server + storage amortised                     | 1.50 |
| **Total variable cost / booking**              | **≈ ₹ 17 / booking** |
| **Net contribution / booking**                 | **₹ 60 − ₹ 17 = ₹ 43** |

Contribution margin ≈ **72 %** of commission. Healthy.

---

## 6. Recommendations

1. **Start on Hetzner**. Move to AWS Mumbai only when DPDP residency or
   latency demands it. Saves ~60 % infra cost in year 1.
2. **Buy KYC in bulk** — Karza / Hyperverge give 30 – 40 % discount on
   annual prepaid packs once volume > 3 000/month.
3. **Throttle SMS** — try WhatsApp OTP first (cheaper), fallback to SMS
   only if message not delivered in 30 s. Saves up to 60 % of SMS cost
   for users on WhatsApp.
4. **Cache Google Maps** — cache geocoding + place autocomplete in
   Redis for 30 days. Routing/ETA cannot be cached.
5. **Compress images on the client** before upload (Flutter
   `flutter_image_compress`). Cuts S3 cost and upload time.
6. **Use Cloudflare R2** for object storage if egress dominates — R2
   has zero egress fees.
7. **Run staging on a single ₹400 VM** that auto‑shuts after office
   hours to save more.
