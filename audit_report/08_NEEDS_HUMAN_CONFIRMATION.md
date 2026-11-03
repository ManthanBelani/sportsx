# 08 — Needs Human Confirmation

Things that cannot be verified from the repository. Each item states what to check and why it matters.

## Infrastructure & environment
1. **Production environment existence.** The repo contains only a dev setup: APP_URL = `https://movable-washstand-ungraded.ngrok-free.dev` (ngrok tunnel), APP_ENV=local, APP_DEBUG=true, MySQL `sportx_dev` on 127.0.0.1. Is there a real production server/domain (`api.sportx.in` per .env.example comments, `sportx.in` used in share links)? Determines F-25 and whether the committed tunnel URLs have ever carried real user traffic.
2. **Whether the committed secrets were ever deployed.** `CREDENTIALS.md` APP_KEY/DB password and `TEST_CREDENTIALS.md` — if the same APP_KEY runs anywhere public, rotation is urgent beyond git hygiene.
3. **Database backups.** Nothing in the repo configures backups. Confirm whether the hosting layer takes snapshots.
4. **Deployment process.** No CI/CD files exist. How is the API deployed (manual FTP? a runbook outside the repo — `SERVER-SETUP.md` and `PHP2SHELL-PATCH-RUNBOOK.md` suggest manual patching)?
5. **Whether `php artisan test` passes.** The PHPUnit suite exists but PHP is not installed on the audit machine — backend test status and live IDOR probing are UNVERIFIED. Run: `php artisan test`, then probe `/api/v1/athletes/{id}` etc. cross-account.
6. **Queue workers in production.** Horizon is installed but not mounted; composer dev uses `queue:listen`. What actually runs the queue + scheduler (`schedule:run` cron) in the real environment? Expiry, reminders, leaderboard rebuild depend on it.

## Third-party consoles
7. **FCM project status.** `FCM_SERVER_KEY` empty in committed docs; Firebase options are compiled in (`firebase_options.dart`). Confirm the Firebase project is real, APNs keys uploaded for iOS, and which package/sender the app ships with.
8. **Google Sign-In configuration.** iOS URL scheme is a `CHANGE_ME_REVERSED_CLIENT_ID` placeholder → iOS Google sign-in cannot work as shipped. Confirm Android client ID `241021895160-...` is the intended production OAuth client and backend `GOOGLE_CLIENT_ID` matches.
9. **Email/OTP delivery provider.** MAIL_PASSWORD null; there's an email-provider probing system (`mail:probe`, EmailSettingsController). Which provider is live in production, and is SMS ever planned (phone OTP is currently impossible — OtpService throws for non-email)? The product is marketed as phone-first.
10. **Sentry (or other crash reporting) account.** Sentry disabled in env and removed from the app; is there a DSN to wire?

## Product / legal decisions
11. **`sportx.in` web presence.** All share links point at `https://sportx.in/profile/{id}` etc., which nothing serves. Will a web app exist at launch, or should share links deep-link into the app (requires app-links + assetlinks.json)?
12. **Release signing custody.** After F-01 rotation: who holds the new keystore, and is Play App Signing (Google-held key) enabled?
13. **Play Store / App Store accounts & privacy questionnaire readiness.** Account deletion exists in-app (with the Google-account bug, F-20); UGC report/block must ship (F-12) before review. Data-safety form will need the PII-leak fixes (F-15) to be truthful.
14. **DPDP compliance sign-off.** Guardian consent flow exists but has no stored consent artifact (timestamp/IP/version). Legal sign-off needed on whether current capture meets your bar; also confirm the 90-day chat purge and hard-delete behaviour match the published `PRIVACY_POLICY.md`.
15. **Near-me (M3.8) descope decision.** Zero geo infrastructure exists. Either fund the build (F-32, L) or formally remove "distance/near me" from P0 marketing claims — academy cards promise "km" in the spec.
16. **Sponsor role residue.** `role:sponsor` middleware, `/onboarding/sponsor`, `SponsorProfile` model still exist (endpoints 410 where relevant). Confirm intent to keep the code path or remove it.
17. **P2 groups scope.** Groups are fully built (routes, tables, screens) despite being P2 while P0 items are missing. Confirm whether to keep shipping/maintaining them.
18. **`ADMIN_2FA_ENFORCE` in production.** Only pinned `true` in `.env.example`; if the real .env has it false, admin 2FA accepts any 6-digit code. Verify the production value.

## Runtime behaviour not executable here
19. **FCM deep-link tap behaviour on real devices** (cold/warm/terminated) — code path verified; device behaviour not (no device/emulator run in this audit).
20. **Actual email deliverability of OTP/reset/guardian mails** — code + probes exist; no live send was performed (read-only audit, dev env).
21. **iOS build viability** — Info.plist has placeholder scheme + missing camera/photo usage strings (crash on first media pick). No macOS toolchain here to build; treat iOS as NOT launch-ready until F-25-class fixes + a build are done.
