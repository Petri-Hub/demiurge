---
name: workspace-lifecycle-protocol
description: Defines how agents sync, detect, and manage workspaces inside .workspace/. Load this skill after workspace-structural-protocol whenever you need to interact with the workspace. Covers git sync (clone/pull/push), detection, folder initialization, file numbering, workspace continuation, and commit conventions.
user-invocable: false
---

# Skill: Workspace Lifecycle Protocol

## Purpose

This skill governs how agents **interact** with `.workspace/` — syncing with the remote repository, detecting existing workspaces, initializing new workspace folders, appending files, and persisting work. It builds on the structure defined in `workspace-structural-protocol`.

**Load `workspace-structural-protocol` first** to understand the folder layout, naming rules, and ownership before using any operation in this skill.

## Hard Constraints

These constraints are absolute. Violating any of them produces broken agent behavior — duplicate workspaces, lost data, or sync conflicts.

- **`.workspace/` is a git repository. You never `mkdir .workspace/`.** The `.workspace/` directory is a clone of a shared git repository, or a local git repository when the project declares no remote — it is never created as a plain folder. Running `mkdir .workspace/` produces a directory with no history and no sync, causing data loss and sync failures. The only valid ways to obtain `.workspace/` are `git clone` of the declared remote, or `git init` when there is none.

- **`.workspace/` lives in your current working directory. You never clone it elsewhere.** Always clone `.workspace/` into the directory where you are working — the project root. Never clone into a parent directory, a sibling directory, `/tmp/`, or any external path. Other agents expect `.workspace/` at the project root. Placing it elsewhere breaks cross-agent file sharing.

- **Sync before work. Persist before handoff.** Every agent invocation begins with a pull (or clone if not present). Every agent that writes files commits — and pushes, when a remote is declared — before returning to the orchestrator, before a HITL gate, and before any handoff. No exceptions.

## Repository

`.workspace/` is a git repository shared by all demiurge agents. Its remote is **declared by the project, not by this skill** — one line in the project's `CLAUDE.md`:

```
Workspace remote: {workspace-remote}
```

`{workspace-remote}` is any git URL the team can push to, kept separate from the product repository so plans and records never enter product history. Read the line before syncing. When the project declares no remote, the workspace is local-only: initialize it with `git init`, commit as usual, and skip every push.

This repository is the single source of truth. Every agent syncs on entry and persists before exit.

## Sync Protocol

### On invocation — `.workspace/` not found

Clone the declared remote into your current working directory:

```bash
git clone {workspace-remote} .workspace/
```

No remote declared — initialize a local repository instead:

```bash
git init .workspace/
```

Then proceed to Detection.

### On invocation — `.workspace/` exists

Pull the latest changes from inside `.workspace/` (skip when the workspace has no remote):

```bash
cd .workspace/ && git pull
```

### Recovery — uncommitted changes after pull

If `git pull` reveals uncommitted changes from a crashed previous session:

```bash
cd .workspace/ && git add . && git commit -m "recovery: uncommitted work from previous session"
```

Then proceed to Detection.

### On work completion — persist before handoff or HITL gate

When an agent finishes a work unit — before returning to the orchestrator, before surfacing a HITL checkpoint, or before any handoff — commit and push (commit only, for a local workspace):

```bash
cd .workspace/ && git add . && git commit -m "{agent}: {action}" && git push
```

**Commit message format:**

```
{agent-lowercase}: {action}
```

Examples:

```
librarian: docs complete — book-holds feature
architect: plan complete — book-holds feature
executor: implementation complete — book-holds feature
orchestrator: incident summary — catalog-search-outage incident
crawler: crawl complete — member-portal-mapping
quality-engineer: audit complete — 2026-07-23-member-portal-accessibility
```

### Sync summary

| Event | Git operation |
|---|---|
| `.workspace/` not found, remote declared | `git clone {workspace-remote} .workspace/` |
| `.workspace/` not found, no remote | `git init .workspace/` |
| Agent invoked, `.workspace/` exists | `git pull` (skipped without a remote) |
| Uncommitted changes after pull | `git add . && git commit -m "recovery: ..."` |
| Agent completes work unit | `git add . && git commit -m "{agent}: {action}" && git push` (no push without a remote) |

## Detection

Before initializing any workspace folders, detect what already exists.

### Step 1 — Check project folder

```bash
ls .workspace/ | grep {project}
```

If the project folder does not exist, initialize it (see Folder Initialization below).

### Step 2 — Check for existing workspace

```bash
ls .workspace/{project}/features/
ls .workspace/{project}/incidents/
ls .workspace/{project}/compositions/
ls .workspace/{project}/crawls/
ls .workspace/{project}/audits/
```

Match by slug (the descriptive part after the date). The date prefix makes listing chronologically sorted by default.

## Folder Initialization

These commands initialize sub-folders **inside the already-cloned `.workspace/` repository**. They do not create `.workspace/` itself — `.workspace/` is obtained exclusively via `git clone`, or `git init` when no remote is declared.

### Initialize project folder (first time only)

When no project folder exists yet in the workspace repository:

```bash
mkdir -p .workspace/{project}/features
mkdir -p .workspace/{project}/incidents
mkdir -p .workspace/{project}/compositions
mkdir -p .workspace/{project}/crawls
mkdir -p .workspace/{project}/audits
```

This creates the project namespace with all five type folders upfront. Even if the current task only needs one type, create all five — it costs nothing and prevents fragmented folder creation later.

### Initialize a feature workspace

```bash
mkdir -p .workspace/{project}/features/{date}-{feature-slug}/research
mkdir -p .workspace/{project}/features/{date}-{feature-slug}/plans
```

Then write the README.md.

### Initialize an incident workspace

```bash
mkdir -p .workspace/{project}/incidents/{date}-{slug}/investigations
mkdir -p .workspace/{project}/incidents/{date}-{slug}/plans
```

Then write the README.md.

### Initialize a crawl workspace

```bash
mkdir -p .workspace/{project}/crawls/{date}-{slug}/screenshots
mkdir -p .workspace/{project}/crawls/{date}-{slug}/flows
```

Create `screenshots/` and `flows/` based on which outputs the user requested. If screenshots are disabled, omit `screenshots/`. If flows are disabled, omit `flows/`. Then write the README.md and FRONTIER.md.

### Initialize an audit workspace

```bash
mkdir -p .workspace/{project}/audits/{date}-{slug}/findings
```

Then write the README.md run card and the AUDITS.md worklist seeded with the states in scope. Each finding gets its own folder under `findings/` as it is recorded — create those while writing findings, not upfront. See `workspace-audit-protocol` for the run card, worklist, and finding schemas.

### Commit message examples for crawls

```
crawler: crawl complete — 2026-05-05-member-portal-mapping
crawler: crawl complete — 2026-05-05-checkout-flow-screenshots
```

## Continuation

When a workspace already exists and you need to add content to it.

### Append a numbered file

Numbered files (research, investigations, plans) are sequential. To find the next available number:

```bash
ls .workspace/{project}/{type}/{slug}/{subfolder}/ | wc -l
```

Add 1 to the result. Then create the file:

```bash
touch .workspace/{project}/{type}/{slug}/{subfolder}/{N}-{descriptive-slug}.md
```

### Before appending

Always read the existing `README.md` and any existing files in the target subfolder before writing new ones. This prevents duplicating information that was already captured and ensures numbering continues correctly.

## Rules

1. **Sync before work.** Pull (or clone) at the start of every invocation. No exceptions.

2. **Persist before handoff.** Commit and push when your work unit is complete — before returning to the orchestrator, before a HITL gate, before any handoff. No exceptions.

3. **Never initialize workspace folders without checking first.** Always detect before initializing. Duplicate workspaces for the same work cause confusion.

4. **Write README.md before any content files.** The README anchors the workspace — it must exist before research, plans, or any other artifact.

5. **Use today's date for new workspaces.** The date prefix is the creation date, not the last-modified date.

6. **One workspace per unit of work.** A feature gets one feature workspace. An incident gets one incident workspace. Do not split the same work across multiple workspace folders.