#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Question 4: Attach a Data Disk
# ============================================================================
#  Provisions dev-tool-vm (Ubuntu 26.04, Standard_D2s_v3) so you have a VM to
#  attach a disk to. Creates real, billable resources (~1-2 min). Re-runnable.
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

RG="$(lab_rg vm04)"
VM="dev-tool-vm"

echo "======================================================"
echo " Question 4 — Attach a Data Disk"
echo "======================================================"

command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

if az vm show -g "$RG" -n "$VM" --output none 2>/dev/null; then
  echo "  [OK] VM '$VM' already exists — reusing it."
else
  echo "  Provisioning VM '$VM' (Ubuntu 26.04, Standard_D2s_v3)... ~1-2 min."
  az vm create \
    --resource-group "$RG" \
    --name           "$VM" \
    --image          Canonical:ubuntu-26_04-lts:server:latest \
    --size           Standard_D2s_v3 \
    --admin-username "$LAB_ADMIN_USER" \
    --generate-ssh-keys \
    --output none
  echo "  [OK] VM provisioned and running."
fi

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   VM name        : ${VM}"
echo " Your task: create + attach a 32 GiB managed data disk named 'dev-tool-data'."
echo " Validate with:  ./validate.bash"
echo "======================================================"
