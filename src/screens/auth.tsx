import { useState, useEffect } from 'react'
import {
  AppBar,
  PrimaryBtn,
  SecondaryBtn,
  GhostBtn,
  InputField,
  OTPInput,
  EyeIcon,
  type NavFn,
} from '../components/ui'

// ─── Splash Screen ────────────────────────────────────────────────────────────
export function SplashScreen({ navigate }: { navigate: NavFn }) {
  useEffect(() => {
    const t = setTimeout(() => navigate('login'), 2000)
    return () => clearTimeout(t)
  }, [navigate])

  return (
    <div className="flex flex-col h-full bg-[#FAFAFA] items-center justify-center gap-4">
      <div className="w-24 h-24 rounded-[28px] bg-gradient-to-br from-blue-500 to-blue-700 premium-btn-shadow flex items-center justify-center">
        <span className="text-white text-4xl font-bold tracking-tighter">SX</span>
      </div>
      <div className="flex flex-col items-center gap-1">
        <span className="text-2xl font-bold text-gray-900 heading-font tracking-tight">SportX India</span>
        <span className="text-sm text-gray-500 font-medium">India's Sports Network</span>
      </div>
      <div className="absolute bottom-16">
        <div className="w-6 h-6 border-2 border-blue-600 border-t-transparent rounded-full animate-spin" />
      </div>
    </div>
  )
}

// ─── Login Screen ─────────────────────────────────────────────────────────────
export function LoginScreen({ navigate }: { navigate: NavFn }) {
  const [showPass, setShowPass] = useState(false)

  return (
    <div className="flex flex-col h-full bg-white overflow-hidden">
      <div className="flex-1 overflow-y-auto px-4 pt-10 pb-8">
        <div className="flex flex-col items-center mb-8 mt-4">
          <div className="w-16 h-16 rounded-[20px] bg-gradient-to-br from-blue-500 to-blue-700 premium-btn-shadow flex items-center justify-center mb-6">
            <span className="text-white text-xl font-bold tracking-tight">SX</span>
          </div>
          <h1 className="text-3xl font-bold text-gray-900 heading-font tracking-tight">Welcome Back!</h1>
          <p className="text-sm text-gray-500 mt-1.5 font-medium">Sign in to continue</p>
        </div>

        <div className="flex flex-col gap-4">
          <InputField placeholder="Phone or Email" type="text" />
          <InputField
            placeholder="Password"
            type={showPass ? 'text' : 'password'}
            trailing={
              <button onClick={() => setShowPass(v => !v)}>
                <EyeIcon size={20} color="#6B7280" />
              </button>
            }
          />

          <div className="flex justify-end -mt-2">
            <GhostBtn onClick={() => navigate('forgot-password')}>Forgot Password?</GhostBtn>
          </div>

          <PrimaryBtn full onClick={() => navigate('role-select')}>Sign In</PrimaryBtn>

          <div className="flex items-center gap-3 my-1">
            <div className="flex-1 h-px bg-gray-200" />
            <span className="text-xs text-gray-400 font-semibold">OR</span>
            <div className="flex-1 h-px bg-gray-200" />
          </div>

          <SecondaryBtn full onClick={() => {}}>
            <span className="flex items-center gap-2">
              <span className="text-base font-bold" style={{ color: '#4285F4' }}>G</span>
              Continue with Google
            </span>
          </SecondaryBtn>

          <div className="flex items-center justify-center gap-1 mt-2">
            <span className="text-sm text-gray-500">Don't have an account?</span>
            <GhostBtn onClick={() => navigate('signup')}>Sign Up</GhostBtn>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── Signup Screen ────────────────────────────────────────────────────────────
export function SignupScreen({ navigate }: { navigate: NavFn }) {
  const [showPass, setShowPass] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)

  return (
    <div className="flex flex-col h-full bg-white overflow-hidden">
      <AppBar onBack={() => navigate('login')} title="Sign Up" />
      <div className="flex-1 overflow-y-auto px-4 pb-8">
        <h2 className="text-2xl font-bold text-gray-900 mt-4">Create Account</h2>
        <p className="text-sm text-gray-500 mb-6">Join India's sports network</p>

        <div className="flex flex-col gap-4">
          <InputField label="Full Name" placeholder="e.g., Rohan Sharma" />
          <InputField label="Phone Number" placeholder="+91 98765 43210" type="tel" />
          <InputField label="Email (Optional)" placeholder="email@example.com" type="email" />
          <InputField
            label="Password"
            placeholder="Create a password"
            type={showPass ? 'text' : 'password'}
            trailing={
              <button onClick={() => setShowPass(v => !v)}>
                <EyeIcon size={20} color="#6B7280" />
              </button>
            }
          />
          <InputField
            label="Confirm Password"
            placeholder="Repeat password"
            type={showConfirm ? 'text' : 'password'}
            trailing={
              <button onClick={() => setShowConfirm(v => !v)}>
                <EyeIcon size={20} color="#6B7280" />
              </button>
            }
          />

          <PrimaryBtn full onClick={() => navigate('otp')}>Continue</PrimaryBtn>

          <div className="flex items-center justify-center gap-1">
            <span className="text-sm text-gray-500">Already have an account?</span>
            <GhostBtn onClick={() => navigate('login')}>Sign In</GhostBtn>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── OTP Screen ──────────────────────────────────────────────────────────────
export function OTPScreen({ navigate }: { navigate: NavFn }) {
  const [otp, setOtp] = useState('1234')

  return (
    <div className="flex flex-col h-full bg-white overflow-hidden">
      <div className="flex-1 overflow-y-auto px-4 pt-10 pb-8">
        <div className="flex flex-col items-center text-center mb-8">
          <div className="w-14 h-14 rounded-2xl bg-blue-600 flex items-center justify-center mb-6">
            <span className="text-white text-lg font-bold">SX</span>
          </div>
          <h2 className="text-xl font-bold text-gray-900">Verify Your Number</h2>
          <p className="text-sm text-gray-500 mt-2 max-w-xs">
            Enter the 4-digit code sent to <span className="font-semibold text-gray-700">+91 98765 43210</span>
          </p>
        </div>

        <div className="mb-8">
          <OTPInput value={otp} onChange={setOtp} />
        </div>

        <div className="flex flex-col gap-4">
          <div className="flex justify-center">
            <GhostBtn onClick={() => {}} className="text-gray-400">
              Didn't receive it? Resend (30s)
            </GhostBtn>
          </div>

          <PrimaryBtn full onClick={() => navigate('role-select')}>Verify</PrimaryBtn>

          <div className="flex justify-center">
            <GhostBtn onClick={() => navigate('signup')}>Change Phone Number</GhostBtn>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── Role Select Screen ───────────────────────────────────────────────────────
export function RoleSelectScreen({ navigate }: { navigate: NavFn }) {
  const [selectedRole, setSelectedRole] = useState<string | null>(null)

  const roles = [
    {
      id: 'athlete',
      emoji: '🏃',
      title: 'Athlete',
      desc: "I'm a player looking to connect and find opportunities",
    },
    {
      id: 'coach',
      emoji: '🏫',
      title: 'Coach / Academy',
      desc: 'I train athletes and want to showcase my programs',
    },
    {
      id: 'sponsor',
      emoji: '🤝',
      title: 'Sponsor',
      desc: 'I want to support athletes and post opportunities',
    },
  ]

  return (
    <div className="flex flex-col h-full bg-white overflow-hidden">
      <div className="flex-1 overflow-y-auto px-4 pt-6 pb-8">
        <h2 className="text-xl font-bold text-gray-900">Choose Your Role</h2>
        <p className="text-sm text-gray-500 mb-6">Select how you'll use SportX</p>

        <div className="flex flex-col gap-3 mb-8">
          {roles.map(r => (
            <div
              key={r.id}
              onClick={() => setSelectedRole(r.id)}
              className={`rounded-2xl border-2 p-4 cursor-pointer transition-all ${
                selectedRole === r.id
                  ? 'border-blue-600 bg-blue-50'
                  : 'border-gray-200 bg-white'
              }`}
              style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}
            >
              <div className="flex items-center gap-3">
                <span className="text-3xl">{r.emoji}</span>
                <div>
                  <p className="text-base font-semibold text-gray-900">{r.title}</p>
                  <p className="text-sm text-gray-500 mt-0.5">{r.desc}</p>
                </div>
                {selectedRole === r.id && (
                  <div className="ml-auto w-5 h-5 rounded-full bg-blue-600 flex items-center justify-center">
                    <span className="text-white text-xs">✓</span>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        <PrimaryBtn 
          full 
          disabled={!selectedRole} 
          onClick={() => {
            if (selectedRole === 'athlete') navigate('athlete-home')
            else if (selectedRole === 'coach') navigate('coach-home')
            else if (selectedRole === 'sponsor') navigate('sponsor-home')
          }}
        >
          Continue
        </PrimaryBtn>
      </div>
    </div>
  )
}

// ─── Forgot Password Screen ───────────────────────────────────────────────────
export function ForgotPasswordScreen({ navigate }: { navigate: NavFn }) {
  return (
    <div className="flex flex-col h-full bg-white overflow-hidden">
      <AppBar onBack={() => navigate('login')} title="Forgot Password" />
      <div className="flex-1 overflow-y-auto px-4 pt-6 pb-8">
        <h2 className="text-xl font-bold text-gray-900">Reset Your Password</h2>
        <p className="text-sm text-gray-500 mb-6">Enter your phone number or email</p>

        <div className="flex flex-col gap-4">
          <InputField placeholder="Phone or Email" />
          <PrimaryBtn full onClick={() => navigate('reset-password')}>Send Reset Code</PrimaryBtn>

          <div className="flex items-center justify-center gap-1 mt-2">
            <span className="text-sm text-gray-500">Remember your password?</span>
            <GhostBtn onClick={() => navigate('login')}>Sign In</GhostBtn>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── Reset Password Screen ────────────────────────────────────────────────────
export function ResetPasswordScreen({ navigate }: { navigate: NavFn }) {
  const [showNew, setShowNew] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)

  return (
    <div className="flex flex-col h-full bg-white overflow-hidden">
      <AppBar onBack={() => navigate('forgot-password')} title="Set New Password" />
      <div className="flex-1 overflow-y-auto px-4 pt-6 pb-8">
        <h2 className="text-xl font-bold text-gray-900">Create New Password</h2>
        <p className="text-sm text-gray-500 mb-6">Your code has been verified.</p>

        <div className="flex flex-col gap-4">
          <InputField
            label="New Password"
            placeholder="Enter new password"
            type={showNew ? 'text' : 'password'}
            trailing={
              <button onClick={() => setShowNew(v => !v)}>
                <EyeIcon size={20} color="#6B7280" />
              </button>
            }
          />
          <InputField
            label="Confirm New Password"
            placeholder="Repeat new password"
            type={showConfirm ? 'text' : 'password'}
            trailing={
              <button onClick={() => setShowConfirm(v => !v)}>
                <EyeIcon size={20} color="#6B7280" />
              </button>
            }
          />
          <p className="text-xs text-gray-500">Password must be at least 8 characters with 1 number</p>

          <PrimaryBtn full onClick={() => navigate('login')}>Update Password</PrimaryBtn>
        </div>
      </div>
    </div>
  )
}
