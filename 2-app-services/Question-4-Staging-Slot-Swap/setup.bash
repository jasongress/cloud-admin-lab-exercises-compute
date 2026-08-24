#!/usr/bin/env bash
# ============================================================================
#  setup.bash — App Service Q4: Zero-Downtime Release with a Staging Slot
# ============================================================================
#  Deployment slots require the STANDARD tier, so this provisions an S1 plan +
#  web app, and marks production as RELEASE=v1 (your "current version").
#  Real, billable resources (~1-2 min). Re-runnable.
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

RG="$(lab_rg app04)"
PLAN="dev-tool-plan"

echo "======================================================"
echo " App Service Q4 — Staging Slot + Swap"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

APP="$(az webapp list -g "$RG" --query "[0].name" -o tsv 2>/dev/null)"
if [[ -n "$APP" ]]; then
  echo "  [OK] Web app '$APP' already exists — reusing it."
else
  echo "  Provisioning App Service plan '$PLAN' (Linux S1 / Standard)..."
  az appservice plan create -g "$RG" -n "$PLAN" --sku S1 --is-linux --output none
  APP="dev-tool-app-${RANDOM}${RANDOM}"
  echo "  Provisioning web app '$APP' (NODE:22-lts)... ~1-2 min."
  az webapp create -g "$RG" --plan "$PLAN" -n "$APP" --runtime "NODE:22-lts" --output none
  echo "  Marking current production release as RELEASE=v1..."
  az webapp config appsettings set -g "$RG" -n "$APP" --settings RELEASE=v1 --output none
  echo "  [OK] Web app '$APP' provisioned (production RELEASE=v1)."
fi

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   Web app        : ${APP}"
echo "   Production now : RELEASE=$(az webapp config appsettings list -g "$RG" -n "$APP" --query "[?name=='RELEASE'].value | [0]" -o tsv 2>/dev/null)"
echo " Your task: create a 'staging' slot, set RELEASE=v2 there, then swap it"
echo "            into production (so production ends up on RELEASE=v2)."
echo " Validate with:  ./validate.bash"
echo "======================================================"
