# Notification Task Mapping — SportX India

**Last Updated:** 2026-09-12
**Status:** Fully implemented

---

## Notification Types → App Screen Navigation

| Notification `type` | Icon | Color | Trigger (Backend) | App Action on Tap | Deep Link |
|---------------------|------|-------|-------------------|-------------------|-----------|
| `reminder` | `LucideIcons.clock` | Amber `#fef3c7` | `ReminderService` — T-2d, T-1d | Navigate to trial/tournament/scholarship | `/trial/{id}` etc. |
| `registration` | `LucideIcons.checkCircle` | Blue `#dbeafe` | `RegistrationController::verifyTrial`, `rejectTrial`, `updateTournamentPayment` | Navigate to registration detail | `/trial-registration/{id}` `/tournament-registration/{id}` |
| `reply` | `LucideIcons.messageCircle` | Green `#d1fae5` | `EnquiryController::reply` | Navigate to enquiry detail | `/enquiry-detail?id={id}` |
| `shortlist` | `LucideIcons.trophy` | Purple `#ede9fe` | `ScoutShortlistController::store`, `SponsorEngagementController::addToShortlist` | Navigate to shortlist | `/scout-shortlist` or `/shortlist` |
| `application` | `LucideIcons.trophy` | Purple `#ede9fe` | `SponsorEngagementController::updateApplication` | Navigate to my applications | `/my-applications` |
| `warning` | `LucideIcons.bell` | Grey surface | `NotifyOwnerOnListingRemoved`, `NotifyOwnerOnListingWarned` listeners | No navigation (info only) | — |
| `info` / `success` / `warning` | `LucideIcons.bell` | Grey surface | Admin broadcast | No navigation | — |
| *(default)* | `LucideIcons.bell` | Grey surface | Unknown type | No navigation | — |

---

## Implementation Summary (as of 2026-09-12)

### Backend Changes

| File | Change |
|------|--------|
| `app/Services/NotificationService.php` | New — `create()` helper that creates notification + fires `NotificationCreated` event |
| `app/Http/Controllers/EnquiryController.php` | `reply()` now notifies athlete via `NotificationService::createStatic()` with `action_url: "/enquiry/{id}"` |
| `app/Http/Controllers/RegistrationController.php` | `verifyTrial()` / `rejectTrial()` / `updateTournamentPayment()` notify athlete via `NotificationService::createStatic()` |
| `app/Http/Controllers/ScoutShortlistController.php` | `store()` now notifies athlete via `NotificationService::createStatic()` with `action_url: "/scout-shortlist"` |
| `app/Http/Controllers/SponsorEngagementController.php` | `updateApplication()` notifies athlete; `addToShortlist()` notifies athlete via `NotificationService::createStatic()` |
| `app/Events/ListingRemoved.php` | New — fired by `AdminModerationController::remove()` |
| `app/Events/ListingWarned.php` | New — fired by `AdminModerationController::warn()` |
| `app/Listeners/NotifyOwnerOnListingRemoved.php` | New — resolves owner user from listing model, creates notification |
| `app/Listeners/NotifyOwnerOnListingWarned.php` | New — resolves owner user from listing model, creates notification |
| `app/Providers/AppServiceProvider.php` | Registered `ListingRemoved → NotifyOwnerOnListingRemoved` and `ListingWarned → NotifyOwnerOnListingWarned` |

### App Changes

| File | Change |
|------|--------|
| `notifications_provider.dart` | Added `actionUrl` field to `NotificationItem`, preserved in `markAsRead`/`markAllRead` |
| `notifications_screen.dart` | Added `_navigateTo()` helper, tap now parses `actionUrl` and navigates via GoRouter |

---

## Notification Flow

```
User Action
    ↓
Controller/Service
    ↓
NotificationService::create() / createStatic()
    ↓
Notification::create()  →  Database
    ↓
NotificationCreated event  →  SendPushNotificationListener
    ↓                               ↓
ListingRemoved/Warned events    Check notification_prefs['push']
    ↓                               ↓
NotifyOwnerOnListing...        SendPushNotification job (queued)
    ↓                               ↓
Notification::create()         FCM → device push
```

---

## Deep Link Routes

| action_url Pattern | GoRouter Path | Screen |
|--------------------|---------------|--------|
| `/enquiry/{id}` | `/enquiry-detail?id={id}` | EnquiryDetailScreen |
| `/registrations/trials/{id}` | `/trial-registration/{id}` | TrialRegistrationScreen |
| `/registrations/tournaments/{id}` | `/tournament-registration/{id}` | TournamentRegistrationScreen |
| `/scout-shortlist` | `/scout-shortlist` | ScoutShortlistScreen |
| `/shortlist` | `/shortlist` | SponsorShortlistScreen |
| `/my-applications` | `/my-applications` | MyApplicationsScreen |
| `/trial/{id}` | `/trial/{id}` | TrialDetailScreen |
| `/tournament/{id}` | `/tournament/{id}` | TournamentDetailScreen |
| `/academy/{id}` | `/academy/{id}` | AcademyDetailScreen |
| `/coach/{id}` | `/coach-profile/{id}` | CoachProfileDetailScreen |

---

## Notification Preferences

| Pref Key | Default | Effect |
|----------|---------|--------|
| `notification_prefs['push']` | `true` | Controls whether FCM push is sent (checked in `SendPushNotificationListener`) |
| `notification_prefs['email']` | `false` | Reserved |
| `notification_prefs['sms']` | `true` | Reserved |
| `notification_prefs['deadline_reminders']` | `true` | Controls reminder subscription |
| `notification_prefs['location']` | `false` | Controls location-based features |

---

## Setup Requirements (Manual)

1. **FCM Service Account** — Download from Firebase Console → Project Settings → Service Accounts → Generate new private key. Set `FCM_CREDENTIALS_PATH` in `.env` to the JSON file path.
2. **Scheduler** — Add to `routes/console.php`:
   ```php
   $schedule->job(new \App\Jobs\SendDueRemindersJob)->everyFifteenMinutes();
   ```
3. **Queue Worker** — Run `php artisan queue:work` or use Horizon for production.
4. **Run `composer update google/auth`** in backend to install the FCM OAuth library.
