# Practice Exercises — Virtual Machines

These are the "back of the book" problems: **questions only** — no `setup.bash`,
no `validate.bash`, no `solution.md`. The graded questions (1–6) gave you worked
examples; these are the reps that turn understanding into muscle memory.

Work them the same way a cloud admin works any ticket:

1. **Read the scenario into a checklist** of concrete constraints.
2. **Find the reference** — guess `az <noun> <verb>`, confirm in the docs.
3. **Tame the flags with `--help`** — required first, then match the rest to your checklist.
4. **Build the command incrementally**, then **verify with your own eyes.**

Some questions deliberately don't hand you the exact image name or size — finding
those with `az vm image list -o table` and `az vm list-sizes -l <region> -o table`
is part of the exercise.

## How to check your own work (no validator here)

You are the validator now. The commands that tell you the truth:

```bash
az vm show -g <rg> -n <vm> -o jsonc                       # the full definition
az vm show -g <rg> -n <vm> --query <jmespath> -o tsv      # one specific field
az vm get-instance-view -g <rg> -n <vm> \
  --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" -o tsv
az vm list-ip-addresses -g <rg> -n <vm> -o table          # public IP
curl -I http://<public-ip>                                # web reachability
```

## Ground rules

- Use your **own resource groups** — a good convention is `practice-vmNN-rg` so
  they're easy to find and delete. Put everything for one exercise in one group.
- These create **real, billable resources.** Clean up the moment you finish each:
  ```bash
  az group delete --name <your-rg> --yes --no-wait
  ```
- Region is your choice; if a size or image isn't offered where you are, pick
  another region or another size — that decision *is* the skill.

---

## Exercise 1 — Provision with tags

Provision a Linux VM for a short-lived experiment, labelled so finance can tell
what it's for.

**Done when:**
- A VM named `web-01` runs **Ubuntu 24.04 LTS** (find its image alias yourself).
- Size is `Standard_B1s` (a small burstable size — the kind Azure for Students can provision).
- The VM carries two **tags**: `env=practice` and `owner=<your-name>`.
- Admin user `azureuser`, SSH-key auth.

---

## Exercise 2 — Provision, then connect

Prove you can actually get onto a machine you built — half of administration is
logging in to look around.

**Done when:**
- You provision an Ubuntu 26.04 VM named `jump-01`.
- You retrieve its **public IP** from the CLI (not the portal).
- You **SSH in** as `azureuser` and run `hostnamectl`, confirming the OS is
  Ubuntu 26.04.

---

## Exercise 3 — Open HTTPS, but only to you

A service listens on **443**, but it must be reachable **only from your own
workstation's IP**, not the whole internet.

**Done when:**
- An existing VM has an inbound rule allowing **TCP 443**.
- The rule's **source** is restricted to your current public IP
  (hint: find yours, then look for a `--source-address-prefixes`-style option).
- No other new ports are opened.

---

## Exercise 4 — Resize for more memory

A data-processing tool is running out of RAM, not CPU. Give it more memory —
while staying inside what a student subscription can provision.

**Done when:**
- An existing `Standard_B2s` VM (2 vCPU / 4 GB) is resized to `Standard_B2ms`
  (2 vCPU / **8 GB**) — same burstable family, double the RAM. Confirm it's a
  valid target first with `az vm list-vm-resize-options`.
- The VM is **running** afterward.
- You can explain (to yourself) when you'd reach for more memory vs. more vCPUs —
  and why staying in the B-series matters on a low-quota account.

---

## Exercise 5 — Attach two data disks

A database needs its **data** and its **logs** on separate disks.

**Done when:**
- An existing VM has **two** managed data disks attached: one **64 GiB**
  (`db-data`) and one **32 GiB** (`db-logs`).
- Each disk sits on a distinct **LUN**.
- You can list both from `az vm show ... --query "storageProfile.dataDisks"`.

---

## Exercise 6 — Schedule a nightly shutdown

The team keeps forgetting to turn off a dev box. Automate it.

**Done when:**
- An existing VM has an **auto-shutdown** schedule set for **19:00** in your time
  zone (find the right `az vm` sub-command).
- Separately, practice the manual money-saver: **deallocate** the VM, confirm the
  power state is `deallocated` (not merely `stopped`), then **start** it again.

---

## Exercise 7 — A different web server, with a custom page

Repeat the provisioner-script skill, but with **Apache** instead of nginx, and
serve your own content.

**Done when:**
- You provision a VM whose **cloud-init** provisioner installs **Apache**
  (`apache2`) and writes an `index.html` containing the text `Hello, Cloud Admin`.
- Port **80** is open.
- `curl http://<public-ip>` returns your custom `Hello, Cloud Admin` text
  (hint: cloud-init's `write_files:` section can create the page).

---

## Exercise 8 — A Windows VM with RDP

Not everything is Linux. Stand up a Windows Server and make it reachable.

**Done when:**
- You provision a **Windows Server 2022** VM (find the image alias with
  `az vm image list -o table`).
- You set an admin username and a **strong password of your own choosing**
  (you enter it — never share it).
- Inbound **RDP (TCP 3389)** is open so the VM could be reached with a remote
  desktop client.

---

## Exercise 9 — Snapshot a disk before a risky change

Before you make a change you can't easily undo, take a backup.

**Done when:**
- You take a **snapshot** of an existing VM's **OS disk**
  (hint: get the OS disk's ID from `az vm show`, then `az snapshot create`).
- You can list the snapshot with `az snapshot list -g <rg> -o table`.
- You can explain how you'd create a new disk *from* that snapshot to recover.

---

## Exercise 10 — Capstone: deploy a container on boot

Combine everything: a VM that installs Docker and serves a container — all from
its provisioner script.

**Done when:**
- You provision a VM whose **cloud-init** provisioner installs **Docker** and runs
  a container that serves HTTP on port **80** (for example the `nginxdemos/hello`
  image, or `docker run -d -p 80:80 nginx`).
- Port **80** is open.
- `curl http://<public-ip>` returns the container's page.
- Bonus: SSH in and run `docker ps` to see your container running.

---

### When you can do all ten without notes

You've built real competency in provisioning and operating Azure compute. That's
the goal — not memorizing commands, but knowing how to find, build, verify, and
troubleshoot any of them. Next stop in this lab: other compute resources beyond
the virtual machine.
