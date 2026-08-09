# Security and Non-Functional Requirements — SportX India

Auth/authorization model, data protection, rate limiting, scalability, performance targets, and compliance considerations relevant to a sports discovery platform in India.

---

## 1. Authentication & Authorization

### 1.1 User Auth

| Mechanism | Detail | Source |
|---|---|---|
| Primary channel | Email OTP (6-digit, hashed, 5-min expiry) | FR-AUTH-4, decision |
| Secondary channel | Email/password login (bcrypt) | FR-AUTH-5 |
| Social auth | Google OAuth 2.0 (email + profile scope) | S3 |
| Token mechanism | Laravel Sanctum API tokens (SHA-256 hashed in DB) | AS-16 |
| Token lifetime | Configurable; default 1 year for MVP | AS-28 |
| Logout | Token revocation on `POST /auth/logout` | — |
| Account deletion | `POST /me/delete-account` → soft-delete (`status=deleted`) | S11 |

### 1.2 Admin Auth

| Mechanism | Detail | Source |
|---|---|---|
| Portal entry | Separate `POST /admin/login` (email + password) | AD1 |
| 2FA | Time-based OTP (TOTP) — e.g. Google Authenticator compatible. Secret stored encrypted at rest. | AD1 |
| Session flag | `admin_2fa_verified_at` timestamp; custom middleware checks recency (configurable, default: per-session) | AS-26 |

### 1.3 Role-Based Authorization (RBAC)

| Role | Permitted actions |
|---|---|
| Athlete/Parent | Browse all directories, save items, register for trials/tournaments, apply to sponsorships, enquire with coaches/academies, report listings, manage own profile |
| Coach | Above (browse like any user) + create/edit own listing, view/reply to enquiry inbox |
| Academy | Above + create/edit academy listing, post/manage trials, view/verify/reject registrants, view/reply to enquiry inbox |
| Organizer | Above + post/manage trials and tournaments, manage registrations + capacity + payment status (manual), publish results |
| Sponsor | Above + post/manage sponsorships, discover athlete profiles, review/shortlist/reject applications, shortlist with notes |
| Admin | All CRUD on all content types, moderation actions, expiry rule management, category management; accessed via admin portal with 2FA |

### 1.4 Ownership Checks

All mutation endpoints verify ownership via Laravel Policies:

- **Coach listing:** only the coach user who owns the `coach_profile` can edit.
- **Academy:** only the user whose `academy.owner_user_id` matches.
- **Trial:** owned by academy owner or organizer user who created it.
- **Tournament:** owned by the organizer profile user.
- **Sponsorship:** owned by the sponsor profile user.
- **Enquiry inbox:** only the subject's owner (coach user / academy owner user).
- **Registrant management:** only the trial/tournament owner.

---

## 2. Data Protection

### 2.1 Sensitive Data Handling

| Data | Protection |
|---|---|
| Passwords | bcrypt (cost 10+) — never stored/recovered in plaintext |
| OTP codes | Hashed before storage; plaintext exists only in transit (email/phone) and memory during validation |
| Google OAuth tokens | Not stored; only `google_id` retained for account linking |
| Verification documents | Stored in private object storage bucket; served via signed URLs with expiry |
| Trial registration documents | Same as verification documents |
| Admin 2FA secrets | Laravel `encrypt()` (AES-256-CBC with app key) |
| Sanctum tokens | SHA-256 hashed in `personal_access_tokens` table |

### 2.2 Minors' Data (Critical — India Context)

> The platform's **primary consumer** is athletes, including minors (age groups: Under-10 through Under-18). Parents operate accounts on behalf of minor athletes (MVP Overview: "Athlete / Parent" role).

| Concern | Approach |
|---|---|
| Account ownership | The account is registered to the parent's email; the athlete profile represents the minor. No PII of minors beyond what parents provide. |
| Sponsor discovery of minors | **Sponsors can discover all athlete profiles regardless of age group** (SP5 allows any age_group_id filter). **Before launch, a review is required:** should minors be excluded from sponsor discovery by default? Flagged as **AS-34** — requires legal/compliance review. |
| Profile visibility | Athlete profiles are public to logged-in users (sponsors, other athletes). Consider: are minor profiles visible to all authenticated users, or should there be privacy controls? **AS-34.** |
| Data retention | Minor data should not be retained longer than necessary. Deletion at account delete (`softDeletes`); hard purge schedule is an assumption (AS-35 — default: 90 days after account deletion). |

### 2.3 India Data Protection — DPDP Act 2023

| Requirement | Status |
|---|---|
| Consent for data collection | Terms & privacy checkbox at sign-up (S3) — captures consent. |
| Right to access | Account holder can view their data via profile endpoints. Full data export not in MVP — **AS-36** (could-priority). |
| Right to erasure | `Delete Account` in Settings (S11) → soft-delete; hard purge scheduled. |
| Data localization | Not explicitly required for the MVP scope, but server should be in India (or region where data subjects are). **AS-37** — deployment region unspecified. |
| Grievance officer | Not in MVP scope — **AS-36**. |

---

## 3. Rate Limiting

| Endpoint / Context | Limit | Rationale |
|---|---|---|
| `POST /auth/register` | 5/hour per IP | Prevent mass account creation |
| `POST /auth/verify-otp` | 10/minute per IP + per email | Prevent brute-force OTP guessing |
| `POST /auth/resend-otp` | 1/minute per email | Wireframe S4 resend timer enforced server-side |
| `POST /auth/login` | 10/minute per IP | Brute-force prevention |
| `POST /reports` | 5/hour per user | Prevent spam reporting |
| All other API endpoints | 60/minute per token | General abuse prevention |
| `POST /media/upload` | 10/minute per token | Resource abuse prevention |

> **AS-38:** Rate limits above are proposed defaults; actual values should be reviewed after load testing.

Implementation: Laravel `RateLimiter` facade + `ThrottleRequests` middleware. Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After` (on 429 — AS-29).

---

## 4. Input Validation & Sanitization

| Layer | What |
|---|---|
| Flutter | Client-side form validation (lengths, required fields, email format) for UX. **Never the sole protection.** |
| Form Requests | Server-side: type, length, enum, exists (FK), unique constraints. Per `API-Specification.md` endpoint schemas. |
| Model casts | JSON fields (`certifications`, `required_documents`, `facilities`) cast to arrays — validated as arrays of strings. |
| SQL | Eloquent ORM (parameterized queries) — no raw SQL with user input. |
| XSS | All user text stored raw; sanitized on output via `htmlspecialchars` / Blade `{{ }}` when rendered (if web admin ever built). API returns JSON — Flutter handles rendering safely. |
| File uploads | Type whitelist (extension + MIME), size limit (`config/sportx.php`), sanitized filename. No server-side execution of uploaded files. |
| URLs | `external_link` on scholarships validated as a URL (not `javascript:` protocol). |

---

## 5. CORS Configuration

| Setting | Value | Rationale |
|---|---|---|
| Allowed origins | Flutter app origin(s) only (per environment — dev/staging/prod) | Prevent CSRF from other sites |
| Allowed methods | GET, POST, PUT, PATCH, DELETE | REST API |
| Allowed headers | `Authorization`, `Content-Type`, `Accept` | Auth token + JSON |
| Max age | 86400 (24h) | Reduce preflight requests |

---

## 6. Scalability

### 6.1 Statelessness

- All API endpoints are stateless (bearer token auth, no server-side session).
- Client holds the token; server validates on each request via DB lookup (Sanctum default).
- Scale: multiple API instances behind a load balancer (Nginx/ALB).

### 6.2 Queue-Backed Async Work

| Work type | Queue | Rationale |
|---|---|---|
| OTP sending | `notifications` | External call — don't block registration |
| Expiry sweep | `default` | Periodic batch — shouldn't block API |
| Reminder sending | `notifications` | External push — potentially slow |
| Media processing | — | Direct upload (no processing at MVP); if image optimization added, queued |

### 6.3 Database Scaling

- Read replicas for directory/search queries (Phase 4, AS-39).
- Indexes per `Database-Design.md` — all hotspots covered.
- Pagination enforced (`per_page` max 50) to prevent large result sets.

### 6.4 Storage

- Object storage (S3-compatible) decoupled from app servers.
- CDN for public assets (photos, banners).
- Signed URLs for private documents with time-limited expiry.

---

## 7. Performance Targets

| Metric | Target | Assumption |
|---|---|---|
| API response time (P95) — list endpoints | < 500ms | AS-40 |
| API response time (P95) — detail endpoints | < 300ms | AS-40 |
| List page load (mobile, on 4G) | < 2.5s perceived (NFR-3) | Includes network latency |
| Scroll performance | 60fps (no jank) on low-end Android | NFR-3 |
| OTP delivery latency | < 10s | Depends on email/SMS vendor |
| Push notification delivery | < 5s from dispatch to device | Depends on push vendor |
| DB query count per list request | ≤ 3 (one for list + one for count + one for auth) | Target for development |
| Scheduled job sweep duration | < 30s for up to 10,000 listings | AS-41 |

> **AS-40/41:** Performance targets are directional; actual targets should be validated with load testing before production.

---

## 8. Availability & Reliability

| Aspect | Target | Note |
|---|---|---|
| Monthly uptime | 99.5% (NFR-8) | ~3.6h downtime/month allowed |
| Deployment strategy | Blue-green or zero-downtime (Laravel deployer / Envoyer) | AS-42 |
| Database backups | Daily automated + point-in-time recovery | AS-43 |
| Media backups | Object storage has built-in durability (e.g. S3 99.999999999%) | — |
| Monitoring | Application logs + APM (Sentry, Laravel Telescope in dev) | AS-44 — tooling unspecified |
| Error tracking | Exception tracking (Sentry or similar) in production | AS-44 |

---

## 9. Logging & Audit Trail

| What is logged | Where |
|---|---|
| Auth events (login, logout, register, OTP verify, failed attempts) | Laravel `Log` facade |
| Admin moderation actions (approve, remove, warn, expiry override/restore) | `listing_reports.resolved_by` + `expiry_events.overridden_by` + audit log table (**AS-45** — optional; at minimum, DB columns record who/when) |
| Listing status changes (published → closed, published → expired) | Model observers + `Log` |
| API errors (5xx, 429) | Application log |
| Job failures | Failed jobs table (`queue:failed-table`) |

---

## 10. Security Checklist (Pre-Launch)

| # | Check | Status |
|---|---|---|
| SEC-1 | All endpoints require authentication (except public auth/meta/search endpoints). | Pending |
| SEC-2 | Role-based middleware on all role-specific routes. | Pending |
| SEC-3 | Ownership checks on all mutation endpoints (policies). | Pending |
| SEC-4 | OTP codes hashed, rate-limited, and time-expired. | Pending |
| SEC-5 | Passwords hashed (bcrypt). | Pending |
| SEC-6 | Admin portal requires 2FA. | Pending |
| SEC-7 | File upload validation (type + size). | Pending |
| SEC-8 | CORS restricted to app origins. | Pending |
| SEC-9 | Rate limiting on auth endpoints. | Pending |
| SEC-10 | No raw SQL with user input. | Pending |
| SEC-11 | Verification documents served via signed URLs. | Pending |
| SEC-12 | Minors' data review completed (sponsor discovery, profile visibility). | AS-34 — Pending |
| SEC-13 | HTTPS enforced on all endpoints. | Pending |
| SEC-14 | No secrets/config exposed in API responses. | Pending |
| SEC-15 | Soft-delete + hard-purge for account deletion. | Pending |
