# Solution — Question 5: Deallocate a VM to Stop Paying for Compute

This question looks trivial — "turn it off" — and that's exactly the trap. The
lesson is one of the most valuable (and most commonly botched) facts in cloud
cost management: **Stopped is not the same as Deallocated.**

---

## Step 1 — The concept that makes or breaks your bill

A VM has three "off-ish" states, and only one stops the compute meter:

| State | What it means | Are you billed for compute? |
|-------|---------------|-----------------------------|
| **Running** | Powered on | **Yes** |
| **Stopped** (a.k.a. "Stopped (allocated)") | Guest OS is halted, but Azure still **reserves the CPU/RAM** for you | **Yes — still billing!** |
| **Deallocated** ("Stopped (deallocated)") | The VM is released from its host; no compute reserved | **No** (you still pay for disks) |

Here's how people get burned: running `shutdown` / `poweroff` **inside** the VM,
or `az vm stop`, leaves it **Stopped (allocated)** — the OS is off but Azure is
still holding (and charging for) the hardware. To actually stop paying, you must
**deallocate**, which hands the hardware back to Azure.

> You still pay for the **disks** while deallocated — storage is cheap and
> persistent. It's the **compute** (the expensive part) that stops.

---

## Step 2 — Read the requirement into constraints

| Keyword in the problem | Constraint |
|------------------------|------------|
| stop paying for compute | reach the **deallocated** state |
| don't delete it | use deallocate, **not** `az vm delete` |
| start again tomorrow | deallocate is reversible with `az vm start` |

---

## Step 3 — Find the right verb

Guess the noun/verb and confirm in `--help`:

```bash
az vm --help | grep -iE "stop|deallocate|start"
```

You'll see three relevant verbs, and now you know exactly which one you want:

- `az vm stop` — stops the OS but **stays allocated** (still billing). Not this.
- `az vm deallocate` — **releases the hardware, stops compute billing.** This one.
- `az vm start` — brings a stopped/deallocated VM back.

Reference: <https://learn.microsoft.com/cli/azure/vm#az-vm-deallocate>

---

## Step 4 — Do it

```bash
az vm deallocate \
  --resource-group lab-compute-vm05-rg \
  --name           dev-tool-vm
```

To bring it back tomorrow:

```bash
az vm start -g lab-compute-vm05-rg -n dev-tool-vm
```

---

## Step 5 — Verify (and see the trap for yourself)

```bash
az vm get-instance-view -g lab-compute-vm05-rg -n dev-tool-vm \
  --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" -o tsv
# -> VM deallocated     (NOT "VM stopped")

./validate.bash
```

If you had run `az vm stop` instead, that command would print **`VM stopped`** —
and the validator would (correctly) fail you, because you'd still be paying.
That contrast is the whole point of the exercise.

---

## Step 6 — Troubleshooting with composure

| Symptom | Likely cause | Move |
|---------|--------------|------|
| Validator says state is `PowerState/stopped` | You used `az vm stop` or shut down inside the OS | Run `az vm deallocate` |
| Validator says `PowerState/running` | Nothing took effect, or you started it again | Re-run `az vm deallocate` |
| Public IP changed after start | A **dynamic** public IP is released on deallocate | Use a **Static** IP SKU if the address must persist |
| Need it off nightly, automatically | Manual is error-prone | Look at **auto-shutdown** (`az vm auto-shutdown`) or a scheduled automation |

---

## Cheat sheet

| Goal | Command |
|------|---------|
| Stop compute billing (keep the VM) | `az vm deallocate -g <rg> -n <vm>` |
| Start it again | `az vm start -g <rg> -n <vm>` |
| Check the exact power state | `az vm get-instance-view -g <rg> -n <vm> --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" -o tsv` |
| Stop the OS but keep paying (the trap) | `az vm stop -g <rg> -n <vm>` |
| Schedule a nightly shutdown | `az vm auto-shutdown -g <rg> -n <vm> --time 1900` |

**Takeaway:** in the cloud, "off" has a price tag unless you deallocate. Knowing
the difference between *stopped* and *deallocated* is a small fact that saves real
money — exactly the kind of thing that separates a cloud admin from someone who
just clicks "stop."
