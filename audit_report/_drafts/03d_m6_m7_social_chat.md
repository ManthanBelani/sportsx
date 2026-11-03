# 03d — M6 (Programs / Facilities / Athletes) & M7 (Social / Chat) Audit
Audit date: 2026-11-03 · READ-ONLY · Sources: `sportx-api/` (Laravel), `sportx_app/` (Flutter), `sportsx-design-v3/new_design_docs/MVP_FEATURE_LIST.md` §M6, §M7, §6.

---

## M6.1 Training programs (create/edit; Active/Drafts/Past) — **DONE**
**Evidence**
- Routes: `sportx-api/routes/api.php:248-254` — GET /programs, GET /programs/{id}, GET/POST /me/programs, PUT /me/programs/{id}, POST /programs/{id}/enquire (role:athlete).
- `ProgramController` (`sportx-api/app/Http/Controllers/ProgramController.php`): `index` serves active only (`Program::active()`, :32); `show` 404s non-active for non-owners (:55); `mine` filters `?status=draft|active|past` (:63-76); `store`/`update` owner-resolved (coach→coach_profile, academy→academy, others 403, :165-174) and owner-authorized (:176-183). Validation `rules()` :185-200 covers title, sport, age_group, duration, mode, price, schedule, about, status.
- Schema: `database/migrations/2026_10_16_000001_create_programs_facilities_tables.php` — `programs` with enum status draft/active/past, softDeletes, indexes.
- Flutter: `sportx_app/lib/features/program/presentation/screens/my_programs_screen.dart:12-31` — Active/Drafts/Past TabController wired to `myProgramsProvider.load(status:)`; create form posts status active/draft (:160).

**Gaps**: No delete endpoint (soft-delete exists in schema but no route) — minor. Enquire endpoint restricted to role:athlete, so coaches/academies cannot enquire on other providers' programs (spec is athlete-centric; acceptable). **Severity: LOW**

## M6.2 Program / listing enquiry (creates chat thread) — **PARTIAL**
**Evidence**
- `POST /programs/{id}/enquire` → `ProgramController::enquire` (:115-158): creates or reuses an `Enquiry` with `subject_type=program` + first `EnquiryMessage`. Generic `POST /enquiries` → `EnquiryController::store` (`EnquiryController.php:12-40`) for coach_profile/academy/organizer/sponsor/sports_venue/program/opportunity; subject existence asserted (:226-239).
- Thread access: `authorizeAccess` (`EnquiryController.php:150-158`) — only the athlete owner or subject owner (or admin); `subjectOwnerId` (:164-178) resolves owner per subject type. Reply both directions: `reply` (:103-135); mark-read per participant (:137-148). Inbox per role with subject-pair matching (:42-93), `whereRaw('1=0')` leak guard (:84).
- Flutter: `shared/presentation/screens/enquire_screen.dart` via route `/enquire/:subjectType/:subjectId/:title` (`core/router.dart:396`); detail/reply `shared/providers/enquiry_provider.dart:183-220` (GET /enquiries/{id}, POST /enquiries/{id}/messages, PUT read); provider-side inbox screens exist (`coach_enquiry_inbox_screen.dart`, `shared/presentation/screens/enquiry_inbox_screen.dart`).

**Gaps**
1. **Provider is never notified of a new enquiry.** `EnquiryController::store` (lines 26-39) makes NO NotificationService call, and `reply()` (:103-135) only notifies the *athlete* (`$athleteUserId` branch :121-132). Spec §5.4/§5.7 "Enquiry notification → Reply in chat" — the provider only learns of an enquiry by opening the inbox. Also when the *athlete* replies later in the thread, the provider gets no notification (same athlete-only branch). **Severity: HIGH**
2. "Creates a chat thread" is implemented as a separate `Enquiries`/`EnquiryMessage` model, not a `Conversation` — this is fine (and the `minorChatGate` docblock in ConversationController.php:236-238 confirms enquiries deliberately bypass conversation gates), but the enquiry thread and 1:1 chat live in two disconnected inboxes.

## M6.3 Facilities (add/edit/list) — **DONE (minor gaps)**
**Evidence**
- Routes: `routes/api.php:257-262` (public GET /facilities/{id}; /me/facilities CRUD gated `role:academy,organizer`).
- `FacilityController.php`: `ownedQuery` (:80-93) scopes rows to the caller's academy or organizer profile; update/delete go through `owned()` (findOrFail within owned query → cross-tenant 404); validation :113-134.
- Flutter: `features/program/presentation/screens/facility_screens.dart` — list with type filter tabs (:53-58), delete via provider (:167-179), create form `_save` → `facilitiesProvider.save` POST (:206-225). Edit supported via provider.
**Gaps**: Spec lists facility types "ground, indoor, gym, **classroom, changing rooms**, other"; server enum is `ground,indoor,gym,other` (`FacilityController.php:119`) and Flutter tabs match — classroom/changing-rooms not representable. Facility images (`image_media_ids` accepted by API) not uploadable from the create form. **Severity: LOW**

## M6.4 Our Athletes (P1) — **UI-ONLY (mock data)**
**Evidence**
- `sportx_app/lib/features/academy/presentation/screens/invite_athlete_screen.dart:19-33` — hard-coded `_candidates` list (Arjun Patel, Meera Nair, Rohit Sharma, Sana Khan), search filters the local list, `_invited` is a local `Set<String>`; **zero dio/API calls in the file**. Route `/academy-invite-athlete` at `core/router.dart:414`.
- No backend support exists: no academy-athlete link/invite table, no endpoint in `routes/api.php` (grep for academy↔athlete linking returns nothing beyond scout connections and leaderboard comments).
**Gaps**: Entire feature is a mocked screen; no invite/accept state machine, no age filter against real data. P1 so not a launch blocker, but it is shipped as a fake flow. **Severity: MEDIUM** (misleading UI)

---

## M7.1 Create post (text/photo/video, edit/delete own) — **PARTIAL**
**Evidence**
- `POST/PATCH/DELETE /posts` → `PostController::store/update/destroy` (`PostController.php:152-281`). Owner-or-admin checks on update/destroy (:218, :277). Media: free-form URL must start `/storage/` (:164), multi-photo `image_media_ids` ownership-validated against the caller's user/profile rows (:178-196, :239-259). `abort_if(empty body && empty image)` (:198).
- Flutter: `features/social/presentation/screens/create_post_screen.dart` — uploads via `/media/upload` then POSTs `image_url`+`image_media_ids`+hashtags (:99-123); hashtag chips (:229-232).

**Gaps**
1. **Video removed.** Spec M7.1 says text/photo/video. `store()` rejects `video_url` with 422: "Video posts are no longer supported" (`PostController.php:156-158`, repeated :220-222); Flutter create screen only `pickImage` (create_post_screen.dart:52). Deliberate deviation — spec should be updated, but as-built M7.1 ≠ MVP list.
2. **Edit/delete own post is API-ONLY.** `updatePost`/`deletePost` exist in `posts_provider.dart:256-276` but **no screen calls them** (grep across `sportx_app/lib` shows zero callers); `post_detail_screen.dart` (258 lines) has no edit/delete/report menu. A user cannot edit or delete their own post from the app. **Severity: HIGH**

## M7.2 Feed (For You / Following / entity tabs) — **DONE**
**Evidence**
- `GET /feed` + `/posts` → `PostController::index` (`PostController.php:19-100`): `?following=1` scopes to followed authors (:46-50, :58); `?author_role=` role tabs (:63-69); visibility wall public/own/followers-linked (:70-76); pagination 15/page (:79).
- Flutter: `shared/presentation/widgets/home_kit.dart:661-667` — FeedTabsBar `['For You','Following','Athletes','Coaches','Academies','Events']` mapped to `_tabFilters = ['', 'following', 'role:athlete', 'role:coach', 'role:academy', 'role:organizer']` (:1395-1403). Community screen Feed tab uses paginated provider with load-more (`community_screen.dart:730-800`, `posts_provider.dart:138-155` dedupes by id).
**Gaps**: "simple relevance" is not implemented anywhere — both feeds are `->latest()` chronological only (spec wording is soft). Community screen's own Feed section ignores the tab filters (only `paginatedPostsProvider('')`). **Severity: LOW**

## M7.3 Post interactions (like/comment/save) — **PARTIAL**
**Evidence**
- Like: `toggleLike`/`unlike` (`PostController.php:331-366, 322-329`); `post_likes` unique `(post_id,user_id)` (migration `2026_08_11_...php:74`). Like gated on blocks + followers-visibility (:338-341); author notified (:352-362).
- Comment: `comment`/`comments`/`deleteComment` (:284-320, 368-431), threaded `parent_id`, notifications to post author and parent-comment owner with block skips (:395-428). Feed counts via `withCount(['likes','comments'])` (:57) — comments deliberately NOT hydrated in feed (:52-55 comment).
- Flutter: `togglePostLike` in-place feed update (`posts_provider.dart:204-236`); comment + delete comment + reply threading in `post_detail_screen.dart:249-250` and `_submitComment`.

**Gaps**
1. **Save is not wired into posts.** SavedItems API supports `item_type=post` (`SavedItemController.php:38`) and the Saved screen can open posts (`features/saved/presentation/screens/saved_screen.dart:52,90-92`), but **no post UI ever calls the save API**: the bookmark icon on `PostCardV3` just pushes the detail page (`home_kit.dart:788,1391` — `onSave: () => context.push(detail)`), and `post_detail_screen.dart` has no save action. M7.3 "save" is effectively unreachable. **Severity: MEDIUM**
2. **Report post missing in UI** (see moderation section below).

## M7.4 Follow / unfollow — **DONE**
**Evidence**
- Routes `routes/api.php:484-490`. `FollowController.php`: type→user resolution for user/athlete/coach/academy/organizer/scout (:18-30); self-follow 422 (:39); block check 403 (:40-42); `firstOrCreate` idempotent (:44-47); notify only on new (:50-60); unfollow delete (:66-76); status/followers/following endpoints (:78-112).
- DB: `follows` unique `['follower_user_id','followee_user_id']` (`2026_10_17_000001_phase6_social_network_chat_safety.php:18`).
- Flutter: `follow_block_provider.dart:37-51` follow/unfollow wired; follow buttons on profile screens (`view_profile_screen.dart`, community suggested rows).
**Gaps**: none material. **Severity: —**

## M7.5 Connect (request/accept/decline/cancel/remove) — **DONE**
**Evidence**
- Routes `routes/api.php:472-482` incl. PATCH /connections/{id} accept|decline and DELETE both shapes.
- `ConnectionController.php`: request validates active user + not-self (:16-34), block 403 (:39-41), **anti-harassment rate limit 3/day per target** (:45-48), `firstOrCreate` race-safe (:50-57), auto-accept on reverse accepted / mutual pending (:59-80), notifications (:82-91). Accept requires pending + followee (:97-102); decline deletes (:128-134); destroy allows either party (:138-148); status endpoint (:177-200).
- **Chat unlocked on accept**: `ensurePrivateConversation` (:217-249) creates the private Conversation + system message under a cache lock.
- DB: `connections` unique `['follower_user_id','followee_user_id']` (`2026_08_11_000001_create_social_tables.php:49`).
- Flutter: `connections_provider.dart:85-105` request/accept/remove; requests view with accept/decline snackbars (`connection_requests_view.dart:183-194`).
**Gaps**: No "cancel" verb — DELETE by either party covers it (requester delete = cancel). Acceptable. **Severity: —**

## M7.6 1-to-1 messaging — **PARTIAL** (see CRITICAL RULES for the permission holes)
**Evidence**
- Routes `routes/api.php:462-470` (read via GET/POST/PUT/PATCH …/read).
- List/unread: `ConversationController::index` (:16-38) — unread_count computed per participant from `last_read_at` pivot (COALESCE to epoch, :22-33). Show: participant-only `authorizeAccess` (:216-220). markRead updates pivot (:204-214).
- Flutter: `chat_provider.dart` — conversationsProvider (:106-110), markConversationRead fire-and-forget on thread open (:112-133), `sendMessage` returns false on DioException and chat_screen keeps the text in the box with an error snackbar (`chat_screen.dart:50-60` — good error handling), 4-second polling while thread open (:151-157), sender-id normalization (:63-67). Chats/Requests tabs: `chat_list_screen.dart:22,51,84` — Requests tab embeds `ConnectionRequestsView` inline.
- Push: FCM push exists for message sends server-side (`sendMessage` → NotificationService::createStatic :186-194; NotificationService has push fan-out `NotificationService.php:54-108`), but Flutter refresh is polling-only (chat_provider.dart:148 comment "FCM message push, once wired to a foreground handler").
**Gaps**
1. **Requests tab shows connection requests, not message requests** — acceptable interpretation of "Requests", but messages from non-connected users (possible under the cold-DM hole below) surface directly in Chats with no request/consent step.
2. **Unread badge only on chat-list rows** (`chat_list_screen.dart:195-199`). The home header message icon has NO badge (`home_kit.dart:99` — plain icon; the badge logic at :103-107 belongs to the bell/notifications). The conversation list itself never polls when no thread is open (only invalidated on screen open), so badges are stale until the user visits Messages. **Severity: MEDIUM**
3. Polling every 4s per open thread re-fetches the entire thread (`startChatPolling`, chat_provider.dart:151-157) — battery/server load; fine for MVP.

## CRITICAL RULES (§6) — server-side verification

### Rule 3 — Chat permission ("accepted connections or enquiry thread; NO cold DMs") — **VIOLATED for adults**
- The real check is `ConversationController::peerChatGate` (`ConversationController.php:277-319`), invoked from `store()` for private chats (:84-87) and re-invoked at **send time** by `privateSendGate` (:152-155, :321-334 — closes the stale-conversation bypass).
- It reads the **target's** privacy policy: `$targetPolicy = PrivacyController::settings($b)['who_can_message']` (:299), then:
  - `nobody` → 403 MESSAGING_DISABLED (:301-303);
  - `connections` → requires accepted `Connection` either direction (:305-316);
  - **`everyone` → NO relationship check at all** (falls through, :318).
- Default policy: `PrivacyController.php:29` — `'who_can_message' => $isMinor ? 'connections' : 'everyone'`.
- **Consequence: with defaults, any adult A can start a 1:1 conversation with any adult B via `POST /me/conversations` or `POST /conversations` (both → ConversationController::store, routes/api.php:464-465) and message them.** Cold DMs are permitted by default, contradicting §6 rule 3. Only scout↔athlete pairs are hard-gated on an accepted ScoutConnection (:290-294, :336-359).
- Mitigations that DO exist: blocks (403 BLOCKED :77-79), minor gate (:80-82), group chats require an accepted connection with every participant (:102-121), enquiries are separate from conversations (correct).

### Rule 2 — Blocked users cannot message or see each other — **PARTIAL**
- Chat: block checked at conversation create (:77-79), at message send for every participant (:146-150), and notification fan-out skips blocked (:182). Block also deletes follows + connections both ways, killing the chat-unlock path (`BlockController::store` :35-45). Follow/connect requests 403 when blocked (FollowController.php:40-42, ConnectionController.php:39-41).
- Feed/posts: `PostController::index` builds blockedIds both directions and filters `whereNotIn('user_id', $blockedIds)` (:23-25, :59, also :40); `show` 404s (:111); comments/likes/comment all gated (:290, :338, :379). Good.
- **Holes: NO block checks in discovery/profile/search.** `Block::` appears only in Block/Connection/Conversation/Follow/Post controllers. `DirectoryController` (GET /academies/{id} :182, /coaches/{id} :184), `AthleteDiscoveryController` (GET /athletes/{id} :273) and SearchController have zero block filtering → a blocked user can still view the blocker's profile and find them in discovery/search. Spec §5.11 "Block: … hidden both ways" (profile/chat). **Severity: HIGH**
- Block UI gap: `blockUser()` (`follow_block_provider.dart:57-59`) has **no callers** in the app — there is no block button on profiles or in chat; only unblock exists in Safety Centre (`safety_centre_screen.dart:59`). Users cannot actually block anyone from the UI. **Severity: HIGH**

### Rule 2/minors — Guardian `allow_messages` gate — **DONE**
- `ConversationController::minorChatGate` (`ConversationController.php:239-264`, confirmed at the ~line-232 region): for each side, parses athlete `date_of_birth`, if <18 requires `GuardianConsent` with `consent_status=verified` AND `allow_messages=true`, else 403 `GUARDIAN_REQUIRED`. Applied at conversation create for private (:80-82) and group (:109-111) and re-checked per participant at every group send (:159-168) — though NOT re-checked at private send (`privateSendGate` only calls `peerChatGate`), so a consent revoked mid-conversation keeps an existing private thread open until a new conversation is requested. Minor gap.
- Flutter surfaces `GUARDIAN_REQUIRED` with a consent dialog routing to /guardian-consent (`chat_provider.dart:179-208`). Note context: guardian PUT /me/guardian-controls is editable by the minor (prior audit finding stands) — the gate trusts that flag.

### Rule 9 / moderation — **BROKEN for posts**
- Reports: `POST /reports` accepts `post` among subject types (`ReportController.php:22`); admin moderation `reportableTypes` includes `'post' => Post::class` (`Admin/AdminModerationController.php:29-42`).
- **`AdminModerationController::remove` does `$item->update(['status' => 'removed'])` (:141). The `posts` table has NO `status` column** (create migration `2026_08_11_...php:55-66`: user_id, body, image_url, video_url, visibility only; later migrations add hashtags/sport_id/audience/image_media_ids — never status) and `Post::$fillable` has no status. The update is a silent no-op; even if it wrote, `PostController::index`/`show` never filter on status. **A removed-by-moderation post stays visible in the feed.** Feed does filter out *hard-deleted* posts (rows are gone), but the "removed" moderation state does not exist for posts. **Severity: HIGH**
- UI: posts cannot be reported from the app — `/report` route is only pushed from `detail_page_template.dart:368` (listing detail pages); `post_detail_screen.dart` has no report action (the comment at `community_feed.dart:25` claims "report/save live on the detail screen" — they do not). **Severity: MEDIUM** (rule 9 requires every post reportable)

### Follow vs Connect state machines — DB constraints
- `follows`: unique `(follower_user_id, followee_user_id)` — `2026_10_17_000001_phase6_social_network_chat_safety.php:18`. One-way, no status column (instant follow). ✔
- `connections`: unique `(follower_user_id, followee_user_id)` — `2026_08_11_000001_create_social_tables.php:49`; status enum pending/accepted (status column defined in same migration :42-49). Request states: pending → accepted (accept/mutual) or deleted (decline/cancel/remove). ✔ `blocks`: unique `(blocker, blocked)` (`2026_10_17...:31`). ✔
- `conversation_participants`: unique `(conversation_id, user_id)` (`2026_08_11...:26`). ✔

### Enquiry ↔ thread wiring (verify item 7)
- Enquiry = Enquiry + EnquiryMessage rows (`EnquiryController.php:26-37`); NOT a Conversation. Provider discovers via `GET /me/enquiries` inbox (role→subject-pair matching, :42-93). Reply flow works both directions via `POST /enquiries/{id}/messages` with ownership check. Provider notification on new enquiry: **MISSING** (see M6.2). Athlete notification on provider reply: present (:121-132).

### Feed internals (verify item 8)
- Pagination: server 15/page (`PostController.php:79`), Flutter load-more uses `meta.pagination.last_page` with id-dedup (`posts_provider.dart:102-155`). ✔
- N+1: index() is clean — `with('user')`, `withCount`, batched liked-map (:81), batched MediaItem URL map (:83-88). `show()` loads comments with users + replies in one eager-load (:106). ✔
- Blocked-user filtering in index: ✔ (:23-25, :59). Note `?following=1` also excludes blocked from followedIds (:39-44). ✔

### Hard-coded / mock data in production paths (verify item 10)
- Feed/chat/providers are fully API-wired (no mocks). `posts_provider`, `chat_provider`, `connections_provider`, `follow_block_provider`, `enquiry_provider`, `program_provider`, `facilitiesProvider` all hit dio endpoints.
- Mock found: **M6.4 invite_athlete_screen.dart** (hard-coded `_candidates`, see above). Community `_EventsSection` uses real trials/tournaments providers (`community_screen.dart:546-583`). No mock data in feed/chat paths.

### Prior-trace follow-up: chat_provider.dart:111 analyzer error
- The flagged error (FutureProviderRef → WidgetRef) appears **fixed**: current `chat_provider.dart:119` calls `markConversationRead(Ref ref, ...)` (:126) whose signature takes `Ref`; `sendMessage(WidgetRef)` (:135) is only called from `chat_screen.dart:53` inside a `ConsumerState` (WidgetRef context). No type mismatch remains in the file (fixed in commit 8e3423c "chat and feed refinements"). Not re-verified with the analyzer (no build run during this read-only audit).

### Flutter chat UX (verify item 9)
- Send failure: text retained in box + error snackbar (`chat_screen.dart:50-58`) ✔. Polling lifecycle stopChatPolling on dispose (:42-47) ✔. Connection-request UX: `startConversationResult` surfaces `CONNECTION_REQUIRED` / `GUARDIAN_REQUIRED` with dialog→/guardian-consent (`chat_provider.dart:172-208`) ✔. Safety reminder for minors before chat start (:212-231) ✔.
- Requests tab inline connection-requests view with accept/decline (`chat_list_screen.dart:84`, `connection_requests_view.dart`) ✔.

---

## Summary table

| ID | Feature | Status | Top gap | Severity |
|----|---------|--------|---------|----------|
| M6.1 | Training programs | DONE | no delete route | LOW |
| M6.2 | Program/listing enquiry | PARTIAL | provider never notified of new enquiry or athlete reply | HIGH |
| M6.3 | Facilities | DONE | classroom/changing-room types missing | LOW |
| M6.4 | Our Athletes (P1) | UI-ONLY | hard-coded mock candidates, no backend at all | MEDIUM |
| M7.1 | Create post | PARTIAL | video rejected (spec deviation); edit/delete own post unreachable in UI | HIGH |
| M7.2 | Feed tabs | DONE | no relevance ranking (chronological only) | LOW |
| M7.3 | Like/comment/save | PARTIAL | post save UI never calls save API; posts not reportable in UI | MEDIUM |
| M7.4 | Follow/unfollow | DONE | — | — |
| M7.5 | Connect state machine | DONE | — | — |
| M7.6 | 1-to-1 messaging | PARTIAL | cold-DM default violates §6 rule 3; home unread badge missing; stale badges | HIGH |

## Top risks (blunt)
1. **Cold DMs are allowed by default** (`who_can_message=everyone` default for adults + `peerChatGate` falling through) — the headline §6 chat rule is only enforced for minors and scout↔athlete pairs. Fix = default adults to `connections`, or enforce accepted-connection requirement in `peerChatGate` regardless of policy.
2. **Post moderation "remove" is a no-op** — posts table lacks a status column and feed never filters one; removed posts stay live.
3. **Users cannot block anyone from the UI** (no caller of blockUser), and blocked users remain visible in discovery/profile/search endpoints (no Block checks there).
4. **Users cannot edit/delete/report/save their own posts from the app** — all four actions exist server-side and in providers but no screen exposes them.
5. **Providers are never notified of enquiries** — the M6.2 P0 flow relies on the provider randomly opening the inbox.
