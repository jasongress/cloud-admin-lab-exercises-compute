# Question 1 — Provision a Linux VM

## Scenario

The development team needs a new Ubuntu Linux server to host an internal tool.
As the cloud administrator, **provision a virtual machine that meets their
requirements.**

You are on a fresh subscription — nothing has been created for you. Standing up
the resource group **and** the VM is your job.

## Requirements

Your solution is complete when all of the following are true:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A **resource group** exists | name: `lab-compute-vm01-rg`, in your lab region |
| 2 | A **virtual machine** exists in that resource group | name: `dev-tool-vm` |
| 3 | The VM runs **Ubuntu 26.04 LTS** | Canonical, offer `ubuntu-26_04-lts` |
| 4 | The VM **size** | `Standard_B2s` |
| 5 | The **admin username** | `azureuser` |
| 6 | Authentication uses an **SSH key**, not a password | password auth disabled |
| 7 | The VM is **running** | power state `running` |

> **Region:** the resource-group name and region come from `lab-config.sh` at the
> repo root (default region `eastus`). If you changed `LAB_LOCATION` there, create
> your resources in that region — the validator reads the same file, so as long as
> you and it agree, you're fine.

## Before you start

Work from **inside this question's folder** (`cd` into it). Then:

```bash
az login          # authenticate the CLI to your subscription
az account show   # confirm which subscription you're pointed at
./setup.bash           # optional: checks your environment and prints your target
```

## When you think you're done

```bash
./validate.bash
```

Stuck? Open [`solution.md`](solution.md) — it walks through **how a cloud
administrator reasons about this problem**, not just the final command.

## Clean up (avoid surprise charges)

```bash
./cleanup.bash
```
