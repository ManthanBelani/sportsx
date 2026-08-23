# SportX Navigation Messages - Refined Version

This document contains the refined sidebar/navigation messages for all user roles in the SportX app.

## Purpose

The navigation messages were too raw and technical for end users. This document provides user-friendly alternatives that are clearer, more descriptive, and easier to understand at a glance.

---

## Athlete (Main Shell)

| Current | Refined | Notes |
|---------|---------|-------|
| Home | Home | Keep - already clear |
| Search | Explore | More action-oriented, suggests discovery |
| Saved | Bookmarks | More specific about what it contains |
| Activity | Activity Feed | Clarifies it's a feed of updates |
| Profile | My Profile | More personal/ownership feel |

---

## Academy

| Current | Refined | Notes |
|---------|---------|-------|
| Home | Dashboard | Already clear for a dashboard context |
| Trials | My Trials | Indicates ownership, clearer for academy users |
| Enquiries | Messages | Simpler, matches common messaging patterns |
| Profile | Profile | Keep - already clear |

### Suggested Refinements for Academy Dashboard:

| Current | Refined | Notes |
|---------|---------|-------|
| Active Trials | Published Trials | More descriptive of status |
| Total Trials | All Trials | Clearer counting context |
| Drafts | Draft Trials | More specific |
| Quick Actions | Quick Actions | Keep - already clear |
| Post Trial | Create Trial | More action-oriented |
| My Trials | Manage Trials | Better reflects management function |
| Enquiries | Enquiry Inbox | Clarifies location |
| Edit Listing | Edit Profile | Clearer intent |
| My Trials | My Trials | Keep - already clear |
| View All | See All | More concise |

---

## Organizer

| Current | Refined | Notes |
|---------|---------|-------|
| Home | Dashboard | Keep - already clear |
| Events | My Events | Ownership indicator |
| Stats | Performance | More meaningful to organizers |
| Profile | Profile | Keep - already clear |

### Suggested Refinements for Organizer Dashboard:

| Current | Refined | Notes |
|---------|---------|-------|
| Quick Actions | Quick Actions | Keep - already clear |
| Post Trial | Create Trial | More action-oriented |
| Post Tournament | Create Tournament | More action-oriented |
| My Trials | Manage Trials | Better reflects management |
| My Tournaments | Manage Tournaments | Better reflects management |
| Registrations | Registrations | Keep - already clear |
| Results | Results | Keep - already clear |
| Stats | Statistics | Synonym preference |

---

## Coach

| Current | Refined | Notes |
|---------|---------|-------|
| Home | Dashboard | Keep - already clear |
| Schedule | My Schedule | Ownership indicator |
| Enquiries | Enquiries | Keep - already clear |
| Profile | Profile | Keep - already clear |

### Suggested Refinements for Coach Dashboard:

| Current | Refined | Notes |
|---------|---------|-------|
| Quick Actions | Quick Actions | Keep - already clear |
| Edit Profile | Edit Profile | Keep - already clear |
| Show Athletes | Showcase Athletes | More positive framing |
| Manage Enquiries | Enquiry Inbox | Clearer location |
| Add Credential | Add Credential | Keep - already clear |
| Facilities | Facilities | Keep - already clear |
| Schedule | My Schedule | Keep - already clear |

---

## Sponsor

| Current | Refined | Notes |
|---------|---------|-------|
| Home | Dashboard | Keep - already clear |
| Listings | Sponsorships | More specific to sponsor role |
| Inbox | Applications | More descriptive of content |
| Profile | Profile | Keep - already clear |

### Suggested Refinements for Sponsor Dashboard:

| Current | Refined | Notes |
|---------|---------|-------|
| Quick Actions | Quick Actions | Keep - already clear |
| Post Sponsorship | Create Sponsorship | More action-oriented |
| My Sponsorships | My Listings | Keeps consistency with Listings tab |
| Applications | Applications | Keep - already clear |
| Discover Athletes | Find Athletes | More actionable |
| Shortlist | Shortlisted | Clearer it's a list of saved items |
| Stats | Statistics | More formal |

---

## Implementation Guide

To implement these changes, update the `NavigationDestination` labels in each dashboard screen:

### Academy Dashboard
```dart
NavigationDestination(
  icon: Icon(LucideIcons.home),
  selectedIcon: Icon(LucideIcons.home, color: AppColors.primary),
  label: 'Dashboard',  // Changed from 'Home'
),
NavigationDestination(
  icon: Icon(LucideIcons.clipboardList),
  selectedIcon: Icon(LucideIcons.clipboardList, color: AppColors.primary),
  label: 'My Trials',  // Changed from 'Trials'
),
NavigationDestination(
  icon: Icon(LucideIcons.messageCircle),
  selectedIcon: Icon(LucideIcons.messageCircle, color: AppColors.primary),
  label: 'Messages',  // Changed from 'Enquiries'
),
```

### Organizer Dashboard
```dart
NavigationDestination(
  icon: Icon(LucideIcons.calendar),
  selectedIcon: Icon(LucideIcons.calendar, color: AppColors.primary),
  label: 'My Events',  // Changed from 'Events'
),
NavigationDestination(
  icon: Icon(LucideIcons.barChart2),
  selectedIcon: Icon(LucideIcons.barChart2, color: AppColors.primary),
  label: 'Performance',  // Changed from 'Stats'
),
```

### Coach Dashboard
```dart
NavigationDestination(
  icon: Icon(LucideIcons.calendar),
  selectedIcon: Icon(LucideIcons.calendar, color: AppColors.primary),
  label: 'My Schedule',  // Changed from 'Schedule'
),
```

### Sponsor Dashboard
```dart
NavigationDestination(
  icon: Icon(LucideIcons.clipboardList),
  selectedIcon: Icon(LucideIcons.clipboardList, color: AppColors.primary),
  label: 'Sponsorships',  // Changed from 'Listings'
),
NavigationDestination(
  icon: Icon(LucideIcons.inbox),
  selectedIcon: Icon(LucideIcons.inbox, color: AppColors.primary),
  label: 'Applications',  // Changed from 'Inbox'
),
```

### Main Shell (Athlete)
```dart
_buildNavItem(context, role, 1, Icons.search_outlined, Icons.search, 'Explore'),  // Changed from 'Search'
_buildNavItem(context, role, 2, Icons.bookmark_outline, Icons.bookmark, 'Bookmarks'),  // Changed from 'Saved'
_buildNavItem(context, role, 3, Icons.list_alt_outlined, Icons.list_alt, 'Activity Feed'),  // Changed from 'Activity'
_buildNavItem(context, role, 4, Icons.person_outline, Icons.person, 'My Profile'),  // Changed from 'Profile'
```

---

## Quick Summary of Recommended Changes

| Role | Tab | Current | Recommended |
|------|-----|---------|-------------|
| Athlete | 2nd | Search | Explore |
| Athlete | 3rd | Saved | Bookmarks |
| Athlete | 4th | Activity | Activity Feed |
| Athlete | 5th | Profile | My Profile |
| Academy | 2nd | Home | Dashboard |
| Academy | 3rd | Trials | My Trials |
| Academy | 4th | Enquiries | Messages |
| Organizer | 2nd | Events | My Events |
| Organizer | 3rd | Stats | Performance |
| Coach | 2nd | Schedule | My Schedule |
| Sponsor | 2nd | Listings | Sponsorships |
| Sponsor | 3rd | Inbox | Applications |

---

## Files to Update

1. `sportx_app/lib/core/router.dart` - MainShell navigation labels
2. `sportx_app/lib/features/academy/presentation/screens/academy_dashboard_screen.dart` - Academy navigation
3. `sportx_app/lib/features/organizer/presentation/screens/organizer_dashboard_screen.dart` - Organizer navigation
4. `sportx_app/lib/features/coach/presentation/screens/coach_dashboard_screen.dart` - Coach navigation
5. `sportx_app/lib/features/sponsor/presentation/screens/sponsor_dashboard_screen.dart` - Sponsor navigation
