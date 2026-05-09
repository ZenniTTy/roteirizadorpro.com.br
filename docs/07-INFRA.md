# 07 — Infrastructure

State as of 2026-05-07. Update this file whenever infrastructure changes.

---

## DigitalOcean

**Account status:** Active. Team `roteirizadorpro` (uuid `34eaabde-0f22-462c-86e8-7facaad4a7c4`). Email `zennitty@proton.me`.
**Droplet status:** Provisioned 2026-05-08 via DO API session 07. ID `569830613`. 1GB plan; resize to 4-8GB post-M1.
**Droplet IPv4:** `138.197.38.243` (NYC3).
**Hostname:** `roteirizador-pro`
**Region:** `nyc3` (DigitalOcean does not have a São Paulo datacenter — confirmed via `/v2/regions`. Available regions for `s-1vcpu-1gb`: nyc1/2/3, sfo2/3, ams3, fra1, lon1, sgp1, syd1, blr1, tor1. NYC3 picked for proximity to BR users (~100-150ms RTT).)
**Tags:** `roteirizador-pro`, `m1`, `production`.
**Image:** `ubuntu-24-04-x64`.
**Cloud-init bootstrap:** ran on first boot — see `/tmp/roteirizador-cloud-init.yml` (the user_data) and the equivalent `scripts/server-bootstrap.sh` for what was applied.
**M1 acceptance baseline snapshot:** `m1-acceptance-baseline-20260509` (action id `3177273363`, taken 2026-05-09 04:21Z).
**Swap:** 2 GB swap file at `/swapfile` (added during deploy because GraphHopper graph build approached 800 MB heap on a 1 GB host).
**TLS cert:** Let's Encrypt for `api.roteirizadorpro.com.br`, expires 2026-08-07. Auto-renew via `certbot.timer` systemd unit.
**Postgres backups:** daily 03:00 (cron) → `/opt/roteirizador/backups/`, 30-day rotation. Restore drill verified 2026-05-09.

### Panel access

- URL: https://cloud.digitalocean.com
- Login: Client's account; Eduardo has admin via DO Team
- Region for all resources: **São Paulo (sfo3 or nyc3 as fallback if SP unavailable)**

### Eduardo's SSH public key

Generated 2026-05-08 with `ssh-keygen -t ed25519 -C "eduardo@ianelli.tech" -f ~/.ssh/roteirizador_pro -N ""`.

- **Path on laptop:** `~/.ssh/roteirizador_pro` (private), `~/.ssh/roteirizador_pro.pub` (public)
- **Fingerprint:** `SHA256:9FLpFCVU9rZX8TUpP/axoPYrSYYu0yIqxU3VJmHuWvg`
- **Comment:** `eduardo@ianelli.tech`
- **Passphrase:** none (the dedicated key is for unattended deploy automation; the laptop's encrypted home is the security boundary)

The key is uploaded to the DigitalOcean account once (via API in session 07 / 08) and then attached at droplet-creation time so cloud-init can drop it into `/root/.ssh/authorized_keys` on first boot.

### First login sequence (after droplet is created)

Run these in order. Do not skip steps.

```bash
# 1. SSH as root (only this once)
ssh root@<DROPLET_IP>

# 2. Create non-root user
adduser roteirizador
usermod -aG sudo roteirizador

# 3. Copy SSH key to new user
rsync --archive --chown=roteirizador:roteirizador ~/.ssh /home/roteirizador

# 4. Test new user in a second terminal before closing root session
ssh roteirizador@<DROPLET_IP>

# 5. Disable root login and password auth
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no
sudo systemctl restart sshd

# 6. Firewall
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
sudo ufw status

# 7. fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 8. Timezone and hostname
sudo timedatectl set-timezone America/Sao_Paulo
sudo hostnamectl set-hostname roteirizador-pro

# 9. Unattended upgrades
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### DNS records to configure (after droplet IP is known)

These records go in the DNS provider for `roteirizadorpro.com.br` (client's registrar):

| Type | Name | Value | TTL |
|---|---|---|---|
| A | `api` | `<DROPLET_IP>` | 300 |

`roteirizadorpro.com.br` apex and `www` point to Vercel (see below).

### Droplet IPv4

`138.197.38.243` — captured from droplet creation response, session 07.

### Docker installation (Sprint 1 — Day 2)

```bash
# Install Docker Engine (official repo)
sudo apt update
sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker roteirizador
newgrp docker

# Verify
docker run hello-world
```

### Directory structure on server

```
/opt/roteirizador/
├── compose/        ← docker-compose.yml lives here
├── data/
│   ├── postgres/   ← Postgres volume
│   ├── redis/      ← Redis volume
│   └── graphhopper/
│       ├── pbf/    ← OSM PBF files
│       └── graph-cache/  ← built graph
├── backups/        ← pg_dump daily output
├── logs/
└── certs/          ← efi .p12, JWT keys (chmod 600, never in Git)
```

Create on first login:

```bash
sudo mkdir -p /opt/roteirizador/{compose,data/postgres,data/redis,data/graphhopper/pbf,data/graphhopper/graph-cache,backups,logs,certs}
sudo chown -R roteirizador:roteirizador /opt/roteirizador
```

---

## Vercel

**Account status:** Active. Eduardo has owner-level access.
**Project status:** Already created.

### Panel access

- URL: https://vercel.com/dashboard
- Login: Eduardo's account (owner)
- Project name: `<confirm and fill in>`
- Project URL (staging): `<fill in after confirming>`
- Production domain: `roteirizadorpro.com.br`

### Domain configuration

In the Vercel project settings under **Domains**, add:

| Domain | Type |
|---|---|
| `roteirizadorpro.com.br` | Apex (A record or Vercel nameservers) |
| `www.roteirizadorpro.com.br` | CNAME → `cname.vercel-dns.com` |

In the client's DNS provider, add:

| Type | Name | Value |
|---|---|---|
| A | `@` (apex) | `76.76.21.21` (Vercel's IP) |
| CNAME | `www` | `cname.vercel-dns.com` |

> If the DNS provider supports CNAME flattening (Cloudflare does), use CNAME for apex too.

### Git integration

- Repository: `github.com/ZenniTTy/-APP---Entrega-Smart` (monorepo)
- Root directory in Vercel: `apps/landing`
- Branch: `develop` → auto-deploy on push (staging)
- Branch: `main` → auto-deploy on push (production)
- Install command: `bun install` (Vercel auto-detects `bun.lock` since 2024-09; explicit setting recommended)
- Build command: `bun run build`
- Output directory: `.next`

> Configure in Vercel → Project → Settings → Git → Root Directory = `apps/landing`

### Environment variables (Vercel)

Set in Vercel → Project → Settings → Environment Variables:

| Key | Value | Environment |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | `https://api.roteirizadorpro.com.br` | Production |
| `NEXT_PUBLIC_API_URL` | `http://localhost:3000` | Development |
| `NEXT_PUBLIC_APK_URL` | `https://roteirizadorpro.com.br/download` | Production |

---

## Local Development Environment

What Eduardo needs on his Mac before starting Phase 1.

### Required tools

```bash
# Flutter stable
flutter channel stable
flutter upgrade
flutter --version  # should be 3.x

# Node.js 20 LTS (via nvm) — runtime
nvm install 20
nvm use 20
node --version  # should be v20.x

# Bun 1.3+ — package manager (per ADR-0011)
curl -fsSL https://bun.sh/install | bash
bun --version  # should be 1.3.x

# Docker Desktop for Mac
# Download from https://www.docker.com/products/docker-desktop

# Verify Docker
docker --version
docker compose version
```

### Local services (via docker compose)

When `infra/docker-compose.yml` is ready, local dev starts with:

```bash
cd infra
docker compose up -d postgres redis graphhopper
# Backend runs natively (not in Docker) during dev for hot-reload
cd ../apps/backend
bun run dev
```

### Flutter device setup

```bash
# List connected devices
flutter devices

# Run on Android emulator or physical device
cd apps/mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` is the Android emulator's alias for `localhost` on the host machine.

---

## What to Do Next (Ordered)

### Immediately (no server needed)

- [ ] Confirm Vercel project name and staging URL — update this doc.
- [ ] Generate SSH keypair for the droplet (`ssh-keygen -t ed25519`). Add public key to DigitalOcean account.
- [ ] Install Flutter stable, Node.js 20, Docker Desktop on dev machine.
- [ ] Start Phase 1: `flutter create apps/mobile/` — see `TODO.md`.

### Post-M1 (after escrow release)

- [ ] Resize droplet to 8GB via DigitalOcean panel (~2 minutes, no data loss).
- [ ] Run `infra/graphhopper/reimport-sudeste.sh` to load Sudeste full graph (SP+RJ+MG+ES). Plan ~30–90 min downtime.
- [ ] Update GraphHopper `Xmx` to ~4GB after resize.

---

## Secrets Inventory (M1)

> Only M1-relevant secrets are listed. M2 secrets (Efí `.p12`, Efí client secrets, HMAC) come during M2 work.

Secrets that will exist in production. None are committed to Git.

| Secret | Where stored | Who has it |
|---|---|---|
| Postgres password | `/opt/roteirizador/compose/.env` (chmod 600) | Eduardo |
| JWT private key (RS256 PEM) | Same `.env` as `JWT_PRIVATE_KEY` | Eduardo |
| JWT public key (RS256 PEM) | Same `.env` as `JWT_PUBLIC_KEY` | Eduardo |
| (Reserved) Redis password | Same — currently unused on M1 | Eduardo |

## Production .env template

**Location on the droplet:** `/opt/roteirizador/compose/.env` (`chmod 600`, owned by `roteirizador`).
**Loaded by:** the `roteirizador-backend` systemd unit (`EnvironmentFile=`) and `docker compose` (variables consumed by `docker-compose.yml`).

Generate JWT keys locally on the laptop with `scripts/generate-jwt-keys.sh`, then paste the two PEM lines into the corresponding `JWT_*_KEY` slots below.

```env
NODE_ENV=production
PORT=3000

# Strong password generated locally with: openssl rand -base64 32
DATABASE_URL=postgresql://roteirizador:<STRONG-PASSWORD>@127.0.0.1:5432/roteirizador?schema=public

# Generated by scripts/generate-jwt-keys.sh — single-line with literal \n.
# Do NOT reuse dev keys.
JWT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
ACCESS_TOKEN_TTL_SECONDS=900
REFRESH_TOKEN_TTL_SECONDS=604800

# Production allowed origins.
CORS_ORIGINS=https://roteirizadorpro.com.br,https://www.roteirizadorpro.com.br

# GraphHopper sidecar (same droplet, loopback).
GRAPHHOPPER_BASE_URL=http://127.0.0.1:8989

# Reserved for M2.
REDIS_URL=redis://127.0.0.1:6379
```

**Differences vs `apps/backend/.env.example` (dev):**

| Key | Dev | Production |
|---|---|---|
| `NODE_ENV` | `development` | `production` |
| `DATABASE_URL` password | `roteirizador` (loopback dev) | strong, generated per-droplet |
| `JWT_*_KEY` | dev keypair | dedicated production keypair (different from dev) |
| `CORS_ORIGINS` | localhost + production | production only |
