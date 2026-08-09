# System Flow — SportX India

End-to-end flows for the core user journeys. Sequence diagrams show actor ↔ Flutter app ↔ Laravel API ↔ DB/queue interactions; activity diagrams cover branching logic. All flows trace to screens in `SportX-India-Wireframes.md` and use cases in `Use-Cases.md`.

---

## 1. Auth & Onboarding

### 1.1 Sign-Up with Email OTP (S2 → S3 → S4 → A1/A2 → A3)

```mermaid
sequenceDiagram
    actor U as Athlete (Guest)
    participant F as Flutter App
    participant API as Laravel API
    participant DB as Database
    participant Q as Queue

    U->>F: Select role "Athlete / Parent" (S2)
    U->>F: Enter email, accept terms (S3)
    F->>API: POST /auth/register {role, email}
    API->>DB: Create user (status=active, email_verified_at=null)
    API->>Q: Dispatch SendOtpJob
    Q-->>U: Email with 6-digit code
    API-->>F: 202 Accepted {pending_verification}

    U->>F: Enter OTP (S4)
    F->>API: POST /auth/verify-otp {email, code}
    API->>DB: Validate code (hash match, not expired, attempts<limit)
    API->>DB: Set email_verified_at, delete/mark code consumed
    API-->>F: 200 {token, user, needs_onboarding=true}

    U->>F: Onboarding step 1: sports + age group (A1)
    U->>F: Onboarding step 2: skill level + city (A2)
    F->>API: POST /onboarding/athlete {sports[], age_group_id, skill_level, city_id}
    API->>DB: Create athlete_profile + athlete_sports rows
    API-->>F: 201 {profile}
    F->>U: Home dashboard (A3)
```

**Alternate paths**
- Wrong/expired OTP → `POST /auth/resend-otp` re-issues (resend timer honored client-side per S4).
- "Continue with Google" bypasses OTP; account verified at OAuth; `needs_onboarding=true` if no role profile exists yet.
- Phone entered at sign-up → stored unverified; verification deferred (decision).

### 1.2 Provider Onboarding (AC1 / C1 / O1 / SP1)

```mermaid
sequenceDiagram
    actor P as Provider (Coach/Academy/Organizer/Sponsor)
    participant F as Flutter App
    participant API as Laravel API
    participant DB as Database
    participant OBJ as Object Storage

    Note over P,OBJ: Post OTP-verify; role screens C1/AC1/O1/SP1
    P->>F: Complete role onboarding form
    alt Organizer or Sponsor
        P->>F: Upload verification document(s)
        F->>API: POST /media/upload (multipart)
        API->>OBJ: Store file (disk=s3)
        API->>DB: media_items row (owner=profile placeholder)
    end
    F->>API: POST /onboarding/{coach|academy|organizer|sponsor}
    API->>DB: Create role profile (listing_status=draft; verification_status=pending)
    API-->>F: 201 {profile}
    F->>P: Role dashboard (C3/AC3/O2/SP2)
```

---

## 2. Discovery Journey (search → filter → detail → save)

```mermaid
sequenceDiagram
    actor A as Athlete
    participant F as Flutter App
    participant API as Laravel API
    participant DB as Database

    A->>F: Open Universal Search (S6)
    F->>API: GET /meta/trending + GET /me/recent-searches
    API-->>F: sports chips + recents
    A->>F: Type "cricket ahmedabad", submit
    F->>API: GET /search?q=cricket%20ahmedabad
    API->>DB: Per-category queries (trials/academies/... union at service layer)
    API-->>F: {academies:[...], coaches:[...], trials:[...], ...}
    F->>A: Tabbed results (S7)

    A->>F: Open Filters, set sport=Cricket, city=Ahmedabad (S8)
    F->>API: GET /academies?sport_id=1&city_id=5
    API->>DB: Indexed query (listing_status, city_id)
    API-->>F: Page 1 of academy cards
    A->>F: Tap a card
    F->>API: GET /academies/{id}
    F->>A: Detail page (T2)
    A->>F: Tap ♡ save
    F->>API: POST /me/saved {item_type: academy, item_id}
    API->>DB: saved_items row (unique user+item)
    API-->>F: 201
```

---

## 3. Trial Registration (A12 → A13 → A14 → A15 → A24)

```mermaid
sequenceDiagram
    actor A as Athlete
    participant F as Flutter App
    participant API as Laravel API
    participant Svc as RegistrationService
    participant DB as Database
    participant Q as Queue

    A->>F: Open trial detail (A13)
    F->>API: GET /trials/{id}
    API-->>F: Trial incl. required_documents, status=published
    A->>F: Tap "Register for Trial"
    F->>A: Form (T3): auto-filled profile, document upload, payment note (display only)
    A->>F: Attach documents, submit
    F->>API: POST /media/upload (documents)
    F->>API: POST /trials/{id}/registrations {document_media_ids[]}
    API->>Svc: registerForTrial(athlete, trial, payload)
    Svc->>DB: TX: assert status=published & expires_at>now() & not duplicate
    Svc->>DB: Create trial_registration (verification_status=pending, registration_ref generated)
    Svc->>DB: Create trial_registration_documents rows
    Svc->>Q: Dispatch ArmReminderJob (if reminder_enabled)
    DB-->>Svc: committed
    Svc-->>API: registration
    API-->>F: 201 {registration_ref, trial summary}
    F->>A: Confirmation screen (A15): ref ID, Add to Calendar, Remind me toggle

    Note over A,Q: My Activity (A24) reads GET /me/activity?t=trials
    F->>API: GET /me/activity
    API-->>F: [{trial, status: Pending Review}, ...]
```

**Business rules enforced in service:**
- Double registration blocked by unique `(trial_id, athlete_id)` → 409.
- `status != published` or `expires_at` passed → 422 "registration closed".
- `required_documents` list drives which document rows must exist before `document_status=submitted`.

---

## 4. Tournament Registration with Capacity & Waitlist (A16–A18 + O8)

```mermaid
flowchart TD
    Start([Athlete taps Register on Tournament]) --> LoadForm[Load categories + capacities from API]
    LoadForm --> PickCat[Athlete picks category U-14 / U-16 / U-18]
    PickCat --> PickType{Participation type?}
    PickType -->|Individual| Details[Fill personal details]
    PickType -->|Team| TeamName[Enter team name]
    TeamName --> Details
    Details --> Check{Category capacity check}
    Check -->|spots available| Create[Create registration status=confirmed]
    Check -->|full, waitlist enabled| Wait[Create registration status=waitlisted]
    Check -->|full, no waitlist| Block[422: category full]
    Create --> PaymentFlag[payment_status=pending — manual flag, no gateway]
    Wait --> PaymentFlag
    PaymentFlag --> ConfirmScreen[Confirmation screen A15-equivalent]
    Wait --> WaitListNote["Athlete informed: waitlisted"]
```

**Organizer side (O7/O8):** `RegistrationManagement` list counts `confirmed` rows per category vs `tournament_categories.capacity`; organizer flips `payment_status` manually (`pending ↔ paid`) and edits `capacity`/`waitlist_enabled`.

---

## 5. Enquiry Flow (Athlete ↔ Coach/Academy) — A11 + C4/C5/AC8/AC9

```mermaid
sequenceDiagram
    actor A as Athlete
    actor C as Coach
    participant F as Flutter App
    participant API as Laravel API
    participant DB as Database
    participant N as NotificationService

    A->>F: Coach detail (A10) → Enquire
    F->>A: Modal: message + preferred date/time (T3)
    A->>F: Submit
    F->>API: POST /enquiries {subject_type: coach_profile, subject_id, message, preferred_datetime}
    API->>DB: enquiries + first enquiry_messages row (TX)
    API-->>A: 201

    C->>F: Open Enquiry Inbox (C4) — tabs All/New/Replied
    F->>API: GET /me/enquiries?filter=new
    API->>DB: enquiries where subject=self, unread messages exist
    C->>F: Open thread (C5)
    F->>API: GET /enquiries/{id} (marks incoming read)
    C->>F: Type reply → Send
    F->>API: POST /enquiries/{id}/messages {body}
    API->>DB: enquiry_messages row (sender=coach)
    API->>N: EnquiryReplied event → notify athlete
    N-->>A: Notifications Center entry (S9)
```

> Sponsor flows (SP8 Reply, SP6 Message) reuse the same `enquiries`/`enquiry_messages` infrastructure with `subject_type = sponsorship_application` — see AS-04.

---

## 6. Sponsorship Application & Shortlist (A21–A23 + SP2–SP9)

```mermaid
sequenceDiagram
    actor A as Athlete
    actor S as Sponsor
    participant F as Flutter App
    participant API as Laravel API
    participant DB as Database

    A->>F: Sponsorship detail (A22) → Apply
    F->>A: Pitch form: note + profile auto-attach confirmed (T3)
    A->>F: Submit
    F->>API: POST /sponsorships/{id}/applications {pitch_note}
    API->>DB: sponsorship_applications (status=submitted; unique per sponsorship+athlete)
    API-->>F: 201 → visible in My Activity (A24, Sponsorships tab)

    S->>F: Dashboard (SP2) → Applications inbox (SP7)
    F->>API: GET /me/applications
    S->>F: Open application (SP8)
    F->>API: GET /applications/{id}
    alt Shortlist
        S->>F: Shortlist
        F->>API: POST /applications/{id}/shortlist
        API->>DB: application.status=shortlisted + upsert shortlist_entries
    else Reject
        S->>F: Reject
        F->>API: POST /applications/{id}/reject
        API->>DB: application.status=rejected
    else Reply
        S->>F: Reply → opens enquiry thread on this application
        F->>API: POST /applications/{id}/reply {message}
        API->>DB: enquiries(subject_type=sponsorship_application) + message
    end

    S->>F: Shortlist screen (SP9) — grouped list + per-athlete note
    F->>API: PUT /me/shortlist/{entry} {note}
```

---

## 7. Trial Posting & Registrant Management (Academy: AC4 → AC7)

```mermaid
flowchart LR
    subgraph Academy
        AC4[AC4 Trial Posting Form] -->|Save & Publish| Pub[(trial status=published)]
        AC4 -->|Draft| Draft[(trial status=draft)]
    end
    subgraph Athlete
        A13[A13 Trial Detail] -->|registers| TR[(trial_registration pending)]
    end
    subgraph AcademyMgmt[Academy Management]
        AC5[AC5 My Trials] --> AC6[AC6 Registrant List]
        AC6 --> AC7[AC7 Registrant Detail]
        AC7 -->|Mark as Verified| Verified[(verification_status=verified)]
        AC7 -->|Reject| Rejected[(verification_status=rejected)]
    end
    Pub --> A13
    TR --> AC6
```

**Document review sequence (AC7):**

```mermaid
sequenceDiagram
    actor Ac as Academy Owner
    participant API as Laravel API
    participant DB as Database
    participant OBJ as Storage

    Ac->>API: GET /trials/{id}/registrants
    API-->>Ac: list with document_status badges
    Ac->>API: GET /registrations/{id}
    API-->>Ac: athlete snapshot + document list
    Ac->>API: GET /media/{media_id}/url
    API->>OBJ: Generate signed URL
    OBJ-->>Ac: Render document in viewer
    Ac->>API: POST /registrations/{id}/verify  (or /reject)
    API->>DB: trial_registrations.verification_status = verified|rejected
    API-->>Ac: 200; athlete sees status update in My Activity
```

---

## 8. Results Publishing (O9 → O10)

```mermaid
sequenceDiagram
    actor O as Organizer
    actor Pub as Public Viewer
    participant F as Flutter App
    participant API as Laravel API
    participant DB as Database

    O->>F: Tournament → Publish Results (O9)
    O->>F: Select category; enter winner / runner-up / 3rd place
    O->>F: Upload bracket image (optional)
    F->>API: POST /tournaments/{id}/results {category_id, places[{place, winner_name}], bracket_media_id}
    API->>DB: Delete existing unpublished rows for category; insert tournament_results (place 1..3), published_at=now()
    API-->>O: 201

    Pub->>API: GET /tournaments/{id}/results
    API->>DB: tournament_results where published_at not null + bracket media URL
    API-->>Pub: Grouped by category → bracket visualization / ranked list (O10)
```

---

## 9. Reporting & Moderation (S10 → AD6 → AD7)

```mermaid
sequenceDiagram
    actor U as User
    actor Ad as Admin
    participant API as Laravel API
    participant DB as Database
    participant N as NotificationService

    U->>API: POST /reports {reportable_type, reportable_id, reason, comment}
    API->>DB: listing_reports (status=pending)
    API-->>U: 201

    Ad->>API: GET /admin/moderation/queue
    API->>DB: reports pending, grouped by reportable (count, reason, first_reported_at)
    API-->>Ad: AD6 queue rows

    Ad->>API: GET /admin/moderation/reports/{id}
    API-->>Ad: report detail + listing snapshot

    alt Approve (no action)
        Ad->>API: POST /admin/moderation/reports/{id}/approve
        API->>DB: report.status=approved, resolved_by, resolved_at
    else Edit listing
        Ad->>API: POST /admin/moderation/reports/{id}/edit-then-resolve
        API->>DB: opens content edit (AD5); report.status=edited
    else Remove listing
        Ad->>API: POST /admin/moderation/reports/{id}/remove
        API->>DB: listing.status=removed; report.status=removed
        API->>N: notify listing owner
    else Warn owner
        Ad->>API: POST /admin/moderation/reports/{id}/warn
        API->>DB: report.status=warned
        API->>N: notify listing owner
    end
```

---

## 10. Auto-Expiry Engine (AD8/AD9 + scheduler)

```mermaid
flowchart TD
    Sched([Scheduler — hourly, cadence TBD]) --> Rules[Load active expiry_rules per content_type]
    Rules --> Find[Find published trials/tournaments/sponsorships/scholarships<br/>where expires_at <= now and no pending event]
    Find --> CreateEv[Create expiry_events rows status=pending]
    CreateEv --> Execute[Execute due events: content.status = expired]
    Execute --> Mark[expiry_events.status=expired, executed_at=now]
    Mark --> Notify[Notify listing owner]
    Execute --> Monitor[AD9 Monitor: Pending/Expired/Overridden tabs]
    AdminAct{Admin action}
    Monitor --> AdminAct
    AdminAct -->|Override pending| Override[event=overridden; content stays published]
    AdminAct -->|Restore expired| Restore[event=restored; content.status=published; expires_at recomputed]
```

*Note:* `expires_at` is set when a listing is published (rule applied at publish time) and recomputed on restore. The sweep is idempotent via the pending-event guard.

---

## 11. Reminder Delivery

```mermaid
sequenceDiagram
    participant S as Scheduler
    participant RS as ReminderService
    participant DB as Database
    participant NP as NotificationProvider (TBD)
    actor U as User

    Note over DB: reminder_subscriptions created by:<br/>- Save action on trial/tournament/scholarship<br/>- Reminder toggle on A15 confirmation
    S->>RS: dispatchDue() (scheduled)
    RS->>DB: SELECT * FROM reminder_subscriptions WHERE remind_at <= now AND sent_at IS NULL
    loop each subscription
        RS->>DB: Create notifications row (type=reminder, link to content)
        RS->>NP: push(user, payload)
        RS->>DB: sent_at = now
    end
    NP-->>U: Push + Notifications Center entry (S9)
```

*Reminder offset (how many days/hours before the date to remind) is unspecified in sources — **AS-05**; default candidate: T-2 days and T-1 day per S9 example copy ("in 2 days", "tomorrow").*
