---
name: arch-review
description: |
    Use this to review code changes for coupling/cohesion violations and SOLID principles; produce actionable refactor suggestions with minimal churn.
metadata:
    category: review
    focus: architecture
author: Cristian Oliveira
version: 0.0.1
---

# Architecture Review (Coupling + Cohesion)

## What I do
I review code (preferably a PR/diff) and flag **coupling** and **cohesion** issues using concrete, code-based heuristics.

## When to use me
Use me when the user says things like:
- "Review this PR for coupling/cohesion"
- "Find design smells / architecture issues"
- "Is this too coupled?"
- "Does this module have low cohesion?"
- "Suggest refactors with minimal risk"

If the scope is unclear (whole repo vs changed files), ask a single question:
**“Review only the diff/changed files, or also scan related modules?”**

## How I work
1. **Identify review scope**
   - Prefer: changed files + their immediate dependencies.
   - If only a snippet is provided, analyze locally but note uncertainty.

2. **Look for coupling violations** (not just imports)
   - **Structural coupling:** reads another module’s internal fields/shape directly.
   - **Temporal coupling:** requires calls in a specific order (init/connect before use).
   - **Global/config coupling:** depends on env globals, singletons, process state.
   - **Framework coupling:** business logic trapped in React hooks/controllers/etc.
   - **Data-shape coupling:** deep JSON nesting assumptions across boundaries.
   - **Hidden side-effects:** functions that mutate shared state unexpectedly.
   - **Cross-layer coupling:** domain logic mixed with I/O (SQL/HTTP/fs/logging).

3. **Look for cohesion violations**
   - **God module / grab-bag utils**: multiple unrelated responsibilities.
   - **Mixed abstraction levels:** high-level flow + low-level plumbing in same function.
   - **Flag explosion:** many boolean params / “mode” switches.
   - **Shotgun surgery risk:** “one change requires edits everywhere.”
   - **Poor naming boundaries:** file/module name doesn’t match what it contains.

4. **Rate findings**
   - Severity: `P0` (likely bug/risk now), `P1` (high maintenance cost), `P2` (cleanup).
   - Confidence: `high/med/low` depending on evidence and context.

5. **Recommend minimal-churn improvements**
   - Prefer: small extractions, boundary mappers, dependency direction fixes.
   - Provide refactor steps that can be done as **1–3 small commits**.

## Output format (always follow this)
### Summary
- 3–6 bullets: biggest coupling/cohesion risks, in plain language.

### Findings (grouped)
For each finding:
- **Type:** coupling | cohesion
- **Pattern:** (e.g., temporal coupling, god module, mixed abstraction)
- **Evidence:** file + function + a short excerpt description
- **Why it matters:** concrete failure mode / maintenance cost
- **Suggested fix:** specific steps (and an optional “smallest safe change” variant)

### Suggested refactor plan
- 1–3 commits, each with:
  - goal
  - files touched
  - acceptance check (tests/lint/build)

## Heuristic checklist (quick scan)
### Coupling red flags
- “Service reaches into store.db.client.internalThing…”
- “Must call init() before doX()”
- “Reads process.env / globals inside core logic”
- “Domain logic inside controller/hook with direct HTTP/DB”
- “Front-end uses deep API fields without mapping layer”
- “Lots of unrelated modules import this one *because it has random helpers*”

### Cohesion red flags
- file named `utils`, `helpers`, `common` growing endlessly
- a module changes for multiple unrelated reasons
- functions with many flags / optional params controlling behavior
- same file contains formatting + business rules + persistence + logging

## Notes / Guardrails
- Don’t demand DI for everything. DI is a tool for testability and substitutability, not a universal fix.
- Prefer improving boundaries (interfaces, mappers, small modules) over adding patterns.
- If recommending new abstractions, justify them with a concrete pain avoided.
