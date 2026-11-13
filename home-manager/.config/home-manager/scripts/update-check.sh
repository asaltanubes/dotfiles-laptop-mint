#!/usr/bin/env bash

set -euo pipefail
HM_DIR="${HOME}/.config/home-manager/"
HM_PROFILE="${HOME}/.local/state/nix/profiles/home-manager"

cd "$HM_DIR"
cp flake.lock flake.lock.backup
trap "mv -f flake.lock.backup flake.lock" EXIT

nix flake update

NEW_DERIVATION=$(nix path-info --derivation ".#homeConfigurations.\"asaltanubes\".activationPackage")
CURRENT_DERIVATION=$(nix path-info --derivation "$HM_PROFILE")

DIFF=$(nix store diff-closures --derivation "$CURRENT_DERIVATION" "$NEW_DERIVATION")
if [[ -z "$DIFF" ]]; then
  notify-send "Home-manager updates" "Everything is up to date."
else
  notify-send "Home-manager updates" "$(head -n 20 <<< "$DIFF")"
fi

