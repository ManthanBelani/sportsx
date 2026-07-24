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

const athleteTabMap: Record<string, string> = {
  home: 'athlete-home',
  discover: 'discover',
  messages: 'chat-list',
  profile: 'my-profile-athlete',
};


// ---------------------------------------------------------------------------
// ViewProfileScreen
// ---------------------------------------------------------------------------
export function ViewProfileScreen({ navigate, onBack }: { navigate: NavFn; onBack?: () => void }) {
  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        title="Profile"
        onBack={onBack ?? (() => navigate(-1 as any))}
        rightActions={
          <IconBtn icon={<span className="text-xl font-bold">⋯</span>} onClick={() => {}} />
        }
      />
      <div className="flex-1 overflow-y-auto">
        {/* Banner */}
        <div className="h-44 bg-gradient-to-br from-blue-500 to-indigo-600 relative">
          <div className="absolute -bottom-10 left-1/2 -translate-x-1/2">
            <Avatar size={80} name="Priya Patel" />
          </div>
        </div>

        {/* Identity */}
        <div className="mt-12 flex flex-col items-center gap-1 px-4">
          <div className="flex items-center gap-1">
            <span className="text-lg font-bold text-gray-900">Priya Patel</span>
            <VerifiedBadge />
          </div>
          <div className="flex items-center gap-2">
            <SportBadge sport="Athletics" />
            <span className="text-xs text-gray-500">Delhi, DL</span>
          </div>
        </div>

        {/* Stats */}
        <div className="px-4 mt-4">
          <StatRow stats={[{ label: 'Posts', value: 31 }, { label: 'Connects', value: 203 }, { label: 'Achieve', value: 8 }]} />
        </div>

        {/* Actions */}
        <div className="flex gap-3 px-4 mt-4">
          <SecondaryBtn label="Connect" onClick={() => {}} className="flex-1" />
          <PrimaryBtn label="Message" onClick={() => navigate('chat-screen')} className="flex-1" />
        </div>

        {/* About */}
        <div className="px-4 mt-6">
          <SectionLabel label="ABOUT" />
          <p className="text-sm text-gray-600 mt-2 leading-relaxed">
            National-level sprinter representing Delhi Athletics Association. Passionate about breaking barriers and inspiring young athletes across India.
          </p>
        </div>

        {/* Achievements */}
        <div className="px-4 mt-6">
          <SectionLabel label="ACHIEVEMENTS" />
          <div className="flex flex-col gap-3 mt-2">
            <Card>
              <div className="flex items-center gap-3 p-3">
                <span className="text-2xl">🥇</span>
                <div>
                  <p className="text-sm font-semibold text-gray-900">National Athletics Championship</p>
                  <p className="text-xs text-gray-500">Gold Medal · 100m Sprint · 2024</p>
                </div>
              </div>
            </Card>
            <Card>
              <div className="flex items-center gap-3 p-3">
                <span className="text-2xl">🥈</span>
                <div>
                  <p className="text-sm font-semibold text-gray-900">State Athletics Meet</p>
                  <p className="text-xs text-gray-500">Silver Medal · 200m Sprint · 2023</p>
                </div>
              </div>
            </Card>
          </div>
        </div>

        {/* Tournament History */}
        <div className="px-4 mt-6">
          <SectionLabel label="TOURNAMENT HISTORY" />
          <div className="flex flex-col gap-3 mt-2">
            <Card>
              <div className="flex items-center justify-between p-3">
                <div>
                  <p className="text-sm font-semibold text-gray-900">Nationals 2024</p>
                  <p className="text-xs text-gray-500">100m · 11.2s · Rank #1</p>
                </div>
                <span className="text-xs text-green-600 font-semibold">Finished</span>
              </div>
            </Card>
            <Card>
              <div className="flex items-center justify-between p-3">
                <div>
                  <p className="text-sm font-semibold text-gray-900">State Open 2023</p>
                  <p className="text-xs text-gray-500">200m · 23.4s · Rank #2</p>
                </div>
                <span className="text-xs text-blue-600 font-semibold">Completed</span>
              </div>
            </Card>
          </div>
        </div>

        {/* Performance Stats */}
        <div className="px-4 mt-6">
          <SectionLabel label="PERFORMANCE STATS" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[{ label: 'Personal Best (100m)', value: '11.1s' }, { label: 'Personal Best (200m)', value: '23.1s' }, { label: 'Competitions', value: '14' }, { label: 'Win Rate', value: '71%' }].map(s => (
                <div key={s.label} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-xs text-gray-500">{s.label}</span>
                  <span className="text-xs font-semibold text-gray-900">{s.value}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Media Gallery */}
        <div className="px-4 mt-6">
          <SectionLabel label="MEDIA GALLERY" />
          <div className="grid grid-cols-3 gap-1 mt-2">
            {[...Array(6)].map((_, i) => (
              <div
                key={i}
                className="aspect-square bg-gray-200 rounded-lg flex items-center justify-center text-gray-400 text-2xl cursor-pointer"
                onClick={() => navigate('media-viewer')}
              >
                📷
              </div>
            ))}
          </div>
        </div>

        {/* Social Links */}
        <div className="px-4 mt-6 mb-8">
          <SectionLabel label="SOCIAL LINKS" />
          <div className="flex gap-4 mt-2">
            {['𝕏', 'in', '▶', '📸'].map((icon, i) => (
              <div key={i} className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center text-gray-600 text-sm font-bold cursor-pointer">
                {icon}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// PostDetailScreen
// ---------------------------------------------------------------------------
export function PostDetailScreen({ navigate, onBack }: { navigate: NavFn; onBack?: () => void }) {
  const [comment, setComment] = useState('');

  const comments = [
    { name: 'Arjun Kumar', text: 'Great achievement! Keep it up 🔥', time: '2m ago' },
    { name: 'Sunita Rao', text: 'Congratulations Priya! Proud of you.', time: '10m ago' },
    { name: 'Rahul Mehta', text: 'Incredible performance as always!', time: '1h ago' },
    { name: 'Coach Sharma', text: 'Hard work pays off. Well done!', time: '3h ago' },
  ];

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        title="Post"
        onBack={onBack ?? (() => navigate(-1 as any))}
        rightActions={
          <IconBtn icon={<span className="text-xl font-bold">⋯</span>} onClick={() => {}} />
        }
      />
      <div className="flex-1 overflow-y-auto pb-20">
        <div className="px-4 pt-4">
          <PostCard
            author={{ name: 'Priya Patel', sport: 'Athletics', verified: true }}
            content="Just won gold at the National Athletics Championship! 🥇 Grateful for all your support. This one's for Delhi! 🏃‍♀️"
            timestamp="2h ago"
            likes={142}
            comments={5}
            navigate={navigate}
          />
        </div>

        <div className="px-4 mt-4">
          <SectionLabel label="COMMENTS (5)" />
          <div className="flex flex-col gap-0 mt-2">
            {comments.map((c, i) => (
              <div key={i} className="flex items-start gap-2 py-3 border-b border-gray-100 last:border-0">
                <Avatar size={28} name={c.name} />
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-semibold text-gray-900">{c.name}</p>
                  <p className="text-xs text-gray-600 mt-0.5">{c.text}</p>
                </div>
                <span className="text-xs text-gray-400 shrink-0">{c.time}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Fixed comment input */}
      <div className="border-t border-gray-200 flex items-center gap-2 px-4 py-2 bg-white">
        <Avatar size={32} name="Rohan Sharma" />
        <input
          className="flex-1 text-sm bg-gray-100 rounded-full px-4 py-2 outline-none"
          placeholder="Add a comment..."
          value={comment}
          onChange={e => setComment(e.target.value)}
        />
        <button className="text-blue-600 font-semibold text-sm px-2">Send</button>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// OpportunitiesListScreen
// ---------------------------------------------------------------------------
export function OpportunitiesListScreen({ navigate }: { navigate: NavFn }) {
  const [activeTab, setActiveTab] = useState('All');
  
  const [selectedSport, setSelectedSport] = useState('');
  const [selectedRegion, setSelectedRegion] = useState('');
  
  const [showSportFilter, setShowSportFilter] = useState(false);
  const [showRegionFilter, setShowRegionFilter] = useState(false);

  const opportunities = [
    { title: 'Athlete Sponsorship 2024', org: 'Nike India', sport: 'Cricket', region: 'Pan-India', type: 'Sponsorship' },
    { title: 'Equipment Grant Program', org: 'BCCI Foundation', sport: 'Cricket', region: 'Maharashtra', type: 'Equipment' },
    { title: 'Youth Sports Fund 2024', org: 'SAI', sport: 'Athletics', region: 'National', type: 'Funding' },
  ];

  const filtered = opportunities.filter(opp => {
    if (activeTab !== 'All' && opp.type !== activeTab) return false;
    if (selectedSport && opp.sport !== selectedSport) return false;
    if (selectedRegion && opp.region !== selectedRegion) return false;
    return true;
  });

  return (
    <div className="flex flex-col h-full overflow-hidden relative">
      <AppBar
        title="Opportunities"
        logoLeft
        rightActions={
          <div className="flex gap-1">
            <IconBtn icon={<BellIcon />} onClick={() => navigate('notifications-list')} />
            <IconBtn icon={<SettingsIcon />} onClick={() => navigate('settings')} />
          </div>
        }
      />
      <div className="px-4 pt-3">
        <SearchBar placeholder="Search opportunities..." onSearch={() => {}} />
        <div className="mt-3">
          <TabPills tabs={['All', 'Sponsorship', 'Equipment', 'Funding']} active={activeTab} onTab={setActiveTab} />
        </div>
        <div className="flex gap-2 mt-3 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
          <FilterChip label={selectedSport || "Sport ▼"} active={!!selectedSport} onClick={() => setShowSportFilter(true)} onRemove={() => setSelectedSport('')} />
          <FilterChip label={selectedRegion || "Region ▼"} active={!!selectedRegion} onClick={() => setShowRegionFilter(true)} onRemove={() => setSelectedRegion('')} />
        </div>
      </div>
      <div className="flex-1 overflow-y-auto px-4 pt-3 flex flex-col gap-3 pb-4">
        {filtered.map((opp, i) => (
          <OpportunityCard
            key={i}
            title={opp.title}
            org={opp.org}
            sport={opp.sport}
            region={opp.region}
            type={opp.type}
            onApply={() => navigate('apply-form')}
            onView={() => navigate('opportunity-detail')}
            navigate={navigate}
          />
        ))}
        {filtered.length === 0 && <div className="py-10 text-center text-gray-500 text-sm">No opportunities match filters.</div>}
      </div>
      <BottomNav role="athlete" active="discover" onTab={(tab: string) => navigate(athleteTabMap[tab] || tab)} />
      
      {showSportFilter && <FilterBottomSheet title="Select Sport" options={['Cricket', 'Football', 'Athletics']} selected={selectedSport} onClose={() => setShowSportFilter(false)} onSelect={setSelectedSport} />}
      {showRegionFilter && <FilterBottomSheet title="Select Region" options={['Pan-India', 'Maharashtra', 'National', 'Delhi']} selected={selectedRegion} onClose={() => setShowRegionFilter(false)} onSelect={setSelectedRegion} />}
    </div>
  );
}

// ---------------------------------------------------------------------------
// OpportunityDetailScreen
// ---------------------------------------------------------------------------
export function OpportunityDetailScreen({ navigate, onBack }: { navigate: NavFn; onBack?: () => void }) {
  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        title="Opportunity Details"
        onBack={onBack ?? (() => navigate(-1 as any))}
        rightActions={
          <IconBtn icon={<span className="text-xl">★</span>} onClick={() => {}} />
        }
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        {/* Sponsor identity */}
        <div className="flex flex-col items-center gap-2">
          <Avatar size={80} name="Nike India" />
          <p className="text-xl font-bold text-gray-900">Nike India</p>
          <div className="flex items-center gap-2">
            <SportBadge sport="Sportswear" />
            <span className="text-xs text-gray-500">Pan-India</span>
          </div>
        </div>

        <h2 className="text-xl font-semibold text-gray-900 mt-4 text-center">Athlete Sponsorship 2024</h2>

        {/* About */}
        <div className="mt-6">
          <SectionLabel label="ABOUT" />
          <p className="text-sm text-gray-600 mt-2 leading-relaxed">
            Nike India is looking for talented athletes across India to represent the brand. Selected athletes will receive gear, training support, and financial assistance for competition travel.
          </p>
        </div>

        {/* Details */}
        <div className="mt-6">
          <SectionLabel label="DETAILS" />
          <Card className="mt-2">
            <div className="p-3 flex flex-col gap-2">
              {[
                { label: 'Sport', value: 'Cricket' },
                { label: 'Region', value: 'Pan-India' },
                { label: 'Type', value: 'Sponsorship' },
                { label: 'Eligibility', value: 'State-level and above' },
                { label: 'Deadline', value: 'Dec 31 2024' },
              ].map(row => (
                <div key={row.label} className="flex justify-between items-center py-1 border-b border-gray-100 last:border-0">
                  <span className="text-xs text-gray-500">{row.label}</span>
                  <span className="text-xs font-semibold text-gray-900">{row.value}</span>
                </div>
              ))}
              <div className="flex justify-between items-center py-1">
                <span className="text-xs text-gray-500">Status</span>
                <StatusDot status="open" label="Open" />
              </div>
            </div>
          </Card>
        </div>

        {/* Sponsor */}
        <div className="mt-6">
          <SectionLabel label="SPONSOR" />
          <div className="flex items-center gap-3 mt-2">
            <Avatar size={48} name="Nike India" />
            <div className="flex-1">
              <p className="text-sm font-semibold text-gray-900">Nike India</p>
            </div>
            <GhostBtn label="View Profile →" onClick={() => navigate('view-profile')} />
          </div>
        </div>

        {/* CTA */}
        <div className="mt-6">
          <CTABtn label="Apply Now" onClick={() => navigate('apply-form')} className="w-full" />
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// ApplyFormScreen
// ---------------------------------------------------------------------------
export function ApplyFormScreen({ navigate, onBack }: { navigate: NavFn; onBack?: () => void }) {
  const [why, setWhy] = useState('');
  const [achievements, setAchievements] = useState('');
  const [contactPref, setContactPref] = useState('In-app message');

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        title="Apply for Opportunity"
        onBack={onBack ?? (() => navigate(-1 as any))}
        rightActions={<GhostBtn label="Submit" onClick={() => navigate('app-submitted')} />}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        <div>
          <p className="text-sm text-gray-500">You are applying for:</p>
          <p className="text-sm font-semibold text-gray-900 mt-0.5">Athlete Sponsorship 2024 — Nike India</p>
        </div>

        <div>
          <SectionLabel label="YOUR PROFILE" />
          <div className="flex items-center gap-3 mt-2">
            <Avatar size={48} name="Rohan Sharma" />
            <div>
              <p className="text-sm font-semibold text-gray-900">Rohan Sharma</p>
              <p className="text-xs text-gray-500">Cricket · Mumbai · State Level</p>
            </div>
          </div>
        </div>

        <Divider />

        <TextArea
          label="Why should you be selected? *"
          placeholder="Describe why you're the right fit..."
          value={why}
          onChange={(v) => setWhy(v)}
          rows={4}
        />

        <TextArea
          label="Relevant Achievements"
          placeholder="List your key achievements..."
          value={achievements}
          onChange={(v) => setAchievements(v)}
          rows={3}
        />

        <SelectField
          label="Contact Preference"
          options={['In-app message', 'Email', 'Phone']}
          value={contactPref}
          onChange={setContactPref}
        />

        <PrimaryBtn label="Submit Application" onClick={() => navigate('app-submitted')} className="w-full" />

        <p className="text-xs text-gray-500 text-center">Your profile will be shared with the sponsor for review.</p>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// AppSubmittedScreen
// ---------------------------------------------------------------------------
export function AppSubmittedScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden">
      <div className="flex flex-col items-center justify-center h-full px-8 text-center gap-4">
        <CheckCircleIcon className="w-16 h-16 text-green-500" />
        <p className="text-xl font-bold text-gray-900">Application Submitted!</p>
        <p className="text-sm text-gray-500">
          Your application for Athlete Sponsorship 2024 has been sent to Nike India for review.
        </p>
        <p className="text-sm text-gray-500">
          You will be notified once the sponsor reviews your application.
        </p>
        <SecondaryBtn label="View My Applications" onClick={() => {}} className="w-full" />
        <PrimaryBtn label="Back to Opportunities" onClick={() => navigate('opportunities-list')} className="w-full" />
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// SearchFilterScreen
// ---------------------------------------------------------------------------
export function SearchFilterScreen({ navigate, onBack, onApply }: { navigate: NavFn; onBack?: () => void; onApply?: () => void }) {
  const [selected, setSelected] = useState<Set<string>>(new Set());

  const toggle = (key: string) => {
    setSelected(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const chips = (items: string[]) => (
    <div className="flex flex-wrap gap-2 mt-2">
      {items.map(item => (
        <FilterChip key={item} label={item} active={selected.has(item)} onClick={() => toggle(item)} />
      ))}
    </div>
  );

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        title="Search & Filter"
        onBack={onBack ?? (() => navigate(-1 as any))}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-5">
        <SearchBar placeholder="Search..." onSearch={() => {}} />

        <div>
          <SectionLabel label="FILTER BY SPORT" />
          {chips(['Cricket', 'Football', 'Athletics', 'Badminton', 'Swimming', 'Tennis'])}
          <GhostBtn label="+ More" onClick={() => {}} className="mt-2" />
        </div>

        <div>
          <SectionLabel label="FILTER BY LOCATION" />
          {chips(['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Pune', 'Chennai'])}
          <GhostBtn label="+ More" onClick={() => {}} className="mt-2" />
        </div>

        <div>
          <SectionLabel label="FILTER BY ACHIEVEMENT" />
          {chips(['School', 'State', 'National', 'International'])}
        </div>

        <div>
          <SectionLabel label="FILTER BY AGE" />
          {chips(['Under-14', 'Under-16', 'Under-19', 'Under-23', 'Open'])}
        </div>

        <div className="flex items-center justify-between mt-2">
          <GhostBtn label="Clear All Filters" onClick={() => setSelected(new Set())} />
        </div>

        <PrimaryBtn label="Apply Filters" onClick={onApply ?? (() => {})} className="w-full" />
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// NotificationsListScreen
// ---------------------------------------------------------------------------
export function NotificationsListScreen({ navigate }: { navigate: NavFn }) {
  const todayNotifs = [
    { icon: '🤝', title: 'New Connection!', body: 'Arjun Kumar accepted your connection request.', time: '2m ago', read: false },
    { icon: '🏆', title: 'Opportunity Match', body: 'A new sponsorship matches your profile.', time: '30m ago', read: false },
  ];
  const yesterdayNotifs = [
    { icon: '👍', title: 'Post Liked', body: 'Sunita Rao liked your post about Nationals 2024.', time: 'Yesterday', read: true },
    { icon: '💬', title: 'New Comment', body: 'Coach Sharma commented on your achievement post.', time: 'Yesterday', read: true },
  ];

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        title="Notifications"
        logoLeft
        rightActions={<IconBtn icon={<SettingsIcon />} onClick={() => navigate('settings')} />}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-3 pb-4">
        <SectionLabel label="TODAY" />
        <div className="flex flex-col gap-2 mt-2">
          {todayNotifs.map((n, i) => (
            <NotificationCard
              key={i}
              icon={n.icon}
              title={n.title}
              body={n.body}
              time={n.time}
              read={n.read}
              onClick={() => navigate('notification-detail')}
              navigate={navigate}
            />
          ))}
        </div>

        <div className="mt-4">
          <SectionLabel label="YESTERDAY" />
          <div className="flex flex-col gap-2 mt-2">
            {yesterdayNotifs.map((n, i) => (
              <NotificationCard
                key={i}
                icon={n.icon}
                title={n.title}
                body={n.body}
                time={n.time}
                read={n.read}
                onClick={() => navigate('notification-detail')}
                navigate={navigate}
              />
            ))}
          </div>
        </div>
      </div>
      <BottomNav role="athlete" active="home" onTab={(tab: string) => navigate(athleteTabMap[tab] || tab)} />
    </div>
  );
}

// ---------------------------------------------------------------------------
// NotificationDetailScreen
// ---------------------------------------------------------------------------
export function NotificationDetailScreen({ navigate, onBack }: { navigate: NavFn; onBack?: () => void }) {
  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        title="Notification Detail"
        onBack={onBack ?? (() => navigate(-1 as any))}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-8 flex flex-col items-center text-center gap-4 pb-8">
        <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center text-3xl">🤝</div>
        <p className="text-xl font-bold text-gray-900">New Connection!</p>
        <p className="text-sm text-gray-700 leading-relaxed">
          Arjun Kumar accepted your connection request. You are now connected and can message each other directly.
        </p>
        <p className="text-xs text-gray-500">Received: Today at 2:30 PM</p>
        <PrimaryBtn label="View Profile" onClick={() => navigate('view-profile')} className="w-full" />
        <SecondaryBtn label="Send Message" onClick={() => navigate('chat-screen')} className="w-full" />
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------
export function SettingsScreen({ navigate, onBack }: { navigate: NavFn; onBack?: () => void }) {
  const [pushNotif, setPushNotif] = useState(true);
  const [emailNotif, setEmailNotif] = useState(false);

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        title="Settings"
        onBack={onBack ?? (() => navigate(-1 as any))}
      />
      <div className="flex-1 overflow-y-auto pb-8">
        {/* Account */}
        <div className="border-b border-gray-100">
          <div className="px-4 pt-4 pb-1">
            <SectionLabel label="ACCOUNT" />
          </div>
          <SettingRow label="Edit Profile" icon={<EditIcon />} onClick={() => navigate('edit-profile')} />
          <SettingRow label="Change Password" icon={<EyeIcon />} onClick={() => {}} />
          <SettingRow label="Email Preferences" icon={<BellIcon />} onClick={() => {}} />
        </div>

        {/* Privacy */}
        <div className="border-b border-gray-100">
          <div className="px-4 pt-4 pb-1">
            <SectionLabel label="PRIVACY" />
          </div>
          <SettingRow label="Profile Visibility" icon={<EyeIcon />} onClick={() => {}} />
          <SettingRow label="Blocked Users" icon={<WarningIcon />} onClick={() => {}} />
        </div>

        {/* Notifications */}
        <div className="border-b border-gray-100">
          <div className="px-4 pt-4 pb-1">
            <SectionLabel label="NOTIFICATIONS" />
          </div>
          <SettingRow
            label="Push Notifications"
            icon={<BellIcon />}
            toggle={{ value: pushNotif, onChange: setPushNotif }}
          />
          <SettingRow
            label="Email Notifications"
            icon={<BellIcon />}
            toggle={{ value: emailNotif, onChange: setEmailNotif }}
          />
        </div>

        {/* Support */}
        <div className="border-b border-gray-100">
          <div className="px-4 pt-4 pb-1">
            <SectionLabel label="SUPPORT" />
          </div>
          <SettingRow label="Help & Support" icon={<ChevronRightIcon />} onClick={() => {}} />
          <SettingRow label="Terms of Service" icon={<ChevronRightIcon />} onClick={() => {}} />
          <SettingRow label="Privacy Policy" icon={<ChevronRightIcon />} onClick={() => {}} />
        </div>

        {/* Danger Zone */}
        <div className="px-4 py-4">
          <SectionLabel label="DANGER ZONE" />
          <div className="mt-3">
            <DangerBtn label="🚪 Log Out" onClick={() => {}} className="w-full mb-3" />
            <DangerBtn label="🗑️ Delete Account" onClick={() => {}} className="w-full" />
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// MediaViewerScreen
// ---------------------------------------------------------------------------
export function MediaViewerScreen({ navigate, onBack }: { navigate: NavFn; onBack?: () => void }) {
  return (
    <div className="h-full bg-black flex flex-col relative overflow-hidden">
      {/* Top bar */}
      <div className="absolute top-0 left-0 right-0 flex items-center justify-between px-4 pt-10 pb-4 z-10">
        <button
          className="text-white text-2xl"
          onClick={onBack ?? (() => navigate(-1 as any))}
        >
          ←
        </button>
        <div className="flex gap-3">
          <button className="text-white text-xl">⋯</button>
          <button className="text-white text-xl">⬇</button>
        </div>
      </div>

      {/* Center image area */}
      <div className="flex-1 flex items-center justify-center">
        <div className="aspect-video bg-gray-800 rounded-xl flex items-center justify-center text-gray-500 text-4xl w-full mx-4">
          📷
        </div>
      </div>

      {/* Bottom overlay */}
      <div className="bg-gradient-to-t from-black/70 to-transparent px-4 pb-6 pt-4">
        <div className="flex items-center gap-3 mb-2">
          <Avatar size={40} name="Rohan Sharma" />
          <div>
            <p className="text-white text-sm font-semibold">Rohan Sharma</p>
            <SportBadge sport="Cricket" />
          </div>
        </div>
        <p className="text-white text-sm mb-3">Amazing training session today! 🏏</p>
        <div className="flex gap-6">
          {['❤️', '💬', '↗️'].map((icon, i) => (
            <button key={i} className="text-white text-xl">{icon}</button>
          ))}
        </div>
      </div>
    </div>
  );
}
