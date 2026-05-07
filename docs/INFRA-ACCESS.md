# INFRA-ACCESS.md — Infrastructure Access & Setup Guide

State as of 2026-05-06. Update this file whenever infrastructure changes.

---

## DigitalOcean

**Account status:** Active. Eduardo has owner-level access.
**Droplet status:** Not yet created. Must be provisioned before Sprint 1 begins.

### Panel access

- URL: https://cloud.digitalocean.com
- Login: Eduardo's account (owner)
- Region for all resources: **São Paulo (sfo3 or nyc3 as fallback if SP unavailable)**

### Droplet to provision (Sprint 0 action)

| Field | Value |
|---|---|
| Plan | Basic — $6/month (1GB RAM / 1 vCPU / 25GB SSD) for M1 homologation |
| OS | Ubuntu 24.04 LTS x64 |
| Region | São Paulo |
| Authentication | SSH Key only (add Eduardo's public key at creation time) |
| Hostname | `roteirizador-pro` |
| Backups | Enable at creation ($1.20/month) |

> **After M1 escrow is released:** resize to $48/month (8GB RAM / 4 vCPU) via Droplet → Resize → no data loss. Takes ~2 minutes. Then reimport full Sudeste PBFs via `infra/graphhopper/reimport-sudeste.sh`.

### How to provision the droplet (step by step)

1. Log in at https://cloud.digitalocean.com.
2. Click **Create → Droplets**.
3. Choose region: **São Paulo**.
4. Choose image: **Ubuntu 24.04 LTS x64**.
5. Choose plan: **Basic → Regular → $6/month** (1GB/1vCPU/25GB).
6. Under **Authentication**: select **SSH Key** → add Eduardo's public key (see below).
7. Set hostname: `roteirizador-pro`.
8. Enable **Backups** checkbox.
9. Click **Create Droplet**.
10. Note the droplet's **IPv4 address** — update this doc and `.env` files.
11. Test SSH: `ssh roteirizador@<IP>` (after first-login hardening below).

### Eduardo's SSH public key

Generate if not yet done:

```bash
ssh-keygen -t ed25519 -C "eduardo@ianelli.tech" -f ~/.ssh/roteirizador_pro
```

Public key location: `~/.ssh/roteirizador_pro.pub`

Add this key to the DigitalOcean account under **Settings → Security → SSH Keys** before creating the droplet. The key is added automatically to new droplets at creation time.

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

`<TO BE FILLED after provisioning>`

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
- Build command: `npm run build`
- Output directory: `.next`

> Configure in Vercel → Project → Settings → Git → Root Directory = `apps/landing`

### Environment variables (Vercel)

Set in Vercel → Project → Settings → Environment Variables:

| Key | Value | Environment |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | `https://api.roteirizadorpro.com.br` | Production |
| `NEXT_PUBLIC_API_URL` | `http://localhost:3000` | Development |
| `NEXT_PUBLIC_APK_URL` | `https://roteirizadorpro.com.br/download` | Production |

### Ownership transfer (end of M1)

At handoff, transfer the Vercel project to the client:

1. Vercel → Project → Settings → Transfer Project.
2. Enter client's Vercel account email.
3. Client accepts the transfer invitation.
4. Eduardo remains as a team member (collaborator) if ongoing support is agreed.

---

## Local Development Environment

What Eduardo needs on his Mac before starting Phase 1.

### Required tools

```bash
# Flutter stable
flutter channel stable
flutter upgrade
flutter --version  # should be 3.x

# Node.js 20 LTS (via nvm)
nvm install 20
nvm use 20
node --version  # should be v20.x

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
npm run dev
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

### When client resolves the card issue

- [ ] Provision $6/month droplet following "How to provision" above.
- [ ] Note droplet IP — update this doc and DNS.
- [ ] Run first login sequence above.
- [ ] Continue with Sprint 1 server tasks in `TODO.md`.

### At M1 handoff

- [ ] Confirm client has DigitalOcean owner access.
- [ ] Transfer Vercel project to client.
- [ ] Transfer GitHub repo to client.
- [ ] Record Loom video covering the four M1 approval criteria.

---

## Secrets Inventory

Secrets that will exist in production. None are committed to Git.

| Secret | Where stored | Who has it |
|---|---|---|
| Postgres password | `/opt/roteirizador/certs/.env` on server | Eduardo |
| Redis password | Same | Eduardo |
| JWT private key (`jwt-private.pem`) | `/opt/roteirizador/certs/` | Eduardo |
| JWT public key (`jwt-public.pem`) | `/opt/roteirizador/certs/` | Eduardo |
| Efi Bank `.p12` certificate | `/opt/roteirizador/certs/efi-prod.p12` | Eduardo + client |
| Efi Client ID | `.env` on server | Eduardo + client |
| Efi Client Secret | `.env` on server | Eduardo + client |
| Efi webhook HMAC secret | `.env` on server | Eduardo + client |

At M1 handoff, Eduardo provides the client with all secrets in an encrypted format (1Password shared vault or similar). The client is responsible for backing them up.
