# Solution — Question 2: Open a Port with a Network Security Group

The command here is one line. The point of the exercise is understanding **why
the port was closed in the first place** and **which knob controls it** — because
that understanding is what lets you debug connectivity for the rest of your
career.

---

## Step 1 — Diagnose before you change anything

The team says the request "just times out." A timeout (as opposed to "connection
refused") is a strong signal: something is silently **dropping** the packets
before they reach the app. In Azure, that "something" is almost always a
**Network Security Group (NSG)** — a stateful firewall attached to the VM's
network interface (or its subnet).

When `az vm create` builds a VM, it creates an NSG that allows **SSH (22)** and
denies everything else inbound by default. Your web app on 8080 was never
allowed in. Nothing is broken — the default is simply "closed unless you say
otherwise." That default-deny posture is a security feature, not a bug.

Mental model: **the NSG is a bouncer with an allow-list. Port 8080 isn't on the
list yet.**

---

## Step 2 — Turn the requirement into constraints

| Keyword in the problem | Constraint |
|------------------------|------------|
| reachable on 8080 | inbound rule, destination port 8080 |
| TCP | protocol TCP |
| "not opening anything else" | one specific port — no ranges, no "*" |
| inbound (browser → VM) | direction = Inbound, access = Allow |

---

## Step 3 — Find the right command

Guess the noun and verb. You're touching a VM's networking, so start at
`az vm` and look for something about ports:

```bash
az vm --help | grep -i port
```

You'll find **`az vm open-port`** — a convenience command that finds the VM's NSG
and adds the allow rule for you. That's the fast path. Reference:
<https://learn.microsoft.com/cli/azure/vm#az-vm-open-port>

There is also the lower-level, more explicit path through the network commands
(`az network nsg rule create`), which every serious admin should recognize:
<https://learn.microsoft.com/cli/azure/network/nsg/rule#az-network-nsg-rule-create>

---

## Step 4 — Do it (the quick way)

```bash
az vm open-port \
  --resource-group lab-compute-vm02-rg \
  --name           dev-tool-vm \
  --port           8080 \
  --priority       900        # lower number = evaluated first; must be unique in the NSG
```

`--priority` matters because NSG rules are evaluated **in order** (100 → 4096)
and the first match wins. Pick a value that doesn't collide with the existing
SSH rule.

### The explicit way (worth knowing)

This is what `open-port` does under the hood — spelled out. First find the NSG,
then add a precise rule:

```bash
# The NSG az created is named after the VM:
az network nsg list -g lab-compute-vm02-rg --query "[].name" -o tsv
# -> dev-tool-vmNSG

az network nsg rule create \
  --resource-group        lab-compute-vm02-rg \
  --nsg-name              dev-tool-vmNSG \
  --name                  allow-8080 \
  --priority              900 \
  --direction             Inbound \
  --access                Allow \
  --protocol              Tcp \
  --destination-port-ranges 8080
```

Notice how each flag maps straight to a constraint from Step 2. When a convenience
command doesn't fit your exact need, dropping down to the explicit command is the
move — and now the "wall of flags" reads as your own checklist.

---

## Step 5 — Verify

```bash
# See the rule you just added
az network nsg rule list \
  -g lab-compute-vm02-rg --nsg-name dev-tool-vmNSG \
  --query "[?destinationPortRange=='8080' || contains(destinationPortRanges, '8080')].{name:name, access:access, dir:direction, port:destinationPortRange}" \
  -o table

./validate.bash
```

To truly confirm end-to-end you'd also need the app actually listening on 8080
inside the VM — but the cloud-admin responsibility here is the network path, and
that's what we validate.

---

## Step 6 — Troubleshooting with composure

| Symptom | Likely cause | Move |
|---------|--------------|------|
| `Priority NNN already exists` | Two rules share a priority | Pick a different, unique `--priority` |
| Rule added but still times out | App isn't listening on 8080 inside the VM, or a **subnet-level** NSG also blocks it | `curl localhost:8080` on the VM; check for an NSG on the subnet too |
| Can SSH but not reach 8080 | Only 22 was ever allowed | That's exactly this task — add the 8080 rule |

**Security reflex:** every time you open a port, ask *"from where?"* Production
admins scope `--source-address-prefixes` to known IP ranges instead of the whole
internet. This lab keeps it simple, but the habit is the lesson.

---

## Cheat sheet

| Goal | Command |
|------|---------|
| Open a port (quick) | `az vm open-port -g <rg> -n <vm> --port 8080 --priority 900` |
| List a VM's NSGs | `az network nsg list -g <rg> --query "[].name" -o tsv` |
| Add an explicit rule | `az network nsg rule create -g <rg> --nsg-name <nsg> -n allow-8080 --priority 900 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 8080` |
| List rules | `az network nsg rule list -g <rg> --nsg-name <nsg> -o table` |
| Delete a rule | `az network nsg rule delete -g <rg> --nsg-name <nsg> -n allow-8080` |

**Takeaway:** connectivity problems in the cloud are usually *permission*
problems, not *plumbing* problems. Learn where the allow-lists live (NSGs), and
"it times out" stops being scary.
