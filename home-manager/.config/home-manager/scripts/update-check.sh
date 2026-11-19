#!/usr/bin/env bash

# If something goes wrong. Stop, don't try to keep runing commands in case
# something important failed.
set -euo pipefail
HM_DIR="${HOME}/.config/home-manager/"
HM_PROFILE="${HOME}/.local/state/nix/profiles/home-manager"

# Wait for network to be on for up to 5*60s~5min
for _ in $(seq 1 60); do
  # The if looks for the return value of ping, >/dev/null discards the stdout and
  # 2>&1 discards the stderr output too.
  if ping -c 1 -W 2 github.com >/dev/null 2>&1; then break; fi
  sleep 5
done

cd "$HM_DIR"
cp flake.lock flake.lock.backup
# Whatever happens, restore the flake.lock
trap "mv -f flake.lock.backup flake.lock" EXIT

nix flake update


DIFF=$(home-manager build && nvd diff "$HM_PROFILE" result | tail -n +3)
trap "mv -f flake.lock.backup flake.lock; rm -rf result" EXIT

if [[ -z "$DIFF" ]]; then
  notify-send "Home-manager updates" "Everything is up to date."
else
  notify-send "Home-manager updates" "$(head -n 20 <<< "$DIFF")"
fi

nix store gc
