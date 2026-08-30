# Solution — App Service Q1: Deploy a Web App

The whole task is three commands. The skill is understanding the **two-layer
model** of App Service — the *plan* (the rented compute) and the *app* (your code
running on it) — because every other App Service task builds on that split.

---

## Step 1 — The mental model: plan vs. app

App Service separates **where your code runs** from **the code itself**:

- **App Service plan** — the compute you rent: OS (Linux/Windows), region, and a
  **pricing tier** (F1 Free, B1 Basic, S1 Standard, P-series Premium) that sets
  CPU/RAM, instance limits, and which features you get. Think of it as the
  *server farm*.
- **Web app** — your application, running **on** a plan, with a chosen **runtime**
  (Node, Python, .NET, …). Many web apps can share one plan.

So the order is always: **create the plan → create the app on it.** That's the
same "create the box, then put the thing in the box" pattern as a resource group,
one level down.

Reference: <https://learn.microsoft.com/cli/azure/appservice/plan> and
<https://learn.microsoft.com/cli/azure/webapp>

---

## Step 2 — Read the requirement into constraints

| Keyword in the problem | Constraint |
|------------------------|------------|
| platform-managed web app | App Service (PaaS), not a VM |
| paid tier, not Free | plan `--sku B1`, `--is-linux` |
| Node runtime | web app `--runtime NODE:22-lts` |
| reachable / curl 200 | the app answers on `https://<name>.azurewebsites.net` |

**Why not Free (F1)?** F1 is quota-limited, has no "Always On," can't scale out,
and has no deployment slots — so later questions in this topic (scale-out, slot
swaps) need at least Basic/Standard anyway. Basic (`B1`) costs only a couple of
cents for a short lab session — just remember to run `./cleanup.bash` when you
finish, since an App Service plan left running bills around the clock.

---

## Step 3 — Which runtime string? Discover, don't guess

Runtime names have an exact format (`NODE:22-lts`). Never guess them — list them:

```bash
az webapp list-runtimes --os linux            # every valid --runtime value
az webapp list-runtimes --os linux | grep -i node
```

Pick a current LTS, e.g. `NODE:22-lts`.

---

## Step 4 — Build it (three commands)

```bash
# 1) The resource group (the box)
az group create --name lab-compute-app01-rg --location centralus

# 2) The App Service plan (the rented compute). --is-linux picks Linux hosts.
az appservice plan create \
  --resource-group lab-compute-app01-rg \
  --name           dev-tool-plan \
  --sku            B1 \
  --is-linux

# 3) The web app on that plan. --name must be GLOBALLY unique.
az webapp create \
  --resource-group lab-compute-app01-rg \
  --plan           dev-tool-plan \
  --name           dev-tool-app-ab1234 \        # <-- change to your own unique name
  --runtime        "NODE:22-lts"
```

`az webapp create` returns JSON including `defaultHostName` — that's your public
URL, `https://<name>.azurewebsites.net`. A freshly created app serves a default
"your app is running" page (HTTP 200) even before you deploy code, which is
exactly what we're proving here.

---

## Step 5 — Verify the way a user would

```bash
# What's the public URL?
az webapp show -g lab-compute-app01-rg -n dev-tool-app-ab1234 \
  --query defaultHostName -o tsv

# Hit it
curl -I https://dev-tool-app-ab1234.azurewebsites.net     # expect: HTTP/... 200

./validate.bash
```

---

## Step 6 — Troubleshooting with composure

| Symptom | Likely cause | Move |
|---------|--------------|------|
| `Website with given name ... already exists` | The web app name isn't globally unique | Pick another name (add more random characters) |
| `curl` hangs then 200 after a while | **Cold start** — the app spins up on first request | Normal; the validator retries |
| 403 / "Web App is stopped" | The app or plan is stopped | `az webapp start -g <rg> -n <app>` |
| Plan create fails on `--is-linux` region | Rare regional capacity issue | Try another region via `LAB_LOCATION` |

---

## Cheat sheet

| Goal | Command |
|------|---------|
| List runtimes | `az webapp list-runtimes --os linux` |
| Create a plan | `az appservice plan create -g <rg> -n <plan> --sku B1 --is-linux` |
| Create a web app | `az webapp create -g <rg> --plan <plan> -n <unique-name> --runtime "NODE:22-lts"` |
| Get the URL | `az webapp show -g <rg> -n <app> --query defaultHostName -o tsv` |
| Test it | `curl -I https://<app>.azurewebsites.net` |
| Stop / start | `az webapp stop|start -g <rg> -n <app>` |

**Takeaway:** App Service trades control for convenience — no OS to patch, no web
server to configure. You rent a *plan* and run an *app* on it. Hold that two-layer
model and the rest of App Service (settings, scaling, slots) falls into place.
