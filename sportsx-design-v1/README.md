# SportX — Client-Ready Design Package

A complete, polished design package for **SportX**, India's sports network. Open `index.html` in any browser to start the client walkthrough.

## How to show this to the client

1. **Start at the design showcase:** open `index.html`
2. Walk through: hero → overview → design system → flows → screen library
3. Click any screen tile to open the live mockup
4. Open `landing.html` to show the marketing site

No build step. No dependencies. Pure HTML + CSS + Lucide icons + Google Fonts.

## What's in this package

| File | Purpose |
| --- | --- |
| `index.html` | **Client showcase** — start here. Hero, role overview, design tokens, user flows, and a visual library of every screen organised by role. |
| `landing.html` | **Marketing site** — the public-facing homepage for SportX with hero, value props, role breakdown, stats and CTA. |
| `home-dashboard.html` … `settings.html` | 78 individual product screens across 6 user roles (athlete, coach, academy, organizer, sponsor, admin) plus auth/shared screens. |
| `DESIGN-HANDOFF.md` | Original implementation contract for engineering. |
| `DESIGN-MANIFEST.json` | Machine-readable map of every screen, token and interaction. |

## Design system at a glance

- **Brand accent:** `#1677ff` (SportX blue) with deep navy `#0d47a1` for gradients
- **Typography:** Inter, 800/700/600/500/400 weights
- **Surface tokens:** `#ffffff` background, `#f7f8fa` surface, `#6b7280` muted, `#d9dee7` border
- **Radius:** 8px standard, 12px cards, 20px hero panels
- **Icons:** Lucide (line icon set)
- **Target viewport:** 430px mobile (iPhone Pro Max class), with all screens designed at production fidelity

## Role breakdown (78 screens total)

- **Onboarding & shared** — 12 screens (auth, role selection, splash, filter panel, etc.)
- **Athlete** — 29 screens (home feed, search, academies, coaches, trials, tournaments, scholarships, sponsorships, profile, settings)
- **Coach** — 8 screens (dashboard, onboarding, enquiries, profile)
- **Academy** — 7 screens (dashboard, onboarding, listing edit, post trial, registrants)
- **Organizer** — 7 screens (dashboard, create tournament, registrations, results)
- **Sponsor** — 7 screens (dashboard, athlete discovery, sponsorships, inbox)
- **Admin** — 10 screens (dashboard, moderation, users, analytics, settings)

## Suggested client walkthrough (10 min)

1. **Open `landing.html`** — show the marketing vision (30s)
2. **Open `index.html`** — walk through the design system tokens (1m)
3. **Athlete flow** — show home → academy directory → academy detail → enquire → saved (2m)
4. **Trial flow** — show trial listings → detail → registration → confirmation (1.5m)
5. **Academy operator flow** — show academy dashboard → post trial → registrant list (2m)
6. **Organizer + Sponsor + Admin** — quick tour of remaining dashboards (2m)
7. **Open any specific screen** the client wants to drill into (1.5m)

## Notes for the developer who'll build this

- All screens are independent HTML files at the project root (no bundler).
- Shared tokens are duplicated in each `<style>` block — extract to a CSS file or design-token system when implementing.
- Every screen uses the same Inter font and Lucide icon set.
- All clickable cards are wired with `onclick` handlers that route to the appropriate screen — links stay navigable as a demo.
- Mobile-first: each screen is designed for ~430px width. Wrap in a container when implementing desktop/tablet responsive variants.