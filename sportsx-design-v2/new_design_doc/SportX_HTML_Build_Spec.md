# SportX – HTML Build Spec (Design → Code Blueprint)

Use this file to rebuild all **44 screens** (4 roles × 11 screens) in plain HTML/CSS/JS.
It is organised in build order: **tokens → shell → components → screens → data → JS**.
Every screen below is described as a stack of **named components** (defined once in §4), so you only write each component once and reuse it.

> Colours/sizes are **visual estimates from the mockups**. Adjust if you have the Figma file.

---

## 0. Build Strategy

| Step | What to do |
|---|---|
| 1 | Copy the `:root` tokens (§1) into `styles.css` |
| 2 | Build the phone shell + bottom nav (§3) |
| 3 | Build each component once (§4) with the class names given |
| 4 | Assemble screens (§5–§8) by stacking components in the order listed |
| 5 | Feed data from the JSON in §9 (or hard-code) |
| 6 | Add the tiny JS router in §10 (role switcher + screen switcher) |

**Suggested file structure**
```
sportx/
├── index.html          # role + screen switcher, phone frame
├── styles.css          # tokens + components
├── app.js              # router + render helpers
├── data.js             # JSON from §9
└── assets/             # images (use placeholders/gradients if none)
```

**Naming convention:** BEM-lite → `.card`, `.card__title`, `.card--yellow`. Screen containers: `<section class="screen" id="coach-home">`.

---

## 1. Design Tokens

```css
:root{
  /* Brand */
  --yellow:#FFC107;          /* primary buttons, active tab/chip, progress */
  --yellow-600:#F5B400;      /* pressed */
  --yellow-100:#FFF6DA;      /* tint cards (Opportunities) */
  --yellow-50:#FFFBEE;       /* profile-completion card bg */

  /* Neutrals */
  --ink:#111827;             /* headings */
  --text:#374151;            /* body */
  --muted:#6B7280;           /* secondary text, timestamps */
  --line:#E5E7EB;            /* dividers, card borders */
  --bg:#FFFFFF;              /* screen background */
  --bg-soft:#F5F6FA;         /* search bars, inactive chips */

  /* Semantic */
  --blue:#2F80ED;            /* verified tick, links, blue icons */
  --blue-100:#EAF2FF;        /* tint card (Find Academies / Find Talent) */
  --green:#22A05B;           /* Approved / Registrations Open */
  --green-100:#E6F6EC;
  --orange:#F59E0B;          /* Pending / Under Review */
  --orange-100:#FFF1D6;
  --red:#E53935;             /* Logout, live, event icon */
  --purple:#8B5CF6;
  --pink:#F43F5E;

  /* Radius */
  --r-sm:8px; --r-md:12px; --r-lg:16px; --r-xl:20px; --r-pill:999px;

  /* Shadow */
  --sh-card:0 2px 8px rgba(17,24,39,.06);
  --sh-fab:0 6px 16px rgba(255,193,7,.45);

  /* Spacing (4pt scale) */
  --s1:4px; --s2:8px; --s3:12px; --s4:16px; --s5:20px; --s6:24px;

  /* Layout */
  --phone-w:390px; --phone-h:844px;
  --nav-h:72px; --topbar-h:56px; --pad-x:16px;

  font-family:'Inter','Poppins',system-ui,-apple-system,'Segoe UI',sans-serif;
}
```

### Typography scale
| Token | Size / Weight | Used for |
|---|---|---|
| `.t-logo` | 22px / 800 | "Sport**X**" wordmark (X = `--yellow`) |
| `.t-h1` | 18px / 700 | Screen title (Create, Community, More) |
| `.t-h2` | 16px / 700 | Section titles ("Featured Coaches", "Suggested for You") |
| `.t-name` | 14–15px / 700 | Card titles, person names |
| `.t-body` | 13px / 400 | Descriptions |
| `.t-meta` | 11–12px / 400–500, `--muted` | Sub-info, timestamps, chip text |
| `.t-stat` | 20px / 800 | Big numbers (KPIs, points) |

---

## 2. Icon Map (use Lucide / Feather / Material)

| Where | Icon |
|---|---|
| Nav Home / Explore / Create / Community / More | `home` / `compass` / `plus` / `users` / `layout-grid` |
| Top bar | `bell`, `chevron-left`, `share-2`, `filter/sliders-horizontal`, `more-vertical`, `clock/history`, `download` (export), `pencil` (edit), `message-square` |
| Verified | `badge-check` (fill `--blue`) |
| Rating | `star` (fill `--yellow`) |
| Location | `map-pin` |
| Post actions | `heart` (red when liked), `message-circle`, `send/share`, `bookmark` |
| Leaderboard | `crown`, `trophy` |
| Search | `search` |
| Menu rows | `user`, `calendar`, `award`, `heart-handshake`, `bookmark`, `users`, `activity`, `bell`, `message-square`, `settings`, `help-circle`, `log-out` |

---

## 3. Phone Shell & Bottom Navigation

### 3.1 Shell
```html
<div class="phone">                       <!-- 390 × 844, radius 44, border 8px #111 -->
  <div class="statusbar">9:41 … signal wifi battery</div>   <!-- 44px -->
  <main class="screen-body"> … screen content … </main>     <!-- scrollable -->
  <nav class="bottomnav"> … </nav>                          <!-- 72px, sticky bottom -->
</div>
```
```css
.phone{width:var(--phone-w);height:var(--phone-h);background:var(--bg);border-radius:44px;
  border:8px solid #111;overflow:hidden;position:relative;display:flex;flex-direction:column}
.statusbar{height:44px;display:flex;justify-content:space-between;align-items:center;padding:0 24px;font-weight:600;font-size:14px}
.screen-body{flex:1;overflow-y:auto;padding:0 var(--pad-x) calc(var(--nav-h) + 12px)}
```

### 3.2 Bottom nav (fixed, white, top border `--line`)
```html
<nav class="bottomnav">
  <a class="nav-item is-active"><i data-lucide="home"></i><span>Home</span></a>
  <a class="nav-item"><i data-lucide="compass"></i><span>Explore</span></a>
  <a class="nav-fab"><i data-lucide="plus"></i><span>Create</span></a>
  <a class="nav-item"><i data-lucide="users"></i><span>Community</span></a>
  <a class="nav-item"><i data-lucide="layout-grid"></i><span>More</span></a>
</nav>
```
```css
.bottomnav{position:absolute;bottom:0;left:0;right:0;height:var(--nav-h);background:#fff;border-top:1px solid var(--line);
  display:grid;grid-template-columns:repeat(5,1fr);align-items:center;text-align:center}
.nav-item{font-size:11px;color:var(--muted);display:flex;flex-direction:column;align-items:center;gap:2px}
.nav-item.is-active{color:var(--yellow)}
.nav-fab i{width:56px;height:56px;border-radius:50%;background:var(--yellow);color:#fff;display:grid;place-items:center;
  margin-top:-28px;box-shadow:var(--sh-fab)}          /* raised centre button */
```
Active-tab rule: Home screen → Home active; Explore-type screens → Explore active; Create → Create label yellow; Community → Community active; More → More active.
> Note: inner/detail screens (profile, programs, etc.) keep the same bar (the mockups show it hidden on some – hide with `.screen--no-nav` if you prefer).

---

## 4. Component Library (build once, reuse)

### C1 · `TopBar--main` (Home, Explore)
`[SportX logo]  ……  [bell] [avatar 32px circle]` — height 56px, padding 0 16px.

### C2 · `TopBar--inner` (all detail screens)
`[‹ back]  [centered .t-h1 title]  [right action icon(s)]` — right slot varies (see screens). Left/right slots are 32px wide so the title stays centred.

### C3 · `ProfileCompletionCard`
```html
<div class="pcc">
  <img class="avatar-40">
  <div class="pcc__body"><b>Hi, Coach Rohit!</b><small>Complete your profile to get more opportunities</small>
    <div class="progress"><i style="width:70%"></i></div></div>
  <div class="pcc__pct">70% ›</div>
</div>
```
`bg:--yellow-50; radius:16; padding:12; border:1px solid #FBE6A6`. Progress track `#F1E3B0`, fill `--yellow`, height 4px, radius pill. Percentage bold 16px right-aligned with chevron.

### C4 · `SectionHeader`
`[icon?] Title(.t-h2) [pill tag?] …… [View All ›](.link, --blue or --ink)` — margin 16px 0 8px.

### C5 · `Podium`
Three columns (order **2 – 1 – 3**), centre one raised 12px and slightly larger (avatar 64 vs 52). Avatar circle with border 3px (gold/silver/bronze) + small rank badge (circle 20px, yellow, top-left). Under it: name (12px bold, 1 line ellipsis) + points `2,450 pts` (11px muted).

### C6 · `ShortcutCard` (2-up grid, gap 12)
`grid-template-columns:1fr 1fr; card radius 16; padding 12; icon 40px; title 13px bold; 2-line subtitle 11px muted` — variant `--yellow` (trophy) and `--blue` (building). Used in Coach/Academy Home.
`QuickActionTile` (Organizer/Scout Home): 4-up grid, each = tinted rounded square 56px with icon + 11px label below.

### C7 · `Tabs--underline` (feed tabs, section tabs)
Horizontal scroll, gap 20px, 13px. Active = `--ink` bold + 2px yellow underline; inactive = `--muted`.

### C8 · `Tabs--pill` (Network/Groups/Events, Chats/Requests, status tabs)
Container `bg:--bg-soft; radius:12; padding:3`. Each tab flex:1, centred, 13px. Active = `bg:--yellow-100` (or solid `--yellow`) + bold ink text, radius 10. Inactive = muted.
`Tabs--text` (Athletes|Coaches|Academies|…): scrollable text with active tab having yellow-tint pill background.

### C9 · `Chip`
`height 28; padding 0 12; radius pill; font 12; bg --bg-soft; color --text`. Active: `bg --yellow; color #111; font-weight 600`. Sport chips may have a leading 14px icon. Tag chips inside cards: smaller (10–11px), border `--line`, bg #F3F4F6.

### C10 · `SearchBar`
`height 44; radius 14; bg --bg-soft; padding 0 14; search icon left; placeholder 13px muted; optional filter button (40×40, radius 12, border) on right`.

### C11 · `PostCard`
```
[avatar 40] [Name ✔] [⋮]
            [role • city • 2h ago]
[text 13px + #hashtags in --blue]
[media: full width, radius 12  (collage: 2/3 + 1/3 stacked)]
[❤ 256   💬 18   ↗ 12                     🔖]
```
Card: no shadow, bottom border `--line`, padding 12 0.

### C12 · `EntityCard` (Explore list – coach / athlete / academy)
```
┌───────────────────────────────────────────┐
│[photo 84×92 r12] Name ✔          ★4.8 (320)│
│                  Sport • Coach              │
│                  📍 Ahmedabad, Gujarat      │
│                  [tag][tag]      [Follow]   │
└───────────────────────────────────────────┘
```
Card: bg white, radius 16, padding 10, gap 10, shadow `--sh-card`. Button: `height 30; padding 0 16; radius 10; bg --yellow; font 12 bold`. Variants: button text = **Follow / View Details / View Profile / View**. Academy variant has a **larger photo (100×100)** and a distance line `📍 Motera, Ahmedabad • 2.5 km`.

### C13 · `ProgramCard` / `OpportunityCard` / `FacilityCard`
Same layout as C12: thumbnail left (84×72), title 14 bold, chips row (age • duration • mode), price (bold ink) on left-bottom, **View Details** yellow button bottom-right. Opportunity adds a green `Registrations Open` badge and 📍/📅 lines.

### C14 · `EventCard` (Explore–Organizer, My Events, Academy Events)
```
[DateBlock][image 76×64][ Title (bold) ⋮ ]
[  NOV     ][          ][ 📍 city / sport • age ]
[ 20-22    ][          ][ [Registrations Open] ] [View]
[ 2026     ]
```
`DateBlock`: 48px wide, stacked `MONTH` (10px yellow bold) / `20-22` (16px bold) / `2026` (10px muted). Registered count shown as `📍 320 Registered` or coloured text.

### C15 · `PersonRow` (Community suggestions, Athletes list)
`[avatar 44] [Name bold / sub 12 muted] …… [Follow]` (Follow = yellow button 28h, radius 8, padding 0 14). Row height ~60, divider optional.

### C16 · `GroupRow`
`[thumb 44 r10] [name bold / "2.4K members" muted] …… [Join]` — Join is a **grey** small button (bg `--bg-soft`, radius 8).

### C17 · `MenuRow` (More)
`[icon 20 muted] [label 14] …… [chevron]` height 48; groups separated by 8px gap; Logout row: icon+label `--red`, no chevron.
`ProfileSummary` at top: avatar 48 + name ✔ + role (muted) + `View Profile ›` (blue link 12px).

### C18 · `CreateRow`
`[icon tile 44×44, radius 12, solid colour, white icon] [title 14 bold / subtitle 12 muted]` inside a card `bg --bg-soft or white, radius 14, padding 12`, vertical gap 10. Icon colours: purple `#8B5CF6`, green `#22A05B`, red `#E53935`, blue `#2F80ED`, pink `#F43F5E`.

### C19 · `ChatRow`
`[avatar 44] [name bold / last msg 12 muted 1-line] …… [time 11 muted / unread badge (yellow circle 18px, bold 10px)]` — height 64.

### C20 · `NotificationRow`
`[avatar or coloured icon tile 40] [bold text 13 / time 11 muted]`; group labels "Today" / "Yesterday" (14 bold, margin 12 0 4). Scout variant adds a leading ☐ checkbox or unread dot.

### C21 · `StatusBadge`
`padding 3 10; radius 8; font 11 bold` — `Approved` (bg green-100 / text green) · `Pending` (orange-100 / orange) · `High Potential` (green) · `Good Potential` (green light) · `Under Review` (orange) · `Registrations Open` (green pill with dot).

### C22 · `Button`
| Variant | Style |
|---|---|
| `.btn-primary` | bg `--yellow`, text #111, bold, radius 12, height 44 |
| `.btn-outline` | border 1px `--line`, bg white, icon + label, radius 12 |
| `.btn-block` | full width, pinned at bottom (Manage Event, Export List, Compare Talents, Save to Shortlist) — margin 12 16, above nav |
| `.btn-sm` | height 30, font 12 |

### C23 · `ProfileHeader`
Cover image height 150 (radius 0 top) + ⋮ button (top-right, 32px white/translucent circle). Avatar 80px circle, 3px white border, overlaps cover by 40px, left-aligned at 16px. Below: Name ✔ (18 bold) → role line (13 muted) → 📍 location. Action row: two buttons 50/50 (`btn-primary` + `btn-outline`). Then `Tabs--underline` (About active), About text, then `DetailList`.
`ProfileStatsRow` (Organizer): 3 equal columns, big number (18 bold) + label (11 muted).

### C24 · `DetailList`
Each row: `[icon 18 muted] [label 13 muted, fixed width 120] [value 13 ink]` — row height 36.

### C25 · `RankTable` (Leaderboard)
Header row (muted 11): `# | Coach | Sport | Points`. Body rows 44px: rank number, avatar 28 + name, sport, points right-aligned bold.

### C26 · `KpiTile` (Analytics)
2×2 grid, gap 10; tile radius 12, border `--line`, padding 10: label (11 muted) → value (`.t-stat`) → delta (`↑42%` 11 green, right).

### C27 · `LineChart`
Card with title, SVG polyline (stroke `--blue`, area fill light blue), tooltip bubble at peak (white, shadow, "320 / 20 Nov"), x-labels beneath. Build with inline `<svg>` or Chart.js.

### C28 · `BarRow` (Top Sources)
`[icon] [label] [track ——— fill(--yellow)] [42%]` — track 6px high, bg `--bg-soft`.

### C29 · `ScoreBar` (Talent Report)
`[label] [track (yellow fill) ] [8.5/10]` — track 8px, radius pill; label 13 left, score right bold.

### C30 · `ListWithCheckbox` (Registrations, Shortlist)
`[☐ 18px] [avatar 40] [name bold / sub muted] …… [StatusBadge]`.

---

## 5. Screen Recipes – COACH

Screen container width = 390. Body padding-x = 16. Stack top → bottom.

| ID | Screen | Nav active |
|---|---|---|
| `coach-home` | Home | Home |
| `coach-explore` | Explore | Explore |
| `coach-create` | Create | Create |
| `coach-community` | Community | Community |
| `coach-more` | More | More |
| `coach-profile` | Coach Profile | – |
| `coach-programs` | Training Programs | – |
| `coach-leaderboard` | Leaderboard (Coaches) | – |
| `coach-academies` | Academies / Training | – |
| `coach-notifications` | Notifications | – |
| `coach-messages` | Messages | – |

### coach-home
1. `TopBar--main`
2. `ProfileCompletionCard` — "Hi, Coach Rohit!" · "Complete your profile to get more opportunities" · **70%**
3. `SectionHeader` — 👑 "Leaderboard" + yellow pill **Coaches** + "View All ›"
4. `Podium` — Rohit Mehta 2,450 · Ankit Sharma 2,120 · Neha Patel 1,950
5. `ShortcutCard ×2` — (yellow, trophy) **Opportunities** "Trials · Tournaments / Scholarships · Sponsorships"; (blue, building) **Academy, Coach & Training Centre** "Find Academies · Athletes / Training Centres"
6. `Tabs--underline` — For You*, Following, Athletes, Coaches, Academies, Events
7. `PostCard` — Rohit Mehta ✔ "Cricket Coach • Ahmedabad • 2h ago" · text "Today's U-14 batting session! Focus, discipline and small improvements every day. #YouthDevelopment" · collage (1 big + 2 small) · 256 / 18 / 12
8. `BottomNav`

### coach-explore
1. `TopBar--main`
2. `SearchBar` "Search athletes, coaches, academies…"
3. `Tabs--text` — Athletes, **Coaches***, Academies, Training Centres
4. `Chip` row — **All Sports***, Cricket, Football, Badminton…
5. `SectionHeader` "Featured Coaches" + "See All"
6. `EntityCard × 4` (button **Follow**) — data §9 `coaches`
7. `BottomNav`

### coach-create
1. `TopBar--inner` title "Create" (no right icon)
2. `CreateRow × 8` — Create Post (purple) · Add Training Program (green) · Create Event (red) · Share Achievement (green) · Add Opportunity (blue) · Upload Photo / Video (pink) · Go Live / Webinar (purple) · Poll (blue) — subtitles in §9 `createMenus.coach`
3. `BottomNav` (Create highlighted)

### coach-community
1. `TopBar--inner` "Community" + right icon `message-circle`
2. `Tabs--pill` — **Network***, Groups, Events
3. `SearchBar` "Search people, groups, events…"
4. `SectionHeader` "Suggested for You"
5. `Tabs--text` — **Athletes***, Coaches, Academies
6. `PersonRow × 4` (Follow)
7. `SectionHeader` "Join Groups" + "See All"
8. `GroupRow × 3` (Join)
9. `BottomNav` (Community active)

### coach-more
1. Header row: title "More" left, avatar right
2. `ProfileSummary` — Rohit Mehta ✔ · Cricket Coach · View Profile ›
3. `MenuRow` group A (8): My Profile, My Training Programs, My Events, My Opportunities, My Achievements, Saved, My Connections, My Activity
4. group B (2): Notifications, Messages
5. group C (2): Settings & Privacy, Help & Support
6. `MenuRow--danger` Logout
7. `BottomNav` (More active)

### coach-profile
1. `TopBar--inner` "Coach Profile" + right: bell, share
2. `ProfileHeader` — cover "COACH" team photo · Rohit Mehta ✔ · "Cricket Coach • BCCI Level 2" · 📍 Ahmedabad, Gujarat · [**Follow**][Message]
3. `Tabs--underline` — **About***, Posts, Programs, Achievements
4. "About" heading + paragraph "Professional cricket coach with 12+ years of experience. Specialized in youth development, batting technique and fitness training."
5. `DetailList` — Coaching Level: BCCI Level 2 · Experience: 12+ Years · Specialization: Batting, Fielding, Fitness · Age Group: U-10, U-14, U-19, Open · Languages: Hindi, English, Gujarati

### coach-programs
1. `TopBar--inner` "My Training Programs" + right `filter`
2. `Tabs--pill` — **Active***, Drafts, Past
3. Right-aligned `btn-primary btn-sm` "+ Add Program"
4. `ProgramCard × 4` — data `programs.coach`

### coach-leaderboard
1. `TopBar--inner` "Leaderboard" + right `trophy`
2. `Tabs--text` — Athletes, **Coaches***, Academies, Teams
3. `Chip` row — All Sports*, Cricket, Football, Badminton
4. `Podium` (rank 1 centre highlighted, yellow-tinted column background)
5. `RankTable` rows 4–10 (data `leaderboard.coachRows`)

### coach-academies
1. `TopBar--inner` "Academies" + right **location dropdown pill** ("📍 Ahmedabad ⌄")
2. `SearchBar` "Search academies, coaches or training…"
3. `Tabs--text` — **Academies***, Coaches, Training Centres
4. `Chip` row — All Sports*, Location, Age Group, filter icon
5. `EntityCard--academy × 4` (button **View Details**) — data `academies`

### coach-notifications
1. `TopBar--inner` "Notifications" + right `clock`
2. `Tabs--pill` — **All***, People, Programs, Events
3. Label "Today" → `NotificationRow × 4`
4. Label "Yesterday" → `NotificationRow × 3`

### coach-messages
1. `TopBar--inner` "Messages" + right `sliders`
2. `Tabs--pill` — **Chats***, Requests
3. `SearchBar` "Search messages…"
4. `ChatRow × 7`

---

## 6. Screen Recipes – ACADEMY

| ID | Screen |
|---|---|
| `acad-home` · `acad-explore` · `acad-create` · `acad-community` · `acad-more` | Main tabs |
| `acad-profile` · `acad-programs` · `acad-events` · `acad-athletes` · `acad-facilities` · `acad-messages` | Detail screens |

### acad-home
1. `TopBar--main`
2. `ProfileCompletionCard` — academy logo · "Hi, Motera Cricket Academy!" · "Complete your profile to reach more athletes" · **80%**
3. `SectionHeader` 👑 Leaderboard + pill **Academies** + View All ›
4. `Podium` — Motera Cricket Academy 4,520 · Ahmedabad Football Acad. 3,980 · Gujarat Badminton Acad. 3,450 (avatars are square-ish academy photos in circles)
5. `ShortcutCard ×2` — **Opportunities** (Trials · Tournaments / Scholarships · Sponsorships) + **Find Talent** ("Connect with Athletes, Coaches, Staff, Collaborations")
6. `Tabs--underline` — For You*, Following, Athletes, Coaches, Academies, Events
7. `PostCard` — Motera Cricket Academy ✔ 2h ago · "New batch registrations open! U-14 and U-16 cricket training program #Cricket #Training #Ahmedabad" · wide team photo · 256/18/12 · extra ✕ icon beside ⋮

### acad-explore
`TopBar--main` → `SearchBar` → `Tabs--text` (Athletes, Coaches, **Academies***, Training Centres) → `Chip` row (All Sports*, Cricket, Football, Badminton) → `EntityCard--academy × 4` (**View Details**): Motera Cricket Academy, Ahmedabad Football Academy, Gujarat Badminton Academy, AquaSport Swimming Academy.

### acad-create
`TopBar--inner` "Create" → `CreateRow × 9`: Create Post · Add Training Program · Create Event / Trial · Post Scholarship / Opportunity · Add Facility / Venue · Recruit Staff · Upload Photos / Videos · Go Live / Webinar · Create Poll.

### acad-community
`TopBar--inner` "Community" → `Tabs--pill` (Network*, Groups, Events) → `SearchBar` → "Suggested for You" → `Tabs--text` (Athletes*, Coaches, Academies) → `PersonRow × 5` → "Join Groups" → `GroupRow × 3`.

### acad-more
Header → `ProfileSummary` (Motera Cricket Academy ✔, Sports Academy) → menu A (10): My Profile, My Training Programs, My Events / Trials, My Scholarships, My Facilities / Venues, My Staff, My Athletes, My Collaborations, Saved, My Activity → B: Notifications, Messages → C: Settings & Privacy, Help & Support → Logout.

### acad-profile
`ProfileHeader` (cover = building photo, avatar = logo) · Name ✔ · `★4.8 (320 Reviews)` · "Sports Academy • Cricket" · 📍 Ahmedabad, Gujarat · [**Follow**][Message] → `Tabs--underline` (**About***, Programs, Facilities, Events, Reviews) → About paragraph → `DetailList`: Sports: Cricket · Age Group: U-8 to U-19 · Coaching Staff: 12+ Coaches · Facilities: 3 Grounds, Indoor Nets, Gym · Location: Ahmedabad, Gujarat · Established: 2018.

### acad-programs
`TopBar--inner` "Training Programs" → `Tabs--pill` (Active*, Drafts, Past) → "+ Add Program" → `ProgramCard × 5` (data `programs.academy`).

### acad-events
`TopBar--inner` "Events / Trials" → `Tabs--pill` (Upcoming*, Past) → "+ Create Event" → `EventCard × 4` (thumbnail-only variant without DateBlock; date in text; registered count in yellow) → data `events.academy`.

### acad-athletes
`TopBar--inner` "Our Athletes" → `Tabs--underline` age groups (All*, U-8, U-10, U-14, U-16, U-19) → `SearchBar` + filter button → `EntityCard--athlete × 5` (photo 56 circle-ish, name, `U-16 • Batsman`, ★ rating (count), button **View Profile**).

### acad-facilities
`TopBar--inner` "Facilities" → `Tabs--underline` (All*, Grounds, Indoor, Gym, Other) → "+ Add Facility" → `FacilityCard × 5` (Main Cricket Ground, Indoor Nets, Fitness Centre, Classroom, Changing Rooms) with **View Details**.

### acad-messages
Same as `coach-messages` with academy data (`chats.academy`).

---

## 7. Screen Recipes – ORGANIZER

| ID | Screen |
|---|---|
| `org-home` · `org-explore` · `org-create` · `org-community` · `org-more` | Main tabs |
| `org-profile` · `org-myevents` · `org-eventdetail` · `org-registrations` · `org-analytics` · `org-messages` | Detail screens |

### org-home
1. `TopBar--main`
2. `ProfileCompletionCard` — logo (RAJ, black circle) · "Hi, Raj Sports Events!" · "Complete your profile to reach more athletes" · **75%**
3. `SectionHeader` "Upcoming Events (Your Events)" + View All ›
4. **Featured event card** — image left (96×96) · date badge (NOV 20-22 2026) · "Gujarat Youth Football Championship" · 📍 Ahmedabad, Gujarat · green badge **Registrations Open** · "320 Registered" · ⋮
5. **Stats row** (4 equal tiles, radius 12, `bg --bg-soft`, 12px padding): calendar-icon "Events" · **320+** Participants · **12K+** Views · **₹2.4K** Revenue
6. `QuickActionTile × 4` — Create Event (red icon, bg pink-tint) · Manage Registrations (blue) · Promote Event (red megaphone) · Analytics (green bars)
7. `Tabs--underline` — For You*, Following, Athletes, Coaches, Academies, Events
8. `PostCard` — Raj Sports Events ✔ · 2h ago · "Registrations are live! Gujarat Youth Football Championship 2026 🔶" · dark banner with title text + yellow "REGISTER NOW" button · 256/18/12

### org-explore
`TopBar--main` → `SearchBar` "Search events, venues, athletes, coaches, academies…" → `Tabs--text` (**Events***, Venues, Athletes, Coaches, Academies) → `Chip` row (All Sports*, Cricket, Football, Basketball, Br…) → `EventCard × 5` (with **DateBlock**, ⋮, **View**) → data `events.explore`.

### org-create
`TopBar--inner` "Create" → `CreateRow × 8`: Create Event (red) · Create Opportunity (yellow/orange) · Add Venue (green) · Post Announcement (purple) · Upload Photo / Video (pink) · Go Live / Stream (red) · Create Poll (blue) · Add Staff / Organiser (green).

### org-community
Same as coach-community; sub-chips: Athletes*, Coaches, Academies, **Organizers**; `PersonRow × 5`; heading **"Popular Groups"**; `GroupRow × 3`.

### org-more
Profile summary (logo, Raj Sports Events ✔, Event Organizer) → menu A (10): My Profile, My Events, Registrations & Participants, My Opportunities, My Venues, My Team / Staff, My Analytics, My Collaborations, Saved, My Activity → Notifications, Messages → Settings & Privacy, Help & Support → Logout.

### org-profile
`ProfileHeader` (cover = stage/crowd; avatar = RAJ logo with small camera badge bottom-right) → Name ✔ → "Event Organizer" → 📍 Ahmedabad, Gujarat → `ProfileStatsRow` (**12** Events · **3.4K** Participants · **15** Collaborations) → [**Edit Profile**][Share] → `Tabs--underline` (**About***, Events, Venues, Team, Media) → About paragraph → `DetailList`: Event Type: Tournaments, Trials, Camps · Sports: Cricket, Football, Throwball, Badminton · Location: Ahmedabad, Gujarat · Established: 2023 · Website: www.rajsportsevents.in.

### org-myevents
`TopBar--inner` "My Events" + `history` → `Tabs--pill` (**Upcoming***, Ongoing, Completed) → "+ Create Event" → `EventCard × 4` (DateBlock, image, title, ⋮, `📍 320 Registered`, **View**).

### org-eventdetail
1. `TopBar--inner` "Event Details & Management" + right **Edit** (pencil + text)
2. Hero image (full width, height 170) + ⋮
3. DateBlock + title "Gujarat Youth Football Championship" + 📍 Ahmedabad, Gujarat
4. Meta row: ⚽ Football • U-14, U-17 + green **Registrations Open**
5. `Tabs--underline` — **Overview***, Registrations, Schedule, Gallery
6. Info rows (icon + text): 📅 20 – 22 Nov 2026 · 📍 Ahmedabad, Gujarat · 👥 320 Registered (500 slots) + progress bar (64%) · ₹500 / team · 🏢 Raj Sports Events
7. Two `btn-outline` side by side: **Share**, **Promote**
8. `btn-primary btn-block` **Manage Event**

### org-registrations
1. `TopBar--inner` "Registrations" + `download`
2. `Tabs--pill` — **All (320)***, Approved (280), Pending (30)
3. `SearchBar` "Search participants…" + filter button
4. `ListWithCheckbox × 7` with `StatusBadge`
5. `btn-primary btn-block` **Export List**

### org-analytics
1. `TopBar--inner` "Event Analytics" + `chevron-down`
2. Full-width **select** styled as bordered box: "Gujarat Youth Football Championship ⌄"
3. `Tabs--pill` range — 7D, **30D***, 3M, 1Y
4. `KpiTile ×4` — Views 12,450 ↑42% · Registrations 320 ↑28% · Revenue ₹1,60,000 ↑35% · Inquiries 86 ↑22%
5. Card "Registrations" → `LineChart` (x: 1 Nov, 10 Nov, 20 Nov, 30 Nov; tooltip "320 / 20 Nov")
6. Card "Top Sources" → `BarRow × 4` — Direct 42% · Instagram 28% · WhatsApp 18% · Search 12%

### org-messages
`TopBar--inner` "Messages" → Chats*/Requests → SearchBar → `ChatRow × 7` (`chats.organizer`).

---

## 8. Screen Recipes – TALENT SCOUT

| ID | Screen |
|---|---|
| `scout-home` · `scout-explore` · `scout-create` · `scout-community` · `scout-more` | Main tabs |
| `scout-profile` · `scout-shortlist` · `scout-report` · `scout-opps` · `scout-notifications` · `scout-messages` | Detail screens |

### scout-home
1. `TopBar--main`
2. `ProfileCompletionCard` — avatar · "Hi, Sameer!" · "Find the next big talent" · **65%**
3. `SectionHeader` "Top Talents (This Week)" + View All ›
4. `Podium` — Aarav Patel (Cricket) 2,450 · Riya Shah (Throwball) 2,180 · Karan Mehta (Football) 1,960 — sport shown under name, points below
5. `QuickActionTile × 4` — Discover Talents (yellow) · Attend Trials (red calendar) · Top Performers (green trophy) · Shortlisting (bookmark)
6. `SectionHeader` "Upcoming Trials & Events" + View All ›
7. Event mini-card — image left · **Gujarat Youth Football Trial** · Ahmedabad, Gujarat · 20-22 Nov 2026 · green **Registrations Open** · ⋮
8. `Tabs--underline` — For You*, Following, Athletes, Events, Trials
9. `PostCard` — Aarav Patel ✔ "U-17 Football • 2h ago" · "Match highlights from State Level Tournament. ⚽" · **video thumbnail with ▶ overlay** (16:9)

### scout-explore
`TopBar--main` → `SearchBar` "Search athletes, coaches, academies, events…" → `Tabs--text` (**Athletes***, Coaches, Academies, Events) → `Chip` row (All Sports*, Cricket, Football, Badminton + filter icon button) → `EntityCard--athlete × 5` (name ✔ + ⋮, ★ rating, `U-17 • Cricket • Gujarat`, tags, **View Profile**) → data `athletes.scout`.

### scout-create
`TopBar--inner` "Create" → `CreateRow × 9` — Add Talent Shortlist (blue star) · Create Talent Report (green) · Add Scouting Opportunity (red) · Add Event / Trial (pink calendar) · Upload Photo / Video (pink) · Add Observation (purple) · Share Opportunity (green) · Create Poll (blue) · Go Live / Stream (red).

### scout-community
Same skeleton as org-community; sub-chips: Athletes*, Coaches, Academies, **Scouts**; PersonRow sub-text = `U-17 • Cricket • Gujarat`; group heading "Join Groups".

### scout-more
Profile summary (Sameer Desai ✔, Talent Scout) → menu A (8): My Profile, My Shortlisted Talents, My Scouting Reports, My Opportunities, My Events / Trials, My Connections, Saved, My Activity → Notifications, Messages → Settings & Privacy, Help & Support → Logout.

### scout-profile
`TopBar--inner` "Scout Profile" + bell + small avatar → `ProfileHeader` (cover "SCOUT" cap; avatar has **green status dot** bottom-right) → Sameer Desai ✔ → "Talent Scout • ★ 4.8 (120 Reviews)" (yellow star, tan text) → 📍 Ahmedabad, Gujarat → [**Edit Profile**][Share] → `Tabs--underline` (**About***, Shortlisted Talents, Reports, Activity) → About paragraph → `DetailList`: Organization: Independent Scout · Sports Focus: Cricket, Football, Athletics · Experience: 8+ Years · Location: Ahmedabad, Gujarat · Availability: Pan Gujarat / India · Languages: English, Hindi, Gujarati.

### scout-shortlist
1. `TopBar--inner` "My Shortlisted Talents" + ⋮
2. `Tabs--pill` — **All (48)***, Under Review (22), Final (12)
3. `SearchBar` "Search shortlisted talents…"
4. `ListWithCheckbox × 5` — each shows `Cricket • U-17` / `State Level` and a **StatusBadge** on the right (High Potential, Under Review, Good Potential …)
5. `btn-primary btn-block` **Compare Talents**

### scout-report
1. `TopBar--inner` "Talent Report"
2. Athlete summary row — photo 56 · Aarav Patel · `U-17 • Cricket • Gujarat` · ★4.8 (320)
3. `Tabs--underline` — **Overview***, Performance, Potential, Notes
4. "Key Information" — 2-column label/value grid: Position: All Rounder · Batting: Right Hand · Bowling: Right Arm Medium Fast · Age Group: U-17 · Current Level: State Level · Location: Ahmedabad, Gujarat
5. "Scouting Assessment" — `ScoreBar × 5`: Technical Skills 8.5 · Physical Fitness 8.0 · Match Awareness 7.5 · Mental Strength 8.0 · Overall Potential 8.2
6. "Conclusion" paragraph: *High potential athlete with strong technical skills and good temperament. Recommended for advanced training and higher level exposure.*
7. `btn-primary btn-block` **Save to Shortlist**

### scout-opps
`TopBar--inner` "Scouting Opportunities" → `Tabs--underline` (**All***, Trials, Scholarships, Camps) → `SearchBar` + filter → `OpportunityCard × 4` (image, title, `U-16 – U-19`, 📍 city, 📅 dates, green Registrations Open, **View Details**).

### scout-notifications
`TopBar--inner` "Notifications" + `clock` → `Tabs--pill` (**All***, Talents, Opportunities, Messages) → `NotificationRow--scout × 8` (checkbox/unread dot, avatar or coloured tile: calendar-red, @-red, play-purple).

### scout-messages
`TopBar--inner` "Messages" → Chats*/Requests → SearchBar → `ChatRow × 8` (`chats.scout`).

---

## 9. Sample Data (copy into `data.js`)

```js
export const createMenus = {
  coach: [
    ["Create Post","Share coaching insights, updates or announcements","#8B5CF6","file-pen"],
    ["Add Training Program","Create and list your training program","#22A05B","dumbbell"],
    ["Create Event","Post trials, tournaments or camps","#E53935","calendar-plus"],
    ["Share Achievement","Add your coaching achievements and certificates","#22A05B","award"],
    ["Add Opportunity","Post scholarship, sponsorship or coaching openings","#2F80ED","building-2"],
    ["Upload Photo / Video","Share training moments, drills or tips","#F43F5E","camera"],
    ["Go Live / Webinar","Host a live training session","#8B5CF6","video"],
    ["Poll","Create a poll for your community","#2F80ED","bar-chart-2"]
  ],
  academy: [
    ["Create Post","Share updates, achievements, or announcements","#8B5CF6","file-pen"],
    ["Add Training Program","Create and list your training programs","#22A05B","dumbbell"],
    ["Create Event / Trial","Post trials, tournaments or camps","#E53935","calendar-plus"],
    ["Post Scholarship / Opportunity","List scholarships or sponsorships","#2F80ED","landmark"],
    ["Add Facility / Venue","Showcase your facilities (grounds, courts, etc.)","#F97316","building"],
    ["Recruit Staff","Post coach or staff openings","#F43F5E","user-plus"],
    ["Upload Photos / Videos","Share training moments, infrastructure","#F43F5E","camera"],
    ["Go Live / Webinar","Host live sessions or open trials","#8B5CF6","video"],
    ["Create Poll","Get feedback from community","#2F80ED","bar-chart-2"]
  ],
  organizer: [
    ["Create Event","Post trials, tournaments or camps","#E53935","calendar-plus"],
    ["Create Opportunity","Post scholarships or sponsorships","#F59E0B","trophy"],
    ["Add Venue","List your ground, court or facility","#22A05B","map-pin"],
    ["Post Announcement","Share important updates","#8B5CF6","megaphone"],
    ["Upload Photo / Video","Share event highlights","#F43F5E","camera"],
    ["Go Live / Stream","Live streaming for your event","#E53935","radio"],
    ["Create Poll","Get feedback from participants","#2F80ED","bar-chart-2"],
    ["Add Staff / Organiser","Add team members to your event","#22A05B","users"]
  ],
  scout: [
    ["Add Talent Shortlist","Save promising athletes","#2F80ED","star"],
    ["Create Talent Report","Generate detailed evaluation report","#22A05B","file-text"],
    ["Add Scouting Opportunity","Post trials, scholarships or scouting calls","#E53935","search"],
    ["Add Event / Trial","Post upcoming selection events","#F43F5E","calendar-plus"],
    ["Upload Photo / Video","Share match footage or athlete clips","#F43F5E","camera"],
    ["Add Observation","Record notes and feedback","#8B5CF6","video"],
    ["Share Opportunity","Share with community or organization","#22A05B","share-2"],
    ["Create Poll","Get feedback from other scouts","#2F80ED","bar-chart-2"],
    ["Go Live / Stream","Live scout session or trial event","#E53935","radio"]
  ]
};

export const coaches = [
  {name:"Rohit Mehta",sport:"Cricket Coach",loc:"Ahmedabad, Gujarat",rating:4.8,count:320,tags:["Batting","Youth Development"]},
  {name:"Priya Sharma",sport:"Football Coach",loc:"Vadodara, Gujarat",rating:4.6,count:210,tags:["Fitness","Strategy"]},
  {name:"Dev Patel",sport:"Badminton Coach",loc:"Surat, Gujarat",rating:4.5,count:180,tags:["Technique","Mental Training"]},
  {name:"Sneha Verma",sport:"Athletics Coach",loc:"Rajkot, Gujarat",rating:4.4,count:150,tags:["Strength","Conditioning"]}
];

export const academies = [
  {name:"Narendra Modi Cricket Academy",area:"Motera, Ahmedabad",km:2.5,sport:"Cricket",age:"U-10 to U-19",rating:4.8,count:320},
  {name:"Ahmedabad Football Academy",area:"Bopal, Ahmedabad",km:6.1,sport:"Football",age:"U-8 to U-18",rating:4.6,count:210},
  {name:"Gujarat Badminton Academy",area:"Thaltej, Ahmedabad",km:4.8,sport:"Badminton",age:"U-10 to U-19",rating:4.7,count:180},
  {name:"SportX Training Centre",area:"Vastrapur, Ahmedabad",km:5.3,sport:"Multi-Sport",age:"All Age Groups",rating:4.5,count:140}
];

export const exploreAcademies = [ // Academy-role Explore
  {name:"Motera Cricket Academy",km:2.5,sport:"Cricket",age:"U-8 to U-19",rating:4.8,count:320},
  {name:"Ahmedabad Football Academy",km:6.1,sport:"Football",age:"U-10 to U-18",rating:4.6,count:210},
  {name:"Gujarat Badminton Academy",km:4.8,sport:"Badminton",age:"U-8 to U-18",rating:4.7,count:180},
  {name:"AquaSport Swimming Academy",km:5.3,sport:"Swimming",age:"U-6 to U-18",rating:4.5,count:140}
];

export const programs = {
  coach: [
    {title:"Beginner Cricket Program",age:"U-10, U-14",dur:"3 Months",mode:"Offline",price:"₹5,000"},
    {title:"Advanced Batting Training",age:"U-14, U-19",dur:"6 Months",mode:"Offline",price:"₹8,000"},
    {title:"Weekend Coaching Program",age:"All Age Groups",dur:"3 Months",mode:"Offline",price:"₹3,000"},
    {title:"1-on-1 Personal Coaching",age:"All Age Groups",dur:"Flexible",mode:"Offline/Online",price:"₹1,500/session"}
  ],
  academy: [
    {title:"Beginner Cricket Program",age:"U-10",dur:"3 Months",mode:"Offline",price:"₹5,000"},
    {title:"Advanced Batting Program",age:"U-14",dur:"6 Months",mode:"Offline",price:"₹8,000"},
    {title:"Fast Bowling Specialist",age:"U-16",dur:"4 Months",mode:"Offline",price:"₹6,500"},
    {title:"Weekend Cricket Camp",age:"All Age Groups",dur:"1 Month",mode:"Offline",price:"₹3,000"},
    {title:"1-on-1 Personal Coaching",age:"All Age Groups",dur:"Flexible",mode:"Offline/Online",price:"₹1,500 / session"}
  ]
};

export const leaderboard = {
  podium: [
    {rank:1,name:"Rohit Mehta",pts:2450},{rank:2,name:"Ankit Sharma",pts:2120},{rank:3,name:"Neha Patel",pts:1950}],
  coachRows: [
    [4,"Dev Patel","Badminton",1780],[5,"Sneha Verma","Athletics",1650],[6,"Karan Shah","Football",1420],
    [7,"Priya Desai","Volleyball",1380],[8,"Manav Joshi","Hockey",1220],[9,"Riya Mehta","Swimming",1150],
    [10,"Amit Rathod","Table Tennis",1020]
  ],
  academyPodium:[["Motera Cricket Academy",4520],["Ahmedabad Football Acad.",3980],["Gujarat Badminton Acad.",3450]],
  scoutPodium:[["Aarav Patel","Cricket",2450],["Riya Shah","Throwball",2180],["Karan Mehta","Football",1960]]
};

export const events = {
  explore: [ // Organizer explore + my events
    {m:"NOV",d:"20-22",y:2026,title:"Gujarat Youth Football Championship",city:"Ahmedabad, Gujarat",meta:"Football • U-14, U-17",open:true},
    {m:"DEC",d:"05",y:2026,title:"State Level Badminton Tournament",city:"Vadodara, Gujarat",meta:"Badminton • Open",open:true},
    {m:"DEC",d:"12-14",y:2026,title:"Inter College Cricket Tournament",city:"Surat, Gujarat",meta:"Cricket • College",open:true},
    {m:"JAN",d:"10",y:2026,title:"Gujarat Throwball Championship",city:"Rajkot, Gujarat",meta:"Throwball • U-19",open:true},
    {m:"JAN",d:"25",y:2026,title:"Ahmedabad Marathon 2026",city:"Ahmedabad, Gujarat",meta:"Running • Open",open:true}
  ],
  mine: [
    {m:"NOV",d:"20-22",y:2026,title:"Gujarat Football Championship",registered:320},
    {m:"DEC",d:"12-14",y:2026,title:"Inter Academy Cricket Cup",registered:150},
    {m:"JAN",d:"10",y:2026,title:"State Badminton Tournament",registered:280},
    {m:"FEB",d:"05",y:2026,title:"College Throwball League",registered:120}
  ],
  academy: [
    {title:"Open Trials – U14",sport:"Cricket",date:"12 Nov 2026",city:"Ahmedabad",note:"120 Registered"},
    {title:"Winter Training Camp",sport:"All Age Groups",date:"1 Dec 2026",city:"Ahmedabad",note:"80 Registered"},
    {title:"Inter Academy Tournament",sport:"U-16",date:"20 Dec 2026",city:"Ahmedabad",note:"16 Teams"},
    {title:"Scouting Trial",sport:"U-19",date:"5 Jan 2027",city:"Ahmedabad",note:"Pre-registration Open"}
  ]
};

export const athletes = {
  academy: [
    {name:"Karan Joshi",meta:"U-16 • Batsman",rating:4.5,count:120},
    {name:"Priya Sharma",meta:"U-14 • All Rounder",rating:4.6,count:98},
    {name:"Dev Patel",meta:"U-19 • Fast Bowler",rating:4.4,count:76},
    {name:"Sneha Verma",meta:"U-14 • Athlete",rating:4.5,count:82},
    {name:"Riya Mehta",meta:"U-16 • Wicket Keeper",rating:4.3,count:68}
  ],
  scout: [
    {name:"Aarav Patel",meta:"U-17 • Cricket • Gujarat",rating:4.8,count:320,tags:["Right Hand Bat","All Rounder"]},
    {name:"Riya Sharma",meta:"Throwball • U-19 • Gujarat",rating:4.6,count:210,tags:["Attacker","State Level"]},
    {name:"Karan Joshi",meta:"Football • U-16 • Gujarat",rating:4.5,count:180,tags:["Forward","District Level"]},
    {name:"Neha Patel",meta:"Athletics • U-18 • Gujarat",rating:4.4,count:150,tags:["Sprinter","State Level"]},
    {name:"Dev Mehta",meta:"Badminton • U-17 • Gujarat",rating:4.3,count:120,tags:["Singles","Ranked Player"]}
  ]
};

export const facilities = [
  {name:"Main Cricket Ground",meta:"Outdoor • Full Size"},
  {name:"Indoor Nets",meta:"4 Practice Lanes"},
  {name:"Fitness Centre",meta:"Gym & Conditioning"},
  {name:"Classroom",meta:"Video Analysis & Theory"},
  {name:"Changing Rooms",meta:"Separate for Boys & Girls"}
];

export const community = {
  coach: {
    people:[["Karan Joshi","Cricket Player • Gujarat"],["Priya Sharma","Football Coach • Vadodara"],["Ahmedabad Cricket Academy","Academy • Ahmedabad"],["Neha Patel","Athlete • Athletics"]],
    groups:[["Cricket Coaches India","2.4K"],["Youth Training & Development","1.8K"],["Strength & Conditioning","1.2K"]]},
  academy: {
    people:[["Arjun Patel","Cricket Player • Ahmedabad"],["Priya Sharma","Throwball Player • Gujarat"],["Rohan Mehta","Cricket Coach • Ahmedabad"],["Shree Sports Academy","Sports Academy • Rajkot"],["AquaSport Swimming Academy","Swimming Academy • Ahmedabad"]],
    groups:[["Gujarat Coaches Network","2.4K"],["Cricket Academies Gujarat","1.8K"],["Sports Facility Owners","1.2K"]]},
  organizer: {
    people:[["Gujarat Sports Association","Organization • Gandhinagar"],["Karan Joshi","Cricket Player • Ahmedabad"],["Priya Sharma","Throwball Player • Vadodara"],["FitYouth Foundation","NGO • Youth Sports"],["Ahmedabad Football Academy","Academy • Ahmedabad"]],
    groups:[["Sports Event Organizers India","2.4K"],["Gujarat Sports Community","1.8K"],["College Sports Coordinators","1.2K"]]},
  scout: {
    people:[["Aarav Patel","U-17 • Cricket • Gujarat"],["Riya Shah","U-19 • Throwball • Gujarat"],["Karan Joshi","U-16 • Football • Gujarat"],["Neha Patel","U-18 • Athletics • Gujarat"],["Dev Mehta","U-17 • Badminton • Gujarat"]],
    groups:[["Talent Scouts India","2.4K"],["Gujarat Sports Talent Network","1.8K"],["Youth Athlete Development","1.2K"]]}
};

export const chats = {
  coach:[["Priya Sharma","Hey! Are weekend batches available?","10:30 AM",2],["Karan Joshi","Thank you for the training!","9:15 AM",1],["Dev Patel","Can I join from next month?","Yesterday"],["Riya Mehta","Shared a photo","Yesterday"],["Sneha Verma","Ok, I will check and let you know.","2 Nov"],["Aman Shah","What is the fee for U-14 batch?","1 Nov"],["Neha Patel","Is personal coaching available?","30 Oct"]],
  academy:[["Arjun Patel","Hi, is admission open?","10:30 AM",2],["Priya Sharma","Can I know the fees?","9:15 AM",1],["Karan Joshi","Thank you for the trial!","Yesterday"],["Riya Mehta","Shared a photo","Yesterday"],["Dev Patel","What are the timings?","2 Nov"],["Coach Rohan","Sure, see you tomorrow.","1 Nov"],["Sneha Verma","Is hostel available?","30 Oct"]],
  organizer:[["Karan Joshi","Sir, can we register our team?","10:30 AM",2],["Ahmedabad Football Academy","Thanks for the opportunity!","9:15 AM",1],["Priya Sharma","When is the last date?","Yesterday"],["Dev Patel","Can we get group discount?","Yesterday"],["Rohan Mehta","Is accommodation available?","2 Nov"],["Neha Patel","Please share event schedule.","1 Nov"],["Coach Rohit","Can we collaborate for next event?","30 Oct"]],
  scout:[["Aarav Patel","Thank you for the trial opportunity!","10:30 AM",1],["Riya Sharma","Can we discuss the next round?","9:15 AM",2],["Karan Joshi","Sharing my latest performance…","Yesterday"],["Coach Mehta","We have a talented player…","Yesterday"],["Dev Mehta","When is the next camp?","2 Nov"],["Neha Patel","Here is my latest video.","1 Nov"],["Ahmedabad Academy","Thanks for the opportunity.","30 Oct"],["Gujarat Sports Association","Please find the event details.","28 Oct"]]
};

export const notifications = {
  coach:{
    Today:[["Karan Joshi started following you","2 minutes ago"],["Ahmedabad Cricket Academy liked your post","15 minutes ago"],["New enquiry for training program","1 hour ago"],["Priya Sharma mentioned you in a post","2 hours ago"]],
    Yesterday:[["Your program received 10 new views","1 day ago"],["Dev Patel sent you a message","1 day ago"],["Your post got 50 likes","1 day ago"]]},
  scout:[["Aarav Patel updated his match performance","5 minutes ago"],["New registration for State Level Cricket Trials","15 minutes ago"],["Riya Sharma shared a new video","1 hour ago"],["Karan Joshi accepted your connection request","2 hours ago"],["New scouting opportunity: Youth Football Camp","3 hours ago"],["Dev Mehta sent you a message","5 hours ago"],["Neha Patel achieved a new milestone","1 day ago"],["Your post reached 1,000 views","1 day ago"]]
};

export const registrations = [
  ["Aarav Patel","Team Captain • U-17","Approved"],["Dev Shah","Player • U-14","Approved"],["Riya Mehta","Player • U-14","Pending"],
  ["Karan Joshi","Player • U-14","Approved"],["Sneha Verma","Player • U-17","Approved"],["Manav Trivedi","Player • U-14","Pending"],["Rohan Desai","Player • U-17","Approved"]
];

export const shortlist = [
  ["Aarav Patel","Cricket • U-17","State Level","High Potential"],
  ["Riya Sharma","Throwball • U-19","District Level","Under Review"],
  ["Karan Joshi","Football • U-16","State Level","Good Potential"],
  ["Neha Patel","Athletics • U-18","State Level","High Potential"],
  ["Dev Mehta","Badminton • U-17","District Level","Under Review"]
];

export const opportunities = [
  {title:"State Level Cricket Trials",age:"U-16 – U-19",city:"Ahmedabad, Gujarat",date:"20-22 Nov 2026"},
  {title:"Youth Football Camp",age:"U-14 – U-17",city:"Vadodara, Gujarat",date:"5-10 Dec 2026"},
  {title:"Athletics Talent Hunt",age:"U-14 – U-19",city:"Surat, Gujarat",date:"12-14 Dec 2026"},
  {title:"Badminton Selection Camp",age:"U-15 – U-19",city:"Rajkot, Gujarat",date:"18-20 Dec 2026"}
];

export const assessment = [["Technical Skills",8.5],["Physical Fitness",8.0],["Match Awareness",7.5],["Mental Strength",8.0],["Overall Potential",8.2]];
export const analytics = {
  kpis:[["Views","12,450","↑42%"],["Registrations","320","↑28%"],["Revenue","₹1,60,000","↑35%"],["Inquiries","86","↑22%"]],
  sources:[["Direct",42],["Instagram",28],["WhatsApp",18],["Search",12]],
  series:[["1 Nov",40],["10 Nov",150],["20 Nov",320],["30 Nov",320]]
};

export const moreMenus = {
  coach:["My Profile","My Training Programs","My Events","My Opportunities","My Achievements","Saved","My Connections","My Activity"],
  academy:["My Profile","My Training Programs","My Events / Trials","My Scholarships","My Facilities / Venues","My Staff","My Athletes","My Collaborations","Saved","My Activity"],
  organizer:["My Profile","My Events","Registrations & Participants","My Opportunities","My Venues","My Team / Staff","My Analytics","My Collaborations","Saved","My Activity"],
  scout:["My Profile","My Shortlisted Talents","My Scouting Reports","My Opportunities","My Events / Trials","My Connections","Saved","My Activity"]
  // always followed by: Notifications, Messages | Settings & Privacy, Help & Support | Logout
};
```

---

## 10. Minimal JS Router (role + screen switcher)

```html
<!-- index.html (skeleton) -->
<header class="switcher">
  <select id="role"><option value="coach">Coach</option><option value="acad">Academy</option>
    <option value="org">Organizer</option><option value="scout">Talent Scout</option></select>
  <div id="screenTabs"></div>
</header>
<div class="phone"><div class="statusbar">9:41</div>
  <main id="view" class="screen-body"></main>
  <nav class="bottomnav" id="nav"></nav></div>
<script type="module" src="app.js"></script>
```
```js
// app.js
import * as D from './data.js';

const screens = {
  coach:  ['home','explore','create','community','more','profile','programs','leaderboard','academies','notifications','messages'],
  acad:   ['home','explore','create','community','more','profile','programs','events','athletes','facilities','messages'],
  org:    ['home','explore','create','community','more','profile','myevents','eventdetail','registrations','analytics','messages'],
  scout:  ['home','explore','create','community','more','profile','shortlist','report','opps','notifications','messages']
};
const renderers = {};              // renderers['coach-home'] = () => `<html string>`
let role='coach', screen='home';

function go(r=role, s=screen){
  role=r; screen=s;
  document.getElementById('view').innerHTML = (renderers[`${r}-${s}`] || (()=>'<p>TODO</p>'))();
  document.getElementById('nav').innerHTML = navHTML(s);
  document.getElementById('screenTabs').innerHTML =
    screens[r].map(x=>`<button data-s="${x}">${x}</button>`).join('');
  window.lucide?.createIcons();
}
const navMap={home:0,explore:1,create:2,community:3,more:4};
function navHTML(s){ /* build 5 items, add .is-active to navMap[s] */ }

document.getElementById('role').onchange = e => go(e.target.value,'home');
document.getElementById('screenTabs').onclick = e => e.target.dataset.s && go(role,e.target.dataset.s);
document.getElementById('nav').onclick = e => { /* map clicks to home/explore/create/community/more */ };
go();
```
Add `<script src="https://unpkg.com/lucide@latest"></script>` for icons.

**Render helper example (component → function):**
```js
const chip = (t,active)=>`<span class="chip ${active?'is-active':''}">${t}</span>`;
const entityCard = c => `
  <article class="entity">
    <div class="entity__img"></div>
    <div class="entity__body">
      <div class="row"><b>${c.name}</b><i data-lucide="badge-check" class="verified"></i>
        <span class="rating">★ ${c.rating} (${c.count})</span></div>
      <div class="t-meta">${c.sport}</div>
      <div class="t-meta"><i data-lucide="map-pin"></i> ${c.loc}</div>
      <div class="row">${c.tags.map(t=>chip(t)).join('')}<button class="btn-primary btn-sm">Follow</button></div>
    </div>
  </article>`;
```

---

## 11. Final QA Checklist

- [ ] Phone frame 390×844, status bar shows **9:41**
- [ ] Bottom nav has 5 items, centre **yellow raised "+"** button, active item yellow
- [ ] Every list card has: image left → bold name → meta → yellow action button
- [ ] Verified ✔ (blue) beside all organisation/coach/athlete names
- [ ] Primary CTAs are **yellow** with dark text; secondary are outlined
- [ ] Status colours: green = Approved/Open, orange = Pending/Under Review
- [ ] Full-width bottom buttons on: Event Details (Manage Event), Registrations (Export List), Shortlist (Compare Talents), Talent Report (Save to Shortlist)
- [ ] Horizontal-scroll rows (chips, tabs) hide scrollbars: `scrollbar-width:none`
- [ ] Images: use grey/gradient placeholders (`background:linear-gradient(135deg,#dbeafe,#fde68a)`) if no assets
- [ ] All 44 screens reachable from the role/screen switcher
