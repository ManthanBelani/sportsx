# SportX – Profile Field Specification (All Roles)

Source: `SportX_Profile_Details.pdf` (6 profile sheets, **30 fields each = 180 fields**).

## Legend

**Priority** (taken from the coloured badge printed on each field):

| Priority | Badge colour | Meaning in the PDF |
|----------|--------------|--------------------|
| **Essential** | Red | Mandatory at registration |
| **High** | Orange/Yellow | Strongly recommended |
| **Medium** | Green | Optional but valuable |

**Data types used** (the PDF shows UI mock-ups only, so types are read from the widget shown):

| Type | Meaning |
|------|---------|
| `text` | Single-line text input |
| `textarea` | Multi-line text (bio / description) |
| `number` | Numeric input |
| `year` | 4-digit year |
| `date` / `date-range` | Date picker |
| `dropdown` | Single-select |
| `dropdown-pair` | Two linked dropdowns (State → City) |
| `multi-tag` | Multi-select shown as removable chips (×) |
| `checkbox-group` | Multiple checkboxes |
| `radio` | Single choice radio buttons |
| `image` | Single image upload |
| `file` | Document upload (PDF/image) |
| `media-multi` | Multiple photos/videos upload |
| `list` | Repeatable rows added via an "+ Add …" button |
| `stats` | Group of numeric counters |
| `url-group` | Set of link inputs (Instagram, YouTube, LinkedIn, Website) |
| `contact` | Phone + email (+ WhatsApp / Contact Now buttons) |
| `readonly-status` | System-controlled badge (verification) |
| `readonly-rating` | System-computed star rating + review count |

## Summary

| Profile role | Essential | High | Medium | Total |
|--------------|:---------:|:----:|:------:|:-----:|
| 1. Athlete | 8 | 15 | 7 | 30 |
| 2. Coach | 8 | 14 | 8 | 30 |
| 3. Academy | 9 | 14 | 7 | 30 |
| 4. Talent Scout | 7 | 16 | 7 | 30 |
| 5. Generalized (all other categories) | 9 | 14 | 7 | 30 |
| 6. Organizer | 7 | 17 | 6 | 30 |

Each sheet also has a **Profile Completion Guide** (circular % indicator, example shown as **60%**) – see the end of each section.

---

# 1. ATHLETE PROFILE

| # | Field | Section (field range) | Priority | Data type | Input details / options / hint |
|---|-------|----------------------|----------|-----------|--------------------------------|
| 1 | Full Name | 1. Basic Information (1–8) | Essential | `text` | e.g. Rohan Mehta – "Your official name" |
| 2 | Profile Photo | 1. Basic Information | Essential | `image` | Photo preview + "Add Photo" tile |
| 3 | Primary Sport | 1. Basic Information | Essential | `dropdown` | e.g. Cricket – "Your main sport" |
| 4 | Position / Event | 1. Basic Information | Essential | `dropdown` | e.g. Batsman (Right Hand) – depends on sport |
| 5 | City / State | 1. Basic Information | Essential | `dropdown-pair` | State (Gujarat) + City (Ahmedabad) |
| 6 | Age / Age Group | 1. Basic Information | Essential | `dropdown` ×2 | Age in years (17 Years) + Age group (U-19) |
| 7 | Skill / Playing Level | 1. Basic Information | Essential | `dropdown` | e.g. Intermediate – self-assessed |
| 8 | Short Bio | 1. Basic Information | Essential | `textarea` | 2–3 lines introduction |
| 9 | Current Team / Academy | 2. Team, Coach & Experience (9, 10, 16, 17) | High | `text` | e.g. Ahmedabad Cricket Academy |
| 10 | Coach | 2. Team, Coach & Experience | High | `text` | e.g. Rohit Mehta – optional but recommended |
| 11 | Achievements | 3. Performance & Achievements (11–15) | High | `text` / `list` | e.g. State Level Winner – 2025 (medals, awards) |
| 12 | Competition History | 3. Performance & Achievements | High | `text` / `list` | e.g. Gujarat State Championship |
| 13 | Performance Statistics | 3. Performance & Achievements | High | `text` (sport-specific) | e.g. Matches, Runs, Average |
| 14 | Personal Best / Best Performance | 3. Performance & Achievements | High | `text` | e.g. Highest Score – 142 |
| 15 | Certificates | 3. Performance & Achievements | High | `file` | "Upload Certificate" button |
| 16 | Years of Experience | 2. Team, Coach & Experience | High | `dropdown` | e.g. 5 Years |
| 17 | Training Centre / Academy | 2. Team, Coach & Experience | High | `text` | e.g. Khel Academy, Ahmedabad |
| 18 | Playing Hand / Foot | 4. Physical Attributes (18–20) | High | `dropdown` | e.g. Right-handed (dominant hand or foot) |
| 19 | Height | 4. Physical Attributes | High | `number` + unit `dropdown` | 178 cm |
| 20 | Weight | 4. Physical Attributes | Medium | `number` + unit `dropdown` | 68 kg |
| 21 | Photos / Videos | 5. Media & Visibility (21) | High | `media-multi` | Match photos, training videos, highlights |
| 22 | Athlete Goals | 6. Goals & Opportunities (22–24, 29) | High | `textarea` | Short & long-term goals, e.g. State Team Selection |
| 23 | Open to Opportunities | 6. Goals & Opportunities | High | `checkbox-group` | Trials, Tournaments, Scholarships, Teams, Sponsorships, Academy Admission |
| 24 | Availability | 6. Goals & Opportunities | High | `checkbox-group` | Weekdays, Weekends, Morning, Afternoon, Evening |
| 25 | Travel / Relocation Preference | 7. Location & Travel (25) | Medium | `dropdown` | e.g. Local (Within City/State) |
| 26 | Education / Institution | 8. Education & Additional Sports (26–27) | Medium | `text` | e.g. Gujarat University |
| 27 | Additional Sports | 8. Education & Additional Sports | Medium | `multi-tag` | e.g. Football ×, Athletics × |
| 28 | Verification Status | 9. Verification & Trust (28) | Medium | `readonly-status` | "Not Verified Yet" – verified by SportX |
| 29 | Sponsorship Interest | 6. Goals & Opportunities | Medium | `dropdown` | e.g. Yes, I am interested |
| 30 | Social / Professional Links | 10. Social Links (30) | Medium | `url-group` | Instagram (@yourusername), YouTube (@yourchannel), LinkedIn, Website |

**Completion guide checklist:** Basic Information, Sport & Position, Achievements, Statistics, Media, Goals & Opportunities.

---

# 2. COACH PROFILE

| # | Field | Section (field range) | Priority | Data type | Input details / options / hint |
|---|-------|----------------------|----------|-----------|--------------------------------|
| 1 | Full Name | 1. Basic Information (1–7) | Essential | `text` | e.g. Rohit Sharma |
| 2 | Profile Photo | 1. Basic Information | Essential | `image` | "Upload Photo" |
| 3 | Primary Sport | 1. Basic Information | Essential | `dropdown` | Cricket, Football, Badminton… |
| 4 | Coaching Specialization | 1. Basic Information | Essential | `dropdown` | e.g. Batting, Fitness, Goalkeeping |
| 5 | Coaching Level | 1. Basic Information | Essential | `dropdown` | Grassroots, Youth, State, Professional |
| 6 | City / State | 1. Basic Information | Essential | `dropdown-pair` | Select State + Select City |
| 7 | Short Bio | 1. Basic Information | Essential | `textarea` | 2–3 lines about coaching journey |
| 8 | Years of Coaching Experience | 2. Experience & Current Organization (8–12) | Essential | `dropdown` | Select Years |
| 9 | Coaching Role | 2. Experience & Current Organization | High | `dropdown` | e.g. Head Coach, Assistant Coach |
| 10 | Current Academy / Organization | 2. Experience & Current Organization | High | `text` | e.g. Ahmedabad Cricket Academy |
| 11 | Qualifications / Certifications | 2. Experience & Current Organization | High | `file` (multiple) | BCCI, AIFF, NIS etc. |
| 12 | Teams Coached | 2. Experience & Current Organization | High | `list` | e.g. Gujarat U-16 Team + "Add Team" |
| 13 | Age Groups Coached | 3. Coaching Focus (13–15) | High | `checkbox-group` | U-8, U-10, U-12, U-14, U-16, U-18, U-21, Senior |
| 14 | Athlete Levels Coached | 3. Coaching Focus | High | `checkbox-group` | Beginner, Developing, Intermediate, Advanced, Elite, Professional |
| 15 | Areas of Expertise | 3. Coaching Focus | High | `checkbox-group` | Technical Skills, Tactical Development, Fitness & Conditioning, Mental Training, Youth Development, Match Preparation, Performance Analysis, Talent Development |
| 16 | Training Programs | 4. Coaching Services & Programs (16–17) | High | `list` | e.g. Beginner Program, Advanced Batting, Fitness Camp |
| 17 | Coaching Services | 4. Coaching Services & Programs | High | `checkbox-group` | Individual, Group, Team, Camps/Workshops, Online, Trial Preparation, Competition Preparation, Fitness Training, Performance Analysis, Other |
| 18 | Availability | 5. Availability & Location (18–19) | High | `checkbox-group` | Weekdays, Weekends, Morning, Afternoon, Evening |
| 19 | Training Location | 5. Availability & Location | High | `checkbox-group` + `text` | Academy, Ground, Indoor Facility, Gym, Online, Other + venue name |
| 20 | Coaching Achievements | 6. Achievements & Impact (20–21) | High | `list` | e.g. State Championship Winner 2024 |
| 21 | Athletes / Teams Coached | 6. Achievements & Impact | High | `list` | e.g. 5 state-level players, 2 national selections |
| 22 | Photos & Videos | 7. Media & Presence (22) | High | `media-multi` | Training, matches, camps |
| 23 | Coaching Philosophy | 8. Professional Details (23–26) | Medium | `textarea` | Fundamentals, discipline, long-term development |
| 24 | Fees / Pricing | 8. Professional Details | Medium | `dropdown` | Per Session, Monthly Program, Contact for Fees |
| 25 | Open to Opportunities | 8. Professional Details | Medium | `checkbox-group` | Academy Position, Team Coach, School/College, Camps/Workshops, Consulting, Other |
| 26 | Travel / Relocation Preference | 8. Professional Details | Medium | `dropdown` | Local, State, National, International |
| 27 | Education | 9. Education (27) | Medium | `text` | e.g. B.Com, Gujarat University (optional) |
| 28 | Reviews / Recommendations | 10. Reviews & Verification (28–29) | Medium | `readonly-rating` | e.g. 4.5 ★ (20 reviews) + "View All" |
| 29 | Verification Status | 10. Reviews & Verification | Medium | `readonly-status` | "Not Verified Yet" |
| 30 | Social / Professional Links | 11. Social Links (30) | Medium | `url-group` | Instagram, YouTube, LinkedIn, Website |

**Completion guide checklist:** Basic Information, Coaching Details, Qualifications, Experience, Programs & Services, Achievements, Media, Verification.

---

# 3. ACADEMY PROFILE

| # | Field | Section (field range) | Priority | Data type | Input details / options / hint |
|---|-------|----------------------|----------|-----------|--------------------------------|
| 1 | Academy Name | 1. Basic Information (1–6) | Essential | `text` | e.g. Khel Cricket Academy |
| 2 | Academy Logo / Cover Photo | 1. Basic Information | Essential | `image` (logo + optional cover) | "Upload Logo" |
| 3 | Primary Sport(s) | 1. Basic Information | Essential | `multi-tag` | Cricket ×, Football ×, Badminton × |
| 4 | Academy Type | 1. Basic Information | Essential | `dropdown` | Private, Club, School, College, Govt., etc. |
| 5 | City / State (Location) | 1. Basic Information | Essential | `dropdown-pair` | Gujarat / Ahmedabad |
| 6 | Short Description | 1. Basic Information | Essential | `textarea` | 2–3 lines |
| 7 | Sports / Training Offered | 2. Sports & Training Details (7–9) | Essential | `multi-tag` | e.g. Batting ×, Bowling ×, Fielding × |
| 8 | Age Groups | 2. Sports & Training Details | Essential | `checkbox-group` | U-6, U-8, U-10, U-12, U-14, U-16, U-18, Senior |
| 9 | Training Programs | 2. Sports & Training Details | Essential | `list` | e.g. Beginner Program (3 Months), Advanced (6 Months), Elite (1 Year) + "Add Training Program" |
| 10 | Coaches / Coaching Team | 3. Coaching Team (10) | High | `list` (profile cards) | Photo, name, role, experience (e.g. Rohit Mehta – Head Coach – 10+ yrs) + "Add Coach" |
| 11 | Years Established | 4. Academy Details (11–15) | High | `year` | e.g. 2018 |
| 12 | Facilities | 4. Academy Details | High | `checkbox-group` | Ground, Nets, Indoor Facility, Gym, Video Analysis, Changing Room, Parking, First Aid, Other |
| 13 | Training Schedule | 4. Academy Details | High | `dropdown` | e.g. Morning & Evening Batches |
| 14 | Training Location / Address | 4. Academy Details | High | `textarea` + map pin | Full address with map location |
| 15 | Fees / Pricing | 4. Academy Details | High | `dropdown` + `text` | "Show Fees on Profile" + e.g. ₹3,000 / month (Beginner Program) |
| 16 | Admission / Registration Process | 5. Admission & Contact (16, 23) | High | `dropdown` | e.g. Trial Required |
| 17 | Academy Achievements | 6. Achievements & Outcomes (17–18) | High | `list` | e.g. Gujarat State Champions – U16 (2024) |
| 18 | Athletes / Teams Developed | 6. Achievements & Outcomes | High | `stats` | Trained Athletes (250+), State Selections (12), National Selections (3) |
| 19 | Competitions / Tournaments | 7. Opportunities & Events (19, 20, 28, 30) | High | `list` (event cards) | Name, date, city + "Add Tournament" |
| 20 | Trials / Open Registrations | 7. Opportunities & Events | High | `list` (event cards) | e.g. U-14 Cricket Trials, 12 Oct 2026 + "Add Trial" |
| 21 | Photos & Videos | 8. Media & Gallery (21) | High | `media-multi` | Academy photos, training videos, facilities, events |
| 22 | Verification Status | 9. Verification & Credentials (22, 27) | High | `readonly-status` | "Verified Academy" |
| 23 | Contact / Enquiry | 5. Admission & Contact | High | `contact` | Phone (+91 98765 43210), Email, WhatsApp button, Contact Now button |
| 24 | Website / Social Links | 10. Additional Information (24–26, 29) | Medium | `url-group` | Instagram, YouTube, LinkedIn, Web + URL |
| 25 | Reviews / Recommendations | 10. Additional Information | Medium | `readonly-rating` | e.g. 4.5 ★ (120 reviews) |
| 26 | Academy Head / Owner | 10. Additional Information | Medium | `text` / linked profile | e.g. Amit Patel – Founder & Director |
| 27 | Certifications / Affiliations | 9. Verification & Credentials | Medium | `multi-tag` | BCCI Affiliated, Gujarat Cricket Association, Sports Authority of Gujarat |
| 28 | Scholarships / Financial Aid | 7. Opportunities & Events | Medium | `dropdown` / `list` | e.g. Merit-based scholarships available |
| 29 | Accommodation / Transport | 10. Additional Information | Medium | `dropdown` / `list` | e.g. Transport Available |
| 30 | Open Opportunities | 7. Opportunities & Events | Medium | `dropdown` / `list` | e.g. Coach Recruitment / Partnership |

**Completion guide checklist:** Basic Information, Sports & Training, Coaches, Facilities, Programs, Achievements, Media, Verification. Bottom CTA: **Complete Profile →**

---

# 4. TALENT SCOUT PROFILE

| # | Field | Section (field range) | Priority | Data type | Input details / options / hint |
|---|-------|----------------------|----------|-----------|--------------------------------|
| 1 | Full Name | 1. Basic Information (1–7) | Essential | `text` | e.g. Rohit Kumar |
| 2 | Profile Photo / Cover | 1. Basic Information | Essential | `image` (photo + optional cover) | "Upload Photo" |
| 3 | Scout Type | 1. Basic Information | Essential | `dropdown` | Independent Scout, Club Scout, Academy Scout, Federation Scout, etc. |
| 4 | Primary Sport(s) | 1. Basic Information | Essential | `multi-tag` | Cricket ×, Football ×, Badminton × |
| 5 | Scouting Specialization / Position | 1. Basic Information | Essential | `multi-tag` | Batting, Bowling, Wicketkeeping, Midfielder, Goalkeeper, Sprinter… |
| 6 | City / State (Base Location) | 1. Basic Information | Essential | `dropdown-pair` | Gujarat / Ahmedabad |
| 7 | Short Bio | 1. Basic Information | Essential | `textarea` | 2–3 lines |
| 8 | Years of Scouting Experience | 2. Experience & Organization (8–12) | High | `dropdown` | e.g. 5+ Years |
| 9 | Scouting Level | 2. Experience & Organization | High | `checkbox-group` | Grassroots, School, College, Club, District, State, National, Professional |
| 10 | Age Groups Scouted | 2. Experience & Organization | High | `checkbox-group` | U-8, U-10, U-12, U-14, U-16, U-18, U-21, Senior |
| 11 | Current Organization / Club | 2. Experience & Organization | High | `text` | e.g. Gujarat Cricket Association |
| 12 | Previous Organizations / Teams | 2. Experience & Organization | High | `list` | Name (role) + years, e.g. Rajasthan Royals (Talent Scout) 2022–2024 + "Add Organization" |
| 13 | Certifications / Qualifications | 3. Qualifications & Method (13–15) | High | `list` | Name + year, e.g. AIFF Talent Identification Certificate 2023 + "Add Certificate" |
| 14 | Scouting Method | 3. Qualifications & Method | High | `checkbox-group` | Live Match Scouting, Video Analysis, Training Observation, Statistical Analysis, Trial Assessment, Combine Testing, Coach Recommendations, Other |
| 15 | Evaluation Areas | 3. Qualifications & Method | High | `checkbox-group` | Technical Ability, Tactical Understanding, Physical Fitness, Mental Attributes, Potential, Consistency, Game Awareness, Decision Making |
| 16 | Athletes Scouted | 4. Track Record (16–18) | High | `stats` | Total Athletes (100+), State Level (25), National Level (8) |
| 17 | Successful Talent Discoveries | 4. Track Record | High | `list` (photo + text + year) | e.g. Player selected for Gujarat State Team – 2024 + "Add Talent Discovery" |
| 18 | Scouting Achievements | 4. Track Record | High | `list` (photo + text + year) | e.g. Best Talent Scout Award – Gujarat 2024 + "Add Achievement" |
| 19 | Scouting Regions / Travel Availability | 5. Scouting Coverage (19–23) | High | `checkbox-group` | Local, District, State, National, International |
| 20 | Scouting Events / Matches Covered | 5. Scouting Coverage | High | `multi-tag` | Tournaments, Trials, Leagues, Schools, College Events, Camps |
| 21 | Services Offered | 5. Scouting Coverage | High | `checkbox-group` | Talent Identification, Video Analysis, Recruitment Scouting, Academy Collaboration, Player Evaluation Reports, Trial Organization, Match Scouting, Other |
| 22 | Recruitment Focus | 5. Scouting Coverage | High | `multi-tag` | Academy Admissions, Team Selection, Scholarships, Professional Contracts |
| 23 | Scouting Reports / Portfolio | 5. Scouting Coverage | High | `stats` | Scouting Reports (12), Player Assessments (8), Video Analyses (5) |
| 24 | Photos & Videos | 6. Media & Presence (24) | Medium | `media-multi` | Match photos, scouting videos, events |
| 25 | Professional Recommendations | 7. Professional Network (25–30) | Medium | `readonly-rating` | e.g. 4.7 ★ (18 reviews) + "View All" |
| 26 | Verification Status | 7. Professional Network | Medium | `readonly-status` | "Verified Scout" |
| 27 | Professional Network / Affiliations | 7. Professional Network | Medium | `multi-tag` | Clubs, Academies, Federations, Agents |
| 28 | Availability | 7. Professional Network | Medium | `dropdown` | e.g. Available for Scouting |
| 29 | Website / Social Links | 7. Professional Network | Medium | `url-group` | Instagram, YouTube, LinkedIn, Web + URL |
| 30 | Professional Services / Fees | 7. Professional Network | Medium | `dropdown` | e.g. Contact for Pricing (optional) |

**Completion guide checklist:** Basic Information, Experience & Organization, Qualifications, Scouting Coverage, Track Record, Media & Presence, Network & Links, Verification.

---

# 5. GENERALIZED PROFILE (for all other categories)

**Applicable for:** NGO, Doctor, Physiotherapist, Sports Store, Brand, Nutritionist, Journalist, Agent, Federation, Facility, School/College and more (Sports Psychologist, Sports Photographer, Sports Media, Event Company, Government Body, Other).

> Note: on this sheet the number-circle colours don't always match the badge (e.g., #7 has a red circle but a "High" badge; #10, #17, #25 have yellow circles but "Medium" badges). **The badge label is used below.**

| # | Field | Section (field range) | Priority | Data type | Input details / examples |
|---|-------|----------------------|----------|-----------|---------------------------|
| 1 | Profile Type / Category | 1. Identity & Basic Information | Essential | `dropdown` | NGO, Doctor, Physiotherapist, Sports Store, Brand, etc. |
| 2 | Name (Individual / Organization) | 1. Identity & Basic Information | Essential | `text` | Full name or business name |
| 3 | Profile Photo / Logo | 1. Identity & Basic Information | Essential | `image` | Photo or logo + cover image |
| 4 | Short Description (About) | 1. Identity & Basic Information | Essential | `textarea` | What you do, mission, focus areas (2–3 lines) |
| 5 | Primary Sport(s) | 2. Sports & Specialization | Essential | `multi-tag` / `dropdown` | Main sport associated with |
| 6 | Services / Products Specialization | 2. Sports & Specialization | Essential | `multi-tag` / `text` | Sports medicine, Equipment, Nutrition, Grassroots development, etc. |
| 7 | Target Audience | 2. Sports & Specialization | High | `multi-tag` | Athletes, Coaches, Academies, Teams, Schools, etc. |
| 8 | Primary Location (City/State) | 3. Location | Essential | `dropdown-pair` | Main location of work/business |
| 9 | Service / Operating Area | 3. Location | High | `dropdown` | Local, District, State, National, International |
| 10 | Branches / Multiple Locations | 3. Location | Medium | `list` | Other branches/centres if any |
| 11 | Contact Information | 4. Contact Information | Essential | `contact` | Phone, Email, WhatsApp (at least one required) |
| 12 | Contact Person | 4. Contact Information | High | `text` | Name, designation (for organizations) |
| 13 | Website / Social Links | 4. Contact Information | High | `url-group` | Website, Instagram, LinkedIn, YouTube, etc. |
| 14 | Organization Type | 5. Organization / Professional Details | High | `dropdown` | Private, NGO, Government, Company, Individual Professional, etc. |
| 15 | Established Year | 5. Organization / Professional Details | High | `year` | Year organization/business started |
| 16 | Founder / Owner / Head | 5. Organization / Professional Details | High | `text` | Name and position |
| 17 | Team / Staff | 5. Organization / Professional Details | Medium | `list` | Key members (optional) |
| 18 | Services Offered | 6. Services / Products / Programs | Essential | `list` / `multi-tag` | Consultation, rehabilitation, equipment, programs, etc. |
| 19 | Products Offered (if applicable) | 6. Services / Products / Programs | High | `list` | Sports equipment, apparel, accessories |
| 20 | Programs (if applicable) | 6. Services / Products / Programs | High | `list` | Training program, community program, health program |
| 21 | Professional Qualifications | 7. Qualifications & Experience | High | `text` / `list` | Degree, certification, specialization (if applicable) |
| 22 | Certifications | 7. Qualifications & Experience | High | `file` + details | Upload relevant certificates |
| 23 | Professional Experience | 7. Qualifications & Experience | High | `text` / `list` | Years of experience and key roles |
| 24 | Achievements | 8. Achievements & Track Record | High | `list` | Awards, recognition, major projects, impact |
| 25 | Work / Project History | 8. Achievements & Track Record | Medium | `list` | Important projects, associations, events worked on |
| 26 | Verification Status | 9. Trust & Verification | High | `readonly-status` | Identity / professional / organization verification |
| 27 | Documents | 9. Trust & Verification | Medium | `file` (private) | Registration, licenses, certificates – kept private |
| 28 | Availability | 10. Availability & Service Mode | Medium | `dropdown` | Available / Limited / Not available |
| 29 | Service Mode | 10. Availability & Service Mode | Medium | `dropdown` | Online / Offline / Both / Home Visit |
| 30 | Partnerships / Affiliations | 11. Network & Partnerships | Medium | `multi-tag` / `list` | Academies, brands, federations, government, etc. |

### Additional (important but optional) modules – not numbered fields

| Module | Data type | Note |
|--------|-----------|------|
| Photos & Videos | `media-multi` | Work, products, facilities, events |
| Open Opportunities | `list` | Hiring, collaboration, sponsorship, etc. |
| Reviews & Recommendations | `readonly-rating` | From athletes, coaches, clients |
| Events | `list` | Upcoming and past |
| Posts / Updates | feed content | Announcements, offers, news |
| Analytics | read-only dashboard | Profile views, enquiries, content performance |
| Pricing (if applicable) | `text` / `list` | Per consultation, product price, package |
| Privacy Settings | toggles | Control profile visibility and contact information |

---

# 6. ORGANIZER PROFILE

| # | Field | Section (field range) | Priority | Data type | Input details / options / hint |
|---|-------|----------------------|----------|-----------|--------------------------------|
| 1 | Organizer / Organization Name | 1. Basic Information (1–7) | Essential | `text` | e.g. Gujarat Sports Events |
| 2 | Logo / Cover Photo | 1. Basic Information | Essential | `image` ×2 (logo + cover) | "Upload Logo", "Upload Cover Photo" |
| 3 | Organizer Type | 1. Basic Information | Essential | `dropdown` | Event Company, Individual, Club, College, Federation, NGO, etc. |
| 4 | Primary Sport(s) | 1. Basic Information | Essential | `multi-tag` | Cricket ×, Football ×, Volleyball × |
| 5 | Event Types | 1. Basic Information | Essential | `checkbox-group` | Tournament, Trial, Championship, Camp, League, Workshop, Sports Meet, Marathon, Other |
| 6 | City / State (Base Location) | 1. Basic Information | Essential | `dropdown-pair` | Gujarat / Ahmedabad |
| 7 | Short Description | 1. Basic Information | Essential | `textarea` | 2–3 lines |
| 8 | Years of Experience | 2. Experience & Event History (8–10) | High | `dropdown` | e.g. 5+ Years |
| 9 | Events Organized (History) | 2. Experience & Event History | High | `list` | Event name + year + "Add Event" |
| 10 | Competition Level | 2. Experience & Event History | High | `checkbox-group` | School, College, Club, District, State, National, International, Amateur, Professional |
| 11 | Upcoming Events | 3. Upcoming Events (11–16) | High | `list` (event cards) | Title, category, city, dates, "Registration Open" tag |
| 12 | Event Registration | 3. Upcoming Events | High | `radio` | Individual Registration / Team Registration / Both |
| 13 | Eligibility Criteria | 3. Upcoming Events | High | `multi-tag` / chips | U-14, U-16, U-19, Open (age, gender, location, skill level) |
| 14 | Event Date & Venue | 3. Upcoming Events | High | `date-range` + `textarea` + map | e.g. 15 Nov 2026 – 20 Nov 2026, Narendra Modi Stadium, Ahmedabad |
| 15 | Registration Fee | 3. Upcoming Events | High | `number` + currency `dropdown` | 500 INR – per player/team |
| 16 | Registration Deadline | 3. Upcoming Events | High | `date` | e.g. 31 Oct 2026 |
| 17 | Participants / Teams | 4. Participants & Venue (17–19) | High | `stats` | Participants (1200+), Teams (80), Academies (25) |
| 18 | Venue Details | 4. Participants & Venue | High | venue card + `checkbox-group` | Ground, Changing Room, Parking, Drinking Water, Seating, First Aid |
| 19 | Schedule / Fixtures | 4. Participants & Venue | High | `list` | e.g. 15 Nov – Group Matches; 16 Nov – Knockouts; 18 Nov – Semi Finals; 20 Nov – Final |
| 20 | Results / Winners | 5. Results & Achievements (20–21) | High | `list` | Year + event (2025 Gujarat Inter-Academy Cup…) |
| 21 | Achievements | 5. Results & Achievements | High | `list` | e.g. Organized 20+ events, 5000+ athletes participated |
| 22 | Contact / Enquiry | 6. Contact & Verification (22–23) | High | `contact` | Phone, Email, WhatsApp button, Contact Now button |
| 23 | Verification Status | 6. Contact & Verification | High | `readonly-status` | "Verified Organizer" |
| 24 | Photos & Videos | 7. Media & Gallery (24) | High | `media-multi` | Event photos, videos, posters, highlights |
| 25 | Partners / Affiliations | 8. Partners & Sponsors (25–26) | Medium | `list` (logos) | Federations, brands, academies, institutions |
| 26 | Sponsors | 8. Partners & Sponsors | Medium | `list` (logos) | Current and past sponsors |
| 27 | Opportunities Offered | 9. Opportunities (27) | Medium | `checkbox-group` | Trials, Team Selection, Camps, Volunteer, Scholarships, Coaching Jobs |
| 28 | Reviews / Recommendations | 10. Additional Information (28–30) | Medium | `readonly-rating` | e.g. 4.5 ★ (32 reviews) |
| 29 | Website / Social Links | 10. Additional Information | Medium | `url-group` | Instagram, YouTube, LinkedIn, Web + URL |
| 30 | Organizer / Contact Person | 10. Additional Information | Medium | `text` / linked profile | e.g. Amit Patel – Founder & Event Director |

**Completion guide checklist:** Basic Information, Sports & Event Details, Experience, Upcoming Events, Venue & Schedule, Results & Achievements, Media, Verification.

---

# Cross-Role Comparison of Shared Fields

| Concept | Athlete | Coach | Academy | Scout | Generalized | Organizer |
|---------|:-------:|:-----:|:-------:|:-----:|:-----------:|:---------:|
| Name | #1 E | #1 E | #1 E | #1 E | #2 E | #1 E |
| Photo / Logo | #2 E | #2 E | #2 E | #2 E | #3 E | #2 E |
| Primary Sport | #3 E | #3 E | #3 E | #4 E | #5 E | #4 E |
| City / State | #5 E | #6 E | #5 E | #6 E | #8 E | #6 E |
| Short Bio / Description | #8 E | #7 E | #6 E | #7 E | #4 E | #7 E |
| Years of Experience | #16 H | #8 E | – | #8 H | #23 H | #8 H |
| Availability | #24 H | #18 H | – | #28 M | #28 M | – |
| Photos & Videos | #21 H | #22 H | #21 H | #24 M | (optional) | #24 H |
| Achievements | #11 H | #20 H | #17 H | #18 H | #24 H | #21 H |
| Contact | – | – | #23 H | – | #11 E | #22 H |
| Verification Status | #28 M | #29 M | #22 H | #26 M | #26 H | #23 H |
| Reviews / Recommendations | – | #28 M | #25 M | #25 M | (optional) | #28 M |
| Social / Website Links | #30 M | #30 M | #24 M | #29 M | #13 H | #29 M |

*(E = Essential, H = High, M = Medium)* — the same field can have a different priority per role (e.g. Verification is Medium for Athlete/Coach/Scout but High for Academy/Organizer/Generalized).

---

# Notes on Accuracy / Ambiguities

1. **Data types are inferred** from the UI widgets in the PDF (dropdown arrows, chips, checkboxes, upload buttons). The PDF does not name backend types.
2. **Athlete #6** shows two controls (age in years + age-group dropdown); treat as one field with two values. Same for **#5 City/State** (dropdown-pair) everywhere.
3. **Section headers** show the field range (e.g. "Fields 9–10, 16–17"); some sections contain non-contiguous numbers – the "Section" column above follows the printed layout.
4. **Talent Scout:** section 2 (fields 8–12) holds Years of Experience, Scouting Level, Age Groups Scouted, Current Organization and Previous Organizations.
5. **Academy #24–30** are the "Medium" group; Academy has **9 Essential** fields because Sports/Age Groups/Programs (7–9) are also red.
6. **Generalized sheet:** circle colours are inconsistent with badges; the badge text is treated as the source of truth.
7. **Read-only fields** (Verification Status, Reviews/Recommendations) are system-generated – do not render as user inputs.
8. **Athlete #10 (Coach)** says "optional, but recommended" while its priority badge is **High** – so it is not mandatory.
