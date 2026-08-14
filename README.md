# Hands-on Lab Exercises — Azure Compute

> **Topic:** Provisioning and managing Azure compute resources (starting with
> Virtual Machines).

Welcome. These labs exist to turn you into a **Cloud Administrator** — someone
who *manages, maintains, and secures* a company's cloud environment. Not someone
who has memorised every command. A real admin doesn't know everything; they know
which breadcrumbs to follow. These exercises train exactly that.

Each problem is a short **real-world scenario**. Your job is to work out what it
demands and solve it with the tools at your disposal. You get a script to check
your work and a full solution walkthrough — freely — because this is a
low-stakes place to build competency. Break things here so you don't have to
break them in production.

## The three skills we're building

1. **Reading documentation** — the first question an admin asks is *"where are
   the provider's docs for X?"* Learn to navigate them and you can learn any
   service.
2. **Tooling** — we use the **Azure CLI** (`az`) exclusively. No portal. We like
   the hard way, because the hard way is the way that sticks.
3. **Troubleshooting** — when things break: composure first. Understand the
   cause, fix it, and write down what happened.

## Prerequisites

- **Azure subscription** — a **paid** (pay-as-you-go) subscription is assumed.
  The labs use general-purpose VM sizes that free-tier accounts often can't
  provision.
- A **lab VM** to work from (set it up below). The Azure CLI runs *there*, not on
  your laptop.

## Set up your lab environment

> ✅ **This lab is verified on Ubuntu 26.04 LTS Server — the recommended
> environment.** Do the exercises from a dedicated Azure lab VM (a "jumpbox")
> running Ubuntu 26.04. Working from a clean, disposable VM keeps your machine
> tidy and matches how admins actually operate: from a managed box inside the
> cloud.

**1. Provision the lab VM (Ubuntu 26.04).** You need the Azure CLI to create a
VM, but you don't have it yet — so bootstrap this first VM from **[Azure Cloud
Shell](https://shell.azure.com)** (the CLI is pre-installed there) or the Azure
Portal. From Cloud Shell, run:

```bash
az group create -n lab-jumpbox-rg -l eastus
az vm create \
  --resource-group lab-jumpbox-rg \
  --name           lab-jumpbox \
  --image          Canonical:ubuntu-26_04-lts:server:latest \
  --size           Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys
```

**2. SSH into the lab VM** (use the `publicIpAddress` printed by the command
above):

```bash
ssh azureuser@<publicIpAddress>
```

**3. Install the Azure CLI on the lab VM.** On Ubuntu, one command does it:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

- Azure CLI install (all platforms): <https://learn.microsoft.com/cli/azure/install-azure-cli>
- Azure CLI install on Linux (Ubuntu/Debian): <https://learn.microsoft.com/cli/azure/install-azure-cli-linux>

**4. Log in.** A lab VM has no browser, so use the device-code flow — it prints a
URL and a code you enter from any browser:

```bash
az login --use-device-code
az account show     # confirm the right subscription is active
```

**5. Install git and clone this repo onto the lab VM:**

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/sailplatform/cloud-admin-lab-exercises-compute.git
cd cloud-admin-lab-exercises-compute
```

**6. You're ready** — start the first question:

```bash
scripts/run-question.sh 1
```

> ⚠️ **Cost warning.** These labs create **real Azure resources that cost real
> money** — including the lab VM itself. Exercises use modest, widely-available
> general-purpose sizes (e.g. `Standard_D2s_v3`), and each question is isolated in
> its own resource group so you can wipe it in one command. Bill by the minute:
> provision, solve, validate, then **always run the cleanup step when you finish a
> question.** When you're completely done, delete the lab VM too:
> ```bash
> az group delete -n lab-jumpbox-rg --yes --no-wait
> ```

## How each question is structured

Every graded question lives in its own folder with five files:

| File | What it is |
|------|-----------|
| `setup.bash`   | Prepares/pre-checks the environment for the question. |
| `problem.md`   | The scenario and the exact requirements ("done" criteria). |
| `validate.bash`| Automated PASS/FAIL checks against your subscription. |
| `solution.md`  | A detailed walkthrough of **how an admin reasons about it** — read this if you get stuck. |
| `cleanup.bash` | Deletes everything the question created. |

All scripts are open source — read them. Seeing how a check maps to an
`az ... --query` is good practice in itself.

## The workflow

```bash
# 1. Start a question (runs setup, prints the problem)
scripts/run-question.sh 1

# 2. Solve it yourself with the Azure CLI.
#    Stuck? Open the question's solution.md.

# 3. Check your work
scripts/validate-question.sh 1

# 4. Clean up (delete the resources so they stop costing money)
scripts/cleanup-question.sh 1
```

You can pass a **number** (`1`) or the **folder name**
(`Question-1-Provision-Linux-VM`) to any of the three scripts. Use `all` with
validate/cleanup to sweep every question.

## Configuration — make it yours

Shared settings live in [`lab-config.sh`](lab-config.sh) at the repo root — most
importantly the **region** (`LAB_LOCATION`, default `eastus`). If eastus is far
from you or lacks quota, change it there once and every script follows. You can
also override per run:

```bash
LAB_LOCATION=westeurope scripts/validate-question.sh 1
```

## The practice mindset (why solutions are given freely)

Think of this like working through a math textbook: study the **worked example**
(the graded questions with full `solution.md` walkthroughs), then drill the
**exercises at the back of the book** (upcoming practice sets — problems only, no
solutions) to build muscle memory and confidence. The point isn't to *know how*
to provision a VM — it's to *prove* you can, and to build the habit of finding
the answer when you don't already have it.

## Available questions

| # | Topic | Resource |
|---|-------|----------|
| 1 | Provision a Linux VM | Virtual Machines |

*(More questions are on the way as this lab grows.)*
