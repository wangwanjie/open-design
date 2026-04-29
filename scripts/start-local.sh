#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export VITE_HOST="${VITE_HOST:-0.0.0.0}"
export VITE_PORT="${VITE_PORT:-5173}"
export OD_PORT="${OD_PORT:-7456}"
export COREPACK_HOME="${COREPACK_HOME:-/tmp/corepack}"

required_node="$(tr -d '[:space:]' < .nvmrc 2>/dev/null || true)"

if [[ -n "${NVM_DIR:-}" && -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
  nvm use "$required_node"
elif [[ -n "$required_node" ]]; then
  shopt -s nullglob
  node_dirs=("$HOME/.nvm/versions/node/v${required_node}"*)
  shopt -u nullglob
  if [[ ${#node_dirs[@]} -gt 0 ]]; then
    last_node_index=$((${#node_dirs[@]} - 1))
    export PATH="${node_dirs[$last_node_index]}/bin:$PATH"
  fi
fi

node_major="$(node -p "Number(process.versions.node.split('.')[0])" 2>/dev/null || echo 0)"
if (( node_major < 20 || node_major >= 23 )); then
  echo "Open Design requires Node >=20 <23. Current: $(node --version 2>/dev/null || echo missing)" >&2
  echo "Install Node 22 or set PATH to a compatible Node before running this script." >&2
  exit 1
fi

if [[ ! -d node_modules ]]; then
  echo "node_modules not found; installing dependencies with pnpm..."
  corepack pnpm install
fi

echo "Starting Open Design"
echo "  Web:    http://localhost:${VITE_PORT}"
echo "  LAN:    http://$(ipconfig getifaddr en0 2>/dev/null || hostname):${VITE_PORT}"
echo "  Daemon: http://127.0.0.1:${OD_PORT}"
echo

exec corepack pnpm dev:all
