# 03c — M4 (Events, Trials & Registrations) + M5 (Opportunities) End-to-End Audit

Scope: MVP_FEATURE_LIST.md M4.1–M4.7, M5.1–M5.6. API = `sportx-api/`, Flutter = `sportx_app/`.
Method: static trace of routes → controllers → models → migrations → Flutter screens. No code modified.
Date: 2026-11-02.

---

## Architecture context (read this first)

The "unified events" layer (Phase 8) is a facade over two separate tables (`trials`, `tournaments`) that share one id space:
- `sportx-api/app/Http/Controllers/EventController.php` (create/detail/publish/close, delegates to Provider*)
- `sportx-api/app/Http/Controllers/EventRegistrationController.php` (unified registrant ops: list, detail, approve/reject, bulk, CSV export)
- Legacy per-type paths still fully live: `RegistrationController.php` (register, approve/reject per type), `ProviderTrialController.php`, `ProviderTournamentController.php`.

Id collision is a recurring hazard. `EventRegistrationController::eventOf()` (lines 28–61) resolves `/events/{id}` against BOTH tables and disambiguates by ownership — every unified endpoint pays this tax, and `EventController::show()` has no published check (see M4.2).

---

## M4.1 Create / edit event or trial — Status: DONE (gaps: no required docs on tournaments, edit can silently shift expiry)

Evidence:
- Routes: `routes/api.php:352–364` (per-type `/me/trials`, `/me/tournaments` + publish/close), `367–373` (unified `/me/events`).
- Trials: `ProviderTrialController::store()` L61–100 — role gate `organizer|academy|coach` (L64); validates name/sport/venue/event_datetime/fee(`entry_fee` string, display-only)/`vacancies`/`required_documents`/status draft|published (L66–80). Auto-approve platform setting can force published→draft (L82–88).
- Tournaments: `ProviderTournamentController::store()` L53–133 — role gate `organizer` only (L56); categories with per-category `capacity` inside a `DB::transaction` (L85–124). **No `required_documents` field exists for tournaments at all.**
- Edit: `ProviderTrialController::update()` L102–125, `ProviderTournamentController` analogous; unified `EventController::update()` L109–124 with owner checks (L114, L120).
- Draft/publish: `publish()` calls `ExpiryService::onPublish()` (ProviderTrialController L127–135; ProviderTournamentController L231–236).

Gaps:
1. MEDIUM — Required documents (M4.1 acceptance item) only implemented for trials; tournament creation/edit has no such field, so tournament registration can never collect docs.
2. LOW — `update()` never re-runs `ExpiryService::onPublish()`: an organizer who edits the event date after publish leaves the expiry event scheduled from the old date.
3. LOW — Trials fee is a free-text string (`entry_fee` max 60), tournaments numeric; Flutter treats both as number.

---

## M4.2 Event detail — Status: DONE (slots math OK; unified endpoint leaks drafts)

Evidence:
- Legacy detail endpoints enrich with stats: `TrialController::show()` `app/Http/Controllers/TrialController.php:61–77` (`withCount` registrations + confirmed, `trialStats()`, viewer `registration_status`), `TournamentController::show()` L38–66 (`withRegistrationCounts()` + `registrationStats()` + draft visible to owner L44–58).
- Slot math: `Trial` model — `trialStats()` (EventController L77–91, ProviderTrialController L45–59): `spots = vacancies`, `filled = confirmed_registrations_count` (approved only), `spots_left = max(0, spots - confirmed)`, `utilization_percent`. Tournament: `Tournament.php:103–144` sums `categories.capacity` via `withSum('categories as total_spots', 'capacity')` and uses approved count as filled.
- Flutter trial detail: `sportx_app/lib/features/trial/presentation/screens/trial_detail_screen.dart:43–48` — `'Spots': '${t.spotsLeft ?? 0} left'` rendered in detail rows; fee display L44; role-gated register CTA L29–38.
- Organizer side capacity bar: `organizer_event_management_screen.dart:58–67` — `fill = (registered / totalCapacity).clamp(0, 1)` where totalCapacity = `t.totalSpots` and registered prefers `confirmedRegistrationsCount`.

Gaps:
1. MEDIUM — `EventController::show()` (L93–106) fetches `Trial::find($id)` with **no status filter**: any authenticated user can read DRAFT trials via `/events/{id}?type=trial` (Tournament path has no filter either — but trial path also bypasses the `TrialController::published()` guard). Draft leak.
2. LOW — "filled" counts only approved, but since capacity is never enforced server-side (see M4.3), "spots left" overstates availability: 10 slots, 20 pending registrations still shows 10 left.

---

## M4.3 Event registration — Status: PARTIAL (duplicate guard OK via DB unique; capacity NOT enforced; tournament docs/consent/team-fields missing)

Evidence — capacity: **NOT ENFORCED anywhere**:
- `RegistrationController::storeTrial()` L21–94: checks only `isRegisterable()` (status published + deadline future, `Trial.php:67–70`). No `vacancies` comparison. Duplicate check at L37–40, then `DB::transaction` around insert (L42–93) — but the duplicate check is OUTSIDE the transaction.
- `RegistrationController::storeTournament()` L298–370: checks only `status === 'published'` (L300) and category ownership (L321–322). **No capacity check whatsoever** — grep of the whole controller for capacity shows only the capacity-read/update endpoints (L465–501). Category `capacity` and trial `vacancies` are display-only.
- grep across `app/Http/Controllers/RegistrationController.php` for capacity/vacancies: matches only at L475–478, L492, L496–499 (capacity management endpoints). Confirmed: check-then-insert, no `lockForUpdate`, no slot decrement, no waitlist move on rejection.

Evidence — duplicate registration: DB-protected:
- `database/migrations/2026_01_01_000012_create_trials_tables.php:58` — `$table->unique(['trial_id', 'athlete_id']);`
- `database/migrations/2026_01_01_000013_create_tournaments_tables.php:74` — `$table->unique(['tournament_id', 'category_id', 'athlete_id'], 'tour_reg_unique');`
- App-level friendly 409: storeTrial L37–40, storeTournament L313–319. A true race duplicates nothing (DB rejects), but the user gets a 500 instead of a 409 because the insert isn't wrapped to catch the unique violation.
- Opportunities (`opportunity_applications`) have NO unique index (`2026_10_15_000001_create_opportunities_tables.php`, applications block, no unique) — app-level `exists()` only (OpportunityController L204–208). Race can produce duplicate applications.

Evidence — team/consent/documents:
- Trials: document upload accepted (`document_media_ids`, L28–35, stored in `trial_registration_documents` L58–64), `parental_consent` bool L49.
- Tournaments: **no document fields, no consent field accepted** (validation L305–311: category_id, participation_type, team_name, payment_status, reminder_enabled only).
- Flutter tournament form sends `team_manager`, `captain_name`, `coach_name`, `number_of_players` (`tournament_registration_screen.dart:59–66`) — **the API validation silently drops all four**; data never stored. UI-only columns.

Gaps / Severity:
1. **BLOCKER** — Capacity not enforced (M4.3 acceptance says "capacity enforced"). Unlimited registrations accepted for full trials and categories; waitlist flags exist in schema but nothing writes `waitlisted`.
2. HIGH — Tournament registration: no document upload, no consent, and 4 team-form fields silently discarded.
3. MEDIUM — Opportunity applications: no DB unique index (app-level check only).
4. LOW — Duplicate-reject path returns 500-shaped error (unique violation not caught) for trial/tournament.

---

## M4.4 Manage registrations — Status: DONE backend / PARTIAL frontend (bulk approve/reject is API-only)

Backend:
- Unified list w/ tabs + search: `EventRegistrationController::index()` L105–126 (`status` filter, `q` on athlete name, paginated 30) with `assertOwner` (L89–102, admin bypass).
- Registrant detail incl. docs: `show()` L129–174, `assertCanView` L344–357 (owner, admin, or the athlete themselves).
- Single approve/reject delegate to per-type handlers which notify: `decide()` L288–342 → `RegistrationController::approveTrial/approveTournament/reject*` (each with `authorizeOwner` + activity log + notification).
- Bulk: `bulk()` L190–234 — ownership check (L198–199), caps ids at 200, per-row try/catch returning `processed`/`failed`.

FRAGILE (verified against vendor code): `bulk()` builds a sub-request with `'QUERY_STRING' => ['type' => $kind]` (L209–214) claiming "The sub-request MUST carry the type". Symfony `Request::create` **overwrites** `QUERY_STRING` from the URI (`vendor/symfony/http-foundation/Request.php:486–491`) and for POST puts `$parameters` into POST, not query — so the sub-request arrives with NO type and `decide()` falls into the `auto` id-collision-resolution branch (L313–341). Works for the common owner case via ownership disambiguation, but the intended type pinning silently does not function; an id shared between a trial-registration and tournament-registration the caller owns resolves to the trial first.
- Also: bulk **reject without a reason** fails per-row — `rejectTournament()` requires `rejection_reason` (RegistrationController L440–442) and `rejectTrialNew()` too (L215–217); bulk passes `reason => null`, each row lands in `failed[]`.

Frontend:
- `sportx_app/lib/features/organizer/presentation/screens/registration_management_screen.dart` — 4 tabs All/Approved/Pending/Rejected with counts (L215–220, L249–257), client-side search (L536–548), per-row approve (L868–908) and reject-with-reason dialog (L910–960) hitting legacy PATCH `/registrations/tournaments/{id}/approve|reject` (`organizer_provider.dart:353–371`), empty/error/retry states (L513–570), external-registration explainer banner (L303–344).
- **Bulk approve/reject: NOT in the UI.** The API helper `bulkDecideRegistrations()` exists (`unified_events_provider.dart:253–270`) but grep shows it is called from **zero** screens. The selection checkboxes on rows (L715–743, "Design board · bulk selection checkbox") feed only the export hint text — there is no bulk action button anywhere. M4.4 acceptance "bulk approve/reject" is unmet in the app.

Gaps:
1. HIGH — Bulk approve/reject UI absent despite API + helper existing; selection checkboxes are dead weight.
2. MEDIUM — Bulk type-pinning broken (vendor-verified); reject-without-reason fails per-row.
3. LOW — Trial management UI exists separately (`registration_picker_screen.dart`, trial endpoints in organizer_provider); tabs parity with OR.7 varies.

---

## M4.5 Export registrant list — Status: PARTIAL (CSV exists, ownership OK, content thin, selection ignored)

Backend:
- `EventRegistrationController::export()` L237–265: `assertOwner` (L240), streams real `text/csv` attachment `event-{id}-registrations.csv`.
- Columns: `id, athlete, status, payment_status, created_at` (L247–256). That's it — no category, no team name, no contact, no playing role, **no uploaded documents**, no rejection reason.

Frontend:
- `registration_management_screen.dart:170–197` `_exportCsv()` fetches `/events/{id}/registrations/export?type=tournament` as plain text and hands it to the OS share sheet (`Share.share`). Guarded by `_exporting` flag; honest comment: "The previous implementation only showed the character count of a locally built string."
- The selected-row checkboxes do NOT filter the export — endpoint always exports every registration (L242–244 has no id filter), UI hint "Select rows to export" (L430) is misleading.

Gaps:
1. MEDIUM — Export omits documents, category, team, contact fields — barely usable as a check-in sheet.
2. LOW — Selection ignored; "CSV/Excel" reduced to CSV; shared as text blob rather than a .csv file.

---

## M4.6 Registration status notifications — Status: DONE (with a type-naming quirk)

Evidence:
- Created in every approve/reject handler: approveTrial L199–207, rejectTrialNew L229–237, legacy rejectTrial L172–180, approveTournament L424–432, rejectTournament L452–460 — in-app row via `NotificationService::createStatic` with `action_url` deep links (`/registrations/trials/{id}`, `/registrations/tournaments/{id}`).
- Push: `NotificationService::create()` (`app/Services/NotificationService.php:66–131`) writes the in-app row first, dispatches `NotificationCreated`, chunks device tokens and queues `SendPushNotification` on the `push` queue (L120–129); FCM delivery in `app/Jobs/SendPushNotification.php` → `FCMService::sendPushNotification` (L8, L36–42), with `push_status` guarding double-send (L76). Push payload carries `action_url` (`app/Models/Notification.php:147–163`).
- Deep link honored client-side: `sportx_app/lib/core/services/push_notification_service.dart:69–89, 138–158, 240–244` (cold-start + background tap both route via `action_url`).
- Organizer is also notified of new registrations: storeTrial L66–80, storeTournament L339–355.
- Preference gating with hard-override list `['account_action', 'registration_approved', 'registration_rejected']` (NotificationService L14–19).

Gaps:
1. MEDIUM — The approve/reject notifications are created with `type: 'status_update'`, which matches **neither** hard-override string, so registration outcomes are treated as ordinary `events`-category notifications and CAN be suppressed by user prefs — contradicting the stated intent of HARD_OVERRIDE_TYPES.
2. LOW — Bulk rejects swallow per-row notification failures into `failed[]` silently client-side (Flutter bulk helper returns bare bool anyway — and it isn't wired to any screen).

---

## M4.7 Auto-expiry — Status: DONE (job scheduled + functional + idempotent; no owner notification; AD.10 admin rules exist)

Evidence:
- Scheduler: `sportx-api/routes/console.php:19` — `Schedule::job(new SweepExpiredContentJob)->hourly();` (as claimed).
- Job: `app/Jobs/SweepExpiredContentJob.php:14–20` → `ExpiryService::sweep()`.
- Rule config: `ExpiryService::onPublish()` (`app/Services/ExpiryService.php:23–59`) reads active `ExpiryRule` per content_type with AD8 defaults fallback (trial 1 day after event date, tournament 3 after end date, else deadline day-end); MAP covers trial/tournament/sponsorship/scholarship/opportunity (L16–22). Writes `expires_at` on the listing and a single pending `ExpiryEvent` (replaces prior pending, L44–57).
- Sweep: `sweep()` L61–82 — due pending events → listing status `published` → `expired`; event marked `expired` with `executed_at`. Idempotent: event row transitions out of `pending`, so re-runs don't double-act; listings not in `published` are skipped but their event is still finalized.
- Admin: `routes/api.php:563–567` — GET/PUT `/admin/expiry-rules`, `/admin/expiry/monitor`, override/restore endpoints (`Admin/AdminExpiryController.php:21–50`); Flutter admin screen `features/admin/presentation/screens/admin_expiry_rules_screen.dart` + provider calls (`admin_provider.dart:634, 647`).

Gaps:
1. MEDIUM — Sweep never notifies owners (no NotificationService call anywhere in ExpiryService) — M4.7's "old doc" reference implies closure visibility; expired listings just silently flip status.
2. LOW — Edits that move the event date do not reschedule the pending expiry event (see M4.1 gap 2); restore/override exist for repair.
3. LOW — `sweep()` loads ALL due events unchunked; fine at MVP scale.

---

## M5.1 Opportunity listing & detail — Status: DONE

Evidence:
- Public list: `routes/api.php:388`, `OpportunityController::index()` L32–58 — `Opportunity::open()` (published only, `Opportunity.php:71`), filters type/sport/age_group/deadline window/q, capped per_page 50.
- Detail: `show()` L63–93 — published-or-owner 404 gate (L72), sanctum viewer resolution for `applied`/`application_status`/`saved` state (L79–90).
- Flutter: `opportunity_list_screen.dart` (type chips incl. scholarship/sponsorship/tryout/camp, L27), `opportunity_detail_screen.dart` (type badge, amount, deadline, description, eligibility, benefits, applied state L139–152).

Gaps: LOW — provider/organizer identity not rendered from `provider` morph on the API payload (detail relies on created_by indirectly); cosmetic.

---

## M5.2 Create opportunity — Status: DONE (backend role-checked; client excludes organizer by product decision)

Evidence:
- `store()` L98–130 gated by `resolveProvider()` L340–351: match on `$user->role` → academy/organizer/coach/scout, each requiring its profile, `default => abort(403)`. So backend allows organizer; Flutter deliberately excludes organizer (`core/router.dart:296–298` + `core/role_config.dart:55–58, 65–66` — "organizers never post scholarships/sponsorships").
- Draft/publish: `status in:draft,published` (L115), `publish()`/`close()` with `authorizeOwner` (L163–185); expiry wired on publish (L125–127).

Gaps:
1. LOW — Backend/client mismatch on organizer: an organizer can still POST via API; product rule enforced only in the app.
2. MEDIUM — Posting form (`post_opportunity_screen.dart`) omits `sport_id`, `age_group_id`, `documents_required`, `logo`; **deadline is a free-text TextFormField "Deadline (YYYY-MM-DD)"** (L137–142) with no date picker — invalid input surfaces only as a server 422.

---

## M5.3 Apply with pitch — Status: PARTIAL (pitch + profile snapshot yes; document upload not wired in UI; no dedupe index)

Evidence:
- `apply()` L190–233 — athlete role middleware (`routes/api.php:396`), open check `isRegisterable()` (L193), required `pitch` max 2000 (L199), optional `document_media_ids` (L200–201), 409 on duplicate (L204–208), **profile auto-attached via `snapshot`** (`athleteSnapshot()` L373–385: name, sports, city, age group, skill level, achievements count), owner notification with action_url (L219–230).
- Flutter: `opportunity_detail_screen.dart:33–57` apply with pitch validation, busy-state button (double-submit guarded via `_applying`); provider `apply()` posts only `{pitch}` (`opportunity_provider.dart:109–111`) — **no document upload UI at all**.

Gaps:
1. HIGH — Document attachment (M5.3 acceptance: "+ documents") not reachable from the app; API supports it.
2. MEDIUM — No DB unique on (opportunity_id, athlete_id) — duplicate race possible (see M4.3).
3. LOW — Duplicate 409 message fine, but Flutter surfaces generic error text.

---

## M5.4 My Opportunities — Status: DONE

Evidence:
- `mine()` L238–279: applied (applications w/ opportunity, paginated), saved (SavedItem join — note: filtered through `Opportunity::open()`, so saved-but-closed items disappear), created (by `created_by_user_id`); providers without athlete profile default to `created` instead of 403 (L243–246).
- Flutter: `my_opportunities_screen.dart` — 3 tabs Applied/Saved/Created (L25, L56–61) with status chips.

Gaps: LOW — Saved tab hides closed/expired opportunities the user deliberately saved (opinionated but surprising).

---

## M5.6 Scouting opportunities hub (SC.11) — Status: PARTIAL

Evidence:
- The hub is the unified `/opportunities` list with type filters (scholarship/sponsorship/tryout/camp) at `opportunity_list_screen.dart:27` — scout role can browse and the scout dashboard routes into it; sponsors' legacy route redirects to `/opportunities` (`core/router.dart:209–210, 476–486`).
- The designed "Trials / Scholarships / Camps" three-tab hub shape (SC.11) is approximated by filter chips, not tabs; tryouts and camps are separate types rather than merged "Trials".

Gaps: LOW/MEDIUM — hub exists and is reachable; tab-vs-chip deviation and no scout-specific entry surface beyond role dashboard.

---

## M5.5 (adjacent, P1) Applicant review — Status: DONE

Evidence: `applications()` L284–295 with `authorizeOwner`; `review()` L300–333 — status shortlisted|declined only, `decision_note`, `replied_at`, athlete notification with deep link `/my-opportunities` (L322–330). Flutter inbox `opportunity_applications_screen.dart:39, 57–71, 129–141` with busy-gated shortlist/decline buttons.

---

## Payment reality check (M4.13 / fee display-only)

- No payment gateway anywhere; `entry_fee`/`amount` are display strings/decimals. Registration accepts `payment_status in:pending,paid,waived` client-supplied (storeTournament L309) — the athlete can self-declare "paid" at registration time (LOW severity abuse vector; organizer-side PATCH `/registrations/tournaments/{id}/payment` exists for manual reconciliation, organizer_provider.dart:340–347).
- Trial registration screen shows "Entry Fee: ₹X (Approval Required)" / "Free Entry (Approval Required)" (`trial_registration_screen.dart:262–266`); no "pay at venue" text anywhere — fee is informational only. Consistent with M4.13 being P2/not started.

---

## Flutter UX summary (registration forms, double-submit, states)

- Double-submit protection: both forms use `_submitting` flags disabling the button (`trial_registration_screen.dart:274–294`, `tournament_registration_screen.dart:67–97`); opportunity apply uses `_applying` (opportunity_detail_screen.dart:48, 55–56, 177–181).
- Validation: trial form has NO field validation (all optional client-side; even the "ID Proof" upload is optional regardless of `required_documents` — the required-documents list from the trial is never consulted client-side). Tournament form validates category/team/players/captain with snackbars (L37–57). Opportunity pitch validated non-empty.
- Doc upload: trial single-file picker with success check icon (`trial_registration_screen.dart:58–65, 205–233`) — no per-file progress indicator, single doc slot only (screen built for "ID Proof", while API accepts an array).
- **DOB collected in the trial form (L42–56) but never sent to the API** — `_submit()` posts playing_role/medical/parental_consent/document_media_ids only (L70–75). Dead UI field; athlete age screening impossible.
- Confirmation screen: `shared/presentation/screens/registration_confirmation_screen.dart` — success state with ref/event/date/venue. Note: tournament path fabricates `registration_ref` client-side as `'TRN-{id}'` (tournament_registration_screen.dart:81) — the API returns no ref for tournaments.
- My Registrations: `shared/presentation/screens/my_registrations_screen.dart` — approval-status colors/icons (L55–66), upcoming/past split excluding cancelled (L99–104), cancel action with confirm (L197–204) via `DELETE /me/registrations/{id}` (unified_events_provider.dart:272–277).
- Empty/error states: consistent retry buttons + skeletons across registration management, detail screens; searchable empty state "No results for ..." (registration_management_screen.dart:549–556).

---

## Verdict table

| ID | Feature | Status | Severity of top gap |
|---|---|---|---|
| M4.1 | Create/edit event or trial | DONE | MEDIUM (no required docs for tournaments; expiry not rescheduled on edit) |
| M4.2 | Event detail (slots/status) | DONE | MEDIUM (draft leak via unified `/events/{id}`) |
| M4.3 | Event registration | PARTIAL | **BLOCKER (capacity not enforced)** + HIGH (tournament docs/consent/team fields dropped) |
| M4.4 | Manage registrations | PARTIAL | HIGH (bulk approve/reject not in UI; bulk type-pin broken) |
| M4.5 | Export CSV | PARTIAL | MEDIUM (thin columns, selection ignored) |
| M4.6 | Status notifications | DONE | MEDIUM (`status_update` bypasses hard-override intent) |
| M4.7 | Auto-expiry | DONE | MEDIUM (no owner notification) |
| M5.1 | Opportunity listing/detail | DONE | LOW |
| M5.2 | Create opportunity | DONE | MEDIUM (free-text deadline, missing fields; organizer role mismatch) |
| M5.3 | Apply with pitch | PARTIAL | HIGH (doc upload not wired; no dedupe index) |
| M5.4 | My Opportunities | DONE | LOW (saved tab hides closed items) |
| M5.6 | Scouting hub SC.11 | PARTIAL | LOW (chips not tabs; reachable) |
