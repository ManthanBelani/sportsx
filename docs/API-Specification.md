# API Specification — SportX India

Full endpoint listing for the Laravel REST API. Every endpoint maps to a feature in `Functional-Requirements.md` and a use case in `Use-Cases.md`.

> **Conventions & assumptions**
> - **Base URL:** `/api/v1` — AS-15.
> - **Auth:** Laravel Sanctum bearer tokens (header: `Authorization: Bearer <token>`). Issue at login/verify-OTP; invalidate at logout — AS-16.
> - **Response envelope:** Lists return `{ data: [], meta: { current_page, per_page, total, last_page } }`. Singles return `{ data: { ... } }`. Actions return `{ data: { id, ... } }` or `{ message: "..." }`.
> - **Error envelope:** `{ error: { code: string, message: string, fields?: { [field]: string[] } } }`.
> - **Pagination:** `?page=1&per_page=20` (default 20, max 50). Directory/search results use cursor or offset — AS-17.
> - **Filtering:** Query parameters per module (sport_id, city_id, age_group_id, status, q, etc.). Documented per endpoint.
> - **Sorting:** `?sort=created_at&direction=desc` (default varies per endpoint).
> - **Media upload:** `POST /media/upload` — `multipart/form-data` with `file` + `owner_type` + `owner_id` + `media_type`. Returns `{ data: { id, url } }`.
> - **Polymorphic IDs:** `item_type`/`item_id` or `reportable_type`/`reportable_id` strings are human-readable model class names (e.g. `Trial`, `Academy`).
> - **Admin routes:** prefixed `/api/v1/admin`, require `role=admin` + 2FA session.
> - **Status codes:** 200 OK, 201 Created, 204 No Content, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict (duplicate), 422 Unprocessable Entity (validation), 429 Too Many Requests.

---

## 1. Authentication

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/auth/register` | — | Create account (unverified). | FR-AUTH-2,3 |
| POST | `/auth/verify-otp` | — | Verify OTP; issue token. | FR-AUTH-4 |
| POST | `/auth/resend-otp` | — | Resend OTP (rate-limited). | S4 |
| POST | `/auth/login` | — | Login with email + password; issue token. | FR-AUTH-5 |
| POST | `/auth/logout` | Any | Revoke token. | — |
| POST | `/auth/forgot-password` | — | Request password reset OTP. | S5 |
| POST | `/auth/reset-password` | — | Reset password with OTP token. | S5 |

> **Note:** Google OAuth (FR-AUTH-12) is deferred to Phase 4.

### POST `/auth/register`

**Request:**
```json
{ "role": "athlete", "email": "aryan@example.com", "name": "Aryan Patel" }
```
> `phone` optional (captured but unverified). `role` required (one of S2 options).

**Response 202:**
```json
{ "data": { "message": "OTP sent", "email_masked": "a****@example.com" } }
```

### POST `/auth/verify-otp`

**Request:**
```json
{ "email": "aryan@example.com", "code": "123456" }
```

**Response 200:**
```json
{ "data": { "token": "1|abc...", "user": { "id": 1, "role": "athlete", "name": "...", "email_verified_at": "..." }, "needs_onboarding": true } }
```

### POST `/auth/login`

**Request:**
```json
{ "email": "aryan@example.com", "password": "secret" }
```

**Response 200:** Same shape as verify-otp.

---

## 2. Onboarding

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/onboarding/{role}` | Any, needs_onboarding | Get onboarding form schema/options. | A1,A2,C1,... |
| POST | `/onboarding/athlete` | Athlete | Step 1+2: sports, age group, skill level, city. | FR-AUTH-6 |
| POST | `/onboarding/coach` | Coach | Sports coached, certs, experience. | FR-AUTH-7 |
| POST | `/onboarding/academy` | Academy | Name, sports, city. | FR-AUTH-8 |
| POST | `/onboarding/organizer` | Organizer | Org name, type, verification docs. | FR-AUTH-9 |
| POST | `/onboarding/sponsor` | Sponsor | Brand name, logo, category, verification docs. | FR-AUTH-10 |

### POST `/onboarding/athlete`

**Request:**
```json
{ "full_name": "Aryan Patel", "date_of_birth": "2012-05-15", "gender": "male", "sports": [1, 3], "age_group_id": 3, "skill_level": "intermediate", "city_id": 5 }
```
> `full_name`, `date_of_birth`, `gender` are mandatory per Mandatory Fields PDF. `sports` = array of sport IDs matching A1 multi-select. `photo_media_id` uploaded via `POST /media/upload` with `owner_type=athlete_profile`.

**Response 201:**
```json
{ "data": { "id": 1, "full_name": "Aryan Patel", "date_of_birth": "2012-05-15", "gender": "male", "sports": [...], "age_group": { "id": 3, "name": "Under-14" }, "skill_level": "intermediate", "city": { "id": 5, "name": "Ahmedabad", "state": "Gujarat" }, "profile_completeness": 80 } }
```

> The other onboarding endpoints follow the same pattern with role-specific fields from their wireframes (C1, AC1, O1, SP1).

---

## 3. Master Data (Meta)

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/meta/sports` | Any | List sports (trending chips, filter options). |
| GET | `/meta/cities` | Any | List cities grouped by state. |
| GET | `/meta/age-groups` | Any | List age groups. |
| GET | `/meta/trending-searches` | Any | Recent popular search terms. |

**Response pattern (GET `/meta/sports`):**
```json
{ "data": [ { "id": 1, "name": "Cricket", "is_active": true }, ... ] }
```

---

## 4. Athlete Profile & Media

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/me/profile` | Athlete | Own profile (view). | FR-ATH-1, A4 |
| PUT | `/me/profile` | Athlete | Update profile fields. | FR-ATH-2, A5 |
| POST | `/media/upload` | Athlete/Coach/Academy/Org/Sponsor | Upload photo/video/document. | A6, AC2 |
| PUT | `/media/reorder` | Any | Reorder media items (drag-to-reorder). | A6 |
| DELETE | `/media/{id}` | Owner | Delete a media item. | A6 |
| GET | `/athletes/{id}` | Any | Public athlete profile (for sponsor discovery). | FR-SPON-4, SP6 |

### PUT `/me/profile` (Athlete)

**Request:**
```json
{ "full_name": "Aryan Patel", "date_of_birth": "2012-05-15", "gender": "male", "skill_level": "advanced", "city_id": 5, "phone": "+91 98XXXXXXXX", "academy_id": 5, "coach_id": 3, "position": "Batsman", "experience": "3 years", "achievements": [ { "id": 1, "text": "State-level U-14 selection 2025" }, { "text": "New achievement" } ] }
```
> `full_name`, `date_of_birth`, `gender` are mandatory per PDF and cannot be nulled. Optional fields (phone, academy_id, coach_id, position, experience) can be set to `null` to clear. `achievements` supports add-by-missing-id, remove-by-absence (diff-based). Sports updated via separate `PUT /me/profile/sports`.

### POST `/media/upload`

**Request:** `multipart/form-data` — `file` (image/video), `owner_type` (e.g. `athlete_profile`), `owner_id`, `media_type` (`photo`/`video`/`document`).

**Response 201:**
```json
{ "data": { "id": 42, "url": "https://cdn.../path.jpg", "media_type": "photo" } }
```

---

## 5. Directory / Listing Endpoints

All seven listing types share the same pattern: paginated card-list with consistent filters.

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/academies` | Any | Browse academy directory. | FR-ATH-4, T1 |
| GET | `/academies/{id}` | Any | Academy detail page. | A8, T2 |
| GET | `/coaches` | Any | Browse coach directory. | FR-ATH-5, T1 |
| GET | `/coaches/{id}` | Any | Coach detail page. | A10, T2 |
| GET | `/trials` | Any | Browse trial listings. | FR-ATH-7, T1 |
| GET | `/trials/{id}` | Any | Trial detail page. | A13, T2 |
| GET | `/tournaments` | Any | Browse tournaments (list/calendar). | FR-ATH-9, A16 |
| GET | `/tournaments/{id}` | Any | Tournament detail page. | A17, T2 |
| GET | `/scholarships` | Any | Browse scholarship feed. | FR-ATH-11, T1 |
| GET | `/scholarships/{id}` | Any | Scholarship detail page. | A20, T2 |
| GET | `/sponsorships` | Any | Browse sponsorship opportunities. | FR-ATH-12, T1 |
| GET | `/sponsorships/{id}` | Any | Sponsorship detail page. | A22, T2 |
| GET | `/sports-venues` | Any | Browse sports venues directory. | AS-47, T1 |
| GET | `/sports-venues/{id}` | Any | Sports venue detail page. | AS-47, T2 |

### Shared query parameters (all GET directory endpoints)

| Param | Type | Description |
|---|---|---|
| sport_id | int[] | Filter by sport(s). |
| city_id | int | Filter by city. |
| age_group_id | int | Filter by age group. |
| status | string | Filter by listing status. |
| page | int | Page number. |
| per_page | int | Items per page (default 20, max 50). |
| sort | string | Sort field (e.g. `event_datetime`, `created_at`). |
| direction | string | `asc` or `desc`. |

### Directory-specific extra filters

| Endpoint | Extra params |
|---|---|
| `/academies` | `fee_min`, `fee_max` (S8 price range) |
| `/coaches` | `fee_min`, `fee_max` |
| `/trials` | `date_from`, `date_to` (event date range) |
| `/tournaments` | `date_from`, `date_to`, `month` (calendar view) |
| `/scholarships` | `deadline_from`, `deadline_to` |
| `/sponsorships` | `deadline_from`, `deadline_to` |
| `/sports-venues` | `booking_available` (boolean) |

### GET `/trials` Response (card list)

```json
{ "data": [ { "id": 1, "name": "U-14 Cricket Trials", "sport": { "id": 1, "name": "Cricket" }, "venue": "Sardar Patel Stadium", "city": { "name": "Ahmedabad", "state": "Gujarat" }, "event_datetime": "2026-08-15T07:00:00+05:30", "registration_deadline": "2026-08-14T23:59:59+05:30", "entry_fee": "₹200", "organization_name": "Elite Cricket Academy", "contact_number": "+91 98XXXXXXXX", "status": "published" } ], "meta": { "current_page": 1, "per_page": 20, "total": 89 } }
```

### GET `/trials/{id}` Response (detail)

```json
{ "data": { "id": 1, "name": "U-14 Cricket Trials", "sport": { ... }, "organization_name": "Elite Cricket Academy", "event_datetime": "...", "venue": "...", "google_maps_url": "https://maps.google.com/...", "city": { ... }, "eligibility": "Boys, U-14, Ahmedabad residents", "entry_fee": "₹200", "registration_deadline": "...", "required_documents": ["Aadhaar Card", "Passport Photo"], "contact_number": "+91 98XXXXXXXX", "vacancies": 30, "benefits": "Selected athletes get free academy kit", "status": "published", "is_saved_by_me": true, "organizer": { "type": "academy", "name": "Elite Cricket Academy", "id": 5 } } }
```

> All other detail endpoints follow this shape with fields from T2 field-substitution table in wireframes.

---

## 6. Universal Search

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/search` | Any | Unified search across categories. | FR-DISC-1,2 |
| GET | `/me/recent-searches` | Any | Saved recent searches. | S6 |

### GET `/search`

**Params:** `q` (required), `page`, `per_page`.

**Response 200:**
```json
{ "data": { "academies": { "data": [...], "total": 3 }, "coaches": { "data": [...], "total": 2 }, "trials": { "data": [...], "total": 5 }, "tournaments": { "data": [...], "total": 1 }, "scholarships": { "data": [...], "total": 0 }, "sponsorships": { "data": [...], "total": 2 }, "sports_venues": { "data": [...], "total": 4 } }, "meta": { "query": "cricket ahmedabad", "page": 1 } }
```

---

## 7. Enquiries

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/enquiries` | Athlete | Send enquiry to coach/academy. | FR-ATH-6, FR-ENQ-1 |
| GET | `/me/enquiries` | Coach/Academy | Enquiry inbox (T4). | FR-COACH-3, FR-ACAD-7 |
| GET | `/enquiries/{id}` | Owner | Enquiry thread (T4b). | FR-COACH-4, FR-ACAD-9 |
| POST | `/enquiries/{id}/messages` | Owner | Reply to enquiry. | FR-COACH-4 |
| PUT | `/enquiries/{id}/read` | Owner | Mark messages as read. | — |

### POST `/enquiries`

**Request:**
```json
{ "subject_type": "coach_profile", "subject_id": 3, "message": "Is there a slot this weekend?", "preferred_datetime": "2026-08-09T06:00:00+05:30" }
```
> `subject_type`: `coach_profile`, `academy`, `sponsorship_application` (for sponsor reply flow — AS-04).

**Response 201:** `{ data: { id, subject_type, subject_id, created_at, ... } }`

### GET `/me/enquiries`

**Params:** `filter` (`all`, `new`, `replied` — T4 tabs), `page`, `per_page`.

**Response:**
```json
{ "data": [ { "id": 1, "athlete": { "name": "Aryan Patel", "sport": "Cricket" }, "last_message_preview": "Is there a slot...", "status": "new", "updated_at": "..." } ] }
```

### POST `/enquiries/{id}/messages`

**Request:** `{ "body": "Yes, Saturday 6 AM is open." }`

**Response 201:** Message row + triggers `EnquiryReplied` event → athlete notification.

---

## 8. Trial Registrations

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/trials/{id}/registrations` | Athlete | Register for a trial. | FR-ATH-8 |
| GET | `/trials/{id}/registrations` | Academy/Organizer owner | Registrant list (AC6). | FR-ACAD-5 |
| GET | `/registrations/{id}` | Academy/Organizer | Registrant detail + documents (AC7). | FR-ACAD-6 |
| POST | `/registrations/{id}/verify` | Academy/Organizer | Mark as verified. | FR-ACAD-6 |
| POST | `/registrations/{id}/reject` | Academy/Organizer | Mark as rejected. | FR-ACAD-6 |
| PATCH | `/registrations/{id}/reminder` | Athlete | Toggle reminder on/off. | A15 |

### POST `/trials/{id}/registrations`

**Request:**
```json
{ "document_media_ids": [42, 43], "reminder_enabled": true }
```
> Documents must match the trial's `required_documents` list. Profile fields auto-populated server-side.

**Response 201:**
```json
{ "data": { "registration_ref": "#TR20260815-0042", "trial": { "id": 1, "name": "...", "event_datetime": "...", "venue": "..." }, "status": "pending", "reminder_enabled": true } }
```
> 409 if already registered. 422 if trial closed/expired or documents missing.

---

## 9. Tournament Registrations

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/tournaments/{id}/registrations` | Athlete | Register for a tournament. | FR-ATH-10 |
| GET | `/tournaments/{id}/registrations` | Organizer | Registration management list (O7). | FR-ORG-5 |
| GET | `/tournaments/{id}/capacity` | Organizer | Category capacities (O8). | FR-ORG-6 |
| PUT | `/tournaments/{id}/capacity` | Organizer | Update capacities + waitlist toggle. | FR-ORG-6 |
| PATCH | `/registrations/{reg_id}/payment-status` | Organizer | Flip manual payment flag. | FR-ORG-5 |

### POST `/tournaments/{id}/registrations`

**Request:**
```json
{ "category_id": 2, "participation_type": "team", "team_name": "Team Titans", "reminder_enabled": true }
```

**Response 201:**
```json
{ "data": { "registration_ref": "#TM20260820-0003", "category": { "name": "U-16", "capacity": 24 }, "status": "confirmed", "payment_status": "pending" } }
```
> `status` is `confirmed` if spots available, `waitlisted` if full + waitlist enabled, 422 if full + no waitlist.

### PUT `/tournaments/{id}/capacity`

**Request:**
```json
{ "categories": [ { "id": 2, "capacity": 30, "waitlist_enabled": true }, { "id": 3, "capacity": 24, "waitlist_enabled": false } ] }
```

---

## 10. Results

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/tournaments/{id}/results` | Any | Public results/brackets view. | FR-ORG-8, O10 |
| POST | `/tournaments/{id}/results` | Organizer | Publish results per category. | FR-ORG-7, O9 |

### POST `/tournaments/{id}/results`

**Request:**
```json
{ "category_id": 2, "bracket_media_id": 55, "places": [ { "place": 1, "winner_name": "Team Titans" }, { "place": 2, "winner_name": "Team Strikers" }, { "place": 3, "winner_name": "Team Falcons" } ] }
```

**Response 201:** Results set. Overwrites any unpublished results for the category (O9 re-publish allowed).

---

## 11. Scholarships

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/scholarships` | Any | Browse feed. | FR-ATH-11 |
| GET | `/scholarships/{id}` | Any | Detail with external link. | FR-ATH-11, A20 |

> Scholarships are read-only for athletes; they link to an external application URL. Only admins can create/edit scholarships (see Admin section). FR-ADMIN-11.

---

## 12. Sponsorships & Applications

### Sponsorship Listings (sponsor-facing)

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/me/sponsorships` | Sponsor | Create sponsorship listing. | FR-SPON-2, SP3 |
| GET | `/me/sponsorships` | Sponsor | My sponsorships management list. | FR-SPON-3, SP4 |
| PUT | `/me/sponsorships/{id}` | Sponsor | Edit. | FR-SPON-2 |
| PATCH | `/me/sponsorships/{id}/status` | Sponsor | Publish/close. | FR-SPON-2 |

### Athlete-facing

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/sponsorships/{id}/applications` | Athlete | Submit pitch (FR-ATH-13, A23). |

**Request:** `{ "pitch_note": "I've represented my state at the U-14 level..." }`

### Sponsor Inbox & Shortlist

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/me/applications` | Sponsor | Applications inbox. | FR-SPON-6, SP7 |
| GET | `/me/applications/{id}` | Sponsor | Application detail + pitch. | FR-SPON-7, SP8 |
| POST | `/me/applications/{id}/shortlist` | Sponsor | Shortlist from inbox. | FR-SPON-7 |
| POST | `/me/applications/{id}/reject` | Sponsor | Reject. | FR-SPON-7 |
| POST | `/me/applications/{id}/reply` | Sponsor | Reply (opens enquiry thread). | FR-SPON-7, AS-04 |
| GET | `/me/shortlist` | Sponsor | Shortlist list. | FR-SPON-8, SP9 |
| POST | `/me/shortlist` | Sponsor | Shortlist an athlete directly. | FR-SPON-5 |
| PUT | `/me/shortlist/{entry_id}` | Sponsor | Update note. | FR-SPON-8 |

### Sponsor Athlete Discovery

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/athletes` | Sponsor | Search athlete profiles. | FR-SPON-4, SP5 |

**Params:** `sport_id`, `age_group_id`, `city_id`, `skill_level`, `q`, `page`, `per_page`.

---

## 13. Activity Hub & Saved Items

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/me/activity` | Athlete | My Activity tabs: trials, tournaments, sponsorships. | FR-ATH-14, A24 |
| GET | `/me/saved` | Any | Saved/bookmarked items grouped by type. | FR-ATH-15, A25 |
| POST | `/me/saved` | Any | Save an item. | — |
| DELETE | `/me/saved` | Any | Unsave. | — |

### GET `/me/activity`

**Params:** `type` (`trials`, `tournaments`, `sponsorships`), `status` (optional filter).

**Response:**
```json
{ "data": [ { "type": "trial_registration", "id": 1, "registration_ref": "#TR20260815-0042", "trial": { "id": 1, "name": "U-14 Cricket Trials", "event_datetime": "...", "venue": "..." }, "status": "pending", "reminder_enabled": true } ] }
```

### POST `/me/saved`

**Request:** `{ "item_type": "trial", "item_id": 1 }`

> 409 if already saved. 201 on success.

---

## 14. Notifications

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/me/notifications` | Any | Notifications center list (S9). | FR-NOTIF-1 |
| PATCH | `/me/notifications/{id}/read` | Any | Mark single notification read. | — |
| POST | `/me/notifications/read-all` | Any | Mark all read. | — |

**Params:** `?unread=true` to filter unread-only. `page`, `per_page`.

---

## 15. Reports

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/reports` | Any | Report a listing (S10). | FR-TRUST-1 |
| GET | `/admin/moderation/queue` | Admin | Reported listings queue (AD6). | FR-ADMIN-6 |
| GET | `/admin/moderation/reports/{id}` | Admin | Report detail + listing (AD7). | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/approve` | Admin | Approve listing (no action). | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/remove` | Admin | Remove listing. | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/edit-then-resolve` | Admin | Edit listing content + resolve. | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/warn` | Admin | Warn listing owner. | FR-ADMIN-7 |

### POST `/reports`

**Request:**
```json
{ "reportable_type": "academy", "reportable_id": 5, "reason": "outdated", "comment": "Fees listed are wrong" }
```
> `reportable_type` accepts: `academy`, `coach_profile`, `trial`, `tournament`, `scholarship`, `sponsorship`, `sports_venue`. `reason`: `fake`, `outdated`, `inappropriate`, `other`.

---

## 16. Settings

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/me/settings` | Any | Get user settings. | S11 |
| PUT | `/me/settings` | Any | Update notification prefs, language, etc. | FR-PLAT-1 |
| POST | `/me/delete-account` | Any | Request account deletion. | S11 |

---

## 17. Provider — Coach Listing

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/me/coach-profile` | Coach | Own listing. | FR-COACH-1 |
| PUT | `/me/coach-profile` | Coach | Update listing. | FR-COACH-1 |

---

## 18. Provider — Academy Listing & Trials

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/me/academy` | Academy | Own academy listing. | FR-ACAD-1 |
| PUT | `/me/academy` | Academy | Update listing. | FR-ACAD-1 |
| GET | `/me/trials` | Academy/Organizer | My trials list (AC5/O4). | FR-ACAD-4, FR-ORG-2 |
| POST | `/me/trials` | Academy/Organizer | Create trial (AC4/O3). | FR-ACAD-3, FR-ORG-2 |
| PUT | `/me/trials/{id}` | Owner | Edit trial. | FR-ACAD-3, FR-ORG-2 |
| PATCH | `/me/trials/{id}/publish` | Owner | Publish draft. | — |
| PATCH | `/me/trials/{id}/close` | Owner | Close trial. | FR-ACAD-4 |

### POST `/me/trials`

**Request:**
```json
{ "name": "U-14 Cricket Trial", "organization_name": "Elite Cricket Academy", "sport_id": 1, "event_datetime": "2026-08-15T07:00:00+05:30", "venue": "Sardar Patel Stadium", "google_maps_url": "https://maps.google.com/...", "city_id": 5, "contact_number": "+91 98XXXXXXXX", "registration_deadline": "2026-08-14T23:59:59+05:30", "eligibility": "Boys, U-14, Ahmedabad", "entry_fee": "₹200", "required_documents": ["Aadhaar Card", "Passport Photo"], "vacancies": 30, "benefits": "Free academy kit for selected athletes", "publish": false }
```
> Mandatory fields per PDF: `name`, `organization_name`, `sport_id`, `event_datetime`, `venue`, `google_maps_url`, `contact_number`, `registration_deadline`. Optional: `eligibility`, `entry_fee`, `required_documents`, `vacancies`, `benefits`. `publish: false` → status=draft; `publish: true` → status=published (sets expires_at from expiry rule).

---

## 19. Provider — Organizer Tournaments

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/me/tournaments` | Organizer | My tournaments list (O6). | FR-ORG-4 |
| POST | `/me/tournaments` | Organizer | Create tournament (O5). | FR-ORG-3 |
| PUT | `/me/tournaments/{id}` | Organizer | Edit tournament. | FR-ORG-3 |
| PATCH | `/me/tournaments/{id}/publish` | Organizer | Publish. | — |
| PATCH | `/me/tournaments/{id}/close` | Organizer | Close. | — |

### POST `/me/tournaments`

**Request:**
```json
{ "name": "U-16 State Cup", "sport_id": 1, "format": "knockout", "start_date": "2026-08-20", "end_date": "2026-08-25", "registration_deadline": "2026-08-18", "venue": "GMDC Ground", "google_maps_url": "https://maps.google.com/...", "city_id": 5, "contact_number": "+91 98XXXXXXXX", "entry_fee": "₹500/team", "registration_link": "https://forms.example.com/u16-cup", "prize_pool": "₹50,000", "rules": "ICC standard rules apply", "gender": "male", "categories": [ { "age_group_id": 3, "capacity": 24 }, { "age_group_id": 4, "capacity": 24 } ], "publish": true }
```
> Mandatory fields per PDF: `name`, `sport_id`, `start_date`, `end_date`, `registration_deadline`, `venue`, `google_maps_url`, `entry_fee`, `contact_number`, `registration_link`. Optional: `format`, `city_id`, `prize_pool`, `rules`, `gender`, `banner_media_id`.

---

## 20. Admin Endpoints

All routes prefixed `/api/v1/admin`. Require `role=admin` + 2FA-verified session.

### Admin Auth

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/admin/login` | — | Admin login (email + password). | FR-ADMIN-1 |
| POST | `/admin/verify-2fa` | — | Verify 2FA code. | FR-ADMIN-1 |
| GET | `/admin/dashboard` | Admin | Dashboard counters. | FR-ADMIN-2 |

### Content Management

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/admin/content` | Admin | Category picker with counts (AD3). | FR-ADMIN-3 |
| GET | `/admin/content/{type}` | Admin | Content list per category (AD4). | FR-ADMIN-4 |
| POST | `/admin/content/{type}` | Admin | Create record (AD5). | FR-ADMIN-5 |
| GET | `/admin/content/{type}/{id}` | Admin | Get record for editing. | FR-ADMIN-5 |
| PUT | `/admin/content/{type}/{id}` | Admin | Update record. | FR-ADMIN-5 |
| DELETE | `/admin/content/{type}/{id}` | Admin | Delete record. | FR-ADMIN-5 |

> `{type}` = `academies`, `coaches`, `trials`, `tournaments`, `scholarships`, `sponsorships`, `sports_venues`. Each uses the same schema as the owner's own edit form.

### Expiry Rules & Monitor

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/admin/expiry-rules` | Admin | Show rules (AD8). | FR-ADMIN-8 |
| PUT | `/admin/expiry-rules` | Admin | Update rules. | FR-ADMIN-8 |
| GET | `/admin/expiry/monitor` | Admin | Expiry monitor (AD9). | FR-ADMIN-9 |
| POST | `/admin/expiry/events/{id}/override` | Admin | Override pending expiry. | FR-ADMIN-9 |
| POST | `/admin/expiry/events/{id}/restore` | Admin | Restore expired listing. | FR-ADMIN-9 |

### Category Management

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/admin/categories/sports` | Admin | List sports. | FR-ADMIN-10 |
| POST | `/admin/categories/sports` | Admin | Add sport. | FR-ADMIN-10 |
| PUT | `/admin/categories/sports/{id}` | Admin | Edit sport. | FR-ADMIN-10 |
| DELETE | `/admin/categories/sports/{id}` | Admin | Remove sport (soft). | FR-ADMIN-10 |
| GET | `/admin/categories/cities` | Admin | List cities. | FR-ADMIN-11 |
| POST | `/admin/categories/cities` | Admin | Add city. | FR-ADMIN-11 |
| PUT | `/admin/categories/cities/{id}` | Admin | Edit city. | FR-ADMIN-11 |
| DELETE | `/admin/categories/cities/{id}` | Admin | Remove city (soft). | FR-ADMIN-11 |
| GET | `/admin/categories/age-groups` | Admin | List age groups. | FR-ADMIN-12 |
| POST | `/admin/categories/age-groups` | Admin | Add. | FR-ADMIN-12 |
| PUT | `/admin/categories/age-groups/{id}` | Admin | Edit. | FR-ADMIN-12 |
| DELETE | `/admin/categories/age-groups/{id}` | Admin | Remove (soft). | FR-ADMIN-12 |

---

## 21. Error Catalog

| HTTP | Code | When | Example |
|---|---|---|---|
| 400 | `BAD_REQUEST` | Malformed request body. | — |
| 401 | `UNAUTHORIZED` | Missing/invalid token. | — |
| 403 | `FORBIDDEN` | Role lacks permission. | Athlete trying to access admin routes. |
| 404 | `NOT_FOUND` | Resource missing. | Trial ID doesn't exist. |
| 409 | `CONFLICT` | Duplicate state. | Already registered for trial. Already saved. |
| 422 | `VALIDATION_FAILED` | Field validation errors. | Missing required field, invalid enum. |
| 429 | `TOO_MANY_REQUESTS` | Rate limit exceeded. | OTP resend too frequently. |

### 422 Validation Error Shape

```json
{ "error": { "code": "VALIDATION_FAILED", "message": "The given data was invalid.", "fields": { "email": ["The email has already been taken."], "sports": ["At least one sport is required."] } } }
```

---

## 22. Endpoint Count Summary

| Module | Endpoints |
|---|---|
| Auth | 9 |
| Onboarding | 6 |
| Meta/Master Data | 4 |
| Athlete Profile & Media | 6 |
| Directories (7 listing types × 2) | 14 |
| Universal Search | 2 |
| Enquiries | 5 |
| Trial Registrations | 6 |
| Tournament Registrations | 5 |
| Results | 2 |
| Sponsorships & Applications | 12 |
| Athlete Discovery | 1 |
| Activity & Saved | 5 |
| Notifications | 3 |
| Reports (user + admin) | 8 |
| Settings | 3 |
| Coach Listing | 2 |
| Academy Listing & Trials | 7 |
| Organizer Tournaments | 5 |
| Admin Auth & Dashboard | 3 |
| Admin Content CRUD | 6 |
| Admin Expiry | 5 |
| Admin Categories | 12 |
| Media Upload | 3 |
| **Total** | **~141** |

> Approximate: includes 2 new `/sports-venues` endpoints. Some endpoints share paths under the same method. Exact count finalized during implementation.
