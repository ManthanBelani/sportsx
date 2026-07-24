import { useState, useCallback, useEffect } from 'react'

// Static imports of all screen modules
import * as Auth    from './screens/auth'
import * as Athlete from './screens/athlete'
import * as Coach   from './screens/coach'
import * as Sponsor from './screens/sponsor'
import * as Shared  from './screens/shared'
import * as Admin   from './screens/admin'

export type NavFn = (screen: string, params?: Record<string, unknown>) => void

// ─── Screen Registry ──────────────────────────────────────────────────────────
const SCREENS = [
  { id: 'splash',           label: '1. Splash Screen',             group: 'Auth' },
  { id: 'login',            label: '2. Login Screen',              group: 'Auth' },
  { id: 'signup',           label: '3. Signup Screen',             group: 'Auth' },
  { id: 'otp',              label: '4. OTP Verification',          group: 'Auth' },
  { id: 'role-select',      label: '5. Role Selection',            group: 'Auth' },
  { id: 'forgot-password',  label: '6. Forgot Password',           group: 'Auth' },
  { id: 'reset-password',   label: '7. Reset Password',            group: 'Auth' },
  { id: 'athlete-home',         label: '8. Athlete Home Feed',         group: 'Athlete' },
  { id: 'create-post',          label: '9. Create Post',               group: 'Athlete' },
  { id: 'my-profile-athlete',   label: '10. My Profile (Athlete)',     group: 'Athlete' },
  { id: 'edit-profile',         label: '11. Edit Profile',             group: 'Athlete' },
  { id: 'add-achievement',      label: '12. Add Achievement',          group: 'Athlete' },
  { id: 'add-tournament',       label: '13. Add Tournament',           group: 'Athlete' },
  { id: 'tournament-history',   label: '14. Tournament History',       group: 'Athlete' },
  { id: 'edit-stats',           label: '15. Edit Stats',               group: 'Athlete' },
  { id: 'media-gallery',        label: '16. Media Gallery',            group: 'Athlete' },
  { id: 'upload-media',         label: '17. Upload Media',             group: 'Athlete' },
  { id: 'edit-social-links',    label: '18. Edit Social Links',        group: 'Athlete' },
  { id: 'discover',             label: '19. Discover / Directory',     group: 'Athlete' },
  { id: 'my-connections',       label: '20. My Connections',           group: 'Athlete' },
  { id: 'connection-requests',  label: '21. Connection Requests',      group: 'Athlete' },
  { id: 'chat-list',            label: '22. Chat List',                group: 'Athlete' },
  { id: 'chat-screen',          label: '23. Chat Screen',              group: 'Athlete' },
  { id: 'academies-directory',  label: '24. Academies Directory',      group: 'Athlete' },
  { id: 'coach-home',              label: '25. Coach Home Feed',          group: 'Coach' },
  { id: 'coach-profile',           label: '26. Coach Profile',            group: 'Coach' },
  { id: 'edit-coach-profile',      label: '27. Edit Coach Profile',       group: 'Coach' },
  { id: 'add-credential',          label: '28. Add Credential',           group: 'Coach' },
  { id: 'edit-facilities',         label: '29. Edit Facilities',          group: 'Coach' },
  { id: 'showcase-athletes',       label: '30. Showcase Athletes',        group: 'Coach' },
  { id: 'athlete-directory-coach', label: '31. Athlete Directory (Coach)','group': 'Coach' },
  { id: 'sponsor-directory-coach', label: '32. Sponsor Directory (Coach)','group': 'Coach' },
  { id: 'sponsor-home',              label: '33. Sponsor Home Feed',          group: 'Sponsor' },
  { id: 'sponsor-profile',           label: '34. Sponsor Profile',            group: 'Sponsor' },
  { id: 'edit-sponsor-profile',      label: '35. Edit Sponsor Profile',       group: 'Sponsor' },
  { id: 'my-opportunities',          label: '36. My Opportunities',           group: 'Sponsor' },
  { id: 'past-associations',         label: '37. Past Associations',          group: 'Sponsor' },
  { id: 'athlete-directory-sponsor', label: '38. Athlete Directory (Sponsor)','group': 'Sponsor' },
  { id: 'academy-directory-sponsor', label: '39. Academy Directory (Sponsor)','group': 'Sponsor' },
  { id: 'post-opportunity',          label: '40. Post Opportunity',           group: 'Sponsor' },
  { id: 'listing-status',            label: '41. Listing Status',             group: 'Sponsor' },
  { id: 'view-profile',        label: '42. View Profile (Read-Only)', group: 'Shared' },
  { id: 'post-detail',         label: '43. Post Detail',              group: 'Shared' },
  { id: 'opportunities-list',  label: '44. Opportunities List',       group: 'Shared' },
  { id: 'opportunity-detail',  label: '45. Opportunity Detail',       group: 'Shared' },
  { id: 'apply-form',          label: '46. Apply / Express Interest', group: 'Shared' },
  { id: 'app-submitted',       label: '47. Application Submitted',    group: 'Shared' },
  { id: 'search-filter',       label: '48. Search & Filter',          group: 'Shared' },
  { id: 'notifications',       label: '49. Notifications List',       group: 'Shared' },
  { id: 'notification-detail', label: '50. Notification Detail',      group: 'Shared' },
  { id: 'settings',            label: '51. Settings',                 group: 'Shared' },
  { id: 'media-viewer',        label: '52. Media Viewer',             group: 'Shared' },
  { id: 'admin-dashboard',         label: '53. Admin Dashboard',           group: 'Admin' },
  { id: 'platform-reports',        label: '54. Platform Reports',          group: 'Admin' },
  { id: 'manage-users',            label: '55. Manage Users',              group: 'Admin' },
  { id: 'user-detail',             label: '56. User Detail / Verify',      group: 'Admin' },
  { id: 'pending-approvals',       label: '57. Pending Approvals',         group: 'Admin' },
  { id: 'moderation-queue',        label: '58. Moderation Queue',          group: 'Admin' },
  { id: 'report-detail',           label: '59. Report Detail',             group: 'Admin' },
  { id: 'compose-notification',    label: '60. Compose Notification',      group: 'Admin' },
  { id: 'notification-targeting',  label: '61. Notification Targeting',    group: 'Admin' },
  { id: 'opp-approval-queue',      label: '62. Opportunity Approval Queue','group': 'Admin' },
  { id: 'opp-review-detail',       label: '63. Opportunity Review Detail', group: 'Admin' },
]

const GROUPS = ['Auth', 'Athlete', 'Coach', 'Sponsor', 'Shared', 'Admin']

const GROUP_META: Record<string, { color: string; emoji: string; desc: string }> = {
  Auth:    { color: 'bg-purple-100 text-purple-700', emoji: '🔐', desc: '7 screens' },
  Athlete: { color: 'bg-blue-100 text-blue-700',     emoji: '🏃', desc: '17 screens' },
  Coach:   { color: 'bg-green-100 text-green-700',   emoji: '🏫', desc: '8 screens' },
  Sponsor: { color: 'bg-orange-100 text-orange-700', emoji: '🤝', desc: '9 screens' },
  Shared:  { color: 'bg-gray-100 text-gray-600',     emoji: '🔗', desc: '11 screens' },
  Admin:   { color: 'bg-red-100 text-red-700',       emoji: '⚙️', desc: '11 screens' },
}

type ScreenProps = { navigate: NavFn; onBack: () => void }

function ScreenSwitcher({ id, navigate, onBack }: { id: string; navigate: NavFn; onBack: () => void }) {
  const p: ScreenProps = { navigate, onBack }

  const map: Record<string, React.FC<ScreenProps>> = {
    // Auth
    'splash':           Auth.SplashScreen,
    'login':            Auth.LoginScreen,
    'signup':           Auth.SignupScreen,
    'otp':              Auth.OTPScreen,
    'role-select':      Auth.RoleSelectScreen,
    'forgot-password':  Auth.ForgotPasswordScreen,
    'reset-password':   Auth.ResetPasswordScreen,
    // Athlete
    'athlete-home':         Athlete.AthleteHomeScreen,
    'create-post':          Athlete.CreatePostScreen,
    'my-profile-athlete':   Athlete.MyProfileAthleteScreen,
    'edit-profile':         Athlete.EditProfileScreen,
    'add-achievement':      Athlete.AddAchievementScreen,
    'add-tournament':       Athlete.AddTournamentScreen,
    'tournament-history':   Athlete.TournamentHistoryScreen,
    'edit-stats':           Athlete.EditStatsScreen,
    'media-gallery':        Athlete.MediaGalleryScreen,
    'upload-media':         Athlete.UploadMediaScreen,
    'edit-social-links':    Athlete.EditSocialLinksScreen,
    'discover':             Athlete.DiscoverScreen,
    'my-connections':       Athlete.MyConnectionsScreen,
    'connection-requests':  Athlete.ConnectionRequestsScreen,
    'chat-list':            Athlete.ChatListScreen,
    'chat-screen':          Athlete.ChatScreen,
    'academies-directory':  Athlete.AcademiesDirectoryScreen,
    // Coach
    'coach-home':              Coach.CoachHomeScreen,
    'coach-profile':           Coach.CoachProfileScreen,
    'edit-coach-profile':      Coach.EditCoachProfileScreen,
    'add-credential':          Coach.AddCredentialScreen,
    'edit-facilities':         Coach.EditFacilitiesScreen,
    'showcase-athletes':       Coach.ShowcaseAthletesScreen,
    'athlete-directory-coach': Coach.AthleteDirectoryCoachScreen,
    'sponsor-directory-coach': Coach.SponsorDirectoryCoachScreen,
    // Sponsor
    'sponsor-home':              Sponsor.SponsorHomeScreen,
    'sponsor-profile':           Sponsor.SponsorProfileScreen,
    'edit-sponsor-profile':      Sponsor.EditSponsorProfileScreen,
    'my-opportunities':          Sponsor.MyOpportunitiesScreen,
    'past-associations':         Sponsor.PastAssociationsScreen,
    'athlete-directory-sponsor': Sponsor.AthleteDirectorySponsorScreen,
    'academy-directory-sponsor': Sponsor.AcademyDirectorySponsorScreen,
    'post-opportunity':          Sponsor.PostOpportunityScreen,
    'listing-status':            Sponsor.ListingStatusScreen,
    // Shared
    'view-profile':        Shared.ViewProfileScreen,
    'post-detail':         Shared.PostDetailScreen,
    'opportunities-list':  Shared.OpportunitiesListScreen,
    'opportunity-detail':  Shared.OpportunityDetailScreen,
    'apply-form':          Shared.ApplyFormScreen,
    'app-submitted':       Shared.AppSubmittedScreen,
    'search-filter':       Shared.SearchFilterScreen,
    'notifications':       Shared.NotificationsListScreen,
    'notification-detail': Shared.NotificationDetailScreen,
    'settings':            Shared.SettingsScreen,
    'media-viewer':        Shared.MediaViewerScreen,
    // Admin
    'admin-dashboard':         Admin.AdminDashboardScreen,
    'platform-reports':        Admin.PlatformReportsScreen,
    'manage-users':            Admin.ManageUsersScreen,
    'user-detail':             Admin.UserDetailVerifyScreen,
    'pending-approvals':       Admin.PendingApprovalsScreen,
    'moderation-queue':        Admin.ModerationQueueScreen,
    'report-detail':           Admin.ReportDetailScreen,
    'compose-notification':    Admin.ComposeNotificationScreen,
    'notification-targeting':  Admin.NotificationTargetingScreen,
    'opp-approval-queue':      Admin.OppApprovalQueueScreen,
    'opp-review-detail':       Admin.OppReviewDetailScreen,
  }

  const Comp = map[id]
  if (!Comp) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-2 p-8 text-center bg-white">
        <div className="text-4xl">🚧</div>
        <p className="text-base font-semibold text-gray-900">Screen not found</p>
        <p className="text-sm text-gray-500 font-mono">{id}</p>
      </div>
    )
  }
  return <Comp {...p} />
}

// ─── Device Simulator ──────────────────────────────────────────────────────────
function DeviceSimulator({ 
  initialScreen, 
  externalScreen,
  onScreenChange,
  label,
  deviceType = 'mobile'
}: { 
  initialScreen: string; 
  externalScreen?: string;
  onScreenChange?: (id: string) => void;
  label?: string;
  deviceType?: 'mobile' | 'desktop';
}) {
  const [current, setCurrent] = useState(initialScreen)
  const [history, setHistory] = useState<string[]>([])

  useEffect(() => {
    if (externalScreen && externalScreen !== current) {
      setCurrent(externalScreen)
      setHistory([])
    }
  }, [externalScreen])

  useEffect(() => {
    onScreenChange?.(current)
  }, [current, onScreenChange])

  const navigate = useCallback<NavFn>((screen) => {
    setHistory(h => [...h, current])
    setCurrent(screen)
  }, [current])

  const goBack = useCallback(() => {
    setHistory(h => {
      const next = [...h]
      const prev = next.pop()
      if (prev) setCurrent(prev)
      return next
    })
  }, [])

  const isDesktop = deviceType === 'desktop';
  const width = isDesktop ? 1024 : 390;
  const height = isDesktop ? 768 : 844;
  const borderRadius = isDesktop ? 12 : 44;

  return (
    <div className="flex flex-col items-center gap-4">
      {label && <h3 className="text-xs font-bold text-gray-500 uppercase tracking-widest">{label}</h3>}
      <div
        className="relative flex-shrink-0 overflow-hidden"
        style={{
          width,
          height,
          borderRadius,
          backgroundColor: '#1a1a1a',
          boxShadow: '0 40px 100px rgba(0,0,0,0.4), 0 0 0 1.5px rgba(255,255,255,0.12)',
          transform: 'translateZ(0)'
        }}
      >
        {/* Window Chrome */}
        {isDesktop ? (
          <div className="absolute top-0 left-0 right-0 h-10 bg-[#e2e2e2] flex items-center px-4 z-20 flex-shrink-0 gap-2 border-b border-gray-300">
            <div className="w-3 h-3 rounded-full bg-red-400" />
            <div className="w-3 h-3 rounded-full bg-yellow-400" />
            <div className="w-3 h-3 rounded-full bg-green-400" />
            <div className="flex-1 flex justify-center">
              <div className="bg-white rounded-md px-3 py-1 flex items-center gap-2 text-[10px] text-gray-500 shadow-sm w-64 justify-center">
                <span className="opacity-50">🔒</span> admin.sportx.in
              </div>
            </div>
            <div className="w-16" />
          </div>
        ) : (
          <div className="absolute top-0 left-0 right-0 h-12 bg-white flex items-center justify-between px-8 z-20 flex-shrink-0">
            <span className="text-xs font-bold text-gray-900">9:41</span>
          </div>
        )}
        
        {/* Screen */}
        <div className={`absolute inset-0 ${isDesktop ? 'pt-10' : 'pt-12'} bg-[#FAFAFA] flex flex-col overflow-hidden`}>
          <ScreenSwitcher
            key={current}
            id={current}
            navigate={navigate}
            onBack={goBack}
          />
        </div>
      </div>
    </div>
  )
}


// ─── Main App ─────────────────────────────────────────────────────────────────
export default function App() {
  const [viewMode, setViewMode] = useState<'single'|'grid'>('single')
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set(GROUPS))

  // For single view controls
  const [externalScreen, setExternalScreen] = useState('splash')
  const [activeScreenId, setActiveScreenId] = useState('splash')

  const currentEntry = SCREENS.find(s => s.id === activeScreenId) || SCREENS[0]
  const filteredScreens = SCREENS.filter(s =>
    s.label.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.group.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const toggleGroup = (group: string) => {
    setExpandedGroups(prev => {
      const next = new Set(prev)
      if (next.has(group)) next.delete(group)
      else next.add(group)
      return next
    })
  }

  const jumpToScreen = (id: string) => { 
    setExternalScreen(id)
  }

  return (
    <div className="flex h-screen bg-[#FAFAFA] text-[#09090B] overflow-hidden">
      {/* Sidebar - Only visible in single mode */}
      <div className={`flex-shrink-0 bg-white border-r border-gray-200 flex flex-col transition-all duration-300 ${(sidebarOpen && viewMode === 'single') ? 'w-72' : 'w-0 overflow-hidden'}`}>
        <div className="p-4 border-b border-gray-200 flex-shrink-0">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
              <span className="text-white text-xs font-bold">SX</span>
            </div>
            <div>
              <p className="text-sm font-bold text-gray-900">SportX India</p>
              <p className="text-xs text-gray-500">63 Screens · MVP Design</p>
            </div>
          </div>
          <input
            placeholder="🔍 Search screens..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            className="w-full h-8 rounded-lg border border-gray-200 px-3 text-xs text-gray-900 placeholder-gray-400 outline-none focus:border-blue-600 bg-slate-50"
          />
        </div>
        <div className="flex-1 overflow-y-auto">
          {searchQuery ? (
            <div className="p-2">
              {filteredScreens.map(screen => (
                <button
                  key={screen.id}
                  onClick={() => jumpToScreen(screen.id)}
                  className={`w-full text-left px-3 py-2 rounded-lg text-xs transition-all mb-0.5 flex items-center gap-2 ${activeScreenId === screen.id ? 'bg-blue-600 text-white font-semibold' : 'text-gray-700 hover:bg-slate-50'}`}
                >
                  <span>{GROUP_META[screen.group]?.emoji}</span>
                  {screen.label}
                </button>
              ))}
              {filteredScreens.length === 0 && (
                <p className="text-xs text-gray-400 text-center py-8">No screens found</p>
              )}
            </div>
          ) : (
            GROUPS.map(group => {
              const groupScreens = SCREENS.filter(s => s.group === group)
              const isExpanded = expandedGroups.has(group)
              const meta = GROUP_META[group]
              return (
                <div key={group}>
                  <button
                    onClick={() => toggleGroup(group)}
                    className="w-full flex items-center justify-between px-4 py-3 hover:bg-slate-100 transition-colors mt-1 rounded-lg mx-2"
                    style={{ width: 'calc(100% - 16px)' }}
                  >
                    <div className="flex items-center gap-3">
                      <span className="text-lg">{meta.emoji}</span>
                      <div className="text-left">
                        <p className="text-sm font-bold text-gray-900">{group}</p>
                        <p className="text-[10px] text-gray-500 font-medium">{meta.desc}</p>
                      </div>
                    </div>
                    <span className="text-gray-400 text-xs">{isExpanded ? '▾' : '▸'}</span>
                  </button>
                  {isExpanded && (
                    <div className="flex flex-col gap-1 px-3 py-2">
                      {groupScreens.map(screen => (
                        <button
                          key={screen.id}
                          onClick={() => jumpToScreen(screen.id)}
                          className={`w-full text-left px-4 py-2 rounded-xl text-xs font-medium transition-all ${activeScreenId === screen.id ? 'bg-gradient-to-r from-blue-500 to-blue-600 text-white premium-btn-shadow font-bold' : 'text-gray-600 hover:text-gray-900 hover:bg-slate-100'}`}
                        >
                          {screen.label}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              )
            })
          )}
        </div>
        <div className="p-3 border-t border-gray-200">
          <p className="text-[10px] text-gray-400 text-center">SportX India Design System v1.0 MVP</p>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top Bar */}
        <div className="h-12 bg-white border-b border-gray-200 flex items-center px-4 gap-2 flex-shrink-0 z-10 premium-shadow">
          {viewMode === 'single' && (
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="w-8 h-8 rounded-lg bg-slate-50 border border-gray-200 flex items-center justify-center text-gray-500 hover:bg-slate-100 text-sm"
            >
              ☰
            </button>
          )}
          {viewMode === 'single' && (
            <>
              <span className={`ml-2 text-[10px] font-semibold px-2 py-0.5 rounded-full ${GROUP_META[currentEntry.group]?.color || ''}`}>
                {GROUP_META[currentEntry.group]?.emoji} {currentEntry.group}
              </span>
              <span className="text-sm font-semibold text-gray-900 truncate">{currentEntry.label}</span>
            </>
          )}
          
          <div className="flex-1" />
          
          <div className="flex items-center gap-2 bg-slate-100 p-1 rounded-lg border border-gray-200 mr-2">
            <button 
              onClick={() => setViewMode('single')}
              className={`text-xs font-semibold px-3 py-1 rounded-md transition-all ${viewMode === 'single' ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500 hover:text-gray-900'}`}
            >
              Single Screen
            </button>
            <button 
              onClick={() => setViewMode('grid')}
              className={`text-xs font-semibold px-3 py-1 rounded-md transition-all ${viewMode === 'grid' ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500 hover:text-gray-900'}`}
            >
              4-Role Grid Demo
            </button>
          </div>
        </div>

        {/* Dynamic Content Area */}
        {viewMode === 'single' ? (
          <div className="flex-1 overflow-auto flex flex-col items-center justify-center p-8 bg-[#FAFAFA]">
            <DeviceSimulator 
              initialScreen="splash"
              externalScreen={externalScreen}
              onScreenChange={setActiveScreenId}
              deviceType={currentEntry.group === 'Admin' ? 'desktop' : 'mobile'}
            />
            {/* Prev/Next Navigation for Single Mode */}
            <div className="flex items-center gap-3 mt-6">
              <button
                onClick={() => {
                  const idx = SCREENS.findIndex(s => s.id === activeScreenId)
                  if (idx > 0) jumpToScreen(SCREENS[idx - 1].id)
                }}
                disabled={SCREENS.findIndex(s => s.id === activeScreenId) === 0}
                className="px-4 py-2 text-xs font-semibold bg-white border border-gray-200 rounded-xl text-gray-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed shadow-sm"
              >
                ← Previous
              </button>
              <div className="text-center">
                <p className="text-xs font-bold text-gray-700">
                  {SCREENS.findIndex(s => s.id === activeScreenId) + 1} / {SCREENS.length}
                </p>
                <p className="text-[10px] text-gray-400">screens</p>
              </div>
              <button
                onClick={() => {
                  const idx = SCREENS.findIndex(s => s.id === activeScreenId)
                  if (idx < SCREENS.length - 1) jumpToScreen(SCREENS[idx + 1].id)
                }}
                disabled={SCREENS.findIndex(s => s.id === activeScreenId) === SCREENS.length - 1}
                className="px-4 py-2 text-xs font-semibold bg-white border border-gray-200 rounded-xl text-gray-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed shadow-sm"
              >
                Next →
              </button>
            </div>
          </div>
        ) : (
          <div className="flex-1 overflow-auto bg-[#FAFAFA] p-8">
            <div className="flex flex-wrap gap-8 justify-center min-w-max pb-12" style={{ transform: 'scale(0.85)', transformOrigin: 'top center' }}>
              <DeviceSimulator initialScreen="athlete-home" label="🏃 Athlete Role" />
              <DeviceSimulator initialScreen="coach-home" label="🏫 Coach / Academy Role" />
              <DeviceSimulator initialScreen="sponsor-home" label="🤝 Sponsor Role" />
              <DeviceSimulator initialScreen="admin-dashboard" label="⚙️ Admin Dashboard" deviceType="desktop" />
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
