# Practice Exercises — App Service

Practice problems for App Service: **questions only** — no `setup.bash`,
`validate.bash`, or `solution.md`. The graded questions (1–4) walked you through
the skills; these are the reps.

Work them like any ticket:

1. **Read the scenario into a checklist** of concrete constraints.
2. **Find the reference** — guess `az <noun> <verb>` (`az webapp ...`,
   `az appservice plan ...`), confirm in the docs.
3. **Tame the flags with `--help`** — required first, then match to your checklist.
4. **Build the command incrementally**, then **verify with your own eyes.**

Some questions leave specifics for you to discover — the exact runtime string
(`az webapp list-runtimes --os linux`), an available tier, etc. That discovery
*is* the exercise.

## How to check your own work (no validator here)

You are the validator now:

```bash
APP=$(az webapp list -g <rg> --query "[0].name" -o tsv)     # find your app
az webapp show -g <rg> -n "$APP" --query defaultHostName -o tsv
curl -I https://<app>.azurewebsites.net                     # is it serving?
az webapp config show           -g <rg> -n "$APP" -o jsonc  # runtime, alwaysOn, httpsOnly...
az webapp config appsettings list -g <rg> -n "$APP" -o table
az appservice plan show -g <rg> -n <plan> --query "{tier:sku.tier,instances:sku.capacity}" -o table
```

## Ground rules

- Use your **own resource groups** — e.g. `practice-appNN-rg`. One group per exercise.
- Web app names are **globally unique** — add random characters so yours is free.
- These create **real, billable resources.** Clean up the moment you finish:
  ```bash
  az group delete --name <your-rg> --yes --no-wait
  ```

---

## Exercise 1 — Deploy with a different runtime

Not every app is Node. Stand one up on a different stack.

**Done when:**
- You create a plan (Linux, a paid tier) and a web app running a **Python** (or
  **.NET**) runtime — find the exact `--runtime` value with
  `az webapp list-runtimes --os linux`.
- `curl https://<app>.azurewebsites.net` returns HTTP 200.

---

## Exercise 2 — Deploy your own code

A default page isn't an app. Ship actual content and see it served.

**Done when:**
- You deploy a tiny site/app of your own to a web app (hint: `az webapp up` from a
  folder, or zip deploy with `az webapp deploy --src-path`).
- `curl https://<app>.azurewebsites.net` returns **your** content, not the default
  landing page.

---

## Exercise 3 — App settings and a connection string

Real apps need config *and* a database connection — stored in the right places.

**Done when:**
- The web app has app settings `APP_MODE=demo` and `LOG_LEVEL=info`.
- The web app has a **connection string** named `Default` (type e.g. `SQLAzure`)
  set via `az webapp config connection-string set`.
- You can list both back and explain why a connection string is stored separately
  from a plain app setting.

---

## Exercise 4 — Scale up and turn on Always On

Some workloads shouldn't be allowed to go idle.

**Done when:**
- You **scale up** an existing web app's plan from Basic to **Standard** (`S1`).
- You enable **Always On** (`az webapp config set --always-on true`) so the app
  isn't unloaded when idle.
- You can explain the difference between this (scale **up**) and Question 3
  (scale **out**).

---

## Exercise 5 — Lock it down and watch it

Security posture and observability — two things every admin owns.

**Done when:**
- You enable **HTTPS-only** on the web app so plain HTTP is redirected
  (`az webapp update --set httpsOnly=true`).
- You confirm an `http://` request is redirected/refused while `https://` works.
- You turn on application logging and **stream the logs live**
  (`az webapp log config ...` then `az webapp log tail`), and trigger a request to
  see it appear.

---

### When you can do all five without notes

You can stand up, configure, scale, release, secure, and observe an App Service
app — the full lifecycle of a platform-managed web workload. That's the second
compute type in your toolkit, alongside virtual machines.
