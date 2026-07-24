import React, { useState, type ReactNode, type CSSProperties } from 'react'

// ─── Navigation Context Helper ────────────────────────────────────────────────
export type NavFn = (screen: string, params?: Record<string, unknown>) => void

// ─── App Bar ─────────────────────────────────────────────────────────────────
interface AppBarProps {
  title?: string
  onBack?: () => void
  logoLeft?: boolean
  rightActions?: ReactNode
}
export function AppBar({ title, onBack, logoLeft, rightActions }: AppBarProps) {
  return (
    <div className="flex items-center h-14 glass-header px-4 flex-shrink-0 z-20 sticky top-0">
      {onBack ? (
        <button onClick={onBack} className="w-10 h-10 flex items-center justify-center -ml-2 text-gray-900">
          <svg width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        </button>
      ) : logoLeft ? (
        <div className="flex items-center gap-1.5">
          <div className="w-7 h-7 rounded-lg bg-blue-600 flex items-center justify-center">
            <span className="text-white text-xs font-bold">SX</span>
          </div>
          <span className="text-base font-semibold text-gray-900">SportX India</span>
        </div>
      ) : (
        <div className="w-10" />
      )}
      {title ? (
        <span className="flex-1 text-center text-lg font-semibold text-gray-900 truncate px-2">
          {logoLeft ? '' : title}
        </span>
      ) : (
        <div className="flex-1" />
      )}
      <div className="flex items-center gap-1 -mr-1">
        {rightActions || <div className="w-10" />}
      </div>
    </div>
  )
}

// ─── Icon Button ─────────────────────────────────────────────────────────────
export function IconBtn({ icon, onClick, active }: { icon: ReactNode; onClick?: () => void; active?: boolean }) {
  return (
    <button
      onClick={onClick}
      className={`w-10 h-10 rounded-full flex items-center justify-center border ${
        active ? 'bg-blue-50 border-blue-600 text-blue-600' : 'bg-slate-50 border-gray-200 text-gray-500'
      }`}
    >
      {icon}
    </button>
  )
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────
interface BottomNavProps {
  role: 'athlete' | 'coach' | 'sponsor' | 'admin'
  active: string
  onTab: (tab: string) => void
  onFab?: () => void
}
export function BottomNav({ role, active, onTab, onFab }: BottomNavProps) {
  const athleteTabs = [
    { id: 'home', label: 'Home', icon: HomeIcon },
    { id: 'discover', label: 'Discover', icon: SearchIcon },
    { id: 'create', label: '', icon: null, fab: true },
    { id: 'messages', label: 'Messages', icon: MessageIcon },
    { id: 'profile', label: 'Profile', icon: UserIcon },
  ]
  const coachTabs = [
    { id: 'home', label: 'Home', icon: HomeIcon },
    { id: 'discover', label: 'Discover', icon: SearchIcon },
    { id: 'notifications', label: 'Notifications', icon: BellIcon },
    { id: 'profile', label: 'Profile', icon: UserIcon },
  ]
  const sponsorTabs = [
    { id: 'home', label: 'Home', icon: HomeIcon },
    { id: 'discover', label: 'Discover', icon: SearchIcon },
    { id: 'postopp', label: 'Post Opp', icon: StarIcon },
    { id: 'profile', label: 'Profile', icon: UserIcon },
  ]

  const tabs = role === 'athlete' ? athleteTabs : role === 'coach' ? coachTabs : sponsorTabs

  return (
    <div className="flex-shrink-0 glass-nav h-16 flex items-end pb-1 relative z-20">
      {tabs.map((tab: { id: string; label: string; icon: null | ((p: IconProps) => React.ReactElement); fab?: boolean }) => {
        if (tab.fab) return null;
        
        const isActive = active === tab.id
        const Icon = tab.icon!
        return (
          <button
            key={tab.id}
            onClick={() => onTab(tab.id)}
            className="flex-1 flex flex-col items-center justify-end pb-1 gap-0.5 h-full pt-1"
          >
            <Icon size={24} color={isActive ? '#2563EB' : '#9CA3AF'} />
            <span className="text-[10px] font-semibold" style={{ color: isActive ? '#2563EB' : '#9CA3AF' }}>{tab.label}</span>
            {isActive && <div className="w-1.5 h-1.5 rounded-full bg-blue-600 mt-0.5" />}
          </button>
        )
      })}
      
      {tabs.some(t => t.fab) && (
        <button
          onClick={onFab}
          className="absolute right-4 -top-16 w-14 h-14 rounded-full bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center shadow-lg z-50 hover:opacity-90 active:scale-95 transition-all"
          style={{ boxShadow: '0 4px 12px rgba(249,115,22,0.4)' }}
        >
          <svg width="24" height="24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>
        </button>
      )}
    </div>
  )
}

// ─── Buttons ─────────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export interface BtnProps { children?: ReactNode; label?: string; onClick?: (e?: any) => void; disabled?: boolean; className?: string; full?: boolean }

export function PrimaryBtn({ children, label, onClick, disabled, full, className }: BtnProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`h-12 rounded-full text-white text-sm font-semibold flex items-center justify-center transition-all duration-300 ${full ? 'w-full' : 'px-6'} ${
        disabled ? 'bg-blue-300 cursor-not-allowed' : 'bg-blue-600 active:scale-95 hover:bg-blue-700 premium-btn-shadow'
      } ${className || ''}`}
    >
      {label ?? children}
    </button>
  )
}

export function CTABtn({ children, label, onClick, disabled, full, className }: BtnProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`h-12 rounded-full text-white text-sm font-semibold flex items-center justify-center transition-all duration-300 ${full ? 'w-full' : 'px-6'} ${
        disabled ? 'bg-orange-200 cursor-not-allowed' : 'bg-orange-500 active:scale-95 hover:bg-orange-600'
      } ${className || ''}`}
      style={{ boxShadow: disabled ? 'none' : '0 8px 16px -4px rgba(249,115,22,0.30)' }}
    >
      {label ?? children}
    </button>
  )
}

export function SecondaryBtn({ children, label, onClick, disabled, full, className }: BtnProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`h-12 rounded-full text-sm font-semibold flex items-center justify-center border-2 transition-all ${full ? 'w-full' : 'px-6'} ${
        disabled ? 'border-blue-300 text-blue-300 cursor-not-allowed' : 'border-blue-600 text-blue-600 hover:bg-blue-50 active:scale-95'
      } ${className || ''}`}
    >
      {label ?? children}
    </button>
  )
}

export function GhostBtn({ children, label, onClick, className }: BtnProps) {
  return (
    <button onClick={onClick} className={`text-sm font-semibold text-blue-600 px-2 py-1 active:opacity-70 ${className || ''}`}>
      {label ?? children}
    </button>
  )
}

export function DangerBtn({ children, label, onClick, full, className }: BtnProps) {
  return (
    <button
      onClick={onClick}
      className={`h-12 rounded-xl text-sm font-semibold flex items-center justify-center border border-red-500 text-red-500 active:bg-red-50 transition-all ${full ? 'w-full' : 'px-6'} ${className || ''}`}
    >
      {label ?? children}
    </button>
  )
}

export function SuccessBtn({ children, label, onClick, full, className }: BtnProps) {
  return (
    <button
      onClick={onClick}
      className={`h-12 rounded-xl text-white text-sm font-semibold flex items-center justify-center bg-green-500 active:scale-95 transition-all ${full ? 'w-full' : 'px-6'} ${className || ''}`}
    >
      {label ?? children}
    </button>
  )
}

// ─── Input Fields ─────────────────────────────────────────────────────────────
// onChange accepts string (preferred) or raw event (for compatibility with screens using e.target.value pattern)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
interface InputProps { label?: string; placeholder?: string; type?: string; value?: string; onChange?: (v: any) => void; error?: string; disabled?: boolean; trailing?: ReactNode; leading?: ReactNode }

export function InputField({ label, placeholder, type = 'text', value, onChange, error, disabled, trailing, leading }: InputProps) {
  const [focused, setFocused] = useState(false)
  return (
    <div className="flex flex-col gap-1.5">
      {label && <label className="text-xs font-semibold text-gray-600 ml-1">{label}</label>}
      <div className={`flex items-center rounded-2xl border px-4 gap-2 transition-all duration-200 ${focused ? 'border-blue-600 ring-4 ring-blue-50 bg-white' : error ? 'border-red-500 bg-red-50' : disabled ? 'bg-gray-50 border-gray-100' : 'bg-slate-50 border-gray-200 hover:border-gray-300'}`} style={{ height: 52 }}>
        {leading && <span className="text-gray-400">{leading}</span>}
        <input
          type={type}
          placeholder={placeholder}
          value={value}
          onChange={e => onChange?.(e.target.value)}
          disabled={disabled}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          className="flex-1 bg-transparent outline-none text-sm text-gray-900 placeholder-gray-400 font-[Poppins]"
        />
        {trailing && <span className="text-gray-400 cursor-pointer">{trailing}</span>}
      </div>
      {error && <span className="text-xs text-red-500 flex items-center gap-1">⚠ {error}</span>}
    </div>
  )
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function TextArea({ label, placeholder, value, onChange, rows = 4 }: { label?: string; placeholder?: string; value?: string; onChange?: (v: any) => void; rows?: number }) {
  const [focused, setFocused] = useState(false)
  const maxLen = 300
  return (
    <div className="flex flex-col gap-1">
      {label && <label className="text-xs font-semibold text-gray-500">{label}</label>}
      <div className="relative">
        <textarea
          placeholder={placeholder}
          value={value || ''}
          onChange={e => onChange?.(e.target.value)}
          rows={rows}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          className={`w-full rounded-xl border px-4 py-3 text-sm text-gray-900 placeholder-gray-400 outline-none resize-none transition-all ${focused ? 'border-2 border-blue-600 bg-white' : 'bg-slate-50 border-gray-200'}`}
        />
        <span className="absolute bottom-2 right-3 text-xs text-gray-400">{(value || '').length}/{maxLen}</span>
      </div>
    </div>
  )
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function SearchBar({ placeholder, value, onChange, onSearch }: { placeholder?: string; value?: string; onChange?: (v: string) => void; onSearch?: () => void; [k: string]: any }) {
  const [focused, setFocused] = useState(false)
  return (
    <div className={`flex items-center h-12 rounded-xl border px-4 gap-2 transition-all ${focused ? 'border-2 border-blue-600 bg-white' : 'bg-slate-50 border-gray-200'}`}>
      <SearchIcon size={20} color="#6B7280" />
      <input
        placeholder={placeholder || 'Search...'}
        value={value || ''}
        onChange={e => onChange?.(e.target.value)}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        className="flex-1 bg-transparent outline-none text-sm text-gray-900 placeholder-gray-400"
      />
      {value && <button onClick={() => onChange?.('')} className="text-gray-400 text-sm">✕</button>}
    </div>
  )
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function SelectField({ label, placeholder, value, onChange, options }: { label?: string; placeholder?: string; value?: string; onChange?: (v: any) => void; options?: string[] }) {
  return (
    <div className="flex flex-col gap-1">
      {label && <label className="text-xs font-semibold text-gray-500">{label}</label>}
      <div className="flex items-center h-13 rounded-xl border px-4 gap-2 bg-slate-50 border-gray-200" style={{ height: 52 }}>
        <select
          value={value || ''}
          onChange={e => onChange?.(e.target.value)}
          className="flex-1 bg-transparent outline-none text-sm text-gray-900 appearance-none"
        >
          {placeholder && <option value="">{placeholder}</option>}
          {options?.map(o => <option key={o} value={o}>{o}</option>)}
        </select>
        <ChevronDownIcon size={16} color="#6B7280" />
      </div>
    </div>
  )
}

// ─── OTP Input ────────────────────────────────────────────────────────────────
export function OTPInput({ value }: { value: string; onChange?: (v: string) => void }) {
  const digits = value.split('').slice(0, 4)
  while (digits.length < 4) digits.push('')
  return (
    <div className="flex gap-3 justify-center">
      {digits.map((d, i) => (
        <div
          key={i}
          className={`w-13 h-15 rounded-xl border-2 flex items-center justify-center text-2xl font-bold text-gray-900 ${d ? 'border-blue-600 bg-white' : 'border-gray-200 bg-slate-50'}`}
          style={{ width: 52, height: 60 }}
        >
          {d}
        </div>
      ))}
    </div>
  )
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
interface AvatarProps { size?: number; name?: string; src?: string; storyRing?: boolean; hasStory?: boolean; verified?: boolean; addStory?: boolean }
export function Avatar({ size = 40, name = '?', src, storyRing, hasStory, verified, addStory }: AvatarProps) {
  const initial = name.charAt(0).toUpperCase()
  const ring = storyRing ? (hasStory ? '2.5px solid #2563EB' : '2.5px solid #E5E7EB') : undefined
  return (
    <div className="relative flex-shrink-0" style={{ width: size, height: size }}>
      {src ? (
        <img src={src} alt={name} className="rounded-full object-cover" style={{ width: size, height: size, outline: ring, outlineOffset: 2 }} />
      ) : (
        <div
          className="rounded-full bg-blue-600 flex items-center justify-center text-white font-semibold"
          style={{ width: size, height: size, fontSize: size * 0.38, outline: ring, outlineOffset: 2 }}
        >
          {initial}
        </div>
      )}
      {addStory && (
        <div className="absolute bottom-0 right-0 w-5 h-5 rounded-full bg-blue-600 border-2 border-white flex items-center justify-center">
          <span className="text-white text-xs font-bold leading-none">+</span>
        </div>
      )}
      {verified && (
        <div className="absolute bottom-0 right-0 w-5 h-5 rounded-full bg-green-500 border-2 border-white flex items-center justify-center">
          <span className="text-white text-xs leading-none">✓</span>
        </div>
      )}
    </div>
  )
}

// ─── Badges & Tags ────────────────────────────────────────────────────────────
export function SportBadge({ sport }: { sport: string }) {
  return <span className="text-[11px] font-semibold text-blue-600 bg-blue-50 px-2 py-0.5 rounded-md">{sport}</span>
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function VerifiedBadge(_props?: { label?: string; [k: string]: any }) {
  return <span className="text-green-500 text-sm ml-1">✓</span>
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function StatusDot({ status }: { status: 'open' | 'pending' | 'closed' | 'live' | 'rejected'; [k: string]: any }) {
  const map = {
    open: { color: '#22C55E', label: 'Open' },
    live: { color: '#22C55E', label: 'Live' },
    pending: { color: '#F59E0B', label: 'Pending' },
    closed: { color: '#EF4444', label: 'Closed' },
    rejected: { color: '#EF4444', label: 'Rejected' },
  }
  const { color, label } = map[status]
  return (
    <span className="flex items-center gap-1 text-xs">
      <span className="rounded-full w-2 h-2 flex-shrink-0" style={{ backgroundColor: status === 'pending' ? 'transparent' : color, border: status === 'pending' ? '1.5px solid ' + color : undefined }} />
      <span style={{ color }}>{label}</span>
    </span>
  )
}

// ─── Tab Pills ────────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function TabPills({ tabs, active, onSelect, onTab, onChange }: { tabs: string[]; active: string; onSelect?: (t: string) => void; onTab?: (t: string) => void; onChange?: (t: string) => void; [k: string]: any }) {
  const handler = onSelect ?? onTab ?? onChange ?? (() => {})
  return (
    <div className="flex gap-2 overflow-x-auto px-4 flex-shrink-0" style={{ scrollbarWidth: 'none' }}>
      {tabs.map(tab => (
        <button
          key={tab}
          onClick={() => handler(tab)}
          className={`flex-shrink-0 h-[34px] px-4 rounded-full text-xs font-semibold transition-all ${
            active === tab ? 'bg-blue-600 text-white' : 'bg-slate-50 text-gray-500'
          }`}
        >
          {tab}
        </button>
      ))}
    </div>
  )
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────
export function FilterChip({ label, active, onRemove, onClick }: { label: string; active?: boolean; onRemove?: () => void; onClick?: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold flex-shrink-0 border transition-all ${
        active ? 'bg-blue-50 border-blue-600 text-blue-600' : 'bg-slate-50 border-gray-200 text-gray-500'
      }`}
    >
      {label}
      {active && onRemove && (
        <span onClick={e => { e.stopPropagation(); onRemove() }} className="ml-0.5 text-blue-600">×</span>
      )}
      {!active && <ChevronDownIcon size={12} color="#6B7280" />}
    </button>
  )
}

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────
export function FilterBottomSheet({ title, options, selected, onClose, onSelect }: { title: string; options: string[]; selected?: string; onClose: () => void; onSelect: (v: string) => void }) {
  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-white rounded-t-3xl pt-2 pb-8 px-4 flex flex-col animate-slide-up">
        <div className="w-12 h-1.5 bg-gray-200 rounded-full mx-auto mb-4 mt-1" />
        <div className="flex items-center justify-between px-2 mb-4">
          <h3 className="text-lg font-bold text-gray-900">{title}</h3>
          <button onClick={onClose} className="text-gray-400 font-bold text-xl">×</button>
        </div>
        <div className="flex-1 overflow-y-auto max-h-[50vh]">
          {options.map((opt) => (
            <div 
              key={opt}
              onClick={() => {
                onSelect(opt === selected ? '' : opt)
                onClose()
              }}
              className="flex items-center justify-between p-3 border-b border-gray-100 cursor-pointer hover:bg-slate-50"
            >
              <span className={`text-base font-medium ${opt === selected ? 'text-blue-600' : 'text-gray-700'}`}>{opt}</span>
              {opt === selected && <span className="text-blue-600 font-bold">✓</span>}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

// ─── Section Label ────────────────────────────────────────────────────────────
export function SectionLabel({ children, label }: { children?: ReactNode; label?: string }) {
  return <p className="text-xs font-semibold text-gray-500 uppercase tracking-widest mb-3 mt-1">{label ?? children}</p>
}

// ─── Divider ─────────────────────────────────────────────────────────────────
export function Divider({ inset }: { inset?: boolean }) {
  return <div className={`h-px bg-gray-200 ${inset ? 'ml-4' : ''} my-3`} />
}

// ─── Empty State ──────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function EmptyState({ icon, title, subtitle, description, cta, onCta }: { icon?: ReactNode; title: string; subtitle?: string; description?: string; cta?: string; onCta?: () => void; [k: string]: any }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 px-8 py-12 text-center">
      <div className="text-5xl text-gray-300">{icon || '📭'}</div>
      <p className="text-base font-semibold text-gray-900">{title}</p>
      <p className="text-sm text-gray-500 leading-relaxed">{subtitle ?? description}</p>
      {cta && <CTABtn onClick={onCta}>{cta}</CTABtn>}
    </div>
  )
}

// ─── Card Wrapper ─────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function Card({ children, className, onClick, style }: { children: ReactNode; className?: string; onClick?: () => void; style?: CSSProperties; [k: string]: any }) {
  return (
    <div
      onClick={onClick}
      className={`bg-white rounded-2xl border border-gray-100 p-5 premium-shadow ${onClick ? 'cursor-pointer hover:-translate-y-0.5 hover:shadow-md active:scale-[0.99] transition-all duration-300' : ''} ${className || ''}`}
      style={style}
    >
      {children}
    </div>
  )
}

// ─── Stories Row ─────────────────────────────────────────────────────────────
const STORY_USERS = [
  { name: 'Rohan', viewed: false },
  { name: 'Priya', viewed: true },
  { name: 'Arjun', viewed: false },
  { name: 'Sneha', viewed: true },
  { name: 'Vikram', viewed: false },
]
export function StoriesRow({ onAddStory }: { onAddStory?: () => void }) {
  return (
    <div className="flex gap-3 overflow-x-auto px-4 py-3 flex-shrink-0" style={{ scrollbarWidth: 'none' }}>
      <div className="flex flex-col items-center gap-1 cursor-pointer" onClick={onAddStory}>
        <Avatar size={64} name="You" addStory storyRing hasStory />
        <span className="text-[10px] text-gray-500 w-16 text-center truncate">Your Story</span>
      </div>
      {STORY_USERS.map(u => (
        <div key={u.name} className="flex flex-col items-center gap-1 cursor-pointer">
          <Avatar size={64} name={u.name} storyRing hasStory={!u.viewed} />
          <span className="text-[10px] text-gray-500 w-16 text-center truncate">{u.name}</span>
        </div>
      ))}
    </div>
  )
}

// ─── Post Card ────────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
interface PostCardProps { name?: string; authorName?: string; sport?: string; time?: string; timeAgo?: string; caption?: string; content?: string; authorRole?: string; author?: { name: string; sport: string; verified?: boolean }; likes?: number; comments?: number; hasImage?: boolean; onClick?: () => void; navigate?: NavFn; timestamp?: string; [k: string]: any }
export function PostCard({ name, authorName, sport, time, timeAgo, caption, content, likes = 0, comments = 0, hasImage = true, onClick, author }: PostCardProps) {
  const displayName = name ?? authorName ?? author?.name ?? 'Unknown'
  const displaySport = sport ?? author?.sport ?? ''
  const displayTime = time ?? timeAgo ?? ''
  const displayCaption = caption ?? content ?? ''
  const [liked, setLiked] = useState(false)
  const [showShare, setShowShare] = useState(false)
  const [showComment, setShowComment] = useState(false)
  return (
    <div className="bg-white p-4 border-b border-gray-100">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-2">
          <Avatar size={40} name={displayName} />
          <div>
            <div className="flex items-center gap-1.5">
              <span className="text-sm font-semibold text-gray-900">{displayName}</span>
              <SportBadge sport={displaySport} />
            </div>
            <span className="text-xs text-gray-500">{displayTime}</span>
          </div>
        </div>
        <button className="text-gray-400 p-1">
          <svg width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/></svg>
        </button>
      </div>
      <p className="text-sm text-gray-900 mb-3 leading-relaxed">
        {displayCaption} <span className="text-blue-600">#sports #training</span>
      </p>
      {hasImage && (
        <div
          className="rounded-xl mb-3 flex items-center justify-center text-gray-300 overflow-hidden"
          style={{ aspectRatio: '16/9', background: 'linear-gradient(135deg, #EFF6FF, #DBEAFE)' }}
          onClick={onClick}
        >
          <svg width="48" height="48" fill="none" stroke="#93C5FD" strokeWidth="1.5" viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
        </div>
      )}
      <div className="flex items-center gap-5">
        <button className="flex items-center gap-1.5 text-sm text-gray-500" onClick={() => setLiked(!liked)}>
          <svg width="20" height="20" fill={liked ? '#EF4444' : 'none'} stroke={liked ? '#EF4444' : 'currentColor'} strokeWidth="2" viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
          {likes + (liked ? 1 : 0)}
        </button>
        <button className="flex items-center gap-1.5 text-sm text-gray-500" onClick={(e) => { e.stopPropagation(); setShowComment(true); }}>
          <MessageIcon size={20} color="#6B7280" />
          {comments}
        </button>
        <button className="flex items-center gap-1.5 text-sm text-gray-500" onClick={(e) => { e.stopPropagation(); setShowShare(true); }}>
          <ShareIcon size={20} color="#6B7280" />
          Share
        </button>
      </div>

      {/* Share Bottomsheet */}
      {showShare && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowShare(false)} />
          <div className="relative bg-white rounded-t-3xl pt-2 pb-8 px-4 flex flex-col gap-4 animate-slide-up">
            <div className="w-12 h-1.5 bg-gray-200 rounded-full mx-auto mb-2" />
            <h3 className="text-lg font-bold text-gray-900 text-center">Share this post</h3>
            <div className="flex justify-around mt-2">
              {[
                { label: 'Copy Link', icon: '🔗' },
                { label: 'WhatsApp', icon: '💬' },
                { label: 'Twitter', icon: '🐦' },
                { label: 'Messages', icon: '✉️' },
              ].map((app) => (
                <div key={app.label} className="flex flex-col items-center gap-2 cursor-pointer">
                  <div className="w-14 h-14 bg-gray-100 rounded-full flex items-center justify-center text-2xl">
                    {app.icon}
                  </div>
                  <span className="text-xs text-gray-600 font-medium">{app.label}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Comment Bottomsheet */}
      {showComment && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowComment(false)} />
          <div className="relative bg-white rounded-t-3xl h-[60vh] flex flex-col animate-slide-up">
            <div className="w-12 h-1.5 bg-gray-200 rounded-full mx-auto mt-3" />
            <div className="flex items-center justify-between px-4 pb-3 pt-3 border-b border-gray-100">
              <h3 className="text-lg font-bold text-gray-900">Comments</h3>
              <button onClick={() => setShowComment(false)} className="text-gray-400 font-bold text-xl">×</button>
            </div>
            
            <div className="flex-1 overflow-y-auto px-4 py-4">
              <div className="flex gap-3 mb-5">
                <Avatar size={32} name="Sana S" />
                <div>
                  <p className="text-sm font-semibold text-gray-900">Sana S</p>
                  <p className="text-sm text-gray-600">Great insights! Keep it up 🔥</p>
                  <p className="text-xs text-gray-400 mt-1">2h ago</p>
                </div>
              </div>
              <div className="flex gap-3 mb-5">
                <Avatar size={32} name="Arjun P" />
                <div>
                  <p className="text-sm font-semibold text-gray-900">Arjun P</p>
                  <p className="text-sm text-gray-600">Totally agree with this.</p>
                  <p className="text-xs text-gray-400 mt-1">5h ago</p>
                </div>
              </div>
            </div>

            <div className="border-t border-gray-100 p-3 flex gap-2 items-center bg-gray-50">
              <Avatar size={36} name="Current User" />
              <input 
                type="text" 
                placeholder="Add a comment..." 
                className="flex-1 bg-white border border-gray-200 rounded-full px-4 py-2 text-sm outline-none" 
              />
              <button className="text-blue-600 font-semibold px-2">Post</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

// ─── Athlete Card ─────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function AthleteCard({ name, sport, city, location, level, achievements, connected, onConnect, onView, saveMode, age }: {
  name: string; sport: string; city?: string; location?: string; level?: string; achievements?: number; connected?: boolean; onConnect?: () => void; onView?: () => void; saveMode?: boolean; age?: number; [k: string]: any
}) {
  const displayCity = city ?? location ?? ''
  const displayLevel = level ?? (age ? `Age ${age}` : '')
  const [saved, setSaved] = useState(false)
  
  return (
    <Card className="mb-0">
      {/* Banner */}
      <div className="h-16 bg-gradient-to-r from-slate-200 to-slate-300 relative">
        <div className="absolute -bottom-6 left-4 rounded-full border-2 border-white bg-white">
          <Avatar size={56} name={name} />
        </div>
      </div>
      
      {/* Content */}
      <div className="px-4 pt-8 pb-4">
        <div className="flex items-start justify-between mb-0.5">
          <div className="flex items-center gap-1.5 flex-1 min-w-0">
            <span className="text-base font-bold text-gray-900 truncate">{name}</span>
            <VerifiedBadge />
          </div>
          {saveMode && (
            <button onClick={() => setSaved(!saved)} className={`text-xl leading-none ${saved ? 'text-orange-500' : 'text-gray-300 hover:text-gray-400'}`}>
              {saved ? '★' : '☆'}
            </button>
          )}
        </div>
        
        <p className="text-sm text-gray-700 font-medium mb-1 truncate">{sport}</p>
        <p className="text-xs text-gray-500 mb-2 truncate">{displayCity}{displayCity && displayLevel ? ' • ' : ''}{displayLevel}</p>
        
        {achievements ? (
          <p className="text-xs text-gray-500 flex items-center gap-1.5 mb-4">
            <span className="text-orange-500">🏆</span> {achievements} achievements
          </p>
        ) : (
          <div className="mb-4" />
        )}
        
        <div className="flex gap-2">
          {saveMode ? (
            <PrimaryBtn full onClick={onView}>View Profile</PrimaryBtn>
          ) : (
            <>
              {connected ? (
                <>
                  <PrimaryBtn full onClick={onView}>Message</PrimaryBtn>
                  <SecondaryBtn full onClick={onView}>View Profile</SecondaryBtn>
                </>
              ) : (
                <PrimaryBtn full onClick={onConnect}>Connect</PrimaryBtn>
              )}
            </>
          )}
        </div>
      </div>
    </Card>
  )
}

// ─── Academy Card ─────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function AcademyCard({ name, sport, city, location, athletes, programs, onView }: { name: string; sport: string; city?: string; location?: string; athletes?: number; programs?: number; onView?: () => void; [k: string]: any }) {
  const displayCity = city ?? location ?? ''
  return (
    <Card className="mb-0">
      <div className="h-16 bg-gradient-to-r from-slate-200 to-slate-300 relative">
        <div className="absolute -bottom-6 left-4 rounded-full border-2 border-white bg-white">
          <Avatar size={56} name={name} />
        </div>
      </div>
      <div className="px-4 pt-8 pb-4">
        <div className="flex items-start justify-between mb-0.5">
          <div className="flex items-center gap-1.5 flex-1 min-w-0">
            <span className="text-base font-bold text-gray-900 truncate">{name}</span>
            <VerifiedBadge />
          </div>
        </div>
        <p className="text-sm text-gray-700 font-medium mb-1 truncate">{sport}</p>
        <p className="text-xs text-gray-500 mb-2 truncate">{displayCity}</p>
        
        <p className="text-xs text-gray-500 mb-4 truncate">
          {athletes ? `${athletes} athletes` : ''}{athletes && programs ? ' • ' : ''}{programs ? `${programs} programs` : ''}
        </p>
        
        <div className="flex gap-2">
          <PrimaryBtn full onClick={onView}>View Profile</PrimaryBtn>
        </div>
      </div>
    </Card>
  )
}

// ─── Sponsor Card ─────────────────────────────────────────────────────────────
export function SponsorCard({ name, industry, location, opportunities, onView }: { name: string; industry: string; location: string; opportunities: number; onView?: () => void }) {
  return (
    <Card className="mb-0">
      <div className="h-16 bg-gradient-to-r from-slate-200 to-slate-300 relative">
        <div className="absolute -bottom-6 left-4 rounded-full border-2 border-white bg-white">
          <Avatar size={56} name={name} />
        </div>
      </div>
      <div className="px-4 pt-8 pb-4">
        <div className="flex items-start justify-between mb-0.5">
          <div className="flex items-center gap-1.5 flex-1 min-w-0">
            <span className="text-base font-bold text-gray-900 truncate">{name}</span>
            <VerifiedBadge />
          </div>
        </div>
        <p className="text-sm text-gray-700 font-medium mb-1 truncate">{industry}</p>
        <p className="text-xs text-gray-500 mb-2 truncate">{location}</p>
        
        <p className="text-xs text-gray-500 mb-4 truncate">
          {opportunities} Active Opportunities
        </p>
        
        <div className="flex gap-2">
          <PrimaryBtn full onClick={onView}>View Profile</PrimaryBtn>
        </div>
      </div>
    </Card>
  )
}

// ─── Opportunity Card ─────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function OpportunityCard({ title, org, sport, region, deadline, onApply, onView }: {
  title: string; org: string; sport: string; region: string; deadline?: string; onApply?: () => void; onView?: () => void; [k: string]: any
}) {
  return (
    <Card onClick={onView}>
      <div className="flex items-start gap-3 mb-3">
        <Avatar size={40} name={org} />
        <div className="flex-1 min-w-0">
          <p className="text-base font-semibold text-gray-900 leading-tight">{title}</p>
          <p className="text-xs text-gray-500">{org}</p>
        </div>
      </div>
      <div className="text-xs text-gray-500 mb-3">{sport} · {region}</div>
      <div className="text-xs text-gray-500 mb-3">Deadline: {deadline}</div>
      <Divider />
      <div className="flex items-center justify-between">
        <StatusDot status="open" />
        <CTABtn onClick={e => { e?.stopPropagation?.(); onApply?.() }}>Apply →</CTABtn>
      </div>
    </Card>
  )
}

// ─── Notification Card ────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function NotificationCard({ icon, title, body, time, read, onView, onClick, navigate }: { icon?: string; title: string; body: string; time: string; read?: boolean; onView?: () => void; onClick?: () => void; navigate?: NavFn; [k: string]: any }) {
  const handleView = onView ?? onClick
  return (
    <div
      onClick={handleView}
      className={`rounded-xl p-4 cursor-pointer transition-all border ${read ? 'bg-white border-gray-200' : 'bg-blue-50 border-l-4 border-l-blue-600 border-t-transparent border-r-transparent border-b-transparent'}`}
    >
      <div className="flex items-start gap-2">
        <span className="text-lg">{icon || '🔔'}</span>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-semibold text-gray-900">{title}</p>
          <p className="text-[13px] text-gray-700 leading-relaxed">{body}</p>
          <div className="flex items-center justify-between mt-1">
            <span className="text-xs text-gray-500">{time}</span>
            <GhostBtn>View →</GhostBtn>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── Profile Banner + Header ──────────────────────────────────────────────────
export function ProfileHeader({ name, sport, location, verified }: { name: string; sport: string; location: string; verified?: boolean; isAcademy?: boolean }) {
  return (
    <div className="relative">
      <div
        className="w-full"
        style={{ height: 180, background: 'linear-gradient(135deg, #2563EB, #1E40AF)', position: 'relative' }}
      >
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to bottom, transparent, rgba(17,24,39,0.55))' }} />
      </div>
      <div className="flex flex-col items-center -mt-10 pb-4 bg-white">
        <Avatar size={80} name={name} verified={verified} />
        <div className="flex items-center gap-1 mt-2">
          <h1 className="text-xl font-bold text-gray-900">{name}</h1>
          {verified && <span className="text-green-500">✓</span>}
        </div>
        <div className="flex items-center gap-2 mt-1">
          <SportBadge sport={sport} />
          <span className="text-xs text-gray-500">{location}</span>
        </div>
      </div>
    </div>
  )
}

// ─── Stat Row ─────────────────────────────────────────────────────────────────
export function StatRow({ stats }: { stats: { label: string; value: string | number }[] }) {
  return (
    <div className="flex divide-x divide-gray-200 border border-gray-200 rounded-xl overflow-hidden mx-4">
      {stats.map(s => (
        <div key={s.label} className="flex-1 flex flex-col items-center py-3 gap-0.5">
          <span className="text-base font-semibold text-gray-900">{s.value}</span>
          <span className="text-xs text-gray-500">{s.label}</span>
        </div>
      ))}
    </div>
  )
}

// ─── Upload Area ─────────────────────────────────────────────────────────────
export function UploadArea({ label, hasFile }: { label?: string; hasFile?: boolean }) {
  return (
    <div className={`w-full rounded-xl border-2 border-dashed flex flex-col items-center justify-center py-8 gap-2 cursor-pointer active:bg-slate-50 transition-all ${hasFile ? 'border-blue-600 bg-blue-50' : 'border-gray-200'}`}>
      <span className="text-3xl">{hasFile ? '✅' : '📷'}</span>
      <p className="text-sm text-gray-500">{hasFile ? 'File uploaded' : (label || 'Tap to upload')}</p>
    </div>
  )
}

// ─── Setting Row ──────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function SettingRow({ icon, label, onPress, onClick, toggle, toggleValue }: { icon?: ReactNode; label: string; onPress?: () => void; onClick?: () => void; toggle?: boolean | { value: boolean; onChange: (v: boolean) => void }; toggleValue?: boolean; [k: string]: any }) {
  const isToggleObj = toggle && typeof toggle === 'object'
  const toggleVal = isToggleObj ? (toggle as any).value : toggleValue
  const handleToggle = isToggleObj ? (toggle as any).onChange : undefined
  return (
    <button onClick={onPress ?? onClick} className="flex items-center gap-3 py-4 px-4 w-full border-b border-gray-100 last:border-0 active:bg-slate-50">
      <span className="text-lg">{icon}</span>
      <span className="flex-1 text-sm font-semibold text-gray-900 text-left">{label}</span>
      {toggle ? (
        <div
          className={`w-10 h-6 rounded-full flex items-center px-0.5 transition-colors ${toggleVal ? 'bg-blue-600' : 'bg-gray-200'}`}
          onClick={e => { e.stopPropagation(); handleToggle?.(!toggleVal); }}
        >
          <div className={`w-5 h-5 rounded-full bg-white shadow transition-transform ${toggleVal ? 'translate-x-4' : 'translate-x-0'}`} />
        </div>
      ) : (
        <ChevronRightIcon size={16} color="#6B7280" />
      )}
    </button>
  )
}

// ─── Icons ────────────────────────────────────────────────────────────────────
interface IconProps { size?: number; color?: string; className?: string }

export function HomeIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
}
export function SearchIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
}
export function BellIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0"/></svg>
}
export function UserIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
}
export function StarIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
}
export function MessageIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
}
export function ShareIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
}
export function ChevronDownIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><polyline points="6 9 12 15 18 9"/></svg>
}
export function ChevronRightIcon({ size = 24, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><polyline points="9 18 15 12 9 6"/></svg>
}
export function EditIcon({ size = 20, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
}
export function SettingsIcon({ size = 20, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
}
export function EyeIcon({ size = 20, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
}
export function CameraIcon({ size = 20, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>
}
export function TrophyIcon({ size = 20, color = 'currentColor' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><polyline points="8 21 12 17 16 21"/><line x1="12" y1="17" x2="12" y2="11"/><path d="M7 4H4a1 1 0 0 0-1 1v3a8 8 0 0 0 14 0V5a1 1 0 0 0-1-1h-3"/><path d="M7 4a5 5 0 0 0 10 0H7z"/></svg>
}
export function WarningIcon({ size = 20, color = '#F59E0B' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
}
export function CheckCircleIcon({ size = 64, color = '#22C55E' }: IconProps) {
  return <svg width={size} height={size} fill="none" stroke={color} strokeWidth="2" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
}
