// ── SportX Admin Panel JavaScript ──

const API_BASE = '/api/v1/admin';

// ── Auth Helpers ──
function getToken() {
    return localStorage.getItem('admin_token');
}

function setToken(token) {
    localStorage.setItem('admin_token', token);
}

function clearToken() {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
}

function getUser() {
    const raw = localStorage.getItem('admin_user');
    return raw ? JSON.parse(raw) : null;
}

function setUser(user) {
    localStorage.setItem('admin_user', JSON.stringify(user));
}

function requireAuth() {
    if (!getToken()) {
        window.location.href = '/admin/login';
        return false;
    }
    return true;
}

// ── API Helper ──
async function api(method, path, body = null) {
    const url = API_BASE + path;
    const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    };

    const token = getToken();
    if (token) {
        headers['Authorization'] = 'Bearer ' + token;
    }

    const opts = { method, headers };
    if (body && method !== 'GET') {
        opts.body = JSON.stringify(body);
    }

    try {
        const res = await fetch(url, opts);
        if (res.status === 204) return { ok: true, data: null };
        const data = await res.json();
        if (!res.ok) {
            return { ok: false, error: data.error || { message: 'Request failed' }, status: res.status };
        }
        return { ok: true, data: data.data || data };
    } catch (err) {
        return { ok: false, error: { message: 'Network error. Please try again.' } };
    }
}

// ── Toast ──
function showToast(message, type = '') {
    const toast = document.getElementById('toast');
    if (!toast) return;
    toast.textContent = message;
    toast.className = 'toast show' + (type ? ' toast-' + type : '');
    setTimeout(() => { toast.className = 'toast'; }, 3000);
}

// ── Avatar ──
function getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function avatarColor(name) {
    const colors = ['#2563EB', '#F97316', '#22C55E', '#8B5CF6', '#EC4899', '#06B6D4', '#F59E0B'];
    let hash = 0;
    for (let i = 0; i < (name || '').length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
}

function renderAvatar(name, sizeClass = 'avatar-md') {
    return `<div class="avatar ${sizeClass}" style="background:${avatarColor(name)}">${getInitials(name)}</div>`;
}

// ── Time Ago ──
function timeAgo(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    const now = new Date();
    const diff = Math.floor((now - d) / 1000);
    if (diff < 60) return 'Just now';
    if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
    if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
    if (diff < 604800) return Math.floor(diff / 86400) + 'd ago';
    return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

// ── Date Format ──
function formatDate(dateStr) {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

function formatDateTime(dateStr) {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit' });
}

// ── Badge Helpers ──
function statusBadge(status) {
    const map = {
        'published': 'badge-success',
        'active': 'badge-success',
        'verified': 'badge-success',
        'approved': 'badge-success',
        'resolved': 'badge-success',
        'draft': 'badge-gray',
        'pending': 'badge-warning',
        'unverified': 'badge-warning',
        'expired': 'badge-error',
        'removed': 'badge-error',
        'rejected': 'badge-error',
        'inactive': 'badge-error',
        'actioned': 'badge-blue',
        'overridden': 'badge-blue',
    };
    const cls = map[status] || 'badge-gray';
    return `<span class="badge ${cls}">${status.charAt(0).toUpperCase() + status.slice(1)}</span>`;
}

// ── Debounce ──
function debounce(fn, ms = 300) {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), ms);
    };
}

// ── Escape HTML ──
function escapeHtml(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// ── Sidebar Active State ──
function setActiveNav(route) {
    document.querySelectorAll('.sidebar-nav-link').forEach(link => {
        link.classList.toggle('active', link.dataset.route === route);
    });
}

// ── Logout ──
async function logout() {
    await api('POST', '/logout');
    clearToken();
    window.location.href = '/admin/login';
}
