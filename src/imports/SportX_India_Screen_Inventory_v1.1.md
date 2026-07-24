# SportX India — Revised Flutter Screen Inventory (Granular)

**Document Type:** Screen Inventory & Navigation Reference (Revised)
**Platform:** Flutter Mobile Application (Android) — confirmed technology stack
**Version:** 1.1 — Revised MVP Screen Count
**Prepared For:** Client Review & Development Reference

---

## Note on This Revision

The first screen inventory (v1.0) grouped several distinct actions under single umbrella screens (e.g., "Edit Profile" covered achievements, tournaments, stats, and media all in one screen; "Manage Users" covered approvals, verification, and suspension in one screen). On closer read of the **User-Wise Functionality & Feature List**, many of these umbrella items actually require **their own dedicated screen** in a real Flutter build — separate upload forms, list views, detail views, confirmation screens, and compose forms.

This revised inventory breaks those out individually. **Total screen count has increased from 37 to 63.**

**Confirmed for build:** SportX India MVP will be developed as a native **Flutter** application (Android, MVP phase), with a separate web-based Admin Panel for full admin operations and a lightweight Admin screen set inside the Flutter app itself.

---

## Total Screen Count (Revised)

| Metric | Value |
|---|---|
| **Total Unique Screens (MVP)** | **63** |
| Total Groups | 6 |

### Screens by Group

| Group | v1.0 Count | v1.1 Revised Count |
|---|---|---|
| Auth (Authentication & Onboarding) | 5 | 7 |
| Athlete | 10 | 17 |
| Coach / Academy | 6 | 8 |
| Sponsor | 6 | 9 |
| Shared (All Roles) | 6 | 11 |
| Admin (Mobile — minimal) | 4 | 11 |
| **Total** | **37** | **63** |

---

## 1. Authentication & Onboarding — 7 Screens

| # | Screen | Derived From |
|---|---|---|
| 1 | Splash screen | App launch / session restore |
| 2 | Login screen | Phone/email + password entry |
| 3 | Signup screen | Name, phone/email, role selection |
| 4 | OTP verification screen | OTP entry step during signup/login |
| 5 | Role selection screen | Choose Athlete / Coach-Academy / Sponsor |
| 6 | Forgot password screen | Password-based login requires recovery flow |
| 7 | Reset password screen | Set new password after OTP/email verification |

---

## 2. Athlete Screens — 17 Screens

| # | Screen | Derived From (Feature List Section) |
|---|---|---|
| 1 | Athlete home / feed | 2.x general navigation hub |
| 2 | Create post screen | Post to feed |
| 3 | My profile screen | 2.1 Own Profile |
| 4 | Edit profile screen | 2.1 — edit name, bio, sport, location |
| 5 | Add achievement / certificate screen | 2.1 — "Upload achievements and certificates" |
| 6 | Add tournament participation entry screen | 2.1 — "Maintain tournament participation history" |
| 7 | Tournament history list screen | 2.1 — display of recorded tournaments |
| 8 | Edit performance statistics screen | 2.1 — "Enter/edit self-reported performance statistics" |
| 9 | Media gallery screen | 2.1 — highlight photos & videos gallery |
| 10 | Upload media screen | 2.1 — "Upload highlight photos/videos" |
| 11 | Edit social media links screen | 2.1 — "Add optional external social media links" |
| 12 | Discover / directory screen | 2.2 — browse athletes/academies/sponsors |
| 13 | My connections list screen | 2.3 — "View a personal list of all current connections" |
| 14 | Connection requests screen | 2.3 — "Accept or decline an incoming connection request" |
| 15 | Chat list screen | 2.3 — "View a list of all active chat threads" |
| 16 | Chat screen (1:1 conversation) | 2.3 — "Open an individual one-to-one conversation screen" |
| 17 | Academies & coaches directory screen (athlete view) | 2.4 — browse coaches/academies |

> Athlete-facing screens that are reused by other roles (view coach/sponsor profile, opportunities list/detail, apply form, notifications, search & filter) are listed once under **Section 5 — Shared Screens** to avoid double-counting.

---

## 3. Coach / Academy Screens — 8 Screens

| # | Screen | Derived From (Feature List Section) |
|---|---|---|
| 1 | Coach / academy home feed | General navigation hub |
| 2 | Coach / academy profile screen (own) | 3.1 Own Profile |
| 3 | Edit coach / academy profile screen | 3.1 — edit name, bio, sport, location |
| 4 | Add credentials / certifications screen | 3.1 — "Upload/display credentials and certifications" |
| 5 | Edit facilities & programs screen | 3.1 — "Enter/edit facilities & programs description" |
| 6 | Associated athletes showcase screen | 3.1 — "Optionally showcase associated athletes" |
| 7 | Athlete directory screen (coach view) | 3.2 — browse/search full athlete directory |
| 8 | Sponsor directory screen (coach view) | 3.3 — browse sponsor profiles/listings |

---

## 4. Sponsor Screens — 9 Screens

| # | Screen | Derived From (Feature List Section) |
|---|---|---|
| 1 | Sponsor home feed | General navigation hub |
| 2 | Sponsor profile screen (own) | 4.1 Own Profile |
| 3 | Edit sponsor profile screen | 4.1 — edit org name, description, industry, location |
| 4 | My active opportunities screen | 4.1 — "View list of their own active opportunities" |
| 5 | Past associations showcase screen | 4.1 — "Optionally showcase past associations" |
| 6 | Athlete directory screen (sponsor view) | 4.2 — browse/search/shortlist athletes |
| 7 | Academy directory screen (sponsor view) | 4.3 — browse/search academies & coaches |
| 8 | Post opportunity screen (create listing) | 4.4 — "Create a new sponsorship/opportunity listing" |
| 9 | Listing status screen | 4.4 — "View status of submitted listings (pending/approved/rejected)" |

---

## 5. Shared Screens (Used Across Multiple Roles) — 11 Screens

| # | Screen | Derived From (Feature List Section) |
|---|---|---|
| 1 | View profile screen (read-only) | 2.2 / 3.x / 4.x — viewing any athlete, coach, or sponsor profile |
| 2 | Post detail screen | Feed post + comments |
| 3 | Opportunities list screen | 2.5 / 3.3 / 4.x — browse active sponsorship listings |
| 4 | Opportunity detail screen | 2.5 / 3.3 — full listing detail with eligibility/deadline |
| 5 | Apply / express interest form screen | 2.5 — "Apply for a sponsorship/funding opportunity" |
| 6 | Application submitted confirmation screen | 2.5 — post-submission confirmation |
| 7 | Search & filter screen | 2.6 — sport/location/age/achievement filters |
| 8 | Notifications list screen | 2.7 / 3.4 / 4.5 — all received notifications |
| 9 | Notification detail screen | 2.7 — individual notification content |
| 10 | Settings screen | 5 — account, privacy, notification toggle |
| 11 | Media viewer screen | 5 — full-screen image/video player |

---

## 6. Admin Screens (Mobile — Minimal Footprint) — 11 Screens

Full administrative control lives on the web-based Admin Panel; the following represents the minimal but functionally complete admin screen set available on mobile.

| # | Screen | Derived From (Feature List Section) |
|---|---|---|
| 1 | Admin dashboard screen | 1.5 — user counts, activity overview |
| 2 | Platform reports screen | 1.5 — breakdown by role/region/sport |
| 3 | Manage users list screen | 1.1 — view all registered users |
| 4 | User detail / verify screen | 1.1 — verify profile, apply badge |
| 5 | Pending registrations / approvals screen | 1.1 — "Approve new user registrations" |
| 6 | Moderation queue screen | 1.2 — reported posts/content list |
| 7 | Report detail screen | 1.2 — "Review reported content in detail" |
| 8 | Compose notification screen | 1.3 — title, message body entry |
| 9 | Notification targeting screen | 1.3 — role / region / sport category filters |
| 10 | Opportunity approval queue screen | 1.4 — listings pending approval |
| 11 | Opportunity review detail screen | 1.4 — approve/reject a specific listing |

---

## 7. Consolidated Per-Role Screen Count (End-to-End Journey)

Includes Auth + role-specific + shared screens each role will actually pass through while using the app.

| Role | Auth | Role-Specific | Shared | Total Screens Encountered |
|---|---|---|---|---|
| Athlete | 7 | 17 | 11 | 35 |
| Coach / Academy | 7 | 8 | 11 | 26 |
| Sponsor | 7 | 9 | 11 | 27 |
| Admin | 7 | 11 | 11 (partial use) | 29 |

> Note: Auth (7) and Shared (11) screens are common across roles and are **not duplicated** in the overall MVP total — the 63-screen total reflects unique screens only, calculated as 7 + 17 + 8 + 9 + 11 + 11 = 63.

---

## 8. Build Confirmation

- **App to be built:** Yes — SportX India MVP mobile application
- **Technology stack:** **Flutter** (single codebase, Android target for MVP; iOS explicitly out of scope for this phase per the MVP feature description)
- **Backend:** Cloud-based, scalable (per MVP scope)
- **Admin Panel:** Separate web-based panel for full administrative control, complemented by the 11 minimal admin screens above inside the Flutter app

---

*This revised inventory is derived directly from the SportX India User-Wise Functionality & Feature List v1.0 and supersedes the original 37-screen count in the v1.0 Screen Inventory document. Intended for development planning, sprint estimation, and QA test-case mapping.*
