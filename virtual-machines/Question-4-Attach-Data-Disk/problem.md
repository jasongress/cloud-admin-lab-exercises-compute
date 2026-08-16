# Question 4 — Attach a Data Disk

## Scenario

The internal tool on `dev-tool-vm` is about to start storing a database, and the
team wants that data on a **dedicated disk** — separate from the OS disk, so it
can grow (and be backed up) independently. As the cloud administrator, **create
and attach a new 32 GiB managed data disk** to the VM.

`setup.bash` has provisioned the VM for you.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | The VM exists | `dev-tool-vm` in `lab-compute-vm04-rg` |
| 2 | A **managed data disk** is attached to it | name: `dev-tool-data` |
| 3 | Its **size** | 32 GiB |

> Scope: this is the **cloud-admin** half — provisioning and attaching the disk.
> Formatting and mounting it *inside* the OS is Linux sysadmin work; the
> walkthrough points at it, but validation stops at "attached."

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
