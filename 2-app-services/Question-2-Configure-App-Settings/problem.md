# Question 2 — Configure App Settings

## Scenario

The web app needs configuration: it reads its behaviour from environment
variables (which database to use, which mode to run in, feature toggles). In App
Service these are called **application settings** — key/value pairs Azure injects
into the app's environment. As the cloud administrator, **set the app's
configuration** without redeploying any code.

`setup.bash` has already provisioned a plan and a running web app for you.

## Requirements

The web app in `lab-compute-app02-rg` must have these two application settings:

| Setting name | Value |
|--------------|-------|
| `ENVIRONMENT` | `production` |
| `FEATURE_FLAG` | `beta` |

> App settings are per-app configuration, surfaced to your code as environment
> variables. Setting them restarts the app automatically — that's expected.

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
