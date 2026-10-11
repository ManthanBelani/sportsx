# SportX India — User Personas

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

One primary persona per role across the **six login roles** (Athlete, Coach, Academy, Organizer, Talent Scout, Admin), plus a **Generalized Provider** directory profile (not a login role), grounded in the platform's MVP scope (India-first launch, Gujarat metro focus, cricket-led multi-sport). Each persona maps to the real app flows documented in `Mobile-App-Flow.md`.

---

## How to read a persona

| Field | Meaning |
|-------|---------|
| **Profile** | Name, age, location, role — the "who" |
| **Background** | Life context that shapes their needs |
| **Goals** | What they want to achieve on SportX |
| **Frustrations** | Pain points the platform must solve |
| **Tech comfort** | Device/usage habits that affect UX decisions |
| **Key tasks** | The concrete things they do in the app |
| **Success looks like** | How we know the persona is winning |
| **Quote** | Their voice, in one line |

---

# 1. Athlete / Parent

## 🏃 Primary: Aarav — the teenage athlete
| | |
|---|---|
| **Profile** | Aarav Mehta, 14, Ahmedabad (Vastrapur), Gujarat. School student, right-arm fast bowler. |
| **Background** | Plays club cricket on weekends. His parents want him in a structured academy and visible to selectors, but they don't know which academies are credible or when state trials happen. |
| **Goals** | Find a good cricket academy nearby; never miss a state/district trial; build a profile that looks "professional" to selectors and sponsors. |
| **Frustrations** | Trial info is scattered across WhatsApp groups and posters; no central calendar; can't prove his match stats or media to anyone formally. |
| **Tech comfort** | High. Android phone, daily user of Instagram/YouTube. Low patience for slow or confusing screens. |
| **Key tasks** | Onboard (Cricket, U-14, Intermediate, Ahmedabad) → browse Academies & Trials → register for a trial → upload match photos to Media Gallery → track registrations in Activity Hub. |
| **Success looks like** | Registered for 2 trials this month, profile with 6+ media items, gets an enquiry reply from a coach. |
| **Quote** | _"I just want to know about trials before they fill up, and show my stats in one place."_ |

## 🧑‍🤝‍🧑 Secondary: Mrs. Mehta — the parent
| | |
|---|---|
| **Profile** | Sangeeta Mehta, 41, homemaker, manages Aarav's sports schedule. |
| **Goals** | Safe, verified academies/coaches; clear fees & locations; reminders so she doesn't miss deadlines. |
| **Frustrations** | Fears scams/unverified listings; hates last-minute confusion about venue and documents needed. |
| **Tech comfort** | Medium. Comfortable with WhatsApp and basic apps; values clear language and reminders. |
| **Key tasks** | Uses Saved to shortlist academies; checks documents/fees on detail pages; sets reminders on registrations. |
| **Quote** | _"Tell me it's genuine, tell me where to go, and remind me the day before."_ |

---

# 2. Coach

## 🏏 Primary: Rajesh — the independent coach
| | |
|---|---|
| **Profile** | Rajesh Iyer, 38, Ahmedabad (Maninagar). Ex-ranji player, freelance cricket coach for 9 years. |
| **Background** | Coaches 30+ kids privately and at a local ground. Gets students only through word-of-mouth and wants a public presence to grow his client base and charge appropriately. |
| **Goals** | Build a credible public coaching profile; get quality enquiries; manage enquiries without phone tag; eventually list his own trials. |
| **Frustrations** | No easy way to showcase certifications/experience; inquiries come at all hours via calls; hard to filter serious athletes from casual ones. |
| **Tech comfort** | Medium. Smartphone-savvy but short on time; wants fast, no-nonsense screens. |
| **Key tasks** | Onboard (sport, experience) → complete Coach Profile (credentials, fees, facilities, showcase athletes) → respond in Enquiry Inbox → (later) post a Trial and manage registrants. |
| **Success looks like** | 5+ enquiries/month, profile 100% complete, replies sent within a day. |
| **Quote** | _"If my profile looks professional, parents trust me faster."_ |

---

# 3. Academy

## 🏫 Primary: Priya — academy administrator
| | |
|---|---|
| **Profile** | Priya Nair, 34, Operations Manager at "Elite Cricket Academy", Surat. |
| **Background** | Runs day-to-day ops for a 150-student academy with 4 coaches. Responsible for admissions, trials, and enquiries. Currently juggles Excel + WhatsApp to track everything. |
| **Goals** | Put the academy on the map; run organized trials with online registration; manage enquiries and registrants in one place instead of scattered chats. |
| **Frustrations** | Manual registration = duplicate/missing data; no visibility into how many actually showed up; can't easily collect documents upfront. |
| **Tech comfort** | High. Uses spreadsheets, Google Forms, and dashboards daily. Expects data tables and status filters. |
| **Key tasks** | Onboard (academy name, sport, city) → edit Academy Profile (facilities, photos, age groups) → post Trials → review Trial Registrant List → verify/reject registrants with documents → reply to enquiries. |
| **Success looks like** | A published trial fills 30 spots online, registrant documents collected before the event, zero manual follow-up. |
| **Quote** | _"I want registrations, documents, and status in one screen — not 12 WhatsApp chats."_ |

---

# 4. Organizer

## 🏆 Primary: Sameer — tournament organizer (federation)
| | |
|---|---|
| **Profile** | Sameer Desai, 45, Secretary of a district cricket association, Vadodara. Organizes 6–8 tournaments/year. |
| **Background** | Runs state/district-level tournaments with categories, prize pools, and capacity limits. Currently publishes PDFs and manages entries via physical forms. |
| **Goals** | Publish tournaments with categories & capacity; take online registrations; manage capacity/waitlists; publish results that athletes and parents can point to. |
| **Frustrations** | Over-registration beyond capacity; payment/status chaos; results live only on paper so athletes can't showcase them; no expiry control on stale listings. |
| **Tech comfort** | Medium. Uses email and basic tools; values structure (forms, tables, statuses). |
| **Key tasks** | Onboard (org name, type=federation) → post Tournament (format, dates, fees, prize, categories, capacity) → manage Registration & Capacity → publish Results → close event. |
| **Success looks like** | A tournament with accurate capacity, clean registrant list, and published results within a day of finals. |
| **Quote** | _"If capacity, payments, and results just worked, I'd save a week per tournament."_ |

---

# 5. Generalized Provider

> **[SUPERSEDED — see Backend-Feature-Delta.md]** The v1 **Sponsor / Brand** persona (Anita) is retired (D2). Sponsorship is now an *opportunity type* posted by Coach/Academy/Organizer/Scout; this slot now holds the **Generalized Provider** directory persona.

## 🩺 Primary: Dr. Meera — sports physiotherapist (generalized provider)
| | |
|---|---|
| **Profile** | Meera Joshi, 39, sports physiotherapist running a clinic in Ahmedabad. Listed under the "Physiotherapist" category. |
| **Background** | Works with young athletes on injury prevention and rehab. Gets clients via referrals; wants a credible discoverable presence alongside academies and coaches. |
| **Goals** | Appear in search/directories for athletes and parents; publish credentials and contact details; receive enquiries and connection requests. |
| **Frustrations** | No professional directory for allied sports services; parents can't easily verify credentials; enquiries arrive over scattered channels. |
| **Tech comfort** | Medium. Uses a smartphone and basic dashboards; values clear, trustworthy profiles. |
| **Key tasks** | Onboard as a generalized provider (30 fields, 9 mandatory) → get verified (blue check) → appear in search → answer enquiries/chats (UC22) → be found by athletes and scouts. |
| **Success looks like** | Discoverable, verified profile; a steady stream of enquiries from athletes/parents this month. |
| **Quote** | _"Athletes should be able to find and trust a qualified professional — not just anyone with a clinic."_ |

---

# 6. Talent Scout

## 🔍 Primary: Kiran — independent talent scout
| | |
|---|---|
| **Profile** | Kiran Patel, 42, freelance talent scout specializing in cricket and kabaddi, based in Ahmedabad. Works with academies and clubs to identify promising athletes for trials and scholarships. |
| **Background** | Has relationships with local academies and occasionally gets referral fees when athletes get selected. Needs to track promising athletes over time and share profiles with contacts. |
| **Goals** | Discover promising athletes by sport, age, location, and achievements; build a shortlist of prospects; efficiently share athlete profiles with academy contacts. |
| **Frustrations** | No systematic way to discover athletes outside his immediate network; WhatsApp forwards get lost; can't easily share athlete media with coaches. |
| **Tech comfort** | Medium. Uses WhatsApp and spreadsheets; values simple, fast interfaces. |
| **Key tasks** | Onboard (org, sports, experience) → Scout Dashboard → Discover Athletes (filters: sport, age, location, skill) → View Athlete Profile → Shortlist (with status/notes) → add Observation → send Connect (guardian-routed for minors) → post scouting Opportunities / write Scout Reports (P1). |
| **Success looks like** | Shortlists 15 promising athletes, logs observations, sends 5 connection requests, and posts a scouting opportunity this month. |
| **Quote** | _"I know talent when I see it — I just need a better way to track and share what I find."_ |

---

# 7. Admin

## 🛡️ Primary: Vikram — platform operations admin
| | |
|---|---|
| **Profile** | Vikram Shah, 29, SportX India operations team, works remotely (Bengaluru). |
| **Background** | First line of platform trust & safety. Manages users (suspend/ban), reviews the verification queue, moderates reports, curates admin-posted opportunities, sends broadcasts, and keeps category master data (sports/cities/age-groups/positions) accurate. |
| **Goals** | Keep the platform clean and trustworthy; act on reports and verification requests fast; manage users; configure expiry rules so stale content auto-archives. |
| **Frustrations** | Can't see platform health at a glance; reports, verification requests, and approvals pile up across tools; no control over auto-expiry so dead listings linger. |
| **Tech comfort** | High. Internal-tools native; wants counts, queues, and bulk-friendly actions. |
| **Key tasks** | Admin login (email + 2FA) → Dashboard stats → User Management (suspend/ban) → Verification Queue (approve/reject with reason) → Moderation Queue (approve/remove/warn/suspend) → admin-posted Opportunities → broadcast Notifications → manage Categories & Expiry. |
| **Success looks like** | Reports cleared daily, zero unverified providers live, expired content auto-archived. |
| **Quote** | _"Give me the queues and the numbers — I'll keep the platform trustworthy."_ |

---

## Persona summary at a glance

| Role | Persona | One-line job-to-be-done |
|------|---------|-------------------------|
| Athlete/Parent | Aarav (14) + Mrs. Mehta (guardian) | "Discover and register for opportunities; build a profile that gets me noticed — safely." |
| Coach | Rajesh (38) | "Showcase my coaching, run programs, and turn enquiries into students." |
| Academy | Priya (34) | "Run trials, facilities, and programs without chaos." |
| Organizer | Sameer (45) | "Run tournaments with capacity, registration, and published results." |
| Generalized Provider | Dr. Meera (39) | "Be discoverable and trusted in the sports directory." |
| Talent Scout | Kiran (42) | "Discover, track, and shortlist promising athletes; make contact properly." |
| Admin | Vikram (29) | "Keep the platform trustworthy, clean, and up to date." |

---

## Design implications (what these personas tell us)

- **Trust signals are critical** for Aarav/Mrs. Mehta and Dr. Meera → verified badges, contact info, documents, reviews.
- **Guardian consent & minor-safety** dominate the athlete experience → consent gate, restricted visibility/messaging, anonymised leaderboard, guardian-routed contact by scouts.
- **Discovery + social** drive value for Athletes and Scouts → universal search, feed, follow/connect, and Athlete Discovery.
- **Provider dashboards are "back-office" tools** for Priya/Sameer/Rajesh/Kiran → tables, statuses, bulk actions, clear counts.
- **Reminders & expiry** matter most to Mrs. Mehta (deadlines) and Vikram (stale content).
- **Onboarding must be role-tailored** → each persona lands on a different first-run form with a 30-field profile checklist (see `Mobile-App-Flow.md`).
