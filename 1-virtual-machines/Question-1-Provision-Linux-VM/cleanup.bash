#!/usr/bin/env bash
# ============================================================================
#  cleanup.bash — Question 1: Provision a Linux VM
# ============================================================================
#  Deletes EVERYTHING this question created by deleting its resource group.
#  A VM is never just one object — it drags along a disk, a NIC, a public IP,
#  a network security group and a virtual network. Deleting the resource group
#  removes the whole set in one move, so nothing is left quietly billing you.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_config() {
  local dir="$SCRIPT_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/lab-config.sh" ]]; then echo "$dir/lab-config.sh"; return 0; fi
    dir="$(dirname "$dir")"
  done
  return 1
}
CONFIG="$(find_config)" || { echo "ERROR: could not find lab-config.sh" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG"

RG="$(lab_rg vm01)"

echo "Cleaning up Question 1: resource group '$RG'..."

if [[ "$(az group exists --name "$RG" 2>/dev/null)" == "true" ]]; then
  # --no-wait returns immediately; deletion continues in the background.
  az group delete --name "$RG" --yes --no-wait
  echo "[OK] Deletion requested for '$RG' (running in the background)."
  echo "     Confirm it's gone later with:  az group exists --name $RG   # expect: false"
else
  echo "[OK] Resource group '$RG' does not exist — nothing to clean up."
fi
