# SportX India — Detailed Wireframes

This document provides low-fidelity wireframes for every screen in the **Screen Inventory**, built on top of the **MVP Overview**. Wireframes are shown as mobile-first ASCII layouts (portrait, ~375px width equivalent).

**How to read this doc:** Several screens share the exact same layout template (e.g., every "Directory" screen — Academy, Coach, Trial, Tournament, Scholarship, Sponsorship — is a card list with a search bar and filters). Rather than repeat near-identical wireframes, each **template** is wireframed once in full detail, followed by a table showing how the fields swap per screen. Screens with a genuinely different layout (dashboards, forms, calendar view, moderation queue, etc.) get their own individual wireframe.

**Legend:**
- `[ Button ]` = tappable button
- `[Dropdown ▾]` = filter/select control
- `🔍` = search input
- `⚙` = settings/menu icon
- `←` = back navigation
- `●○○` = pagination/step dots
- `[Tab1|Tab2]` = tab switcher
- `▢` = checkbox / toggle
- Bottom row `[Icon] [Icon] [Icon] [Icon]` = persistent bottom navigation bar

---

## Part A — Shared / Cross-Role Screens

### S1 — Splash Screen
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│                                     │
│            🏆 SportX                │
│         India's Sports Network     │
│                                     │
│                                     │
│         ⏳ Loading...               │
│                                     │
└─────────────────────────────────────┘
```

### S2 — Role Selection
```
┌─────────────────────────────────────┐
│         Who are you joining as?     │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ 🏃 Athlete / Parent           │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🧑‍🏫 Coach                     │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🏫 Academy                    │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🏟 Organizer                  │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 💼 Sponsor / Brand            │  │
│  └───────────────────────────────┘  │
│                                     │
│      Already have an account?      │
│              Log in                │
└─────────────────────────────────────┘
```

### S3 — Sign Up
```
┌─────────────────────────────────────┐
│ ←            Sign Up                │
├─────────────────────────────────────┤
│   [ Phone Number | Email ]  ← toggle │
│   ┌───────────────────────────────┐  │
│   │ +91 ________________         │  │
│   └───────────────────────────────┘  │
│                                     │
│   ▢ I agree to Terms & Privacy      │
│                                     │
│   [        Continue        ]       │
│                                     │
│   ───────────  or  ───────────     │
│   [ Continue with Google ]         │
└─────────────────────────────────────┘
```

### S4 — OTP / Email Verification
```
┌─────────────────────────────────────┐
│ ←         Verify Number             │
├─────────────────────────────────────┤
│   Code sent to +91 98XXX XXXXX      │
│                                     │
│    [ 1 ][ 2 ][ 3 ][ 4 ][ 5 ][ 6 ]   │
│                                     │
│   Resend code in 00:28              │
│                                     │
│   [        Verify        ]         │
└─────────────────────────────────────┘
```

### S5 — Login
```
┌─────────────────────────────────────┐
│ ←              Log In                │
├─────────────────────────────────────┤
│   ┌───────────────────────────────┐  │
│   │ Phone / Email                 │  │
│   └───────────────────────────────┘  │
│   ┌───────────────────────────────┐  │
│   │ Password / OTP                │  │
│   └───────────────────────────────┘  │
│                                     │
│   [          Log In         ]      │
│                                     │
│   Forgot password?                  │
│   New here? Sign Up                 │
└─────────────────────────────────────┘
```

### S6 — Universal Search
```
┌─────────────────────────────────────┐
│ ←   🔍 Search academies, coaches... │
├─────────────────────────────────────┤
│  Recent Searches                    │
│  • Cricket academies Ahmedabad      │
│  • Football trials under-14         │
│                                     │
│  Trending                            │
│  [Cricket] [Football] [Athletics]   │
│  [Badminton] [Swimming]             │
├─────────────────────────────────────┤
│ [Home] [Search] [Saved] [Profile]   │
└─────────────────────────────────────┘
```

### S7 — Search Results (Unified)
```
┌─────────────────────────────────────┐
│ ←   🔍 "cricket ahmedabad"      ⚙   │
├─────────────────────────────────────┤
│ [Academies|Coaches|Trials|Tourn.|   │
│  Scholarships|Sponsorships]         │
│         (scrollable tab bar)        │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [img] Elite Cricket Academy     │ │
│ │ Cricket · Ahmedabad · ₹2000/mo  │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [img] Champions Cricket Club    │ │
│ │ Cricket · Ahmedabad · ₹1800/mo  │ │
│ └─────────────────────────────────┘ │
│           [ Load more ]             │
├─────────────────────────────────────┤
│ [Home] [Search] [Saved] [Profile]   │
└─────────────────────────────────────┘
```

### S8 — Filter Panel
```
┌─────────────────────────────────────┐
│ ←            Filters            Clear│
├─────────────────────────────────────┤
│ Sport                                │
│  [Cricket ✓] [Football] [Athletics] │
│                                     │
│ City / State                        │
│  [ Ahmedabad, Gujarat ▾ ]           │
│                                     │
│ Age Group                           │
│  [Under-12] [Under-14] [Open]      │
│                                     │
│ Price Range                         │
│  ₹0 ────●───────── ₹5000            │
│                                     │
│ Date Range (if applicable)          │
│  [ Start Date ] – [ End Date ]     │
│                                     │
│   [       Apply Filters       ]    │
└─────────────────────────────────────┘
```

### S9 — Notifications Center
```
┌─────────────────────────────────────┐
│ ←          Notifications            │
├─────────────────────────────────────┤
│ 🔔 Trial deadline in 2 days          │
│    U-14 Cricket Trials, Ahmedabad   │
│    2h ago                            │
├─────────────────────────────────────┤
│ 💬 Coach Rahul replied to your      │
│    enquiry                           │
│    5h ago                            │
├─────────────────────────────────────┤
│ 🎓 Scholarship deadline tomorrow     │
│    State Sports Scholarship 2026    │
│    1d ago                            │
├─────────────────────────────────────┤
│ [Home] [Search] [Saved] [Profile]   │
└─────────────────────────────────────┘
```

### S10 — Report a Listing (Modal)
```
┌─────────────────────────────────────┐
│           Report this listing    ✕  │
├─────────────────────────────────────┤
│  Why are you reporting this?        │
│  ○ Fake / Scam                      │
│  ○ Outdated information              │
│  ○ Inappropriate content            │
│  ○ Other                             │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Additional details (optional) │  │
│  └───────────────────────────────┘  │
│                                     │
│  [ Cancel ]      [ Submit Report ] │
└─────────────────────────────────────┘
```

### S11 — Settings
```
┌─────────────────────────────────────┐
│ ←             Settings               │
├─────────────────────────────────────┤
│  Account                             │
│   Edit Profile                    >  │
│   Change Password                 >  │
│                                     │
│  Preferences                         │
│   Notifications                ▢ On │
│   Language                  English >│
│                                     │
│  Support                             │
│   Help Center                     >  │
│   Report a Problem                >  │
│                                     │
│  [       Log Out       ]            │
│  Delete Account                     │
└─────────────────────────────────────┘
```

### S12 — Help / Support
```
┌─────────────────────────────────────┐
│ ←          Help Center                │
├─────────────────────────────────────┤
│  🔍 Search FAQs                      │
│                                     │
│  Popular topics                      │
│  • How do I register for a trial?   │
│  • How do I edit my academy listing?│
│  • How do I report a fake listing?  │
│                                     │
│  Still stuck?                        │
│  [     Contact Support     ]        │
└─────────────────────────────────────┘
```

---

## Part B — Reusable Templates (used across roles)

### T1 — Directory / List Template
*Used by: Academy Directory (A7), Coach Directory (A9), Trial Listings (A12), Scholarship Feed (A19), Sponsorship Opportunities (A21), My Trials [Academy/Organizer], My Tournaments [Organizer], My Sponsorships [Sponsor], Content List [Admin]*

```
┌─────────────────────────────────────┐
│ ←        [Screen Title]          ⚙  │
├─────────────────────────────────────┤
│ 🔍 Search...      [Filter icon]     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [Thumbnail]  Title / Name       │ │
│ │ Subtitle line (sport · city)    │ │
│ │ Meta line (fee / date / status) │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [Thumbnail]  Title / Name       │ │
│ │ Subtitle line                   │ │
│ │ Meta line                       │ │
│ └─────────────────────────────────┘ │
│              (repeat)               │
│           [ Load more ]              │
├─────────────────────────────────────┤
│ [Home] [Search] [Saved] [Profile]   │
└─────────────────────────────────────┘
```

**Field substitutions per screen:**

| Screen | Thumbnail | Subtitle | Meta line |
|---|---|---|---|
| Academy Directory | Academy photo | Sport · City | Fee range |
| Coach Directory | Coach photo | Sport · Experience | Fee · City |
| Trial Listings | Organizer logo | Sport · Venue | Date · Entry fee |
| Tournament (list view) | Event banner | Format · Venue | Dates · Prize pool |
| Scholarship Feed | Provider logo | Sport · Provider | Amount · Deadline |
| Sponsorship Opportunities | Sponsor logo | Sport · Eligibility | Benefits · Deadline |
| My Trials (Academy/Organizer) | — | Sport · Venue | Status: Draft/Published/Closed |
| My Tournaments (Organizer) | — | Format · Venue | Status · Registrant count |
| My Sponsorships (Sponsor) | — | Sport | Status · Applications count |
| Content List (Admin) | — | Category-specific | Status · Last edited |

---

### T2 — Detail Page Template
*Used by: Academy Detail (A8), Coach Detail (A10), Trial Detail (A13), Tournament Detail (A17), Scholarship Detail (A20), Sponsorship Detail (A22)*

```
┌─────────────────────────────────────┐
│ ←                              ♡ ⋮  │
├─────────────────────────────────────┤
│         [ Hero Image / Banner ]     │
├─────────────────────────────────────┤
│  Title (e.g. Elite Cricket Academy) │
│  Sport · City, State                │
├─────────────────────────────────────┤
│  📋 Details                          │
│   Facilities: Turf, Nets, Gym       │
│   Age Groups: U-12, U-16, Open      │
│   Timings: 6–9 AM, 4–7 PM           │
│   Fees: ₹2000–₹5000 / month         │
│                                     │
│  👤 Coaches                          │
│   [Coach card] [Coach card]         │
│                                     │
│  📍 Location                         │
│   [ Map preview ]                   │
│   Full address, contact number      │
│                                     │
│  🚩 Report this listing             │
├─────────────────────────────────────┤
│   [    Enquire / Register    ]     │
└─────────────────────────────────────┘
```

**Field substitutions per screen:**

| Screen | "📋 Details" content | Primary CTA |
|---|---|---|
| Academy Detail | Facilities, coaches, age groups, timings, fees | Enquire |
| Coach Detail | Qualifications, experience, sport, fee, location | Enquire / Book |
| Trial Detail | Eligibility, required documents, entry fee, contact | Register for Trial |
| Tournament Detail | Format, dates, venue, prize pool, entry categories | Register for Tournament |
| Scholarship Detail | Eligibility, amount, provider, deadline | Apply (external link or in-app) |
| Sponsorship Detail | Eligibility, benefits, deadline | Apply / Pitch |

---

### T3 — Enquiry / Registration Form Template
*Used by: Enquire with Coach (A11), Trial Registration Form (A14), Tournament Registration Form (A18), Apply/Pitch to Sponsor Form (A23)*

```
┌─────────────────────────────────────┐
│ ←        [Form Title]                │
├─────────────────────────────────────┤
│  Your Profile (auto-filled)          │
│   Name: Aryan Patel                  │
│   Sport: Cricket · Age: 14           │
│                                     │
│  [Form-specific fields]              │
│   ┌───────────────────────────────┐  │
│   │ Message / Pitch note          │  │
│   └───────────────────────────────┘  │
│   Preferred Date: [ 📅 Select ]      │
│   Upload Document: [ 📎 Attach ]     │
│                                     │
│  ▢ I confirm the details are correct│
│                                     │
│   [        Submit        ]          │
└─────────────────────────────────────┘
```

**Field substitutions per screen:**

| Screen | Form-specific fields |
|---|---|
| Enquire with Coach | Message box, preferred session date/time |
| Trial Registration | Personal details, document upload (ID/certificate), payment note |
| Tournament Registration | Category selection, team/individual toggle, personal details |
| Apply/Pitch to Sponsor | Pitch note text box, profile auto-attach confirmation |

---

### T4 — Enquiry Inbox Template
*Used by: Coach Enquiry Inbox (C4), Academy Enquiry Inbox (AC8)*

```
┌─────────────────────────────────────┐
│ ←          Enquiry Inbox             │
├─────────────────────────────────────┤
│ [All | New | Replied]                │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 🔵 Aryan Patel · Cricket        │ │
│ │ "Is there a slot this weekend?" │ │
│ │ 2h ago              [ Reply ]   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ⚪ Meera Shah · Badminton        │ │
│ │ "What are your fees for U-12?"  │ │
│ │ 1d ago · Replied                │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### T4b — Enquiry Detail / Reply
```
┌─────────────────────────────────────┐
│ ←   Aryan Patel                      │
├─────────────────────────────────────┤
│  Aryan Patel                         │
│  "Is there a slot this weekend?"     │
│  Today, 10:03 AM                     │
│                                     │
│                    You:              │
│      "Yes, Saturday 6 AM is open"    │
│                    Today, 10:15 AM   │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ Type a reply...               │  │
│  └───────────────────────────────┘  │
│                          [ Send ]   │
└─────────────────────────────────────┘
```

---

## Part C — Athlete / Parent (Screens not covered by shared templates)

### A1 — Onboarding: Sport & Age Group
```
┌─────────────────────────────────────┐
│           Tell us about you    ●○○  │
├─────────────────────────────────────┤
│  Which sport(s) do you play?         │
│  [Cricket ✓] [Football] [Badminton] │
│  [Athletics] [Swimming] [+ Add]     │
│                                     │
│  Age Group                           │
│  ○ Under-10  ○ Under-14             │
│  ○ Under-18  ○ Open                 │
│                                     │
│               [ Next ]               │
└─────────────────────────────────────┘
```

### A2 — Onboarding: Skill Level & Location
```
┌─────────────────────────────────────┐
│           Almost done          ○●○  │
├─────────────────────────────────────┤
│  Skill Level                         │
│  ○ Beginner  ○ Intermediate          │
│  ○ Advanced  ○ Competitive           │
│                                     │
│  City                                 │
│  ┌───────────────────────────────┐  │
│  │ 🔍 Ahmedabad, Gujarat         │  │
│  └───────────────────────────────┘  │
│                                     │
│               [ Finish ]             │
└─────────────────────────────────────┘
```

### A3 — Home / Dashboard
```
┌─────────────────────────────────────┐
│  Hi Aryan 👋              🔔  ⚙     │
├─────────────────────────────────────┤
│  🔍 Search academies, trials...     │
├─────────────────────────────────────┤
│  Recommended for you                 │
│  [Academy card] [Academy card] →     │
│                                     │
│  Trials closing soon                 │
│  [Trial card]   [Trial card]  →     │
│                                     │
│  Upcoming: Saved Tournaments          │
│  [Tournament card]              →    │
│                                     │
│  New Scholarships                    │
│  [Scholarship card]              →   │
├─────────────────────────────────────┤
│ [Home] [Search] [Saved] [Profile]   │
└─────────────────────────────────────┘
```

### A4 — My Profile (View)
```
┌─────────────────────────────────────┐
│              My Profile        ⚙    │
├─────────────────────────────────────┤
│           [ 👤 Photo ]               │
│           Aryan Patel                │
│        Cricket · Under-14            │
│         Ahmedabad, Gujarat           │
│                                     │
│  🏆 Achievements                      │
│   • State-level U-14 selection 2025 │
│   • District topscorer 2024         │
│                                     │
│  🎞 Media Gallery                     │
│   [img][img][img][img]  See all →   │
│                                     │
│        [   Edit Profile   ]         │
├─────────────────────────────────────┤
│ [Home] [Search] [Saved] [Profile]   │
└─────────────────────────────────────┘
```

### A5 — Edit Profile
```
┌─────────────────────────────────────┐
│ ←          Edit Profile        Save │
├─────────────────────────────────────┤
│  Name        [ Aryan Patel        ] │
│  Sport(s)    [ Cricket ✓  + Add   ] │
│  Age Group   [ Under-14        ▾  ] │
│  Skill Level [ Intermediate     ▾ ] │
│  City        [ Ahmedabad, Gujarat ] │
│                                     │
│  Achievements                        │
│   [ + Add Achievement ]              │
│   • State-level U-14 selection  ✕   │
│                                     │
│  Media Gallery      [ Manage → ]    │
└─────────────────────────────────────┘
```

### A6 — Media Gallery Manager
```
┌─────────────────────────────────────┐
│ ←         Media Gallery              │
├─────────────────────────────────────┤
│  [ + Upload Photo/Video ]            │
│                                     │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐        │
│  │img1│ │img2│ │vid1│ │img3│        │
│  │ ✕  │ │ ✕  │ │ ▶ ✕│ │ ✕  │        │
│  └────┘ └────┘ └────┘ └────┘        │
│                                     │
│   Drag to reorder                    │
└─────────────────────────────────────┘
```

### A15 — Registration Confirmation
```
┌─────────────────────────────────────┐
│                ✅                    │
│         Registration Confirmed!     │
├─────────────────────────────────────┤
│  U-14 Cricket Trials                 │
│  Sat, 15 Aug 2026 · 7:00 AM          │
│  Sardar Patel Stadium, Ahmedabad     │
│                                     │
│  Registration ID: #TR20260815      │
│                                     │
│  [ 🔔 Remind me before the event ]  │
│  [   Add to Calendar   ]            │
│  [        Done         ]            │
└─────────────────────────────────────┘
```

### A16 — Tournament Calendar (Calendar/List Toggle)
```
┌─────────────────────────────────────┐
│ ←     Tournaments      [Cal | List] │
├─────────────────────────────────────┤
│        August 2026        < >       │
│  Mo Tu We Th Fr Sa Su                │
│               1  2                   │
│  3  4  5  6  7  8  9                 │
│ 10 11 12 13 14 ●15 16                │
│ 17 18 19 20 21 22 23                 │
├─────────────────────────────────────┤
│  Aug 15 — U-16 State Cricket Cup     │
│  Ahmedabad · Prize Pool ₹50,000      │
│  [ View Details ]                    │
└─────────────────────────────────────┘
```

### A24 — My Activity Hub
```
┌─────────────────────────────────────┐
│ ←         My Activity                │
├─────────────────────────────────────┤
│ [Trials | Tournaments | Sponsorships]│
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ U-14 Cricket Trials              │ │
│ │ Registered · 15 Aug 2026         │ │
│ │ Status: Confirmed                │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ District Football Trials         │ │
│ │ Registered · 2 Sep 2026          │ │
│ │ Status: Pending Review           │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### A25 — Saved / Bookmarked Items
```
┌─────────────────────────────────────┐
│ ←            Saved                   │
├─────────────────────────────────────┤
│ [All | Academies | Trials | Tourn. |│
│  Scholarships]                       │
├─────────────────────────────────────┤
│ ♡ Elite Cricket Academy               │
│ ♡ U-16 State Cricket Cup               │
│ ♡ State Sports Scholarship 2026        │
├─────────────────────────────────────┤
│ [Home] [Search] [Saved] [Profile]   │
└─────────────────────────────────────┘
```

---

## Part D — Coach (Screens not covered by shared templates)

### C1 — Coach Onboarding
```
┌─────────────────────────────────────┐
│         Set up your coach profile    │
├─────────────────────────────────────┤
│  Sport(s) coached  [Cricket ✓]      │
│  Certifications    [ + Add ]        │
│   • BCCI Level 2 Certificate         │
│  Years of Experience  [ 8 ]          │
│                                     │
│               [ Next ]               │
└─────────────────────────────────────┘
```

### C2 — Coach Profile Creation/Edit
```
┌─────────────────────────────────────┐
│ ←        Edit My Listing       Save │
├─────────────────────────────────────┤
│          [ 📷 Profile Photo ]        │
│  Name          [ Rahul Mehta      ] │
│  Sport(s)      [ Cricket ✓        ] │
│  Certifications [ + Add / Edit    ] │
│  Experience     [ 8 years        ] │
│  Fee Structure  [ ₹800 / session ] │
│  Location       [ Ahmedabad       ] │
│  Bio            [ Text area       ] │
└─────────────────────────────────────┘
```

### C3 — Coach Dashboard
```
┌─────────────────────────────────────┐
│  Hi Coach Rahul 👋          🔔  ⚙   │
├─────────────────────────────────────┤
│  Profile completeness: 80%  [ →  ]  │
│                                     │
│  📥 New Enquiries (3)      [View →] │
│                                     │
│  Quick Actions                       │
│  [ Edit Listing ]  [ Browse App ]   │
└─────────────────────────────────────┘
```

*(C4/C5 use Template T4/T4b · C6 reuses Athlete/Parent directory & detail screens)*

---

## Part E — Academy (Screens not covered by shared templates)

### AC1 — Academy Onboarding
```
┌─────────────────────────────────────┐
│        Set up your academy           │
├─────────────────────────────────────┤
│  Academy Name  [ Elite Cricket Acad]│
│  Sport(s)      [ Cricket ✓  + Add ] │
│  City          [ Ahmedabad        ] │
│                                     │
│               [ Next ]               │
└─────────────────────────────────────┘
```

### AC2 — Academy Listing Creation/Edit
```
┌─────────────────────────────────────┐
│ ←       Edit Academy Listing   Save │
├─────────────────────────────────────┤
│         [ 📷 Cover Photo ]           │
│  Name         [ Elite Cricket Acad]│
│  Sport(s)     [ Cricket ✓         ] │
│  Facilities   [ Turf, Nets, Gym   ] │
│  Fee Range    [ ₹2000 – ₹5000/mo  ] │
│  Age Groups   [ U-12, U-16, Open  ] │
│  Timings      [ 6–9AM, 4–7PM      ] │
│  Coaches      [ + Add Coach       ] │
│  Photos       [ + Add Photos      ] │
└─────────────────────────────────────┘
```

### AC3 — Academy Dashboard
```
┌─────────────────────────────────────┐
│  Elite Cricket Academy 👋   🔔  ⚙   │
├─────────────────────────────────────┤
│  Active Trials: 2   Enquiries: 5    │
│                                     │
│  [ + Post New Trial ]                │
│                                     │
│  Recent Registrants                  │
│  • Aryan Patel — U-14 Trials         │
│  • Meera Shah — U-14 Trials          │
│                    [ View All → ]   │
└─────────────────────────────────────┘
```

### AC4 — Trial Posting Form (Create/Edit)
```
┌─────────────────────────────────────┐
│ ←       Post a New Trial       Save │
├─────────────────────────────────────┤
│  Trial Name    [ U-14 Cricket Trial]│
│  Sport         [ Cricket          ] │
│  Date & Time   [ 📅 15 Aug 2026   ] │
│  Venue         [ Sardar Patel Std ] │
│  Eligibility   [ Boys, U-14, Ahd. ] │
│  Entry Fee     [ ₹200              ] │
│  Required Docs [ Aadhaar, Photo   ] │
│  Contact       [ +91 98XXXXXXXX   ] │
│                                     │
│  Status: ○ Draft  ● Published       │
│  [        Save & Publish        ]  │
└─────────────────────────────────────┘
```

### AC6 — Trial Registrant List
```
┌─────────────────────────────────────┐
│ ←   Registrants: U-14 Trials         │
├─────────────────────────────────────┤
│ 34 registered · 6 spots left         │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Aryan Patel                     │ │
│ │ Docs: ✅ Submitted   [ View → ] │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Meera Shah                       │ │
│ │ Docs: ⚠ Pending      [ View → ] │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### AC7 — Registrant Detail
```
┌─────────────────────────────────────┐
│ ←        Aryan Patel                 │
├─────────────────────────────────────┤
│  Name: Aryan Patel                   │
│  Age: 14 · Cricket · Under-14        │
│  Contact: +91 98XXXXXXXX             │
│                                     │
│  Submitted Documents                 │
│   📄 Aadhaar Card       [ View ]     │
│   📷 Passport Photo     [ View ]     │
│                                     │
│  [ Mark as Verified ]  [ Reject ]   │
└─────────────────────────────────────┘
```

*(AC5 uses Template T1 · AC8/AC9 use Template T4/T4b)*

---

## Part F — Organizer (Screens not covered by shared templates)

### O1 — Organizer Onboarding
```
┌─────────────────────────────────────┐
│      Set up your organizer profile   │
├─────────────────────────────────────┤
│  Organization Name [ SportsFed Guj ]│
│  Type   ○ Federation ○ Club ○ Other │
│  Verification Docs  [ + Upload    ] │
│                                     │
│               [ Submit ]             │
└─────────────────────────────────────┘
```

### O2 — Organizer Dashboard
```
┌─────────────────────────────────────┐
│  SportsFed Gujarat 👋       🔔  ⚙   │
├─────────────────────────────────────┤
│  Active Trials: 3  Tournaments: 1    │
│                                     │
│  [ + Post Trial ] [ + Post Tournament]│
│                                     │
│  Upcoming Deadlines                  │
│  • U-16 Cup registration closes      │
│    in 3 days                         │
└─────────────────────────────────────┘
```

### O5 — Tournament Listing Create/Edit
```
┌─────────────────────────────────────┐
│ ←     Create Tournament        Save │
├─────────────────────────────────────┤
│  Tournament Name [ U-16 State Cup ] │
│  Format        [ Knockout        ▾] │
│  Dates         [ 📅 20–25 Aug 2026]│
│  Venue         [ GMDC Ground       ] │
│  Entry Fee     [ ₹500 / team       ] │
│  Prize Pool    [ ₹50,000           ] │
│  Categories    [ U-14, U-16, U-18 ] │
│                                     │
│  [        Save & Publish        ]  │
└─────────────────────────────────────┘
```

### O7 — Registration Management (List)
```
┌─────────────────────────────────────┐
│ ←   Registrations: U-16 State Cup    │
├─────────────────────────────────────┤
│ [U-14 (18/24)|U-16 (22/24)|U-18(9/24)]│
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Team Titans          Paid ✅    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Team Strikers        Pending ⚠  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### O8 — Capacity / Spot Management
```
┌─────────────────────────────────────┐
│ ←      Manage Capacity               │
├─────────────────────────────────────┤
│  U-14 Category                       │
│  Spots: 24   Filled: 18               │
│  ──────●───────────                  │
│  ▢ Enable waitlist when full          │
│                                     │
│  U-16 Category                       │
│  Spots: 24   Filled: 22               │
│  ─────────────●────                  │
│                                     │
│  [        Save Changes        ]    │
└─────────────────────────────────────┘
```

### O9 — Results Publishing Form
```
┌─────────────────────────────────────┐
│ ←     Publish Results          Save │
├─────────────────────────────────────┤
│  Category  [ U-16 ▾ ]                │
│                                     │
│  🥇 Winner      [ Team Titans      ] │
│  🥈 Runner-up   [ Team Strikers    ] │
│  🥉 3rd Place   [ Team Falcons     ] │
│                                     │
│  [ + Upload Bracket Image ]          │
│                                     │
│  [       Publish Results       ]   │
└─────────────────────────────────────┘
```

### O10 — Results / Brackets View (Public)
```
┌─────────────────────────────────────┐
│ ←     U-16 State Cup — Results       │
├─────────────────────────────────────┤
│  Quarterfinal   Semifinal   Final    │
│  Titans  ─┐                          │
│           ├─ Titans ─┐               │
│  Falcons ─┘           │               │
│                       ├─ 🏆 Titans   │
│  Strikers─┐           │               │
│           ├─ Strikers─┘               │
│  Eagles  ─┘                          │
├─────────────────────────────────────┤
│ 🥇 Titans  🥈 Strikers  🥉 Falcons   │
└─────────────────────────────────────┘
```

*(O3/O4/O6 use Template T1)*

---

## Part G — Sponsor / Brand (Screens not covered by shared templates)

### SP1 — Sponsor Onboarding
```
┌─────────────────────────────────────┐
│        Set up your brand profile     │
├─────────────────────────────────────┤
│  Brand Name    [ ProGear Sports    ] │
│  Logo          [ 📷 Upload         ] │
│  Category      [ Sportswear      ▾] │
│  Verification  [ + Upload Docs     ] │
│                                     │
│               [ Submit ]             │
└─────────────────────────────────────┘
```

### SP2 — Sponsor Dashboard
```
┌─────────────────────────────────────┐
│  ProGear Sports 👋           🔔  ⚙  │
├─────────────────────────────────────┤
│  Active Listings: 2  New Apps: 7     │
│                                     │
│  [ + Post Sponsorship ]              │
│                                     │
│  Recent Applications                 │
│  • Aryan Patel — Cricket Sponsorship │
│                    [ View All → ]   │
└─────────────────────────────────────┘
```

### SP3 — Sponsorship Listing Create/Edit
```
┌─────────────────────────────────────┐
│ ←   Create Sponsorship Listing  Save│
├─────────────────────────────────────┤
│  Title           [ U-16 Cricket Kit]│
│  Sport           [ Cricket        ] │
│  Eligibility     [ State-level    ] │
│                    players only     │
│  Benefits Offered [ Free kit + ₹5000]│
│                    stipend / month  │
│  Deadline        [ 📅 30 Sep 2026 ] │
│                                     │
│  [       Save & Publish        ]   │
└─────────────────────────────────────┘
```

### SP5 — Athlete Discovery Search
```
┌─────────────────────────────────────┐
│ ←     Discover Athletes              │
├─────────────────────────────────────┤
│  [Sport ▾][Age ▾][City ▾][Level ▾]  │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [👤] Aryan Patel                │ │
│ │ Cricket · U-14 · Ahmedabad      │ │
│ │ 🏆 2 achievements   [ View → ]  │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [👤] Meera Shah                 │ │
│ │ Badminton · U-16 · Surat        │ │
│ │ 🏆 1 achievement    [ View → ]  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### SP6 — Athlete Profile View (Sponsor's View)
```
┌─────────────────────────────────────┐
│ ←        Aryan Patel                 │
├─────────────────────────────────────┤
│           [ 👤 Photo ]               │
│           Aryan Patel                │
│        Cricket · Under-14            │
│                                     │
│  🏆 Achievements                     │
│   • State-level U-14 selection 2025 │
│                                     │
│  🎞 Media Gallery                    │
│   [img][img][img]                   │
│                                     │
│  [  ★ Shortlist  ]  [ Message ]     │
└─────────────────────────────────────┘
```

### SP8 — Application Detail / Pitch View
```
┌─────────────────────────────────────┐
│ ←    Aryan Patel's Application       │
├─────────────────────────────────────┤
│  Applied to: U-16 Cricket Kit        │
│  Date: 20 Jul 2026                   │
│                                     │
│  Pitch Note:                         │
│  "I've represented my state at the  │
│   U-14 level and am looking for..." │
│                                     │
│  [ View Full Profile ]               │
│                                     │
│  [ ★ Shortlist ] [ Reject ] [ Reply]│
└─────────────────────────────────────┘
```

### SP9 — Shortlist
```
┌─────────────────────────────────────┐
│ ←          Shortlist                 │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ★ Aryan Patel · Cricket          │ │
│ │ Note: "Strong technique,        │ │
│ │  follow up next week"           │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ★ Meera Shah · Badminton         │ │
│ │ Note: "—"                        │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

*(SP4 uses Template T1 · SP7 uses Template T4-style inbox)*

---

## Part H — Admin (Screens not covered by shared templates)

### AD1 — Admin Login
```
┌─────────────────────────────────────┐
│            Admin Portal              │
├─────────────────────────────────────┤
│   ┌───────────────────────────────┐  │
│   │ Email                          │  │
│   └───────────────────────────────┘  │
│   ┌───────────────────────────────┐  │
│   │ Password                       │  │
│   └───────────────────────────────┘  │
│   ┌───────────────────────────────┐  │
│   │ 2FA Code                       │  │
│   └───────────────────────────────┘  │
│   [          Log In          ]      │
└─────────────────────────────────────┘
```

### AD2 — Admin Dashboard
```
┌─────────────────────────────────────┐
│  Admin Dashboard                     │
├─────────────────────────────────────┤
│  Active Listings   Flagged Items     │
│      1,204              7            │
│                                     │
│  Pending Expirations   New Signups   │
│         12                  34       │
│                                     │
│  [ Content Mgmt ] [ Moderation ]    │
│  [ Expiry Rules ] [ Categories ]    │
└─────────────────────────────────────┘
```

### AD3 — Content Management — Category Picker
```
┌─────────────────────────────────────┐
│ ←      Content Management            │
├─────────────────────────────────────┤
│  [ 🏫 Academies (412)          > ]  │
│  [ 🧑‍🏫 Coaches (238)           > ]  │
│  [ 🏆 Trials (89)              > ]  │
│  [ 🏟 Tournaments (24)         > ]  │
│  [ 🎓 Scholarships (15)        > ]  │
│  [ 💼 Sponsorships (31)        > ]  │
└─────────────────────────────────────┘
```

### AD5 — Content Create/Edit Form (Generic)
```
┌─────────────────────────────────────┐
│ ←   Edit Academy: Elite Cricket Save│
├─────────────────────────────────────┤
│  [ Dynamic form fields based on the  │
│    selected category's schema —      │
│    same fields as the owner's own    │
│    edit screen (e.g. AC2), editable  │
│    by admin directly. ]              │
│                                     │
│  [        Save Changes        ]    │
│  [        Delete Record        ]   │
└─────────────────────────────────────┘
```

### AD6 — Flagged/Reported Listings Queue
```
┌─────────────────────────────────────┐
│ ←      Reported Listings             │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Elite Cricket Academy            │ │
│ │ Reason: Outdated information     │ │
│ │ Reported 3x · 2 days ago         │ │
│ │                    [ Review → ] │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Coach Vikram Singh                │ │
│ │ Reason: Fake / Scam                │ │
│ │ Reported 1x · 5 hours ago          │ │
│ │                    [ Review → ] │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### AD7 — Moderation Detail / Action Screen
```
┌─────────────────────────────────────┐
│ ←   Reviewing: Elite Cricket Academy │
├─────────────────────────────────────┤
│  Reported by: 3 users                │
│  Reason: Outdated information        │
│  Comment: "Fees listed are wrong"    │
│                                     │
│  [ View Full Listing ]               │
│                                     │
│  Action:                             │
│  [ Approve (No Action) ]             │
│  [ Edit Listing ]                    │
│  [ Remove Listing ]                  │
│  [ Warn Owner ]                      │
└─────────────────────────────────────┘
```

### AD8 — Content Expiry Rules Configuration
```
┌─────────────────────────────────────┐
│ ←      Expiry Rules             Save│
├─────────────────────────────────────┤
│  Trials                              │
│   Auto-expire  [ 1 day ▾ ] after     │
│   event date                          │
│                                     │
│  Tournaments                          │
│   Auto-expire  [ 3 days ▾ ] after    │
│   final match date                    │
│                                     │
│  Sponsorships                         │
│   Auto-expire on listed deadline ▢   │
│                                     │
│  [        Save Rules        ]       │
└─────────────────────────────────────┘
```

### AD9 — Expiry Monitor
```
┌─────────────────────────────────────┐
│ ←      Expiry Monitor                │
├─────────────────────────────────────┤
│ [ Pending | Expired | Overridden ]  │
├─────────────────────────────────────┤
│ U-14 Cricket Trials                  │
│ Expires in 2 days       [ Override ]│
├─────────────────────────────────────┤
│ District Football Trials             │
│ Expired 1 day ago         [ Restore]│
└─────────────────────────────────────┘
```

### AD10/AD11/AD12 — Category Management (Sports / Cities / Age Groups)
```
┌─────────────────────────────────────┐
│ ←    Manage Sports               +  │
├─────────────────────────────────────┤
│  Cricket                        ✎ ✕│
│  Football                       ✎ ✕│
│  Badminton                      ✎ ✕│
│  Athletics                       ✎ ✕│
│  Swimming                       ✎ ✕│
├─────────────────────────────────────┤
│         [ + Add New Sport ]          │
└─────────────────────────────────────┘
```
*(Same layout applies to Cities and Age Groups, with the list items and "Add New" label swapped accordingly.)*

---

## Coverage Summary

| Part | Screens Wireframed Individually | Screens via Shared Templates |
|---|---|---|
| Shared (S1–S12) | 12 | — |
| Templates (T1–T4b) | 6 template wireframes | Covers 20 screens across roles |
| Athlete / Parent | 13 | 12 (via T1/T2/T3) |
| Coach | 3 | 3 (via T1/T4/T4b) |
| Academy | 5 | 4 (via T1/T4/T4b) |
| Organizer | 6 | 4 (via T1) |
| Sponsor | 5 | 4 (via T1/T4) |
| Admin | 8 | 4 (via T1) |
| **Total** | **58 unique wireframes** | **51 screen instances mapped to templates** |

This keeps every one of the 83 screens from the Screen Inventory fully specified — either with its own wireframe or via a clearly mapped shared template — while avoiding needless repetition of identical layouts.
