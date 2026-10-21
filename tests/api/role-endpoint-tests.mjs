#!/usr/bin/env node
/**
 * ─────────────────────────────────────────────────────────────────────────────
 *  SportX API — Role-wise Endpoint Test Runner (production-readiness suite)
 * ─────────────────────────────────────────────────────────────────────────────
 *  Logs in one user per role, walks every endpoint group in routes/api.php
 *  and verifies status codes + RBAC (role-gated endpoints return 403 from
 *  other roles). No npm dependencies — Node 18+ (built-in fetch).
 *
 *  Suites
 *    Public        health/meta/directories/search/legacy-410 contract
 *    Auth          login & register validation, security (401/410/422)
 *    RBAC Guard    cross-role 403 matrix
 *    Organizer     provider self-service + creates events/opportunity
 *    Lifecycle     athlete×provider registration + approval + results + ICS
 *    Enrollment    coach approval/reject lifecycle
 *    Coach         coach self-service
 *    Academy       academy self-service
 *    Athlete       athlete self-service (+ media upload, verification, report)
 *    Social        connections → chat → follow → posts → blocks
 *    Enquiries     athlete enquiry + replies + opportunity application
 *    Sponsor       discovery + application review + legacy 410s
 *    Scout         profile/shortlist/observations/connections/dashboard
 *    Admin         dashboards, queues, categories, users, audit logs
 *    Cleanup       deletes rows created by this run
 *
 *  Usage (from sportx-api/):
 *    node tests/api/role-endpoint-tests.mjs
 *    node tests/api/role-endpoint-tests.mjs --base=http://127.0.0.1:8001
 *    node tests/api/role-endpoint-tests.mjs --destructive    # add admin casualty ops
 *    node tests/api/role-endpoint-tests.mjs --cleanup=false  # keep created rows
 *    node tests/api/role-endpoint-tests.mjs --suite=admin,scout   # subset
 *
 *  Prereqs: server running (STARTING_SERVER.md), DB seeded with test users
 *  (TEST_CREDENTIALS.md): php artisan migrate:fresh --seed --seeder=AllSeeder
 * ─────────────────────────────────────────────────────────────────────────────
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));

/* ─────────────────────────────── 1. CONFIG ───────────────────────────────── */

const argMap = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v = ''] = a.replace(/^--/, '').split('=');
    return [k, v === '' ? true : v];
  }),
);
const CFG = {
  BASE: String(argMap.base ?? process.env.BASE_URL ?? 'http://127.0.0.1:8000').replace(/\/+$/, ''),
  DESTRUCTIVE: String(argMap.destructive ?? 'false') === 'true',
  CLEANUP: String(argMap.cleanup ?? 'true') !== 'false',
  SLOW: Number(argMap.slow ?? 0),
  SUITES: String(argMap.suite ?? argMap.suites ?? '').split(',').map((s) => s.trim()).filter(Boolean),
  REPORT_DIR: path.join(HERE, 'results'),
};
const CREDS = {
  athlete:   { label: 'Athlete (John)',     email: 'athlete@sportx.test',   password: 'password' },
  athlete2:  { label: 'Athlete (Priya)',    email: 'priya@sportx.test',     password: 'password' },
  coach:     { label: 'Coach (Sarah)',      email: 'coach@sportx.test',     password: 'password' },
  academy:   { label: 'Academy (Elite)',    email: 'academy@sportx.test',   password: 'password' },
  organizer: { label: 'Organizer (Gujarat)',email: 'organizer@sportx.test', password: 'password' },
  sponsor:   { label: 'Sponsor (Decathlon)',email: 'sponsor@sportx.test',   password: 'password' },
  scout:     { label: 'Scout (Kiran)',      email: 'kiran@scout.test',      password: 'password' },
  admin:     { label: 'Admin',              email: 'admin@sportx.test',     password: 'password' },
};

/* ─────────────────────────────── 2. CLIENT ───────────────────────────────── */

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const G = '\x1b[32m', R = '\x1b[31m', Y = '\x1b[33m', D = '\x1b[2m', X = '\x1b[0m';
let httpCalls = 0;
let lastAuthCall = 0;

async function req(method, p, token, body, opts = {}) {
  const headers = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  let payload;
  if (opts.form) {
    payload = body; // FormData
  } else if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }
  // auth endpoints share a 10/min bucket — self-pace to avoid 429 noise
  const isAuth = p.startsWith('/auth/');
  if (isAuth) {
    const wait = lastAuthCall + 6400 - Date.now();
    if (wait > 0) await sleep(wait);
    lastAuthCall = Date.now();
  }
  for (let attempt = 0; attempt < 3; attempt++) {
    let res;
    try {
      res = await fetch(`${CFG.BASE}/api/v1${p}`, {
        method, headers, body: payload, signal: AbortSignal.timeout(30000),
      });
    } catch (e) {
      return { status: 0, json: null, text: `network error: ${e.message}` };
    }
    httpCalls++;
    if (res.status === 429 && attempt < 2) {
      await sleep(Math.max(Number(res.headers.get('retry-after')) || 12, 6) * 1000);
      continue;
    }
    const ct = res.headers.get('content-type') || '';
    let json = null, text = '';
    if (ct.includes('json')) json = await res.json().catch(() => null);
    else text = await res.text().catch(() => '');
    if (CFG.SLOW) await sleep(CFG.SLOW);
    return { status: res.status, json, text };
  }
}

/* deep helpers that tolerate `{data:[…]}`, pagination keys, flat arrays, … */
function candidates(json) {
  const out = [];
  const walk = (v) => {
    if (Array.isArray(v)) {
      if (v.length && v[0] && typeof v[0] === 'object' && 'id' in v[0]) out.push(...v);
      v.forEach((x) => { if (typeof x !== 'object') walk(x); });
    } else if (v && typeof v === 'object') {
      if (v.data !== undefined) walk(v.data); else Object.values(v).forEach(walk);
    }
  };
  walk(json);
  return out.filter((o) => o && typeof o === 'object');
}
function pick(json, pred = () => true) {
  return candidates(json).find(pred) ?? null;
}
function all(json, pred = () => true) {
  return candidates(json).filter(pred);
}

/* ─────────────────────────────── 3. TOTP ─────────────────────────────────── */

const B32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
function b32decode(s) {
  let bits = '';
  for (const c of (s ?? '').toUpperCase().replace(/=+$/, '').replace(/\s/g, '')) {
    const v = B32.indexOf(c);
    if (v >= 0) bits += v.toString(2).padStart(5, '0');
  }
  const bytes = [];
  for (let i = 0; i + 8 <= bits.length; i += 8) bytes.push(parseInt(bits.slice(i, i + 8), 2));
  return Buffer.from(bytes);
}
function totp(secret, stepOffset = 0) {
  if (!secret) return null;
  const t = Math.floor(Date.now() / 30000) + stepOffset;
  const buf = Buffer.alloc(8);
  buf.writeUInt32BE(Math.floor(t / 2 ** 32), 0);
  buf.writeUInt32BE(t >>> 0, 4);
  const h = crypto.createHmac('sha1', b32decode(secret)).update(buf).digest();
  const o = h[h.length - 1] & 0xf;
  const bin = ((h[o] & 0x7f) << 24) | (h[o + 1] << 16) | (h[o + 2] << 8) | h[o + 3];
  return String(bin % 1_000_000).padStart(6, '0');
}
const SECRET_FILE = path.join(HERE, '.admin_totp_secret.txt');

/* ───────────────────────── 4. CONTEXT + RESULT COLLECTOR ─────────────────── */

const ctx = { tokens: {}, users: {}, created: {} };
const results = [];
const suiteCounts = {};

function record(suite, t, res, extras = {}) {
  const expected = [].concat(t.expect ?? 200);
  const ok = expected.includes(res.status);
  const soft = t.soft === true;
  const state = res.status === 'SKIP' ? 'skip' : ok ? 'pass' : soft ? 'soft' : 'fail';
  // Surface per-field validation errors on 422s so failing round-trips are diagnosable.
  let note = extras.note || (t.note ? `note: ${t.note}` : '');
  if (res.status === 422 && res.json?.error?.errors) {
    const errs = Object.entries(res.json.error.errors)
      .map(([f, msgs]) => `${f}: ${[].concat(msgs).join(' / ')}`)
      .join('; ');
    note = `${note}${note ? ' | ' : ''}${errs}`;
  }
  results.push({
    suite, method: t.method, name: t.name, path: t._path ?? t.name,
    expected, status: res.status, ok: state !== 'fail' && state !== 'soft' ? state === 'pass' : false,
    state, note,
  });
  suiteCounts[suite] ??= { pass: 0, fail: 0, skip: 0, soft: 0 };
  suiteCounts[suite][state]++;
  return state;
}
function hardFail(suite, name, note) {
  results.push({ suite, method: '—', name, path: name, expected: [200], status: 'ABORT', state: 'fail' });
  suiteCounts[suite] ??= { pass: 0, fail: 0, skip: 0, soft: 0 };
  suiteCounts[suite].fail++;
}
function logResult(r) {
  const icon = r.state === 'pass' ? `${G}✓${X}` : r.state === 'soft' ? `${Y}~${X}` : r.state === 'skip' ? `${D}⤼${X}` : `${R}✗${X}`;
  console.log(`  ${icon} ${r.method.padEnd(6)} ${r.path.padEnd(58)} ${String(r.status).padEnd(3)} ${D}${r.note ?? ''}${X}`);
}

/* date helpers */
const future = (days, withTime = true) => {
  const iso = new Date(Date.now() + days * 864e5).toISOString();
  return withTime ? iso.slice(0, 16).replace('T', ' ') : iso.slice(0, 10);
};

/* ────────────────────────── 5. CI CONNECT / LOGIN ────────────────────────── */

async function health() {
  return req('GET', '/health', null);
}

async function loginRole(role, suite = 'Boot') {
  const c = CREDS[role];
  const r = await req('POST', '/auth/login', null, { email: c.email, password: c.password });
  record(suite, { method: 'POST', name: `login ${role}`, expect: 200 }, r, { note: r.json?.message ?? '' });
  console.log(`  ${r.status === 200 ? `${G}✓${X}` : `${R}✗${X}`} login  ${role.padEnd(20)} status ${r.status}`);
  if (r.status === 200) {
    ctx.tokens[role] = r.json.token;
    ctx.users[role] = r.json.user?.id ?? null;
    return r.json.token;
  }
  return null;
}

async function adminLogin() {
  const suite = 'Admin';
  const r = await req('POST', '/admin/login', null, { email: CREDS.admin.email, password: CREDS.admin.password });
  record(suite, { method: 'POST', name: 'POST /admin/login', expect: 200, _path: '/admin/login' }, r);
  logResult({ state: r.status === 200 ? 'pass' : 'fail', method: 'POST', path: '/admin/login', status: r.status, note: '' });
  if (r.status !== 200) return null;
  const token = r.json?.data?.token;

  // one call covers: enforce-off (any 6 digits), first-time provisioning, existing secret
  const v1 = await req('POST', '/admin/verify-2fa', token, { code: '123456' });
  if (v1.status === 200) {
    record(suite, { method: 'POST', name: '2FA verify', expect: 200, _path: '/admin/verify-2fa' }, v1);
    console.log(`  ${G}✓${X} admin  2FA verified (enforcement disabled in this env)`);
    ctx.tokens.admin = token;
    return token;
  }
  const data = v1.json?.data ?? {};
  let secret = data.setup_required
    ? data.otpauth_url?.match(/secret=([^&]+)/)?.[1] ?? null
    : (fs.existsSync(SECRET_FILE) ? fs.readFileSync(SECRET_FILE, 'utf8').trim() : null);
  if (secret && data.setup_required) {
    fs.writeFileSync(SECRET_FILE, secret);
    console.log(`  ${Y}i${X} admin  provisioned new TOTP secret (cached to ${path.basename(SECRET_FILE)})`);
  }
  if (!secret) {
    console.log(`  ${R}!${X} admin  cannot verify 2FA: no TOTP secret. Run php artisan tinker and null this admin's google2fa_secret once, then re-run (runner will re-provision).`);
    return null;
  }
  for (const off of [0, -1, 1]) {
    const v = await req('POST', '/admin/verify-2fa', token, { code: totp(secret, off) });
    if (v.status === 200) {
      record(suite, { method: 'POST', name: '2FA verify (TOTP)', expect: 200, _path: '/admin/verify-2fa' }, v);
      console.log(`  ${G}✓${X} admin  2FA verified via TOTP`);
      ctx.tokens.admin = token;
      return token;
    }
  }
  hardFail(suite, 'POST /admin/verify-2fa (TOTP)', 'all TOTP windows rejected — was cached secret rotated?');
  console.log(`  ${R}✗${X} admin  TOTP rejected — re-provision (null google2fa_secret) and re-run`);
  return null;
}

/* ───────────────────────── 6. CONTEXT RESOLUTION ─────────────────────────── */

async function resolveContext() {
  const fetched = {};
  const g = async (p, role) => {
    const r = await req('GET', p, role ? ctx.tokens[role] : null);
    fetched[p] = r;
    return r.json;
  };

  await g('/meta/sports');
  ctx.sportId = pick(fetched['/meta/sports'].json)?.id ?? null;
  ctx.sportName = pick(fetched['/meta/sports'].json)?.name ?? null;
  await g('/meta/cities');
  ctx.cityId = pick(fetched['/meta/cities'].json)?.id ?? null;
  await g('/meta/age-groups');
  ctx.ageGroupId = pick(fetched['/meta/age-groups'].json)?.id ?? null;
  await g('/academies');
  ctx.academyId = pick(fetched['/academies'].json)?.id ?? null;
  await g('/coaches');
  const coachRows = all(fetched['/coaches'].json);
  ctx.coachRow = coachRows.find((c) => c.personal_coaching === true) ?? coachRows[0] ?? null;
  ctx.coachId = ctx.coachRow?.id ?? null;
  ctx.coachUserId = ctx.coachRow?.user_id ?? null;
  await g('/trials');
  const trialRows = all(fetched['/trials'].json);
  ctx.trialRow = trialRows.find((t) => /publish/i.test(t.status ?? '')) ?? trialRows[0] ?? null;
  ctx.trialId = ctx.trialRow?.id ?? null;
  await g('/tournaments');
  ctx.tournamentId = all(fetched['/tournaments'].json)[0]?.id ?? null;
  await g('/opportunities');
  ctx.opportunityId = all(fetched['/opportunities'].json)[0]?.id ?? null;
  await g('/programs');
  const progRows = all(fetched['/programs'].json);
  ctx.programRow = progRows.find((p) => (p.status ?? '') === 'active') ?? progRows[0] ?? null;
  ctx.programId = ctx.programRow?.id ?? null;
  await g('/sports-venues');
  ctx.venueId = pick(fetched['/sports-venues'].json)?.id ?? null;

  // athlete profiles for sponsor/scout/athlete flows
  const athRes = await req('GET', '/athletes', ctx.tokens.sponsor ?? ctx.tokens.scout ?? ctx.tokens.athlete);
  ctx.athleteProfileIds = all(athRes.json).map((a) => a.id).filter(Boolean);
  ctx.athleteProfileId = ctx.athleteProfileIds[0] ?? null;
  ctx.athlete2ProfileId = ctx.athleteProfileIds[1] ?? ctx.athleteProfileIds[0] ?? null;
}

async function resolveAthleteSideData() {
  if (!ctx.tokens.athlete) return;
  const prof = await req('GET', '/me/profile', ctx.tokens.athlete);
  ctx.athleteProfileRaw = prof.json?.data ?? pick(prof.json) ?? null;
  ctx.myAthleteProfileId = ctx.athleteProfileRaw?.id ?? null;

  const notif = await req('GET', '/me/notifications', ctx.tokens.athlete);
  ctx.notificationId = (all(notif.json).find((n) => !n.read_at) ?? all(notif.json)[0])?.id ?? null;

  const convs = await req('GET', '/me/conversations', ctx.tokens.athlete);
  ctx.conversationId = pick(convs.json)?.id ?? null;

  const feed = await req('GET', '/feed', ctx.tokens.athlete);
  ctx.feedPostId = (all(feed.json).find((p) => String(p.user_id) !== String(ctx.users.athlete)) ?? all(feed.json)[0])?.id ?? null;

  const regs = await req('GET', '/me/registrations', ctx.tokens.athlete);
  ctx.myTrialRegId = pick(regs.json)?.id ?? null;
  ctx.myTrialRegRegRef = pick(regs.json)?.registration_ref ?? null;

  const scoutList = await req('GET', '/scouts', ctx.tokens.athlete);
  ctx.scoutProfilePublicId = pick(scoutList.json)?.id ?? null;
}

async function resolveAdminSideData() {
  if (!ctx.tokens.admin || !ctx.tokens.athlete) return;
  const v = await req('GET', '/me/verification', ctx.tokens.athlete);
  ctx.verifReqId = (all(v.json).find((x) => (x.status ?? 'pending') === 'pending') ?? all(v.json)[0])?.id ?? null;
  const a = await req('GET', '/admin/audit-logs', ctx.tokens.admin);
  ctx.auditLogId = pick(a.json)?.id ?? null;
}

/* ───────────────────────────── 7. SUITE RUNNER ───────────────────────────── */

function expand(p) {
  return String(p).replace(/<([^>]+)>/g, (_, key) => {
    const v = key.split('.').reduce((o, k) => (o ?? {})[k], { ...ctx, ...ctx.created, uid2: ctx.users.athlete2, uidA: ctx.users.athlete });
    if (v === undefined || v === null || v === '') return `__missing_${key}__`;
    return String(v);
  });
}

async function runSuite(suite, tests) {
  suiteCounts[suite] ??= { pass: 0, fail: 0, skip: 0, soft: 0 };
  console.log(`\n${Y}▶ ${suite}${X}  (${tests.length} checks)`);
  for (const t of tests) {
    if (t.destructive && !CFG.DESTRUCTIVE) {
      results.push({ suite, method: t.method, name: t.name, path: t._path ?? t.name, expected: [].concat(t.expect ?? 200), status: 'SKIP', state: 'skip', note: 'destructive — run with --destructive' });
      suiteCounts[suite].skip++;
      logResult({ state: 'skip', method: t.method, path: t._path ?? t.name, status: 'SKIP', note: 'destructive (skipped)' });
      continue;
    }
    const tokenName = t.token ?? 'athlete';
    if (tokenName !== 'none' && tokenName !== 'forged' && !ctx.tokens[tokenName]) {
      results.push({ suite, method: t.method, name: t.name, path: t._path ?? t.name, expected: [].concat(t.expect ?? 200), status: 'SKIP', state: 'skip', note: `no token for ${tokenName}` });
      suiteCounts[suite].skip++;
      logResult({ state: 'skip', method: t.method, path: t._path ?? t.name, status: 'SKIP', note: `no ${tokenName} token` });
      continue;
    }
    const actualPath = expand(t._path ?? t.path);
    if (actualPath.includes('__missing_')) {
      const missing = actualPath.match(/__missing_(.+?)__/)?.[1];
      results.push({ suite, method: t.method, name: t.name, path: t._path ?? t.name, expected: [].concat(t.expect ?? 200), status: 'SKIP', state: 'skip', note: `unresolved context: ${missing}` });
      suiteCounts[suite].skip++;
      logResult({ state: 'skip', method: t.method, path: t._path ?? t.name, status: 'SKIP', note: `unresolved ctx: ${missing}` });
      continue;
    }
    const token = tokenName === 'none' ? null : tokenName === 'forged' ? 'forged-token-aaaaaaaaaaaaaaaaaaaaaa' : ctx.tokens[tokenName];
    const body = typeof t.body === 'function' ? t.body() : t.body;
    const r = await req(t.method, actualPath, token, body, { form: t.form === true });
    t._path = actualPath;
    const state = record(suite, t, r, { note: r.json?.message ?? r.json?.error?.message ?? (r.text ? r.text.replace(/\s+/g, ' ').slice(0, 110) : '') });
    logResult(results[results.length - 1]);
    if (typeof t.each === 'function' && r.json) t.each(r, results[results.length - 1]);
    if (t.keep && r.status < 300 && r.json) {
      const val =
        r.json?.data?.id ??
        r.json?.user?.id ??
        r.json?.data?.user?.id ??
        r.json?.data?.[0]?.id ??
        pick(r.json)?.id ??
        null;
      if (val != null) ctx.created[t.keep.split('.').pop()] = val;
    }
  }
}

/* ───────────────────────────── 8. SUITE TABLES ───────────────────────────── */

const S = [];

/* A. Public */
S.push({
  name: 'Public',
  tests: [
    { name: 'api root manifest', method: 'GET', path: '/', token: 'none' },
    { name: 'GET /health', method: 'GET', path: '/health', token: 'none' },
    { name: 'GET /system/health', method: 'GET', path: '/system/health', token: 'none' },
    { name: 'GET /meta/sports', method: 'GET', path: '/meta/sports', token: 'none' },
    { name: 'GET /meta/cities', method: 'GET', path: '/meta/cities', token: 'none' },
    { name: 'GET /meta/age-groups', method: 'GET', path: '/meta/age-groups', token: 'none' },
    { name: 'GET /meta/positions', method: 'GET', path: '/meta/positions', token: 'none' },
    { name: 'GET /meta/facilities', method: 'GET', path: '/meta/facilities', token: 'none' },
    { name: 'GET /meta/trending-searches', method: 'GET', path: '/meta/trending-searches', token: 'none' },
    { name: 'GET /academies', method: 'GET', path: '/academies', token: 'none' },
    { name: 'GET /academies/{id}', method: 'GET', path: '/academies/<academyId>', token: 'none' },
    { name: 'GET /coaches', method: 'GET', path: '/coaches', token: 'none' },
    { name: 'GET /coaches/{id}', method: 'GET', path: '/coaches/<coachId>', token: 'none' },
    { name: 'GET /trials', method: 'GET', path: '/trials', token: 'none' },
    { name: 'GET /trials/{id}', method: 'GET', path: '/trials/<trialId>', token: 'none' },
    { name: 'GET /tournaments', method: 'GET', path: '/tournaments', token: 'none' },
    { name: 'GET /tournaments/{id}', method: 'GET', path: '/tournaments/<tournamentId>', token: 'none' },
    { name: 'GET /tournaments/{id}/results (public)', method: 'GET', path: '/tournaments/<tournamentId>/results', token: 'none' },
    { name: 'GET /opportunities?type=scholarship', method: 'GET', path: '/opportunities?type=scholarship', token: 'none' },
    { name: 'GET /opportunities?type=sponsorship', method: 'GET', path: '/opportunities?type=sponsorship', token: 'none' },
    { name: 'GET /opportunities/{id}', method: 'GET', path: '/opportunities/<opportunityId>', token: 'none' },
    { name: 'GET /programs', method: 'GET', path: '/programs', token: 'none' },
    { name: 'GET /programs/{id}', method: 'GET', path: '/programs/<programId>', token: 'none' },
    { name: 'GET /sports-venues', method: 'GET', path: '/sports-venues', token: 'none' },
    { name: 'GET /sports-venues/{id}', method: 'GET', path: '/sports-venues/<venueId>', token: 'none' },
    { name: 'GET /explore', method: 'GET', path: '/explore', token: 'none' },
    { name: 'GET /search?q=cricket', method: 'GET', path: '/search?q=cricket', token: 'none' },
    { name: 'GET /organizers/{id} (public card)', method: 'GET', path: '/organizers/<organizerProfileId>', token: 'none' },
    { name: 'GET /scholarships → 410 (legacy gone)', method: 'GET', path: '/scholarships', token: 'none', expect: 410 },
    { name: 'GET /scholarships/{id} → 410', method: 'GET', path: '/scholarships/1', token: 'none', expect: 410 },
    { name: 'GET /sponsorships → 410 (legacy gone)', method: 'GET', path: '/sponsorships', token: 'none', expect: 410 },
    { name: 'GET /sponsorships/{id} → 410', method: 'GET', path: '/sponsorships/1', token: 'none', expect: 410 },
    { name: 'GET /unknown-route → 404', method: 'GET', path: '/definitely-not-a-route', token: 'none', expect: 404 },
  ],
});

/* B. Auth & security */
S.push({
  name: 'Auth',
  tests: [
    { name: 'POST /auth/login (bad password)', method: 'POST', path: '/auth/login', token: 'none', body: { email: 'athlete@sportx.test', password: 'definitely-wrong' }, expect: 401 },
    { name: 'POST /auth/login (unknown email)', method: 'POST', path: '/auth/login', token: 'none', body: { email: 'nobody@sportx.test', password: 'long-enough' }, expect: 401 },
    { name: 'POST /auth/register (validation → 422)', method: 'POST', path: '/auth/register', token: 'none', body: { role: 'athlete', email: 'not-an-email', password: 'x' }, expect: 422 },
    { name: 'POST /auth/register (sponsor role → 410)', method: 'POST', path: '/auth/register', token: 'none', body: () => ({ role: 'sponsor', email: `sponsor-reg-${Date.now()}@sportx.test`, password: 'password123' }), expect: 410 },
    { name: 'POST /auth/register (valid athlete → 201)', method: 'POST', path: '/auth/register', token: 'none', body: () => ({ role: 'athlete', email: `runner-bot-${Date.now()}@sportx.test`, password: 'password1234', name: 'Runner Bot' }), expect: 201, keep: 'createdUserId' },
    { name: 'POST /auth/forgot-password (200)', method: 'POST', path: '/auth/forgot-password', token: 'none', body: { email: 'ghost@sportx.test' } },
    { name: 'POST /auth/send-otp (bad channel → 422)', method: 'POST', path: '/auth/send-otp', token: 'none', body: { channel: 'fax', destination: '123', purpose: 'signup' }, expect: 422 },
    { name: 'GET /auth/me (no token → 401)', method: 'GET', path: '/auth/me', token: 'none', expect: 401 },
    { name: 'GET /me/profile (no token → 401)', method: 'GET', path: '/me/profile', token: 'none', expect: 401 },
    { name: 'GET /admin/dashboard (no token → 401)', method: 'GET', path: '/admin/dashboard', token: 'none', expect: 401 },
    { name: 'GET /me/activity (forged token → 401)', method: 'GET', path: '/me/activity', token: 'forged', expect: 401 },
  ],
});

/* C. RBAC guard matrix */
function roleGuardTests() {
  const denied = (role, method, path, label, body, expect = 403) =>
    ({ name: `RBAC ${role} → ${label}`, method, path, token: role, expect, body });
  return [
    denied('athlete', 'GET', '/me/coach-profile', 'coach-profile'),
    denied('athlete', 'GET', '/me/academy', 'academy profile'),
    denied('athlete', 'GET', '/me/organizer', 'organizer profile'),
    denied('athlete', 'GET', '/me/facilities', 'academy facilities'),
    denied('athlete', 'GET', '/coach/enrollments', 'coach enrollments inbox'),
    denied('athlete', 'GET', '/me/scout-profile', 'scout profile'),
    denied('athlete', 'GET', '/me/scout-shortlist', 'scout shortlist'),
    denied('athlete', 'GET', '/me/organizer/analytics', 'organizer analytics'),
    denied('athlete', 'POST', '/me/programs', 'program create'),
    denied('athlete', 'GET', '/admin/dashboard', 'admin dashboard'),
    denied('athlete', 'GET', '/admin/users', 'admin users'),
    denied('athlete', 'GET', '/admin/settings', 'admin settings'),
    denied('athlete', 'GET', '/admin/verification', 'admin verification queue'),
    denied('athlete', 'PATCH', '/admin/verification/1/approve', 'admin verification approve'),
    denied('coach', 'GET', '/me/academy', 'academy profile'),
    denied('coach', 'GET', '/me/facilities', 'academy facilities'),
    denied('coach', 'GET', '/me/organizer', 'organizer profile'),
    denied('coach', 'GET', '/scouts', 'scouts directory (athlete only)'),
    denied('coach', 'GET', '/athletes', 'athlete discovery'),
    denied('coach', 'GET', '/observations', 'observations (scout only)'),
    denied('coach', 'GET', '/admin/users', 'admin users'),
    denied('coach', 'POST', '/trials/<trialId>/register', 'trial registration (athlete only)'),
    denied('coach', 'POST', '/coaches/<coachId>/enroll', 'coaching enrollment start (athlete only)'),
    denied('academy', 'GET', '/me/coach-profile', 'coach-profile'),
    denied('academy', 'GET', '/me/scout-profile', 'scout profile'),
    denied('academy', 'GET', '/me/organizer', 'organizer profile'),
    denied('organizer', 'GET', '/me/coach-profile', 'coach-profile'),
    denied('organizer', 'GET', '/me/facilities', 'academy facilities'),
    denied('sponsor', 'GET', '/scouts', 'scouts directory (athlete only)'),
    denied('sponsor', 'GET', '/me/scout-profile', 'scout profile'),
    denied('sponsor', 'GET', '/coach/enrollments', 'coach enrollments'),
    denied('sponsor', 'POST', '/opportunities/<opportunityId>/apply', 'opportunity apply (athlete only)', { pitch: 'x' }),
    denied('scout', 'GET', '/coach/enrollments', 'coach enrollments'),
    denied('scout', 'GET', '/me/facilities', 'academy facilities'),
    denied('athlete2', 'GET', '/me/coach-profile', 'coach-profile'),
  ];
}

S.push({ name: 'RBAC Guard', tests: roleGuardTests() });

/* D. Organizer provider */
S.push({
  name: 'Organizer',
  tests: [
    { name: 'GET /auth/me', method: 'GET', path: '/auth/me', token: 'organizer' },
    { name: 'GET /me/organizer', method: 'GET', path: '/me/organizer', token: 'organizer' },
    { name: 'PUT /me/organizer', method: 'PUT', path: '/me/organizer', token: 'organizer', body: { description: 'Updated by endpoint test runner' } },
    { name: 'GET /me/organizer/analytics', method: 'GET', path: '/me/organizer/analytics', token: 'organizer' },
    { name: 'GET /me/events (all)', method: 'GET', path: '/me/events?filter=all', token: 'organizer' },
    { name: 'POST /me/events?type=trial', method: 'POST', path: '/me/events?type=trial', token: 'organizer',
      body: () => ({ name: `TestRunner Trial ${Date.now()}`, sport_id: ctx.sportId, city_id: ctx.cityId, venue: 'Test Ground, Mumbai', event_datetime: future(7), registration_deadline: future(4), contact_number: '9800000000', eligibility: 'Open to all', vacancies: 20, entry_fee: 'Free', status: 'draft' }),
      expect: 201, keep: 'orgTrialId' },
    { name: 'PUT /me/events/{trial}', method: 'PUT', path: '/me/events/<orgTrialId>?type=trial', token: 'organizer', body: { venue: 'Main Ground, Mumbai' } },
    { name: 'POST /me/events/{trial}/publish', method: 'POST', path: '/me/events/<orgTrialId>/publish?type=trial', token: 'organizer' },
    { name: 'GET /events/{trial} (show)', method: 'GET', path: '/events/<orgTrialId>', token: 'organizer' },
    { name: 'POST /me/events?type=tournament', method: 'POST', path: '/me/events?type=tournament', token: 'organizer',
      body: () => ({ name: `TestRunner Cup ${Date.now()}`, sport_id: ctx.sportId, city_id: ctx.cityId, venue: 'Cup Stadium', format: 'knockout', start_date: future(8, false), end_date: future(9, false), registration_deadline: future(5, false), entry_fee: 100, prize_pool: 'Trophy', contact_number: '9800000001', gender: 'male', status: 'draft', categories: [{ name: 'Open TR', age_group_id: ctx.ageGroupId, capacity: 50 }] }),
      expect: 201, keep: 'orgTournamentId',
      each: () => {} },
    { name: 'PUT /me/events/{tournament}', method: 'PUT', path: '/me/events/<orgTournamentId>?type=tournament', token: 'organizer', body: { rules: 'Fair play enforced.' } },
    { name: 'GET /tournaments/{id} (fetch created cat)', method: 'GET', path: '/tournaments/<orgTournamentId>', token: 'organizer',
      each: (r) => { if (!ctx.created.orgTournamentCatId) ctx.created.orgTournamentCatId = pick(r.json, (c) => c.name?.includes?.('TR') || c.capacity != null)?.id ?? pick(r.json)?.id; } },
    { name: 'PUT /me/tournaments/{id}/categories', method: 'PUT', path: '/me/tournaments/<orgTournamentId>/categories', token: 'organizer',
      body: () => ({ categories: [{ id: ctx.created.orgTournamentCatId, name: 'Open TR', capacity: 40 }] }),
      each: (r) => { ctx.created.orgTournamentCatId = pick(r.json)?.id ?? ctx.created.orgTournamentCatId; } },
    { name: 'POST /me/events/{tournament}/publish', method: 'POST', path: '/me/events/<orgTournamentId>/publish?type=tournament', token: 'organizer' },
    { name: 'PUT /tournaments/{id}/capacity (owner)', method: 'PUT', path: '/tournaments/<orgTournamentId>/capacity', token: 'organizer',
      body: () => ({ categories: [{ id: ctx.created.orgTournamentCatId, capacity: 30 }] }) },
    { name: 'GET /tournaments/{id}/capacity (owner)', method: 'GET', path: '/tournaments/<orgTournamentId>/capacity', token: 'organizer' },
    { name: 'POST /me/opportunities (scholarship TR)', method: 'POST', path: '/me/opportunities', token: 'organizer',
      body: () => ({ type: 'scholarship', title: `TestRunner Scholarship ${Date.now()}`, sport_id: ctx.sportId, amount: 25000, description: 'Automated opportunity from test runner', eligibility: 'Any athlete', status: 'published' }),
      expect: 201, keep: 'opportunityTrId' },
    { name: 'PUT /me/opportunities/{id}', method: 'PUT', path: '/me/opportunities/<opportunityTrId>', token: 'organizer', body: { description: 'Edited by test runner' } },
    { name: 'POST /me/opportunities/{id}/publish', method: 'POST', path: '/me/opportunities/<opportunityTrId>/publish', token: 'organizer' },
    { name: 'GET /me/opportunities', method: 'GET', path: '/me/opportunities', token: 'organizer' },
    { name: 'GET /me/home (any role can)', method: 'GET', path: '/me/home', token: 'organizer' },
  ],
});

/* E. Lifecycle: athlete × provider */
S.push({
  name: 'Lifecycle',
  tests: [
    { name: 'POST /trials/{trial}/register (athlete)', method: 'POST', path: '/trials/<orgTrialId>/register', token: 'athlete',
      body: { playing_role: 'All-rounder', parental_consent: true, reminder_enabled: true }, expect: 201 },
    { name: 'GET /me/registrations/trials (mine)', method: 'GET', path: '/me/registrations/trials', token: 'athlete',
      each: (r) => { if (!ctx.created.myNewTrialRegId) ctx.created.myNewTrialRegId = pick(r.json, (x) => String(x.trial?.id ?? x.trial_id) === String(ctx.created.orgTrialId))?.id ?? null; } },
    { name: 'GET /trials/{trial}/registrations (owner)', method: 'GET', path: '/trials/<orgTrialId>/registrations', token: 'organizer' },
    { name: 'GET /trials/{trial}/pending-requests (owner)', method: 'GET', path: '/trials/<orgTrialId>/pending-requests', token: 'organizer' },
    { name: 'POST /registrations/trials/{reg}/verify (owner)', method: 'POST', path: '/registrations/trials/<myNewTrialRegId>/verify', token: 'organizer', soft: true },
    { name: 'PATCH /registrations/trials/{reg}/approve (owner)', method: 'PATCH', path: '/registrations/trials/<myNewTrialRegId>/approve', token: 'organizer' },
    { name: 'GET /registrations/trials/{reg} (detail)', method: 'GET', path: '/registrations/trials/<myNewTrialRegId>', token: 'athlete' },
    { name: 'GET /registrations/trials/{reg}/ics', method: 'GET', path: '/registrations/trials/<myNewTrialRegId>/ics', token: 'athlete' },
    { name: 'POST /tournaments/{t}/register (athlete)', method: 'POST', path: '/tournaments/<orgTournamentId>/register', token: 'athlete',
      body: () => ({ category_id: ctx.created.orgTournamentCatId, participation_type: 'individual', payment_status: 'pending', reminder_enabled: true }), expect: [200, 201] },
    { name: 'GET /me/registrations/tournaments (athlete)', method: 'GET', path: '/me/registrations/tournaments', token: 'athlete',
      each: (r) => { if (!ctx.created.myTournRegId) ctx.created.myTournRegId = pick(r.json, (x) => String(x.tournament?.id ?? x.tournament_id) === String(ctx.created.orgTournamentId))?.id ?? null; } },
    { name: 'POST /tournaments/{t}/register (athlete2)', method: 'POST', path: '/tournaments/<orgTournamentId>/register', token: 'athlete2',
      body: () => ({ category_id: ctx.created.orgTournamentCatId, participation_type: 'individual' }), expect: [200, 201] },
    { name: 'GET /me/registrations/tournaments (athlete2)', method: 'GET', path: '/me/registrations/tournaments', token: 'athlete2',
      each: (r) => { if (!ctx.created.ath2TournRegId) ctx.created.ath2TournRegId = pick(r.json, (x) => String(x.tournament?.id ?? x.tournament_id) === String(ctx.created.orgTournamentId))?.id ?? null; } },
    { name: 'GET /tournaments/{t}/pending-requests (owner)', method: 'GET', path: '/tournaments/<orgTournamentId>/pending-requests', token: 'organizer' },
    { name: 'PATCH /registrations/tournaments/{reg}/approve (owner)', method: 'PATCH', path: '/registrations/tournaments/<myTournRegId>/approve', token: 'organizer' },
    { name: 'PATCH /registrations/tournaments/{reg}/payment (owner)', method: 'PATCH', path: '/registrations/tournaments/<myTournRegId>/payment', token: 'organizer', body: { payment_status: 'paid' } },
    { name: 'PATCH /registrations/tournaments/{reg}/reject (ath2, owner)', method: 'PATCH', path: '/registrations/tournaments/<ath2TournRegId>/reject', token: 'organizer', body: { rejection_reason: 'Duplicate entry (test)' } },
    { name: 'POST /events/{t}/registrations/bulk', method: 'POST', path: '/events/<orgTournamentId>/registrations/bulk?type=tournament', token: 'organizer',
      body: () => ({ action: 'approve', ids: [ctx.created.myTournRegId, ctx.created.ath2TournRegId].filter(Boolean) }) },
    { name: 'GET /events/{t}/registrations (owner)', method: 'GET', path: '/events/<orgTournamentId>/registrations?type=tournament', token: 'organizer' },
    { name: 'GET /events/{t}/registrations/export (CSV)', method: 'GET', path: '/events/<orgTournamentId>/registrations/export?type=tournament', token: 'organizer' },
    { name: 'GET /registrations/{reg} (unified)', method: 'GET', path: '/registrations/<myTournRegId>', token: 'organizer' },
    { name: 'GET /registrations/tournaments/{reg}/ics', method: 'GET', path: '/registrations/tournaments/<myTournRegId>/ics', token: 'athlete' },
    { name: 'POST /tournaments/{t}/results (store)', method: 'POST', path: '/tournaments/<orgTournamentId>/results', token: 'organizer',
      body: () => ({ results: [{ category_id: ctx.created.orgTournamentCatId, place: 1, winner_name: 'TestRunner Winner' }] }), expect: 201,
      each: (r) => { if (!ctx.created.orgResultId) ctx.created.orgResultId = r.json?.data?.[0]?.id ?? pick(r.json)?.id; } },
    { name: 'POST /tournaments/{t}/results/{r}/publish', method: 'POST', path: '/tournaments/<orgTournamentId>/results/<orgResultId>/publish', token: 'organizer' },
    { name: 'GET /tournaments/{t}/results (public read-back)', method: 'GET', path: '/tournaments/<orgTournamentId>/results', token: 'none' },
    { name: 'POST /tournaments/{t}/results/{r}/unpublish', method: 'POST', path: '/tournaments/<orgTournamentId>/results/<orgResultId>/unpublish', token: 'organizer' },
    { name: 'POST /tournaments/{t}/results/{r}/publish (restore)', method: 'POST', path: '/tournaments/<orgTournamentId>/results/<orgResultId>/publish', token: 'organizer' },
    { name: 'POST /me/events/{trial}/close (end of life)', method: 'POST', path: '/me/events/<orgTrialId>/close?type=trial', token: 'organizer' },
    { name: 'POST /me/events/{tournament}/close (end of life)', method: 'POST', path: '/me/events/<orgTournamentId>/close?type=tournament', token: 'organizer' },
  ],
});

/* F. Coaching enrollment lifecycle */
S.push({
  name: 'Enrollment',
  tests: [
    { name: 'POST /coaches/{coach}/enroll (athlete, session)', method: 'POST', path: '/coaches/<coachId>/enroll', token: 'athlete',
      body: { plan_type: 'session', notes: 'Invitation from test runner' }, expect: [200, 201, 409], soft: true },
    { name: 'POST /coaches/{coach}/enroll (athlete, quarterly → approve pin)', method: 'POST', path: '/coaches/<coachId>/enroll', token: 'athlete', body: { plan_type: 'quarterly' }, expect: [200, 201, 409], soft: true,
      each: (r) => { if (r.status === 201 && r.json?.data?.id) ctx.created.pendingEnrollmentId ??= r.json.data.id; } },
    { name: 'POST /coaches/{coach}/enroll (athlete2, monthly)', method: 'POST', path: '/coaches/<coachId>/enroll', token: 'athlete2', body: { plan_type: 'monthly' }, expect: [200, 201, 409], soft: true },
    { name: 'POST /coaches/{coach}/enroll (athlete2, quarterly → reject pin)', method: 'POST', path: '/coaches/<coachId>/enroll', token: 'athlete2', body: { plan_type: 'quarterly' }, expect: [200, 201, 409], soft: true,
      each: (r) => { if (r.status === 201 && r.json?.data?.id) ctx.created.rejectEnrollmentId ??= r.json.data.id; } },
    { name: 'GET /me/coaching-enrollments (athlete)', method: 'GET', path: '/me/coaching-enrollments', token: 'athlete' },
    { name: 'GET /coach/enrollments (coach inbox)', method: 'GET', path: '/coach/enrollments', token: 'coach',
      each: (r) => {
        const forThisCoach = all(r.json).filter((x) => String(x.coach_id ?? x.coach?.id) === String(ctx.coachId));
        const rows = forThisCoach.length ? forThisCoach : all(r.json);
        const pending = rows.filter((x) => (x.approval_status ?? x.status ?? '') === 'pending');
        if (!pending.length) return;
        // Approve the athlete's own session plan when we can; reject target
        // comes from the quarterly pin above (or another pending row).
        ctx.created.pendingEnrollmentId ??= (pending.find((x) => String(x.plan_type) === 'session') ?? pending[0])?.id ?? null;
        ctx.created.rejectEnrollmentId ??= (pending.find((x) => x.id !== ctx.created.pendingEnrollmentId))?.id ?? null;
      } },
    {
      name: 'PATCH /coaching-enrollments/{e}/approve (coach)',
      method: 'PATCH', path: '/coaching-enrollments/<pendingEnrollmentId>/approve', token: 'coach',
      body: { coach_response: 'Welcome! First session scheduled.', start_date: future(2) },
      each: (r) => { if (r.status === 200) ctx.approvedEnrollmentId = ctx.created.pendingEnrollmentId; },
    },
    { name: 'GET /coach/enrollments (fresh state again)', method: 'GET', path: '/coach/enrollments', token: 'coach',
      each: (r) => {
        if (ctx.created.rejectEnrollmentId) return;
        const rows = all(r.json).filter((x) => String(x.coach_id ?? x.coach?.id) === String(ctx.coachId) && (x.approval_status ?? x.status ?? '') === 'pending');
        const mine = rows.find((x) => String(x.plan_type) === 'monthly');
        ctx.created.rejectEnrollmentId = (mine ?? rows[0])?.id ?? null;
      } },
    { name: 'PATCH /coaching-enrollments/{e}/reject (coach)', method: 'PATCH', path: '/coaching-enrollments/<rejectEnrollmentId>/reject', token: 'coach',
      body: { rejection_reason: 'No capacity this cycle.' } },
    { name: 'GET /me/coaching-enrollments (athlete2 after reject)', method: 'GET', path: '/me/coaching-enrollments', token: 'athlete2' },
  ],
});

/* G. Coach self-service */
S.push({
  name: 'Coach',
  tests: [
    { name: 'GET /me/coach-profile', method: 'GET', path: '/me/coach-profile', token: 'coach' },
    { name: 'PUT /me/coach-profile', method: 'PUT', path: '/me/coach-profile', token: 'coach', body: { bio: 'Updated by endpoint test runner', fee_per_session: 500 } },
    { name: 'GET /me/events (mine)', method: 'GET', path: '/me/events?filter=all', token: 'coach' },
    { name: 'POST /me/trials (coach trial TR)', method: 'POST', path: '/me/trials', token: 'coach',
      body: () => ({ name: `Coach Trial TR ${Date.now()}`, sport_id: ctx.sportId, city_id: ctx.cityId, venue: 'Coach Ground', event_datetime: future(10), registration_deadline: future(7), contact_number: '9900000000', status: 'draft' }), expect: 201, keep: 'coachTrialId' },
    { name: 'PUT /me/trials/{id}', method: 'PUT', path: '/me/trials/<coachTrialId>', token: 'coach', body: { eligibility: 'Open' } },
    { name: 'POST /me/trials/{id}/publish', method: 'POST', path: '/me/trials/<coachTrialId>/publish', token: 'coach' },
    { name: 'POST /me/trials/{id}/close', method: 'POST', path: '/me/trials/<coachTrialId>/close', token: 'coach' },
    { name: 'POST /me/programs (program TR)', method: 'POST', path: '/me/programs', token: 'coach',
      body: () => ({ title: `TestRunner Program ${Date.now()}`, sport_id: ctx.sportId, duration: '1 month', mode: 'hybrid', price: 1500, about: 'Automated program', status: 'active' }), expect: 201, keep: 'programTrId' },
    { name: 'PUT /me/programs/{id}', method: 'PUT', path: '/me/programs/<programTrId>', token: 'coach', body: { about: 'Edited by test runner' } },
    { name: 'GET /me/programs', method: 'GET', path: '/me/programs', token: 'coach' },
    { name: 'GET /me/enquiries (coach inbox)', method: 'GET', path: '/me/enquiries', token: 'coach' },
    { name: 'GET /me/activity', method: 'GET', path: '/me/activity', token: 'coach' },
    { name: 'GET /me/completion-checklist', method: 'GET', path: '/me/completion-checklist', token: 'coach' },
    { name: 'GET /me/settings', method: 'GET', path: '/me/settings', token: 'coach' },
    { name: 'PUT /me/settings (language)', method: 'PUT', path: '/me/settings', token: 'coach', body: { language: 'en' } },
    { name: 'GET /me/social-links', method: 'GET', path: '/me/social-links', token: 'coach' },
    { name: 'PUT /me/social-links', method: 'PUT', path: '/me/social-links', token: 'coach', body: { instagram: 'https://instagram.com/sportx_test_runner' } },
    { name: 'GET /me/privacy', method: 'GET', path: '/me/privacy', token: 'coach' },
    { name: 'PUT /me/privacy', method: 'PUT', path: '/me/privacy', token: 'coach', body: { who_can_message: 'connections' } },
    { name: 'GET /me/notification-preferences', method: 'GET', path: '/me/notification-preferences', token: 'coach' },
    { name: 'PUT /me/notification-preferences', method: 'PUT', path: '/me/notification-preferences', token: 'coach', body: { push: true, categories: { reminders: true } } },
    { name: 'POST /me/change-password (wrong current → 401)', method: 'POST', path: '/me/change-password', token: 'coach', body: { current_password: 'wrongpass', password: 'newpass1234', password_confirmation: 'newpass1234' }, expect: 401 },
    { name: 'POST /me/device-tokens/subscribe', method: 'POST', path: '/me/device-tokens/subscribe', token: 'coach', body: () => ({ token: `runner-${crypto.randomUUID()}`, device_type: 'android' }) },
    { name: 'POST /me/device-tokens/test', method: 'POST', path: '/me/device-tokens/test', token: 'coach', soft: true },
    { name: 'GET /me/notifications', method: 'GET', path: '/me/notifications', token: 'coach' },
    { name: 'POST /me/notifications/read-all', method: 'POST', path: '/me/notifications/read-all', token: 'coach' },
    { name: 'POST /analytics/events', method: 'POST', path: '/analytics/events', token: 'coach', body: { event: 'test_runner_ping', props: { suite: 'coach' } }, expect: 201 },
    { name: 'POST /me/recent-searches', method: 'POST', path: '/me/recent-searches', token: 'coach', body: { query: 'test runner cricket' }, expect: [200, 201] },
    { name: 'GET /me/recent-searches', method: 'GET', path: '/me/recent-searches', token: 'coach' },
    { name: 'GET /leaderboard', method: 'GET', path: '/leaderboard', token: 'coach' },
    { name: 'GET /leaderboard/strip', method: 'GET', path: '/leaderboard/strip', token: 'coach' },
    { name: 'GET /me/home', method: 'GET', path: '/me/home', token: 'coach' },
  ],
});

/* H. Academy self-service */
S.push({
  name: 'Academy',
  tests: [
    {
      name: 'GET /me/academy (capture)', method: 'GET', path: '/me/academy', token: 'academy',
      each: (r) => {
        const row = r.json?.data ?? pick(r.json);
        if (!row || row.name == null) return;
        // Only fields the validator accepts for PUT /me/academy.
        // facilities/age_groups/achievements come back as JSON strings —
        // the PUT validator wants real arrays.
        const arr = (v) => (v == null ? null : typeof v === 'string' ? JSON.parse(v) : v);
        ctx.academyRow = {
          name: row.name, description: row.description, address: row.address,
          city_id: row.city_id, contact_number: row.contact_number,
          facilities: Array.isArray(row.facilities) ? row.facilities : arr(row.facilities),
          fee_range: row.fee_range, timings: row.timings,
          age_groups: Array.isArray(row.age_groups) ? row.age_groups : arr(row.age_groups),
          year_established: row.year_established,
          achievements: Array.isArray(row.achievements) ? row.achievements : arr(row.achievements),
          email: row.email, website: row.website,
        };
      },
    },
    {
      name: 'PUT /me/academy (round-trip)',
      method: 'PUT', path: '/me/academy', token: 'academy',
      body: () => {
        // PUT /me/academy validates name/description/address/city_id/contact_number
        // as required (no partial-update semantics), so round-trip the current
        // profile with a description tag added.
        const cur = ctx.academyRow ? { ...ctx.academyRow } : null;
        if (!cur) return null;
        cur.description = `${cur.description ?? ''} (Touched by test runner)`.trim();
        return cur;
      },
    },
    { name: 'POST /me/facilities (create TR)', method: 'POST', path: '/me/facilities', token: 'academy', body: () => ({ name: `Facility TR ${Date.now()}`, type: 'ground', amenities: ['parking', 'floodlights'] }), expect: 201, keep: 'facilityId' },
    { name: 'PUT /me/facilities/{id}', method: 'PUT', path: '/me/facilities/<facilityId>', token: 'academy', body: { amenities: ['parking'] } },
    { name: 'GET /me/facilities', method: 'GET', path: '/me/facilities', token: 'academy' },
    { name: 'DELETE /me/facilities/{id} (cleanup own)', method: 'DELETE', path: '/me/facilities/<facilityId>', token: 'academy' },
    { name: 'GET /me/enquiries', method: 'GET', path: '/me/enquiries', token: 'academy' },
    { name: 'GET /me/home', method: 'GET', path: '/me/home', token: 'academy' },
    { name: 'GET /me/completion-checklist', method: 'GET', path: '/me/completion-checklist', token: 'academy' },
    { name: 'GET /me/activity', method: 'GET', path: '/me/activity', token: 'academy' },
  ],
});

/* I. Athlete self-service */
S.push({
  name: 'Athlete',
  tests: [
    { name: 'GET /auth/me', method: 'GET', path: '/auth/me', token: 'athlete' },
    { name: 'GET /me/profile', method: 'GET', path: '/me/profile', token: 'athlete', each: (r) => { ctx.athleteProfileRaw ||= r.json?.data ?? pick(r.json); } },
    { name: 'PUT /me/profile (full shape)', method: 'PUT', path: '/me/profile', token: 'athlete',
      body: () => ({
        full_name: ctx.athleteProfileRaw?.full_name ?? ctx.athleteProfileRaw?.name ?? 'John Athlete',
        date_of_birth: ctx.athleteProfileRaw?.date_of_birth ?? '2004-01-01',
        gender: ctx.athleteProfileRaw?.gender ?? 'male',
        skill_level: ctx.athleteProfileRaw?.skill_level ?? 'intermediate',
        city_id: ctx.athleteProfileRaw?.city_id ?? ctx.cityId,
      }) },
    { name: 'PUT /me/profile/sports', method: 'PUT', path: '/me/profile/sports', token: 'athlete',
      body: () => ({ sports: [{ sport_id: ctx.sportId, is_primary: true, level: 'advanced' }] }) },
    { name: 'GET /me/completion-checklist', method: 'GET', path: '/me/completion-checklist', token: 'athlete' },
    { name: 'GET /me/home', method: 'GET', path: '/me/home', token: 'athlete' },
    { name: 'GET /explore (auth)', method: 'GET', path: '/explore', token: 'athlete' },
    { name: 'GET /search (auth)', method: 'GET', path: '/search?q=football', token: 'athlete' },
    { name: 'GET /leaderboard', method: 'GET', path: '/leaderboard', token: 'athlete' },
    { name: 'GET /leaderboard/strip', method: 'GET', path: '/leaderboard/strip', token: 'athlete' },
    { name: 'GET /athletes (peer discovery)', method: 'GET', path: '/athletes', token: 'athlete' },
    { name: 'GET /athletes/{id}', method: 'GET', path: '/athletes/<athleteProfileId>', token: 'athlete' },
    { name: 'GET /me/settings', method: 'GET', path: '/me/settings', token: 'athlete' },
    { name: 'PUT /me/settings', method: 'PUT', path: '/me/settings', token: 'athlete', body: { notification_prefs: { push: true }, language: 'en' } },
    { name: 'GET /me/privacy', method: 'GET', path: '/me/privacy', token: 'athlete' },
    { name: 'PUT /me/privacy', method: 'PUT', path: '/me/privacy', token: 'athlete', body: { profile_visibility: 'public' } },
    { name: 'GET /me/social-links', method: 'GET', path: '/me/social-links', token: 'athlete' },
    { name: 'PUT /me/social-links', method: 'PUT', path: '/me/social-links', token: 'athlete', body: { website: 'https://sportx.test/runner' } },
    { name: 'GET /me/activity', method: 'GET', path: '/me/activity', token: 'athlete' },
    { name: 'GET /me/notifications', method: 'GET', path: '/me/notifications', token: 'athlete' },
    { name: 'PATCH /me/notifications/{n}/read', method: 'PATCH', path: '/me/notifications/<notificationId>/read', token: 'athlete' },
    { name: 'GET /me/notification-preferences', method: 'GET', path: '/me/notification-preferences', token: 'athlete' },
    { name: 'PUT /me/notification-preferences', method: 'PUT', path: '/me/notification-preferences', token: 'athlete', body: { categories: { mentions: true } } },
    { name: 'POST /analytics/events', method: 'POST', path: '/analytics/events', token: 'athlete', body: { event: 'test_runner_ping' }, expect: 201 },
    { name: 'POST /me/saved (save opportunity)', method: 'POST', path: '/me/saved', token: 'athlete', body: () => ({ item_type: 'opportunity', item_id: ctx.opportunityId }), expect: [200, 201] },
    { name: 'GET /me/saved', method: 'GET', path: '/me/saved', token: 'athlete' },
    { name: 'DELETE /me/saved (unsaved)', method: 'DELETE', path: '/me/saved', token: 'athlete', body: () => ({ item_type: 'opportunity', item_id: ctx.opportunityId }) },
    { name: 'POST /me/achievements', method: 'POST', path: '/me/achievements', token: 'athlete', body: () => ({ title: `TestRunner Achievement ${Date.now()}`, level: 'state', year: 2026, description: 'Automated' }), expect: 201, keep: 'achievementTrId' },
    { name: 'PUT /me/achievements/{id}', method: 'PUT', path: '/me/achievements/<achievementTrId>', token: 'athlete', body: { title: 'Edited Achv TR' } },
    { name: 'GET /me/achievements', method: 'GET', path: '/me/achievements', token: 'athlete' },
    { name: 'DELETE /me/achievements/{id} (cleanup)', method: 'DELETE', path: '/me/achievements/<achievementTrId>', token: 'athlete' },
    { name: 'POST /media/upload (png)', method: 'POST', path: '/media/upload', token: 'athlete', form: true,
      body: () => { const fd = new FormData(); fd.append('media_type', 'photo'); fd.append('caption', 'test runner upload'); fd.append('file', new Blob([Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'base64')], { type: 'image/png' }), 'tr.png'); return fd; },
      each: (r) => { if (r.json?.data?.id) ctx.created.uploadedMediaId = r.json.data.id; }, expect: [200, 201] },
    { name: 'GET /me/media', method: 'GET', path: '/me/media', token: 'athlete' },
    { name: 'GET /media/{id}/signed-url', method: 'GET', path: '/media/<uploadedMediaId>/signed-url', token: 'athlete' },
    { name: 'DELETE /media/{id} (cleanup own upload)', method: 'DELETE', path: '/media/<uploadedMediaId>', token: 'athlete' },
    { name: 'POST /me/verification (own profile)', method: 'POST', path: '/me/verification', token: 'athlete', body: () => ({ verifiable_type: 'athlete_profile', verifiable_id: ctx.myAthleteProfileId ?? ctx.athleteProfileId, notes: 'Automated request (test runner)' }), expect: [200, 201] },
    { name: 'GET /me/verification', method: 'GET', path: '/me/verification', token: 'athlete' },
    { name: 'GET /me/guardian-controls', method: 'GET', path: '/me/guardian-controls', token: 'athlete' },
    { name: 'POST /reports', method: 'POST', path: '/reports', token: 'athlete', body: () => ({ reportable_type: 'sports_venue', reportable_id: ctx.venueId, reason: 'other', comment: 'Automated report row by test runner' }), expect: 201, keep: 'reportId' },
    { name: 'GET /me/reports', method: 'GET', path: '/me/reports', token: 'athlete' },
    { name: 'GET /observations (not a scout → 403)', method: 'GET', path: '/observations', token: 'athlete', expect: 403 },
    { name: 'GET /scout/dashboard (not a scout → 403)', method: 'GET', path: '/scout/dashboard', token: 'athlete', expect: 403 },
  ],
});

/* J. Athlete social */
S.push({
  name: 'Social',
  tests: [
    { name: 'POST /connections → priya', method: 'POST', path: '/connections', token: 'athlete', body: () => ({ user_id: ctx.users.athlete2 }), expect: [200, 201, 409], soft: true },
    { name: 'GET /me/connections/status/{uid2} (capture pair row)', method: 'GET', path: '/me/connections/status/<uid2>', token: 'athlete',
      each: (r) => { ctx.created.priyaConnectionRowId = r.json?.data?.connection_id ?? null; } },
    { name: 'DELETE /connections/{id} (reset athlete↔athlete2 pair)', method: 'DELETE', path: '/connections/<priyaConnectionRowId>', token: 'athlete',
      expect: [200, 204, 404], note: 'lets the accept branch run even on an already-paired dirty DB' },
    { name: 'POST /me/connections/request (priya2)', method: 'POST', path: '/me/connections/request', token: 'athlete', body: () => ({ user_id: ctx.users.athlete2 }), expect: [200, 201, 409] },
    { name: 'GET /me/connections (athlete)', method: 'GET', path: '/me/connections', token: 'athlete' },
    { name: 'GET /me/connections/requests (priya)', method: 'GET', path: '/me/connections/requests', token: 'athlete2',
      each: (r) => { ctx.created.pendingConnectionId ??= (all(r.json).find((x) => String(x.follower_user_id) === String(ctx.users.athlete) && (x.status ?? 'pending') === 'pending') ?? all(r.json).find((x) => (x.status ?? 'pending') === 'pending'))?.id ?? null; } },
    { name: 'POST /me/connections/{id}/accept (priya)', method: 'POST', path: '/me/connections/<pendingConnectionId>/accept', token: 'athlete2',
      expect: [200, 404], note: '404 = mutual-pending auto-accept already closed the pair' },
    { name: 'GET /me/connections/count', method: 'GET', path: '/me/connections/count', token: 'athlete' },
    { name: 'GET /me/connections/status/{userId}', method: 'GET', path: '/me/connections/status/<uid2>', token: 'athlete' },
    { name: 'POST /conversations (private w/ coach)', method: 'POST', path: '/conversations', token: 'athlete', body: () => ({ participant_id: ctx.coachUserId }) },
    { name: 'POST /me/conversations (alias route)', method: 'POST', path: '/me/conversations', token: 'athlete', body: () => ({ participant_id: ctx.coachUserId }) },
    { name: 'GET /me/conversations', method: 'GET', path: '/me/conversations', token: 'athlete', each: (r) => { ctx.conversationId ??= pick(r.json)?.id; } },
    { name: 'GET /conversations/{id} (athlete)', method: 'GET', path: '/conversations/<conversationId>', token: 'athlete', soft: true,
      note: 'facilitate conversation fetch' },
    { name: 'GET /conversations/{id} (coach)', method: 'GET', path: '/conversations/<conversationId>', token: 'coach', soft: true },
    { name: 'POST /conversations/{id}/messages (athlete)', method: 'POST', path: '/conversations/<conversationId>/messages', token: 'athlete', body: { body: 'Hello from test runner 🏏' }, expect: 201 },
    { name: 'POST /conversations/{id}/read (coach)', method: 'POST', path: '/conversations/<conversationId>/read', token: 'coach', soft: true },
    { name: 'PUT /conversations/{id}/read (coach, alias verb)', method: 'PUT', path: '/conversations/<conversationId>/read', token: 'coach', soft: true },
    { name: 'POST /follow/user/{priya}', method: 'POST', path: '/follow/user/<uid2>', token: 'athlete', expect: [200, 201] },
    { name: 'GET /me/following', method: 'GET', path: '/me/following', token: 'athlete' },
    { name: 'GET /me/followers (priya)', method: 'GET', path: '/me/followers', token: 'athlete2' },
    { name: 'DELETE /follow/user/{priya} (cleanup)', method: 'DELETE', path: '/follow/user/<uid2>', token: 'athlete' },
    { name: 'GET /feed', method: 'GET', path: '/feed', token: 'athlete' },
    { name: 'GET /posts (alias)', method: 'GET', path: '/posts', token: 'athlete' },
    { name: 'POST /posts', method: 'POST', path: '/posts', token: 'athlete', body: () => ({ body: `Test runner post ${new Date().toISOString()}`, hashtags: ['testrunner'], visibility: 'public' }), expect: 201, keep: 'myPostId' },
    { name: 'GET /posts/{mine}', method: 'GET', path: '/posts/<myPostId>', token: 'athlete' },
    { name: 'PATCH /posts/{mine} (edit)', method: 'PATCH', path: '/posts/<myPostId>', token: 'athlete', body: { body: 'Edited body from test runner' } },
    { name: 'POST /posts/{mine}/like (priya)', method: 'POST', path: '/posts/<myPostId>/like', token: 'athlete2' },
    { name: 'GET /posts/{mine}/comments', method: 'GET', path: '/posts/<myPostId>/comments', token: 'athlete' },
    { name: 'POST /posts/{mine}/comments (priya)', method: 'POST', path: '/posts/<myPostId>/comments', token: 'athlete2', body: { body: 'Comment from test runner' }, expect: 201, keep: 'myCommentId' },
    { name: 'DELETE /comments/{id} (cleanup)', method: 'DELETE', path: '/comments/<myCommentId>', token: 'athlete2' },
    { name: 'DELETE /posts/{mine}/like (unlike)', method: 'DELETE', path: '/posts/<myPostId>/like', token: 'athlete2' },
    { name: 'DELETE /posts/{mine} (cleanup)', method: 'DELETE', path: '/posts/<myPostId>', token: 'athlete' },
    { name: 'POST /blocks (block runner-bot)', method: 'POST', path: '/blocks', token: 'athlete', body: () => ({ user_id: ctx.created.createdUserId ?? ctx.users.athlete2 }), expect: [200, 201] },
    { name: 'GET /blocks', method: 'GET', path: '/blocks', token: 'athlete' },
    { name: 'DELETE /blocks/{user} (unblock)', method: 'DELETE', path: '/blocks/<createdUserId>', token: 'athlete', body: undefined, soft: true, note: 'if register block failed earlier this 404s — soft' },
  ],
});

/* K. Enquiries + opportunity application */
S.push({
  name: 'Enquiries',
  tests: [
    { name: 'POST /enquiries (athlete → program TR)', method: 'POST', path: '/enquiries', token: 'athlete',
      body: () => ({ subject_type: 'program', subject_id: ctx.created.programTrId ?? ctx.programId, message: 'Automated enquiry from test runner', preferred_datetime: future(5) }),
      expect: 201, keep: 'enquiryTrId' },
    { name: 'GET /me/enquiries (athlete inbox)', method: 'GET', path: '/me/enquiries', token: 'athlete' },
    { name: 'GET /enquiries/{id} (athlete owner)', method: 'GET', path: '/enquiries/<enquiryTrId>', token: 'athlete' },
    { name: 'POST /enquiries/{id}/messages (coach reply)', method: 'POST', path: '/enquiries/<enquiryTrId>/messages', token: 'coach', body: { body: 'Reply from owner (test runner)' }, expect: 201 },
    { name: 'POST /enquiries/{id}/messages (admin reply)', method: 'POST', path: '/enquiries/<enquiryTrId>/messages', token: 'admin', body: { body: 'Reply from admin (test runner)' }, expect: 201 },
    { name: 'PUT /enquiries/{id}/read (athlete)', method: 'PUT', path: '/enquiries/<enquiryTrId>/read', token: 'athlete' },
    { name: 'POST /opportunities/{id}/apply (athlete)', method: 'POST', path: '/opportunities/<opportunityTrId>/apply', token: 'athlete', body: { pitch: 'Test runner candidate — strongest timings in the trial data.' }, expect: [200, 201] },
    { name: 'GET /me/opportunities?type=applied', method: 'GET', path: '/me/opportunities?type=applied', token: 'athlete', soft: true },
  ],
});

/* L. Sponsor review + legacy */
S.push({
  name: 'Sponsor',
  tests: [
    { name: 'GET /auth/me', method: 'GET', path: '/auth/me', token: 'sponsor' },
    { name: 'GET /athletes (discovery)', method: 'GET', path: '/athletes', token: 'sponsor' },
    { name: 'GET /athletes/{id}', method: 'GET', path: '/athletes/<athleteProfileId>', token: 'sponsor' },
    { name: 'GET /opportunities/{id}/applications (owner)', method: 'GET', path: '/opportunities/<opportunityTrId>/applications', token: 'organizer',
      each: (r) => { ctx.created.opportunityAppId ??= pick(r.json)?.id; } },
    { name: 'PATCH /opportunities/{id}/applications/{appId} (review)', method: 'PATCH', path: '/opportunities/<opportunityTrId>/applications/<opportunityAppId>', token: 'organizer', body: { status: 'shortlisted', decision_note: 'Great timings (test runner).' } },
    { name: 'GET /me/sponsorships → 410 (legacy)', method: 'GET', path: '/me/sponsorships', token: 'sponsor', expect: 410 },
    { name: 'POST /me/sponsorships → 410 (legacy)', method: 'POST', path: '/me/sponsorships', token: 'sponsor', expect: 410 },
    { name: 'GET /me/shortlist → 410 (legacy)', method: 'GET', path: '/me/shortlist', token: 'sponsor', expect: 410 },
    { name: 'POST /me/shortlist → 410 (legacy)', method: 'POST', path: '/me/shortlist', token: 'sponsor', expect: 410 },
    { name: 'GET /me/applications → 410 (legacy)', method: 'GET', path: '/me/applications', token: 'athlete', expect: 410 },
  ],
});

/* M. Talent scout */
S.push({
  name: 'Talent Scout',
  tests: [
    { name: 'GET /auth/me', method: 'GET', path: '/auth/me', token: 'scout' },
    { name: 'GET /me/scout-profile', method: 'GET', path: '/me/scout-profile', token: 'scout' },
    { name: 'PUT /me/scout-profile', method: 'PUT', path: '/me/scout-profile', token: 'scout', body: () => ({ sports_specialization: [ctx.sportId], experience_years: 8, listing_status: true }) },
    { name: 'GET /athletes (scout discovery)', method: 'GET', path: '/athletes', token: 'scout' },
    { name: 'GET /scout/dashboard', method: 'GET', path: '/scout/dashboard', token: 'scout' },
    { name: 'POST /observations', method: 'POST', path: '/observations', token: 'scout', body: () => ({ athlete_profile_id: ctx.athleteProfileId, rating: 4, note: 'Automated observation (test runner)' }), expect: 201 },
    { name: 'GET /observations', method: 'GET', path: '/observations', token: 'scout' },
    { name: 'POST /me/scout-shortlist/{athlete}', method: 'POST', path: '/me/scout-shortlist/<athleteProfileId>', token: 'scout', body: { status: 'under_review', tags: ['test-runner'], notes: 'Automated shortlist' }, expect: [200, 201, 409], soft: true },
    { name: 'GET /me/scout-shortlist', method: 'GET', path: '/me/scout-shortlist', token: 'scout' },
    { name: 'PATCH /me/scout-shortlist/{athlete}', method: 'PATCH', path: '/me/scout-shortlist/<athleteProfileId>', token: 'scout', body: { status: 'high', notes: 'Promoted by test runner' } },
    { name: 'DELETE /me/scout-shortlist/{athlete} (cleanup)', method: 'DELETE', path: '/me/scout-shortlist/<athleteProfileId>', token: 'scout' },
    { name: 'POST /athletes/{id}/connect (scout → ath2)', method: 'POST', path: '/athletes/<athlete2ProfileId>/connect', token: 'scout', body: { purpose: 'Automated scout contact (test runner)' }, expect: [200, 201, 409], soft: true },
    { name: 'GET /scout-connection-status/athlete/{id}', method: 'GET', path: '/scout-connection-status/athlete/<athlete2ProfileId>', token: 'scout', soft: true },
    { name: 'GET /me/scout-connections (scout)', method: 'GET', path: '/me/scout-connections', token: 'scout',
      each: (r) => { ctx.created.scoutConnectionsCount = all(r.json).length; } },
    { name: 'GET /me/scout-connections/incoming', method: 'GET', path: '/me/scout-connections/incoming', token: 'scout' },
    { name: 'POST /scouts/{scout}/connect (athlete initiate)', method: 'POST', path: '/scouts/<scoutProfilePublicId>/connect', token: 'athlete', body: { message: 'Automated two-way connect (test runner)' }, expect: [200, 201, 409], soft: true },
    { name: 'GET /me/scout-connection-requests (athlete side)', method: 'GET', path: '/me/scout-connection-requests', token: 'athlete',
      each: (r) => { if (!ctx.created.scoutConnectionId) ctx.created.scoutConnectionId = pick(r.json, (x) => (x.status ?? '') === 'pending')?.id ?? pick(r.json)?.id; } },
    { name: 'POST /me/scout-connection-requests/{id}/accept (athlete)', method: 'POST', path: '/me/scout-connection-requests/<scoutConnectionId>/accept', token: 'athlete', soft: true, expect: [200, 409] },
    { name: 'GET /me/scout-connections (after accept)', method: 'GET', path: '/me/scout-connections', token: 'scout' },
    { name: 'DELETE /me/scout-connections/{id} (cleanup)', method: 'DELETE', path: '/me/scout-connections/<scoutConnectionId>', token: 'scout', soft: true, expect: [200, 404] },
  ],
});

/* N. Admin */
S.push({
  name: 'Admin',
  tests: [
    { name: 'GET /admin/me', method: 'GET', path: '/admin/me', token: 'admin' },
    { name: 'GET /admin/dashboard', method: 'GET', path: '/admin/dashboard', token: 'admin' },
    { name: 'GET /admin/verification (queue)', method: 'GET', path: '/admin/verification', token: 'admin' },
    { name: 'GET /admin/verification/{id}', method: 'GET', path: '/admin/verification/<verifReqId>', token: 'admin' },
    { name: 'PATCH /admin/verification/{id}/approve', method: 'PATCH', path: '/admin/verification/<verifReqId>/approve', token: 'admin' },
    { name: 'GET /admin/content (picker)', method: 'GET', path: '/admin/content', token: 'admin' },
    { name: 'GET /admin/content/trials', method: 'GET', path: '/admin/content/trials', token: 'admin' },
    { name: 'GET /admin/content/opportunities', method: 'GET', path: '/admin/content/opportunities', token: 'admin' },
    { name: 'GET /admin/content/trials/{id}', method: 'GET', path: '/admin/content/trials/<orgTrialId>', token: 'admin' },
    { name: 'GET /admin/moderation/queue', method: 'GET', path: '/admin/moderation/queue', token: 'admin' },
    { name: 'GET /admin/moderation/reports/{id}', method: 'GET', path: '/admin/moderation/reports/<reportId>', token: 'admin', soft: true },
    { name: 'POST /admin/moderation/reports/{id}/approve', method: 'POST', path: '/admin/moderation/reports/<reportId>/approve', token: 'admin', soft: true },
    { name: 'GET /admin/expiry-rules', method: 'GET', path: '/admin/expiry-rules', token: 'admin' },
    { name: 'GET /admin/expiry/monitor', method: 'GET', path: '/admin/expiry/monitor', token: 'admin' },
    { name: 'GET /admin/categories/sports', method: 'GET', path: '/admin/categories/sports', token: 'admin' },
    { name: 'POST /admin/categories/sports (TR sport)', method: 'POST', path: '/admin/categories/sports', token: 'admin', body: () => ({ name: `TestRunnerSport ${Date.now() % 100000}`, is_active: true }), expect: 201, keep: 'sportTrId' },
    { name: 'PUT /admin/categories/sports/{id} (rename TR)', method: 'PUT', path: '/admin/categories/sports/<sportTrId>', token: 'admin', body: () => ({ name: `TestRunnerSport Renamed ${Date.now() % 100000}` }) },
    { name: 'GET /admin/categories/cities', method: 'GET', path: '/admin/categories/cities', token: 'admin' },
    { name: 'GET /admin/categories/age-groups', method: 'GET', path: '/admin/categories/age-groups', token: 'admin' },
    { name: 'GET /admin/categories/positions', method: 'GET', path: '/admin/categories/positions', token: 'admin' },
    { name: 'DELETE /admin/categories/sports/{id} (cleanup TR)', method: 'DELETE', path: '/admin/categories/sports/<sportTrId>', token: 'admin', expect: [200, 204] },
    { name: 'GET /admin/settings', method: 'GET', path: '/admin/settings', token: 'admin', each: (r) => { ctx.currentSettings = r.json?.data?.settings ?? null; } },
    { name: 'PUT /admin/settings (no-op body)', method: 'PUT', path: '/admin/settings', token: 'admin', body: {} },
    { name: 'PUT /admin/settings (toggle boolean)', method: 'PUT', path: '/admin/settings', token: 'admin',
      body: () => { const [k, v] = Object.entries(ctx.currentSettings ?? {}).find(([, v]) => typeof v === 'boolean') ?? []; return k ? { [k]: !v } : {}; },
      each: (r) => {
        const [k] = Object.entries(ctx.currentSettings ?? {}).find(([, v]) => typeof v === 'boolean') ?? [];
        if (k && r.status === 200) flippedBack = k;
      } },
    { name: 'PUT /admin/settings (flip back)', method: 'PUT', path: '/admin/settings', token: 'admin',
      body: () => (flippedBack ? { [flippedBack]: !ctx.currentSettings?.[flippedBack] } : {}), soft: true },
    { name: 'GET /admin/email-settings', method: 'GET', path: '/admin/email-settings', token: 'admin' },
    { name: 'GET /admin/email-settings/diagnostics', method: 'GET', path: '/admin/email-settings/diagnostics', token: 'admin' },
    { name: 'POST /admin/email-settings/clear-token-cache', method: 'POST', path: '/admin/email-settings/clear-token-cache', token: 'admin' },
    { name: 'GET /admin/users', method: 'GET', path: '/admin/users', token: 'admin' },
    { name: 'GET /admin/users?q=runner-bot', method: 'GET', path: '/admin/users?q=runner-bot', token: 'admin' },
    { name: 'GET /admin/users/{id}', method: 'GET', path: '/admin/users/<createdUserId>', token: 'admin' },
    { name: 'POST /admin/users/{id}/approve (runner bot)', method: 'POST', path: '/admin/users/<createdUserId>/approve', token: 'admin' },
    { name: 'GET /admin/opportunities (review queue)', method: 'GET', path: '/admin/opportunities', token: 'admin' },
    { name: 'GET /admin/notifications/stats', method: 'GET', path: '/admin/notifications/stats', token: 'admin' },
    { name: 'GET /admin/audit-logs', method: 'GET', path: '/admin/audit-logs', token: 'admin' },
    { name: 'GET /admin/audit-logs/{id}', method: 'GET', path: '/admin/audit-logs/<auditLogId>', token: 'admin', soft: true },
    { name: 'GET /admin/registrations/analytics/dashboard', method: 'GET', path: '/admin/registrations/analytics/dashboard', token: 'admin' },
    { name: 'GET /admin/registrations/activity-log', method: 'GET', path: '/admin/registrations/activity-log', token: 'admin' },
    { name: 'POST /admin/notifications/broadcast (in_app only)', method: 'POST', path: '/admin/notifications/broadcast', token: 'admin', body: { title: 'Test runner broadcast', body: 'Automated broadcast — safe to ignore.', channels: ['in_app'] }, expect: [200, 201], destructive: true, note: 'sends in-app notification to active users' },
    { name: 'POST /admin/users/{id}/suspend (runner bot)', method: 'POST', path: '/admin/users/<createdUserId>/suspend', token: 'admin', expect: [200, 201], destructive: true },
    { name: 'DELETE /admin/users/{id} (runner bot)', method: 'DELETE', path: '/admin/users/<createdUserId>', token: 'admin', expect: [200, 204], destructive: true },
  ],
});

/* O. Cleanup (destructive-gated content deletes for rows this run created) */
S.push({
  name: 'Cleanup',
  tests: [
    { name: 'DELETE /admin/content/trials/{orgTrial}', method: 'DELETE', path: '/admin/content/trials/<orgTrialId>', token: 'admin', expect: [200, 204], destructive: true },
    { name: 'DELETE /admin/content/tournaments/{orgTournament}', method: 'DELETE', path: '/admin/content/tournaments/<orgTournamentId>', token: 'admin', expect: [200, 204], destructive: true },
    { name: 'DELETE /admin/content/trials/{coachTrial}', method: 'DELETE', path: '/admin/content/trials/<coachTrialId>', token: 'admin', expect: [200, 204], destructive: true },
    { name: 'DELETE /admin/content/opportunities/{opportunityTr}', method: 'DELETE', path: '/admin/content/opportunities/<opportunityTrId>', token: 'admin', expect: [200, 204], destructive: true },
    { name: 'DELETE /admin/content/programs/{programTr}', method: 'DELETE', path: '/admin/content/programs/<programTrId>', token: 'admin', expect: [200, 204], destructive: true },
    { name: 'POST /admin/logout (last call)', method: 'POST', path: '/admin/logout', token: 'admin' },
  ],
});

let flippedBack = null;

/* ─────────────────────────────── 9. MAIN ─────────────────────────────────── */

async function main() {
  console.log('');
  console.log('  SportX API — role-wise endpoint test runner');
  console.log(`  target : ${CFG.BASE}`);
  console.log(`  flags  : destructive=${CFG.DESTRUCTIVE}  cleanup=${CFG.CLEANUP}`);
  console.log('');

  const pre = await health();
  if (pre.status === 0) {
    console.error(`${R}✗ Server unreachable at ${CFG.BASE}/api/v1/health${X}`);
    console.error('  Start the backend first (STARTING_SERVER.md) then re-run.');
    process.exit(2);
  }
  if (pre.status !== 200) {
    console.error(`${R}✗ /health returned ${pre.status} (DB?)${X} — check MySQL in XAMPP.`);
    process.exit(2);
  }
  console.log(`  ${G}✓${X} server reachable, DB connected`);

  for (const role of ['athlete', 'athlete2', 'coach', 'academy', 'organizer', 'sponsor', 'scout']) await loginRole(role);
  await adminLogin(); // sets ctx.tokens.admin (or null → admin suites skip cleanly)
  ctx.uid2 = ctx.users.athlete2;
  ctx.uidA = ctx.users.athlete;

  // organizer profile id (public card endpoint needs profile id, not user id)
  if (ctx.tokens.organizer) {
    const o = await req('GET', '/me/organizer', ctx.tokens.organizer);
    ctx.created.organizerProfileId = o.json?.data?.id ?? pick(o.json)?.id ?? null;
  }
  await resolveContext();
  await resolveAthleteSideData();
  await resolveAdminSideData();

  let plan = S;
  if (CFG.SUITES.length) {
    plan = S.filter((s) => CFG.SUITES.includes(s.name.toLowerCase().split(' ')[0]));
    if (!plan.length) plan = S;
  }

  for (const suite of plan) await runSuite(suite.name, suite.tests);

  writeReport();
  summarize();
}

/* ────────────────────────── 10. REPORT + EXIT ────────────────────────────── */

function summarize() {
  const pass = results.filter((r) => r.state === 'pass').length;
  const soft = results.filter((r) => r.state === 'soft').length;
  const fail = results.filter((r) => r.state === 'fail').length;
  const skip = results.filter((r) => r.state === 'skip').length;
  console.log('\n' + '═'.repeat(74));
  console.log('  RESULTS BY SUITE');
  console.log('═'.repeat(74));
  for (const [s, c] of Object.entries(suiteCounts)) {
    const pad = s.padEnd(26, ' ');
    const badge = c.fail ? `${R}✗${X}` : `${G}✓${X}`;
    console.log(`  ${badge} ${pad} pass ${c.pass}  soft ${c.soft}  fail ${c.fail}  skip ${c.skip}`);
  }
  console.log('─'.repeat(74));
  console.log(`  TOTAL checks: ${results.length}   ${G}pass ${pass}${X}   ${Y}soft ${soft}${X}   ${R}fail ${fail}${X}   ${D}skip ${skip}${X}   (${httpCalls} HTTP calls)`);
  if (soft) {
    console.log(`\n  ${Y}SOFT FAILS (state-dependent — rerun on fresh seed or investigate):${X}`);
    results.filter((r) => r.state === 'soft').slice(0, 20).forEach((r) => console.log(`   ~ [${r.suite}] ${r.method} ${r.path} → ${r.status} (want ${[].concat(r.expected).join('/')})`));
  }
  if (fail) {
    console.log(`\n  ${R}HARD FAILS:${X}`);
    results.filter((r) => r.state === 'fail').slice(0, 40).forEach((r) => console.log(`   ✗ [${r.suite}] ${r.method} ${r.path} → ${r.status}, want ${[].concat(r.expected).join('/')}  ${r.note ?? ''}`));
  }
  process.exit(fail ? 1 : 0);
}

function writeReport() {
  fs.mkdirSync(CFG.REPORT_DIR, { recursive: true });
  const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const jsonPath = path.join(CFG.REPORT_DIR, `endpoint-report-${ts}.json`);
  const mdPath = path.join(CFG.REPORT_DIR, `endpoint-report-${ts}.md`);
  fs.writeFileSync(jsonPath, JSON.stringify({
    meta: { base: CFG.BASE, flags: { destructive: CFG.DESTRUCTIVE, cleanup: CFG.CLEANUP }, finished_at: new Date().toISOString() },
    created: ctx.created,
    results,
  }, null, 2));

  const lines = [
    '# SportX API — endpoint test report',
    '',
    `**Base URL:** ${CFG.BASE}  `,
    `**Generated:** ${new Date().toISOString()}  `,
    `**Flags:** destructive=${CFG.DESTRUCTIVE}, cleanup=${CFG.CLEANUP}`,
    '',
    '| Suite | Pass | Soft | Fail | Skip |',
    '|---|---|---|---|---|',
  ];
  for (const [s, c] of Object.entries(suiteCounts)) lines.push(`| ${s} | ${c.pass} | ${c.soft} | ${c.fail} | ${c.skip} |`);
  lines.push('', '## Checks', '', '| Suite | Method | Check | Expected | Got | Result | Note |', '|---|---|---|---|---|---|---|');
  for (const r of results) {
    const res = r.state === 'pass' ? '✓ pass' : r.state === 'soft' ? '~ soft' : r.state === 'skip' ? '⤼ skip' : '✗ FAIL';
    lines.push(`| ${r.suite} | ${r.method} | ${String(r.path).replace(/\|/g, '\\|')} | ${[].concat(r.expected).join('/')} | ${r.status} | ${res} | ${String(r.note ?? '').replace(/\|/g, '\\|').slice(0, 120)} |`);
  }
  fs.writeFileSync(mdPath, lines.join('\n'));
  console.log(`\n  report → ${mdPath}`);
}

process.on('unhandledRejection', (e) => {
  console.error('Runner crashed:', e);
  process.exit(3);
});

main();
