#!/usr/bin/env bash
# ============================================================================
#  lab-config.sh — shared configuration for the Compute lab
# ============================================================================
#  Every setup.bash / validate.bash / cleanup.bash sources this one file, so
#  all the scripts for a question agree on WHERE your resources live and WHAT
#  they are named.
#
#  This is YOUR file to edit. The most common change is the region. Azure
#  capacity varies by region: if a deployment fails with SkuNotAvailable or an
#  allocation error, the region is simply full of that size right now — switch
#  LAB_LOCATION to another region and re-run. Reliable alternates:
#      westus2, westus3, eastus2, southcentralus, westeurope, northeurope
#  The scripts don't care which region you pick — they only care that setup, your
#  solution, validate, and cleanup all agree on it. That agreement is exactly why
#  the value lives here, in one place, instead of being retyped in every script.
#
#  You can also override any value for a single run without editing the file:
#      LAB_LOCATION=westus3 ./validate.bash
# ============================================================================

# Azure region where all lab resources are created.
export LAB_LOCATION="${LAB_LOCATION:-centralus}"

# Prefix applied to every resource group this lab creates. Keeps lab resources
# easy to spot in the portal and easy to delete when you're done.
export LAB_RG_PREFIX="${LAB_RG_PREFIX:-lab-compute}"

# Default admin username for Linux VMs created in this lab.
export LAB_ADMIN_USER="${LAB_ADMIN_USER:-azureuser}"

# Build the resource-group name for a question from its short slug.
#   lab_rg vm01   ->   lab-compute-vm01-rg
lab_rg() {
  echo "${LAB_RG_PREFIX}-$1-rg"
}
