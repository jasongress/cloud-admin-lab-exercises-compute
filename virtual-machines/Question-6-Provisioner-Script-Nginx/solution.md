# Solution — Question 6: Provision a Web Server with a Provisioner Script

This question combines three skills: **provisioning** (Q1), **opening a port**
(Q2), and a new one — making the VM **configure itself on first boot** with a
provisioner script. That last idea, "infrastructure that stands itself up," is
the doorway to real automation.

---

## Step 1 — Read the requirement into constraints

| Keyword in the problem | Constraint |
|------------------------|------------|
| configures itself on first boot | a **provisioner script** — on Azure/Linux that's **cloud-init** via `--custom-data` |
| install and start nginx | the script's job: `apt install nginx`, ensure it's running |
| reachable on port 80 | open inbound TCP 80 (an NSG rule) |
| curl returns the nginx page | the end-to-end proof: HTTP 200 with `Server: nginx` |

Two moving parts have to line up: nginx must be **installed** (provisioner
script) **and** the network must **let traffic in** (port 80). Miss either and
the curl fails — a great lesson in "it works on the box but not from outside."

---

## Step 2 — What is a "provisioner script" on Azure?

When a Linux VM boots for the first time, **cloud-init** looks for user-supplied
configuration and runs it. `az vm create` hands your file to cloud-init through
the **`--custom-data`** parameter. So the "provisioner script" is just a small
cloud-init file you write and pass in. Reference:

- cloud-init on Azure: <https://learn.microsoft.com/azure/virtual-machines/linux/using-cloud-init>
- `az vm create` (see `--custom-data`): <https://learn.microsoft.com/cli/azure/vm#az-vm-create>

> There's a second way — the **Custom Script Extension**
> (`az vm extension set --name CustomScript ...`) — which runs a script *after*
> the VM is already up. cloud-init is the cleaner "first boot" choice and is what
> we use here; knowing the extension exists is enough for now.

---

## Step 3 — Write the provisioner script (cloud-init)

Create a file called `cloud-init.yaml`. The `#cloud-config` first line is
required — it tells cloud-init how to read the file.

```yaml
#cloud-config
package_update: true
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
```

What each part does:
- `package_update: true` — refresh the apt package index first (like `apt update`).
- `packages:` — install nginx from the distro repos.
- `runcmd:` — commands run late in boot; here we make sure nginx is enabled (starts on every boot) and running now.

On Ubuntu, installing the `nginx` package already starts it — the `runcmd` lines
are belt-and-suspenders so the requirement holds even if defaults change.

---

## Step 4 — Provision the VM with the script, then open the port

```bash
# 1) Create the resource group
az group create --name lab-compute-vm06-rg --location eastus

# 2) Create the VM, handing your provisioner script to cloud-init
az vm create \
  --resource-group lab-compute-vm06-rg \
  --name           dev-tool-vm \
  --image          Canonical:ubuntu-26_04-lts:server:latest \
  --size           Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data    cloud-init.yaml        # <-- the provisioner script

# 3) Open inbound port 80 (same skill as Question 2)
az vm open-port \
  --resource-group lab-compute-vm06-rg \
  --name           dev-tool-vm \
  --port           80 \
  --priority       900
```

`--custom-data` accepts the path to your file (the CLI reads and base64-encodes
it for you). cloud-init then runs it during first boot — which takes a minute or
two **after** `az vm create` returns. Patience here is part of the skill.

---

## Step 5 — Verify the way a user would: curl the public IP

```bash
# Get the public IP
IP=$(az vm list-ip-addresses -g lab-compute-vm06-rg -n dev-tool-vm \
      --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)
echo "$IP"

# Hit it. -I shows headers; look for "Server: nginx" and "200 OK".
curl -I "http://$IP"

./validate.bash
```

If it's not up yet, wait 30–60s and try again — cloud-init may still be
installing. The validator already retries for you.

---

## Step 6 — Troubleshooting with composure

The classic failure here is "curl times out," and the discipline is to isolate
**which** of the two moving parts is wrong:

| Symptom | Likely cause | Move |
|---------|--------------|------|
| Connection **times out** | Port 80 not open (NSG) | Confirm the rule: `az network nsg rule list -g <rg> --nsg-name dev-tool-vmNSG -o table` |
| Connection **refused** / empty reply | Port is open but nginx isn't running | SSH in; `systemctl status nginx`; check cloud-init ran |
| Works after a long wait | cloud-init was still installing | Normal — it runs on first boot; just wait |
| Never installs | Bad cloud-init (e.g. missing `#cloud-config` line, wrong indentation) | On the VM: `sudo cloud-init status --long` and `sudo cat /var/log/cloud-init-output.log` |

The single most useful file when a provisioner script misbehaves:

```bash
# (SSH into the VM)
sudo cat /var/log/cloud-init-output.log     # shows exactly what your script did
```

That log is the difference between guessing and knowing.

---

## Cheat sheet

| Goal | Command |
|------|---------|
| Pass a provisioner script | `az vm create ... --custom-data cloud-init.yaml` |
| Open port 80 | `az vm open-port -g <rg> -n <vm> --port 80 --priority 900` |
| Get the public IP | `az vm list-ip-addresses -g <rg> -n <vm> --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv` |
| Test the web server | `curl -I http://<public-ip>` |
| Read the provisioner log (on the VM) | `sudo cat /var/log/cloud-init-output.log` |
| Check cloud-init finished (on the VM) | `sudo cloud-init status --long` |

**Takeaway:** a VM that stands itself up is the first step toward
infrastructure-as-code. You described the machine's desired state in a tiny file,
and it built itself — and when it doesn't, `cloud-init-output.log` tells you why.
