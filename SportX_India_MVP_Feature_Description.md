# SportX India — MVP Feature Description Document

**Document Type:** MVP Scope & Feature Specification
**Platform:** Flutter Mobile Application (Android)
**Version:** 1.0 — Minimum Viable Product
**Prepared For:** Client Review & Development Reference

---

## Overview

SportX India MVP is a Flutter-based Android application designed to connect Athletes, Coaches & Academies, and Sponsors within the Indian sports ecosystem. The MVP introduces four distinct user roles — **Admin**, **Athlete**, **Coach/Academy**, and **Sponsor** — each with a tailored interface, defined access permissions, and role-specific features.

The goal of the MVP is to establish the core platform experience: professional profile creation, role-based discovery, cross-role connectivity, and a targeted notification system — all within a clean, modern sports-themed UI.

---

## User Roles

The platform supports the following four roles:

| Role | Description |
|---|---|
| Admin | Platform manager with backend control |
| Athlete | Sports players and student athletes |
| Coach / Academy | Coaches, trainers, and sports academies |
| Sponsor | Brands and organizations offering sports opportunities |

---

## Role 1 — Admin

### Role Description
The Admin is the platform controller responsible for managing users, content, and platform integrity. The Admin operates via a dedicated web-based Admin Panel (separate from the Flutter app) and holds complete oversight of all platform activity.

### Admin Capabilities

**User Management**
- View, approve, suspend, or remove any user account across all roles
- Verify and badge athlete, coach/academy, and sponsor profiles

**Content & Post Moderation**
- Review and remove reported posts or inappropriate content
- Monitor platform-wide activity and community posts

**Notification Management**
- Compose and broadcast push notifications to specific roles or regions
- Send notifications related to trials, selections, tournaments, camps, and sponsorship opportunities
- Target notifications by sport category or geographic region (state/city)

**Opportunity Management**
- Approve or reject opportunities and event listings posted by Sponsors or Academies
- Ensure listings are authentic and appropriate before they reach athletes

**Platform Reports & Dashboard**
- View registered user counts by role, region, and sport category
- Access basic activity metrics to monitor platform health

---

## Role 2 — Athlete

### Role Description
Athletes are the primary users of SportX India. This role is designed for sports players at all levels — school, college, state, or national — including NCC sports participants and student athletes. The Athlete role is built to give every player a professional digital identity, the ability to network with peers, and direct access to opportunities relevant to their sport and region.

### 2a. Own Profile

Each Athlete has a dedicated personal profile serving as their digital sports identity. The profile includes:

- **Profile Photo** — Personal photo upload
- **Full Name & Bio** — Short introduction and personal sports story
- **Sport Category** — Primary sport (e.g., Cricket, Football, Athletics, etc.)
- **Location** — State and city
- **Achievements & Certificates** — Upload and display awards, certificates, and recognition
- **Tournament Participation History** — Record of events and competitions attended
- **Performance Statistics** — Basic self-reported performance data relevant to their sport
- **Highlight Photos & Videos** — A media gallery to showcase their best sporting moments
- **Social Media Links** — Optional links to external profiles

The athlete can edit and update their profile at any time to keep it current.

### 2b. Viewing Other Profiles

Athletes can browse and view the profiles of:

- **Other Athletes** — Discover peers across different sports, states, and achievement levels
- **Coaches & Academies** — View academy details, coaching staff, and associated sports
- **Sponsors** — View sponsor profiles and the opportunities they have listed

Profile viewing is accessible through search, discovery feeds, or direct connection.

### 2c. Connections with Other Athletes

Athletes can build a professional sports network exclusively with fellow athletes through a **connection system**:

- Send and receive connection requests to/from other athletes
- View a personal connections list
- Browse connected athletes' profiles and activity

> **In-App Messaging (Bare Minimum):** A basic direct messaging feature between connected athletes is included within available resources. This enables simple text-based communication between connected peers for networking and coordination purposes.

### 2d. Academies & Coaches Section

Athletes have access to a dedicated **Academies & Coaches** directory where they can:

- Browse and search listed coaches and academies
- View full academy/coach profiles including sport specialisation, location, and contact details
- Discover academies offering trials, training programs, or workshops
- Receive notifications from academies relevant to their sport and region

### 2e. Sponsors Section

Athletes have access to a **Sponsors & Opportunities** section where they can:

- Browse sponsor profiles and active sponsorship listings
- View opportunity details (eligibility, sport category, region, deadline)
- Express interest or apply for sponsorships and funding opportunities
- Receive notifications about new sponsorship openings relevant to their sport

---

## Role 3 — Coach / Academy

### Role Description
This role covers individual coaches, trainers, and registered sports academies. Coaches and Academies use the platform to establish a credible professional presence, discover talented athletes, and connect with potential sponsors for funding and support.

### 3a. Own Profile

Each Coach or Academy has a professional profile that includes:

- **Profile Photo / Academy Logo**
- **Name & Bio** — Individual coach bio or academy overview
- **Sport Specialisation** — Sports they coach or train athletes in
- **Location** — State and city of operation
- **Credentials & Certifications** — Coaching licenses, affiliations, and achievements
- **Facilities & Programs** — Description of training facilities, camps, or programs offered
- **Associated Athletes** — Optional showcase of athletes they have trained
- **Contact / Inquiry Details**

The profile serves as a discovery page for athletes seeking training and for sponsors seeking credible sports institutions to support.

### 3b. Athletes Directory

Coaches and Academies can access the full **Athletes Directory** to:

- Browse and search athlete profiles by sport, location, age category, and achievement level
- View complete athlete profiles including stats, achievements, and highlight media
- Identify potential recruits or trial candidates
- Reach out to athletes (subject to connection/messaging availability)

### 3c. Sponsors Section

Coaches and Academies can access the **Sponsors** section to:

- Browse sponsor profiles and available funding/support opportunities
- View sponsorship listings that may be applicable to their academy or athletes
- Connect with sponsors for potential partnerships, equipment support, or event funding

---

## Role 4 — Sponsor

### Role Description
Sponsors are brands, organisations, or individuals who wish to support athletes, academies, or sporting events through funding, equipment, or other opportunities. The Sponsor role provides tools to discover talent, publish opportunities, and build meaningful partnerships within the Indian sports community.

### 4a. Own Profile

Each Sponsor has a branded profile on the platform that includes:

- **Logo / Brand Photo**
- **Organisation Name & Description** — Who they are and what they support
- **Industry / Category** — e.g., Sportswear, Nutrition, Financial Services, etc.
- **Location / Coverage Area**
- **Active Opportunities Listed** — Sponsorships and opportunities currently open
- **Past Associations** — Optional showcase of previous athletes or events supported

The sponsor profile builds trust and credibility within the athlete and coach community.

### 4b. Athletes Directory

Sponsors can access the full **Athletes Directory** to:

- Browse and search athlete profiles by sport, location, achievement level, and age category
- View athlete profiles including achievements, highlights, and performance data
- Identify athletes who align with their brand or sponsorship focus
- Shortlist or reach out to athletes of interest

### 4c. Coaches & Academies Directory

Sponsors can access the **Coaches & Academies** directory to:

- Browse and search academy and coach profiles
- View academy credentials, sport specialisations, and program details
- Identify academies or coaches aligned with their sponsorship goals
- Connect with academies for institutional partnerships or event sponsorships

---

## Notification System

A targeted **Push Notification System** is included in the MVP to ensure relevant information reaches the right users without noise.

### Notification Targeting
Notifications can be delivered based on:
- **Role** — Athletes, Coaches, Sponsors (or all)
- **Sport Category** — Notifications reach only users associated with the relevant sport
- **Region** — State or city-level targeting to ensure geographic relevance

### Notification Types
| Notification Type | Relevant Role(s) |
|---|---|
| Trial announcements | Athletes |
| Selection updates | Athletes |
| Tournament information | Athletes, Coaches |
| Camp & workshop alerts | Athletes, Coaches |
| New sponsorship opportunities | Athletes, Coaches |
| New athlete profiles (for sponsors) | Sponsors |
| Platform updates & announcements | All Roles |

Notifications are sent by the Admin or, in the case of opportunity listings, triggered when an approved Sponsor or Academy publishes a new listing.

---

## Search & Discovery

The platform includes a **Search & Discovery** module available to all roles, enabling users to find relevant profiles quickly.

**Athletes can be searched/filtered by:**
- Sport category
- State / City
- Achievement level
- Age category

**Coaches & Academies can be searched by:**
- Sport specialisation
- Location

**Sponsors can be searched by:**
- Industry/category
- Active opportunities

---

## MVP Access Summary

| Feature | Athlete | Coach / Academy | Sponsor | Admin |
|---|---|---|---|---|
| Own Profile | ✅ | ✅ | ✅ | ✅ |
| View Athlete Profiles | ✅ | ✅ | ✅ | ✅ |
| View Coach/Academy Profiles | ✅ | — | ✅ | ✅ |
| View Sponsor Profiles | ✅ | ✅ | — | ✅ |
| Connect with Athletes | ✅ | — | — | — |
| Basic Messaging (Athletes) | ✅ | — | — | — |
| Sponsor Opportunities Section | ✅ | ✅ | ✅ (post) | ✅ |
| Push Notifications | ✅ | ✅ | ✅ | ✅ (send) |
| Search & Discovery | ✅ | ✅ | ✅ | ✅ |
| User & Content Management | — | — | — | ✅ |

---

## Platform Scope — MVP

| Item | Scope |
|---|---|
| Platform | Android (Flutter) |
| Admin Panel | Web-based |
| Backend | Cloud-based, scalable |
| Media Support | Profile photos, highlight images, and short videos |
| Messaging | Basic in-app direct messaging between connected athletes |
| Future Releases | iOS app, full web platform, AI recommendations, performance analytics, verified badges |

---

## Out of Scope for MVP

The following features are acknowledged for future development and are **not included** in the MVP:

- iOS Application
- Live Streaming
- Tournament Registration System
- AI-Based Talent Recommendations
- Sports Resume / CV Generation
- Full Performance Analytics Dashboard
- Academy Partnership Portal
- Verified Badge System (admin-level only in MVP)

---

*This document defines the MVP scope for SportX India v1.0. All features described above are subject to final technical review and confirmation during the development planning phase.*
