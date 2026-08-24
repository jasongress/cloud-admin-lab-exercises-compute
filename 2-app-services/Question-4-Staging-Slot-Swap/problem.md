# Question 4 — Zero-Downtime Release with a Staging Slot

## Scenario

Production is live and you need to ship a new version **without downtime** and
**without risk**. App Service's answer is **deployment slots**: a separate,
fully-running copy of the app (e.g. `staging`) that you deploy and test on its own
URL, then **swap** into production — Azure warms up the new version first and
flips traffic over instantly.

`setup.bash` has provisioned the plan (Standard tier — slots require it) and a
web app whose current release is marked `RELEASE=v1`.

Your job: roll out **v2** through a staging slot and swap it live.

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A deployment slot named **`staging`** exists on the web app | slot `staging` |
| 2 | You mark the new release in staging and **swap** it into production | prod app setting `RELEASE` = `v2` after the swap |
| 3 | Production is healthy after the swap | `curl https://<app>.azurewebsites.net` → HTTP 200 |

> We use the app setting `RELEASE` as a stand-in for "a new version of the code":
> set `RELEASE=v2` on the **staging** slot, confirm it there, then swap — after
> which **production** carries `v2`. (App settings move with the slot on swap
> unless you pin them as slot-specific.)

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
