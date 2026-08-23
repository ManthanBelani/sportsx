# SportX Athlete App - Design Audit Report

**Date:** August 23, 2026  
**Design Source:** `sportsx-design-v1/` (78 screens total)  
**Flutter App:** `sportx_app/`

---

## Executive Summary

The athlete side of the SportX app is **severely incomplete**. Out of **9 athlete-specific screens** designed, only **4 basic screens** are implemented. Critical features for athlete engagement (scholarships, sponsorships, tournaments, trials) are completely missing.

---

## Part 1: Athlete Screens - Design vs Implementation

### 1.1 Screens That ARE Implemented

| Design File | Flutter Screen | Status |
|-------------|----------------|--------|
| `athlete/media-gallery.html` | `MediaGalleryScreen` | ✅ Implemented |
| `athlete/settings.html` | `ProfileScreen` (partial) | ⚠️ Partial |
| `profile-view.html` | `ViewProfileScreen` (type=athlete) | ✅ Implemented |
| `profile-edit.html` | `EditProfileScreen` | ✅ Implemented |

### 1.2 Screens MISSING Implementation

| Design File | Screen Name | Priority |
|-------------|-------------|----------|
| `athlete/scholarship-feed.html` | Scholarship Feed | 🔴 HIGH |
| `athlete/scholarship-detail.html` | Scholarship Detail | 🔴 HIGH |
| `athlete/sponsorship-list.html` | Sponsorship List | 🔴 HIGH |
| `athlete/sponsorship-detail.html` | Sponsorship Detail | 🔴 HIGH |
| `athlete/apply-sponsor.html` | Apply for Sponsorship | 🔴 HIGH |
| `athlete/tournament-detail.html` | Tournament Detail | 🔴 HIGH |
| `athlete/tournament-registration.html` | Tournament Registration | 🔴 HIGH |
| `athlete/enquire-coach.html` | Enquire Coach | 🟡 MEDIUM |
| `athlete/settings.html` | Full Settings Screen | 🔴 HIGH |

---

## Part 2: Related Screens Athletes Need (Missing)

These screens are in the root directory and athletes would interact with them:

| Design File | Screen Name | Purpose | Status |
|-------------|-------------|---------|--------|
| `academy-detail.html` | Academy Detail | View academy info | ❌ Missing |
| `trial-detail.html` | Trial Detail | View trial info | ❌ Missing |
| `trial-listings.html` | Trial Listings | Browse trials | ❌ Missing |
| `trial-registration.html` | Trial Registration | Register for trial | ❌ Missing |
| `tournament-calendar.html` | Tournament Calendar | View tournament calendar | ❌ Missing |
| `coach-detail.html` | Coach Detail | View coach profile | ⚠️ Partial (enquiry missing) |
| `coach-directory.html` | Coach Directory | Browse coaches | ⚠️ Partial |
| `academy-directory.html` | Academy Directory | Browse academies | ❌ Missing |
| `saved-items.html` | Saved Items | View saved items | ❌ Missing |
| `search-results.html` | Search Results | Search functionality | ❌ Missing |
| `notifications.html` | Notifications | View notifications | ❌ Missing |
| `universal-search.html` | Universal Search | Global search | ❌ Missing |

---

## Part 3: Detailed Missing Features Analysis

### 3.1 Scholarship Module (🔴 CRITICAL - Fully Missing)

**Design:** `athlete/scholarship-feed.html`, `athlete/scholarship-detail.html`

**Features Designed:**
- Scholarship feed with search bar
- Sport filter chips (Football, Basketball, Athletics, Swimming)
- Scholarship cards showing: thumbnail, provider, amount badge, deadline badge
- Detail screen with: hero gradient, eligibility criteria, application steps, required documents
- External link to apply on official portal
- Save (heart) and Share actions

**Missing in Flutter:**
- No scholarship feed screen
- No scholarship detail screen
- No scholarship data model
- No scholarship API endpoints
- No scholarship provider

---

### 3.2 Sponsorship Module (🔴 CRITICAL - Fully Missing)

**Design:** `athlete/sponsorship-list.html`, `athlete/sponsorship-detail.html`, `athlete/apply-sponsor.html`

**Features Designed:**
- Sponsorship list with brand logos, descriptions, benefit tags (Grant, Gear Package, Mentorship)
- Sponsorship detail with dark hero, benefits list, eligibility
- Apply Sponsor form with profile preview, pitch note textarea, document upload
- Deadline badges

**Missing in Flutter:**
- No sponsorship list screen
- No sponsorship detail screen
- No apply sponsor screen
- No sponsorship data model
- No sponsorship API endpoints

---

### 3.3 Tournament Module (🔴 CRITICAL - Fully Missing)

**Design:** `athlete/tournament-detail.html`, `athlete/tournament-registration.html`, `tournament-calendar.html`

**Features Designed:**

**Tournament Detail:**
- Hero gradient with date, title, location, sport categories, team count
- Info grid: Entry Fee, Prize Pool, Format, Registration Deadline
- Prize pool card with breakdown (1st, 2nd, 3rd)
- Organizer card with verified badge
- Venue section with "View on Map"
- Save and Share actions

**Tournament Registration:**
- Category selection (U-16, U-18) with radio-style selection
- Team Details: Team Name, Manager, Contact, Number of Players
- Player Details: Captain Name, Coach Name
- Fee note and Submit button

**Tournament Calendar:**
- Calendar view for tournaments
- Date groups with tournament entries

**Missing in Flutter:**
- No tournament detail screen
- No tournament registration screen
- No tournament calendar screen
- No tournament data model
- No tournament API endpoints

---

### 3.4 Trial Module (🔴 CRITICAL - Fully Missing)

**Design:** `trial-detail.html`, `trial-listings.html`, `trial-registration.html`

**Features Designed:**
- Trial listings with filterable cards
- Trial detail with trial information, eligibility, venue
- Trial registration form

**Missing in Flutter:**
- No trial listings screen
- No trial detail screen
- No trial registration screen
- No trial data model

---

### 3.5 Academy Module (🔴 HIGH - Partially Missing)

**Design:** `academy-detail.html`, `academy-directory.html`

**Features Designed:**
- Academy directory with search and filters
- Academy detail with academy info, trials offered, contact details

**Missing in Flutter:**
- Academy directory screen
- Academy detail screen
- Academy data model

---

### 3.6 Coach Enquiry Module (🟡 MEDIUM - Partially Missing)

**Design:** `athlete/enquire-coach.html`, `coach-detail.html`

**Features Designed:**
- Enquire Coach modal/form with:
  - Coach info card (avatar, name, sport, experience, price)
  - Message textarea
  - Preferred Training Days (day + time inputs)
  - Age dropdown
  - Contact Number
  - Send Enquiry button

**Current Implementation:**
- `coach-detail.html` has basic coach view
- But no "Enquire Coach" form/screen in Flutter
- No enquiry submission API

---

## Part 4: UI Components Missing in Athlete Feature

### 4.1 Cards & Containers
| Component | Used In | Flutter Status |
|-----------|---------|----------------|
| Info Card (label + value layout) | Multiple screens | ❌ Missing |
| Profile Preview Card | apply-sponsor | ❌ Missing |
| Coach Info Card | enquire-coach | ❌ Missing |
| Organizer Card | tournament-detail | ❌ Missing |
| Sponsor Card | sponsorship-list | ❌ Missing |
| Scholarship Card | scholarship-feed | ❌ Missing |

### 4.2 Buttons & Actions
| Component | Used In | Flutter Status |
|-----------|---------|----------------|
| External Link Button | scholarship-detail | ❌ Missing |
| Share Button | Multiple screens | ❌ Missing |
| Save/Heart Button | Multiple screens | ❌ Missing |

### 4.3 Form Elements
| Component | Used In | Flutter Status |
|-----------|---------|----------------|
| Phone Input (country code + input) | enquire-coach | ❌ Missing |
| Document Upload Area | apply-sponsor | ❌ Missing |
| Day + Time Input Row | enquire-coach | ❌ Missing |
| Age Dropdown | enquire-coach | ❌ Missing |

### 4.4 Badges & Tags
| Component | Used In | Flutter Status |
|-----------|---------|----------------|
| Amount Badge (green) | scholarship/sponsorship | ❌ Missing |
| Deadline Badge (red/amber) | All listing screens | ❌ Missing |
| Benefit Tag (green pill) | sponsorship | ❌ Missing |
| Sport Filter Chip | All listing screens | ⚠️ Partial |

### 4.5 Specialized Layouts
| Component | Used In | Flutter Status |
|-----------|---------|----------------|
| Prize Pool Card (amber gradient) | tournament-detail | ❌ Missing |
| Hero Gradient Section | scholarship/tournament | ❌ Missing |
| Media Grid (3-column) | media-gallery | ❌ Missing |
| Tab Bar (Photos/Videos/Achievements) | media-gallery | ⚠️ Partial |

---

## Part 5: Design Tokens (from athlete screens)

### Colors
```css
--bg: #ffffff              /* Background */
--surface: #f7f8fa        /* Light gray surface */
--fg: #111111             /* Foreground/text dark */
--muted: #6b7280          /* Muted gray text */
--border: #d9dee7         /* Light border */
--accent: #1677ff         /* Primary blue accent */

/* Semantic */
#fee2e2 / #dc2626         /* Red/error */
#fef3c7 / #92400e         /* Amber/warning */
#d1fae5 / #065f46         /* Green/success */
#dbeafe / #1677ff         /* Blue/info */
#1a365d / #2d5a87         /* Hero gradient */
```

### Typography
```css
Font: 'Inter', system-ui, sans-serif
Weights: 400, 500, 600, 700
Sizes: 12, 13, 14, 15, 16, 18, 20-22, 28, 32
```

### Spacing & Radius
```css
Padding: 8px, 10-12px, 14-16px, 20-24px
Radius: 4px (badges), 8px (cards/buttons), 14px (toggle), 20px (chips)
```

### Icons
- Library: **Lucide Icons**
- Used: `arrow-left`, `wifi`, `radio`, `battery-full`, `mail`, `bell`, `lock`, `trash-2`, `clock`, `trophy`, `stadium`, `chevron-right`

---

## Part 6: Priority Implementation Order

### Phase 1: Core Athlete Features (Week 1-2)
1. **Scholarship Feed + Detail** - High revenue potential
2. **Sponsorship List + Detail + Apply** - Core monetization
3. **Athlete Settings Screen** - User retention

### Phase 2: Event Discovery (Week 3-4)
4. **Tournament Calendar + Detail + Registration** - Major engagement driver
5. **Trial Listings + Detail + Registration** - Key athlete use case

### Phase 3: Discovery & Engagement (Week 5-6)
6. **Academy Directory + Detail** - Training discovery
7. **Coach Directory + Detail + Enquiry** - Coach connection
8. **Saved Items Screen** - User engagement

### Phase 4: Utilities (Week 7+)
9. **Notifications Screen** - User engagement
10. **Search Results + Universal Search** - Navigation
11. **Help & Support** - User retention

---

## Part 7: Files to Create

### New Flutter Files Needed

```
lib/features/athlete/
├── presentation/
│   ├── screens/
│   │   ├── scholarship_feed_screen.dart      # NEW
│   │   ├── scholarship_detail_screen.dart     # NEW
│   │   ├── sponsorship_list_screen.dart       # NEW
│   │   ├── sponsorship_detail_screen.dart     # NEW
│   │   ├── apply_sponsor_screen.dart          # NEW
│   │   ├── tournament_detail_screen.dart      # NEW
│   │   ├── tournament_registration_screen.dart # NEW
│   │   ├── tournament_calendar_screen.dart    # NEW
│   │   ├── trial_listings_screen.dart         # NEW
│   │   ├── trial_detail_screen.dart           # NEW
│   │   ├── trial_registration_screen.dart     # NEW
│   │   ├── academy_directory_screen.dart      # NEW
│   │   ├── academy_detail_screen.dart         # NEW
│   │   ├── enquire_coach_screen.dart          # NEW
│   │   └── athlete_settings_screen.dart       # NEW (full version)
│   └── widgets/
│       ├── scholarship_card.dart             # NEW
│       ├── sponsorship_card.dart             # NEW
│       ├── tournament_card.dart              # NEW
│       ├── trial_card.dart                   # NEW
│       ├── academy_card.dart                 # NEW
│       ├── info_card.dart                    # NEW
│       ├── prize_pool_card.dart              # NEW
│       ├── coach_info_card.dart              # NEW
│       ├── deadline_badge.dart               # NEW
│       ├── amount_badge.dart                 # NEW
│       └── benefit_tag.dart                  # NEW
├── models/
│   ├── scholarship.dart                      # NEW
│   ├── sponsorship.dart                      # NEW
│   ├── tournament.dart                       # NEW
│   ├── trial.dart                            # NEW
│   └── academy.dart                          # NEW
└── providers/
    ├── scholarship_provider.dart             # NEW
    ├── sponsorship_provider.dart             # NEW
    ├── tournament_provider.dart              # NEW
    ├── trial_provider.dart                   # NEW
    └── academy_provider.dart                  # NEW
```

---

## Notes

- `@sportsx-design-v1/` folder was not found in the project directory
- Design uses **Lucide Icons** and **Inter** font family
- 78 total screens in design, athlete-specific screens are 9
- No dedicated athlete models/providers - currently uses generic `User` class and shared `directory_provider.dart`

---

*Report generated for SportX Project - Athlete App Audit*
