# SportX API — endpoint test report

**Base URL:** http://127.0.0.1:8000  
**Generated:** 2026-10-20T15:42:14.019Z  
**Flags:** destructive=true, cleanup=true

| Suite | Pass | Soft | Fail | Skip |
|---|---|---|---|---|
| Boot | 7 | 0 | 0 | 0 |
| Admin | 43 | 0 | 0 | 0 |
| Public | 33 | 0 | 0 | 0 |
| Auth | 11 | 0 | 0 | 0 |
| RBAC Guard | 35 | 0 | 0 | 0 |
| Organizer | 21 | 0 | 0 | 0 |
| Lifecycle | 28 | 0 | 0 | 0 |
| Enrollment | 7 | 0 | 0 | 1 |
| Coach | 32 | 0 | 0 | 0 |
| Academy | 10 | 0 | 0 | 0 |
| Athlete | 42 | 0 | 0 | 0 |
| Social | 32 | 0 | 0 | 1 |
| Enquiries | 8 | 0 | 0 | 0 |
| Sponsor | 10 | 0 | 0 | 0 |
| Talent Scout | 20 | 0 | 0 | 0 |
| Cleanup | 6 | 0 | 0 | 0 |

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
| Admin | POST | /admin/verify-2fa | 200 | 200 | ✓ pass |  |
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
| Public | GET | /trials/13 | 200 | 200 | ✓ pass |  |
| Public | GET | /tournaments | 200 | 200 | ✓ pass |  |
| Public | GET | /tournaments/13 | 200 | 200 | ✓ pass |  |
| Public | GET | /tournaments/13/results | 200 | 200 | ✓ pass |  |
| Public | GET | /opportunities?type=scholarship | 200 | 200 | ✓ pass |  |
| Public | GET | /opportunities?type=sponsorship | 200 | 200 | ✓ pass |  |
| Public | GET | /opportunities/10 | 200 | 200 | ✓ pass |  |
| Public | GET | /programs | 200 | 200 | ✓ pass |  |
| Public | GET | /programs/9 | 200 | 200 | ✓ pass |  |
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
| Auth | POST | /auth/register | 422 | 422 | ✓ pass | The given data was invalid. \| email: The email field must be a valid email address.; password: The password field must  |
| Auth | POST | /auth/register | 410 | 410 | ✓ pass | Sponsor accounts are no longer offered. Providers list scholarships and sponsorships as opportunities instead. |
| Auth | POST | /auth/register | 201 | 201 | ✓ pass | Registration successful. |
| Auth | POST | /auth/forgot-password | 200 | 200 | ✓ pass | If an account exists, a reset link has been sent |
| Auth | POST | /auth/send-otp | 422 | 422 | ✓ pass | The given data was invalid. \| channel: The selected channel is invalid. |
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
| RBAC Guard | POST | /trials/13/register | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | POST | /coaches/1/enroll | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/coach-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/scout-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/organizer | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/coach-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/facilities | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /scouts | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/scout-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /coach/enrollments | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | POST | /opportunities/10/apply | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /coach/enrollments | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/facilities | 403 | 403 | ✓ pass | Insufficient permissions |
| RBAC Guard | GET | /me/coach-profile | 403 | 403 | ✓ pass | Insufficient permissions |
| Organizer | GET | /auth/me | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/organizer | 200 | 200 | ✓ pass |  |
| Organizer | PUT | /me/organizer | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/organizer/analytics | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/events?filter=all | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/events?type=trial | 201 | 201 | ✓ pass |  |
| Organizer | PUT | /me/events/18?type=trial | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/events/18/publish?type=trial | 200 | 200 | ✓ pass |  |
| Organizer | GET | /events/18 | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/events?type=tournament | 201 | 201 | ✓ pass |  |
| Organizer | PUT | /me/events/16?type=tournament | 200 | 200 | ✓ pass |  |
| Organizer | GET | /tournaments/16 | 200 | 200 | ✓ pass |  |
| Organizer | PUT | /me/tournaments/16/categories | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/events/16/publish?type=tournament | 200 | 200 | ✓ pass |  |
| Organizer | PUT | /tournaments/16/capacity | 200 | 200 | ✓ pass |  |
| Organizer | GET | /tournaments/16/capacity | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/opportunities | 201 | 201 | ✓ pass |  |
| Organizer | PUT | /me/opportunities/13 | 200 | 200 | ✓ pass |  |
| Organizer | POST | /me/opportunities/13/publish | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/opportunities | 200 | 200 | ✓ pass |  |
| Organizer | GET | /me/home | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /trials/18/register | 201 | 201 | ✓ pass | Registration request submitted successfully |
| Lifecycle | GET | /me/registrations/trials | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /trials/18/registrations | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /trials/18/pending-requests | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /registrations/trials/9/verify | 200 | 200 | ✓ pass | Trial registration approved |
| Lifecycle | PATCH | /registrations/trials/9/approve | 200 | 200 | ✓ pass | Trial registration approved |
| Lifecycle | GET | /registrations/trials/9 | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /registrations/trials/9/ics | 200 | 200 | ✓ pass | BEGIN:VCALENDAR VERSION:2.0 PRODID:-//SportX//Event Calendar//EN CALSCALE:GREGORIAN BEGIN:VEVENT UID:trial-9@s |
| Lifecycle | POST | /tournaments/16/register | 200/201 | 201 | ✓ pass | Registration request submitted successfully |
| Lifecycle | GET | /me/registrations/tournaments | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /tournaments/16/register | 200/201 | 201 | ✓ pass | Registration request submitted successfully |
| Lifecycle | GET | /me/registrations/tournaments | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /tournaments/16/pending-requests | 200 | 200 | ✓ pass |  |
| Lifecycle | PATCH | /registrations/tournaments/12/approve | 200 | 200 | ✓ pass | Registration approved |
| Lifecycle | PATCH | /registrations/tournaments/12/payment | 200 | 200 | ✓ pass |  |
| Lifecycle | PATCH | /registrations/tournaments/13/reject | 200 | 200 | ✓ pass | Registration rejected |
| Lifecycle | POST | /events/16/registrations/bulk?type=tournament | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /events/16/registrations?type=tournament | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /events/16/registrations/export?type=tournament | 200 | 200 | ✓ pass | id,athlete,status,payment_status,created_at 12,"John Athlete",confirmed,paid,"2026-10-20 15:40:43" 13,"Priya P |
| Lifecycle | GET | /registrations/12 | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /registrations/tournaments/12/ics | 200 | 200 | ✓ pass | BEGIN:VCALENDAR VERSION:2.0 PRODID:-//SportX//Event Calendar//EN CALSCALE:GREGORIAN BEGIN:VEVENT UID:tournamen |
| Lifecycle | POST | /tournaments/16/results | 201 | 201 | ✓ pass |  |
| Lifecycle | POST | /tournaments/16/results/7/publish | 200 | 200 | ✓ pass |  |
| Lifecycle | GET | /tournaments/16/results | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /tournaments/16/results/7/unpublish | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /tournaments/16/results/7/publish | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /me/events/18/close?type=trial | 200 | 200 | ✓ pass |  |
| Lifecycle | POST | /me/events/16/close?type=tournament | 200 | 200 | ✓ pass |  |
| Enrollment | POST | /coaches/1/enroll | 200/201/409 | 409 | ✓ pass | Already enrolled or pending for this plan |
| Enrollment | GET | /me/coaching-enrollments | 200 | 200 | ✓ pass |  |
| Enrollment | GET | /coach/enrollments | 200 | 200 | ✓ pass |  |
| Enrollment | PATCH | /coaching-enrollments/5/approve | 200 | 200 | ✓ pass | Enrollment approved |
| Enrollment | POST | /coaches/1/enroll | 200/201/409 | 409 | ✓ pass | Already enrolled or pending for this plan |
| Enrollment | GET | /coach/enrollments | 200 | 200 | ✓ pass |  |
| Enrollment | PATCH | PATCH /coaching-enrollments/{e}/reject (coach) | 200 | SKIP | ⤼ skip | unresolved context: rejectEnrollmentId |
| Enrollment | GET | /me/coaching-enrollments | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/coach-profile | 200 | 200 | ✓ pass |  |
| Coach | PUT | /me/coach-profile | 200 | 200 | ✓ pass |  |
| Coach | GET | /me/events?filter=all | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/trials | 201 | 201 | ✓ pass |  |
| Coach | PUT | /me/trials/19 | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/trials/19/publish | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/trials/19/close | 200 | 200 | ✓ pass |  |
| Coach | POST | /me/programs | 201 | 201 | ✓ pass |  |
| Coach | PUT | /me/programs/12 | 200 | 200 | ✓ pass |  |
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
| Academy | PUT | /me/academy | 200 | 200 | ✓ pass |  |
| Academy | POST | /me/facilities | 201 | 201 | ✓ pass |  |
| Academy | PUT | /me/facilities/12 | 200 | 200 | ✓ pass |  |
| Academy | GET | /me/facilities | 200 | 200 | ✓ pass |  |
| Academy | DELETE | /me/facilities/12 | 200 | 200 | ✓ pass |  |
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
| Athlete | PATCH | /me/notifications/125/read | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/notification-preferences | 200 | 200 | ✓ pass |  |
| Athlete | PUT | /me/notification-preferences | 200 | 200 | ✓ pass |  |
| Athlete | POST | /analytics/events | 201 | 201 | ✓ pass |  |
| Athlete | POST | /me/saved | 200/201 | 201 | ✓ pass |  |
| Athlete | GET | /me/saved | 200 | 200 | ✓ pass |  |
| Athlete | DELETE | /me/saved | 200 | 200 | ✓ pass |  |
| Athlete | POST | /me/achievements | 201 | 201 | ✓ pass |  |
| Athlete | PUT | /me/achievements/7 | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/achievements | 200 | 200 | ✓ pass |  |
| Athlete | DELETE | /me/achievements/7 | 200 | 200 | ✓ pass |  |
| Athlete | POST | /media/upload | 200/201 | 201 | ✓ pass |  |
| Athlete | GET | /me/media | 200 | 200 | ✓ pass |  |
| Athlete | GET | /media/56/signed-url | 200 | 200 | ✓ pass |  |
| Athlete | DELETE | /media/56 | 200 | 200 | ✓ pass |  |
| Athlete | POST | /me/verification | 200/201 | 200 | ✓ pass | A verification request is already pending for this profile. |
| Athlete | GET | /me/verification | 200 | 200 | ✓ pass |  |
| Athlete | GET | /me/guardian-controls | 200 | 200 | ✓ pass |  |
| Athlete | POST | /reports | 201 | 201 | ✓ pass |  |
| Athlete | GET | /me/reports | 200 | 200 | ✓ pass |  |
| Athlete | GET | /observations | 403 | 403 | ✓ pass | Scout profile required. |
| Athlete | GET | /scout/dashboard | 403 | 403 | ✓ pass | Scout profile required. |
| Social | POST | /connections | 200/201/409 | 409 | ✓ pass | Connection request already exists. |
| Social | POST | /me/connections/request | 200/201/409 | 409 | ✓ pass | Connection request already exists. |
| Social | GET | /me/connections | 200 | 200 | ✓ pass |  |
| Social | GET | /me/connections/requests | 200 | 200 | ✓ pass |  |
| Social | POST | POST /me/connections/{id}/accept (priya) | 200 | SKIP | ⤼ skip | unresolved context: pendingConnectionId |
| Social | GET | /me/connections/count | 200 | 200 | ✓ pass |  |
| Social | GET | /me/connections/status/5 | 200 | 200 | ✓ pass |  |
| Social | POST | /conversations | 200 | 200 | ✓ pass |  |
| Social | POST | /me/conversations | 200 | 200 | ✓ pass |  |
| Social | GET | /me/conversations | 200 | 200 | ✓ pass |  |
| Social | GET | /conversations/2 | 200 | 200 | ✓ pass | note: facilitate conversation fetch |
| Social | GET | /conversations/2 | 200 | 200 | ✓ pass |  |
| Social | POST | /conversations/2/messages | 201 | 201 | ✓ pass |  |
| Social | POST | /conversations/2/read | 200 | 200 | ✓ pass |  |
| Social | PUT | /conversations/2/read | 200 | 200 | ✓ pass |  |
| Social | POST | /follow/user/5 | 200/201 | 201 | ✓ pass |  |
| Social | GET | /me/following | 200 | 200 | ✓ pass |  |
| Social | GET | /me/followers | 200 | 200 | ✓ pass |  |
| Social | DELETE | /follow/user/5 | 200 | 200 | ✓ pass |  |
| Social | GET | /feed | 200 | 200 | ✓ pass |  |
| Social | GET | /posts | 200 | 200 | ✓ pass |  |
| Social | POST | /posts | 201 | 201 | ✓ pass |  |
| Social | GET | /posts/8 | 200 | 200 | ✓ pass |  |
| Social | PATCH | /posts/8 | 200 | 200 | ✓ pass |  |
| Social | POST | /posts/8/like | 200 | 200 | ✓ pass |  |
| Social | GET | /posts/8/comments | 200 | 200 | ✓ pass |  |
| Social | POST | /posts/8/comments | 201 | 201 | ✓ pass |  |
| Social | DELETE | /comments/7 | 200 | 200 | ✓ pass |  |
| Social | DELETE | /posts/8/like | 200 | 200 | ✓ pass |  |
| Social | DELETE | /posts/8 | 200 | 200 | ✓ pass |  |
| Social | POST | /blocks | 200/201 | 201 | ✓ pass |  |
| Social | GET | /blocks | 200 | 200 | ✓ pass |  |
| Social | DELETE | /blocks/31 | 200 | 200 | ✓ pass | note: if register block failed earlier this 404s — soft |
| Enquiries | POST | /enquiries | 201 | 201 | ✓ pass |  |
| Enquiries | GET | /me/enquiries | 200 | 200 | ✓ pass |  |
| Enquiries | GET | /enquiries/9 | 200 | 200 | ✓ pass |  |
| Enquiries | POST | /enquiries/9/messages | 201 | 201 | ✓ pass |  |
| Enquiries | POST | /enquiries/9/messages | 201 | 201 | ✓ pass |  |
| Enquiries | PUT | /enquiries/9/read | 200 | 200 | ✓ pass |  |
| Enquiries | POST | /opportunities/13/apply | 200/201 | 201 | ✓ pass |  |
| Enquiries | GET | /me/opportunities?type=applied | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /auth/me | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /athletes | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /athletes/1 | 200 | 200 | ✓ pass |  |
| Sponsor | GET | /opportunities/13/applications | 200 | 200 | ✓ pass |  |
| Sponsor | PATCH | /opportunities/13/applications/11 | 200 | 200 | ✓ pass |  |
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
| Talent Scout | POST | /me/scout-shortlist/1 | 200/201/409 | 201 | ✓ pass |  |
| Talent Scout | GET | /me/scout-shortlist | 200 | 200 | ✓ pass |  |
| Talent Scout | PATCH | /me/scout-shortlist/1 | 200 | 200 | ✓ pass |  |
| Talent Scout | DELETE | /me/scout-shortlist/1 | 200 | 200 | ✓ pass | Removed from shortlist |
| Talent Scout | POST | /athletes/2/connect | 200/201/409 | 409 | ✓ pass | Connection already exists. |
| Talent Scout | GET | /scout-connection-status/athlete/2 | 200 | 200 | ✓ pass |  |
| Talent Scout | GET | /me/scout-connections | 200 | 200 | ✓ pass |  |
| Talent Scout | GET | /me/scout-connections/incoming | 200 | 200 | ✓ pass |  |
| Talent Scout | POST | /scouts/1/connect | 200/201/409 | 201 | ✓ pass |  |
| Talent Scout | GET | /me/scout-connection-requests | 200 | 200 | ✓ pass |  |
| Talent Scout | POST | /me/scout-connection-requests/9/accept | 200/409 | 200 | ✓ pass |  |
| Talent Scout | GET | /me/scout-connections | 200 | 200 | ✓ pass |  |
| Talent Scout | DELETE | /me/scout-connections/9 | 200/404 | 200 | ✓ pass | Connection removed. |
| Admin | GET | /admin/me | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/dashboard | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/verification | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/verification/7 | 200 | 200 | ✓ pass |  |
| Admin | PATCH | /admin/verification/7/approve | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/content | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/content/trials | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/content/opportunities | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/content/trials/18 | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/moderation/queue | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/moderation/reports/6 | 200 | 200 | ✓ pass |  |
| Admin | POST | /admin/moderation/reports/6/approve | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/expiry-rules | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/expiry/monitor | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/categories/sports | 200 | 200 | ✓ pass |  |
| Admin | POST | /admin/categories/sports | 201 | 201 | ✓ pass |  |
| Admin | PUT | /admin/categories/sports/13 | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/categories/cities | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/categories/age-groups | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/categories/positions | 200 | 200 | ✓ pass |  |
| Admin | DELETE | /admin/categories/sports/13 | 200/204 | 204 | ✓ pass |  |
| Admin | GET | /admin/settings | 200 | 200 | ✓ pass |  |
| Admin | PUT | /admin/settings | 200 | 200 | ✓ pass |  |
| Admin | PUT | /admin/settings | 200 | 200 | ✓ pass |  |
| Admin | PUT | /admin/settings | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/email-settings | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/email-settings/diagnostics | 200 | 200 | ✓ pass |  |
| Admin | POST | /admin/email-settings/clear-token-cache | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/users | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/users?q=runner-bot | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/users/31 | 200 | 200 | ✓ pass |  |
| Admin | POST | /admin/users/31/approve | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/opportunities | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/notifications/stats | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/audit-logs | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/audit-logs/271 | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/registrations/analytics/dashboard | 200 | 200 | ✓ pass |  |
| Admin | GET | /admin/registrations/activity-log | 200 | 200 | ✓ pass |  |
| Admin | POST | /admin/notifications/broadcast | 200/201 | 201 | ✓ pass | note: sends in-app notification to active users |
| Admin | POST | /admin/users/31/suspend | 200/201 | 200 | ✓ pass |  |
| Admin | DELETE | /admin/users/31 | 200/204 | 204 | ✓ pass |  |
| Cleanup | DELETE | /admin/content/trials/18 | 200/204 | 204 | ✓ pass |  |
| Cleanup | DELETE | /admin/content/tournaments/16 | 200/204 | 204 | ✓ pass |  |
| Cleanup | DELETE | /admin/content/trials/19 | 200/204 | 204 | ✓ pass |  |
| Cleanup | DELETE | /admin/content/opportunities/13 | 200/204 | 204 | ✓ pass |  |
| Cleanup | DELETE | /admin/content/programs/12 | 200/204 | 204 | ✓ pass |  |
| Cleanup | POST | /admin/logout | 200 | 200 | ✓ pass |  |