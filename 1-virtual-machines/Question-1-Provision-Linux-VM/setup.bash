#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Question 1: Provision a Linux VM
# ============================================================================
#  This question has NOTHING to pre-create for you: provisioning the resource
#  group and the VM is the whole exercise. So setup does two useful things:
#    1. Confirms your environment is ready (az installed + you're logged in).
#    2. Prints the exact names and region the validator will check, so you know
#       your target before you start typing.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- locate and source the shared lab config (walk up to find it) -----------
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
VM="dev-tool-vm"

echo "======================================================"
echo " Question 1 — Provision a Linux VM"
echo "======================================================"

# --- preflight: is the Azure CLI installed? ---------------------------------
if ! command -v az >/dev/null 2>&1; then
  echo "  [X] Azure CLI ('az') is not installed."
  echo "      Install it: https://learn.microsoft.com/cli/azure/install-azure-cli"
  exit 1
fi
echo "  [OK] Azure CLI is installed."

# --- preflight: are you logged in? ------------------------------------------
if ! az account show >/dev/null 2>&1; then
  echo "  [X] You are not logged in. Run:  az login"
  exit 1
fi
SUB_NAME="$(az account show --query name -o tsv 2>/dev/null)"
echo "  [OK] Logged in. Active subscription: ${SUB_NAME}"

echo "------------------------------------------------------"
echo " Your target (this is what the validator checks for):"
echo "   Resource group : ${RG}"
echo "   Region         : ${LAB_LOCATION}"
echo "   VM name        : ${VM}"
echo "   Image          : Ubuntu 26.04 LTS (Canonical, offer ubuntu-26_04-lts)"
echo "   Size           : Standard_B2als_v2"
echo "   Admin user     : ${LAB_ADMIN_USER}"
echo "------------------------------------------------------"
echo " Read problem.md for the full requirements, then build your solution."
echo " Validate with:  ./validate.bash"
echo "======================================================"
