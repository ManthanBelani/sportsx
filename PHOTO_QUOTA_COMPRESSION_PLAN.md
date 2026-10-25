# Photo-Only Uploads, Compression & Per-Role Photo Quota — Implementation Plan

## Goal

1. **Remove video uploads for every role** — users can upload **photos only**
   (profile photo, cover photo, gallery, posts, achievements, credentials, etc.).
   Existing videos already on the server stay viewable; no *new* video uploads.
2. **Add compression logic** so the server is not flooded with heavy photos
   (client-side tuning + server-side resize/re-encode of every upload).
3. **Admin-controlled per-role photo limits** — admin can set, per role
   (athlete, coach, academy, organizer, scout, sponsor), how many photos that
   role may upload.
4. **Excluded from the limit count**: cover photo, profile photo (avatar),
   and photos attached to **posts**. The quota counts only **media gallery
   uploads** (documents, achievements and credentials are also not counted —
   they are not gallery photos; see *Scope of the counter* below).

> **Assumption note.** The request reads "do not count the cover photo and
> profile photo into it, and also the photo into the post". This plan assumes
> *all three* are excluded from the quota, i.e. the limit governs only the
> private/public media gallery. If posts **should** be counted instead, the
> only change is the WHERE clause in the counter query (Step 3E).

---

## Current state (verified in codebase)

| Area | Location | Behaviour today |
|---|---|---|
| Shared picker/upload | `sportx_app\lib\shared\presentation\widgets\media_picker.dart` (`pickAndUploadMedia`, L45–143) | Bottom sheet: camera / gallery / **video**; `ImagePicker.pickImage(imageQuality: 80)` for photos, `pickVideo()` with a 10 MB guard; multipart POST `POST /api/media/upload` with `media_type` (`photo` / `video` / `document`) |
| Media gallery | `sportx_app\lib\features\athlete\presentation\screens\media_gallery_screen.dart` | Photo / **Video** / Achievement tabs; `_uploadMedia` picks video when Videos tab is active (L218); long-press → set as profile/cover (L171–210) |
| Post creation | `sportx_app\lib\features\social\presentation\screens\create_post_screen.dart` (L48–101) | Uploads a photo via `/media/upload`, then `POST /api/posts` with `image_url`; a **video tile is still offered** in `create_bottom_sheet.dart:209` and `create_screen.dart:81` |
| Profile / cover | `edit_profile_screen.dart` (L127–179), `coach_profile_edit_screen.dart` (L174–186), academy & organizer onboarding/profile screens | Upload via the shared picker; `PUT /api/me/profile` / `PUT /api/me/profile/images` with `photo_media_id` / `cover_media_id` |
| Backend upload | `sportx-api\app\Http\Controllers\MediaController.php` `upload()` (L43–136) | Validates `media_type`, MIME sniffing, `max:10240` KB (10 MB) from `config/sportx.php`, stores on local `public` disk, inserts `media_items` row |
| Backend config | `sportx-api\config\sportx.php` L181–186 | `allowed_video_types => ['mp4']`, max 10 MB |
| Admin settings store | `sportx-api\app\Support\PlatformSettings.php` | JSON-file-backed settings (`storage/app/platform_settings.json`) with `writable()` allow-list and `defaults()`; already has `media_max_size_mb` key. Read by both the mobile admin screen (`AdminSettingsController`) and the web Blade panel (`AdminPanelController::settings`) |
| Server compression | — | **None.** No Intervention/GD usage; only the Flutter `imageQuality: 80` reduces photos before they hit the wire |
| Backend roles | `app\Support\UserRoles`, `EnsureRole` middleware | Roles: athlete, coach, academy, organizer, talent_scout, sponsor, admin |

---

## Step-by-step implementation

### Phase 1 — Flutter: photo-only uploads

**1A. `media_picker.dart` — the single choke point**

- Remove the `pickVideo()` branch from `pickAndUploadMedia()`
  (`media_picker.dart:85–92`); the video camera option disappears from the
  bottom sheet for **all roles**.
- Change the picker's `maxWidth`/`maxHeight`/`imageQuality` to a stricter,
  reviewed constant (e.g. `imageQuality: 75`, `maxWidth: 1920`) — this is the
  first compression stage and immediately cuts upload payload size.
- Reject non-image mimeTypes defensively before upload (documents screen
  still uses its own branch — keep it photo/PDF-only as it already is).
- Add a new optional parameter **`context: String`** (values: `gallery`,
  `profile`, `cover`, `post`, `achievement`, `credential`, `document`,
  `logo`). It is sent as `context` in the `POST /media/upload` body so the
  backend can apply the correct quota rule (Step 3).

**1B. Media gallery screen**

- Remove the **Videos tab** and the `video` branch in `_uploadMedia`
  (`media_gallery_screen.dart:145–148, 214–224`).
- Keep the Videos tab data render for **legacy** videos already uploaded, but
  stop offering upload there; label it "Videos (read-only)" or hide the tab
  when a user has zero videos (preferred).
- Expose the remaining user's quota to the UI: when calling
  `GET /me/media`, the response (Step 3F) includes
  `photos_used` / `photos_limit`. Show a small header line —
  e.g. "23 / 50 photos — 27 left" — and disable the upload button with a
  snackbar message when the limit is reached **before** the user even opens
  the picker (best UX: quota known client-side; verified again server-side).

**1C. Post creation**

- Delete the video tile from `create_bottom_sheet.dart:209` and
  `create_screen.dart:81`.
- When calling the shared picker from `create_post_screen.dart`, pass
  `context: 'post'` (excluded from quota, still compressed).
- Allow up to N images per post (introduce `POST /api/posts` support for
  `image_media_ids` array, initial max 5 — see 3G) while keeping backward
  compatibility with the single `image_url` field.

**1D. Profile / cover / other surfaces**

- `edit_profile_screen.dart`, `coach_profile_edit_screen.dart`,
  academy/organizer onboarding & profile screens keep working unchanged
  (they already go through the shared picker): they will now pass
  `context: 'profile'` / `'cover'` / `'logo'` and are automatically excluded
  from the quota.
- `media_viewer_screen.dart` stays as-is (it still plays legacy videos).
- Add a compile-time guard: `grep -r "pickVideo"` in `sportx_app\lib` must
  return zero hits after the change.

### Phase 2 — Compression (server side)

**2A. Install the image driver**

`config/images.php` already exists (driver `gd`). Laravel's image handling
needs `intervention/image` as a direct dependency (only in lock today):

```
composer require intervention/image
composer require intervention/image-driver-gd
```

(Imagick variant `image-driver-imagick` optional on the server if available.)

**2B. New `App\Services\PhotoCompressor`**

- Input: stored path of a freshly uploaded `photo`.
- Decode, strip EXIF (privacy: strips GPS coordinates), 
- **Resize**: fit within `1600×1600` px (configurable:
  `platform_settings.photo_max_dimension`, default 1600).
- **Re-encode**: JPEG quality 78 (configurable
  `platform_settings.photo_jpeg_quality`); convert PNGs with no alpha to JPEG,
  keep alpha PNGs as WebP/PNG.
- Overwrite the stored file in place (public disk), then update the
  `media_items` row (`size_bytes`, `mime_type`) and write
  `compressed_at` timestamp.
- Return the percentage saved for logging/metrics.

**2C. Queue it — do not block the request**

The project already runs **Laravel Horizon / queues** (`queue:listen` in the
composer `dev` script). Create a job:

```
app/Jobs/CompressPhoto.php        (implements ShouldQueue)
```

- `MediaController::upload()` dispatches the job **after** storing the
  original file and responding to the client, so upload latency is unchanged.
- The job is idempotent (`$media->compressed_at === null` guard) and
  try/catch failures with a Sentry report (Sentry already integrated).
- Jump image uploads down the queue quickly; large batches still drain fast
  because re-encoding a 10 MB JPEG takes ~100–300 ms.
- Optional burning-down: a one-off artisan command
  `php artisan media:compress-existing` (chunked 100 by 100) to compress the
  existing backlog — run in a maintenance window.
- Keep an untouched backup only for **profile/cover** images (they're small
  and frequently displayed); for gallery photos overwrite directly to save
  disk. *(Decision recorded here so it's revisitable.)*

**2D. Reject videos server-side for all roles**

- `MediaController::upload()` — remove `video` from the
  `media_type` validation and return a clear error:
  `422 "Video uploads are no longer supported. Please upload a photo."`
- `config/sportx.php`: empty `allowed_video_types`, keep the image allow-list.
- `PlatformController`/`PostController` (routes/api.php posts L115–124):
  reject non-empty `video_url` on new posts with the same message; existing
  posts with `video_url` remain renderable.

### Phase 3 — Admin per-role photo quota

**3A. Settings keys in `PlatformSettings`** (`app\Support\PlatformSettings.php`)

Defaults (gallery photos; `0` = no limit, negative/disabled = upload
disabled):

```php
'gallery_photo_limit_athlete'   => 100,
'gallery_photo_limit_coach'     => 150,
'gallery_photo_limit_academy'   => 500,
'gallery_photo_limit_organizer' => 300,
'gallery_photo_limit_talent_scout' => 100,
'gallery_photo_limit_sponsor'   => 100,
```

Add each key to `writable()` **and** `defaults()`. Because
`effective()` overlays defaults with stored overrides
(`PlatformSettings::effective()`, L63–66), no schema change is required —
limits live in the existing `platform_settings.json`, with an
`AuditLog::create` entry written by `AdminSettingsController::update()` as it
already does (settings.update audit trail is free).

**3B. Helper**

```php
// PlatformSettings
public static function galleryPhotoLimit(string $role): int;
```

Wraps a match on the role → limit key. Single source of truth (the class
header docblock explicitly warns against duplicate readers — respect it).

**3C. SQLite avoidance — use a counter, not a recount**

Counting `media_items` repeatedly can get slow; but role limits here are
simple and `media_items` is small. Still, prefer a maintained counter:

- New columns on the owner row (athlete_profiles / coach_profiles /
  academy_profiles / organizer_profiles / sponsor_profiles /
  talent_scout_profiles): `gallery_photo_count INT DEFAULT 0`.
- Increment in `MediaController::upload()` (inside a DB transaction),
  decrement in `destroy()` so deleting photos frees quota.
- One-off backfill migration/artisan command sets the initial count from
  the real `media_items` rows.

**3D. Enforcement in `MediaController::upload()`**

In `upload()`, before storing:

```php
if ($context === 'gallery') {                       // from Step 1A
    $limit = PlatformSettings::galleryPhotoLimit($user->role);
    if ($limit >= 0) {
        $used = $profile->gallery_photo_count;      // from 3C
        if ($used >= $limit) {
            abort(422, "Upload limit reached: {$limit} photos allowed for your role (profile & cover photos are free).");
        }
        if ($used + $batch > $limit && $batch > 1) { /* multi-select case */ }
    }
}
```

Server answer is the **authoritative** check; the app only pre-checks
(Step 1B) for UX. The blocked error message also arrives in the snackbar.
Increment happens after the file store succeeds, decrement on delete
(owner-or-admin check already exists in `destroy()`).

**3E. Context tagging**

- `POST /media/upload` accepts `context` (validated enum). When omitted by
  older app versions, default to `gallery` (safest = count it).
- The row stores `context` in a new nullable string column
  `media_items.context` (migration with `hasColumn` guard like other recent
  migrations, e.g. `2026_10_14_000002_phase2_media_captions.php`).
- Profile-photo / cover flows additionally **update the owner row**
  (`photo_media_id` / `cover_media_id`) and can now include the previous
  media id's owner decrement logic when a photo is replaced or deleted.

**3F. Expose limit & usage to the app**

- Extend `GET /me/media` response with:
  ```json
  "photo_quota": { "used": 23, "limit": 100, "remaining": 77 }
  ```
- The Flutter media gallery + settings screens read this (no extra call).

**3G. Photo limit on posts (not quota-related)**

- `PostController::store()` L115: accept `image_media_ids[]` with
  `max:5` (new platform key `post_max_photos` default 5).
- Validate each id: owned by user, `context`/owner matches, still exists.
- Delete the `video_url` acceptance from the validation (keep DB column for
  legacy rows) — with a friendly 422 message.

---

## Admin panel (both UIs already exist)

### Mobile admin app (JSON route: `/api/admin/settings` → `AdminSettingsController`)

- The screen reads `PlatformSettings::effective()`. Because the new per-role
  keys are inside `writable()` + `defaults()`, `update()` will accept them and
  the audit-log write happens automatically.
- UI addition in the Flutter admin "System Settings" screen: a
  "Photo limits" section listing one numeric field per role
  (0 = "no limit" helper text). Validation: `0 <= n <= 10000`.
- Backend validation in `AdminSettingsController::update()` — extend the
  auto-built `$rules` loop:
  - boolean keys stay `boolean`,
  - new gallery limit keys get `sometimes|integer|min:0|max:10000`.

### Web admin panel (Blade: `AdminPanelController::settings` + `resources\views\admin\settings.blade.php`)

- Same "Photo limits" section in a card; the form already POSTs to
  `POST /settings` (`updateSettings`), just add the inputs.
- The two UIs remain in sync automatically because both write the same JSON
  store through `PlatformSettings`. The class docblock (L9–15) explicitly
 forbids duplicating readers — both go through the helper.

---

## What is *NOT* counted against the quota

| Photo type | Context value | Counted? |
|---|---|---|
| Profile photo / avatar | `profile` | **No** |
| Cover photo | `cover` | **No** |
| Logo (academy / organizer / sponsor / tournament …) | `logo` | **No** |
| Post photos | `post` | **No** *(per stated requirement — flip one WHERE clause if this changes)* |
| Achievements | `achievement` | No (kept unlimited; revisit if abused) |
| Credentials / documents | `credential` / `document` | No |
| **Media gallery uploads** | `gallery` | **Yes** — this is what the admin limit governs |

Changing what's counted after launch = editing the single
`WHERE context = 'gallery'` predicate in 3C/3D. Nothing else moves.

Legacy rows (created before this change) get `context = NULL`; the migration
sets them to `'gallery'` only when they are **not** referenced by any
`photo_media_id` / `cover_media_id` / `logo_media_id` / post image — otherwise
their proper context is inferred.

---

## Edge cases & hardening

1. **Race condition on the counter** — increment/decrement inside the same DB
   transaction as the insert/delete; not per-request-read.
2. **Replacing a profile photo** — the old photo keeps the `profile`
   context; deleting it never releases gallery quota (it never consumed any).
3. **`photos_limit = 0`** — role is hard-blocked from gallery uploads
   (admin intentionally disabling gallery for that role).
4. **Legacy app versions** still send `media_type=video` — server returns a
   clear 422; no silent failures.
5. **Multi-photo pick** — if the shared picker gains multi-select later, the
   server quota check must run per-file inside one request; keep the current
   one-file-per-request contract to stay simple.
6. **Rate limiting** — add a throttle middleware on `POST /media/upload`
   (e.g. 30 uploads/hour/user) as an extra flood-protection layer next to
   compression.
7. **Disk usage regression signal** — log compressed size savings to
   Sentry/captured metrics so the effect is measurable.

---

## Touch-list (files expected to change)

**Flutter (`sportx_app`)**
- `lib\shared\presentation\widgets\media_picker.dart` — remove video branch;
  add `context` param; stricter `imageQuality`.
- `lib\features\athlete\presentation\screens\media_gallery_screen.dart` —
  remove Videos upload; show quota; use `context: 'gallery'`.
- `lib\features\social\presentation\screens\create_post_screen.dart`,
  `lib\features\social\presentation\widgets\create_bottom_sheet.dart`,
  `lib\features\social\presentation\screens\create_screen.dart` — remove
  video tile; `context: 'post'`.
- `lib\features\athlete\presentation\screens\edit_profile_screen.dart`,
  coach / academy / organizer profile & onboarding screens — pass the right
  `context`.
- Flutter **admin** System Settings screen — "Photo limits" section.

**Backend (`sportx-api`)**
- `composer.json` — add `intervention/image` (+ GD driver).
- `app\Services\PhotoCompressor.php` *(new)*, `app\Jobs\CompressPhoto.php` *(new)*.
- `app\Http\Controllers\MediaController.php` — reject video; `context`
  validation; quota check; counter update; dispatch compress job.
- `app\Http\Controllers\PostController.php` — reject `video_url`; accept
  `image_media_ids` (max 5).
- `app\Support\PlatformSettings.php` — new defaults + `writable()` keys +
  `galleryPhotoLimit()` helper.
- `app\Http\Controllers\Admin\AdminSettingsController.php` — numeric
  validation rules for the new keys.
- `resources\views\admin\settings.blade.php` + `AdminPanelController` —
  "Photo limits" card.
- Migrations — `media_items.context`, `*_profiles.gallery_photo_count`,
  backfill + context-tagging migration. Optional
  `app\Console\Commands\MediaCompressExisting.php`.
- `config/sportx.php` — empty `allowed_video_types`; compression defaults
  (`photo_max_dimension`, `photo_jpeg_quality`).

---

## Testing checklist

**PHP (`php artisan test`)** — extend `tests\Feature\MediaUploadTest.php`:
- video upload rejected for every role; photo upload accepted.
- gallery upload increments counter; deletion decrements.
- limit reached → 422 with quota message; profile/cover/upload with
  `context: 'profile'`/`'cover'`/`'post'` succeed **at** limit.
- admin must not be able to set negative limit; `0` blocks uploads.
- compression: upload a large fake image; assert stored file is smaller /
  `compressed_at` set (queue: `Queue::fake()` then `$job->handle()` manually
  in test).
- counter integrity after profile-photo replacement.

**Flutter** — widget tests for gallery quota banner + disabled button;
manual matrix: athlete, coach, academy, organizer, scout, sponsor.

**Manual smoke**
1. Admin sets athlete limit to 5 → athlete uploads 5 photos → 6th blocked
   with clear message; profile & cover photos and post photos still work.
2. Admin sets coach limit to 0 → coache gallery blocked, career video "no
   upload" is not offered anywhere.
3. Confirm no "video" option visible in any role's picker anywhere in the app.
