# Solution — Question 1: Provision a Linux VM

Before you skip to the command at the bottom: the command is the *least*
important thing here. Anyone can copy a command. What makes you a cloud
administrator is the thinking that happens **before** you type it. That's what
this walkthrough is really about.
---

## Step 1 — Read the problem like an admin

A seasoned admin doesn't read a ticket looking for a command. They read it
looking for **constraints** — the non-negotiable facts the finished resource
must satisfy. Underline the nouns and adjectives:

> Provision a **virtual machine**, running **Ubuntu 26.04 LTS**, size
> **Standard_B2als_v2**, admin user **azureuser**, using an **SSH key** (not a
> password), and leave it **running**, inside a **resource group** named
> `lab-compute-vm01-rg`.

Every highlighted word is going to become one flag on one command. Turn the
prose into a checklist:

| Keyword in the problem | What it becomes |
|------------------------|-----------------|
| resource group `lab-compute-vm01-rg` | a container you create first |
| virtual machine `dev-tool-vm` | the thing you're provisioning |
| Ubuntu 26.04 LTS | which OS image to pick |
| Standard_B2als_v2 | the VM size (CPU/RAM tier) |
| azureuser | the admin username |
| SSH key, not a password | the authentication method |
| running | the expected end state |

You now know your destination *exactly*. Half of troubleshooting is just
knowing precisely what "done" looks like — you just wrote it down.

---

## Step 2 — Decide the shape before touching the keyboard

Two facts aren't spelled out as flags but you still have to settle them:

- **Where?** Every Azure resource lives in a region. This lab keeps the region
  in `lab-config.sh` (`LAB_LOCATION`, default `centralus`) so every script agrees.
  Real admins pick a region for latency, cost, and data-residency reasons.
- **What has to exist first?** In Azure a VM must live inside a **resource
  group**. Nothing here creates it for you, so that's step one. A resource
  group is just a labelled box — its superpower is that deleting the box
  deletes everything in it (which is exactly how `cleanup.bash` works).

Mental model: **create the box → put the VM in the box.**

**A word on the size.** The problem hands you `Standard_B2als_v2`, but understand
*why*. It's a **burstable B-series** size (2 vCPU / 4 GB): inexpensive, and among
the **most widely-available sizes across Azure regions**. Bigger or specialized
families are more often **capacity-constrained** — Azure replies `SkuNotAvailable`
or an allocation error when a region is temporarily full of that size. Burstable
sizes bank CPU credits while idle and spend them under load, a great fit for labs
and light workloads. Rule of thumb: if a `create` fails, it's usually the
**region's capacity**, not your account — try another region by changing
`LAB_LOCATION` in `lab-config.sh` (`westus2`, `westus3`, `eastus2`, and
`westeurope` are reliable alternates).

---

## Step 3 — Find the reference (the real skill)

You are *not* expected to remember VM flags. You're expected to know **where the
answer lives** and how to get there fast. The path is always the same:

> **Azure CLI reference → Virtual Machines → Commands → `az vm` → `az vm create`**

Direct link: <https://learn.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest>

Notice the shape of the `az` command tree — it reads like a sentence:

```
az   vm   create
│    │     └─ the action (verb)
│    └─ the resource (noun)
└─ the tool
```

Almost every Azure task you'll ever do is `az <resource> <action>`. Learn to
*guess* the noun and verb, then confirm in the docs. Need to create a group?
`az group create`. Start a VM? `az vm start`. Resize one? `az vm resize`. The
pattern is the documentation's table of contents.

---

## Step 4 — Tame the parameter overload with `--help`

Open the `az vm create` page (or run `az vm create --help`) and your first
reaction is fair: **there are dozens of parameters.** Nobody uses all of them.
Here's how an admin cuts a wall of flags down to size:

```bash
az vm create --help
```

Read it with two filters:

1. **What's required?** The help marks required arguments. For `az vm create`
   the essentials are just `--resource-group` and `--name`. Everything else has
   a sensible default.
2. **Which optional flags map to MY constraints?** Go back to your Step-1
   checklist and, for each item, scan the help text for the matching flag:

| My constraint | Flag |
|---------------|------|
| Ubuntu 26.04 | `--image <URN>` (see Step 4b — no shortcut alias exists for 26.04) |
| Standard_B2als_v2 | `--size Standard_B2als_v2` |
| azureuser | `--admin-username azureuser` |
| SSH key, no password | `--generate-ssh-keys` (creates a keypair AND disables password login) |

Ignore the other 40 flags. They exist for scenarios you don't have. This filter
— *required first, then match the rest to your checklist* — is how you stay calm
in front of any over-parameterised command.

> **Tip:** `--generate-ssh-keys` reuses an existing key in `~/.ssh` if you have
> one, or creates a fresh keypair if you don't. Because it uses key-based auth,
> Azure sets `disablePasswordAuthentication = true` for you — requirement #6
> handled without a separate flag.

### Step 4b — When there's no image alias, build the URN yourself

For common images the CLI offers short **aliases**. List them:

```bash
az vm image list --output table   # look at the "UrnAlias" column
```

You'll see `Ubuntu2204`, `Ubuntu2404`… but **no `Ubuntu2604`**. Aliases lag
behind new releases. This is the exact moment novices get stuck — and the exact
moment an admin shrugs and finds the image the long way. Every Azure image has a
four-part identifier called a **URN**:

```
Publisher : Offer : Sku : Version
```

You discover each part with three `az vm image` sub-commands, narrowing as you go:

```bash
# 1) Publisher — Ubuntu images come from Canonical
az vm image list-publishers --location centralus -o table | grep -i canonical

# 2) Offer — find the 26.04 LTS offer
az vm image list-offers --publisher Canonical --location centralus -o table | grep -i 26
#   -> ubuntu-26_04-lts

# 3) Sku — pick the plain server image (this is Gen2; 'server-gen1' is the old Gen1)
az vm image list-skus --publisher Canonical --offer ubuntu-26_04-lts --location centralus -o table
#   -> server, server-gen1, minimal, ...
```

Assemble the parts, using `latest` for the version so you always get the newest
patch:

```
Canonical:ubuntu-26_04-lts:server:latest
```

That string goes straight into `--image`. You just did what the alias would have
done — and now you can find *any* image, aliased or not. (The `server` SKU is
Gen2, which is what current sizes like `Standard_B2als_v2` expect.)

---

## Step 5 — Build the command incrementally

Assemble it flag by flag, each one traceable to a line in your checklist. Create
the box first:

```bash
# 1) Create the resource group (the box). Region comes from lab-config.sh.
az group create \
  --name lab-compute-vm01-rg \
  --location centralus
```

```bash
# 2) Create the VM inside it, one flag per constraint.
az vm create \
  --resource-group lab-compute-vm01-rg \                 # which box
  --name           dev-tool-vm \                         # the VM's name
  --image          Canonical:ubuntu-26_04-lts:server:latest \  # Ubuntu 26.04 LTS (Gen2)
  --size           Standard_B2als_v2 \                     # the CPU/RAM tier
  --admin-username azureuser \                           # the login name
  --generate-ssh-keys                                    # SSH-key auth, password disabled
```

`az vm create` provisions the VM **and** starts it, so requirement #7 (running)
is satisfied the moment the command returns. It prints a small JSON summary
including the `publicIpAddress` — hold onto that if you want to SSH in.

> If you changed `LAB_LOCATION` in `lab-config.sh`, use *that* region in the
> `az group create --location` above. The two must match.

---

## Step 6 — Verify with your own eyes

Don't trust "it didn't error" — confirm the facts. `az vm show` prints the
VM's definition; `--query` pulls out just the field you care about (that's
[JMESPath](https://jmespath.org/), the query language the CLI uses):

```bash
# Is it the size and image I asked for?
az vm show -g lab-compute-vm01-rg -n dev-tool-vm \
  --query "{size:hardwareProfile.vmSize, offer:storageProfile.imageReference.offer}" -o table

# Is it actually running?
az vm get-instance-view -g lab-compute-vm01-rg -n dev-tool-vm \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv

# What's its public IP (for SSH)?
az vm list-ip-addresses -g lab-compute-vm01-rg -n dev-tool-vm -o table
```

Then let the graded check confirm everything at once:

```bash
./validate.bash
```

---

## Step 7 — When it goes wrong, stay composed

Errors are information, not emergencies. Read the message; it usually names the
fix. The common ones here:

| Symptom | What it means | Move |
|---------|---------------|------|
| `Please run 'az login'` | The CLI isn't authenticated | `az login`, then retry |
| `ResourceGroupNotFound` | You skipped step 1, or misspelled the group | Create the group first; check the name matches exactly |
| `The platform image ... is not available` / bad URN | A typo in the four-part URN, or wrong region | Re-run the Step-4b discovery commands and copy the parts exactly |
| `SkuNotAvailable` / allocation error for the size | That size is temporarily out of capacity in your region (or not offered there) | Change `LAB_LOCATION` in `lab-config.sh` to another region (`westus2`, `westus3`, `eastus2`, `westeurope`) and retry; or pick another **B-series v2** size (`Standard_B2ats_v2`, `Standard_B2as_v2`) |
| VM name/DNS already taken | The name collides with something existing | Delete the old resource or pick a clean region |

A real admin's habit: when something breaks, write down *what* you saw and *how*
you fixed it. That note is worth more next time than any memorised command.

---

## Cheat sheet

| Goal | Command |
|------|---------|
| Log in | `az login` |
| Create a resource group | `az group create -n <rg> -l <region>` |
| List image aliases | `az vm image list -o table` |
| Find an image offer/sku | `az vm image list-offers --publisher Canonical -l <region>` / `... list-skus --offer <offer>` |
| Create the VM | `az vm create -g <rg> -n <vm> --image Canonical:ubuntu-26_04-lts:server:latest --size Standard_B2als_v2 --admin-username azureuser --generate-ssh-keys` |
| Inspect a VM | `az vm show -g <rg> -n <vm> -o jsonc` |
| Check power state | `az vm get-instance-view -g <rg> -n <vm> --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" -o tsv` |
| Get the public IP | `az vm list-ip-addresses -g <rg> -n <vm> -o table` |
| See a command's options | `az vm create --help` |
| Delete everything | `az group delete -n <rg> --yes --no-wait` |

**The transferable takeaway:** read the ticket into a checklist → find the
`az <noun> <verb>` in the reference → use `--help` to match flags to your
checklist (and `az vm image list-*` to build a URN when no alias exists) → build
incrementally → verify each fact. That loop solves the next VM question, and the
App Service one after it, and services you've never seen.
