# Solution — App Service Q3: Scale Out

One command — but only if you know the difference between the two kinds of
scaling and where the "instance count" knob actually lives (on the **plan**, not
the app).

---

## Step 1 — Scale up vs. scale out

| | Scale **up** (vertical) | Scale **out** (horizontal) |
|--|--------------------------|-----------------------------|
| What changes | a **bigger** tier (more CPU/RAM per instance) | **more instances** of the same size |
| CLI | change the plan's `--sku` (B1 → S1 → P1v3) | change the plan's **worker count** |
| Good for | a single heavy request path | lots of concurrent requests |

The marketing push is about **concurrency** — many users at once — so you scale
**out**: add instances and let App Service's built-in load balancer spread traffic
across them. (Scaling up is a separate lever you'd reach for if each request were
individually too heavy.)

---

## Step 2 — The knob is on the PLAN

Instances are a property of the **App Service plan** (the compute), not the web
app. All apps on a plan share its instances. So you update the plan's worker
count. From `az appservice plan update --help` the flag is
`--number-of-workers`. Reference:
<https://learn.microsoft.com/cli/azure/appservice/plan#az-appservice-plan-update>

---

## Step 3 — Do it

Find the plan, then scale it out:

```bash
PLAN=$(az appservice plan list -g lab-compute-app03-rg --query "[0].name" -o tsv)

az appservice plan update \
  --resource-group lab-compute-app03-rg \
  --name           "$PLAN" \
  --number-of-workers 3
```

> **Tier limits matter.** Basic (B-series) allows up to **3** instances — which is
> why this exercise targets 3. To go higher you'd first scale *up* to Standard
> (10) or Premium (30). And true **auto**scale (add/remove instances based on CPU
> or a schedule) requires Standard or higher — on Basic you scale manually.

---

## Step 4 — Verify

```bash
az appservice plan show -g lab-compute-app03-rg -n "$PLAN" \
  --query "{tier:sku.tier, instances:sku.capacity}" -o table
# instances -> 3

./validate.bash
```

---

## Step 5 — Troubleshooting with composure

| Symptom | Likely cause | Move |
|---------|--------------|------|
| Error setting workers to > 3 | You're on Basic (max 3) | Scale *up* to Standard first, then scale out further |
| `capacity` still 1 | Updated the wrong plan, or command didn't apply | Re-check `$PLAN`; re-run the update |
| Want it automatic | Manual scaling doesn't react to load | Use autoscale rules (needs Standard+): `az monitor autoscale ...` |

---

## Cheat sheet

| Goal | Command |
|------|---------|
| Find the plan | `az appservice plan list -g <rg> --query "[0].name" -o tsv` |
| Scale out (instances) | `az appservice plan update -g <rg> -n <plan> --number-of-workers 3` |
| Scale up (tier) | `az appservice plan update -g <rg> -n <plan> --sku S1` |
| Check tier + instances | `az appservice plan show -g <rg> -n <plan> --query "{tier:sku.tier,instances:sku.capacity}" -o table` |

**Takeaway:** "the app is slow under load" usually means **scale out**; "each
request is heavy" means **scale up**. Both are one command on the *plan* — and
knowing the tier ceilings (Basic = 3) keeps you from promising capacity your tier
can't deliver.
