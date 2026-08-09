<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Sign In - SportX Admin</title>
    <link rel="stylesheet" href="{{ asset('admin/css/admin.css') }}">
</head>
<body>
    <div class="login-page">
        <div class="login-card">
            {{-- Step 1: Email/Password --}}
            <div id="step-login">
                <div class="login-logo">SX</div>
                <h1 class="login-title">SportX Admin</h1>
                <p class="login-subtitle">Sign in to your admin account</p>

                <div id="login-error" class="login-error" style="display:none;"></div>

                <form class="login-form" onsubmit="handleLogin(event)">
                    <div class="form-group">
                        <label class="form-label">Email</label>
                        <input type="email" id="email" class="input" placeholder="admin@sportx.in" required autocomplete="email">
                    </div>
                    <div class="form-group">
                        <label class="form-label">Password</label>
                        <input type="password" id="password" class="input" placeholder="Enter your password" required autocomplete="current-password">
                    </div>
                    <button type="submit" id="login-btn" class="btn btn-primary btn-block">Sign In</button>
                </form>
            </div>

            {{-- Step 2: 2FA --}}
            <div id="step-2fa" style="display:none;">
                <div class="login-logo">&#x1F510;</div>
                <h1 class="login-title">Two-Factor Auth</h1>
                <p class="login-subtitle">Enter the 6-digit code from your authenticator app</p>

                <div id="twofa-error" class="login-error" style="display:none;"></div>

                <form class="login-form" onsubmit="handle2FA(event)">
                    <div class="form-group">
                        <input type="text" id="twofa-code" class="input" placeholder="000000" maxlength="6" pattern="[0-9]{6}" inputmode="numeric" autocomplete="one-time-code" required style="text-align:center;font-size:24px;letter-spacing:8px;">
                    </div>
                    <button type="submit" id="twofa-btn" class="btn btn-primary btn-block">Verify</button>
                    <button type="button" class="btn btn-ghost btn-block" onclick="backToLogin()">Back to login</button>
                </form>
            </div>
        </div>
    </div>

    <div id="toast" class="toast"></div>

    <script src="{{ asset('admin/js/admin.js') }}"></script>
    <script>
        // If already logged in, redirect
        if (getToken()) {
            window.location.href = '{{ route("admin.dashboard") }}';
        }

        async function handleLogin(e) {
            e.preventDefault();
            const btn = document.getElementById('login-btn');
            const errEl = document.getElementById('login-error');
            btn.disabled = true;
            btn.textContent = 'Signing in...';
            errEl.style.display = 'none';

            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;

            const res = await api('POST', '/login', { email, password });

            if (res.ok) {
                setToken(res.data.token);
                setUser(res.data.user);
                if (res.data.requires_2fa) {
                    document.getElementById('step-login').style.display = 'none';
                    document.getElementById('step-2fa').style.display = 'block';
                    document.getElementById('twofa-code').focus();
                } else {
                    window.location.href = '{{ route("admin.dashboard") }}';
                }
            } else {
                errEl.textContent = res.error.message || 'Login failed.';
                errEl.style.display = 'block';
            }

            btn.disabled = false;
            btn.textContent = 'Sign In';
        }

        async function handle2FA(e) {
            e.preventDefault();
            const btn = document.getElementById('twofa-btn');
            const errEl = document.getElementById('twofa-error');
            btn.disabled = true;
            btn.textContent = 'Verifying...';
            errEl.style.display = 'none';

            const code = document.getElementById('twofa-code').value;

            const res = await api('POST', '/verify-2fa', { code });

            if (res.ok) {
                setUser(res.data.user);
                showToast('Verified successfully!', 'success');
                setTimeout(() => {
                    window.location.href = '{{ route("admin.dashboard") }}';
                }, 500);
            } else {
                errEl.textContent = res.error.message || 'Invalid code.';
                errEl.style.display = 'block';
            }

            btn.disabled = false;
            btn.textContent = 'Verify';
        }

        function backToLogin() {
            document.getElementById('step-login').style.display = 'block';
            document.getElementById('step-2fa').style.display = 'none';
        }
    </script>
</body>
</html>
