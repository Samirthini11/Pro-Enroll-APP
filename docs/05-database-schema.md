# 05 · Database Schema (PostgreSQL + PostGIS)

This is the core schema used by both Flutter apps and the admin web
panel. It is intentionally simple — most product complexity is handled
at the application layer.

Conventions:
- All tables have `id BIGSERIAL PRIMARY KEY`, `created_at`, `updated_at`.
- Soft delete via `deleted_at TIMESTAMPTZ NULL`.
- Money in **paise** (`BIGINT`) — never floats.
- Geo points in `geography(Point, 4326)` for `ST_DWithin` queries.
- Enum columns use `TEXT CHECK (...)` for easy migration.

---

## 1. Reference / catalog tables

```sql
CREATE TABLE city (
  id           BIGSERIAL PRIMARY KEY,
  name         TEXT NOT NULL,            -- 'Pondicherry', 'Karaikal', ...
  state        TEXT NOT NULL,            -- 'Puducherry' / 'Tamil Nadu'
  centroid     geography(Point, 4326) NOT NULL,
  radius_km    INTEGER NOT NULL DEFAULT 25,
  is_live      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE category (
  id           BIGSERIAL PRIMARY KEY,
  code         TEXT NOT NULL UNIQUE,     -- 'ac', 'plumber', 'ro', 'car', 'bike', 'fridge', 'wash'
  name_en      TEXT NOT NULL,
  name_ta      TEXT NOT NULL,
  icon_url     TEXT,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  base_visit_fee_paise BIGINT NOT NULL DEFAULT 15000  -- default ₹150
);

CREATE TABLE sub_category (
  id           BIGSERIAL PRIMARY KEY,
  category_id  BIGINT NOT NULL REFERENCES category(id),
  code         TEXT NOT NULL,            -- 'ac_gas_refill', 'ac_install'
  name_en      TEXT NOT NULL,
  name_ta      TEXT NOT NULL,
  typical_price_min_paise BIGINT,
  typical_price_max_paise BIGINT,
  UNIQUE (category_id, code)
);
```

---

## 2. Users (customers)

```sql
CREATE TABLE app_user (
  id            BIGSERIAL PRIMARY KEY,
  phone_e164    TEXT NOT NULL UNIQUE,    -- '+919812345678'
  name          TEXT,
  email         TEXT,
  preferred_lang TEXT NOT NULL DEFAULT 'ta' CHECK (preferred_lang IN ('ta','en','fr')),
  status        TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','blocked','deleted')),
  wallet_balance_paise BIGINT NOT NULL DEFAULT 0,
  city_id       BIGINT REFERENCES city(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ
);

CREATE TABLE user_address (
  id            BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  label         TEXT NOT NULL,           -- 'Home', 'Office'
  line1         TEXT NOT NULL,
  line2         TEXT,
  landmark      TEXT,
  city          TEXT NOT NULL,
  pincode       TEXT NOT NULL,
  geo           geography(Point, 4326) NOT NULL,
  is_default    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_user_address_user ON user_address(user_id);
CREATE INDEX idx_user_address_geo  ON user_address USING GIST (geo);
```

---

## 3. Professionals (pros)

```sql
CREATE TABLE pro (
  id                 BIGSERIAL PRIMARY KEY,
  phone_e164         TEXT NOT NULL UNIQUE,
  full_name          TEXT NOT NULL,
  display_name       TEXT,
  photo_url          TEXT,
  languages          TEXT[] NOT NULL DEFAULT ARRAY['ta'],
  city_id            BIGINT NOT NULL REFERENCES city(id),
  home_geo           geography(Point, 4326) NOT NULL,  -- registered address
  current_geo        geography(Point, 4326),           -- last live update
  current_geo_at     TIMESTAMPTZ,
  work_radius_km     INTEGER NOT NULL DEFAULT 5,
  is_available       BOOLEAN NOT NULL DEFAULT FALSE,   -- pro toggled "Online"
  kyc_status         TEXT NOT NULL DEFAULT 'pending'
                     CHECK (kyc_status IN ('pending','in_review','verified','rejected')),
  rating_avg         NUMERIC(3,2) NOT NULL DEFAULT 0,
  rating_count       INTEGER NOT NULL DEFAULT 0,
  jobs_completed     INTEGER NOT NULL DEFAULT 0,
  pro_score          INTEGER NOT NULL DEFAULT 50,      -- 0..100 ranking
  visit_fee_paise    BIGINT NOT NULL DEFAULT 15000,
  status             TEXT NOT NULL DEFAULT 'active'
                     CHECK (status IN ('active','suspended','deleted')),
  subscription_plan  TEXT NOT NULL DEFAULT 'free'
                     CHECK (subscription_plan IN ('free','basic','plus')),
  subscription_until DATE,
  bank_account_no    TEXT,
  bank_ifsc          TEXT,
  upi_id             TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at         TIMESTAMPTZ
);

CREATE INDEX idx_pro_current_geo ON pro USING GIST (current_geo);
CREATE INDEX idx_pro_city_avail  ON pro (city_id, is_available, kyc_status);
CREATE INDEX idx_pro_score       ON pro (pro_score DESC);

CREATE TABLE pro_skill (
  pro_id        BIGINT NOT NULL REFERENCES pro(id) ON DELETE CASCADE,
  category_id   BIGINT NOT NULL REFERENCES category(id),
  experience_yr INTEGER NOT NULL DEFAULT 0,
  is_primary    BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (pro_id, category_id)
);

CREATE TABLE pro_sub_skill (
  pro_id           BIGINT NOT NULL REFERENCES pro(id) ON DELETE CASCADE,
  sub_category_id  BIGINT NOT NULL REFERENCES sub_category(id),
  PRIMARY KEY (pro_id, sub_category_id)
);

CREATE TABLE pro_document (
  id        BIGSERIAL PRIMARY KEY,
  pro_id    BIGINT NOT NULL REFERENCES pro(id) ON DELETE CASCADE,
  kind      TEXT NOT NULL CHECK (kind IN ('aadhaar','pan','selfie','shop_photo','cert','other')),
  s3_key    TEXT NOT NULL,
  status    TEXT NOT NULL DEFAULT 'pending'
            CHECK (status IN ('pending','approved','rejected')),
  meta      JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE pro_kyc_event (
  id          BIGSERIAL PRIMARY KEY,
  pro_id      BIGINT NOT NULL REFERENCES pro(id) ON DELETE CASCADE,
  provider    TEXT NOT NULL,        -- 'karza' | 'hyperverge'
  ref_id      TEXT NOT NULL,
  result      TEXT,                  -- 'match', 'no_match'
  score       NUMERIC(5,2),
  raw         JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 4. Booking & job flow

```sql
CREATE TABLE booking (
  id                 BIGSERIAL PRIMARY KEY,
  code               TEXT NOT NULL UNIQUE,           -- 'PE-2026-000123'
  user_id            BIGINT NOT NULL REFERENCES app_user(id),
  pro_id             BIGINT REFERENCES pro(id),      -- null until accepted
  category_id        BIGINT NOT NULL REFERENCES category(id),
  sub_category_id    BIGINT REFERENCES sub_category(id),
  address_id         BIGINT NOT NULL REFERENCES user_address(id),
  problem_text       TEXT,
  preferred_slot     TSTZRANGE NOT NULL,             -- requested window
  scheduled_at       TIMESTAMPTZ,                    -- final confirmed
  status             TEXT NOT NULL DEFAULT 'pending_acceptance'
                     CHECK (status IN (
                       'pending_acceptance','accepted','on_the_way',
                       'in_progress','completed','cancelled','no_show')),
  visit_fee_paise    BIGINT NOT NULL,
  quoted_amount_paise BIGINT,
  final_amount_paise BIGINT,
  commission_paise   BIGINT,
  payment_mode       TEXT CHECK (payment_mode IN ('upi','card','netbanking','wallet','cash')),
  payment_status     TEXT NOT NULL DEFAULT 'pending'
                     CHECK (payment_status IN ('pending','paid','refunded','failed')),
  cancellation_reason TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_at        TIMESTAMPTZ,
  started_at         TIMESTAMPTZ,
  completed_at       TIMESTAMPTZ,
  cancelled_at       TIMESTAMPTZ
);

CREATE INDEX idx_booking_user      ON booking(user_id, created_at DESC);
CREATE INDEX idx_booking_pro       ON booking(pro_id, created_at DESC);
CREATE INDEX idx_booking_status    ON booking(status);

CREATE TABLE booking_photo (
  id          BIGSERIAL PRIMARY KEY,
  booking_id  BIGINT NOT NULL REFERENCES booking(id) ON DELETE CASCADE,
  kind        TEXT NOT NULL CHECK (kind IN ('problem','before','after','invoice')),
  uploader    TEXT NOT NULL CHECK (uploader IN ('user','pro')),
  s3_key      TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE booking_offer (
  -- N pros that the system pinged for a job; first to accept wins.
  id          BIGSERIAL PRIMARY KEY,
  booking_id  BIGINT NOT NULL REFERENCES booking(id) ON DELETE CASCADE,
  pro_id      BIGINT NOT NULL REFERENCES pro(id),
  offered_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded   TEXT CHECK (responded IN ('accepted','rejected','expired')),
  responded_at TIMESTAMPTZ
);
```

---

## 5. Chat & live tracking

```sql
CREATE TABLE chat_message (
  id          BIGSERIAL PRIMARY KEY,
  booking_id  BIGINT NOT NULL REFERENCES booking(id) ON DELETE CASCADE,
  sender      TEXT NOT NULL CHECK (sender IN ('user','pro','system')),
  text        TEXT,
  attachment_s3_key TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_chat_booking ON chat_message(booking_id, id);

-- We do not persist every GPS ping; we keep only the last point on `pro.current_geo`.
-- Optionally store a track for completed bookings for proof-of-service.
CREATE TABLE booking_track (
  booking_id  BIGINT NOT NULL REFERENCES booking(id) ON DELETE CASCADE,
  point       geography(Point, 4326) NOT NULL,
  at          TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (booking_id, at)
);
```

---

## 6. Payments, wallet, payouts

```sql
CREATE TABLE payment (
  id           BIGSERIAL PRIMARY KEY,
  booking_id   BIGINT NOT NULL REFERENCES booking(id),
  pg_order_id  TEXT NOT NULL UNIQUE,    -- razorpay order id
  pg_payment_id TEXT,
  amount_paise BIGINT NOT NULL,
  status       TEXT NOT NULL CHECK (status IN ('created','authorized','captured','failed','refunded')),
  method       TEXT,
  raw          JSONB,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE wallet_ledger (
  id           BIGSERIAL PRIMARY KEY,
  owner_kind   TEXT NOT NULL CHECK (owner_kind IN ('user','pro','platform')),
  owner_id     BIGINT NOT NULL,
  booking_id   BIGINT REFERENCES booking(id),
  kind         TEXT NOT NULL CHECK (kind IN
               ('credit_payment','debit_commission','debit_payout',
                'credit_cashback','debit_refund','adjustment')),
  amount_paise BIGINT NOT NULL,        -- positive = credit, negative = debit
  balance_after_paise BIGINT NOT NULL,
  note         TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_wallet_owner ON wallet_ledger(owner_kind, owner_id, id DESC);

CREATE TABLE payout (
  id           BIGSERIAL PRIMARY KEY,
  pro_id       BIGINT NOT NULL REFERENCES pro(id),
  amount_paise BIGINT NOT NULL,
  pg_payout_id TEXT,
  status       TEXT NOT NULL CHECK (status IN ('queued','processing','paid','failed')),
  raw          JSONB,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 7. Ratings & disputes

```sql
CREATE TABLE rating (
  id          BIGSERIAL PRIMARY KEY,
  booking_id  BIGINT NOT NULL UNIQUE REFERENCES booking(id),
  user_id     BIGINT NOT NULL REFERENCES app_user(id),
  pro_id      BIGINT NOT NULL REFERENCES pro(id),
  stars       SMALLINT NOT NULL CHECK (stars BETWEEN 1 AND 5),
  text        TEXT,
  tags        TEXT[],                  -- 'on_time','clean','fair_price'
  is_flagged  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE dispute (
  id           BIGSERIAL PRIMARY KEY,
  booking_id   BIGINT NOT NULL REFERENCES booking(id),
  raised_by    TEXT NOT NULL CHECK (raised_by IN ('user','pro')),
  reason       TEXT NOT NULL,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'open'
               CHECK (status IN ('open','in_review','resolved','rejected')),
  resolution   TEXT,
  refund_paise BIGINT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at  TIMESTAMPTZ
);
```

---

## 8. Notifications, devices, OTP

```sql
CREATE TABLE device (
  id           BIGSERIAL PRIMARY KEY,
  owner_kind   TEXT NOT NULL CHECK (owner_kind IN ('user','pro','admin')),
  owner_id     BIGINT NOT NULL,
  fcm_token    TEXT NOT NULL,
  platform     TEXT NOT NULL CHECK (platform IN ('android','ios','web')),
  app_version  TEXT,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_device_owner ON device(owner_kind, owner_id);

CREATE TABLE notification_log (
  id           BIGSERIAL PRIMARY KEY,
  owner_kind   TEXT NOT NULL,
  owner_id     BIGINT NOT NULL,
  channel      TEXT NOT NULL CHECK (channel IN ('push','sms','whatsapp','email')),
  template     TEXT NOT NULL,
  payload      JSONB,
  status       TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- OTP is kept in Redis (TTL 5 min). The table below is only for audit.
CREATE TABLE otp_audit (
  id          BIGSERIAL PRIMARY KEY,
  phone_e164  TEXT NOT NULL,
  purpose     TEXT NOT NULL,            -- 'login','reset','kyc'
  status      TEXT NOT NULL,            -- 'sent','verified','failed','expired'
  ip          INET,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 9. Admin & audit

```sql
CREATE TABLE admin_user (
  id          BIGSERIAL PRIMARY KEY,
  email       TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('support','ops','finance','superadmin')),
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_log (
  id          BIGSERIAL PRIMARY KEY,
  actor_kind  TEXT NOT NULL,            -- 'admin','system','user','pro'
  actor_id    BIGINT,
  action      TEXT NOT NULL,            -- 'kyc.approve','booking.refund'
  target_kind TEXT,
  target_id   BIGINT,
  meta        JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_target ON audit_log(target_kind, target_id, created_at DESC);
```

---

## 10. Example geo‑search query

Find verified, online AC mechanics within 5 km of customer, sorted by
`pro_score` then distance:

```sql
SELECT
  p.id,
  p.display_name,
  p.rating_avg,
  p.visit_fee_paise,
  ST_Distance(p.current_geo, $1) / 1000.0 AS distance_km
FROM pro p
JOIN pro_skill s ON s.pro_id = p.id AND s.category_id = $2
WHERE p.kyc_status   = 'verified'
  AND p.status       = 'active'
  AND p.is_available = TRUE
  AND p.current_geo_at > NOW() - INTERVAL '5 minutes'
  AND ST_DWithin(p.current_geo, $1, 5000)   -- 5 km
ORDER BY p.pro_score DESC, distance_km ASC
LIMIT 20;
```

Parameters: `$1` = customer geography point, `$2` = category id (e.g.
`ac`).

---

## 11. Migrations & backups

- Use **Prisma Migrate** (or Flyway / Liquibase for Django) — all
  schema changes in version control.
- **Daily logical backup** with `pg_dump` to object storage.
- **Continuous PITR** via managed Postgres provider from Pilot stage
  onward.
- Quarterly **restore drill** on a staging box.
