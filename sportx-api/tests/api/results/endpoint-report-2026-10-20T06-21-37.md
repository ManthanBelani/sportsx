# SportX API — endpoint test report

**Base URL:** http://127.0.0.1:8000  
**Generated:** 2026-10-20T06:21:37.833Z  
**Flags:** destructive=true, cleanup=true

| Suite | Pass | Soft | Fail | Skip |
|---|---|---|---|---|
| Boot | 7 | 0 | 0 | 0 |
| Admin | 1 | 0 | 0 | 41 |
| Public | 33 | 0 | 0 | 0 |
| Auth | 11 | 0 | 0 | 0 |
| RBAC Guard | 35 | 0 | 0 | 0 |
| Organizer | 18 | 0 | 3 | 0 |
| Lifecycle | 16 | 0 | 4 | 8 |
| Enrollment | 7 | 0 | 1 | 0 |
| Coach | 32 | 0 | 0 | 0 |
| Academy | 9 | 0 | 1 | 0 |
| Athlete | 41 | 0 | 1 | 0 |
| Social | 29 | 0 | 4 | 0 |
| Enquiries | 7 | 0 | 0 | 1 |
| Sponsor | 10 | 0 | 0 | 0 |
| Talent Scout | 19 | 0 | 1 | 0 |
| Cleanup | 0 | 0 | 0 | 6 |

## Checks

| Suite | Method | Check | Expected | Got | Result | Note |
|---|---|---|---|---|---|---|
| Boot | POST | login athlete | 200 | 200 | ✓ pass |  |
| Boot | POST | login athlete2 | 200 | 200 | ✓ pass |  |
| Boot | POST | login coach | 200 | 200 | ✓ pass |  |
| Boot | POST | login academy | 200 | 200 | ✓ pass |  |
| Boot | POST | login organizer | 200 | 200 | ✓ pass |  |
| Boot | POST | login sponsor | 200 | 200 | ✓ pass |  |
| Boot | POST | login scout | 200 | 200 | ✓ pass |  |
| Admin | POST | /admin/login | 200 | 200 | ✓ pass |  |
| Public | GET | / | 200 | 200 | ✓ pass |  |
| Public | GET | /health | 200 | 200 | ✓ pass |  |
| Public | GET | /system/health | 200 | 200 | ✓ pass |  |
| Public | GET | /meta/sports | 200 | 200 | ✓ pass |  |
| Public | GET | /meta/cities | 200 | 200 | ✓ pass |  |
| Public | GET | /meta/age-groups | 200 | 200 | ✓ pass |  |
| Public | GET | /meta/positions | 200 | 200 | ✓ pass |  |
| Public | GET | /meta/facilities | 200 | 200 | ✓ pass |  |
| Public | GET | /meta/trending-searches | 200 | 200 | ✓ pass |  |
| Public | GET | /academies | 200 | 200 | ✓ pass |  |
| Public | GET | /academies/1 | 200 | 200 | ✓ pass |  |
| Public | GET | /coaches | 200 | 200 | ✓ pass |  |
| Public | GET | /coaches/1 | 200 | 200 | ✓ pass |  |
| Public | GET | /trials | 200 | 200 | ✓ pass |  |
| Public | GET | /trials/4 | 200 | 200 | ✓ pass |  |
| Public | GET | /tournaments | 200 | 200 | ✓ pass |  |
| Public | GET | /tournaments/4 | 200 | 200 | ✓ pass |  |
| Public | GET | /tournaments/4/results | 200 | 200 | ✓ pass |  |
| Public | GET | /opportunities?type=scholarship | 200 | 200 | ✓ pass |  |
| Public | GET | /opportunities?type=sponsorship | 200 | 200 | ✓ pass |  |
| Public | GET | /opportunities/1 | 200 | 200 | ✓ pass |  |
| Public | GET | /programs | 200 | 200 | ✓ pass |  |
| Public | GET | /programs/1 | 200 | 200 | ✓ pass |  |
| Public | GET | /sports-venues | 200 | 200 | ✓ pass |  |
| Public | GET | /sports-venues/1 | 200 | 200 | ✓ pass |  |
| Public | GET | /explore | 200 | 200 | ✓ pass |  |
| Public | GET | /search?q=cricket | 200 | 200 | ✓ pass |  |
| Public | GET | /organizers/1 | 200 | 200 | ✓ pass |  |
| Public | GET | /scholarships | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Public | GET | /scholarships/1 | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Public | GET | /sponsorships | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Public | GET | /sponsorships/1 | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Public | GET | /definitely-not-a-route | 404 | 404 | ✓ pass | Endpoint not found. |
| Auth | POST | /auth/login | 401 | 401 | ✓ pass | Invalid credentials |
| Auth | POST | /auth/login | 401 | 401 | ✓ pass | Invalid credentials |
| Auth | POST | /auth/register | 422 | 422 | ✓ pass | The given data was invalid. |
| Auth | POST | /auth/register | 410 | 410 | ✓ pass | Sponsor accounts are no longer offered. Providers list scholarships and sponsorships as opportunities instead. |
| Auth | POST | /auth/register | 201 | 201 | ✓ pass | Registration successful. |
| Auth | POST | /auth/forgot-password | 200 | 200 | ✓ pass | If an account exists, a reset link has been sent |
| Auth | POST | /auth/send-otp | 422 | 422 | ✓ pass | The given data was invalid. |
| Auth | GET | /auth/me | 401 | 401 | ✓ pass | Unauthenticated. |
| Auth | GET | /me/profile | 401 | 401 | ✓ pass | Unauthenticated. |
| Auth | GET | /admin/dashboard | 401 | 401 | ✓ pass | Unauthenticated. |
| Auth | GET | /me/activity | 401 | 401 | ✓ pass | Unauthenticated. |
| RBAC Guard | GET | /me/coach-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/academy | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/organizer | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/facilities | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /coach/enrollments | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/scout-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/scout-shortlist | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/organizer/analytics | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | POST | /me/programs | 403 | 403 | ✓ pass | Only coach or academy accounts can post programs. |
| RBAC Guard | GET | /admin/dashboard | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /admin/users | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /admin/settings | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /admin/verification | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | PATCH | /admin/verification/1/approve | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/academy | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/facilities | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/organizer | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /scouts | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /athletes | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /observations | 403 | 403 | ✓ pass | Scout profile required. |
| RBAC Guard | GET | /admin/users | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | POST | /trials/4/register | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | POST | /coaches/1/enroll | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/coach-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/scout-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/organizer | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/coach-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/facilities | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /scouts | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/scout-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /coach/enrollments | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | POST | /opportunities/1/apply | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /coach/enrollments | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/facilities | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/coach-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| Organizer | GET | /auth/me | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/organizer | 200 | 200 | ✓ pass |  |
| Organizer | PUT | /me/organizer | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/organizer/analytics | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/events?filter=all | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/events?type=trial | 201 | 201 | ✓ pass |  |
| Organizer | PUT | /me/events/9?type=trial | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/events/9/publish?type=trial | 200 | 200 | ✓ pass |  |
| Organizer | GET | /events/9 | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/events?type=tournament | 201 | 201 | ✓ pass |  |
| Organizer | PUT | /me/events/11?type=tournament | 200 | 200 | ✓ pass |  |
| Organizer | GET | /tournaments/11 | 200 | 404 | ✗ FAIL | Endpoint not found. |
| Organizer | PUT | /me/tournaments/11/categories | 200 | 500 | ✗ FAIL | SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry '11-1' for key 'tournament_categories_tournament_i |
| Organizer | POST | /me/events/11/publish?type=tournament | 200 | 200 | ✓ pass |  |
| Organizer | PUT | /tournaments/11/capacity | 200 | 422 | ✗ FAIL | The given data was invalid. |
| Organizer | GET | /tournaments/11/capacity | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/opportunities | 201 | 201 | ✓ pass |  |
| Organizer | PUT | /me/opportunities/8 | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/opportunities/8/publish | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/opportunities | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/home | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /trials/9/register | 201 | 201 | ✓ pass | Registration request submitted successfully |
| Lifecycle | GET | /me/registrations/trials | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /trials/9/registrations | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /trials/9/pending-requests | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /registrations/trials/4/verify | 200 | 200 | ✓ pass | Trial registration approved |
| Lifecycle | PATCH | /registrations/trials/4/approve | 200 | 200 | ✓ pass | Trial registration approved |
| Lifecycle | GET | /registrations/trials/4 | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /registrations/trials/4/ics | 200 | 200 | ✓ pass | BEGIN:VCALENDAR VERSION:2.0 PRODID:-//SportX//Event Calendar//EN CALSCALE:GREGORIAN BEGIN:VEVENT UID:trial-4@s |
| Lifecycle | POST | /tournaments/11/register | 200 | 422 | ✗ FAIL | The given data was invalid. |
| Lifecycle | GET | /me/registrations/tournaments | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /tournaments/11/register | 200 | 422 | ✗ FAIL | The given data was invalid. |
| Lifecycle | GET | /me/registrations/tournaments | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /tournaments/11/pending-requests | 200 | 200 | ✓ pass |  |
| Lifecycle | PATCH | PATCH /registrations/tournaments/{reg}/approve (owner) | 200 | SKIP | ⤼ skip | unresolved context: myTournRegId |
| Lifecycle | PATCH | PATCH /registrations/tournaments/{reg}/payment (owner) | 200 | SKIP | ⤼ skip | unresolved context: myTournRegId |
| Lifecycle | PATCH | PATCH /registrations/tournaments/{reg}/reject (ath2, owner) | 200 | SKIP | ⤼ skip | unresolved context: ath2TournRegId |
| Lifecycle | POST | /events/11/registrations/bulk?type=tournament | 200 | 422 | ✗ FAIL | The given data was invalid. |
| Lifecycle | GET | /events/11/registrations?type=tournament | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /events/11/registrations/export?type=tournament | 200 | 200 | ✓ pass | id,athlete,status,payment_status,created_at  |
| Lifecycle | GET | GET /registrations/{reg} (unified) | 200 | SKIP | ⤼ skip | unresolved context: myTournRegId |
| Lifecycle | GET | GET /registrations/tournaments/{reg}/ics | 200 | SKIP | ⤼ skip | unresolved context: myTournRegId |
| Lifecycle | POST | /tournaments/11/results | 201 | 422 | ✗ FAIL | The given data was invalid. |
| Lifecycle | POST | POST /tournaments/{t}/results/{r}/publish | 200 | SKIP | ⤼ skip | unresolved context: orgResultId |
| Lifecycle | GET | /tournaments/11/results | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | POST /tournaments/{t}/results/{r}/unpublish | 200 | SKIP | ⤼ skip | unresolved context: orgResultId |
| Lifecycle | POST | POST /tournaments/{t}/results/{r}/publish (restore) | 200 | SKIP | ⤼ skip | unresolved context: orgResultId |
| Lifecycle | POST | /me/events/9/close?type=trial | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /me/events/11/close?type=tournament | 200 | 200 | ✓ pass |  |
| Enrollment | POST | /coaches/1/enroll | 200/201 | 201 | ✓ pass | Enrollment request submitted |
| Enrollment | GET | /me/coaching-enrollments | 200 | 200 | ✓ pass |  |
| Enrollment | GET | /coach/enrollments | 200 | 200 | ✓ pass |  |
| Enrollment | PATCH | /coaching-enrollments/4/approve | 200 | 200 | ✓ pass | Enrollment approved |
| Enrollment | POST | /coaches/1/enroll | 200/201 | 201 | ✓ pass | Enrollment request submitted |
| Enrollment | GET | /coach/enrollments | 200 | 200 | ✓ pass |  |
| Enrollment | PATCH | /coaching-enrollments/5/reject | 200 | 422 | ✗ FAIL | The given data was invalid. |
| Enrollment | GET | /me/coaching-enrollments | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/coach-profile | 200 | 200 | ✓ pass |  |
| Coach | PUT | /me/coach-profile | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/events?filter=all | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/trials | 201 | 201 | ✓ pass |  |
| Coach | PUT | /me/trials/10 | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/trials/10/publish | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/trials/10/close | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/programs | 201 | 201 | ✓ pass |  |
| Coach | PUT | /me/programs/8 | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/programs | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/enquiries | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/activity | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/completion-checklist | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/settings | 200 | 200 | ✓ pass |  |
| Coach | PUT | /me/settings | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/social-links | 200 | 200 | ✓ pass |  |
| Coach | PUT | /me/social-links | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/privacy | 200 | 200 | ✓ pass |  |
| Coach | PUT | /me/privacy | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/notification-preferences | 200 | 200 | ✓ pass |  |
| Coach | PUT | /me/notification-preferences | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/change-password | 401 | 401 | ✓ pass | Current password is incorrect |
| Coach | POST | /me/device-tokens/subscribe | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/device-tokens/test | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/notifications | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/notifications/read-all | 200 | 200 | ✓ pass |  |
| Coach | POST | /analytics/events | 201 | 201 | ✓ pass |  |
| Coach | POST | /me/recent-searches | 200/201 | 201 | ✓ pass |  |
| Coach | GET | /me/recent-searches | 200 | 200 | ✓ pass |  |
| Coach | GET | /leaderboard | 200 | 200 | ✓ pass |  |
| Coach | GET | /leaderboard/strip | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/home | 200 | 200 | ✓ pass |  |
| Academy | GET | /me/academy | 200 | 200 | ✓ pass |  |
| Academy | PUT | /me/academy | 200 | 422 | ✗ FAIL | The given data was invalid. |
| Academy | POST | /me/facilities | 201 | 201 | ✓ pass |  |
| Academy | PUT | /me/facilities/8 | 200 | 200 | ✓ pass |  |
| Academy | GET | /me/facilities | 200 | 200 | ✓ pass |  |
| Academy | DELETE | /me/facilities/8 | 200 | 200 | ✓ pass |  |
| Academy | GET | /me/enquiries | 200 | 200 | ✓ pass |  |
| Academy | GET | /me/home | 200 | 200 | ✓ pass |  |
| Academy | GET | /me/completion-checklist | 200 | 200 | ✓ pass |  |
| Academy | GET | /me/activity | 200 | 200 | ✓ pass |  |
| Athlete | GET | /auth/me | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/profile | 200 | 200 | ✓ pass |  |
| Athlete | PUT | /me/profile | 200 | 200 | ✓ pass |  |
| Athlete | PUT | /me/profile/sports | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/completion-checklist | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/home | 200 | 200 | ✓ pass |  |
| Athlete | GET | /explore | 200 | 200 | ✓ pass |  |
| Athlete | GET | /search?q=football | 200 | 200 | ✓ pass |  |
| Athlete | GET | /leaderboard | 200 | 200 | ✓ pass |  |
| Athlete | GET | /leaderboard/strip | 200 | 200 | ✓ pass |  |
| Athlete | GET | /athletes | 200 | 200 | ✓ pass |  |
| Athlete | GET | /athletes/1 | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/settings | 200 | 200 | ✓ pass |  |
| Athlete | PUT | /me/settings | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/privacy | 200 | 200 | ✓ pass |  |
| Athlete | PUT | /me/privacy | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/social-links | 200 | 200 | ✓ pass |  |
| Athlete | PUT | /me/social-links | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/activity | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/notifications | 200 | 200 | ✓ pass |  |
| Athlete | PATCH | /me/notifications/1/read | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/notification-preferences | 200 | 200 | ✓ pass |  |
| Athlete | PUT | /me/notification-preferences | 200 | 200 | ✓ pass |  |
| Athlete | POST | /analytics/events | 201 | 201 | ✓ pass |  |
| Athlete | POST | /me/saved | 200/201 | 201 | ✓ pass |  |
| Athlete | GET | /me/saved | 200 | 200 | ✓ pass |  |
| Athlete | DELETE | /me/saved | 200 | 200 | ✓ pass |  |
| Athlete | POST | /me/achievements | 201 | 201 | ✓ pass |  |
| Athlete | PUT | /me/achievements/3 | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/achievements | 200 | 200 | ✓ pass |  |
| Athlete | DELETE | /me/achievements/3 | 200 | 200 | ✓ pass |  |
| Athlete | POST | /media/upload | 200 | 201 | ✗ FAIL |  |
| Athlete | GET | /me/media | 200 | 200 | ✓ pass |  |
| Athlete | GET | /media/51/signed-url | 200 | 200 | ✓ pass |  |
| Athlete | DELETE | /media/51 | 200 | 200 | ✓ pass |  |
| Athlete | POST | /me/verification | 200/201 | 201 | ✓ pass |  |
| Athlete | GET | /me/verification | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/guardian-controls | 200 | 200 | ✓ pass |  |
| Athlete | POST | /reports | 201 | 201 | ✓ pass |  |
| Athlete | GET | /me/reports | 200 | 200 | ✓ pass |  |
| Athlete | GET | /observations | 403 | 403 | ✓ pass | Scout profile required. |
| Athlete | GET | /scout/dashboard | 403 | 403 | ✓ pass | Scout profile required. |
| Social | POST | /connections | 200/201 | 201 | ✓ pass |  |
| Social | POST | /me/connections/request | 200 | 409 | ✗ FAIL | Connection request already exists. |
| Social | GET | /me/connections | 200 | 200 | ✓ pass |  |
| Social | GET | /me/connections/requests | 200 | 200 | ✓ pass |  |
| Social | POST | /me/connections/12/accept | 200 | 200 | ✓ pass |  |
| Social | GET | /me/connections/count | 200 | 200 | ✓ pass |  |
| Social | GET | /me/connections/status/5 | 200 | 200 | ✓ pass |  |
| Social | POST | /conversations | 200 | 200 | ✓ pass |  |
| Social | POST | /me/conversations | 200 | 200 | ✓ pass |  |
| Social | GET | /me/conversations | 200 | 200 | ✓ pass |  |
| Social | GET | /conversations/1 | 200 | 200 | ✓ pass |  |
| Social | GET | /conversations/1 | 200 | 403 | ✗ FAIL |  |
| Social | POST | /conversations/1/messages | 201 | 201 | ✓ pass |  |
| Social | POST | /conversations/1/read | 200 | 403 | ✗ FAIL |  |
| Social | PUT | /conversations/1/read | 200 | 403 | ✗ FAIL |  |
| Social | POST | /follow/user/5 | 200/201 | 201 | ✓ pass |  |
| Social | GET | /me/following | 200 | 200 | ✓ pass |  |
| Social | GET | /me/followers | 200 | 200 | ✓ pass |  |
| Social | DELETE | /follow/user/5 | 200 | 200 | ✓ pass |  |
| Social | GET | /feed | 200 | 200 | ✓ pass |  |
| Social | GET | /posts | 200 | 200 | ✓ pass |  |
| Social | POST | /posts | 201 | 201 | ✓ pass |  |
| Social | GET | /posts/4 | 200 | 200 | ✓ pass |  |
| Social | PATCH | /posts/4 | 200 | 200 | ✓ pass |  |
| Social | POST | /posts/4/like | 200 | 200 | ✓ pass |  |
| Social | GET | /posts/4/comments | 200 | 200 | ✓ pass |  |
| Social | POST | /posts/4/comments | 201 | 201 | ✓ pass |  |
| Social | DELETE | /comments/3 | 200 | 200 | ✓ pass |  |
| Social | DELETE | /posts/4/like | 200 | 200 | ✓ pass |  |
| Social | DELETE | /posts/4 | 200 | 200 | ✓ pass |  |
| Social | POST | /blocks | 200/201 | 201 | ✓ pass |  |
| Social | GET | /blocks | 200 | 200 | ✓ pass |  |
| Social | DELETE | /blocks/26 | 200 | 200 | ✓ pass | note: if register block failed earlier this 404s — soft |
| Enquiries | POST | /enquiries | 201 | 201 | ✓ pass |  |
| Enquiries | GET | /me/enquiries | 200 | 200 | ✓ pass |  |
| Enquiries | GET | /enquiries/5 | 200 | 200 | ✓ pass |  |
| Enquiries | POST | /enquiries/5/messages | 201 | 201 | ✓ pass |  |
| Enquiries | POST | POST /enquiries/{id}/messages (admin reply) | 201 | SKIP | ⤼ skip | no token for admin |
| Enquiries | PUT | /enquiries/5/read | 200 | 200 | ✓ pass |  |
| Enquiries | POST | /opportunities/8/apply | 200/201 | 201 | ✓ pass |  |
| Enquiries | GET | /me/opportunities?type=applied | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /auth/me | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /athletes | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /athletes/1 | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /opportunities/8/applications | 200 | 200 | ✓ pass |  |
| Sponsor | PATCH | /opportunities/8/applications/7 | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /me/sponsorships | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Sponsor | POST | /me/sponsorships | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Sponsor | GET | /me/shortlist | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Sponsor | POST | /me/shortlist | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Sponsor | GET | /me/applications | 410 | 410 | ✓ pass | Scholarships and sponsorships are now opportunities. Use GET /api/v1/opportunities instead. |
| Talent Scout | GET | /auth/me | 200 | 200 | ✓ pass |  |
| Talent Scout | GET | /me/scout-profile | 200 | 200 | ✓ pass |  |
| Talent Scout | PUT | /me/scout-profile | 200 | 200 | ✓ pass |  |
| Talent Scout | GET | /athletes | 200 | 200 | ✓ pass |  |
| Talent Scout | GET | /scout/dashboard | 200 | 200 | ✓ pass |  |
| Talent Scout | POST | /observations | 201 | 201 | ✓ pass |  |
| Talent Scout | GET | /observations | 200 | 200 | ✓ pass |  |
| Talent Scout | POST | /me/scout-shortlist/1 | 200/201 | 409 | ✗ FAIL | Athlete already shortlisted. |
| Talent Scout | GET | /me/scout-shortlist | 200 | 200 | ✓ pass |  |
| Talent Scout | PATCH | /me/scout-shortlist/1 | 200 | 200 | ✓ pass |  |
| Talent Scout | DELETE | /me/scout-shortlist/1 | 200 | 200 | ✓ pass | Removed from shortlist |
| Talent Scout | POST | /athletes/2/connect | 200/201/409 | 409 | ✓ pass | Connection already exists. |
| Talent Scout | GET | /scout-connection-status/athlete/2 | 200 | 200 | ✓ pass |  |
| Talent Scout | GET | /me/scout-connections | 200 | 200 | ✓ pass |  |
| Talent Scout | GET | /me/scout-connections/incoming | 200 | 200 | ✓ pass |  |
| Talent Scout | POST | /scouts/1/connect | 200/201/409 | 409 | ✓ pass | Connection already exists. |
| Talent Scout | GET | /me/scout-connection-requests | 200 | 200 | ✓ pass |  |
| Talent Scout | POST | /me/scout-connection-requests/3/accept | 200/409 | 200 | ✓ pass |  |
| Talent Scout | GET | /me/scout-connections | 200 | 200 | ✓ pass |  |
| Talent Scout | DELETE | /me/scout-connections/3 | 200/404 | 200 | ✓ pass | Connection removed. |
| Admin | GET | GET /admin/me | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/dashboard | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/verification (queue) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/verification/{id} | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | PATCH | PATCH /admin/verification/{id}/approve | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/content (picker) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/content/trials | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/content/opportunities | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/content/trials/{id} | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/moderation/queue | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/moderation/reports/{id} | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | POST | POST /admin/moderation/reports/{id}/approve | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/expiry-rules | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/expiry/monitor | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/categories/sports | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | POST | POST /admin/categories/sports (TR sport) | 201 | SKIP | ⤼ skip | no token for admin |
| Admin | PUT | PUT /admin/categories/sports/{id} (rename TR) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/categories/cities | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/categories/age-groups | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/categories/positions | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | DELETE | DELETE /admin/categories/sports/{id} (cleanup TR) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/settings | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | PUT | PUT /admin/settings (no-op body) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | PUT | PUT /admin/settings (toggle boolean) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | PUT | PUT /admin/settings (flip back) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/email-settings | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/email-settings/diagnostics | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | POST | POST /admin/email-settings/clear-token-cache | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/users | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/users?q=runner-bot | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/users/{id} | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | POST | POST /admin/users/{id}/approve (runner bot) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/opportunities (review queue) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/notifications/stats | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/audit-logs | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/audit-logs/{id} | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/registrations/analytics/dashboard | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | GET | GET /admin/registrations/activity-log | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | POST | POST /admin/notifications/broadcast (in_app only) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | POST | POST /admin/users/{id}/suspend (runner bot) | 200 | SKIP | ⤼ skip | no token for admin |
| Admin | DELETE | DELETE /admin/users/{id} (runner bot) | 200 | SKIP | ⤼ skip | no token for admin |
| Cleanup | DELETE | DELETE /admin/content/trials/{orgTrial} | 200 | SKIP | ⤼ skip | no token for admin |
| Cleanup | DELETE | DELETE /admin/content/tournaments/{orgTournament} | 200 | SKIP | ⤼ skip | no token for admin |
| Cleanup | DELETE | DELETE /admin/content/trials/{coachTrial} | 200 | SKIP | ⤼ skip | no token for admin |
| Cleanup | DELETE | DELETE /admin/content/opportunities/{opportunityTr} | 200 | SKIP | ⤼ skip | no token for admin |
| Cleanup | DELETE | DELETE /admin/content/programs/{programTr} | 200 | SKIP | ⤼ skip | no token for admin |
| Cleanup | POST | POST /admin/logout (last call) | 200 | SKIP | ⤼ skip | no token for admin |