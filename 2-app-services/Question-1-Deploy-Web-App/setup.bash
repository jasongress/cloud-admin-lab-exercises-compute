#!/usr/bin/env bash
# ============================================================================
#  setup.bash — App Service Question 1: Deploy a Web App
# ============================================================================
#  Building the App Service plan and web app IS the exercise, so setup only
#  preflights your environment and shows the target. Nothing is provisioned here.
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

RG="$(lab_rg app01)"

echo "======================================================"
echo " App Service Q1 — Deploy a Web App"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
command -v curl >/dev/null 2>&1 || echo "  [!] 'curl' not found — you'll need it to test the app (sudo apt-get install -y curl)."
echo "  [OK] Azure CLI present and logged in."

echo "------------------------------------------------------"
echo " Your target:"
echo "   Resource group : ${RG}"
echo "   Region         : ${LAB_LOCATION}"
echo "   Plan           : Linux, a paid tier such as B1 (Basic)"
echo "   Web app        : a globally-unique name, Node runtime (e.g. NODE:22-lts)"
echo " Your task: create the resource group, an App Service plan, and a web app,"
echo "            then confirm it answers 200 at https://<name>.azurewebsites.net"
echo " Validate with:  ./validate.bash"
echo "======================================================"
