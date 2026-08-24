# Question 5 — Deallocate a VM to Stop Paying for Compute

## Scenario

`dev-tool-vm` is only used during business hours, but it's been running (and
billing) around the clock. Finance has asked you to **stop paying for its compute
overnight**. As the cloud administrator, put the VM into the state where it
**stops incurring compute charges** — without deleting it, so it can be started
again tomorrow.

`setup.bash` has provisioned the VM in a running state.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | The VM still exists (not deleted) | `dev-tool-vm` in `lab-compute-vm05-rg` |
| 2 | The VM is in the state that **stops compute billing** | power state `deallocated` |

> There's a trap here. "Stopping" a VM from inside the OS (or the wrong CLI move)
> leaves it **Stopped** but still **allocated** — and you keep paying. The
> walkthrough explains the difference; the validator checks for the state that
> actually saves money.

## Get started

```bash
./setup.bash
```

## When you think you're done

```bash
./validate.bash
```

Stuck? Open [`solution.md`](solution.md).

## Clean up

```bash
./cleanup.bash
```
