# 03 — User Flow Results (all 12 flows)

Each flow from `MVP_FEATURE_LIST.md` §5 / `SCREEN_INVENTORY.md` §12, traced screen-by-screen in code. Verdict applies to P0 steps only. Evidence refs point at the strongest citation; full detail in `_drafts/`.

| # | Flow | Verdict | First failing step |
|---|---|---|---|
| 5.1 | Onboarding & trust | **PASS with defects** | — |
| 5.2 | Athlete: discover → register for trial | **FAIL** | registration submit (capacity/dup/consent) |
| 5.3 | Athlete: scholarship / sponsorship | **PASS with defects** | — |
| 5.4 | Athlete: academy/coach enquiry | **FAIL** | provider never notified of enquiry |
| 5.5 | Athlete: build credibility | **PARTIAL** | verification docs exposed; leaderboard integrity |
| 5.6 | Networking (follow/connect/chat) | **FAIL** | chat rule (cold DMs); no block/report |
| 5.7 | Coach: program → enquiries | **FAIL** | enquiry notification never fires |
| 5.8 | Academy: listing → trial → registrants | **FAIL** | capacity; bulk actions; export thin |
| 5.9 | Organizer: event lifecycle | **FAIL** | capacity enforcement; bulk approve/reject |
| 5.10 | Scout: discover → shortlist → contact | **FAIL** | minor-contact guardian routing fictitious |
| 5.11 | Content & safety loop | **FAIL** | report/block unreachable; moderation remove 500s |
| 5.12 | Admin | **PASS with defects** | — |

---

## 5.1 Onboarding & trust — PASS with defects
Role selection → signup → email OTP (6-box, resend timer, clear error states) → guardian consent if <18 (real guardian-email OTP, persisted row) → role wizard → Home with completion meter → verification request → admin approval → badge + hard-override notification. **All steps complete.**
Defects: T&C/privacy checkbox is not recorded anywhere (legal exposure, M1.1); email auto-verified on password signup; login OTP can be skipped client-side (`require_otp=false`); forgot-password is broken end-to-end (M1.7); returning-user login works. Evidence: `OtpService.php:47-113`, `GuardianConsentService.php:57-64`, `AuthController.php:194-196`, `forgot_password_screen.dart:29`.

## 5.2 Athlete: discover → register for a trial — FAIL
Home → Explore → filter → trial detail (slots bar, fee) → registration form → confirmation (Pending) → My Registrations → notification on decision → detail. Navigation and rendering all work.
Failing step: **the registration itself is unsafe** — capacity never checked server-side (unlimited registrations; MVP rule 6 broken, `RegistrationController::storeTrial L21-94`), duplicate race returns 500 instead of 409, DOB collected but never sent (no age screening vs eligibility), required documents never enforced, athlete can self-declare `payment_status=paid`, and the approval notification's deep link 404s in-app (`/registrations/trials/{id}` unrouted). Verdict would be PASS for the happy path alone, but rule 6 is a P0 business rule.

## 5.3 Athlete: scholarship / sponsorship — PASS with defects
Opportunities list (type filters) → detail → apply with pitch (profile auto-attached as snapshot, `OpportunityController.php:373-385`) → confirmation → My Opportunities (Applied tab) → owner notified. Works.
Defects: document upload exists in API but not in the UI; no unique index on applications (double-tap race = duplicate applications); saved tab hides closed opportunities. My Opportunities → decision notification: review API exists with ownership checks; no provider review UI (P1).

## 5.4 Athlete: academy/coach enquiry — FAIL
Explore → academy/coach → program detail → enquiry form → thread created → …
Failing step: **the provider is never notified that an enquiry exists** (`EnquiryController::store :12-48` sends no notification; only replies notify, and only the athlete). The P0 flow's "Provider replies" step never triggers: a coach/academy discovers enquiries only by manually opening the inbox. Chat thread + reply flow themselves work.

## 5.5 Athlete: build credibility — PARTIAL
Profile → completion checklist (server-computed, deep links) → add sports → achievements + certificates → upload media → post updates → request verification → leaderboard.
Defects: certificates land on the public disk (anyone with the URL can fetch a minor's certificate, B-6/H-2); leaderboard climb is gameable (+50 points per self-declared achievement, unverified, uncapped — M8.1); posts can't be edited/deleted from the app.

## 5.6 Networking: follow/connect/chat — FAIL
Follow works everywhere (instant, FCM). Connect request → accept/decline/cancel/remove all work with a proper state machine, anti-spam cap, mutual auto-accept, and conversation auto-creation on accept.
Failing steps: **(1) chat rule violated** — with the adult default `who_can_message=everyone`, any user can cold-DM any other user (`ConversationController::peerChatGate :277-319`, fall-through at `:318`); minors ARE gated (verified consent + allow_messages), so the child-safety floor holds, but the adult no-cold-DM rule does not. **(2) No block button exists anywhere in the app** (`blockUser()` zero callers) and blocked users remain visible in discovery/search. **(3) Chat has no report/block menu** despite spec. Minor's revoked consent leaves existing private threads open (gate not re-checked at send).

## 5.7 Coach: program → enquiries — FAIL
Onboarding → programs CRUD (fully wired, drafts persist) → publish → appears in profile/Explore.
Failing step: enquiry arrives **silently** (see 5.4) — notification for new enquiries is never sent, so the "Enquiry notification → Reply in chat" step of the flow cannot happen without manual inbox checks. Reply itself works and does notify the athlete.

## 5.8 Academy: listing → trial → registrants — FAIL
Listing live in Explore; facilities CRUD works; create trial (draft/publish, role-gated); registrations arrive; approve/reject per-row works with notifications.
Failing steps: capacity unenforced (5.2); **bulk approve/reject impossible from the UI** (checkboxes wired to nothing, `registration_management_screen.dart:715-743`); export CSV works but is thin and ignores row selection; trial auto-close works (hourly sweep) but the owner isn't notified; scholarship posting works but applicant review has no UI (P1).

## 5.9 Organizer: event lifecycle — FAIL
Create (drafts persist per-form) → publish → visible in Explore → share fails (URLs 404) → registrations → per-row approve/reject works.
Failing steps: capacity (5.2); bulk actions (5.8); **tournament creation lacks required-documents entirely**; announcement screen has no backend; schedule editor (P1) doesn't exist; results publishing exists (P1, thin). The P0 event lifecycle is functional one-registrant-at-a-time but violates capacity and bulk-management requirements.

## 5.10 Scout: discover → shortlist → contact — FAIL
Dashboard (partial: stale "upcoming" trials, minors' full names in Top Talents) → discover (filters work, minus position) → athlete profile → **shortlist with status + private note works and is provably private** (owner-scoped, no IDOR found, rule 10 held) → observation works → contact…
Failing step: **"minors route to guardian" is fictitious.** `AthleteContactController.php:39-49` sends the "guardian review" notification to the *minor's own user_id* (no guardian account exists anywhere — consent stores guardian name/phone/email as strings), and `ScoutConnectionController::store :34-77` has no minor handling at all. The only real protection left is the chat gate after acceptance. Also: adding an athlete to a shortlist notifies the athlete with the scout's real name — rule-10 tension for a feature meant to be discreet.

## 5.11 Content & safety loop — FAIL
Report: reachable only from 4 listing detail screens (`detail_page_template.dart:363`) — **posts and profiles cannot be reported from the app**, violating rule 9. Block: **unreachable** (no button anywhere; Safety Centre can only show an empty list). Moderation: API approve/warn/suspend work with notifications + audit logs; **remove on post/facility reports throws 500** (sets a nonexistent `status` column, `AdminModerationController.php:141`) leaving the report pending and content live; the Blade panel's "resolve" closes reports while leaving content live, and its "remove" hard-deletes without notifying anyone. Repeat-offender tracking doesn't exist. The safety loop cannot be completed by end users or admins.

## 5.12 Admin — PASS with defects
Login (Blade: CSRF + throttled + forced TOTP; API: token cannot reach `/admin/*` until TOTP verified) → dashboard (KPIs, minus two wireframe tiles) → verification queue (complete, the best surface) → content manager (works; 4 entity types unaudited) → master data (complete + seeded) → expiry rules (Blade chain works; admin API updateRules 500s; Flutter admin screen is a mock). Defects: admin API login/2FA unthrottled; seeded TOTP secret committed to the repo; suspended users keep live sessions; `google2fa_secret` serialized out of `/admin/users`.

## Cross-cutting user-experience findings (all roles)
- Feedback: loading/empty/error+retry states are broadly present (shared `EmptyState`, 20+ skeletons); the model implementation is Notifications. Weak spots: universal search errors render as "No results", no offline detection anywhere (no `connectivity_plus`), no upload progress/cancel.
- Dead ends: every push tap on `/account-status`, `/my-reports`, `/registrations/{type}/{id}` lands on "Page not found" (unrouted action_urls); all external share links 404.
- Notifications: registration outcomes are preference-suppressible (typed `status_update`, not the hard-override types); message icon has no unread badge; enquiry creation is silent.
- Logout clears session properly (server revoke + FCM unregister + secure-storage wipe); settings-screen logout skips the confirmation dialog.
