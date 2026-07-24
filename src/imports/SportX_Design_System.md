# SportX India — Design System
**Version:** 1.0 MVP
**Platform:** Flutter (Android) + Web Admin Panel
**Theme:** Light (Dark mode — future release)
**Inspiration:** LinkedIn · Strava · Instagram · Behance

---

## 1. Brand Identity

### Brand Personality
| Trait | Expression |
|---|---|
| Professional | Clean layouts, structured profiles, no clutter |
| Energetic | Orange accents, bold sport banners, active typography |
| Trustworthy | Verified badges, consistent UI language, honest copy |
| Youthful | Rounded corners, generous spacing, modern font |
| Premium | Subtle shadows, high-quality image treatment, refined spacing |

### Brand Voice (UI Copy)
- Active voice always: "Connect" not "Send Connection Request"
- Specific over clever: "48 athletes found" not "Lots of players here!"
- Errors explain + guide: "OTP expired. Tap Resend to get a new one."
- Empty states invite action: "No connections yet. Start discovering athletes →"

---

## 2. Color Palette

### Primary Colors

| Name | Hex | Usage |
|---|---|---|
| Royal Blue | `#2563EB` | Primary buttons, active nav, links, app bar accents |
| Orange | `#F97316` | CTA buttons, FAB, badges, highlights |

### Neutral Colors

| Name | Hex | Usage |
|---|---|---|
| White | `#FFFFFF` | Screen backgrounds, card surfaces, nav bar |
| Surface Gray | `#F8FAFC` | Card backgrounds, input fields, section fills |
| Border | `#E5E7EB` | Card borders, dividers, input borders |
| Text Primary | `#111827` | Headings, body text, labels |
| Text Secondary | `#6B7280` | Subtitles, meta info, hints, timestamps |

### Semantic Colors

| Name | Hex | Usage |
|---|---|---|
| Success Green | `#22C55E` | Verified badge, accepted status, connected state, open opportunity |
| Error Red | `#EF4444` | Errors, suspended status, rejected status, delete actions |
| Warning Amber | `#F59E0B` | Pending approval, draft state, soft warnings |
| Info Blue Light | `#EFF6FF` | Unread notification background, info banners, filter chip bg |

### Color Usage Rules
- Never use Orange on a Blue background or Blue on an Orange background
- Text on `#2563EB` or `#F97316` backgrounds must be `#FFFFFF`
- Text on `#F8FAFC` or `#FFFFFF` backgrounds must be `#111827` or `#6B7280`
- Minimum contrast ratio: 4.5:1 for body text, 3:1 for large text
- Never use raw black `#000000` — use `#111827` for darkest text

### Color Gradient (Banner/Hero)
```
Sport Banner overlay gradient:
  Top: transparent
  Bottom: rgba(17, 24, 39, 0.55)
  Direction: vertical (top → bottom)
  Applied over all profile banner images for text legibility
```

---

## 3. Typography

### Font Family
**Primary:** `Poppins` (Google Fonts)
**Fallback:** `Inter`, `SF Pro`, `sans-serif`

Use Poppins for all text. Inter as fallback only.

### Type Scale

| Role | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| Display | 28px | 700 Bold | 1.2 | Screen titles, onboarding headings |
| Heading 1 | 22px | 700 Bold | 1.3 | Profile names, major section titles |
| Heading 2 | 18px | 600 SemiBold | 1.35 | Welcome greetings, card section titles |
| Heading 3 | 16px | 600 SemiBold | 1.4 | Sub-section titles, tab labels |
| Body | 14px | 400 Regular | 1.5 | Body copy, card descriptions, post text |
| Body SemiBold | 14px | 600 SemiBold | 1.5 | Button labels, stat values, names in lists |
| Caption | 12px | 400 Regular | 1.4 | Timestamps, meta info, section labels, char count |
| Caption SemiBold | 12px | 600 SemiBold | 1.4 | Tags, chips, small badges |

### Typography Rules
- Headings: always `#111827`
- Body: `#111827` for primary, `#6B7280` for secondary/meta
- Captions: `#6B7280`
- Links / interactive text: `#2563EB`
- CTA text on buttons: `#FFFFFF`
- Never use font sizes below 12px
- Letter spacing on Display/H1: `-0.02em` (tighter for bold display)
- Letter spacing on Caption: `+0.01em` (slightly looser for readability)

---

## 4. Spacing System

All spacing uses an **8px base grid**.

| Token | Value | Usage |
|---|---|---|
| `space-1` | 4px | Icon-to-text gap, tight inline spacing |
| `space-2` | 8px | Between small elements, padding inside chips |
| `space-3` | 12px | Internal card padding (compact) |
| `space-4` | 16px | Standard internal padding, between list items |
| `space-5` | 20px | Section internal padding |
| `space-6` | 24px | Between sections within a screen |
| `space-8` | 32px | Between major content blocks |
| `space-10` | 40px | Screen-level top/bottom padding |
| `space-12` | 48px | Hero section spacing |

### Horizontal Screen Padding
- All screens: **16px** left and right padding
- Cards: **16px** internal horizontal padding
- Section labels: **16px** from edge

---

## 5. Border Radius

| Component | Radius | Notes |
|---|---|---|
| Cards | 16px | Athlete cards, post cards, coach cards |
| Buttons (primary/secondary) | 12px | All buttons |
| Input fields | 12px | Text inputs, dropdowns, search bars |
| Chips / Tags | 20px | Filter chips, sport badges, role tags |
| Avatars | 50% | Always circular |
| Bottom sheets / Modals | 20px top-left, 20px top-right, 0px bottom | Drag-up sheets |
| Notification cards | 12px | Slightly tighter than standard cards |
| Story circles | 50% | Always circular + 2.5px border ring |
| Media tiles (grid) | 8px | Highlight/post image grid tiles |
| OTP boxes | 10px | OTP digit input boxes |
| Stat chips | 8px | Profile stat containers |

---

## 6. Shadows & Elevation

| Level | CSS/Flutter equivalent | Used on |
|---|---|---|
| `shadow-sm` | `0 1px 4px rgba(0,0,0,0.06)` | Input fields, chips, small surfaces |
| `shadow-md` | `0 2px 12px rgba(0,0,0,0.08)` | Cards (athlete, post, coach, sponsor) |
| `shadow-lg` | `0 4px 20px rgba(0,0,0,0.12)` | Bottom sheets, modals, FAB |
| `shadow-blue` | `0 4px 12px rgba(37,99,235,0.25)` | Primary blue buttons (hover/active state) |
| `shadow-orange` | `0 4px 12px rgba(249,115,22,0.30)` | Orange CTA buttons, FAB |
| `shadow-nav` | `0 -1px 8px rgba(0,0,0,0.06)` | Bottom navigation bar (top shadow) |

### Elevation Rules
- Cards float at `shadow-md`
- FAB always at `shadow-orange`
- App bar: no shadow (flat, just bottom border `0.5px #E5E7EB`)
- Bottom nav: `shadow-nav` only
- Modals/sheets: `shadow-lg`

---

## 7. Buttons

### Primary Button (Blue — Default action)
```
Background:   #2563EB
Text:         #FFFFFF  14px SemiBold
Radius:       12px
Height:       48px
Padding:      0 24px
Shadow:       shadow-blue
Width:        Full width for forms / Auto for inline actions

States:
  Default  → bg #2563EB
  Hover    → bg #1D4ED8  (darker shade)
  Pressed  → bg #1E40AF  + slight scale 0.98
  Disabled → bg #93C5FD  text #FFFFFF  no shadow
  Loading  → show CircularProgressIndicator (white) inside button
```

### CTA Button (Orange — Primary conversion action)
```
Background:   #F97316
Text:         #FFFFFF  14px SemiBold
Radius:       12px
Height:       48px
Padding:      0 24px
Shadow:       shadow-orange
Width:        Full width for screens / Auto for cards

States:
  Default  → bg #F97316
  Hover    → bg #EA6C0A
  Pressed  → bg #C2570A  + scale 0.98
  Disabled → bg #FED7AA  text #FFFFFF  no shadow
```

### Secondary Button (Outlined Blue)
```
Background:   transparent
Border:       1.5px solid #2563EB
Text:         #2563EB  14px SemiBold
Radius:       12px
Height:       48px
Padding:      0 24px

States:
  Default  → transparent bg
  Pressed  → bg #EFF6FF
  Disabled → border #93C5FD  text #93C5FD
```

### Ghost / Text Button
```
Background:   transparent
Border:       none
Text:         #2563EB  14px SemiBold
Height:       auto (inline)
Padding:      4px 8px

Used for: "View All →", "Load More", "Forgot password?", section-level actions
```

### Danger Button (Outlined Red)
```
Background:   transparent
Border:       1.5px solid #EF4444
Text:         #EF4444  14px SemiBold
Radius:       12px
Height:       48px

Used for: Log out, Delete, Withdraw actions
```

### Icon Button (Circular)
```
Background:   #F8FAFC
Border:       1px solid #E5E7EB
Size:         40x40px  radius: 50%
Icon:         20px  #6B7280

Active state: bg #EFF6FF  border #2563EB  icon #2563EB
Used for: Notification bell, Settings, Back, Share
```

### FAB (Floating Action Button)
```
Background:   #F97316
Icon:         24px  #FFFFFF
Size:         56x56px  radius: 50%
Shadow:       shadow-orange
Position:     Bottom nav center (embedded in nav for Create/Post Opp.)
```

---

## 8. Input Fields

### Standard Text Input
```
Background:   #F8FAFC
Border:       1px solid #E5E7EB
Border Radius: 12px
Height:       52px
Padding:      0 16px
Font:         14px Regular  #111827
Placeholder:  14px Regular  #9CA3AF

States:
  Default  → border #E5E7EB
  Focused  → border 2px #2563EB  bg #FFFFFF
  Error    → border 2px #EF4444  bg #FEF2F2
  Filled   → border #E5E7EB  bg #FFFFFF
  Disabled → bg #F3F4F6  text #9CA3AF
```

### Multiline Text Area
```
Same as text input but:
  Min height: 100px
  Padding:    12px 16px
  Resize:     vertical only
  Character count shown bottom-right in 12px #6B7280
```

### Dropdown
```
Same styling as text input +
  Trailing icon: chevron-down  16px  #6B7280
  Tap opens bottom sheet with list options
  Selected value: #111827
  Placeholder: #9CA3AF
```

### Search Bar
```
Background:   #F8FAFC
Border:       1px solid #E5E7EB
Border Radius: 12px
Height:       48px
Padding:      0 16px
Leading icon: search  20px  #6B7280
Focused:      border 2px #2563EB
Clear button: × appears when input has text  #6B7280
```

### OTP Input Boxes
```
Size:         52x60px each  (4 boxes, spaced 12px apart)
Background:   #F8FAFC
Border:       1.5px solid #E5E7EB
Border Radius: 10px
Font:         22px Bold  #111827  center-aligned

States:
  Empty    → border #E5E7EB
  Active   → border 2px #2563EB  bg #FFFFFF
  Filled   → border #2563EB  bg #FFFFFF
  Error    → border 2px #EF4444  bg #FEF2F2  shake animation
```

---

## 9. Cards

### Athlete Card
```
Background:   #FFFFFF
Border:       0.5px solid #E5E7EB
Border Radius: 16px
Shadow:       shadow-md
Padding:      16px

Layout:
  Row 1: [Avatar 48px] | Name (14px SemiBold) | Verified ✓
                        | Sport · City (12px #6B7280)
  Row 2: Achievement level  ·  N achievements (12px #6B7280)
  Row 3: ─────────────────────────────────────
  Row 4:                         [Connect / Connected btn]
```

### Coach / Academy Card
```
Same structure as Athlete Card, replacing:
  Row 1: [Logo 48px] | Academy Name | Verified ✓
                      | Sport · City
  Row 2: N athletes  ·  N programs
  Row 4:                         [View Profile btn]
```

### Sponsor Card
```
Same structure, replacing:
  Row 1: [Logo 48px] | Org Name  | Verified ✓
                      | Industry
  Row 2: N Active Opportunities
  Row 4:                         [View Profile btn]
```

### Opportunity Card
```
Background:   #FFFFFF
Border:       0.5px solid #E5E7EB
Border Radius: 16px
Shadow:       shadow-md
Padding:      16px

Layout:
  Row 1: [Sponsor Logo 40px]  Opportunity Title (16px SemiBold)
  Row 2: Sport  ·  Region  ·  Deadline (12px #6B7280)
  Row 3: ─────────────────────────────────────
  Row 4: ● Open (12px #22C55E)      [Apply → ] CTA orange btn
```

### Post Card
```
Background:   #FFFFFF
Border:       none (feed-style, separated by 8px gap)
Border Radius: 0px (full-width) OR 16px (if shown in a list)
Padding:      16px

Layout:
  Row 1: [Avatar 40px] | Name (14px SemiBold) · Sport chip
                        | Timestamp (12px #6B7280)    [···]
  Row 2: Caption text (14px #111827) — multiline
         Hashtags (14px #2563EB)
  Row 3: [Media Image/Video — 16:9 — radius 12px]
  Row 4: ❤ N   💬 N   ↗ Share  (14px #6B7280)
```

### Notification Card (Unread)
```
Background:   #EFF6FF
Left border:  3px solid #2563EB
Border Radius: 12px
Padding:      14px 16px

Layout:
  Row 1: [Icon 20px] | Title (14px SemiBold #111827)
  Row 2:               Body (13px #111827)
  Row 3:               Timestamp (12px #6B7280)  [Action btn]
```

### Notification Card (Read)
```
Background:   #FFFFFF
Border:       0.5px solid #E5E7EB
No left border accent
```

---

## 10. Navigation

### Bottom Navigation Bar
```
Height:       64px
Background:   #FFFFFF
Top border:   0.5px solid #E5E7EB
Shadow:       shadow-nav

Items: 5 tabs (Athlete) / 4 tabs (Coach) / 4 tabs (Sponsor)
  Icon size:    24px
  Label size:   10px SemiBold
  Active:       #2563EB icon + label + 3px underline dot
  Inactive:     #9CA3AF icon + label

FAB (center):
  Size:         52x52px  radius: 50%
  Background:   #F97316
  Icon:         24px  #FFFFFF
  Shadow:       shadow-orange
  Offset:       -12px from nav top edge (floating)
```

### App Bar
```
Height:       56px
Background:   #FFFFFF
Bottom border: 0.5px solid #E5E7EB
Shadow:       none (flat)
Padding:      0 16px

Left:   Back arrow (←) OR app logo/wordmark
Center: Screen title  18px SemiBold  #111827
Right:  Action icons (max 2)  icon-button style
```

### Tab Pills (within screen)
```
Container: horizontal scroll row  padding: 0 16px  gap: 8px
Pill:
  Active:   bg #2563EB  text #FFFFFF  12px SemiBold  radius: 20px
  Inactive: bg #F8FAFC  text #6B7280  12px SemiBold  radius: 20px
  Padding:  8px 16px
  Height:   34px
```

---

## 11. Chips & Badges

### Filter Chip (Active)
```
Background:   #EFF6FF
Border:       1px solid #2563EB
Text:         #2563EB  12px SemiBold
Radius:       20px
Padding:      6px 12px
Trailing:     × icon  12px  #2563EB  (to remove filter)
```

### Filter Chip (Inactive)
```
Background:   #F8FAFC
Border:       1px solid #E5E7EB
Text:         #6B7280  12px Regular
Radius:       20px
Padding:      6px 12px
```

### Sport Badge
```
Background:   #EFF6FF
Text:         #2563EB  11px SemiBold
Radius:       6px
Padding:      3px 8px
Used inline next to username/name in cards and feed
```

### Verified Badge
```
Icon:         checkmark circle  16px  #22C55E
Label:        "Verified" (tooltip on long press)
Position:     Inline after name or overlaid on avatar bottom-right
```

### Unread Count Badge
```
Background:   #F97316
Text:         #FFFFFF  10px Bold
Min-size:     18x18px  radius: 50%
Position:     top-right of icon  offset: -4px -4px
Max display:  "9+" if count > 9
```

### Status Dot
```
● Open      #22C55E  8px circle
○ Pending   #F59E0B  8px circle (outline)
● Closed    #EF4444  8px circle
```

---

## 12. Avatars

### Sizes
| Size | Dimensions | Used in |
|---|---|---|
| XS | 28x28px | Comment rows, mini lists |
| SM | 40px | Feed post header, chat rows, connection rows |
| MD | 48px | Directory cards, notification rows |
| LG | 64px | Stories, search results |
| XL | 80px | Profile header (own profile, view profile) |
| XXL | 96px | Onboarding / welcome screen |

### Avatar Rules
- Always circular (radius: 50%)
- Default fallback: first initial on `#2563EB` background  white text
- Verified overlay: small `#22C55E` check circle badge at bottom-right (XL/XXL only)
- Story ring: `2.5px` border in `#2563EB` when unviewed, `#E5E7EB` when viewed, gap `2px` between ring and avatar

---

## 13. Icons

### Icon Library
**Recommended:** Lucide Icons or Heroicons (Outline style)

### Icon Sizes
| Size | Usage |
|---|---|
| 16px | Inline within body text, caption level |
| 20px | Card icons, input leading icons, badges |
| 24px | Navigation bar, app bar actions |
| 28px | Section header icons |
| 48px | Empty state illustrations, onboarding icons |

### Icon Color Rules
- Navigation (inactive): `#9CA3AF`
- Navigation (active): `#2563EB`
- Inside blue buttons: `#FFFFFF`
- Inside orange buttons: `#FFFFFF`
- Inline in body: `#6B7280`
- Action icons (like, comment, share): `#6B7280` default, `#EF4444` for liked state
- Verified: `#22C55E`
- Warning: `#F59E0B`

### Key Sport Icons
Use sport-specific icons for cricket (🏏), football (⚽), athletics (🏃), badminton (🏸), swimming (🏊), etc. — use outline emoji or custom SVG icons to keep consistent with the icon library style.

---

## 14. Images & Media

### Profile Banners
```
Dimensions:   Full width × 180px
Object-fit:   cover
Overlay:      vertical gradient (transparent → rgba(17,24,39,0.55))
Corner Radius: 0px (edge-to-edge in profile header)
Default:      sport-themed gradient bg (#2563EB → #1E40AF)
```

### Post Media (Feed)
```
Aspect Ratio: 16:9 preferred / 1:1 square allowed
Width:        Full card width minus padding
Border Radius: 12px
Object-fit:   cover
Video:        play button overlay (white circle 48px, rgba bg)
```

### Highlight Grid (3-col)
```
Layout:       3 equal columns  gap: 2px
Cell size:    (screen width - 32px) / 3 — square aspect ratio
Border Radius: 8px
Video cells:  play icon overlay (white 32px, dark semi-transparent bg)
```

### Logo / Brand Images (Coach, Sponsor)
```
Shape:        Circle (same avatar rules)
Background:   #F8FAFC if logo has transparency
Border:       0.5px solid #E5E7EB
```

---

## 15. Dividers & Separators

### Full-Width Divider
```
Height:   1px
Color:    #E5E7EB
Margin:   16px 0
Used between profile sections, settings groups
```

### Inset Divider (Card-level)
```
Height:   0.5px
Color:    #E5E7EB
Margin:   12px 0
Left offset: 16px (aligns with content, not edge)
```

### Section Label
```
Text:     12px SemiBold UPPERCASE  #6B7280  letter-spacing: 0.08em
Margin:   4px 0 12px 0
e.g.      "PERSONAL INFO"  "SPORT DETAILS"  "TODAY"
```

---

## 16. Animations & Transitions

### Timing Functions
| Name | Value | Used for |
|---|---|---|
| Fast | 150ms ease-out | Button press, toggle, like action |
| Standard | 200ms ease-in-out | Screen transitions, card expand |
| Smooth | 300ms ease-in-out | Bottom sheet open/close, modal |
| Slow | 400ms ease-in-out | Onboarding animations, success screens |

### Key Animations
```
Screen push/pop:    200ms  horizontal slide (right-to-left push)
Bottom sheet open:  300ms  slide up from bottom  ease-out
Bottom sheet close: 250ms  slide down  ease-in
Card press:         scale(0.98)  150ms  ease-out
Like button:        scale(1.3) → scale(1.0)  200ms  spring
Tab switch:         200ms  fade + slight horizontal shift
Notification badge: scale(1.2) → scale(1.0)  150ms  on new notification
Loading skeleton:   shimmer animation  1.2s infinite  left → right
FAB press:          scale(0.92)  150ms
Success screen:     checkmark draw animation  400ms
```

### Rules
- No animation longer than 400ms in production
- All animations must respect `prefers-reduced-motion` (disable non-essential motion)
- No looping animations except loading states
- Avoid simultaneous animations on more than 2 elements
- Page transitions: keep it directional and consistent (push right, pop left)

---

## 17. Empty States

### Pattern
```
┌───────────────────────────────┐
│                               │
│        [Illustration]         │  48–64px icon  #9CA3AF
│                               │
│    No connections yet         │  16px SemiBold  #111827
│                               │
│  Start discovering athletes   │  14px  #6B7280  center
│  and send connection requests │
│                               │
│  ┌─────────────────────────┐  │
│  │    Discover Athletes →  │  │  CTA btn  #F97316  auto-width
│  └─────────────────────────┘  │
│                               │
└───────────────────────────────┘
```

### Empty State Copy Examples
| Screen | Title | Subtitle | CTA |
|---|---|---|---|
| Feed | No posts yet | Follow athletes to see their updates | Discover Athletes |
| Connections | No connections yet | Find and connect with athletes in your sport | Discover |
| Messages | No messages | Connect with athletes to start chatting | Go to Connections |
| Notifications | You're all caught up! | Check back later for updates | Go to Home |
| Opportunities | No opportunities found | Try adjusting your filters | Clear Filters |
| Search results | No results found | Try a different name or sport | Clear Search |

---

## 18. Loading States

### Screen Loading
```
Use skeleton screens (not spinners) for content-heavy screens:
  Cards:      shimmer blocks in card shape
  Avatars:    shimmer circles
  Text lines: shimmer rectangles (varying widths: 60%, 80%, 45%)
  Shimmer:    #F0F0F0 → #E0E0E0 → #F0F0F0  1.4s loop
```

### Inline / Button Loading
```
Replace button label with CircularProgressIndicator (20px, white)
Button stays same size and disabled during load
```

### Pull-to-Refresh
```
Use Flutter's RefreshIndicator
Color: #2563EB
```

---

## 19. Error States

### Inline Field Error
```
Text:       12px Regular  #EF4444
Icon:       exclamation circle  14px  #EF4444
Position:   below input field  margin-top: 4px
Border:     changes to 2px #EF4444 on the field
```

### Toast / Snackbar
```
Background:   #111827
Text:         #FFFFFF  14px
Radius:       10px
Duration:     3 seconds  bottom-center
Success toast: left icon ✓  #22C55E
Error toast:   left icon ✕  #EF4444
```

### Full Screen Error
```
Same layout as empty state pattern:
  Icon:     ⚠ or network icon  48px  #F59E0B
  Title:    "Something went wrong"
  Subtitle: "Check your connection and try again."
  CTA:      [Try Again]  outlined btn
```

---

## 20. Role-Based UI Differences Summary

| Component | Athlete | Coach / Academy | Sponsor |
|---|---|---|---|
| Bottom nav tabs | Home, Discover, Create, Messages, Profile | Home, Discover, ─, Notifications, Profile | Home, Discover, Post Opp, ─, Profile |
| FAB | ➕ Create Post  #F97316 | None | ⭐ Post Opportunity  #F97316 |
| Profile banner default | Sport action photo | Academy / ground photo | Brand banner |
| Avatar shape | Circle (person photo) | Circle (logo or person) | Circle (brand logo) |
| Card action (on others) | [Connect] / [Message] | [View Profile] / [Message] | [View Profile] / [★ Save] |
| Feed content | Peer athlete posts | Athlete + Academy posts | Athlete + Academy posts |
| Discover tabs | Athletes / Coaches / Sponsors | Athletes / Sponsors | Athletes / Academies |
| Verified badge | ✓ personal achievement | ✓ institutional credential | ✓ organisation verified |

---

## 21. Flutter Implementation Notes

### Fonts
```yaml
# pubspec.yaml
fonts:
  - family: Poppins
    fonts:
      - asset: assets/fonts/Poppins-Regular.ttf
        weight: 400
      - asset: assets/fonts/Poppins-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Poppins-Bold.ttf
        weight: 700
```

### Theme Setup (ThemeData)
```dart
ThemeData(
  fontFamily: 'Poppins',
  colorScheme: ColorScheme.light(
    primary: Color(0xFF2563EB),
    secondary: Color(0xFFF97316),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    error: Color(0xFFEF4444),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Color(0xFF111827),
    onSurface: Color(0xFF111827),
  ),
  scaffoldBackgroundColor: Color(0xFFFFFFFF),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF111827),
    elevation: 0,
    shadowColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111827),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF2563EB),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minimumSize: Size(double.infinity, 48),
      textStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF8FAFC),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
    ),
    hintStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: Color(0xFF9CA3AF),
    ),
  ),
  cardTheme: CardTheme(
    color: Color(0xFFFFFFFF),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    selectedItemColor: Color(0xFF2563EB),
    unselectedItemColor: Color(0xFF9CA3AF),
    selectedLabelStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
    ),
    elevation: 0,
  ),
)
```

### App Colors Class
```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary
  static const Color primary = Color(0xFF2563EB);
  static const Color cta = Color(0xFFF97316);

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Borders
  static const Color border = Color(0xFFE5E7EB);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Primary shades
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryDarker = Color(0xFF1E40AF);

  // Orange shades
  static const Color ctaDark = Color(0xFFEA6C0A);
  static const Color ctaLight = Color(0xFFFED7AA);
}
```

### App Text Styles Class
```dart
// lib/core/theme/app_text_styles.dart

class AppTextStyles {
  static const TextStyle display = TextStyle(
    fontFamily: 'Poppins', fontSize: 28,
    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Poppins', fontSize: 22,
    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Poppins', fontSize: 18,
    fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Poppins', fontSize: 16,
    fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: 'Poppins', fontSize: 14,
    fontWeight: FontWeight.w400, color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle bodySemiBold = TextStyle(
    fontFamily: 'Poppins', fontSize: 14,
    fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: 'Poppins', fontSize: 12,
    fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
  static const TextStyle captionSemiBold = TextStyle(
    fontFamily: 'Poppins', fontSize: 12,
    fontWeight: FontWeight.w600, color: AppColors.textSecondary,
  );
  static const TextStyle button = TextStyle(
    fontFamily: 'Poppins', fontSize: 14,
    fontWeight: FontWeight.w600, letterSpacing: 0.1,
  );
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: 'Poppins', fontSize: 12,
    fontWeight: FontWeight.w600, color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );
}
```

---

*Document: SportX India — Design System v1.0 MVP*
*Companion files: SportX_Athlete_Screens.md · SportX_Coach_Screens.md · SportX_Sponsor_Screens.md · SportX_Admin_Screens.md*
