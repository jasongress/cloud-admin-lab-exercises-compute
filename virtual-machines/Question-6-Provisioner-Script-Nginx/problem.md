# Question 6 — Provision a Web Server with a Provisioner Script

## Scenario

The team wants a web server that comes up **ready to serve** — no manual SSH,
no hand-installing packages. As the cloud administrator, **provision a VM that
configures itself on first boot**: a provisioner script should install and start
**nginx**, and the VM should be reachable on **port 80** so that curling its
public IP returns the nginx welcome page.

This is how real deployments work: the VM is described *as code* and stands
itself up. `setup.bash` only checks your environment — building the VM (with its
provisioner script) is the whole exercise.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A VM exists | `dev-tool-vm` in `lab-compute-vm06-rg`, Ubuntu 26.04, `Standard_D2s_v3` |
| 2 | **nginx** is installed and running — placed there by a **provisioner script**, not by manual SSH | via cloud-init `--custom-data` |
| 3 | Inbound **TCP 80** is open | access: Allow, direction: Inbound, port: 80 |
| 4 | Curling the VM's public IP returns nginx | `curl http://<public-ip>` → HTTP 200, `Server: nginx` |

> A provisioner script runs on **first boot**, so give it a minute or two after
> the VM is created before you validate — installing nginx isn't instant.

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
