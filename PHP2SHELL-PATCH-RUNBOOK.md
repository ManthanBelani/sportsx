# 🔴 PHP2Shell Patch & Verify Runbook
### CVE-2026-109618 / CVE-2026-109619 — Unauthenticated RCE (CVSS 9.2)

> **Disclosed:** 21 Oct 2026 · **Status:** Actively exploited in the wild (Cloudflare, Amazon TI, eSentire)
> **CISA:** "Critical Vulnerabilities in PHP Require Immediate Patching" (21 Oct 2026)
> **Exploit timing:** Fires *while PHP parses the request — **before** Laravel/app code runs.*

**Targets covered by this runbook:**

| # | Environment | Stack | Target version |
|---|---|---|---|
| A | Production — `45.196.196.118` (`root`) | Ubuntu + `ppa:ondrej/php` · **PHP 8.3-FPM** · Nginx · MySQL · Laravel at `/var/www/sportx` | **8.3.36** |
| B | Local dev machine | `ppa:ondrej/php` (sury) · **PHP 8.4.14 (FPM + CLI)** | **8.4.27** |

> ⚠️ **The fix is a PHP runtime upgrade only.** No Laravel code change and no
> `composer` package change fixes this — `composer audit` already returns clean
> (`laravel/framework v13.35.0`, `symfony/http-foundation v8.1.8`,
> `guzzlehttp/guzzle 8.2.0`, `laravel/sanctum v4.3.3`).

---

## Phase 0 — Pre-flight (2 minutes)

```bash
ssh root@45.196.196.118
```

**0.1 Record current versions (needed for rollback):**

```bash
php -v | head -1
dpkg -l | grep -E 'php8\.(3|4)-(cli|fpm|common)' | awk '{print $2, $3}'
```

**0.2 Confirm PHP-FPM is what actually serves traffic:**

```bash
grep -n fastcgi_pass /etc/nginx/sites-enabled/*
# Expected: fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
```

**0.3 Snapshot (so you can roll back):**

```bash
cp /etc/php/8.3/fpm/php.ini /etc/php/8.3/fpm/php.ini.bak-$(date +%Y%m%d)
cp /etc/nginx/sites-available/sportx /etc/nginx/sites-available/sportx.bak-$(date +%Y%m%d)
mysqldump -u root -p --single-transaction --routines --triggers sportx > /root/sportx-$(date +%Y%m%d).sql
```

**0.4 Open a second terminal.** Keep a live tail running so you see breakage immediately:

```bash
tail -f /var/log/nginx/error.log /var/www/sportx/storage/logs/laravel.log
```

---

## Phase 1 — Verify you are currently vulnerable

```bash
php -v                 # CLI
php-fpm8.3 -v          # FPM  ← THIS is the one that matters for web traffic
dpkg -l php8.3-fpm | tail -1
```

**Pass criteria after patching:** `8.3.36` (prod) / `8.4.27` (local).

> 🔍 **Why your `apt` may not offer the fix yet:** on a machine I checked, apt
> package lists were last refreshed **15 Oct 2026 — six days before the patch
> existed**, so `apt-cache policy` still showed the *old* version as the
> candidate. **`apt update` is mandatory, not optional.**

---

## Phase 2 — Patch PHP (Production)

### 2.1 Refresh package lists

```bash
apt update
```

### 2.2 Confirm the fixed version is now offered

```bash
apt-cache policy php8.3-cli php8.3-fpm
# Candidate must be >= 8.3.36
```

> If `Candidate` is still `< 8.3.36`, the ondrej PPA hasn't synced for your
> Ubuntu release yet. **Do not proceed** — go to Phase 3 (mitigations) and
> re-check hourly.

### 2.3 Upgrade every PHP package you installed in Step 3 of `SERVER-SETUP.md`

```bash
apt install --only-upgrade -y \
  php8.3-fpm php8.3-cli php8.3-common \
  php8.3-mysql php8.3-pgsql php8.3-sqlite3 \
  php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip \
  php8.3-bcmath php8.3-intl php8.3-gd php8.3-redis \
  php8.3-opcache php8.3-readline
```

> **Don't skip the extensions.** Mixed-version extension libs (`php8.3-mysql`,
> `php8.3-opcache`, …) cause hard FPM start failures if they lag the core.

### 2.4 Verify BOTH binaries

```bash
php -v | head -1        # expect 8.3.36
php-fpm8.3 -v | head -1 # expect 8.3.36  ← must match
```

> ⚠️ `php -v` only proves the **CLI** is patched. FPM is a separate binary —
> **always check `php-fpm8.3 -v` too.**

---

## Phase 3 — Temporary mitigations *(ONLY if you cannot patch in Phase 2)*

> These **narrow attack paths but do NOT make you safe.** PHP explicitly states
> they are incomplete. Apply only as a stopgap while waiting for the PPA sync.

Create a drop-in so `apt upgrade` won't clobber it later:

```bash
cat > /etc/php/8.3/fpm/conf.d/99-php2shell-mitigation.ini <<'INI'
; CVE-2026-109618 — remove the OOM memory cap so the corruptible OOM path
; cannot be reached. Must be effective for web SAPI, not just CLI.
memory_limit = -1

; CVE-2026-109619 — session upload progress is a documented attack vector.
; Safe to disable: Laravel never uses PHP's native upload-progress feature.
session.upload_progress.enabled = 0
INI

# Apply to CLI too (artisan / scheduled jobs)
cp /etc/php/8.3/fpm/conf.d/99-php2shell-mitigation.ini /etc/php/8.3/cli/conf.d/
```

**Make it non-overridable by the application** (belt-and-braces):

```bash
cat > /etc/php/8.3/fpm/conf.d/98-php2shell-lock.ini <<'INI'
; Deny the app the ability to re-enable this via ini_set()
session.upload_progress.enabled = 0
INI
```

> ✅ **Good news for this codebase:** a repo-wide grep confirms your app makes
> **zero `ini_set()` calls** and does not override `memory_limit`.
> The only `memory_limit` hit is `config/horizon.php:40 → 'memory_limit' => 128`,
> which is Horizon's *worker MB limit*, **not** the PHP ini directive — so it
> will not fight this mitigation.

**Optional availability boundary** (PHP recommends; still not a complete fix):

```bash
# Example: cap FPM pool memory via cgroup
# /etc/php/8.3/fpm/pool.d/www.conf
; pm.status_path is unrelated — use systemd for the cgroup cap instead
systemctl set-property php8.3-fpm.service MemoryMax=2G
```

---

## Phase 4 — Restart (MANDATORY) + config test

> 🔴 **A `reload` is NOT sufficient for CVE-2026-109619.** That flaw is
> *stale global state held by a live worker process*. Only a **full restart**
> destroys workers carrying freed-memory references.

```bash
php-fpm8.3 -t                 # "test is successful"
nginx -t                      # "syntax is ok"

systemctl restart php8.3-fpm  # RESTART, not reload
systemctl reload nginx
```

**Confirm workers actually recycled (start time should be "just now"):**

```bash
systemctl status php8.3-fpm --no-pager | head -8
ps -o pid,lstart,cmd -C php-fpm8.3
```

**Verify no process still runs the old binary:**

```bash
ps -eo pid,cmd | grep -E 'php-fpm8\.3|php8\.3' | grep -v grep
```

---

## Phase 5 — Laravel re-verification

```bash
cd /var/www/sportx

php artisan config:clear
php artisan route:clear
php artisan view:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache

php artisan about        # quick boot smoke test
```

**Functional smoke tests:**

```bash
# 1. Nginx → FPM handshake
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://45.196.196.118/

# 2. Laravel actually boots (not a 502 / blank PHP page)
curl -s http://45.196.196.118/ | head -20

# 3. API route responds
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://45.196.196.118/api/anything

# 4. PHP actually executing (proves FPM path, not static serving)
curl -s "http://45.196.196.118/index.php" -o /dev/null -w "HTTP %{http_code}\n"
```

**If you get `502 Bad Gateway`:**

```bash
ls -la /var/run/php/php8.3-fpm.sock   # socket missing?
tail -30 /var/log/nginx/error.log
tail -30 /var/log/php8.3-fpm.log
php-fpm8.3 -t                         # config syntax
journalctl -u php8.3-fpm -n 50 --no-pager
```

**Common causes:** extension version mismatch → reinstall the extensions in 2.3;
`memory_limit` typo → check `php-fpm8.3 -i | grep memory_limit`.

---

## Phase 6 — Confirm the mitigation took effect

```bash
# Through FPM specifically (not CLI!)
curl -s "http://45.196.196.118/index.php" >/dev/null   # warm the pool

# Check effective values via CLI (matches if conf.d applied to both SAPIs)
php -i | grep -E '^memory_limit|^session.upload_progress.enabled'
```

Expected (post-Phase 3):

```
memory_limit => -1 => -1
session.upload_progress.enabled => Off => Off
```

**Version re-check (final gate):**

```bash
php -v | head -1 && php-fpm8.3 -v | head -1
# ✅ Both must show 8.3.36
```

---

## Phase 7 — Compromise hunt *(CISA/NCSC: assume probing already happened)*

Exploitation attempts were observed **4 days before disclosure (17 Oct 2026)**.
Treat your server as potentially probed.

### 7.1 Look for webshells / dropped files

```bash
# PHP files modified since the threat window opened
find /var/www/sportx -type f -name "*.php" -newermt "2026-10-10" \
  -not -path "*/vendor/*" -not -path "*/storage/*" -not -path "*/bootstrap/cache/*"

# Unexpected scripts in public web root (e.g. stray test files)
find /var/www/sportx/public -type f ! -name "*.js" ! -name "*.css" \
  ! -name "*.ico" ! -name "*.png" ! -name "*.jpg" ! -name "*.svg" ! -name "*.woff2"

# obfuscation markers
grep -rIlE 'base64_decode\s*\(\s*\$_(POST|GET|REQUEST)|eval\s*\(\s*gzinflate|system\s*\(\s*\$_REQUEST' \
  /var/www/sportx --include='*.php' 2>/dev/null | grep -v vendor
```

### 7.2 PHP workers launching shells (explicit CISA IOC)

```bash
grep -iE 'sh -c|/bin/bash|/bin/sh|curl |wget |nc |bash -i|/dev/tcp/|base64 -d' \
  /var/log/nginx/access.log /var/log/nginx/error.log | tail -50

# Suspicious 200s on non-Laravel paths
awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -30
```

### 7.3 Webshell callback signatures in access log

```bash
grep -iE '\.php\?.*=|/tmp/|wp-config|\.env|config/\.env|php://input|data://|PHPRC' \
  /var/log/nginx/access.log | tail -50
```

### 7.4 Unauthorized access / persistence

```bash
grep -i "Accepted" /var/log/auth.log | tail -50
crontab -l
ls -la /etc/cron.d/ /etc/cron.daily/
find /root /tmp /var/tmp -name "*.php" -o -name "*.sh" -newermt "2026-10-10" 2>/dev/null | head

# unexpected listeners
ss -tlnp
```

### 7.5 Laravel log sweep

```bash
grep -iE 'error|exception|403|419|500' /var/www/sportx/storage/logs/laravel.log | tail -50
```

> **If you find anything suspicious:** isolate the server (do *not* wipe), preserve
> `/var/log/nginx/*`, `/var/log/auth.log`, `storage/logs/*`, snapshot the disk,
> then rebuild from a known-good image rather than cleaning in place.

---

## Phase 8 — Application-side hardening (the only "code" changes)

These don't fix php2shell, but they were flagged in the audit and are real risks:

### 8.1 Production `.env` — `/var/www/sportx/.env`

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=http://45.196.196.118      # or your real domain once TLS is on
LOG_CHANNEL=stack
```

> ⚠️ Your **local** `.env` currently has `APP_ENV=local`, `APP_DEBUG=true` and a
> **stale ngrok URL** (`https://movable-washstand-ungraded.ngrok-free.dev`).
> That's acceptable for local dev — but **verify the server's copy is not a
> `git clone` of it.** `APP_DEBUG=true` in production leaks full stack traces,
> env vars, DB credentials and `APP_KEY` to any unauthenticated request that
> triggers an error.
>
> ```bash
> ssh root@45.196.196.118 'grep -E "^(APP_ENV|APP_DEBUG|APP_URL)" /var/www/sportx/.env'
> ```

After any `.env` edit:

```bash
cd /var/www/sportx && php artisan config:clear && php artisan config:cache
```

### 8.2 Remove the stray test script

`test_schol.php` sits in the project root and boots Laravel on a direct hit.
It's only 7 lines and prints a count (no secrets), but stray entry points
shouldn't exist.

```bash
ssh root@45.196.196.118 'ls -la /var/www/sportx/test_schol.php && rm -v /var/www/sportx/test_schol.php'
```

Also delete it from the repo locally.

### 8.3 Block dotfiles and non-public PHP in Nginx

Your current `/etc/nginx/sites-available/sportx` — add inside `server {}`:

```nginx
    # Never serve env / vcs / backups
    location ~* /(\.env|\.env\..*|\.git/|composer\.(json|lock)|package-lock\.json)$ {
        deny all;
        return 404;
    }

    # Only public/index.php may be executed
    location ~ ^/index\.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_read_timeout 120s;
    }

    # Kill every other direct PHP hit (blocks dropped webshells)
    location ~ \.php$ {
        return 404;
    }
```

```bash
nginx -t && systemctl reload nginx
curl -s -o /dev/null -w "webshell-path HTTP %{http_code}\n" \
  http://45.196.196.118/test_schol.php     # expect 404
```

### 8.4 Keep `.deb` artifacts out of the repo

Your repo root contains:

```
php-sqlite3_2%3a8.3+93ubuntu2_all.deb
php8.3-sqlite3_8.3.6-0ubuntu0.24.04.10_amd64.deb
```

Both are **8.3.6 — far below the fixed 8.3.36**, i.e. *vulnerable builds*.
Delete them and add to `.gitignore`:

```bash
rm -v /home/rainstreamweb/Pictures/test/sportsx/*.deb
echo '*.deb' >> /home/rainstreamweb/Pictures/test/sportsx/.gitignore
```

> Also confirm `CREDENTIALS.md` contains no live secrets committed to git.

---

## Phase 9 — Local dev machine (PHP 8.4.14 → 8.4.27)

```bash
sudo apt update
apt-cache policy php8.4-cli      # Candidate must be >= 8.4.27

sudo apt install --only-upgrade -y \
  php8.4-fpm php8.4-cli php8.4-common php8.4-mysql php8.4-pgsql \
  php8.4-sqlite3 php8.4-mbstring php8.4-xml php8.4-curl php8.4-zip \
  php8.4-bcmath php8.4-intl php8.4-gd php8.4-redis php8.4-opcache \
  php8.4-readline php8.4-imagick php8.4-igbinary php8.4-mcrypt

php -v | head -1      # must show 8.4.27
php-fpm8.4 -v | head -1

sudo systemctl restart php8.4-fpm
```

> If `apt-cache policy` still shows `8.4.14` as **Candidate**, your package
> lists are stale (mine were last synced **15 Oct 2026**) — `apt update` first,
> then `sudo add-apt-repository -y ppa:ondrej/php && sudo apt update` if the
> PPA itself hasn't published yet.

---

## Rollback

```bash
# Restore PHP to the previously recorded version (from Phase 0.1)
apt install --only-upgrade -y \
  php8.3-cli=OLD_VERSION php8.3-fpm=OLD_VERSION php8.3-common=OLD_VERSION

systemctl restart php8.3-fpm

# Restore configs
cp /etc/php/8.3/fpm/php.ini.bak-YYYYMMDD /etc/php/8.3/fpm/php.ini
cp /etc/nginx/sites-available/sportx.bak-YYYYMMDD /etc/nginx/sites-available/sportx
nginx -t && systemctl reload nginx

# Restore DB if migrate went wrong
mysql -u root -p sportx < /root/sportx-YYYYMMDD.sql
```

> **Rollback means re-exposing a critical unauthenticated RCE.** Use it only if
> the site is down, and re-apply the Phase 3 mitigations immediately.

---

## ✅ Verification checklist

**Production — `45.196.196.118`**

- [ ] `apt update` run (lists newer than 21 Oct 2026)
- [ ] `php -v | head -1` → **8.3.36**
- [ ] `php-fpm8.3 -v | head -1` → **8.3.36** *(CLI alone is NOT enough)*
- [ ] All `php8.3-*` extensions upgraded to matching build
- [ ] `php-fpm8.3 -t` → *test is successful*
- [ ] `nginx -t` → *syntax is ok*
- [ ] **`systemctl restart php8.3-fpm`** performed (restart ≠ reload — stale-state CVE)
- [ ] Workers show a fresh start time (`ps -o pid,lstart,cmd -C php-fpm8.3`)
- [ ] *(if not yet patched)* `memory_limit = -1` + `session.upload_progress.enabled = 0` applied to **fpm and cli**
- [ ] `curl http://45.196.196.118/` → HTTP 200, Laravel boots
- [ ] API route returns expected status (not 502/500)
- [ ] `php artisan config:cache && route:cache && view:cache` re-run
- [ ] Compromise hunt (Phase 7) completed — no webshells, no suspicious cron, no odd listeners
- [ ] Server `.env` has `APP_ENV=production` + `APP_DEBUG=false`
- [ ] `test_schol.php` removed
- [ ] Nginx blocks `.env` / direct PHP execution

**Local dev**

- [ ] `php -v` → **8.4.27**
- [ ] `php-fpm8.4 -v` → **8.4.27**
- [ ] `php artisan serve` / `composer dev` still works
- [ ] Vulnerable `*.deb` files removed from repo root

**Ongoing**

- [ ] WAF in front (Vercel/Cloudflare) — reduces exposure, **never replaces patching**
- [ ] Monitor for PHP workers spawning shells or downloading tools
- [ ] Re-run `composer audit` after next `composer update`

---

## Quick one-shot (production, after `apt update` confirms 8.3.36 is available)

```bash
ssh root@45.196.196.118
```

```bash
set -e
apt update
apt install --only-upgrade -y \
  php8.3-fpm php8.3-cli php8.3-common php8.3-mysql php8.3-pgsql \
  php8.3-sqlite3 php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip \
  php8.3-bcmath php8.3-intl php8.3-gd php8.3-redis php8.3-opcache php8.3-readline
php-fpm8.3 -t
systemctl restart php8.3-fpm
systemctl reload nginx
php -v | head -1; php-fpm8.3 -v | head -1
curl -s -o /dev/null -w "site HTTP %{http_code}\n" http://45.196.196.118/
cd /var/www/sportx && php artisan config:cache && php artisan route:cache && php artisan view:cache
echo "DONE — both binaries must read 8.3.36 above."
```

---

## References

- PHP security advisory (21 Oct 2026): <https://www.php.net/archive/2026.php#2026-10-21-5>
- CISA Alert: <https://www.cisa.gov/news-events/alerts/2026/10/21/critical-vulnerabilities-php-require-immediate-patching>
- NCSC-NZ (active exploitation): <https://www.ncsc.govt.nz/alerts/cve-2026-109618-and-cve-2026-109619-affecting-php/>
- NCSC-NL IOC repo: <https://github.com/NCSC-NL/php2shell>
- Tenable FAQ: <https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote>
- Fixed versions: **8.5.12 · 8.4.27 · 8.3.36 · 8.2.35** (7.4–8.1: source backports only)
