#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Question 2: Open a Port with a Network Security Group
# ============================================================================
#  This question needs a VM to already exist so you can open a port ON it.
#  So setup PROVISIONS that VM for you (Ubuntu 26.04, Standard_B2als_v2), running,
#  with only SSH open by default. Opening port 8080 is your job.
#
#  Provisioning creates real, billable resources and takes ~1-2 minutes.
#  This script is safe to re-run: it skips anything that already exists.
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

RG="$(lab_rg vm02)"
VM="dev-tool-vm"

echo "======================================================"
echo " Question 2 — Open a Port with a Network Security Group"
echo "======================================================"

# --- preflight --------------------------------------------------------------
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

# --- provision the resource group + VM (idempotent) -------------------------
echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

if az vm show -g "$RG" -n "$VM" --output none 2>/dev/null; then
  echo "  [OK] VM '$VM' already exists — reusing it."
else
  echo "  Provisioning VM '$VM' (Ubuntu 26.04, Standard_B2als_v2)... this takes ~1-2 min."
  az vm create \
    --resource-group "$RG" \
    --name           "$VM" \
    --image          Canonical:ubuntu-26_04-lts:server:latest \
    --size           Standard_B2als_v2 \
    --admin-username "$LAB_ADMIN_USER" \
    --generate-ssh-keys \
    --output none
  echo "  [OK] VM provisioned and running."
fi

echo "------------------------------------------------------"
echo " The tool serves on TCP 8080 but the port is closed."
echo "   Resource group : ${RG}"
echo "   VM name        : ${VM}"
echo " Your task: open inbound TCP 8080 — and nothing else."
echo " Validate with:  ./validate.bash"
echo "======================================================"
