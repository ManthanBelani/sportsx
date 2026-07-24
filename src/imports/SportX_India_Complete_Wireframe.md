# SportX India — Complete App Wireframe Specification
**Version:** 1.0 MVP | **Platform:** Flutter (Android) + Web Admin Panel | **Total Screens:** 63 Unique Screens

---

## Table of Contents
1. [Design System Quick Reference](#1-design-system-quick-reference)
2. [Global Components](#2-global-components)
3. [Authentication & Onboarding (7 Screens)](#3-authentication--onboarding-7-screens)
4. [Athlete Screens (17 Screens)](#4-athlete-screens-17-screens)
5. [Coach / Academy Screens (8 Screens)](#5-coach--academy-screens-8-screens)
6. [Sponsor Screens (9 Screens)](#6-sponsor-screens-9-screens)
7. [Shared Screens (11 Screens)](#7-shared-screens-11-screens)
8. [Admin Screens — Mobile (11 Screens)](#8-admin-screens--mobile-11-screens)
9. [Navigation Flow Diagrams](#9-navigation-flow-diagrams)
10. [State & Interaction Specifications](#10-state--interaction-specifications)

---

## 1. Design System Quick Reference

### Color Palette
| Token | Hex | Usage |
|---|---|---|
| Primary Blue | `#2563EB` | Primary buttons, active nav, links, app bar accents |
| CTA Orange | `#F97316` | CTA buttons, FAB, badges, highlights |
| White | `#FFFFFF` | Screen backgrounds, card surfaces, nav bar |
| Surface Gray | `#F8FAFC` | Card backgrounds, input fields, section fills |
| Border | `#E5E7EB` | Card borders, dividers, input borders |
| Text Primary | `#111827` | Headings, body text, labels |
| Text Secondary | `#6B7280` | Subtitles, meta info, hints, timestamps |
| Success Green | `#22C55E` | Verified badge, accepted status, connected state |
| Error Red | `#EF4444` | Errors, suspended status, rejected status |
| Warning Amber | `#F59E0B` | Pending approval, draft state |
| Info Blue Light | `#EFF6FF` | Unread notification background, info banners |

### Typography (Poppins)
| Role | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| Display | 28px | 700 Bold | 1.2 | Screen titles, onboarding headings |
| H1 | 22px | 700 Bold | 1.3 | Profile names, major section titles |
| H2 | 18px | 600 SemiBold | 1.35 | Welcome greetings, card section titles |
| H3 | 16px | 600 SemiBold | 1.4 | Sub-section titles, tab labels |
| Body | 14px | 400 Regular | 1.5 | Body copy, card descriptions, post text |
| Body SemiBold | 14px | 600 SemiBold | 1.5 | Button labels, stat values, names in lists |
| Caption | 12px | 400 Regular | 1.4 | Timestamps, meta info, section labels |
| Caption SemiBold | 12px | 600 SemiBold | 1.4 | Tags, chips, small badges |

### Spacing (8px Base Grid)
- Screen horizontal padding: **16px** left/right
- Card internal padding: **16px**
- Between sections: **24px**
- Between cards: **8px** gap
- Screen-level top/bottom padding: **40px**

### Border Radius
- Cards: **16px** | Buttons: **12px** | Input fields: **12px** | Chips/Tags: **20px** (pill) | Avatars: **50%** | Bottom sheets: **20px** top corners | Media tiles: **8px**

### Shadows
- Cards: `0 2px 12px rgba(0,0,0,0.08)` | Bottom sheets: `0 4px 20px rgba(0,0,0,0.12)` | FAB: `0 4px 12px rgba(249,115,22,0.30)` | Blue buttons: `0 4px 12px rgba(37,99,235,0.25)` | Bottom nav: `0 -1px 8px rgba(0,0,0,0.06)`

---

## 2. Global Components

### 2.1 App Bar
```
+-----------------------------------------+
| [<-]  Screen Title (18px SemiBold)  [🔔][⚙️] |
+-----------------------------------------+
| 0.5px border #E5E7EB (bottom)           |
+-----------------------------------------+
```
- **Height:** 56px | **Background:** #FFFFFF | **Left:** Back arrow OR app logo | **Center:** Screen title (18px SemiBold, #111827) | **Right:** Max 2 action icons (40x40px circular, #F8FAFC bg, #6B7280 icon) | **No shadow** — flat with bottom border only

### 2.2 Bottom Navigation Bar
```
+-----------------------------------------+
|  [🏠]   [🔍]   [➕]   [💬]   [👤]      |
|  Home  Discover Create Messages Profile |
|      ● (active underline dot)           |
+-----------------------------------------+
```
- **Height:** 64px | **Background:** #FFFFFF | **Top border:** 0.5px solid #E5E7EB | **Shadow:** `0 -1px 8px rgba(0,0,0,0.06)` | **5 tabs (Athlete):** Home, Discover, Create, Messages, Profile | **4 tabs (Coach):** Home, Discover, Notifications, Profile | **4 tabs (Sponsor):** Home, Discover, Post Opp, Profile | **Icon:** 24px | **Label:** 10px SemiBold | **Active:** #2563EB + 3px underline dot | **Inactive:** #9CA3AF | **FAB (center, Athlete):** 52x52px circle, #F97316, white 24px icon, shadow-orange, offset -12px from nav top

### 2.3 Tab Pills (Horizontal Scroll)
- **Active:** bg #2563EB, text #FFFFFF, 12px SemiBold, radius 20px, padding 8px 16px, height 34px | **Inactive:** bg #F8FAFC, text #6B7280, 12px SemiBold, radius 20px | **Container:** horizontal scroll, padding 0 16px, gap 8px

### 2.4 Primary Button (Blue)
- **Background:** #2563EB | **Text:** #FFFFFF, 14px SemiBold | **Radius:** 12px | **Height:** 48px | **Padding:** 0 24px | **Shadow:** shadow-blue | **Full width** for forms / Auto for inline | **States:** Default (#2563EB) → Hover (#1D4ED8) → Pressed (#1E40AF + scale 0.98) → Disabled (#93C5FD, no shadow)

### 2.5 CTA Button (Orange)
- **Background:** #F97316 | **Text:** #FFFFFF, 14px SemiBold | **Radius:** 12px | **Height:** 48px | **Padding:** 0 24px | **Shadow:** shadow-orange | **States:** Default (#F97316) → Hover (#EA6C0A) → Pressed (#C2570A + scale 0.98) → Disabled (#FED7AA)

### 2.6 Secondary Button (Outlined Blue)
- **Background:** transparent | **Border:** 1.5px solid #2563EB | **Text:** #2563EB, 14px SemiBold | **Radius:** 12px, Height: 48px | **Pressed:** bg #EFF6FF

### 2.7 Ghost / Text Button
- **Background:** transparent, no border | **Text:** #2563EB, 14px SemiBold | **Height:** auto (inline) | **Padding:** 4px 8px | **Used for:** "View All →", "Load More", "Forgot password?"

### 2.8 Danger Button (Outlined Red)
- **Background:** transparent | **Border:** 1.5px solid #EF4444 | **Text:** #EF4444, 14px SemiBold | **Height:** 48px | **Used for:** Log out, Delete, Withdraw

### 2.9 Icon Button (Circular)
- **Size:** 40x40px, radius 50% | **Background:** #F8FAFC | **Border:** 1px solid #E5E7EB | **Icon:** 20px, #6B7280 | **Active:** bg #EFF6FF, border #2563EB, icon #2563EB

### 2.10 Standard Text Input
- **Background:** #F8FAFC | **Border:** 1px solid #E5E7EB | **Radius:** 12px | **Height:** 52px | **Padding:** 0 16px | **Font:** 14px Regular, #111827 | **Placeholder:** 14px Regular, #9CA3AF | **Focused:** border 2px #2563EB, bg #FFFFFF | **Error:** border 2px #EF4444, bg #FEF2F2 | **Disabled:** bg #F3F4F6, text #9CA3AF

### 2.11 Search Bar
- **Background:** #F8FAFC | **Border:** 1px solid #E5E7EB | **Radius:** 12px | **Height:** 48px | **Padding:** 0 16px | **Leading icon:** search, 20px, #6B7280 | **Focused:** border 2px #2563EB | **Clear button:** × appears when input has text, #6B7280

### 2.12 OTP Input Boxes
- **Size:** 52x60px each (4 boxes, spaced 12px apart) | **Background:** #F8FAFC | **Border:** 1.5px solid #E5E7EB | **Radius:** 10px | **Font:** 22px Bold, #111827, center-aligned | **Active:** border 2px #2563EB, bg #FFFFFF | **Filled:** border #2563EB, bg #FFFFFF | **Error:** border 2px #EF4444, bg #FEF2F2, shake animation

### 2.13 Filter Chip (Active)
- **Background:** #EFF6FF | **Border:** 1px solid #2563EB | **Text:** #2563EB, 12px SemiBold | **Radius:** 20px | **Padding:** 6px 12px | **Trailing:** × icon, 12px, #2563EB (to remove filter)

### 2.14 Filter Chip (Inactive)
- **Background:** #F8FAFC | **Border:** 1px solid #E5E7EB | **Text:** #6B7280, 12px Regular | **Radius:** 20px | **Padding:** 6px 12px

### 2.15 Sport Badge
- **Background:** #EFF6FF | **Text:** #2563EB, 11px SemiBold | **Radius:** 6px | **Padding:** 3px 8px | **Used inline** next to username/name in cards and feed

### 2.16 Verified Badge
- **Icon:** checkmark circle, 16px, #22C55E | **Label:** "Verified" (tooltip on long press) | **Position:** Inline after name or overlaid on avatar bottom-right

### 2.17 Unread Count Badge
- **Background:** #F97316 | **Text:** #FFFFFF, 10px Bold | **Min-size:** 18x18px, radius 50% | **Position:** top-right of icon, offset -4px -4px | **Max display:** "9+" if count > 9

### 2.18 Status Dot
- **● Open:** #22C55E, 8px circle | **○ Pending:** #F59E0B, 8px circle (outline) | **● Closed:** #EF4444, 8px circle

### 2.19 Section Label
- **Text:** 12px SemiBold UPPERCASE, #6B7280 | **Letter-spacing:** 0.08em | **Margin:** 4px 0 12px 0

### 2.20 Full-Width Divider
- **Height:** 1px | **Color:** #E5E7EB | **Margin:** 16px 0

### 2.21 Inset Divider (Card-level)
- **Height:** 0.5px | **Color:** #E5E7EB | **Margin:** 12px 0 | **Left offset:** 16px (aligns with content, not edge)

### 2.22 Toast / Snackbar
- **Background:** #111827 | **Text:** #FFFFFF, 14px | **Radius:** 10px | **Duration:** 3 seconds, bottom-center | **Success:** left icon ✓ #22C55E | **Error:** left icon ✕ #EF4444

### 2.23 Empty State Pattern
- **Icon:** 48-64px, #9CA3AF | **Title:** 16px SemiBold #111827 | **Subtitle:** 14px #6B7280 center | **CTA:** CTA button #F97316

### 2.24 Loading Skeleton
- **Cards:** shimmer blocks in card shape | **Avatars:** shimmer circles | **Text lines:** shimmer rectangles (varying widths: 60%, 80%, 45%) | **Shimmer:** #F0F0F0 → #E0E0E0 → #F0F0F0, 1.4s loop

### 2.25 Avatar Sizes
| Size | Dimensions | Used In |
|---|---|---|
| XS | 28x28px | Comment rows, mini lists |
| SM | 40px | Feed post header, chat rows, connection rows |
| MD | 48px | Directory cards, notification rows |
| LG | 64px | Stories, search results |
| XL | 80px | Profile header (own profile, view profile) |
| XXL | 96px | Onboarding / welcome screen |

- **Always circular** (radius: 50%) | **Default fallback:** first initial on #2563EB background, white text | **Verified overlay:** small #22C55E check circle badge at bottom-right (XL/XXL only) | **Story ring:** 2.5px border in #2563EB when unviewed, #E5E7EB when viewed, gap 2px between ring and avatar


---

## 3. Authentication & Onboarding (7 Screens)

### Screen 1: Splash Screen
```
+-----------------------------------------+
|                                         |
|                                         |
|                                         |
|            [SPORTX LOGO]                |  Centered, large
|            (Wordmark/Icon)              |  #2563EB or brand asset
|                                         |
|                                         |
|         "India's Sports Network"        |  14px #6B7280
|                                         |
|                                         |
|                                         |
|         [Circular Progress]             |  #2563EB, small
|                                         |
+-----------------------------------------+
```
- **Background:** #FFFFFF | **Logo:** Centered, large scale (approx 120x120px or wordmark) | **Tagline:** "India's Sports Network" — 14px Regular, #6B7280, centered below logo | **Loading indicator:** Circular progress, #2563EB, small, centered at bottom | **Behavior:** Auto-navigates to Login after 2-3 seconds or session check | **No app bar, no bottom nav**

---

### Screen 2: Login Screen
```
+-----------------------------------------+
|                                         |
|            [SPORTX LOGO]                |  Top-center, medium
|                                         |
|         Welcome Back!                   |  Display 28px Bold #111827
|         Sign in to continue             |  Body 14px #6B7280
|                                         |
|    +-----------------------------+      |
|    | Phone or Email              |      |  Text input
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    | Password              [👁️]  |      |  Password input with toggle
|    +-----------------------------+      |
|                                         |
|         Forgot Password?                |  Ghost button, right-aligned
|                                         |
|    +-----------------------------+      |
|    |         Sign In               |      |  Primary Blue button, full width
|    +-----------------------------+      |
|                                         |
|    ---------  OR  ---------             |  Divider with text
|                                         |
|    +-----------------------------+      |
|    |      Continue with Google    |      |  Outlined button, Google icon
|    +-----------------------------+      |
|                                         |
|    Don't have an account? Sign Up       |  Body 14px, "Sign Up" as link #2563EB
|                                         |
+-----------------------------------------+
```
- **Background:** #FFFFFF | **Top padding:** 40px | **Horizontal padding:** 16px | **Logo:** Medium size, top-center | **Title:** "Welcome Back!" — Display 28px Bold, #111827 | **Subtitle:** "Sign in to continue" — Body 14px, #6B7280 | **Phone/Email input:** Standard text input, placeholder "Phone or Email" | **Password input:** Standard text input, placeholder "Password", trailing eye icon to toggle visibility | **Forgot Password:** Ghost button, right-aligned below password field | **Sign In button:** Primary Blue, full width, 48px height | **OR divider:** Full-width divider with "OR" text centered, #6B7280 | **Google Sign In:** Outlined button with Google icon, full width | **Sign Up link:** "Don't have an account? Sign Up" — Body 14px, "Sign Up" as #2563EB link | **No app bar, no bottom nav** | **Keyboard:** Pushes content up, dismisses on tap outside

---

### Screen 3: Signup Screen
```
+-----------------------------------------+
|                                         |
|            [SPORTX LOGO]                |
|                                         |
|         Create Account                  |  Display 28px Bold
|         Join India's sports network     |  Body 14px #6B7280
|                                         |
|    +-----------------------------+      |
|    | Full Name                   |      |
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    | Phone Number                |      |
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    | Email (Optional)            |      |
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    | Password              [👁️]  |      |
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    | Confirm Password      [👁️]  |      |
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    |         Continue              |      |  Primary Blue, full width
|    +-----------------------------+      |
|                                         |
|    Already have an account? Sign In     |  "Sign In" as #2563EB link
|                                         |
+-----------------------------------------+
```
- **Background:** #FFFFFF | **Title:** "Create Account" — Display 28px Bold | **Subtitle:** "Join India's sports network" — Body 14px, #6B7280 | **Fields:** Full Name, Phone Number, Email (Optional), Password, Confirm Password | **All inputs:** Standard text input style | **Password fields:** With eye toggle icon | **Continue button:** Primary Blue, full width | **Sign In link:** "Already have an account? Sign In" — "Sign In" as #2563EB link | **Validation:** Inline error messages below each field (12px #EF4444) | **No app bar, no bottom nav**

---

### Screen 4: OTP Verification Screen
```
+-----------------------------------------+
|                                         |
|         Verify Your Number              |  H1 22px Bold
|                                         |
|    Enter the 4-digit code sent to       |  Body 14px #6B7280
|    +91 98765 43210                      |  Body SemiBold 14px #111827
|                                         |
|    +----+ +----+ +----+ +----+          |
|    |    | |    | |    | |    |          |  OTP boxes 52x60px
|    +----+ +----+ +----+ +----+          |
|                                         |
|    [Error: Invalid OTP. Please try      |  12px #EF4444 (if error)
|     again.]                             |
|                                         |
|    Didn't receive it? Resend (30s)      |  Ghost button, timer countdown
|                                         |
|    +-----------------------------+      |
|    |         Verify                |      |  Primary Blue, full width
|    +-----------------------------+      |
|                                         |
|    Change Phone Number                  |  Ghost button, centered
|                                         |
+-----------------------------------------+
```
- **Background:** #FFFFFF | **Title:** "Verify Your Number" — H1 22px Bold | **Subtitle:** "Enter the 4-digit code sent to" + phone number — Body 14px #6B7280 + Body SemiBold #111827 | **OTP boxes:** 4 boxes, 52x60px each, 12px gap, auto-focus next box on input | **Error state:** Red border, shake animation, error text below | **Resend:** Ghost button with countdown timer (initially disabled, 30s countdown) | **Verify button:** Primary Blue, full width, disabled until 4 digits entered | **Change Phone Number:** Ghost button, centered | **No app bar, no bottom nav**

---

### Screen 5: Role Selection Screen
```
+-----------------------------------------+
|                                         |
|         Choose Your Role                |  H1 22px Bold
|                                         |
|    Select how you'll use SportX         |  Body 14px #6B7280
|                                         |
|    +-----------------------------+      |
|    |  🏃                         |      |
|    |  Athlete                    |      |  H3 16px SemiBold
|    |  I'm a player looking to    |      |  Body 14px #6B7280
|    |  connect and find opportunities|   |
|    +-----------------------------+      |  Card style, 16px radius
|                                         |
|    +-----------------------------+      |
|    |  🏫                         |      |
|    |  Coach / Academy            |      |
|    |  I train athletes and want  |      |
|    |  to showcase my programs    |      |
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    |  🤝                         |      |
|    |  Sponsor                    |      |
|    |  I want to support athletes |      |
|    |  and post opportunities     |      |
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    |         Continue              |      |  Primary Blue, full width
|    +-----------------------------+      |  (disabled until role selected)
|                                         |
+-----------------------------------------+
```
- **Background:** #FFFFFF | **Title:** "Choose Your Role" — H1 22px Bold | **Subtitle:** "Select how you'll use SportX" — Body 14px, #6B7280 | **Role cards:** 3 selectable cards, full width, 16px radius, #FFFFFF bg, 0.5px #E5E7EB border, shadow-md | **Each card:** Large icon (48px) at top-left, title (H3 16px SemiBold), description (Body 14px #6B7280) | **Selected card:** Border 2px #2563EB, bg #EFF6FF | **Unselected card:** Border 0.5px #E5E7EB, bg #FFFFFF | **Continue button:** Primary Blue, full width, disabled until role selected | **No app bar, no bottom nav**

---

### Screen 6: Forgot Password Screen
```
+-----------------------------------------+
|  [<-]  Forgot Password                   |  App bar with back arrow
+-----------------------------------------+
|                                         |
|         Reset Your Password             |  H1 22px Bold
|                                         |
|    Enter your phone number or email     |  Body 14px #6B7280
|    and we'll send you a reset code      |
|                                         |
|    +-----------------------------+      |
|    | Phone or Email              |      |  Text input
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    |      Send Reset Code          |      |  Primary Blue, full width
|    +-----------------------------+      |
|                                         |
|    Remember your password? Sign In      |  "Sign In" as #2563EB link
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Forgot Password" | **Title:** "Reset Your Password" — H1 22px Bold | **Subtitle:** "Enter your phone number or email and we'll send you a reset code" — Body 14px #6B7280 | **Input:** Phone or Email — standard text input | **Send Reset Code:** Primary Blue, full width | **Sign In link:** "Remember your password? Sign In" | **No bottom nav**

---

### Screen 7: Reset Password Screen
```
+-----------------------------------------+
|  [<-]  Set New Password                  |  App bar with back arrow
+-----------------------------------------+
|                                         |
|         Create New Password             |  H1 22px Bold
|                                         |
|    Your code has been verified.         |  Body 14px #6B7280
|    Enter your new password below.       |
|                                         |
|    +-----------------------------+      |
|    | New Password          [👁️]  |      |  Password input
|    +-----------------------------+      |
|                                         |
|    +-----------------------------+      |
|    | Confirm New Password  [👁️]  |      |  Password input
|    +-----------------------------+      |
|                                         |
|    Password must be at least 8          |  Caption 12px #6B7280
|    characters with 1 number             |
|                                         |
|    +-----------------------------+      |
|    |      Update Password          |      |  Primary Blue, full width
|    +-----------------------------+      |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Set New Password" | **Title:** "Create New Password" — H1 22px Bold | **Subtitle:** "Your code has been verified. Enter your new password below." — Body 14px #6B7280 | **Fields:** New Password, Confirm New Password (both with eye toggle) | **Hint:** "Password must be at least 8 characters with 1 number" — Caption 12px #6B7280 | **Update Password:** Primary Blue, full width | **Success:** Toast "Password updated successfully", navigate to Login | **No bottom nav**


---

## 4. Athlete Screens (17 Screens)

### Screen 8: Athlete Home / Feed
```
+-----------------------------------------+
|  [SPORTX]  SportX India        [🔔][⚙️]|  App bar: logo left, icons right
+-----------------------------------------+
|  [Stories Row — Horizontal Scroll]      |
|  +----+ +----+ +----+ +----+ +----+    |
|  |😊+ | |😊  | |😊  | |😊  | |😊  |    |  64px circles, first is "Add Story"
|  |Your| |Name| |Name| |Name| |Name|    |  Blue ring = unviewed, gray = viewed
|  |Story| |    | |    | |    | |    |    |  Caption 10px below each
|  +----+ +----+ +----+ +----+ +----+    |
+-----------------------------------------+
|  +---------------------------------+    |
|  | [Avatar 40px] Name · [Cricket] |    |  Post Card
|  | 2 hours ago              [···] |    |
|  |                                 |    |
|  | Had an amazing training session |    |  Body 14px #111827
|  | today! #cricket #training       |    |  Hashtags #2563EB
|  |                                 |    |
|  | [Image/Video — 16:9 — radius 12]|    |
|  |                                 |    |
|  | ❤ 24   💬 5   ↗ Share          |    |  14px #6B7280
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 40px] Name · [Football]|    |  Second post card
|  | ...                             |    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable feed with 8px gap          |
|   between post cards)                   |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [➕]  [💬]  [👤]          |  Bottom nav, Home active
|  Home  Discover Create Messages Profile |
+-----------------------------------------+
```
- **App bar:** SportX logo/wordmark left, notification bell + settings icons right | **Stories row:** Horizontal scroll, 64px circular avatars with story rings | First item: "Your Story" with + icon overlay, user's own avatar | Subsequent items: Other users' stories, name caption below (10px) | Blue ring (#2563EB, 2.5px) = unviewed, Gray ring (#E5E7EB) = viewed | **Post cards:** Full width, 16px internal padding, separated by 8px gap | **Row 1:** Avatar 40px | Name (14px SemiBold) + Sport badge inline | Timestamp (12px #6B7280) | [···] menu icon | **Row 2:** Caption text (14px #111827), multiline, hashtags in #2563EB | **Row 3:** Media image/video (16:9 aspect, radius 12px). Video has play button overlay (white circle 48px on semi-transparent bg) | **Row 4:** Like count (❤ N), Comment count (💬 N), Share (↗ Share) — all 14px #6B7280 | **Pull-to-refresh:** RefreshIndicator, color #2563EB | **Empty state:** "No posts yet. Follow athletes to see their updates" + "Discover Athletes" CTA | **Bottom nav:** 5 tabs, Home active (#2563EB) | **FAB (center):** 52x52px orange circle with + icon, shadow-orange

---

### Screen 9: Create Post Screen
```
+-----------------------------------------+
|  [<-]  Create Post              [Post]  |  App bar: back + "Post" text button
+-----------------------------------------+
|                                         |
|  [Avatar 48px]  Your Name               |  14px SemiBold
|  [Cricket]                              |  Sport badge
|                                         |
|  +---------------------------------+    |
|  | What's on your mind?            |    |  Multiline text area
|  |                                 |    |  Min height: 100px
|  |                                 |    |  Placeholder: 14px #9CA3AF
|  |                                 |    |  Character count: 12px #6B7280
|  +---------------------------------+    |  bottom-right
|                                         |
|  [📷 Add Photo]  [🎥 Add Video]         |  Icon buttons, horizontal row
|                                         |
|  +---------------------------------+    |
|  | [Image preview — 16:9]     [×]  |    |  Selected media preview
|  +---------------------------------+    |  with remove button
|                                         |
|  Add hashtags: #cricket #training       |  Inline hashtag suggestions
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Create Post", right: "Post" text button (Ghost style, #2563EB, disabled until text or media added) | **User info:** Avatar 48px + Name (14px SemiBold) + Sport badge inline | **Text area:** Multiline, min height 100px, placeholder "What's on your mind?", character count bottom-right (12px #6B7280) | **Media buttons:** "Add Photo" and "Add Video" — icon buttons in horizontal row | **Media preview:** 16:9 aspect, radius 12px, with × remove button top-right | **Hashtag suggestions:** Inline chips below text area | **Post button:** Becomes active (solid #2563EB) when content entered | **No bottom nav** (full screen modal feel)

---

### Screen 10: My Profile Screen (Athlete)
```
+-----------------------------------------+
|  [<-]  My Profile               [✏️]    |  App bar: back + edit icon
+-----------------------------------------+
| [Banner Image — Full width × 180px]     |
|  +---------------------------------+    |  Gradient overlay: transparent →
|  |                                 |    |  rgba(17,24,39,0.55) bottom
|  |    [Avatar 80px]                |    |  Avatar centered, overlapping
|  |    Rohan Sharma                 |    |  banner bottom edge by 40px
|  |    ✓ Verified                   |    |
|  |    [Cricket]  Mumbai, MH        |    |  Sport badge + location
|  +---------------------------------+    |
|                                         |
|  ---- Profile Stats ----                |
|  +---------+ +---------+ +---------+   |
|  |  24     | |   156   | |   12    |   |  Stat chips, 8px radius
|  |Posts    | |Connects | |Achieve  |   |  #111827 SemiBold + #6B7280 caption
|  +---------+ +---------+ +---------+   |
|                                         |
|  ---- About ----                        |  Section label
|  State-level cricketer with 5+ years    |  Body 14px #111827
|  of competitive experience...           |
|                                         |
|  ---- Achievements ----                 |
|  +---------------------------------+    |
|  | 🏆  State Championship 2024     |    |  Achievement card
|  |     Winner — Under-19 Cricket   |    |  Icon + title + subtitle
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🥈  National Trials Qualifier   |    |
|  |     2023 — Athletics            |    |
|  +---------------------------------+    |
|                                         |
|  ---- Tournament History ----           |
|  +---------------------------------+    |
|  | 🏏  Mumbai Premier League       |    |  Tournament card
|  |     2024 · Mumbai · 1st Place   |    |  Icon + name + meta
|  +---------------------------------+    |
|                                         |
|  ---- Performance Stats ----            |
|  +---------------------------------+    |
|  | Batting Average: 45.2           |    |  Stat row
|  | Matches Played: 32              |    |  Label + value
|  | Best Score: 128*                |    |
|  +---------------------------------+    |
|                                         |
|  ---- Media Gallery ----                |
|  +----+ +----+ +----+ +----+ +----+   |  3-col grid, square cells
|  |📷  | |📷  | |🎥  | |📷  | |📷  |   |  8px radius, 2px gap
|  +----+ +----+ +----+ +----+ +----+   |  Video cells: play icon overlay
|                                         |
|  ---- Social Links ----                 |
|  [Instagram] [Twitter/X] [LinkedIn]     |  Icon buttons, horizontal row
|                                         |
|  +-----------------------------+        |
|  |      Share Profile            |        |  Secondary outlined button
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "My Profile", edit icon (✏️) right | **Banner:** Full width × 180px, object-fit cover, gradient overlay (transparent → rgba(17,24,39,0.55)) | **Avatar:** 80px (XL), circular, overlapping banner bottom edge by 40px, centered | **Name:** H1 22px Bold, #111827, centered below avatar | **Verified badge:** ✓ icon 16px #22C55E, inline after name | **Sport + Location:** Sport badge + "Mumbai, MH" — Caption 12px #6B7280, centered | **Stats row:** 3 stat chips horizontally, 8px radius | Posts | Connections | Achievements | Values: #111827 SemiBold, Labels: #6B7280 Caption | **About section:** Section label + body text | **Achievements:** List of achievement cards with icon, title, subtitle | **Tournament History:** List of tournament cards with icon, name, meta info | **Performance Stats:** Card with stat rows (label + value) | **Media Gallery:** 3-column grid, square cells, 8px radius, 2px gap. Video cells have play icon overlay | **Social Links:** Icon buttons in horizontal row (Instagram, Twitter/X, LinkedIn) | **Share Profile button:** Secondary outlined button, full width | **No bottom nav** (or Profile tab active if accessed from nav)

---

### Screen 11: Edit Profile Screen
```
+-----------------------------------------+
|  [<-]  Edit Profile             [Save]  |  App bar: back + Save text button
+-----------------------------------------+
|                                         |
|         [Avatar 80px with 📷 icon]      |  Tap to change photo
|         Change Photo                    |  Caption 12px #2563EB
|                                         |
|  ---- PERSONAL INFO ----                |  Section label
|                                         |
|  Full Name                              |  Label 12px SemiBold #6B7280
|  +-----------------------------+        |
|  | Rohan Sharma                |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Bio                                    |
|  +-----------------------------+        |
|  | State-level cricketer...    |        |  Multiline text area
|  +-----------------------------+        |  Char count bottom-right
|                                         |
|  Primary Sport                          |
|  +-----------------------------+        |
|  | Cricket              [▼]    |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Location                               |
|  +-----------------------------+        |
|  | Mumbai, Maharashtra         |        |  Text input
|  +-----------------------------+        |
|                                         |
|  ---- SPORT DETAILS ----                |  Section label
|                                         |
|  [+ Add Achievement]                    |  Ghost button
|  [+ Add Tournament]                     |  Ghost button
|  [+ Edit Statistics]                    |  Ghost button
|  [+ Upload Media]                       |  Ghost button
|  [+ Add Social Links]                   |  Ghost button
|                                         |
|  +-----------------------------+        |
|  |         Save Changes          |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Edit Profile", "Save" text button right (Ghost #2563EB, disabled until changes made) | **Avatar:** 80px with camera icon overlay (bottom-right, small circular button #2563EB with white 📷 icon) | **Change Photo:** Caption 12px #2563EB, centered below avatar | **Section labels:** "PERSONAL INFO", "SPORT DETAILS" — 12px SemiBold UPPERCASE #6B7280 | **Fields:** Full Name (text), Bio (multiline), Primary Sport (dropdown), Location (text) | **Action buttons:** Ghost buttons to navigate to sub-screens for adding achievements, tournaments, stats, media, social links | **Save Changes:** Primary Blue, full width | **Form validation:** Inline errors below fields | **No bottom nav**

---

### Screen 12: Add Achievement / Certificate Screen
```
+-----------------------------------------+
|  [<-]  Add Achievement          [Save]  |  App bar
+-----------------------------------------+
|                                         |
|  Achievement Title *                    |  Label 12px SemiBold
|  +-----------------------------+        |
|  | e.g., State Championship    |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Description                            |
|  +-----------------------------+        |
|  | Brief details about the     |        |  Multiline text area
|  | achievement...              |        |
|  +-----------------------------+        |
|                                         |
|  Year                                   |
|  +-----------------------------+        |
|  | 2024                 [▼]    |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Upload Certificate / Photo             |
|  +-----------------------------+        |
|  |      [📷 Upload Image]        |        |  Upload area
|  |      Tap to upload certificate|        |  Dashed border, centered
|  +-----------------------------+        |  Preview shown after upload
|                                         |
|  +-----------------------------+        |
|  |         Save Achievement      |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Add Achievement", "Save" text button right | **Fields:** Achievement Title (required), Description (multiline), Year (dropdown), Upload Certificate/Photo | **Upload area:** Dashed border (#E5E7EB), centered icon + text, tap to open image picker | **After upload:** Preview thumbnail shown with × remove button | **Save Achievement:** Primary Blue, full width | **Validation:** Required field marked with *, inline errors | **No bottom nav**

---

### Screen 13: Add Tournament Participation Entry Screen
```
+-----------------------------------------+
|  [<-]  Add Tournament           [Save]  |  App bar
+-----------------------------------------+
|                                         |
|  Tournament Name *                      |
|  +-----------------------------+        |
|  | e.g., Mumbai Premier League |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Sport *                                |
|  +-----------------------------+        |
|  | Cricket                [▼]  |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Location                               |
|  +-----------------------------+        |
|  | Mumbai, Maharashtra         |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Year *                                 |
|  +-----------------------------+        |
|  | 2024                 [▼]    |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Position / Result                      |
|  +-----------------------------+        |
|  | e.g., 1st Place, Finalist   |        |  Text input
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |         Save Tournament       |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Add Tournament", "Save" text button right | **Fields:** Tournament Name (required), Sport (required dropdown), Location (text), Year (required dropdown), Position/Result (text) | **Save Tournament:** Primary Blue, full width | **No bottom nav**

---

### Screen 14: Tournament History List Screen
```
+-----------------------------------------+
|  [<-]  Tournament History                |  App bar
+-----------------------------------------+
|                                         |
|  +---------------------------------+    |
|  | 🏏  Mumbai Premier League       |    |  Tournament card
|  |     2024 · Mumbai · 1st Place   |    |  Icon + name + meta
|  |                       [->]       |    |  Chevron right
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🏏  State Under-19 Championship |    |
|  |     2023 · Pune · Semi-finalist |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🏃  Inter-School Athletics Meet |    |
|  |     2022 · Delhi · 2nd Place    |    |
|  +---------------------------------+    |
|                                         |
|  (+ Floating button to add new)         |  FAB small, bottom-right
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Tournament History" | **List:** Tournament cards, full width, 16px padding, separated by 8px gap | Each card: Sport icon + Tournament name (14px SemiBold) + Year · Location · Result (12px #6B7280) + chevron right (->) | **Empty state:** "No tournaments added yet. Record your participation history." + "Add Tournament" CTA | **FAB (bottom-right):** Small circular + button to add new tournament | **No bottom nav**

---

### Screen 15: Edit Performance Statistics Screen
```
+-----------------------------------------+
|  [<-]  Edit Statistics          [Save]  |  App bar
+-----------------------------------------+
|                                         |
|  These are self-reported stats for      |  Body 14px #6B7280
|  your profile. Be honest!               |
|                                         |
|  ---- CRICKET STATS ----                |  Section label (dynamic by sport)
|                                         |
|  Batting Average                        |
|  +-----------------------------+        |
|  | 45.2                        |        |  Number input
|  +-----------------------------+        |
|                                         |
|  Matches Played                         |
|  +-----------------------------+        |
|  | 32                          |        |  Number input
|  +-----------------------------+        |
|                                         |
|  Best Score                             |
|  +-----------------------------+        |
|  | 128*                        |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Wickets Taken                          |
|  +-----------------------------+        |
|  | 45                          |        |  Number input
|  +-----------------------------+        |
|                                         |
|  (+ Add Custom Stat)                    |  Ghost button
|                                         |
|  +-----------------------------+        |
|  |         Save Statistics       |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Edit Statistics", "Save" text button right | **Info text:** "These are self-reported stats for your profile. Be honest!" — Body 14px #6B7280 | **Section label:** Dynamic based on sport (e.g., "CRICKET STATS", "FOOTBALL STATS") | **Fields:** Sport-specific stat fields (number inputs and text inputs) | **Add Custom Stat:** Ghost button to add additional stat fields | **Save Statistics:** Primary Blue, full width | **No bottom nav**

---

### Screen 16: Media Gallery Screen
```
+-----------------------------------------+
|  [<-]  Media Gallery            [Select]|  App bar
+-----------------------------------------+
|                                         |
|  +----+ +----+ +----+                   |  3-col grid
|  |📷  | |📷  | |🎥  |                   |  Square cells, 8px radius
|  +----+ +----+ +----+                   |  2px gap between cells
|  +----+ +----+ +----+                   |  Video cells: play icon overlay
|  |📷  | |📷  | |📷  |                   |  (white 32px on dark semi-transparent)
|  +----+ +----+ +----+                   |
|  +----+ +----+ +----+                   |
|  |🎥  | |📷  | |📷  |                   |
|  +----+ +----+ +----+                   |
|                                         |
|  (+ Floating button to upload)          |  FAB small, bottom-right
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Media Gallery", "Select" text button right (for multi-select mode) | **Grid:** 3 columns, square cells, 8px radius, 2px gap | **Images:** Fill cell, object-fit cover | **Videos:** Same + play icon overlay (white 32px on dark semi-transparent bg) | **Tap:** Opens Media Viewer (full screen) | **Long press:** Enters selection mode (checkmark appears on selected items) | **FAB (bottom-right):** Small circular + button to upload new media | **Empty state:** "No media yet. Upload your highlights!" + "Upload Media" CTA | **No bottom nav**

---

### Screen 17: Upload Media Screen
```
+-----------------------------------------+
|  [<-]  Upload Media             [Post]  |  App bar
+-----------------------------------------+
|                                         |
|  +---------------------------------+    |
|  |                                 |    |  Large upload area
|  |      [📷 or 🎥 icon]            |    |  Dashed border #E5E7EB
|  |                                 |    |  Centered
|  |    Tap to select photo/video    |    |  Body 14px #6B7280
|  |                                 |    |
|  +---------------------------------+    |
|                                         |
|  OR                                     |  Divider with text
|                                         |
|  +---------------------------------+    |
|  |      📷  Take Photo             |    |  Button
|  +---------------------------------+    |
|  +---------------------------------+    |
|  |      🎥  Record Video           |    |  Button
|  +---------------------------------+    |
|                                         |
|  Caption (Optional)                     |
|  +-----------------------------+        |
|  | Add a caption...            |        |  Text input
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |         Upload                |        |  Primary Blue, full width
|  +-----------------------------+        |  (disabled until media selected)
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Upload Media", "Post" text button right (disabled until media selected) | **Upload area:** Large dashed border (#E5E7EB), centered icon + text, tap to open gallery | **After selection:** Preview shown in upload area with × to remove | **Camera options:** "Take Photo" and "Record Video" buttons below OR divider | **Caption:** Optional text input | **Upload button:** Primary Blue, full width, disabled until media selected | **Progress:** Shows upload progress bar when uploading | **No bottom nav**

---

### Screen 18: Edit Social Media Links Screen
```
+-----------------------------------------+
|  [<-]  Social Links             [Save]  |  App bar
+-----------------------------------------+
|                                         |
|  Instagram                              |
|  +-----------------------------+        |
|  | @rohan.sharma               |        |  Text input with @ prefix
|  +-----------------------------+        |
|                                         |
|  Twitter / X                            |
|  +-----------------------------+        |
|  | @rohancricket               |        |  Text input
|  +-----------------------------+        |
|                                         |
|  LinkedIn                               |
|  +-----------------------------+        |
|  | linkedin.com/in/rohan       |        |  Text input
|  +-----------------------------+        |
|                                         |
|  YouTube                                |
|  +-----------------------------+        |
|  | youtube.com/@rohancricket   |        |  Text input
|  +-----------------------------+        |
|                                         |
|  (+ Add Another Platform)               |  Ghost button
|                                         |
|  +-----------------------------+        |
|  |         Save Links            |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Social Links", "Save" text button right | **Fields:** Instagram, Twitter/X, LinkedIn, YouTube — all text inputs | **Add Another Platform:** Ghost button to add custom platform fields | **Save Links:** Primary Blue, full width | **No bottom nav**

---

### Screen 19: Discover / Directory Screen
```
+-----------------------------------------+
|  [SPORTX]  Discover            [🔔][⚙️]|  App bar
+-----------------------------------------+
|  +---------------------------------+    |
|  | 🔍  Search athletes, coaches... |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  [Athletes] [Coaches] [Sponsors]        |  Tab pills, horizontal scroll
|   Blue bg    Gray bg     Gray bg        |  First tab active
|                                         |
|  ---- FILTERS ----                      |
|  [Cricket ▼] [Mumbai ▼] [U-19 ▼]       |  Filter chips, active state
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Rohan Sharma      |    |  Athlete Card
|  | ✓ Verified                      |    |
|  | Cricket · Mumbai                |    |  12px #6B7280
|  | State Level · 5 achievements    |    |
|  | -----------------------------   |    |  Inset divider
|  |                    [Connect]    |    |  Secondary outlined button
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Priya Patel       |    |  Second athlete card
|  | Cricket · Delhi                 |    |
|  | National Level · 12 achievements|    |
|  | -----------------------------   |    |
|  |                    [Connect]    |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Arjun Kumar       |    |  Third card
|  | ...                             |    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, 8px gap between      |
|   cards, load more on scroll)           |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [➕]  [💬]  [👤]          |  Bottom nav, Discover active
|  Home  Discover Create Messages Profile |
+-----------------------------------------+
```
- **App bar:** SportX logo left, notification + settings icons right | **Search bar:** Full width, placeholder "Search athletes, coaches..." | **Tab pills:** Athletes | Coaches | Sponsors — horizontal scroll, first active | **Filter chips:** Active filters shown as chips with × to remove, tap to open filter bottom sheet | **Athlete cards:** Full width, 16px padding, 16px radius, shadow-md | Avatar 48px | Name (14px SemiBold) + Verified badge | Sport · City (12px #6B7280) | Achievement level · N achievements (12px #6B7280) | Inset divider | [Connect] button (Secondary outlined, right-aligned) | **Coach cards:** Same structure, replacing: Logo 48px | Academy Name | Sport · City | N athletes · N programs | [View Profile] | **Sponsor cards:** Logo 48px | Org Name | Industry | N Active Opportunities | [View Profile] | **Load more:** Infinite scroll or "Load More" ghost button at bottom | **Empty state:** "No results found. Try adjusting your filters." + "Clear Filters" CTA | **Bottom nav:** 5 tabs, Discover active (#2563EB)

---

### Screen 20: My Connections List Screen
```
+-----------------------------------------+
|  [<-]  My Connections         [🔍]      |  App bar with search
+-----------------------------------------+
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Rohan Sharma      |    |  Connection row
|  | Cricket · Mumbai                |    |  Tap to view profile
|  |                    [💬] [⋯]     |    |  Message icon + more menu
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Priya Patel       |    |
|  | Athletics · Delhi               |    |
|  |                    [💬] [⋯]     |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Coach Rahul       |    |
|  | Cricket Academy · Bangalore     |    |
|  |                    [💬] [⋯]     |    |
|  +---------------------------------+    |
|                                         |
|  (Alphabetical or recent sort,          |
|   scrollable list)                      |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "My Connections", search icon right | **Connection rows:** Full width, 16px padding, tap to view profile | Avatar 48px | Name (14px SemiBold) | Sport · City (12px #6B7280) | Message icon (💬) + More menu (⋯) right-aligned | **Message icon:** Opens Chat screen with that user | **More menu:** Bottom sheet with options: View Profile, Remove Connection, Block | **Search:** Filters connections in real-time | **Empty state:** "No connections yet. Start discovering athletes →" + "Discover" CTA | **No bottom nav** (or accessed from Messages tab)

---

### Screen 21: Connection Requests Screen
```
+-----------------------------------------+
|  [<-]  Connection Requests               |  App bar
+-----------------------------------------+
|                                         |
|  ---- RECEIVED (3) ----                 |  Section label with count
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Arjun Kumar       |    |  Request card
|  | Football · Pune                 |    |
|  | State Level · 3 achievements    |    |
|  |                                 |    |
|  | [Decline]        [Accept]       |    |  Danger outlined + Primary Blue
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Sneha Rao         |    |
|  | Badminton · Hyderabad           |    |
|  | [Decline]        [Accept]       |    |
|  +---------------------------------+    |
|                                         |
|  ---- SENT (2) ----                     |  Section label with count
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Coach Vikram      |    |  Sent request row
|  | Cricket Academy · Chennai       |    |
|  |                    [Pending]    |    |  Caption "Pending" #F59E0B
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Connection Requests" | **Received section:** Section label with count in parentheses | Request cards: Avatar 48px | Name | Sport · City | Achievement info | [Decline] (Danger outlined) + [Accept] (Primary Blue) buttons side by side | **Sent section:** Section label with count | Sent rows: Avatar 48px | Name | Sport · City | "Pending" caption #F59E0B | **Empty state:** "No pending requests" for each section | **No bottom nav**

---

### Screen 22: Chat List Screen
```
+-----------------------------------------+
|  [SPORTX]  Messages            [🔔][⚙️]|  App bar
+-----------------------------------------+
|  +---------------------------------+    |
|  | 🔍  Search conversations...     |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Rohan Sharma   ●  |    |  Chat row
|  | Hey, are you coming to the      |    |  ● = unread dot #2563EB
|  | practice tomorrow?         2m   |    |  Preview + timestamp
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Priya Patel       |    |
|  | Great match yesterday!     1h   |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Coach Rahul    ●  |    |
|  | Trial selection update...  3h   |    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, sorted by most       |
|   recent message)                       |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [➕]  [💬]  [👤]          |  Bottom nav, Messages active
|  Home  Discover Create Messages Profile |
+-----------------------------------------+
```
- **App bar:** SportX logo left, notification + settings icons right | **Search bar:** "Search conversations..." | **Chat rows:** Full width, 16px padding, tap to open conversation | Avatar 48px | Name (14px SemiBold) + Unread dot (● #2563EB, 8px) if unread | Message preview (14px #6B7280, single line, ellipsis) | Timestamp (12px #6B7280, right-aligned) | **Empty state:** "No messages yet. Connect with athletes to start chatting." + "Go to Connections" CTA | **Bottom nav:** 5 tabs, Messages active (#2563EB)

---

### Screen 23: Chat Screen (1:1 Conversation)
```
+-----------------------------------------+
|  [<-] [Avatar 40px] Rohan Sharma  [📎][📞]|  App bar
+-----------------------------------------+
|                                         |
|         Yesterday                       |  Date separator, 12px #6B7280
|                                         |
|  +---------------------------+          |
|  | Hey! How's your training  |          |  Received bubble
|  | going?                    |          |  bg: #F8FAFC, text: #111827
|  |                    2:30 PM |          |  14px, timestamp bottom-right
|  +---------------------------+          |
|                                         |
|          +---------------------------+  |
|          | Going great! Just finished |  |  Sent bubble
|          | my sprint drills.          |  |  bg: #2563EB, text: #FFFFFF
|          |                    2:32 PM |  |  14px, timestamp bottom-right
|          +---------------------------+  |
|                                         |
|  +---------------------------+          |
|  | Nice! Want to join the     |          |
|  | practice match this        |          |
|  | weekend?                   |          |
|  |                    2:33 PM |          |
|  +---------------------------+          |
|                                         |
|          +---------------------------+  |
|          | Definitely! What time?     |  |
|          |                    2:35 PM |  |
|          +---------------------------+  |
|                                         |
|  (Scrollable, newest at bottom)         |
|                                         |
+-----------------------------------------+
|  [📎]  +---------------------+  [🎙️]   |  Input area
|        | Type a message...   |         |  Text input
|        +---------------------+          |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), Avatar 40px + Name (14px SemiBold), attachment (📎) + call (📞) icons right | **Date separators:** Centered, 12px #6B7280 | **Received bubbles:** bg #F8FAFC, text #111827, 14px, rounded 16px top-left/top-right/bottom-right, bottom-left 4px | **Sent bubbles:** bg #2563EB, text #FFFFFF, 14px, rounded 16px top-left/top-right/bottom-left, bottom-right 4px | **Timestamp:** 10px #6B7280, bottom-right of each bubble | **Input area:** Attachment icon (📎) left, text input center ("Type a message...", #9CA3AF), microphone icon (🎙️) right | **Send button:** Appears when text entered, replaces microphone with paper plane icon (#2563EB) | **No bottom nav**

---

### Screen 24: Academies & Coaches Directory Screen (Athlete View)
```
+-----------------------------------------+
|  [SPORTX]  Academies           [🔔][⚙️]|  App bar
+-----------------------------------------+
|  +---------------------------------+    |
|  | 🔍  Search academies, coaches...|    |  Search bar
|  +---------------------------------+    |
|                                         |
|  [All] [Cricket] [Football] [Athletics] |  Tab pills by sport
|                                         |
|  +---------------------------------+    |
|  | [Logo 48px] Rahul Cricket       |    |  Academy Card
|  |   Academy                       |    |
|  | Cricket · Bangalore             |    |
|  | 45 athletes · 6 programs        |    |
|  | -----------------------------   |    |
|  |                    [View Profile]|    |  Secondary outlined
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Logo 48px] FitLife Sports      |    |
|  |   Academy                       |    |
|  | Athletics · Mumbai              |    |
|  | 120 athletes · 8 programs       |    |
|  | -----------------------------   |    |
|  |                    [View Profile]|    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, 8px gap)             |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [➕]  [💬]  [👤]          |  Bottom nav
|  Home  Discover Create Messages Profile |
+-----------------------------------------+
```
- **App bar:** SportX logo left, title "Academies", notification + settings right | **Search bar:** "Search academies, coaches..." | **Tab pills:** Sport categories, horizontal scroll | **Academy cards:** Full width, 16px padding, 16px radius, shadow-md | Logo 48px | Academy Name (14px SemiBold) | Sport · City (12px #6B7280) | N athletes · N programs (12px #6B7280) | Inset divider | [View Profile] button (Secondary outlined, right-aligned) | **Empty state:** "No academies found. Try a different search." + "Clear Search" CTA | **Bottom nav:** 5 tabs


---

## 5. Coach / Academy Screens (8 Screens)

### Screen 25: Coach / Academy Home Feed
```
+-----------------------------------------+
|  [SPORTX]  Home                [🔔][⚙️]|  App bar
+-----------------------------------------+
|  [Stories Row — Horizontal Scroll]      |
|  +----+ +----+ +----+ +----+ +----+    |
|  |😊+ | |😊  | |😊  | |😊  | |😊  |    |  Same as athlete feed
|  |Your| |Name| |Name| |Name| |Name|    |
|  |Story| |    | |    | |    | |    |    |
|  +----+ +----+ +----+ +----+ +----+    |
+-----------------------------------------+
|  +---------------------------------+    |
|  | [Avatar 40px] Athlete Name      |    |  Post Card (peer + academy)
|  | · [Cricket]    3h ago    [···] |    |
|  |                                 |    |
|  | Just won the state trials!      |    |
|  | #cricket #statelevel            |    |
|  |                                 |    |
|  | [Image — 16:9 — radius 12]      |    |
|  |                                 |    |
|  | ❤ 45   💬 8   ↗ Share          |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Logo 40px] FitLife Academy     |    |  Academy post
|  | · [Athletics]  5h ago    [···] |    |
|  |                                 |    |
|  | New batch starting next week!   |    |
|  | Register now. #athletics        |    |
|  |                                 |    |
|  | ❤ 23   💬 4   ↗ Share          |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [🔔]  [👤]                |  Bottom nav, 4 tabs
|  Home  Discover Notif  Profile          |  Home active
+-----------------------------------------+
```
- **App bar:** SportX logo left, notification + settings icons right | **Stories row:** Same as athlete feed (64px circles, story rings) | **Post cards:** Same structure as athlete feed — athlete posts + academy posts mixed | **Bottom nav:** 4 tabs (Coach): Home, Discover, Notifications, Profile — Home active (#2563EB) | **No FAB** (Coach role has no FAB)

---

### Screen 26: Coach / Academy Profile Screen (Own)
```
+-----------------------------------------+
|  [<-]  My Academy              [✏️]    |  App bar
+-----------------------------------------+
| [Banner Image — Full width × 180px]     |
|  +---------------------------------+    |
|  |    [Logo 80px]                  |    |
|  |    Rahul Cricket Academy        |    |  H1 22px Bold
|  |    ✓ Verified                   |    |
|  |    [Cricket]  Bangalore, KA     |    |
|  +---------------------------------+    |
|                                         |
|  ---- Academy Stats ----                |
|  +---------+ +---------+ +---------+   |
|  |  45     | |   6     | |   12    |   |
|  |Athletes | |Programs | |Years    |   |
|  +---------+ +---------+ +---------+   |
|                                         |
|  ---- About ----                        |
|  Premier cricket academy with state-    |
|  of-the-art facilities...               |
|                                         |
|  ---- Credentials ----                  |
|  +---------------------------------+    |
|  | 📜  BCCI Level 2 Coaching       |    |
|  |     License — 2019              |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🏆  National Academy of the     |    |
|  |     Year — 2022                 |    |
|  +---------------------------------+    |
|                                         |
|  ---- Facilities & Programs ----        |
|  +---------------------------------+    |
|  | 🏟️  3 Turf Wickets              |    |
|  | 🏋️  Gym & Fitness Center        |    |
|  | 🏠  Residential Camp (Summer)   |    |
|  | 📅  Weekend Batch (Sat-Sun)     |    |
|  +---------------------------------+    |
|                                         |
|  ---- Associated Athletes ----          |
|  +----+ +----+ +----+ +----+ +----+   |
|  |😊  | |😊  | |😊  | |😊  | |😊  |   |  5 athlete avatars
|  |Name| |Name| |Name| |Name| |Name|   |  Tap to view profile
|  +----+ +----+ +----+ +----+ +----+   |
|                                         |
|  ---- Contact ----                      |
|  📞 +91 98765 43210                     |
|  📧 contact@rahulcricket.com            |
|                                         |
|  +-----------------------------+        |
|  |      Share Profile            |        |
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "My Academy", edit icon (✏️) right | **Banner:** Full width × 180px, academy/ground photo, gradient overlay | **Logo:** 80px (XL), circular, overlapping banner bottom edge | **Name:** H1 22px Bold | **Verified badge:** Inline | **Sport + Location:** Sport badge + "Bangalore, KA" | **Stats row:** Athletes | Programs | Years of operation | **About:** Section label + body text | **Credentials:** List of certification cards with icon, title, subtitle | **Facilities & Programs:** List with icons (🏟️ 🏋️ 🏠 📅) | **Associated Athletes:** Horizontal scroll of 5 athlete avatars (64px circles with names below) | **Contact:** Phone and email, 14px #111827 | **Share Profile:** Secondary outlined button | **No bottom nav**

---

### Screen 27: Edit Coach / Academy Profile Screen
```
+-----------------------------------------+
|  [<-]  Edit Academy            [Save]  |  App bar
+-----------------------------------------+
|                                         |
|         [Logo 80px with 📷 icon]        |  Tap to change logo
|         Change Logo                     |  Caption 12px #2563EB
|                                         |
|  ---- ACADEMY INFO ----                 |  Section label
|                                         |
|  Academy Name                           |
|  +-----------------------------+        |
|  | Rahul Cricket Academy       |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Bio / Overview                         |
|  +-----------------------------+        |
|  | Premier cricket academy...  |        |  Multiline
|  +-----------------------------+        |
|                                         |
|  Sport Specialisation                   |
|  +-----------------------------+        |
|  | Cricket              [▼]    |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Location                               |
|  +-----------------------------+        |
|  | Bangalore, Karnataka        |        |  Text input
|  +-----------------------------+        |
|                                         |
|  ---- CREDENTIALS ----                  |
|  [+ Add Credential]                     |  Ghost button
|                                         |
|  ---- FACILITIES ----                   |
|  [+ Add Facility]                       |  Ghost button
|                                         |
|  ---- ASSOCIATED ATHLETES ----          |
|  [+ Showcase Athletes]                  |  Ghost button
|                                         |
|  Contact Phone                          |
|  +-----------------------------+        |
|  | +91 98765 43210             |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Contact Email                          |
|  +-----------------------------+        |
|  | contact@rahulcricket.com    |        |  Text input
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |         Save Changes          |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Edit Academy", "Save" text button right | **Logo:** 80px with camera icon overlay | **Change Logo:** Caption 12px #2563EB | **Section labels:** "ACADEMY INFO", "CREDENTIALS", "FACILITIES", "ASSOCIATED ATHLETES" | **Fields:** Academy Name, Bio (multiline), Sport Specialisation (dropdown), Location, Contact Phone, Contact Email | **Ghost buttons:** To add credentials, facilities, showcase athletes | **Save Changes:** Primary Blue, full width | **No bottom nav**

---

### Screen 28: Add Credentials / Certifications Screen
```
+-----------------------------------------+
|  [<-]  Add Credential          [Save]  |  App bar
+-----------------------------------------+
|                                         |
|  Credential Title *                     |
|  +-----------------------------+        |
|  | e.g., BCCI Level 2 License  |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Issuing Authority                      |
|  +-----------------------------+        |
|  | e.g., BCCI                  |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Year Obtained                          |
|  +-----------------------------+        |
|  | 2019                 [▼]    |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Upload Certificate                     |
|  +-----------------------------+        |
|  |      [📷 Upload Document]     |        |  Upload area
|  |      Tap to upload            |        |  Dashed border
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |         Save Credential       |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Add Credential", "Save" text button right | **Fields:** Credential Title (required), Issuing Authority, Year Obtained (dropdown), Upload Certificate | **Upload area:** Dashed border, centered icon + text | **Save Credential:** Primary Blue, full width | **No bottom nav**

---

### Screen 29: Edit Facilities & Programs Screen
```
+-----------------------------------------+
|  [<-]  Edit Facilities         [Save]  |  App bar
+-----------------------------------------+
|                                         |
|  Facility / Program Name *              |
|  +-----------------------------+        |
|  | e.g., Turf Wicket           |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Description                            |
|  +-----------------------------+        |
|  | Details about the facility  |        |  Multiline
|  +-----------------------------+        |
|                                         |
|  Type                                   |
|  +-----------------------------+        |
|  | Facility               [▼]  |        |  Dropdown: Facility/Program
|  +-----------------------------+        |
|                                         |
|  (+ Add Another)                        |  Ghost button
|                                         |
|  +-----------------------------+        |
|  |         Save Facilities       |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Edit Facilities", "Save" text button right | **Fields:** Facility/Program Name (required), Description (multiline), Type (dropdown: Facility or Program) | **Add Another:** Ghost button to add more facility rows | **Save Facilities:** Primary Blue, full width | **No bottom nav**

---

### Screen 30: Associated Athletes Showcase Screen
```
+-----------------------------------------+
|  [<-]  Showcase Athletes       [Save]  |  App bar
+-----------------------------------------+
|                                         |
|  Search and select athletes to          |  Body 14px #6B7280
|  showcase on your profile:              |
|                                         |
|  +---------------------------------+    |
|  | 🔍  Search your athletes...     |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  ---- SELECTED (3) ----                 |
|  +---------------------------------+    |
|  | [Avatar 48px] Rohan Sharma   ✓  |    |  Selected row
|  | Cricket · Mumbai                |    |  Checkmark right
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Priya Patel    ✓  |    |
|  | Athletics · Delhi               |    |
|  +---------------------------------+    |
|                                         |
|  ---- AVAILABLE ----                    |
|  +---------------------------------+    |
|  | [Avatar 48px] Arjun Kumar       |    |  Unselected row
|  | Football · Pune                 |    |  Tap to select
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Sneha Rao         |    |
|  | Badminton · Hyderabad           |    |
|  +---------------------------------+    |
|                                         |
|  +-----------------------------+        |
|  |         Save Showcase         |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Showcase Athletes", "Save" text button right | **Search bar:** "Search your athletes..." | **Selected section:** Athletes already showcased, with ✓ checkmark | **Available section:** Athletes connected to academy, tap to select/deselect | **Save Showcase:** Primary Blue, full width | **No bottom nav**

---

### Screen 31: Athlete Directory Screen (Coach View)
```
+-----------------------------------------+
|  [SPORTX]  Athletes            [🔔][⚙️]|  App bar
+-----------------------------------------+
|  +---------------------------------+    |
|  | 🔍  Search athletes...          |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  [All] [Cricket] [Football] [Athletics] |  Tab pills
|                                         |
|  [U-19 ▼] [State ▼] [Mumbai ▼]         |  Filter chips
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Rohan Sharma      |    |  Athlete Card
|  | Cricket · Mumbai                |    |
|  | State Level · 5 achievements    |    |
|  | -----------------------------   |    |
|  |                    [View Profile]|    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Priya Patel       |    |
|  | Athletics · Delhi               |    |
|  | National Level · 12 achievements|    |
|  | -----------------------------   |    |
|  |                    [View Profile]|    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, 8px gap)             |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [🔔]  [👤]                |  Bottom nav
|  Home  Discover Notif  Profile          |
+-----------------------------------------+
```
- **App bar:** SportX logo left, title "Athletes", notification + settings right | **Search bar:** "Search athletes..." | **Tab pills:** Sport categories | **Filter chips:** Age category, Achievement level, Location | **Athlete cards:** Same as Discover screen but with [View Profile] button instead of [Connect] | **Bottom nav:** 4 tabs, Discover active

---

### Screen 32: Sponsor Directory Screen (Coach View)
```
+-----------------------------------------+
|  [SPORTX]  Sponsors            [🔔][⚙️]|  App bar
+-----------------------------------------+
|  +---------------------------------+    |
|  | 🔍  Search sponsors...          |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  [All] [Sportswear] [Nutrition] [Finance]| Tab pills by industry
|                                         |
|  +---------------------------------+    |
|  | [Logo 48px] Nike India          |    |  Sponsor Card
|  | Sportswear · Pan-India          |    |
|  | 5 Active Opportunities          |    |
|  | -----------------------------   |    |
|  |                    [View Profile]|    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Logo 48px] Gatorade            |    |
|  | Nutrition · Mumbai, Delhi       |    |
|  | 2 Active Opportunities          |    |
|  | -----------------------------   |    |
|  |                    [View Profile]|    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [🔔]  [👤]                |  Bottom nav
|  Home  Discover Notif  Profile          |
+-----------------------------------------+
```
- **App bar:** SportX logo left, title "Sponsors", notification + settings right | **Search bar:** "Search sponsors..." | **Tab pills:** Industry categories | **Sponsor cards:** Logo 48px | Org Name (14px SemiBold) | Industry · Location (12px #6B7280) | N Active Opportunities (12px #6B7280) | Inset divider | [View Profile] button | **Bottom nav:** 4 tabs


---

## 6. Sponsor Screens (9 Screens)

### Screen 33: Sponsor Home Feed
```
+-----------------------------------------+
|  [SPORTX]  Home                [🔔][⚙️]|  App bar
+-----------------------------------------+
|  [Stories Row — Horizontal Scroll]      |
|  +----+ +----+ +----+ +----+ +----+    |
|  |😊+ | |😊  | |😊  | |😊  | |😊  |    |
|  |Your| |Name| |Name| |Name| |Name|    |
|  |Story| |    | |    | |    | |    |    |
|  +----+ +----+ +----+ +----+ +----+    |
+-----------------------------------------+
|  +---------------------------------+    |
|  | [Avatar 40px] Athlete Name      |    |  Post Card
|  | · [Cricket]    1h ago    [···] |    |
|  |                                 |    |
|  | Excited to announce our new     |    |
|  | sponsorship program!            |    |
|  |                                 |    |
|  | [Image — 16:9 — radius 12]      |    |
|  |                                 |    |
|  | ❤ 67   💬 12   ↗ Share         |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [⭐]  [👤]                |  Bottom nav, 4 tabs
|  Home  Discover PostOpp Profile         |  Home active
+-----------------------------------------+
```
- **App bar:** SportX logo left, notification + settings icons right | **Stories row:** Same as athlete feed | **Post cards:** Same structure — mixed athlete + academy posts | **Bottom nav:** 4 tabs (Sponsor): Home, Discover, Post Opp, Profile — Home active (#2563EB) | **No FAB** (Sponsor has Post Opp tab instead)

---

### Screen 34: Sponsor Profile Screen (Own)
```
+-----------------------------------------+
|  [<-]  My Profile               [✏️]    |  App bar
+-----------------------------------------+
| [Banner Image — Full width × 180px]     |
|  +---------------------------------+    |
|  |    [Logo 80px]                  |    |
|  |    Nike India                   |    |  H1 22px Bold
|  |    ✓ Verified                   |    |
|  |    [Sportswear]  Pan-India      |    |
|  +---------------------------------+    |
|                                         |
|  ---- Sponsor Stats ----                |
|  +---------+ +---------+ +---------+   |
|  |  5      | |   23    | |   8     |   |
|  |Active   | |Athletes | |Years    |   |
|  |Opp      | |Sponsored| |Active   |   |
|  +---------+ +---------+ +---------+   |
|                                         |
|  ---- About ----                        |
|  Leading sportswear brand supporting    |
|  athletes across India...               |
|                                         |
|  ---- Active Opportunities ----         |
|  +---------------------------------+    |
|  | 🏃  Athlete Sponsorship 2024    |    |  Opportunity card
|  |     Cricket · Pan-India         |    |
|  |     Deadline: Dec 31, 2024      |    |
|  |     ● Open                      |    |  Green dot
|  |                       [View]    |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🏫  Academy Equipment Support   |    |
|  |     All Sports · Maharashtra    |    |
|  |     Deadline: Jan 15, 2025      |    |
|  |     ● Open                      |    |
|  |                       [View]    |    |
|  +---------------------------------+    |
|                                         |
|  ---- Past Associations ----            |
|  +----+ +----+ +----+ +----+ +----+   |
|  |😊  | |😊  | |😊  | |😊  | |😊  |   |  5 athlete avatars
|  |Name| |Name| |Name| |Name| |Name|   |
|  +----+ +----+ +----+ +----+ +----+   |
|                                         |
|  +-----------------------------+        |
|  |      Share Profile            |        |
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "My Profile", edit icon (✏️) right | **Banner:** Full width × 180px, brand banner, gradient overlay | **Logo:** 80px (XL), circular | **Name:** H1 22px Bold | **Verified badge:** Inline | **Industry + Coverage:** Sport badge + "Pan-India" | **Stats row:** Active Opportunities | Athletes Sponsored | Years Active | **About:** Section label + body text | **Active Opportunities:** List of opportunity cards with icon, title, sport · region, deadline, status dot (● Open #22C55E), [View] ghost button | **Past Associations:** Horizontal scroll of 5 athlete avatars (64px circles) | **Share Profile:** Secondary outlined button | **No bottom nav**

---

### Screen 35: Edit Sponsor Profile Screen
```
+-----------------------------------------+
|  [<-]  Edit Profile            [Save]  |  App bar
+-----------------------------------------+
|                                         |
|         [Logo 80px with 📷 icon]        |  Tap to change logo
|         Change Logo                     |  Caption 12px #2563EB
|                                         |
|  ---- ORGANIZATION INFO ----            |  Section label
|                                         |
|  Organization Name                      |
|  +-----------------------------+        |
|  | Nike India                  |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Description                            |
|  +-----------------------------+        |
|  | Leading sportswear brand... |        |  Multiline
|  +-----------------------------+        |
|                                         |
|  Industry / Category                    |
|  +-----------------------------+        |
|  | Sportswear             [▼]  |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Coverage Area                          |
|  +-----------------------------+        |
|  | Pan-India                 |        |  Text input
|  +-----------------------------+        |
|                                         |
|  ---- PAST ASSOCIATIONS ----            |
|  [+ Add Past Association]               |  Ghost button
|                                         |
|  +-----------------------------+        |
|  |         Save Changes          |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Edit Profile", "Save" text button right | **Logo:** 80px with camera icon overlay | **Change Logo:** Caption 12px #2563EB | **Section labels:** "ORGANIZATION INFO", "PAST ASSOCIATIONS" | **Fields:** Organization Name, Description (multiline), Industry/Category (dropdown), Coverage Area | **Add Past Association:** Ghost button | **Save Changes:** Primary Blue, full width | **No bottom nav**

---

### Screen 36: My Active Opportunities Screen
```
+-----------------------------------------+
|  [<-]  My Opportunities        [+]      |  App bar with add icon
+-----------------------------------------+
|                                         |
|  ---- ACTIVE (3) ----                   |  Section label with count
|                                         |
|  +---------------------------------+    |
|  | 🏃  Athlete Sponsorship 2024    |    |  Opportunity card
|  |     Cricket · Pan-India         |    |
|  |     Deadline: Dec 31, 2024      |    |
|  |     ● Open              [Edit]  |    |  Green dot + Edit ghost
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🏫  Academy Equipment Support   |    |
|  |     All Sports · Maharashtra    |    |
|  |     Deadline: Jan 15, 2025      |    |
|  |     ● Open              [Edit]  |    |
|  +---------------------------------+    |
|                                         |
|  ---- PENDING APPROVAL (1) ----         |
|                                         |
|  +---------------------------------+    |
|  | 🏃  Youth Development Program   |    |
|  |     Football · Delhi            |    |
|  |     Submitted: Nov 1, 2024      |    |
|  |     ○ Pending           [View]  |    |  Amber outline dot
|  +---------------------------------+    |
|                                         |
|  ---- CLOSED (2) ----                   |
|                                         |
|  +---------------------------------+    |
|  | 🏃  Summer Camp Sponsorship     |    |
|  |     Athletics · Bangalore       |    |
|  |     Closed: Aug 30, 2024        |    |
|  |     ● Closed            [View]  |    |  Red dot
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "My Opportunities", + icon right (to create new) | **Active section:** Section label with count | Opportunity cards: Icon + Title (14px SemiBold) | Sport · Region (12px #6B7280) | Deadline (12px #6B7280) | Status dot + [Edit] ghost button | **Pending Approval section:** Same structure, ○ Pending #F59E0B | **Closed section:** Same structure, ● Closed #EF4444 | **Empty state:** Per section | **No bottom nav**

---

### Screen 37: Past Associations Showcase Screen
```
+-----------------------------------------+
|  [<-]  Past Associations       [Save]  |  App bar
+-----------------------------------------+
|                                         |
|  Search and select athletes to          |  Body 14px #6B7280
|  showcase as past associations:         |
|                                         |
|  +---------------------------------+    |
|  | 🔍  Search athletes...          |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  ---- SHOWCASED (4) ----                |
|  +---------------------------------+    |
|  | [Avatar 48px] Rohan Sharma   ✓  |    |
|  | Cricket · Mumbai                |    |
|  | Sponsored: 2022-2024            |    |
|  +---------------------------------+    |
|                                         |
|  ---- AVAILABLE ----                    |
|  +---------------------------------+    |
|  | [Avatar 48px] Priya Patel       |    |
|  | Athletics · Delhi               |    |
|  +---------------------------------+    |
|                                         |
|  +-----------------------------+        |
|  |         Save Showcase         |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Past Associations", "Save" text button right | **Search bar:** "Search athletes..." | **Showcased section:** Already selected athletes with sponsorship period | **Available section:** Tap to select/deselect | **Save Showcase:** Primary Blue, full width | **No bottom nav**

---

### Screen 38: Athlete Directory Screen (Sponsor View)
```
+-----------------------------------------+
|  [SPORTX]  Athletes            [🔔][⚙️]|  App bar
+-----------------------------------------+
|  +---------------------------------+    |
|  | 🔍  Search athletes...          |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  [All] [Cricket] [Football] [Athletics] |  Tab pills
|                                         |
|  [State ▼] [U-19 ▼] [Mumbai ▼]         |  Filter chips
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Rohan Sharma      |    |  Athlete Card
|  | Cricket · Mumbai                |    |
|  | State Level · 5 achievements    |    |
|  | -----------------------------   |    |
|  |              [⭐ Save] [View]   |    |  Save + View buttons
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Priya Patel       |    |
|  | Athletics · Delhi               |    |
|  | National Level · 12 achievements|    |
|  | -----------------------------   |    |
|  |              [⭐ Saved] [View]  |    |  Saved state (filled star)
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [⭐]  [👤]                |  Bottom nav
|  Home  Discover PostOpp Profile         |
+-----------------------------------------+
```
- **App bar:** SportX logo left, title "Athletes", notification + settings right | **Search bar:** "Search athletes..." | **Tab pills:** Sport categories | **Filter chips:** Achievement level, Age, Location | **Athlete cards:** Same structure but action buttons: [⭐ Save] (outline star) or [⭐ Saved] (filled star #F97316) + [View] ghost button | **Bottom nav:** 4 tabs, Discover active

---

### Screen 39: Academy Directory Screen (Sponsor View)
```
+-----------------------------------------+
|  [SPORTX]  Academies           [🔔][⚙️]|  App bar
+-----------------------------------------+
|  +---------------------------------+    |
|  | 🔍  Search academies...         |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  [All] [Cricket] [Football] [Athletics] |  Tab pills
|                                         |
|  +---------------------------------+    |
|  | [Logo 48px] Rahul Cricket       |    |  Academy Card
|  |   Academy                       |    |
|  | Cricket · Bangalore             |    |
|  | 45 athletes · 6 programs        |    |
|  | -----------------------------   |    |
|  |                    [View Profile]|    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [⭐]  [👤]                |  Bottom nav
|  Home  Discover PostOpp Profile         |
+-----------------------------------------+
```
- **App bar:** SportX logo left, title "Academies", notification + settings right | **Search bar:** "Search academies..." | **Tab pills:** Sport categories | **Academy cards:** Same as coach view | **Bottom nav:** 4 tabs

---

### Screen 40: Post Opportunity Screen (Create Listing)
```
+-----------------------------------------+
|  [<-]  Post Opportunity        [Submit] |  App bar
+-----------------------------------------+
|                                         |
|  Opportunity Title *                    |
|  +-----------------------------+        |
|  | e.g., Athlete Sponsorship   |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Description                            |
|  +-----------------------------+        |
|  | Details about the opportunity|       |  Multiline text area
|  | and what you're offering...  |       |
|  +-----------------------------+        |
|                                         |
|  Sport Category *                       |
|  +-----------------------------+        |
|  | Cricket                [▼]  |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Region / Location *                    |
|  +-----------------------------+        |
|  | Pan-India / Specific city   |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Eligibility Criteria                   |
|  +-----------------------------+        |
|  | e.g., State-level and above |        |  Multiline
|  +-----------------------------+        |
|                                         |
|  Application Deadline *                 |
|  +-----------------------------+        |
|  | Dec 31, 2024           [📅]  |        |  Date picker input
|  +-----------------------------+        |
|                                         |
|  Opportunity Type                       |
|  +-----------------------------+        |
|  | Sponsorship            [▼]  |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |         Submit for Approval   |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
|  Your listing will be reviewed by       |  Caption 12px #6B7280
|  admin before going live.               |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Post Opportunity", "Submit" text button right (disabled until required fields filled) | **Fields:** Opportunity Title (required), Description (multiline), Sport Category (required dropdown), Region/Location (required), Eligibility Criteria (multiline), Application Deadline (required date picker), Opportunity Type (dropdown: Sponsorship, Equipment, Funding, etc.) | **Submit for Approval:** Primary Blue, full width | **Note:** "Your listing will be reviewed by admin before going live." — Caption 12px #6B7280 | **No bottom nav**

---

### Screen 41: Listing Status Screen
```
+-----------------------------------------+
|  [<-]  Listing Status                   |  App bar
+-----------------------------------------+
|                                         |
|  ---- PENDING APPROVAL ----             |  Section label
|                                         |
|  +---------------------------------+    |
|  | 🏃  Youth Development Program   |    |
|  |     Football · Delhi            |    |
|  |     Submitted: Nov 1, 2024      |    |
|  |     ○ Pending                   |    |  Amber outline dot
|  |                       [View]    |    |
|  +---------------------------------+    |
|                                         |
|  ---- APPROVED ----                     |
|                                         |
|  +---------------------------------+    |
|  | 🏃  Athlete Sponsorship 2024    |    |
|  |     Cricket · Pan-India         |    |
|  |     Approved: Oct 15, 2024      |    |
|  |     ● Live                      |    |  Green dot
|  |              [Edit] [Close]     |    |
|  +---------------------------------+    |
|                                         |
|  ---- REJECTED ----                     |
|                                         |
|  +---------------------------------+    |
|  | 🏫  Equipment Grant             |    |
|  |     All Sports · Mumbai         |    |
|  |     Rejected: Oct 10, 2024      |    |
|  |     ● Rejected                  |    |  Red dot
|  |     Reason: Incomplete info     |    |  12px #EF4444
|  |                       [Edit]    |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Listing Status" | **Pending Approval section:** Opportunity cards with ○ Pending #F59E0B status | **Approved section:** Cards with ● Live #22C55E status, [Edit] + [Close] buttons | **Rejected section:** Cards with ● Rejected #EF4444 status, rejection reason (12px #EF4444), [Edit] button to resubmit | **Empty state:** Per section | **No bottom nav**


---

## 7. Shared Screens (11 Screens)

### Screen 42: View Profile Screen (Read-Only)
```
+-----------------------------------------+
|  [<-]  Profile                 [⋯]      |  App bar with more menu
+-----------------------------------------+
| [Banner Image — Full width × 180px]     |
|  +---------------------------------+    |
|  |    [Avatar 80px]                |    |
|  |    Rohan Sharma                 |    |  H1 22px Bold
|  |    ✓ Verified                   |    |
|  |    [Cricket]  Mumbai, MH        |    |
|  +---------------------------------+    |
|                                         |
|  ---- Profile Stats ----                |
|  +---------+ +---------+ +---------+   |
|  |  24     | |   156   | |   12    |   |
|  |Posts    | |Connects | |Achieve  |   |
|  +---------+ +---------+ +---------+   |
|                                         |
|  [Connect]  [Message]                   |  Two buttons side by side
|  (Secondary) (Primary Blue)             |
|                                         |
|  ---- About ----                        |
|  State-level cricketer with 5+ years    |
|  of competitive experience...           |
|                                         |
|  ---- Achievements ----                 |
|  +---------------------------------+    |
|  | 🏆  State Championship 2024     |    |
|  |     Winner — Under-19 Cricket   |    |
|  +---------------------------------+    |
|                                         |
|  ---- Tournament History ----           |
|  +---------------------------------+    |
|  | 🏏  Mumbai Premier League       |    |
|  |     2024 · Mumbai · 1st Place   |    |
|  +---------------------------------+    |
|                                         |
|  ---- Performance Stats ----            |
|  +---------------------------------+    |
|  | Batting Average: 45.2           |    |
|  | Matches Played: 32              |    |
|  | Best Score: 128*                |    |
|  +---------------------------------+    |
|                                         |
|  ---- Media Gallery ----                |
|  +----+ +----+ +----+ +----+ +----+   |
|  |📷  | |📷  | |🎥  | |📷  | |📷  |   |
|  +----+ +----+ +----+ +----+ +----+   |
|                                         |
|  ---- Social Links ----                 |
|  [Instagram] [Twitter/X] [LinkedIn]     |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Profile", [⋯] more menu right | **Banner:** Full width × 180px, gradient overlay | **Avatar:** 80px (XL), circular | **Name:** H1 22px Bold | **Verified badge:** Inline | **Sport + Location:** Sport badge + City, State | **Stats row:** Posts | Connections | Achievements | **Action buttons:** [Connect] (Secondary outlined) + [Message] (Primary Blue) side by side, full width each (50/50 split) | If already connected: [Message] + [Connected] (disabled gray) | **About, Achievements, Tournament History, Performance Stats, Media Gallery, Social Links:** Same as My Profile but read-only | **More menu (⋯):** Bottom sheet with options: Report Profile, Block User, Share Profile | **No bottom nav**

---

### Screen 43: Post Detail Screen
```
+-----------------------------------------+
|  [<-]  Post                    [⋯]      |  App bar
+-----------------------------------------+
|                                         |
|  +---------------------------------+    |
|  | [Avatar 40px] Name · [Cricket] |    |
|  | 2 hours ago              [⋯]   |    |
|  |                                 |    |
|  | Had an amazing training session |    |
|  | today! #cricket #training       |    |
|  |                                 |    |
|  | [Image/Video — 16:9 — radius 12]|    |
|  |                                 |    |
|  | ❤ 24   💬 5   ↗ Share          |    |
|  +---------------------------------+    |
|                                         |
|  ---- COMMENTS (5) ----                 |  Section label
|                                         |
|  +---------------------------------+    |
|  | [Avatar 28px] Priya Patel       |    |  Comment row
|  | Great work! Keep it up!      1h |    |  XS avatar
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 28px] Coach Rahul       |    |
|  | Well done, see you at practice |    |
|  | tomorrow!                   2h |    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable comments list)             |
|                                         |
+-----------------------------------------+
|  [Avatar 32px] +---------------------+  |  Comment input
|                | Add a comment...    |  |  Text input
|                +---------------------+  |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Post", [⋯] more menu right | **Post card:** Same as feed post but full screen | **Comments section:** Section label with count | **Comment rows:** Avatar 28px (XS) | Name (12px SemiBold) | Comment text (14px #111827) | Timestamp (12px #6B7280, right-aligned) | **Comment input:** Avatar 32px left, text input center ("Add a comment..."), send icon appears when text entered | **More menu (⋯):** Options: Report Post, Copy Link, Share | **No bottom nav**

---

### Screen 44: Opportunities List Screen
```
+-----------------------------------------+
|  [SPORTX]  Opportunities       [🔔][⚙️]|  App bar
+-----------------------------------------+
|  +---------------------------------+    |
|  | 🔍  Search opportunities...     |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  [All] [Sponsorship] [Equipment] [Funding]| Tab pills
|                                         |
|  [Cricket ▼] [Pan-India ▼] [Open ▼]    |  Filter chips
|                                         |
|  +---------------------------------+    |
|  | [Logo 40px] Athlete Sponsorship |    |  Opportunity Card
|  |     Nike India                  |    |
|  | Cricket · Pan-India             |    |  12px #6B7280
|  | Deadline: Dec 31, 2024          |    |
|  | -----------------------------   |    |
|  | ● Open                        |    |  Green dot
|  |              [Apply → ]         |    |  CTA orange button
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Logo 40px] Equipment Grant     |    |
|  |     Gatorade                    |    |
|  | All Sports · Maharashtra        |    |
|  | Deadline: Jan 15, 2025          |    |
|  | -----------------------------   |    |
|  | ● Open              [Apply → ]  |    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, 8px gap)             |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [➕]  [💬]  [👤]          |  Bottom nav (Athlete)
|  Home  Discover Create Messages Profile |
+-----------------------------------------+
```
- **App bar:** SportX logo left, title "Opportunities", notification + settings right | **Search bar:** "Search opportunities..." | **Tab pills:** Opportunity types (All, Sponsorship, Equipment, Funding) | **Filter chips:** Sport, Region, Status | **Opportunity cards:** Full width, 16px padding, 16px radius, shadow-md | Sponsor Logo 40px | Opportunity Title (16px SemiBold) | Sponsor Name (14px #6B7280) | Sport · Region (12px #6B7280) | Deadline (12px #6B7280) | Inset divider | Status dot (● Open #22C55E) | [Apply →] CTA orange button, right-aligned | **Empty state:** "No opportunities found. Try adjusting your filters." + "Clear Filters" CTA | **Bottom nav:** Role-dependent tabs

---

### Screen 45: Opportunity Detail Screen
```
+-----------------------------------------+
|  [<-]  Opportunity Details     [⭐]      |  App bar with save icon
+-----------------------------------------+
|                                         |
|  [Logo 80px]                            |
|  Nike India                             |  H1 22px Bold
|  [Sportswear]  Pan-India                |  Sport badge + location
|                                         |
|  Athlete Sponsorship 2024               |  H2 18px SemiBold
|                                         |
|  ---- ABOUT ----                        |  Section label
|  We are looking for talented cricketers |
|  to sponsor for the upcoming season...  |
|                                         |
|  ---- DETAILS ----                      |
|  +---------------------------------+    |
|  | Sport: Cricket                  |    |
|  | Region: Pan-India               |    |
|  | Type: Sponsorship               |    |
|  | Eligibility: State-level and    |    |
|  |   above                         |    |
|  | Deadline: Dec 31, 2024          |    |
|  | Status: ● Open                  |    |  Green dot
|  +---------------------------------+    |
|                                         |
|  ---- SPONSOR ----                      |
|  [Logo 48px] Nike India                 |
|  View Profile →                         |  Ghost button
|                                         |
|  +-----------------------------+        |
|  |      Apply Now                |        |  CTA Orange, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Opportunity Details", save/bookmark icon (⭐) right | **Sponsor logo:** 80px (XL), circular, centered at top | **Sponsor name:** H1 22px Bold, centered | **Industry + Coverage:** Sport badge + "Pan-India", centered | **Opportunity title:** H2 18px SemiBold | **About section:** Section label + body text | **Details section:** Card with key-value pairs (Sport, Region, Type, Eligibility, Deadline, Status with dot) | **Sponsor section:** Logo 48px + Name + "View Profile →" ghost button | **Apply Now:** CTA Orange, full width | **If already applied:** Button shows "Applied ✓" disabled state | **No bottom nav**

---

### Screen 46: Apply / Express Interest Form Screen
```
+-----------------------------------------+
|  [<-]  Apply for Opportunity   [Submit] |  App bar
+-----------------------------------------+
|                                         |
|  You are applying for:                  |  Body 14px #6B7280
|  Athlete Sponsorship 2024 — Nike India  |  Body SemiBold 14px #111827
|                                         |
|  ---- YOUR PROFILE ----                 |  Section label
|  [Avatar 48px] Rohan Sharma             |
|  Cricket · Mumbai · State Level         |  12px #6B7280
|                                         |
|  Why should you be selected? *          |
|  +-----------------------------+        |
|  | Briefly explain why you're a  |      |  Multiline text area
|  | good fit for this opportunity |      |
|  +-----------------------------+        |
|                                         |
|  Relevant Achievements                  |
|  +-----------------------------+        |
|  | List your top 2-3 achievements|      |  Multiline
|  +-----------------------------+        |
|                                         |
|  Contact Preference                     |
|  +-----------------------------+        |
|  | In-app message           [▼]  |      |  Dropdown
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |         Submit Application    |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
|  Your profile will be shared with       |  Caption 12px #6B7280
|  the sponsor for review.                |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Apply for Opportunity", "Submit" text button right (disabled until required fields filled) | **Opportunity info:** "You are applying for:" + opportunity name — Body 14px #6B7280 + Body SemiBold #111827 | **Your Profile section:** Avatar 48px + Name + Sport · Location · Level | **Fields:** Why should you be selected? (required multiline), Relevant Achievements (multiline), Contact Preference (dropdown: In-app message, Email, Phone) | **Submit Application:** Primary Blue, full width | **Note:** "Your profile will be shared with the sponsor for review." — Caption 12px #6B7280 | **No bottom nav**

---

### Screen 47: Application Submitted Confirmation Screen
```
+-----------------------------------------+
|                                         |
|                                         |
|            [✓ Checkmark Icon]           |  64px, #22C55E
|                                         |
|    Application Submitted!               |  H1 22px Bold #111827
|                                         |
|  Your application for Athlete           |  Body 14px #6B7280
|  Sponsorship 2024 has been sent to      |
|  Nike India for review.                 |
|                                         |
|  You will be notified once the          |  Body 14px #6B7280
|  sponsor reviews your application.      |
|                                         |
|  +-----------------------------+        |
|  |      View My Applications     |        |  Secondary outlined button
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |      Back to Opportunities    |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
|                                         |
+-----------------------------------------+
```
- **Background:** #FFFFFF | **Checkmark icon:** 64px, #22C55E, centered | **Title:** "Application Submitted!" — H1 22px Bold, centered | **Subtitle:** Application details — Body 14px #6B7280, centered | **Info text:** "You will be notified once the sponsor reviews your application." — Body 14px #6B7280, centered | **View My Applications:** Secondary outlined button | **Back to Opportunities:** Primary Blue, full width | **No app bar, no bottom nav** (full screen success state)

---

### Screen 48: Search & Filter Screen
```
+-----------------------------------------+
|  [<-]  Search & Filter                  |  App bar
+-----------------------------------------+
|                                         |
|  +---------------------------------+    |
|  | 🔍  Search...                   |    |  Search bar
|  +---------------------------------+    |
|                                         |
|  ---- FILTER BY SPORT ----              |  Section label
|  [Cricket] [Football] [Athletics]       |  Filter chips, multi-select
|  [Badminton] [Swimming] [Tennis]        |
|  [+ More]                               |
|                                         |
|  ---- FILTER BY LOCATION ----           |
|  [Mumbai] [Delhi] [Bangalore]           |  Filter chips
|  [Hyderabad] [Pune] [Chennai]           |
|  [+ More]                               |
|                                         |
|  ---- FILTER BY ACHIEVEMENT ----        |
|  [School] [State] [National]            |  Filter chips
|  [International]                        |
|                                         |
|  ---- FILTER BY AGE ----                |
|  [Under-14] [Under-16] [Under-19]      |  Filter chips
|  [Under-23] [Open]                      |
|                                         |
|  [Clear All Filters]                    |  Ghost button, left
|                                         |
|  +-----------------------------+        |
|  |         Apply Filters         |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Search & Filter" | **Search bar:** "Search..." at top | **Filter sections:** Sport (multi-select chips), Location (multi-select chips), Achievement Level (multi-select chips), Age Category (multi-select chips) | **More button:** [+ More] to see additional options in bottom sheet | **Clear All Filters:** Ghost button, left-aligned | **Apply Filters:** Primary Blue, full width | **Active filters:** Pre-selected chips shown in filled state (#EFF6FF bg, #2563EB border) | **No bottom nav**

---

### Screen 49: Notifications List Screen
```
+-----------------------------------------+
|  [SPORTX]  Notifications       [⚙️]     |  App bar
+-----------------------------------------+
|                                         |
|  ---- TODAY ----                        |  Section label
|                                         |
|  +---------------------------------+    |
|  | [Icon 20px] New Connection!     |    |  Unread notification
|  | Arjun Kumar accepted your       |    |  bg: #EFF6FF
|  | connection request.             |    |  Left border: 3px #2563EB
|  | 2m ago                 [View]   |    |  12px #6B7280
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Icon 20px] Trial Announcement  |    |  Unread notification
|  | FitLife Academy is hosting      |    |
|  | trials this weekend.            |    |
|  | 1h ago                 [View]   |    |
|  +---------------------------------+    |
|                                         |
|  ---- YESTERDAY ----                    |
|                                         |
|  +---------------------------------+    |
|  | [Icon 20px] Opportunity Update  |    |  Read notification
|  | Your application was viewed by  |    |  bg: #FFFFFF
|  | Nike India.                     |    |  Border: 0.5px #E5E7EB
|  | Yesterday              [View]   |    |  No left border
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, grouped by date)     |
|                                         |
+-----------------------------------------+
|  [🏠]  [🔍]  [➕]  [💬]  [👤]          |  Bottom nav (Athlete)
|  Home  Discover Create Messages Profile |
+-----------------------------------------+
```
- **App bar:** SportX logo left, title "Notifications", settings icon right | **Grouped by date:** "TODAY", "YESTERDAY", "OLDER" — Section labels | **Unread notification cards:** bg #EFF6FF, left border 3px solid #2563EB, radius 12px, padding 14px 16px | Icon 20px | Title (14px SemiBold #111827) | Body (13px #111827) | Timestamp (12px #6B7280) + [View] ghost button | **Read notification cards:** bg #FFFFFF, border 0.5px #E5E7EB, no left border accent | **Tap:** Opens Notification Detail | **Swipe left:** Reveal "Mark as Read/Unread" and "Delete" actions | **Empty state:** "You're all caught up! Check back later for updates." + "Go to Home" CTA | **Bottom nav:** Role-dependent tabs

---

### Screen 50: Notification Detail Screen
```
+-----------------------------------------+
|  [<-]  Notification Detail              |  App bar
+-----------------------------------------+
|                                         |
|  [Large Icon 48px]                      |  Centered, #2563EB
|                                         |
|    New Connection!                      |  H1 22px Bold, centered
|                                         |
|  Arjun Kumar has accepted your          |  Body 14px #111827, centered
|  connection request. You can now        |
|  message each other and view full       |
|  profiles.                              |
|                                         |
|  Received: Today at 2:30 PM             |  Caption 12px #6B7280, centered
|                                         |
|  +-----------------------------+        |
|  |      View Profile             |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |      Send Message             |        |  Secondary outlined button
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Notification Detail" | **Icon:** Large 48px, #2563EB, centered | **Title:** H1 22px Bold, centered | **Body:** Body 14px #111827, centered, multiline | **Timestamp:** Caption 12px #6B7280, centered | **Action buttons:** Contextual based on notification type (View Profile, Send Message, View Opportunity, etc.) | **No bottom nav**

---

### Screen 51: Settings Screen
```
+-----------------------------------------+
|  [<-]  Settings                         |  App bar
+-----------------------------------------+
|                                         |
|  ---- ACCOUNT ----                      |  Section label
|  +---------------------------------+    |
|  | 👤  Edit Profile           [->] |    |  Settings row
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🔒  Change Password        [->] |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | ✉️  Email Preferences      [->] |    |
|  +---------------------------------+    |
|                                         |
|  ---- PRIVACY ----                      |
|  +---------------------------------+    |
|  | 👁️  Profile Visibility     [->] |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🚫  Blocked Users          [->] |    |
|  +---------------------------------+    |
|                                         |
|  ---- NOTIFICATIONS ----                |
|  +---------------------------------+    |
|  | 🔔  Push Notifications     [ON] |    |  Toggle switch
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 📧  Email Notifications    [OFF]|    |  Toggle switch
|  +---------------------------------+    |
|                                         |
|  ---- SUPPORT ----                      |
|  +---------------------------------+    |
|  | ❓  Help & Support         [->] |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 📋  Terms of Service       [->] |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🔒  Privacy Policy         [->] |    |
|  +---------------------------------+    |
|                                         |
|  ---- DANGER ZONE ----                  |
|  +---------------------------------+    |
|  | 🚪  Log Out                     |    |  Danger outlined, full width
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🗑️  Delete Account              |    |  Danger outlined, full width
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Settings" | **Section labels:** "ACCOUNT", "PRIVACY", "NOTIFICATIONS", "SUPPORT", "DANGER ZONE" — 12px SemiBold UPPERCASE #6B7280 | **Settings rows:** Full width, 16px padding, tap to navigate | Icon 24px left | Label (14px SemiBold #111827) | Chevron right (→) or Toggle switch right | **Toggle switches:** ON = #2563EB track, OFF = #E5E7EB track | **Log Out:** Danger outlined button, full width | **Delete Account:** Danger outlined button, full width | **No bottom nav**

---

### Screen 52: Media Viewer Screen
```
+-----------------------------------------+
|  [<-]                          [⋯][⬇️] |  App bar (transparent bg)
+-----------------------------------------+
|                                         |
|                                         |
|                                         |
|         [Full-screen Image/Video]       |  Object-fit contain
|                                         |
|                                         |
|                                         |
+-----------------------------------------+
|  [Avatar 40px] Name · Sport      ❤ 💬 ↗ |  Bottom overlay
|  Caption text here...                   |  Semi-transparent bg
+-----------------------------------------+
```
- **App bar:** Transparent background, back arrow (←) left, more menu (⋯) + download (⬇️) right | **Media:** Full screen, object-fit contain, black background (#000000) | **Image:** Pinch to zoom, double-tap to zoom | **Video:** Play/pause controls, progress bar, fullscreen toggle | **Bottom overlay:** Semi-transparent black bg | Avatar 40px | Name (14px SemiBold #FFFFFF) | Sport badge | Like (❤), Comment (💬), Share (↗) icons | Caption text (14px #FFFFFF) | **Swipe left/right:** Navigate to next/previous media in gallery | **Tap:** Toggle UI visibility (hide/show app bar and bottom overlay) | **No bottom nav**


---

## 8. Admin Screens — Mobile (11 Screens)

### Screen 53: Admin Dashboard Screen
```
+-----------------------------------------+
|  [SPORTX]  Admin Dashboard     [⚙️]     |  App bar
+-----------------------------------------+
|                                         |
|  Good Morning, Admin                    |  H2 18px SemiBold
|  Here's today's overview                |  Body 14px #6B7280
|                                         |
|  ---- QUICK STATS ----                  |  Section label
|  +---------+ +---------+ +---------+   |
|  |  1,245  | |   89    | |   12    |   |
|  |Total    | |Pending  | |Reports  |   |
|  |Users    | |Approvals| |Today    |   |
|  +---------+ +---------+ +---------+   |
|                                         |
|  ---- USER BREAKDOWN ----               |
|  +---------------------------------+    |
|  | 👤  Athletes:        892        |    |  Stat row
|  | 🏫  Coaches:         187        |    |
|  | 🤝  Sponsors:        166        |    |
|  +---------------------------------+    |
|                                         |
|  ---- RECENT ACTIVITY ----              |
|  +---------------------------------+    |
|  | 🔔  New user registered:        |    |  Activity row
|  |     Arjun Kumar (Athlete)       |    |
|  |     5 minutes ago               |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🔔  Opportunity submitted:      |    |
|  |     Nike India                  |    |
|  |     15 minutes ago              |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | ⚠️  Content reported:           |    |
|  |     Post #12345                 |    |
|  |     30 minutes ago              |    |
|  +---------------------------------+    |
|                                         |
|  ---- QUICK ACTIONS ----                |
|  +---------+ +---------+ +---------+   |
|  | [👤]    | | [✓]     | | [📋]    |   |  Icon buttons
|  | Users   | | Approve | | Reports |   |  3 columns
|  +---------+ +---------+ +---------+   |
|  +---------+ +---------+ +---------+   |
|  | [🔔]    | | [⭐]    | | [📊]    |   |
|  | Notify  | | Opp     | | Reports |   |
|  +---------+ +---------+ +---------+   |
|                                         |
+-----------------------------------------+
```
- **App bar:** SportX logo left, title "Admin Dashboard", settings icon right | **Greeting:** "Good Morning, Admin" — H2 18px SemiBold | **Subtitle:** "Here's today's overview" — Body 14px #6B7280 | **Quick Stats:** 3 stat cards | Total Users | Pending Approvals | Reports Today | Values: H1 22px Bold, Labels: Caption 12px #6B7280 | **User Breakdown:** Card with role counts | **Recent Activity:** List of activity rows with icon, description, timestamp | **Quick Actions:** 2×3 grid of icon buttons (60x60px circular, #F8FAFC bg, #2563EB icon) with labels below | Each navigates to respective admin screen | **Bottom nav:** Same as other roles but with Admin tab active

---

### Screen 54: Platform Reports Screen
```
+-----------------------------------------+
|  [<-]  Platform Reports                 |  App bar
+-----------------------------------------+
|                                         |
|  ---- USERS BY ROLE ----                |  Section label
|  +---------------------------------+    |
|  | 👤  Athletes        892  71.6%  |    |  Progress bar
|  | ████████████████████░░░░░░░░░░░ |    |  #2563EB fill
|  | 🏫  Coaches         187  15.0%  |    |
|  | ████░░░░░░░░░░░░░░░░░░░░░░░░░░░ |    |  #F97316 fill
|  | 🤝  Sponsors        166  13.3%  |    |
|  | ███░░░░░░░░░░░░░░░░░░░░░░░░░░░░ |    |  #22C55E fill
|  +---------------------------------+    |
|                                         |
|  ---- USERS BY REGION ----              |
|  +---------------------------------+    |
|  | Maharashtra        312  25.1%   |    |
|  | Delhi              198  15.9%   |    |
|  | Karnataka          156  12.5%   |    |
|  | Telangana          124   9.9%   |    |
|  | Tamil Nadu          98   7.9%   |    |
|  | [View All Regions →]            |    |  Ghost button
|  +---------------------------------+    |
|                                         |
|  ---- USERS BY SPORT ----               |
|  +---------------------------------+    |
|  | Cricket            445  35.7%   |    |
|  | Football           267  21.4%   |    |
|  | Athletics          189  15.2%   |    |
|  | Badminton          134  10.8%   |    |
|  | [View All Sports →]             |    |  Ghost button
|  +---------------------------------+    |
|                                         |
|  ---- ACTIVITY METRICS ----             |
|  +---------------------------------+    |
|  | New registrations (7d):    45   |    |
|  | Active users (7d):        678   |    |
|  | Posts created (7d):       123   |    |
|  | Connections made (7d):    89    |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Platform Reports" | **Users by Role:** Card with role breakdown and horizontal progress bars | Each bar: role color fill on #F8FAFC track | **Users by Region:** Card with region list, count, percentage | **Users by Sport:** Card with sport list, count, percentage | **View All:** Ghost button at bottom of each list | **Activity Metrics:** Card with 7-day stats | **No bottom nav**

---

### Screen 55: Manage Users List Screen
```
+-----------------------------------------+
|  [<-]  Manage Users            [🔍]     |  App bar with search
+-----------------------------------------+
|                                         |
|  [All] [Athletes] [Coaches] [Sponsors]  |  Tab pills
|                                         |
|  [Verified ▼] [Active ▼] [Maharashtra ▼]|  Filter chips
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Rohan Sharma      |    |  User row
|  | 👤 Athlete · Mumbai · ✓ Verified|    |
|  |                    [⋯]          |    |  More menu
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Logo 48px] Rahul Cricket       |    |
|  |   Academy                       |    |
|  | 🏫 Coach · Bangalore · ✓ Verified|   |
|  |                    [⋯]          |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Logo 48px] Nike India          |    |
|  | 🤝 Sponsor · Pan-India · ✓ Verif|    |
|  |                    [⋯]          |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Avatar 48px] Arjun Kumar       |    |
|  | 👤 Athlete · Pune · Unverified  |    |  No checkmark
|  |                    [⋯]          |    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, 8px gap)             |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Manage Users", search icon right | **Tab pills:** All | Athletes | Coaches | Sponsors | **Filter chips:** Verification status, Account status, Location | **User rows:** Full width, 16px padding, tap to view detail | Avatar/Logo 48px | Name (14px SemiBold) | Role icon (👤 🏫 🤝) + Role · Location · Verification status (12px #6B7280) | [⋯] more menu right | **More menu (⋯):** Bottom sheet with options: View Profile, Verify User, Suspend Account, Delete Account | **Empty state:** "No users found." | **No bottom nav**

---

### Screen 56: User Detail / Verify Screen
```
+-----------------------------------------+
|  [<-]  User Detail             [⋯]      |  App bar
+-----------------------------------------+
|                                         |
|  [Avatar 80px]                          |
|  Rohan Sharma                           |  H1 22px Bold
|  👤 Athlete · Mumbai, MH                |  14px #6B7280
|                                         |
|  Status: Unverified                     |  Caption 12px #F59E0B
|                                         |
|  ---- PROFILE INFO ----                 |  Section label
|  +---------------------------------+    |
|  | Email: rohan@email.com          |    |
|  | Phone: +91 98765 43210          |    |
|  | Joined: Oct 15, 2024            |    |
|  | Last Active: Today              |    |
|  +---------------------------------+    |
|                                         |
|  ---- VERIFICATION ----                 |
|  +---------------------------------+    |
|  | 📜  State Championship 2024     |    |  Uploaded doc
|  |     [View Document]             |    |  Ghost button
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | 🏏  Mumbai Premier League       |    |
|  |     [View Document]             |    |
|  +---------------------------------+    |
|                                         |
|  +-----------------------------+        |
|  |      ✓ Verify & Add Badge     |        |  Success Green button
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |      Suspend Account            |        |  Warning Amber outlined
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |      🗑️ Delete Account          |        |  Danger outlined
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "User Detail", [⋯] more menu right | **Avatar:** 80px (XL), circular | **Name:** H1 22px Bold | **Role + Location:** 👤 Athlete · Mumbai, MH — 14px #6B7280 | **Status:** "Unverified" — Caption 12px #F59E0B (or "Verified" #22C55E, "Suspended" #EF4444) | **Profile Info:** Card with email, phone, joined date, last active | **Verification section:** List of uploaded documents/achievements with [View Document] ghost button | **Verify & Add Badge:** Success Green button (#22C55E bg, white text), full width | **Suspend Account:** Warning Amber outlined button | **Delete Account:** Danger outlined button | **No bottom nav**

---

### Screen 57: Pending Registrations / Approvals Screen
```
+-----------------------------------------+
|  [<-]  Pending Approvals                |  App bar
+-----------------------------------------+
|                                         |
|  ---- NEW REGISTRATIONS (5) ----        |  Section label
|                                         |
|  +---------------------------------+    |
|  | [Avatar 48px] Sneha Rao         |    |  Approval card
|  | 👤 Athlete · Hyderabad          |    |
|  | Registered: Today               |    |
|  |                                 |    |
|  | [Reject]           [Approve]    |    |  Danger + Success
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Logo 48px] Pro Sports Academy  |    |
|  | 🏫 Coach · Chennai              |    |
|  | Registered: Yesterday           |    |
|  |                                 |    |
|  | [Reject]           [Approve]    |    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, 8px gap)             |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Pending Approvals" | **Section label:** "NEW REGISTRATIONS (5)" with count | **Approval cards:** Avatar/Logo 48px | Name (14px SemiBold) | Role icon + Role · Location (12px #6B7280) | Registration date (12px #6B7280) | [Reject] (Danger outlined) + [Approve] (Success Green) buttons side by side | **Approve action:** Shows confirmation dialog, then toast "User approved successfully" | **Reject action:** Shows dialog with optional reason input, then toast | **Empty state:** "No pending approvals. All caught up!" | **No bottom nav**

---

### Screen 58: Moderation Queue Screen
```
+-----------------------------------------+
|  [<-]  Moderation Queue        [🔍]     |  App bar
+-----------------------------------------+
|                                         |
|  [All] [Posts] [Comments] [Profiles]    |  Tab pills
|                                         |
|  +---------------------------------+    |
|  | ⚠️  Reported Post #12345        |    |  Report card
|  |     Reported by: Priya Patel    |    |
|  |     Reason: Inappropriate content|   |
|  |     2 hours ago        [Review] |    |  Ghost button
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | ⚠️  Reported Comment #6789      |    |
|  |     Reported by: Rohan Sharma   |    |
|  |     Reason: Spam                |    |
|  |     5 hours ago        [Review] |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | ⚠️  Reported Profile #445       |    |
|  |     Reported by: Coach Rahul    |    |
|  |     Reason: Fake information    |    |
|  |     1 day ago          [Review] |    |
|  +---------------------------------+    |
|                                         |
|  (Scrollable list, 8px gap)             |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Moderation Queue", search icon right | **Tab pills:** All | Posts | Comments | Profiles | **Report cards:** Full width, 16px padding | ⚠️ Warning icon 20px #F59E0B | Report ID (14px SemiBold) | Reported by (12px #6B7280) | Reason (12px #6B7280) | Timestamp (12px #6B7280) | [Review] ghost button right | **Tap card:** Opens Report Detail screen | **Empty state:** "No reports to review. Platform is clean!" | **No bottom nav**

---

### Screen 59: Report Detail Screen
```
+-----------------------------------------+
|  [<-]  Report #12345                    |  App bar
+-----------------------------------------+
|                                         |
|  ---- REPORT INFO ----                  |  Section label
|  +---------------------------------+    |
|  | Reported by: Priya Patel        |    |
|  | Reason: Inappropriate content   |    |
|  | Reported: 2 hours ago           |    |
|  | Status: Pending Review          |    |  #F59E0B
|  +---------------------------------+    |
|                                         |
|  ---- REPORTED CONTENT ----             |
|  +---------------------------------+    |
|  | [Avatar 40px] Arjun Kumar       |    |  Post preview
|  | · [Football]    3h ago          |    |
|  |                                 |    |
|  | This post contains inappropriate|    |  Body text
|  | content that violates...        |    |
|  |                                 |    |
|  | [View Full Content →]           |    |  Ghost button
|  +---------------------------------+    |
|                                         |
|  ---- ACTIONS ----                      |
|  +-----------------------------+        |
|  |      ✓ Dismiss Report         |        |  Secondary outlined
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |      🗑️ Remove Content        |        |  Danger outlined
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |      🚫 Suspend User          |        |  Danger outlined
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Report #12345" | **Report Info:** Card with reporter, reason, timestamp, status | **Reported Content:** Card showing preview of reported post/comment/profile | [View Full Content →] ghost button to see original | **Actions:** Dismiss Report (Secondary outlined) — marks as resolved without action | Remove Content (Danger outlined) — deletes the reported content | Suspend User (Danger outlined) — suspends the user's account | **Each action:** Shows confirmation dialog before executing | **Toast feedback:** "Report dismissed", "Content removed", or "User suspended" | **No bottom nav**

---

### Screen 60: Compose Notification Screen
```
+-----------------------------------------+
|  [<-]  Compose Notification    [Send]   |  App bar
+-----------------------------------------+
|                                         |
|  Notification Title *                   |
|  +-----------------------------+        |
|  | e.g., Trial Announcement    |        |  Text input
|  +-----------------------------+        |
|                                         |
|  Message Body *                         |
|  +-----------------------------+        |
|  | Enter your notification     |        |  Multiline text area
|  | message here...             |        |
|  +-----------------------------+        |
|  Character count: 0/200                 |  Caption 12px #6B7280
|                                         |
|  ---- TARGETING (Optional) ----         |  Section label
|                                         |
|  Target Role                            |
|  +-----------------------------+        |
|  | All Roles              [▼]  |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Target Region                          |
|  +-----------------------------+        |
|  | All Regions            [▼]  |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Target Sport                           |
|  +-----------------------------+        |
|  | All Sports             [▼]  |        |  Dropdown
|  +-----------------------------+        |
|                                         |
|  Estimated Reach: ~1,245 users          |  Caption 12px #6B7280
|                                         |
|  +-----------------------------+        |
|  |         Send Notification     |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Compose Notification", "Send" text button right (disabled until title and body filled) | **Fields:** Notification Title (required), Message Body (required multiline, max 200 chars), Target Role (dropdown), Target Region (dropdown), Target Sport (dropdown) | **Estimated Reach:** Dynamic count based on selected filters — Caption 12px #6B7280 | **Send Notification:** Primary Blue, full width | **Success:** Toast "Notification sent to ~1,245 users" | **No bottom nav**

---

### Screen 61: Notification Targeting Screen
```
+-----------------------------------------+
|  [<-]  Notification Targeting           |  App bar
+-----------------------------------------+
|                                         |
|  ---- SELECT ROLES ----                 |  Section label
|  +---------------------------------+    |
|  | [✓] All Roles                   |    |  Checkbox row
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [ ] Athletes only               |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [ ] Coaches only                |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [ ] Sponsors only               |    |
|  +---------------------------------+    |
|                                         |
|  ---- SELECT REGIONS ----               |
|  +---------------------------------+    |
|  | [✓] All Regions                 |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [ ] Maharashtra                 |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [ ] Delhi                       |    |
|  +---------------------------------+    |
|  (More regions in scrollable list)      |
|                                         |
|  ---- SELECT SPORTS ----                |
|  +---------------------------------+    |
|  | [✓] All Sports                  |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [ ] Cricket                     |    |
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [ ] Football                    |    |
|  +---------------------------------+    |
|  (More sports in scrollable list)       |
|                                         |
|  +-----------------------------+        |
|  |         Apply Targeting       |        |  Primary Blue, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Notification Targeting" | **Checkbox rows:** Full width, 16px padding | Checkbox left (square, #2563EB when checked, #E5E7EB when unchecked) | Label (14px SemiBold #111827) | **Sections:** Roles, Regions, Sports | **All option:** Selecting "All" deselects individual items | **Individual selection:** Selecting any individual item unchecks "All" | **Apply Targeting:** Primary Blue, full width | **Returns to Compose screen with selected filters** | **No bottom nav**

---

### Screen 62: Opportunity Approval Queue Screen
```
+-----------------------------------------+
|  [<-]  Opportunity Approvals            |  App bar
+-----------------------------------------+
|                                         |
|  ---- PENDING (4) ----                  |  Section label
|                                         |
|  +---------------------------------+    |
|  | [Logo 40px] Athlete Sponsorship |    |  Opportunity card
|  |     Nike India                  |    |
|  | Cricket · Pan-India             |    |
|  | Submitted: Nov 1, 2024          |    |
|  |                                 |    |
|  | [Reject]           [Approve]    |    |  Danger + Success
|  +---------------------------------+    |
|  +---------------------------------+    |
|  | [Logo 40px] Equipment Grant     |    |
|  |     Gatorade                    |    |
|  | All Sports · Maharashtra        |    |
|  | Submitted: Oct 30, 2024         |    |
|  |                                 |    |
|  | [Reject]           [Approve]    |    |
|  +---------------------------------+    |
|                                         |
|  ---- RECENTLY APPROVED ----            |
|  +---------------------------------+    |
|  | [Logo 40px] Training Camp       |    |
|  |     FitLife Academy             |    |
|  | Athletics · Bangalore           |    |
|  | Approved: Oct 28, 2024          |    |
|  |                       [View]    |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Opportunity Approvals" | **Pending section:** Section label with count | Opportunity cards: Logo 40px | Title (14px SemiBold) | Sponsor name (12px #6B7280) | Sport · Region (12px #6B7280) | Submitted date (12px #6B7280) | [Reject] (Danger outlined) + [Approve] (Success Green) buttons | **Recently Approved section:** Same cards but with approved date and [View] ghost button | **Approve action:** Shows confirmation, toast "Opportunity approved and published" | **Reject action:** Shows dialog with reason input, toast "Opportunity rejected" | **Empty state:** Per section | **No bottom nav**

---

### Screen 63: Opportunity Review Detail Screen
```
+-----------------------------------------+
|  [<-]  Review Opportunity     [⋯]       |  App bar
+-----------------------------------------+
|                                         |
|  [Logo 80px]                            |
|  Nike India                             |  H1 22px Bold
|  [Sportswear]  Pan-India                |
|                                         |
|  Athlete Sponsorship 2024               |  H2 18px SemiBold
|                                         |
|  ---- SUBMISSION DETAILS ----           |  Section label
|  +---------------------------------+    |
|  | Submitted by: Nike India        |    |
|  | Submitted on: Nov 1, 2024       |    |
|  | Status: Pending Approval        |    |  #F59E0B
|  +---------------------------------+    |
|                                         |
|  ---- OPPORTUNITY DETAILS ----          |
|  +---------------------------------+    |
|  | Sport: Cricket                  |    |
|  | Region: Pan-India               |    |
|  | Type: Sponsorship               |    |
|  | Eligibility: State-level and    |    |
|  |   above                         |    |
|  | Deadline: Dec 31, 2024          |    |
|  +---------------------------------+    |
|                                         |
|  ---- DESCRIPTION ----                  |
|  We are looking for talented cricketers |
|  to sponsor for the upcoming season...  |
|                                         |
|  ---- ADMIN ACTIONS ----                |
|  +-----------------------------+        |
|  |      ✓ Approve & Publish      |        |  Success Green, full width
|  +-----------------------------+        |
|                                         |
|  +-----------------------------+        |
|  |      Reject with Reason       |        |  Danger outlined, full width
|  +-----------------------------+        |
|                                         |
+-----------------------------------------+
```
- **App bar:** Back arrow (←), title "Review Opportunity", [⋯] more menu right | **Sponsor logo:** 80px (XL), circular | **Sponsor name:** H1 22px Bold | **Industry + Coverage:** Sport badge + "Pan-India" | **Opportunity title:** H2 18px SemiBold | **Submission Details:** Card with submitter, date, status | **Opportunity Details:** Card with key-value pairs | **Description:** Section label + body text | **Admin Actions:** Approve & Publish (Success Green, full width) — immediate publish | Reject with Reason (Danger outlined, full width) — opens dialog for rejection reason | **More menu (⋯):** Options: Edit Opportunity (before approval), Preview as User | **No bottom nav**


---

## 9. Navigation Flow Diagrams

### 9.1 Authentication Flow
```
Splash Screen → Login Screen → [Sign Up] → Signup Screen → OTP Verification → Role Selection → [Athlete/Coach/Sponsor Home]
              ↘ [Forgot Password] → Forgot Password → Reset Password → Login Screen
```

### 9.2 Athlete Main Flow
```
Athlete Home (Feed)
    ├── [Create Post FAB] → Create Post Screen → [Post] → Athlete Home
    ├── [Story tap] → Story Viewer → [Back] → Athlete Home
    ├── [Post tap] → Post Detail Screen → [Back] → Athlete Home
    ├── [Profile tab] → My Profile Screen
    │       ├── [Edit] → Edit Profile Screen → [Save] → My Profile
    │       ├── [Add Achievement] → Add Achievement Screen → [Save] → Edit Profile
    │       ├── [Add Tournament] → Add Tournament Screen → [Save] → Edit Profile
    │       ├── [Edit Statistics] → Edit Statistics Screen → [Save] → Edit Profile
    │       ├── [Upload Media] → Upload Media Screen → [Upload] → Media Gallery
    │       ├── [Media Gallery tap] → Media Gallery Screen → [Upload FAB] → Upload Media
    │       └── [Social Links] → Social Links Screen → [Save] → Edit Profile
    ├── [Discover tab] → Discover Screen
    │       ├── [Search] → Search & Filter Screen → [Apply] → Discover Screen
    │       ├── [Athlete card tap] → View Profile Screen → [Connect/Message] → View Profile
    │       ├── [Coach card tap] → View Profile Screen → [View Profile] → View Profile
    │       └── [Sponsor card tap] → View Profile Screen → [View Profile] → View Profile
    ├── [Messages tab] → Chat List Screen
    │       ├── [Chat row tap] → Chat Screen → [Back] → Chat List
    │       └── [Connections] → My Connections Screen → [Chat icon] → Chat Screen
    │               ├── [Requests] → Connection Requests Screen → [Accept/Decline] → Connection Requests
    │               └── [Search] → filters connections in real-time
    └── [Profile tab] → My Profile Screen (same as above)
```

### 9.3 Coach Main Flow
```
Coach Home (Feed)
    ├── [Discover tab] → Discover Screen (Athletes/Sponsors tabs)
    │       ├── [Athlete card] → View Profile Screen → [Message] → Chat Screen
    │       └── [Sponsor card] → View Profile Screen → [View Profile] → View Profile
    ├── [Notifications tab] → Notifications List Screen → [Notification tap] → Notification Detail
    └── [Profile tab] → Coach Profile Screen
            ├── [Edit] → Edit Coach Profile → [Save] → Coach Profile
            ├── [Add Credential] → Add Credential Screen → [Save] → Edit Profile
            ├── [Edit Facilities] → Edit Facilities Screen → [Save] → Edit Profile
            └── [Showcase Athletes] → Showcase Athletes Screen → [Save] → Edit Profile
```

### 9.4 Sponsor Main Flow
```
Sponsor Home (Feed)
    ├── [Discover tab] → Discover Screen (Athletes/Academies tabs)
    │       ├── [Athlete card] → View Profile Screen → [⭐ Save] → View Profile
    │       └── [Academy card] → View Profile Screen → [View Profile] → View Profile
    ├── [Post Opp tab] → My Opportunities Screen
    │       ├── [+] → Post Opportunity Screen → [Submit] → Application Submitted
    │       ├── [Opportunity tap] → Listing Status Screen → [Edit] → Post Opportunity
    │       └── [View tap] → Opportunity Detail Screen
    └── [Profile tab] → Sponsor Profile Screen
            ├── [Edit] → Edit Sponsor Profile → [Save] → Sponsor Profile
            └── [Past Associations] → Past Associations Screen → [Save] → Edit Profile
```

### 9.5 Opportunities Flow (All Roles)
```
Opportunities List Screen (from Discover or Home)
    ├── [Search/Filter] → Search & Filter Screen → [Apply] → Opportunities List
    ├── [Opportunity card tap] → Opportunity Detail Screen
    │       ├── [⭐ Save] → toggles save state
    │       ├── [Apply] → Apply Form Screen → [Submit] → Application Submitted Confirmation
    │       └── [View Sponsor] → View Profile Screen (Sponsor)
    └── [Back] → Previous Screen
```

### 9.6 Admin Flow
```
Admin Dashboard
    ├── [Users icon] → Manage Users List Screen
    │       ├── [User row tap] → User Detail Screen → [Verify/Suspend/Delete] → Manage Users
    │       └── [Pending tab] → Pending Approvals Screen → [Approve/Reject] → Pending Approvals
    ├── [Approve icon] → Pending Approvals Screen (same as above)
    ├── [Reports icon] → Moderation Queue Screen
    │       ├── [Report tap] → Report Detail Screen → [Dismiss/Remove/Suspend] → Moderation Queue
    │       └── [Tab switch] → filter by content type
    ├── [Notify icon] → Compose Notification Screen
    │       └── [Targeting] → Notification Targeting Screen → [Apply] → Compose Notification
    ├── [Opp icon] → Opportunity Approval Queue Screen
    │       ├── [Opportunity tap] → Opportunity Review Detail → [Approve/Reject] → Approval Queue
    │       └── [Approve/Reject buttons] → direct action with toast
    └── [Reports icon] → Platform Reports Screen
```

---

## 10. State & Interaction Specifications

### 10.1 Button States (All Buttons)
| State | Visual |
|---|---|
| Default | Standard bg color, shadow present |
| Hover (Web) | Darker shade bg, maintained shadow |
| Pressed | Darker shade bg + scale(0.98), maintained shadow |
| Disabled | Light shade bg, no shadow, #FFFFFF text |
| Loading | CircularProgressIndicator (20px white) replaces label, button disabled |

### 10.2 Card Press States
| State | Visual |
|---|---|
| Default | shadow-md, scale(1.0) |
| Pressed | shadow-lg, scale(0.98), 150ms ease-out |

### 10.3 Input Field States
| State | Border | Background | Text |
|---|---|---|---|
| Default | 1px #E5E7EB | #F8FAFC | #111827 |
| Focused | 2px #2563EB | #FFFFFF | #111827 |
| Filled | 1px #E5E7EB | #FFFFFF | #111827 |
| Error | 2px #EF4444 | #FEF2F2 | #111827 |
| Disabled | 1px #E5E7EB | #F3F4F6 | #9CA3AF |

### 10.4 Bottom Navigation States
| State | Icon | Label | Indicator |
|---|---|---|---|
| Active | #2563EB | #2563EB 10px SemiBold | 3px underline dot #2563EB |
| Inactive | #9CA3AF | #9CA3AF 10px Regular | None |

### 10.5 Notification Card States
| State | Background | Left Border |
|---|---|---|
| Unread | #EFF6FF | 3px solid #2563EB |
| Read | #FFFFFF | None (0.5px #E5E7EB border all around) |

### 10.6 Connection Button States
| Context | Button Style | Text |
|---|---|---|
| Not connected | Secondary outlined | "Connect" |
| Request sent | Disabled gray | "Pending" |
| Connected | Disabled (bg #F8FAFC, text #22C55E) | "Connected ✓" |
| Own profile | Hidden | — |

### 10.7 Opportunity Status Display
| Status | Dot | Color | Button State |
|---|---|---|---|
| Open | ● | #22C55E | "Apply →" CTA Orange active |
| Pending (applied) | ○ | #F59E0B | "Applied ✓" disabled |
| Closed | ● | #EF4444 | "Closed" disabled |

### 10.8 Loading States
| Context | Visual |
|---|---|
| Screen load | Skeleton screens (shimmer blocks matching content shape) |
| Button action | CircularProgressIndicator (20px white) inside button |
| Pull-to-refresh | RefreshIndicator (#2563EB color) |
| Image upload | Linear progress bar (#2563EB) below upload area |
| List pagination | Skeleton card at bottom of list |

### 10.9 Error States
| Context | Visual |
|---|---|
| Inline field | 12px #EF4444 text + exclamation icon below field |
| Screen-level | Full-screen error with icon, title, subtitle, "Try Again" button |
| Network | Toast: "Check your connection and try again." |
| Form submission | Toast: "Something went wrong. Please try again." |

### 10.10 Empty States by Screen
| Screen | Title | Subtitle | CTA |
|---|---|---|---|
| Feed | No posts yet | Follow athletes to see their updates | Discover Athletes |
| Connections | No connections yet | Find and connect with athletes in your sport | Discover |
| Messages | No messages | Connect with athletes to start chatting | Go to Connections |
| Notifications | You're all caught up! | Check back later for updates | Go to Home |
| Opportunities | No opportunities found | Try adjusting your filters | Clear Filters |
| Search results | No results found | Try a different name or sport | Clear Search |
| Media Gallery | No media yet | Upload your highlights! | Upload Media |
| Tournament History | No tournaments added | Record your participation history | Add Tournament |
| Admin Queue | No pending items | All caught up! | — |

### 10.11 Animation Specifications
| Animation | Duration | Easing | Properties |
|---|---|---|---|
| Screen push/pop | 200ms | ease-in-out | translateX (right-to-left push) |
| Bottom sheet open | 300ms | ease-out | translateY (bottom to position) |
| Bottom sheet close | 250ms | ease-in | translateY (position to bottom) |
| Card press | 150ms | ease-out | scale(0.98) |
| Like button | 200ms | spring | scale(1.3) → scale(1.0) |
| Tab switch | 200ms | ease-in-out | opacity + slight translateX |
| FAB press | 150ms | ease-out | scale(0.92) |
| Notification badge | 150ms | ease-out | scale(1.2) → scale(1.0) |
| Skeleton shimmer | 1.4s | linear | gradient position left → right (infinite) |
| Success checkmark | 400ms | ease-out | stroke draw animation |
| OTP error shake | 300ms | ease-in-out | translateX oscillation |

### 10.12 Accessibility Requirements
- **Minimum touch target:** 48x48dp for all interactive elements
- **Contrast ratio:** 4.5:1 minimum for body text, 3:1 for large text
- **Screen reader labels:** All icons and images must have content descriptions
- **Focus indicators:** Visible focus rings (2px #2563EB outline) for keyboard navigation
- **Reduced motion:** Respect `prefers-reduced-motion` — disable non-essential animations
- **Text scaling:** Support up to 200% text scaling without layout breakage
- **Color independence:** Never rely on color alone to convey information (always pair with icon/text)

### 10.13 Responsive Considerations (Mobile Only)
- **Screen width:** 360dp - 420dp (standard Android phone range)
- **Safe areas:** Account for notches, status bar (24dp), gesture navigation (16dp bottom)
- **Keyboard handling:** Input fields must scroll into view when keyboard opens
- **Orientation:** Portrait only for MVP (landscape not supported)

---

## Appendix A: Screen Count Summary

| Group | Screen Count | Screen Numbers |
|---|---|---|
| Authentication & Onboarding | 7 | 1-7 |
| Athlete Screens | 17 | 8-24 |
| Coach / Academy Screens | 8 | 25-32 |
| Sponsor Screens | 9 | 33-41 |
| Shared Screens | 11 | 42-52 |
| Admin Screens (Mobile) | 11 | 53-63 |
| **TOTAL** | **63** | — |

## Appendix B: Role-Based Screen Access Matrix

| Screen Group | Athlete | Coach | Sponsor | Admin |
|---|---|---|---|---|
| Auth (7 screens) | ✅ | ✅ | ✅ | ✅ |
| Athlete (17 screens) | ✅ | ❌ | ❌ | ❌ |
| Coach (8 screens) | ❌ | ✅ | ❌ | ❌ |
| Sponsor (9 screens) | ❌ | ❌ | ✅ | ❌ |
| Shared (11 screens) | ✅ | ✅ | ✅ | ✅ |
| Admin (11 screens) | ❌ | ❌ | ❌ | ✅ |

## Appendix C: Icon Reference

Use **Lucide Icons** or **Heroicons (Outline style)** throughout the app. Key icons by screen:

| Screen/Feature | Primary Icon | Size | Color |
|---|---|---|---|
| Home tab | home | 24px | Active: #2563EB, Inactive: #9CA3AF |
| Discover tab | search | 24px | Active: #2563EB, Inactive: #9CA3AF |
| Create tab | plus-circle | 24px | Active: #2563EB, Inactive: #9CA3AF |
| Messages tab | message-circle | 24px | Active: #2563EB, Inactive: #9CA3AF |
| Profile tab | user | 24px | Active: #2563EB, Inactive: #9CA3AF |
| Notifications tab | bell | 24px | Active: #2563EB, Inactive: #9CA3AF |
| Post Opp tab | star | 24px | Active: #2563EB, Inactive: #9CA3AF |
| Settings | settings | 24px | #6B7280 |
| Back arrow | arrow-left | 24px | #111827 |
| More menu | more-vertical | 20px | #6B7280 |
| Share | share-2 | 20px | #6B7280 |
| Like (default) | heart | 20px | #6B7280 |
| Like (active) | heart | 20px | #EF4444 (filled) |
| Comment | message-circle | 20px | #6B7280 |
| Search | search | 20px | #6B7280 |
| Verified | check-circle | 16px | #22C55E |
| Camera | camera | 24px | #FFFFFF (on #2563EB bg) |
| Attachment | paperclip | 24px | #6B7280 |
| Send | send | 24px | #2563EB |
| Microphone | mic | 24px | #6B7280 |
| Play (video) | play-circle | 32-48px | #FFFFFF |
| Download | download | 24px | #FFFFFF (on media viewer) |
| Filter | filter | 20px | #6B7280 |
| Calendar | calendar | 16px | #6B7280 |
| Trophy (achievement) | trophy | 20px | #F59E0B |
| Medal (tournament) | medal | 20px | #2563EB |
| Document | file-text | 20px | #6B7280 |
| Warning | alert-triangle | 20px | #F59E0B |
| Checkmark | check | 24px | #22C55E |
| Close/X | x | 16-24px | #6B7280 or #EF4444 |
| Trash/Delete | trash-2 | 20px | #EF4444 |
| Log Out | log-out | 20px | #EF4444 |
| Eye (password) | eye / eye-off | 20px | #6B7280 |
| Chevron Right | chevron-right | 16px | #6B7280 |
| Chevron Down | chevron-down | 16px | #6B7280 |

---

*Document: SportX India — Complete App Wireframe Specification v1.0*
*Derived from: SportX Design System v1.0 + Screen Inventory v1.1 + User-Wise Feature List v1.0*
*Total Screens: 63 | Platform: Flutter (Android) MVP | Prepared for: Design & Development Reference*
