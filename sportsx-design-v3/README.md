# SportX v3 — New Design Package (Phase 1)

Yellow-first mobile redesign. **100% plain HTML** — open any file directly in a browser, edit with any text editor. No build step, no dependencies (only Google Fonts + images from CDN).

## Start here

| File | Purpose |
|------|---------|
| `index.html` | **Role showcase** — 4 roles × 11 screens (44 mini previews). Click any card to open that screen. |
| `screens/home.html` | **Home** — start of the clickable Academy flow. |
| `screens/*.html` | **13 standalone screens** — each is a complete, editable page: `home`, `explore`, `create`, `community`, `more`, `profile`, `programs`, `events`, `athletes`, `facilities`, `notifications`, `messages`, `detail`. |
| `styles.css` | Shared design tokens + components. Link from every screen — edit once, reflect everywhere. |
| `app.html` | Alternate all-in-one prototype (same 13 screens via hash routing). Optional — `screens/` is the primary format. |
| `src/` | Original React + Vite source for reference (`npm install && npm run dev`). Static HTML is the source of truth for design reviews. |

## What's inside (Phase 1)

- **Roles in showcase:** Coach, Academy, Organizer, Talent Scout — 11 screens each.
- **Fully built as HTML:** Academy path — all 13 screens above, linked together with real `<a href>` navigation + bottom nav.
- **Placeholders (Phase 2):** Coach / Organizer / Scout role-specific content, athlete + admin roles, auth/onboarding, landing page. Mini previews reuse the same shell today.

## How to edit

1. Open `screens/<name>.html` in a text editor.
2. Look for `<!-- EDIT: ... -->` comments — they mark the exact blocks to duplicate/change (cards, rows, texts, images).
3. Colors / fonts / spacing live in `styles.css` (`:root` tokens at the top).
4. Save, refresh the browser. Done.

## Design tokens (`styles.css`)

- `--yellow #FFC107`, `--yellow-deep #D9A400`, `--yellow-light #FFF6DA`, `--yellow-soft #FFF9E6`
- `--ink #111111`, `--secondary #6B7280`, `--tertiary #9CA3AF`
- `--surface #F4F5F7`, `--white #FFFFFF`, `--border #E8EAED`, `--border-soft #EFF1F4`
- Type: Sora (headings) + Inter (body). Icons: inline SVG / emoji fallbacks per screen.
- Target: 430px mobile (`.phone` max-width).

## Client walkthrough (5 min)

1. Open `index.html` — hero → 4 role sections → horizontal screen rows.
2. Click any Academy card (e.g. `Academy Profile`) — opens `screens/profile.html`.
3. Click through: Home → greet card → Explore → academy card → Detail → Send Enquiry toast → More → Facilities → Messages. All links are real files.
