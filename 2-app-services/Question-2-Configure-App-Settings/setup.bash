#!/usr/bin/env bash
# ============================================================================
#  setup.bash — App Service Q2: Configure App Settings
# ============================================================================
#  Configuring the app is the exercise, so setup PROVISIONS the plan + web app
#  for you (Linux B1, Node). Real, billable resources (~1 min). Re-runnable:
#  reuses an existing app in the resource group instead of creating a second.
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

RG="$(lab_rg app02)"
PLAN="dev-tool-plan"

echo "======================================================"
echo " App Service Q2 — Configure App Settings"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

EXISTING_APP="$(az webapp list -g "$RG" --query "[0].name" -o tsv 2>/dev/null)"
if [[ -n "$EXISTING_APP" ]]; then
  echo "  [OK] Web app '$EXISTING_APP' already exists — reusing it."
else
  echo "  Provisioning App Service plan '$PLAN' (Linux B1)..."
  az appservice plan create -g "$RG" -n "$PLAN" --sku B1 --is-linux --output none
  APP="dev-tool-app-${RANDOM}${RANDOM}"
  echo "  Provisioning web app '$APP' (NODE:22-lts)... ~1 min."
  az webapp create -g "$RG" --plan "$PLAN" -n "$APP" --runtime "NODE:22-lts" --output none
  echo "  [OK] Web app '$APP' provisioned."
fi

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   Web app        : $(az webapp list -g "$RG" --query "[0].name" -o tsv 2>/dev/null)"
echo " Your task: add app settings  ENVIRONMENT=production  and  FEATURE_FLAG=beta"
echo " Validate with:  ./validate.bash"
echo "======================================================"
