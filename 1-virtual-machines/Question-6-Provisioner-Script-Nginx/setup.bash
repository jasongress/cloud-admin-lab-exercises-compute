#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Question 6: Provision a web server with a provisioner script
# ============================================================================
#  Provisioning the VM WITH its provisioner script is the whole exercise, so
#  setup only preflights your environment and shows you the target. You build
#  the VM (Ubuntu 26.04 + cloud-init that installs nginx) and open port 80.
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

RG="$(lab_rg vm06)"
VM="dev-tool-vm"

echo "======================================================"
echo " Question 6 — Provision a Web Server with a Provisioner Script"
echo "======================================================"

command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
command -v curl >/dev/null 2>&1 || echo "  [!] 'curl' not found — you'll need it to test the web server (sudo apt-get install -y curl)."
echo "  [OK] Azure CLI present and logged in."

echo "------------------------------------------------------"
echo " Your target:"
echo "   Resource group : ${RG}"
echo "   Region         : ${LAB_LOCATION}"
echo "   VM name        : ${VM}"
echo "   Image / size   : Ubuntu 26.04 (Canonical:ubuntu-26_04-lts:server:latest) / Standard_B2als_v2"
echo " Your task:"
echo "   1. Provision the VM with a PROVISIONER SCRIPT (cloud-init) that installs nginx."
echo "   2. Open inbound TCP port 80."
echo "   3. Confirm: curl http://<public-ip> returns the nginx page."
echo " Give cloud-init 1-2 min after create before validating."
echo " Validate with:  ./validate.bash"
echo "======================================================"
