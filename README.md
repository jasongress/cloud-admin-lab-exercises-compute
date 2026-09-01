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

- **Azure subscription** — a **paid** (pay-as-you-go) subscription. The labs use
  small, inexpensive **burstable B-series** VM sizes, chosen because they're among
  the most widely-available sizes across Azure regions.
- A **lab VM** to work from (set it up below). The Azure CLI runs *there*, not on
  your laptop.

> 🌍 **Region tip.** Azure capacity varies by region — a size that's full (or not
> offered) in one region is usually available in another. If a `create` fails with
> `SkuNotAvailable` or an allocation error, **just try a different region**: change
> `LAB_LOCATION` in [`lab-config.sh`](lab-config.sh) and re-run. The default is
> `centralus`; good alternates include `westus2`, `westus3`, `eastus2`,
> `southcentralus`, `westeurope`, and `northeurope`.

## Set up your lab environment

> ✅ **This lab is verified on Ubuntu 24.04 LTS Server — the recommended
> environment for the jumpbox.** Do the exercises from a dedicated Azure lab VM
> (a "jumpbox") running Ubuntu 24.04 — you'll set it up once and use it all
> semester. Working from a clean, dedicated VM keeps your own machine tidy and
> matches how admins actually operate: from a managed box inside the cloud.
>
> *(We use the 24.04 **LTS** for the jumpbox because the Azure CLI's package repo
> fully supports it. The graded questions still have you provision Ubuntu 26.04
> VMs — that's the exercise; the CLI on your jumpbox can create any OS version.)*

**1. Provision the lab VM from the Azure Portal.** This first VM is your
workbench — you'll run every exercise from it. Create it in the **Portal's GUI**
([portal.azure.com](https://portal.azure.com) → **Create a resource** → **Virtual
machine**). The Portal is the easiest way to make your very first VM, and it
doesn't need the Azure CLI you haven't installed yet.

Create a VM that meets these requirements — the exact size and names are your
choice, as long as it satisfies each row:

| Setting | Requirement |
|---------|-------------|
| **Image** | Ubuntu Server **24.04 LTS** (the Azure CLI installs cleanly on it) |
| **Size** | at least **1 vCPU** and **4 GB RAM** — e.g. `Standard_B2als_v2` (2 vCPU / 4 GB) |
| **Authentication type** | **Password** (simpler than SSH keys for a first login) |
| **Username** | your choice (e.g. `azureuser`) |
| **Password** | a strong password *you* set — note it down; you need it to log in |
| **Public inbound ports** | allow **SSH (22)** so you can connect |
| **Region** | **Central US** works well for this size; if `Standard_B2als_v2` isn't available there, try another location (see the Region tip above) |

> Put it in its own resource group (e.g. `lab-jumpbox-rg`) — separate from the
> per-question groups — so it's easy to find all semester and to delete in one
> action once the course is over.

**2. Connect to the lab VM with VS Code.** The easiest way to work the labs is
**VS Code Remote-SSH**: you get a file explorer, a rendered preview of each
`problem.md` / `solution.md`, and a terminal — all running *on the jumpbox*.

> 📺 **New to Remote-SSH?** Watch [Connect VS Code to a remote server over SSH](https://www.youtube.com/watch?v=CDjqhAN5RqA),
> or follow Microsoft's step-by-step [Remote-SSH tutorial](https://code.visualstudio.com/docs/remote/ssh-tutorial).

One-time setup on your own laptop:

1. Install **[VS Code](https://code.visualstudio.com)**.
2. In VS Code, open the Extensions view and install **Remote - SSH** (publisher:
   Microsoft).

Then connect — grab the VM's **Public IP** from its **Overview** page in the
Portal, and:

1. Press **F1** (or `Cmd/Ctrl+Shift+P`) → **Remote-SSH: Connect to Host…** →
   **Add New SSH Host…** → enter `ssh <your-username>@<public-ip>` and save it to
   your SSH config.
2. Run **Remote-SSH: Connect to Host…** again, pick the host, and enter the
   **password** you set. A new window opens, connected to the VM.
3. Open a shell on the VM with **Terminal → New Terminal** — you'll run the next
   steps there.

> Prefer the command line? Plain `ssh <your-username>@<public-ip>` works too, as
> does the Portal's **Connect → Bastion** (browser-based, no local SSH client).

**3. Install the Azure CLI on the lab VM.** On Ubuntu, one command does it:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az version    # confirm it installed
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

**6. Open the repo in VS Code and start.** In VS Code, **File → Open Folder →**
`cloud-admin-lab-exercises-compute`. Now you can browse every question in the
explorer. Open a question's `problem.md` and hit the **preview** icon (top-right,
or right-click → **Open Preview**) to read it nicely rendered — same for
`solution.md`. Then run the scripts in the integrated terminal:

```bash
cd 1-virtual-machines/Question-1-Provision-Linux-VM
./setup.bash        # then read problem.md and solve it
```

> ⚠️ **Cost warning.** These labs create **real Azure resources that cost real
> money**. Each question is isolated in its own resource group, and they use small
> burstable sizes (`Standard_B2als_v2` and friends) that are cheap and widely available.
> You're billed by the minute, so the golden rule for **question** resources is:
> provision, solve, validate, then **run `./cleanup.bash` the moment you finish a
> question.**

> 💡 **Your lab VM is the exception — keep it for the whole semester; don't delete
> it.** Just **stop (deallocate)** it when you're done for the day so it stops
> charging for compute, and **Start** it again next time. Easiest way: in the
> Portal, open the VM and click **Stop** — that *deallocates* it (compute billing
> stops; you keep the VM and its disk). Or from any machine with the Azure CLI:
> ```bash
> az vm deallocate --resource-group lab-jumpbox-rg --name <your-vm-name>
> ```
> ⚠️ Do **not** "shut down" from inside the OS (`sudo poweroff`) — that leaves the
> VM **Stopped (allocated)** and **still billing for compute** (the exact trap
> you'll meet in Question 5). Only **delete** `lab-jumpbox-rg` at the **end of the
> course**.

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
importantly the **region** (`LAB_LOCATION`, default `centralus`). If a region is far
from you, lacks capacity for a size, or refuses a deployment, change it there once
and every script follows. You can also override for a single run:

```bash
LAB_LOCATION=westus3 ./validate.bash
```

**Hitting capacity or `SkuNotAvailable` errors?** That's a region-full situation,
not a problem with your account — pick another region and retry. Reliable
alternates: `westus2`, `westus3`, `eastus2`, `southcentralus`, `westeurope`,
`northeurope`. Resources you already created stay where they are, so also delete
any half-created resource group before retrying in a new region.

## The practice mindset (why solutions are given freely)

First study the **worked examples** — the graded questions, each with a full
`solution.md` walkthrough of how an admin reasons through the task. Then drill the
**practice sets** (problems only, no solutions) to build muscle memory and
confidence. The point isn't to *know how* to provision a VM — it's to *prove* you
can, and to build the habit of finding the answer when you don't already have it.

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
are problems only — your reps for building muscle memory.*
