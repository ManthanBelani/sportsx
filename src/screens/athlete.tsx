import { useState } from 'react'
import {
  AppBar,
  BottomNav,
  IconBtn,
  PrimaryBtn,
  SecondaryBtn,
  GhostBtn,
  DangerBtn,
  InputField,
  TextArea,
  SearchBar,
  SelectField,
  Avatar,
  SportBadge,
  TabPills,
  FilterChip,
  SectionLabel,
  Divider,
  StoriesRow,
  PostCard,
  AthleteCard,
  AcademyCard,
  SponsorCard,
  Card,
  EmptyState,
  UploadArea,
  ProfileHeader,
  StatRow,
  BellIcon,
  SettingsIcon,
  EditIcon,
  CameraIcon,
  ChevronRightIcon,
  MessageIcon,
  type NavFn,
} from '../components/ui'

// Tab navigation helper
const athleteTabMap: Record<string, string> = {
  home: 'athlete-home',
  discover: 'discover',
  messages: 'chat-list',
  profile: 'my-profile-athlete',
}

// ─── Athlete Home Screen ──────────────────────────────────────────────────────
export function AthleteHomeScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden bg-slate-50">
      <AppBar
        logoLeft
        rightActions={
          <>
            <IconBtn icon={<BellIcon size={20} />} onClick={() => navigate('notifications')} />
            <IconBtn icon={<SettingsIcon size={20} />} onClick={() => navigate('settings')} />
          </>
        }
      />
      <StoriesRow />
      <div className="flex-1 overflow-y-auto">
        <PostCard
          name="Rohan Sharma"
          sport="Cricket"
          time="2h ago"
          caption="Great training session today! Working on my cover drive technique. Every rep counts. 💪"
          likes={42}
          comments={8}
          hasImage
          onClick={() => navigate('post-detail')}
        />
        <PostCard
          name="Priya Menon"
          sport="Athletics"
          time="4h ago"
          caption="New personal best in 400m sprint! Hard work paying off. Thank you coach Arjun for the push!"
          likes={87}
          comments={14}
          hasImage
          onClick={() => navigate('post-detail')}
        />
        <PostCard
          name="Vikram Singh"
          sport="Football"
          time="6h ago"
          caption="State-level tournament next weekend. Our team is ready. Come support us at Nehru Stadium, Pune!"
          likes={31}
          comments={5}
          hasImage={false}
          onClick={() => navigate('post-detail')}
        />
      </div>
      <BottomNav
        role="athlete"
        active="home"
        onTab={t => navigate(athleteTabMap[t] ?? 'athlete-home')}
        onFab={() => navigate('create-post')}
      />
    </div>
  )
}

// ─── Create Post Screen ───────────────────────────────────────────────────────
export function CreatePostScreen({ navigate }: { navigate: NavFn }) {
  const [caption, setCaption] = useState('')
  const [hasImage, setHasImage] = useState(false)

  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        onBack={() => navigate('athlete-home')}
        title="Create Post"
        rightActions={<GhostBtn onClick={() => navigate('athlete-home')}>Post</GhostBtn>}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        <div className="flex items-center gap-3 mb-4">
          <Avatar size={48} name="Rohan Sharma" />
          <div>
            <p className="text-sm font-semibold text-gray-900">Rohan Sharma</p>
            <SportBadge sport="Cricket" />
          </div>
        </div>

        <TextArea
          placeholder="What's on your mind?"
          value={caption}
          onChange={setCaption}
          rows={5}
        />

        <div className="flex gap-3 mt-4">
          <button
            className="flex items-center gap-2 px-4 py-2 rounded-xl border border-gray-200 bg-slate-50 text-sm text-gray-600"
            onClick={() => setHasImage(true)}
          >
            <CameraIcon size={18} color="#6B7280" />
            Add Photo
          </button>
          <button className="flex items-center gap-2 px-4 py-2 rounded-xl border border-gray-200 bg-slate-50 text-sm text-gray-600">
            <span>🎥</span>
            Add Video
          </button>
        </div>

        {hasImage ? (
          <div
            className="mt-4 rounded-xl border-2 border-blue-300 bg-blue-50 flex items-center justify-center"
            style={{ height: 160 }}
          >
            <div className="flex flex-col items-center gap-2 text-blue-400">
              <span className="text-3xl">🖼️</span>
              <span className="text-sm">Photo added</span>
            </div>
          </div>
        ) : (
          <div
            className="mt-4 rounded-xl border-2 border-dashed border-gray-200 flex items-center justify-center"
            style={{ height: 120 }}
          >
            <span className="text-sm text-gray-400">No image selected</span>
          </div>
        )}

        <div className="mt-4">
          <p className="text-xs font-semibold text-gray-500 mb-2">Add hashtags:</p>
          <div className="flex flex-wrap gap-2">
            <SportBadge sport="#cricket" />
            <SportBadge sport="#training" />
            <SportBadge sport="#sportxindia" />
            <button className="text-xs text-blue-600 font-semibold px-2 py-0.5 rounded-md border border-blue-200">+ Add</button>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── My Profile — Athlete ─────────────────────────────────────────────────────
export function MyProfileAthleteScreen({ navigate }: { navigate: NavFn }) {
  const galleryColors = ['#DBEAFE', '#FEF3C7', '#D1FAE5', '#FCE7F3', '#EDE9FE', '#FEE2E2']

  return (
    <div className="flex flex-col h-full overflow-hidden bg-slate-50">
      <AppBar
        onBack={() => navigate('athlete-home')}
        title="My Profile"
        rightActions={
          <IconBtn icon={<EditIcon size={20} />} onClick={() => navigate('edit-profile')} />
        }
      />
      <div className="flex-1 overflow-y-auto">
        <ProfileHeader name="Rohan Sharma" sport="Cricket" location="Mumbai, MH" verified />
        <StatRow
          stats={[
            { label: 'Posts', value: 24 },
            { label: 'Connects', value: 156 },
            { label: 'Achieve', value: 12 },
          ]}
        />

        <div className="px-4 py-4 flex flex-col gap-5 bg-white mt-2">
          <div>
            <SectionLabel>ABOUT</SectionLabel>
            <p className="text-sm text-gray-700 leading-relaxed">
              State-level cricketer from Mumbai with 6 years of competitive experience. Specialise in middle-order batting and off-spin bowling. Passionate about representing India someday.
            </p>
          </div>

          <div>
            <SectionLabel>ACHIEVEMENTS</SectionLabel>
            <div className="flex flex-col gap-3">
              <Card>
                <div className="flex items-center gap-3">
                  <span className="text-2xl">🏆</span>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">Maharashtra State Championship</p>
                    <p className="text-xs text-gray-500">Runner-up · 2023</p>
                  </div>
                </div>
              </Card>
              <Card>
                <div className="flex items-center gap-3">
                  <span className="text-2xl">🥇</span>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">District Under-23 Gold Medal</p>
                    <p className="text-xs text-gray-500">Winner · 2022</p>
                  </div>
                </div>
              </Card>
            </div>
          </div>

          <div>
            <SectionLabel>TOURNAMENT HISTORY</SectionLabel>
            <div className="flex flex-col gap-3">
              <Card>
                <div className="flex items-center gap-3">
                  <span className="text-2xl">🏏</span>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">Ranji Trophy — Mumbai XI</p>
                    <p className="text-xs text-gray-500">Nov 2023 · Semi-Finals</p>
                  </div>
                </div>
              </Card>
              <Card>
                <div className="flex items-center gap-3">
                  <span className="text-2xl">🏏</span>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">Vijay Hazare Trophy</p>
                    <p className="text-xs text-gray-500">Oct 2022 · Quarter Finals</p>
                  </div>
                </div>
              </Card>
            </div>
          </div>

          <div>
            <SectionLabel>PERFORMANCE STATS</SectionLabel>
            <Card>
              <div className="flex flex-col gap-3">
                {[
                  { label: 'Batting Average', value: '45.2' },
                  { label: 'Matches', value: '32' },
                  { label: 'Best Score', value: '128*' },
                  { label: 'Wickets', value: '45' },
                ].map((s, i, arr) => (
                  <div key={s.label}>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">{s.label}</span>
                      <span className="text-sm font-semibold text-gray-900">{s.value}</span>
                    </div>
                    {i < arr.length - 1 && <Divider />}
                  </div>
                ))}
              </div>
            </Card>
          </div>

          <div>
            <SectionLabel>MEDIA GALLERY</SectionLabel>
            <div className="grid grid-cols-3 gap-2">
              {galleryColors.map((color, i) => (
                <div
                  key={i}
                  className="rounded-xl aspect-square"
                  style={{ background: color }}
                />
              ))}
            </div>
          </div>

          <div>
            <SectionLabel>SOCIAL LINKS</SectionLabel>
            <div className="flex flex-wrap gap-2">
              <SecondaryBtn onClick={() => {}}>Instagram</SecondaryBtn>
              <SecondaryBtn onClick={() => {}}>Twitter</SecondaryBtn>
              <SecondaryBtn onClick={() => {}}>LinkedIn</SecondaryBtn>
            </div>
          </div>

          <SecondaryBtn full onClick={() => {}}>Share Profile</SecondaryBtn>
        </div>
      </div>
    </div>
  )
}

// ─── Edit Profile Screen ──────────────────────────────────────────────────────
export function EditProfileScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        onBack={() => navigate('my-profile-athlete')}
        title="Edit Profile"
        rightActions={<GhostBtn onClick={() => navigate('my-profile-athlete')}>Save</GhostBtn>}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        <div className="flex flex-col items-center mb-6">
          <div className="relative">
            <Avatar size={80} name="Rohan Sharma" />
            <button className="absolute bottom-0 right-0 w-7 h-7 rounded-full bg-blue-600 border-2 border-white flex items-center justify-center">
              <CameraIcon size={14} color="white" />
            </button>
          </div>
          <span className="text-xs text-blue-600 mt-2">Change Photo</span>
        </div>

        <SectionLabel>PERSONAL INFO</SectionLabel>
        <div className="flex flex-col gap-4 mb-6">
          <InputField label="Full Name" value="Rohan Sharma" />
          <TextArea label="Bio" value="State-level cricketer from Mumbai with 6 years of competitive experience." />
          <SelectField
            label="Primary Sport"
            value="Cricket"
            options={['Cricket', 'Football', 'Athletics', 'Badminton']}
          />
          <InputField label="Location" value="Mumbai, Maharashtra" />
        </div>

        <SectionLabel>SPORT DETAILS</SectionLabel>
        <div className="flex flex-col gap-2 mb-6">
          <GhostBtn onClick={() => navigate('add-achievement')}>+ Add Achievement</GhostBtn>
          <GhostBtn onClick={() => navigate('add-tournament')}>+ Add Tournament</GhostBtn>
          <GhostBtn onClick={() => navigate('edit-stats')}>+ Edit Statistics</GhostBtn>
          <GhostBtn onClick={() => navigate('upload-media')}>+ Upload Media</GhostBtn>
          <GhostBtn onClick={() => navigate('edit-social-links')}>+ Add Social Links</GhostBtn>
        </div>

        <PrimaryBtn full onClick={() => navigate('my-profile-athlete')}>Save Changes</PrimaryBtn>
      </div>
    </div>
  )
}

// ─── Add Achievement Screen ───────────────────────────────────────────────────
export function AddAchievementScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        onBack={() => navigate('edit-profile')}
        title="Add Achievement"
        rightActions={<GhostBtn onClick={() => navigate('edit-profile')}>Save</GhostBtn>}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        <div className="flex flex-col gap-4">
          <InputField label="Achievement Title *" placeholder="e.g., State Championship" />
          <TextArea label="Description" placeholder="Describe your achievement..." />
          <SelectField label="Year" options={['2024', '2023', '2022', '2021']} />
          <div>
            <p className="text-xs font-semibold text-gray-500 mb-2">Upload Certificate / Photo</p>
            <UploadArea label="Tap to upload certificate or photo" />
          </div>
          <PrimaryBtn full onClick={() => navigate('edit-profile')}>Save Achievement</PrimaryBtn>
        </div>
      </div>
    </div>
  )
}

// ─── Add Tournament Screen ────────────────────────────────────────────────────
export function AddTournamentScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        onBack={() => navigate('edit-profile')}
        title="Add Tournament"
        rightActions={<GhostBtn onClick={() => navigate('edit-profile')}>Save</GhostBtn>}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        <div className="flex flex-col gap-4">
          <InputField label="Tournament Name *" placeholder="e.g., Ranji Trophy" />
          <SelectField label="Sport *" options={['Cricket', 'Football', 'Athletics']} />
          <InputField label="Location" placeholder="e.g., Mumbai, Maharashtra" />
          <SelectField label="Year *" options={['2024', '2023', '2022']} />
          <InputField label="Position / Result" placeholder="e.g., 1st Place, Finalist" />
          <PrimaryBtn full onClick={() => navigate('tournament-history')}>Save Tournament</PrimaryBtn>
        </div>
      </div>
    </div>
  )
}

// ─── Tournament History Screen ────────────────────────────────────────────────
export function TournamentHistoryScreen({ navigate }: { navigate: NavFn }) {
  const tournaments = [
    { icon: '🏏', name: 'Ranji Trophy — Mumbai XI', meta: 'Nov 2023 · Semi-Finals' },
    { icon: '🏏', name: 'Vijay Hazare Trophy', meta: 'Oct 2022 · Quarter Finals' },
    { icon: '🏃', name: 'District T20 League', meta: 'Jun 2022 · Runner-up' },
  ]

  return (
    <div className="flex flex-col h-full overflow-hidden bg-slate-50">
      <AppBar onBack={() => navigate('my-profile-athlete')} title="Tournament History" />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        {tournaments.length > 0 ? (
          <div className="flex flex-col gap-3">
            {tournaments.map((t, i) => (
              <Card key={i}>
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{t.icon}</span>
                  <div className="flex-1">
                    <p className="text-sm font-semibold text-gray-900">{t.name}</p>
                    <p className="text-xs text-gray-500">{t.meta}</p>
                  </div>
                  <ChevronRightIcon size={16} color="#9CA3AF" />
                </div>
              </Card>
            ))}
          </div>
        ) : (
          <EmptyState
            icon="🏆"
            title="No Tournaments Yet"
            subtitle="Add your tournament history to showcase your experience"
            cta="Add Tournament"
            onCta={() => navigate('add-tournament')}
          />
        )}
      </div>

      {/* FAB */}
      <button
        onClick={() => navigate('add-tournament')}
        className="absolute bottom-6 right-6 w-14 h-14 rounded-full bg-orange-500 flex items-center justify-center"
        style={{ boxShadow: '0 4px 12px rgba(249,115,22,0.35)' }}
      >
        <span className="text-white text-2xl leading-none">+</span>
      </button>
    </div>
  )
}

// ─── Edit Stats Screen ────────────────────────────────────────────────────────
export function EditStatsScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        onBack={() => navigate('edit-profile')}
        title="Edit Statistics"
        rightActions={<GhostBtn onClick={() => navigate('edit-profile')}>Save</GhostBtn>}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        <p className="text-sm text-gray-500 mb-5">
          These are self-reported stats. Be honest!
        </p>

        <SectionLabel>CRICKET STATS</SectionLabel>
        <div className="flex flex-col gap-4">
          <InputField label="Batting Average" value="45.2" type="number" />
          <InputField label="Matches Played" value="32" type="number" />
          <InputField label="Best Score" value="128*" />
          <InputField label="Wickets Taken" value="45" type="number" />

          <GhostBtn onClick={() => {}}>+ Add Custom Stat</GhostBtn>

          <PrimaryBtn full onClick={() => navigate('edit-profile')}>Save Statistics</PrimaryBtn>
        </div>
      </div>
    </div>
  )
}

// ─── Media Gallery Screen ─────────────────────────────────────────────────────
export function MediaGalleryScreen({ navigate }: { navigate: NavFn }) {
  const tiles = [
    { color: '#DBEAFE', video: false },
    { color: '#D1FAE5', video: true },
    { color: '#FEF3C7', video: false },
    { color: '#FCE7F3', video: false },
    { color: '#EDE9FE', video: true },
    { color: '#FEE2E2', video: false },
    { color: '#CFFAFE', video: false },
    { color: '#FEF9C3', video: true },
    { color: '#F0FDF4', video: false },
  ]

  return (
    <div className="flex flex-col h-full overflow-hidden bg-slate-50">
      <AppBar
        onBack={() => navigate('my-profile-athlete')}
        title="Media Gallery"
        rightActions={<GhostBtn>Select</GhostBtn>}
      />
      <div className="flex-1 overflow-y-auto p-4">
        <div className="grid grid-cols-3 gap-2">
          {tiles.map((t, i) => (
            <div
              key={i}
              className="rounded-xl aspect-square relative overflow-hidden"
              style={{ background: t.color }}
            >
              {t.video && (
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-8 h-8 rounded-full bg-black/40 flex items-center justify-center">
                    <span className="text-white text-xs ml-0.5">▶</span>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* FAB */}
      <button
        onClick={() => navigate('upload-media')}
        className="absolute bottom-6 right-6 w-14 h-14 rounded-full bg-orange-500 flex items-center justify-center"
        style={{ boxShadow: '0 4px 12px rgba(249,115,22,0.35)' }}
      >
        <CameraIcon size={22} color="white" />
      </button>
    </div>
  )
}

// ─── Upload Media Screen ──────────────────────────────────────────────────────
export function UploadMediaScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        onBack={() => navigate('media-gallery')}
        title="Upload Media"
        rightActions={<GhostBtn>Post</GhostBtn>}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        <div style={{ height: 160 }}>
          <UploadArea label="Tap to select photo or video" />
        </div>

        <div className="flex items-center gap-3 my-4">
          <div className="flex-1 h-px bg-gray-200" />
          <span className="text-xs text-gray-400 font-semibold">OR</span>
          <div className="flex-1 h-px bg-gray-200" />
        </div>

        <div className="flex flex-col gap-3">
          <SecondaryBtn full onClick={() => {}}>📷  Take Photo</SecondaryBtn>
          <SecondaryBtn full onClick={() => {}}>🎥  Record Video</SecondaryBtn>
          <InputField label="Caption (Optional)" placeholder="Add a caption..." />
          <PrimaryBtn full onClick={() => {}}>Upload</PrimaryBtn>
        </div>
      </div>
    </div>
  )
}

// ─── Edit Social Links Screen ─────────────────────────────────────────────────
export function EditSocialLinksScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        onBack={() => navigate('edit-profile')}
        title="Social Links"
        rightActions={<GhostBtn onClick={() => navigate('edit-profile')}>Save</GhostBtn>}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        <div className="flex flex-col gap-4">
          <InputField label="Instagram" value="@rohan.sharma" />
          <InputField label="Twitter / X" value="@rohancricket" />
          <InputField label="LinkedIn" value="linkedin.com/in/rohan" />
          <InputField label="YouTube" value="youtube.com/@rohancricket" />
          <GhostBtn onClick={() => {}}>+ Add Another Platform</GhostBtn>
          <PrimaryBtn full onClick={() => navigate('edit-profile')}>Save Links</PrimaryBtn>
        </div>
      </div>
    </div>
  )
}

// ─── Discover Screen ──────────────────────────────────────────────────────────
const MOCK_ATHLETES_ALL = [
  { id: 1, type: 'athlete', name: 'Rohan Sharma', sport: 'Cricket', state: 'Mumbai', level: 'State Level', achievements: 5, ageGroup: 'U-19' },
  { id: 2, type: 'athlete', name: 'Priya Menon', sport: 'Athletics', state: 'Pune', level: 'National Level', achievements: 8, ageGroup: 'U-19' },
  { id: 3, type: 'athlete', name: 'Arjun Patel', sport: 'Football', state: 'Bengaluru', level: 'District Level', achievements: 3, ageGroup: 'Open' },
];

const MOCK_COACHES_ALL = [
  { id: 4, type: 'coach', name: 'Elite Cricket Academy', sport: 'Cricket', state: 'Mumbai', athletes: 48, programs: 6 },
  { id: 5, type: 'coach', name: 'Pace Athletics Hub', sport: 'Athletics', state: 'Pune', athletes: 32, programs: 4 },
];

const MOCK_SPONSORS_ALL = [
  { id: 6, type: 'sponsor', name: 'Nike India', industry: 'Sports Apparel', state: 'Pan India', opportunities: 4 },
  { id: 7, type: 'sponsor', name: 'Red Bull', industry: 'Energy Drinks', state: 'Mumbai', opportunities: 2 },
];

export function DiscoverScreen({ navigate }: { navigate: NavFn }) {
  const [activeTab, setActiveTab] = useState('Athletes');
  const [query, setQuery] = useState('');

  const [selectedSport, setSelectedSport] = useState('');
  const [selectedState, setSelectedState] = useState('');
  const [selectedAge, setSelectedAge] = useState('');

  const [showSportFilter, setShowSportFilter] = useState(false);
  const [showStateFilter, setShowStateFilter] = useState(false);
  const [showAgeFilter, setShowAgeFilter] = useState(false);

  const filteredAthletes = MOCK_ATHLETES_ALL.filter(a => {
    if (query && !a.name.toLowerCase().includes(query.toLowerCase())) return false;
    if (selectedSport && a.sport !== selectedSport) return false;
    if (selectedState && !a.state.includes(selectedState)) return false;
    if (selectedAge && a.ageGroup !== selectedAge) return false;
    return true;
  });

  const filteredCoaches = MOCK_COACHES_ALL.filter(c => {
    if (query && !c.name.toLowerCase().includes(query.toLowerCase())) return false;
    if (selectedSport && c.sport !== selectedSport) return false;
    if (selectedState && !c.state.includes(selectedState)) return false;
    return true;
  });

  const filteredSponsors = MOCK_SPONSORS_ALL.filter(s => {
    if (query && !s.name.toLowerCase().includes(query.toLowerCase())) return false;
    if (selectedState && !s.state.includes(selectedState)) return false;
    return true;
  });

  return (
    <div className="flex flex-col h-full overflow-hidden bg-slate-50 relative">
      <AppBar
        logoLeft
        rightActions={
          <>
            <IconBtn icon={<BellIcon size={20} />} onClick={() => navigate('notifications')} />
            <IconBtn icon={<SettingsIcon size={20} />} onClick={() => navigate('settings')} />
          </>
        }
      />

      <div className="px-4 pt-3 pb-2 bg-white border-b border-gray-100">
        <SearchBar placeholder="Search athletes, coaches..." value={query} onChange={setQuery} />
        <div className="mt-2">
          <TabPills tabs={['Athletes', 'Coaches', 'Sponsors']} active={activeTab} onSelect={setActiveTab} />
        </div>
        <div className="flex gap-2 mt-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
          <FilterChip label={selectedSport || "Sport ▼"} active={!!selectedSport} onClick={() => setShowSportFilter(true)} onRemove={() => setSelectedSport('')} />
          <FilterChip label={selectedState || "State ▼"} active={!!selectedState} onClick={() => setShowStateFilter(true)} onRemove={() => setSelectedState('')} />
          {activeTab === 'Athletes' && <FilterChip label={selectedAge || "Age ▼"} active={!!selectedAge} onClick={() => setShowAgeFilter(true)} onRemove={() => setSelectedAge('')} />}
        </div>
      </div>

      <div className={`flex-1 overflow-y-auto px-4 py-3 ${activeTab !== 'Athletes' ? 'grid grid-cols-2 gap-3 items-start' : 'flex flex-col gap-3'}`}>
        {activeTab === 'Athletes' && (
          <>
            {filteredAthletes.map(a => (
              <AthleteCard key={a.id} name={a.name} sport={a.sport} city={a.state} level={a.level} achievements={a.achievements} onConnect={() => {}} onView={() => navigate('view-profile')} />
            ))}
            {filteredAthletes.length === 0 && <div className="py-10 text-center text-gray-500 text-sm">No athletes found.</div>}
          </>
        )}
        {activeTab === 'Coaches' && (
          <>
            {filteredCoaches.map(c => (
              <AcademyCard key={c.id} name={c.name} sport={c.sport} city={c.state} athletes={c.athletes} programs={c.programs} onView={() => navigate('view-profile')} />
            ))}
            {filteredCoaches.length === 0 && <div className="col-span-2 py-10 text-center text-gray-500 text-sm">No academies found.</div>}
          </>
        )}
        {activeTab === 'Sponsors' && (
          <>
            {filteredSponsors.map(s => (
              <SponsorCard key={s.id} name={s.name} industry={s.industry} location={s.state} opportunities={s.opportunities} onView={() => navigate('view-profile')} />
            ))}
            {filteredSponsors.length === 0 && <div className="col-span-2 py-10 text-center text-gray-500 text-sm">No sponsors found.</div>}
          </>
        )}
      </div>

      <BottomNav role="athlete" active="discover" onTab={t => navigate(athleteTabMap[t] ?? 'athlete-home')} onFab={() => navigate('create-post')} />
      
      {showSportFilter && <FilterBottomSheet title="Select Sport" options={['Cricket', 'Football', 'Athletics']} selected={selectedSport} onClose={() => setShowSportFilter(false)} onSelect={setSelectedSport} />}
      {showStateFilter && <FilterBottomSheet title="Select State" options={['Mumbai', 'Pune', 'Bengaluru', 'Pan India']} selected={selectedState} onClose={() => setShowStateFilter(false)} onSelect={setSelectedState} />}
      {showAgeFilter && <FilterBottomSheet title="Select Age Group" options={['U-16', 'U-19', 'Open']} selected={selectedAge} onClose={() => setShowAgeFilter(false)} onSelect={setSelectedAge} />}
    </div>
  )
}

// ─── My Connections Screen ────────────────────────────────────────────────────
export function MyConnectionsScreen({ navigate }: { navigate: NavFn }) {
  const connections = [
    { name: 'Priya Menon', sport: 'Athletics' },
    { name: 'Arjun Patel', sport: 'Football' },
    { name: 'Sneha Kulkarni', sport: 'Badminton' },
    { name: 'Vikram Singh', sport: 'Cricket' },
  ]

  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        onBack={() => navigate('athlete-home')}
        title="My Connections"
        rightActions={
          <IconBtn
            icon={<svg width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>}
          />
        }
      />
      <div className="flex-1 overflow-y-auto">
        {connections.map((c, i) => (
          <div key={i} className="flex items-center gap-3 px-4 py-3 border-b border-gray-100">
            <Avatar size={48} name={c.name} />
            <div className="flex-1">
              <p className="text-sm font-semibold text-gray-900">{c.name}</p>
              <p className="text-xs text-gray-500">{c.sport}</p>
            </div>
            <div className="flex gap-2">
              <button
                className="w-9 h-9 rounded-full bg-slate-50 border border-gray-200 flex items-center justify-center"
                onClick={() => navigate('chat-screen')}
              >
                <MessageIcon size={16} color="#6B7280" />
              </button>
              <button className="w-9 h-9 rounded-full bg-slate-50 border border-gray-200 flex items-center justify-center">
                <svg width="16" height="16" fill="none" stroke="#6B7280" strokeWidth="2" viewBox="0 0 24 24"><circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/></svg>
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Connection Requests Screen ───────────────────────────────────────────────
export function ConnectionRequestsScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden bg-slate-50">
      <AppBar onBack={() => navigate('athlete-home')} title="Connection Requests" />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8">
        <SectionLabel>RECEIVED (3)</SectionLabel>
        <div className="flex flex-col gap-3 mb-5">
          {[
            { name: 'Anjali Rao', sport: 'Swimming', level: 'State Level' },
            { name: 'Dev Khanna', sport: 'Wrestling', level: 'National Level' },
          ].map((r, i) => (
            <Card key={i}>
              <div className="flex items-center gap-3 mb-3">
                <Avatar size={48} name={r.name} />
                <div>
                  <p className="text-sm font-semibold text-gray-900">{r.name}</p>
                  <p className="text-xs text-gray-500">{r.sport} · {r.level}</p>
                </div>
              </div>
              <div className="flex gap-2">
                <div className="flex-1">
                  <DangerBtn full onClick={() => {}}>Decline</DangerBtn>
                </div>
                <div className="flex-1">
                  <PrimaryBtn full onClick={() => {}}>Accept</PrimaryBtn>
                </div>
              </div>
            </Card>
          ))}
        </div>

        <SectionLabel>SENT (2)</SectionLabel>
        <div className="flex flex-col gap-3">
          {[
            { name: 'Karan Mehta', sport: 'Hockey' },
            { name: 'Tanya Verma', sport: 'Gymnastics' },
          ].map((r, i) => (
            <div key={i} className="flex items-center gap-3 bg-white rounded-2xl border border-gray-200 p-3" style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
              <Avatar size={48} name={r.name} />
              <div className="flex-1">
                <p className="text-sm font-semibold text-gray-900">{r.name}</p>
                <p className="text-xs text-gray-500">{r.sport}</p>
              </div>
              <span className="text-xs font-semibold text-amber-600 bg-amber-50 border border-amber-200 px-2 py-1 rounded-full">Pending</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

// ─── Chat List Screen ─────────────────────────────────────────────────────────
export function ChatListScreen({ navigate }: { navigate: NavFn }) {
  const chats = [
    { name: 'Priya Menon', preview: 'Great session today! 💪', time: '2m', unread: true },
    { name: 'Arjun Patel', preview: 'Are you coming to the match?', time: '1h', unread: true },
    { name: 'Coach Sharma', preview: 'Training at 6 AM tomorrow', time: '3h', unread: false },
    { name: 'Vikram Singh', preview: 'Congratulations on the win!', time: '1d', unread: false },
  ]

  return (
    <div className="flex flex-col h-full overflow-hidden bg-white">
      <AppBar
        logoLeft
        rightActions={
          <>
            <IconBtn icon={<BellIcon size={20} />} onClick={() => navigate('notifications')} />
            <IconBtn icon={<SettingsIcon size={20} />} onClick={() => navigate('settings')} />
          </>
        }
      />
      <div className="px-4 py-3 border-b border-gray-100">
        <SearchBar placeholder="Search conversations..." />
      </div>
      <div className="flex-1 overflow-y-auto">
        {chats.map((c, i) => (
          <button
            key={i}
            className="flex items-center gap-3 px-4 py-3 border-b border-gray-100 w-full active:bg-slate-50"
            onClick={() => navigate('chat-screen')}
          >
            <Avatar size={48} name={c.name} />
            <div className="flex-1 min-w-0 text-left">
              <div className="flex items-center gap-2">
                <span className={`text-sm font-semibold ${c.unread ? 'text-gray-900' : 'text-gray-700'}`}>
                  {c.name}
                </span>
                {c.unread && <span className="w-2 h-2 rounded-full bg-blue-600 flex-shrink-0" />}
              </div>
              <p className="text-xs text-gray-500 truncate">{c.preview}</p>
            </div>
            <span className="text-xs text-gray-400 flex-shrink-0">{c.time}</span>
          </button>
        ))}
      </div>
      <BottomNav
        role="athlete"
        active="messages"
        onTab={t => navigate(athleteTabMap[t] ?? 'athlete-home')}
        onFab={() => navigate('create-post')}
      />
    </div>
  )
}

// ─── Chat Screen ──────────────────────────────────────────────────────────────
export function ChatScreen({ navigate }: { navigate: NavFn }) {
  const [text, setText] = useState('')

  const messages = [
    { sent: false, text: 'Hey! Great match yesterday 🏏' },
    { sent: true, text: 'Thanks man! You played really well too.' },
    { sent: false, text: 'Are you joining the inter-district camp next month?' },
    { sent: true, text: 'Yes! Registered yesterday. Looking forward to it.' },
  ]

  return (
    <div className="flex flex-col h-full overflow-hidden bg-slate-50">
      <AppBar
        onBack={() => navigate('chat-list')}
        title=""
        rightActions={
          <div className="flex gap-2">
            <button className="text-gray-500 text-xl">📎</button>
            <button className="text-gray-500 text-xl">📞</button>
          </div>
        }
      />
      {/* Custom title area with avatar */}
      <div className="flex items-center gap-2 px-4 pb-0 pointer-events-none absolute top-2.5 left-12">
        <Avatar size={36} name="Rohan Sharma" />
        <span className="text-base font-semibold text-gray-900">Rohan Sharma</span>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-3 mt-2">
        <div className="flex justify-center">
          <span className="text-xs text-gray-500 bg-white rounded-full px-3 py-1 border border-gray-200">Yesterday</span>
        </div>
        {messages.map((m, i) => (
          <div key={i} className={`flex ${m.sent ? 'justify-end' : 'justify-start'}`}>
            <div
              className={`max-w-[75%] px-4 py-2 text-sm leading-relaxed ${
                m.sent
                  ? 'bg-blue-600 text-white rounded-2xl rounded-tr-none'
                  : 'bg-white text-gray-900 rounded-2xl rounded-tl-none border border-gray-200'
              }`}
            >
              {m.text}
            </div>
          </div>
        ))}
      </div>

      <div className="flex-shrink-0 border-t border-gray-200 bg-white flex items-center gap-2 px-4 py-2">
        <button className="text-gray-400 text-xl">📎</button>
        <input
          className="flex-1 bg-slate-50 rounded-full px-4 py-2 text-sm outline-none border border-gray-200"
          placeholder="Type a message..."
          value={text}
          onChange={e => setText(e.target.value)}
        />
        <button className="text-gray-400 text-xl">🎙️</button>
      </div>
    </div>
  )
}

// ─── Academies Directory Screen ───────────────────────────────────────────────
const MOCK_ATHLETE_ACADEMIES = [
  { id: 1, name: 'Elite Cricket Academy', sport: 'Cricket', city: 'Mumbai', athletes: 48, programs: 6 },
  { id: 2, name: 'Pace Athletics Hub', sport: 'Athletics', city: 'Pune', athletes: 32, programs: 4 },
  { id: 3, name: 'Goal FC Academy', sport: 'Football', city: 'Bengaluru', athletes: 60, programs: 5 },
]

export function AcademiesDirectoryScreen({ navigate }: { navigate: NavFn }) {
  const [activeTab, setActiveTab] = useState('All');
  const [query, setQuery] = useState('');
  
  const [selectedState, setSelectedState] = useState('');
  const [showStateFilter, setShowStateFilter] = useState(false);

  const filtered = MOCK_ATHLETE_ACADEMIES.filter(a => {
    if (activeTab !== 'All' && a.sport !== activeTab) return false;
    if (query && !a.name.toLowerCase().includes(query.toLowerCase())) return false;
    if (selectedState && !a.city.includes(selectedState)) return false;
    return true;
  });

  return (
    <div className="flex flex-col h-full overflow-hidden bg-slate-50 relative">
      <AppBar
        logoLeft
        rightActions={
          <>
            <IconBtn icon={<BellIcon size={20} />} onClick={() => navigate('notifications')} />
            <IconBtn icon={<SettingsIcon size={20} />} onClick={() => navigate('settings')} />
          </>
        }
      />

      <div className="px-4 pt-3 pb-2 bg-white border-b border-gray-100">
        <SearchBar placeholder="Search academies, coaches..." value={query} onChange={setQuery} />
        <div className="mt-2">
          <TabPills tabs={['All', 'Cricket', 'Football', 'Athletics', 'Badminton']} active={activeTab} onSelect={setActiveTab} />
        </div>
        <div className="flex gap-2 mt-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
          <FilterChip label={selectedState || "State ▼"} active={!!selectedState} onClick={() => setShowStateFilter(true)} onRemove={() => setSelectedState('')} />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-3 grid grid-cols-2 gap-3 items-start">
        {filtered.map(a => (
          <AcademyCard key={a.id} name={a.name} sport={a.sport} city={a.city} athletes={a.athletes} programs={a.programs} onView={() => {}} />
        ))}
        {filtered.length === 0 && (
          <div className="col-span-2 py-10 text-center text-gray-500 text-sm">No academies found.</div>
        )}
      </div>

      <BottomNav role="athlete" active="discover" onTab={t => navigate(athleteTabMap[t] ?? 'athlete-home')} onFab={() => navigate('create-post')} />
      
      {showStateFilter && <FilterBottomSheet title="Select State" options={['Mumbai', 'Pune', 'Bengaluru']} selected={selectedState} onClose={() => setShowStateFilter(false)} onSelect={setSelectedState} />}
    </div>
  )
}
