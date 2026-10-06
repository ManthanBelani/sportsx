import { useState } from "react";

type Screen =
  | "home"
  | "explore"
  | "create"
  | "community"
  | "more"
  | "profile"
  | "programs"
  | "events"
  | "athletes"
  | "facilities"
  | "notifications"
  | "messages"
  | "detail";

type IconName =
  | "home"
  | "compass"
  | "plus"
  | "users"
  | "grid"
  | "bell"
  | "message"
  | "search"
  | "chevron"
  | "arrow"
  | "star"
  | "map"
  | "calendar"
  | "trophy"
  | "bookmark"
  | "share"
  | "edit"
  | "academy"
  | "user"
  | "clock"
  | "chart"
  | "shield"
  | "image"
  | "video"
  | "settings"
  | "logout";

const photos = {
  cricket:
    "https://images.unsplash.com/photo-1732315797079-fe90763b8bd9?auto=format&fit=crop&w=900&q=82",
  football:
    "https://images.unsplash.com/photo-1625990637351-ee0e5e9ba5e5?auto=format&fit=crop&w=900&q=82",
  player:
    "https://images.unsplash.com/photo-1547839918-5ed99eac4175?auto=format&fit=crop&w=700&q=82",
  stadium:
    "https://images.unsplash.com/photo-1644664750583-1cf0430098ff?auto=format&fit=crop&w=900&q=82",
};

const people = [
  { name: "Arjun Patel", role: "Cricket · All-rounder", img: photos.player },
  { name: "Riya Sharma", role: "Football · U-17", img: photos.football },
  { name: "Karan Joshi", role: "Cricket · Batter", img: photos.cricket },
  { name: "Neha Patel", role: "Football · Striker", img: photos.stadium },
];

function Icon({ name, size = 20 }: { name: IconName; size?: number }) {
  const paths: Record<IconName, React.ReactNode> = {
    home: <><path d="m3 10 9-7 9 7" /><path d="M5 9v11h14V9" /><path d="M9 20v-7h6v7" /></>,
    compass: <><circle cx="12" cy="12" r="9" /><path d="m15 9-2 4-4 2 2-4 4-2Z" /></>,
    plus: <><path d="M12 5v14M5 12h14" /></>,
    users: <><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" /></>,
    grid: <><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" /></>,
    bell: <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" /><path d="M10 21h4" /></>,
    message: <path d="M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4Z" />,
    search: <><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></>,
    chevron: <path d="m9 18 6-6-6-6" />,
    arrow: <path d="m15 18-6-6 6-6" />,
    star: <path d="m12 2 3 6 7 .9-5 4.8 1.3 6.8-6.3-3.3-6.3 3.3L7 13.7 2 9l7-.9L12 2Z" />,
    map: <><path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z" /><circle cx="12" cy="10" r="2.5" /></>,
    calendar: <><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M16 3v4M8 3v4M3 10h18" /></>,
    trophy: <><path d="M8 21h8M12 17v4M7 4h10v4a5 5 0 0 1-10 0V4Z" /><path d="M7 6H3v2a4 4 0 0 0 4 4M17 6h4v2a4 4 0 0 1-4 4" /></>,
    bookmark: <path d="M6 3h12v18l-6-4-6 4V3Z" />,
    share: <><circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" /><path d="m8.6 10.5 6.8-4M8.6 13.5l6.8 4" /></>,
    edit: <><path d="M12 20h9" /><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z" /></>,
    academy: <><path d="m3 10 9-6 9 6" /><path d="M5 10v9h14v-9M9 19v-5h6v5" /></>,
    user: <><circle cx="12" cy="8" r="4" /><path d="M4 21a8 8 0 0 1 16 0" /></>,
    clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v6l4 2" /></>,
    chart: <><path d="M4 19V9M10 19V5M16 19v-7M22 19H2" /></>,
    shield: <><path d="M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11Z" /><path d="m9 12 2 2 4-4" /></>,
    image: <><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="m21 15-5-5L5 21" /></>,
    video: <><rect x="3" y="5" width="14" height="14" rx="2" /><path d="m17 10 4-3v10l-4-3" /></>,
    settings: <><circle cx="12" cy="12" r="3" /><path d="M19.4 15a2 2 0 0 0 .4 2.2l.1.1-2.6 2.6-.1-.1a2 2 0 0 0-2.2-.4 2 2 0 0 0-1.2 1.8V21h-3.6v-.2A2 2 0 0 0 9 19a2 2 0 0 0-2.2.4l-.1.1-2.6-2.6.1-.1A2 2 0 0 0 4.6 15a2 2 0 0 0-1.8-1.2H2v-3.6h.8A2 2 0 0 0 4.6 9a2 2 0 0 0-.4-2.2l-.1-.1 2.6-2.6.1.1A2 2 0 0 0 9 4.6a2 2 0 0 0 1.2-1.8V2h3.6v.8A2 2 0 0 0 15 4.6a2 2 0 0 0 2.2-.4l.1-.1 2.6 2.6-.1.1A2 2 0 0 0 19.4 9a2 2 0 0 0 1.8 1.2h.8v3.6h-.8a2 2 0 0 0-1.8 1.2Z" /></>,
    logout: <><path d="M10 17l5-5-5-5M15 12H3M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" /></>,
  };
  return <svg className="icon" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name]}</svg>;
}

function Tap({ children, onClick, className = "", label }: { children: React.ReactNode; onClick?: () => void; className?: string; label?: string }) {
  return <div role="button" tabIndex={0} aria-label={label} className={`tap ${className}`} onClick={onClick} onKeyDown={(e) => e.key === "Enter" && onClick?.()}>{children}</div>;
}

function Logo() {
  return <div className="logo">Sport<span>X</span><i /></div>;
}

function Avatar({ person = people[0], small = false }: { person?: typeof people[number]; small?: boolean }) {
  return <img className={`avatar ${small ? "avatar-small" : ""}`} src={person.img} alt={person.name} />;
}

function TopBar({ title, back, onBack, onNotify, onMessage }: { title?: string; back?: boolean; onBack?: () => void; onNotify?: () => void; onMessage?: () => void }) {
  return <div className="topbar">
    {back ? <Tap className="icon-tap" onClick={onBack} label="Go back"><Icon name="arrow" /></Tap> : title ? <div className="topbar-spacer" /> : <Logo />}
    {title && <div className="topbar-title">{title}</div>}
    <div className="top-actions">
      {onMessage && <Tap className="icon-tap" onClick={onMessage} label="Messages"><Icon name="message" size={18} /></Tap>}
      {onNotify && <Tap className="icon-tap notification-button" onClick={onNotify} label="Notifications"><Icon name="bell" size={18} /><b>3</b></Tap>}
      {!back && !title && <Avatar small />}
      {back && !onNotify && <div className="topbar-spacer" />}
    </div>
  </div>;
}

function Search({ placeholder = "Search athletes, coaches, academies..." }: { placeholder?: string }) {
  return <div className="search"><Icon name="search" size={18} /><span>{placeholder}</span></div>;
}

function Chip({ children, active, onClick }: { children: React.ReactNode; active?: boolean; onClick?: () => void }) {
  return <Tap onClick={onClick} className={`chip ${active ? "chip-active" : ""}`}>{children}</Tap>;
}

function Primary({ children, onClick, compact = false }: { children: React.ReactNode; onClick?: () => void; compact?: boolean }) {
  return <Tap onClick={onClick} className={`primary ${compact ? "primary-compact" : ""}`}>{children}</Tap>;
}

function SectionHead({ title, action = "View all", onClick }: { title: string; action?: string; onClick?: () => void }) {
  return <div className="section-head"><div>{title}</div>{onClick && <Tap onClick={onClick} className="see-all">{action}<Icon name="chevron" size={13} /></Tap>}</div>;
}

function BottomNav({ screen, go }: { screen: Screen; go: (screen: Screen) => void }) {
  const items: { label: string; icon: IconName; id: Screen }[] = [
    { label: "Home", icon: "home", id: "home" },
    { label: "Explore", icon: "compass", id: "explore" },
    { label: "Create", icon: "plus", id: "create" },
    { label: "Community", icon: "users", id: "community" },
    { label: "More", icon: "grid", id: "more" },
  ];
  const active = ["profile", "programs", "events", "athletes", "facilities"].includes(screen) ? "more" : screen;
  return <div className="bottom-nav">{items.map((item) => <Tap key={item.id} className={`nav-item ${active === item.id ? "nav-active" : ""} ${item.id === "create" ? "create-nav" : ""}`} onClick={() => go(item.id)}>
    <div className="nav-icon"><Icon name={item.icon} size={item.id === "create" ? 24 : 20} /></div><span>{item.label}</span>
  </Tap>)}</div>;
}

function Stat({ value, label }: { value: string; label: string }) {
  return <div className="stat"><strong>{value}</strong><span>{label}</span></div>;
}

function AcademyCard({ title, location, image, onClick }: { title: string; location: string; image: string; onClick: () => void }) {
  return <Tap className="academy-card" onClick={onClick}>
    <img src={image} alt="" />
    <div className="academy-info"><div className="verified-line"><strong>{title}</strong><span className="verified">✓</span></div><p><Icon name="map" size={12} />{location}</p><div className="card-bottom"><span><Icon name="star" size={12} />4.8 (320)</span><span className="text-link">View Details</span></div></div>
  </Tap>;
}

function PersonRow({ person, action = "View Profile", onClick }: { person: typeof people[number]; action?: string; onClick?: () => void }) {
  return <div className="person-row"><Avatar person={person} /><div className="person-copy"><strong>{person.name}<span className="verified">✓</span></strong><p>{person.role}</p><span><Icon name="star" size={11} /> 4.8 · Ahmedabad</span></div><Primary compact onClick={onClick}>{action}</Primary></div>;
}

function Home({ go, toast }: { go: (s: Screen) => void; toast: (s: string) => void }) {
  return <><TopBar onNotify={() => go("notifications")} onMessage={() => go("messages")} />
    <main className="page">
      <Tap className="greet-card" onClick={() => go("profile")}><Avatar /><div className="greet-copy"><span>Good morning,</span><strong>Hi, Motera Cricket Academy!</strong><p>Complete your profile to get discovered</p><div className="progress"><i /></div></div><b>80%</b><Icon name="chevron" size={18} /></Tap>
      <div className="role-line"><span className="role-badge">ACADEMY</span><span>Ahmedabad, Gujarat</span></div>
      <SectionHead title="Leaderboard" action="View all" onClick={() => toast("Leaderboard opened")} />
      <div className="leaderboard">
        {["Motera Cricket Academy", "Ahmedabad Football Academy", "Gujarat Badminton Academy"].map((name, i) => <div className="rank" key={name}><span>{i + 1}</span><img src={[photos.cricket, photos.football, photos.stadium][i]} alt="" /><strong>{name}</strong><small>{(i + 1) * 3200 + 4100} pts</small></div>)}
      </div>
      <div className="quick-grid">
        <Tap className="quick-tile" onClick={() => go("events")}><i className="tile-icon yellow"><Icon name="trophy" /></i><strong>Opportunities</strong><span>Trials & tournaments</span></Tap>
        <Tap className="quick-tile" onClick={() => go("facilities")}><i className="tile-icon blue"><Icon name="academy" /></i><strong>Find Talent</strong><span>Connect with athletes</span></Tap>
      </div>
      <SectionHead title="For you" action="Academies" onClick={() => go("explore")} />
      <div className="feed-card"><div className="feed-author"><Avatar person={people[2]} small /><div><strong>Motera Cricket Academy</strong><span>2h · Ahmedabad</span></div><Tap onClick={() => toast("Post saved")}><Icon name="bookmark" size={18} /></Tap></div><p>New batch registrations open for our U-16 high performance cricket program.</p><img src={photos.cricket} alt="Cricket players training on a field" /><div className="feed-actions"><span>♥ 254</span><span>♡ 18</span><span><Icon name="share" size={15} /> 12</span></div></div>
    </main>
  </>;
}

function Explore({ go }: { go: (s: Screen) => void }) {
  const [filter, setFilter] = useState("Academies");
  return <><TopBar onNotify={() => go("notifications")} />
    <main className="page"><Search /><div className="horizontal chips">{["All Sports", "Cricket", "Football", "Badminton"].map((x) => <Chip key={x} active={x === "All Sports"}>{x}</Chip>)}</div>
      <div className="tabs">{["Athletes", "Coaches", "Academies", "Training Centres"].map((x) => <Tap key={x} onClick={() => setFilter(x)} className={filter === x ? "tab-active" : ""}>{x}</Tap>)}</div>
      <SectionHead title={filter === "Athletes" ? "Featured athletes" : "Featured academies"} action="4.8 ★" />
      {filter === "Athletes" ? people.map((person) => <PersonRow person={person} key={person.name} onClick={() => go("athletes")} />) :
        <div className="academy-list">
          <AcademyCard title="Motera Cricket Academy" location="Ahmedabad · 2.5 km" image={photos.cricket} onClick={() => go("detail")} />
          <AcademyCard title="Ahmedabad Football Academy" location="Ahmedabad · 6.1 km" image={photos.football} onClick={() => go("detail")} />
          <AcademyCard title="Gujarat Badminton Academy" location="Gujarat · 4.8 km" image={photos.stadium} onClick={() => go("detail")} />
          <AcademyCard title="AquaSport Swimming Academy" location="Vastrapur · 8.2 km" image={photos.player} onClick={() => go("detail")} />
        </div>}
    </main>
  </>;
}

const createItems: { icon: IconName; color: string; title: string; sub: string }[] = [
  { icon: "edit", color: "purple", title: "Create Post", sub: "Share updates, achievements or announcements" },
  { icon: "calendar", color: "green", title: "Add Training Program", sub: "Create and list your training program" },
  { icon: "trophy", color: "red", title: "Create Event / Trial", sub: "Post trials, tournaments or camps" },
  { icon: "academy", color: "blue", title: "Post Scholarship / Opportunity", sub: "List scholarships or sponsorships" },
  { icon: "map", color: "orange", title: "Add Facility / Venue", sub: "Showcase your training grounds or courts" },
  { icon: "user", color: "pink", title: "Recruit Staff", sub: "Post coach or staff openings" },
  { icon: "image", color: "magenta", title: "Upload Photos / Videos", sub: "Share training moments and facilities" },
  { icon: "video", color: "purple", title: "Go Live / Webinar", sub: "Host a live training session" },
];

function Create({ toast }: { toast: (s: string) => void }) {
  return <><TopBar title="Create" /><main className="page create-page">{createItems.map((item) => <Tap className="create-row" key={item.title} onClick={() => toast(`${item.title} selected`)}><i className={`create-icon ${item.color}`}><Icon name={item.icon} /></i><div><strong>{item.title}</strong><p>{item.sub}</p></div><Icon name="chevron" size={18} /></Tap>)}</main></>;
}

function Community({ go, toast }: { go: (s: Screen) => void; toast: (s: string) => void }) {
  const [tab, setTab] = useState("Network");
  return <><TopBar title="Community" onMessage={() => go("messages")} /><main className="page"><div className="tabs community-tabs">{["Network", "Groups", "Events"].map((x) => <Tap key={x} onClick={() => setTab(x)} className={tab === x ? "tab-active" : ""}>{x}</Tap>)}</div><Search placeholder="Search people, groups, events..." />
    <SectionHead title="Suggested for you" />
    <div className="horizontal chips"><Chip active>Athletes</Chip><Chip>Coaches</Chip><Chip>Academies</Chip></div>
    {people.map((person, i) => <PersonRow person={person} key={person.name} action={i === 1 ? "Following" : "Follow"} onClick={() => toast(i === 1 ? `Unfollowed ${person.name}` : `Following ${person.name}`)} />)}
    <SectionHead title="Join Groups" action="See all" onClick={() => toast("All groups opened")} />
    {["Gujarat Coaches Network", "Cricket Academies Gujarat", "Sports Facility Owners"].map((group, i) => <div className="group-row" key={group}><img src={[photos.cricket, photos.football, photos.stadium][i]} alt="" /><div><strong>{group}</strong><span>{1.8 + i}k members</span></div><Chip onClick={() => toast(`Joined ${group}`)}>Join</Chip></div>)}
  </main></>;
}

function More({ go }: { go: (s: Screen) => void }) {
  const menu: { icon: IconName; label: string; screen?: Screen }[] = [
    { icon: "user", label: "My Profile", screen: "profile" }, { icon: "calendar", label: "My Training Programs", screen: "programs" },
    { icon: "trophy", label: "My Events / Trials", screen: "events" }, { icon: "users", label: "My Athletes", screen: "athletes" },
    { icon: "academy", label: "My Facilities / Venues", screen: "facilities" }, { icon: "chart", label: "My Analytics" },
    { icon: "bookmark", label: "Saved" }, { icon: "bell", label: "Notifications", screen: "notifications" },
    { icon: "message", label: "Messages", screen: "messages" }, { icon: "settings", label: "Settings & Privacy" }, { icon: "shield", label: "Help & Support" },
  ];
  return <><TopBar title="More" /><main className="page"><Tap className="profile-summary" onClick={() => go("profile")}><Avatar person={people[2]} /><div><strong>Motera Cricket Academy <span className="verified">✓</span></strong><span>Sports Academy</span><b>View Profile ›</b></div></Tap>
    <div className="menu-card">{menu.map((item) => <Tap className="menu-row" key={item.label} onClick={() => item.screen && go(item.screen)}><Icon name={item.icon} size={18} /><span>{item.label}</span><Icon name="chevron" size={17} /></Tap>)}
      <Tap className="menu-row logout"><Icon name="logout" size={18} /><span>Logout</span></Tap></div>
  </main></>;
}

function BackPage({ title, go, children, action }: { title: string; go: (s: Screen) => void; children: React.ReactNode; action?: React.ReactNode }) {
  return <><TopBar title={title} back onBack={() => go("more")} /><main className="page subpage">{children}</main>{action}</>;
}

function Profile({ go, toast }: { go: (s: Screen) => void; toast: (s: string) => void }) {
  return <BackPage title="Academy Profile" go={go}><div className="profile-hero"><img src={photos.cricket} alt="Cricket academy team" /><div className="profile-avatar"><img src={photos.stadium} alt="" /></div></div><div className="profile-title"><strong>Motera Cricket Academy <span className="verified">✓</span></strong><p><Icon name="map" size={13} /> Motera, Ahmedabad · Gujarat</p><span><Icon name="star" size={13} /> 4.8 (320 reviews)</span></div><div className="profile-actions"><Primary onClick={() => toast("Profile editor opened")}><Icon name="edit" size={16} /> Edit Profile</Primary><Chip onClick={() => toast("Profile shared")}><Icon name="share" size={16} /> Share</Chip></div><div className="tabs"><Tap className="tab-active">About</Tap><Tap>Programs</Tap><Tap>Facilities</Tap><Tap>Reviews</Tap></div><section className="content-card"><SectionHead title="About" /><p>Professional cricket academy with world-class coaching, certified trainers, and high-performance programs for aspiring athletes.</p><div className="details">{[["Founded", "2018"], ["Age Group", "U-8 to U-19"], ["Students", "320+"], ["Coaching staff", "12 coaches"], ["Languages", "English, Hindi, Gujarati"]].map(([a,b]) => <div key={a}><span>{a}</span><strong>{b}</strong></div>)}</div></section></BackPage>;
}

const programs = ["Beginner Cricket Program", "Advanced Batting Training", "Fit & Bowling Specialist", "Weekend Cricket Camp", "1-on-1 Personal Coaching"];
function Programs({ go, toast }: { go: (s: Screen) => void; toast: (s: string) => void }) {
  return <BackPage title="My Training Programs" go={go} action={<div className="sticky-action"><Primary onClick={() => toast("New program form opened")}><Icon name="plus" /> Add Program</Primary></div>}><div className="tabs"><Tap className="tab-active">Active</Tap><Tap>Drafts</Tap><Tap>Past</Tap></div>{programs.map((p,i) => <div className="list-card" key={p}><img src={i%2 ? photos.football : photos.cricket} alt="" /><div><strong>{p}</strong><p><Icon name="users" size={12}/> U-{12+i*2} · {8+i*4} weeks</p><b>₹{(i+3)*1000}</b></div><Primary compact onClick={() => toast(`${p} opened`)}>View Details</Primary></div>)}</BackPage>;
}

function Events({ go, toast }: { go: (s: Screen) => void; toast: (s: string) => void }) {
  const events = ["Open Trials · U-16 Cricket", "Winter Training Camp", "Inter Academy Cricket Tournament", "State Badminton Tournament", "Football Scouting Trial"];
  return <BackPage title="Events / Trials" go={go} action={<div className="sticky-action"><Primary onClick={() => toast("Create event form opened")}><Icon name="plus"/> Create Event</Primary></div>}><div className="tabs"><Tap className="tab-active">Upcoming</Tap><Tap>Past</Tap></div>{events.map((e,i) => <div className="event-card" key={e}><div className="event-date"><b>{11+i*3}</b><span>NOV</span></div><img src={i%2?photos.stadium:photos.cricket} alt="" /><div><strong>{e}</strong><p><Icon name="map" size={12}/> Ahmedabad</p><span className="status-pill">{i === 0 ? "Registration open" : "Upcoming"}</span></div><Tap onClick={() => toast(`${e} opened`)}><Icon name="chevron"/></Tap></div>)}</BackPage>;
}

function Athletes({ go }: { go: (s: Screen) => void }) {
  return <BackPage title="Our Athletes" go={go}><Search placeholder="Search athletes..." /><div className="horizontal chips"><Chip active>All</Chip><Chip>U-14</Chip><Chip>U-16</Chip><Chip>U-19</Chip></div>{people.concat(people.slice(0,2)).map((person,i) => <PersonRow key={`${person.name}${i}`} person={person} onClick={() => go("detail")} />)}</BackPage>;
}

function Facilities({ go, toast }: { go: (s: Screen) => void; toast: (s: string) => void }) {
  const facilities = [["Main Cricket Ground",photos.cricket],["Indoor Nets",photos.player],["Fitness Centre",photos.stadium],["Classrooms",photos.football],["Changing Rooms",photos.cricket]];
  return <BackPage title="Facilities" go={go} action={<div className="sticky-action"><Primary onClick={() => toast("Add facility form opened")}><Icon name="plus"/> Add Facility</Primary></div>}><div className="horizontal chips"><Chip active>All</Chip><Chip>Grounds</Chip><Chip>Indoor</Chip></div>{facilities.map(([f,img]) => <div className="list-card facility-card" key={f}><img src={img} alt="" /><div><strong>{f}</strong><p><Icon name="map" size={12}/> Motera Campus</p></div><Primary compact onClick={() => toast(`${f} opened`)}>View Details</Primary></div>)}</BackPage>;
}

function Notifications({ go }: { go: (s: Screen) => void }) {
  const notes = [["user","Karan Joshi joined your academy","10 min"],["users","Ahmedabad Cricket Academy followed you","45 min"],["message","New enquiry for training program","1 hr"],["trophy","Priya Sharma registered for U-16 trial","3 hr"],["star","You received a new 5-star review","Yesterday"]];
  return <><TopBar title="Notifications" back onBack={() => go("home")} /><main className="page"><div className="tabs"><Tap className="tab-active">All</Tap><Tap>Opportunities</Tap><Tap>System</Tap></div>{notes.map(([icon,text,time]) => <div className="notification-row" key={text}><i><Icon name={icon as IconName} size={18}/></i><div><strong>{text}</strong><span>{time}</span></div><b /></div>)}</main></>;
}

function Messages({ go }: { go: (s: Screen) => void }) {
  return <><TopBar title="Messages" back onBack={() => go("home")} /><main className="page"><div className="tabs"><Tap className="tab-active">Chats</Tap><Tap>Requests</Tap></div><Search placeholder="Search messages..." />{people.concat(people.slice(0,2)).map((person,i) => <Tap className="chat-row" key={`${person.name}${i}`}><Avatar person={person}/><div><strong>{person.name}</strong><p>{i%2 ? "Thanks for the update!" : "When does the next batch start?"}</p></div><span>{i<2 ? "10:30" : "Yesterday"}{i<3 && <b>{i+1}</b>}</span></Tap>)}</main></>;
}

function Detail({ go, toast }: { go: (s: Screen) => void; toast: (s: string) => void }) {
  return <div className="detail-page"><div className="detail-hero"><img src={photos.cricket} alt="Cricket training academy"/><Tap className="floating-back" onClick={() => go("explore")}><Icon name="arrow"/></Tap><Tap className="floating-save" onClick={() => toast("Saved to favourites")}><Icon name="bookmark"/></Tap></div><div className="detail-sheet"><span className="role-badge">CRICKET ACADEMY</span><div className="detail-title">Motera Cricket Academy <span className="verified">✓</span></div><p><Icon name="map" size={14}/> Motera, Ahmedabad · 2.5 km</p><div className="detail-rating"><Icon name="star" size={15}/> <b>4.8</b><span>(320 reviews)</span></div><div className="detail-stats"><Stat value="320+" label="Athletes"/><Stat value="12" label="Coaches"/><Stat value="8" label="Programs"/></div><SectionHead title="About the academy"/><p>World-class cricket coaching with certified professionals, modern facilities and athlete-first development programs.</p><SectionHead title="What we offer"/><div className="offer-grid"><span>Indoor nets</span><span>Fitness center</span><span>Video analysis</span><span>Match practice</span></div></div><div className="sticky-action detail-action"><Chip onClick={() => toast("Message sent")}><Icon name="message"/> Message</Chip><Primary onClick={() => toast("Enquiry submitted")}>Send Enquiry</Primary></div></div>;
}

function SportXPrototype({ onExit }: { onExit?: () => void }) {
  const [screen, setScreen] = useState<Screen>("home");
  const [toastText, setToastText] = useState("");
  const toast = (message: string) => {
    setToastText(message);
    window.setTimeout(() => setToastText(""), 1800);
  };
  const go = (next: Screen) => {
    setScreen(next);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };
  const props = { go, toast };
  const screens: Record<Screen, React.ReactNode> = {
    home: <Home {...props}/>, explore: <Explore go={go}/>, create: <Create toast={toast}/>,
    community: <Community {...props}/>, more: <More go={go}/>, profile: <Profile {...props}/>,
    programs: <Programs {...props}/>, events: <Events {...props}/>, athletes: <Athletes go={go}/>,
    facilities: <Facilities {...props}/>, notifications: <Notifications go={go}/>,
    messages: <Messages go={go}/>, detail: <Detail {...props}/>,
  };
  const showNav = !["notifications", "messages", "detail"].includes(screen);
  return <div className="app-shell prototype-shell">{onExit && <Tap className="exit-prototype" onClick={onExit}><Icon name="arrow" size={18}/> All role screens</Tap>}<div className="phone">{screens[screen]}{showNav && <BottomNav screen={screen} go={go}/>} {toastText && <div className="toast">{toastText}</div>}</div></div>;
}

type RoleKey = "coach" | "academy" | "organizer" | "scout";

const roleShowcase: Record<RoleKey, { title: string; subtitle: string; accent: string; screens: string[] }> = {
  coach: {
    title: "Coach",
    subtitle: "Rohit Mehta · Cricket Coach",
    accent: "role-coach",
    screens: ["Home", "Explore", "Create", "Community", "More", "Coach Profile", "Training Programs", "Leaderboard", "Academies", "Notifications", "Messages"],
  },
  academy: {
    title: "Academy",
    subtitle: "Motera Cricket Academy",
    accent: "role-academy",
    screens: ["Home", "Explore", "Create", "Community", "More", "Academy Profile", "Training Programs", "Events / Trials", "Athletes", "Facilities", "Messages"],
  },
  organizer: {
    title: "Organizer",
    subtitle: "Raj Sports Events",
    accent: "role-organizer",
    screens: ["Home", "Explore", "Create", "Community", "More", "Organizer Profile", "My Events", "Event Management", "Registrations", "Analytics", "Messages"],
  },
  scout: {
    title: "Talent Scout",
    subtitle: "Sameer Desai · Scout",
    accent: "role-scout",
    screens: ["Home", "Explore", "Create", "Community", "More", "Scout Profile", "Shortlisted Talents", "Talent Report", "Opportunities", "Notifications", "Messages"],
  },
};

const miniPeople = ["Arjun Patel", "Riya Sharma", "Karan Joshi", "Neha Patel"];

function MiniHeader({ title, numbered }: { title?: string; numbered?: boolean }) {
  return <div className="mini-header">{title ? <><Icon name="arrow" size={11}/><strong>{title}</strong><span /></> : <><Logo/><div><Icon name="bell" size={11}/><span className="mini-avatar"/></div></>}{numbered && <i />}</div>;
}

function MiniNav({ active = 0 }: { active?: number }) {
  const nav: IconName[] = ["home", "compass", "plus", "users", "grid"];
  return <div className="mini-nav">{nav.map((icon, i) => <div className={i === active ? "on" : ""} key={icon}><Icon name={icon} size={i === 2 ? 14 : 11}/><span>{["Home","Explore","Create","Community","More"][i]}</span></div>)}</div>;
}

function MiniList({ role, type = "people" }: { role: RoleKey; type?: "people" | "cards" | "messages" | "menu" }) {
  if (type === "menu") return <div className="mini-menu">{["My Profile", role === "organizer" ? "My Events" : "My Training Programs", role === "scout" ? "Shortlisted Talents" : "My Opportunities", "My Analytics", "Saved", "Notifications", "Messages", "Settings & Privacy"].map((x, i) => <div key={x}><Icon name={["user","calendar","trophy","chart","bookmark","bell","message","settings"][i] as IconName} size={11}/><span>{x}</span><Icon name="chevron" size={9}/></div>)}</div>;
  if (type === "messages") return <div className="mini-rows">{miniPeople.concat(["Dev Mehta","Coach Rohan"]).map((name, i) => <div className="mini-person" key={name}><img src={people[i%4].img} alt=""/><p><strong>{name}</strong><span>{i%2 ? "Thanks for the update!" : "When does the next batch start?"}</span></p><small>{i<2 ? "10:30" : "1d"}</small></div>)}</div>;
  if (type === "cards") return <div className="mini-card-list">{miniPeople.map((name, i) => <div key={name}><img src={i%2 ? photos.football : photos.cricket} alt=""/><p><strong>{role === "organizer" ? ["Youth Football Championship","Inter Academy Cricket Cup","State Badminton Tournament","Ahmedabad Marathon"][i] : role === "scout" ? ["Open U-16 Cricket Trials","Football Selection Camp","State Athletics Trials","Badminton Camp"][i] : ["Beginner Cricket Program","Advanced Batting Training","Weekend Cricket Camp","High Performance Program"][i]}</strong><span>Ahmedabad · Gujarat</span><b>View Details</b></p></div>)}</div>;
  return <div className="mini-rows">{miniPeople.map((name, i) => <div className="mini-person" key={name}><img src={people[i].img} alt=""/><p><strong>{name}</strong><span>{people[i].role}</span></p><b>Follow</b></div>)}</div>;
}

function MiniScreen({ role, name, index, onOpen }: { role: RoleKey; name: string; index: number; onOpen: () => void }) {
  const info = roleShowcase[role];
  const lower = name.toLowerCase();
  const isMain = index < 5;
  const headerTitle = isMain ? (name === "Create" || name === "Community" || name === "More" ? name : undefined) : name;
  return <Tap className="showcase-card" onClick={onOpen}>
    <div className="screen-number">{index + 1}. {name} <span>({info.title})</span></div>
    <div className={`mini-phone ${info.accent}`}>
      <MiniHeader title={headerTitle}/>
      <div className="mini-body">
        {name === "Home" && <><div className="mini-greet"><img src={people[index].img} alt=""/><p><span>Good morning,</span><strong>{info.subtitle}</strong><small>Complete your profile</small><i/></p><b>80%</b></div><div className="mini-section"><strong>{role === "organizer" ? "Upcoming Events" : role === "scout" ? "Top Talents This Week" : "Leaderboard"}</strong><span>View all ›</span></div><div className="mini-ranks">{[0,1,2].map(i => <div key={i}><b>{i+1}</b><img src={people[i].img} alt=""/><span>{miniPeople[i]}</span></div>)}</div><div className="mini-quick"><div><Icon name="trophy" size={14}/><strong>Opportunities</strong></div><div><Icon name="academy" size={14}/><strong>{role === "scout" ? "Find Talent" : "My Programs"}</strong></div></div><div className="mini-section"><strong>For you</strong><span>Following</span></div><div className="mini-feed"><p><span className="mini-avatar"/><strong>{info.subtitle}</strong></p><img src={role === "academy" ? photos.cricket : photos.football} alt=""/></div></>}
        {name === "Explore" && <><div className="mini-search"><Icon name="search" size={10}/>Search athletes, coaches, academies...</div><div className="mini-chips"><b>All Sports</b><span>Cricket</span><span>Football</span></div><div className="mini-tabs"><span>Athletes</span><span>Coaches</span><b>{role === "organizer" ? "Events" : "Academies"}</b></div><MiniList role={role} type={role === "organizer" ? "cards" : "people"}/></>}
        {name === "Create" && <div className="mini-create">{createItems.slice(0,7).map((item,i) => <div key={item.title}><i className={item.color}><Icon name={item.icon} size={11}/></i><p><strong>{role === "scout" && i === 0 ? "Add Talent Shortlist" : item.title}</strong><span>{item.sub}</span></p></div>)}</div>}
        {name === "Community" && <><div className="mini-tabs"><b>Network</b><span>Groups</span><span>Events</span></div><div className="mini-search"><Icon name="search" size={10}/>Search people, groups...</div><div className="mini-section"><strong>Suggested for you</strong></div><MiniList role={role}/><div className="mini-section"><strong>Join Groups</strong><span>See all</span></div></>}
        {name === "More" && <><div className="mini-profile"><img src={people[2].img} alt=""/><p><strong>{info.subtitle}</strong><span>{info.title}</span><b>View Profile ›</b></p></div><MiniList role={role} type="menu"/></>}
        {!isMain && lower.includes("profile") && <><div className="mini-profile-hero"><img src={role === "organizer" ? photos.football : photos.cricket} alt=""/><span><img src={people[2].img} alt=""/></span></div><div className="mini-profile-title"><strong>{info.subtitle} ✓</strong><span>Ahmedabad · Gujarat</span><b>Edit Profile</b></div><div className="mini-tabs"><b>About</b><span>Programs</span><span>Activity</span></div><div className="mini-about"><strong>About</strong><p>Professional sports profile with verified experience and achievements.</p>{["Experience","Specialization","Languages","Members"].map(x=><span key={x}>{x}<b>Verified</b></span>)}</div></>}
        {!isMain && (lower.includes("program") || lower.includes("event") || lower.includes("facilities") || lower.includes("opportunities")) && <><div className="mini-tabs"><b>Active</b><span>Drafts</span><span>Past</span></div><div className="mini-add">＋ Add {lower.includes("event") ? "Event" : lower.includes("facilities") ? "Facility" : "Program"}</div><MiniList role={role} type="cards"/></>}
        {!isMain && (lower.includes("messages")) && <><div className="mini-tabs"><b>Chats</b><span>Requests</span></div><div className="mini-search"><Icon name="search" size={10}/>Search messages...</div><MiniList role={role} type="messages"/></>}
        {!isMain && (lower.includes("notification")) && <><div className="mini-tabs"><b>All</b><span>Opportunities</span><span>System</span></div><MiniList role={role} type="messages"/></>}
        {!isMain && !lower.includes("profile") && !lower.includes("program") && !lower.includes("event") && !lower.includes("facilities") && !lower.includes("opportunities") && !lower.includes("messages") && !lower.includes("notification") && <><div className="mini-search"><Icon name="search" size={10}/>Search {name.toLowerCase()}...</div><div className="mini-chips"><b>All</b><span>Cricket</span><span>Football</span></div><MiniList role={role} type={lower.includes("analytics") || lower.includes("report") ? "cards" : "people"}/></>}
      </div>
      <MiniNav active={Math.min(index,4)}/>
    </div>
  </Tap>;
}

function Showcase({ onOpen }: { onOpen: () => void }) {
  return <div className="showcase">
    <div className="showcase-hero"><div><Logo/><span>Product prototype</span></div><div className="showcase-title">Every role. Every screen.<br/><em>One connected sports ecosystem.</em></div><p>Browse the complete SportX mobile experience role by role. Select any screen to open the clickable prototype.</p><Primary onClick={onOpen}>Open clickable prototype <Icon name="chevron" size={17}/></Primary></div>
    {(Object.keys(roleShowcase) as RoleKey[]).map((role) => {
      const info = roleShowcase[role];
      return <section className={`role-section ${info.accent}`} key={role}><div className="role-heading"><div className="role-mark"><Icon name={role === "academy" ? "academy" : role === "organizer" ? "calendar" : role === "scout" ? "search" : "user"}/></div><div><span>SPORTX FOR</span><div className="role-title">{info.title}</div><p>{info.screens.length} connected mobile screens</p></div><div className="scroll-hint">Scroll to explore <Icon name="chevron" size={15}/></div></div><div className="screen-row">{info.screens.map((name,index) => <MiniScreen key={name} role={role} name={name} index={index} onOpen={onOpen}/>)}</div></section>;
    })}
  </div>;
}

export default function App() {
  const [prototype, setPrototype] = useState(false);
  return prototype ? <SportXPrototype onExit={() => setPrototype(false)}/> : <Showcase onOpen={() => setPrototype(true)}/>;
}
