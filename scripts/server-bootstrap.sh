#!/usr/bin/env bash
# Roteirizador Pro — server bootstrap (Ubuntu 24.04 LTS).
#
# Codifies the manual procedure documented in docs/07-INFRA.md. Run as the
# initial root user immediately after droplet creation; the script creates a
# non-root sudo user, hardens SSH, installs UFW + fail2ban + Docker Engine +
# unattended-upgrades, and lays down the /opt/roteirizador/ tree.
#
# Idempotent: safe to re-run. Each section detects already-applied state and
# skips the operation rather than overwriting.
#
# Usage (as root, on the droplet):
#   curl -fsSL https://raw.githubusercontent.com/ZenniTTy/-APP---Entrega-Smart/develop/scripts/server-bootstrap.sh \
#     | bash -s -- <ssh_pubkey>
# OR (after cloning the repo):
#   sudo ./scripts/server-bootstrap.sh "<ssh_pubkey>"
#
# Argument:
#   $1 — ssh_pubkey: the OpenSSH public key (one line, e.g. "ssh-ed25519 AAAA... eduardo@ianelli.tech")
#                    that will be authorized for the new roteirizador user.
#
# After this script:
#   - Re-login as roteirizador (NOT root): `ssh roteirizador@<droplet>`
#   - Clone the repo to /opt/roteirizador/compose/
#   - Drop the production .env in /opt/roteirizador/compose/.env (chmod 600)
#   - rsync the prepared graph-cache from your laptop (scripts/rsync-graph-cache.sh)
#   - `cd /opt/roteirizador/compose && docker compose up -d`

set -euo pipefail

DEPLOY_USER="${DEPLOY_USER:-roteirizador}"
HOSTNAME="${HOSTNAME_OVERRIDE:-roteirizador-pro}"
TIMEZONE="${TIMEZONE:-America/Sao_Paulo}"
SSH_PUBKEY="${1:-}"

log()  { printf "\n\033[1;36m[bootstrap]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[bootstrap warn]\033[0m %s\n" "$*"; }
fail() { printf "\n\033[1;31m[bootstrap fail]\033[0m %s\n" "$*"; exit 1; }

[[ "$(id -u)" -eq 0 ]] || fail "Run as root. (sudo ./scripts/server-bootstrap.sh ...)"
[[ -n "$SSH_PUBKEY" ]]  || fail "ssh_pubkey arg required. See script header."

# 1 — System update + base packages -------------------------------------------
log "1/9  apt update + base packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg lsb-release ufw fail2ban \
  unattended-upgrades rsync git

# 2 — Non-root sudo user with the provided SSH key ----------------------------
log "2/9  create user '$DEPLOY_USER' (if missing)"
if ! id -u "$DEPLOY_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$DEPLOY_USER"
  usermod -aG sudo "$DEPLOY_USER"
  # Passwordless sudo for the deploy user (needed for docker group activation
  # via newgrp and for cron-driven backups). The user is restricted by SSH
  # key + UFW + fail2ban.
  echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$DEPLOY_USER"
  chmod 0440 "/etc/sudoers.d/$DEPLOY_USER"
else
  log "  ✓ user $DEPLOY_USER already exists"
fi

install -d -o "$DEPLOY_USER" -g "$DEPLOY_USER" -m 0700 "/home/$DEPLOY_USER/.ssh"
AUTH_KEYS="/home/$DEPLOY_USER/.ssh/authorized_keys"
touch "$AUTH_KEYS"
chmod 0600 "$AUTH_KEYS"
chown "$DEPLOY_USER:$DEPLOY_USER" "$AUTH_KEYS"
if ! grep -qF "$SSH_PUBKEY" "$AUTH_KEYS"; then
  echo "$SSH_PUBKEY" >> "$AUTH_KEYS"
  log "  ✓ ssh key authorized for $DEPLOY_USER"
else
  log "  ✓ ssh key already authorized"
fi

# 3 — SSH hardening (only after the key is in place) --------------------------
log "3/9  SSH hardening (PermitRootLogin no, PasswordAuthentication no)"
SSHD_CONF="/etc/ssh/sshd_config"
SSHD_DROP="/etc/ssh/sshd_config.d/10-roteirizador-hardening.conf"
cat > "$SSHD_DROP" <<EOF
# Managed by server-bootstrap.sh — do not edit by hand.
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
chmod 0644 "$SSHD_DROP"
sshd -t                                 # validate config
systemctl reload ssh

# 4 — UFW firewall ------------------------------------------------------------
log "4/9  UFW (allow 22, 80, 443; default deny incoming)"
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP (Certbot + Nginx redirect)'
ufw allow 443/tcp comment 'HTTPS (api.roteirizadorpro.com.br)'
ufw --force enable
ufw status verbose

# 5 — fail2ban (sshd jail) ----------------------------------------------------
log "5/9  fail2ban (sshd jail, 1h ban after 3 failures in 10 min)"
JAIL_LOCAL="/etc/fail2ban/jail.local"
cat > "$JAIL_LOCAL" <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
backend = systemd

[sshd]
enabled = true
EOF
chmod 0644 "$JAIL_LOCAL"
systemctl enable --now fail2ban
systemctl restart fail2ban

# 6 — Hostname + timezone + unattended-upgrades -------------------------------
log "6/9  hostname=$HOSTNAME, timezone=$TIMEZONE, unattended-upgrades"
hostnamectl set-hostname "$HOSTNAME"
timedatectl set-timezone "$TIMEZONE"
# Enable security updates auto-install. The dpkg-reconfigure approach in
# 07-INFRA.md is interactive — this drop-in is the equivalent non-interactive form.
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# 7 — Docker Engine (official Ubuntu repo, modern keyring location) -----------
log "7/9  Docker Engine + Compose plugin"
if ! command -v docker >/dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable
EOF
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
else
  log "  ✓ docker already installed ($(docker --version))"
fi
usermod -aG docker "$DEPLOY_USER" || true
systemctl enable --now docker

# 8 — /opt/roteirizador/ tree -------------------------------------------------
log "8/9  /opt/roteirizador/ directory tree"
install -d -o "$DEPLOY_USER" -g "$DEPLOY_USER" -m 0755 \
  /opt/roteirizador \
  /opt/roteirizador/compose \
  /opt/roteirizador/data \
  /opt/roteirizador/data/postgres \
  /opt/roteirizador/data/redis \
  /opt/roteirizador/data/graphhopper \
  /opt/roteirizador/data/graphhopper/pbf \
  /opt/roteirizador/data/graphhopper/graph-cache \
  /opt/roteirizador/backups \
  /opt/roteirizador/logs
install -d -o "$DEPLOY_USER" -g "$DEPLOY_USER" -m 0700 \
  /opt/roteirizador/certs

# 9 — Summary -----------------------------------------------------------------
log "9/9  done"
cat <<EOF

──────────────────────────────────────────────────────────────────────────
  Bootstrap complete on $(hostname).

  Next steps (from your laptop):
    1.  ssh ${DEPLOY_USER}@<this server>
    2.  git clone https://github.com/ZenniTTy/-APP---Entrega-Smart.git \\
            /opt/roteirizador/compose/repo
    3.  cp /opt/roteirizador/compose/repo/infra/docker-compose.yml \\
            /opt/roteirizador/compose/
    4.  Drop the production .env into /opt/roteirizador/compose/.env (chmod 600).
    5.  rsync the laptop graph-cache:
            ./scripts/rsync-graph-cache.sh ${DEPLOY_USER}@<this server>
    6.  cd /opt/roteirizador/compose && docker compose up -d
    7.  Configure Nginx + Certbot (see docs/INSTALL.md §5).

  Services already running on this host:
    docker     — $(docker --version 2>/dev/null || echo NOT INSTALLED)
    fail2ban   — $(systemctl is-active fail2ban)
    ufw        — $(ufw status | head -1)
    timezone   — $(timedatectl show -p Timezone --value)
    hostname   — $(hostname)
──────────────────────────────────────────────────────────────────────────
EOF
