# Pro-Enroll Platform

A two-app, hyperlocal services marketplace built with Flutter, targeting
Pondicherry, Karaikal and nearby Tamil Nadu towns. The platform connects
verified blue‑collar professionals (AC mechanics, plumbers, electricians,
2‑wheeler / car mechanics, RO‑water service, fridge & washing machine
repair, etc.) with end‑users who need on‑demand home services.

The product is delivered as two Flutter mobile apps that share one backend:

| App                | Audience                       | Purpose                                                                 |
| ------------------ | ------------------------------ | ----------------------------------------------------------------------- |
| **Pro‑Enroll App** | Professionals / Service Pros   | Self‑enrollment, KYC verification, profile, location, jobs, earnings.   |
| **Pro‑User App**   | Customers / End users          | Search & filter professionals nearby, book a visit, pay, rate & review. |

> Tag‑line: **“Local skills. Verified hands. One tap away.”**

---

## Documents in this repository

All product, business and engineering documents live under [`docs/`](docs/):

1. [`01-product-overview.md`](docs/01-product-overview.md) — Vision, target market (Pondicherry / Karaikal), personas, revenue model.
2. [`02-feature-suggestions.md`](docs/02-feature-suggestions.md) — Suggestions to **maximize the idea** (features, growth hacks, differentiation).
3. [`03-backend-architecture.md`](docs/03-backend-architecture.md) — High‑level backend architecture, services, tech stack.
4. [`04-server-cost-and-specifications.md`](docs/04-server-cost-and-specifications.md) — Server **specifications and monthly cost** estimates for 3 scale stages.
5. [`05-database-schema.md`](docs/05-database-schema.md) — Core PostgreSQL schema (users, professionals, bookings, payments, reviews).
6. [`06-api-specification.md`](docs/06-api-specification.md) — REST API endpoints used by both Flutter apps.
7. [`07-flutter-app-structure.md`](docs/07-flutter-app-structure.md) — Recommended Flutter project structure, packages and screens for both apps.
8. [`08-launch-and-growth-roadmap.md`](docs/08-launch-and-growth-roadmap.md) — Pilot launch plan for Pondicherry & Karaikal, marketing and growth.

---

## Quick summary of the idea

**Problem.** In Pondicherry, Karaikal and nearby Tamil Nadu towns, finding a
trustworthy AC mechanic, plumber or RO‑water technician still depends on
word‑of‑mouth, paper pamphlets and random phone numbers stuck on walls.
Customers don’t know who is genuine, who is nearby, what the fair price is,
or whether the person will actually show up. Skilled professionals, on the
other hand, struggle to get a steady flow of jobs and have no digital
identity.

**Solution.** A hyperlocal, verified, two‑app marketplace:

- Professionals enroll through the **Pro‑Enroll App** with Aadhaar + phone +
  selfie + skill proof. Admin verifies them. Their live location decides
  which customers can see them.
- Customers open the **Pro‑User App**, pick a category (AC, plumber, car,
  bike, RO, fridge, washing machine, …), see verified pros nearby with
  ratings & price, and book a **home visit** at a chosen time slot.
- Payment is digital (UPI / cash on service). Platform charges a small
  commission + optional “featured listing” for pros.

**Why it works for Pondicherry / Karaikal.**
- Compact geography → fast pilot, easy logistics, low CAC.
- High smartphone + UPI penetration, bilingual (Tamil + English) population.
- Tourism + rental homes + middle‑class housing → recurring demand for AC,
  plumbing, RO and appliance repair.
- No dominant local player; UrbanCompany / Housejoy don’t serve these towns
  deeply.

See [`docs/01-product-overview.md`](docs/01-product-overview.md) and
[`docs/02-feature-suggestions.md`](docs/02-feature-suggestions.md) for the
full plan, and
[`docs/04-server-cost-and-specifications.md`](docs/04-server-cost-and-specifications.md)
for the infrastructure cost estimate.
