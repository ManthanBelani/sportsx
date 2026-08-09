# Functional & Non-Functional Requirements — SportX India

Requirements are numbered `FR-<MODULE>-<n>` / `NFR-<n>` and prioritized **MoSCoW**: **M**ust / **S**hould / **C**ould. Modules follow the six roles plus shared platform concerns. Every requirement traces to the MVP Overview feature list or Screen Inventory.

**Global exclusions (by decision, apply to all requirements):**
- No in-app payment processing. Entry fees/prize pools/stipends are display-only fields; organizer payment tracking is a manual status flag.
- Email is the primary OTP-verified channel; phone verification is deferred.
- Notification/OTP vendor is unspecified (abstract provider interfaces only).
- Admin module requirements are fully specified here but scheduled to a later build phase.
- **Mandatory/Optional field definitions** match `SportX_India_Mandatory_Fields_MVP.pdf` (now resolved — AS-05). A consolidated mandatory-fields reference (FR-MAND) is provided below the module-specific requirements.

---

---

## 1. AUTH — Authentication & Onboarding

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-AUTH-1 | The app shall present a splash screen on launch with branding and a loading state. | S | S1 |
| FR-AUTH-2 | The app shall present role selection with five cards: Athlete/Parent, Coach, Academy, Organizer, Sponsor/Brand. | M | S2 |
| FR-AUTH-3 | The app shall allow sign-up with phone number **or** email input, a terms & privacy checkbox, and a "Continue with Google" option. | M | S3 |
| FR-AUTH-4 | The app shall verify the account with a 6-digit OTP code screen including a resend-with-timer. **Primary channel: email. Phone OTP: deferred.** | M | S4 + decision |
| FR-AUTH-5 | The app shall provide login with phone/email + password or OTP toggle, forgot-password, and sign-up links. | M | S5 |
| FR-AUTH-6 | On first sign-up, athletes/parents shall complete onboarding: (a) multi-select sport(s) + age group; (b) skill level + city/state. | M | A1, A2 |
| FR-AUTH-7 | On first sign-up, coaches shall complete onboarding capturing sport(s) coached, certifications, and years of experience. | M | C1 |
| FR-AUTH-8 | On first sign-up, academies shall complete onboarding capturing academy name, sport(s), and city. | M | AC1 |
| FR-AUTH-9 | On first sign-up, organizers shall complete onboarding capturing organization name, type (Federation/Club/Other), and verification document upload. | M | O1 |
| FR-AUTH-10 | On first sign-up, sponsors shall complete onboarding capturing brand name, logo, category, and verification document upload. | M | SP1 |
| FR-AUTH-11 | Verification document uploads (organizer, sponsor) shall be stored for review. **Review workflow is an assumption** (no admin approval screen specified in MVP). | S | O1, SP1 |
| FR-AUTH-12 | The Google sign-in option shown on S3 may be deferred if it adds delivery risk; email/OTP must always work. | C | S3 |

## 2. ATH — Athlete / Parent

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ATH-1 | Athletes shall have a viewable profile: photo, name, sport(s), age group, city/state, achievements list, media gallery preview. | M | A4 |
| FR-ATH-2 | Athletes shall edit profile fields, add/remove achievements, and manage a media gallery (upload, delete, drag-to-reorder photos/videos). | M | A5, A6 |
| FR-ATH-3 | Athletes shall see a home dashboard with: search bar, recommended academies, trials closing soon, saved/upcoming tournaments, new scholarships. | M | A3 |
| FR-ATH-4 | Athletes shall browse the Academy Directory (card list: thumbnail, name, sport · city, fee range) and open a detail page (facilities, coaches, age groups, timings, fees, location map preview, contact). | M | A7, A8, T1, T2 |
| FR-ATH-5 | Athletes shall browse the Coach Directory (name, sport, experience, fee, city) and open a detail page (qualifications, experience, fee structure, location). | M | A9, A10 |
| FR-ATH-6 | Athletes shall send an enquiry to a coach via a modal/form with message box and preferred date/time. | M | A11, T3 |
| FR-ATH-7 | Athletes shall browse Trial Listings (sport, date, venue, organizer, entry fee) and open a detail page (eligibility, required documents, entry fee, contact). | M | A12, A13 |
| FR-ATH-8 | Athletes shall register for a trial via a form (profile auto-fill, document upload, **payment note only — informational**), and receive a confirmation screen with registration ID, add-to-calendar, and reminder toggle. | M | A14, A15, T3 |
| FR-ATH-9 | Athletes shall browse a Tournament Calendar with calendar/list toggle, and open a detail page (format, dates, venue, prize pool, entry categories, entry fee). | M | A16, A17 |
| FR-ATH-10 | Athletes shall register for a tournament via a form (category selection, team/individual selection, personal details). | M | A18, T3 |
| FR-ATH-11 | Athletes shall browse a Scholarship Feed (provider, sport, amount, deadline) and open a detail page (eligibility, application steps, **external link** for applying). | M | A19, A20 |
| FR-ATH-12 | Athletes shall browse Sponsorship Opportunities (sponsor, sport, eligibility, benefits, deadline) and open a detail page. | M | A21, A22 |
| FR-ATH-13 | Athletes shall apply/pitch to a sponsor via a form with pitch note and auto-attached profile. | M | A23, T3 |
| FR-ATH-14 | Athletes shall see a My Activity hub with tabs: Trials, Tournaments, Sponsorships — each showing status per item (e.g. Confirmed, Pending Review). | M | A24 |
| FR-ATH-15 | Athletes shall save/bookmark any listing and view saved items grouped by type; the save/unsave heart is available on detail pages. | M | A25, T2 |
| FR-ATH-16 | Athletes shall receive deadline & date reminders for saved trial dates, tournament dates, and scholarship deadlines (delivery channel per NFR/vendor decision). | M | Feature list; S9 |
| FR-ATH-17 | Scholarship applications happen on the provider's external site; the app links out and does not track the external application state. | S | A20 ("external link") |

## 3. COACH — Coach

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-COACH-1 | Coaches shall create/edit a public listing: photo, name, sport(s), certifications, experience, fee structure, location, bio. | M | C2 |
| FR-COACH-2 | Coaches shall see a dashboard with new-enquiry count, profile completeness meter, and quick actions (Edit Listing, Browse App). | M | C3 |
| FR-COACH-3 | Coaches shall have an enquiry inbox (tabs All/New/Replied) listing athlete name, sport, message preview, time, and a Reply action. | M | C4, T4 |
| FR-COACH-4 | Coaches shall open an enquiry detail and reply in a message-thread view. | M | C5, T4b |
| FR-COACH-5 | Coaches shall be able to browse the full app like an athlete/parent (reusing all directory/detail screens). | M | C6 |

## 4. ACAD — Academy

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ACAD-1 | Academies shall create/edit a public listing: cover photo, name, sport(s), facilities, fee range, age groups, timings, coaches, photos. | M | AC2 |
| FR-ACAD-2 | Academies shall see a dashboard with active-trials count, enquiry count, a "+ Post New Trial" action, and recent registrants. | M | AC3 |
| FR-ACAD-3 | Academies shall create/edit trials: name, sport, date & time, venue, eligibility, entry fee, required documents, contact, and draft/published status; save & publish supported. | M | AC4 |
| FR-ACAD-4 | Academies shall manage their trials in a list with status (Draft/Published/Closed) and edit/close actions. | M | AC5, T1 |
| FR-ACAD-5 | Academies shall view a registrant list per trial with counts (registered, spots left) and per-row document-submission status. | M | AC6 |
| FR-ACAD-6 | Academies shall view a registrant detail (profile snapshot, submitted documents with viewer) and take actions **Mark as Verified** / **Reject**. | M | AC7 |
| FR-ACAD-7 | Academies shall have an enquiry inbox and enquiry detail/reply identical in behavior to the coach inbox. | M | AC8, AC9, T4/T4b |

## 5. ORG — Organizer

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ORG-1 | Organizers shall see a dashboard with active trials count, tournaments count, + Post Trial / + Post Tournament actions, and upcoming deadlines. | M | O2 |
| FR-ORG-2 | Organizers shall create/edit/publish/close trial listings with the same fields as academy trial posting. | M | O3, O4, AC4 |
| FR-ORG-3 | Organizers shall create/edit tournaments: name, format (dropdown), dates, venue, entry fee, prize pool, categories; save & publish supported. | M | O5 |
| FR-ORG-4 | Organizers shall manage tournaments in a list with status and registrant counts. | M | O6, T1 |
| FR-ORG-5 | Organizers shall manage registrations per event, filterable by category with capacity meters (`filled/capacity` per category) and a **manual payment status flag** per registrant (e.g. Paid / Pending — **not** a payment integration). | M | O7 |
| FR-ORG-6 | Organizers shall adjust category capacity (slider/input per category) and toggle a waitlist when full. | S | O8 |
| FR-ORG-7 | Organizers shall publish results per category: winner, runner-up, 3rd place, plus bracket image upload. | M | O9 |
| FR-ORG-8 | Published results shall be publicly viewable as a bracket visualization and/or ranked list (🥇/🥈/🥉). | M | O10 |

## 6. SPON — Sponsor / Brand

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-SPON-1 | Sponsors shall see a dashboard with active listings count, new applications count, + Post Sponsorship action, and recent applications. | M | SP2 |
| FR-SPON-2 | Sponsors shall create/edit sponsorship listings: title, sport, eligibility criteria, benefits offered, deadline; save & publish supported. | M | SP3 |
| FR-SPON-3 | Sponsors shall manage their sponsorships in a list with status and applications count. | M | SP4, T1 |
| FR-SPON-4 | Sponsors shall search/filter athlete profiles by sport, age group, city, skill level; result cards show name, sport · age group · city, and achievement count. | M | SP5 |
| FR-SPON-5 | Sponsors shall view an athlete profile (photo, achievements, media gallery) with Shortlist and Message actions. **Message action mentions an undefined thread — see AS-* in Glossary.** | M | SP6 |
| FR-SPON-6 | Sponsors shall have an applications inbox listing athlete name, sport, date applied, status. | M | SP7, T4-style |
| FR-SPON-7 | Sponsors shall view an application detail (pitch note, applied-to listing, date, view-full-profile) with actions: Shortlist / Reject / Reply. | M | SP8 |
| FR-SPON-8 | Sponsors shall maintain a shortlist grouped list with a free-text note per athlete. | M | SP9 |

## 7. ADMIN — Admin (full spec, later build phase)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ADMIN-1 | Admins shall log in through a dedicated admin portal with email, password, and 2FA. | M | AD1 |
| FR-ADMIN-2 | Admins shall see a dashboard with counters: active listings, flagged items, pending expirations, new signups. | M | AD2 |
| FR-ADMIN-3 | Admins shall manage content via a category picker (Academies, Coaches, Trials, Tournaments, Scholarships, Sponsorships) with per-category counts. | M | AD3 |
| FR-ADMIN-4 | Admins shall browse/search/sort/filter a content list per category. | M | AD4, T1 |
| FR-ADMIN-5 | Admins shall create/edit/delete any record via a dynamic form matching the owner's own edit screen schema. | M | AD5 |
| FR-ADMIN-6 | Admins shall see a flagged/reported listings queue showing listing, reason, report count, and time since first report. | M | AD6 |
| FR-ADMIN-7 | Admins shall take moderation actions on a flagged listing: Approve (no action), Edit Listing, Remove Listing, Warn Owner; with report detail (reporters, reason, comment) and view-listing link. | M | AD7 |
| FR-ADMIN-8 | Admins shall configure content expiry rules per content type (e.g. trials auto-expire N days after event date; tournaments N days after final match date; sponsorships expire on listed deadline). | M | AD8 |
| FR-ADMIN-9 | Admins shall monitor expirations in tabs Pending/Expired/Overridden, with Override and Restore actions. | M | AD9 |
| FR-ADMIN-10 | Admins shall manage master categories: sports, cities/states, age groups (add/edit/remove). | M | AD10–AD12 |
| FR-ADMIN-11 | **Scholarships are created and maintained exclusively by admins** ("curated, admin-maintained list") — there is no self-serve scholarship posting role. | M | MVP Overview §1 feature list |

## 8. DISC — Discovery, Search & Filters (shared)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-DISC-1 | A universal search screen shall offer a search bar, recent searches, and trending sport chips. | M | S6 |
| FR-DISC-2 | Unified search results shall be presented in tabs across all six categories (Academies/Coaches/Trials/Tournaments/Scholarships/Sponsorships) with paginated card lists. | M | S7 |
| FR-DISC-3 | A shared filter panel shall support: sport multi-select, city/state dropdown, age group, price range slider, and date range (where applicable); with Apply and Clear. | M | S8 |
| FR-DISC-4 | The same filter/facet semantics shall apply consistently across all listing types. | M | Global Filters feature |
| FR-DISC-5 | All list views shall support pagination ("Load more"). | M | T1, S7 |

## 9. ENQ — Enquiry & Messaging (shared pattern)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ENQ-1 | Enquiry threads shall store athlete message, provider replies, and timestamps, displayed as a message-thread view. | M | T4b |
| FR-ENQ-2 | Inbox rows shall distinguish unread/new vs replied states. | M | T4 |
| FR-ENQ-3 | Sponsor "Message" (SP6) and sponsor application "Reply" (SP8) shall reuse the same enquiry/thread infrastructure. **Assumption: no separate chat system exists.** | S | SP6, SP8 |

## 10. NOTIF — Notifications

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-NOTIF-1 | A notifications center shall list all alerts (deadline reminders, enquiry replies, status updates) with icon, title, context line, and relative time. | M | S9 |
| FR-NOTIF-2 | Reminders shall be generated for saved trials, tournaments, and scholarship deadlines as they approach. | M | Feature list |
| FR-NOTIF-3 | Enquiry replies shall generate a notification. | M | S9 example |
| FR-NOTIF-4 | Users shall be able to toggle notifications in Settings. | M | S11 |
| FR-NOTIF-5 | The delivery mechanism (push provider, in-app badge) is abstracted behind a `NotificationProvider` interface — vendor undecided. | M | Decision |

## 11. TRUST — Reporting & Moderation (user side)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-TRUST-1 | Users shall be able to report any listing from its detail page via a modal with reasons (Fake/Scam, Outdated information, Inappropriate content, Other) and optional comment. | M | S10, T2 |
| FR-TRUST-2 | Multiple reports on the same listing shall be aggregated for the admin queue (report count shown). | M | AD6 |

## 12. PLAT — Platform / Shared UI

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-PLAT-1 | Settings shall include: edit profile, change password, notification toggle, language selector (English only at MVP), help center, report a problem, log out, delete account. | M | S11 |
| FR-PLAT-2 | Help Center shall offer FAQ search, popular topics, and a contact-support form. | C | S12 |
| FR-PLAT-3 | A persistent bottom navigation bar with Home / Search / Saved / Profile shall appear on primary athlete-facing screens. | M | T1 etc. |
| FR-PLAT-4 | Every detail page shall expose Save (♡), an overflow menu (⋮), and a "Report this listing" entry. | M | T2 |
| FR-PLAT-5 | The six content categories shall share a consistent card-list → detail → form pattern per templates T1–T3. | M | Screen Inventory notes |

---

## Non-Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| NFR-1 | **Platform:** Flutter mobile app (Android + iOS from one codebase); Laravel REST API backend; relational database (see Database-Design — engine choice is an assumption). | M |
| NFR-2 | **Mobile-first UX:** layouts specified at ~375px portrait baseline; bottom-nav pattern for primary flows. | M |
| NFR-3 | **Performance:** directory/list endpoints paginated; card-list scrolling must remain smooth on low-end Android devices (target: 60fps list scrolling; list page load P95 < 2.5s on 4G — target is an assumption). | M |
| NFR-4 | **Scalability:** stateless API (token auth), queue-backed async work (notifications, expiry sweeps), media stored in object storage not the app server/DB. | M |
| NFR-5 | **Security:** password hashing with a modern algorithm, OTP expiry & rate limiting, role-based authorization on every endpoint, admin 2FA, document/media uploads validated & access-controlled. See `Security-and-NonFunctional.md`. | M |
| NFR-6 | **Privacy (India context):** athlete profiles may belong to minors (age groups include Under-10 through Under-18) — profile visibility & sponsor discovery of minors must be reviewed before launch. See Security doc. | M |
| NFR-7 | **Auditability:** moderation actions, listing status changes, and override/restore actions on expiry are auditable (who/when/what). | S |
| NFR-8 | **Availability target:** 99.5% monthly for the API during MVP (assumption — no SLA stated anywhere). | S |
| NFR-9 | **Localization shell:** language setting exists, English-only content at MVP (assumption). | C |
| NFR-10 | **Offline:** no offline mode required for MVP (assumption). | C |

---

## Mandatory Fields Reference (from PDF)

Source: `SportX_India_Mandatory_Fields_MVP.pdf`. Status column: `■ Mandatory` or `Optional` as defined in the PDF. Fields marked "System" are auto-managed. All fields below are now reflected in `Database-Design.md`.

### Athlete

| Field | Status | DB Column |
|---|---|---|
| Full Name | ■ Mandatory | `athlete_profiles.full_name` |
| Profile Photo | ■ Mandatory | `athlete_profiles.photo_media_id` |
| Sport | ■ Mandatory | `athlete_sports.sport_id` |
| City | ■ Mandatory | `athlete_profiles.city_id` |
| Date of Birth | ■ Mandatory | `athlete_profiles.date_of_birth` |
| Gender | ■ Mandatory | `athlete_profiles.gender` |
| Contact Number | Optional | `users.phone` |
| Email | Optional | `users.email` |
| Academy | Optional | `athlete_profiles.academy_id` |
| Coach | Optional | `athlete_profiles.coach_id` |
| Position | Optional | `athlete_profiles.position` |
| Experience | Optional | `athlete_profiles.experience` |
| Achievements | Optional | `achievements.text` |
| Videos | Optional | `media_items` (media_type=video) |
| Certificates | Optional | `media_items` (media_type=document) |
| Ranking | System | — |
| Verification | System | — |

### Coach

| Field | Status | DB Column |
|---|---|---|
| Full Name | ■ Mandatory | `coach_profiles.full_name` |
| Sport | ■ Mandatory | `coach_profiles.sport_id` |
| City | ■ Mandatory | `coach_profiles.city_id` |
| Contact Number | ■ Mandatory | `coach_profiles.contact_number` |
| Experience | ■ Mandatory | `coach_profiles.experience` |
| Profile Photo | Optional | `coach_profiles.photo_media_id` |
| Qualification | Optional | `coach_profiles.qualification` |
| Certifications | Optional | `coach_profiles.certifications` |
| Academy | Optional | `coach_profiles.academy_id` |
| Languages | Optional | `coach_profiles.languages` |
| Email | Optional | `coach_profiles.email` |
| Personal Coaching | Optional | `coach_profiles.personal_coaching` |
| Fees | Optional | `coach_profiles.fee_structure` |
| Achievements | Optional | — (not modeled separately; future) |
| Rating | System | — |
| Verification | System | — |

### Academy

| Field | Status | DB Column |
|---|---|---|
| Academy Name | ■ Mandatory | `academies.name` |
| Sport(s) Offered | ■ Mandatory | `academy_sports` |
| Address | ■ Mandatory | `academies.address` |
| City | ■ Mandatory | `academies.city_id` |
| Contact Number | ■ Mandatory | `academies.contact_number` |
| Google Maps Location | ■ Mandatory | `academies.google_maps_url` |
| Description | ■ Mandatory | `academies.description` |
| Logo | Optional | `academies.logo_media_id` |
| Cover Photo | Optional | `academies.cover_media_id` |
| Email | Optional | `academies.email` |
| Website/Social Media | Optional | `academies.website` |
| Head Coach | Optional | `academies.head_coach_id` |
| Year Established | Optional | `academies.year_established` |
| Age Groups | Optional | `academies.age_groups` |
| Training Timings | Optional | `academies.timings` |
| Fees | Optional | `academies.fee_range` |
| Facilities | Optional | `academies.facilities` |
| Achievements | Optional | `academies.achievements` |
| Photos & Videos | Optional | `media_items` morphMany |
| Verification Badge | System | `academies.verification_badge` |

### Tournament

| Field | Status | DB Column |
|---|---|---|
| Tournament Name | ■ Mandatory | `tournaments.name` |
| Sport | ■ Mandatory | `tournaments.sport_id` |
| Organizer | ■ Mandatory | `tournaments.organizer_name` |
| Tournament Dates | ■ Mandatory | `tournaments.start_date`, `tournaments.end_date` |
| Registration Deadline | ■ Mandatory | `tournaments.registration_deadline` |
| Venue | ■ Mandatory | `tournaments.venue` |
| Google Maps | ■ Mandatory | `tournaments.google_maps_url` |
| Entry Fee | ■ Mandatory | `tournaments.entry_fee` |
| Contact Number | ■ Mandatory | `tournaments.contact_number` |
| Registration Link | ■ Mandatory | `tournaments.registration_link` |
| Banner | Optional | `tournaments.banner_media_id` |
| Age Category | Optional | `tournament_categories.age_group_id` |
| Gender | Optional | `tournaments.gender` |
| Prize Pool | Optional | `tournaments.prize_pool` |
| Rules | Optional | `tournaments.rules` |
| Fixtures | Optional | — |
| Results | System | `tournament_results` |
| Photos | Optional | `media_items` |
| Status | System | — |
| Verification | System | — |

### Trial

| Field | Status | DB Column |
|---|---|---|
| Trial Name | ■ Mandatory | `trials.name` |
| Organization | ■ Mandatory | `trials.organization_name` |
| Sport | ■ Mandatory | `trials.sport_id` |
| Date | ■ Mandatory | `trials.event_datetime` |
| Venue | ■ Mandatory | `trials.venue` |
| Google Maps | ■ Mandatory | `trials.google_maps_url` |
| Contact Number | ■ Mandatory | `trials.contact_number` |
| Registration Deadline | ■ Mandatory | `trials.registration_deadline` |
| Eligibility | Optional | `trials.eligibility` |
| Required Documents | Optional | `trials.required_documents` |
| Vacancies | Optional | `trials.vacancies` |
| Benefits | Optional | `trials.benefits` |
| Registration Fee | Optional | `trials.entry_fee` |
| Status | System | `trials.status` |
| Verification | System | — |

### Sponsor / Scholarship

| Field | Status | DB Column (sponsorships / scholarships) |
|---|---|---|
| Organization Name | ■ Mandatory | `organization_name` |
| Sponsorship/Scholarship Name | ■ Mandatory | `sponsorships.title` / `scholarships.name` |
| Sport | ■ Mandatory | `sport_id` |
| Eligibility | ■ Mandatory | `eligibility_criteria` / `eligibility` |
| Last Date | ■ Mandatory | `deadline` |
| Application Link | ■ Mandatory | `application_link` |
| Contact Email/Number | ■ Mandatory | `contact_email`, `contact_phone` |
| Logo | Optional | `logo_media_id` |
| Benefits | Optional | `benefits_offered` / `benefits` |
| Amount | Optional | `amount` |
| Documents Required | Optional | `documents_required` |
| Description | Optional | `description` |
| Verification | System | — |

### Sports Venue (new entity from PDF)

| Field | Status | DB Column |
|---|---|---|
| Venue Name | ■ Mandatory | `sports_venues.name` |
| Sport | ■ Mandatory | `sports_venues.sport_id` |
| Address | ■ Mandatory | `sports_venues.address` |
| Google Maps | ■ Mandatory | `sports_venues.google_maps_url` |
| Contact Number | ■ Mandatory | `sports_venues.contact_number` |
| Photos | Optional | `sports_venues.photos` (json) |
| Booking Available | Optional | `sports_venues.booking_available` |
| Pricing | Optional | `sports_venues.pricing` |
| Facilities | Optional | `sports_venues.facilities` (json) |
| Working Hours | Optional | `sports_venues.working_hours` |
| Rating | System | — |
| Verification | System | — |

---

## Traceability: MVP Feature → FR(s)

| MVP Feature (Overview) | FR IDs |
|---|---|
| Sign Up / Login | FR-AUTH-1…5, role onboarding FR-AUTH-6…10 |
| Digital Profile | FR-ATH-1, FR-ATH-2 |
| Academy Directory + Search & Filter | FR-ATH-4, FR-DISC-1…4 |
| Coach Directory + Search & Filter | FR-ATH-5, FR-DISC-1…4 |
| Book/Enquire with Coaches | FR-ATH-6, FR-ENQ-1…3 |
| Trial Listings + Search & Filter | FR-ATH-7, FR-DISC-1…4 |
| Trial Registration | FR-ATH-8 |
| Tournament Calendar + Registration | FR-ATH-9, FR-ATH-10 |
| Scholarship Feed | FR-ATH-11, FR-ATH-17, FR-ADMIN-11 |
| Sponsorship Opportunities | FR-ATH-12 |
| Apply/Pitch to Sponsors | FR-ATH-13 |
| Universal Search | FR-DISC-1, FR-DISC-2 |
| Global Filters | FR-DISC-3, FR-DISC-4 |
| Deadline & Date Reminders | FR-ATH-16, FR-NOTIF-2 |
| Report a Listing | FR-TRUST-1, FR-TRUST-2 |
| Coach: Own Profile / Enquiry Inbox / Browse Like Any User | FR-COACH-1, FR-COACH-3…5 |
| Academy: Listing / Trial Posting / Registrants / Enquiries | FR-ACAD-1…7 |
| Organizer: Trials / Tournaments / Registrations / Results | FR-ORG-1…8 |
| Sponsor: Listing / Discovery / Applications / Shortlisting | FR-SPON-1…8 |
| Admin: Content CRUD / Moderation / Expiry Rules / Categories | FR-ADMIN-1…11 |
