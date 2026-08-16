#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Question 5: Deallocate a VM to stop paying for compute
# ============================================================================
#  Provisions dev-tool-vm (Ubuntu 26.04, Standard_D2s_v3) in a RUNNING state so
#  you have something to deallocate. Real, billable resources (~1-2 min).
#  Re-runnable: if the VM exists but you left it deallocated from a prior run,
#  this restarts it so you begin from a clean 'running' state.
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

RG="$(lab_rg vm05)"
VM="dev-tool-vm"

echo "======================================================"
echo " Question 5 — Deallocate a VM to stop compute billing"
echo "======================================================"

command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

if az vm show -g "$RG" -n "$VM" --output none 2>/dev/null; then
  echo "  [OK] VM '$VM' already exists — ensuring it's running to start clean."
  az vm start -g "$RG" -n "$VM" --output none 2>/dev/null || true
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
echo "   VM name        : ${VM}   (currently: running)"
echo " Your task: put the VM into the state that STOPS compute billing,"
echo "            without deleting it."
echo " Validate with:  ./validate.bash"
echo "======================================================"
