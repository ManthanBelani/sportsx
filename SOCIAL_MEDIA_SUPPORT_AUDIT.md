# SportX — Social-Media Support Audit: Feed, Likes, Recommendations & Graph

**Date:** 2026-10-14
**Question:** "Is the app + API built in a way that supports social-media-like features — feed, likes, recommendations, etc.?"
**Short answer:** **Yes for LinkedIn-style core, No for Instagram/TikTok-style discovery.**
The backend + app ship a **working 1st-generation professional network**: chronological feed, posts with media, likes, threaded comments, hashtags (stored), follows + two-way connections, chat-on-connect, save/share on profiles, notifications center with a Mentions category. What is **not** built is the algorithmic layer: no ranked/personalized feed, no @mention extraction + notify, no hashtag search/trending, no rule-based recommendations, no share-resolver deep links for posts, no stories/reels/groups/live (all explicitly P1.19/P2-parked).
**Scope:** `sportx-api/app/Http/Controllers/PostController.php`, `FollowController.php`, `ConnectionController.php`, `SearchController.php`, `HomeController.php`, `SavedItemController.php`, `NotificationService.php`, `Models/Post.php` vs `sportx_app/lib/features/social/**` (`posts_provider.dart`, `create_post_screen.dart`, `post_detail_screen.dart`, `create_sheet.dart`), `connections/**`, `home/home_screen.dart`, `core/router.dart`, `saved/saved_screen.dart`. Plan refs: `PHASE_WISE_IMPLEMENTATION_PLAN.md` Phase 6 + Phase 11 P1.7/P1.8/P1.16/P1.17/P1.18.

## 0. Architecture position (read this first)

| Question | Answer |
|---|---|
| What social model did SportX choose? | **LinkedIn for sports, not Instagram.** Graph = one-way `follows` (fan) + two-way `connections` (mutual, unlocks chat) + scout-namespaced connections. Feed = network + public posts. No cold DMs, minors guardian-gated, blocks hide both ways. |
| Is feed algorithmic? | **No. Chronological `latest()` + visibility gate.** No score, no For-You ranking, no collaborative filtering. `GET /feed` and `GET /posts` are the same handler (`api.php:468-469` → `PostController@index`). |
| Are recommendations real? | **No.** Home "Recommended Athletes" rail renders `academies.take(3) + coaches.take(2)` (`home_screen.dart:216-229`) with a `Follow` button that only navigates to detail. No `GET /suggest|recommend` endpoint exists. Rule-based recs are P1.7 (not built). |
| Push/email on social events? | **Wired for connections, dead for likes/comments/mentions.** `ConnectionController` emits `status_update` via `NotificationService` (request/accept/mutual → push+in-app). `PostController` emits **zero** notifications — like/comment create no row, so the `mentions` tab stays empty despite the category mapper existing. |

---

## 1. Feature matrix — what exists, what is partial, what is missing

Status: `✅ Done` · `⚠️ Partial (works, gaps noted)` · `❌ Missing` · `⏭️ Parked P1/P2 by plan (correct to be missing in MVP)`

| # | Social feature | Backend | App | Status | Evidence |
|---|---|---|---|---|---|
| 1 | Chronological feed (own + accepted-connections + public, blocked excluded, followers-visibility) | `PostController@index` — block-list merge, accepted-`Connection` ids, `visibility public\|followers`, `withCount(likes,comments)`, `paginate(15)` | `postsFeedProvider GET /posts` → `SocialPost` list | **✅ Done (v1)** | `PostController.php:14-47`; `posts_provider.dart:44-48`; `HomeController::feedPreview` latest-3 |
| 2 | Feed tabs (For You / Following / Athletes / Coaches / Academies / Events per plan §6) | Single unfiltered index; no `?tab=` / `?audience=` param | No tab UI on any feed; `/community` redirects to `/network` (`router.dart:530`) | **❌ Missing** | Plan Phase 6 lists tabs; controller has none |
| 3 | Create post (text + image/video via `/media/upload`, visibility public/followers) | `POST /posts` — body/image/video, `hashtags[≤10]`, `sport_id`, 422-if-empty | `CreatePostScreen` — caption + gallery/camera pick → `POST /media/upload` → `POST /posts {body,image_url,hashtags}` + `CreateSheet` entry | **✅ Done** | `PostController:61-88`; `create_post_screen.dart:74-114,84-95`; `create_sheet.dart:23` |
| 4 | Edit / delete own post (admin override) | `PATCH/DELETE /posts/{id}` owner-or-admin | `updatePost` / `deletePost` helpers exist; no edit UI screen wired | **⚠️ Partial** | `PostController:90-127`; `posts_provider.dart:78-98` |
| 5 | Like / unlike with counts | `POST /posts/{id}/like` toggle + `DELETE …/like` explicit; returns `{liked, likes_count}` | `togglePostLike` (POST) + `unlikePost` (DELETE), invalidate feed+detail; heart shows `likesCount` + red-when-liked | **⚠️ Partial** | `PostController:155-180`; `posts_provider.dart:56-76`; `post_detail_screen.dart:96` |
| 6 | Feed-row `liked` state | `show` adds `likedBy(user)`; **`index` does not** — feed rows never carry `liked:true` | `SocialPost.fromJson` reads `liked` (always false from feed) | **⚠️ Partial — 1-line backend fix** | `PostController:49-59` vs `:34-46`; `posts_provider.dart:39` |
| 7 | Comments + threaded replies + delete perms | `GET/POST /posts/{id}/comments` (paginate 20), `parent_id` threading, `replies` eager on show; delete by comment/post owner or admin | `postCommentsProvider`, `commentOnPost {body}`, `deleteComment`, detail shows `Comments (n)` + input | **✅ Done** | `PostController:129-199`; `posts_provider.dart:100-126`; `post_detail_screen.dart:22-36,105` |
| 8 | Comment replies UI | Backend returns `comments.replies.user` | Detail lists top-level only; no reply-to-reply composer (`parent_id` never sent from app) | **⚠️ Partial** | `posts_provider.dart:118-125` sends `{body}` only |
| 9 | Hashtags (store + display) | `hashtags` JSON array cast, `≤10 × ≤40ch` on store/update | Chip picker from 10 sport names (`Cricket…Wrestling`), sent as array | **⚠️ Partial** | `Post.php:13`; `PostController:63-70`; `create_post_screen.dart:28-39,205-216` |
| 10 | Hashtag extraction / search / trending | No `#tag` parsing from body; `GET /search` has no `posts`/`hashtag` group | No tappable hashtag, no hashtag results page | **❌ Missing (P1.8)** | `SearchController:67-111` groups lack posts |
| 11 | @Mentions (parse + notify + highlight) | Zero: no parsing, no `mention` row creation | Zero UI | **❌ Missing (P1.8)** | `grep mention` hits only `NotificationService::categoryFor` mapper + prefs key |
| 12 | Like/comment → notification | `NotificationService::categoryFor` maps `like|comment|mention|message → mentions`, prefs key exists — **but `PostController` never calls `NotificationService`** | `notifications_screen` has Mentions tab that will stay empty for social events | **❌ Missing (emit only)** | `PostController.php` has 0 `NotificationService` refs; `NotificationController:34-36` tab filter ready |
| 13 | Follow (one-way, any profile type) | `POST/DELETE /follow/{type}/{id}` resolves `user|athlete|coach|academy|organizer|scout` → user id; self-follow 422; blocked 403 `BLOCKED` | `followProfile/unfollowProfile`, `followingProvider/followersProvider` | **✅ Done** | `FollowController:32-63`; `follow_block_provider.dart:37-50` |
| 14 | Connections (two-way, request/accept/decline, mutual-auto-accept, chat unlock + notify) | Full: 409-duplicate, block gate, accept→`ensurePrivateConversation` + `status_update` notif; `status/count/requests` helpers | `athleteDirectoryProvider.connect`, `connectionStatusProvider`, Network/MyConnections/Requests screens, scout-namespaced inbox | **✅ Done** | `ConnectionController:13-230`; `network_screen.dart`, `athlete_directory_screen.dart` |
| 15 | Suggested people / "who to follow" | No suggest query | `network_screen.dart:248` shows `No suggestions right now` when directory empty; no ranking | **❌ Missing (P1.8 suggest query)** | — |
| 16 | Rule-based recommendations (sport/age/location) | No endpoint | Home rail is academies+coaches, mislabeled "Recommended Athletes"; `Follow` button navigates, does not follow | **❌ Missing (P1.7) + label bug** | `home_screen.dart:158-162,184-306,288-294` |
| 17 | Save post | `SavedItemController` `item_type` includes `post` (+enrich closure); `GET/POST/DELETE /me/saved` | `SavedScreen` Posts tab + `post-detail/{id}` deep-link resolver | **✅ Done** | `SavedItemController:38,158`; `saved_screen.dart:92` |
| 18 | Share post / deep link | No `GET /share/{type}/{slug}` resolver (P1.16) | `share_plus` used on athlete/coach/profile screens only — **not on post detail** | **❌ Missing (P1.16)** | `grep Share.share` → profile/coach/view-profile only |
| 19 | Chat / DMs | `conversations+participants+messages` (text P0, `media_url` P1-ready), accepted-connection OR enquiry-thread only, 90-day purge | `chat_provider` + list/thread screens + `CONNECTION_REQUIRED` 403 gate | **✅ Done (by design: no cold DMs)** | Phase 6 audit; `chat_provider.dart:92-104` |
| 20 | Chat media / attachments | `messages.media_url` column exists | No picker/send-attachment UI | **⏭️ P1.8 — correctly deferred** | — |
| 21 | Notifications center (All/People/Opps/Events/Mentions, unread, read-all, delete) | `GET /me/notifications?tab=` + `meta.unread_count` + read/read-all/delete + prefs with hard-override lock | Tabs + grouping + prefs screen with locked account/registration rows | **✅ Done (shell); content gap = #12** | `NotificationController`; `notification_preferences_screen.dart:58-73` |
| 22 | Digest ("3 new updates today" vs per-event push, AS-71) | Not built | Grouping only | **⏭️ P1.17 — correctly deferred** | Plan Phase 11 |
| 23 | Per-sport FCM topics (`sportx_sport_{id}`) | `FCMService::sendToTopic` exists; subscription UX not built | No topic picker | **⏭️ P1.18 — correctly deferred** | `FCMService.php:157` |
| 24 | Stories / reels / live / groups / polls / boosted | None (no tables, no routes) | None | **⏭️ P2-parked — correctly absent** | Plan Phase 11 Parked |
| 25 | Safety: blocks + reports on posts | `blocks` (hide both ways, kill follow/chat) + `listing_reports` morph includes `post` → admin queue | Report sheet + block actions + Safety Centre entry | **✅ Done** | `BlockController`; `ReportController`; Phase 6 audit |

---

## 2. What works end-to-end TODAY (demo script)

1. **Post → like → comment:** Create Post (caption + photo + `#Cricket`) → appears in `GET /posts` (author + counts) → open `/post-detail/:id` → heart toggles (`POST /posts/:id/like` → `{liked, likes_count}`) → comment (`POST …/comments {body}`) → reply row appears; owner/admin can `DELETE /comments/:id`. ✅
2. **Follow + connect → chat:** directory → `POST /follow/athlete/:id` (fan) and/or `POST /me/connections/request {user_id}` → incoming `/connection-requests` → accept → `status_update` notification (in-app + push where configured) + private conversation seeded with "Say hi!" → `POST /conversations/:id/messages` works; cold DM without connection → `403 CONNECTION_REQUIRED`. ✅
3. **Save + notify shell:** save post from detail → Saved → Posts tab → tap → back to detail. Connection request/accept produces notification rows in All/People tabs with unread badge. ✅
4. **Guardrails:** blocked user's posts vanish from feed both directions; `followers`-only posts visible only to accepted connections + self; public listings readable logged-out, acting requires login. ✅

## 3. What does NOT work (honest gap list vs "social media like")

| # | Gap | User-visible symptom | Root cause (file) | Fix size |
|---|---|---|---|---|
| G-1 | No personalized/ranked feed; no Following-only toggle | Every user sees same `latest()` order; power users drown | `PostController@index` single path, no `?tab=` | M — new `filter=following|sport|hashtag` + tabs UI (P1) |
| G-2 | Liking from feed shows wrong state on revisit | Heart unlit even after liking (until detail opened) | `index` omits `likedBy` (N+1 concern) — `show` has it | **S — map `liked` in index via single `whereIn` query** |
| G-3 | No notification on like/comment/reply | Authors never learn their post got engagement; Mentions tab empty | `PostController::toggleLike/comment` never call `NotificationService::create` | **S — 2 emit calls (respect prefs + self-like skip + block check)** |
| G-4 | No @mentions at all | Typing `@name` is plain text | No extractor, no `mention` notif type emission, no highlight widget | M — extractor + autocomplete (`GET /suggest/users?q=`) + notify (P1.8) |
| G-5 | Hashtags are labels, not links | Tapping `#Cricket` does nothing; searching `#Cricket` finds nothing | Stored array, no index/query path, no `posts` group in `GET /search` | M — `whereJsonContains` filter + search group + tappable chip → results (P1.8) |
| G-6 | No recommendations engine | "Recommended Athletes" shows academies/coaches; Follow button just navigates | No `GET /recommendations|/suggest` (sport/age/location rules) | M — P1.7 rule-based endpoint + rail fix + real Follow call |
| G-7 | Cannot share a post outside the app | No link to send on WhatsApp; shared profile links only | No `GET /share/post/:id` resolver + `FRONTEND_URL` unset | S — resolver + `Share.share(url)` on detail (P1.16) |
| G-8 | No reply-to-reply composer | Deep threads read-only beyond L1 | App never sends `parent_id` though API supports it | S — reply affordance passing `parent_id` |
| G-9 | No post edit UI | Must delete + repost to fix typo | `updatePost` helper exists, screen lacks edit entry | S — overflow menu → edit sheet |
| G-10 | No trending / discover-hashtags | No way to find what's hot | `GET /meta/trending-searches` is static fallback list | M — aggregate `hashtags` + search-log trending (P1.8/P9 polish) |
| G-11 | Community tab is an alias, not a feed | Tapping Community lands on Network (people), not posts | `router.dart:530 /community → /network`; no dedicated feed screen in shell | S/M — decide IA: feed-in-Community vs feed-in-Home vs separate tab (UX call) |

S = <½ day · M = 1–3 days (incl. tests).

---

## 4. Is the DATA MODEL social-ready? (yes — with 2 indexes to add)

| Table / column | Ready? | Note |
|---|---|---|
| `posts (user_id, body, image_url, video_url, visibility, audience, hashtags JSON, sport_id)` + `post_likes (post_id,user_id)` + `post_comments (post_id,user_id,body,parent_id)` | ✅ Yes | Threading, counts (`withCount`), visibility, sport tag all present. Add composite index `(post_id,created_at)` + unique `(post_id,user_id)` on likes if not already migrated (duplicate-like race). |
| `follows (follower_user_id, followee_user_id)` + `connections (follower/followee + status pending/accepted)` + `blocks` | ✅ Yes | Correct LinkedIn split. Keep `connections` name (plan says `connection_requests` — doc-only divergence, §M-8 of gap audit). |
| `saved_items (post morph)` | ✅ Yes | Enrichment closure present. |
| `notifications (category mentions, type like/comment/mention/message, action_url)` + `notification_prefs.categories.mentions` | ✅ Shell ready, content dead | Mapper + prefs + tab filter exist; needs G-3/G-4 emitters. |
| Missing for P1 | Hashtag GIN/JSON index, `mentions (post_id|comment_id, mentioned_user_id)`, `post_views` (for ranking/views), share `slug` | Add when building G-4/G-5/P1.7; not needed for MVP launch. |

No migration is needed to launch v1 social. Do **not** remodel — extend.

---

## 5. Production-readiness notes specific to social (add to Phase 10 gate)

1. **N+1 / pagination:** `index` eager-loads `user, comments.user` + `withCount` — good. Standardize paginator shape to `{data, meta:{current_page,per_page,total}}` (currently raw Laravel `paginate` on feed vs `{data}` envelope on show — app already handles both, but document it). Cap `comments.replies` depth to 1 to avoid explosion.
2. **Abuse:** posts throttled `30,1` ✅; add per-day post cap + duplicate-body guard before launch (spam). Reports-on-post → moderation queue path already exists — verify SLA (24h triage) in runbook.
3. **Media:** single-image upload only (`_selectedMedia.first`); video_url accepted by API but app has no video picker — either add or remove `video_url` from spec for MVP honesty. MIME validation + 5MB cap enforced server-side (Phase 10 §5.4).
4. **Privacy/safety:** verify `followers`-visibility + block-both-ways + minor-masking on staging with 3 test users (A follows B, B blocks A, minor C posts). Chat stays locked until accept — re-verify after any graph change.
5. **Realtime:** feed is pull (`FutureProvider` + invalidate on like/comment). No websockets — acceptable for MVP; add pull-to-refresh + `loadMore` pagination on feed list before launch (currently full-refetch).
6. **Analytics:** `POST /analytics/events` exists — log `post_created|post_liked|post_commented|follow|connect_request` from app to get the funnel for P1 ranking work.

---

## 6. Recommended build order (social-only, production-ready)

**Before MVP launch (≤2 days, all S-size):**
1. G-2 feed `liked` flag (backend 1-query fix + regression test).
2. G-3 like/comment notifications (emit + prefs-respect + self-skip + block-check; verify Mentions tab fills + push arrives).
3. G-8 reply composer (`parent_id` pass-through) + G-9 post edit entry (overflow menu → existing `updatePost`).
4. G-6 label honesty: rename rail to "Recommended Academies & Coaches" (or wire real Follow call) — 10-minute trust fix.
5. Feed pull-to-refresh + pagination (`loadMore`) so 1000-post users don't OOM.

**Right after launch (P1 wave — needs PM ordering):**
6. G-1 feed tabs (`?filter=following|sport`) + Following-only default toggle.
7. G-4 mentions (@extract + suggest-users + notify + highlight) + G-5 hashtag search/trending + G-10 trending aggregator.
8. G-6 rule-based recommendations (`GET /recommendations?relay=sport,age,city` + rail + Network suggestions) — P1.7.
9. G-7 share resolver (`GET /share/post/:slug` + `Share.share` on detail + `action_url` tap routing — pairs with gap-audit M-9).
10. Digest (P1.17) + per-sport topics (P1.18) once push volume justifies it.

**Explicitly not in MVP (correct):** stories, reels/shorts, live/streaming, groups/polls, boosted placement, chat media — all P2-parked. Saying "no" here is a feature, not a gap: keeps moderation + quota + scope shippable.

---

## Appendix — Where to look (review cheat-sheet)

- Feed + CRUD: `sportx-api/app/Http/Controllers/PostController.php:14-88` (index/store), `:90-127` (update/destroy), `:129-199` (comments/likes)
- Model: `sportx-api/app/Models/Post.php:11-33` (fillable, hashtag cast, `likedBy`)
- Routes: `sportx-api/routes/api.php:434-449` (connections+follows), `:468-478` (feed/posts/likes/comments)
- Graph: `FollowController.php:32-63`; `ConnectionController.php:13-112` (request/accept + notif), `:211-229` (chat unlock)
- Search (no posts group): `SearchController.php:67-111`
- Home rail bug: `sportx_app/lib/features/home/presentation/screens/home_screen.dart:158-162,184-306`
- Providers: `social/presentation/providers/posts_provider.dart:44-126`; `connections/.../follow_block_provider.dart:37-50`, `athlete_directory_provider.dart:47-52`
- Screens: `social/.../create_post_screen.dart:74-114`, `post_detail_screen.dart:22-105`, `create_sheet.dart:23`; router `core/router.dart:441,496,528-530`
- Save-post: `SavedItemController.php:38,158`; `saved/.../saved_screen.dart:92`
- Notif shell (empty for social): `NotificationService.php:20-52`; `NotificationController.php:34-36`; `PostController.php` (0 emits — the gap)

---

*Bottom line for stakeholders: you have a shippable LinkedIn-lite today. If "social media like" means post/like/comment/follow/connect/chat/save/report — **yes, built on both sides**. If it means algorithmic For-You, @mentions, hashtag discovery, suggested-people, outside-app share links — **not yet; scoped as P1.7/P1.8/P1.16 and correctly out of MVP**. Build the 5 S-items in §6 pre-launch, then sequence the P1 social wave by retention data, not by parity envy.*
