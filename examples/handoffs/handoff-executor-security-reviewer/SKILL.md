---
name: handoff-executor-security-reviewer
description: Bilateral contract for security review between Executor (sender) and Executor - Security Reviewer (receiver). Defines dispatch payload, response payload, validation, and error handling.
user-invocable: false
---

# Skill: Handoff — Executor ↔ Executor - Security Reviewer

## Purpose

This skill defines the bilateral contract between Executor and Executor - Security Reviewer during the Review phase. The Executor dispatches implementation files and security context; the Security Reviewer evaluates against a 10-vector attack checklist and returns structured findings with exploitation scenarios and remediations. This handoff happens once per task during Phase 6 (Review) of Plan Execution or Phase 6 (Review) of Direct Execution, only when security review is enabled.

## Participants

| Role | Agent | Responsibility |
|---|---|---|
| Sender | Executor | Collects files changed, constraint pack, and security context, writes dispatch handoff file |
| Receiver | Executor - Security Reviewer | Reads each file, evaluates against 10-vector attack checklist, verifies exploitability, returns findings |

## Dispatch

The sender writes a handoff file following `workspace-handoff-protocol`. The payload is structured as Markdown sections.

### Variant: Review Phase

Used when the Executor completes implementation for a task and security review is enabled in the configuration. Same structure for both Plan Execution and Direct Execution — plan-specific fields are optional.

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Task Title | yes | `string` | Title of the subtask being reviewed. From the todowrite tracker or "Direct Execution". |
| Plan Path | yes | `path` | Absolute path to the plan file being executed, or the literal string `DIRECT`. |
| Files Changed | yes | `list<path>` | Absolute paths to every file modified or created in this subtask. From the implementation evidence. |
| Constraint Pack | yes | `object` | Structured object with subsections. From grounding output. |
| Security Context | no | `string` | Additional security context: authentication mechanism, authorization model, data sensitivity classification, known threat model. From the plan or project discovery. |
| Plan Context | no | `string` | Brief context about the plan or requirements — identifies data types being handled (money, PII, credentials) to calibrate sensitivity. |

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

- `~/projects/shelf/modules/loan-extension/src/main/java/application/services/ExtendLoanService.java`
- `~/projects/shelf/modules/loan-extension/src/main/java/infrastructure/controllers/LoanExtensionController.java`
- `~/projects/shelf/modules/loan-extension/src/main/java/application/ports/LoanExtensionRepositoryPort.java`

### Constraint Pack

#### Mandatory Rules

| Category | Rule |
|---|---|
| layering | Service layer does not access repository directly — use port interface |
| errors | All business rule violations return 422 with structured error body |
| security | Loan extensions must be idempotent — duplicate requests must not create duplicate extensions |

#### Prohibitions

- Do not modify the HoldsModule — out of scope
- Do not log member identifiers or contact details

### Security Context

Authentication via JWT bearer tokens. Authorization by tenant isolation — each request includes `X-Tenant-ID` header. Sensitive data: member loan history. PII: no direct PII in this feature, but loan references link to member records (name, email). Optimistic locking via `@Version` for concurrent modifications.

### Plan Context

Loan extension feature for the loans module. Two behavioral contracts: BC-01 deducts extension days and creates a record, BC-02 rejects oversize requests with 422. Shared allowance — race conditions on allowance modification are the primary security concern.
`````

## Response

The receiver writes a response handoff file following `workspace-handoff-protocol`. The response payload is structured as Markdown sections.

### Variant: Review Phase

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Status | yes | `enum(done)` | Always `done` — the review completed. Findings determine whether code needs fixing. |
| Task Title | yes | `string` | Echoes the dispatch Task Title for traceability. |
| Verdict | yes | `enum(approved, needs_fix)` | `approved` when no critical findings. `needs_fix` when one or more critical or high findings exist. |
| Severity | yes | `enum(critical, high, medium, low)` | The highest severity among all findings. `low` when approved with no findings. |
| Findings | yes | `table{#, Vector, Severity, File, Attack, Description}` | Every finding with its attack vector, exploitation scenario, and description. Empty table when approved with no findings. |
| Fix Suggestions | yes | `table{#, Finding, Suggestion}` | One concrete remediation per finding. Empty table when approved with no findings. |

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

`critical`

### Findings

| # | Vector | Severity | File | Attack | Description |
|---|---|---|---|---|---|
| 1 | Race Conditions | critical | `ExtendLoanService.java:38-52` | A member sends two concurrent extension requests for the same loan with 30 days of allowance, each requesting 21. Without atomic check-and-update, both requests pass the allowance check and the allowance goes to -12. | Allowance check and allowance update are not atomic — no locking between reading remainingExtensionDays and writing the updated value |
| 2 | Broken Authorization | high | `LoanExtensionController.java:29` | An authenticated user changes the `loanId` in the request body to extend a loan that belongs to another tenant's member. | Endpoint accepts `loanId` from request body without verifying the loan belongs to the requesting tenant |
| 3 | Error Information Leakage | medium | `LoanExtensionController.java:45` | A malformed request triggers a database constraint violation, and the full SQL error message (including table name and column) is returned in the HTTP response body. | Exception handler propagates raw database exception messages to the client |

### Fix Suggestions

| # | Finding | Suggestion |
|---|---|---|
| 1 | Non-atomic allowance operation | Wrap the allowance check and update in a database transaction with optimistic locking. Use `@Version` on the entity and handle `OptimisticLockException` to retry or return 409 Conflict. |
| 2 | Missing tenant isolation | Add tenant ownership verification before processing: load the loan, verify `loan.getTenantId()` matches the authenticated user's tenant from the JWT. Return 403 Forbidden on mismatch. |
| 3 | Database error leakage | Replace the generic exception handler with one that catches `PersistenceException` and returns a generic 500 response. Never include database error messages in HTTP responses. |
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

- Verdict `approved` must have no critical findings in the Findings table
- Verdict `needs_fix` must have at least one critical or high finding
- Severity must match the highest severity in the Findings table
- Every finding must include an Attack field with a concrete exploitation scenario
- Every finding must have a corresponding Fix Suggestion
- Task Title must match the dispatch Task Title for traceability

## Error Handling

- **Dispatch validation failure:** Sender stops and surfaces the validation error to the user. Do not write the handoff file.
- **Intake validation failure:** Receiver writes a response handoff with Status `done`, Verdict `approved`, Severity `low`, and Notes listing which validation rules failed — cannot review files that do not exist or a constraint pack without rules.
- **Execution failure (file unreadable):** Receiver skips the unreadable file and reviews the remaining files. Notes which file was skipped and why. Continues with available files.
- **Response validation failure:** Sender applies the same severity logic as the Assess & Fix phase. Critical findings stop execution immediately. High findings trigger a fix iteration. Medium/low are accepted as observations.

## Examples

### End-to-end: Plan Execution Security Review

**Dispatch handoff file** (`execution/handoffs/9-security-review-dispatch.md`):

`````markdown
---
from: executor
to: executor-security-reviewer
timestamp: 2026-05-27T15:32:00Z
type: dispatch
status: pending
---

# Handoff: Executor → Security Reviewer

## Purpose

Review the loan extension implementation for security vulnerabilities — race conditions, authorization gaps, and data exposure.

## Context

GREEN phase complete. Three files changed: service, controller, and port interface. Feature modifying a shared allowance — race conditions are the primary concern. JWT authentication with tenant isolation.

## Payload

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Plan Path

`.workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md`

### Files Changed

- `~/projects/shelf/modules/loan-extension/src/main/java/application/services/ExtendLoanService.java`
- `~/projects/shelf/modules/loan-extension/src/main/java/infrastructure/controllers/LoanExtensionController.java`
- `~/projects/shelf/modules/loan-extension/src/main/java/application/ports/LoanExtensionRepositoryPort.java`

### Constraint Pack

#### Mandatory Rules

| Category | Rule |
|---|---|
| layering | Service layer does not access repository directly — use port interface |
| errors | All business rule violations return 422 with structured error body |
| security | Loan extensions must be idempotent — duplicate requests must not create duplicate extensions |

#### Prohibitions

- Do not modify the HoldsModule — out of scope
- Do not log member identifiers or contact details

### Security Context

Authentication via JWT bearer tokens. Authorization by tenant isolation — each request includes `X-Tenant-ID` header. Sensitive data: member loan history. PII: no direct PII in this feature, but loan references link to member records (name, email). Optimistic locking via `@Version` for concurrent modifications.

### Plan Context

Loan extension feature for the loans module. Two behavioral contracts: BC-01 deducts extension days and creates a record, BC-02 rejects oversize requests with 422. Shared allowance — race conditions on allowance modification are the primary security concern.

## Validation

- Task Title is non-empty
- Plan Path points to existing file
- 3 Files Changed — all exist on disk
- Constraint Pack has 3 Mandatory Rules including 1 security rule
`````

**Response handoff file** (`execution/handoffs/10-security-review-response.md`):

`````markdown
---
from: executor-security-reviewer
to: executor
timestamp: 2026-05-27T15:38:00Z
type: response
status: done
---

# Handoff: Security Reviewer → Executor

## Purpose

Return security review findings for the loan extension implementation.

## Context

Reviewed 3 files against the 10-vector attack checklist. Critical finding: non-atomic allowance operation enabling over-extension via concurrent requests. High finding: missing tenant isolation on loan access. Medium finding: database error message leakage.

## Payload

### Status

`done`

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Verdict

`needs_fix`

### Severity

`critical`

### Findings

| # | Vector | Severity | File | Attack | Description |
|---|---|---|---|---|---|
| 1 | Race Conditions | critical | `ExtendLoanService.java:38-52` | A member sends two concurrent extension requests for the same loan with 30 days of allowance, each requesting 21. Without atomic check-and-update, both requests pass the allowance check and the allowance goes to -12. | Allowance check and allowance update are not atomic — no locking between reading remainingExtensionDays and writing the updated value |
| 2 | Broken Authorization | high | `LoanExtensionController.java:29` | An authenticated user changes the `loanId` in the request body to extend a loan that belongs to another tenant's member. | Endpoint accepts `loanId` from request body without verifying the loan belongs to the requesting tenant |
| 3 | Error Information Leakage | medium | `LoanExtensionController.java:45` | A malformed request triggers a database constraint violation, and the full SQL error message (including table name and column) is returned in the HTTP response body. | Exception handler propagates raw database exception messages to the client |

### Fix Suggestions

| # | Finding | Suggestion |
|---|---|---|
| 1 | Non-atomic allowance operation | Wrap the allowance check and update in a database transaction with optimistic locking. Use `@Version` on the entity and handle `OptimisticLockException` to retry or return 409 Conflict. |
| 2 | Missing tenant isolation | Add tenant ownership verification before processing: load the loan, verify `loan.getTenantId()` matches the authenticated user's tenant from the JWT. Return 403 Forbidden on mismatch. |
| 3 | Database error leakage | Replace the generic exception handler with one that catches `PersistenceException` and returns a generic 500 response. Never include database error messages in HTTP responses. |

## Validation

- Verdict `needs_fix` is consistent with 1 critical and 1 high finding
- Severity `critical` matches the highest finding severity
- All 3 findings have concrete Attack scenarios
- All 3 findings have corresponding fix suggestions
- Task Title matches the dispatch
`````
