# Solution — App Service Q4: Zero-Downtime Release with a Staging Slot

This is the capstone: the technique real teams use to ship without downtime. The
commands are short; the value is understanding **what a slot is** and **what a
swap actually does**.

---

## Step 1 — The concept: slots and swapping

A **deployment slot** is a second, fully-running copy of your web app on the same
plan, with its own hostname (`https://<app>-staging.azurewebsites.net`). You
deploy the new version *there* and test it in isolation.

A **swap** doesn't copy files around. Azure **warms up** the staging instance
(starts it, waits until it's responding), then **flips the routing** so the warm
staging instance becomes production — and the old production becomes staging.
Because the new version is already warm when traffic flips, users see **no
downtime** and **no cold start**. If something's wrong, you swap again to roll
back instantly.

> **Slots require Standard tier or higher.** That's why `setup.bash` used `S1`.
> Basic and Free have no slots. `S1` is the most expensive tier in these labs, so
> it's especially important to run `./cleanup.bash` as soon as you're done — a
> Standard plan left running for days adds up.

Reference: <https://learn.microsoft.com/azure/app-service/deploy-staging-slots>

---

## Step 2 — About the "new version" in this exercise

In reality you'd deploy new *code* to the staging slot. To keep the focus on the
slot mechanics (and make the result checkable from the CLI), we represent "the new
version" with an app setting: **`RELEASE=v2`**. Production starts at `RELEASE=v1`;
after a correct swap, production reads `RELEASE=v2`. App settings travel with the
slot on swap unless you pin them as slot-specific — which is exactly what lets a
swap carry your release forward.

---

## Step 3 — Do it

Find the app, then run the release:

```bash
APP=$(az webapp list -g lab-compute-app04-rg --query "[0].name" -o tsv)

# 1) Create the staging slot (a clone of production's config)
az webapp deployment slot create \
  --resource-group lab-compute-app04-rg \
  --name           "$APP" \
  --slot           staging

# 2) Put the new version on STAGING only (note --slot staging)
az webapp config appsettings set \
  --resource-group lab-compute-app04-rg \
  --name           "$APP" \
  --slot           staging \
  --settings       RELEASE=v2

# 3) (You'd test https://$APP-staging.azurewebsites.net here.)

# 4) Swap staging into production — warm-up + instant flip
az webapp deployment slot swap \
  --resource-group lab-compute-app04-rg \
  --name           "$APP" \
  --slot           staging \
  --target-slot    production
```

After the swap, **production** carries `RELEASE=v2` and the old `v1` now lives in
the `staging` slot (ready to swap back if you need to roll back).

---

## Step 4 — Verify

```bash
# Production now reports v2
az webapp config appsettings list -g lab-compute-app04-rg -n "$APP" \
  --query "[?name=='RELEASE'].value | [0]" -o tsv        # -> v2

# Production is healthy
curl -I "https://$(az webapp show -g lab-compute-app04-rg -n "$APP" --query defaultHostName -o tsv)"

./validate.bash
```

---

## Step 5 — Troubleshooting with composure

| Symptom | Likely cause | Move |
|---------|--------------|------|
| `slot create` fails | Plan isn't Standard+ | Slots need S1+; scale the plan up first |
| After swap, prod still `v1` | You set `RELEASE=v2` on production, not on `--slot staging`, then swapped the unchanged value | Set it on staging, then swap |
| Setting didn't move on swap | It was marked as a **slot setting** (sticky) | Sticky settings stay put by design; unpin it if it should travel |
| Need to roll back | Bad release reached prod | Swap again — the previous version is sitting in `staging` |

**Sticky settings** are a feature, not a bug: things that must differ per slot
(e.g. a staging database connection string) are pinned so they *don't* follow the
swap. Everything else travels — which is how your release moves forward.

---

## Cheat sheet

| Goal | Command |
|------|---------|
| Create a slot | `az webapp deployment slot create -g <rg> -n <app> --slot staging` |
| Configure a slot | `az webapp config appsettings set -g <rg> -n <app> --slot staging --settings K=V` |
| Swap into production | `az webapp deployment slot swap -g <rg> -n <app> --slot staging --target-slot production` |
| List slots | `az webapp deployment slot list -g <rg> -n <app> -o table` |
| Roll back | swap again (previous version is now in `staging`) |

**Takeaway:** slots turn a scary "deploy to production" into a reversible,
zero-downtime **swap**. Warm up the new version out of the traffic path, flip when
it's ready, and keep the old one one command away in case you need it back.
