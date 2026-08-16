#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Question 6: Provision a web server with a provisioner script
# ============================================================================
#  Read-only. Confirms nginx is actually serving by CURLING the VM's public IP,
#  exactly the way a user would reach it. Exit = number of failed checks.
#  Requires: curl (to test the web server over the network).
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

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

# --- helpers (clean single-quoted JMESPath + curl over the network) ---------
public_ip() {
  az vm list-ip-addresses -g "$RG" -n "$VM" \
    --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>/dev/null
}

# An inbound Allow rule opens TCP 80 (robust to both destinationPortRange and *Ranges)
port_80_open() {
  az network nsg list -g "$RG" \
    --query "[].securityRules[?access=='Allow' && direction=='Inbound'].[destinationPortRange, destinationPortRanges]" \
    -o tsv 2>/dev/null | grep -qw 80
}

# curl retries a few times so a just-finished cloud-init still passes.
http_200() {
  local ip; ip="$(public_ip)"; [[ -z "$ip" ]] && return 1
  [[ "$(curl -s -o /dev/null -w '%{http_code}' \
        --retry 3 --retry-delay 3 --retry-connrefused --max-time 20 \
        "http://$ip" 2>/dev/null)" == "200" ]]
}

nginx_serving() {
  local ip; ip="$(public_ip)"; [[ -z "$ip" ]] && return 1
  curl -s -I --retry 3 --retry-delay 3 --retry-connrefused --max-time 20 \
       "http://$ip" 2>/dev/null | grep -qi '^Server:.*nginx'
}

echo "======================================================"
echo " Validating Question 6: nginx via provisioner script"
echo "   Resource group: $RG   |   VM: $VM"
echo "======================================================"

check "Resource group '$RG' exists" \
  bash -c '[[ "$(az group exists --name "'"$RG"'")" == "true" ]]'

check "VM '$VM' exists in '$RG'" \
  az vm show -g "$RG" -n "$VM"

check "Inbound Allow rule opens TCP port 80" \
  port_80_open

check "Web server answers on port 80 (curl returns HTTP 200)" \
  http_200

check "The web server is nginx (Server header)" \
  nginx_serving

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  ip="$(public_ip)"
  [[ -n "$ip" ]] && echo "Hint: VM public IP is ${ip}. Try:  curl -v http://${ip}"
  echo "If the VM is brand new, cloud-init may still be installing nginx — wait a minute and re-run."
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
