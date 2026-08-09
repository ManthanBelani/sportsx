# SportX Admin Web Panel — Implementation Prompt

**Design Reference:** `sportsx/src/screens/admin.tsx`
**Backend:** `sportx-api/` (Laravel)
**Design System:** `sportsx/src/imports/SportX_Design_System.md`

---

## Overview

Create a standalone admin web panel with:
- **Frontend:** HTML5 + CSS3 (pure, no JS frameworks)
- **Backend:** Laravel Blade templates (integrated with existing `sportx-api`)
- **Design:** Must match admin screens in `sportsx/src/screens/admin.tsx` exactly

---

## Design Requirements

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Primary Blue | `#2563EB` | Buttons, active nav, links |
| CTA Orange | `#F97316` | CTA buttons, highlights |
| Text Primary | `#111827` | Headings, body text |
| Text Secondary | `#6B7280` | Meta, captions |
| Surface | `#F8FAFC` | Card backgrounds |
| Border | `#E5E7EB` | Dividers, borders |
| Success | `#22C55E` | Verified, approved |
| Error | `#EF4444` | Errors, delete |
| Warning | `#F59E0B` | Pending, draft |

### Typography

- Font: **Poppins** (Google Fonts)
- Headings: 700 weight
- Body: 400/500 weight
- Captions: 12px

### Spacing & Radius

- Spacing: 8px base grid
- Cards: 16px border-radius
- Buttons: 12px border-radius
- Inputs: 12px border-radius
- Shadows: `0 2px 12px rgba(0,0,0,0.08)` for cards

---

## Layout Structure

Match `AdminWebLayout` from `sportsx/src/screens/admin.tsx`:

```
┌─────────────────────────────────────────────────────────┐
│ Sidebar (256px)     │  Main Content Area             │
│ w-64                │                                │
│ [SX] SportX Admin   │ ┌─ TopBar ──────────────────┐ │
│                      │ │ h-16 (64px)               │ │
│ 📊 Dashboard        │ │ px-8 (32px)               │ │
│ 👥 Manage Users     │ └────────────────────────────┘ │
│ ✅ Approvals         │                                │
│ 🚨 Moderation       │ ┌─ Content ────────────────┐ │
│ 🤝 Opportunities    │ │ max-w-5xl (~1024px)      │ │
│ 🔔 Notifications    │ │ p-8 (32px padding)       │ │
│ 📈 Reports          │ │ flex gap-6 (24px)         │ │
│                      │ │                            │ │
│                      │ │                            │ │
│                      │ └────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**Key measurements from admin.tsx:**
- Sidebar: `w-64` (256px), border-right `border-gray-200`
- TopBar: `h-16` (64px), `px-8` (32px horizontal padding)
- Content: `p-8` (32px padding), `max-w-5xl` (1024px max-width), `gap-6` (24px between items)
- Card border-radius: `rounded-xl` (12px in Tailwind, matches 16px design spec)
- Sidebar nav items: `py-2.5 px-3 rounded-lg`

---

## Pages to Build

### 1. Login Page (`admin/login.blade.php`)

```
┌──────────────────────────────────┐
│                                  │
│         [Logo]                  │
│       SportX Admin               │
│                                  │
│   ┌──────────────────────────┐   │
│   │ Email                  │   │
│   └──────────────────────────┘   │
│   ┌──────────────────────────┐   │
│   │ Password                │   │
│   └──────────────────────────┘   │
│                                  │
│   [    Sign In    ] (btn-primary)│
│                                  │
│   2FA Step (after login):       │
│   ┌──────────────────────────┐   │
│   │ Enter 6-digit code      │   │
│   └──────────────────────────┘   │
│   [    Verify    ]              │
│                                  │
└──────────────────────────────────┘
```

### 2. Dashboard (`admin/dashboard.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│  Good Morning, Admin                                   │
│  Here's today's overview                                │
│                                                         │
│  QUICK STATS                                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐               │
│  │ 1,245   │ │   89    │ │   12    │               │
│  │Total    │ │Pending  │ │Reports  │               │
│  │Users    │ │Approvals│ │Today    │               │
│  └──────────┘ └──────────┘ └──────────┘               │
│                                                         │
│  USER BREAKDOWN                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 👤 Athletes     892                             │   │
│  │ 🏫 Coaches     187                             │   │
│  │ 🤝 Sponsors    166                             │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  RECENT ACTIVITY                                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 👤 New athlete registration: Priya Patel  2m ago │   │
│  │ 🏫 New academy added: Delhi Cricket     15m ago  │   │
│  │ ⚠️ Content report flagged for review    1h ago   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  QUICK ACTIONS                                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                  │
│  │  👥     │ │  ✅     │ │  🚨     │                  │
│  │ Users   │ │ Approve │ │ Reports │                  │
│  └─────────┘ └─────────┘ └─────────┘                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                  │
│  │  🔔     │ │  🤝     │ │  📊     │                  │
│  │ Notify  │ │  Opp    │ │ Stats   │                  │
│  └─────────┘ └─────────┘ └─────────┘                  │
└─────────────────────────────────────────────────────────┘
```

### 3. Manage Users (`admin/users.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│ ← Back        Manage Users                    🔍        │
├─────────────────────────────────────────────────────────┤
│  [All] [Athletes] [Coaches] [Sponsors]  (tab pills)    │
│                                                         │
│  [Verified ▼] [Active ▼]  (filter chips)              │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Avatar] Priya Patel           👤 · Mumbai · ✓  │   │
│  │           👤 Athlete · Unverified · 🟢 Active   │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Avatar] Arjun Kumar           👤 · Delhi · ✓   │   │
│  │           👤 Athlete · Verified · 🔴 Inactive    │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 4. User Detail (`admin/user-detail.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│ ← Back        User Detail                      ⋯      │
├─────────────────────────────────────────────────────────┤
│                    [Avatar 80px]                      │
│                  Rohan Sharma                          │
│                  👤 Athlete · Mumbai, MH               │
│                  Status: Unverified (amber)            │
│                                                         │
│  PROFILE INFO                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Email        rohan@email.com                    │   │
│  │ Phone        +91 98765 43210                   │   │
│  │ Joined       Oct 15 2024                       │   │
│  │ Last Active  Today                             │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  VERIFICATION                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 📜 State Championship 2024                     │   │
│  │    Achievement Certificate    [View Document]   │   │
│  ├─────────────────────────────────────────────────┤   │
│  │ 🏏 Mumbai Premier League                        │   │
│  │    Participation Certificate  [View Document]   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  [✓ Verify & Add Badge] (btn-success)                 │
│  [Suspend Account] (amber outlined)                    │
│  [🗑 Delete Account] (btn-danger)                      │
└─────────────────────────────────────────────────────────┘
```

### 5. Pending Approvals (`admin/approvals.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│ ← Back        Pending Approvals                         │
├─────────────────────────────────────────────────────────┤
│  NEW REGISTRATIONS (5)                                 │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Avatar] Kavya Singh                           │   │
│  │           👤 Athlete · Hyderabad                  │   │
│  │           Registered: Today                     │   │
│  │  [Reject]  [Approve]                         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Avatar] Manish Reddy                          │   │
│  │           👤 Athlete · Pune                      │   │
│  │           Registered: Today                     │   │
│  │  [Reject]  [Approve]                         │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 6. Moderation Queue (`admin/moderation.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│ ← Back        Moderation Queue                         │
├─────────────────────────────────────────────────────────┤
│  [All] [Posts] [Comments] [Profiles]  (tab pills)      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ⚠️ Reported Post #12345                         │   │
│  │     Reported by: Priya Patel                    │   │
│  │     Reason: Inappropriate content               │   │
│  │     10m ago                                    │   │
│  │  [Review →]                                    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ⚠️ Reported Comment #12344                       │   │
│  │     Reported by: Arjun Kumar                    │   │
│  │     Reason: Spam                                │   │
│  │     45m ago                                    │   │
│  │  [Review →]                                    │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 7. Report Detail (`admin/report-detail.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│ ← Back        Report #12345                             │
├─────────────────────────────────────────────────────────┤
│  REPORT INFO                                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Reported by    Priya Patel                      │   │
│  │ Reason        Inappropriate content              │   │
│  │ Reported time Today at 10:30 AM                │   │
│  │ Status        Pending Review (amber)            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  REPORTED CONTENT                                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Avatar] Rahul Mehta                           │   │
│  │           Cricket · Delhi                        │   │
│  │                                                 │   │
│  │ This post was flagged for potentially violating │   │
│  │ community guidelines...                          │   │
│  │  [View Full Content →]                          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ACTIONS                                               │
│  [✓ Dismiss Report] (secondary)                        │
│  [🗑 Remove Content] (btn-danger)                      │
│  [🚫 Suspend User] (btn-danger)                       │
└─────────────────────────────────────────────────────────┘
```

### 8. Compose Notification (`admin/notification-compose.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│ ← Back        Compose Notification              [Send]   │
├─────────────────────────────────────────────────────────┤
│  Notification Title *                                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ e.g., Trial Announcement                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Message Body *                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Enter your notification message...               │   │
│  │                                                 │   │
│  │                                                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  TARGETING (Optional)                                  │
│                                                         │
│  Target Role                                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │ All Roles ▼                                     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Target Region                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │ All Regions ▼                                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Target Sport                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │ All Sports ▼                                    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Estimated Reach: ~1,245 users                          │
│                                                         │
│  [Send Notification] (btn-primary)                      │
└─────────────────────────────────────────────────────────┘
```

### 9. Platform Reports (`admin/reports.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│ ← Back        Platform Reports                          │
├─────────────────────────────────────────────────────────┤
│  USERS BY ROLE                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Athletes  ████████████████████░░░░ 71.6%  892 │   │
│  │ Coaches   █████░░░░░░░░░░░░░░░░░░░░  15.0%  187 │   │
│  │ Sponsors ████░░░░░░░░░░░░░░░░░░░░░  13.3%  166 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  USERS BY REGION                                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Maharashtra                          312          │   │
│  │ Delhi                               198          │   │
│  │ Karnataka                           156          │   │
│  │ Telangana                           124          │   │
│  │ Tamil Nadu                           98          │   │
│  │                        [View All Regions →]    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  USERS BY SPORT                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Cricket                                 445      │   │
│  │ Football                               267      │   │
│  │ Athletics                              189      │   │
│  │ Badminton                             134      │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ACTIVITY METRICS                                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │ New registrations (7d)                45        │   │
│  │ Active users (7d)                   678        │   │
│  │ Posts (7d)                          123        │   │
│  │ Connections (7d)                      89        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 10. Opportunity Approvals (`admin/opportunities.blade.php`)

```
┌─────────────────────────────────────────────────────────┐
│ ← Back        Opportunity Approvals                     │
├─────────────────────────────────────────────────────────┤
│  PENDING (4)                                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Logo] Youth Cricket Program 2024              │   │
│  │        Adidas India                            │   │
│  │        Cricket · Maharashtra                    │   │
│  │        Submitted: Today                        │   │
│  │  [Reject]  [Approve]                         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Logo] Women in Sports Fund                    │   │
│  │        Puma Sports                              │   │
│  │        Athletics · Pan-India                     │   │
│  │        Submitted: Yesterday                      │   │
│  │  [Reject]  [Approve]                         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  RECENTLY APPROVED                                     │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Logo] Athlete Sponsorship 2024                  │   │
│  │        Nike India                    [View]       │   │
│  │        Approved: Oct 12 2024                     │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## CSS Classes

```css
/* Layout */
.sidebar { width: 256px; background: #FFFFFF; border-right: 1px solid #E5E7EB; }
.main-content { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
.topbar { height: 64px; border-bottom: 1px solid #E5E7EB; padding: 0 32px; }
.content { flex: 1; overflow-y: auto; padding: 32px; }
.content-inner { max-width: 1024px; margin: 0 auto; display: flex; flex-direction: column; gap: 24px; }

/* Cards */
.card {
  background: #FFFFFF;
  border: 0.5px solid #E5E7EB;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.08);
}
.card-padded { padding: 16px; }

/* Buttons */
.btn {
  height: 48px;
  border-radius: 12px;
  font-weight: 600;
  font-size: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  cursor: pointer;
  border: none;
  transition: all 0.15s ease;
}
.btn-primary { background: #2563EB; color: #FFFFFF; }
.btn-primary:hover { background: #1D4ED8; }
.btn-cta { background: #F97316; color: #FFFFFF; }
.btn-cta:hover { background: #EA6C0A; }
.btn-success { background: #22C55E; color: #FFFFFF; }
.btn-danger { background: #EF4444; color: #FFFFFF; }
.btn-secondary { background: transparent; border: 1.5px solid #2563EB; color: #2563EB; }
.btn-ghost { background: transparent; color: #2563EB; font-weight: 600; }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }

/* Inputs */
.input {
  background: #F8FAFC;
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  height: 52px;
  padding: 0 16px;
  font-size: 14px;
  width: 100%;
  font-family: 'Poppins', sans-serif;
}
.input:focus { outline: none; border: 2px solid #2563EB; background: #FFFFFF; }
.textarea { min-height: 100px; padding: 12px 16px; resize: vertical; }

/* Badges */
.badge { display: inline-flex; align-items: center; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; }
.badge-success { background: #DCFCE7; color: #22C55E; }
.badge-warning { background: #FEF3C7; color: #F59E0B; }
.badge-error { background: #FEE2E2; color: #EF4444; }
.badge-blue { background: #EFF6FF; color: #2563EB; }

/* Tab Pills */
.tab-pills { display: flex; gap: 8px; }
.tab-pill {
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  background: #F8FAFC;
  color: #6B7280;
  border: none;
}
.tab-pill.active { background: #2563EB; color: #FFFFFF; }

/* Filter Chips */
.filter-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
  background: #F8FAFC;
  border: 1px solid #E5E7EB;
  color: #6B7280;
  cursor: pointer;
}
.filter-chip.active { background: #EFF6FF; border-color: #2563EB; color: #2563EB; }

/* Section Label */
.section-label {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #6B7280;
  margin-bottom: 12px;
}

/* Avatar */
.avatar { border-radius: 50%; object-fit: cover; }
.avatar-sm { width: 40px; height: 40px; }
.avatar-md { width: 48px; height: 48px; }
.avatar-lg { width: 80px; height: 80px; }

/* Divider */
.divider { height: 1px; background: #E5E7EB; margin: 16px 0; }

/* Stats Card */
.stat-card { display: flex; flex-direction: column; align-items: center; padding: 24px; gap: 8px; }
.stat-value { font-size: 28px; font-weight: 700; color: #111827; }
.stat-label { font-size: 12px; color: #6B7280; }
```

---

## Backend Integration

**API Base:** `/api/v1/admin`
**Auth Token:** Bearer token stored in session

### Authentication

```php
// POST /api/v1/admin/login
// Request: {email, password}
// Response: {token, user: {id, name, email, role}, requires_2fa}

// POST /api/v1/admin/verify-2fa
// Request: {code}
// Response: {user: {id, name, email, role, admin_2fa_verified_at}}

// POST /api/v1/admin/logout
// Headers: Authorization: Bearer {token}
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/dashboard` | Stats: active_listings, flagged_items, pending_expirations, new_signups_30d |
| GET | `/api/v1/admin/content` | Category picker with counts |
| GET | `/api/v1/admin/content/{type}` | Paginated list (type = academies/coaches/trials/tournaments/scholarships/sponsorships/sports_venues) |
| GET | `/api/v1/admin/content/{type}/{id}` | Single item |
| POST | `/api/v1/admin/content/{type}` | Create |
| PUT | `/api/v1/admin/content/{type}/{id}` | Update |
| DELETE | `/api/v1/admin/content/{type}/{id}` | Delete |
| GET | `/api/v1/admin/moderation/queue` | Reports list |
| POST | `/api/v1/admin/moderation/reports/{id}/approve` | Approve report |
| POST | `/api/v1/admin/moderation/reports/{id}/remove` | Remove listing |
| POST | `/api/v1/admin/moderation/reports/{id}/warn` | Warn owner |
| GET | `/api/v1/admin/expiry/monitor?tab=pending` | Expiry events (pending/expired/overridden) |
| POST | `/api/v1/admin/expiry/events/{id}/override` | Override expiry |
| POST | `/api/v1/admin/expiry/events/{id}/restore` | Restore listing |
| GET | `/api/v1/admin/categories/sports` | Sports list |
| POST | `/api/v1/admin/categories/sports` | Add sport |
| PUT | `/api/v1/admin/categories/sports/{id}` | Update sport |
| DELETE | `/api/v1/admin/categories/sports/{id}` | Delete sport |
| GET | `/api/v1/admin/categories/cities` | Cities list |
| POST | `/api/v1/admin/categories/cities` | Add city |
| PUT | `/api/v1/admin/categories/cities/{id}` | Update city |
| DELETE | `/api/v1/admin/categories/cities/{id}` | Delete city |
| GET | `/api/v1/admin/categories/age-groups` | Age groups list |
| POST | `/api/v1/admin/categories/age-groups` | Add age group |
| PUT | `/api/v1/admin/categories/age-groups/{id}` | Update age group |
| DELETE | `/api/v1/admin/categories/age-groups/{id}` | Delete age group |

---

## File Structure

```
sportx-api/
├── resources/views/admin/
│   ├── layouts/
│   │   └── main.blade.php      # Shared layout with sidebar
│   ├── login.blade.php
│   ├── dashboard.blade.php
│   ├── users.blade.php
│   ├── user-detail.blade.php
│   ├── approvals.blade.php
│   ├── moderation.blade.php
│   ├── report-detail.blade.php
│   ├── notification-compose.blade.php
│   ├── opportunities.blade.php
│   └── reports.blade.php
├── public/admin/css/
│   └── admin.css               # All admin styles
├── public/admin/js/
│   └── admin.js                # API calls, interactions
└── routes/web.php              # Admin routes
```

---

## Routes (web.php)

```php
Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AdminController::class, 'login'])->name('login');
    Route::post('/login', [AdminController::class, 'authenticate']);
    Route::post('/verify-2fa', [AdminController::class, 'verify2fa'])->name('verify2fa');
    Route::post('/logout', [AdminController::class, 'logout'])->name('logout');

    Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
        Route::get('/dashboard', [AdminController::class, 'dashboard'])->name('dashboard');
        Route::get('/users', [AdminController::class, 'users'])->name('users');
        Route::get('/users/{id}', [AdminController::class, 'userDetail'])->name('users.detail');
        Route::get('/approvals', [AdminController::class, 'approvals'])->name('approvals');
        Route::get('/moderation', [AdminController::class, 'moderation'])->name('moderation');
        Route::get('/moderation/{id}', [AdminController::class, 'reportDetail'])->name('moderation.detail');
        Route::get('/notifications/compose', [AdminController::class, 'composeNotification'])->name('notifications.compose');
        Route::get('/opportunities', [AdminController::class, 'opportunities'])->name('opportunities');
        Route::get('/reports', [AdminController::class, 'reports'])->name('reports');
    });
});
```

---

## Implementation Checklist

- [ ] Create `resources/views/admin/layouts/main.blade.php`
- [ ] Create `public/admin/css/admin.css` with all styles
- [ ] Create `public/admin/js/admin.js` for API calls
- [ ] Create login page with 2FA flow
- [ ] Create dashboard with stats and activity
- [ ] Create users management page
- [ ] Create user detail page
- [ ] Create approvals page
- [ ] Create moderation queue page
- [ ] Create report detail page
- [ ] Create notification compose page
- [ ] Create opportunities page
- [ ] Create platform reports page
- [ ] Add admin routes to `routes/web.php`
- [ ] Create AdminController with all methods
- [ ] Test API integration
- [ ] Test authentication flow
