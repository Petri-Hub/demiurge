---
name: forge-plan-open
description: "Canonical principles, mandatory anchors, writing standards, and quality checklist for creating open-structure plan template skills in the demiurge agent system. Use this skill when God needs to design, generate, or validate a plan template for infrastructure, tooling, testing, CI/CD, or project foundation plans — plans whose structure is unique to their domain and cannot be expressed through the catalog-driven forge-plan section system."
user-invocable: false
---

# Skill: Open-Structure Plan Creation

## Purpose

Some plans have no fixed shape: infrastructure, tooling, CI/CD, project foundation — work whose structure is unique to its domain and cannot be expressed through a catalog of predefined sections. Forcing those plans into catalog sections produces documents that fit the template and miss the work. Open-structure templates solve this with discipline instead of a catalog: four mandatory anchors (Summary, Context & Motivation, Scope, ADRs) that every plan must answer, and a freehand body the Architect composes at plan time from domain-specific sections guided by principles. This skill is the canonical reference for creating those templates — there are no recommended or default sections beyond the anchors; the Architect decides what the plan needs.

## Open-Structure Plan Template Skill Format

Every open-structure plan template skill follows this canonical structure. No exceptions.

```markdown
---
name: plan-open-{type}
description: "{what this template covers — the domains whose plans it governs}"
user-invocable: false
---

# Skill: Plan — {Type Name} (Open Structure)

## Purpose

{What kind of plans this template produces. The product/technology context that grounds freehand sections. 2-3 sentences.}

## Mandatory Anchors

{The four mandatory sections every open-structure plan must include, with rationale, template, example, and directives.}

## Freehand Body

{Guidance on how the Architect composes domain-specific sections. Principles, what they look like, and an example.}

## Writing Standards

{Universal writing standards plus open-structure-specific standards.}
```

### Frontmatter

#### Rationale

The frontmatter identifies the template and is how the Architect selects it. The `-open-` infix in the name is the signal that this template follows open-structure principles rather than catalog-driven composition; the `description` names the domains it covers.

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Skill identifier. Must follow the pattern `plan-open-{type}`. The `-open-` infix distinguishes open-structure templates from catalog-driven ones (`plan-{type}`). Examples: `plan-open-tooling`, `plan-open-mobile`. |
| `description` | Yes | What this template covers — the domains and plan types it governs. |
| `user-invocable` | Yes | Always `false` — plan templates are loaded by the Architect, never invoked by the user. |

#### Example

```yaml
---
name: plan-open-tooling
description: "Use when the Architect produces an open-structure plan — infrastructure, tooling, CI/CD, environments, migrations, project foundation, observability, developer tooling, or any plan whose structure is unique to its domain and cannot be expressed through the catalog-driven section system."
user-invocable: false
---
```

#### Directives

**Do:**
- Follow the `plan-open-{type}` naming convention — the `-open-` infix distinguishes open-structure from catalog-driven at load time
- Make `description` specific enough to distinguish from other open-structure templates

**Don't:**
- Don't use a vague name like `plan-open-generic` — the name states the scope the template covers (`tooling`, `mobile`, `data`). A deliberately stack-agnostic template is allowed when its scope is named and its Purpose tells the Architect to ground freehand sections in the target repository's stack at plan time
- Don't create a stack-agnostic template when the project already has a stack-specific one for the same scope — the specific one carries verified stack facts the generic one has to rediscover on every run
- Don't include selection guidance ("NOT for domain features…") — the Architect has already decided which template to load before reading the skill

## Mandatory Anchors

Every open-structure plan must include these four sections. They are non-negotiable. Their presence is what separates a disciplined open-structure plan from an unstructured brain dump. The Architect fills them regardless of the plan's domain.

These four anchors were chosen because they answer the only questions that every plan — regardless of domain — must answer:

1. **Where am I?** (Summary — navigation)
2. **Why does this exist?** (Context & Motivation — purpose)
3. **What is in and what is out?** (Scope — boundaries)
4. **What was decided and why?** (ADRs — decisions with trade-offs)

Everything else is domain-specific and belongs in the freehand body.

### Summary

> A navigation TOC for the plan file. Open-structure plans have variable sections, making a scannable map of every section and its anchor link more important than in fixed-structure plans.

#### Template

```markdown
## Summary

- [{Section Name}](#{section-anchor})
- [{Section Name}](#{section-anchor})
{...lists every section in the plan, in order}
```

#### Example

```markdown
## Summary

- [Context & Motivation](#context--motivation)
- [Scope](#scope)
- [Architecture Decision Records](#architecture-decision-records-adrs)
- [Pipeline Stages](#pipeline-stages)
- [Runner Configuration](#runner-configuration)
- [Deployment Strategy](#deployment-strategy)
```

#### Directives

**Do:**
- List every section in the plan, including all freehand sections
- Place Summary as the first section in the plan
- Update the TOC if freehand sections are added or renamed during planning

**Don't:**
- Don't omit freehand sections from the TOC — they are harder to find without anchors precisely because they are non-standard
- Don't list sections that don't appear in the plan — the TOC is a contract, not a wishlist

---

### Context & Motivation

> 1-3 sentences on WHY this plan exists. Anchors every downstream decision — when the executor encounters ambiguity in a later section, this section tells them what the plan is fundamentally trying to achieve.

#### Template

```markdown
## Context & Motivation

{1-3 sentences on WHY this plan exists. What business pain or technical debt it addresses. What changes after this plan is executed.}
```

#### Example

```markdown
## Context & Motivation

The deployment pipeline currently runs all jobs on a single runner, causing build queues of 20+ minutes during peak hours. Deployments to staging are manual and untracked. This plan introduces a multi-stage pipeline with parallelized jobs and automated staging deployment on every merge to main, cutting peak build time below 5 minutes and removing the manual deployment step.
```

#### Directives

**Do:**
- Focus on business value and the problem being solved, not the technical solution
- State what changes after execution — the reader should understand the before/after
- Keep to 1-3 sentences

**Don't:**
- Don't describe the technical solution here — that belongs in later sections
- Don't include implementation details, file paths, or technology names beyond what is needed to understand the motivation

---

### Scope

> Explicit in-scope and out-of-scope boundaries. Open-structure plans are often multi-round or multi-phase — without explicit scope, the executor cannot distinguish what to build now from what is deferred.

#### Template

```markdown
## Scope

### In Scope

- {Item or area within this plan's boundaries}
- {Item}

### Out of Scope

- {Item or area explicitly excluded — with a note on when or whether it will be addressed}
- {Item}
```

#### Example

```markdown
## Scope

### In Scope

- Pipeline definition file for the `shelf-api` module
- Parallelized build + test stages (lint, compile, unit test, integration test)
- Automated staging deployment stage triggered on merge to main
- Slack notification on pipeline failure

### Out of Scope

- Production deployment automation (Phase 2, after staging proves stable for 2 weeks)
- Pipeline for other modules (separate plans)
- Cross-environment secret rotation (owned by platform team)
```

#### Directives

**Do:**
- List concrete items, not categories — "build + test stages" not "some CI stuff"
- In "Out of Scope," note when deferred items will be addressed if known
- Make the boundary unambiguous — if the executor would reasonably wonder "is this my job?", the scope section should answer

**Don't:**
- Don't list vague categories like "configuration" or "setup" — be specific about what is configured and what is set up
- Don't leave "Out of Scope" empty — even "Nothing deferred, this plan is self-contained" is better than omission

---

### Architecture Decision Records (ADRs)

> Non-trivial architectural or design choices documented with context, decision, and trade-offs. Without ADRs, future readers see the "what" but not the "why." ADRs come after Scope because decisions are made within boundaries — the reader first understands what is in and out of scope, then sees the decisions that govern the in-scope work.

#### Template

```markdown
## Architecture Decision Records (ADRs)

| ID | Decision (Title) | Context (Why?) | Trade-offs / Consequences |
|---|---|---|---|
| ADR-01 | {Title} | {Why this decision was needed — what alternatives existed} | {What is sacrificed or gained by this choice} |
| ADR-02 | {Title} | {Context} | {Trade-offs} |
```

#### Example

```markdown
## Architecture Decision Records (ADRs)

| ID | Decision (Title) | Context (Why?) | Trade-offs / Consequences |
|---|---|---|---|
| ADR-01 | GitHub Actions over Jenkins | Jenkins requires a dedicated runner and maintenance overhead. GitHub Actions provides managed runners, native caching, and parallel jobs out of the box. The repository is already on GitHub. | Per-minute runner costs on private repos. Acceptable — estimated 4,000 min/month at $0.008/min = $32/mo. Jenkins would cost $0/min but ~4h/mo maintenance. |
| ADR-02 | Container-based deployment over bare-metal script | Staging deployment currently runs a shell script over SSH, which drifts between environments. Container builds produce identical artifacts across environments and enable rollback via image tags. | Requires a container registry. The existing GitHub Container Registry is used — no new infrastructure. Adds ~90s to the pipeline for image build + push. |
```

#### Directives

**Do:**
- Include trade-offs for every decision — a decision without trade-offs is either trivial or incomplete
- Name the alternatives considered, not just the chosen path
- Reference ADRs from freehand sections when a section is affected by a decision (e.g., "per ADR-01, GitHub Actions runners are used")

**Don't:**
- Don't document obvious or trivial choices — ADRs are for decisions where reasonable alternatives exist
- Don't write trade-offs as purely positive — every decision sacrifices something
- Don't repeat the ADR content in freehand sections — reference by ID

## Freehand Body

### What it is

The freehand body is the set of domain-specific sections that sit between the mandatory anchors. It is what makes open-structure plans open: the Architect composes sections based on what the plan needs, not what a catalog allows. There are no recommended or default sections — the Architect decides what the plan needs and composes those sections from scratch.

### How the Architect composes freehand sections

**1. Every section must have a clear purpose.** Before writing a section header, the Architect asks: "What question does this section answer for the executor?" If the answer is vague ("it provides context"), the section doesn't deserve to exist. If the answer is specific ("it defines the pipeline stages, their dependencies, and the trigger for each"), it does.

**2. Section names should be domain-native, not generic.** "Pipeline Stages" is better than "Configuration." "Runner Configuration" is better than "Setup." The section name tells the executor what domain concept lives inside.

**3. Sections should be composable — each is independent.** An executor should be able to read sections in any order and understand each one. Cross-references (e.g., "per ADR-01") connect them, but no section should depend on another section's prose to make sense.

**4. Depth over breadth.** A few deeply-specified sections are better than many shallow ones. Each section should provide enough detail that the executor can implement it without making design judgments. If a section raises more questions than it answers, it needs more detail — or it should be split into multiple sections.

**5. Include code, types, and configurations inline.** Open-structure plans often involve configuration files, type definitions, environment variables, and tool-specific syntax. These belong inline in the sections that define them — not in an appendix. The executor reads the plan top-to-bottom and implements as they go.

**6. Cross-reference everything.** ADRs are referenced by ID (ADR-XX). Freehand sections reference their governing ADR. Everything links — the plan is a web, not a list.

### What freehand sections look like

There is no fixed template for freehand sections — that is the point. But a well-composed freehand section typically includes:

- **A short introduction** (1-3 sentences) explaining what this layer/component/area does and why it exists
- **The specification** — types, code snippets, configuration, tables, or prose, depending on what the domain requires
- **Source references** — file paths, documentation links, or cross-references that ground the specification in verified fact

### Example freehand section

````markdown
## Pipeline Stages

Defines the ordered set of jobs in the CI workflow, their trigger conditions, and their dependencies. Each stage maps to a GitHub Actions job.

### Stage 1 — Build (parallel)

Triggers on: every push to any branch, every PR

Jobs run in parallel:
- `lint` — `npm run lint --workspace shelf-api`
- `compile` — `npm run build --workspace shelf-api`
- `unit-test` — `npm run test --workspace shelf-api`

Source: existing scripts verified at `apps/shelf-api/package.json:6-14`

### Stage 2 — Integration Test

Depends on: Stage 1 (all three jobs must pass)

```yaml
integration-test:
  needs: [lint, compile, unit-test]
  runs-on: ubuntu-latest
  steps:
    - uses: ./.github/actions/setup-env
    - run: npm run test:integration --workspace shelf-api
```

Uses the reusable composite action for the runtime and dependency cache — avoids duplicating setup across 4 jobs.

### Stage 3 — Build & Push Container (main branch only)

Depends on: Stage 2

Triggers on: merge to `main`

Builds the staging Docker image, tags it with the commit SHA, and pushes to the registry.

Image tag convention: `staging-{commit-sha}` (per ADR-02 — enables rollback by tag).
````

## Writing Standards

These standards apply to every open-structure plan, regardless of domain.

**Reference exact file paths.** `.github/workflows/shelf-api-ci.yml` is acceptable. "The pipeline file" is not. The Architect has read the codebase — use that knowledge.

**One concern per entry.** A table row that says "X and Y" is two rows. A section that covers "build and deploy" is two sections. Split them.

**No placeholders.** "...", "etc", "TBD", "N/A (fill later)" are not acceptable. If a section genuinely has no content, omit the entire section — do not leave placeholders.

**Cross-reference by ID.** ADRs are ADR-XX. Freehand sections reference their governing ADR. Everything links.

**Separate new from modified.** When a section distinguishes between new and existing elements, maintain that separation — they have different implementation implications.

**Every freehand section must state its purpose.** The first 1-3 sentences of a freehand section must answer: what does this section define, and why does the executor need it? A section without a purpose statement is a section that doesn't know why it exists.

**Source every specification.** Types, configurations, API shapes, and tool-specific syntax must trace to a file path, documentation link, or ADR. "The existing scripts are..." must be followed by "Source: verified at `apps/shelf-api/package.json:6-14`" or "Source: GitHub Actions documentation, verified via Context7." Unverified specifications are assumptions, and assumptions become silent bugs.

**Configuration values must be grounded.** If the plan specifies environment variables, default values, or configuration constants, each must trace to where that value comes from — a Terraform file, an existing config file, a verified documentation source. Invented configuration values are assumptions, and assumptions become silent bugs.

## Open-Structure Plan Template Composition

When God composes an open-structure plan template, the structure is:

```
1. Summary                    (mandatory anchor)
2. Context & Motivation       (mandatory anchor)
3. Scope                       (mandatory anchor)
4. ADRs                        (mandatory anchor)
5. {freehand sections}         (domain-specific, composed by the Architect at plan time)
```

The mandatory anchors always come first, in this order. Freehand sections follow, in whatever order the plan's domain demands. There are no recommended or default sections between the anchors and the freehand body.

### How God composes an open-structure template

1. **Includes all four mandatory anchors** — always, no exceptions
2. **Does NOT enumerate freehand sections** — the template's freehand body is left open. The template provides the principles (from the Freehand Body section above) and the Architect composes the actual sections at plan time, based on the specific plan's domain
3. **Grounds the template in the project's technology stack** — the Purpose section names the concrete technologies, patterns, and integrations the Architect should expect, so freehand sections are grounded in verified stack facts. A deliberately stack-agnostic template names no stack; its Purpose instead instructs the Architect to establish the target repository's stack during grounding, before any freehand section is written

## Quality Checklist

Before saving an open-structure plan template skill file, verify every item:

- [ ] Frontmatter is exactly `name`, `description`, and `user-invocable: false`
- [ ] `name` follows the `plan-open-{type}` convention — the `-open-` infix distinguishes from catalog-driven templates
- [ ] `description` states what the template covers
- [ ] All four mandatory anchors are present: Summary, Context & Motivation, Scope, ADRs
- [ ] Mandatory anchors appear in the order: Summary, Context & Motivation, Scope, ADRs
- [ ] Each mandatory anchor has a Rationale blockquote, Template (code block), Example (code block), and Directives (Do/Don't lists)
- [ ] No recommended or default sections exist between the anchors and the freehand body
- [ ] The Freehand Body section is present and explains: what it is, how the Architect composes freehand sections, what they look like, and the principles governing them
- [ ] Writing Standards include the universal standards (exact file paths, one concern per entry, no placeholders, cross-reference by ID, separate new from modified) plus open-structure-specific standards (every freehand section states its purpose, source every specification, configuration values must be grounded)
- [ ] The template's Purpose section grounds the template in the project's technology stack (concrete technologies, patterns, integrations) — or, for a deliberately stack-agnostic template, instructs the Architect to establish the target repository's stack during grounding
- [ ] The composition section explains the ordering constraint (mandatory anchors first, then freehand body — no intermediate layer)
- [ ] Examples are domain-neutral (no bias toward a specific use case like load testing)
