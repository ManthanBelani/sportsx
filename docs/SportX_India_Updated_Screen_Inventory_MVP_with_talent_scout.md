# SportX India
## Updated Flutter Screen Inventory (MVP)

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.
>
> **⚠️ [SUPERSEDED — see Backend-Feature-Delta.md and `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md`].** This document is the **old** inventory (44 screens, 6 numbered roles including *Sponsor / Brand*, no verified scout pipeline). The new canonical inventory is `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md` (**129 screens, 6 roles: Athlete/Parent, Coach, Academy, Organizer, Talent Scout, Admin**) with ID prefixes `A`/`S`/`D`/`AT`/`CO`/`AC`/`OR`/`SC`/`AD`. Kept for history; use the new inventory for screen IDs.

---

## 0. Shared / Common (All Roles)

> **[SUPERSEDED]** — the new design replaces these with `S.1–S.30` shared-shell screens plus `A.1–A.10` auth screens (OTP auth + guardian consent + verification request). See §8 mapping.

| # | Screen | Purpose | Key Elements | Navigates To |
|---|--------|---------|---------------|---------------|
| 0.1 | Splash Screen | App load, auth check, route to onboarding or home. | Logo, loader. | Onboarding or role-based Home |
| 0.2 | Role Selection | First-time user selects their role. | **[SUPERSEDED]** New `A.2`: 5 selectable role cards (Athlete/Parent, Coach, Academy, Organizer, Talent Scout) — *Sponsor removed*; Admin is internal. | Sign Up (0.3) |
| 0.3 | Sign Up | Phone/email registration. | Phone/email, OTP or password, T&C checkbox. | OTP Verification (0.4) |
| 0.4 | OTP Verification | Verify phone/email. | OTP input, resend timer. | Role onboarding |
| 0.5 | Login | Returning-user login. | Phone/email, password/OTP toggle. | Role-based Home |
| 0.6 | Universal Search | Cross-entity search. | Search academies, coaches, trials and athletes where permitted. | Relevant detail screen |
| 0.7 | Global Filter Sheet | Reusable filters. | Sport, age, location, price, date and relevant athlete criteria. | Filtered results |
| 0.8 | Notifications | Deadline/date and platform notification feed. | Notification cards, read/unread state. | Relevant detail |
| 0.9 | Report Listing / User | Report fake, stale, suspicious or inappropriate activity. | Reason dropdown, notes, submit. | Confirmation → back |
| 0.10 | Settings / Account | Account settings and logout. | Profile settings, language, notifications. | Login on logout |

---

## 1. Athlete / Parent

| # | Screen | Purpose | Key Elements | Navigates To |
|---|--------|---------|---------------|---------------|
| 1.1 | Onboarding — Preferences | Capture sport(s), age group, skill level and city. | Sport chips, age dropdown, city picker. | Home (1.2) |
| 1.2 | Home / Dashboard | Main entry point. | Nearby academies, trending trials, quick-access tiles. | Directories, trials, scholarships, athlete discovery |
| 1.3 | My Profile | View digital profile. | Avatar, bio, sports, achievements. | Edit Profile (1.4) |
| 1.4 | Edit Profile | Edit basic info, sports and achievements. | Form fields, save. | Media Gallery (1.5) |
| 1.5 | Media Gallery | Upload/view photos and videos. | Gallery grid, upload. | Back to Profile |
| 1.6 | Academy Directory | Browse academies. | Academy cards, search/filter. | Academy Detail |
| 1.7 | Academy Detail | View full academy information. | Sports, location, fees, facilities, coaches, timings. | Enquiry / Report |
| 1.8 | Coach Directory | Browse coaches. | Coach cards, search/filter. | Coach Detail |
| 1.9 | Coach Detail | View full coach information. | Qualifications, experience, location, fees. | Enquiry / Report |
| 1.10 | Trial Listings | Browse trials. | Trial cards, search/filter. | Trial Detail |
| 1.11 | Trial Detail | View full trial information. | Organizer, eligibility, fee, documents, register CTA. | Trial Registration |
| 1.12 | Trial Registration Form | Register for a trial. | Personal details, document upload, submit. | Registration Confirmation |
| 1.13 | Enquiry / Contact Form | Send enquiry to coach or academy. | Message box, submit. | Confirmation |
| 1.14 | Tournament Calendar | Browse tournaments. | Calendar/list toggle. | Tournament Detail |
| 1.15 | Tournament Detail | View tournament information. | Format, dates, venue, prize pool, register CTA. | Tournament Registration |
| 1.16 | Tournament Registration Form | Register for tournament. | Team/individual details, category, submit. | Registration Confirmation |
| 1.17 | Scholarship Feed | Browse scholarships/schemes. | Provider, sport, amount, deadline. | Scholarship Detail |
| 1.18 | Scholarship Detail | View scholarship information. | Eligibility, amount, deadline, apply info. | Back |
| 1.19 | Sponsorship Opportunities | Browse sponsorship listings. | Brand, sport, benefits. | Sponsorship Detail |
| 1.20 | Sponsorship Detail | View sponsorship opportunity. | Eligibility, benefits, apply CTA. | Pitch Submission |
| 1.21 | Pitch Submission Form | Submit profile and pitch. | Pitch text, attach profile, submit. | Confirmation |
| 1.22 | Registration Confirmation | Success screen for registrations. | Success summary, view registrations CTA. | Home |
| 1.23 | Athlete Discovery | Discover other athletes. | Athlete cards; sport, location, age group and shared interests. | Athlete Profile View (1.24), Filter |
| 1.24 | Athlete Profile View | View another athlete's public profile. | Profile, sports, achievements, media, connect CTA. | Connection Request / Chat |
| 1.25 | Connection Requests | Manage incoming/outgoing requests. | Accept, decline, cancel, remove connection. | Athlete Chat |
| 1.26 | Athlete Chat Inbox | View athlete conversations. | Conversation list, unread indicators. | Athlete Chat Thread |
| 1.27 | Athlete Chat Thread | 1-to-1 chat with an accepted connection. | Message thread, text input, report/block actions. | Back to Inbox |
| 1.28 | Blocked / Safety Action | Confirm/manage block or report action. | Reason selection, block confirmation. | Back / Admin review |

---

## 2. Coach

| # | Screen | Purpose | Key Elements | Navigates To |
|---|--------|---------|---------------|---------------|
| 2.1 | Onboarding — Coach Profile Setup | Capture certifications, experience, sports, fees and location. | Multi-step form. | Coach Home |
| 2.2 | Coach Home / Dashboard | Entry point for enquiries and profile. | Summary tiles, recent enquiries. | Profile, Inbox, Browse |
| 2.3 | Coach Profile (Own) | View own listing. | Certifications, experience, sports, fees, location. | Edit Profile |
| 2.3a | Edit Coach Profile | Edit coach details. | Form fields, save. | Back to Profile |
| 2.4 | Enquiry Inbox | List booking/enquiry requests. | Conversation cards, unread state. | Enquiry Thread |
| 2.5 | Enquiry Thread | View/respond to enquiry. | Message thread, reply box. | Back to Inbox |

*Coach reuses relevant shared browse screens for academies, coaches, trials and search.*

---

## 3. Academy

| # | Screen | Purpose | Key Elements | Navigates To |
|---|--------|---------|---------------|---------------|
| 3.1 | Onboarding — Academy Setup | Capture sports, facilities, location, fees and photos. | Multi-step form, image upload. | Academy Home |
| 3.2 | Academy Home / Dashboard | Entry point for trials, enquiries and registrants. | Summary tiles. | Listing, Trial Management, Inbox |
| 3.3 | Own Listing | View academy public listing. | Sports, facilities, location, fees, photos. | Edit Listing |
| 3.3a | Edit Listing | Edit academy listing. | Form fields, save. | Back to Listing |
| 3.4 | Trial Management | Manage academy trials. | Trial cards, status. | Create/Edit, Registrants |
| 3.5 | Create / Edit Trial | Create or edit trial. | Name, sport, date, venue, eligibility, fee, documents. | Back to Trial Management |
| 3.6 | Registrant List | View trial registrants. | Registrant cards, contact info. | Registrant Detail |
| 3.7 | Registrant Detail | View full submission. | Personal details, uploaded documents. | Back |

---

## 4. Organizer (Trial / Tournament)

| # | Screen | Purpose | Key Elements | Navigates To |
|---|--------|---------|---------------|---------------|
| 4.1 | Organizer Home / Dashboard | Trial and tournament summary. | Active trials, tournaments, registrants. | Trial/Tournament Management |
| 4.2 | Tournament Management | Manage tournaments. | Tournament cards, status. | Create/Edit, Registrants |
| 4.3 | Create / Edit Tournament | Create or edit tournament. | Format, dates, venue, fees, prize pool, categories. | Back |
| 4.4 | Tournament Registrant List | View/export registrants and manage capacity. | Registrant list, capacity indicator, export. | Registrant Detail |
| 4.5 | Results Publishing | Publish brackets/final results. | Result entry/upload, publish. | Back |

---

## 5. Talent Scout

| # | Screen | Purpose | Key Elements | Navigates To |
|---|--------|---------|---------------|---------------|
| 5.1 | Onboarding — Scout Profile Setup | Capture scout identity and professional details. | Organization/affiliation, sports specialization, experience, location. | Scout Home (5.2) |
| 5.2 | Talent Scout Home / Dashboard | Entry point for athlete discovery and shortlists. | Search shortcut, saved athletes, activity summary. | Athlete Discovery, Shortlist |
| 5.3 | Athlete Discovery — Search | Browse/search athlete profiles. | Filterable athlete cards by sport, age group, location, skill level and achievements. | Athlete Profile View |
| 5.4 | Athlete Profile View | Review a discovered athlete's public profile. | Sports history, achievements, media, shortlist and connect CTA. | Shortlist / Connection Request |
| 5.5 | Shortlist | View saved promising athletes. | Shortlisted athlete cards, remove option. | Athlete Profile View |
| 5.6 | Connection / Enquiry | Contact athlete or parent through the platform. | Connection/enquiry form and status. | Confirmation / Back |

---

## 6. Sponsor / Brand

> **[SUPERSEDED — see Backend-Feature-Delta.md].** The `sponsor` role is **REMOVED** (delta §0 D2 / §4). Sponsorship is now an **Opportunity type** posted by Academy/Organizer/Coach/Scout (Athlete P1) and browsed by all — see new screens `D.9`/`D.10` (opportunity detail/apply), `AT.8` (My Opportunities), `AC.9`/`SC.11`/`SC.12` (provider posting). The sponsor screens below are retained for history only; their backend (`sponsor_profiles`, `sponsorships`, sponsor onboarding) is dropped/migrated (`Database-Design.md` §16).

| # | Screen | Purpose | Key Elements | Navigates To |
|---|--------|---------|---------------|---------------|
| 6.1 | Onboarding — Sponsor Setup | Capture brand info and sport focus. | Form fields, logo upload. | Sponsor Home |
| 6.2 | Sponsor Home / Dashboard | Entry point for listings and applications. | Summary tiles. | Listings, Athlete Discovery, Applications |
| 6.3 | Sponsorship Listings | Manage sponsorship opportunities. | Listing cards, status. | Create/Edit |
| 6.4 | Create / Edit Sponsorship | Create/edit sponsorship listing. | Sport, eligibility, benefits, publish. | Back |
| 6.5 | Athlete Discovery — Search | Browse/search athletes. | Filterable athlete grid. | Athlete Profile View |
| 6.6 | Athlete Profile View | View athlete public profile. | Profile summary, shortlist CTA. | Shortlist |
| 6.7 | Applications Inbox | Review pitches/applications. | Applicant cards. | Application Detail |
| 6.7a | Application Detail | View pitch and applicant summary. | Pitch, profile, actions. | Back |
| 6.8 | Shortlist | View saved athletes. | Shortlisted athlete cards. | Athlete Profile |

---

## 7. Admin (Internal Dashboard)

| # | Screen | Purpose | Key Elements | Navigates To |
|---|--------|---------|---------------|---------------|
| 7.1 | Admin Login | Internal team login. | Email/password, 2FA if applicable. | Admin Home |
| 7.2 | Admin Home / Dashboard | View platform activity and reports. | Summary tiles, recent activity. | Content, Moderation, Categories |
| 7.3 | Content Manager | Manage platform records. | Filterable data table. | Record Edit |
| 7.3a | Record Edit | Add/edit/delete records. | Full record form. | Back |
| 7.4 | Moderation Queue | Review reported listings and users. | Reports, reasons, linked content/user preview. | Moderation Detail |
| 7.4a | Moderation Detail | Take moderation action. | Approve, reject, remove, warn or block as applicable. | Back |
| 7.5 | Category Manager | Manage sports, cities and age categories. | Editable master lists. | Back |
| 7.6 | Expiry Rules | Configure automatic expiry. | Rule list, add/edit form. | Back |

---

## Updated Screen Count Summary

> **[SUPERSEDED]** The table below is the old count (**44 named screens, incl. Sponsor**). The new canonical inventory (`sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md` §11) counts **129 screens** across 6 roles.

| Role | Primary Screens (OLD — superseded) |
|------|------------------|
| Shared / Common | 10 |
| Athlete / Parent | 28 |
| Coach | 6 (+ shared browse screens reused) |
| Academy | 7 (+ shared enquiry screens) |
| Organizer | 5 (+ shared trial management) |
| Talent Scout | 6 (+ shared athlete/search/filter screens) |
| Sponsor / Brand | 9 — **[REMOVED]** |
| Admin | 8 |

**New counts (v3 / `SCREEN_INVENTORY.md` §11):** Auth & Onboarding 10 · Shared shell 30 · Shared detail & forms 17 · Athlete/Parent 10 · Coach 8 · Academy 12 · Organizer 17 · Talent Scout 13 · Admin 12 → **Total 129 (94 P0 / 25 P1 / 10 P2)**.

**Note:** Athlete-to-athlete chat remains limited to accepted connections, **but** the MVP **now includes** a lightweight public social feed, posts, likes/comments, follow/connect and 1-to-1 chat (new `S.9`/`S.27`/`S.12`/`S.17`/`S.18`/`S.19`). Stories, group chat and cold DMs stay out. This old note is **[SUPERSEDED]**.

---

## 8. Mapping — old IDs → new v3 screen IDs

> Source of new IDs: `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md`. Use the new IDs everywhere.

| Old (this doc) | New v3 ID(s) | Notes |
|---|---|---|
| 0.1 Splash | `A.1` | — |
| 0.2 Role Selection | `A.2` | Sponsor card removed |
| 0.3 Sign Up | `A.3` | OTP + phone/email + Google (D9) |
| 0.4 OTP Verification | `A.4` | Now **P0** (delta D1) |
| 0.5 Login | `A.5` | Keep password; add OTP branch |
| — | `A.6` Forgot/Reset (OTP) | P1 |
| — | `A.7` Language · `A.8` Permissions | P1 |
| — | `A.9` Guardian Consent · `AT.10` Parent Controls | **NEW** P0 (minors) |
| — | `A.10` Verification Request · `AD.4` Verification Queue | **NEW** P0 |
| 0.6 Universal Search | `S.5` | — |
| 0.7 Global Filter Sheet | `S.4` | — |
| 0.8 Notifications | `S.16` | + role tabs |
| 0.9 Report Listing/User | `S.26` | + report users/posts |
| 0.10 Settings/Account | `S.15` More · `S.22` Settings/Privacy | + safety centre `S.23` |
| 1.x Athlete directory/detail | `S.2`/`S.3`/`S.4` + `D.1`–`D.13` | Grouped discovery + detail forms |
| 1.14–1.16 Tournaments | `D.6`–`D.8`/`AT.9` | Unified event detail/registration |
| 1.17–1.21 Scholarships/Sponsorships | `D.9`/`D.10`/`AT.8`/`SC.11` | **Unified opportunities** |
| 1.23–1.28 Athlete discovery/chat | `S.12`–`S.14`/`S.17`–`S.19` | Feed/follow/connect/chat |
| 2.x Coach | `CO.1`–`CO.8` | + Programs (`CO.4`/`CO.5`) |
| 3.x Academy | `AC.1`–`AC.12` | + Facilities (`AC.7`/`AC.8`) |
| 4.x Organizer | `OR.1`–`OR.17` | + Opportunity/Venue/Announcement |
| 5.x Talent Scout | `SC.1`–`SC.13` | + shortlist pipeline/reports/observations |
| 6.x Sponsor | — | **[REMOVED]** → opportunities |
| 7.x Admin | `AD.1`–`AD.12` | + user mgmt/verification/leaderboard config |
