---
name: new-repo-guardrails
description: |
  Create and enforce practical guardrails when starting a new repository/project or evaluating guardrails in an existing repository.
  Use when user asks things like "set up repo guardrails", "bootstrap project standards", "how should this new repo be structured", "analyze this repo's engineering guardrails", or "create a project operating playbook".
  Triggers:
  - "create guardrails for a new repo"
  - "bootstrap a new project with standards"
  - "analyze repository guardrails"
  - "set up quality gates/workflow for this repo"
---

# New Repo Guardrails

## Purpose
Create a predictable, low-ambiguity operating system for a new repository: workflow, quality gates, architecture boundaries, config policy, and release/landing discipline.

## Trigger Phrases (STRICT)
Activate only when the user intent is explicitly about creating, hardening, or auditing repository guardrails.

Examples:
- "create a new repo playbook"
- "define standards for this project"
- "what guardrails should this repository enforce"
- "set up engineering workflow and checks"

Do not activate for normal feature work unless the user asks for process/policy design.

## Inputs
- `repo_mode` (required): `new` or `existing`
- `project_type` (required): e.g. `go-cli`, `node-web`, `python-service`
- `tracking_system` (optional): `beads`, `jira`, `github-issues` (default: infer from repo)
- `ci_platform` (optional): `github-actions`, `gitlab-ci`, `circleci` (default: infer)

## Expected Outputs
Produce all of the following:
1. Guardrails spec document (`docs/engineering/guardrails.md`)
2. Command cheat sheet (`docs/engineering/commands.md`)
3. Quality gate contract (`Makefile` targets + CI workflow)
4. Session landing checklist (`docs/engineering/landing-checklist.md`)
5. Initial bootstrap artifacts (pre-commit config, linter config, test commands)

## Workflow
1) Discover baseline
- Inspect existing files: `AGENTS.md`, `DEVELOPMENT.md`, `Makefile`, CI workflows, lint/test configs.
- If `repo_mode=new`, scaffold minimal equivalents.

2) Define policy -> command -> enforcement chain
- Policy: concise statement of intended behavior.
- Command: exact operator commands for each lifecycle phase.
- Enforcement: pre-commit + CI checks that fail when policy is violated.

3) Establish lifecycle triggers
- Session start: discover/claim work.
- During work: track follow-ups and dependencies.
- Pre-commit: run aggregate quality gate (`make all`-style target).
- Landing: sync state and ensure successful push.
- Release: explicit trigger model (e.g., semver tag).

4) Encode non-negotiable quality gates
- Formatting and linting
- Tests (unit + integration where applicable)
- Security/static checks
- Coverage threshold (team-configurable)
- CI parity with local checks

5) Define architecture and configuration guardrails
- Establish package/module boundaries and dependency direction.
- Define one canonical configuration format.
- Define precedence (defaults < config file < env vars).

6) Add anti-patterns
- Document explicit "DO NOT" behaviors with consequences.
- Include "failure mode -> recovery command" guidance.

7) Validate guardrails are runnable
- Execute key commands locally when possible.
- If execution is blocked, provide exact verification commands.

## Guardrails (MANDATORY)
- NEVER leave process rules as prose only; map each to commands and enforcement.
- NEVER define CI checks without equivalent local commands.
- NEVER allow ambiguous completion criteria; define what "done" means.
- NEVER introduce multiple competing workflows for the same lifecycle step.
- DO NOT use destructive git operations unless explicitly requested.
- DO NOT claim checks were run if they were not executed.

## Canonical Guardrail Template
Use this structure for each rule:

```markdown
### <Guardrail Name>
- Intent: <why this exists>
- Operator command(s): `<exact commands>`
- Enforcement: <pre-commit/CI/rules>
- Failure signal: <how it fails>
- Recovery: <how to fix>
```

## Baseline Command Set (Adapt Per Stack)
```bash
# Session start
bd ready
bd update <id> --status=in_progress

# Local quality gate
make all

# Optional strict checks
make security-check
make check-coverage THRESHOLD=65
pre-commit run --all-files

# Landing
git status
git add <files>
bd sync
git commit -m "<message>"
bd sync
git pull --rebase && bd sync && git push
```

## Anti-Patterns
- "Ready to push later" workflows
- Untracked side work outside issue system
- CI-only checks with no local equivalent
- Unbounded complexity and no coverage budget
- Conflicting config formats and precedence rules

## Error Handling
- Missing prerequisite tool: report exact install command and continue with remaining steps.
- No-op repo state: state "no changes required" and show validation evidence.
- Partial setup: list completed artifacts, missing artifacts, and next exact commands.

## Success Criteria
- A newcomer can follow one document and run one command path per lifecycle stage.
- Local checks and CI checks are aligned.
- "Done" is objectively testable (commands + enforcement).
- Guardrails are versioned in-repo and reviewed like code.
