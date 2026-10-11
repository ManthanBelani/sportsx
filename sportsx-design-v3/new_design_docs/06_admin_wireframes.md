# SportX India - Wireframes: Admin (web dashboard)

> Companion to `SCREEN_INVENTORY.md` and `MVP_FEATURE_LIST.md`. Priority: `P0` MVP, `P1` MVP+, `P2` post-MVP.

**Screens for this role:** 12 (P0 10, P1 2, P2 0)

## Journey in one line

```text
Login with 2FA -> dashboard -> verification queue -> moderation queue -> user management -> content, master data and expiry rules.
```

## Legend

| Symbol | Meaning |
|---|---|
| `[ Label ]` | Button |
| `(Chip)` | Chip / tag |
| `(o)` | Avatar or selected radio |
| `[x]` `[ ]` | Checkbox |
| `[____]` | Input |
| `[ Opt v ]` | Dropdown |
| `(v)` | Verified badge |
| `*Tab*` | Active tab |
| `>` | Opens another screen |
| `-->` | Horizontal scroll |

## Contents

1. **Access** - AD.1, AD.2
2. **Trust & safety** - AD.4, AD.7, AD.8, AD.3
3. **Content & data** - AD.5, AD.6, AD.9, AD.10
4. **Engagement tools** - AD.11, AD.12

---

## 1. Access

#### AD.1 - Admin Login  `P0`

> Web dashboard layout.

```text
┌────────────────────────────────────────────┐
│ +------------------------------+           │
│ |       SportX Admin           |           │
│ | Email    [_______________]   |           │
│ | Password [_______________]   |           │
│ | 2FA code [______]            |           │
│ | [ Login ]                    |           │
│ +------------------------------+           │
└────────────────────────────────────────────┘
```

#### AD.2 - Admin Dashboard  `P0`

```text
┌────────────────────────────────────────────┐
│ +--------+----------------------+          │
│ | Dash   | Users 12.4K  Verif 38|          │
│ | Users  | Reports 14  Events 92|          │
│ | Verif. +----------------------+          │
│ | Content| New users by role    |          │
│ | Moder. |  ||| || | |||        |          │
│ | Master +----------------------+          │
│ | Expiry | Recent activity      |          │
│ +--------+----------------------+          │
└────────────────────────────────────────────┘
```

## 2. Trust & safety

#### AD.4 - Verification Queue  `P0`

```text
┌────────────────────────────────────────────┐
│ Verification Requests (38)                 │
│ Name   | Role  | Docs   | Action           │
│ Rohit  | Coach | [open] | [Approve]        │
│ Reject needs a reason                      │
└────────────────────────────────────────────┘
```

#### AD.7 - Moderation Queue  `P0`

```text
┌────────────────────────────────────────────┐
│ Reports (14)  (Open)(Resolved)             │
│ # | Type  | Reason     | Preview           │
│ 1 | Post  | Misleading | "..."  [Open]     │
│ 2 | User  | Abuse      | Name   [Open]     │
└────────────────────────────────────────────┘
```

#### AD.8 - Moderation Detail  `P0`

```text
┌────────────────────────────────────────────┐
│ Report #112                                │
│ Reason: Fake listing                       │
│ Reporter: Name   Target: Listing           │
│ [ content preview ]                        │
│ [ Approve ][ Remove ][ Warn ]              │
│ [ Suspend user ]                           │
└────────────────────────────────────────────┘
```

#### AD.3 - User Management  `P0`

```text
┌────────────────────────────────────────────┐
│ Users  [ Search ] (Role v)(Status v)       │
│ Name    | Role   | Status | Action         │
│ Akshay  | Athlete| Active | [View]         │
│ Motera  | Academy| Active | [View]         │
│ -- detail: Suspend / Ban --                │
└────────────────────────────────────────────┘
```

## 3. Content & data

#### AD.5 - Content Manager  `P0`

```text
┌────────────────────────────────────────────┐
│ Content  (Academies v)  [ Search ]         │
│ Name   | City | Status | Created           │
│ Motera | Ahd. | Live   | 12 Oct            │
│ [ Edit ]  [ Delete ]  [ + Add ]            │
└────────────────────────────────────────────┘
```

#### AD.6 - Record Edit  `P0`

```text
┌────────────────────────────────────────────┐
│ Edit record                                │
│ Name   [_______________]                   │
│ City   [ Ahmedabad   v ]                   │
│ Status [ Live        v ]                   │
│ [ Delete ]        [ Save ]                 │
└────────────────────────────────────────────┘
```

#### AD.9 - Category / Master Manager  `P0`

```text
┌────────────────────────────────────────────┐
│ Master data                                │
│ Sports | Cities | Age groups | Positions   │
│ Cricket        [edit] [x]                  │
│ Football       [edit] [x]                  │
│ [ + Add ]                                  │
└────────────────────────────────────────────┘
```

#### AD.10 - Expiry Rules  `P0`

```text
┌────────────────────────────────────────────┐
│ Expiry rules                               │
│ Events: close 1 day after end date         │
│ Opportunities: at deadline                 │
│ [ + Add rule ]   [ Edit ]                  │
└────────────────────────────────────────────┘
```

## 4. Engagement tools

#### AD.11 - Leaderboard Config  `P1`

```text
┌────────────────────────────────────────────┐
│ Points rules                               │
│ Verified achievement   +50                 │
│ Event participation    +20                 │
│ Post                   +2                  │
│ Season length [ 6 months ]                 │
│ [ Save ]   [ Reset season ]                │
└────────────────────────────────────────────┘
```

#### AD.12 - Broadcast Notification  `P1`

```text
┌────────────────────────────────────────────┐
│ New broadcast                              │
│ Audience (All)(Athletes)(Coaches)          │
│ Title   [_______________]                  │
│ Message                                    │
│ +------------------------------+           │
│ Send  (Now)(Schedule)                      │
│ [ Send ]                                   │
└────────────────────────────────────────────┘
```
