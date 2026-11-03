# 00 — Executive Summary

**Audit date:** 2026-11-03 · **Scope:** full codebase, read-only · **Method:** 7 end-to-end module traces (UI → state → API → validation/auth → DB → response → UI) + security sweep + runnable checks. Evidence with file:line in `_drafts/` and reports 01–08. All 94 P0 features and all P0 screens were assessed; wireframe fidelity was sampled, not pixel-audited.

## Completion

| Measure | Result |
|---|---|
| **P0 features DONE** | **35 / 69 = 51%** (31 PARTIAL, 1 BROKEN, 2 NOT STARTED) |
| P1 features DONE | 3 / 27 = 11% |
| P0 screens built & on real data | ~78 / 94 ≈ 83% (8 mock/UI-only; rest partial with named defects) |
| §6 business rules enforced server-side | 5 of 10 (4 violated, 1 partial — the violated ones are chat, capacity, leaderboard integrity, moderation) |
| User flows (12) | 1 PASS-with-defects cluster: onboarding, admin, scholarship pass; **7 of 12 FAIL** on a P0 step |
| Flutter | analyze 0 errors; tests 90 pass / 1 fail; no CI anywhere |
| Backend tests | UNVERIFIED — PHP not installed on audit machine; suite exists |

## Verdict: **NO-GO**

Not for lack of screens — the app looks built. It's NO-GO because the platform's trust-and-safety promises are not enforced where it matters (server), secrets are exposed, and five of the six "rules the build depends on" that failing tests would catch are violated in production code paths. Estimated 3–4 dev-weeks of largely mechanical work (07_FIX_PLAN Waves 1–3) to reach GO WITH CONDITIONS.

**Five reasons that drive the verdict:**
1. **Secrets committed to git** — release signing keystore, live APP_KEY, DB root password, and the seeded admin TOTP secret (`my-release-key.jks`, `CREDENTIALS.md`, `AdminProfileSeeder.php:19`).
2. **Child-safety gaps** — minors' "guardian review" notifications go to the minor (no guardian account exists); minors can loosen their own guardian controls; `who_can_connect` unenforced; minors' emails/phones leak through discovery; contact PII + certificates on the public web root.
3. **Safety actions unreachable or broken** — no block button anywhere in the app; report only on 4 listing screens (not posts/profiles); moderation "remove" on posts throws 500 leaving reported content live; blocked users still visible in search.
4. **Core P0 rules unenforced** — event/trial capacity never checked (unlimited registrations); cold DMs allowed by default for adults; leaderboard points uncapped and self-declared ("verified only" filter is dead code).
5. **Auth weaknesses** — login OTP bypassable with a client flag; suspended/pending users keep full API access (no status middleware, tokens never expire); admin API login unthrottled.

## Top 10 critical risks

| # | Risk | Evidence |
|---|---|---|
| 1 | Anyone with repo access can sign malicious app updates | `my-release-key.jks` tracked |
| 2 | Admin 2FA compromised by committed seed secret + unthrottled verify | `AdminProfileSeeder.php:19`, `routes/api.php:640-645` |
| 3 | Suspended/stalked users cannot actually be cut off (tokens live forever, no status check) | `config/sanctum.php:53`, no middleware |
| 4 | Minors reachable by strangers: cold DM (minors gated, but connections aren't), scout contact "routed" to the minor, contact PII leaked | `ConversationController.php:318`, `AthleteContactController.php:39-49`, `AthleteDiscoveryController.php:132` |
| 5 | ID documents & children's certificates downloadable by URL | `MediaController.php:266` (public disk) |
| 6 | Reported/abusive UGC stays live (moderation remove 500s; report/block unreachable) | `AdminModerationController.php:141`, zero block callers |
| 7 | Event capacity fiction — organizers promise 50 slots, unlimited register; fairness + refund-offline exposure | `RegistrationController.php:21-94` |
| 8 | App-store rejection: account deletion fails for Google users; UGC reporting/blocking invisible; no crash reporting (M12.6 not started) | `SettingsController::destroy`, `pubspec.yaml:36` |
| 9 | Release builds point at a dev ngrok tunnel; iOS media permissions missing (crash on first use); no CI to catch any of it | `.env`, `Info.plist`, no `.github/` |
| 10 | Leaderboard integrity gameable in seconds (+50 pts per fabricated achievement) — destroys the trust layer the MVP depends on | `LeaderboardService.php:81-90` |

## What is genuinely good (evidence-backed)
IDOR sweep of ~22 endpoint families found no missing ownership checks · OTP pipeline is production-grade (bcrypt, expiry, attempts, caps, anti-enumeration) · one-role-per-account enforced · verification/blue-check admin-only end-to-end · auto-expiry job real and idempotent · media validation content-sniffed with quotas · push pipeline handles all three app states with deep links · Flutter API client + error mapping is the best code in the repo · zero TODO/FIXME debt · duplicate registration unique-protected.

## Fastest path to MVP READY (details in 07_FIX_PLAN)
Wave 1 (security/secrets, ~1 week): rotate+purge secrets → status middleware → remove OTP bypass → capacity in a transaction → private disk for documents.
Wave 2 (child safety & trust, ~1 week): real guardian mediation → lock guardian controls → enforce chat/connection rules → block+report reachable everywhere → leaderboard verified-only.
Wave 3 (flow breakers, ~1–2 weeks): enquiry & registration notifications with routed deep links → consent capture → forgot-password fix → Google-account deletion → bulk approvals → analytics instrumentation.
Then: backend test run + CI, production env/flavors, iOS permissions, and a re-audit of Waves 1–2.

**Definition check (MVP READY):** currently 0/5 criteria met (P0 DONE 51%, 7 BLOCKER-class items open, HIGHs open in auth/minors/chat/registration/moderation, 7 flows fail, no CI/test coverage of P0). With Waves 1–3 executed, GO WITH CONDITIONS is realistic within a month of focused work.
