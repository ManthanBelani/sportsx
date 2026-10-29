# Verification Badge (Blue Check) — Implementation Plan

> Goal: every role (athlete, coach, academy, organizer, sponsor, talent scout) can
> request a verification badge, upload proof documents, and get approved/rejected
> from the admin side. After approval the green/blue check shows next to the name
> across the app.

---

## 1. Current status (audit of the codebase)

### 1.1 Backend — ALREADY IMPLEMENTED ✔ (nothing to build)

| Piece | File | Notes |
|---|---|---|
| Table | `sportx-api/database/migrations/2026_10_03_000001_create_verification_requests_table.php` | `requester_user_id`, `verifiable` (morphs), `status[pending|approved|rejected]`, `proof_media_ids` (json), `notes`, `reviewed_by`, `decision_reason`, `reviewed_at` |
| Model | `sportx-api/app/Models/VerificationRequest.php` | `approve($admin, $reason)` L102, `reject($admin, $reason)` L114, `setBadge()` L129 writes `verification_badge` (academy/coach) or `verification_status` (organizer/sponsor) |
| Controller | `sportx-api/app/Http/Controllers/VerificationController.php` | `store()` L43 (request), `index()` L89 (my requests), admin `queue()` L111, `show()` L133, `approve()` L143, `reject()` L168 |
| Routes | `sportx-api/routes/api.php` | User: `POST /me/verification` (L151, throttle 5/min), `GET /me/verification` (L152). Admin: `GET /admin/verification`, `GET /admin/verification/{id}`, `PATCH .../approve`, `PATCH .../reject` (L537-540, behind `role:admin` + `admin.2fa`) |
| Tests | `sportx-api/tests/Feature/VerificationRequestTest.php` | 12 tests: ownership 403, duplicate-request reuse, approve sends notification, reject-requires-reason, badge flip, etc. |
| Seed data | `sportx-api/database/seeders/TrustSafetySeeder.php` L83-97 | pending/approved/rejected example requests |

Request payload (`POST /me/verification`):

```json
{
  "verifiable_type": "athlete_profile",   // athlete_profile | coach_profile | academy | organizer_profile | talent_scout_profile
  "verifiable_id": 12,                    // pk of the profile row
  "notes": "Additional context (optional)",
  "proof_media_ids": [61, 62]             // media_items ids of uploaded docs
}
```

Constraints enforced server-side: only your own profile (403 otherwise), one
live request at a time (a pending request is reused, L62-74).

On decision the API writes an `account_action` notification with
`action_url: '/profile'` and flips the badge column on the profile table.

### 1.2 User app (Flutter) — UI exists but DEMO-ONLY ✘

- `sportx_app/lib/features/auth/presentation/screens/verification_screen.dart`
  - Has the full UI (status card, requirements, two `MediaUploadTile`s, notes,
    submit button) but state is a local `enum _VerifyStatus` (L21) and the
    submit button only does `setState(...)` (L100).
  - **No code in the app calls `/me/verification` today.**
- Route `/verification` already registered: `sportx_app/lib/core/router.dart:341`.
- Entry point exists: profile-completion "Verification Document" row
  (`profile_completion_screen.dart:348-349`). Missing from More screen —
  should be added as a `MoreRow` for every role (see §3.4).
- Badge display code already exists and is only waiting for data:
  `profile_screen.dart:296`, `more_screen.dart:153-162`, `sportx_cards.dart:259`,
  `home_kit.dart:1144 (_VerifiedDot)`, `view_profile_screen.dart:475`,
  `talent_scout_athlete_profile_view_screen.dart:242`.

### 1.3 Admin (Flutter) — NOTHING ✘

- `admin_provider.dart` has no methods for `/admin/verification` (endpoints
  L537-540 on the API are consumed only by tests).
- `user_detail_verify_screen.dart` + "Verify" button in
  `manage_users_screen.dart:87-98` call `POST /admin/users/{id}/approve`
  which approves the *account/email* — it never touches
  `verification_requests` and never sets a badge.
- Server Blade panel (`/panel`) has no queue view either; only a dashboard
  count (`AdminDashboardController.php:38`) and a cosmetic toast button in
  `resources/views/admin/user-detail.blade.php:97`.

### 1.4 Data gap — `/me/profile` never says "verified"

`ProfileController::show` (`sportx-api/app/Http/Controllers/ProfileController.php:11-40`)
does not return `is_verified`, so `profile_screen.dart:92`
(`data['is_verified'] == true`) is always false and the badge never renders.

---

## 2. Design (how the feature will work)

```
[User]                [Backend]                         [Admin]
 opens /verification  (screens per role)  POST /me/verification
     ── upload docs (POST /media) ─────────────►──────────────┐
     ◄───────────── { status: pending } ────────┘             │
                                                              ▼
                                          Flutter admin queue screen
                                          GET /admin/verification
                                          (open drawer → docs preview)
                                          PATCH /{id}/approve ───────► badge=true + notification
                                          PATCH /{id}/reject ────────► badge=false + notification
     ◄──────── in-app notification + badge shown next to name ───┘
```

Rules already encoded in the backend (keep, don't duplicate):
- one live request per profile; resubmitting while pending reuses the row;
- badge decision is authoritative in `verification_requests` (approve→badge
  column true, reject→false);
- reject **requires** a `decision_reason` (max 1000 chars) which reaches the
  user in the notification.

---

## 3. Implementation steps — User app (`sportx_app`)

### 3.1 Provider `verification_provider.dart`

New file: `lib/features/auth/presentation/providers/verification_provider.dart`
(follow the pattern of `scout_shortlist_provider.dart`):

```dart
enum VerificationStatus { none, pending, verified, rejected }

class VerificationState {
  final VerificationStatus status;
  final List<ProofDoc> docs;          // media_items ids
  final String? decisionReason;
  final String? submittedAt;          // request created_at
  final bool submitting;
  ...
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  Future<void> load() async {
    // GET /me/verification -> latest request
    // status mapping: pending->pending, approved->verified, rejected->rejected
  }

  Future<bool> submit({required List<int> proofMediaIds, String? notes}) async {
    // POST /me/verification {verifiable_type, verifiable_id, notes, proof_media_ids}
    // 403 => "only your own profile"; 422 duplicate => reload() to adopt row
  }
}

final verificationProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>(...);
```

Resolving `verifiable_type` / `verifiable_id` per role — add a small helper in
`lib/core/role_config.dart` or the provider, using the profile id already
fetched by profile screens (`/me/profile` response `profile.id`):

| Flutter role (`SportXRole`) | `verifiable_type` |
|---|---|
| athlete | `athlete_profile` |
| coach | `coach_profile` |
| academy | `academy` |
| organizer | `organizer_profile` |
| scout | `talent_scout_profile` |
| sponsor | `sponsor_profile` *(first add to `VERIFIABLE_TYPES` — see §5.2)* |

### 3.2 Wire `verification_screen.dart` to the provider

Replace the local `_VerifyStatus` flow (L9-100):

1. `initState` → `Future.microtask(ref.read(verificationProvider.notifier).load())`.
2. Status card renders from `state.status` (reuse existing 4 states);
   when `rejected`, show `state.decisionReason` under "Couldn't verify"
   so users know why.
3. `MediaUploadTile` → on success store the returned `media_item` id in
   provider-state (the tiles already upload via `POST /media` — keep, but the
   upload must target `owner_type`-agnostic `context: 'credential'` /
   gallery as the media quota model allows).
4. Submit button → `state.submitting ? null : () => notifier.submit(...)`,
   disabled until at least 1 doc uploaded; success snackbar
   "Submitted — review usually takes 24-48 h", then status flips to pending.

### 3.3 Entry points (all roles)

- `more_screen` (role-driven `role_config.dart`): add to the **Trust & Safety /
  Account** group for every non-admin role:

  ```dart
  MoreRow(
    label: 'Verification badge',
    icon: LucideIcons.badgeCheck,
    route: '/verification',
    trailing: user?.isVerified == true ? _verifiedDot : null,
  )
  ```

- After a decision the `account_action` notification already deep-links to
  `/profile` — pointing it at `/verification` instead is a one-line backend
  change (`VerificationController.php` L156 / L181, optional).
- Settings/profile screen chevron: "Get the blue check" row when
  `!isVerified` and no pending request.

### 3.4 Show the badge once approved

Nothing to build — the widgets exist. Only make sure each surface is fed
`is_verified`:

| Surface | Already reads | Feeding data |
|---|---|---|
| Athlete profile header | `profile_screen.dart:92` from `/me/profile` | §5.1 backend one-liner |
| More screen header | `user?.isVerified` | already OK (login/home payloads) |
| Public profiles | `view_profile_screen.dart:475` | surface source must include `is_verified` (user detail / discovery payloads) |
| Coach/Academy/Organizer/Sponsor view screens | `verification_badge` / `verification_status` on the entity | already OK via entity detail endpoints |
| Shorts of names in rows | `home_kit.dart:_VerifiedDot` | already OK |

---

## 4. Implementation steps — Admin app (Flutter)

### 4.1 Provider methods (`admin_provider.dart`)

```dart
// inside AdminNotifier
Future<void> loadVerificationQueue() async {
  final resp = await _dio.get('/admin/verification');   // paginated 20
  state = state.copyWith(verificationQueue: items);
}

Future<bool> reviewVerification(int requestId, {required bool approve, String? reason}) async {
  await _dio.patch(
    '/admin/verification/$requestId/${approve ? 'approve' : 'reject'}',
    data: approve ? {} : {'reason': reason},              // reason REQUIRED on reject
  );
  // remove from queue list
}
```

### 4.2 Queue screen

New `lib/features/admin/presentation/screens/verification_queue_screen.dart`:

- Route in `core/router.dart` under the admin group: `/admin/verification`,
  opened from the existing **Approvals** row (admin More already links
  `/admin/approvals`, `role_config.dart:412,425`) — either merge both queues
  into tabs ("User accounts" | "Verification badges") or link a new row
  `MoreRow(label: 'Badge queue', icon: badgeCheck, route: '/admin/verification')`.
- List tile per request:
  - requester name, role label, verifiable type/id, request date, status chip;
  - tap → detail view listing `proof_media_ids` resolved via
    `MediaUtils.resolveUrl('/storage/<media url>')`
    (same pattern as `user_detail_verify_screen.dart:210-279` doc viewer)
    + `notes`.
- Actions: **Approve** (success toast + remove row) and **Reject** (dialog
  mandating a reason — server rejects `PATCH` without `reason` with 422).

### 4.3 Fix the misleading "Verify" in manage_users

`manage_users_screen.dart:87-98` "Verify" + `user_detail_verify_screen`
`Approve/Reject` currently approve email/account. Relabel to
**"Approve account"** so admins don't confuse it with the badge, and surface
`user.isVerified` (already in `AdminUser`) as a separate badge column with a
"Badge queue" link.

---

## 5. Backend touch-ups (small, low risk)

1. **`/me/profile` must include `is_verified`** — `ProfileController::show`:
   add `'is_verified' => $user->isVerified(),` alongside the resource array
   (`User::isVerified()` already exists, `User.php:98-103`) — without this
   the profile badge never appears.

2. **Allow sponsor requests** — `VerificationController::VERIFIABLE_TYPES`
   (L27-33) add `'sponsor_profile'`; the model already knows its badge column
   (`BADGE_COLUMNS` covers it). Also include `sponsor_profile`
   in `relationName()` (L191-200).

3. *(Optional)* point decision notifications to `/verification` instead of
   `/profile` so the user lands on the status card.

> No new migrations needed. No scheduled job required in scope — decisions are
> synchronous.

---

## 6. Ship order & checklist

| # | Task | Where |
|---|---|---|
| 1 | `/me/profile` returns `is_verified` + allow `sponsor_profile` type | backend, §5 |
| 2 | `verificationProvider` (load/submit) | Flutter user, §3.1 |
| 3 | Re-wire `verification_screen.dart` to provider (docs → ids → submit) | §3.2 |
| 4 | More-screen entry row per role + profile-screen CTA | §3.3 |
| 5 | Admin `loadVerificationQueue` / `reviewVerification` | §4.1 |
| 6 | Admin badge-queue screen + router under admin tabs | §4.2 |
| 7 | Rename account "Verify" → "Approve account", add badge info column | §4.3 |
| 8 | Feature test pass (`php artisan test --filter=VerificationRequestTest`) + Flutter smoke for all 6 roles | |
| 9 | Admin smoke: request as athlete → approve → badge on profile + notification; request as organizer → reject with reason → reason visible on user status card | |

Acceptance criteria:
- Every non-admin role can reach `/verification` from More, upload proof, submit,
  and see `pending → verified/rejected` with the decision reason.
- Approved users show the `badgeCheck` icon next to their name everywhere names show.
- Admin can browse the pending queue, view submitted documents, approve, and
  reject with a mandatory reason; the queue drains and the user gets notified.
