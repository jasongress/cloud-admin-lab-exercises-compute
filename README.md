# Hands-on Lab Exercises — Azure Compute

> **Topic:** Provisioning and managing Azure compute resources — **Virtual
> Machines** (IaaS) and **App Service** (PaaS).

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

- **Azure subscription** — an [**Azure for Students**](https://azure.microsoft.com/free/students/)
  subscription (the **$100 credit**, no credit card required) is all you need. The
  labs deliberately use small **burstable B-series** VM sizes that fit a student
  subscription's quota and budget.
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
  --size           Standard_B2s \
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
cd 1-virtual-machines/Question-1-Provision-Linux-VM
./setup.bash        # then read problem.md and solve it
```

> ⚠️ **Cost & credit warning.** These labs create **real Azure resources** that
> draw down your credit — including the lab VM itself. They use small burstable
> sizes (`Standard_B2s` and friends) chosen to fit the **Azure for Students** $100
> budget and quota, and each question is isolated in its own resource group so you
> can wipe it in one command. You're billed by the minute, so the golden rule is:
> provision, solve, validate, then **run the cleanup step the moment you finish a
> question.** When you're done for the day, delete the lab VM too:
> ```bash
> az group delete -n lab-jumpbox-rg --yes --no-wait
> ```

## How each question is structured

Every graded question lives in its own **self-contained folder** with five files:

| File | What it is |
|------|-----------|
| `setup.bash`      | Prepares/pre-checks the environment for the question. |
| `problem.md` | The scenario and the exact requirements ("done" criteria). |
| `validate.bash`   | Automated PASS/FAIL checks against your subscription. |
| `solution.md`| A detailed walkthrough of **how an admin reasons about it** — read this if you get stuck. |
| `cleanup.bash`    | Deletes everything the question created. |

`setup.bash`, `validate.bash`, and `cleanup.bash` are executable scripts you run **from inside
the question folder** — no central runner, no question numbers to remember. All
scripts are open source: read them. Seeing how a check maps to an `az ... --query`
is good practice in itself.

## The workflow

Everything happens **inside a single question folder** — `cd` into it and go:

```bash
cd 1-virtual-machines/Question-1-Provision-Linux-VM

./setup.bash       # 1. Prepare/preflight the environment (and, where relevant, provision the starting VM)

# 2. Read problem.md and solve it yourself with the Azure CLI.
#    Stuck? Open solution.md in the same folder.

./validate.bash    # 3. Check your work — prints PASS/FAIL for each requirement

./cleanup.bash     # 4. Delete the resources so they stop costing money
```

That's the whole model: one folder, three commands (`./setup.bash`, `./validate.bash`,
`./cleanup.bash`).

## Configuration — make it yours

Shared settings live in [`lab-config.sh`](lab-config.sh) at the repo root — most
importantly the **region** (`LAB_LOCATION`, default `eastus`). If eastus is far
from you or lacks quota, change it there once and every script follows. You can
also override per run:

```bash
LAB_LOCATION=westeurope ./validate.bash
```

## The practice mindset (why solutions are given freely)

Think of this like working through a math textbook: study the **worked example**
(the graded questions with full `solution.md` walkthroughs), then drill the
**exercises at the back of the book** (upcoming practice sets — problems only, no
solutions) to build muscle memory and confidence. The point isn't to *know how*
to provision a VM — it's to *prove* you can, and to build the habit of finding
the answer when you don't already have it.

## Available questions

The lab is organized by **compute type**. Each folder below holds its own numbered
questions and a `practice/` set — work them from inside each question folder.

### [`1-virtual-machines/`](1-virtual-machines/) — Virtual Machines (IaaS)

| # | Topic | Skill |
|---|-------|-------|
| 1 | Provision a Linux VM | Create a resource group + Ubuntu 26.04 VM from scratch |
| 2 | Open a Port with an NSG | Diagnose closed connectivity; add an inbound rule |
| 3 | Resize a VM | Discover valid sizes; resize in place |
| 4 | Attach a Data Disk | Create + attach a managed data disk |
| 5 | Deallocate a VM | Stop compute billing (Stopped vs Deallocated) |
| 6 | Provision with a Provisioner Script | cloud-init installs nginx on first boot; curl the public IP |

Plus [**10 practice exercises**](1-virtual-machines/practice/exercises.md) (Windows
+ RDP, disk snapshots, Docker on boot, …).

### [`2-app-services/`](2-app-services/) — App Service (PaaS)

| # | Topic | Skill |
|---|-------|-------|
| 1 | Deploy a Web App | Create an App Service plan + web app on a runtime; curl it live |
| 2 | Configure App Settings | Set application settings (env vars) without redeploying |
| 3 | Scale Out | Run the app on 3 instances (scale out vs. scale up) |
| 4 | Staging Slot + Swap | Zero-downtime release: deploy to a slot, then swap to production |

Plus [**5 practice exercises**](2-app-services/practice/exercises.md) (other
runtimes, deploy your own code, connection strings, scale up + Always On,
HTTPS-only + log streaming).

*Every graded question comes with a full `solution.md` walkthrough. Practice sets
are problems only — your reps, like the exercises at the back of a textbook.*
