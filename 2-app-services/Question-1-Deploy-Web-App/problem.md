# Question 1 — Deploy a Web App

## Scenario

The team wants to stop managing servers for a small internal website. Instead of
a VM they'll patch and babysit, they want a **platform-managed web app** — they
push code, Azure runs it. As the cloud administrator, **stand up an Azure App
Service web app** and prove it's live in a browser.

App Service is a **Platform-as-a-Service (PaaS)**: you don't see the VM, the OS,
or the web server — Azure runs all of that. You provide the app; Azure provides
the platform.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A resource group exists | `lab-compute-app01-rg`, in your lab region |
| 2 | An **App Service plan** exists in it | Linux, a **paid** tier (e.g. `B1` Basic) — not Free (`F1`) |
| 3 | A **web app** runs on that plan | a **Node** runtime (e.g. `NODE:22-lts`) |
| 4 | The app is **reachable** | `curl https://<app-name>.azurewebsites.net` returns **HTTP 200** |

> **Web app names are globally unique** — the name becomes
> `https://<name>.azurewebsites.net`, a public DNS host shared by all of Azure.
> Pick something unlikely to be taken, e.g. `dev-tool-app-<your-initials><digits>`.
> The validator finds *the* web app in your resource group, so the exact name is
> your choice.

## Before you start

Work from **inside this question's folder**. Then:

```bash
az login
az account show
./setup.bash      # optional: preflight + shows your target
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
