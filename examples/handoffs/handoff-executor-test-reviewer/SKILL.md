---
name: handoff-executor-test-reviewer
description: Bilateral contract for test coverage review between Executor (sender) and Executor - Test Reviewer (receiver). Defines dispatch payload, response payload, validation, and error handling.
user-invocable: false
---

# Skill: Handoff — Executor ↔ Executor - Test Reviewer

## Purpose

This skill defines the bilateral contract between Executor and Executor - Test Reviewer during the Review phase. The Executor dispatches implementation files, test evidence, and the constraint pack; the Test Reviewer statically analyzes test code against production code and returns structured findings. This handoff happens once per task during Phase 6 (Review) of Plan Execution or Phase 6 (Review) of Direct Execution, only when test review is enabled.

## Participants

| Role | Agent | Responsibility |
|---|---|---|
| Sender | Executor | Collects files changed, test strategy, TDD evidence, and constraint pack, writes dispatch handoff file |
| Receiver | Executor - Test Reviewer | Reads production and test code, evaluates against 10-criteria checklist, returns findings with suggested tests |

## Dispatch

The sender writes a handoff file following `workspace-handoff-protocol`. The payload is structured as Markdown sections.

### Variant: Review Phase

Used when the Executor completes implementation for a task and test review is enabled in the configuration. Same structure for both Plan Execution and Direct Execution — plan-specific fields like Test Strategy and TDD Evidence are optional.

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Task Title | yes | `string` | Title of the subtask being reviewed. From the todowrite tracker or "Direct Execution". |
| Plan Path | yes | `path` | Absolute path to the plan file being executed, or the literal string `DIRECT`. |
| Files Changed | yes | `list<path>` | Absolute paths to every file modified or created — both production and test files. From the implementation evidence. |
| Constraint Pack | yes | `object` | Structured object with subsections. From grounding output. |
| Test Strategy | no | `string` | From the plan's Test Strategy section — defines how correctness is verified. |
| Acceptance Criteria | no | `string` | BDD tables (Given/When/Then) from the plan — defines expected behaviors that tests should prove. |
| TDD Evidence | no | `string` | Output from the RED sub-agent — proves RED was confirmed before GREEN. From the RED response handoff. |

**Constraint Pack Subsections:**

| Subsection | Required | Type | Description |
|---|---|---|---|
| Mandatory Rules | yes | `table{Category, Rule}` | Architectural rules tagged by category. Includes testing standards. From grounding output. |
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
- `~/projects/shelf/modules/loan-extension/src/test/java/LoanExtensionServiceTest.java`
- `~/projects/shelf/modules/loan-extension/src/test/java/LoanExtensionRepositoryTest.java`

### Constraint Pack

#### Mandatory Rules

| Category | Rule |
|---|---|
| testing | Test files follow the pattern `*ServiceTest.java` |
| testing | Integration tests use `@IntegrationTest` and test the full request lifecycle |
| layering | Service layer does not access repository directly — use port interface |

#### Prohibitions

- Do not modify the HoldsModule — out of scope

### Test Strategy

Unit tests for service layer logic (allowance validation, error handling). Integration tests for the full request lifecycle via `@IntegrationTest`. Test command: `mvn test -pl modules/loan-extension -Dtest="*LoanExtension*"`. Numeric edge cases must be covered: zero, negative, limit, overflow.

### Acceptance Criteria

1. **AC-01**: Given remainingExtensionDays is 30, When an extension of 10 days is requested, Then remainingExtensionDays becomes 20 and LoanExtension record has status PENDING
2. **AC-02**: Given remainingExtensionDays is 5, When an extension of 14 days is requested, Then HTTP 422 is returned and remainingExtensionDays remains 5

### TDD Evidence

RED phase confirmed. Two test files created with 4 tests. All fail because skeleton methods return null. Test command: `mvn test -pl modules/loan-extension -Dtest="*LoanExtension*"`. Tests run: 4, Failures: 4, Errors: 0.
`````

## Response

The receiver writes a response handoff file following `workspace-handoff-protocol`. The response payload is structured as Markdown sections.

### Variant: Review Phase

**Payload Sections:**

| Section | Required | Type | Description |
|---|---|---|---|
| Status | yes | `enum(done)` | Always `done` — the review completed. Findings determine whether code needs fixing. |
| Task Title | yes | `string` | Echoes the dispatch Task Title for traceability. |
| Verdict | yes | `enum(approved, needs_fix)` | `approved` when no high or critical findings. `needs_fix` when one or more high or critical findings exist. |
| Severity | yes | `enum(critical, high, medium, low, none)` | The highest severity among all findings. `none` when approved with no findings. |
| Findings | yes | `table{#, Criterion, Severity, File, Description}` | Every finding with its criterion from the 10-criteria checklist. Empty table when approved with no findings. |
| Fix Suggestions | yes | `table{#, Finding, Suggestion}` | One concrete, actionable fix per finding. Empty table when approved with no findings. |
| Suggested Tests | no | `table{#, Name, Scenario, Input, Expected, Target}` | Complete test specifications for missing tests. Only populated when criterion 9 (Missing tests) produces findings. Max 5 entries. |
| Notes | no | `string` | Observations, TDD discipline assessment, or caveats. |

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
| 1 | Numeric edge cases | high | `LoanExtensionServiceTest.java` | No test for a zero-day extension — passing 0 as the requested days should return 422 but no test verifies this |
| 2 | Numeric edge cases | high | `LoanExtensionServiceTest.java` | No test for a negative extension — passing -5 should return 422 but no test verifies this |
| 3 | Error scenario coverage | high | `LoanExtensionServiceTest.java` | No test for optimistic locking failure — concurrent modification should return 409 but no test verifies this |
| 4 | Assertion quality | medium | `LoanExtensionServiceTest.java:34` | Test asserts `getStatus() != null` instead of `assertEquals(PENDING, getStatus())` — the assertion is too weak to prove the correct status |
| 5 | TDD discipline | medium | `LoanExtensionServiceTest.java` | RED evidence shows 4 tests were created but current file has 5 tests — one test was added during GREEN without going through RED |

### Fix Suggestions

| # | Finding | Suggestion |
|---|---|---|
| 1 | Missing zero-day test | Add test `testRejectZeroDayExtension` — see Suggested Tests below |
| 2 | Missing negative-day test | Add test `testRejectNegativeDayExtension` — see Suggested Tests below |
| 3 | Missing locking failure test | Add test `testRejectConcurrentModification` — see Suggested Tests below |
| 4 | Weak assertion | Replace `assertNotNull(result.getStatus())` with `assertEquals(LoanExtensionStatus.PENDING, result.getStatus())` |
| 5 | Test added outside RED | The fifth test should be documented as a justified addition during GREEN, or routed through a new RED cycle |

### Suggested Tests

| # | Name | Scenario | Input | Expected | Target |
|---|---|---|---|---|---|
| 1 | `testRejectZeroDayExtension` | Given remainingExtensionDays is 30, When an extension of 0 days is requested, Then HTTP 422 is returned with validation error | `requestedDays = 0, remainingExtensionDays = 30` | HTTP 422, remainingExtensionDays unchanged | `LoanExtensionServiceTest.java` |
| 2 | `testRejectNegativeDayExtension` | Given remainingExtensionDays is 30, When an extension of -5 days is requested, Then HTTP 422 is returned with validation error | `requestedDays = -5, remainingExtensionDays = 30` | HTTP 422, remainingExtensionDays unchanged | `LoanExtensionServiceTest.java` |
| 3 | `testRejectConcurrentModification` | Given two concurrent requests modify the same loan, Then the second request receives 409 Conflict | Two parallel requests with same loanId | First: 200, Second: 409 | `LoanExtensionServiceTest.java` |

### Notes

TDD discipline is mostly intact — RED evidence matches 4 of 5 current tests. The fifth test (oversize rejection at the exact allowance) appears to have been added during GREEN without RED confirmation. Numeric edge case coverage is incomplete for an allowance feature — zero and negative day counts must be tested.
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

- Verdict `approved` must have no high or critical findings in the Findings table
- Verdict `needs_fix` must have at least one high or critical finding
- Severity must match the highest severity in the Findings table
- Every finding must have a corresponding Fix Suggestion
- Suggested Tests must be populated when any finding references criterion 9 (Missing tests)
- Task Title must match the dispatch Task Title for traceability

## Error Handling

- **Dispatch validation failure:** Sender stops and surfaces the validation error to the user. Do not write the handoff file.
- **Intake validation failure:** Receiver writes a response handoff with Status `done`, Verdict `approved`, Severity `none`, and Notes listing which validation rules failed — cannot review files that do not exist.
- **Execution failure (file unreadable):** Receiver skips the unreadable file and reviews the remaining files. Notes which file was skipped and why. Continues with available files.
- **Response validation failure:** Sender applies the same severity logic as the Assess & Fix phase. High findings trigger a fix iteration. Medium/low are accepted as observations.

## Examples

### End-to-end: Plan Execution Test Review

**Dispatch handoff file** (`execution/handoffs/11-test-review-dispatch.md`):

`````markdown
---
from: executor
to: executor-test-reviewer
timestamp: 2026-05-27T15:34:00Z
type: dispatch
status: pending
---

# Handoff: Executor → Test Reviewer

## Purpose

Review test coverage and quality for the ExtendLoanService implementation.

## Context

GREEN phase complete. Three files changed: service implementation, service test, repository test. TDD was enabled — RED phase confirmed 4 failing tests before implementation. Allowance feature requiring numeric edge case coverage.

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
| testing | Test files follow the pattern `*ServiceTest.java` |
| testing | Integration tests use `@IntegrationTest` and test the full request lifecycle |
| layering | Service layer does not access repository directly — use port interface |

#### Prohibitions

- Do not modify the HoldsModule — out of scope

### Test Strategy

Unit tests for service layer logic (allowance validation, error handling). Integration tests for the full request lifecycle via `@IntegrationTest`. Test command: `mvn test -pl modules/loan-extension -Dtest="*LoanExtension*"`. Numeric edge cases must be covered: zero, negative, limit, overflow.

### Acceptance Criteria

1. **AC-01**: Given remainingExtensionDays is 30, When an extension of 10 days is requested, Then remainingExtensionDays becomes 20 and LoanExtension record has status PENDING
2. **AC-02**: Given remainingExtensionDays is 5, When an extension of 14 days is requested, Then HTTP 422 is returned and remainingExtensionDays remains 5

### TDD Evidence

RED phase confirmed. Two test files created with 4 tests. All fail because skeleton methods return null. Test command: `mvn test -pl modules/loan-extension -Dtest="*LoanExtension*"`. Tests run: 4, Failures: 4, Errors: 0.

## Validation

- Task Title is non-empty
- Plan Path points to existing file
- 3 Files Changed — all exist on disk
- Constraint Pack has 3 Mandatory Rules
`````

**Response handoff file** (`execution/handoffs/12-test-review-response.md`):

`````markdown
---
from: executor-test-reviewer
to: executor
timestamp: 2026-05-27T15:40:00Z
type: response
status: done
---

# Handoff: Test Reviewer → Executor

## Purpose

Return test coverage and quality findings for the ExtendLoanService implementation.

## Context

Reviewed 3 files (1 production, 2 test). Found 3 high-severity missing edge case tests and 2 medium issues (weak assertion, test added outside RED cycle). An allowance feature demands complete edge case coverage — zero, negative, and concurrent modification scenarios are missing.

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
| 1 | Numeric edge cases | high | `LoanExtensionServiceTest.java` | No test for a zero-day extension — passing 0 as the requested days should return 422 but no test verifies this |
| 2 | Numeric edge cases | high | `LoanExtensionServiceTest.java` | No test for a negative extension — passing -5 should return 422 but no test verifies this |
| 3 | Error scenario coverage | high | `LoanExtensionServiceTest.java` | No test for optimistic locking failure — concurrent modification should return 409 but no test verifies this |
| 4 | Assertion quality | medium | `LoanExtensionServiceTest.java:34` | Test asserts `getStatus() != null` instead of `assertEquals(PENDING, getStatus())` — the assertion is too weak to prove the correct status |
| 5 | TDD discipline | medium | `LoanExtensionServiceTest.java` | RED evidence shows 4 tests were created but current file has 5 tests — one test was added during GREEN without going through RED |

### Fix Suggestions

| # | Finding | Suggestion |
|---|---|---|
| 1 | Missing zero-day test | Add test `testRejectZeroDayExtension` — see Suggested Tests |
| 2 | Missing negative-day test | Add test `testRejectNegativeDayExtension` — see Suggested Tests |
| 3 | Missing locking failure test | Add test `testRejectConcurrentModification` — see Suggested Tests |
| 4 | Weak assertion | Replace `assertNotNull(result.getStatus())` with `assertEquals(LoanExtensionStatus.PENDING, result.getStatus())` |
| 5 | Test added outside RED | The fifth test should be documented as a justified addition during GREEN, or routed through a new RED cycle |

### Suggested Tests

| # | Name | Scenario | Input | Expected | Target |
|---|---|---|---|---|---|
| 1 | `testRejectZeroDayExtension` | Given remainingExtensionDays is 30, When an extension of 0 days is requested, Then HTTP 422 is returned with validation error | `requestedDays = 0, remainingExtensionDays = 30` | HTTP 422, remainingExtensionDays unchanged | `LoanExtensionServiceTest.java` |
| 2 | `testRejectNegativeDayExtension` | Given remainingExtensionDays is 30, When an extension of -5 days is requested, Then HTTP 422 is returned with validation error | `requestedDays = -5, remainingExtensionDays = 30` | HTTP 422, remainingExtensionDays unchanged | `LoanExtensionServiceTest.java` |
| 3 | `testRejectConcurrentModification` | Given two concurrent requests modify the same loan, Then the second request receives 409 Conflict | Two parallel requests with same loanId | First: 200, Second: 409 | `LoanExtensionServiceTest.java` |

### Notes

TDD discipline is mostly intact — RED evidence matches 4 of 5 current tests. The fifth test (oversize rejection at the exact allowance) appears to have been added during GREEN without RED confirmation. Numeric edge case coverage is incomplete for an allowance feature — zero and negative day counts must be tested.

## Validation

- Verdict `needs_fix` is consistent with 3 high-severity findings
- Severity `high` matches the highest finding severity
- All 5 findings have corresponding fix suggestions
- Suggested Tests populated with 3 entries for missing tests
- Task Title matches the dispatch
`````
