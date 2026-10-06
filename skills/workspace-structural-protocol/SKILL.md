---
name: workspace-structural-protocol
description: Defines the .workspace/ folder structure, naming conventions, file ownership rules, and path patterns used across all demiurge agents. This is the schema — load it first to understand what the workspace looks like. For detection and folder initialization operations, load workspace-lifecycle-protocol after this one.
user-invocable: false
---

# Skill: Workspace Structure Protocol

## Purpose

This skill defines the `.workspace/` directory — the file-based memory system used by all demiurge agents. It covers the folder layout, naming rules, file ownership, and path patterns. It does **not** cover how to detect or initialize workspaces — that belongs in `workspace-lifecycle-protocol`.

## Repository Nature

`.workspace/` is a **git repository**, not a plain folder. It is a shared, version-controlled store cloned from the remote the project declares — or a local repository when it declares none. Every agent clones it into its current working directory on first use, pulls before every session, and pushes after completing work. Treat `.workspace/` as a database with git-based concurrency — never as a local scratch directory.

## Core Principle

**Files are the shared memory. Messages are for coordination.**

When an agent produces research, a plan, documentation research, a composition, a crawl record, or an audit, it writes a file. The next agent reads that file directly. This keeps individual agent context windows lean and ensures no information is lost between handoffs.

## Constraints

- **`.workspace/` is obtained by `git clone` (or `git init` when the project declares no remote), never by `mkdir`.** The directory is a shared git repository. Creating it as a plain folder disconnects the agent from all prior work and breaks cross-agent file sharing. See `workspace-lifecycle-protocol` for the full sync specification.

- **`.workspace/` lives in the agent's current working directory.** Always clone into the project root where you are working. Never clone into a different path, a parent directory, or an external location. Other agents expect `.workspace/` at the project root.

## Full Structure

```
.workspace/
  {project}/
    features/
      {date}-{feature-slug}/
        README.md
        research/
          1-{descriptive-slug}.md
          2-{descriptive-slug}.md
        docs/
          1-{descriptive-slug}.md
          2-{descriptive-slug}.md
        plans/
          1-{descriptive-slug}.md
          2-{descriptive-slug}.md
    incidents/
      {date}-{slug}/
        README.md
        investigations/
          1-{descriptive-slug}.md
          2-{descriptive-slug}.md
        docs/
          1-{descriptive-slug}.md
        plans/
          1-{descriptive-slug}.md
    compositions/
      {date}-{slug}/
        README.md
        {slug}.md
        assets/
          {asset-slug}.{ext}
    crawls/
      {date}-{slug}/
        README.md
        FRONTIER.md
        screenshots/
          01-{page-slug}.png
          02-{page-slug}.png
        flows/
          {flow-slug}.md
    audits/
      {date}-{slug}/
        README.md
        AUDITS.md
        findings/
          {N}-{finding-slug}/
            README.md
            evidence/
              {evidence-file}
  evolution/
    entries/
      {agent-id}/
        {date}-{slug}.md
    archive/
      {agent-id}/
        {date}-{slug}.md
    reviews/
      {date}-review.md
  teaching/
    courses/
      {date}-{course-slug}/
        README.md
        syllabus.md
        ledger.md
        quizzes/
          {n}-{date}.md
        episodes/
          {n}-{episode-slug}.md
    archive/
      {date}-{course-slug}/
```

> **`evolution/` sits outside any `{project}/` folder.** It is a system area, not a project workspace — agents record end-of-run friction notes here, and they are reviewed later in a batch. See `workspace-evolution-protocol` for the capture rules and entry schema.

> **`teaching/` is likewise a system area, owned exclusively by Teacher.** It holds long-lived course state for the learning pipelines — syllabi, spaced-repetition ledgers, quiz history. Its file schemas live in `teacher-teaching-protocol`; no other agent writes or needs to read here.

> **`audits/` is a shared project workspace type, open to any agent performing an audit.** Its internal schema — the run card, the per-finding folder, the verdict and severity vocabulary, and the evidence rules — lives in `workspace-audit-protocol`. Load that skill before writing an audit.

## Folder Purpose

| Folder | Purpose |
|---|---|
| `{project}/` | Project namespace — all work for one product or repository lives here |
| `{project}/features/` | Feature delivery workspaces |
| `{project}/incidents/` | Incident investigation and hotfix workspaces |
| `{project}/compositions/` | Finished, audience-ready written deliverables produced by Scribe — post-mortems, technical reports, executive briefs, announcements |
| `{project}/crawls/` | Web application crawl records — screenshots, navigation flows, and URL tracking |
| `{project}/audits/` | Audit records — findings backed by evidence, judged against stated criteria. Domain-agnostic: quality, accessibility, security, functional. Schema in `workspace-audit-protocol` |
| `evolution/` | System area (outside any project) for the evolution loop — agents' end-of-run friction notes, the archive of processed notes, and review ledgers |
| `evolution/entries/{agent-id}/` | Open friction notes awaiting review, namespaced per agent — agents write only here |
| `evolution/archive/{agent-id}/` | Notes already processed by the review — written by the review only |
| `evolution/reviews/` | Batch review ledgers — written by the review only |
| `teaching/` | System area (outside any project) for Teacher's learning pipelines — active course state and archive |
| `teaching/courses/{date}-{course-slug}/` | One active course: card, syllabus, spacing ledger, quiz history, episode records — written by Teacher only |
| `teaching/archive/{date}-{course-slug}/` | Completed courses, moved here whole at close — written by Teacher only |

## Naming Conventions

### Project folders

```
{project}
```

Lowercase, no spaces, no special characters. One folder per product or repository the fleet works on.

- `shelf`
- `shelf-admin`

### Feature folders

```
{date}-{feature-slug}
```

- `date` — ISO format: `2026-05-05`
- `feature-slug` — short kebab-case description of the feature
- **Do not repeat the project name** — the project is already the parent folder
- Examples: `2026-05-05-book-holds`, `2026-05-05-loan-module-refactor`

### Incident folders

```
{date}-{slug}
```

- `date` — ISO format: `2026-04-27`
- `slug` — short kebab-case description of the incident
- **Do not repeat the project name**
- Examples: `2026-04-27-due-date-off-by-one`, `2026-04-27-catalog-search-outage`

### Composition folders

```
{date}-{slug}
```

- `date` — ISO format: `2026-06-12`
- `slug` — short kebab-case naming the deliverable and, where useful, its audience
- **Do not repeat the project name** — the project is already the parent folder
- Examples: `2026-06-12-shelf-architecture-overview`, `2026-04-27-catalog-search-outage-postmortem`

The composition itself is a single markdown file named after the slug (`{slug}.md`); supporting images or exhibits live in an optional `assets/` subfolder.

### Crawl folders

```
{date}-{slug}
```

- `date` — ISO format: `2026-05-05`
- `slug` — short kebab-case describing the crawl target or purpose
- **Do not repeat the project name**
- Examples: `2026-05-05-mapping-external-client-app`, `2026-05-05-checkout-flow-screenshots`

### Crawl screenshot files

```
{NN}-{page-slug}.png
```

- `NN` — sequential integer starting at 01, zero-padded to two digits
- `page-slug` — short kebab-case describing the page captured
- For parallelized crawls, prefix with section slug: `{prefix}-{NN}-{page-slug}.png`
- Examples: `01-homepage.png`, `02-login-page.png`, `auth-01-login-form.png`

### Crawl flow files

```
{flow-slug}.md
```

- `flow-slug` — short kebab-case describing the navigation flow or user journey
- Each file contains a Mermaid `flowchart TD` diagram
- Examples: `authentication.md`, `checkout.md`, `main-navigation.md`

### Audit folders

```
{date}-{slug}
```

- `date` — ISO format: `2026-07-23`
- `slug` — short kebab-case naming the audit's subject and, where useful, its type
- **Do not repeat the project name**
- Examples: `2026-07-23-admin-accessibility`, `2026-07-23-checkout-security`

Naming inside an audit folder — finding folders and evidence files — is defined in `workspace-audit-protocol`.

### Numbered files (research, plans, investigations)

```
{N}-{descriptive-slug}.md
```

- `N` — sequential integer starting at 1, no zero-padding
- `slug` — specific and descriptive, reflects the content
- Examples: `1-loans-module-architecture.md`, `2-hold-queue-entry-points.md`

**The number defines the reading order.** Write files in the order the next agent should read them. Foundation first, detail last.

### Date prefix benefit

All workspace types use a `{date}-` prefix. This means `ls` output is naturally sorted chronologically — newest at the bottom, oldest at the top. No extra tooling needed to find recent work.

## Path Reference Pattern

All workspace paths follow this pattern:

```
.workspace/{project}/{type}/{date}-{slug}/
```

The `{project}` segment is always present for **workspaces**. The only areas outside a project folder are `evolution/` (the evolution loop) and `teaching/` (Teacher's course state) — system areas rather than project workspaces.

## File Ownership

| File / Folder | Written by | Read by |
|---|---|---|
| `features/.../README.md` | Agent that opens the feature workspace | Any agent |
| `features/.../research/{N}-*.md` | User, or the agent the user asked to record findings | Architect |
| `features/.../docs/{N}-*.md` | Librarian | Architect, Executor, any agent |
| `features/.../plans/{N}-*.md` | Architect | Executor |
| `incidents/.../README.md` | Agent that opens the incident workspace | Any agent |
| `incidents/.../investigations/{N}-*.md` | User, or the agent the user asked to record findings | Orchestrator, Architect |
| `incidents/.../docs/{N}-*.md` | Librarian | Architect, Executor, any agent |
| `incidents/.../plans/{N}-*.md` | Architect | Executor |
| `compositions/.../README.md` | Scribe | User, any agent |
| `compositions/.../{slug}.md` | Scribe | User, any agent |
| `compositions/.../assets/*` | Scribe | User, any agent |
| `crawls/.../README.md` | Crawler | Any agent |
| `crawls/.../FRONTIER.md` | Crawler | Sub-crawlers during parallel execution, any agent |
| `crawls/.../screenshots/*.png` | Crawler and sub-crawlers | User, any agent needing visual context |
| `crawls/.../flows/*.md` | Crawler | User, any agent |
| `audits/.../README.md` | The agent performing the audit | User, any agent |
| `audits/.../findings/{N}-{slug}/FINDING.md` | The agent performing the audit | User, any agent |
| `audits/.../findings/{N}-{slug}/evidence/*` | The agent performing the audit | User, any agent |
| `evolution/entries/{agent-id}/*.md` | The agent named by `{agent-id}` (its own folder only) | The review |
| `evolution/archive/{agent-id}/*.md` | The review | The review, any agent auditing past decisions |
| `evolution/reviews/*.md` | The review | User, any agent |
| `teaching/**` | Teacher | Teacher, user |

**Ownership rules:**

- The Architect never writes to `research/`, `investigations/`, or `docs/` — research and investigations are inputs it grounds against, and `docs/` belongs to Librarian
- Librarian writes to `docs/` only — never to `research/`, `plans/`, or `investigations/`
- The Executor reads plans but does not write to `.workspace/`
- The Orchestrator reads investigation outputs but does not write research or plans
- The Crawler writes crawl records under `crawls/` — screenshots, FRONTIER.md, README.md, and flows
- Sub-crawler instances write screenshots only — the parent Crawler owns all markdown files
- Scribe writes to `compositions/` only — never to `research/`, `docs/`, `plans/`, or `investigations/`
- Any agent performing an audit writes under `audits/` — the run card records which one; one audit folder per audit, so parallel audits never share a folder
- Every agent writes its friction notes only to its own `evolution/entries/{agent-id}/` folder — never to another agent's folder, and never to `evolution/archive/` or `evolution/reviews/`
- Teacher writes to `teaching/` and its own `evolution/entries/teacher/` only — never to project folders; no other agent writes to `teaching/`

## README.md Template

Every workspace folder must have a `README.md` at its root. Keep it short — its purpose is orientation, not documentation.

```markdown
# {Workspace Title}

- **Type:** feature | incident | crawl | composition | audit
- **Project:** {project}
- **Opened:** {YYYY-MM-DD}
- **Opened by:** {agent or user}

## Context

{1–3 sentences describing what this workspace is for.}
```

## Agent Quick Reference

| Agent | Responsibility in `.workspace/` |
|---|---|
| **Orchestrator** | Creates feature and incident workspaces → delegates planning and implementation → gates on plan → synthesizes results for the user |
| **Architect** | Reads research, investigation, or docs files → writes numbered plan files |
| **Executor** | Reads plan files and docs files → executes |
| **Librarian** | Writes documentation research files under `docs/` in features and incidents workspaces |
| **Crawler** | Writes crawl records under `{project}/crawls/` — screenshots, FRONTIER.md, README.md, flows |
| **Scribe** | Writes finished documents under `{project}/compositions/` — the composition file, its README.md, and optional assets |
| **Teacher** | Writes course state under `teaching/` — syllabi, ledgers, quizzes, episode records; may read project artifacts as course source material |
| **Auditing agents** (any agent running an audit) | Write audit records under `{project}/audits/` — run card, per-finding folders, evidence. Schema in `workspace-audit-protocol` |
