R# Ubuntu Server Setup — Laravel Backend

Server: `45.196.196.118` · User: `root`

> **Step 1 is done in the hosting provider's console/VNC only if SSH is broken.**
> All other steps are done over SSH once it works:
> ```bash
> ssh root@45.196.196.118
> # password: (the one you provided)
> ```

---

## Step 0 — Login (via provider console/VNC if SSH refuses connections)

In the provider console, run these **one by one** and check what fails:

```bash
# 1. Check if SSH server is installed and running
systemctl status ssh || systemctl status sshd

# 2. If not installed
apt update && apt install -y openssh-server

# 3. Enable and start it
systemctl enable --now ssh

# 4. Make sure it's listening
ss -tlnp | grep :22
# Expected output: a line with LISTEN and sshd on 0.0.0.0:22

# 5. If you see "LISTEN" but still can't connect from outside, open the firewall:
ufw status
ufw allow OpenSSH
# If ufw is "inactive" but still can't connect → check the provider's
# Security Group / external firewall and allow port 22 for your IP.
```

✅ When `ssh root@45.196.196.118` from your PC works, continue below.

---

## Step 1 — Update the server

```bash
apt update && apt upgrade -y
```

---

## Step 2 — Install Git

```bash
apt install -y git
git --version
```

Configure Git (use your real name/email):

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

(Optional but recommended) Add an SSH key so you can pull/push from GitHub:

```bash
ssh-keygen -t ed25519 -C "server-key" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
# Copy the output → GitHub → Settings → SSH and GPG keys → New SSH key
```

---

## Step 3 — Install PHP 8.3 + Laravel extensions

```bash
apt install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
apt update

apt install -y php8.3-fpm php8.3-cli php8.3-common \
  php8.3-mysql php8.3-pgsql php8.3-sqlite3 \
  php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip \
  php8.3-bcmath php8.3-intl php8.3-gd php8.3-redis \
  php8.3-opcache php8.3-readline

php -v            # should show 8.3.x
php -m | head -30 # check extensions loaded
```

---

## Step 4 — Install Composer

```bash
cd /tmp
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
composer --version   # should print version
```

---

## Step 5 — Install MySQL

```bash
apt install -y mysql-server
systemctl enable --now mysql
mysql_secure_installation   # answer: Set root password = yes, rest = yes/enter
```

Create a database + user for Laravel:

```bash
mysql -u root -p
```

Inside MySQL shell run:

```sql
CREATE DATABASE sportx CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'sportx'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_HERE';
GRANT ALL PRIVILEGES ON sportx.* TO 'sportx'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

---

## Step 6 — Install Nginx

```bash
apt install -y nginx
systemctl enable --now nginx
```

Test in browser: `http://45.196.196.118` → should show "Welcome to nginx".

---

## Step 7 — Put the Laravel project on the server

```bash
mkdir -p /var/www
cd /var/www

# From GitHub (recommended):
git clone git@github.com:YOUR_USER/YOUR_REPO.git sportx
# ...or HTTPS:
git clone https://github.com/YOUR_USER/YOUR_REPO.git sportx

cd /var/www/sportx
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate
```

Edit `.env`:

```bash
nano .env
```

Set these values:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=http://45.196.196.118

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=sportx
DB_USERNAME=sportx
DB_PASSWORD=STRONG_PASSWORD_HERE
```

Then migrate:

```bash
php artisan migrate --force
```

---

## Step 8 — Configure Nginx for Laravel

```bash
nano /etc/nginx/sites-available/sportx
```

Paste (replace the **whole file** — delete any `default` line inside):

```nginx
server {
    listen 80;
    server_name 45.196.196.118;
    root /var/www/sportx/public;
    index index.php;

    charset utf-8;
    client_max_body_size 64M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

Enable it and disable default site:

```bash
ln -sf /etc/nginx/sites-available/sportx /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t            # must say "syntax is ok"
systemctl reload nginx
```

---

## Step 9 — Fix permissions

```bash
chown -R www-data:www-data /var/www/sportx
chmod -R 775 /var/www/sportx/storage /var/www/sportx/bootstrap/cache
# check your own deploy user too (e.g. root):
chown -R root:www-data /var/www/sportx
```

---

## Step 10 — Production optimizations

```bash
cd /var/www/sportx
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

If you use queue/scheduler:

```bash
(crontab -l ; echo "* * * * * cd /var/www/sportx && php artisan schedule:run >> /dev/null 2>&1") | crontab -
```

---

## Done — Verify

Open in browser: `http://45.196.196.118`

Troubleshooting if it fails:

```bash
tail -50 /var/www/nginx/error.log
tail -50 /var/log/nginx/error.log
tail -50 /var/www/sportx/storage/logs/laravel.log
systemctl status php8.3-fpm nginx
```

---

## Quick checklist

- [ ] SSH works (`ss -tlnp | grep :22` shows LISTEN)
- [ ] `git --version` works
- [ ] `php -v` shows 8.3
- [ ] `composer --version` works
- [ ] MySQL database `sportx` + user created
- [ ] Nginxsite `sportx` enabled, `default` removed, `nginx -t` passes
- [ ] `.env` configured, `php artisan migrate --force` done
- [ ] Storage + bootstrap/cache owned by `www-data`
- [ ] App loads at `http://45.196.196.118`
