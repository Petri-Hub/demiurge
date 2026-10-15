---
name: workspace-evolution-protocol
description: Defines how agents capture friction at the end of a run — the Evolution Close-out, what counts as friction, the entry schema, where to write entries, and how to persist them. Load this skill at the start of every invocation alongside workspace-structural-protocol. Agents only record friction here; it is read and reviewed later, in a batch.
user-invocable: false
---

# Skill: Workspace Evolution Protocol

## Purpose

When you finish a job, you'll often notice things that got in your way — an instruction you had to guess at, a tool you wished you had, a rule that blocked work you were meant to do. This skill is how you write those things down so they can be fixed later.

You only write them down — you don't act on them yourself. The notes are read and reviewed later, in a batch, and that review is what decides whether anything changes. Your job is to leave one honest, specific note and move on. A note isn't complaining and it isn't admitting failure — it's how the system gets better.

**Read `workspace-structural-protocol` first** — it explains the `.workspace/` folder and how it's synced. Your notes live inside it.

## When to write your notes

Do this at **one point only: right at the end, just before you report that you're done.**

Don't stop in the middle of your work to write a note — finish the job first. Then take one moment to look back over the whole run.

### The close-out procedure

1. Look back over the run you just completed.
2. Ask yourself the three reflection questions below.
3. For each distinct thing worth recording, write one note (schema in the next section).
4. Persist your notes (see Persistence).
5. Report completion as normal.

### The three reflection questions

- **Where did I have to guess?** Was any instruction unclear, or did two contradict each other?
- **What did I have to fight or work around?** A missing tool or skill, a rule that blocked work you were supposed to do, a step that kept failing.
- **What would have made this easier?** A capability, a clearer instruction, or something you needed to know but didn't.

Answer only from **this run, your own experience.** Say what something cost *you, this time*. Don't guess how often it happens to other agents or how important it is overall — you can't know that, and guessing pollutes the notes. The later review works out the big picture across every agent's notes; that's its job, not yours.

### "Nothing to report" is a complete and common close-out

Most runs have no friction worth recording. **"No friction this run" is a correct, complete close-out** — when that is true, write no entry and report completion.

Do **not** invent friction to fill the close-out. A fabricated entry is worse than silence: it pollutes the review with noise that buries the real notes. Log liberally when friction is real; log nothing when it is not.

## What Counts as Friction

Log liberally — if something genuinely chafed, it is worth an entry. Examples:

- An instruction in your prompt or pipeline was ambiguous, vague, or contradicted another instruction.
- You needed a tool, MCP server, or skill you did not have, and had to work around its absence.
- A constraint blocked work that you believe was legitimate and in-scope.
- A pipeline phase did not match the reality of the task — missing a step, ordering steps wrong, or assuming inputs you did not have.
- A step failed repeatedly and you had to retry or improvise to get past it.
- A handoff from or to another agent was missing context you needed.
- You produced a worse result than you could have, and you can name what held you back.

### What is NOT friction (do not log these)

- **Normal HITL gates and approvals.** Waiting for the user to confirm is the system working as designed.
- **The user changing their mind or scope.** That is direction, not a system defect.
- **A constraint stopping you from doing something out of scope.** When a guardrail blocks out-of-scope work, it is functioning correctly — that is not friction, that is the boundary doing its job. Only log a constraint when it blocked work you believe was genuinely *in* scope.
- **Your own reasoning error that you caught and corrected** with no systemic cause behind it.

## Entry Location and Naming

Evolution entries live under a dedicated top-level area of the `.workspace/` repository, namespaced by agent:

```
.workspace/
  evolution/
    entries/
      {agent-id}/
        {date}-{slug}.md        ← open entries awaiting review
    archive/
      {agent-id}/
        {date}-{slug}.md        ← entries already processed by the review (don't write here)
    reviews/
      {date}-review.md          ← review ledgers (don't write here)
```

- `{agent-id}` — your own name in kebab-case, matching the workspace commit convention: `quality-engineer`, `architect`, `executor`, `demiurge`, `scribe`.
- `{date}` — ISO format, today's date: `2026-06-15`.
- `{slug}` — short kebab-case naming the friction: `ambiguous-date-format`, `missing-lint-report-tool`, `plan-assumed-research-files`.

You write only to `evolution/entries/{agent-id}/`. The `archive/` and `reviews/` folders belong to the review — never write there.

If `evolution/entries/` or your agent folder does not exist yet, create it before writing:

```bash
mkdir -p .workspace/evolution/entries/{agent-id}
```

## Entry Schema

Each entry is one markdown file: frontmatter plus three short free-form answers. There is **no category field** — you do not classify your own friction. Categories are assigned later during the review, where the whole set of notes is in view and classification is actually useful.

```markdown
---
agent: {agent-id}
date: {YYYY-MM-DD}
pipeline: {pipeline-skill-name or "none"}
phase: {phase name where friction arose, or "across the run"}
felt-severity: low | medium | high
status: open
---

## What happened
{The concrete situation. Name the exact instruction text, file path, tool, skill, or step that created the friction — concrete beats abstract.}

## What I did about it
{What you actually did: worked around it, guessed, retried, asked the user, or produced a degraded result.}

## What would have helped
{Optional. A capability, a clearer instruction, or a piece of knowledge that would have removed the friction. This is a hypothesis for the review to weigh, not a spec — write "—" if you have none.}
```

**Field notes:**

- `felt-severity` is **how much it cost you on this run**, nothing more. `low` = minor annoyance; `medium` = real extra work or a degraded result; `high` = blocked or forced a significant workaround. It is not a system-wide importance rating.
- `status: open` marks the entry as awaiting review. You always write `open`. The review flips it and moves the file to `archive/` once processed.
- One entry per **distinct** friction. Do not bundle two unrelated frictions into one file — it breaks clustering. Do not split one friction across two files either.

### Worked example

`.workspace/evolution/entries/architect/2026-06-15-plan-template-missing-async-section.md`

```markdown
---
agent: architect
date: 2026-06-15
pipeline: pipeline-architect-deep-planning
phase: Contextualization
felt-severity: medium
status: open
---

## What happened
The project plan template has no section for asynchronous/event-driven flows. The feature I planned was entirely message-driven (a message queue consumer), and I had to force the design into the synchronous "Endpoints" section, which made the plan read awkwardly for the Executor.

## What I did about it
I added an unofficial "Event Flows" subsection by hand inside the Implementation Steps section, which deviates from the template the quality checklist expects.

## What would have helped
A dedicated "Asynchronous Flows" section in the plan template, covering producers, consumers, and the message contract.
```

## Persistence

Evolution entries ride your normal end-of-run persistence. Because the close-out runs immediately before you report completion — the same point at which you commit and push your work — your entries are included in that push automatically.

If your primary work was already pushed and only the evolution entry remains, persist it explicitly:

```bash
cd .workspace/ && git add evolution/ && git commit -m "{agent-id}: evolution entry — {slug}" && git push
```

Never leave an entry uncommitted — an unpushed entry is invisible to the review and the note is lost.

## Hard Constraints

These are absolute. Violating them breaks the review or the integrity of the notes.

- **Never make up friction.** "Nothing to report" is the correct close-out for most runs. A fabricated note buries the real ones.
- **Never rate how important something is system-wide.** Report only your own experience of this run. Working out the big picture across every agent's notes is the reviewer's job, not yours.
- **Never write to `evolution/archive/` or `evolution/reviews/`.** Those belong to the review. You write only to `evolution/entries/{agent-id}/`.
