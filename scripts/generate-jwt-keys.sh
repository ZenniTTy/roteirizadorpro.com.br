#!/usr/bin/env bash
# Generates a 2048-bit RSA key pair for the backend's RS256 JWT signing/verification.
# Outputs two env-var lines suitable for pasting into apps/backend/.env.
#
# The keys themselves are NEVER committed (apps/backend/certs/ and *.pem are gitignored).
# Production keys are managed by the deployment environment, not this script.
#
# Usage:
#   ./scripts/generate-jwt-keys.sh                    # prints to stdout
#   ./scripts/generate-jwt-keys.sh >> apps/backend/.env  # appends to local .env
set -euo pipefail

CERTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/apps/backend/certs"
mkdir -p "$CERTS_DIR"

PRIVATE_PEM="$CERTS_DIR/jwt_private.pem"
PUBLIC_PEM="$CERTS_DIR/jwt_public.pem"

openssl genrsa -out "$PRIVATE_PEM" 2048 2>/dev/null
openssl rsa -in "$PRIVATE_PEM" -out "$PUBLIC_PEM" -outform PEM -pubout 2>/dev/null
chmod 600 "$PRIVATE_PEM"

# Convert real newlines to \n so PEM contents survive a single-line .env value.
escape_pem() {
  awk 'BEGIN{ORS="\\n"} {print}' "$1" | sed 's/\\n$//'
}

cat <<EOF
JWT_PRIVATE_KEY="$(escape_pem "$PRIVATE_PEM")"
JWT_PUBLIC_KEY="$(escape_pem "$PUBLIC_PEM")"
EOF
