# SportX India - Wireframes: Academy

> Companion to `SCREEN_INVENTORY.md` and `MVP_FEATURE_LIST.md`. Priority: `P0` MVP, `P1` MVP+, `P2` post-MVP.

**Screens for this role:** 66 (P0 51, P1 11, P2 4)

## Journey in one line

```text
Onboard listing -> add programs and facilities -> create trials -> review registrants -> post scholarships -> manage athletes and enquiries.
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

1. **Sign up & onboarding** - A.1, A.2, A.3, A.4, A.5, A.6, A.7, A.8, AC.1, A.10
2. **Home & academy profile** - AC.2, D.3, AC.3, D.14, D.15
3. **Training programs** - AC.4, CO.5, D.11, D.12
4. **Events / trials & registrants** - AC.6, OR.5, OR.6, OR.7, OR.8, D.6
5. **Facilities** - AC.7, AC.8, D.13
6. **Scholarships & opportunities** - AC.9, D.9
7. **Our athletes** - AC.5, AC.10, D.1
8. **Staff & collaborations** - AC.11, AC.12
9. **Discovery** - S.2, S.3, S.4, S.5, S.6, S.7
10. **Other profiles** - D.2, D.4, D.5
11. **Posts & media** - S.8, S.9, S.10, S.27, S.28
12. **Network, chat & notifications** - S.12, S.13, S.14, S.19, S.17, S.18, S.16
13. **Account & safety** - S.15, S.20, S.21, S.22, S.23, S.24, S.25, S.26, S.29, S.30

---

## 1. Sign up & onboarding

#### A.1 - Splash  `P0`

> Auth check, then routes to A.2 (new user) or the role Home (returning user).

```text
┌────────────────────────────────────────────┐
│                                            │
│                                            │
│      [ SportX logo ]                       │
│   LET'S DEFEAT HISTORY                     │
│                                            │
│                                            │
│      ( loader . . . )                      │
└────────────────────────────────────────────┘
```

#### A.2 - Welcome / Role Selection  `P0`

> One role per account in MVP. Selecting a card goes to A.3.

```text
┌────────────────────────────────────────────┐
│ Welcome to SportX                          │
│ Who are you?                               │
│ +----------------+----------------+        │
│ | (o) Athlete /  | (o) Coach      |        │
│ |     Parent     |                |        │
│ +----------------+----------------+        │
│ | (o) Academy    | (o) Organizer  |        │
│ +----------------+----------------+        │
│ | (o) Talent     |                         │
│ |     Scout      |                         │
│ +----------------+                         │
│ [ Continue ]                               │
│ Already a member? Login                    │
└────────────────────────────────────────────┘
```

#### A.3 - Sign Up  `P0`

> Phone or email. T&C must be ticked before the button enables.

```text
┌────────────────────────────────────────────┐
│ <  Create account                          │
│ Role: Athlete   (change)                   │
│ Phone / Email                              │
│ [______________________]                   │
│ Password (optional)                        │
│ [______________________]                   │
│ [x] I accept Terms & Privacy               │
│ [ Send OTP ]                               │
│ ---------- or ----------                   │
│ [ Continue with Google ]                   │
└────────────────────────────────────────────┘
```

#### A.4 - OTP Verification  `P0`

> Next: A.9 if athlete is under 18, otherwise the role onboarding wizard.

```text
┌────────────────────────────────────────────┐
│ <  Verify                                  │
│ Enter the 6-digit code sent to             │
│ +91 98XXXXXX10                             │
│ [ 4 ] [ 2 ] [ _ ] [ _ ] [ _ ] [ _ ]        │
│ Resend code in 00:28                       │
│ [ Verify ]                                 │
│ Wrong number? Edit                         │
└────────────────────────────────────────────┘
```

#### A.5 - Login  `P0`

```text
┌────────────────────────────────────────────┐
│ [ SportX logo ]                            │
│ Welcome back                               │
│ *OTP* | Password                           │
│ Phone / Email                              │
│ [______________________]                   │
│ [ Get OTP ]                                │
│ Forgot password?                           │
│ New here? Create account                   │
└────────────────────────────────────────────┘
```

#### A.6 - Forgot / Reset Password  `P1`

```text
┌────────────────────────────────────────────┐
│ <  Reset password                          │
│ Phone / Email                              │
│ [______________________]                   │
│ [ Send OTP ]                               │
│ -- after OTP --                            │
│ New password  [____________]               │
│ Confirm       [____________]               │
│ [ Reset password ]                         │
└────────────────────────────────────────────┘
```

#### A.7 - Language Selection  `P1`

```text
┌────────────────────────────────────────────┐
│ <  Language                                │
│ ( ) English                                │
│ (o) Hindi                                  │
│ ( ) Gujarati                               │
│ [ Apply ]                                  │
└────────────────────────────────────────────┘
```

#### A.8 - Permissions Primer  `P1`

> Each Allow triggers the OS permission dialog. Skip is always available.

```text
┌────────────────────────────────────────────┐
│ [ icon: pin ]                              │
│ Find academies and trials near you         │
│ [ Allow location ]                         │
│ [ icon: bell ]                             │
│ Get updates on registrations               │
│ [ Allow notifications ]                    │
│ Skip for now                               │
└────────────────────────────────────────────┘
```

#### AC.1 - Onboarding - Academy Setup  `P0`

```text
┌────────────────────────────────────────────┐
│ Step 3 of 5          Facilities            │
│ Academy name  [_____________]              │
│ Sports        (Cricket)(+)                 │
│ Age range     [ U-8 ] to [ U-19 ]          │
│ Facilities    (Grounds)(Nets)(Gym)         │
│ Address       [_____________]              │
│ Pin on map    [ map ]                      │
│ Fees          [____] / month               │
│ Photos        [ + ] [ + ] [ + ]            │
│ [ Back ]            [ Next ]               │
└────────────────────────────────────────────┘
```

#### A.10 - Verification Request & Status  `P0`

> Status values: Not started, Pending, Verified, Rejected (with reason).

```text
┌────────────────────────────────────────────┐
│ <  Get verified                            │
│ Status: ( Pending review )                 │
│ ID proof                                   │
│ [ + Upload ]   id_front.jpg                │
│ Organization / club proof                  │
│ [ + Upload ]                               │
│ Notes (optional)                           │
│ [______________________]                   │
│ [ Submit for review ]                      │
└────────────────────────────────────────────┘
```

## 2. Home & academy profile

#### AC.2 - Academy Home  `P0`

```text
┌────────────────────────────────────────────┐
│ [SportX]  [ search ] (bell3) (o)           │
│ Hi, Motera Cricket Academy!  80%           │
│ Leaderboard: Academies                     │
│  (o)Elite 2500 (o)Motera 2310              │
│ [Opportunities] [Find Talent]              │
│ +----------+ +----------+                  │
│ | Enquiries| | Registr. |                  │
│ |    12    | |   120    |                  │
│ +----------+ +----------+                  │
│ [ post card ]                              │
│------------------------------------------  │
│ [Home] Explore (+) Community More          │
└────────────────────────────────────────────┘
```

#### D.3 - Academy Profile  `P0`

```text
┌────────────────────────────────────────────┐
│ <  SportX              [share] ...         │
│ [ cover ]  (logo)                          │
│ Motera Cricket Academy (v)                 │
│ * 4.8 (320 reviews)                        │
│ Sports Academy * Cricket                   │
│ Motera, Ahmedabad                          │
│ [ Follow ]  [ Message ]                    │
│ *About*|Programs|Facilities|Events|Reviews │
│ Sports        Cricket                      │
│ Age group     U-8 to U-19                  │
│ Coaches       12+                          │
│ Facilities    3 Grounds, Nets, Gym         │
│ Established   2018                         │
│ [ Enquire ]                                │
└────────────────────────────────────────────┘
```

#### AC.3 - Edit Academy Profile  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Edit academy          [ Save ]          │
│ Logo, cover, gallery                       │
│ Name, sports, age range                    │
│ Facilities chips                           │
│ Staff count, established                   │
│ Address + map pin                          │
│ Fees, timings                              │
└────────────────────────────────────────────┘
```

#### D.14 - Reviews List  `P1`

```text
┌────────────────────────────────────────────┐
│ <  Reviews                                 │
│ 4.8  *****  (320)                          │
│ 5 [=========]                              │
│ 4 [===      ]                              │
│ (o) Aman * 5  "Great coaching"             │
│ (o) Riya * 4  "Good facilities"            │
│ [ Write a review ]                         │
└────────────────────────────────────────────┘
```

#### D.15 - Write Review  `P1`

> Allowed only after a verified interaction (enquiry or attended event).

```text
┌────────────────────────────────────────────┐
│ <  Write review                            │
│ Rating  *  *  *  *  *                      │
│ Review                                     │
│ +------------------------------+           │
│ +------------------------------+           │
│ [ Submit ]                                 │
└────────────────────────────────────────────┘
```

## 3. Training programs

#### AC.4 - Academy Programs  `P0`

> Same as CO.4 and CO.5, owned by the academy.

```text
┌────────────────────────────────────────────┐
│ <  Training Programs                       │
│ [ same as CO.4 ]                           │
└────────────────────────────────────────────┘
```

#### CO.5 - Create / Edit Program  `P0`

```text
┌────────────────────────────────────────────┐
│ <  New program                             │
│ Title    [__________________]              │
│ Sport    [ Cricket        v ]              │
│ Age      (U-10)(U-14)(All)                 │
│ Duration [ 3 months ]                      │
│ Mode     (Offline)(Online)                 │
│ Price    [ Rs ____ ] per [ month v]        │
│ Schedule [__________________]              │
│ About                                      │
│ +------------------------------+           │
│ [ Save draft ]    [ Publish ]              │
└────────────────────────────────────────────┘
```

#### D.11 - Program Detail  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Program               [bk]              │
│ [ image ]                                  │
│ Beginner Cricket Program                   │
│ by Motera Cricket Academy >                │
│ U-10 - U-14 * 3 Months                     │
│ Offline * Rs 5,000                         │
│ Schedule: Mon/Wed/Fri 6 AM                 │
│ About this program ...                     │
│ [ Enquire ]                                │
└────────────────────────────────────────────┘
```

#### D.12 - Enquiry Form  `P0`

> Submitting creates a chat thread (S.18) with the provider.

```text
┌────────────────────────────────────────────┐
│ <  Enquire                                 │
│ To: Motera Cricket Academy                 │
│ About: Beginner Cricket Program            │
│ Preferred batch [ Morning v ]              │
│ Message                                    │
│ +------------------------------+           │
│ |                              |           │
│ +------------------------------+           │
│ [ Send enquiry ]                           │
└────────────────────────────────────────────┘
```

## 4. Events / trials & registrants

#### AC.6 - Events / Trials (Academy)  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Events / Trials                         │
│ *Upcoming*|Past                            │
│ [ + Create Event ]                         │
│ +------------------------------+           │
│ | 12 Nov  Open Trials U14      |           │
│ | Ahmedabad * 120 Registered   |           │
│ |                   [ View ]   |           │
│ +------------------------------+           │
└────────────────────────────────────────────┘
```

#### OR.5 - Create / Edit Event  `P0`

> Multi-step. Steps: Basics, Dates & venue, Eligibility, Fees & slots, Review.

```text
┌────────────────────────────────────────────┐
│ Step 2 of 5       Dates & venue            │
│ Type    (Tournament)(Trial)(Camp)          │
│ Sport   [ Football       v ]               │
│ Start   [ 20 Nov 2026 ]                    │
│ End     [ 22 Nov 2026 ]                    │
│ Venue   [ Pick venue     v ]               │
│ Categories (U-14)(U-17)                    │
│ Fee     [ Rs 500 ] per [team v]            │
│ Slots   [ 500 ]                            │
│ Docs required (Age proof)(ID)              │
│ [ Save draft ]     [ Next ]                │
└────────────────────────────────────────────┘
```

#### OR.6 - Event Management  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Manage event        [Edit] ...          │
│ [ cover ]                                  │
│ NOV 20-22 2026                             │
│ Gujarat Youth Football Champ.              │
│ ( Registrations Open )                     │
│ 320 / 500 slots                            │
│ [===============     ]                     │
│ Fee Rs 500/team                            │
│ *Overview*|Registrations|Schedule|Gallery  │
│ [ Share ]  [ Close registrations ]         │
│ [ Manage Event ]                           │
└────────────────────────────────────────────┘
```

#### OR.7 - Registrations / Participants  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Registrations                           │
│ *All(320)*|Approved(280)|Pending(30)       │
│ [ Search participants ]  [filter]          │
│ [x] (o) Aarav Patel  U-17                  │
│          ( Approved )                      │
│ [ ] (o) Riya Mehta   U-17                  │
│          ( Pending )                       │
│ [ Approve ] [ Reject ] (bulk)              │
│ [ Export List ]                            │
└────────────────────────────────────────────┘
```

#### OR.8 - Registrant Detail  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Registrant                              │
│ (o) Riya Mehta  ( Pending )                │
│ DOB 12/04/2010 * U-17                      │
│ Phone, Email, Team                         │
│ Documents                                  │
│  [ age proof.pdf ]                         │
│ [ Reject ]       [ Approve ]               │
└────────────────────────────────────────────┘
```

#### D.6 - Event / Trial Detail  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Event               [share] [bk]        │
│ [ cover image ]                            │
│ NOV 20-22 2026                             │
│ Gujarat Youth Football Champ.              │
│ Ahmedabad * Football * U-14,U-17           │
│ ( Registrations Open )                     │
│ 320 Registered (500 slots)                 │
│ [===============     ]                     │
│ Fee: Rs 500 / team                         │
│ Organizer: Raj Sports Events >             │
│ *Overview*|Schedule|Gallery                │
│ Eligibility / documents ...                │
│ [ Register Now ]                           │
└────────────────────────────────────────────┘
```

## 5. Facilities

#### AC.7 - Facilities  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Facilities                              │
│ All|Grounds|Indoor|Gym|Other               │
│ [ + Add Facility ]                         │
│ +------------------------------+           │
│ | [img] Main Cricket Ground    |           │
│ | Outdoor * Full size [ View ] |           │
│ +------------------------------+           │
└────────────────────────────────────────────┘
```

#### AC.8 - Add / Edit Facility  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Add facility          [ Save ]          │
│ Name   [__________________]                │
│ Type   (Ground)(Indoor)(Gym)               │
│ Size / lanes [____________]                │
│ Amenities (Lights)(Parking)                │
│ Images [ + ] [ + ]                         │
└────────────────────────────────────────────┘
```

#### D.13 - Facility / Venue Detail  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Facility                                │
│ [ image carousel ]  1/5                    │
│ Indoor Nets                                │
│ Type: Indoor * 4 practice lanes            │
│ Amenities: lights, bowling machine         │
│ Location: Motera, Ahmedabad                │
└────────────────────────────────────────────┘
```

## 6. Scholarships & opportunities

#### AC.9 - My Scholarships / Opportunities  `P0`

```text
┌────────────────────────────────────────────┐
│ <  My Scholarships                         │
│ [ + Post opportunity ]                     │
│ Active|Closed                              │
│ +------------------------------+           │
│ | Merit Scholarship  12 apps   |           │
│ | Deadline 30 Nov   [ Review ] |           │
│ +------------------------------+           │
└────────────────────────────────────────────┘
```

#### D.9 - Opportunity Detail  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Opportunity         [bk] [share]        │
│ ( Scholarship )                            │
│ Gujarat Sports Scholarship 2026            │
│ Provider: Sports Authority                 │
│ Amount: Rs 50,000                          │
│ Deadline: 30 Nov 2026                      │
│ Eligibility                                │
│  - Age 14-19, state level                  │
│ Benefits                                   │
│  - Coaching + kit                          │
│ [ Apply Now ]                              │
└────────────────────────────────────────────┘
```

## 7. Our athletes

#### AC.5 - Our Athletes  `P1`

```text
┌────────────────────────────────────────────┐
│ <  Our Athletes                            │
│ (All)(U-8)(U-10)(U-14)(U-16)               │
│ [ Search athletes ]    [filter]            │
│ (o) Karan Joshi                            │
│     U-16 * Batsman  * 4.5                  │
│                   [ View Profile ]         │
│ (o) Priya Sharma  U-14 ...                 │
│ [ + Invite athlete ]                       │
└────────────────────────────────────────────┘
```

#### AC.10 - Add / Invite Athlete  `P1`

```text
┌────────────────────────────────────────────┐
│ <  Invite athlete                          │
│ [ Search by name / phone ]                 │
│ (o) Karan J.   [ Invite ]                  │
│ Pending invites: 2                         │
└────────────────────────────────────────────┘
```

#### D.1 - Athlete Profile (own & public)  `P0`

> Own view shows Edit/Share/View as Public. Visitors see Follow/Connect/Message; scouts also see Shortlist.

```text
┌────────────────────────────────────────────┐
│ <  SportX              [share] ...         │
│ +------------------------------+           │
│ |        [ cover image ]       |           │
│ | (o)[cam]                     |           │
│ +------------------------------+           │
│ Akshay Pandya (v)                          │
│ Cricket Player * Athlete                   │
│ Ahmedabad, Gujarat                         │
│ 12 Posts|5 Conn|3 Sports|4 Ach.            │
│ Profile 68% [=======   ]                   │
│ [ Edit ] [ Share ] [ As Public ]           │
│ *Overview*|Posts|Achv|Media|Conn.          │
│ ABOUT                       Edit           │
│  Role, Location, Age, College              │
│ SPORTS                    Manage           │
│  [Cricket - Primary Sport]                 │
│  [ + Add another sport ]                   │
│ MEDIA            [img][img][+4]            │
│ ACHIEVEMENTS         [ + Add ]             │
│ SOCIAL LINKS  IG | LI | YT                 │
└────────────────────────────────────────────┘
```

## 8. Staff & collaborations

#### AC.11 - My Staff / Recruit Staff  `P2`

```text
┌────────────────────────────────────────────┐
│ <  Staff            [ + Add ]              │
│ (o) Coach Rohan  Head Coach                │
│ [ Post opening ]                           │
└────────────────────────────────────────────┘
```

#### AC.12 - My Collaborations  `P2`

```text
┌────────────────────────────────────────────┐
│ <  Collaborations                          │
│ [ partner org cards ]                      │
└────────────────────────────────────────────┘
```

## 9. Discovery

#### S.2 - Explore - All  `P0`

> See All opens S.3 for that category.

```text
┌────────────────────────────────────────────┐
│ [SportX]  [ search ] (bell3) (o)           │
│ *All*|Athletes|Coaches|Academies|Events    │
│ Popular Athletes         See All           │
│ [card][card][card] -->                     │
│ Coaches                  See All           │
│ [card][card][card] -->                     │
│ Academies                See All           │
│ [card][card] -->                           │
│ Events                   See All           │
│ [card][card] -->                           │
│ Opportunities                              │
│ [Scholarship][Sponsorship] -->             │
│------------------------------------------  │
│ Home [Explore] (+) Community More          │
└────────────────────────────────────────────┘
```

#### S.3 - Explore - Category List  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Explore                [filter]         │
│ [ Search athletes, sport, city ]           │
│ All|*Athletes*|Coaches|Academies|Events    │
│ (Sport v)(State v)(Age v)(More v)          │
│ 1,248 Athletes     Most Relevant v         │
│ +-------------+ +-------------+            │
│ | [photo] [b] | | [photo] [b] |            │
│ | Name  (v)   | | Name  (v)   |            │
│ | Cricket*GJ  | | Football*MH |            │
│ | U-19*All-r. | | U-17*Fwd    |            │
│ | T12  V5     | | T8   V3     |            │
│ | [ Follow ]  | | [ Follow ]  |            │
│ +-------------+ +-------------+            │
│------------------------------------------  │
│ Home [Explore] (+) Community More          │
└────────────────────────────────────────────┘
```

#### S.4 - Filter & Sort Sheet  `P0`

> Bottom sheet. Fields vary by category (e.g. Facilities for academies).

```text
┌────────────────────────────────────────────┐
│ ----------- handle -----------             │
│ Filters                  Reset             │
│ Sport      (Cricket)(Football)+            │
│ State/City [ Gujarat       v ]             │
│ Age group  (U-10)(U-14)(U-19)              │
│ Position   [ Any           v ]             │
│ Level      (District)(State)               │
│ Price      [==o=======o==]                 │
│ Date       [ any          v ]              │
│ Sort by    (o) Relevant ( ) Near           │
│ [ Show 124 results ]                       │
└────────────────────────────────────────────┘
```

#### S.5 - Universal Search + Results  `P0`

```text
┌────────────────────────────────────────────┐
│ <  [ Search...        ] [x]                │
│ Recent                                     │
│  - Cricket academy Motera   [x]            │
│  - U-14 trials                             │
│ -- after typing --                         │
│ Athletes (3)                               │
│  (o) Arjun Patel  Cricket                  │
│ Coaches (2)                                │
│ Academies (4)                              │
│ Events (1)                                 │
│ No results? "Try another sport"            │
└────────────────────────────────────────────┘
```

#### S.6 - Leaderboard  `P0`

> Athletes P0. Coaches, Academies, Teams, Events tabs are P1.

```text
┌────────────────────────────────────────────┐
│ <  Leaderboard              (i)            │
│ *Athletes*|Coaches|Academies|...           │
│ (All)(Cricket)(Football)(Bdmtn)            │
│ [ India v ]  [ All ages v ]                │
│ Top Athletes                               │
│     (o)      (O)      (o)                  │
│    Priya    ARJUN    Sneha                 │
│     #2       #1       #3                   │
│    1250     1480     1120                  │
│ 4 (o) Karan J.  Cricket  980 [Follow]      │
│ 5 (o) Dev M.    Football 940 [Follow]      │
│ ...                                        │
│ [ View Full Leaderboard ]                  │
│------------------------------------------  │
│ [Home] Explore (+) Community More          │
└────────────────────────────────────────────┘
```

#### S.7 - Leaderboard Info  `P1`

```text
┌────────────────────────────────────────────┐
│ <  How points work                         │
│ Points come from:                          │
│  - Verified achievements                   │
│  - Profile completeness                    │
│  - Activity (posts, events)                │
│ Seasons reset every 6 months               │
│ [ Got it ]                                 │
└────────────────────────────────────────────┘
```

## 10. Other profiles

#### D.2 - Coach Profile  `P0`

```text
┌────────────────────────────────────────────┐
│ <  SportX              [share] ...         │
│ [ cover ]  (o)                             │
│ Rohit Mehta (v)                            │
│ Cricket Coach * BCCI Level 2               │
│ Ahmedabad, Gujarat                         │
│ 12 | 5.2K | 15                             │
│ [ Edit Profile ]  [ Message ]              │
│ *About*|Posts|Programs|Achv                │
│ Experience     12+ years                   │
│ Specialization Batting, Fielding           │
│ Age group      U-10 ... Open               │
│ Languages      Hindi, English              │
│ PROGRAMS                                   │
│ [ Beginner Cricket  Rs5,000 ]              │
│ [ Follow ]  [ Connect ]                    │
└────────────────────────────────────────────┘
```

#### D.4 - Organizer Profile  `P0`

```text
┌────────────────────────────────────────────┐
│ <  SportX              [share] ...         │
│ [ cover ]  (RAJ)                           │
│ Raj Sports Events (v)                      │
│ Event Organizer * Ahmedabad                │
│ 12 Events|5.2K Part.|15 Collab.            │
│ [ Edit Profile ] [ Share ]                 │
│ *About*|Events|Venues|Team|Media           │
│ Event types  Tournaments, Trials           │
│ Sports       Cricket, Football             │
│ Established  2023                          │
│ Website      rajsportsevents.in            │
└────────────────────────────────────────────┘
```

#### D.5 - Scout Profile  `P0`

> Own view adds Shortlisted Talents and Reports tabs (private). Public view shows About and Activity only.

```text
┌────────────────────────────────────────────┐
│ <  SportX              [share] ...         │
│ [ cover ]  (o)                             │
│ Sameer Desai (v)                           │
│ Talent Scout * 4.8 (120)                   │
│ Ahmedabad, Gujarat                         │
│ [ Edit Profile ] [ Share ]                 │
│ *About*|Shortlisted|Reports|Activity       │
│ Organization   Independent Scout           │
│ Sports focus   Cricket, Football           │
│ Experience     8+ years                    │
│ Availability   Pan Gujarat / India         │
│ Languages      Eng, Hin, Guj               │
└────────────────────────────────────────────┘
```

## 11. Posts & media

#### S.8 - Create Launcher  `P0`

> Tiles depend on role (see SCREEN_INVENTORY role sections).

```text
┌────────────────────────────────────────────┐
│ Create                       [X]           │
│ Share, Add or Create on SportX             │
│ +---------------+---------------+          │
│ | Create Post   | Add           |          │
│ |               | Achievement   |          │
│ +---------------+---------------+          │
│ | Upload Media  | Create Event  |          │
│ +---------------+---------------+          │
│ | Create        | Add Academy   |          │
│ | Opportunity   |               |          │
│ +---------------+---------------+          │
│ Quick Post                                 │
│ (Photo)(Video)(Text)(Achievement)          │
│------------------------------------------  │
│ Home Explore [(+)] Community More          │
└────────────────────────────────────────────┘
```

#### S.9 - Create Post  `P0`

```text
┌────────────────────────────────────────────┐
│ X  New post              [ Post ]          │
│ (o) Akshay Pandya  (Public v)              │
│ +------------------------------+           │
│ | What's on your mind?         |           │
│ |                              |           │
│ +------------------------------+           │
│ #hashtags                                  │
│ [img][img][ + ]                            │
│ (Photo)(Video)(Tag sport)                  │
└────────────────────────────────────────────┘
```

#### S.10 - Upload Media  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Upload media          [ Upload ]        │
│ [ + Choose photos / videos ]               │
│ [img] [vid>] [img]                         │
│ Caption  [___________________]             │
│ Sport    [ Cricket        v ]              │
│ Uploading 2 of 3 ... [=====  ]             │
└────────────────────────────────────────────┘
```

#### S.27 - Post Detail  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Post                    ...             │
│ (o) Priya Sharma [v]    2h                 │
│ State Level Athlete                        │
│ Text and #hashtags                         │
│ [img][img][img]                            │
│ Like 256  Comment 18  Share 12 [bk]        │
│ ---------- Comments ----------             │
│ (o) Sneha: Great!                          │
│ [ Add a comment...        ] [>]            │
└────────────────────────────────────────────┘
```

#### S.28 - Media Viewer  `P0`

```text
┌────────────────────────────────────────────┐
│ X                            ...           │
│ +------------------------------+           │
│ |                              |           │
│ |        [ photo / video ]     |           │
│ |                              |           │
│ +------------------------------+           │
│   < swipe >      1 / 7                     │
│ [share]  [report]                          │
└────────────────────────────────────────────┘
```

## 12. Network, chat & notifications

#### S.12 - Community - Network  `P1`

```text
┌────────────────────────────────────────────┐
│ [SportX]  [ search ] (bell3) (o)           │
│ *Network*|Groups|Events                    │
│ [ Search people, groups ]                  │
│ Suggested for you                          │
│ (Athletes)(Coaches)(Academies)             │
│ (o) Priya S.  Throwball [Follow]           │
│ (o) Ankit S.  Coach     [Follow]           │
│ (o) Motera Acad.        [Follow]           │
│------------------------------------------  │
│ Home Explore (+) [Community] More          │
└────────────────────────────────────────────┘
```

#### S.13 - Community - Groups  `P2`

```text
┌────────────────────────────────────────────┐
│ [SportX]  [ search ] (bell3) (o)           │
│ Network|*Groups*|Events                    │
│ Join groups                                │
│ (#) Cricket Coaches India                  │
│     2.4K members      [ Join ]             │
│ (#) Youth Training & Dev                   │
│     1.8K members      [ Join ]             │
│------------------------------------------  │
│ Home Explore (+) [Community] More          │
└────────────────────────────────────────────┘
```

#### S.14 - Group Detail  `P2`

```text
┌────────────────────────────────────────────┐
│ <  Cricket Coaches India   [Join]          │
│ 2.4K members                               │
│ About | Posts | Members                    │
│ [ post ]  [ post ]                         │
└────────────────────────────────────────────┘
```

#### S.19 - Connections  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Connections                             │
│ Followers|Following|*Connections*|Req      │
│ Requests (3)                               │
│ (o) Neha P.  Athlete                       │
│     [ Accept ]  [ Decline ]                │
│ Sent                                       │
│ (o) Dev M.   [ Cancel ]                    │
│ Connected (5)                              │
│ (o) Rohit M. [ Message ] [ ... ]           │
└────────────────────────────────────────────┘
```

#### S.17 - Messages Inbox  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Messages                                │
│ *Chats* | Requests (2)                     │
│ [ Search messages ]                        │
│ (o) Karan Joshi        10:42               │
│     Thank you for the...    (2)            │
│ (o) Priya Sharma        9:15               │
│     Fees for U-14?                         │
│ (o) Motera Academy   Yesterday             │
│     Sure, see you tomorrow                 │
└────────────────────────────────────────────┘
```

#### S.18 - Chat Thread  `P0`

> Only for accepted connections or enquiry threads. Overflow has Report and Block.

```text
┌────────────────────────────────────────────┐
│ <  (o) Karan Joshi        ...              │
│ ----------- Today -----------              │
│    +--------------------+                  │
│    | When is next batch? |                 │
│    +--------------------+                  │
│ +--------------------+                     │
│ | Monday 6 AM        |                     │
│ +--------------------+                     │
│ [+] [ Type a message ] [>]                 │
└────────────────────────────────────────────┘
```

#### S.16 - Notifications  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Notifications          (*)              │
│ *All*|People|Opps|Events|Mentions          │
│ Mark all as read                           │
│ TODAY                                      │
│ o (o) Priya followed you                   │
│       [ Follow back ]       2m             │
│ o (!) New sponsorship match   1h           │
│ YESTERDAY                                  │
│   (o) Rohit liked your post                │
│   (o) Sneha commented "..."                │
│ THIS WEEK                                  │
│   (v) Verification under review            │
└────────────────────────────────────────────┘
```

## 13. Account & safety

#### S.15 - More Menu  `P0`

> Rows differ by role. Athlete version shown.

```text
┌────────────────────────────────────────────┐
│ More                     (bell3)(*)        │
│ +------------------------------+           │
│ | (o)+ Akshay Pandya  [v]      |           │
│ | Athlete * Ahmedabad          |           │
│ | 12 Posts 5 Conn. 68%         |           │
│ | [ View Profile ]             |           │
│ +------------------------------+           │
│ > My Profile                               │
│ > My Opportunities                         │
│ > My Activity                              │
│ > Achievements & Certificates              │
│ > Saved                                    │
│ > Settings & Privacy                       │
│ > Help & Support                           │
│ > About SportX                             │
│ > Logout                                   │
│------------------------------------------  │
│ Home Explore (+) Community [More]          │
└────────────────────────────────────────────┘
```

#### S.20 - Saved  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Saved                                   │
│ Athletes|Coaches|Academies|Posts|Opps      │
│ +------------------------------+           │
│ | (o) Motera Academy   [bkmk]  |           │
│ | Cricket * 2.5 km  [ View ]   |           │
│ +------------------------------+           │
│ [ saved item ]                             │
└────────────────────────────────────────────┘
```

#### S.21 - My Activity  `P1`

```text
┌────────────────────────────────────────────┐
│ <  My activity                             │
│ Posts|Achievements|Events|Applied          │
│ [ post card ]                              │
│ [ achievement card ]                       │
│ [ application: Pending ]                   │
└────────────────────────────────────────────┘
```

#### S.22 - Settings & Privacy  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Settings                                │
│ Account                                    │
│  > Phone / Email                           │
│  > Change password                         │
│ Privacy                                    │
│  Profile visibility [Public v]             │
│  Who can message    [Connect v]            │
│ Notifications                              │
│  Push        [ON ]                         │
│ Language          English >                │
│ Blocked users           >                  │
│ Delete account (red)                       │
└────────────────────────────────────────────┘
```

#### S.23 - Blocked Users / Safety Centre  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Blocked users                           │
│ (o) Name One     [ Unblock ]               │
│ (o) Name Two     [ Unblock ]               │
│ My reports                                 │
│  Report #112 - Under review                │
└────────────────────────────────────────────┘
```

#### S.24 - Help & Support  `P0`

```text
┌────────────────────────────────────────────┐
│ <  Help & Support                          │
│ > FAQs                                     │
│ > Report a problem                         │
│ > Contact SportX                           │
│ [ Email support ]                          │
└────────────────────────────────────────────┘
```

#### S.25 - About SportX  `P0`

```text
┌────────────────────────────────────────────┐
│ <  About                                   │
│ > About us                                 │
│ > Terms & conditions                       │
│ > Privacy policy                           │
│ > Community guidelines                     │
│ v1.0.0                                     │
└────────────────────────────────────────────┘
```

#### S.26 - Report Sheet  `P0`

> Bottom sheet opened from any overflow menu.

```text
┌────────────────────────────────────────────┐
│ -------- handle --------                   │
│ Report this {post/user/listing}            │
│ Reason                                     │
│ ( ) Fake or misleading                     │
│ ( ) Stale / expired                        │
│ ( ) Inappropriate                          │
│ ( ) Suspicious activity                    │
│ Notes [_____________________]              │
│ [ Submit report ]                          │
│ -- confirmation --                         │
│ Thanks. We'll review it.                   │
└────────────────────────────────────────────┘
```

#### S.29 - Logout Confirm  `P0`

```text
┌────────────────────────────────────────────┐
│ +------------------------------+           │
│ | Logout?                      |           │
│ | You can log in anytime.      |           │
│ | [ Cancel ]    [ Logout ]     |           │
│ +------------------------------+           │
└────────────────────────────────────────────┘
```

#### S.30 - Share Sheet / Deep Link  `P1`

```text
┌────────────────────────────────────────────┐
│ ------- handle -------                     │
│ Share                                      │
│ (WhatsApp)(Copy link)(More)                │
│ sportx.in/p/akshay-pandya                  │
└────────────────────────────────────────────┘
```
