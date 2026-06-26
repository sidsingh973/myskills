---
name: spec
description: Product spec scaffold — Problem, Core Features, Scope, Non-Goals, Success Metric. Shape Up format.
---

# /spec — Product Spec Generator

Fills the standard product spec scaffold. PM provides product-specific content;
the scaffold enforces the Shape Up format and forces non-goal discipline.

## Scaffold

```
# Product Spec: <Name>

## Problem
<Who has it, how often, what they do instead today.>

## Core Features
1. <Feature> — <why it matters, not what it does>
2. ...

## Scope (this build)
<What IS included. Time-boxed. One cycle.>

## Non-Goals (explicitly killed)
- NOT <X> — because <reason>
- NOT <Y> — because <reason>

## Success Metric
<One metric, testable in under 1 minute.>
<Pass/fail threshold. No ranges.>
```

## Rules enforced by this template

- **Non-goals must explicitly kill something** — "we are not doing X because Y." Vague exclusions ("not in scope") don't count.
- **Success metric is binary and testable in <1 min** — "user can run /jupyter and see output in <10s" not "users are happy."
- **Scope is time-boxed** — one build cycle, not a roadmap.
- **Features say WHY, not WHAT** — "zero-setup kernel (so Siddharth never sees a 404)" not "kernel registration."

## Usage

PM: use this scaffold for every new product. Fill it in; don't deviate from the structure.
Cofounder: reject any spec missing non-goals or with an untestable success metric.
