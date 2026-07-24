import React, { useState } from 'react';
import {
  AppBar, BottomNav, IconBtn, PrimaryBtn, SecondaryBtn, GhostBtn,
  InputField, TextArea, SearchBar, SelectField, Avatar, SportBadge,
  VerifiedBadge, TabPills, FilterChip, SectionLabel, Divider,
  StoriesRow, PostCard, AthleteCard, SponsorCard, Card,
  UploadArea, StatRow, ProfileHeader,
  EyeIcon, EditIcon, SettingsIcon, BellIcon, CameraIcon,
  ChevronRightIcon, SearchIcon,
  type NavFn,
} from '../components/ui';

// ─── CoachHomeScreen ────────────────────────────────────────────────────────

export function CoachHomeScreen({ navigate }: { navigate: NavFn }) {
  const onTab = (t: string) => {
    const map: Record<string, string> = {
      home: 'coach-home',
      discover: 'athlete-directory-coach',
      notifications: 'notifications',
      profile: 'coach-profile',
    };
    navigate(map[t] || t);
  };

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        logoLeft
        rightActions={[
          <IconBtn key="bell" icon={<BellIcon />} onClick={() => navigate('notifications')} />,
          <IconBtn key="settings" icon={<SettingsIcon />} onClick={() => navigate('settings')} />,
        ]}
      />
      <StoriesRow />
      <div className="flex-1 overflow-y-auto px-4 py-3 flex flex-col gap-4">
        <PostCard
          sport="Cricket"
          authorName="Rahul Cricket Academy"
          authorRole="Coach"
          content="Excited to announce our new U-19 residential camp starting December 2024. Applications open now!"
          timeAgo="2h ago"
          likes={34}
          comments={8}
        />
        <PostCard
          sport="Athletics"
          authorName="Track Masters Academy"
          authorRole="Coach"
          content="Congratulations to our athlete Priya Sharma for qualifying for the National Athletics Championship!"
          timeAgo="5h ago"
          likes={62}
          comments={14}
        />
        <PostCard
          sport="Football"
          authorName="Goal FC Academy"
          authorRole="Coach"
          content="Open trials for our Under-17 football batch. Saturday, 7 AM at Kanteerava Stadium."
          timeAgo="1d ago"
          likes={89}
          comments={21}
        />
      </div>
      <BottomNav role="coach" active="home" onTab={onTab} />
    </div>
  );
}

// ─── CoachProfileScreen ─────────────────────────────────────────────────────

export function CoachProfileScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('coach-home')}
        title="My Academy"
        rightActions={[
          <IconBtn key="edit" icon={<EditIcon />} onClick={() => navigate('edit-coach-profile')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto">
        {/* Banner */}
        <div className="h-44 bg-gradient-to-br from-blue-700 to-blue-900 relative flex items-end justify-center pb-0">
          <div className="absolute bottom-0 translate-y-1/2">
            <Avatar size={80} name="Rahul Cricket Academy" />
          </div>
        </div>

        {/* Profile info */}
        <div className="mt-12 px-4 flex flex-col items-center gap-1">
          <p className="font-bold text-xl text-gray-900">Rahul Cricket Academy</p>
          <VerifiedBadge label="✓ Verified" />
          <div className="flex items-center gap-2 mt-1">
            <SportBadge sport="Cricket" />
            <span className="text-sm text-gray-500">Bangalore, KA</span>
          </div>
        </div>

        {/* Stats */}
        <div className="mt-4 px-4">
          <StatRow
            stats={[
              { label: 'Athletes', value: 45 },
              { label: 'Programs', value: 6 },
              { label: 'Years', value: 12 },
            ]}
          />
        </div>

        <div className="px-4 mt-4 flex flex-col gap-4 pb-6">
          {/* About */}
          <div>
            <SectionLabel label="ABOUT" />
            <p className="text-sm text-gray-600 mt-1 leading-relaxed">
              Rahul Cricket Academy has been nurturing cricketing talent since 2012. We offer structured coaching for all age groups, from grassroots to elite level, with a focus on technical excellence and mental conditioning.
            </p>
          </div>

          {/* Credentials */}
          <div>
            <SectionLabel label="CREDENTIALS" />
            <div className="flex flex-col gap-2 mt-2">
              <Card style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
                <div className="flex items-center gap-3 p-3">
                  <span className="text-xl">📜</span>
                  <div>
                    <p className="text-sm font-semibold text-gray-800">BCCI Level 2 Coaching License</p>
                    <p className="text-xs text-gray-500">Board of Control for Cricket in India • 2019</p>
                  </div>
                </div>
              </Card>
              <Card style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
                <div className="flex items-center gap-3 p-3">
                  <span className="text-xl">🏆</span>
                  <div>
                    <p className="text-sm font-semibold text-gray-800">National Academy of Year 2022</p>
                    <p className="text-xs text-gray-500">Sports Authority of India • 2022</p>
                  </div>
                </div>
              </Card>
            </div>
          </div>

          {/* Facilities & Programs */}
          <div>
            <SectionLabel label="FACILITIES & PROGRAMS" />
            <Card className="mt-2" style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
              <div className="p-3 flex flex-col gap-2">
                {[
                  { icon: '🏟️', label: '3 Turf Wickets' },
                  { icon: '🏋️', label: 'Gym & Fitness' },
                  { icon: '🏠', label: 'Residential Camp' },
                  { icon: '📅', label: 'Weekend Batch' },
                ].map((item) => (
                  <div key={item.label} className="flex items-center gap-2">
                    <span>{item.icon}</span>
                    <span className="text-sm text-gray-700">{item.label}</span>
                  </div>
                ))}
              </div>
            </Card>
          </div>

          {/* Associated Athletes */}
          <div>
            <SectionLabel label="ASSOCIATED ATHLETES" />
            <div className="flex gap-3 mt-2 overflow-x-auto pb-1">
              {['Rohit S', 'Priya K', 'Amit V', 'Neha R', 'Suresh M'].map((name) => (
                <div key={name} className="flex flex-col items-center gap-1 shrink-0">
                  <Avatar size={64} name={name} />
                  <p className="text-xs text-gray-600 text-center w-14 truncate">{name}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Contact */}
          <div>
            <SectionLabel label="CONTACT" />
            <div className="flex flex-col gap-1 mt-1">
              <p className="text-sm text-gray-700">📞 +91 98765 43210</p>
              <p className="text-sm text-gray-700">📧 contact@rahulcricket.com</p>
            </div>
          </div>

          <SecondaryBtn full label="Share Profile" onClick={() => {}} />
        </div>
      </div>
    </div>
  );
}

// ─── EditCoachProfileScreen ──────────────────────────────────────────────────

export function EditCoachProfileScreen({ navigate }: { navigate: NavFn }) {
  const [academyName, setAcademyName] = useState('Rahul Cricket Academy');
  const [bio, setBio] = useState('');
  const [sport, setSport] = useState('Cricket');
  const [location, setLocation] = useState('Bangalore, Karnataka');
  const [phone, setPhone] = useState('+91 98765 43210');
  const [email, setEmail] = useState('contact@rahulcricket.com');

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('coach-profile')}
        title="Edit Academy"
        rightActions={[
          <GhostBtn key="save" label="Save" onClick={() => navigate('coach-profile')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        {/* Avatar */}
        <div className="flex flex-col items-center gap-1">
          <div className="relative">
            <Avatar size={80} name="Rahul Cricket Academy" />
            <div className="absolute bottom-0 right-0 bg-blue-600 rounded-full p-1">
              <CameraIcon className="w-3 h-3 text-white" />
            </div>
          </div>
          <p className="text-xs text-blue-600">Change Logo</p>
        </div>

        <SectionLabel label="ACADEMY INFO" />
        <InputField
          label="Academy Name"
          value={academyName}
          onChange={(v) => setAcademyName(v)}
        />
        <TextArea
          label="Bio / Overview"
          value={bio}
          onChange={(v) => setBio(v)}
          placeholder="Describe your academy..."
        />
        <SelectField
          label="Sport Specialisation"
          value={sport}
          onChange={(v) => setSport(v)}
          options={['Cricket', 'Football', 'Athletics', 'Badminton']}
        />
        <InputField
          label="Location"
          value={location}
          onChange={(v) => setLocation(v)}
        />

        <div className="flex items-center justify-between">
          <SectionLabel label="CREDENTIALS" />
          <GhostBtn label="+ Add Credential" onClick={() => navigate('add-credential')} />
        </div>

        <div className="flex items-center justify-between">
          <SectionLabel label="FACILITIES" />
          <GhostBtn label="+ Add Facility" onClick={() => navigate('edit-facilities')} />
        </div>

        <div className="flex items-center justify-between">
          <SectionLabel label="ASSOCIATED ATHLETES" />
          <GhostBtn label="+ Showcase Athletes" onClick={() => navigate('showcase-athletes')} />
        </div>

        <InputField
          label="Contact Phone"
          value={phone}
          onChange={(v) => setPhone(v)}
        />
        <InputField
          label="Contact Email"
          value={email}
          onChange={(v) => setEmail(v)}
        />

        <PrimaryBtn full label="Save Changes" onClick={() => navigate('coach-profile')} />
      </div>
    </div>
  );
}

// ─── AddCredentialScreen ─────────────────────────────────────────────────────

export function AddCredentialScreen({ navigate }: { navigate: NavFn }) {
  const [title, setTitle] = useState('');
  const [issuer, setIssuer] = useState('');
  const [year, setYear] = useState('2024');

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('edit-coach-profile')}
        title="Add Credential"
        rightActions={[
          <GhostBtn key="save" label="Save" onClick={() => navigate('edit-coach-profile')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        <InputField
          label="Credential Title *"
          placeholder="e.g., BCCI Level 2 License"
          value={title}
          onChange={(v) => setTitle(v)}
        />
        <InputField
          label="Issuing Authority"
          placeholder="e.g., BCCI"
          value={issuer}
          onChange={(v) => setIssuer(v)}
        />
        <SelectField
          label="Year Obtained"
          value={year}
          onChange={(v) => setYear(v)}
          options={['2024', '2023', '2022', '2021', '2020', '2019']}
        />
        <div>
          <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Upload Certificate</p>
          <UploadArea />
        </div>
        <PrimaryBtn full label="Save Credential" onClick={() => navigate('edit-coach-profile')} />
      </div>
    </div>
  );
}

// ─── EditFacilitiesScreen ────────────────────────────────────────────────────

export function EditFacilitiesScreen({ navigate }: { navigate: NavFn }) {
  const [facilityName, setFacilityName] = useState('');
  const [description, setDescription] = useState('');
  const [type, setType] = useState('Facility');

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('edit-coach-profile')}
        title="Edit Facilities"
        rightActions={[
          <GhostBtn key="save" label="Save" onClick={() => navigate('edit-coach-profile')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        <InputField
          label="Facility / Program Name *"
          placeholder="e.g., Turf Wicket"
          value={facilityName}
          onChange={(v) => setFacilityName(v)}
        />
        <TextArea
          label="Description"
          value={description}
          onChange={(v) => setDescription(v)}
          placeholder="Describe this facility or program..."
        />
        <SelectField
          label="Type"
          value={type}
          onChange={(v) => setType(v)}
          options={['Facility', 'Program']}
        />
        <GhostBtn label="+ Add Another" onClick={() => {}} />
        <PrimaryBtn full label="Save Facilities" onClick={() => navigate('edit-coach-profile')} />
      </div>
    </div>
  );
}

// ─── ShowcaseAthletesScreen ──────────────────────────────────────────────────

const SELECTED_ATHLETES = [
  { name: 'Rohit Sharma', sport: 'Cricket' },
  { name: 'Priya Kumar', sport: 'Athletics' },
];

const AVAILABLE_ATHLETES = [
  { name: 'Amit Verma', sport: 'Cricket' },
  { name: 'Neha Reddy', sport: 'Football' },
];

export function ShowcaseAthletesScreen({ navigate }: { navigate: NavFn }) {
  const [selected, setSelected] = useState<Set<string>>(
    new Set(SELECTED_ATHLETES.map((a) => a.name))
  );
  const [query, setQuery] = useState('');

  const toggle = (name: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(name) ? next.delete(name) : next.add(name);
      return next;
    });
  };

  const allAthletes = [...SELECTED_ATHLETES, ...AVAILABLE_ATHLETES];

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('edit-coach-profile')}
        title="Showcase Athletes"
        rightActions={[
          <GhostBtn key="save" label="Save" onClick={() => navigate('edit-coach-profile')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        <p className="text-sm text-gray-600">
          Search and select athletes to showcase on your profile
        </p>
        <SearchBar
          placeholder="Search your athletes..."
          value={query}
          onChange={(v) => setQuery(v)}
        />

        <SectionLabel label={`SELECTED (${selected.size})`} />
        {allAthletes
          .filter((a) => selected.has(a.name))
          .map((athlete) => (
            <div
              key={athlete.name}
              className="flex items-center gap-3 p-2 rounded-xl bg-green-50 cursor-pointer"
              onClick={() => toggle(athlete.name)}
            >
              <Avatar size={48} name={athlete.name} />
              <div className="flex-1">
                <p className="text-sm font-semibold text-gray-800">{athlete.name}</p>
                <p className="text-xs text-gray-500">{athlete.sport}</p>
              </div>
              <span className="text-green-600 font-bold text-lg">✓</span>
            </div>
          ))}

        <SectionLabel label="AVAILABLE" />
        {allAthletes
          .filter((a) => !selected.has(a.name))
          .map((athlete) => (
            <div
              key={athlete.name}
              className="flex items-center gap-3 p-2 rounded-xl bg-white border border-gray-100 cursor-pointer"
              onClick={() => toggle(athlete.name)}
            >
              <Avatar size={48} name={athlete.name} />
              <div className="flex-1">
                <p className="text-sm font-semibold text-gray-800">{athlete.name}</p>
                <p className="text-xs text-gray-500">{athlete.sport}</p>
              </div>
            </div>
          ))}

        <PrimaryBtn full label="Save Showcase" onClick={() => navigate('edit-coach-profile')} />
      </div>
    </div>
  );
}

// ─── AthleteDirectoryCoachScreen ─────────────────────────────────────────────

const MOCK_COACH_ATHLETES = [
  { id: 1, name: 'Vikas Nair', sport: 'Cricket', state: 'Mumbai, MH', age: 18, ageGroup: 'U-19' },
  { id: 2, name: 'Sana Sheikh', sport: 'Athletics', state: 'Delhi, DL', age: 17, ageGroup: 'U-19' },
  { id: 3, name: 'Arjun Patel', sport: 'Football', state: 'Pune, MH', age: 19, ageGroup: 'Open' },
  { id: 4, name: 'Ravi Kumar', sport: 'Cricket', state: 'Delhi, DL', age: 16, ageGroup: 'U-16' },
]

export function AthleteDirectoryCoachScreen({ navigate }: { navigate: NavFn }) {
  const [activeTab, setActiveTab] = useState('All');
  const [query, setQuery] = useState('');
  
  const [selectedAge, setSelectedAge] = useState('');
  const [selectedState, setSelectedState] = useState('');
  const [selectedSport, setSelectedSport] = useState('');
  
  const [showAgeFilter, setShowAgeFilter] = useState(false);
  const [showStateFilter, setShowStateFilter] = useState(false);
  const [showSportFilter, setShowSportFilter] = useState(false);

  const onTab = (t: string) => {
    const map: Record<string, string> = {
      home: 'coach-home',
      discover: 'athlete-directory-coach',
      notifications: 'notifications',
      profile: 'coach-profile',
    };
    navigate(map[t] || t);
  };

  const filtered = MOCK_COACH_ATHLETES.filter(a => {
    if (activeTab !== 'All' && a.sport !== activeTab) return false;
    if (query && !a.name.toLowerCase().includes(query.toLowerCase())) return false;
    if (selectedAge && a.ageGroup !== selectedAge) return false;
    if (selectedState && !a.state.includes(selectedState)) return false;
    if (selectedSport && a.sport !== selectedSport) return false;
    return true;
  });

  return (
    <div className="flex flex-col h-full overflow-hidden relative">
      <AppBar
        logoLeft
        title="Athletes"
        rightActions={[
          <IconBtn key="bell" icon={<BellIcon />} onClick={() => navigate('notifications')} />,
          <IconBtn key="settings" icon={<SettingsIcon />} onClick={() => navigate('settings')} />,
        ]}
      />
      <div className="px-4 pt-2">
        <SearchBar placeholder="Search athletes..." value={query} onChange={(v) => setQuery(v)} />
      </div>
      <div className="px-4 mt-2">
        <TabPills tabs={['All', 'Cricket', 'Football', 'Athletics']} active={activeTab} onChange={setActiveTab} />
      </div>
      <div className="px-4 mt-2 flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
        <FilterChip label={selectedAge || "Age ▼"} active={!!selectedAge} onClick={() => setShowAgeFilter(true)} onRemove={() => setSelectedAge('')} />
        <FilterChip label={selectedState || "State ▼"} active={!!selectedState} onClick={() => setShowStateFilter(true)} onRemove={() => setSelectedState('')} />
        <FilterChip label={selectedSport || "Sport ▼"} active={!!selectedSport} onClick={() => setShowSportFilter(true)} onRemove={() => setSelectedSport('')} />
      </div>
      <div className="flex-1 overflow-y-auto px-4 grid grid-cols-2 gap-3 pt-3 pb-4 items-start">
        {filtered.map(a => (
          <AthleteCard key={a.id} name={a.name} sport={a.sport} location={a.state} age={a.age} onView={() => navigate('view-profile')} />
        ))}
        {filtered.length === 0 && (
          <div className="col-span-2 py-10 text-center text-gray-500 text-sm">No athletes match your filters.</div>
        )}
      </div>
      <BottomNav role="coach" active="discover" onTab={onTab} />

      {showAgeFilter && <FilterBottomSheet title="Select Age Group" options={['U-16', 'U-19', 'Open']} selected={selectedAge} onClose={() => setShowAgeFilter(false)} onSelect={setSelectedAge} />}
      {showStateFilter && <FilterBottomSheet title="Select State" options={['Mumbai', 'Delhi', 'Pune']} selected={selectedState} onClose={() => setShowStateFilter(false)} onSelect={setSelectedState} />}
      {showSportFilter && <FilterBottomSheet title="Select Sport" options={['Cricket', 'Football', 'Athletics']} selected={selectedSport} onClose={() => setShowSportFilter(false)} onSelect={setSelectedSport} />}
    </div>
  );
}

// ─── SponsorDirectoryCoachScreen ──────────────────────────────────────────────

const MOCK_COACH_SPONSORS = [
  { id: 1, name: 'Nike India', industry: 'Sportswear', location: 'Pan-India', opportunities: 5 },
  { id: 2, name: 'Gatorade India', industry: 'Nutrition', location: 'Pan-India', opportunities: 3 },
  { id: 3, name: 'Decathlon India', industry: 'Sportswear', location: 'Delhi, DL', opportunities: 8 },
]

export function SponsorDirectoryCoachScreen({ navigate }: { navigate: NavFn }) {
  const [activeTab, setActiveTab] = useState('All');
  const [query, setQuery] = useState('');
  
  const [selectedLocation, setSelectedLocation] = useState('');
  const [showLocationFilter, setShowLocationFilter] = useState(false);

  const onTab = (t: string) => {
    const map: Record<string, string> = {
      home: 'coach-home',
      discover: 'athlete-directory-coach',
      notifications: 'notifications',
      profile: 'coach-profile',
    };
    navigate(map[t] || t);
  };

  const filtered = MOCK_COACH_SPONSORS.filter(s => {
    if (activeTab !== 'All' && s.industry !== activeTab) return false;
    if (query && !s.name.toLowerCase().includes(query.toLowerCase())) return false;
    if (selectedLocation && !s.location.includes(selectedLocation)) return false;
    return true;
  });

  return (
    <div className="flex flex-col h-full overflow-hidden relative">
      <AppBar
        logoLeft
        title="Sponsors"
        rightActions={[
          <IconBtn key="bell" icon={<BellIcon />} onClick={() => navigate('notifications')} />,
          <IconBtn key="settings" icon={<SettingsIcon />} onClick={() => navigate('settings')} />,
        ]}
      />
      <div className="px-4 pt-2">
        <SearchBar placeholder="Search sponsors..." value={query} onChange={(v) => setQuery(v)} />
      </div>
      <div className="px-4 mt-2">
        <TabPills tabs={['All', 'Sportswear', 'Nutrition', 'Finance']} active={activeTab} onChange={setActiveTab} />
      </div>
      <div className="px-4 mt-2 flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
        <FilterChip label={selectedLocation || "Location ▼"} active={!!selectedLocation} onClick={() => setShowLocationFilter(true)} onRemove={() => setSelectedLocation('')} />
      </div>
      <div className="flex-1 overflow-y-auto px-4 grid grid-cols-2 gap-3 pt-3 pb-4 items-start">
        {filtered.map(s => (
          <SponsorCard key={s.id} name={s.name} industry={s.industry} location={s.location} opportunities={s.opportunities} onView={() => navigate('view-profile')} />
        ))}
        {filtered.length === 0 && (
          <div className="col-span-2 py-10 text-center text-gray-500 text-sm">No sponsors match your filters.</div>
        )}
      </div>
      <BottomNav role="coach" active="discover" onTab={onTab} />
      
      {showLocationFilter && <FilterBottomSheet title="Select Location" options={['Pan-India', 'Delhi', 'Mumbai', 'Pune']} selected={selectedLocation} onClose={() => setShowLocationFilter(false)} onSelect={setSelectedLocation} />}
    </div>
  );
}
