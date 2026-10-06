---
name: handoff-executor-refinement-reviewer
description: Bilateral contract for behavioral contract verification between Executor (sender) and Executor - Refinement Reviewer (receiver). Defines dispatch payload, response payload, validation, and error handling.
user-invocable: false
---

# Skill: Handoff — Executor ↔ Executor - Refinement Reviewer

## Purpose

This skill defines the bilateral contract between Executor and Executor - Refinement Reviewer during the Review phase. The Executor dispatches implementation files and behavioral contract identifiers; the Refinement Reviewer cross-references every BC-ID against test evidence and returns a calibrated confidence rating. This handoff happens once per task during Phase 6 (Review) of Plan Execution or Phase 6 (Review) of Direct Execution, only when refinement review is enabled.

## Participants

| Role | Agent | Responsibility |
|---|---|---|
| Sender | Executor | Collects files changed, BC-IDs, plan context, and constraint pack, writes dispatch handoff file |
| Receiver | Executor - Refinement Reviewer | Reads plan, test code, and implementation, builds BC evidence map, calibrates confidence, returns findings |

## Dispatch

The sender writes a handoff file following `workspace-handoff-protocol`. The payload shape depends on the pipeline context.

### Variant: Plan Execution

Used when the Executor is executing a plan file. The dispatch includes BC-IDs and plan context from the plan's Behavioral Contracts section.

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Task Title | yes | `string` | Title of the subtask being reviewed. From the todowrite tracker. |
| Plan Path | yes | `path` | Absolute path to the plan file being executed. The receiver reads BC definitions from this file. |
| Files Changed | yes | `list<path>` | Absolute paths to every file modified or created — implementation and test files. From the implementation evidence. |
| Constraint Pack | no | `object` | Structured object with subsections. From grounding output. Used to understand layering constraints referenced by BCs. |
| BC IDs | yes | `list{string}` | Behavioral Contract IDs (e.g., BC-1, BC-2) that this subtask must satisfy. From the plan's Behavioral Contracts section. |
| Plan Context | yes | `string` | Relevant sections from the plan: Behavioral Contracts with pre/post-conditions, acceptance criteria BDD tables. Copied from the plan. |
| Business Rules | no | `string` | BR-IDs and their constraints — for verifying that business rules mentioned in BCs are enforced in code. From the plan's Business Rules section. |
| Acceptance Criteria | no | `string` | BDD tables (Given/When/Then) — for verifying that acceptance criteria are met by test evidence. From the plan's Use Cases section. |
| Implementation Summary | no | `string` | Brief description of what was implemented — for orientation, not as evidence. From the implementation notes. |

**Constraint Pack Subsections** (when provided):

| Subsection | Required | Type | Description |
|---|---|---|---|
| Mandatory Rules | yes | `table{Category, Rule}` | Architectural rules tagged by category. From grounding output. |
| Prohibitions | yes | `list{string}` | Hard boundaries that must not be crossed. From grounding output. |

**Concrete Example — Plan Execution:**

`````markdown
## Payload

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Plan Path

`.workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md`

### Files Changed

- `~/projects/shelf/modules/loan-extension/src/main/java/application/services/ExtendLoanService.java`
- `~/projects/shelf/modules/loan-extension/src/test/java/LoanExtensionServiceTest.java`
- `~/projects/shelf/modules/loan-extension/src/test/java/LoanExtensionRepositoryTest.java`

### Constraint Pack

#### Mandatory Rules

| Category | Rule |
|---|---|
| layering | Service layer does not access repository directly — use port interface |
| errors | All business rule violations return 422 with structured error body |

#### Prohibitions

- Do not modify the HoldsModule — out of scope

### BC IDs

- BC-01
- BC-02

### Plan Context

**BC-01: Extend a loan within its allowance**
- Pre-condition: Loan exists with remainingExtensionDays >= requestedDays
- Action: Deduct requestedDays from remainingExtensionDays, create LoanExtension record with status PENDING
- Post-condition: remainingExtensionDays -= requestedDays; LoanExtension record created with status PENDING

**BC-02: Reject an extension beyond the allowance**
- Pre-condition: Loan exists with remainingExtensionDays < requestedDays
- Action: Return error response without modifying the allowance or creating a record
- Post-condition: HTTP 422 returned; remainingExtensionDays unchanged; no LoanExtension record created

### Business Rules

- **BR-01**: Requested extension days must be greater than zero
- **BR-02**: Requested extension days must not exceed the remaining allowance
- **BR-03**: Extension must be idempotent — duplicate requests do not create duplicate records

### Acceptance Criteria

1. **AC-01**: Given remainingExtensionDays is 30, When an extension of 10 days is requested, Then remainingExtensionDays becomes 20 and LoanExtension record has status PENDING
2. **AC-02**: Given remainingExtensionDays is 5, When an extension of 14 days is requested, Then HTTP 422 is returned and remainingExtensionDays remains 5

### Implementation Summary

Implemented ExtendLoanService with two main code paths: extendLoan (BC-01) and rejectOversizeExtension (BC-02). Used LoanExtensionRepositoryPort for persistence. Added optimistic locking via @Version.
`````

### Variant: Direct Execution

Used when the Executor is implementing ad-hoc instructions without a plan file. No behavioral contracts, no BC-IDs — the review verifies implementation against the requirements summary instead.

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Task Title | yes | `string` | Always "Direct Execution". |
| Plan Path | yes | `path` | Always the literal string `DIRECT`. |
| Files Changed | yes | `list<path>` | Absolute paths to every file modified or created. From the implementation evidence. |
| Constraint Pack | no | `object` | Structured object with subsections. From grounding output. |
| Requirements Summary | yes | `string` | Derived from the user's request — replaces BC-IDs and Plan Context. Describes what the implementation must achieve and what tests should prove. |
| Implementation Summary | no | `string` | Brief description of what was implemented — for orientation, not as evidence. |

**Concrete Example — Direct Execution:**

`````markdown
## Payload

### Task Title

Direct Execution

### Plan Path

`DIRECT`

### Files Changed

- `~/projects/shelf/modules/batch-processing/src/main/java/BatchProcessingService.java`
- `~/projects/shelf/modules/batch-processing/src/test/java/BatchProcessingServiceTest.java`

### Requirements Summary

Implement a batch processing endpoint that accepts a list of loan IDs and extends each one. Each item must be processed independently — one failure must not block the others. The endpoint must return a summary with processed count, failed count, and error details per failure. Tests must verify: successful batch, partial failure (some succeed, some fail), empty batch rejection, and duplicate ID handling.

### Implementation Summary

Implemented BatchProcessingService with independent processing per item using a result accumulator. Returns BatchResult with processed/failed counts and per-item error details.
`````

## Response

The receiver writes a response handoff file following `workspace-handoff-protocol`. The response shape depends on the dispatch variant.

### Variant: Plan Execution

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Status | yes | `enum(done)` | Always `done` — the review completed. |
| Task Title | yes | `string` | Echoes the dispatch Task Title for traceability. |
| Verdict | yes | `enum(approved, needs_fix)` | `approved` when Confidence is high and no critical findings. `needs_fix` otherwise. |
| Severity | yes | `enum(critical, high, medium, low, none)` | The highest severity among all findings. `none` when approved with no findings. |
| Confidence | yes | `enum(high, medium, low)` | Calibrated from the BC Evidence Map. `high` only when every BC-ID has direct test evidence with verified assertions. |
| BC Evidence Map | yes | `table{BC-ID, Pre-condition, Post-condition, Test Evidenced, Test Name, Assertion Verified, Status}` | One row per BC-ID. Status values: VERIFIED, MISSING, PARTIAL, MISMATCH. |
| Findings | yes | `table{#, Criterion, Severity, BC-ID, File, Description}` | Every finding with its BC-ID reference. Empty when approved with no findings. |
| Fix Suggestions | yes | `table{#, Finding, Suggestion}` | One concrete fix per finding, referencing the BC-ID. Empty when approved with no findings. |
| Low Confidence Areas | no | `table{#, Severity, BC Reference, Description, File Paths}` | Only populated when Confidence is medium or low. Explains why confidence was reduced. |
| Follow Up Review Suggestions | no | `list{string}` | Only populated when Confidence is medium or low. Recommendations for human review. |
| Notes | no | `string` | Observations or caveats. |

**Concrete Example — Plan Execution:**

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

### Confidence

`medium`

### BC Evidence Map

| BC-ID | Pre-condition | Post-condition | Test Evidenced | Test Name | Assertion Verified | Status |
|---|---|---|---|---|---|---|
| BC-01 | Loan exists with remainingExtensionDays >= requestedDays | remainingExtensionDays -= requestedDays; LoanExtension record created with status PENDING | yes | `testExtendLoan_Success` | no | PARTIAL |
| BC-02 | Loan exists with remainingExtensionDays < requestedDays | HTTP 422 returned; remainingExtensionDays unchanged; no LoanExtension record created | yes | `testRejectOversizeExtension` | yes | VERIFIED |

### Findings

| # | Criterion | Severity | BC-ID | File | Description |
|---|---|---|---|---|---|
| 1 | Assertion implemented vs BC post-condition | high | BC-01 | `LoanExtensionServiceTest.java:28` | Test asserts `getStatus() != null` instead of verifying `getStatus() == PENDING` — does not prove the post-condition |
| 2 | Negative flows by BC | high | BC-01 | `LoanExtensionServiceTest.java` | No test verifies the post-condition `remainingExtensionDays -= requestedDays` — the allowance is not asserted after processing |

### Fix Suggestions

| # | Finding | Suggestion |
|---|---|---|
| 1 | Weak assertion for BC-01 | Add assertion `assertEquals(LoanExtensionStatus.PENDING, result.getStatus())` to verify the exact post-condition state |
| 2 | Missing allowance assertion for BC-01 | Add assertion verifying `assertEquals(20, loan.getRemainingExtensionDays())` after processing to prove the days were deducted |

### Low Confidence Areas

| # | Severity | BC Reference | Description | File Paths |
|---|---|---|---|---|
| 1 | high | BC-01 | Post-condition assertion is incomplete — status is checked for non-null but not for PENDING | `LoanExtensionServiceTest.java` |
| 2 | high | BC-01 | Allowance deduction is not verified — the post-condition states remainingExtensionDays decreases but no assertion checks the new value | `LoanExtensionServiceTest.java` |

### Follow Up Review Suggestions

- BC-01 has partial test evidence — assertion verifies the record exists but not its status or the allowance change. Recommend manual verification of the service logic before merge.

### Notes

BC-02 is fully verified — test name references the BC, assertion checks both HTTP status and allowance immutability. BC-01 has the test but the assertion is too weak to fully prove the post-condition. Confidence is medium because one of two BCs has incomplete evidence.
`````

### Variant: Direct Execution

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Status | yes | `enum(done)` | Always `done`. |
| Task Title | yes | `string` | Echoes the dispatch Task Title. |
| Verdict | yes | `enum(approved, needs_fix)` | `approved` when Confidence is high. `needs_fix` otherwise. |
| Severity | yes | `enum(critical, high, medium, low, none)` | Highest severity among findings. |
| Confidence | yes | `enum(high, medium, low)` | Calibrated against the Requirements Summary instead of BC-IDs. |
| Requirements Coverage | yes | `table{#, Requirement, Test Evidenced, Test Name, Verified, Status}` | One row per requirement from the Requirements Summary. |
| Findings | yes | `table{#, Criterion, Severity, Requirement, File, Description}` | Every finding referenced to a requirement. |
| Fix Suggestions | yes | `table{#, Finding, Suggestion}` | One concrete fix per finding. |
| Low Confidence Areas | no | `table{#, Severity, Requirement, Description, File Paths}` | Only when Confidence is medium or low. |
| Follow Up Review Suggestions | no | `list{string}` | Only when Confidence is medium or low. |
| Notes | no | `string` | Observations or caveats. |

**Concrete Example — Direct Execution:**

`````markdown
## Payload

### Status

`done`

### Task Title

Direct Execution

### Verdict

`approved`

### Severity

`none`

### Confidence

`high`

### Requirements Coverage

| # | Requirement | Test Evidenced | Test Name | Verified | Status |
|---|---|---|---|---|---|
| 1 | Successful batch processes all items | yes | `testBatchProcessing_Success` | yes | VERIFIED |
| 2 | Partial failure — some succeed, some fail | yes | `testBatchProcessing_PartialFailure` | yes | VERIFIED |
| 3 | Empty batch rejection | yes | `testBatchProcessing_EmptyBatch` | yes | VERIFIED |
| 4 | Duplicate ID handling | yes | `testBatchProcessing_DuplicateIds` | yes | VERIFIED |

### Findings

No findings.

### Fix Suggestions

No suggestions.

### Notes

All four requirements from the Requirements Summary have direct test evidence with verified assertions. Confidence is high.
`````

## Validation

Both parties must verify:

**Dispatch-side (sender checks before writing):**

- Task Title must be a non-empty string
- Files Changed must contain at least one path
- Every path in Files Changed must exist on disk at dispatch time
- **Plan Execution variant:** BC IDs must contain at least one entry; Plan Context must be non-empty
- **Direct Execution variant:** Requirements Summary must be non-empty; Plan Path must be `DIRECT`

**Response-side (sender checks after receiving):**

- **Plan Execution variant:** BC Evidence Map must have one row per BC-ID from the dispatch
- **Plan Execution variant:** Confidence `high` requires every BC Evidence Map row to have Test Evidenced = `yes` AND Assertion Verified = `yes`
- **Plan Execution variant:** Confidence medium or low requires Low Confidence Areas to be populated
- **Direct Execution variant:** Requirements Coverage must have one row per requirement from the dispatch
- Verdict `approved` requires Confidence = `high`
- Verdict `needs_fix` requires at least one high or critical finding
- Every finding must reference a BC-ID or requirement number
- Task Title must match the dispatch Task Title for traceability

## Error Handling

- **Dispatch validation failure:** Sender stops and surfaces the validation error to the user. Do not write the handoff file.
- **Intake validation failure:** Receiver writes a response handoff with Status `done`, Verdict `approved`, Confidence `high`, and Notes listing which validation rules failed. Cannot verify BCs without BC-IDs or requirements without a summary.
- **Execution failure (plan file unreadable):** Receiver writes a response with Confidence `low` and Notes explaining the plan file could not be read. BC Evidence Map will show all BCs as MISSING.
- **Response validation failure:** Sender applies the same severity logic as the Assess & Fix phase. Critical findings stop execution. High findings trigger a fix iteration. Medium/low are accepted as observations.

## Examples

### End-to-end: Plan Execution Refinement Review

**Dispatch handoff file** (`execution/handoffs/13-refinement-review-dispatch.md`):

`````markdown
---
from: executor
to: executor-refinement-reviewer
timestamp: 2026-05-27T15:36:00Z
type: dispatch
status: pending
---

# Handoff: Executor → Refinement Reviewer

## Purpose

Verify that BC-01 and BC-02 are fully implemented and proven by test evidence.

## Context

GREEN phase complete. Quality and security reviews returned findings that were fixed. This is the final review — cross-reference behavioral contracts against actual test assertions.

## Payload

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Plan Path

`.workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md`

### Files Changed

- `~/projects/shelf/modules/loan-extension/src/main/java/application/services/ExtendLoanService.java`
- `~/projects/shelf/modules/loan-extension/src/test/java/LoanExtensionServiceTest.java`
- `~/projects/shelf/modules/loan-extension/src/test/java/LoanExtensionRepositoryTest.java`

### Constraint Pack

#### Mandatory Rules

| Category | Rule |
|---|---|
| layering | Service layer does not access repository directly — use port interface |
| errors | All business rule violations return 422 with structured error body |

#### Prohibitions

- Do not modify the HoldsModule — out of scope

### BC IDs

- BC-01
- BC-02

### Plan Context

**BC-01: Extend a loan within its allowance**
- Pre-condition: Loan exists with remainingExtensionDays >= requestedDays
- Action: Deduct requestedDays from remainingExtensionDays, create LoanExtension record with status PENDING
- Post-condition: remainingExtensionDays -= requestedDays; LoanExtension record created with status PENDING

**BC-02: Reject an extension beyond the allowance**
- Pre-condition: Loan exists with remainingExtensionDays < requestedDays
- Action: Return error response without modifying the allowance or creating a record
- Post-condition: HTTP 422 returned; remainingExtensionDays unchanged; no LoanExtension record created

### Business Rules

- **BR-01**: Requested extension days must be greater than zero
- **BR-02**: Requested extension days must not exceed the remaining allowance

### Acceptance Criteria

1. **AC-01**: Given remainingExtensionDays is 30, When an extension of 10 days is requested, Then remainingExtensionDays becomes 20 and LoanExtension record has status PENDING
2. **AC-02**: Given remainingExtensionDays is 5, When an extension of 14 days is requested, Then HTTP 422 is returned and remainingExtensionDays remains 5

### Implementation Summary

Implemented ExtendLoanService with two main code paths: extendLoan (BC-01) and rejectOversizeExtension (BC-02). Used LoanExtensionRepositoryPort for persistence. Added optimistic locking via @Version.

## Validation

- Task Title is non-empty
- Plan Path points to existing file
- 3 Files Changed — all exist on disk
- BC IDs has 2 entries: BC-01, BC-02
- Plan Context includes pre/post-conditions for both BCs
`````

**Response handoff file** (`execution/handoffs/14-refinement-review-response.md`):

`````markdown
---
from: executor-refinement-reviewer
to: executor
timestamp: 2026-05-27T15:42:00Z
type: response
status: done
---

# Handoff: Refinement Reviewer → Executor

## Purpose

Return behavioral contract verification for BC-01 and BC-02.

## Context

Cross-referenced 2 BC-IDs against test files and implementation. BC-02 is fully verified. BC-01 has partial evidence — the test exists but the assertion is too weak to prove the full post-condition (status not checked, allowance change not verified). Confidence is medium.

## Payload

### Status

`done`

### Task Title

Implement ExtendLoanService — BC-01 and BC-02

### Verdict

`needs_fix`

### Severity

`high`

### Confidence

`medium`

### BC Evidence Map

| BC-ID | Pre-condition | Post-condition | Test Evidenced | Test Name | Assertion Verified | Status |
|---|---|---|---|---|---|---|
| BC-01 | remainingExtensionDays >= requestedDays | remainingExtensionDays -= requestedDays; LoanExtension record with status PENDING | yes | `testExtendLoan_Success` | no | PARTIAL |
| BC-02 | remainingExtensionDays < requestedDays | HTTP 422; remainingExtensionDays unchanged; no LoanExtension record | yes | `testRejectOversizeExtension` | yes | VERIFIED |

### Findings

| # | Criterion | Severity | BC-ID | File | Description |
|---|---|---|---|---|---|
| 1 | Assertion implemented vs BC post-condition | high | BC-01 | `LoanExtensionServiceTest.java:28` | Test asserts `getStatus() != null` instead of `assertEquals(PENDING, getStatus())` — does not prove the post-condition |
| 2 | Negative flows by BC | high | BC-01 | `LoanExtensionServiceTest.java` | No assertion verifies `remainingExtensionDays -= requestedDays` — the allowance change is untested |

### Fix Suggestions

| # | Finding | Suggestion |
|---|---|---|
| 1 | Weak assertion for BC-01 | Add `assertEquals(LoanExtensionStatus.PENDING, result.getStatus())` to verify the exact post-condition |
| 2 | Missing allowance assertion for BC-01 | Add `assertEquals(20, loan.getRemainingExtensionDays())` after processing to prove the deduction |

### Low Confidence Areas

| # | Severity | BC Reference | Description | File Paths |
|---|---|---|---|---|
| 1 | high | BC-01 | Post-condition assertion incomplete — status checked for non-null, not for PENDING | `LoanExtensionServiceTest.java` |
| 2 | high | BC-01 | Allowance deduction unverified — post-condition states decrease but no assertion checks new value | `LoanExtensionServiceTest.java` |

### Follow Up Review Suggestions

- BC-01 has partial test evidence — assertion verifies the record exists but not its status or the allowance change. Recommend manual verification of the service logic before merge.

### Notes

BC-02 is fully verified — test name references the BC, assertion checks both HTTP status and allowance immutability. BC-01 has the test but the assertion is too weak to fully prove the post-condition. Confidence is medium because one of two BCs has incomplete evidence.

## Validation

- BC Evidence Map has 2 rows matching dispatch BC IDs (BC-01, BC-02)
- Confidence `medium` is justified — BC-01 has Assertion Verified = no
- Low Confidence Areas populated with 2 entries
- Follow Up Review Suggestions populated
- All findings reference BC-IDs
- Task Title matches the dispatch
`````
