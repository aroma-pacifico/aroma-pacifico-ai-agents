# aroma-pacifico-ai-agents

Canonical AI agent rules, engineering standards, pc-iac Terraform rules and agent skills, distributed to every Aroma Pacífico repository

Part of the Aroma Pacífico pilot, the 2026 update of the coffee traceability pilot for Cauca, Huila and Tolima. Work is tracked in [aroma-pacifico-roadmap](https://github.com/aroma-pacifico/aroma-pacifico-roadmap) and on the [Aroma Pacífico Pilot board](https://github.com/orgs/aroma-pacifico/projects/1).

## What lives here

This repository holds the canonical engineering constitution (`AGENTS.md`), AI configuration files (`CLAUDE.md`, `GEMINI.md`, `.claude/settings.json`), git workflow, commit-msg hook, and templates (`CONTRIBUTING.md`, `.gitmessage`, `.githooks/commit-msg`, `.github/`), technical standards (`standards/`), agent skills (`.agents/skills/`), and the rules synchronization tool (`scripts/sync-rules.sh`). No delivery code or infrastructure definitions reside here.

## Repository Map

The `aroma-pacifico` GitHub organization organizes concerns across nine dedicated repositories:

| Repository | Visibility | Holds |
|---|---|---|
| `aroma-pacifico-roadmap` | Private | Issues, milestones, labels only (no rules, no code) |
| `aroma-pacifico-ai-agents` | Private | Canonical rules, standards, skills, the sync script (this task) |
| `aroma-pacifico-architecture` | Private | Case statement, decision log, ADRs, design documents, plan, observability, release notes, costs |
| `aroma-pacifico-diagrams` | Private | Diagram sources and SVG/PNG exports, boxes D01-D13 |
| `aroma-pacifico-terraform-modules` | **Public** | Reusable Terraform reference modules, versioned by git tag (pc-iac-015) |
| `aroma-pacifico-infrastructure` | Private | Terraform root stack of the pattern environment, remote state, variables, plan-only CI/CD |
| `aroma-pacifico-design-system` | Private | Design system of the three applications |
| `aroma-pacifico-presentation` | Private | Final presentation and defense script |
| `aroma-pacifico-web` | **Public** | Technical solution showcase website published with GitHub Pages |

Every issue lives in `aroma-pacifico/aroma-pacifico-roadmap`. Reference issues as `aroma-pacifico/aroma-pacifico-roadmap#<n>`, never as a bare `#<n>`.

## Rules Distribution and Synchronization

Downstream delivery repositories receive verbatim copies of the distributed rule set:
`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.claude/settings.json`, `CONTRIBUTING.md`, `.gitmessage`, `.githooks/commit-msg`, `.github/pull_request_template.md`, `.github/workflows/pr-conventions.yml`, `standards/`, and `.agents/skills/`.
Private delivery repositories also receive `docs/case/case-statement.pdf`. The public repositories (`aroma-pacifico-terraform-modules` and `aroma-pacifico-web`) never receive the case statement.

Because the canonical repository is private and requires no extra cross-repository secrets, synchronization and drift checking are executed locally by the lead agent using `scripts/sync-rules.sh`:

- **Check drift across delivery repositories**:
  ```bash
  ./scripts/sync-rules.sh check
  ```
- **Apply distributed rules to a target repository clone**:
  ```bash
  ./scripts/sync-rules.sh apply <repo-path-or-name>
  ```

Rule changes must always be authored, reviewed, and merged in this repository first before running `scripts/sync-rules.sh apply`.

## Tasks delivered here

- [G01](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/40) Set up AI agent rules and engineering standards
