import React, { useState } from 'react';
import {
  AppBar, BottomNav, IconBtn, PrimaryBtn, CTABtn, SecondaryBtn, GhostBtn, DangerBtn, SuccessBtn,
  InputField, TextArea, SearchBar, SelectField, Avatar, SportBadge, VerifiedBadge, StatusDot,
  TabPills, FilterChip, SectionLabel, Divider, PostCard, AthleteCard, AcademyCard, SponsorCard,
  OpportunityCard, NotificationCard, ProfileHeader, StatRow, Card, EmptyState, UploadArea, SettingRow,
  EyeIcon, EditIcon, SettingsIcon, BellIcon, CameraIcon, TrophyIcon, WarningIcon, ChevronRightIcon,
  CheckCircleIcon, SearchIcon,
  type NavFn,
} from '../components/ui';

// ---------------------------------------------------------------------------
// AdminWebLayout
// ---------------------------------------------------------------------------
export function AdminWebLayout({ navigate, title, children, rightActions, onBack }: { navigate: NavFn, title: string, children: React.ReactNode, rightActions?: React.ReactNode, onBack?: () => void }) {
  const sidebarLinks = [
    { label: 'Dashboard', route: 'admin-dashboard', icon: '📊' },
    { label: 'Manage Users', route: 'manage-users', icon: '👥' },
    { label: 'Approvals', route: 'pending-approvals', icon: '✅' },
    { label: 'Moderation', route: 'moderation-queue', icon: '🚨' },
    { label: 'Opportunities', route: 'opp-approval-queue', icon: '🤝' },
    { label: 'Notifications', route: 'compose-notification', icon: '🔔' },
    { label: 'Reports', route: 'platform-reports', icon: '📈' },
  ]
  return (
    <div className="flex h-full w-full bg-slate-50 overflow-hidden text-gray-900">
      <div className="w-64 bg-white border-r border-gray-200 flex flex-col flex-shrink-0">
        <div className="h-16 flex items-center px-6 border-b border-gray-100 gap-3">
          <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
            <span className="text-white text-xs font-bold">SX</span>
          </div>
          <span className="font-bold text-lg tracking-tight">SportX Admin</span>
        </div>
        <div className="flex-1 overflow-y-auto py-4 px-3 flex flex-col gap-1">
          {sidebarLinks.map(link => (
            <button
              key={link.route}
              onClick={() => navigate(link.route)}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors text-left text-gray-700 hover:bg-slate-100`}
            >
              <span>{link.icon}</span>
              {link.label}
            </button>
          ))}
        </div>
      </div>
      <div className="flex-1 flex flex-col overflow-hidden">
        <div className="h-16 bg-white border-b border-gray-200 flex items-center px-8 justify-between flex-shrink-0">
          <div className="flex items-center gap-4">
            {onBack && (
              <button onClick={onBack} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
                <span className="text-gray-500 font-bold">←</span>
              </button>
            )}
            <h1 className="text-xl font-bold text-gray-900">{title}</h1>
          </div>
          <div className="flex items-center gap-4">
            {rightActions}
          </div>
        </div>
        <div className="flex-1 overflow-y-auto p-8">
          <div className="max-w-5xl mx-auto flex flex-col gap-6">
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// AdminDashboardScreen
// ---------------------------------------------------------------------------
export function AdminDashboardScreen({ navigate }: { navigate: NavFn }) {
  const recentActivity = [
    { icon: '👤', desc: 'New athlete registration: Priya Patel', time: '2m ago' },
    { icon: '🏫', desc: 'New academy added: Delhi Cricket Academy', time: '15m ago' },
    { icon: '⚠️', desc: 'Content report flagged for review', time: '1h ago' },
  ];

  const quickActions = [
    { label: 'Users', icon: '👥', route: 'manage-users' },
    { label: 'Approve', icon: '✅', route: 'pending-approvals' },
    { label: 'Reports', icon: '🚨', route: 'moderation-queue' },
    { label: 'Notify', icon: '🔔', route: 'compose-notification' },
    { label: 'Opp', icon: '🤝', route: 'opp-approval-queue' },
    { label: 'Stats', icon: '📊', route: 'platform-reports' },
  ];

  return (
    <AdminWebLayout navigate={navigate} title="Admin Dashboard" rightActions={<IconBtn icon={<SettingsIcon />} onClick={() => navigate('settings')} />}>
        <p className="text-lg font-semibold text-gray-900">Good Morning, Admin</p>
        <p className="text-sm text-gray-500">Here's today's overview</p>

        {/* Quick Stats */}
        <div className="mt-2">
          <SectionLabel label="QUICK STATS" />
          <div className="mt-2">
            <StatRow stats={[{ label: 'Total Users', value: 1245 }, { label: 'Pending Approvals', value: 89 }, { label: 'Reports Today', value: 12 }]} />
          </div>
        </div>

        {/* User Breakdown */}
        <div className="mt-2">
          <SectionLabel label="USER BREAKDOWN" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[{ icon: '👤', label: 'Athletes', count: 892 }, { icon: '🏫', label: 'Coaches', count: 187 }, { icon: '🤝', label: 'Sponsors', count: 166 }].map(row => (
                <div key={row.label} className="flex items-center justify-between py-1 border-b border-gray-100 last:border-0">
                  <div className="flex items-center gap-2">
                    <span>{row.icon}</span>
                    <span className="text-sm text-gray-700">{row.label}</span>
                  </div>
                  <span className="text-sm font-semibold text-gray-900">{row.count}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Recent Activity */}
        <div className="mt-2">
          <SectionLabel label="RECENT ACTIVITY" />
          <div className="flex flex-col gap-2 mt-2">
            {recentActivity.map((a, i) => (
              <Card key={i}>
                <div className="flex items-center gap-3 p-3">
                  <span className="text-xl">{a.icon}</span>
                  <p className="text-sm text-gray-700 flex-1">{a.desc}</p>
                  <span className="text-xs text-gray-400 shrink-0">{a.time}</span>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="mt-2">
          <SectionLabel label="QUICK ACTIONS" />
          <div className="grid grid-cols-3 gap-3 mt-2">
            {quickActions.map(action => (
              <button
                key={action.route}
                className="rounded-xl bg-slate-50 flex flex-col items-center py-4 gap-2"
                onClick={() => navigate(action.route)}
              >
                <div className="w-[60px] h-[60px] bg-blue-50 rounded-full flex items-center justify-center text-2xl">
                  {action.icon}
                </div>
                <span className="text-xs font-medium text-gray-700">{action.label}</span>
              </button>
            ))}
          </div>
        </div>
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// PlatformReportsScreen
// ---------------------------------------------------------------------------
export function PlatformReportsScreen({ navigate }: { navigate: NavFn }) {
  const roleData = [
    { label: 'Athletes', count: 892, pct: '71.6%', color: 'bg-blue-500', w: 'w-[72%]' },
    { label: 'Coaches', count: 187, pct: '15%', color: 'bg-orange-400', w: 'w-[15%]' },
    { label: 'Sponsors', count: 166, pct: '13.3%', color: 'bg-green-500', w: 'w-[13%]' },
  ];

  return (
    <AdminWebLayout navigate={navigate} title="Platform Reports" onBack={() => navigate('admin-dashboard')}>
        {/* Users by Role */}
        <div>
          <SectionLabel label="USERS BY ROLE" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-4">
              {roleData.map(r => (
                <div key={r.label}>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm text-gray-700 flex-1">{r.label}</span>
                    <span className="text-xs font-semibold text-gray-900">{r.count}</span>
                    <span className="text-xs text-gray-500">{r.pct}</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div className={`h-full ${r.color} ${r.w} rounded-full`} />
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Users by Region */}
        <div className="mt-2">
          <SectionLabel label="USERS BY REGION" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[{ region: 'Maharashtra', count: 312 }, { region: 'Delhi', count: 198 }, { region: 'Karnataka', count: 156 }, { region: 'Telangana', count: 124 }, { region: 'Tamil Nadu', count: 98 }].map(r => (
                <div key={r.region} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-sm text-gray-700">{r.region}</span>
                  <span className="text-sm font-semibold text-gray-900">{r.count}</span>
                </div>
              ))}
              <GhostBtn label="View All Regions →" onClick={() => {}} className="mt-1" />
            </div>
          </Card>
        </div>

        {/* Users by Sport */}
        <div className="mt-2">
          <SectionLabel label="USERS BY SPORT" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[{ sport: 'Cricket', count: 445 }, { sport: 'Football', count: 267 }, { sport: 'Athletics', count: 189 }, { sport: 'Badminton', count: 134 }].map(s => (
                <div key={s.sport} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-sm text-gray-700">{s.sport}</span>
                  <span className="text-sm font-semibold text-gray-900">{s.count}</span>
                </div>
              ))}
              <GhostBtn label="View All Sports →" onClick={() => {}} className="mt-1" />
            </div>
          </Card>
        </div>

        {/* Activity Metrics */}
        <div className="mt-2">
          <SectionLabel label="ACTIVITY METRICS" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[
                { label: 'New registrations (7d)', value: 45 },
                { label: 'Active users (7d)', value: 678 },
                { label: 'Posts (7d)', value: 123 },
                { label: 'Connections (7d)', value: 89 },
              ].map(m => (
                <div key={m.label} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-sm text-gray-500">{m.label}</span>
                  <span className="text-sm font-semibold text-gray-900">{m.value}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// ManageUsersScreen
// ---------------------------------------------------------------------------
export function ManageUsersScreen({ navigate }: { navigate: NavFn }) {
  const [activeTab, setActiveTab] = useState('All');
  
  const [selectedVerified, setSelectedVerified] = useState('');
  const [selectedActive, setSelectedActive] = useState('');
  
  const [showVerifiedFilter, setShowVerifiedFilter] = useState(false);
  const [showActiveFilter, setShowActiveFilter] = useState(false);

  const users = [
    { name: 'Priya Patel', role: 'Athlete', city: 'Mumbai', verified: true, active: true },
    { name: 'Arjun Kumar', role: 'Athlete', city: 'Delhi', verified: true, active: false },
    { name: 'Coach Sharma', role: 'Coach', city: 'Bangalore', verified: false, active: true },
    { name: 'Nike India', role: 'Sponsor', city: 'Mumbai', verified: true, active: true },
  ];

  const filtered = users.filter(u => {
    if (activeTab !== 'All' && u.role !== activeTab.slice(0, -1)) return false; // Athlete/Coach/Sponsor
    if (selectedVerified === 'Yes' && !u.verified) return false;
    if (selectedVerified === 'No' && u.verified) return false;
    if (selectedActive === 'Active' && !u.active) return false;
    if (selectedActive === 'Inactive' && u.active) return false;
    return true;
  });

  return (
    <AdminWebLayout navigate={navigate} title="Manage Users" onBack={() => navigate('admin-dashboard')} rightActions={<IconBtn icon={<SearchIcon />} onClick={() => navigate('search-filter')} />}>
      <div>
        <TabPills tabs={['All', 'Athletes', 'Coaches', 'Sponsors']} active={activeTab} onTab={setActiveTab} />
        <div className="flex gap-2 mt-3 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
          <FilterChip label={selectedVerified || "Verified ▼"} active={!!selectedVerified} onClick={() => setShowVerifiedFilter(true)} onRemove={() => setSelectedVerified('')} />
          <FilterChip label={selectedActive || "Active ▼"} active={!!selectedActive} onClick={() => setShowActiveFilter(true)} onRemove={() => setSelectedActive('')} />
        </div>
      </div>
      <div className="flex flex-col gap-2 mt-3">
        {filtered.map((u, i) => (
          <Card key={i}>
            <div className="flex items-center gap-3 p-3">
              <Avatar size={48} name={u.name} />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-900 truncate">{u.name}</p>
                <p className="text-xs text-gray-500">
                  👤 {u.role} · {u.city} · {u.verified ? '✓ Verified' : 'Unverified'} · {u.active ? '🟢 Active' : '🔴 Inactive'}
                </p>
              </div>
              <IconBtn icon={<span className="text-xl font-bold">⋯</span>} onClick={() => navigate('user-detail')} />
            </div>
          </Card>
        ))}
        {filtered.length === 0 && <div className="py-10 text-center text-gray-500 text-sm">No users match filters.</div>}
      </div>
      
      {showVerifiedFilter && <FilterBottomSheet title="Verified Status" options={['Yes', 'No']} selected={selectedVerified} onClose={() => setShowVerifiedFilter(false)} onSelect={setSelectedVerified} />}
      {showActiveFilter && <FilterBottomSheet title="Active Status" options={['Active', 'Inactive']} selected={selectedActive} onClose={() => setShowActiveFilter(false)} onSelect={setSelectedActive} />}
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// UserDetailVerifyScreen
// ---------------------------------------------------------------------------
export function UserDetailVerifyScreen({ navigate }: { navigate: NavFn }) {
  return (
    <AdminWebLayout navigate={navigate} title="User Detail" onBack={() => navigate('manage-users')} rightActions={<IconBtn icon={<span className="text-xl font-bold">⋯</span>} onClick={() => {}} />}>
        <div className="flex flex-col items-center gap-2">
          <Avatar size={80} name="Rohan Sharma" />
          <p className="text-xl font-bold text-gray-900">Rohan Sharma</p>
          <p className="text-sm text-gray-500">👤 Athlete · Mumbai, MH</p>
          <p className="text-xs font-semibold text-amber-500">Status: Unverified</p>
        </div>

        <div className="mt-2">
          <SectionLabel label="PROFILE INFO" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[
                { label: 'Email', value: 'rohan@email.com' },
                { label: 'Phone', value: '+91 98765 43210' },
                { label: 'Joined', value: 'Oct 15 2024' },
                { label: 'Last Active', value: 'Today' },
              ].map(r => (
                <div key={r.label} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-xs text-gray-500">{r.label}</span>
                  <span className="text-xs font-semibold text-gray-900">{r.value}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        <div className="mt-2">
          <SectionLabel label="VERIFICATION" />
          <div className="flex flex-col gap-3 mt-2">
            <Card>
              <div className="flex items-center gap-3 p-3">
                <span className="text-2xl">📜</span>
                <div className="flex-1">
                  <p className="text-sm font-semibold text-gray-900">State Championship 2024</p>
                  <p className="text-xs text-gray-500">Achievement Certificate</p>
                </div>
                <GhostBtn label="View Document" onClick={() => {}} />
              </div>
            </Card>
            <Card>
              <div className="flex items-center gap-3 p-3">
                <span className="text-2xl">🏏</span>
                <div className="flex-1">
                  <p className="text-sm font-semibold text-gray-900">Mumbai Premier League</p>
                  <p className="text-xs text-gray-500">Participation Certificate</p>
                </div>
                <GhostBtn label="View Document" onClick={() => {}} />
              </div>
            </Card>
          </div>
        </div>

        <div className="mt-2 flex flex-col gap-3">
          <SuccessBtn label="✓ Verify & Add Badge" onClick={() => {}} className="w-full" />
          <button
            className="w-full border border-amber-500 text-amber-500 rounded-xl py-3 text-sm font-semibold"
            onClick={() => {}}
          >
            Suspend Account
          </button>
          <DangerBtn label="🗑️ Delete Account" onClick={() => {}} className="w-full" />
        </div>
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// PendingApprovalsScreen
// ---------------------------------------------------------------------------
export function PendingApprovalsScreen({ navigate }: { navigate: NavFn }) {
  const pending = [
    { name: 'Kavya Singh', role: 'Athlete', city: 'Hyderabad', registered: 'Today' },
    { name: 'Manish Reddy', role: 'Athlete', city: 'Pune', registered: 'Today' },
  ];

  return (
    <AdminWebLayout navigate={navigate} title="Pending Approvals" onBack={() => navigate('admin-dashboard')}>
        <div>
          <SectionLabel label="NEW REGISTRATIONS (5)" />
          <div className="flex flex-col gap-3 mt-2">
            {pending.map((u, i) => (
              <Card key={i}>
                <div className="p-3">
                  <div className="flex items-center gap-3 mb-3">
                    <Avatar size={48} name={u.name} />
                    <div>
                      <p className="text-sm font-semibold text-gray-900">{u.name}</p>
                      <p className="text-xs text-gray-500">👤 {u.role} · {u.city}</p>
                      <p className="text-xs text-gray-400">Registered: {u.registered}</p>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <DangerBtn label="Reject" onClick={() => {}} className="flex-1" />
                    <SuccessBtn label="Approve" onClick={() => {}} className="flex-1" />
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div className="mt-4">
          <EmptyState
            title="No more pending items"
            description="All registrations have been reviewed."
            navigate={navigate}
          />
        </div>
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// ModerationQueueScreen
// ---------------------------------------------------------------------------
export function ModerationQueueScreen({ navigate }: { navigate: NavFn }) {
  const [activeTab, setActiveTab] = useState('All');

  const reports = [
    { id: '12345', type: 'Posts', reporter: 'Priya Patel', reason: 'Inappropriate content', time: '10m ago' },
    { id: '12344', type: 'Comments', reporter: 'Arjun Kumar', reason: 'Spam', time: '45m ago' },
    { id: '12343', type: 'Profiles', reporter: 'Coach Sharma', reason: 'Misinformation', time: '2h ago' },
  ];

  const filtered = reports.filter(r => activeTab === 'All' || r.type === activeTab);

  return (
    <AdminWebLayout navigate={navigate} title="Moderation Queue" onBack={() => navigate('admin-dashboard')}>
      <div>
        <TabPills tabs={['All', 'Posts', 'Comments', 'Profiles']} active={activeTab} onTab={setActiveTab} />
      </div>
      <div className="flex flex-col gap-3 mt-3">
        {filtered.map((r, i) => (
          <Card key={i}>
            <div className="p-3">
              <div className="flex items-start gap-2 mb-2">
                <span className="text-xl">⚠️</span>
                <div className="flex-1">
                  <p className="text-sm font-semibold text-gray-900">Reported {r.type.slice(0, -1)} #{r.id}</p>
                  <p className="text-xs text-gray-500">Reported by: {r.reporter}</p>
                  <p className="text-xs text-gray-500">Reason: {r.reason}</p>
                  <p className="text-xs text-gray-400 mt-1">{r.time}</p>
                </div>
              </div>
              <GhostBtn label="Review" onClick={() => navigate('report-detail')} />
            </div>
          </Card>
        ))}
        {filtered.length === 0 && <div className="py-10 text-center text-gray-500 text-sm">No items in queue.</div>}
      </div>
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// ReportDetailScreen
// ---------------------------------------------------------------------------
export function ReportDetailScreen({ navigate }: { navigate: NavFn }) {
  return (
    <AdminWebLayout navigate={navigate} title="Report #12345" onBack={() => navigate('moderation-queue')}>
        <div>
          <SectionLabel label="REPORT INFO" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[
                { label: 'Reported by', value: 'Priya Patel' },
                { label: 'Reason', value: 'Inappropriate content' },
                { label: 'Reported time', value: 'Today at 10:30 AM' },
              ].map(r => (
                <div key={r.label} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-xs text-gray-500">{r.label}</span>
                  <span className="text-xs font-semibold text-gray-900">{r.value}</span>
                </div>
              ))}
              <div className="flex justify-between items-center py-1">
                <span className="text-xs text-gray-500">Status</span>
                <span className="text-xs font-semibold text-amber-500">Pending Review</span>
              </div>
            </div>
          </Card>
        </div>

        <div className="mt-2">
          <SectionLabel label="REPORTED CONTENT" />
          <Card className="mt-2">
            <div className="p-3">
              <div className="flex items-center gap-3 mb-2">
                <Avatar size={40} name="Rahul Mehta" />
                <div>
                  <p className="text-sm font-semibold text-gray-900">Rahul Mehta</p>
                  <p className="text-xs text-gray-500">Cricket · Delhi</p>
                </div>
              </div>
              <p className="text-sm text-gray-600 leading-relaxed">
                This post was flagged for potentially violating community guidelines...
              </p>
              <GhostBtn label="View Full Content →" onClick={() => {}} className="mt-2" />
            </div>
          </Card>
        </div>

        <div className="mt-2 flex flex-col gap-3">
          <SectionLabel label="ACTIONS" />
          <SecondaryBtn label="✓ Dismiss Report" onClick={() => {}} className="w-full" />
          <DangerBtn label="🗑️ Remove Content" onClick={() => {}} className="w-full" />
          <DangerBtn label="🚫 Suspend User" onClick={() => {}} className="w-full" />
        </div>
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// ComposeNotificationScreen
// ---------------------------------------------------------------------------
export function ComposeNotificationScreen({ navigate }: { navigate: NavFn }) {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [role, setRole] = useState('All Roles');
  const [region, setRegion] = useState('All Regions');
  const [sport, setSport] = useState('All Sports');

  return (
    <AdminWebLayout navigate={navigate} title="Compose Notification" onBack={() => navigate('admin-dashboard')} rightActions={<GhostBtn label="Send" onClick={() => {}} />}>
        <InputField
          label="Notification Title *"
          placeholder="e.g., Trial Announcement"
          value={title}
          onChange={(v) => setTitle(v)}
        />
        <TextArea
          label="Message Body *"
          placeholder="Enter your notification message..."
          value={body}
          onChange={(v) => setBody(v)}
          rows={4}
        />

        <div>
          <SectionLabel label="TARGETING (Optional)" />
        </div>

        <SelectField
          label="Target Role"
          options={['All Roles', 'Athletes only', 'Coaches only', 'Sponsors only']}
          value={role}
          onChange={setRole}
        />
        <SelectField
          label="Target Region"
          options={['All Regions', 'Maharashtra', 'Delhi', 'Karnataka', 'Telangana']}
          value={region}
          onChange={setRegion}
        />
        <SelectField
          label="Target Sport"
          options={['All Sports', 'Cricket', 'Football', 'Athletics', 'Badminton']}
          value={sport}
          onChange={setSport}
        />

        <p className="text-xs text-gray-500">Estimated Reach: ~1,245 users</p>

        <PrimaryBtn label="Send Notification" onClick={() => {}} className="w-full" />
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// NotificationTargetingScreen
// ---------------------------------------------------------------------------
export function NotificationTargetingScreen({ navigate }: { navigate: NavFn }) {
  const [roles, setRoles] = useState<Record<string, boolean>>({ 'All Roles': true, 'Athletes only': false, 'Coaches only': false, 'Sponsors only': false });
  const [regions, setRegions] = useState<Record<string, boolean>>({ 'All Regions': true, Maharashtra: false, Delhi: false, Karnataka: false, 'Tamil Nadu': false });
  const [sports, setSports] = useState<Record<string, boolean>>({ 'All Sports': true, Cricket: false, Football: false, Athletics: false });

  const CheckRow = ({ label, checked, onChange }: { label: string; checked: boolean; onChange: () => void }) => (
    <div className="flex items-center gap-3 py-3 border-b border-gray-100 last:border-0 cursor-pointer" onClick={onChange}>
      <div className={`w-5 h-5 rounded border-2 flex items-center justify-center ${checked ? 'bg-blue-600 border-blue-600' : 'border-gray-300'}`}>
        {checked && <span className="text-white text-xs">✓</span>}
      </div>
      <span className="text-sm text-gray-700">{label}</span>
    </div>
  );

  return (
    <AdminWebLayout navigate={navigate} title="Notification Targeting" onBack={() => navigate('compose-notification')}>
        <div>
          <SectionLabel label="SELECT ROLES" />
          {Object.keys(roles).map(r => (
            <CheckRow key={r} label={r} checked={roles[r]} onChange={() => setRoles(prev => ({ ...prev, [r]: !prev[r] }))} />
          ))}
        </div>

        <div>
          <SectionLabel label="SELECT REGIONS" />
          {Object.keys(regions).map(r => (
            <CheckRow key={r} label={r} checked={regions[r]} onChange={() => setRegions(prev => ({ ...prev, [r]: !prev[r] }))} />
          ))}
        </div>

        <div>
          <SectionLabel label="SELECT SPORTS" />
          {Object.keys(sports).map(s => (
            <CheckRow key={s} label={s} checked={sports[s]} onChange={() => setSports(prev => ({ ...prev, [s]: !prev[s] }))} />
          ))}
        </div>

        <PrimaryBtn label="Apply Targeting" onClick={() => navigate('compose-notification')} className="w-full" />
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// OppApprovalQueueScreen
// ---------------------------------------------------------------------------
export function OppApprovalQueueScreen({ navigate }: { navigate: NavFn }) {
  const pending = [
    { org: 'Adidas India', title: 'Youth Cricket Program 2024', sport: 'Cricket', region: 'Maharashtra', submitted: 'Today' },
    { org: 'Puma Sports', title: 'Women in Sports Fund', sport: 'Athletics', region: 'Pan-India', submitted: 'Yesterday' },
  ];

  return (
    <AdminWebLayout navigate={navigate} title="Opportunity Approvals" onBack={() => navigate('admin-dashboard')}>
        <div>
          <SectionLabel label="PENDING (4)" />
          <div className="flex flex-col gap-3 mt-2">
            {pending.map((opp, i) => (
              <Card key={i}>
                <div className="p-3 cursor-pointer" onClick={() => navigate('opp-review-detail')}>
                  <div className="flex items-start gap-3 mb-3">
                    <Avatar size={40} name={opp.org} />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-bold text-gray-900 truncate">{opp.title}</p>
                      <p className="text-xs text-gray-500">{opp.org}</p>
                      <p className="text-xs text-gray-400">{opp.sport} · {opp.region}</p>
                      <p className="text-xs text-gray-400">Submitted: {opp.submitted}</p>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <DangerBtn label="Reject" onClick={e => { e.stopPropagation(); }} className="flex-1" />
                    <SuccessBtn label="Approve" onClick={e => { e.stopPropagation(); }} className="flex-1" />
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div className="mt-4">
          <SectionLabel label="RECENTLY APPROVED" />
          <div className="mt-2">
            <Card>
              <div className="flex items-center gap-3 p-3">
                <Avatar size={40} name="Nike India" />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold text-gray-900">Athlete Sponsorship 2024</p>
                  <p className="text-xs text-gray-500">Nike India</p>
                  <p className="text-xs text-gray-400">Approved: Oct 12 2024</p>
                </div>
                <GhostBtn label="View" onClick={() => navigate('opp-review-detail')} />
              </div>
            </Card>
          </div>
        </div>
    </AdminWebLayout>
  );
}

// ---------------------------------------------------------------------------
// OppReviewDetailScreen
// ---------------------------------------------------------------------------
export function OppReviewDetailScreen({ navigate }: { navigate: NavFn }) {
  return (
    <AdminWebLayout navigate={navigate} title="Review Opportunity" onBack={() => navigate('opp-approval-queue')} rightActions={<IconBtn icon={<span className="text-xl font-bold">⋯</span>} onClick={() => {}} />}>
        <div className="flex flex-col items-center gap-2">
          <Avatar size={80} name="Nike India" />
          <p className="text-xl font-bold text-gray-900">Nike India</p>
          <div className="flex items-center gap-2">
            <SportBadge sport="Sportswear" />
            <span className="text-xs text-gray-500">Pan-India</span>
          </div>
        </div>

        <p className="text-xl font-semibold text-gray-900 mt-4 text-center">Athlete Sponsorship 2024</p>

        <div className="mt-2">
          <SectionLabel label="SUBMISSION DETAILS" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[
                { label: 'Submitted by', value: 'Nike India' },
                { label: 'Submitted on', value: 'Oct 10 2024' },
              ].map(r => (
                <div key={r.label} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-xs text-gray-500">{r.label}</span>
                  <span className="text-xs font-semibold text-gray-900">{r.value}</span>
                </div>
              ))}
              <div className="flex justify-between items-center py-1">
                <span className="text-xs text-gray-500">Status</span>
                <span className="text-xs font-semibold text-amber-500">Pending Approval</span>
              </div>
            </div>
          </Card>
        </div>

        <div className="mt-2">
          <SectionLabel label="OPPORTUNITY DETAILS" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[
                { label: 'Sport', value: 'Cricket' },
                { label: 'Region', value: 'Pan-India' },
                { label: 'Type', value: 'Sponsorship' },
                { label: 'Eligibility', value: 'State-level and above' },
                { label: 'Deadline', value: 'Dec 31 2024' },
              ].map(r => (
                <div key={r.label} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-xs text-gray-500">{r.label}</span>
                  <span className="text-xs font-semibold text-gray-900">{r.value}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        <div className="mt-2">
          <SectionLabel label="DESCRIPTION" />
          <p className="text-sm text-gray-600 mt-2 leading-relaxed">
            Nike India is looking for talented athletes across India to represent the brand. Selected athletes will receive gear, training support, and financial assistance for competition travel. This program aims to support emerging athletes at the state level and above.
          </p>
        </div>

        <div className="mt-2">
          <SectionLabel label="ADMIN ACTIONS" />
          <div className="flex flex-col gap-3 mt-2">
            <SuccessBtn label="✓ Approve & Publish" onClick={() => {}} className="w-full" />
            <DangerBtn label="Reject with Reason" onClick={() => {}} className="w-full" />
          </div>
        </div>
    </AdminWebLayout>
  );
}
