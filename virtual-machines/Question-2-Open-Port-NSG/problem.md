# Question 2 — Open a Port with a Network Security Group

## Scenario

The internal tool on `dev-tool-vm` has started serving its web UI on **TCP port
8080**. The team reports they can't reach it from their browsers — the request
just times out. As the cloud administrator, **make the tool reachable on port
8080** without opening anything else.

`setup.bash` has already provisioned the VM for you (it exists and is running).
Your job is only to open the port.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | The VM exists and is running | `dev-tool-vm` in `lab-compute-vm02-rg` (setup did this) |
| 2 | An **inbound** security rule **allows TCP 8080** | access: Allow, direction: Inbound, port: 8080 |

> Don't open port ranges or "all ports." A cloud admin opens exactly what's
> needed — 8080 and nothing more.

## Get started

```bash
./setup.bash      # provisions the VM
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
