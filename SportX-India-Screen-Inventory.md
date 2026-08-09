# SportX India — Detailed Screen Inventory

This document maps every feature from the **MVP Overview** to the actual screens needed to build it. Each role's screens are listed in the order a user would typically encounter them, with purpose, key UI elements, and the feature(s) it supports.

---

## Shared / Cross-Role Screens

These exist once but are used across multiple roles.

| # | Screen | Purpose | Key Elements | Supports Feature |
|---|---|---|---|---|
| S1 | Splash Screen | App launch/branding moment | Logo, loading state | — |
| S2 | Role Selection | Let a new user pick how they're joining | Cards: Athlete/Parent, Coach, Academy, Organizer, Sponsor | Sign Up / Login |
| S3 | Sign Up | Create an account | Phone/Email input, terms checkbox | Sign Up / Login |
| S4 | OTP / Email Verification | Verify contact method | 6-digit code input, resend timer | Sign Up / Login |
| S5 | Login | Return-user access | Phone/Email + password/OTP toggle | Sign Up / Login |
| S6 | Universal Search | Single search entry point | Search bar, recent searches, trending chips | Universal Search |
| S7 | Search Results (Unified) | Mixed results across categories | Tabs (Academies/Coaches/Trials/Tournaments/Scholarships/Sponsorships), result cards | Universal Search, Global Filters |
| S8 | Filter Panel | Apply filters to any listing type | Sport, city/state, age group, price range, date range | Global Filters |
| S9 | Notifications Center | All alerts in one place | Reminder list, enquiry replies, status updates | Deadline & Date Reminders |
| S10 | Report a Listing (Modal) | Flag suspicious content | Reason dropdown, optional comment, submit | Report a Listing |
| S11 | Settings | Account-level controls | Notification prefs, logout, delete account, language | — |
| S12 | Help / Support | FAQ or contact support | Search FAQ, contact form | — |

---

## 1. Athlete / Parent Screens

| # | Screen | Purpose | Key Elements | Supports Feature |
|---|---|---|---|---|
| A1 | Onboarding — Sport & Age Group | Capture sport(s) and age group after signup | Multi-select sport chips, age group picker | Sign Up / Login |
| A2 | Onboarding — Skill Level & Location | Capture skill level and city | Skill level selector, city/state autocomplete | Sign Up / Login |
| A3 | Home / Dashboard | Landing screen after login | Recommended academies/trials, saved items, quick search | — |
| A4 | My Profile (View) | Display own profile | Name, sport(s), achievements, media gallery preview | Digital Profile |
| A5 | Edit Profile | Edit profile details | Editable fields, achievement list add/remove | Digital Profile |
| A6 | Media Gallery Manager | Upload/organize photos & videos | Grid view, upload button, delete/reorder | Digital Profile |
| A7 | Academy Directory (List) | Browse all academies | Card list: name, sport, city, fee range, thumbnail | Academy Directory |
| A8 | Academy Detail Page | Full academy info | Facilities, coaches, age groups, timings, contact, map | Academy Directory |
| A9 | Coach Directory (List) | Browse all coaches | Card list: name, sport, experience, fee, city | Coach Directory |
| A10 | Coach Detail Page | Full coach profile | Qualifications, experience, fee structure, location | Coach Directory |
| A11 | Enquire with Coach (Modal/Form) | Send a request/question to a coach | Message box, preferred date/time, submit | Book/Enquire with Coaches |
| A12 | Trial Listings (List) | Browse all trials | Card list: sport, date, venue, organizer, entry fee | Trial Listings |
| A13 | Trial Detail Page | Full trial info | Eligibility, required documents, contact, entry fee | Trial Listings |
| A14 | Trial Registration Form | Register for a trial | Personal details, document upload, payment note (if applicable) | Trial Registration |
| A15 | Registration Confirmation | Confirm successful registration | Summary, add-to-calendar button, reminder toggle | Trial Registration |
| A16 | Tournament Calendar (Calendar/List Toggle) | Browse tournaments | Month/list view, entry categories | Tournament Calendar |
| A17 | Tournament Detail Page | Full tournament info | Format, dates, venue, prize pool, entry fee | Tournament Calendar |
| A18 | Tournament Registration Form | Register for a tournament | Category selection, personal details | Tournament Registration |
| A19 | Scholarship Feed (List) | Browse scholarships | Card list: provider, sport, amount, deadline | Scholarship Feed |
| A20 | Scholarship Detail Page | Full scholarship info | Eligibility, application steps, external link | Scholarship Feed |
| A21 | Sponsorship Opportunities (List) | Browse sponsorship listings | Card list: sponsor, sport, eligibility, benefits | Sponsorship Opportunities |
| A22 | Sponsorship Detail Page | Full sponsorship info | Eligibility criteria, benefits, deadline | Sponsorship Opportunities |
| A23 | Apply/Pitch to Sponsor Form | Submit application | Profile auto-attach, pitch note text box | Apply/Pitch to Sponsors |
| A24 | My Activity Hub | Track all registrations/applications | Tabs: Trials, Tournaments, Sponsorships — status per item | Trial/Tournament Registration, Apply/Pitch to Sponsors |
| A25 | Saved / Bookmarked Items | Quick access to saved listings | List grouped by type | Deadline & Date Reminders |

---

## 2. Coach Screens

| # | Screen | Purpose | Key Elements | Supports Feature |
|---|---|---|---|---|
| C1 | Coach Onboarding | Capture sport(s) coached, certifications | Multi-step form | Own Profile Creation |
| C2 | Coach Profile Creation/Edit | Build/edit public listing | Certifications, experience, fee structure, location, photo | Own Profile Creation |
| C3 | Coach Dashboard | Landing screen for coach role | Enquiry count, profile completeness meter | — |
| C4 | Enquiry Inbox (List) | View all incoming enquiries | List with athlete name, date, status (new/replied) | Enquiry Inbox |
| C5 | Enquiry Detail / Reply | View and respond to a specific enquiry | Message thread, reply box | Enquiry Inbox |
| C6 | Browse Mode | Coach browsing as any user | Reuses A7–A22 screens | Browse Like Any User |

---

## 3. Academy Screens

| # | Screen | Purpose | Key Elements | Supports Feature |
|---|---|---|---|---|
| AC1 | Academy Onboarding | Initial setup — sports offered, location | Multi-step form | Own Listing Creation |
| AC2 | Academy Listing Creation/Edit | Build/edit public listing | Facilities, fee range, photos, coaches, age groups, timings | Own Listing Creation |
| AC3 | Academy Dashboard | Landing screen for academy role | Active trials count, pending enquiries, registrant summary | — |
| AC4 | Trial Posting Form (Create/Edit) | Create a new trial under academy name | Sport, date, venue, eligibility, fee, required documents | Trial Posting |
| AC5 | My Trials (Management List) | View/manage all posted trials | Status (draft/published/closed), edit/close actions | Trial Posting |
| AC6 | Trial Registrant List | View athletes registered for a specific trial | Table: name, contact, documents submitted, status | Registrant Management |
| AC7 | Registrant Detail | View a single registrant's submission | Profile snapshot, document viewer | Registrant Management |
| AC8 | Enquiry Inbox (List) | View incoming enquiries | Same pattern as Coach's C4 | Enquiry Inbox |
| AC9 | Enquiry Detail / Reply | Respond to an enquiry | Message thread, reply box | Enquiry Inbox |

---

## 4. Organizer Screens

| # | Screen | Purpose | Key Elements | Supports Feature |
|---|---|---|---|---|
| O1 | Organizer Onboarding | Initial setup | Organization name, type, verification docs | Sign Up / Login |
| O2 | Organizer Dashboard | Landing screen | Active trials/tournaments count, upcoming deadlines | — |
| O3 | Trial Listing Create/Edit | Create/edit a trial | Same fields as AC4 | Trial Listing Management |
| O4 | My Trials (Management List) | Manage all posted trials | Status, edit/publish/close actions | Trial Listing Management |
| O5 | Tournament Listing Create/Edit | Create/edit a tournament | Format, dates, venue, entry fees, prize pool, categories | Tournament Listing Management |
| O6 | My Tournaments (Management List) | Manage all posted tournaments | Status, edit/publish actions | Tournament Listing Management |
| O7 | Registration Management (List) | View registrants per event | Table: name, category, payment status, capacity meter | Registration Management |
| O8 | Capacity / Spot Management | Adjust available spots per category | Slider/input per category, waitlist toggle | Registration Management |
| O9 | Results Publishing Form | Enter/upload results | Bracket builder or results table, winner tagging | Results Publishing |
| O10 | Results / Brackets View (Public) | Display published results | Bracket visualization or ranked list | Results Publishing |

---

## 5. Sponsor / Brand Screens

| # | Screen | Purpose | Key Elements | Supports Feature |
|---|---|---|---|---|
| SP1 | Sponsor Onboarding | Initial setup — brand info | Brand name, logo, category, verification | Sign Up / Login |
| SP2 | Sponsor Dashboard | Landing screen | Active listings, new applications count | — |
| SP3 | Sponsorship Listing Create/Edit | Post a new opportunity | Sport, eligibility criteria, benefits offered, deadline | Sponsorship Listing |
| SP4 | My Sponsorships (Management List) | Manage posted opportunities | Status, edit/close actions | Sponsorship Listing |
| SP5 | Athlete Discovery Search | Search athlete profiles | Filters: sport, age, city, achievements | Athlete Discovery |
| SP6 | Athlete Profile View (Sponsor's View) | View a candidate's full profile | Achievements, media gallery, contact/shortlist buttons | Athlete Discovery |
| SP7 | Applications Inbox (List) | View incoming pitches | List: athlete name, sport, date applied, status | Applications Inbox |
| SP8 | Application Detail / Pitch View | Read a specific pitch | Pitch note, attached profile, accept/reject/shortlist actions | Applications Inbox |
| SP9 | Shortlist | View saved candidates | Grouped list, notes field per athlete | Shortlisting |

---

## 6. Admin Screens

| # | Screen | Purpose | Key Elements | Supports Feature |
|---|---|---|---|---|
| AD1 | Admin Login | Secure entry point | Email/password, 2FA | — |
| AD2 | Admin Dashboard | Overview of platform health | Counts: active listings, flagged items, pending expirations | — |
| AD3 | Content Management — Category Picker | Choose which content type to manage | Tabs: Academies, Coaches, Trials, Tournaments, Scholarships, Sponsorships | Content CRUD |
| AD4 | Content List (per category) | Browse/search all records of a type | Table with search, sort, status filters | Content CRUD |
| AD5 | Content Create/Edit Form (generic) | Add or edit any record | Dynamic form based on category schema | Content CRUD |
| AD6 | Flagged/Reported Listings Queue | Review reported content | List: listing, reporter reason, date reported | Listing Moderation |
| AD7 | Moderation Detail / Action Screen | Take action on a flagged listing | View listing, reason, approve/remove/warn actions | Listing Moderation |
| AD8 | Content Expiry Rules Configuration | Set auto-expiry logic | Rule builder (e.g., "expire trial X days after event date") | Content Expiry Rules |
| AD9 | Expiry Monitor | View upcoming/executed expirations | List with status: pending, expired, overridden | Content Expiry Rules |
| AD10 | Category Management — Sports | Add/edit/remove sport types | Editable list, add new sport | Category Management |
| AD11 | Category Management — Cities | Add/edit/remove supported cities/states | Editable list | Category Management |
| AD12 | Category Management — Age Groups | Add/edit/remove age categories | Editable list | Category Management |

---

## Screen Count Summary

| Role | Screen Count |
|---|---|
| Shared/Cross-Role | 12 |
| Athlete / Parent | 25 |
| Coach | 6 |
| Academy | 9 |
| Organizer | 10 |
| Sponsor / Brand | 9 |
| Admin | 12 |
| **Total** | **83** |

*(Some screens, like enquiry inbox/reply, follow the same pattern across Coach and Academy — these can share a single reusable component during development even though they're counted separately here for clarity.)*

---

## Notes for Build Planning

- **Reusable patterns**: Directory list → Detail page → Enquiry/Registration form is a repeating pattern across Academy, Coach, Trial, and Tournament. Building this as one flexible template (rather than four separate ones) will speed up development significantly.
- **Enquiry Inbox** (Coach + Academy) and **Content Management** (Admin) both follow a List → Detail → Action pattern — good candidates for shared components.
- **Not yet covered** (flagged in the earlier gap-analysis): dedicated screens for ratings/reviews, in-app chat/messaging threads, payment collection, and listing analytics aren't included above since they weren't part of the original MVP feature list. Let me know if you'd like these added — I can extend the inventory to cover them.
