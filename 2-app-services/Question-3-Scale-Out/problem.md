# Question 3 — Scale Out

## Scenario

A marketing push is coming and the single instance behind the web app won't keep
up. Rather than move to a bigger machine, the team wants **more copies of the app
running behind Azure's load balancer** so traffic is spread across them. As the
cloud administrator, **scale the app out to 3 instances.**

`setup.bash` has provisioned the plan and web app (currently 1 instance).

## Requirements

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A web app exists | in `lab-compute-app03-rg` |
| 2 | The App Service plan runs **3 instances** | worker/instance count = `3` |

> "Scale **out**" (more instances) is different from "scale **up**" (a bigger
> tier). This question is about scaling *out*. The Basic tier supports up to 3
> instances — enough for this exercise.

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
