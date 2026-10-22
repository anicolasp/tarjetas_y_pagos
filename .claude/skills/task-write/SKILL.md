---
name: task-write
description: Writes clear, implementation-ready GitHub issues for Tarjetas y Pagos — a single issue, or an epic with one sub-issue per plan phase — with reuse search, classification, product context, business rules, acceptance criteria, testing strategy and phased deliverables. Use when the user asks to "create an epic", "write the tasks", "turn the plan into issues", "create an issue" or "task-write".
---

# Task Writer

A workflow for creating clear, implementation-ready GitHub issues for **Tarjetas y Pagos**: a personal-finance Flutter app (Android first) to track credit cards, expenses, debts and reports. Stack: Flutter + Riverpod + go_router, local SQLite (`sqflite`), on-device ML Kit OCR, Claude API for receipt OCR, local notifications. UI in Spanish (Dominican Republic); money in RD$ and US$.

## Purpose

Create issues that explain the user outcome, define implementation boundaries, and give developers or AI agents testable instructions. Do not create issues that only list code changes.

## Prerequisites

1. `gh auth status` must be authenticated. If not, stop and ask the user to run `gh auth login`.
2. Get the repo with `gh repo view --json nameWithOwner -q .nameWithOwner`.
3. Read the source: a plan in `~/.claude/plans/`, pasted text, or an existing finding. Read `AGENTS.md` / `CLAUDE.md` if they exist.

## Workflow

### 1. Declare the initial checklist

Before drafting, confirm:

- [ ] Run the Reuse search first and include the real commands and results.
- [ ] Add `## Issue Classification` with all seven required fields.
- [ ] If UX surface is not `none`, include `## UX/UI Spec`.
- [ ] If multi-step flow is `yes`, include `## E2E Flow Required`.
- [ ] If risk is high, money logic is involved, or auth/security is involved, mark the issue **Needs spec refinement** (see step 3).
- [ ] For bugfixes and refactors, include `## Fuera de alcance`.
- [ ] If the task comes from an existing finding, include a verified `## Diagnóstico conocido`.

### 2. Search for reusable functionality first

Search the live code before writing the issue. Check:

- SQLite schema, migrations and seeds: `lib/data/database.dart`.
- Models and their codecs: `lib/data/models/`.
- Repositories, Riverpod providers and services: `lib/data/repositories/`, `lib/data/providers.dart`, `lib/services/`.
- Pure helpers: `lib/core/` (`money.dart`, `formatters.dart`, `billing_cycle.dart`, `card_detection.dart`, validators).
- Routes and redirects: `lib/core/router.dart`.
- Existing screens and widgets: `lib/features/<feature>/`.
- Existing tests: `test/`.
- Whether the required data actually exists (column, table, seed).

Record the commands and their actual results in `## Additional context`:

```markdown
### Reuse search
- `<command or query>` → `<actual result>`
- Closest implementation: `<file:line>` — <works / does not work and why>
```

Then decide:

- **Exists and works:** request connecting or extending it, and name the file and line.
- **Exists but does not work:** explain why, with a concrete path.
- **Does not exist:** include the search that returned no result.
- **Required data is missing:** mark the issue as blocked, or add the migration to the scope.

Do not claim a search was run unless it actually was.

### 3. Classify the issue first

Put `## Issue Classification` first in the issue body (right after `Parte de #<epic>` when the issue belongs to an epic):

```markdown
## Issue Classification
- **Type:** feature | bugfix | refactor | infra | docs
- **Layers:** flutter | sqlite | android | infra
- **UX surface:** none | minor | major
- **Multi-step flow:** yes | no
- **Risk:** low | medium | high
- **Money logic:** yes | no
- **Auth/security:** yes | no
```

- **Money logic:** amounts, currencies, totals, balances, billing cycles, payments, debts.
- **Auth/security:** login, passwords, session, biometrics, secure storage, card data, API keys, sending data off the device.

Classification determines required sections:

- UX surface `minor` or `major` → include `## UX/UI Spec`.
- Multi-step flow `yes` → include `## E2E Flow Required`.
- Risk `high`, Money logic `yes`, or Auth/security `yes` → include `## Unknowns to kill before coding` and add `Needs spec refinement with the user before implementation.` to `## Additional context`. `pick-issue` must resolve those unknowns with the user before coding.

### 4. Describe the product context

```markdown
## Product context
**User story:** As a [role], I want [goal] so that [benefit].
**Flow position:** Where this fits in the user journey (onboarding → setup → home → cards / expenses / debts / reports → profile).
**User outcome:** control | savings | avoid late fees | speed | peace of mind

**Market baseline (when relevant):**
- **How others do it:** 1–2 references (bank apps in DR, budgeting apps).
- **Parity we must reach:** The expected baseline.
- **Where we win:** What this app does better (e.g. "best card today", RD$/US$ kept separate, offline).
```

Identify the smallest valuable slice. For Dominican Republic specifics (RD$/US$, `es_DO` dates, local banks), state the requirements explicitly.

### 5. Explain what needs to change

```markdown
## What needs to change
**Current UX:** What the user sees or cannot do today.
**Expected UX:** What the user should be able to do.

**Current code:** Verified current implementation (file:line).
**Expected code:** The intended behavior or integration.
```

### 6. Specify business rules and unresolved decisions

For tasks with logic, state the rules explicitly: validation, ordering, state transitions, per-user scoping (`user_id`), limits, and side effects (notifications, recalculated balances). Project invariants to restate when they apply:

- Money is stored as integer cents plus a currency; totals are always separated by currency, never converted.
- Only the last 4 digits of a card are stored.
- Every repository query is scoped by `user_id`.

For pure UI wiring, use:

```markdown
## Business rules: N/A — UI wiring only
```

For medium/high-risk work, list unresolved decisions under `## Unknowns to kill before coding`. Do not hide ambiguity in broad acceptance criteria.

For a bugfix or refactor, add `## Fuera de alcance`. Name what must not change and why. State that if implementation requires changes outside the agreed scope, the implementer must stop and report.

When the issue is based on another agent's finding, review, or incident, add `## Diagnóstico conocido` and verify every `file:line` reference against live code.

### 7. Add AI leverage when relevant

Use `## AI leverage` to describe the specific AI opportunity (e.g. receipt OCR with Claude, categorization suggestions) and separate the core deliverable from optional future AI work. State what data leaves the device. If AI is not relevant, use:

```markdown
## AI leverage: N/A
```

### 8. Define database design when needed

If tables, columns, or migrations are involved, document:

- Tables and columns, including SQLite types, nullability, defaults, and foreign keys.
- Per-user scoping: which repository methods filter by `user_id`.
- The migration: bump the DB version and add the step in `onUpgrade` in `lib/data/database.dart`; never edit an already-shipped `onCreate` without a migration.
- Model and codec changes in `lib/data/models/`.

If no database changes are needed, use:

```markdown
## Database design: N/A — no schema changes
```

### 9. List files and ownership boundaries

Include 2–5 specific paths in `## Key files to modify`, ordered by importance.

For work that may run in parallel, add `## Exclusive files` with the exact files owned by the issue. If two issues share exclusive files, schedule them sequentially and record the dependency. Avoid vague directory-only lists.

### 10. Write testable acceptance criteria

```markdown
## Acceptance criteria
- [ ] User-visible behavior meets the expected outcome.
- [ ] Loading, empty, error, and success states are handled when applicable.
- [ ] Relevant edge cases and business rules are verified.
- [ ] Light and dark themes render correctly (when there is UI).
- [ ] `flutter analyze` passes with no issues.
- [ ] `flutter test` passes, with new tests for the added logic.
```

Include at least one user-visible criterion and any relevant offline, currency or notification criterion. Never use vague statements such as "works correctly."

### 11. Define the testing strategy

For tasks with logic, specify:

- **Unit:** pure logic in `lib/core/` and models.
- **Repository / DB:** `sqflite_common_ffi` with an in-memory database.
- **Widget:** screens and widgets with `flutter_test`.
- **Manual / E2E:** the flow driven with Marionette in a debug build.

For pure UI wiring, use:

```markdown
## Testing strategy: Manual — verify UI wiring in app with Marionette
```

State the test data and preconditions (user, cards, cut days, expenses) needed to reproduce the flow.

### 12. Split medium and large work into phases

For medium or larger features, add `## Phased deliverables` with an ordered sequence, a checklist per phase, and a concrete Definition of Done for each phase.

For multi-screen flows, use these tracks:

- **C0:** models, contracts and fixtures — merged first.
- **D:** SQLite schema, migrations and repositories.
- **L:** pure logic and Riverpod providers.
- **U:** screens and widgets.
- **I:** integration tests and the Marionette journey.

Declare the track, disjoint `## Exclusive files`, and a track-appropriate Definition of Done. For small tasks (1–2 files, under about an hour), one phase is enough.

### 13. Assign the agent and apply labels

Add `## Assigned agent` (default: `claude`). Labels:

- `task` on every sub-issue, plus `fase-N` for its phase.
- `epic` on the epic.
- `bug`, `enhancement` or `documentation` as applicable.

### 14. Add UX/UI specification when required

When UX surface is `minor` or `major`, include `## UX/UI Spec` with:

- Screens affected and their routes.
- An ASCII wireframe.
- Initial, loading, empty, error, success, blocked, and dense states as relevant.
- Interaction logic, validation, navigation, and failure behavior.
- Visual criteria: Material 3 theme tokens from `lib/core/theme.dart`, light/dark, small screens, accessibility.
- The `ValueKey` of every interactive element (e.g. `card.save`) so Marionette can drive it.
- Exact Spanish (Dominican Republic) microcopy for titles, buttons, empty states, and errors; money formatted as `RD$ 1,250.00` / `US$ 1,250.00`.

Omit the entire section when UX surface is `none`.

### 15. Add an E2E flow when required

When Multi-step flow is `yes`, include `## E2E Flow Required` with:

- The user journey as numbered steps driven with Marionette, with the expected result of each step.
- Required seed data and preconditions.
- Specific end-to-end acceptance criteria.
- Setup notes: debug build, Android emulator or device, VM service URI for Marionette.

Omit the entire section when Multi-step flow is `no`.

### 16. Include additional context

Use `## Additional context` for dependencies (`#issues` that must be merged first, or "None"), scope exclusions, blockers, reuse-search evidence, and refinement routing.

### 17. Right-size the issue

| Size | Scope |
|---|---|
| XS | 1–2 files, under 30 minutes |
| S | 2–4 files, around 30–60 minutes |
| M | 4–8 files, around 1–3 hours |
| L | 8–15 files, around 3–6 hours; must have phased deliverables |
| XL | over 15 files or over 6 hours; split into smaller issues |

Large initiatives belong in an epic. Agents implement the individual issues, not the epic itself.

### 18. Show the draft and wait for approval

Show the user the epic title (if any), the list of issues with size and phase, and one complete issue body. **Do not create anything in GitHub until the user approves.**

### 19. Create the issues in GitHub

1. Create missing labels: `gh label create epic --color 5319e7 -f`, `gh label create task --color 0e8a16 -f`, and `gh label create fase-N --color c5def5 -f` per phase.
2. Write each body to a file in the scratchpad and create the sub-issues first, saving their numbers:
   ```bash
   gh issue create --title "[cards]: verb + outcome" --body-file <path> --label "task,fase-1,enhancement"
   ```
3. Create the epic with the epic template and the `epic` label.
4. Edit each sub-issue to add `Parte de #<epic>` as the first line of its body (`gh issue edit N --body-file <path>`).
5. Report the epic link and a `# | title | phase | size` table.

For a single standalone issue, skip the epic steps.

## Epic template

```markdown
## Goal
<product summary in 3–4 lines>

## Key decisions
<short table taken from the plan>

## Tasks
- [ ] #N Phase 1 — ...
- [ ] #N Phase 2 — ...

## Workflow
Each task is picked up with `pick-issue #N`: one branch and one PR per task, in order. After the user authorizes the merge, `main` is updated and the next task is picked.

## Full plan
<plan path or link>
```

## Definition of Done (every sub-issue)

A PR from a `feat/<slug>` branch, created with the `pick-issue` skill, that closes the issue (`Closes #N`), is reviewed, and is **merged only with the user's explicit authorization**.

## Final adherence checklist

Before creating the issues, verify:

- [ ] Reuse search ran before drafting and its real results are recorded.
- [ ] `## Issue Classification` is first (after `Parte de #<epic>`) and contains all seven fields.
- [ ] Product context explains the user value.
- [ ] Business rules, project invariants and unknowns are explicit.
- [ ] Database design, key files, and exclusive files are included when applicable.
- [ ] Acceptance criteria are specific, testable, and include `flutter analyze` and `flutter test`.
- [ ] Testing strategy is defined.
- [ ] Medium/large tasks have phased deliverables; XL tasks are split.
- [ ] Labels and agent assignment are set.
- [ ] Required UX/UI (with `ValueKey`s and microcopy) and E2E sections are present.
- [ ] High-risk, money or auth/security work is marked for spec refinement.
- [ ] The issue does not duplicate reusable functionality or assume unverified data exists.

If any required check fails, do not create the issue yet. Complete the missing research or specification first.

## Rules

- **Never merge** PRs or branches without the user's explicit authorization for that specific merge.
- Do not create issues, labels or Projects before the user approves the draft.
- Do not include sensitive data (API keys, full card numbers, personal data) in issues.
