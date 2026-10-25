# Privacy Policy — SportX India

**Effective date:** 25 October 2026  
**Last updated:** 25 October 2026

---

## Introduction

This Privacy Policy explains how **SportX India** ("**SportX**", "**we**", "**us**", or "**our**"), having its principal place of operations in Ahmedabad, Gujarat, India, collects, uses, processes, stores, discloses, and protects your personal data when you:

1. Visit or browse our informative website and landing pages;
2. Pre-register for early access or submit enquiries via our contact forms;
3. Create an account, browse, or interact across the **SportX mobile application** (available on Android and iOS), backend APIs, and web services; or
4. Use any associated services, community features, registration systems, and tools provided by SportX (collectively, the "**Services**" or the "**Platform**").

SportX operates a comprehensive discovery, networking, and connection platform for India's sports ecosystem—bringing together **Athletes and Parents/Guardians**, **Coaches**, **Sports Academies & Clubs**, **Trial and Tournament Organizers**, **Talent Scouts**, and **Allied Sports Providers** (such as sports medical professionals, physiotherapists, nutritionists, sports stores, brands, NGOs, and federations).

By accessing or using our Services, registering an account, or submitting information to us, you acknowledge that you have read, understood, and agree to the collection and use of your personal data as described in this Privacy Policy and our [Terms of Service](file:///d:/SportX%20Project/docs/Security-and-NonFunctional.md). If you do not agree, please do not access or use the Services.

---

## 1. Information We Collect

We collect only the information necessary to provide, secure, and personalize our sports ecosystem services. The types of personal data we collect depend on how you interact with the Platform and the user role you select.

### 1.1 Account & Authentication Information
* **Direct Signup & Login:** Mobile phone number or email address, password (stored strictly as a cryptographic **bcrypt** hash; plaintext passwords are never stored or accessible), and 6-digit One-Time Password (OTP) verification codes.
* **Google Sign-In ("Continue with Google"):** When you choose to authenticate via Google, we collect and verify your Google ID token server-side against Google's public JSON Web Key Sets (JWKS). We store your verified email address, full name, profile avatar URL, and Google's stable unique identifier (`sub` claim) in our `social_accounts` record. Any OAuth tokens retained are encrypted at rest using AES-256 encryption. We **do not** request or access private Gmail messages, Google Drive files, or contacts.

### 1.2 Role-Specific Profile Information
Depending on your onboarding role, you provide structured profile details:

* **Athletes:** Full name, profile photo, date of birth, age group (e.g., U-14, U-16, U-19, Senior), gender, primary and secondary sports, playing position/discipline/event, dominant hand/foot, physical metrics (height and weight, if provided), city and state of residence, short sports bio, current team or academy affiliations, coach details, competition history, performance statistics, personal bests, uploaded certificates of achievement, photos and video highlight media, sports aspirations/goals, and open opportunity preferences (trials, tournaments, scholarships, sponsorships).
* **Coaches:** Full name, profile photo and cover photo, primary sport, coaching specializations (e.g., batting, goalkeeping, fitness), coaching level (Grassroots, Youth, State, Professional), qualifications and accreditations (e.g., BCCI, AIFF, NIS certifications), years of coaching experience, current academy or team affiliations, teams and age groups coached, training programs published, coaching services offered, fee structure estimates, training locations, coaching philosophy, and professional achievements.
* **Sports Academies & Clubs:** Academy name, logo and cover image, academy type (Private, Club, School, College, Government), primary sports offered, full address, city/state, Google Maps / GPS location coordinates, description, training batch schedules, age groups trained, training facilities available (e.g., turf, practice nets, gym, floodlights, video analysis), structured training programs, admission/trial guidelines, fee information, coaching staff profiles, and business registration/affiliation documents.
* **Tournament & Trial Organizers:** Organization name, logo and banner photo, organizer type (Event Company, Federation, Club, School/College, NGO), sports managed, event categories (tournaments, trials, championships, camps, workshops), base city/state, description, past event history, and contact details.
* **Talent Scouts:** Full name, profile photo, scout type (Independent, Club, Academy, Federation), sports scouted, scouting specialization, base location, experience, affiliated sports organizations/clubs, scouting regions, and scouting credentials (e.g., AIFF Talent Identification Certificate).
* **Generalized Allied Sports Providers (Directory Profiles):** Business or professional name, category (Doctor, Physiotherapist, Sports Store, Nutritionist, Agent, Federation, Facility, Photographer, Psychologist, etc.), logo/photo, primary sports, services or products offered, operating address, city/state, contact information (phone, email, WhatsApp), and professional credentials.

### 1.3 Activities, Registrations & Applications
* **Trial & Tournament Registrations:** Information submitted when registering for trials or tournaments, including participant category, playing position, team name, required verification documents (such as age or identification proof), and unique registration tracking references (e.g., `#TR...`).
* **Opportunity Applications:** Information submitted when applying for scholarships, sponsorships, tryouts, or training camps, including personal athletic pitches, eligibility data, and athletic profile snapshots.
* **Program Enquiries:** Inquiries sent directly to coaches, academies, or organizers regarding admissions, schedules, or private training.

### 1.4 Confidential Talent Scout Data (Owner-Only Scout-Data Privacy Policy)
* When a verified Talent Scout evaluates athletes on the Platform, they may maintain **talent shortlists** (categorized under pipeline statuses such as *Under Review*, *Good*, *High*, or *Final*, accompanied by tags and private scouting notes), log **scouting observations**, and draft **player evaluation reports**.
* **Strict Confidentiality:** Under our **Scout-Data Privacy Policy**, all scouting shortlists, tags, private observations, and scout evaluation reports are **owner-only**. They are confidential to the individual scout who created them, are never visible on public athlete profiles, and are never disclosed to other users or the scouted athlete.

### 1.5 Community, Social & Communications
* **Feed & Social Interactions:** Content you post to the social feed (text, photos, training videos), comments, likes, and bookmarked/saved listings.
* **Networking (Follow & Connect):** One-way follow relationships and mutual connection requests.
* **In-App Messaging & Chat:** Direct 1-to-1 chat conversations between users with accepted mutual connections or active enquiry threads. **We do not permit unsolicited cold direct messaging.** If you block another user, communication and content visibility are severed in both directions.
* **Content Moderation & Reports:** Reason, description, and metadata submitted when reporting an inappropriate listing, post, message, or user profile.

### 1.6 Guardian Consent & Information for Minors (Under 18 Years)
* For athletes under the age of 18, we collect the **Parent or Guardian's full name, mobile phone number, relationship to the minor**, and verifiable consent timestamp via One-Time Password (OTP) verification.
* Guardian control settings (`allow_messages`, `allow_public_profile`, `leaderboard_name_mode`).

### 1.7 Automatically Collected Technical & Device Data
* **Device & Connection Data:** Device model, manufacturer, operating system and version, unique device identifiers, browser type, network carrier, and IP address.
* **Push Notification Device Tokens:** Unique Firebase Cloud Messaging (FCM) registration tokens stored in `user_device_tokens` to deliver alerts, trial reminders, and message notifications to your device.
* **App Usage & Diagnostics:** Feature usage logs, API response times, crash logs, and error metrics used strictly for debugging, platform stability, and fraud prevention.

---

## 2. How We Use Your Information

We process personal data strictly for legitimate operational, contractual, and service-delivery purposes:

| Purpose | Description |
|---|---|
| **Account Creation & Authentication** | Creating, maintaining, and verifying your account across our mobile application and APIs; authenticating sign-ins via phone/email OTP or Google Sign-In. |
| **Sports Discovery & Search** | Enabling athletes, parents, coaches, academies, and scouts to discover sports opportunities, facilities, programs, and talent through search filters (sport, city, age group, skill level). |
| **Facilitating Registrations & Applications** | Processing athlete registration requests for trials and tournaments, managing approval workflows for organizers, and submitting opportunity applications. |
| **Networking & Communication** | Enabling mutual connections, enquiry threads, and 1-to-1 in-app chat between verified connections; facilitating contact between providers and athletes/guardians. |
| **Notifications & Reminders** | Delivering transactional in-app notifications, FCM mobile push notifications, and email alerts regarding trial dates (T-2 days and T-1 day reminders), registration decisions (approved/rejected), message replies, and system updates. |
| **Verification & Trust Badge Management** | Reviewing identity documents, coach qualifications, academy affiliations, and organizer credentials submitted to obtain the verified blue checkmark badge. |
| **Leaderboard & Talent Recognition** | Computing per-sport performance rankings and leaderboards based on verified achievements (with minor anonymization controls). |
| **Safety, Moderation & Security** | Operating report queues, moderating user-generated content, preventing brute-force attacks, enforcing rate limits, preventing fraud, and resolving safety grievances. |
| **Compliance with Law** | Complying with statutory and regulatory obligations under Indian law, including court orders and requests from lawful investigative agencies. |

---

## 3. Informational Pricing & Non-Collection of Payment Data

* **No In-App Payment Gateway:** SportX does **not** process monetary transactions or payments within the app or website. We do not operate a payment gateway, and we **never** collect, process, or store financial credentials, credit card numbers, debit card numbers, net banking credentials, or UPI PINs.
* **Informational Fee Disclosures:** Any fees displayed on listings (such as tournament entry fees, trial registration charges, academy tuition, or coaching packages) are purely informational notes provided by the organizer, academy, or coach.
* **Direct Offline / External Transactions:** All financial settlements, fee collections, or prize payouts take place directly between the user and the event organizer, academy, or coach outside the SportX platform. Event organizers may manually record an informational payment status (`pending`, `paid`, `waived`) in their registrant lists for their own record-keeping.

---

## 4. Legal Basis and Consent

Under the **Digital Personal Data Protection Act, 2023 (DPDP Act)** and the **Information Technology Act, 2000**, we process your personal data based on:

1. **Consent:** Freely given, specific, informed, and unambiguous consent provided when you register an account, submit verification forms, or upload your athletic profile.
2. **Contractual Performance:** Processing necessary to deliver the Services you requested (such as facilitating trial registrations, forwarding enquiries, or transmitting in-app messages).
3. **Legal Obligations:** Processing required to comply with applicable laws, government regulations, law enforcement subpoenas, or legal proceedings in India.
4. **Legitimate Uses:** Protecting platform integrity, investigating abuse, ensuring network security, and preventing fraudulent activities.

You have the right to withdraw your consent at any time through in-app settings or by contacting our Grievance Officer. Withdrawal of consent does not affect the lawfulness of processing carried out prior to withdrawal, but may limit your ability to access certain features of the Platform.

---

## 5. Protection of Children and Young Athletes (< 18 Years)

SportX is dedicated to fostering grassroots athletic talent across India while maintaining the highest standards of child safety and privacy under the **Digital Personal Data Protection Act, 2023**:

### 5.1 Verifiable Parental / Guardian Consent Gate
* Any athlete under the age of 18 (determined by the mandatory Date of Birth field upon registration) is classified as a minor.
* **Mandatory Consent Gate:** A minor athlete's account remains in a pending, unactivated state until verifiable **Parent or Guardian Consent** is completed.
* The parent or guardian must provide their full name, relationship to the athlete, and mobile phone number, and must authenticate consent via a secure One-Time Password (OTP) sent to the guardian's contact number.

### 5.2 Guardian-Routed Communications & Shielded Profiles
* **Hidden Contact Details:** Personal contact details (phone numbers, email addresses) of minor athletes are strictly hidden from public discovery views.
* **Guardian-Routed Contact:** Inquiries, contact requests, and connection requests from talent scouts, coaches, or academies regarding a minor athlete are routed directly to the verified parent or guardian.
* **No Unsolicited Direct Messaging:** Third parties cannot initiate cold direct messages with minor athletes. In-app chat is unlocked only after a connection is explicitly accepted with guardian authorization.

### 5.3 Anonymized Leaderboards
* By default, minor athletes on public leaderboards and rankings are displayed in an anonymized format (such as first name with last initial, e.g., *"Aryan P."*) or hidden, in accordance with the guardian's selected preferences (`leaderboard_name_mode`).

### 5.4 Guardian Control Dashboard
* Parents and guardians retain ongoing authority through the Platform's Guardian Controls (`GET/PUT /me/guardian-controls`), enabling them to adjust profile visibility, manage who can message or connect, or request immediate deletion of the minor's account and data.

---

## 6. Information Sharing and Disclosure

We respect your privacy and **do not sell, rent, or trade your personal information** to data brokers or third-party advertisers. We share information only under the following limited circumstances:

### 6.1 Within the Platform Ecosystem
* **Public Profiles:** Information you choose to include in your public athletic, coach, academy, organizer, scout, or provider profile is discoverable by other registered users in accordance with your privacy settings.
* **Registrations & Applications:** When an athlete registers for a trial or tournament, or applies for an opportunity (scholarship, sponsorship, tryout), their application details, profile snapshot, and uploaded registration documents are shared with the respective organizer, academy, or provider managing that listing.
* **Scout Confidentiality:** Under our Scout-Data Privacy Policy, scouting shortlists, evaluation ratings, and private notes are strictly restricted to the authoring scout and are **never** shared with other users or the athlete.

### 6.2 Trusted Service Providers
We share data with third-party service providers who assist us in operating our infrastructure, subject to strict confidentiality, security obligations, and data processing agreements:
* **Cloud Hosting & Private Object Storage:** Secure cloud servers and S3-compatible private object storage for media files and verification documents (served via time-limited, expiring signed URLs).
* **Push Notification Infrastructure:** **Firebase Cloud Messaging (Google FCM HTTP v1)** to deliver real-time push alerts and reminders to registered device tokens.
* **Email Delivery Systems:** Secure transactional email infrastructure (including SMTP relays and Google Workspace / Gmail REST API over OAuth 2.0 with SPF, DKIM, and DMARC enforcement) used strictly to deliver verification codes, password resets, and critical account notices.
* **Form Submission Handlers:** Form-processing tools (such as Formspree) used solely for handling pre-launch landing page enquiries.

### 6.3 Legal Compliance & Protection of Rights
We may disclose personal data if required to do so by applicable Indian law, regulation, judicial decree, warrant, or official directive from a competent law enforcement authority or court of law, or where necessary to:
* Investigate potential violations of our Terms of Service;
* Detect, prevent, or address fraud, security breaches, or technical vulnerabilities; or
* Protect the safety, rights, and property of SportX users, young athletes, or the general public.

### 6.4 Business Reorganization
In the event of a merger, acquisition, financing due diligence, corporate restructuring, or sale of assets, user data may be transferred as part of the business assets. In such circumstances, the acquirer will remain bound by the commitments set out in this Privacy Policy, and users will be notified of any material changes.

---

## 7. Third-Party Integrations & External Links

### 7.1 Google Sign-In
When you use "Continue with Google," authentication is handled through Google Identity Services. Your interaction is governed by Google’s Privacy Policy. SportX verifies the issued ID token server-side and requests only basic profile identity (`email`, `profile`).

### 7.2 WhatsApp and Direct Phone Contact
Our platform and website may feature direct WhatsApp or phone buttons to enable users to contact verified academies, organizers, or SportX support. Clicking these links opens WhatsApp or your phone dialer, which are operated independently by third parties under their respective privacy policies. SportX does not monitor or store private conversations conducted off-platform on WhatsApp or cellular networks.

### 7.3 External Venue Links & Map Previews
Tournament and trial listings often provide Google Maps coordinates or location links to assist athletes with venue navigation. These map links navigate to external services governed by third-party terms and privacy policies.

---

## 8. Cookies, Local Storage & Session Technologies

* **Website Cookies:** Our informative website uses basic, essential cookies to maintain page functionality, remember preferences, and safeguard against cross-site request forgery (CSRF). You can manage or disable cookies via your browser settings, though certain interactive features may become unavailable.
* **Mobile App Local Storage:** The SportX mobile application utilizes secure client-side storage (`shared_preferences`) solely to store your authentication session token (Laravel Sanctum bearer token) and localized display preferences (e.g., active role state). We do not use intrusive cross-app ad tracking technologies.

---

## 9. Data Storage, Security & Protection Measures

We employ robust physical, technical, and managerial safeguards designed to protect personal data from loss, unauthorized access, alteration, disclosure, or destruction:

1. **Cryptographic Password Protection:** All account passwords are encrypted using **bcrypt** hashing with adaptive cost factors. Passwords are never stored in plain text.
2. **OTP Security:** One-Time Passwords (OTPs) are cryptographically hashed, rate-limited (maximum 5 attempts per code, 60-second cooldown), and automatically expire within 5 minutes.
3. **Encrypted Credentials at Rest:** Third-party OAuth tokens and secrets stored in our database utilize AES-256 encryption.
4. **Transport Layer Encryption:** All network communication between the mobile app, website, and our APIs is strictly encrypted in transit using **TLS 1.2 / TLS 1.3 (HTTPS)**.
5. **Private Document Storage:** Sensitive identity proof and registration documents are stored in private cloud storage buckets, inaccessible to the public, and served strictly via expiring, cryptographically signed URLs.
6. **Role-Based Access Control (RBAC) & Policies:** Backend API endpoints enforce ownership policies (e.g., coach profiles are editable only by the owning coach; scout shortlists are accessible solely by the authoring scout; conversation threads are restricted to verified participants).
7. **Administrative Security (2FA):** Administrative portal access requires dedicated credentials and mandatory Time-Based One-Time Password (**TOTP 2FA**).
8. **Rate Limiting & Abuse Prevention:** API routes are protected by tiered rate limiters to prevent brute-force attacks, scraping, and spam.

*While we implement rigorous, industry-aligned safeguards, no electronic transmission or cloud storage system can be guaranteed to be 100% immune from compromise. Users are urged to maintain strong passwords and safeguard their login credentials.*

---

## 10. Data Retention & Account Deletion

### 10.1 Retention Period
We retain your personal data only for as long as your account remains active or as necessary to fulfill the purposes set out in this Policy, resolve disputes, enforce agreements, or comply with statutory retention requirements under Indian law.

### 10.2 Immediate Self-Service Account Deletion
You maintain complete control over your data. You may permanently delete your account at any time directly within the SportX mobile application:
* Navigate to: **Settings → Delete Account**;
* Enter your account password or verify via OTP to confirm your identity;
* Upon confirmation, the system triggers `DELETE /me/account`. Your public profile, media, registrations, opportunities, and saved items are **immediately and permanently removed from public view**.

### 10.3 Purge Schedule & Backups
* Following an account deletion request, user data is marked for permanent deletion.
* Backup snapshots and historical system audit logs (retained strictly for financial reconciliation, legal dispute defense, and platform security) are automatically purged within **90 days** in accordance with our hard-purge lifecycle.

---

## 11. Your Legal Rights

Subject to the **Digital Personal Data Protection Act, 2023 (DPDP Act)** and the **Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011**, you (or a parent/guardian acting on behalf of a minor) have the following rights as a Data Principal:

1. **Right to Access & Summary:** Request a summary of the personal data we hold about you and the processing activities undertaken.
2. **Right to Correction & Updating:** Request the correction, completion, or updating of inaccurate, misleading, or outdated personal information via your in-app profile editor or support.
3. **Right to Erasure / Deletion:** Request the complete deletion of your account and personal data, accessible self-service via **Settings → Delete Account**.
4. **Right to Withdraw Consent:** Withdraw previously granted consent for processing at any time.
5. **Right to Grievance Redressal:** Register grievances regarding data handling with our designated Grievance Officer, who is obligated to resolve complaints within statutory timeframes.
6. **Right to Nominate:** Nominate another individual to exercise your data rights in the event of death or incapacity, as recognized under the DPDP Act.

To exercise any of these rights, please submit a written request to our Grievance Officer at the contact details provided below. We will verify your identity before processing the request and respond within a reasonable, legally prescribed timeframe.

---

## 12. Changes to This Privacy Policy

We may periodically revise this Privacy Policy to reflect enhancements in our Services, changes in technology, or evolving legal and regulatory frameworks. 

When updates are made, we will update the "**Last updated**" date at the top of this page. For significant or material changes that impact your privacy rights, we will provide prominent advance notice through an in-app announcement banner, push notification, or email before the changes become effective. Your continued use of the Services after the effective date of an updated Privacy Policy constitutes your acceptance of the revised terms.

---

## 13. Grievance Officer & Contact Us

In compliance with the **Information Technology Act, 2000**, the **Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules, 2021**, and the **Digital Personal Data Protection Act, 2023**, the contact details for our designated Grievance Officer and corporate office are:

* **Entity:** SportX India
* **Attn / Designation:** Grievance Officer / Data Protection Team
* **Address:** Ahmedabad, Gujarat, India — 380015
* **Email:** [sportxconnect@gmail.com](mailto:sportxconnect@gmail.com)
* **WhatsApp / Phone Support:** [+91 87994 38783](https://wa.me/918799438783)
* **Website:** [sportx.in](https://sportx.in)

If you have any questions, concerns, feedback, or grievances regarding our privacy practices, please contact us at [sportxconnect@gmail.com](mailto:sportxconnect@gmail.com). We are committed to addressing and resolving all inquiries expeditiously.
