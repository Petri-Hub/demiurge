---
name: handoff-executor-quality-reviewer
description: Bilateral contract for code quality review between Executor (sender) and Executor - Quality Reviewer (receiver). Defines dispatch payload, response payload, validation, and error handling.
user-invocable: false
---

# Skill: Handoff — Executor ↔ Executor - Quality Reviewer

## Purpose

This skill defines the bilateral contract between Executor and Executor - Quality Reviewer during the Review phase. The Executor dispatches implementation files and the constraint pack; the Quality Reviewer evaluates against a 9-criteria checklist and returns structured findings with fix suggestions. This handoff happens once per task during Phase 6 (Review) of Plan Execution or Phase 6 (Review) of Direct Execution, only when quality review is enabled.

## Participants

| Role | Agent | Responsibility |
|---|---|---|
| Sender | Executor | Collects files changed and constraint pack from grounding, writes dispatch handoff file |
| Receiver | Executor - Quality Reviewer | Reads each file, evaluates against 9-criteria checklist and constraint pack, returns findings |

## Dispatch

The sender writes a handoff file following `workspace-handoff-protocol`. The payload is structured as Markdown sections.

### Variant: Review Phase

Used when the Executor completes implementation for a task and quality review is enabled in the configuration. Same structure for both Plan Execution and Direct Execution — plan-specific fields are optional.

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Task Title | yes | `string` | Title of the subtask being reviewed. From the todowrite tracker or "Direct Execution". |
| Plan Path | yes | `path` | Absolute path to the plan file being executed, or the literal string `DIRECT`. |
| Files Changed | yes | `list<path>` | Absolute paths to every file modified or created in this subtask. From the implementation evidence. |
| Constraint Pack | yes | `object` | Structured object with subsections. From grounding output. |
| Reference Module Path | no | `path` | Absolute path to a reference module that exemplifies correct patterns for this layer. From grounding output. |
| Plan Context | no | `string` | Brief context about what the implementation is supposed to achieve. From the plan or user requirements. |

**Constraint Pack Subsections:**

| Subsection | Required | Type | Description |
|---|---|---|---|
| Mandatory Rules | yes | `table{Category, Rule}` | Architectural rules tagged by category. From grounding output. |
| Prohibitions | yes | `list{string}` | Hard boundaries that must not be crossed. From grounding output. |

**Concrete Example:**

`````markdown
## Payload

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Plan Path

`.workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md`

### Files Changed

- `~/projects/shelf/modules/loan-extension/src/main/java/domain/entities/LoanExtension.java`
- `~/projects/shelf/modules/loan-extension/src/main/java/application/services/ExtendLoanService.java`
- `~/projects/shelf/modules/loan-extension/src/main/java/application/ports/LoanExtensionRepositoryPort.java`

### Constraint Pack

#### Mandatory Rules

| Category | Rule |
|---|---|
| layering | Service layer does not access repository directly — use port interface |
| layering | Controllers do not contain business logic — delegate to use case services |
| errors | All business rule violations return 422 with structured error body |

#### Prohibitions

- Do not modify the HoldsModule — out of scope
- Do not use raw SQL queries outside repository implementations

### Reference Module Path

`~/projects/shelf/modules/holds/`

### Plan Context

Two behavioral contracts for loan extension: BC-01 extends a loan within its allowance (deduct days, create record), BC-02 rejects oversize requests (return 422, no allowance change). Concurrent writes guarded by optimistic locking — low risk tolerance for layering violations.
`````

## Response

The receiver writes a response handoff file following `workspace-handoff-protocol`. The response payload is structured as Markdown sections.

### Variant: Review Phase

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Status | yes | `enum(done)` | Always `done` — the review completed. Findings determine whether code needs fixing. |
| Task Title | yes | `string` | Echoes the dispatch Task Title for traceability. |
| Verdict | yes | `enum(approved, needs_fix)` | `approved` when no critical or high findings. `needs_fix` when one or more critical or high findings exist. |
| Severity | yes | `enum(critical, high, medium, low)` | The highest severity among all findings. `low` when approved with no findings. |
| Findings | yes | `table{#, Criterion, Severity, File, Description}` | Every finding with its criterion from the 9-criteria checklist. Empty table when approved with no findings. |
| Fix Suggestions | yes | `table{#, Finding, Suggestion}` | One concrete, actionable fix per finding. Empty table when approved with no findings. |

**Concrete Example:**

`````markdown
## Payload

### Status

`done`

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Verdict

`needs_fix`

### Severity

`high`

### Findings

| # | Criterion | Severity | File | Description |
|---|---|---|---|---|
| 1 | Architecture adherence | high | `ExtendLoanService.java:47` | Service imports `LoanExtensionRepositoryImpl` directly instead of using the port interface — violates layering rule |
| 2 | Error handling | high | `ExtendLoanService.java:62` | Method catches generic `Exception` and returns null instead of throwing a domain-specific exception — caller cannot distinguish failure modes |
| 3 | DRY violations | medium | `ExtendLoanService.java:35,71` | Extension allowance validation duplicated in both `extendLoan` and `rejectExtension` methods |

### Fix Suggestions

| # | Finding | Suggestion |
|---|---|---|
| 1 | Direct repository import | Replace `LoanExtensionRepositoryImpl` import with `LoanExtensionRepositoryPort`. Inject the port interface via constructor. |
| 2 | Generic exception catch | Replace `catch (Exception e)` with `catch (OptimisticLockException e)` for the locking failure, and throw `ExtensionLimitExceededException` for the business rule violation. Both should propagate as 422 responses. |
| 3 | Duplicated validation | Extract `validateExtensionAllowance(int remainingDays, int requestedDays)` as a private method. Call it from both code paths. |
`````

## Validation

Both parties must verify:

**Dispatch-side (sender checks before writing):**

- Task Title must be a non-empty string
- Plan Path must be an absolute path to an existing file, or the literal string `DIRECT`
- Files Changed must contain at least one path
- Constraint Pack must include at least one Mandatory Rule
- Every path in Files Changed must exist on disk at dispatch time

**Response-side (sender checks after receiving):**

- Verdict `approved` must have no critical or high findings in the Findings table
- Verdict `needs_fix` must have at least one critical or high finding
- Severity must match the highest severity in the Findings table
- Every finding must have a corresponding Fix Suggestion
- Task Title must match the dispatch Task Title for traceability

## Error Handling

- **Dispatch validation failure:** Sender stops and surfaces the validation error to the user. Do not write the handoff file.
- **Intake validation failure:** Receiver writes a response handoff with Status `done`, Verdict `approved`, Severity `low`, and Notes listing which validation rules failed — cannot review files that do not exist or a constraint pack without rules.
- **Execution failure (file unreadable):** Receiver skips the unreadable file and reviews the remaining files. Notes which file was skipped and why. Continues with available files.
- **Response validation failure:** Sender applies the same severity logic as the Assess & Fix phase. Critical findings stop execution. High findings trigger a fix iteration. Medium/low are accepted as observations.

## Examples

### End-to-end: Plan Execution Quality Review

**Dispatch handoff file** (`execution/handoffs/7-quality-review-dispatch.md`):

`````markdown
---
from: executor
to: executor-quality-reviewer
timestamp: 2026-05-27T15:30:00Z
type: dispatch
status: pending
---

# Handoff: Executor → Quality Reviewer

## Purpose

Review the ExtendLoanService implementation for code quality, architecture adherence, and constraint compliance.

## Context

GREEN phase complete for task "Implement ExtendLoanService — BC-01 and BC-02". Tests pass. Quality review enabled in configuration. Constraint pack from grounding has 7 mandatory rules and 3 prohibitions. Holds module is the reference for correct patterns.

## Payload

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Plan Path

`.workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md`

### Files Changed

- `~/projects/shelf/modules/loan-extension/src/main/java/domain/entities/LoanExtension.java`
- `~/projects/shelf/modules/loan-extension/src/main/java/application/services/ExtendLoanService.java`
- `~/projects/shelf/modules/loan-extension/src/main/java/application/ports/LoanExtensionRepositoryPort.java`

### Constraint Pack

#### Mandatory Rules

| Category | Rule |
|---|---|
| layering | Service layer does not access repository directly — use port interface |
| layering | Controllers do not contain business logic — delegate to use case services |
| errors | All business rule violations return 422 with structured error body |

#### Prohibitions

- Do not modify the HoldsModule — out of scope
- Do not use raw SQL queries outside repository implementations

### Reference Module Path

`~/projects/shelf/modules/holds/`

### Plan Context

Two behavioral contracts for loan extension: BC-01 extends a loan within its allowance (deduct days, create record), BC-02 rejects oversize requests (return 422, no allowance change). Concurrent writes guarded by optimistic locking — low risk tolerance for layering violations.

## Validation

- Task Title is non-empty
- Plan Path points to existing file
- 3 Files Changed — all exist on disk
- Constraint Pack has 3 Mandatory Rules
`````

**Response handoff file** (`execution/handoffs/8-quality-review-response.md`):

`````markdown
---
from: executor-quality-reviewer
to: executor
timestamp: 2026-05-27T15:35:00Z
type: response
status: done
---

# Handoff: Quality Reviewer → Executor

## Purpose

Return quality review findings for the ExtendLoanService implementation.

## Context

Reviewed 3 files against the 9-criteria checklist and constraint pack. Found 2 high-severity layering and error-handling violations and 1 medium DRY issue. The service imports the concrete repository instead of the port interface, and uses a generic catch block.

## Payload

### Status

`done`

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Verdict

`needs_fix`

### Severity

`high`

### Findings

| # | Criterion | Severity | File | Description |
|---|---|---|---|---|
| 1 | Architecture adherence | high | `ExtendLoanService.java:47` | Service imports `LoanExtensionRepositoryImpl` directly instead of using the port interface — violates layering rule |
| 2 | Error handling | high | `ExtendLoanService.java:62` | Method catches generic `Exception` and returns null instead of throwing a domain-specific exception — caller cannot distinguish failure modes |
| 3 | DRY violations | medium | `ExtendLoanService.java:35,71` | Extension allowance validation duplicated in both `extendLoan` and `rejectExtension` methods |

### Fix Suggestions

| # | Finding | Suggestion |
|---|---|---|
| 1 | Direct repository import | Replace `LoanExtensionRepositoryImpl` import with `LoanExtensionRepositoryPort`. Inject the port interface via constructor. |
| 2 | Generic exception catch | Replace `catch (Exception e)` with `catch (OptimisticLockException e)` for the locking failure, and throw `ExtensionLimitExceededException` for the business rule violation. Both should propagate as 422 responses. |
| 3 | Duplicated validation | Extract `validateExtensionAllowance(int remainingDays, int requestedDays)` as a private method. Call it from both code paths. |

## Validation

- Verdict `needs_fix` is consistent with 2 high-severity findings
- Severity `high` matches the highest finding severity
- All 3 findings have corresponding fix suggestions
- Task Title matches the dispatch
`````
