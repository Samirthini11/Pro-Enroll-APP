# 06 · REST API Specification (v1)

All endpoints are versioned under `/v1` and return JSON. Authentication
is **JWT Bearer** in the `Authorization` header except where noted as
*Public*. All timestamps are ISO‑8601 UTC. Money is in **paise**.

Roles:

| Role          | Token claim `role` | Issued after                                |
| ------------- | ------------------ | ------------------------------------------- |
| Customer      | `user`             | OTP verify on Pro‑User App                  |
| Pro (pending) | `pro_pending`      | OTP verify on Pro‑Enroll App, before KYC    |
| Pro (live)    | `pro`              | KYC approved                                |
| Admin         | `admin`            | Email + password login on web panel         |

Common error envelope:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "phone is invalid",
    "details": { "field": "phone" }
  }
}
```

---

## 1. Auth (Public)

### `POST /v1/auth/otp/send`
```json
// req
{ "phone": "+919812345678", "purpose": "login" }
// 200
{ "request_id": "abc123", "expires_in": 300 }
```

### `POST /v1/auth/otp/verify`
```json
// req
{ "request_id": "abc123", "otp": "456789", "app": "pro_enroll" }
// 200
{
  "access_token":  "eyJ...",          // 15 min
  "refresh_token": "eyJ...",          // 30 days
  "role": "pro_pending",
  "user": { "id": 42, "phone": "+919812345678", "name": null }
}
```

### `POST /v1/auth/refresh`
```json
{ "refresh_token": "eyJ..." }
```

### `POST /v1/auth/logout`
Invalidates refresh token. Requires `Authorization`.

---

## 2. Catalog (Public, cached at CDN)

### `GET /v1/cities`
List of supported cities.

### `GET /v1/categories?lang=ta`
List of categories with localised names + icons.

### `GET /v1/categories/:code/sub-categories`
List of sub‑categories with typical price range.

---

## 3. Customer (`role=user`)

### `GET /v1/me` — current user profile

### `PATCH /v1/me`
```json
{ "name": "Saraswathi", "preferred_lang": "ta", "city_id": 1 }
```

### `POST /v1/me/addresses`
```json
{
  "label": "Home",
  "line1": "12, Mission Street",
  "landmark": "Near Aurobindo Ashram",
  "city": "Pondicherry",
  "pincode": "605001",
  "lat": 11.9416,
  "lng": 79.8083,
  "is_default": true
}
```

### `GET /v1/me/addresses`
### `DELETE /v1/me/addresses/:id`

### `GET /v1/search/pros`
Query params:
- `category` (required) — e.g. `ac`
- `lat`, `lng` (required)
- `radius_km` (default 5, max 25)
- `sort` — `score` (default) | `distance` | `rating` | `price`
- `min_rating` — e.g. `4`
- `available_now` — `true`/`false`
- `language` — `ta`, `en`, `fr`

Response:
```json
{
  "items": [
    {
      "id": 73,
      "display_name": "Murugan AC Service",
      "photo_url": "https://...",
      "rating_avg": 4.7,
      "rating_count": 142,
      "jobs_completed": 380,
      "visit_fee_paise": 15000,
      "distance_km": 1.2,
      "languages": ["ta","en"],
      "is_available": true,
      "verified": true
    }
  ],
  "next_cursor": null
}
```

### `GET /v1/pros/:id`
Full pro profile, sample work photos, recent reviews.

### `POST /v1/bookings`
```json
{
  "pro_id": 73,                       // optional; if null, broadcast to top 3
  "category_id": 1,
  "sub_category_id": 4,
  "address_id": 88,
  "problem_text": "AC not cooling",
  "preferred_slot": {
    "start": "2026-05-14T10:00:00+05:30",
    "end":   "2026-05-14T12:00:00+05:30"
  },
  "photo_keys": ["uploads/abc.jpg", "uploads/def.jpg"]
}
// 201
{
  "id": 901,
  "code": "PE-2026-000901",
  "status": "pending_acceptance",
  "visit_fee_paise": 15000
}
```

### `GET /v1/bookings?status=active|past`
Paginated list.

### `GET /v1/bookings/:id`
Full booking with timeline and photos.

### `POST /v1/bookings/:id/cancel`
```json
{ "reason": "Plan changed" }
```

### `POST /v1/bookings/:id/rate`
```json
{ "stars": 5, "text": "Very polite, fixed in 30 min", "tags": ["on_time","fair_price"] }
```

### `POST /v1/bookings/:id/dispute`
```json
{ "reason": "Did not fix the problem", "description": "...", "photo_keys": [] }
```

### Payments

### `POST /v1/payments/order`
```json
{ "booking_id": 901, "amount_paise": 50000 }
// 200
{ "pg_order_id": "order_AbC", "key_id": "rzp_test_..." }
```

### `POST /v1/payments/verify`
Razorpay client signature verification.

### `POST /v1/payments/cod-ack`
Mark a booking as paid in cash (by pro). Triggers reconciliation.

---

## 4. Pro (`role=pro` and `pro_pending`)

### `POST /v1/pros/profile`     (`pro_pending`)
```json
{
  "full_name": "Murugan S.",
  "display_name": "Murugan AC Service",
  "languages": ["ta","en"],
  "city_id": 1,
  "home": { "lat": 11.94, "lng": 79.81, "address": "..." },
  "work_radius_km": 5,
  "skills": [
    { "category_code": "ac",      "experience_yr": 8, "is_primary": true },
    { "category_code": "fridge",  "experience_yr": 4, "is_primary": false }
  ],
  "sub_skills": ["ac_gas_refill", "ac_install"],
  "visit_fee_paise": 15000
}
```

### KYC

### `POST /v1/kyc/aadhaar/initiate`
```json
{ "aadhaar_last4": "1234" }
// 200
{ "kyc_ref_id": "kyc_abc" }
```

### `POST /v1/kyc/aadhaar/otp`
```json
{ "kyc_ref_id": "kyc_abc", "otp": "1234" }
```

### `POST /v1/kyc/selfie`
Multipart upload. Returns liveness/match score.

### `POST /v1/kyc/documents`
Multipart upload of additional documents.

### `GET /v1/kyc/status`
```json
{ "status": "verified", "rejected_reason": null, "updated_at": "..." }
```

### Availability & live location

### `PATCH /v1/pros/me/availability`
```json
{ "is_available": true }
```

### `POST /v1/pros/me/location`
```json
{ "lat": 11.943, "lng": 79.812, "accuracy_m": 8, "battery_pct": 73 }
```
(Also pushed via Socket.IO event `pro:location` while a booking is
active.)

### Jobs

### `GET /v1/pros/me/offers`
Active offers waiting for accept (TTL 60 s).

### `POST /v1/pros/me/offers/:id/accept`
### `POST /v1/pros/me/offers/:id/reject`

### `GET /v1/pros/me/bookings?status=...`

### `POST /v1/bookings/:id/on-the-way`
### `POST /v1/bookings/:id/start`
### `POST /v1/bookings/:id/complete`
```json
{ "final_amount_paise": 80000, "before_photo_keys": ["..."], "after_photo_keys": ["..."] }
```

### Earnings

### `GET /v1/pros/me/earnings?range=today|week|month`

### `GET /v1/pros/me/payouts`
List of payouts and statuses.

### `PATCH /v1/pros/me/bank`
```json
{ "bank_account_no": "1234567890", "bank_ifsc": "IDFB0001", "upi_id": "murugan@idfc" }
```

---

## 5. Chat (both roles)

### `GET /v1/bookings/:id/messages?after=<id>`
### `POST /v1/bookings/:id/messages`
```json
{ "text": "Reached the gate", "attachment_key": null }
```

Realtime via Socket.IO room `booking:<id>` (events `message`,
`pro:location`, `booking:status`).

---

## 6. Uploads

### `POST /v1/uploads/presign`
```json
{ "kind": "kyc", "mime": "image/jpeg" }
// 200
{ "key": "kyc/2026/05/abc.jpg", "url": "https://...", "method": "PUT", "expires_in": 600 }
```
Apps `PUT` the file directly to S3 with the signed URL, then send the
`key` back to the relevant endpoint.

---

## 7. Notifications

### `POST /v1/devices`
```json
{ "fcm_token": "...", "platform": "android", "app_version": "1.0.0" }
```

### `DELETE /v1/devices/:token`

### `PATCH /v1/me/notification-prefs`
```json
{ "push": true, "sms": true, "whatsapp": true, "email": false, "promotions": false }
```

---

## 8. Admin (`role=admin`, behind separate origin)

| Method | Path                                  | Purpose                                |
| ------ | ------------------------------------- | -------------------------------------- |
| GET    | `/v1/admin/kyc?status=in_review`      | KYC queue                              |
| POST   | `/v1/admin/kyc/:pro_id/approve`       | Approve                                |
| POST   | `/v1/admin/kyc/:pro_id/reject`        | Reject with reason                     |
| GET    | `/v1/admin/bookings?status=...`       | All bookings, filterable               |
| POST   | `/v1/admin/bookings/:id/refund`       | Force refund + reason                  |
| GET    | `/v1/admin/disputes?status=open`      | Dispute queue                          |
| POST   | `/v1/admin/disputes/:id/resolve`      | Resolve a dispute                      |
| GET    | `/v1/admin/revenue?range=...`         | Revenue dashboard                      |
| POST   | `/v1/admin/broadcast`                 | Push/WhatsApp broadcast by segment     |
| GET    | `/v1/admin/audit?actor=...`           | Audit log                              |

---

## 9. Webhooks (inbound, signature‑verified)

| Path                          | From          | Purpose                                 |
| ----------------------------- | ------------- | --------------------------------------- |
| `/v1/webhooks/razorpay`       | Razorpay      | Payment captured / refunded / payout    |
| `/v1/webhooks/kyc`            | Karza / Hyperverge | Async KYC result                   |
| `/v1/webhooks/msg91`          | MSG91         | SMS DLR                                 |
| `/v1/webhooks/whatsapp`       | Gupshup       | WA delivery, replies                    |

---

## 10. Rate limits (default; tuned per endpoint)

| Bucket                | Limit               |
| --------------------- | ------------------- |
| OTP send per phone    | 5 / hour            |
| OTP verify per phone  | 10 / hour           |
| Search                | 60 / minute / user  |
| Booking create        | 5 / minute / user   |
| Location update (pro) | 12 / minute / pro   |

Enforced with Redis token bucket; 429 with `Retry-After` header.

---

## 11. WebSocket events

Namespace: `/ws`. Auth: pass JWT in `auth.token` on connect.

| Direction | Event                | Payload                                                 |
| --------- | -------------------- | ------------------------------------------------------- |
| Client → Server | `join`         | `{ booking_id }`                                        |
| Client → Server | `message`      | `{ booking_id, text }`                                  |
| Client → Server | `pro:location` | `{ booking_id, lat, lng, at }`                          |
| Server → Client | `message`      | full chat message                                       |
| Server → Client | `pro:location` | `{ lat, lng, at }`                                      |
| Server → Client | `booking:status` | `{ booking_id, status }`                              |
| Server → Client | `offer:new`    | (pro app) `{ offer_id, booking_id, expires_at }`        |
