# Entity-Relationship Diagram — SportX India

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

Logical ERD (Mermaid) with entity and attribute descriptions. Physical schema (types, indexes, constraints) is specified in `Database-Design.md`.

> **Conventions:** PK = primary key, FK = foreign key. Multi-value attributes shown on wireframes (e.g. facilities, required documents) are modeled as JSON arrays on the parent for MVP simplicity — flagged per entity and in `Glossary-and-Assumptions.md` (AS-07). Polymorphic relationships (reports, saves, enquiries targets, feed authors, opportunity providers, verification requesters) use `*_type` + `*_id` pairs matching Laravel morph relations.
>
> **New-design deltas applied here:** `sponsor` role removed (→ `opportunities`); `scout` role added; OTP restored (P0); guardian consent added; social feed / network / messaging added; leaderboard engine added; profiles extended to 30 fields per role. Removed entities are marked **[REMOVED]**.

> **Platform integrations (2026-10):** `social_accounts` **[NEW]** (Google sign-in — `Google-Authentication.md`), `notifications` **[EXTENDED]** with FCM columns, and `user_device_tokens` **[HARDENED]** with a unique token + `last_seen_at` + `failure_count` (`FCM-Notification-System.md`). `users.google_id` is **REMOVED**.

---

## 1. ERD

```mermaid
erDiagram
    USERS ||--o| ATHLETE_PROFILES : "has (role=athlete)"
    USERS ||--o| COACH_PROFILES : "has (role=coach)"
    USERS ||--o| ACADEMIES : "owns (role=academy)"
    USERS ||--o| ORGANIZER_PROFILES : "has (role=organizer)"
    USERS ||--o| TALENT_SCOUT_PROFILES : "has (role=scout)"
    USERS ||--o| ADMIN_PROFILES : "has (role=admin)"
    USERS ||--o| GENERALIZED_PROFILES : "may own (directory profile)"

    USERS ||--o| GUARDIAN_CONSENTS : "minor guarded by"
    USERS ||--o{ VERIFICATION_REQUESTS : "requests verification"

    ATHLETE_PROFILES ||--o{ ATHLETE_SPORTS : "plays"
    SPORTS ||--o{ ATHLETE_SPORTS : "played in"
    POSITIONS ||--o{ ATHLETE_SPORTS : "position/event"
    ATHLETE_PROFILES ||--o{ ACHIEVEMENTS : "has"
    ATHLETE_PROFILES ||--o{ MEDIA_ITEMS : "owns"
    SPORTS ||--o{ SPORTS_VENUES : "played at"

    COACH_PROFILES ||--o{ COACH_SPORTS : "coaches"
    SPORTS ||--o{ COACH_SPORTS : "coached in"
    ACADEMIES ||--o{ ACADEMY_SPORTS : "offers"
    SPORTS ||--o{ ACADEMY_SPORTS : "offered in"
    ACADEMIES ||--o{ ACADEMY_COACHES : "employs"
    USERS ||--o{ ACADEMY_COACHES : "listed as coach"
    ACADEMIES ||--o{ FACILITIES : "operates"
    ACADEMIES ||--o{ ACADEMY_ATHLETE_INVITES : "invites"
    TALENT_SCOUT_PROFILES ||--o{ TALENT_SCOUT_SPORTS : "scouts in"
    SPORTS ||--o{ TALENT_SCOUT_SPORTS : "scouted in"

    COACH_PROFILES ||--o{ PROGRAMS : "owns (coach programs)"
    ACADEMIES ||--o{ PROGRAMS : "owns (academy programs)"
    USERS ||--o{ PROGRAMS : "publishes/enquires"

    TRIALS ||--o{ TRIAL_REGISTRATIONS : "has"
    ATHLETE_PROFILES ||--o{ TRIAL_REGISTRATIONS : "registers"
    TRIAL_REGISTRATIONS ||--o{ TRIAL_REGISTRATION_DOCUMENTS : "submits"
    ACADEMIES ||--o{ TRIALS : "posts (optional)"
    USERS ||--o{ TRIALS : "posts (organizer/academy owner)"

    TOURNAMENTS ||--o{ TOURNAMENT_CATEGORIES : "offers"
    AGE_GROUPS ||--o{ TOURNAMENT_CATEGORIES : "categorizes"
    TOURNAMENTS ||--o{ TOURNAMENT_REGISTRATIONS : "has"
    TOURNAMENT_CATEGORIES ||--o{ TOURNAMENT_REGISTRATIONS : "entered under"
    ATHLETE_PROFILES ||--o{ TOURNAMENT_REGISTRATIONS : "registers"
    TOURNAMENTS ||--o{ TOURNAMENT_RESULTS : "publishes"
    USERS ||--o{ TOURNAMENTS : "organizes"

    TRIALS ||--o{ EVENT_SCHEDULES : "scheduled (P1)"
    TOURNAMENTS ||--o{ EVENT_SCHEDULES : "scheduled (P1)"
    TRIALS ||--o{ EVENT_VIEWS : "viewed (P1)"
    TOURNAMENTS ||--o{ EVENT_VIEWS : "viewed (P1)"

    ACADEMIES ||--o{ OPPORTUNITIES : "posts"
    ORGANIZER_PROFILES ||--o{ OPPORTUNITIES : "posts"
    COACH_PROFILES ||--o{ OPPORTUNITIES : "posts"
    TALENT_SCOUT_PROFILES ||--o{ OPPORTUNITIES : "posts"
    USERS ||--o{ OPPORTUNITIES : "posts (admin schemes)"
    OPPORTUNITIES ||--o{ OPPORTUNITY_APPLICATIONS : "receives"
    ATHLETE_PROFILES ||--o{ OPPORTUNITY_APPLICATIONS : "applies"

    USERS ||--o{ POSTS : "authors"
    POSTS ||--o{ POST_LIKES : "liked"
    POSTS ||--o{ POST_COMMENTS : "commented"
    USERS ||--o{ POST_LIKES : "likes"
    USERS ||--o{ POST_COMMENTS : "writes"

    USERS ||--o{ FOLLOWS : "follows"
    USERS ||--o{ CONNECTION_REQUESTS : "requests/accepts"
    CONVERSATIONS ||--o{ CONVERSATION_PARTICIPANTS : "has"
    USERS ||--o{ CONVERSATION_PARTICIPANTS : "joins"
    CONVERSATIONS ||--o{ MESSAGES : "contains"
    USERS ||--o{ MESSAGES : "sends"
    USERS ||--o{ BLOCKS : "blocks"

    ENQUIRIES ||--o{ ENQUIRY_MESSAGES : "contains"
    ENQUIRIES }o--o| CONVERSATIONS : "links to chat thread"
    USERS ||--o{ ENQUIRY_MESSAGES : "sends"
    ATHLETE_PROFILES ||--o{ ENQUIRIES : "initiates"

    USERS ||--o{ SCOUT_SHORTLISTS : "scout curates"
    ATHLETE_PROFILES ||--o{ SCOUT_SHORTLISTS : "shortlisted"
    USERS ||--o{ OBSERVATIONS : "scout logs"
    ATHLETE_PROFILES ||--o{ OBSERVATIONS : "observed"
    USERS ||--o{ SCOUT_REPORTS : "scout writes (P1)"
    ATHLETE_PROFILES ||--o{ SCOUT_REPORTS : "reported on (P1)"

    LEADERBOARD_SEASONS ||--o{ LEADERBOARD_SCORES : "ranks"
    ATHLETE_PROFILES ||--o{ LEADERBOARD_SCORES : "scores"
    SPORTS ||--o{ LEADERBOARD_SCORES : "scored in"

    USERS ||--o{ REVIEWS : "rates (P1)"
    USERS ||--o{ BROADCASTS : "admin sends (P1)"
    USERS ||--o{ ANALYTICS_EVENTS : "generates"
    USERS ||--o{ SAVED_ITEMS : "saves"
    USERS ||--o{ LISTING_REPORTS : "files"
    USERS ||--o{ NOTIFICATIONS : "receives"
    USERS ||--o{ OTP_CODES : "verifies with"
    USERS ||--o{ USER_DEVICE_TOKENS : "registers devices for FCM push"
    USERS ||--o{ SOCIAL_ACCOUNTS : "links identities (Google)"

    SPORTS }o--o{ TRIALS : "classifies"
    SPORTS }o--o{ TOURNAMENTS : "classifies"
    SPORTS }o--o{ OPPORTUNITIES : "classifies"
    SPORTS }o--o{ PROGRAMS : "classifies"
    SPORTS }o--o{ POSTS : "tagged"
    SPORTS }o--o{ SPORTS_VENUES : "offered at"
    CITIES }o--o{ TRIALS : "located in"
    CITIES }o--o{ TOURNAMENTS : "located in"

    USERS {
        bigint id PK
        string role "athlete|coach|academy|organizer|scout|admin"
        string name
        string email UK "nullable — email signup"
        string phone UK "nullable — phone signup"
        timestamp email_verified_at "set by OTP verify (A.4)"
        timestamp phone_verified_at "set by OTP verify (A.4)"
        string password_hash "nullable — OTP/Google-only accounts"
        -- google_id REMOVED -> SOCIAL_ACCOUNTS join table (Google-Authentication.md §4)
        string status "pending|active|suspended|banned|deleted"
        string profile_visibility "public|connections|private"
        string who_can_message "everyone|connections|nobody"
        string who_can_connect "everyone|nobody"
        json social_links "nullable"
        string two_factor_secret "nullable, admin 2FA"
    }

    OTP_CODES {
        bigint id PK
        bigint user_id FK "nullable (pre-registration)"
        string purpose "signup|login|reset_password|guardian_consent|verify_contact"
        string channel "email|phone"
        string destination
        string code_hash
        datetime expires_at
        int attempts "default 0, max 5"
        datetime resend_available_at "60s cooldown"
        timestamp consumed_at
    }

    SOCIAL_ACCOUNTS {
        bigint id PK
        bigint user_id FK "-> USERS, cascadeOnDelete"
        string provider "google (string, not enum — extensible)"
        string provider_user_id "UK with provider — Google `sub` claim"
        string email "nullable — snapshot at link time"
        string name "nullable"
        string avatar_url "nullable"
        text access_token "nullable — ENCRYPTED at rest"
        text refresh_token "nullable — ENCRYPTED at rest"
        datetime token_expires_at "nullable"
        string scopes "nullable"
    }

    GUARDIAN_CONSENTS {
        bigint id PK
        bigint athlete_user_id FK
        string guardian_name
        string guardian_phone
        string relationship "parent|guardian|sibling|other"
        string consent_status "pending|verified|revoked"
        timestamp verified_at
        boolean allow_messages
        boolean allow_public_profile
        string leaderboard_name_mode "full|initials|hidden"
    }

    VERIFICATION_REQUESTS {
        bigint id PK
        bigint requester_user_id FK
        string requestable_type "morph: athlete/coach/academy/organizer/scout profile"
        bigint requestable_id
        bigint id_proof_media_id FK "private"
        bigint org_proof_media_id FK "private"
        text note
        string status "pending|approved|rejected"
        bigint reviewed_by FK "admin"
        text review_reason
    }

    ATHLETE_PROFILES {
        bigint id PK
        bigint user_id FK
        string full_name "1 ■ Mandatory"
        date date_of_birth "6 ■ Mandatory"
        string gender "male|female|other|prefer_not_to_say"
        bigint age_group_id FK "6 ■ Mandatory"
        string skill_level "7 ■ Mandatory"
        bigint city_id FK "5 ■ Mandatory"
        text bio "8 ■ Mandatory"
        bigint photo_media_id FK "2 ■ Mandatory"
        bigint academy_id FK "9 🟠"
        string team_name "9 🟠"
        bigint coach_id FK "10 🟠"
        json competition_history "12 🟠"
        json performance_stats "13 🟠"
        string personal_best "14 🟠"
        int experience_years "16 🟠"
        string playing_hand "18 🟠"
        smallint height_cm "19 🟠"
        smallint weight_kg "20 🟢"
        json goals "22 🟠"
        json open_to "23 🟠"
        json availability "24 🟠"
        boolean sponsorship_interest "29 🟢"
        json social_links "30 🟢"
        string verification_status "28 🟢"
        string listing_status
        int profile_completeness
    }

    ATHLETE_SPORTS {
        bigint id PK
        bigint athlete_id FK
        bigint sport_id FK "3 primary / 27 additional"
        bigint position_id FK "4 position/event"
        string playing_role "4 e.g. Batsman (Right Hand)"
        string level "7 per-sport"
        int experience_years "16 per-sport"
        boolean is_primary "3 primary flag"
    }

    ACHIEVEMENTS {
        bigint id PK
        string owner_type "morph: athlete_profile|coach_profile"
        bigint owner_id
        string title "11"
        string achievement_type "tournament|award|selection|record|certification|other"
        bigint sport_id FK
        string level "e.g. State/National"
        smallint year
        text description
        bigint certificate_media_id FK "15 certificate"
    }

    COACH_PROFILES {
        bigint id PK
        bigint user_id FK
        string full_name "1 ■ Mandatory"
        bigint photo_media_id FK "2 ■ Mandatory"
        bigint city_id FK "6 ■ Mandatory"
        string coaching_level "grassroots|youth|state|professional — 5 ■ Mandatory"
        text bio "7 ■ Mandatory"
        int experience_years "8 ■ Mandatory"
        json specializations "4 ■ Mandatory"
        string coaching_role "9 🟠"
        bigint academy_id FK "10 🟠"
        string organization_name "10 🟠"
        json certifications "11 🟠"
        json teams_coached "12 🟠"
        json age_groups_coached "13 🟠"
        json levels_coached "14 🟠"
        json expertise "15 🟠"
        json services "17 🟠"
        json availability "18 🟠"
        json training_locations "19 🟠"
        json coaching_achievements "20 🟠"
        string athletes_coached_summary "21 🟠"
        string fee_structure "24 🟢"
        json open_to "25 🟢"
        json social_links "30 🟢"
        string contact_number
        string email
        string verification_status "29 🟢"
        string listing_status
        int profile_completeness
    }

    COACH_SPORTS {
        bigint id PK
        bigint coach_id FK
        bigint sport_id FK "3 primary sport(s)"
        boolean is_primary
    }

    ACADEMIES {
        bigint id PK
        bigint owner_user_id FK
        string name "1 ■ Mandatory"
        bigint logo_media_id FK "2 ■ Mandatory"
        bigint cover_media_id FK "2 ■ Mandatory"
        string academy_type "private|club|school|college|government — 4 ■ Mandatory"
        bigint city_id FK "5 ■ Mandatory"
        text description "6 ■ Mandatory"
        json training_offered "7 ■ Mandatory"
        json age_groups "8 ■ Mandatory"
        string address "14 🟠"
        string google_maps_url "14 🟠"
        smallint year_established "11 🟠"
        json facilities_summary "12 🟠 (mirrors facilities table)"
        string training_schedule "13 🟠"
        string fee_range "15 🟠"
        text admission_process "16 🟠"
        json achievements "17 🟠"
        string athletes_developed "18 🟠"
        json competitions "19 🟠"
        string head_name "26 🟢"
        string head_designation "26 🟢"
        string contact_number "23 🟠"
        string website "24 🟢"
        json social_links "24 🟢"
        boolean verification_badge "22 🟠"
        string verification_status "22 🟠"
        string listing_status
        int profile_completeness
    }

    ACADEMY_SPORTS {
        bigint id PK
        bigint academy_id FK
        bigint sport_id FK
        boolean is_primary
    }

    ACADEMY_COACHES {
        bigint id PK
        bigint academy_id FK
        bigint coach_user_id FK "nullable"
        string display_name "fallback"
    }

    FACILITIES {
        bigint id PK
        bigint academy_id FK
        string name
        string facility_type "ground|indoor|gym|court|pool|other"
        string size_spec "size / lanes"
        json amenities
        json media
    }

    ORGANIZER_PROFILES {
        bigint id PK
        bigint user_id FK
        string organization_name "1 ■ Mandatory"
        bigint logo_media_id FK "2 ■ Mandatory"
        bigint cover_media_id FK "2 ■ Mandatory"
        string org_type "event_company|individual|club|college|federation|ngo|other — 3 ■ Mandatory"
        bigint city_id FK "6 ■ Mandatory"
        text description "7 ■ Mandatory"
        json event_types "5 ■ Mandatory"
        int experience_years "8 🟠"
        json events_history "9 🟠"
        json competition_levels "10 🟠"
        string participants_summary "17 🟠"
        json venue_amenities "18 🟠"
        json achievements "21 🟠"
        json partners "25 🟢"
        json sponsors "26 🟢"
        string contact_number "22 🟠"
        string website "29 🟢"
        json social_links "29 🟢"
        string verification_status "23 🟠"
        string listing_status
        int profile_completeness
    }

    ORGANIZER_SPORTS {
        bigint id PK
        bigint organizer_id FK
        bigint sport_id FK
        boolean is_primary
    }

    TALENT_SCOUT_PROFILES {
        bigint id PK
        bigint user_id FK
        string full_name "1 ■ Mandatory"
        bigint photo_media_id FK "2 ■ Mandatory"
        bigint cover_media_id FK "2 ■ Mandatory"
        string scout_type "independent|club|academy|federation — 3 ■ Mandatory"
        json specializations "5 ■ Mandatory"
        bigint city_id FK "6 ■ Mandatory"
        text bio "7 ■ Mandatory"
        int experience_years "8 🟠"
        string scouting_level "grassroots..professional — 9 🟠"
        json age_groups_scouted "10 🟠"
        string organization_name "11 🟠"
        json previous_organizations "12 🟠"
        json certifications "13 🟠"
        json scouting_methods "14 🟠"
        json evaluation_areas "15 🟠"
        string athletes_scouted "16 🟠"
        text discoveries "17 🟠"
        json scouting_achievements "18 🟠"
        json regions "19 🟠"
        json events_covered "20 🟠"
        json services "21 🟠"
        json recruitment_focus "22 🟠"
        json affiliations "27 🟢"
        string availability "available|limited|unavailable — 28 🟢"
        string website "29 🟢"
        json social_links "29 🟢"
        string verification_status "26 🟢"
        string listing_status
        int profile_completeness
    }

    TALENT_SCOUT_SPORTS {
        bigint id PK
        bigint scout_id FK
        bigint sport_id FK
        boolean is_primary
    }

    GENERALIZED_PROFILES {
        bigint id PK
        bigint user_id FK "nullable — directory profile"
        string category "1 ■ Mandatory (NGO, doctor…)"
        string name "2 ■ Mandatory"
        bigint logo_media_id FK "3 ■ Mandatory"
        bigint cover_media_id FK "3 ■ Mandatory"
        text description "4 ■ Mandatory"
        bigint city_id FK "8 ■ Mandatory"
        string specialization "6 ■ Mandatory"
        string contact_number "11 ■ Mandatory"
        string email "11 ■ Mandatory"
        json services "18 ■ Mandatory"
        json target_audience "7 🟠"
        string service_area "local..international — 9 🟠"
        json products "19 🟠"
        json programs "20 🟠"
        json certifications "22 🟠"
        text professional_experience "23 🟠"
        json achievements "24 🟠"
        json documents "27 🟢 (private)"
        string service_mode "online|offline|both|home_visit — 29 🟢"
        json partnerships "30 🟢"
        string pricing "display-only"
        string verification_status "26 🟠"
        string listing_status
        int profile_completeness
    }

    PROGRAMS {
        bigint id PK
        string owner_type "morph: coach_profile|academy"
        bigint owner_id
        bigint sport_id FK
        string title
        string age_group
        string duration
        string mode "online|offline|hybrid"
        string price "display-only"
        string schedule
        text about
        string status "draft|active|past|removed"
    }

    SPORTS {
        bigint id PK
        string name UK
        boolean is_active
    }

    CITIES {
        bigint id PK
        string name
        string state
        boolean is_active
    }

    AGE_GROUPS {
        bigint id PK
        string name UK "e.g. Under-14"
        boolean is_active
    }

    POSITIONS {
        bigint id PK
        bigint sport_id FK "nullable"
        string name "e.g. Batsman"
        boolean is_active
    }

    TRIALS {
        bigint id PK
        bigint posted_by_user_id FK
        bigint academy_id FK "nullable"
        string name
        string organization_name "■ Mandatory"
        bigint sport_id FK
        bigint position_id FK "position/event"
        timestamp event_datetime
        string venue "■ Mandatory"
        string google_maps_url "■ Mandatory"
        bigint city_id FK
        string contact_number "■ Mandatory"
        timestamp registration_deadline "■ Mandatory"
        text eligibility "Optional"
        json required_documents "Optional"
        smallint vacancies "Optional"
        text benefits "Optional"
        string entry_fee "Optional — display only"
        string status
        timestamp expires_at
    }

    TOURNAMENTS {
        bigint id PK
        bigint organizer_id FK
        bigint sport_id FK "■ Mandatory"
        string name "■ Mandatory"
        string organizer_name "■ Mandatory"
        string format
        string event_type "tournament|championship|league|camp|workshop|sports_meet|marathon|other"
        date start_date "■ Mandatory"
        date end_date "■ Mandatory"
        date registration_deadline "■ Mandatory"
        string venue "■ Mandatory"
        string google_maps_url "■ Mandatory"
        bigint city_id FK
        string entry_fee "■ Mandatory — display only"
        string contact_number "■ Mandatory"
        string registration_link "■ Mandatory (external)"
        string prize_pool "Optional"
        text rules "Optional"
        bigint banner_media_id FK "Optional"
        string gender "Optional"
        string status
        timestamp expires_at
    }

    TOURNAMENT_CATEGORIES {
        bigint id PK
        bigint tournament_id FK
        bigint age_group_id FK
        int capacity
        boolean waitlist_enabled
    }

    TOURNAMENT_REGISTRATIONS {
        bigint id PK
        bigint tournament_id FK
        bigint category_id FK
        bigint athlete_id FK
        string participation_type "individual|team"
        string team_name "nullable"
        string payment_status "manual flag: pending|paid"
        string status "pending|confirmed|waitlisted|cancelled"
    }

    TRIAL_REGISTRATIONS {
        bigint id PK
        bigint trial_id FK
        bigint athlete_id FK
        string registration_ref
        string document_status "pending|submitted"
        string verification_status "pending|verified|rejected"
        boolean reminder_enabled
    }

    EVENT_SCHEDULES {
        bigint id PK
        string schedulable_type "morph: trial|tournament (P1)"
        bigint schedulable_id
        date day
        string slot_label
        time start_time
        time end_time
        string venue
    }

    EVENT_VIEWS {
        bigint id PK
        string viewable_type "morph: trial|tournament (P1)"
        bigint viewable_id
        bigint user_id FK "nullable"
        string source
    }

    OPPORTUNITIES {
        bigint id PK
        string provider_type "morph: academy|organizer_profile|coach_profile|talent_scout_profile|user(admin)"
        bigint provider_id
        string type "scholarship|sponsorship|tryout|camp"
        string title
        bigint sport_id FK
        string organization_name
        text eligibility
        text benefits
        decimal amount "display/sort only"
        string location
        date deadline
        json documents_required
        text description
        bigint logo_media_id FK
        boolean posted_by_admin "legacy admin schemes"
        string status
        timestamp expires_at
    }

    OPPORTUNITY_APPLICATIONS {
        bigint id PK
        bigint opportunity_id FK
        bigint athlete_id FK
        text pitch
        json documents
        json profile_snapshot "captured at apply time"
        string status "submitted|shortlisted|rejected|accepted"
        bigint reviewed_by FK "nullable"
        text review_note "P1"
    }

    POSTS {
        bigint id PK
        bigint author_user_id FK
        text body
        json media
        json hashtags
        bigint sport_id FK
        string audience "public|followers|connections"
        int likes_count
        int comments_count
        string status "published|removed"
    }

    POST_LIKES {
        bigint id PK
        bigint post_id FK
        bigint user_id FK
    }

    POST_COMMENTS {
        bigint id PK
        bigint post_id FK
        bigint user_id FK
        bigint parent_id FK "nullable"
        text body
        string status "published|removed"
    }

    FOLLOWS {
        bigint id PK
        bigint follower_user_id FK
        string followable_type "morph: athlete/coach/academy/organizer/scout profile"
        bigint followable_id
    }

    CONNECTION_REQUESTS {
        bigint id PK
        bigint requester_user_id FK
        bigint addressee_user_id FK
        string purpose "scout contact purpose (SC.13)"
        text message
        string status "pending|accepted|declined|cancelled|removed"
        timestamp responded_at
    }

    CONVERSATIONS {
        bigint id PK
        timestamp last_message_at
    }

    CONVERSATION_PARTICIPANTS {
        bigint id PK
        bigint conversation_id FK
        bigint user_id FK
        timestamp last_read_at
    }

    MESSAGES {
        bigint id PK
        bigint conversation_id FK
        bigint sender_user_id FK
        text body "text P0"
        json attachments "media P1"
        timestamp read_at
    }

    BLOCKS {
        bigint id PK
        bigint blocker_user_id FK
        bigint blocked_user_id FK
    }

    SCOUT_SHORTLISTS {
        bigint id PK
        bigint scout_user_id FK
        bigint athlete_id FK
        string status "under_review|good|high|final"
        json tags
        text notes "private"
    }

    OBSERVATIONS {
        bigint id PK
        bigint scout_user_id FK
        bigint athlete_id FK
        int rating "nullable"
        text note
        json media
    }

    SCOUT_REPORTS {
        bigint id PK
        bigint scout_user_id FK
        bigint athlete_id FK
        json scores "5-dimension (P1)"
        string conclusion "recommend|watch|pass"
        text notes
        string status "draft|final"
    }

    REVIEWS {
        bigint id PK
        bigint rater_user_id FK
        string rateable_type "morph: coach_profile|academy|organizer_profile|program|facility (P1)"
        bigint rateable_id
        int rating "1–5"
        text body
        boolean interaction_verified "gating"
        string status "published|hidden"
    }

    LEADERBOARD_SEASONS {
        bigint id PK
        string name
        date starts_at
        date ends_at
        boolean is_active
    }

    LEADERBOARD_SCORES {
        bigint id PK
        bigint season_id FK
        bigint athlete_id FK
        bigint sport_id FK
        int points
        json breakdown "source of points"
    }

    LEADERBOARD_CONFIG {
        bigint id PK
        string key UK "weight / season length (P1)"
        json value
        bigint updated_by FK
    }

    BROADCASTS {
        bigint id PK
        bigint sender_admin_id FK
        json audience "role/status/city filters"
        string title
        text body
        timestamp scheduled_at
        timestamp sent_at
        string status "draft|scheduled|sent|cancelled"
    }

    ANALYTICS_EVENTS {
        bigint id PK
        bigint user_id FK "nullable"
        string event "funnel event"
        json context
    }

    ACADEMY_ATHLETE_INVITES {
        bigint id PK
        bigint academy_id FK
        bigint invited_user_id FK "nullable (P1)"
        string invited_name
        string invited_phone
        string status "pending|accepted|declined"
    }

    ENQUIRIES {
        bigint id PK
        bigint athlete_id FK
        string subject_type "morph: coach_profile|academy|organisation|program|opportunity|facility"
        bigint subject_id
        datetime preferred_datetime "nullable"
        bigint conversation_id FK "nullable — chat thread link"
    }

    ENQUIRY_MESSAGES {
        bigint id PK
        bigint enquiry_id FK
        bigint sender_user_id FK
        text body
        json media
        timestamp read_at
    }

    SAVED_ITEMS {
        bigint id PK
        bigint user_id FK
        string item_type "morph: academy|coach_profile|trial|tournament|opportunity|program|facility|post|event|generalized_profile"
        bigint item_id
    }

    LISTING_REPORTS {
        bigint id PK
        bigint reporter_user_id FK
        string reportable_type "morph: user|post|academy|coach_profile|organizer_profile|trial|tournament|opportunity|program|facility|generalized_profile"
        bigint reportable_id
        string reason "fake|outdated|inappropriate|misleading|spam|other"
        text comment
        string status "pending|approved|edited|removed|warned|suspended"
        bigint resolved_by FK "admin, nullable"
    }

    NOTIFICATIONS {
        bigint id PK
        bigint user_id FK
        string type "varchar(40) — widened from enum; see FCM doc §2"
        string channel "in_app|push|email|sms"
        string title
        string body
        string category "nullable — client routing key"
        string image_url "nullable — rich push image"
        string priority "normal|high"
        string notifiable_type "nullable polymorphic link"
        bigint notifiable_id
        string action_url "nullable — deep link"
        json metadata "nullable"
        timestamp read_at
        datetime pushed_at "nullable — FCM accepted"
        string push_status "queued|sent|partial|failed|no_devices"
    }

    USER_DEVICE_TOKENS {
        bigint id PK
        bigint user_id FK "-> USERS, cascadeOnDelete"
        string token UK "FCM registration token — UNIQUE per app install"
        string device_type "ios|android|web"
        string device_id "nullable"
        boolean is_active "default true"
        datetime last_seen_at "nullable — TTL pruning"
        int failure_count "default 0 — transient failures before retirement"
    }

    EXPIRY_RULES {
        bigint id PK
        string content_type "trial|tournament|opportunity|program|facility"
        string trigger_field "event_date|final_date|listed_deadline"
        int days_after
        boolean is_active
    }

    EXPIRY_EVENTS {
        bigint id PK
        string content_type
        bigint content_id
        datetime scheduled_at
        datetime executed_at
        string status "pending|expired|overridden|restored"
        bigint overridden_by FK "admin, nullable"
    }

    SPORTS_VENUES {
        bigint id PK
        bigint owner_user_id FK "nullable — provider CRUD (P1)"
        string name "■ Mandatory"
        bigint sport_id FK "■ Mandatory"
        string address "■ Mandatory"
        string google_maps_url "■ Mandatory"
        string contact_number "■ Mandatory"
        bigint city_id FK
        json photos "Optional"
        boolean booking_available "Optional"
        string pricing "Optional"
        json facilities "Optional"
        string working_hours "Optional"
        string listing_status
    }
```

> **Removed entities [REMOVED]:** `sponsor_profiles`, `sponsorships`, `sponsorship_applications`, `scholarships`, and `shortlist_entries` (sponsor-owned). They collapse into `opportunities` + `opportunity_applications`; the sponsor-owned shortlist becomes the scout-owned `scout_shortlists`. Additionally **`users.google_id`** is removed (superseded by `social_accounts`) and the legacy **`device_tokens`** table is scheduled for removal (**AS-69**). Migration actions are listed in `Database-Design.md` §16.

---

## 2. Entity Descriptions

### Identity, auth & roles

| Entity | Description | Key attributes |
|---|---|---|
| `users` | One account per person/organization; a single `role` column determines which profile table applies (`athlete`, `coach`, `academy`, `organizer`, `scout`, `admin`). **`sponsor` REMOVED, `scout` ADDED.** **Assumption (AS-01):** one role per account — a person who is both coach and athlete needs two accounts. Profile privacy/messaging prefs live here. `google_id` **REMOVED** → `social_accounts`. `notification_prefs` (json) holds per-channel/category push & email preferences. | role, name, email (nullable unique), phone (nullable unique), password_hash (nullable), status, profile_visibility, who_can_message, who_can_connect, social_links, notification_prefs |
| `otp_codes` | **P0 (D1).** Time-boxed 6-digit codes for sign-up/login/reset **and** guardian consent, over **email or phone** channels. Stored hashed, attempt-counted, single-use, 60s resend cooldown. | purpose, channel, destination, code_hash, expires_at, attempts, resend_available_at, consumed_at |
| `social_accounts` | **NEW.** Third-party identities for "Continue with Google" (A.3 / D9 CLOSED). Replaces `users.google_id`; a join table so Apple Sign In needs no migration. Keyed on Google's stable `sub` claim, **not** email — consumer Gmail addresses are not unique. OAuth tokens encrypted at rest and excluded from all API responses. | provider, provider_user_id (UK with provider), email, name, avatar_url, access_token (encrypted), refresh_token (encrypted) |
| `guardian_consents` | **NEW.** Guardian consent + parent controls for minors (DOB < 18) — mandatory before profile activation (A.9/AT.10). Closes AS-34. | guardian_name, guardian_phone, relationship, consent_status, allow_messages, allow_public_profile, leaderboard_name_mode |
| `verification_requests` | **NEW.** Request → admin queue (AD.4) → blue-check badge. Polymorphic requester over the profile tables. | requestable_type/id, id_proof_media_id, org_proof_media_id, status, reviewed_by, review_reason |
| `admin_profiles` | Marks a user as admin; carries `two_factor_secret` for the admin portal 2FA (AD.1). | two_factor_secret, is_super_admin |
| `positions` | **NEW master data.** Sport-scoped positions/events powering the athlete filter (S.4) and mandatory "Position/Event" field. | sport_id, name |

### Athlete side

| Entity | Description | Key attributes |
|---|---|---|
| `athlete_profiles` | The public sports profile seen across the app. **Extended to the 30-field set.** | age_group_id, skill_level, city_id, bio, photo, open_to, availability, verification_status |
| `athlete_sports` | Join table for multi-select sports, now carrying per-sport detail. | athlete_id, sport_id, position_id, playing_role, level, experience_years, is_primary |
| `achievements` | **Typed records** (not free text): title, type, sport, level, year, certificate — owner morph covers athlete (field 11/15) and coach (field 20). | owner_type/id, title, achievement_type, sport_id, year, certificate_media_id |
| `media_items` | Photos/videos in galleries and posts — polymorphic over profile/academy/event/post/program/facility owners. | owner_type+owner_id, media_type, path, caption, sport_id, sort_order |

### Provider profiles & listings

| Entity | Description | Key attributes |
|---|---|---|
| `coach_profiles` | Coach public listing. **Extended to the 30-field set.** | full_name, specializations, coaching_level, experience_years, city_id, services, availability, fee_structure, listing_status |
| `coach_sports` | Join: coach ↔ sports offered. | coach_id, sport_id, is_primary |
| `academies` | Academy listing. **Extended to the 30-field set.** Facilities now a dedicated table (JSON mirror kept as summary). | owner_user_id, name, academy_type, training_offered, age_groups, city_id, contact, listing_status |
| `academy_sports` | Join: academy ↔ sports offered. | academy_id, sport_id |
| `academy_coaches` | Coaches displayed on an academy detail page. **Assumption (AS-12):** links to a coach user account, with optional free-text name fallback. | academy_id, coach_user_id (nullable), display_name |
| `facilities` | **NEW.** Academy facilities (ground/indoor/gym/court/pool) replacing the `academies.facilities` JSON column (AC.7/AC.8/D.13). | academy_id, name, facility_type, size_spec, amenities, media |
| `organizer_profiles` | Organization identity + verification status. **Extended to the 30-field set.** | organization_name, org_type, event_types, city_id, verification_status |
| `organizer_sports` | Join: organizer ↔ sports offered. | organizer_id, sport_id |
| `talent_scout_profiles` | **NEW role profile (scout).** Full 30-field scout profile. Canonical name per `Database-Design.md`. | scout_type, specializations, city_id, scouting_level, regions, recruitment_focus, availability |
| `talent_scout_sports` | Join: scout ↔ sports focus. | scout_id, sport_id, is_primary |
| `generalized_profiles` | **NEW.** Directory profiles for non-login categories (NGO, doctor, sports store, brand, federation…) — 30-field set, category-driven. | category, name, specialization, city_id, services, service_area, verification_status |
| `programs` | **NEW.** Training program listings owned by a coach or academy (CO.4/CO.5/AC.4/D.11). | owner_type/id, sport_id, title, duration, mode, price, schedule, status |

### Master data

| Entity | Description |
|---|---|
| `sports`, `cities`, `age_groups`, `positions` | Admin-managed lists (AD.10–12) referenced by every listing and filter. `is_active` enables soft removal without breaking historical rows. |

### Time-boxed content & events

| Entity | Description | Key attributes |
|---|---|---|
| `trials` | Posted by an academy (academy_id set) **or** an organizer (academy_id null, posted_by = organizer user); now carries a `position_id`. | sport_id, position_id, event_datetime, venue, city_id, eligibility, entry_fee (display), required_documents (JSON), status, expires_at |
| `tournaments` | Organizer-owned events (O5); `event_type` covers tournament/championship/league/camp/workshop/sports_meet/marathon. | format, event_type, start/end dates, venue, entry_fee, prize_pool, status, expires_at |
| `tournament_categories` | Age-group categories with capacity and waitlist toggle (O7/O8). Capacity lives here, not on the tournament. | age_group_id, capacity, waitlist_enabled |
| `event_schedules` | **NEW [P1].** Per-event timetable slots (OR.9) — polymorphic over trial/tournament. | day, slot_label, start_time, end_time, venue |
| `event_views` | **NEW [P1].** View log feeding event analytics (OR.12). | viewable_type/id, user_id, source |
| `sports_venues` | Discoverable physical sports venues (stadia, grounds, courts); gains `owner_user_id` for provider CRUD (OR.13, P1). | name, sport_id, address, google_maps_url, booking_available, pricing, facilities, owner_user_id |
| ~~`scholarships`~~ | **[REMOVED]** → `opportunities` (type='scholarship'), admin schemes retained via `posted_by_admin`. | — |
| ~~`sponsorships`~~ | **[REMOVED]** → `opportunities` (type='sponsorship'), legacy provider preserved. | — |

### Opportunities (unified)

| Entity | Description | Key attributes |
|---|---|---|
| `opportunities` | **NEW — biggest structural change (D2/D3).** Scholarship / sponsorship / tryout / camp collapse into one provider-posted table. Posted by academy/organizer/coach/scout (athlete P1); browsed by all. | provider_type/id, type, title, sport_id, eligibility, benefits, amount, deadline, status, posted_by_admin |
| `opportunity_applications` | **NEW.** Athlete in-app applications with pitch + documents + profile snapshot; status machine and P1 provider review. | opportunity_id, athlete_id, pitch, status, review_note |

### Social feed

| Entity | Description | Key attributes |
|---|---|---|
| `posts` | **NEW (P0).** Feed posts with media/hashtags/sport tag/audience and denormalized counts (S.9/S.27). | author_user_id, body, media, hashtags, sport_id, audience, likes_count, comments_count |
| `post_likes` | **NEW.** One row per user per post. | post_id, user_id (unique pair) |
| `post_comments` | **NEW.** Comment tree (self-referential parent_id). | post_id, user_id, parent_id, body |

### Network & messaging

| Entity | Description | Key attributes |
|---|---|---|
| `follows` | **NEW.** One-way follows over the profile morph set. | follower_user_id, followable_type/id |
| `connection_requests` | **NEW.** Mutual request→accept graph; gates chat. Used by scouts to contact athletes (guardian-routed for minors, SC.13). | requester_user_id, addressee_user_id, purpose, status, responded_at |
| `conversations` + `conversation_participants` + `messages` | **NEW (P0).** 1:1 chat (group-ready). Enquiry threads interoperate via `enquiries.conversation_id`. | last_message_at; user_id/last_read_at; body (text P0), attachments (P1) |
| `blocks` | **NEW.** Blocked pairs; hides content both ways and blocks chat (S.23). | blocker_user_id, blocked_user_id (unique pair) |

### Scouting

| Entity | Description | Key attributes |
|---|---|---|
| `scout_shortlists` | **CHANGED.** Scout pipeline with status tabs, tags and private notes (SC.5/SC.6). Replaces sponsor `shortlist_entries`. | scout_user_id, athlete_id, status (under_review/good/high/final), tags, notes |
| `observations` | **NEW.** Quick scout note + rating + optional media (SC.10). | scout_user_id, athlete_id, rating, note, media |
| `scout_reports` | **NEW [P1].** 5-dimension assessment + conclusion (SC.8/SC.9). | scores (JSON), conclusion, notes, status |

### Transactions / interactions

| Entity | Description | Key attributes |
|---|---|---|
| `trial_registrations` | One row per athlete per trial (unique pair). `registration_ref` is the human ID on the confirmation screen (A15). | document_status, verification_status (set via AC7), reminder_enabled |
| `trial_registration_documents` | Uploaded documents per registration; `document_type` matches the trial's required_documents list. | document_type, media_id, status |
| `tournament_registrations` | Per category; unique (tournament, category, athlete). Holds the **manual** payment_status flag from O7 — no payment records exist. | participation_type, team_name, payment_status, status (incl. waitlisted) |
| `enquiries` + `enquiry_messages` | Thread + messages; now linked to a `conversations` row. `subject_type/subject_id` targets a coach profile, academy, organisation, program, opportunity or facility. | preferred_datetime, conversation_id; messages keyed by sender |
| `saved_items` | Bookmarks polymorphic over academy/coach/trial/tournament/opportunity/program/facility/post/event/generalized profile. | unique (user, item_type, item_id) |
| `listing_reports` | Reports polymorphic over users, posts and listings; `status` + `resolved_by` capture moderation outcome (AD.7). Reason enum extended (misleading/spam). | reason, comment, status |
| `notifications` | **CHANGED (FCM).** All alerts; polymorphic link back to the source record for deep-linking. The row is the **source of truth** — the in-app inbox reads it and the FCM payload is derived from it, so the tray and the centre cannot disagree. `type` widened from a 3-value enum to `varchar(40)`. | type, channel, category, priority, image_url, action_url, metadata, read_at, pushed_at, push_status |
| `user_device_tokens` | **CHANGED (FCM).** FCM registration tokens, one row per installed app instance. `token` is **UNIQUE** — FCM tokens identify exactly one installation, and duplicates would let one user's device receive another user's notifications after a reinstall. Tokens are retired on `UNREGISTERED`, after repeated transient failures, on logout, or after `DEVICE_TOKEN_TTL_DAYS` of inactivity. | user_id, token (UK), device_type, device_id, is_active, last_seen_at, failure_count |
| `reviews` | **NEW [P1].** Ratings (1–5) gated to verified interactions; polymorphic rateable (coach/academy/organizer/program/facility). | rating, body, interaction_verified, status |
| `broadcasts` | **NEW [P1].** Admin broadcast with audience filter, schedule and FCM fan-out job (AD.12). | audience, title, body, scheduled_at, status |
| `analytics_events` | **NEW.** Product/funnel event log (signup, registration, enquiry, shortlist); also feeds event analytics (OR.12). | user_id, event, context |

### Leaderboard

| Entity | Description |
|---|---|
| `leaderboard_seasons` | **NEW (P0).** Season windows with reset job. |
| `leaderboard_scores` | **NEW (P0).** Points per athlete per sport per season, with breakdown; drives `GET /leaderboard` + home strip. Minors anonymized per guardian consent. |
| `leaderboard_config` | **NEW [P1].** Admin weights + season length (AD.11). |

### Academy ops

| Entity | Description | Key attributes |
|---|---|---|
| `academy_athlete_invites` | **NEW [P1].** Academy invites athletes by name/phone; accept/decline sets `academy_id` (AC.5/AC.10). | academy_id, invited_user_id/name/phone, status |

### Expiry system

| Entity | Description |
|---|---|
| `expiry_rules` | One active row per content_type (AD.8): which date field triggers expiry and the day offset. Content set now trial/tournament/**opportunity**/program/facility. |
| `expiry_events` | Scheduled/executed expirations per listing, with pending/expired/overridden/restored status driving the AD.9 monitor tabs and admin override/restore actions. |

---

## 3. Relationship Notes

1. **Trials have two possible owners.** `trials.academy_id` is set for academy-posted trials; for organizer-posted trials it's NULL and ownership flows through `posted_by_user_id`. Authorization checks both.
2. **Reports/saves/enquiries use polymorphic targets** so one reporting/bookmark/enquiry subsystem serves all listing types (now also `post`, `user`, `opportunity`, `program`, `facility`). Enquiries interoperate with the new `conversations`/`messages` chat by carrying `conversation_id`.
3. **Verification documents** uploaded during onboarding/verification are stored as `media_items` owned by the profile entity, referenced by `verification_requests`; private documents use signed URLs.
4. **Capacity enforcement** is computed: `tournament_registrations` count per `category_id` vs `tournament_categories.capacity`; waitlisted rows do not consume capacity.
5. **No payments tables exist by design** — only the manual `payment_status` flag on `tournament_registrations`; `opportunities.amount` and all fees are display-only.
6. **`sports_venues`** is a discoverable listing type; it joins `saved_items`, `listing_reports`, universal search, and admin content management, and gains owner-scoped CRUD for organizers (P1).
7. **Tournament `registration_link`** is mandatory per the PDF — organizers can provide an external registration link alongside the in-app registration flow (AS-48: both paths coexist).
8. **Unified opportunities** replace scholarships/sponsorships. A provider morph (academy/organizer/coach/scout/admin) posts rows; athletes apply in-app via `opportunity_applications` and track status (AT.8). Legacy admin-exclusive schemes are kept via `posted_by_admin`.
9. **Social & messaging adds a graph layer.** `follows` (one-way), `connection_requests` (mutual, accept unlocks chat), `conversations`+`messages` (1:1 P0), and `blocks`. Minors may only chat when a guardian-allowed connection exists.
10. **Leaderboard points** are derived (verified achievements + completion + activity) and stored in `leaderboard_scores` per season/sport; minors are anonymized per `guardian_consents.leaderboard_name_mode`.
11. **Removed sponsor artifacts** (`sponsor_profiles`, `sponsorships`, `sponsorship_applications`, `scholarships`, sponsor `shortlist_entries`) are migrated into `opportunities`/`opportunity_applications` and `scout_shortlists`; see `Database-Design.md` §16 for migration actions.
