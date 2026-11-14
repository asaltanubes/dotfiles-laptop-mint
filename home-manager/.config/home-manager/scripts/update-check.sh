#!/usr/bin/env bash

# If something goes wrong. Stop, don't try to keep runing commands in case
# something important failed.
set -euo pipefail
HM_DIR="${HOME}/.config/home-manager/"
HM_PROFILE="${HOME}/.local/state/nix/profiles/home-manager"

cd "$HM_DIR"
cp flake.lock flake.lock.backup
# Whatever happens, restore the flake.lock
trap "mv -f flake.lock.backup flake.lock" EXIT

# Wait for network to be on for up to 5*60s~5min
for i in $(sec 1 60); do
  # The if looks for the return value of ping, >/dev/null discards the stdout and
  # 2>&1 discards the stderr output too.
  if ping -c 1 -W 2 github.com >/dev/null 2>&1; then break; fi
  sleep 5
done

nix flake update

NEW_DERIVATION=$(nix path-info --derivation ".#homeConfigurations.\"asaltanubes\".activationPackage")
CURRENT_DERIVATION=$(nix path-info --derivation "$HM_PROFILE")

DIFF=$(nix store diff-closures --derivation "$CURRENT_DERIVATION" "$NEW_DERIVATION")
if [[ -z "$DIFF" ]]; then
  notify-send "Home-manager updates" "Everything is up to date."
else
  notify-send "Home-manager updates" "$(head -n 20 <<< "$DIFF")"
fi

