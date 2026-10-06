---
name: handoff-architect-rules-reviewer
description: Bilateral contract for plan conformance review between Architect (sender) and Architect-Rules-Reviewer (receiver). Defines the dispatch pointers, the verdict and findings response, validation rules, and error handling.
user-invocable: false
---

# Skill: Handoff — Architect ↔ Architect-Rules-Reviewer

## Purpose

This contract governs conformance review of a technical plan. The Architect dispatches it from its Review phase, once a plan is written to disk and before that plan reaches the user; the reviewer follows the dispatch's two pointers, judges the plan against the target project's own rules, and returns a verdict with findings. One plan per dispatch — a feature that produced several plans produces several dispatches, sent in parallel.

## Participants

| Role | Agent | Responsibility |
|---|---|---|
| Sender | Architect | Writes the plan to disk, resolves the project root, writes one dispatch per plan, and validates every response before acting on it |
| Receiver | Architect-Rules-Reviewer | Reads the plan, the project's rule system, its README, and the shared modules the plan names; returns a verdict with severity-ordered findings |

## Dispatch

The sender writes a handoff file following the workspace handoff protocol, with this payload:

| Field | Type | Required | Description |
|---|---|---|---|
| plan_path | path | yes | Workspace path to the single plan under review. A dispatch carries exactly one plan; several plans mean several dispatches. |
| project_root | path | yes | Path to the repository whose rules govern this plan — the directory holding `.claude/rules/`, `CLAUDE.md`, and `README.md`. The plan lives in the workspace, the rules live here, and the reviewer needs both. |

```yaml
plan_path: .workspace/shelf/features/2026-07-14-hold-queue/plans/2-pickup-reminders.md
project_root: ~/projects/shelf
```

The plan never appears in the payload — `plan_path` points at it, and the reviewer reads the source of truth. There is deliberately no scope or focus field: the reviewer checks the whole plan against the whole rule system, because a focus written by the agent under review would let it steer attention away from the conventions it did not know it broke.

## Response

The receiver writes a response handoff following the workspace handoff protocol, with this payload:

| Field | Type | Required | Description |
|---|---|---|---|
| scope | string | yes | The plan's title — identifies what was reviewed |
| verdict | enum(approved, needs_fix, blocked) | yes | `approved` when no critical or high finding stands, `needs_fix` when one does, `blocked` when the dispatch could not be used |
| total_findings | integer | yes | Count of findings returned, 0 to 10 — equal to the length of `findings` |
| rule_system | enum(present, absent) | yes | Whether the project root held a rule system. `absent` means the review ran against the README and the named modules only, and the sender must present it as an unguided review |
| unverified_rules | list | no | Rules whose mandated pattern could not be resolved, each with why it could not be checked |
| findings | list | no | Flat and severity-ordered. Each entry carries `severity`, `dimension`, `rule`, `plan_section`, `correction`, and `acknowledged` |

Each finding's fields: `severity` is critical, high, medium, or low. `dimension` names which conformance dimension caught it. `rule` names the governing rule and where it is written. `plan_section` names the plan's own heading — never a file path or line number, because the code does not exist yet. `correction` is what the plan should say instead. `acknowledged` is whether the plan documented the deviation, recorded so the sender routes it for human arbitration rather than fixing it silently.

```yaml
scope: Hold Queue — Pickup Reminders
verdict: needs_fix
total_findings: 3
rule_system: present
unverified_rules:
  - rule: foundation/persistence.md — "follow the framework's repository conventions"
    why: Context7 returned no result for the ORM version the project pins
findings:
  - severity: high
    dimension: Dependency direction
    rule: foundation/architecture.md — "domain services never import from infrastructure/"
    plan_section: "Pickup Reminders — Implementation"
    correction: Define a ReminderDispatcher port in the domain layer and have the scheduler depend on it; the queue client stays behind the adapter.
    acknowledged: false
  - severity: high
    dimension: Shared infrastructure bypass
    rule: components/notifications.md — "all outbound email goes through NotificationService"
    plan_section: "Pickup Reminders — Reminder Email"
    correction: Publish a HoldReadyForPickup event and let NotificationService render it; drop the direct SMTP call the plan specifies.
    acknowledged: false
  - severity: medium
    dimension: Contract convention
    rule: concerns/api.md — "error responses use the problem+json envelope"
    plan_section: "API Contracts"
    correction: Return the documented envelope for 409 and 422 instead of the bare message object.
    acknowledged: true
```

A clean review returns the outcome fields alone:

```yaml
scope: Hold Queue — Pickup Reminders
verdict: approved
total_findings: 0
rule_system: present
```

## Validation

**Sender, before writing the dispatch:**

- `plan_path` exists on disk and sits in a `plans/` directory
- `project_root` exists on disk and is a directory
- The dispatch carries exactly one `plan_path` — a list of plans is a contract violation

**Receiver, on intake:**

- `plan_path` resolves to a readable file
- `project_root` resolves to a readable directory
- The dispatch carries one `plan_path`, not a list

**Sender, after receiving the response:**

- `approved` requires zero critical and zero high findings
- `needs_fix` requires at least one critical or high finding
- `blocked` requires `total_findings` of 0 and a stated reason
- `total_findings` equals the length of `findings` and never exceeds 10
- Every finding carries all six fields — `severity`, `dimension`, `rule`, `plan_section`, `correction`, and `acknowledged`

## Error Handling

- **Dispatch fails the sender's own validation:** the sender resolves the path before writing anything. A handoff pointing at a file that is not there produces a `blocked` round trip that the sender pays for in full.
- **Receiver gets an unusable dispatch:** it returns `blocked` with zero findings and the failed validation rules named. It never returns `approved` — an unread plan and a clean plan must never produce the same verdict.
- **Project root holds no rule system:** the receiver reviews against the README and the modules the plan names, sets `rule_system: absent`, and returns a normal verdict on that reduced basis.
- **A rule's mandated pattern cannot be resolved:** the receiver records it in `unverified_rules` and continues. It reports no finding built on an unresolved pattern, because a guessed rule produces a fabricated violation.
- **Sender receives `blocked`:** it treats the plan as unreviewed, corrects the dispatch, and re-sends. A `blocked` verdict is never counted as a review that happened.
- **Sender receives `approved` with `rule_system: absent`:** it presents the result to the user as an unguided review and names the missing rule system, so a clean verdict on a reduced basis is never read as a clean verdict on a full one.
- **Sender receives a malformed response:** it surfaces the validation failure to the user and holds off acting on any finding until a valid response arrives or the user directs otherwise.
