---
name: forge-handoff
description: Meta-skill for producing individual handoff skill files — each one a bilateral communication contract between two agents. Covers the contract's sections, payload design, and the pointer principle for passing produced material. Use when creating, validating, or updating a handoff skill.
user-invocable: false
---

# **Skill: Forge Handoff**

## **Purpose**

When one agent dispatches work to another, both need to agree on exactly what is sent and what comes back — otherwise the sender guesses what the receiver needs, the receiver returns something the sender can't parse, and the failure surfaces two steps downstream where it's hardest to debug. A handoff skill is that agreement made explicit: a bilateral contract, loaded by both participants and by no one else. The sender reads the Dispatch section to know what to write; the receiver reads the Response section to know what to return. Neither agent embeds the contract in its own prompt — the skill file is the single source of truth.

This skill is the template for producing those contracts. It defines the contract's content — not the runtime mechanics of handoff files (location, naming, universal structure), which belong to the workspace protocol layer that every handoff skill references instead of duplicating.

---

## **The Two Essentials**

Everything else in a handoff contract is adaptable; these two are not.

**1. The section structure.** Every handoff skill has the same sections, in the same order, so any agent can navigate any contract:

```markdown
---
name: handoff-{sender}-{receiver}
description: {one-line description of this bilateral contract}
user-invocable: false
---

# Skill: Handoff — {Sender} ↔ {Receiver}

## Purpose
{What this handoff achieves, when it happens, and its direction. 2-3 sentences.}

## Participants
{Sender and receiver, one row each, with their responsibilities.}

## Dispatch
{What the sender writes: a fields table and a filled example.}

## Response
{What the receiver returns: a fields table and a filled example.
Omit this section entirely when the receiver only signals completion —
its absence is the declaration that the handoff is one-way.}

## Validation
{What both parties verify, as concrete pass/fail rules.}

## Error Handling
{What each party does when validation or the work itself fails.}
```

**2. The pointer principle.** When the material being handed over already exists as a file — a plan, a research document, an implementation — the payload carries a *pointer* to it (its workspace path, plus scope notes on what to look at), never the material itself inlined into the dispatch. Chat is transport, not storage: inlined content bloats context, drifts from the file on disk the moment either changes, and leaves no auditable record. The receiver follows the pointer and reads the source of truth. Compose actual content into payload fields only for data that exists nowhere else — a mission statement, scope boundaries, constraints gathered for this dispatch.

---

## **Writing the Sections**

**Purpose** — 2-3 sentences: what the handoff achieves, which pipeline phase triggers it, and whether the receiver returns a response or only signals completion.

**Participants** — a two-row table (sender, receiver) with each agent's responsibility. A handoff is bilateral; if several receivers get the same dispatch, write one contract per pair.

**Dispatch** — opens by referencing the workspace handoff protocol for file mechanics, then defines the payload: a fields table (name, type, required, and where the sender gets the value) followed by a filled example with realistic values. Field names are natural lowercase (`plan_path`, `review_scope`, `files_changed`) — the payload should read like a document, not a protocol dump. If the sender has genuinely different payload shapes in different pipeline contexts, give each context its own named subsection; don't force them into one table by making everything optional.

**Response** — mirrors Dispatch: fields table plus filled example. Lead with the outcome (`status`, `verdict`) and include something the sender can verify — findings, paths, evidence — rather than a bare "done".

**Validation** — a short list of concrete pass/fail rules both parties check ("every path in `files_changed` exists on disk", "an `approved` verdict requires an empty findings list").

**Error Handling** — what the sender does when its own dispatch fails validation, what the receiver does when the dispatch it gets is invalid or the work itself fails, and what the sender does with an invalid response. Name the action in each case.

---

## **Example — a Dispatch payload**

````markdown
## Dispatch

The sender writes a handoff file following the workspace handoff protocol, with this payload:

| Field | Type | Required | Description |
|---|---|---|---|
| plan_path | path | yes | Workspace path to the plan under review |
| review_scope | string | yes | What to focus on — sections, risk areas, specific concerns |
| ignore_sections | list | no | Plan sections to skip (already validated or out of scope) |

```yaml
plan_path: .workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md
review_scope: Error scenarios and state machine transitions — boundary cases are the highest risk.
ignore_sections:
  - Test Strategy
```
````

The plan itself never appears in the payload — `plan_path` points at it.

---

## **Quality Checklist**

- [ ] Frontmatter is exactly `name`, `description`, `user-invocable: false`, with `name` following `handoff-{sender}-{receiver}` in kebab-case
- [ ] All sections present in order; Response omitted only when the handoff is one-way
- [ ] Purpose names both participants, the trigger, and the direction
- [ ] Produced material is passed by pointer — no file content inlined into a payload that exists on disk
- [ ] Every field has a type, a required marker, and a description saying where its value comes from
- [ ] Field names are natural lowercase, and every example is filled with realistic values — no placeholders
- [ ] Validation rules are concrete pass/fail assertions covering both dispatch and response
- [ ] Error Handling names the action for each failure point
- [ ] No duplication of the workspace handoff protocol's content
