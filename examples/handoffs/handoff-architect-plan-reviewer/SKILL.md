---
name: handoff-architect-plan-reviewer
description: Bilateral contract for adversarial plan review between Architect (sender) and Architect-Plan-Reviewer (receiver). Defines the dispatch pointers and rigor declaration, the verdict and findings response, validation rules, and error handling.
user-invocable: false
---

# Skill: Handoff — Architect ↔ Architect-Plan-Reviewer

## Purpose

This contract governs adversarial review of a technical plan. The Architect dispatches it from its Review phase, once a plan is written to disk and before that plan reaches the user; the reviewer attacks the plan's reasoning across seven dimensions and returns a verdict with findings, each carrying a question sharp enough to resolve it. Review is single-round — the sender incorporates or carries forward what comes back and does not re-dispatch.

## Participants

| Role | Agent | Responsibility |
|---|---|---|
| Sender | Architect | Writes the plan to disk, declares the rigor tier and stakes the plan was authored against, writes the dispatch, and validates the response before acting on it |
| Receiver | Architect-Plan-Reviewer | Reads the plan, the discovery, and the codebase the plan touches; attacks across seven dimensions; returns a verdict with severity-ordered findings |

## Dispatch

The sender writes a handoff file following the workspace handoff protocol, with this payload:

| Field | Type | Required | Description |
|---|---|---|---|
| plan_path | path | yes | Workspace path to the plan under review |
| project_root | path | yes | Path to the repository the plan targets. The reviewer navigates it to confirm the paths, entities, and endpoints the plan references actually exist |
| rigor_tier | enum(lean, standard, hardened) | yes | The tier the plan was authored against, as resolved with the user at the start of planning. This is the declared standard the reviewer judges the plan's complexity against |
| stakes | string | yes | Who uses this feature and what breaks if it fails. Supplies the context that makes a proportionality finding evidence rather than opinion |
| discovery_path | path | no | Workspace path to the research or discovery files. The reviewer reads these as business truth |
| review_scope | string | no | Risk areas worth concentrated attention. Advisory — it directs where the reviewer looks first, never what it is permitted to report |

```yaml
plan_path: .workspace/shelf/features/2026-07-14-hold-queue/plans/1-hold-allocation.md
project_root: ~/projects/shelf
rigor_tier: hardened
stakes: Members wait in line for a returned copy; a copy allocated twice or skipped past the next member breaks the queue's fairness and needs a librarian to repair by hand.
discovery_path: .workspace/shelf/features/2026-07-14-hold-queue/research/
review_scope: Concurrency of allocation when two copies are returned at once, and expiry of unclaimed holds.
```

The plan never appears in the payload — `plan_path` points at it. There is deliberately no field for excluding sections from review: with a single round there is no "already reviewed" state to exempt, and a section the authoring agent removes from scope is a section nobody checks.

## Response

The receiver writes a response handoff following the workspace handoff protocol, with this payload:

| Field | Type | Required | Description |
|---|---|---|---|
| scope | string | yes | The plan's title — identifies what was reviewed |
| verdict | enum(approved, needs_fix, blocked) | yes | `approved` when no critical or high finding stands, `needs_fix` when one does, `blocked` when the dispatch could not be used |
| total_findings | integer | yes | Count of findings returned, 0 to 10 — equal to the length of `findings` |
| unverified_claims | list | no | Claims the plan's correctness rests on that could not be checked, each with why |
| findings | list | no | Flat and severity-ordered. Each entry carries `severity`, `dimension`, `source`, `description`, and `question` |

Each finding's fields: `severity` is critical, high, medium, or low. `dimension` names which attack dimension raised it. `source` cites the plan section, discovery section, or codebase file the finding rests on. `description` states what is wrong. `question` is specific enough that answering it resolves the finding — this is what the sender acts on, so a finding without one gives the sender nothing to do.

```yaml
scope: Hold Queue — Hold Allocation
verdict: needs_fix
total_findings: 3
unverified_claims:
  - claim: "the job scheduler never runs two instances of the same job concurrently"
    why: Context7 has no documentation for the scheduler version the plan pins
findings:
  - severity: critical
    dimension: Discovery contradictions
    source: Plan "Hold Lifecycle" vs discovery 2-hold-rules.md §3
    description: The plan marks a hold fulfilled when the copy is allocated; the discovery states a hold is fulfilled only when the member checks the copy out. These produce different queue states for the same return.
    question: Is a hold fulfilled at allocation or at checkout?
  - severity: high
    dimension: Missing edge cases
    source: Plan "Hold Lifecycle" — no branch for an expired pickup window
    description: A member may never collect the allocated copy. The plan defines allocation and checkout but not expiry, so the copy has no defined state to return to.
    question: What happens to the copy and to the next member in line when a pickup window expires?
  - severity: medium
    dimension: Complexity proportionality
    source: Plan ADR-03 — dedicated message queue with dead-letter handling for allocation events
    description: ADR-03 introduces a queue and a dead-letter path for allocations that happen a few hundred times a day in one branch library. At the hardened tier a row lock and a retry are warranted; a dedicated queue plus DLQ is infrastructure the volume does not call for.
    question: What does the dedicated queue buy over a transactional allocation with a row lock and an alert on failure?
```

A clean review returns the outcome fields alone:

```yaml
scope: Hold Queue — Hold Allocation
verdict: approved
total_findings: 0
```

## Validation

**Sender, before writing the dispatch:**

- `plan_path` exists on disk and sits in a `plans/` directory
- `project_root` exists on disk and is a directory
- `rigor_tier` is one of `lean`, `standard`, `hardened` — never inferred, always the value resolved with the user
- `stakes` is a non-empty statement of who uses the feature and what failure costs

**Receiver, on intake:**

- `plan_path` resolves to a readable file
- `project_root` resolves to a readable directory
- `rigor_tier` and `stakes` are both present — without them dimension 7 has no standard to judge against

**Sender, after receiving the response:**

- `approved` requires zero critical and zero high findings
- `needs_fix` requires at least one critical or high finding
- `blocked` requires `total_findings` of 0 and a stated reason
- `total_findings` equals the length of `findings` and never exceeds 10
- Every finding carries all five fields — `severity`, `dimension`, `source`, `description`, and `question`

## Error Handling

- **Dispatch fails the sender's own validation:** the sender resolves the missing value before writing anything. Dispatching without a rigor tier produces a review that either skips proportionality or invents a standard for it.
- **Receiver gets an unusable dispatch:** it returns `blocked` with zero findings and the failed validation rules named. It never returns `approved` — an unread plan and a clean plan must never produce the same verdict.
- **Discovery path is absent or unreadable:** the receiver reviews plan and codebase only, and records in `unverified_claims` that discovery contradictions could not be checked. It reports no contradiction finding against a discovery it could not read.
- **A claim the plan depends on cannot be verified:** the receiver records it in `unverified_claims` and continues. It reports no finding built on an unresolved claim, because a guessed dependency behavior produces a fabricated risk.
- **Sender receives `blocked`:** it treats the plan as unreviewed, corrects the dispatch, and re-sends. A `blocked` verdict is never counted as a review that happened, and re-sending after `blocked` is the one case that is not a second review round.
- **Sender receives `approved` alongside a populated `unverified_claims`:** it presents both to the user together, so a clean verdict is never read as covering ground the review could not reach.
- **Sender receives a malformed response:** it surfaces the validation failure to the user and holds off acting on any finding until a valid response arrives or the user directs otherwise.
