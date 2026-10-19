# Athlete Side - Complete Fix Plan

## Overview
This document outlines a structured plan to fix all identified issues in the athlete side of the SportX app, making it production-ready.

---

## 1. Leaderboard Algorithm Design & UI

### Current State
- `LeaderboardStrip` widget exists in `sportx_cards.dart` (line 606-689)
- `LeaderboardScreen` at `/leaderboard` route (talent_scout feature)
- Admin config at `/admin/leaderboard-config`
- No athlete-specific leaderboard implementation

### Required Changes

#### 1.1 Backend Algorithm Design
```dart
// New file: lib/features/athlete/presentation/providers/leaderboard_provider.dart

enum LeaderboardPeriod { weekly, monthly, season, allTime }
enum LeaderboardCategory { xp, matches, wins, achievements, connections }

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final String avatarUrl;
  final int score;
  final String sport;
  final String level;
  final bool isCurrentUser;
}

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, ({
  LeaderboardPeriod period,
  LeaderboardCategory category,
  String? sportId,
})>((ref, params) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/me/leaderboard', queryParameters: {
    'period': params.period.name,
    'category': params.category.name,
    if (params.sportId != null) 'sport_id': params.sportId,
  });
  return (resp.data['data'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
});
```

#### 1.2 UI Components
- **AthleteLeaderboardScreen** - Full screen with period/category filters
- **LeaderboardWidget** - Reusable widget for home/dashboard embedding
- **PodiumView** - Top 3 visual with medals (already exists in `LeaderboardStrip`)
- **MyRankCard** - Shows current user's rank with percentile

#### 1.3 Integration Points
- Add to athlete home screen (`HomeScreen`)
- Add to athlete profile (`ProfileScreen`)
- Add to "More" menu via `roleConfig.dart`

---

## 2. Test Data in Feed & UI Refinement

### Current State
- `CommunityPostCard` in `community_feed.dart` - good base component
- `postsFeedProvider` fetches from `/posts` endpoint
- No test/mock data for development

### Required Changes

#### 2.1 Test Data Provider
```dart
// New file: lib/features/social/presentation/providers/test_data_provider.dart

final testPostsProvider = Provider<List<SocialPost>>((ref) {
  return [
    SocialPost(
      id: 'test_1',
      authorName: 'Rohit Sharma',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=rohit',
      body: 'Just completed my first marathon! 🏃‍♂️ The training paid off. Thanks to my coach @coach_patel for the guidance.',
      imageUrl: 'https://picsum.photos/seed/marathon/800/450',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      likesCount: 47,
      commentsCount: 12,
      liked: false,
    ),
    // ... more test posts
  ];
});
```

#### 2.2 UI Refinements for CommunityPostCard
- Add **repost/share** functionality
- Add **save/bookmark** with visual feedback
- Improve image loading with **cached_network_image**
- Add **hashtag/mention** tap handling
- Implement **infinite scroll** pagination
- Add **pull-to-refresh**
- Skeleton loading states (already have `Skeleton` widget)

#### 2.3 Feed Algorithm
```dart
// Enhance postsFeedProvider with:
- Pagination (cursor-based)
- Filter by: Following, For You, Trending
- Time-based sorting
- Content type filters (text, image, video, poll)
```

---

## 3. Connect Card Overflow Fix (PersonRowCard)

### Issue
`PersonRowCard` in `home_kit.dart` (line 1098) has overflow when:
- Name is long
- Role text is long
- City name is long
- CTA button label is long

### Root Cause Analysis
The `Row` with `Expanded` child doesn't constrain the CTA button (`CompactPrimaryButton`) which has fixed padding but no max width constraint.

### Fix
```dart
// In PersonRowCard build method - replace the Row with:

child: Row(children: [
  _Avatar(initial: name.isNotEmpty ? name[0].toUpperCase() : 'A', url: photoUrl, size: 45),
  const SizedBox(width: 9),
  Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Flexible(
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
        const SizedBox(width: 4),
        const _VerifiedDot(),
      ]),
      const SizedBox(height: 3),
      Text(role,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
      const SizedBox(height: 3),
      RatingLine(rating: rating, city: city),
    ]),
  ),
  const SizedBox(width: 8),
  // FIX: Wrap CTA in ConstrainedBox or Flexible
  Flexible(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 80),
      child: CompactPrimaryButton(label: ctaLabel, onTap: onTap),
    ),
  ),
]),
```

### Additional Improvements
- Make `CompactPrimaryButton` responsive with `FittedBox` for long labels
- Add `maxWidth` parameter to `CompactPrimaryButton`
- Consider `IntrinsicWidth` for dynamic sizing

---

## 4. Create Screen as Bottom Sheet/Popup

### Current State
- `CreateScreen` at `/create` route - full screen
- FAB in `MainShell` navigates to `/create`
- `CreatePostScreen` at `/create-post` - full screen with bottom nav bar

### Required Changes

#### 4.1 Convert CreateScreen to Modal Bottom Sheet
```dart
// New file: lib/features/social/presentation/widgets/create_bottom_sheet.dart

class CreateBottomSheet extends ConsumerWidget {
  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateBottomSheetContent(),
    );
  }
}

class _CreateBottomSheetContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref.watch(roleConfigProvider).createTiles
        .where((t) => t.priority != CreatePriority.p2)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            // Grid
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 84,
                ),
                itemCount: tiles.length,
                itemBuilder: (_, i) => _CreateTileCard(tile: tiles[i], index: i),
              ),
            ),
            // Quick Post Options (optional - can be separate sheet)
            _QuickPostSection(),
          ],
        ),
      ),
    );
  }
}
```

#### 4.2 Convert CreatePostScreen to Bottom Sheet
```dart
// Modify CreatePostScreen to support both full-screen and bottom sheet modes
class CreatePostScreen extends ConsumerStatefulWidget {
  final bool isBottomSheet;
  const CreatePostScreen({super.key, this.isBottomSheet = false});
  // ... rest of implementation
}
```

#### 4.3 Update FAB in MainShell
```dart
// In MainShell._buildFab
_buildFab(context, () => CreateBottomSheet.show(context, ref)),
```

---

## 5. Community Page Overall Refinement

### Current State
- `CommunityScreen` with 3 tabs: Network, Groups, Events
- Network: Search, filter chips, suggested athletes, academy card
- Groups: Static list
- Events: Trials + tournaments

### Required Changes

#### 5.1 Network Tab Improvements
- **Add infinite scroll** for suggested athletes
- **Implement "My Network"** - show connections with online status
- **Add "Follow/Connect" actions** with optimistic UI
- **Filter by sport, location, level** - connect to search filters
- **Skeleton loading** for all sections

#### 5.2 Groups Tab - Make Dynamic
```dart
// New provider: lib/features/social/presentation/providers/groups_provider.dart
final groupsProvider = FutureProvider<List<Group>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/groups', queryParameters: {'type': 'popular'});
  return (resp.data['data'] as List).map(Group.fromJson).toList();
});
```
- Replace static list with API-driven groups
- Add "Create Group" action for eligible roles
- Show member count, activity indicator

#### 5.3 Events Tab Enhancements
- **Unified event model** (trials, tournaments, programs)
- **Filter by date range, sport, location**
- **Calendar view toggle** (list ↔ calendar)
- **Register/RSVP** actions directly from card
- **Map view** integration

#### 5.4 New "Feed" Tab (or merge with Network)
- Move `CommunityPostCard` feed here
- Infinite scroll with pagination
- Pull-to-refresh
- Create post FAB (or use main FAB)

---

## 6. Chat Logic Fixes

### Current State
- `chat_provider.dart` - basic conversation/message models
- `ChatListScreen` - list with search, tabs (Chats/Requests)
- `ChatScreen` - individual chat (need to check)
- Connection gating for scout↔athlete (403 CONNECTION_REQUIRED)

### Issues to Fix

#### 6.1 Message Ordering
```dart
// In conversationDetailProvider - messages come in reverse order (newest first)
// Fix: Reverse the list for display
final messages = (body['messages'] as List? ?? []).cast<Map<String, dynamic>>();
return messages.map(ChatMessage.fromJson).toList().reversed.toList();
```

#### 6.2 Real-time Updates
- **Add WebSocket/FCM integration** for live messages
- **Optimistic send** - show message immediately, sync on success
- **Read receipts** - mark as read when screen visible
- **Typing indicators**

#### 6.3 Connection Request Flow
- Fix "Requests" tab - currently shows static UI
- Connect to `/me/connection-requests` endpoint
- Add accept/decline actions with optimistic updates

#### 6.4 Media Support
- Image/video sending
- File attachments
- Voice messages

#### 6.5 Pagination
- Load older messages on scroll up
- Initial load: last 50 messages

---

## 7. Athlete Onboarding & Mandatory Fields for All Roles

### Current State
- Athlete onboarding: 2 screens (`OnboardingSportAgeScreen`, `OnboardingSkillLocationScreen`)
- `OnboardingProvider` collects: sports, age_group, skill_level, city, full_name, dob, gender
- Other roles have their own onboarding screens

### Required Changes

#### 7.1 Define Mandatory Fields per Role
```dart
// New file: lib/core/role_requirements.dart

enum MandatoryField {
  fullName,
  dateOfBirth,
  gender,
  phone,
  sports,
  skillLevel,
  city,
  bio,
  profilePhoto,
  coverPhoto,
  verificationDoc,
  // Role-specific
  coachingLicense,      // coach
  academyLicense,       // academy
  organizationName,     // organizer
  scoutingLicense,      // scout
  companyName,          // sponsor
}

const Map<SportXRole, List<MandatoryField>> mandatoryFields = {
  SportXRole.athlete: [
    MandatoryField.fullName,
    MandatoryField.dateOfBirth,
    MandatoryField.gender,
    MandatoryField.sports,
    MandatoryField.skillLevel,
    MandatoryField.city,
    MandatoryField.profilePhoto,
  ],
  SportXRole.coach: [
    MandatoryField.fullName,
    MandatoryField.dateOfBirth,
    MandatoryField.gender,
    MandatoryField.phone,
    MandatoryField.sports,
    MandatoryField.coachingLicense,
    MandatoryField.city,
    MandatoryField.profilePhoto,
    MandatoryField.bio,
  ],
  SportXRole.academy: [
    MandatoryField.organizationName,
    MandatoryField.academyLicense,
    MandatoryField.city,
    MandatoryField.sports,
    MandatoryField.coverPhoto,
    MandatoryField.profilePhoto,
    MandatoryField.bio,
  ],
  // ... other roles
};
```

#### 7.2 Progressive Onboarding Flow
- **Step 1**: Core identity (name, DOB, gender, phone)
- **Step 2**: Role-specific (sports, level, license, etc.)
- **Step 3**: Media (profile photo, cover photo)
- **Step 4**: Verification (documents, ID)
- **Step 5**: Preferences (notifications, privacy)

#### 7.3 Validation & Completion Tracking
- Use `ProfileCompletionScreen` as checkpoint
- Block feature access until mandatory fields complete
- Show progress in onboarding flow

---

## 8. API Call Timing & State Management Issues

### Current Issues Identified

#### 8.1 Duplicate/Unnecessary API Calls
- `ref.invalidate()` called multiple times in succession
- Providers refetch on every navigation
- No request deduplication

#### 8.2 Loading State Management
- Multiple providers show independent loading states
- No global loading coordinator
- Flashing skeletons on cached data

#### 8.3 Cache Strategy
```dart
// Current: FutureProvider (no cache control)
// Better: Use AsyncNotifier with explicit cache

// Example improved pattern:
class PostsNotifier extends AsyncNotifier<List<SocialPost>> {
  @override
  Future<List<SocialPost>> build() => _fetchPosts();
  
  Future<List<SocialPost>> _fetchPosts({bool forceRefresh = false}) async {
    if (!forceRefresh && state.hasValue) return state.value!;
    final resp = await ref.read(dioProvider).get('/posts');
    return (resp.data['data'] as List).map(SocialPost.fromJson).toList();
  }
  
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPosts(forceRefresh: true));
  }
}
```

#### 8.4 Request Deduplication
```dart
// Add dio interceptor for request deduplication
class DeduplicationInterceptor extends Interceptor {
  final Map<String, Future<Response>> _pending = {};
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET') {
      final key = '${options.path}?${options.queryParameters}';
      if (_pending.containsKey(key)) {
        handler.resolve(await _pending[key]!);
        return;
      }
      final future = _pending[key] = _execute(options);
      handler.resolve(await future);
      _pending.remove(key);
    } else {
      handler.next(options);
    }
  }
}
```

#### 8.5 Optimistic Updates
- Like/unlike posts
- Follow/unfollow users
- Send messages
- Mark notifications read

---

## 9. Notifications & Google Sign-In Fixes

### 9.1 Notifications Issues

#### Current State
- `PushNotificationService` - FCM + local notifications
- `NotificationsProvider` - in-app bell with tabs
- Device token registration in `AuthNotifier._registerFcmToken()`

#### Issues
1. **Token registration race condition** - Called multiple times
2. **Permission handling** - iOS/Android 13+ not properly handled
3. **Deep linking** - `action_url` parsing inconsistent
4. **Background handler** - Empty, needs implementation
5. **Channel mismatch** - Android channels must match backend

#### Fixes
```dart
// 1. Single token registration with guard
class PushNotificationService {
  static bool _tokenRegistered = false;
  
  static Future<void> registerTokenIfNeeded(WidgetRef ref) async {
    if (_tokenRegistered) return;
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) return;
    
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(dioProvider).post('/me/device-tokens', data: {
          'token': token,
          'device_type': Platform.isIOS ? 'ios' : 'android',
        });
        _tokenRegistered = true;
      }
    } catch (_) {}
  }
}

// 2. Proper permission flow
static Future<void> requestPermissions() async {
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
    criticalAlert: false,
  );
  
  if (Platform.isAndroid) {
    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }
}

// 3. Deep link parsing - normalize in one place
static String? parseActionUrl(RemoteMessage msg) {
  return (msg.data['action_url'] ?? 
          msg.data['actionUrl'] ?? 
          msg.data['deep_link'] ?? 
          msg.data['deeplink'])?.toString();
}

// 4. Background handler - store for next app open
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Store notification for in-app display on next launch
  final prefs = await SharedPreferences.getInstance();
  final pending = prefs.getStringList('pending_notifications') ?? [];
  pending.add(jsonEncode(message.data));
  await prefs.setStringList('pending_notifications', pending);
}
```

### 9.2 Google Sign-In Issues

#### Current State
- `GoogleSignInButton` widget in `google_sign_in_button.dart`
- Uses `google_sign_in` package with `serverClientId`
- Passes ID token to backend `/auth/google`

#### Issues
1. **Server client ID not configured** - `String.fromEnvironment` with empty default
2. **Role handling** - Role passed on signup but not on login
3. **Error handling** - Generic error messages
4. **Web support** - Not configured for Flutter web

#### Fixes
```dart
// 1. Configure via --dart-define
// In CI/CD or local run: flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your_web_client_id

// 2. Improve GoogleSignInButton
class GoogleSignInButton extends ConsumerStatefulWidget {
  final String? role;
  final bool isSignUp;
  const GoogleSignInButton({super.key, this.role, this.isSignUp = false});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  // ... existing code ...
  
  Future<void> _signIn() async {
    // ... existing code ...
    
    // Use role only for signup
    final roleToSend = widget.isSignUp ? widget.role : null;
    await ref.read(authProvider.notifier).signInWithGoogle(
      idToken: idToken, 
      role: roleToSend,
    );
  }
}

// 3. Add web support
// In web/index.html add Google Identity Services script
// Use google_sign_in_web package for web platform

// 4. Better error handling
try {
  // ... sign in ...
} on GoogleSignInException catch (e) {
  switch (e.code) {
    case 'network_error':
      SnackBarUtils.showError(context, 'Network error. Check connection.');
      break;
    case 'canceled':
      // User dismissed - silent
      break;
    default:
      SnackBarUtils.showError(context, 'Google sign-in failed: ${e.message}');
  }
}
```

---

## Implementation Priority & Timeline

### Phase 1: Critical Fixes (Week 1-2)
| Priority | Task | Effort |
|----------|------|--------|
| P0 | Connect card overflow fix | 2h |
| P0 | API call deduplication & caching | 8h |
| P0 | Google Sign-In server client ID config | 2h |
| P0 | Notification token registration guard | 4h |
| P0 | Chat message ordering fix | 2h |

### Phase 2: Core Features (Week 2-3)
| Priority | Task | Effort |
|----------|------|--------|
| P1 | Create bottom sheet (CreateScreen + CreatePostScreen) | 16h |
| P1 | Community page refinement (all 3 tabs) | 24h |
| P1 | Test data for feed + infinite scroll | 8h |
| P1 | Athlete onboarding mandatory fields validation | 12h |

### Phase 3: Enhanced Features (Week 3-4)
| Priority | Task | Effort |
|----------|------|--------|
| P2 | Leaderboard algorithm & UI | 24h |
| P2 | Chat real-time + media support | 24h |
| P2 | Notification deep linking + background handler | 8h |
| P2 | Progressive onboarding for all roles | 24h |

### Phase 4: Polish & Testing (Week 4-5)
| Priority | Task | Effort |
|----------|------|--------|
| P3 | End-to-end testing all flows | 16h |
| P3 | Performance profiling | 8h |
| P3 | Accessibility audit | 8h |
| P3 | Documentation & handoff | 8h |

---

## Technical Debt to Address

1. **Replace `FutureProvider` with `AsyncNotifier`** for all data providers
2. **Add request deduplication interceptor** to Dio
3. **Implement optimistic updates** for all mutations
4. **Add proper error boundaries** with retry logic
5. **Standardize loading/skeleton patterns** across all screens
6. **Add integration tests** for critical user flows

---

## Files to Create/Modify Summary

### New Files
- `lib/features/athlete/presentation/providers/leaderboard_provider.dart`
- `lib/features/social/presentation/providers/test_data_provider.dart`
- `lib/features/social/presentation/providers/groups_provider.dart`
- `lib/features/social/presentation/widgets/create_bottom_sheet.dart`
- `lib/core/role_requirements.dart`
- `lib/core/interceptors/deduplication_interceptor.dart`

### Modified Files
- `lib/shared/presentation/widgets/home_kit.dart` (PersonRowCard fix)
- `lib/features/social/presentation/screens/create_screen.dart` (bottom sheet)
- `lib/features/social/presentation/screens/create_post_screen.dart` (bottom sheet support)
- `lib/features/social/presentation/screens/community_screen.dart` (refinement)
- `lib/features/chat/presentation/providers/chat_provider.dart` (message ordering, real-time)
- `lib/features/chat/presentation/screens/chat_list_screen.dart` (requests tab)
- `lib/features/onboarding/presentation/providers/onboarding_provider.dart` (validation)
- `lib/core/role_config.dart` (mandatory fields per role)
- `lib/core/services/push_notification_service.dart` (token guard, deep link, background)
- `lib/features/auth/presentation/widgets/google_sign_in_button.dart` (web support, errors)
- `lib/core/router.dart` (FAB to bottom sheet)
- `lib/core/utils/api_client.dart` (add interceptor)

---

## Success Criteria

✅ **Leaderboard** - Athlete sees rank, can filter by period/category, top 3 podium visible  
✅ **Feed** - Test data loads, infinite scroll works, images cached, pull-to-refresh works  
✅ **Connect Card** - No overflow on any screen size, long names/roles/cities handled  
✅ **Create** - Opens as bottom sheet from FAB, CreatePostScreen also bottom sheet  
✅ **Community** - All 3 tabs dynamic, groups from API, events filterable, feed integrated  
✅ **Chat** - Messages ordered correctly, real-time updates, connection requests work  
✅ **Onboarding** - All roles have mandatory fields defined, validation prevents incomplete profiles  
✅ **API/State** - No duplicate calls, proper caching, optimistic updates, loading states consistent  
✅ **Notifications** - Tokens registered once, deep links work, background handler stores notifications  
✅ **Google Sign-In** - Works on Android/iOS/Web, proper errors, role handling correct

---

## Next Steps

1. **Review this plan** with the team
2. **Prioritize Phase 1** items for immediate action
3. **Assign ownership** for each task
4. **Set up test environment** with backend endpoints
5. **Begin implementation** starting with connect card overflow (quickest win)