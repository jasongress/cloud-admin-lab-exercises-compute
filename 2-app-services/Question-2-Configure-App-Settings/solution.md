# Solution — App Service Q2: Configure App Settings

Two commands, one important idea: in App Service you change configuration
**without touching code or the server**. App settings are the PaaS replacement
for "SSH in and edit a config file."

---

## Step 1 — What "app settings" are

An **application setting** is a key/value pair Azure injects into your app's
process as an **environment variable**. Your code reads `ENVIRONMENT` the same way
it would read any env var (`process.env.ENVIRONMENT` in Node, `os.environ` in
Python). They live in the platform, not in your code — so you can change them per
environment (dev/staging/prod) without redeploying.

Reference: <https://learn.microsoft.com/cli/azure/webapp/config/appsettings>

---

## Step 2 — Read the requirement into constraints

| Keyword | Constraint |
|---------|------------|
| set configuration, no redeploy | use app settings, not a code change |
| `ENVIRONMENT=production` | one key/value |
| `FEATURE_FLAG=beta` | a second key/value |

---

## Step 3 — Find the command

The setting lives under a web app's **config**, so the noun path is
`az webapp config appsettings`. Check the verbs:

```bash
az webapp config appsettings --help      # -> set, list, delete
```

`set` takes `--settings KEY=VALUE` (space-separated for multiple).

---

## Step 4 — Do it

First, what's the app called? (setup generated a unique name — find it.)

```bash
APP=$(az webapp list -g lab-compute-app02-rg --query "[0].name" -o tsv)
echo "$APP"
```

Set both settings in one call:

```bash
az webapp config appsettings set \
  --resource-group lab-compute-app02-rg \
  --name           "$APP" \
  --settings       ENVIRONMENT=production FEATURE_FLAG=beta
```

Setting app settings triggers an app **restart** so the new environment takes
effect — expected, and quick.

---

## Step 5 — Verify

```bash
az webapp config appsettings list \
  -g lab-compute-app02-rg -n "$APP" \
  --query "[?name=='ENVIRONMENT' || name=='FEATURE_FLAG']" -o table

./validate.bash
```

---

## Step 6 — Troubleshooting with composure

| Symptom | Likely cause | Move |
|---------|--------------|------|
| Setting not showing | Typo in the key, or set on the wrong app | Re-list; confirm `$APP` is the right name |
| Value has spaces/special chars | Shell split it | Quote it: `--settings KEY="some value"` |
| Secret in plain text | App settings are readable by anyone with access | For real secrets, use a **Key Vault reference** instead of a literal value |

**Security note:** app settings are fine for non-secret config. For passwords,
connection strings, and API keys, store the secret in **Azure Key Vault** and put
a *reference* in the app setting — the value stays in the vault, and the app reads
it at runtime. That habit keeps secrets out of your CLI history and the portal.

---

## Cheat sheet

| Goal | Command |
|------|---------|
| Find the app in an RG | `az webapp list -g <rg> --query "[0].name" -o tsv` |
| Set settings | `az webapp config appsettings set -g <rg> -n <app> --settings K1=V1 K2=V2` |
| List settings | `az webapp config appsettings list -g <rg> -n <app> -o table` |
| Delete a setting | `az webapp config appsettings delete -g <rg> -n <app> --setting-names K1` |

**Takeaway:** configuration is a platform concern, not a code concern. App
settings let you retune an app per environment in seconds — and knowing to push
*secrets* into Key Vault instead is what separates a config change from a security
incident.
