# Follow / Connect System Fix Plan

> Status: Planned
> Scope: `sportx-api` (Laravel) + `sportx_app` (Flutter)
> Goal: Complete the LinkedIn-style model — **Follow → see their posts** (one-way) and **Connect → chat + full social access** (two-way, accepted).

---

## 1. Problem summary (audit findings)

| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 1 | Follow feature is dead in the app: `followProfile` / `unfollowProfile` are defined but **never called**. No Follow button exists on any profile screen. The "Follow" CTA on Community only navigates. | `sportx_app\lib\features\connections\presentation\providers\follow_block_provider.dart:37-55`, `social\presentation\screens\community_screen.dart:135`, `features\shared\presentation\screens\view_profile_screen.dart:483-495` | 🔴 Critical |
| 2 | `visibility = 'followers'` posts are gated by **accepted Connections**, not the Follow table. The Follow table is never consulted for feed visibility. | `sportx-api\app\Http\Controllers\PostController.php:24-33,41-43` | 🔴 Critical |
| 3 | No follow-scoped feed query exists. The "Following" feed tab hits the same `GET /posts` as "For You" — it is cosmetic. | `sportx-api\routes\api.php:487-498`, `sportx_app\lib\shared\presentation\widgets\home_kit.dart:606,1337` | 🔴 Critical |
| 4 | `PostController::show()` has no visibility check — anyone can open a `followers`-only post via `GET /posts/{id}`. | `sportx-api\app\Http\Controllers\PostController.php:60-70` | 🔴 Privacy hole |
| 5 | Chat gate only covers athlete↔athlete and scout↔athlete. Coach/academy/organizer DMs are open to anyone with their user id. | `sportx-api\app\Http\Controllers\ConversationController.php:169-198` | 🟡 Gap |
| 6 | Chat gate only runs at conversation **creation** — existing conversations stay chattable after connection removal/block. | `sportx-api\app\Http\Controllers\ConversationController.php:57-70` | 🟡 Gap |
| 7 | `who_can_message` privacy setting is stored but never enforced. | `sportx-api\app\Http\Controllers\PrivacyController.php` vs `ConversationController` | 🟡 Gap |
| 8 | Message button is always enabled even when not connected; failure surfaces as a snackbar after-the-fact. | `view_profile_screen.dart:241-249` | 🟡 UX |
| 9 | Profiles show Connects count but no Followers count (followers treated as private). | `AthleteProfile`/`CoachProfile` append counts, discovery controllers | Low |

---

## 2. Target behaviour (definition of done)

- **Follow** (one-way, instant, no approval):
  - User A can follow User B from any profile surface. Following is visible on profiles (followers / following counts).
  - A sees B's posts with `visibility = 'followers'` in the feed.
  - A can optionally see B's posts in a "Following" feed tab (posts from everyone A follows).
- **Connect** (two-way, pending → accepted):
  - Request must be accepted (or auto-accepted on mutual interest) before a chat exists.
  - Accepted connection unlocks 1:1 chat, and also grants followers-level post access (connections are stronger than follows).
- **Chat gating**: DMs require an accepted connection for ALL role pairs (unless configured otherwise), enforced on both create and send. Block / removed connections kill chat access.
- **Privacy**: `who_can_message` (`everyone | connections | nobody`) is actually enforced.

---

## 3. Implementation phases

### Phase A — Backend: feed + follow semantics (P0)

**A1. Feed query: introduce follower scope** — `PostController::index()`
- Build `$followerIds` from `Follow::where('followee_user_id', $userId)` (and keep `$connectedIds`).
- Visibility rule set:
  - `public` → everyone (minus blocked).
  - `followers` → author's **followers + connections**.
  - own posts → always.
- Refactor to a single relationship-safe query; keep blocked exclusion.

**A2. New "Following" feed parameter**
- Support `GET /posts?following=1` → only posts authored by users the current user follows (plus own posts).
- Optional supporting params (`?type=athlete|coach|...` can come later if the tab filters are needed).

**A3. Enforce visibility on single post fetch** — `PostController::show()`
- Same visibility logic as `index()` (public / own / follower-or-connected for `followers`).
- Return 404 (not 403) to avoid leaking post existence.

**A4. Follower counts on public payloads**
- Append `followers_count` / `following_count` to `/athletes/{id}`, `/coaches/{id}` and `me` payloads (handle in the same count-append mechanism used for `connections_count` in `AthleteProfile` / `CoachProfile`).

### Phase B — Backend: chat gating (P0)

**B1. Generalize `peerChatGate()`** — `ConversationController`
- All role pairs (athlete, coach, academy, organizer, scout, generic user) require an accepted generic `Connection`; keep the scout↔athlete `ScoutConnection` gate as-is (it maps to profile graphs).
- Run the gate **before** the existing-conversation reuse check in `store()` so stale conversations can't bypass it.

**B2. Enforce gate on send**
- In `sendMessage()`, deny if no accepted connection (per B1 rules) between the two participants of a private conversation — this closes the stale-conversation hole permanently.

**B3. Enforce `who_can_message`**
- In `peerChatGate()`: if the target's privacy setting is `connections_only` → require accepted connection; `nobody` → reject (except admin / existing enquiry contexts if product decides); `everyone` → allow public non-athlete DMs per product choice. Default for existing rows: `everyone` (no breaking change).

**B4. Remove connection → remove chat? (decision needed)**
- Option 1 (chosen default): keep conversation but block sends (covered by B2).
- Document the decision in this file once made.

### Phase C — Frontend (Flutter): surface the Follow feature (P0)

**C1. Follow button on profile screens**
- Add Follow/Following toggle (`view_profile_screen.dart`) alongside Connect + Message, wired to `followProfile()` / `unfollowProfile()` with the correct **profile type + profile id** (backend `/follow/{type}/{id}` resolves profile-table ids).
- Optimistic UI + snackbar on failure.

**C2. Follow state fetch**
- Add a "do I follow this profile?" check. Simplest: client checks via the follow lists, or (preferred) add backend endpoint `GET /follow/status/{type}/{id}` returning `{ following: bool, followers_count, following_count }` (extend FollowController) and consume it in a provider.

**C3. Community screen "Follow" CTA becomes real**
- `community_screen.dart:135` — make PersonRowCard's CTA actually call `followProfile(...)`, or rename the CTA to "View" if product decides rows stay view-only.

**C4. "Following" feed tab becomes real**
- `home_kit.dart` feed tabs — "Following" tab must invalidate `postsFeedProvider` with `following: true` query param (matches Phase A2). Others use the normal feed.

**C5. Message button UX**
- On athlete profiles: show Message as disabled/locked with a lock hint when connection status ≠ accepted (data already available via `connectionStatusProvider`); opening chat consumed via `startConversationResult` stays as fallback error path.

**C6. Show follower counts**
- Replace/extend the stats row (`_buildStatsRow`) with Followers count using Phase A4 payload.

### Phase D — Polish + safety (P1)

- **D1.** Unblock → follow state consistency: verify `BlockController::destroy` doesn't leave orphan follows (block already removes follows + connections on create — confirm reverse edge).
- **D2.** `PostController::update()` — visibility sync of `audience` column already mirrored; add a regression test.
- **D3.** Throttle + dedupe: wrap `Connections::request` creation in `firstOrCreate` to kill the duplicate race (currently double-check then `create` — race window).
- **D4.** Seed demo follows in `SocialGraphSeeder` so the feed shows follower-gated posts in dev.

---

## 4. API changes summary

| Method / Path | Change |
|---|---|
| `GET /posts?following=1` | New filter — feed from followed users only |
| `GET /posts/{id}` | Now enforces visibility (404 for hidden posts) |
| `POST/DELETE /follow/{type}/{id}` | Unchanged (already correct) |
| `GET /follow/status/{type}/{id}` *(new)* | `{ following, followers_count, following_count }` |
| `/athletes/{id}`, `/coaches/{id}` | Appends `followers_count` |
| Chat endpoints | Gating generalized + enforced on send; `who_can_message` enforced |

---

## 5. Test plan

**Backend (feature tests / Postman)**
1. A follows B (no connection) → A's feed shows B's `visibility=followers` posts; A cannot DM B (`CONNECTION_REQUIRED`).
2. A + B connect+accept → chat allowed both ways, system message exists; both now see each other's followers-only posts.
3. A blocks B (or removes connection) → existing conversation cannot accept new messages (B2).
4. User C (not follower/connected) opens B's followers-only post by id → 404.
5. `GET /posts?following=1` returns only followed authors' posts + own.
6. `who_can_message = connections` → only connected users can start a chat.

**Flutter**
1. Profile screen: Follow toggles optimistically; status persists after reload.
2. Community "Follow" CTA follows instantly.
3. Feed "Following" tab shows followed-only posts.
4. Athlete profile: Message locked until Connected.

---

## 6. Open decisions (ask product)

1. Should connections also unlock followers-only posts, or strictly follows? *(Plan assumes both — connections are the stronger signal.)*
2. Keep the scout↔athlete chat gate as a separate profile-based system, or unify into generic connections?
3. When a connection is removed: keep old chat history readable but block sends (recommended), or archive the conversation?
4. Community screen rows: implement inline follow, or keep them view-only with follow only on the profile screen?

---

## 7. Suggested execution order

| Order | Task | Est. |
|-------|------|------|
| 1 | A1 + A3 (feed visibility + show check) — backend core fix | Small |
| 2 | B1 + B2 (chat gate generalize + send enforcement) | Small |
| 3 | C1 + C2 + C5 (follow button, status endpoint, message lock) | Medium |
| 4 | A2 + C4 (following feed param + real tab) | Small |
| 5 | A4 + C6 (follower counts) | Small |
| 6 | B3 (privacy enforcement) + D3 (race dedupe) | Small |
| 7 | D1, D2, D4 polish + full test pass | Small |
