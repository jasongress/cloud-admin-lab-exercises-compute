# Solution — Question 3: Resize a VM

Resizing is one command. The skill being tested is knowing **what sizes are
actually available to you** before you commit to one — because the size you want
isn't always offered in your region, and picking blindly is how you hit a wall
mid-change.

---

## Step 1 — Read the requirement into constraints

| Keyword in the problem | Constraint |
|------------------------|------------|
| CPU-bound, needs more capacity | move to a bigger size |
| Standard_D4s_v3 | the exact target size (4 vCPU / 16 GB) |
| keep it running | the VM should be `running` when you're done |

The problem hands you the target, but in real life *you* choose it. So the first
real skill is: **how do I find a valid larger size?**

---

## Step 2 — Discover the available sizes (don't guess)

Two commands answer "what can I resize this VM to?"

```bash
# What sizes can THIS VM be resized to, in place?
az vm list-vm-resize-options \
  --resource-group lab-compute-vm03-rg --name dev-tool-vm \
  --query "[].name" -o table
```

```bash
# Or, more generally: what sizes exist in the region at all?
az vm list-sizes --location eastus \
  --query "[?starts_with(name, 'Standard_D')].{name:name, vCPUs:numberOfCores, memMB:memoryInMb}" \
  -o table
```

`Standard_D4s_v3` is the same family (`Ds_v3`) as the current `Standard_D2s_v3`,
just one tier up — the safest kind of resize, because same-family moves rarely
require special hardware and usually complete without surprises. Reference:
<https://learn.microsoft.com/cli/azure/vm#az-vm-resize>

---

## Step 3 — Understand what resizing actually does

A seasoned admin knows the catch **before** running the command:

- If the target size is available on the **current host**, the resize applies
  with a quick reboot.
- If it isn't, Azure must **deallocate** the VM, move it to a host that supports
  the size, and start it again — a short outage. Same-family, adjacent-tier moves
  (like ours) almost always stay on the same host.

So resizing can briefly interrupt the service. You'd schedule it in a maintenance
window in production. Here, just know that a reboot may happen.

---

## Step 4 — Do it

```bash
az vm resize \
  --resource-group lab-compute-vm03-rg \
  --name           dev-tool-vm \
  --size           Standard_D4s_v3
```

`az vm resize` leaves the VM in its prior power state — since setup left it
running, it comes back running, satisfying requirement #3. (If a resize ever
leaves it stopped, `az vm start -g <rg> -n <vm>` brings it back.)

---

## Step 5 — Verify

```bash
az vm show -g lab-compute-vm03-rg -n dev-tool-vm \
  --query hardwareProfile.vmSize -o tsv          # -> Standard_D4s_v3

az vm get-instance-view -g lab-compute-vm03-rg -n dev-tool-vm \
  --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" -o tsv

./validate.bash
```

---

## Step 6 — Troubleshooting with composure

| Symptom | Likely cause | Move |
|---------|--------------|------|
| `SkuNotAvailable` / size not in the resize list | The target size isn't offered on the current host or region | Use `az vm list-vm-resize-options`; if empty, `az vm deallocate` then resize then `az vm start` |
| Resize succeeds but VM is stopped | Azure had to relocate it | `az vm start -g <rg> -n <vm>` |
| Quota error | Your subscription's vCPU quota for the family is exhausted | Request a quota increase, or pick a smaller/other family |

**The mindset:** capacity changes are cheap to *do* and easy to *reverse* — you
can resize back down just as fast. What separates an admin is checking
availability first and knowing a reboot might happen, so nobody is surprised.

---

## Cheat sheet

| Goal | Command |
|------|---------|
| List valid in-place resize targets | `az vm list-vm-resize-options -g <rg> -n <vm> --query "[].name" -o table` |
| List all sizes in a region | `az vm list-sizes -l <region> -o table` |
| Resize | `az vm resize -g <rg> -n <vm> --size Standard_D4s_v3` |
| Confirm size | `az vm show -g <rg> -n <vm> --query hardwareProfile.vmSize -o tsv` |
| Start (if it came back stopped) | `az vm start -g <rg> -n <vm>` |

**Takeaway:** never hard-code a size you haven't confirmed is available. The
discovery commands (`list-vm-resize-options`, `list-sizes`) are the difference
between a smooth change and a stuck one.
