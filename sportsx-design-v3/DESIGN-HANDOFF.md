# SportX v3 implementation handoff (Phase 1)

Source of truth: `src/App.tsx` (+ `src/index.css`). Static mirrors: `index.html` (showcase), `app.html` (prototype), `styles.css` (tokens).

## Build target
- Static preview needs no bundler: open `index.html` / `app.html` directly.
- React/Vite in `src/` is for ongoing work (`npm install && npm run dev`).
- Keep class names, copy, spacing, colors identical between `src/` and static mirrors.

## Token contract
- Extract before coding: `--yellow`, `--yellow-deep`, `--yellow-light`, `--yellow-soft`, `--ink`, `--secondary`, `--tertiary`, `--surface`, `--border`, `--border-soft`, semantic (`--green`, `--blue`, `--red`, `--purple`, `--orange`, `--pink`), `--shadow`, `--shadow-up`, radius 8/11/13/14/16/18/99, Sora + Inter, 430px target.
- Primary CTA is always `linear-gradient(#FFD54A, #FFC107, #F5B400)` with ink text — never a flat blue.
- No Material elevation; shadows only via the two tokens above.

## Screen map (Phase 1)
- Showcase: 4 roles × 11 = 44 mini screens in `index.html` (JS-rendered from `roleShowcase`).
- Clickable: 13 hashes in `app.html`: `home, explore, create, community, more, profile, programs, events, athletes, facilities, notifications, messages, detail`.
- `screens/*.html` are thin iframe wrappers around `app.html#<screen>` for decks/iframes.
- Phase 2 (not in this drop): role-specific coach/organizer/scout content, athlete + admin roles, auth/onboarding, landing page, desktop breakpoints.

## Interaction contract
- Bottom nav: Home / Explore / Create (raised yellow) / Community / More. Sub-screens (profile, programs, events, athletes, facilities) highlight More; notifications/messages/detail hide the nav.
- Toasts: dark `#2B2B2B` pill, 1.8s, bottom 90px — for every non-navigating action.
- Explore filter tabs and Community tabs are local state; everything else is hash routing.

## Checklist
1. Open `index.html`, click through all 4 role rows; confirm 44 cards render with no horizontal page scroll (row scroll only).
2. Open `app.html`, visit all 13 hashes; confirm nav visibility rules + sticky CTAs + toasts.
3. Compare `app.html` against `src/App.tsx` screens pixel-for-pixel before refactoring.
4. Validate 360 / 390 / 430 widths with no overflow; mini-phones are fixed 252px cards by design.
