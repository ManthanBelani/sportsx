# SportX — Design ⇄ Flutter Cross-Verification Report (All Roles)

**Date:** Oct 2026
**Design source:** `design_screeen_shot/` (4 Play Store previews + 13 WhatsApp design-board images)
**App:** `sportx_app/` (Flutter, v3.2 unified shell, `sportx-api/` backend)

---

## 1. Executive Summary

The app follows the design boards' core architecture — **one unified `MainShell` bottom-nav (Home / Explore / ➕ Create / Community / More) for every role**, with per-role *content* driven by `core/role_config.dart` (create tiles, More rows, discover links, accents). Cross-verifying every design image screen-by-screen against the Flutter code shows:

| Overall result | Value |
|---|---|
| Design screens represented | 48+ across 5 role boards + shared screens |
| Fully matched | ✅ 27 |
| Partially matched | ⚠️ 14 |
| Deliberate deviations (product decisions, commented in code) | 📝 5 |
| Missing | ❌ 4 |

The **athlete, organizer and coach boards are the strongest**; the **scout board has the most gaps** in the Create tab; and a few *design-side artifacts* (Play Store preview 2 stat naming) do not match the in-app boards they were derived from.

---

## 2. Design Image Inventory & Role Mapping

| Image | Content | Role |
|---|---|---|
| `sportx_screenshot_1_home…4` (+ playstore previews, feature graphic) | Play Store marketing mocks: home, athlete profile, opportunities list, academies directory | Athlete (mock only — marketing artifact) |
| `4.14.41 PM.jpeg` / `PM7.jpeg` | Explore — athlete grid variant / rail variant | All roles (shell tab) |
| `4.14.42 PM.jpeg` / `PM6.jpeg` | More hub (athlete) / generic Create 2-col grid | Athlete |
| `4.14.43 PM1→PM4` | Own profile, Notifications, Leaderboard, Academies directory | Athlete / shared |
| `4.14.44 PM5` | Athlete Home | Athlete |
| `4.15.00 PM` | 12-screen Coach board (Home, Explore, Create, Community, More, Profile, Programs, Leaderboard, Academies, Notifications, Messages) | Coach |
| `4.15.15 PM` | 12-screen Academy board (…+ Our Athletes, Events/Trials, Facilities) | Academy |
| `4.15.31 PM` | 12-screen Organizer board (…+ Event Mgmt, Registrations, Analytics) | Organizer |
| `4.17.25 PM` | 12-screen Scout board (…+ Shortlist, Talent Report, Scouting Opportunities) | Talent Scout |
| `10.53.52 PM` | Play Store feature graphic (no UI) | — |

---

## 3. Shared Shell (all 5 role boards — screens 1–5)

Design intent (`USERFLOW.md` §3.1 + each board): every role gets the same 5 tabs; only content changes.

| Element | Design | Flutter | Status |
|---|---|---|---|
| Bottom nav 5 items + 47px rounded Create FAB pulled above bar | all boards | `router.dart MainShell` — same geometry (72px bar, yellow FAB, underline active state) | ✅ |
| SportXWordmark + bell(unread) + avatar header | all boards | `home_kit.dart SportXWordmark + HomeHeaderActions` | ✅ |
| Home = role dashboard inside shell | boards | Home/Coach/Academy/Organizer/Scout dashboards all registered in ShellRoute | ✅ |
| Explore tab role content | boards | `ExploreScreen` switches organizer layout + role discover links | ✅ |
| Community tab (Network/Groups/Events + suggested + groups) | boards | `CommunityScreen` — Network/Groups/Events tabs + role chips | ✅ (partial — group "Join" flow cosmetic, see §6) |
| Create tab role-driven tile list | boards | `CreateScreen` + `roleConfigProvider.createTiles` | ⚠️ layout & tile coverage per role (below) |
| More tab role-driven rows | boards | `MoreScreen` + `roleConfigProvider.moreRows` | ✅ (strongest match) |

---

## 4. Role 1 — Athlete

### 4.1 Home (`4.14.44 PM5`) → `features/home/presentation/screens/home_screen.dart`

| Design element | Flutter | Status |
|---|---|---|
| Greet card (avatar, Hi Rahul!, 60% + Complete Now) | `GreetCardV3` w/ real profile photo + `/profile-completion` CTA | ✅ |
| Leaderboard card (👑 chips + top-5 rank strip) | `LeaderboardSectionV3` — chips + strip w/ rank badges | ✅ |
| Quick tiles 2-col: Opportunities (yellow) + Academy Coach & Training (blue) with sub-tiles | Two `QuickTileV3` with exact same 4+3 sub-tiles (`Trials/Tournaments/Scholarships/Sponsorships`, `Academies/Coaches/Training/Centres`) | ✅ |
| Feed tabs (For You…Events) + post card (1+2+2 image grid, ❤💬✈, bookmark) | `FeedTabsBar` + `PostCardV3` identical geometry | ✅ |
| Recommended Athletes rail (Follow) | `_RecommendedRail` + `RailPersonCard` — **CTA is "View" not "Follow"** (wired to profile instead of a dead follow button) | ⚠️ (intentional fix of known gap in USERFLOW §12.3) |
| Role line (Athlete badge + city) | `RoleLine` (blue badge in design is `yellowTint` in code — minor color) | ✅ |

### 4.2 Own Profile (`4.14.43 PM1`) → `athlete/profile_screen.dart`

| Design element | Flutter | Status |
|---|---|---|
| Cover + overlapping avatar + verified name + Edit Profile pill | `_profileHero` + `_profileTitle` | ✅ |
| Stathead: Posts / Connections / Sports / Achievements / % complete + bar | `_statHead` — exact 5 stats + gradient + bar | ✅ |
| Bio + Edit Profile / Share Profile / View as Public | `_profileActions` (Edit gradient, Share chip, Public chip) | ✅ |
| Tabs Overview/Posts/Achievements/Media/Connections | `KitTabBar` — taps navigate to the corresponding screens | ⚠️ tabs navigate away instead of switching inline |
| About card (Full Name/Role/Location/Age Group/**College/Interests** + Edit) | `_aboutCard` — **College & Interests rows missing** (data not modeled) | ⚠️ |
| Sports card (Primary Sport badge, Playing Role/Level/Experience, dashed Add Another Sport) | `_sportsCard` — badge + Add Another Sport ✅, **Playing Role/Level/Experience rows missing** | ⚠️ |
| Media 3-col grid with +N overlay | `_mediaCard` — identical (76px tiles, +N black tile) | ✅ |
| Achievements rows + dashed Add Achievement | `_achievementsCard` ✅ (dashed style differs, functional) | ✅ |
| Social links avatar icons + Edit | `_socialCard` + `SocialLinksRow` | ✅ |
| Connections avatar strip (Rohit/Priya/Karan/Sneha, +12 More) | **missing** — replaced by `_roleQuickLinks` tool grid | ⚠️ |
| Play Store preview 2 stats (Followers/Achievements/Trials Attended) | Not implemented anywhere | 📝 artifact differs from board; board is source of truth |

### 4.3 Explore (`4.14.41 PM` + `PM7`) → `home/presentation/screens/explore_screen.dart`

| Design element | Flutter | Status |
|---|---|---|
| Variant A: category chips (All/Athletes/Coaches/Academies/Events) + filter chips (Sport/State/Age Group/Position/More Filters) + **2-col athlete card grid w/ bookmark, 🏆, 🎥 counts + Follow** | **Not implemented** — rival variant B (rails) rendered instead | ❌ |
| Variant B: header chips + rails Popular Athletes / Coaches / Academies / Events + Opportunities rows | implemented (search + role shortcuts + `RailPersonCard`/`RailAcademyCard`/`RailEventCard` + opportunity rows) | ✅ |
| "Most Relevant" sort + result count | ❌ not implemented | ❌ |

### 4.4 Notifications (`4.14.43 PM2`) → `notifications/notifications_screen.dart`

| Design element | Flutter | Status |
|---|---|---|
| Category tabs All/People/Opportunities/Events/Mentions | ❌ missing — flat list | ❌ |
| Day grouping (Today/Yesterday/This Week/Earlier) + Mark all as read | ❌ list is grouped by date only via row metadata; **no Mark all as read control** | ⚠️ |
| Unread dot / Follow back action / thumbnail | rows rendered from provider; follow-back action absent | ⚠️ |

### 4.5 Leaderboard (`4.14.43 PM3`) → `talent_scout/leaderboard_screen.dart`

| Design element | Flutter | Status |
|---|---|---|
| Podium (2 silver / 1 gold / 3 bronze) + ranks 4–10 + sport chips | `_podiumCard(1 tall, 2, 3)` + rank list + sport chips — comment cites v3 S.6 | ✅ |
| Tabs Athletes/Coaches/Academies/Teams/Events | Athletes only (other tabs absent) | ⚠️ |
| India / All Age Groups dropdowns, Follow button per row | ❌ | ❌ |

### 4.6 Academies directory (`4.14.43 PM4`) → `academy/academy_directory_screen.dart`

Hero banner "Find the Right Academy", Academies/Coaches/Training segmented tabs, filter dropdown row (Location/Sport/Age/Facilities/Sort), rows w/ rating + View Details — implemented at `/academies` with search + chips + rating rows (`directory_list_template`); **distance + facilities icon strip simplified**. | ✅ partial |

### 4.7 Opportunities list (Play Store preview 3) → `opportunity/opportunity_list_screen.dart`

Tabs Trials/Tournaments/Scholarships/Sponsorships → Flutter uses chips **Scholarships/Sponsorships/Trials/Camps** (tournaments live in their own `/tournaments` directory). Cards: gradient hero + type badge + date + Apply Now ✅. | ⚠️ acceptable |

### 4.8 Create (`4.14.42 PM6`) → `social/create_screen.dart`

Design generic grid (8 tiles + Quick Post Options Photo/Video/Text/Poll/Achievement) → Flutter renders **role-config rows** (3 for athlete: Post/Achievement/Media — organizer-board style). **Find/Add Team, Add Academy, Add Coaching Service and Quick-Post strip are missing.** | ⚠️ |

### 4.9 More (`4.14.42 PM`) → `more/more_screen.dart`

Stathead (avatar+edit, View Profile, Posts/Connections/% complete) ✅ exact; rows My Profile / My Opportunities / My Activity / My Achievements & Certificates / Saved / Settings & Privacy / Help & Support / About SportX / Logout ✅ exact tinted icon style (code adds extra rows: Profile Completion, Leaderboard, Manage Sports, Registrations, Notifications, Messages — superset of design). | ✅ |

**Athlete score: 12 ✅ · 8 ⚠️ · 3 ❌**

---

## 5. Role 2 — Coach (`4.15.00 PM` board)

| # | Design screen | Flutter | Status |
|---|---|---|---|
| 1 | Home: greet 70%, Leaderboard (Coaches chip), Opportunities + Training tiles, feed | `coach_dashboard_screen.dart` — greet w/ real completion, RoleLine, `LeaderboardSectionV3`, feed, **+ Enrollment Requests & Recent Enquiries cards (extra, wired)**. **Missing the two quick tiles** (Opportunities / Academy & Training) | ⚠️ |
| 2 | Explore: Athletes/Coaches/Academies tabs + Featured Coaches rows (star rating, chips, Follow) | Shared `ExploreScreen` rails include Coaches rail w/ View (not Follow) | ⚠️ |
| 3 | Create rows: Create Post / Add Training Program / Create Event / Share Achievement / Add Opportunity / Upload Photo/Video / **Go Live/Webinar / Poll** | Config has 6 tiles exactly matching (incl. opportunity, media); **Go Live is `p2` and filtered OUT of the Create tab** (removed by `where != p2`); Poll never built | ⚠️ |
| 4 | Community (Suggested athletes + Join Groups) | Shared screen + coach discover links | ✅ |
| 5 | More rows: My Profile / My Training Programs / My Events / My Opportunities / Achievements / Saved / My Connections / My Activity / Notifications / Messages / Settings / Help / Logout | `role_config` rows match **all 13 design rows exactly** | ✅ |
| 6 | Coach Profile view (About: Coaching Level/Experience/Registration/Specialization/Age Group/Languages) | **New `/coach-profile` view built to board screen 6** — COACH cover banner, verified name, "{Sport} Coach · qualification", city, Edit Profile (yellow) + Share, About/Posts/Programs/Achievements tabs, detail rows from real model data (Experience, Coaching Level, Certifications, Languages). **profileRoute now points here** (was the edit form). Age Group row omitted — not in the coach model | ✅ |
| 7 | My Training Programs (Active/Drafts/Past + ₹ cards) | `/my-programs` `MyProgramsScreen` + `/post-program` | ✅ |
| 8 | Leaderboard (Coaches tab) | shared leaderboard | ⚠️ (tabs) |
| 9 | Academies / Training directory | `/academies`, `/programs` | ✅ |
| 10 | Notifications | shared (see 4.4) | ⚠️ |
| 11 | Messages (Chats/Requests tabs) | `/chat-list` | ⚠️ (Requests tab scope) |

**Coach score: 4 ✅ · 7 ⚠️**

---

## 6. Role 3 — Academy (`4.15.15 PM` board)

| # | Design screen | Flutter | Status |
|---|---|---|---|
| 1 | Home: greet 80%, Leaderboard (Academies), Opportunities + Find Talent tiles, feed | `academy_dashboard_screen.dart` — greet ✅, RoleLine ✅, Leaderboard ✅, **two QuickTileV3s matching design exactly** (Opportunities w/ 4 sub-tiles; Find Talent w/ Athletes/Coaches/Staff/More) + KPI cards (extra) | ✅ |
| 2 | Explore (Academies tab w/ View Details rows) | shared rails | ✅ |
| 3 | Create rows: Create Post / Add Training Program / Create Event-Trial / Post Scholarship / Add Facility / **Recruit Staff** / Upload / **Go Live / Create Poll** | Config: Post, Program, Event, Opportunity, Facility, Media, **+ Invite Athlete (replacement for Recruit Staff)**; Go Live & Poll absent | ⚠️ |
| 4 | Community | shared | ✅ |
| 5 | More rows incl. My Scholarships, My Facilities, My Staff, My Athletes, My Collaborations | Config matches design set (naming: "My Opportunities" instead of "My Scholarships") **+ Enquiries row (extra, wired)** | ✅ |
| 6 | Academy Profile (About/Programs/Facilities/Events/Reviews + Established) | `/academy-profile` `AcademyProfileScreen` — **restyled to board screen 6**: cover photo w/ ACADEMY fallback banner, overlapping logo avatar, verified name + `{meta}` + location, Edit Profile / Share buttons (`profileRoute` fixed — was landing on the edit form), Programs / Events / Trials links, About/detail sections. Established row omitted — not in the academy model | ✅ |
| 7 | Training Programs | `/my-programs` | ✅ |
| 8 | Events/Trials (Upcoming/Past + Registered counts) | `/my-trials` `TrialPostingScreen` flow | ✅ |
| 9 | Our Athletes (age-group chips U-8..U-19, rating rows, View Profile) | `/showcase-athletes` — shows athletes; **age-group filter chips cosmetic** | ⚠️ |
| 10 | Facilities (All/Grounds/Indoor/Gym + Add Facility + View Details) | `/facilities` `FacilityListScreen` + `/post-facility` | ✅ |
| 11 | Messages | `/chat-list` | ⚠️ |

**Academy score: 8 ✅ · 3 ⚠️**

---

## 7. Role 4 — Organizer (`4.15.31 PM` board)

| # | Design screen | Flutter | Status |
|---|---|---|---|
| 1 | Home: greet 75% + chevron, Upcoming Events featured card (date badge, Registrations Open, 320 Registered), 4 stat tiles (Events/Participants/Views/₹ Revenue), 4 quick tiles (Create Event/Manage Registrations/Promote Event/Analytics), feed | `organizer_dashboard_screen.dart` — **matches every block**: `GreetCardV3(chevron)` w/ real completion %, `OrgEventCard` + mini cards, 4 `OrgStatTile` in board colors (gold/blue/red/green), 4 `OrgQuickTile`, `V3FeedPreview` | ✅ |
| 2 | Explore: Events/Venues/Athletes/Coaches/Academies tabs + event rows View | `_OrganizerExplore` special layout — exactly this | ✅ |
| 3 | Create rows design (8: Event, Opportunity, Venue, Announcement, Upload, Go Live, Poll, Staff) | **4 tiles only: Event / Venue / Announcement / Staff** — Opportunity, Go Live, Poll, Upload removed **on product request (commented in `role_config.dart` org-create block)** | 📝 deliberate |
| 4 | Community | shared | ✅ |
| 5 | More rows (8 role rows) — exact match incl. Registrations & Participants, My Venues, My Team/Staff, My Analytics, My Collaborations | `role_config` — all 8 + shared tail, no About row (matches board) | ✅ |
| 6 | Organizer Profile (About/Events/Venues/Team/Media + Event Type/Sports/Established/Website) | `/organizer-profile` `OrganizerProfileViewScreen` | ✅ |
| 7 | My Events (Upcoming/Ongoing/Completed) | `/my-tournaments` + `/my-trials` | ✅ |
| 8 | Event Details & Management (Overview/Registrations/Schedule/Gallery, Manage Event) | `/organizer-event/:id` `OrganizerEventManagementScreen` | ✅ |
| 9 | Registrations (All/Approved/Pending counts, approve badges, Export List) | `/registration-management` + `/registrant-list` — approve/reject wired; **bulk checkboxes + Export List missing** | ⚠️ |
| 10 | Event Analytics (range chips, Views/Registrations/Revenue, chart, Top Sources) | `/organizer-analytics` — metrics + chart; **Top-Sources breakdown missing** | ⚠️ |
| 11 | Messages | shared | ⚠️ |

**Organizer score: 8 ✅ · 3 ⚠️ · 1 📝**

---

## 8. Role 5 — Talent Scout (`4.17.25 PM` board)

| # | Design screen | Flutter | Status |
|---|---|---|---|
| 1 | Home: greet "Find the next big talent" 65%, Top Talents podium (2/1/3 w/ crown), 4 quick tiles (Discover Talents/Attend Trials/Top Performers/Shortlisting), Upcoming Trials list, feed | `talent_scout_dashboard_screen.dart` — greet ✅ exact copy, podium ✅ exact 2-1-3, **4 `OrgQuickTile` tiles** (Discover Talents/Attend Trials/Top Performers/Shortlisting), trials list ✅ | ✅ |
| 2 | Explore: athlete rows (name, age/sport/state, ⭐ 4.8 (320), chips, View Profile) | `/scout-discovery` `TalentScoutAthleteDiscoveryScreen` — grid + filters | ✅ |
| 3 | Create rows design (9: Add Talent Shortlist / Create Talent Report / Add Scouting Opportunity / Add Event-Trial / Upload / Add Observation / Share Opportunity / **Poll / Go Live**) | Config 7 tiles in design order incl. **Create Talent Report** (`/talent-report`) and **Share Opportunity**; Poll/Go Live deliberately absent app-wide | ✅ (Poll/GoLive 📝) |
| 4 | Community | shared | ✅ |
| 5 | More rows — design: My Profile / My Shortlisted Talents / My Scouting Reports / My Opportunities / **My Events/Trials** / My Connections / … | Config matches incl. **"My Events / Trials"** → `/trials`; adds Discover Talents | ✅ |
| 6 | Scout Profile (About/Shortlisted/Reports/Activity + org/experience/languages) | `/scout-profile` `TalentScoutProfileScreen` **view split fixed**: SCOUT cover hero, verified name, "Talent Scout · city", Edit Profile (yellow) → `/scout-profile/edit` + Share, pinned About / Shortlisted Talents / Reports / Activity tabs; About = bio + detail rows (Organization, Affiliation, Sports Focus, Experience, Location, social links). **Rating/Languages/Availability rows deliberately omitted** — not in the scout profile model (no fabricated data). Inline edit form now lives at `/scout-profile/edit` (`TalentScoutProfileEditScreen`) | ✅ (rating/reviews omitted — data not modeled) |
| 7 | My Shortlisted Talents (All(48)/Under Review/Final tabs, status badges High Potential etc., **Compare Talents**) | `/scout-shortlist` + `/scout-compare` `CompareTalentsScreen` ✅ (status badges simplified) | ✅ |
| 8 | Talent Report (Overview/Performance/Potential/Notes, assessment sliders 8.5/10, Save to Shortlist) | `/talent-report` `TalentReportScreen` — sections present; **static data, no wizard** | ⚠️ |
| 9 | Scouting Opportunities (All/Trials/Scholarships/Camps + View Details) | `/opportunities` shared list (chips differ) | ⚠️ |
| 10 | Notifications (All/Talents/Opportunities/Messages) | shared (see 4.4) | ⚠️ |
| 11 | Messages | `/chat-list` | ⚠️ |

**Scout score: 10 ✅ · 1 ⚠️ (Talent Report static mock) — fixed this session**

---

## 9. Roles 6–7 — Sponsor / Admin

| Role | Design | Flutter | Status |
|---|---|---|---|
| Sponsor | **No dedicated board in `design_screeen_shot/`** — Play Store asset lists Sponsorships as content | Legacy role removed (410 SPONSOR_REMOVED); `/sponsor-dashboard → /opportunities`, sponsorships + scholarships = unified Opportunities module reachable by every role; all sponsor screens replicated as redirects | ✅ consistent w/ USERFLOW.md §13 |
| Admin | No design board provided | `/admin/login` + 2FA → `admin_web_layout` dashboard, users, approvals, moderation, reports, opportunities queue, analytics, settings — full module set exists (`features/admin/`, 20 screens) | ✅ (no design to diff) |

---

## 10. Missing / Gaps (prioritized)

1. **❌ Athlete Explore variant A** — the 2-col athlete-card grid with bookmark + trophy/video counts + Follow and filter chips (Sport/State/Age/Position/More Filters) is not implemented anywhere.
2. **❌ Notifications design** — no category tabs (All/People/Opportunities/Events/Mentions), no day-grouped sections with "Mark all as read", no thumbnails.
3. **❌ Leaderboard extra tabs** (Coaches/Academies/Teams/Events) + country/age-group filters + per-row Follow.
4. **❌ Poll create tile + Go Live stream** — appears in 4 of 5 boards; only a dead `/coach-go-live` screen remains and it's filtered out of the Create tab.
5. **⚠️ Profile Connections strip** on own profile (avatar row + "+12 More").
6. **⚠️ Organizer bulk registration actions** (multi-select + Export List) and **analytics Top-Sources breakdown**.
7. **⚠️ Coach "Share Achievement" / "Create Talent Report" / "Share Opportunity" create rows** (scout & coach boards).
8. **⚠️ About-card detail rows** (College, Interests, Playing Role/Level/Experience) — backend fields not surfaced.

## 11. Deliberate Deviations (documented in code — do **not** raise as bugs)

| Deviation | Where documented |
|---|---|
| Organizer create tiles reduced to 4 (no Opportunity/Go Live/Poll/Upload) | `role_config.dart` org-create comment |
| Organizer More board stops at Help & Support (no About row) | `role_config.dart` comment |
| Recommended-athlete CTA is **View** (not Follow) | fixes USERFLOW.md §12.3 "Follow just navigates" |
| Sponsor role screens removed → unified `/opportunities` | `router.dart` 410-SPONSOR_REMOVED comments |
| Leaderboard Demo `performance_stats` hidden when backend empty | `view_profile_screen.dart` comment (avoid fake UI) |

## 12. Design-side Inconsistencies (report to designer)

1. Play Store preview 2 stat strip (Followers · Achievements · Trials Attended) contradicts every board's stathead (Posts · Connections · Sports · Achievements · % Complete) — app follows the boards.
2. Generic Create mock (2-col grid, 8 tiles) conflicts with all 5 role boards (vertical rows, role-specific sets) — app follows the boards.
3. Explore has two competing mockups (grid variant vs rail variant) — app shipped the rails variant.

## 13. Recommended Fix Order

1. Notifications screen upgrade (tabs + day groups + mark-all-read) — affects all 5 boards.
2. Athlete Explore grid variant behind the category chips.
3. Scout Create tab: add Talent Report + Share Opportunity rows; surface `/talent-report` route (it exists but has no inbound tile).
4. Leaderboard secondary tabs + row Follow.
5. Profile Connections strip + About-extra rows (needs API fields: college, interests, playing_role).
6. Un-hide coach **Go Live** tile (or delete the orphan route).

---

*Verified files: `core/role_config.dart`, `core/router.dart`, `shared/presentation/widgets/home_kit.dart`, `home/home_screen.dart`, `home/explore_screen.dart`, `social/community_screen.dart`, `social/create_screen.dart`, `more/more_screen.dart`, `athlete/profile_screen.dart`, `coach/coach_dashboard_screen.dart`, `academy/academy_dashboard_screen.dart`, `organizer/organizer_dashboard_screen.dart`, `talent_scout/*`, `opportunity/opportunity_list_screen.dart`, `notifications/notifications_screen.dart`, `shared/view_profile_screen.dart`.*
