# Question 3 — Resize a VM

## Scenario

`dev-tool-vm` was provisioned as a `Standard_B1s` (1 vCPU / 1 GB). The tool
has grown and the team reports it's CPU-bound during business hours. As the cloud
administrator, **give it more capacity by resizing it to `Standard_B2s`**
(2 vCPU / 4 GB). Keep the VM running afterwards.

`setup.bash` has provisioned the VM at the smaller size for you.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | The VM exists | `dev-tool-vm` in `lab-compute-vm03-rg` |
| 2 | The VM **size** is now | `Standard_B2s` |
| 3 | The VM is **running** | power state `running` |

## Get started

```bash
./setup.bash      # provisions the D2s_v3 VM
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
