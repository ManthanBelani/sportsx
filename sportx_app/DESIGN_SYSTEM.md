# SportX Flutter App — Design System (v2)

Extracted from `sportx_app/lib/`. Source of truth is `sportsx-design-v2`.

> Core files:
> - `lib/theme/colors.dart` — palette
> - `lib/theme/design_tokens.dart` — spacing / radius / metrics
> - `lib/theme/app_theme.dart` — Material 3 ThemeData
> - `lib/shared/presentation/widgets/sportx_ui.dart` — UI kit
> - `lib/shared/presentation/widgets/form_page_template.dart`
> - `lib/shared/presentation/widgets/detail_page_template.dart`
> - `lib/shared/presentation/widgets/skeleton.dart`
> - `lib/shared/presentation/widgets/async_state_view.dart`
> - `lib/core/utils/snackbar_utils.dart`

---

## 1. Brand Principles

- Yellow-first brand. No blue primary.
- White cards on light grey surface.
- 1px borders + soft shadows, no Material elevation.
- Sora for headings, Inter for body.
- Lucide icons only.
- 8px base spacing, 16px page padding.

---

## 2. Colors (`theme/colors.dart`)

### Brand

| Token | Hex | Usage |
|-------|-----|-------|
| `yellow` / `cta` | `#FFC107` | Primary CTA bg, selected chip, nav indicator |
| `yellowDeep` / `primary` / `primaryDark` | `#D9A400` | Theme primary, focus border, rating star, section icons |
| `yellowTint` / `ctaLight` | `#FFF6DA` | Pending pill bg, CTA light bg |
| `yellowSoft` | `#FFF9E6` | Soft highlight |
| `primaryLight` | `#FFD54A` | Button gradient top |
| `ctaDark` | `#F5B400` | Button gradient bottom, progress bar |
| `primaryDarker` | `#8A6D00` | Selected nav / text-button |
| `ink` | `#111111` | Button text, headings |
| `dark` | `#2B2B2B` | Secondary button text |

### Neutrals

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#FFFFFFFF` | AppBar, cards, bottom bar |
| `surface` | `#FFF4F5F7` | Scaffold bg, meta pills, detail grid |
| `cardBackground` | `#FFFFFFFF` | Cards |
| `textPrimary` | `#FF111111` | Headings, body |
| `textSecondary` | `#FF6B7280` | Subtitles, hints, meta |
| `textTertiary` | `#FF9CA3AF` | Placeholders, unselected nav |
| `border` | `#FFE8EAED` | Card / input / divider border |
| `borderSoft` | `#FFEFF1F4` | Inner pills, soft borders |

### Semantic

| Token | Hex / Pair |
|-------|------------|
| `success` / `successLight` | `#22C55E` / `#DCFCE7` |
| `error` / `errorLight` | `#EF4444` / `#FEE2E2` |
| `warning` / `warnText` | `#F59E0B` / `#B45309` |
| `info` / `infoLight` | `#3B82F6` / `#E3EFFF` |
| `sportBadgeBg` | `#E3EFFF` |
| `verifiedBadge` | `#22C55E` |
| `mandatoryIndicator` | `#EF4444` |

### Role Accents

| Token | Hex |
|-------|-----|
| `coach` | `#8A6AEA` |
| `academy` | `#03B94C` |
| `organizer` | `#FB802E` |
| `scout` | `#3B82F6` |
| `admin` | `#EF4444` |
| `shared` | `#06B6D4` |
| `pink` | `#F24C96` |
| `amberDeep` | `#FE9710` |

### Gradients

```dart
// PrimaryButton / selected Chip / checkbox
LinearGradient(topCenter -> bottomCenter, [#FFD54A, #FFC107, #F5B400])

// Avatar (EntityRow, GreetCard)
LinearGradient(topLeft -> bottomRight, [#FFE9A8, #FFC107, #F5B400])

// GreetCard bg
LinearGradient(topCenter -> bottomCenter, [white, #FFFCF0])
```

---

## 3. Typography (`theme/app_theme.dart`)

Dependencies: `google_fonts`, `lucide_flutter`.

- Headings: **Sora**
- Body / Labels / Buttons: **Inter**

| Style | Font | Size | Weight | Color | Notes |
|-------|------|------|--------|-------|-------|
| `displayLarge` | Sora | 28 | 800 | textPrimary | letterSpacing -1.0 |
| `displayMedium` | Sora | 22 | 700 | textPrimary | |
| `displaySmall` | Sora | 22 | 700 | textPrimary | |
| `headlineMedium` | Sora | 20 | 700 | textPrimary | |
| `titleLarge` / Section | Sora | 19 | 700 | ink | `SectionHeader`, detail title |
| `titleMedium` | Sora | 16 | 700 | textPrimary | |
| `titleSmall` | Sora | 15 | 700 | textPrimary | OppCard title 15 |
| AppBar | Sora | 17 | 700 | textPrimary | |
| `bodyLarge` | Inter | 16 | 400 | textPrimary | height 1.5 |
| `bodyMedium` | Inter | 14 | 400 | textPrimary | height 1.5 |
| `bodySmall` | Inter | 12 | 400 | textSecondary | letterSpacing 0.1 |
| `labelLarge` / Button | Inter | 14 | 700 | ink/dark | |
| `labelMedium` | Inter | 12 | 600 | textSecondary | |
| `labelSmall` | Inter | 12 | 600 | textSecondary | letterSpacing 0.08 |
| Pill | Inter | 11 | 700 | variant fg | |
| BottomNav selected | Inter | 10-11 | 800/700 | primaryDarker | unselected 10/600 tertiary |

---

## 4. Spacing / Radius / Elevation (`theme/design_tokens.dart`)

```dart
spacingXs  = 4.0
spacingSm  = 8.0
spacingMd  = 12.0
spacingLg  = 16.0  // page padding
spacingXl  = 20.0
spacing2Xl = 24.0
spacing3Xl = 32.0

radius   = 8.0
radiusSm = 10.0
radiusMd = 16.0  // cards, entities
radiusLg = 22.0
pill     = 999
card     = 16
oppCard  = 18
detailCard = 20
btnRadius = 14
inputRadius = 13
```

Component metrics:

```dart
btnHeight = 50.0
inputHeight = 50.0
chipHeight = 34.0
iconBtnSize = 40.0
fabSize = 58.0
oppThumbHeight = 158.0
avatarSm = 42.0
avatarMd = 56.0
avatarLg = 96.0
heroHeight = 230.0
```

Shadows (`sportx_ui.dart` → `SportXShadows`):

```dart
e1: [0,1,2 rgba(16,20,21,.05), 0,1,3 rgba(.04)]        // cards, chips, inputs
e2: [0,8,24-8 rgba(16,20,21,.14), 0,2,6 rgba(.05)]     // sticky bar
btnShadow: [0,6,16 rgba(FFC107,.55)]
fabShadow: [0,10,22 rgba(FFC107,.55), 0,3,8 rgba(17,17,17,.18)]
```

> Use `BoxShadow`, not Material `elevation`. Cards: `elevation: 0`.

---

## 5. Theme Defaults (`theme/app_theme.dart` → `AppTheme.lightTheme`)

```dart
useMaterial3: true
scaffoldBackgroundColor: surface (#F4F5F7)
primaryColor: yellowDeep
colorScheme.light(
  primary: yellowDeep,
  secondary: yellow,
  surface: surface,
  error: error,
  onPrimary: ink,
  onSecondary: ink,
  onSurface: textPrimary,
)
```

| Component | Spec |
|-----------|------|
| AppBar | `white 88%`, fg textPrimary, elevation 0, Sora 17/700 |
| Card | white, 16r, 1px `border`, margin 0/6, elevation 0 |
| ElevatedButton | yellow bg, ink fg, 0 elevation, pad 13/20, 14r, min 50h, Inter 14/700 |
| OutlinedButton | dark fg, 1px border, pad 11/16, 14r, min 46h |
| TextButton | primaryDarker, Inter 14/700 |
| Input | filled white, pad 14/16, 13r, 1.5px border, focus yellowDeep, error error, label secondary 14, hint tertiary 14 |
| BottomNav | white, selected primaryDarker, unselected tertiary, 10px labels 800/600 |
| NavigationBar | indicator yellow 22%, white bg, 0 elevation, 11px label |
| Chip | white, selected yellow, Inter 13 dark, pad 15/6, 11r + border |
| Divider | border, 0.5 thick |
| SnackBar | textPrimary bg, white Inter 14, 10r, floating |

---

## 6. UI Kit (`shared/presentation/widgets/sportx_ui.dart`)

| Widget | Props | Visual Spec |
|--------|-------|-------------|
| `PrimaryButton` | `label, onPressed, icon, small` | Gradient yellow, small ? 36h/11r : 50h/14r, `1px #785000 18%`, btnShadow, Inter 14 (small 13) /700 ink, icon 17 ink + 8 gap |
| `SecondaryButton` | `label, onPressed, icon` | White, 46h, 14r, border, e1, Inter 14/700 dark |
| `SportXTopBar` | `title/titleWidget, showBack, actions, bottom` | White 88%, Sora 17/700, 1px border divider, Lucide `arrowLeft` |
| `SectionHeader` | `title, actionText, onActionTap` | Sora 19/700 ink + pill see-all: white/border/999r, Inter 12.5/700 secondary + chevron 14 |
| `SportXChip` | `label, selected, onTap, icon` | 34h, pad 15h, 11r, unselected white/e1/border Inter 13/500 dark; selected yellow gradient/btnShadow/`#785000 20%` Inter 700 ink, icon 14 |
| `StatusPill` | `label, kind: pending/ok/no/draft/feat/info` | 999r, pad 11/5, Inter 11/700. pending yellowTint/B45309, ok DCFCE7/15803D, no FEE2E2/B91C1C, draft F1F3F5/6B7280, feat 16A34A/white, info E3EFFF/3B82F6 |
| `EntityRow` | `title, subtitle, avatarText, onTap, trailing` | White, 16r, border, e1, pad 12, mb 10, 42 circle avatar gradient Inter 15/800, title Inter 14.5/600, subtitle 12 secondary, chevron `#C9CDD3` 20 |
| `OppCard` | `title, org, meta[{icon,text}], featured, onTap` | White, 18r, border, e1, mb 13, 158h `#14161A` thumb + trophy 46 white70, FEATURED pill, pad 15/13/15/14, Sora 15/700, org Inter 12.5 secondary, meta pills surface/borderSoft/999r 12 secondary |
| `GreetCard` | `title, subtitle, progress 0..1, avatarText` | White→#FFFCF0, `#F0E3B2` border, 18r, e1, pad 15, 56 avatar, title Inter 15.5/700, pct Sora 12/800, 8h bar `#EDEFF2` / `#F5B400` 999r |
| `QuickTile` | `label, icon, tintBg, tintFg, onTap` | White, 16r, border, e1, pad 12, 40 circle tint + 19 icon, Sora 13.5/700 |
| `SportXSearchBar` | `hint, onTap` | 50h, white, 1.5px border, 14r, e1, pad 14h, search 18 secondary + Inter 14 secondary |
| `SportXIconButton` | `icon, onTap, badge` | 40 circle white/border/e1, 19 dark icon, badge red 19min 999r white 2px ring Inter 11/700 white |

Icons: `lucide_flutter` (`arrowLeft`, `chevronRight`, `trophy`, `search`, `mapPin`, `star`, `heart`, `phone`, `flag`, `navigation`, `cloudOff`, `searchX`).

---

## 7. Page Templates / Layout Patterns

### Form Page (`form_page_template.dart` → `FormPageTemplate`)

- Scaffold `surface`, AppBar white 88% + Sora 17/700 + 1px border.
- Body `SingleChildScrollView` pad `16,16,16,110`, maxWidth pattern 480 for CTA.
- Auto-fill block: label Inter 12/700/0.4 dark + white card 16r/border/e1 pad 12.
- Confirm row: 22px box 7r white/border 1.5, checked yellow gradient + ink check 15, text Inter 13.5 dark 1.5.
- BottomSheet: white 94%, top border, pad 16/12 + safeArea, full-width `PrimaryButton` disabled until confirmed.

### Detail Page (`detail_page_template.dart` → `DetailPageTemplate`)

- Scaffold `surface`, Stack: scroll content (pad bottom 110) + overlay header + sticky CTA.
- Hero: 230h, image cover or `#14161A` + trophy 46 white 90%.
- Header btns: 38 circle `#141416 45%` + white 25% border, icon 18 white; save toggles Lucide `heart` → Material `favorite` red.
- Content card: `Translate(0,-20)`, white, 20r, border, e1, pad 16.
- Title Sora 19/700/1.25, subtitle Inter 12.5 secondary + mapPin 14, rating star yellowDeep 16 + Inter 14/600 + count 13 secondary.
- Tags: surface/borderSoft/999r pad 9/5 Inter 12 secondary.
- Details grid: 2-col, 10 gap, 2.2 aspect, surface/borderSoft/16r pad 12, key 12 secondary + value 14/600.
- Location: 120h map box surface/16r/border + `EntityRow` + navigation 18.
- Report link: flag 14 + Inter 13 secondary, centered.
- Sticky CTA: white 94%, border, 18r, e2, pad 12, Primary (+ Secondary 48 phone or dual CTA).

### Directory / List Pattern

- Surface bg, 16 page pad, white cards 12-16r + border + e1, 10-12 gaps.
- Search → filter chips → list/grid. See `directory_list_template.dart`.

---

## 8. States / Feedback

### Loading (`skeleton.dart`)

```dart
Shimmer.fromColors(base: border 60%, highlight: surface, 1400ms)
SkeletonBox: border bg, height required, default 8r
```

Variants: `GenericListSkeleton` (64 thumb + 14/12 lines + 20r pills), `GenericGridSkeleton` (2-col 0.85, 110 thumb), `GenericDetailSkeleton` (180 hero + stats + 48 CTA), `HomeSkeleton`, `DiscoverSkeleton`, `NotificationsSkeleton`, `ConnectionsSkeleton`, `ChatListSkeleton`, `Coach*`, `ScoutDashboardSkeleton`, `SponsorDashboardSkeleton`, etc.

### Async (`async_state_view.dart`)

- `AsyncDetailBuilder` / `DirectoryStateView`: loading → `Generic*Skeleton` in Scaffold, error → `_ErrorView`, empty → `_EmptyView`.
- Error: `cloudOff` 40 secondary + 14 secondary msg + ElevatedButton primary Retry.
- Empty: `searchX` 40 secondary + `Nothing here yet` 14 secondary.

### SnackBar (`core/utils/snackbar_utils.dart` → `SnackBarUtils`)

| Method | Bg | Duration |
|--------|----|----------|
| `showSuccess(msg)` | success | 2s |
| `showError(err, fallback)` | error | 4s |
| `showInfo(msg)` | info | 3s |
| `showValidationError(fieldErrors, err)` | error | first field error |

Floating, white text, `hideCurrentSnackBar` first, strips `Exception:/DioException` prefixes, truncates to 220 chars first line.

---

## 9. Assets / Dependencies

`pubspec.yaml`:

- `flutter`, `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `intl`
- `google_fonts`, `lucide_flutter`, `cached_network_image`, `flutter_svg`, `shimmer`
- `image_picker`, `url_launcher`, `share_plus`, `table_calendar`, `pull_to_refresh`
- `firebase_core`, `firebase_messaging`, `flutter_dotenv`
- `uses-material-design: true`
- assets: `.env`, `assets/images/`

No custom `FontFamily` in pubspec — fonts via `GoogleFonts` at runtime (`Inter` + `Sora`).

---

## 10. Usage Snippets

```dart
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/theme/design_tokens.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

// CTA
const PrimaryButton(label: 'Apply Now', onPressed: submit);

// Filter
SportXChip(label: 'Football', selected: true, onTap: () {});

// Status
const StatusPill(label: 'PENDING', kind: PillKind.pending);

// List row
EntityRow(title: 'Coach Name', subtitle: 'Football • Delhi', avatarText: 'C');

// Card
OppCard(title: 'U-16 Trials', org: 'Academy', featured: true, meta: [(icon: LucideIcons.mapPin, text: 'Delhi')]);

// Header
SectionHeader(title: 'Opportunities', actionText: 'See all', onActionTap: () {});
```

### Do / Don't

- Do use `AppColors` + `DesignTokens` + `SportX*` widgets. Don't hardcode hex/padding.
- Do use `e1/e2/btnShadow` via `BoxDecoration`. Don't use Material `elevation`.
- Do use Sora for titles, Inter for body. Don't mix other fonts.
- Do use Lucide icons. Don't use Material icons except filled `favorite` for saved state.
- Do wrap lists in `DirectoryStateView` + skeletons. Don't leave blank loading.
