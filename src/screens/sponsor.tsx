import React, { useState } from 'react';
import {
  AppBar, BottomNav, IconBtn, PrimaryBtn, SecondaryBtn, GhostBtn,
  InputField, TextArea, SearchBar, SelectField, Avatar, SportBadge,
  VerifiedBadge, TabPills, FilterChip, SectionLabel, StatusDot,
  StoriesRow, PostCard, AthleteCard, AcademyCard, SponsorCard,
  OpportunityCard, Card, StatRow,
  EyeIcon, EditIcon, SettingsIcon, BellIcon, CameraIcon,
  type NavFn,
} from '../components/ui';

// ─── SponsorHomeScreen ────────────────────────────────────────────────────────

export function SponsorHomeScreen({ navigate }: { navigate: NavFn }) {
  const onTab = (t: string) => {
    const map: Record<string, string> = {
      home: 'sponsor-home',
      discover: 'athlete-directory-sponsor',
      postopp: 'my-opportunities',
      profile: 'sponsor-profile',
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
          authorName="Nike India"
          authorRole="Sponsor"
          content="We are proud to announce our new athlete sponsorship program for U-19 cricketers. Apply now!"
          timeAgo="1h ago"
          likes={74}
          comments={18}
        />
        <PostCard
          sport="Athletics"
          authorName="Gatorade India"
          authorRole="Sponsor"
          content="Fuelling India's future champions. Check out our nutrition grant for elite track and field athletes."
          timeAgo="4h ago"
          likes={51}
          comments={9}
        />
        <PostCard
          sport="Football"
          authorName="Decathlon India"
          authorRole="Sponsor"
          content="Equipment support available for grassroots football academies. Limited spots — apply today!"
          timeAgo="2d ago"
          likes={38}
          comments={5}
        />
      </div>
      <BottomNav role="sponsor" active="home" onTab={onTab} />
    </div>
  );
}

// ─── SponsorProfileScreen ─────────────────────────────────────────────────────

export function SponsorProfileScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('sponsor-home')}
        title="My Profile"
        rightActions={[
          <IconBtn key="edit" icon={<EditIcon />} onClick={() => navigate('edit-sponsor-profile')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto">
        {/* Banner */}
        <div className="h-44 bg-gradient-to-br from-gray-800 to-gray-950 relative flex items-end justify-center">
          <div className="absolute bottom-0 translate-y-1/2">
            <Avatar size={80} name="Nike India" />
          </div>
        </div>

        {/* Profile info */}
        <div className="mt-12 px-4 flex flex-col items-center gap-1">
          <p className="font-bold text-xl text-gray-900">Nike India</p>
          <VerifiedBadge label="✓ Verified" />
          <div className="flex items-center gap-2 mt-1">
            <SportBadge sport="Sportswear" />
            <span className="text-sm text-gray-500">Pan-India</span>
          </div>
        </div>

        {/* Stats */}
        <div className="mt-4 px-4">
          <StatRow
            stats={[
              { label: 'Active Opp', value: 5 },
              { label: 'Athletes\nSponsored', value: 23 },
              { label: 'Years Active', value: 8 },
            ]}
          />
        </div>

        <div className="px-4 mt-4 flex flex-col gap-4 pb-6">
          {/* About */}
          <div>
            <SectionLabel label="ABOUT" />
            <p className="text-sm text-gray-600 mt-1 leading-relaxed">
              Nike India is committed to empowering athletes across the country. Through our sponsorship programs, we support emerging talent in cricket, athletics, football, and more — providing gear, funding, and visibility.
            </p>
          </div>

          {/* Active Opportunities */}
          <div>
            <SectionLabel label="ACTIVE OPPORTUNITIES" />
            <div className="flex flex-col gap-2 mt-2">
              {[
                { title: 'Athlete Sponsorship 2024', sport: 'Cricket', deadline: 'Dec 31, 2024' },
                { title: 'Youth Development Grant', sport: 'Athletics', deadline: 'Jan 15, 2025' },
              ].map((opp) => (
                <Card key={opp.title} style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
                  <div className="p-3 flex items-center justify-between">
                    <div className="flex-1">
                      <p className="text-sm font-semibold text-gray-800">{opp.title}</p>
                      <p className="text-xs text-gray-500">{opp.sport} • Deadline: {opp.deadline}</p>
                      <div className="mt-1">
                        <StatusDot status="open" label="Open" />
                      </div>
                    </div>
                    <GhostBtn label="View" onClick={() => navigate('listing-status')} />
                  </div>
                </Card>
              ))}
            </div>
          </div>

          {/* Past Associations */}
          <div>
            <SectionLabel label="PAST ASSOCIATIONS" />
            <div className="flex gap-3 mt-2 overflow-x-auto pb-1">
              {['Vikas N', 'Sana S', 'Arjun P', 'Meera K', 'Rahul T'].map((name) => (
                <div key={name} className="flex flex-col items-center gap-1 shrink-0">
                  <Avatar size={64} name={name} />
                  <p className="text-xs text-gray-600 text-center w-14 truncate">{name}</p>
                </div>
              ))}
            </div>
          </div>

          <SecondaryBtn full label="Share Profile" onClick={() => {}} />
        </div>
      </div>
    </div>
  );
}

// ─── EditSponsorProfileScreen ─────────────────────────────────────────────────

export function EditSponsorProfileScreen({ navigate }: { navigate: NavFn }) {
  const [orgName, setOrgName] = useState('Nike India');
  const [description, setDescription] = useState('');
  const [industry, setIndustry] = useState('Sportswear');
  const [coverage, setCoverage] = useState('Pan-India');

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('sponsor-profile')}
        title="Edit Profile"
        rightActions={[
          <GhostBtn key="save" label="Save" onClick={() => navigate('sponsor-profile')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        {/* Avatar */}
        <div className="flex flex-col items-center gap-1">
          <div className="relative">
            <Avatar size={80} name="Nike India" />
            <div className="absolute bottom-0 right-0 bg-blue-600 rounded-full p-1">
              <CameraIcon className="w-3 h-3 text-white" />
            </div>
          </div>
          <p className="text-xs text-blue-600">Change Logo</p>
        </div>

        <SectionLabel label="ORGANIZATION INFO" />
        <InputField
          label="Organization Name"
          value={orgName}
          onChange={(v) => setOrgName(v)}
        />
        <TextArea
          label="Description"
          value={description}
          onChange={(v) => setDescription(v)}
          placeholder="Describe your organization and mission..."
        />
        <SelectField
          label="Industry / Category"
          value={industry}
          onChange={(v) => setIndustry(v)}
          options={['Sportswear', 'Nutrition', 'Finance', 'Equipment', 'Media']}
        />
        <InputField
          label="Coverage Area"
          value={coverage}
          onChange={(v) => setCoverage(v)}
        />

        <div className="flex items-center justify-between">
          <SectionLabel label="PAST ASSOCIATIONS" />
          <GhostBtn label="+ Add Past Association" onClick={() => navigate('past-associations')} />
        </div>

        <PrimaryBtn full label="Save Changes" onClick={() => navigate('sponsor-profile')} />
      </div>
    </div>
  );
}

// ─── MyOpportunitiesScreen ────────────────────────────────────────────────────

export function MyOpportunitiesScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('sponsor-home')}
        title="My Opportunities"
        rightActions={[
          <IconBtn
            key="add"
            icon={<span className="text-xl font-light leading-none">+</span>}
            onClick={() => navigate('post-opportunity')}
          />,
        ]}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        {/* Active */}
        <SectionLabel label="ACTIVE (3)" />
        {[
          { title: 'Athlete Sponsorship 2024', sport: 'Cricket', region: 'Pan-India', deadline: 'Dec 31, 2024' },
          { title: 'Youth Development Grant', sport: 'Athletics', region: 'Delhi', deadline: 'Jan 15, 2025' },
        ].map((opp) => (
          <Card key={opp.title} style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
            <div className="p-3 flex items-center justify-between">
              <div className="flex-1">
                <p className="text-sm font-semibold text-gray-800">{opp.title}</p>
                <p className="text-xs text-gray-500">{opp.sport} • {opp.region} • Deadline: {opp.deadline}</p>
                <div className="mt-1">
                  <StatusDot status="open" label="Open" />
                </div>
              </div>
              <GhostBtn label="Edit" onClick={() => navigate('listing-status')} />
            </div>
          </Card>
        ))}

        {/* Pending */}
        <SectionLabel label="PENDING APPROVAL (1)" />
        <Card style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
          <div className="p-3 flex items-center justify-between">
            <div className="flex-1">
              <p className="text-sm font-semibold text-gray-800">Equipment Support Fund</p>
              <p className="text-xs text-gray-500">Football • Mumbai</p>
              <div className="mt-1">
                <StatusDot status="pending" label="Pending Review" />
              </div>
            </div>
            <GhostBtn label="View" onClick={() => navigate('listing-status')} />
          </div>
        </Card>

        {/* Closed */}
        <SectionLabel label="CLOSED (2)" />
        <Card style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
          <div className="p-3 flex items-center justify-between">
            <div className="flex-1">
              <p className="text-sm font-semibold text-gray-800">Summer Training Grant 2023</p>
              <p className="text-xs text-gray-500">All Sports • Pan-India</p>
              <div className="mt-1">
                <StatusDot status="closed" label="Closed" />
              </div>
            </div>
            <GhostBtn label="View" onClick={() => navigate('listing-status')} />
          </div>
        </Card>
      </div>
    </div>
  );
}

// ─── PastAssociationsScreen ───────────────────────────────────────────────────

const SHOWCASED_ATHLETES = [
  { name: 'Vikas Nair', sport: 'Cricket', period: 'Sponsored: 2022–2024' },
  { name: 'Priya Kumar', sport: 'Athletics', period: 'Sponsored: 2021–2023' },
];

const AVAILABLE_ASSOC_ATHLETES = [
  { name: 'Arjun Patel', sport: 'Football' },
  { name: 'Sana Sheikh', sport: 'Athletics' },
];

export function PastAssociationsScreen({ navigate }: { navigate: NavFn }) {
  const [selected, setSelected] = useState<Set<string>>(
    new Set(SHOWCASED_ATHLETES.map((a) => a.name))
  );
  const [query, setQuery] = useState('');

  const toggle = (name: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(name) ? next.delete(name) : next.add(name);
      return next;
    });
  };

  const allAthletes = [
    ...SHOWCASED_ATHLETES.map((a) => ({ ...a, period: a.period })),
    ...AVAILABLE_ASSOC_ATHLETES.map((a) => ({ ...a, period: '' })),
  ];

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('edit-sponsor-profile')}
        title="Past Associations"
        rightActions={[
          <GhostBtn key="save" label="Save" onClick={() => navigate('edit-sponsor-profile')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        <p className="text-sm text-gray-600">
          Search and select athletes to showcase as past associations
        </p>
        <SearchBar
          placeholder="Search athletes..."
          value={query}
          onChange={(v) => setQuery(v)}
        />

        <SectionLabel label={`SHOWCASED (${selected.size})`} />
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
                {athlete.period && (
                  <p className="text-xs text-green-700">{athlete.period}</p>
                )}
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

        <PrimaryBtn full label="Save Showcase" onClick={() => navigate('edit-sponsor-profile')} />
      </div>
    </div>
  );
}

const MOCK_ATHLETES = [
  { id: 1, name: 'Vikas Nair', sport: 'Cricket', state: 'Mumbai, MH', age: 18, ageGroup: 'U-19' },
  { id: 2, name: 'Sana Sheikh', sport: 'Athletics', state: 'Delhi, DL', age: 17, ageGroup: 'U-19' },
  { id: 3, name: 'Arjun Patel', sport: 'Football', state: 'Pune, MH', age: 19, ageGroup: 'Open' },
  { id: 4, name: 'Ravi Kumar', sport: 'Cricket', state: 'Delhi, DL', age: 16, ageGroup: 'U-16' },
]

export function AthleteDirectorySponsorScreen({ navigate }: { navigate: NavFn }) {
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
      home: 'sponsor-home',
      discover: 'athlete-directory-sponsor',
      postopp: 'my-opportunities',
      profile: 'sponsor-profile',
    };
    navigate(map[t] || t);
  };

  const filtered = MOCK_ATHLETES.filter(a => {
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
          <AthleteCard key={a.id} name={a.name} sport={a.sport} location={a.state} age={a.age} saveMode={true} onView={() => navigate('view-profile')} />
        ))}
        {filtered.length === 0 && (
          <div className="col-span-2 py-10 text-center text-gray-500 text-sm">No athletes match your filters.</div>
        )}
      </div>
      <BottomNav role="sponsor" active="discover" onTab={onTab} />

      {showAgeFilter && <FilterBottomSheet title="Select Age Group" options={['U-16', 'U-19', 'Open']} selected={selectedAge} onClose={() => setShowAgeFilter(false)} onSelect={setSelectedAge} />}
      {showStateFilter && <FilterBottomSheet title="Select State" options={['Mumbai', 'Delhi', 'Pune']} selected={selectedState} onClose={() => setShowStateFilter(false)} onSelect={setSelectedState} />}
      {showSportFilter && <FilterBottomSheet title="Select Sport" options={['Cricket', 'Football', 'Athletics']} selected={selectedSport} onClose={() => setShowSportFilter(false)} onSelect={setSelectedSport} />}
    </div>
  );
}

// ─── AcademyDirectorySponsorScreen ────────────────────────────────────────────

const MOCK_ACADEMIES = [
  { id: 1, name: 'Rahul Cricket Academy', sport: 'Cricket', state: 'Delhi, DL', athletes: 120, programs: 5 },
  { id: 2, name: 'Pune FC Youth', sport: 'Football', state: 'Pune, MH', athletes: 80, programs: 3 },
  { id: 3, name: 'Elite Athletics Club', sport: 'Athletics', state: 'Mumbai, MH', athletes: 150, programs: 6 },
]

export function AcademyDirectorySponsorScreen({ navigate }: { navigate: NavFn }) {
  const [activeTab, setActiveTab] = useState('All');
  const [query, setQuery] = useState('');
  
  const [selectedState, setSelectedState] = useState('');
  const [selectedSport, setSelectedSport] = useState('');
  
  const [showStateFilter, setShowStateFilter] = useState(false);
  const [showSportFilter, setShowSportFilter] = useState(false);

  const onTab = (t: string) => {
    const map: Record<string, string> = {
      home: 'sponsor-home',
      discover: 'academy-directory-sponsor',
      postopp: 'my-opportunities',
      profile: 'sponsor-profile',
    };
    navigate(map[t] || t);
  };

  const filtered = MOCK_ACADEMIES.filter(a => {
    if (activeTab !== 'All' && a.sport !== activeTab) return false;
    if (query && !a.name.toLowerCase().includes(query.toLowerCase())) return false;
    if (selectedState && !a.state.includes(selectedState)) return false;
    if (selectedSport && a.sport !== selectedSport) return false;
    return true;
  });

  return (
    <div className="flex flex-col h-full overflow-hidden relative">
      <AppBar
        logoLeft
        title="Academies"
        rightActions={[
          <IconBtn key="bell" icon={<BellIcon />} onClick={() => navigate('notifications')} />,
          <IconBtn key="settings" icon={<SettingsIcon />} onClick={() => navigate('settings')} />,
        ]}
      />
      <div className="px-4 pt-2">
        <SearchBar placeholder="Search academies..." value={query} onChange={(v) => setQuery(v)} />
      </div>
      <div className="px-4 mt-2">
        <TabPills tabs={['All', 'Cricket', 'Football', 'Athletics']} active={activeTab} onChange={setActiveTab} />
      </div>
      <div className="px-4 mt-2 flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
        <FilterChip label={selectedState || "State ▼"} active={!!selectedState} onClick={() => setShowStateFilter(true)} onRemove={() => setSelectedState('')} />
        <FilterChip label={selectedSport || "Sport ▼"} active={!!selectedSport} onClick={() => setShowSportFilter(true)} onRemove={() => setSelectedSport('')} />
      </div>
      <div className="flex-1 overflow-y-auto px-4 grid grid-cols-2 gap-3 pt-3 pb-4 items-start">
        {filtered.map(a => (
          <AcademyCard key={a.id} name={a.name} sport={a.sport} location={a.state} athletes={a.athletes} programs={a.programs} onView={() => navigate('view-profile')} />
        ))}
        {filtered.length === 0 && (
          <div className="col-span-2 py-10 text-center text-gray-500 text-sm">No academies match your filters.</div>
        )}
      </div>
      <BottomNav role="sponsor" active="discover" onTab={onTab} />
      
      {showStateFilter && <FilterBottomSheet title="Select State" options={['Mumbai', 'Delhi', 'Pune']} selected={selectedState} onClose={() => setShowStateFilter(false)} onSelect={setSelectedState} />}
      {showSportFilter && <FilterBottomSheet title="Select Sport" options={['Cricket', 'Football', 'Athletics']} selected={selectedSport} onClose={() => setShowSportFilter(false)} onSelect={setSelectedSport} />}
    </div>
  );
}

// ─── PostOpportunityScreen ────────────────────────────────────────────────────

export function PostOpportunityScreen({ navigate }: { navigate: NavFn }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [sport, setSport] = useState('Cricket');
  const [region, setRegion] = useState('');
  const [eligibility, setEligibility] = useState('');
  const [deadline, setDeadline] = useState('');
  const [oppType, setOppType] = useState('Sponsorship');

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('my-opportunities')}
        title="Post Opportunity"
        rightActions={[
          <GhostBtn key="submit" label="Submit" onClick={() => navigate('listing-status')} />,
        ]}
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        <InputField
          label="Opportunity Title *"
          placeholder="e.g., Athlete Sponsorship"
          value={title}
          onChange={(v) => setTitle(v)}
        />
        <TextArea
          label="Description"
          value={description}
          onChange={(v) => setDescription(v)}
          placeholder="Describe the opportunity..."
        />
        <SelectField
          label="Sport Category *"
          value={sport}
          onChange={(v) => setSport(v)}
          options={['Cricket', 'Football', 'Athletics', 'All Sports']}
        />
        <InputField
          label="Region / Location *"
          placeholder="Pan-India / Specific city"
          value={region}
          onChange={(v) => setRegion(v)}
        />
        <TextArea
          label="Eligibility Criteria"
          value={eligibility}
          onChange={(v) => setEligibility(v)}
          placeholder="Who can apply?"
        />
        <InputField
          label="Application Deadline *"
          placeholder="Dec 31, 2024"
          value={deadline}
          onChange={(v) => setDeadline(v)}
          trailing={<span>📅</span>}
        />
        <SelectField
          label="Opportunity Type"
          value={oppType}
          onChange={(v) => setOppType(v)}
          options={['Sponsorship', 'Equipment', 'Funding', 'Training']}
        />
        <PrimaryBtn
          full
          label="Submit for Approval"
          onClick={() => navigate('listing-status')}
        />
        <p className="text-xs text-gray-500 text-center">
          Your listing will be reviewed by admin before going live.
        </p>
      </div>
    </div>
  );
}

// ─── ListingStatusScreen ──────────────────────────────────────────────────────

export function ListingStatusScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full overflow-hidden">
      <AppBar
        onBack={() => navigate('sponsor-home')}
        title="Listing Status"
      />
      <div className="flex-1 overflow-y-auto px-4 pt-4 pb-8 flex flex-col gap-4">
        {/* Pending */}
        <SectionLabel label="PENDING APPROVAL" />
        <Card style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
          <div className="p-3 flex items-center justify-between">
            <div className="flex-1">
              <p className="text-sm font-semibold text-gray-800">Youth Development Program</p>
              <p className="text-xs text-gray-500">Football • Delhi</p>
              <p className="text-xs text-gray-400">Submitted: Nov 1, 2024</p>
              <div className="mt-1">
                <StatusDot status="pending" label="Pending Review" />
              </div>
            </div>
            <GhostBtn label="View" onClick={() => {}} />
          </div>
        </Card>

        {/* Approved */}
        <SectionLabel label="APPROVED" />
        <Card style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
          <div className="p-3 flex items-start justify-between">
            <div className="flex-1">
              <p className="text-sm font-semibold text-gray-800">Athlete Sponsorship 2024</p>
              <p className="text-xs text-gray-500">Cricket • Pan-India</p>
              <p className="text-xs text-gray-400">Approved: Oct 15, 2024</p>
              <div className="mt-1">
                <StatusDot status="live" label="Live" />
              </div>
            </div>
            <div className="flex gap-2">
              <GhostBtn label="Edit" onClick={() => {}} />
              <GhostBtn label="Close" onClick={() => {}} />
            </div>
          </div>
        </Card>

        {/* Rejected */}
        <SectionLabel label="REJECTED" />
        <Card style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
          <div className="p-3 flex items-start justify-between">
            <div className="flex-1">
              <p className="text-sm font-semibold text-gray-800">Equipment Grant</p>
              <p className="text-xs text-gray-500">All Sports • Mumbai</p>
              <p className="text-xs text-gray-400">Rejected: Oct 10, 2024</p>
              <div className="mt-1">
                <StatusDot status="rejected" label="Rejected" />
              </div>
              <p className="text-xs text-red-500 mt-1">Reason: Incomplete info</p>
            </div>
            <GhostBtn label="Edit" onClick={() => navigate('post-opportunity')} />
          </div>
        </Card>
      </div>
    </div>
  );
}
