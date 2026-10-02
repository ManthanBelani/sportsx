# SportX – UI Screen Specification

> Tagline under logo: **"LET'S DEFEAT HISTORY"**
> Purpose of this document: describe every screen (features, placement, layout, content, states) precisely enough to rebuild the same design in HTML/CSS/JS.
> Total screens documented: **10 screens** (+1 alternate Home variant = 11 images).

---

## 0. Screen Index

| # | Screen | Canvas type | Bottom-nav active tab |
|---|--------|-------------|-----------------------|
| 1 | Home (Feed) – Variant A | Mobile (~740px wide artboard) | Home |
| 1b | Home (Feed) – Variant B (quick-access icons inside cards) | Mobile | Home |
| 2 | Explore – "All" overview | Mobile | Explore |
| 3 | Explore – Athletes (filtered grid) | Mobile | Explore |
| 4 | Create (action hub) | Mobile/tablet portrait (~1024px artboard) | Create |
| 5 | Community – Network | Tablet/desktop-like 3-column | Community |
| 6 | More (menu + profile summary) | Mobile/tablet portrait | More |
| 7 | Profile (own profile, overview tab) | Tablet portrait, 2-column | – (sub-screen) |
| 8 | Notifications | Mobile/tablet portrait | – (sub-screen) |
| 9 | Leaderboard | Mobile/tablet portrait | – (sub-screen) |
| 10 | Academies (Find academy) | Mobile/tablet portrait | – (sub-screen) |

> ⚠️ **Data inconsistency in the mockups (keep or fix as you wish):** Home greets the user as **"Hi, Rahul!"** (avatar letter **R**) while More/Profile/Notifications show the user as **Akshay Pandya**. Profile completion is **60%** on Home but **68%** on More/Profile. Use one consistent user in your HTML build (recommended: Akshay Pandya, 68%).

---

## 1. Global Design System

### 1.1 Colors (approximate values sampled from the designs)

| Token | Hex (approx.) | Usage |
|-------|---------------|-------|
| `--primary` | `#FFC72C` (golden yellow) | Primary buttons (Follow, Connect, View, Complete Now, View Details), active tab pill, Create FAB, active nav icon/label, progress bar fill |
| `--primary-soft` | `#FFE9A0` / `#FFF3C4` | Active chip fill (e.g., "All Sports", "Network"), banner backgrounds |
| `--primary-tint` | `#FFF8E5` | Profile-completion banner, Opportunities card, More profile card |
| `--text-dark` | `#0F1B3D` (deep navy) | Headings, names, button text |
| `--text-muted` | `#5B6785` (slate blue-grey) | Sub-labels, meta text ("Cricket • Gujarat") |
| `--bg` | `#F6F8FD` (very light blue-white) | Page background |
| `--card` | `#FFFFFF` | All cards, with soft shadow |
| `--blue-tint` | `#E8F0FF` | Academy/Coach/Training card, info chips |
| `--blue-link` | `#1E6CF0` | Links ("Mark all as read", "Edit", "Manage", "View All"), hashtags, verified badge |
| `--red` | `#E5334B` | Heart/like, notification badge, Logout, "Event" tag |
| `--green` | `#22A559` | "Scholarship" tag, Add Achievement tile, About icon |
| `--purple` | `#7B3FE4` | Create Opportunity tile, Saved icon |
| `--verified` | `#1E6CF0` | Blue check-circle verified badge next to names |
| `--notif-dot` | `#1E6CF0` | Unread dot in notifications |
| `--online-dot` | `#2ECC71` | Green presence dot on header avatar |

Rank medal colors: **Gold** (#1), **Silver** (#2), **Bronze** (#3).

### 1.2 Typography
- Font: rounded geometric sans (Plus Jakarta Sans / Poppins / Nunito Sans style). Suggest **"Plus Jakarta Sans"** from Google Fonts.
- Screen title: 20–24px, weight 700.
- Section title (e.g., "Popular Athletes"): 20px, weight 700.
- Card name: 16–17px, weight 700 (+ verified icon).
- Meta / sub-label: 13–14px, weight 400–500, `--text-muted`.
- Buttons: 15–16px, weight 600–700.
- Logo: bold black italic-ish "Sport" + yellow "X", with tiny letter-spaced tagline "LET'S DEFEAT HISTORY" (≈8px, uppercase, tracking 2px) underneath.

### 1.3 Shape, Spacing, Elevation
- Page horizontal padding: **16–20px**.
- Card radius: **16–20px**; button radius: **8–12px** (Follow/Connect are rounded rectangles, not pills); chip/tab radius: **999px (pill)**.
- Card shadow: `0 4px 16px rgba(20,30,70,0.06)`; no hard borders (very subtle 1px `#EEF1F8` in places).
- Vertical gap between sections: **20–24px**; inside cards: **12–16px**.
- Icons: outline style (Lucide/Feather-like), 22–24px, navy; colored filled icons inside tinted rounded squares on Create/More screens.

### 1.4 Status Bar (top, all screens)
- Time **"9:41"** left (bold), signal bars + Wi-Fi + battery icons right.

### 1.5 Reusable Components

**A. App Header (top bar) – used on Home, Explore(All), Community**
`[Logo]  [Search field (flex)]  [Bell icon + red badge "3"]  [Round avatar with green online dot]`

**B. Sub-page Header – used on Explore-Athletes, Notifications, Leaderboard, Academies**
`[← back arrow] [Logo (on some)] [Centered title] [right action icon]`

**C. Bottom Navigation (5 items, fixed, white rounded-top bar, floating shadow)**
Order left → right: **Home · Explore · (Create FAB, center) · Community · More**
- Home: house icon. Explore: compass icon. Community: three-people icon. More: 2×2 grid icon.
- Center **Create**: large **yellow circle (~64px) with "+"**, raised/overlapping above the bar; label "Create" below it.
- Active tab: icon and label turn **yellow/gold**, icon gets filled style, with a **small yellow underline pill** below the label. Inactive: navy outline icon + navy label.
- On the Create screen the FAB label "Create" turns yellow with underline.

**D. Buttons**
- **Primary (Follow / Connect / View / View Details / Join-style)**: yellow fill, navy bold text, radius ~8px, full width of card in athlete/coach/academy cards.
- **Secondary (Join, Follow in leaderboard table, View Profile on rank 2/3)**: light grey-blue / tinted fill, navy text.
- **Chip (filter)**: pill, white/very light fill with icon + label; **active chip = yellow fill**.

**E. Verified badge**: small blue filled circle with white check, placed right after the name.

**F. Kebab menu**: vertical three dots (⋮), placed top-right of posts and top-right corner of image cards (inside a small translucent white rounded square on images).

**G. Bookmark icon**: outline bookmark; on Explore grid it sits inside a small translucent white square at top-right of the photo.

**H. Notification bell**: white circular button with shadow, red circular badge "3" at top-right.

---

## 2. Screen 1 – Home (Feed) — Variant A

**Purpose:** landing page; profile completion nudge, leaderboard glance, quick links to Opportunities and Academies, social feed, athlete recommendations.

### Layout (top → bottom, single scroll column)
```
┌──────────────────────────────────────────┐
│ 9:41                        signal wifi bat│
│ [SportX logo] [🔍 Search athletes,        ] [🔔3] [avatar•]│
│               coaches, academies…                          │
├──────────────────────────────────────────┤
│ ┌ Profile completion banner (cream bg) ─┐│
│ │ (R) Hi, Rahul!                60% >  [Complete Now]│
│ │     Complete your profile to get more opportunities│
│ │     ▓▓▓▓▓▓▓▓▓░░░░░░░ (progress bar)     ││
│ └───────────────────────────────────────┘│
│ ┌ Leaderboard card ─────────────────────┐│
│ │ 👑 Leaderboard [All Sports*][Cricket][Football][Throwball][Badminton]  View All >│
│ │ (1) (2) (3) (4) (5) horizontal avatars w/ rank badge│
│ │ Arjun Patel | Priya Sharma | Karan Joshi | Sneha Verma | Dev Mehta│
│ │ 2,450 pts   | 2,180 pts    | 1,960 pts   | 1,820 pts   | 1,650 pts│
│ └───────────────────────────────────────┘│
│ ┌ Opportunities (cream) ┐┌ Academy, Coach & Training Centre (light blue) ┐│
│ │ 🏆 Opportunities   >  ││ 🎓 Academy, Coach & Training Centre        >  ││
│ │ Trials•Tournaments•   ││ Find Academies • Coaches • Training Centres  ││
│ │ Scholarships•Sponsor. ││                                              ││
│ └───────────────────────┘└──────────────────────────────────────────────┘│
│ Tabs: [For You*] Following Athletes Coaches Academies Events [⚙ filter icon]│
│ ┌ Post card ────────────────────────────┐│
│ │ (avatar) Priya Sharma ✔          ⋮     ││
│ │ State Level Athlete • Throwball • Gujarat • 2h ago│
│ │ "Another great practice session today! Consistency creates progress 💪"│
│ │ #Throwball #Training #NeverGiveUp (blue links)│
│ │ ┌──────────────┬────────┬────────┐      ││
│ │ │ big photo    │ photo  │ photo  │ (collage: 1 large left, 2×2 small right)│
│ │ │ (left, tall) ├────────┼────────┤      ││
│ │ │              │ photo  │ photo  │      ││
│ │ └──────────────┴────────┴────────┘      ││
│ │ ❤ 256   💬 18   ➤ 12                  🔖││
│ └───────────────────────────────────────┘│
│ Recommended Athletes for You        [See all >]│
│ ┌─────┐┌─────┐┌─────┐┌─────┐ (horizontal scroll)│
│ │photo││photo││photo││photo││                  │
│ │ ⋮   ││ ⋮   ││ ⋮   ││ ⋮   ││                  │
│ │Arjun Patel ✔ … Priya Sharma ✔ … Karan Joshi ✔ … Sneha Verma ✔│
│ │Cricket•Gujarat│Throwball•Gujarat│Football•Surat│Athletics•Gujarat│
│ │[Follow]│[Follow]│[Follow]│[Follow]│            │
│ └─────┘└─────┘└─────┘└─────┘                  │
│        Bottom Nav (Home active)                │
└──────────────────────────────────────────┘
```

### Details per block
1. **Header (Component A).** Search placeholder: *"Search athletes, coaches, academies…"*. Bell has badge **3**. Avatar has green dot.
2. **Profile-completion banner.** Cream/yellow-tinted rounded card, 1px yellow-ish border. Left: yellow circle with letter **"R"**. Text: bold **"Hi, Rahul!"**, sub-text *"Complete your profile to get more opportunities"*. Right: **"60% >"** then yellow button **"Complete Now"**. Under the text: full-width progress bar (yellow fill 60%, grey track).
3. **Leaderboard card.** White card. Title row: gold crown icon + **"Leaderboard"** (bold), then horizontally scrollable sport chips: **All Sports (active, yellow-soft)**, Cricket, Football, Throwball, Badminton; far right link **"View All >"**. Below: 5 equal columns separated by thin vertical dividers; each has circular avatar (~56px) with a small numbered circle badge at top-left (1 = gold fill, 2 = silver, 3 = bronze, 4 & 5 = white with border), then name (bold) and points (**2,450 pts**, etc.).
4. **Two shortcut cards side by side (50/50).**
   - Left (cream bg): yellow circle with black trophy icon; title **"Opportunities"**; sub-text *"Trials • Tournaments • Scholarships • Sponsorships"*; chevron `>` at right.
   - Right (light-blue bg): graduation-cap-with-person icon; title **"Academy, Coach & Training Centre"**; sub-text *"Find Academies • Coaches • Training Centres"*; chevron `>`.
5. **Feed tabs.** Underlined tab bar: **For You** (active, bold with yellow underline), Following, Athletes, Coaches, Academies, Events; at far right a **sliders/filter icon** in a small white square.
6. **Post card.** Header: avatar, name + verified badge, ⋮ menu at right. Sub-line: *State Level Athlete • Throwball • Gujarat • 2h ago*. Caption with 💪 emoji, hashtags in blue. Photo collage: left large photo (≈50% width) + right 2×2 grid. Action row: red filled heart **256**, comment bubble **18**, send/share arrow **12**, bookmark aligned right.
7. **Recommended Athletes for You.** Section heading bold left + **"See all >"** white pill button right. Horizontal carousel of cards (~160px wide): top photo (rounded top corners) with ⋮ in translucent square; below: name + ✔; sub-line *Sport • State*; full-width yellow **Follow** button. Next card peeks at right edge to hint scroll.

### Variant B (Home – second image)
Identical to Variant A except the two shortcut cards are **taller and expanded** with mini icon tiles below the text:
- **Opportunities card** → sub-text *"Trials • Tournaments • Scholarships • Sponsorships"* + a row of 4 small white tiles: **Trials** (red calendar icon), **Tournaments** (purple trophy), **Scholarships** (green graduation cap), **Sponsorships** (orange handshake).
- **Academy, Coach & Training Centre card** → left icon is a blue academy building; row of 3 tiles: **Academies** (blue building), **Coaches** (red person icon), **Training Centres** (green dumbbell).
- Feed post & recommendations are identical (feed is slightly scrolled less; card shows 4 recommended athletes).
- Use Variant B if you want richer quick-access; Variant A if you want a compact home.

---

## 3. Screen 2 – Explore (All)

**Purpose:** discovery hub – horizontal carousels for every entity type.

### Layout
```
Header (Component A)
Category chips (horizontal): [All*] [👤 Athletes] [👥 Coaches] [🏛 Academies] [📅 Events]
── Popular Athletes ───────────── [See All >]
  carousel cards (photo, ⋮, name ✔, "Sport • State", "U-19 • Role", [Follow])
── Coaches ─────────────────────── [See All >]
  carousel cards (photo w/ cap, ⋮, name, "X Coach", city, [Connect])
── Academies ───────────────────── [See All >]
  carousel cards (building photo, ⋮, name, city, "Sport • Type", [View])
── Events ──────────────────────── [See All >]
  carousel cards (banner image with date badge, ⋮, title, 📍 location, bookmark, tag chip)
── Opportunities ───────────────── [See All >]
  two horizontal compact cards (icon tile, title, org, tags, bookmark)
Bottom Nav (Explore active)
```

### Content
- **Category chips:** "All" is active (yellow fill). Others are white pills with outline icon on left.
- **Popular Athletes cards (4 visible):**
  | Name | Line 1 | Line 2 |
  |------|--------|--------|
  | Arjun Patel ✔ | Cricket • Gujarat | U-19 • All-rounder |
  | Priya Sharma ✔ | Throwball • Gujarat | U-17 • Spiker |
  | Karan Joshi ✔ | Football • Surat | U-18 • Midfielder |
  | Sneha Verma ✔ | Athletics • Gujarat | U-20 • Sprinter |
  Each: yellow **Follow** button full width.
- **Coaches cards (photo of coach in navy cap & navy jacket):**
  | Name | Role | City |
  |------|------|------|
  | Rohit Desai | Cricket Coach | Ahmedabad, Gujarat |
  | Neha Shah | Throwball Coach | Vadodara, Gujarat |
  | Amit Trivedi | Football Coach | Surat, Gujarat |
  | Vikram Solanki | Athletics Coach | Rajkot, Gujarat |
  Button: yellow **Connect**.
- **Academies cards:**
  | Name | City | Tags |
  |------|------|------|
  | Elite Cricket Academy | Ahmedabad, Gujarat | Cricket • Residential |
  | Game On Sports Centre | Surat, Gujarat | Multi-Sports • Indoor |
  | Shakti Sports Academy | Vadodara, Gujarat | Football • Residential |
  | Rise Training Centre | Bharuch, Gujarat | Athletics • Multi-Sports |
  Button: yellow **View**. (Names are slightly smaller/bolder, 14px.)
- **Events cards (3 visible, wider):** image banner with a **white/cream rounded date badge** top-left (big day number + month, e.g., **12 OCT**), ⋮ top-right. Below: bold title, 📍 location (blue pin), bookmark outline at right, and a colored tag chip at bottom-left:
  | Date | Title | Location | Tag |
  |------|-------|----------|-----|
  | 12 OCT | Gujarat U-19 Cricket Trials | Ahmedabad, Gujarat | **Trial** (green chip) |
  | 18 OCT | State Level Throwball Tournament | Vadodara, Gujarat | **Tournament** (blue chip) |
  | 25 OCT | Open Athletics Meet | Surat, Gujarat | **Event** (red/pink chip) |
- **Opportunities (2 cards side-by-side):**
  1. Cream icon tile w/ gold trophy · **Sports Scholarship 2026** · *Sports Authority of India* · chips **Scholarship** (green) + **Nationwide** (grey-blue) · bookmark.
  2. Cream icon tile w/ orange briefcase · **Brand Sponsorship Opportunity** · *PlayFit Sports* · chips **Sponsorship** (yellow) + **India** (grey-blue) · bookmark.

Section heading style: bold 20px left, **"See All >"** in a small white pill right (with shadow).

---

## 4. Screen 3 – Explore → Athletes (filtered grid)

**Purpose:** searchable, filterable athlete directory.

### Layout
```
Sub-page header: [← ] Explore ................ [sliders icon]
Search bar (full width, light-blue-grey fill): 🔍 "Search athletes by name, sport, location…"
Category chips: [All] [Athletes*] [Coaches] [Academies] [Events]
Filter dropdown chips (one row, scrolls): [Sport ⌄][State ⌄][Age Group ⌄][Position ⌄][⚙ More Filters]
Result row: "1,248 Athletes"                 [↕ Most Relevant ⌄]
2-column grid of athlete cards
Bottom Nav (Explore active)
```

### Athlete grid card (2 columns, ~50% width each, 12px gap)
- Top: wide photo (aspect ≈ 2:1), rounded top corners, **bookmark** icon in translucent white square (top-right).
- Name (bold) + verified ✔.
- Sub-line 1: *Sport • State* (muted).
- Sub-line 2: *Age group • Position* (muted).
- Bottom row: left = 🏆 trophy count + 🎬 video-camera count; right = yellow **Follow** button (~100px wide).

### Data
| Name | Sport • State | Age • Position | 🏆 | 🎬 |
|------|---------------|----------------|----|----|
| Arjun Patel ✔ | Cricket • Gujarat | U-19 • All-rounder | 12 | 5 |
| Priya Sharma ✔ | Throwball • Gujarat | U-17 • Spiker | 8 | 6 |
| Karan Joshi ✔ | Football • Surat | U-18 • Midfielder | 10 | 4 |
| Sneha Verma ✔ | Athletics • Gujarat | U-20 • Sprinter | 15 | 7 |
| Dev Mehta ✔ | Badminton • Ahmedabad | U-19 • Singles | 9 | 3 |
| Riya Desai ✔ | Volleyball • Vadodara | U-17 • Attacker | 11 | 5 |
| (2 more partially visible, continue scrolling) | | | | |

Active chip "Athletes" is yellow. Dropdown chips are white pills with a small chevron; "More Filters" has a sliders icon.

---

## 5. Screen 4 – Create (action hub)

**Purpose:** full-screen sheet to create any content type.

### Layout
```
Header: [Logo]      Create               [✕ close (grey circle)]
                    Share, Add or Create on SportX (subtitle, muted)
2-column grid of 8 action cards (each: colored-tint bg, rounded icon tile left, title + description, chevron right)
"Quick Post Options" heading + "Share something quickly"
Row of 5 square tiles: Photo · Video · Text · Poll · Achievement
Bottom Nav (Create FAB label active/yellow)
```

### 8 action cards (row by row, left | right)
| Row | Left card | Right card |
|-----|-----------|------------|
| 1 | **Create Post** – "Share updates, photos, videos or thoughts with the community" · pink/red-tint bg, red document icon | **Add Achievement** – "Add your medals, certificates, records and milestones" · green-tint bg, green trophy icon |
| 2 | **Upload Media** – "Share photos and videos from your training, matches or events" · light-blue bg, blue image icon | **Create Event** – "Add a trial, tournament, camp or sports event" · cream/yellow bg, orange calendar icon |
| 3 | **Create Opportunity** – "Post scholarship, sponsorship or tryout opportunity" · light-purple bg, purple briefcase icon | **Find / Add Team** – "Create or list your team and find team members" · pink bg, red people icon |
| 4 | **Add Academy** – "List your academy, coaching centre or training facility" · light-green bg, green building icon | **Add Coaching Service** – "List your coaching services and connect with athletes" · light-blue bg, blue whistle icon |

Card anatomy: 72px rounded-square icon tile (slightly darker tint than card) at left · bold title (18px) · 2–3 line muted description · navy `>` chevron centered right. Card radius ~20px, faint shadow.

### Quick Post Options
Five white tiles in one row (equal width, radius 14px, shadow): icon on top, label below.
- **Photo** (blue image icon), **Video** (red camera), **Text** (blue doc), **Poll** (green bars), **Achievement** (gold trophy).

---

## 6. Screen 5 – Community (Network) — wide 3-column layout

**Purpose:** social network view with feed, discovery sidebar, and suggestions. This screen is drawn wider (tablet/desktop feel) so build it responsive: stack to one column on phones.

### Layout
```
Header (Component A – search: "Search people, posts or organizations…")
Segmented top tabs (3 equal wide pills): [👥 Network*] [👥 Groups] [📅 Events]
┌───────────┬──────────────────────────────┬───────────────────────┐
│ LEFT NAV  │ CENTER FEED                  │ RIGHT SIDEBAR         │
│ Discover  │ Composer card                │ People You May Know   │
│ ▣ All*    │ Post cards…                  │ Suggested Groups      │
│ 👤Athletes│                              │ Upcoming Events       │
│ 🎓Coaches │                              │                       │
│ 🏛Academies│                             │                       │
│ ◇ Brands  │                              │                       │
│ 🛡Officials│                             │                       │
└───────────┴──────────────────────────────┴───────────────────────┘
Bottom Nav (Community active)
```
Column widths ≈ **15% | 50% | 30%**.

### Left column – "Discover"
Heading "Discover" (bold). Vertical list; each row = icon + label: **All** (active: yellow-soft pill background, grid icon), Athletes, Coaches, Academies, Brands, Officials.

### Center – Composer card
White card: user avatar + rounded grey input *"Share an update, achievement or thought…"*; below, 4 inline actions: **Photo** (blue), **Video** (red), **Achievement** (gold trophy), **Poll** (green bars).

### Center – Post cards
1. **Priya Sharma ✔ • 2h** — *U-17 Throwball Player • Gujarat 🌐* — text: "Proud to share that our team won the District Throwball Championship 2024! 🏆 Grateful to my coach and teammates for the support! ❤️" — image layout: 1 big photo left (≈60%) + 2 stacked small photos right (team huddle, gold medal). Actions: ❤ 124 · 💬 18 · ↪ 6.
2. **Arjun Patel ✔ • 5h** — *Cricket Player • Gujarat 🌐* — "Training session at Sardar Patel Stadium today. Discipline and consistency always pay off. 💪" — one wide photo (batsman). Actions: ❤ 210 · 💬 24 · ↪ 12.
3. **Dev Mehta • 1d** — *Badminton Player • Ahmedabad 🌐* — "Excited to be part of the upcoming selection camp. Looking forward to meeting new players and learning! 🚀" (cut off by nav).
Post header: avatar, name ✔, dot separator + time, second line role • location + globe icon (public), ⋮ right.

### Right sidebar cards
- **People You May Know** (+ "See All"): rows of avatar · name (✔) · role · city · yellow **Connect** button.
  Karan Joshi ✔ — Football Player, Ahmedabad; Sneha Verma ✔ — Athlete, Vadodara; Rohit Mehta — Sports Coach, Surat; Neha Patel — Badminton Player, Rajkot.
- **Suggested Groups** (+ "See All"): square thumbnail · group name · member count · grey **Join** button.
  Gujarat Athletes Network (1.2K members), Throwball Community (842), College Sports Network (1.6K), Sports Scholarships (540).
- **Upcoming Events** (+ "See All"): date tile (red month "OCT", big day) · title · 📍 location · 👥 "N interested" · chevron.
  OCT 12 Ahmedabad Throwball Trials — Ahmedabad, Gujarat — 120 interested; OCT 18 State Level Football Tournament — Vadodara, Gujarat — 340 interested; NOV 02 Badminton Selection Camp — Surat, Gujarat — 210 interested.

---

## 7. Screen 6 – More

**Purpose:** account hub / settings menu.

### Layout
```
Header: [Logo]   More / "Manage • Explore • Get Support"   [🔔3] [⚙ settings]
Profile summary card (cream/yellow-tint gradient)
List of 9 menu rows (white cards, icon tile left, title + description, chevron right)
Bottom Nav (More active)
```

### Profile summary card
- Left: circular avatar (~140px) with small white **pencil edit** badge bottom-right.
- Right: **Akshay Pandya ✔** (bold, large) · "Athlete" · 📍 "Ahmedabad, Gujarat".
- Top-right: white pill button **"View Profile >"**.
- Bottom stats row (3 columns with thin dividers): **12** Posts · **5** Connections · **68%** Profile Complete.

### Menu rows (icon tile colors in brackets)
| # | Title | Description | Icon tile |
|---|-------|-------------|-----------|
| 1 | My Profile | View and edit your profile, verification and profile completion | person (blue) |
| 2 | My Opportunities | View applied, saved and created opportunities (sponsorships, trials, scholarships) | briefcase (red/pink) |
| 3 | My Activity | My posts, achievements, events and applications | document (green) |
| 4 | My Achievements & Certificates | Manage your achievements, medals, records and certificates | trophy (yellow) |
| 5 | Saved | Saved athletes, coaches, academies, posts and opportunities | bookmark (purple) |
| 6 | Settings & Privacy | Account settings, privacy, notifications and security | gear (blue) |
| 7 | Help & Support | FAQs, report a problem, contact SportX | question-circle (red/pink) |
| 8 | About SportX | About us, terms & policies, community guidelines | info-circle (green) |
| 9 | Logout | Sign out from your account | exit arrow (red) — **row has pink bg, title in red** |

---

## 8. Screen 7 – Profile (own profile, Overview tab)

**Purpose:** full athlete profile with sections. Two-column body at tablet width; stack on phones.

### Layout
```
Top bar: [←] [SportX logo]                       [share icon] [⋮]
Cover image (rounded, ~180px tall, sunset stadium, player in "INDIA 10" jersey from behind)
Avatar (large circle ~170px, white ring) overlapping cover bottom-left, small camera badge bottom-right
Name row: "Akshay Pandya ✔" · "Cricket Player • Athlete" · 📍 Ahmedabad, Gujarat       [✎ Edit Profile] (outlined pill, top right)
Stats strip (5 cells): 12 Posts | 5 Connections | 3 Sports | 4 Achievements | [68% Profile Complete + yellow progress bar]
Bio: "Aspiring athlete and sports enthusiast. Passionate about cricket and sports development. Believes in discipline, consistency and continuous learning. 🚀"
Action buttons row (3): [✎ Edit Profile (yellow)] [Share Profile (grey-blue)] [👁 View as Public (grey-blue)]
Tabs: Overview* · Posts · Achievements · Media · Connections   (active = yellow text + yellow underline)
Body: 2 columns (LEFT ≈48% | RIGHT ≈52%)
```

### Left column cards
1. **About** (icon: person, "Edit" link right) – key/value rows with small icons:
   Full Name: Akshay Pandya · Role: Athlete (Cricket) · Location: Ahmedabad, Gujarat · Age Group: 18 – 21 years · College: B.Com, Ahmedabad · Interests: Cricket, Football, Fitness, Sports Development.
2. **Media** ("View All") – 3×2 thumbnail grid (rounded); some tiles carry a small video-camera badge; last tile is dark overlay with **"+4"**.
3. **Social Links** ("Edit") – three icons with labels: **Instagram**, **LinkedIn**, **YouTube**.

### Right column cards
1. **Sports** ("Manage" link) – sub-card: cricket-bat/ball thumbnail, **Cricket**, yellow chip **"Primary Sport"**; three mini-fields: Playing Role: Batsman · Playing Level: College / District · Experience: 5+ years. Below: dashed-border button **"⊕ Add Another Sport"**.
2. **Achievements** ("View All") – 3 rows each with tinted icon tile, title, subtitle and ⋮:
   - District Throwball Championship 2024 — *Team Winner • Gujarat* (medal icon, yellow)
   - NCC B Certificate (A Grade) — *NCC • 2024* (certificate icon, pink)
   - 1st Rank – GK Competition — *Bhavnagar Level • 2023* (trophy, yellow)
   Then full-width tinted button **"⊕ Add Achievement"**.
3. **Connections** ("View All") – row of 4 circular avatars with name + role (Rohit/Coach, Priya/Athlete, Karan/Player, Sneha/Player) and a 5th grey circle **"+12 More"**.

---

## 9. Screen 8 – Notifications

### Layout
```
Header: [←] [Logo]   Notifications   [⚙]
Filter chips (scroll): [🔔 All*] [👥 People] [📅 Opportunities] [📅 Events] [@ Mentions]   (active underlined in yellow)
Section "Today"          (right: "Mark all as read" blue link)
Section "Yesterday"
Section "This Week"
Section "Earlier"
```
Each notification = white card row: **blue unread dot** at far left · circular avatar or tinted icon circle · bold-highlighted sentence + muted meta line (time) · optional right-side element (thumbnail 130×80 rounded, yellow "Follow back" button, or chevron). Read/older items lack the dot.

### Items
| Section | Icon/Avatar | Text | Meta | Right element |
|---------|-------------|------|------|----------------|
| Today | Priya avatar | **Priya Sharma** started following you. | 2 minutes ago | yellow **Follow back** button |
| Today | yellow trophy circle | Your achievement **"District Throwball Championship 2024"** got 25 likes. | 18 minutes ago | team photo thumbnail |
| Today | red calendar circle | **New sponsorship opportunity** matching your profile. | Sports Equipment Brand • Open for applications · 1 hour ago | "SPORTS BRAND" dark thumbnail |
| Today | blue calendar circle | **Ahmedabad Football Trials 2026** is happening near you. | 12 Jan 2026 • Ahmedabad · 2 hours ago | football-on-grass thumbnail |
| Yesterday | Rohit Mehta avatar | **Rohit Mehta** liked your post. | Yesterday, 7:30 PM | cricket photo thumbnail |
| This Week | green chat-bubble circle | **Sneha Verma** commented on your post. "Great performance! 🔥" | 2 days ago | team photo thumbnail |
| This Week | purple people circle | You have been added to **Gujarat Athletes Network** group. | 3 days ago | chevron `>` |
| Earlier | red "@" circle | You were mentioned in a post by **Karan Joshi**. "@Akshay Pandya check this opportunity." | 5 days ago | "TRIALS OPEN" thumbnail |
| Earlier | blue shield-check circle | Your profile verification is under review. | 1 week ago | chevron `>` |

Bottom nav is NOT shown on this screen.

---

## 10. Screen 9 – Leaderboard

### Layout
```
Header: [←] [Logo]   Leaderboard   [ⓘ info]
Entity tabs: [👤 Athletes*] [🎓 Coaches] [🏛 Academies] [👥 Teams] [🏆 Events]   (active = yellow, with underline)
Sport chips: [All Sports*] [Cricket] [Football] [Badminton] [Athletics] [Throwball] [••• More]
Title block:  👑 Top Athletes  + "Based on performance, achievements and overall activity"
  Right side dropdowns: [📍 India ⌄] [👥 All Age Groups ⌄]
Podium (3 cards, order: 2nd · 1st · 3rd; 1st is taller/raised & highlighted yellow)
Ranked table (rows #4–#10)
[View Full Leaderboard >] (white pill button, centered)
Bottom Nav (none highlighted)
```

### Podium
| Position | Card style | Name | Sport | State | Points | Button |
|----------|-----------|------|-------|-------|--------|--------|
| 2 (left) | light-grey bg, silver ribbon medal "2" | Priya Sharma ✔ | Throwball | Gujarat | 1,250 pts | grey **View Profile** |
| 1 (center, taller) | light-yellow bg, gold ribbon medal "1" | Arjun Patel ✔ | Cricket | Gujarat | 1,480 pts | yellow **View Profile** |
| 3 (right) | light-peach bg, bronze ribbon medal "3" | Sneha Verma ✔ | Badminton | Maharashtra | 1,120 pts | peach **View Profile** |
Each: large circular avatar (~110px), name + badge, sport icon + sport, pin icon + state, bold points.

### Table (columns: # | Athlete | Sport | Location | Points | action)
| # | Athlete | Sub-label | Sport | Location | Points |
|---|---------|-----------|-------|----------|--------|
| 4 | Rohit Mehta ✔ | U-19 Player | Football | Surat | 980 |
| 5 | Kavya Desai ✔ | U-17 Athlete | Athletics | Vadodara | 920 |
| 6 | Dev Patel | – | Volleyball | Ahmedabad | 890 |
| 7 | Ishita Singh | – | Basketball | Rajkot | 860 |
| 8 | Manav Joshi ✔ | – | Hockey | Gandhinagar | 820 |
| 9 | Riya Mehta | – | Swimming | Mumbai | 780 |
| 10 | Karan Shah | – | Table Tennis | Ahmedabad | 760 |
Every row: avatar (44px) + name, sport icon + text, pin + city, bold points, grey **Follow** button at right (rounded rect, light fill). Header row is muted text on a white card.

---

## 11. Screen 10 – Academies (Find an Academy)

### Layout
```
Header: [←] [Logo]  Academies   [📍 Ahmedabad ⌄ (pill)] [🗺 map icon]
Search bar: 🔍 "Search academies, coaches or training…"
Sport chips: [▦ All Sports*] [Cricket] [Football] [Badminton] [Swimming] [Athletics] [••• More]
Hero banner (dark overlay photo of coach with kids):
    "Find the " (white) + "Right Academy" (yellow)
    "Discover trusted academies, certified coaches and professional training programs near you."
Segmented tabs (3): [🏛 Academies*] [Coaches] [Training]
Filter dropdown chips: [📍 Location ⌄] [Sport ⌄] [Age Group ⌄] [☰ Facilities ⌄] [↕ Sort ⌄]
Vertical list of academy cards
Bottom Nav
```

### Academy list card (horizontal card)
- **Left:** photo (~270×145, rounded) with image-carousel dots bottom-left (first academy also has a dark pill badge **"👑 Elite Academy"** bottom-left).
- **Right, top:** name (bold 20px) + verified ✔; at far right ⭐ **rating** bold with review count in parentheses.
- Line: 📍 area, city • distance (e.g., "Motera, Ahmedabad • 2.5 km").
- Tag chips (grey-blue pills): sport, age range, program type.
- Facility row with small outline icons (4 items).
- Yellow **View Details** button aligned right under the rating.

### Data
| Academy | Area • Distance | Chips | Facilities | Rating |
|---------|-----------------|-------|------------|--------|
| Narendra Modi Cricket Academy ✔ (Elite badge) | Motera, Ahmedabad • 2.5 km | Cricket · Age 8 – 21 · Professional Coaching | Certified Coaches · Indoor Nets · Fitness Training · Match Exposure | 4.8 (320) |
| Ahmedabad Football Academy ✔ | Bopal, Ahmedabad • 6.1 km | Football · Age 6 – 18 · Skill Development | Grass Turf · Certified Coaches · Video Analysis · Tournaments | 4.6 (210) |
| Gujarat Badminton Academy ✔ | Thaltej, Ahmedabad • 4.8 km | Badminton · Age 8 – 21 · Advanced Training | Indoor Courts · Certified Coaches · Fitness & Conditioning · State Level Exposure | 4.7 (180) |
| Aquasport Swimming Academy ✔ | Vastrapur, Ahmedabad • 5.3 km | Swimming · Age 5 – 18 · Beginner to Advanced | Olympic Pool · Certified Coaches · Safety & Lifeskills · Competitions | 4.5 (140) |
| Sardar Patel Sports Academy ✔ | Navrangpura, Ahmedabad • 3.9 km | Athletics · Age 8… · High Performance | (cut off) | 4.4 (110) |

---

## 12. Navigation Map

```
Bottom Nav
├── Home  ──► Leaderboard (View All) · Opportunities · Academy/Coach/Training (→ Academies) · Notifications (bell) · Profile (avatar)
├── Explore ─► Explore-Athletes (See All / Athletes chip) · Coaches · Academies · Events · Opportunities
├── Create (+) ─► Create hub (8 actions + 5 quick posts)
├── Community ─► Network / Groups / Events tabs
└── More ─► Profile · My Opportunities · My Activity · Achievements · Saved · Settings · Help · About · Logout
```
Sub-screens (Notifications, Leaderboard, Academies, Profile) use a **back arrow** and hide or de-emphasize the bottom-nav active state.

---

## 13. HTML/CSS Build Guide

### 13.1 Suggested CSS variables
```css
:root{
  --primary:#FFC72C; --primary-soft:#FFEFB8; --primary-tint:#FFF8E5;
  --navy:#0F1B3D; --muted:#5B6785; --bg:#F6F8FD; --card:#fff;
  --blue:#1E6CF0; --blue-tint:#E8F0FF; --red:#E5334B; --green:#22A559; --purple:#7B3FE4;
  --radius-card:18px; --radius-btn:10px; --radius-pill:999px;
  --shadow:0 4px 16px rgba(20,30,70,.07);
  --pad:16px;
}
body{font-family:'Plus Jakarta Sans',system-ui,sans-serif;background:var(--bg);color:var(--navy);margin:0}
```

### 13.2 Key layout recipes
- **Mobile shell:** `max-width:430px; margin:auto; padding-bottom:110px` (space for bottom nav).
- **Bottom nav:** `position:fixed; bottom:0; display:grid; grid-template-columns:repeat(5,1fr); background:#fff; border-radius:24px 24px 0 0; box-shadow:0 -4px 20px rgba(0,0,0,.08)`; center item has `.fab{width:64px;height:64px;border-radius:50%;background:var(--primary);margin-top:-32px;box-shadow:0 6px 16px rgba(255,199,44,.5)}`.
- **Horizontal carousels:** `display:flex; gap:12px; overflow-x:auto; scroll-snap-type:x mandatory;` cards `flex:0 0 160px` (athletes/coaches/academies) or `flex:0 0 230px` (events).
- **Explore grid:** `display:grid; grid-template-columns:1fr 1fr; gap:12px`.
- **Post collage:** `display:grid; grid-template-columns:1.1fr 1fr 1fr; grid-template-rows:1fr 1fr; gap:4px;` first image `grid-row:span 2`.
- **Create hub:** `display:grid; grid-template-columns:1fr 1fr; gap:14px`; quick-post row `grid-template-columns:repeat(5,1fr)`.
- **Community desktop:** `display:grid; grid-template-columns:180px 1fr 320px; gap:16px`; collapse to 1 column under 900px.
- **Profile body:** `grid-template-columns:1fr 1fr`; collapse under 700px.
- **Leaderboard podium:** `display:grid; grid-template-columns:1fr 1.1fr 1fr; align-items:end` (center card taller).
- **Academy card:** `display:grid; grid-template-columns:270px 1fr` (stack under 600px).
- **Progress bar:** track `#E6EAF2` height 8px radius 99px; fill `var(--primary)` width = %.
- **Verified badge:** inline SVG circle `#1E6CF0` with white check, 16px.

### 13.3 Component checklist (build once, reuse)
`Header`, `SubHeader`, `BottomNav`, `Chip`, `ChipRow`, `TabUnderline`, `SegmentedTabs`, `Button(primary/secondary/outline/dashed)`, `SectionHeader (title + See All pill)`, `AthleteCard`, `CoachCard`, `AcademyCard(vertical)`, `AcademyListCard(horizontal)`, `EventCard`, `OpportunityCard`, `PostCard`, `PhotoCollage`, `LeaderboardStrip`, `PodiumCard`, `RankRow`, `NotificationRow`, `MenuRow`, `ActionCard(Create)`, `QuickTile`, `StatCell`, `InfoRow(key/value)`, `VerifiedBadge`, `KebabMenu`, `BookmarkButton`.

### 13.4 Assets to prepare
- Logo (SVG): "Sport" black + "X" yellow with two-line tagline.
- Avatar portraits (Indian athletes), cover photo, stadium/sunset action photos, academy building photos, event banners → use placeholders (`https://picsum.photos` or local files) since no remote images are needed at spec level.
- Icons: use **Lucide** or **Phosphor** (outline) – bell, search, compass, home, users, grid, plus, bookmark, heart, message-circle, send, map-pin, calendar, trophy, briefcase, graduation-cap, building, dumbbell, handshake, shield-check, settings, help-circle, info, log-out, filter/sliders, chevron-right/down, arrow-left, camera, video, image, bar-chart.

### 13.5 Interaction notes
- Chips/tabs: single-select, active state = yellow fill (chips) or yellow text + underline (tabs).
- Follow/Connect buttons: toggle to "Following"/"Requested" (grey) on click.
- Bookmark: toggles filled state.
- Heart: toggles red fill and increments count.
- Progress banner "Complete Now" → Profile edit.
- Notification bell badge count → Notifications screen; avatar → Profile.
- Center "+" → opens Create hub.
