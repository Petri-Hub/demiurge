---
name: workspace-handoff-protocol
description: Defines how to write and read handoff files inside the .workspace/ directory. Load this skill whenever you are about to write a handoff file or read one produced by another agent. Covers file location, naming, universal structure, writing principles, and quality standards.
user-invocable: false
---

# Skill: Workspace Handoff Protocol

## Purpose

This skill governs how handoff files are written and read inside `.workspace/`. A handoff file is the coordination artifact between two agents — it replaces unstructured in-memory messages with a persistent, typed, self-documenting Markdown file that both the sender and receiver share.

**Load `workspace-structural-protocol` first** if you haven't already, to understand the broader workspace layout.

---

## Core Principle

**Every inter-agent communication that transfers work is a file, not a message.**

When an orchestrator dispatches a sub-agent, when a leaf agent signals completion, when an architect requests a review — the coordination lives in a handoff file. The receiving agent reads the file from disk. The file persists for auditing, debugging, and resumption. No information is lost between handoffs because no information lives only in memory.

---

## File Location

Handoff files live inside the workspace alongside research, plans, and investigations:

```
.workspace/
  {project}/
    features/
      {date}-{feature-slug}/
        README.md
        research/
          ...
        plans/
          ...
        execution/
          handoffs/
            1-{descriptive-slug}.md
            2-{descriptive-slug}.md
    incidents/
      {date}-{slug}/
        README.md
        investigations/
          ...
        plans/
          ...
        execution/
          handoffs/
            1-{descriptive-slug}.md
            2-{descriptive-slug}.md
```

The `execution/handoffs/` folder is created when the first handoff file is written. It does not exist in an empty workspace.

**When to create it:**
- An orchestrator dispatches a sub-agent for execution work
- An architect sends a plan for review
- A leaf agent signals work complete
- Any agent transfers work to another agent and needs structured coordination

**When NOT to create it:**
- Simple user-facing messages (progress updates, questions, confirmations) — these stay in conversation
- File reads where no coordination is needed — the agent reads the file directly
- Responses that are purely conversational — no work is being transferred

---

## Naming Convention

```
{N}-{descriptive-slug}.md
```

- `N` — sequential integer starting at 1, no zero-padding
- `slug` — kebab-case, describes the handoff action and participants
- The number defines chronological order — reading handoffs sequentially tells the full execution story

**Naming patterns:**

| Pattern | When to use | Example |
|---|---|---|
| `{N}-{action}-dispatch.md` | Sender composes dispatch for a sub-agent | `3-red-dispatch.md` |
| `{N}-{action}-response.md` | Sub-agent returns structured output | `4-red-response.md` |
| `{N}-{action}-review.md` | Sending content for adversarial review | `5-critic-review.md` |
| `{N}-{action}-completion.md` | Leaf agent signals work complete | `1-crawl-completion.md` |
| `{N}-{action}-coordination.md` | General coordination between agents | `2-planning-coordination.md` |

**Dispatch/Response pairing:** When an orchestrator dispatches a sub-agent and expects a response, use sequential numbers — the dispatch file and response file are adjacent in the sequence:

```
3-grounding-dispatch.md       ← orchestrator writes
4-grounding-response.md       ← sub-agent writes
5-red-dispatch.md             ← orchestrator writes
6-red-response.md             ← sub-agent writes
7-review-dispatch.md          ← orchestrator writes (shared by multiple reviewers)
8-quality-review-response.md  ← reviewer writes
9-security-review-response.md ← reviewer writes
```

One dispatch file can produce multiple response files when an orchestrator sends the same handoff to several sub-agents. Each sub-agent writes its own response file with the next available number.

---

## Universal Structure

Every handoff file follows this structure. No exceptions.

```markdown
---
from: {sender-agent-name}
to: {receiver-agent-name}
timestamp: {ISO-8601}
type: {dispatch | response | completion | coordination}
status: {pending | done | failed}
---

# Handoff: {sender} → {receiver}

## Purpose
{What this handoff achieves — 1-2 sentences. The receiver reads this first to understand why this file exists.}

## Context
{Why this handoff exists now — what triggered it, what work preceded it, what the receiver needs to know about the current state. 2-3 sentences maximum. If the receiver needs more history, it reads previous handoff files in sequence.}

## Payload
{The actual data the receiver needs — freely structured, typed, validated. See Payload Composition below.}

## Validation
{What the receiver must verify before acting on this handoff. Explicit rules, each with a clear pass/fail condition.}
```

### Frontmatter Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `from` | string | yes | Name of the agent that wrote this file — lowercase, hyphenated (e.g. `executor`, `executor-red`, `crawler`) |
| `to` | string | yes | Name of the agent that should read this file — lowercase, hyphenated |
| `timestamp` | string | yes | ISO-8601 timestamp of when this file was written |
| `type` | enum | yes | `dispatch` (sender → receiver), `response` (receiver → sender), `completion` (leaf signals done), `coordination` (general handoff) |
| `status` | enum | yes | `pending` (receiver has not yet acted), `done` (receiver acted successfully), `failed` (receiver acted and failed) |

**Status immutability:** The `status` field in a handoff file is set once by the author and never updated. The sender writes a dispatch with `status: pending`. The receiver writes a SEPARATE response file with `status: done` or `status: failed`. No agent modifies another agent's handoff file — the audit trail stays intact.

### Mandatory Sections

| Section | Purpose | Why it's mandatory |
|---|---|---|
| **Purpose** | What this handoff achieves | The receiver needs to know why this file exists before reading anything else |
| **Context** | What triggered this handoff and what preceded it | Without context, the receiver acts on the payload without understanding the situation |
| **Payload** | The actual data | This is the content the receiver acts on |
| **Validation** | What the receiver must verify | Without validation, the contract is unenforceable — the receiver might act on malformed data |

### Optional Sections

Add these when the handoff needs them. Omit them when it doesn't.

| Section | When to include |
|---|---|
| **Error Handling** | When the handoff has failure modes the receiver must handle explicitly |
| **Constraints** | When the receiver must respect specific boundaries during execution |
| **References** | When the receiver needs to consult other files, skills, or documentation |
| **Examples** | When the payload format is complex enough that a concrete example clarifies intent |

---

## Payload Composition

The Payload section is the only part that varies significantly between handoffs. It is freely structured — the sender composes the right fields for the specific situation. Two composition modes exist:

### Pointing Payload

The content already exists as a file in the workspace. The handoff points to it and adds coordination metadata.

```markdown
## Payload

| Field | Type | Required | Description |
|---|---|---|---|
| TARGET_PATH | path | yes | Absolute path to the existing file |
| SCOPE | string | yes | What the receiver should focus on |
| IGNORE | list<string> | no | Sections or aspects to skip |

TARGET_PATH: .workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md
SCOPE: Behavioral Contracts and Error Scenarios — boundary cases are the highest risk.
IGNORE: Test Strategy (already validated)
```

Use a pointing payload when:
- The content exists as a file the receiver can read directly
- The handoff is primarily about coordination (what to focus on, what to skip)
- Examples: architect sends plan to critic, orchestrator sends research path to architect

### Composing Payload

The content doesn't exist yet. The handoff composes the data from scratch.

```markdown
## Payload

| Field | Type | Required | Description |
|---|---|---|---|
| MISSION | string | yes | What this dispatch must achieve — single sentence |
| BEHAVIOR_TO_PROVE | list<object> | yes | Each entry: `{BC-ID, post-condition}` |
| TEST_COMMAND | string | yes | Exact command to run tests |
| TEST_TARGET_FILES | list<path> | yes | Skeleton files to test against |
| PROJECT_PATH | path | yes | Absolute path to the project root |
| CONSTRAINT_PACK | object | yes | Mandatory rules and prohibitions |
| REFERENCE_PATH | path | no | Existing file as pattern reference |

MISSION: Write failing tests that prove the loan extension behavior does not yet exist.

BEHAVIOR_TO_PROVE:
  - BC-01: extensionsRemaining -= 1; LoanExtension record created with status PENDING
  - BC-02: HTTP 422 returned; extensionsRemaining unchanged; no LoanExtension record created

TEST_COMMAND: mvn test -pl modules/loan-extension -Dtest="*LoanExtension*"

TEST_TARGET_FILES:
  - src/main/java/modules/loan-extension/domain/entities/LoanExtension.java
  - src/main/java/modules/loan-extension/application/services/ExtendLoanService.java

PROJECT_PATH: ~/projects/shelf

CONSTRAINT_PACK:
  MANDATORY_RULES:
    - [layering] Service layer does not access repository directly — use port interface
    - [errors] All business rule violations return 422 with structured error body
  PROHIBITIONS:
    - Do not modify the HoldsModule — out of scope

REFERENCE_PATH: ~/projects/shelf/modules/holds/src/test/java/HoldServiceTest.java
```

Use a composing payload when:
- The content is being created for this specific dispatch
- The receiver needs structured data that doesn't exist as a file
- Examples: executor dispatches to a sub-agent, orchestrator sends detailed instructions to a specialist

### Decision rule

**Before composing, check if the content already exists in the workspace.** If it does, point to it. If it doesn't, compose it. Never do both for the same data — either the file IS the content, or the handoff IS the content. Duplication creates drift.

---

## Writing Principles

These principles apply to every handoff file regardless of type, mode, or participants.

### 1. The file must be self-contained for its declared scope

The receiver reads this file and has everything it needs to act within the declared scope. If the payload points to another file, the receiver can find that file from the path provided. If the payload composes data, all fields are present. No critical data lives only in the sender's memory.

### 2. Every field is typed

`string`, `path`, `enum(value1, value2)`, `list<T>`, `object`. No untyped fields. An untyped field is one the sender fills with something the receiver doesn't expect.

**Bad:**
```
FILES: some test files
COMMAND: run the tests
```

**Good:**
```
| Field | Type | Required | Description |
|---|---|---|---|
| TEST_FILES | list<path> | yes | Absolute paths to test files created or modified |
| TEST_COMMAND | string | yes | Exact command to execute the test suite |
```

### 3. Every field is marked required or optional

No defaults. If a field is sometimes present, it's optional — and the Validation section says when it's expected. "Required unless..." is optional with a validation rule, not required.

### 4. Every field has a description

Not just the field name. `MISSION` without a description is a label. `MISSION: What this dispatch must achieve — single sentence` is a contract.

### 5. Payload uses tables, not prose

A table is scannable, typed, and unambiguous. Prose is none of those things.

**Bad:**
```
The test command is mvn test and you should test the LoanExtension files.
The project is at ~/projects/shelf. Make sure to follow the layering rules.
```

**Good:**
```
| Field | Type | Required | Description |
|---|---|---|---|
| TEST_COMMAND | string | yes | Exact command to execute the test suite |
| PROJECT_PATH | path | yes | Absolute path to the project root |
| CONSTRAINT_PACK | object | yes | Mandatory rules and prohibitions from grounding |
```

### 6. Validation is explicit, not implied

Every rule gets its own bullet. "STATUS `done` requires VERDICT = `confirmed`" is a rule. "Ensure consistency between STATUS and VERDICT" is a suggestion — and suggestions get ignored.

**Bad:**
```
Make sure the response is valid and consistent.
```

**Good:**
```
## Validation
- STATUS `done` requires VERDICT = `confirmed`
- Every path in TEST_FILES must exist on disk
- EVIDENCE must contain actual output, not a summary
- STATUS `failed` must include NOTES explaining why
```

### 7. Context is just enough, never too much

The Context section tells the receiver WHY this handoff exists and WHAT preceded it. It does NOT reproduce the full pipeline history. One paragraph, 2-3 sentences. If the receiver needs more context, it reads previous handoff files in the same folder — they're numbered sequentially.

### 8. Reference by path, not by content

If the receiver needs a plan file, include the path. If it needs a research file, include the path. Don't copy the content into the handoff — that creates duplication and drift. The only exception is when the content doesn't exist as a file and must be composed in the payload.

### 9. Concrete values in examples, never placeholders

When providing concrete payload values, use actual paths, actual field values, actual commands. No `{placeholder}` syntax. A value like `.workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md` is a real path. A value like `{plan_path}` is not — it forces the receiver to guess what goes there.

---

## Good vs Bad Examples

### Example 1: Dispatch — Structured vs Unstructured

**Bad** (current pattern — dispatch fields embedded in Task prompt prose):
```
You are being invoked to write failing tests. Here is what you need:
- MISSION: write tests for the loan extension feature
- TEST_COMMAND: mvn test
- FILES: the new files in the loan-extension module
- CONSTRAINTS: follow the layering rules
```

No types. No required/optional distinction. No validation. The sub-agent interprets "the new files" and "layering rules" — interpretation produces inconsistency.

**Good** (proposed — handoff file with typed payload):

````markdown
---
from: executor
to: executor-red
timestamp: 2026-05-26T14:30:00Z
type: dispatch
status: pending
---

# Handoff: Executor → RED

## Purpose
Write failing tests that prove the loan extension behavior does not yet exist.

## Context
Grounding complete. Skeleton files created in the loan-extension module. Plan specifies two behavioral contracts (BC-01, BC-02) with boundary cases. This is the TDD RED phase.

## Payload

| Field | Type | Required | Description |
|---|---|---|---|
| MISSION | string | yes | What this dispatch must achieve |
| BEHAVIOR_TO_PROVE | list<object> | yes | BC-IDs with verifiable post-conditions |
| TEST_COMMAND | string | yes | Exact command to run tests |
| TEST_TARGET_FILES | list<path> | yes | Skeleton files tests are written against |
| PROJECT_PATH | path | yes | Absolute path to the project root |
| CONSTRAINT_PACK | object | yes | Mandatory rules and prohibitions |
| REFERENCE_PATH | path | no | Existing test file as pattern reference |

MISSION: Write failing tests proving that ExtendLoanService and LoanExtensionRepository do not yet satisfy BC-01 and BC-02.

BEHAVIOR_TO_PROVE:
  - BC-01: extensionsRemaining -= 1; LoanExtension record created with status PENDING
  - BC-02: HTTP 422 returned; extensionsRemaining unchanged; no LoanExtension record created

TEST_COMMAND: mvn test -pl modules/loan-extension -Dtest="*LoanExtension*"

TEST_TARGET_FILES:
  - ~/projects/shelf/modules/loan-extension/src/main/java/domain/entities/LoanExtension.java
  - ~/projects/shelf/modules/loan-extension/src/main/java/application/services/ExtendLoanService.java

PROJECT_PATH: ~/projects/shelf

CONSTRAINT_PACK:
  MANDATORY_RULES:
    - [layering] Service layer does not access repository directly — use port interface
    - [errors] All business rule violations return 422 with structured error body
  PROHIBITIONS:
    - Do not modify the HoldsModule — out of scope

REFERENCE_PATH: ~/projects/shelf/modules/holds/src/test/java/HoldServiceTest.java

## Validation
- BEHAVIOR_TO_PROVE must reference at least one BC-ID
- Every path in TEST_TARGET_FILES must exist on disk
- TEST_COMMAND must be executable in PROJECT_PATH
- CONSTRAINT_PACK must include at least one MANDATORY_RULE
````

### Example 2: Pointing Handoff — Review Request

**Bad** (current pattern — architect sends plan as in-memory text to its reviewer):
```
Architect writes the plan to .workspace/, then tells the reviewer: "Please review the plan at {path}"
No structured handoff. The reviewer doesn't know what to focus on, what to skip, or what the risk tolerance is.
```

**Good** (proposed — handoff file with pointing payload):

````markdown
---
from: architect
to: architect-plan-reviewer
timestamp: 2026-05-26T15:00:00Z
type: dispatch
status: pending
---

# Handoff: Architect → Architect-Plan-Reviewer

## Purpose
Adversarial review of the loan extension plan before delivery to the Executor.

## Context
Plan drafted for the shelf product. Two ADRs involved (optimistic locking, event-driven notifications). The feature changes persisted loan state — risk tolerance is low.

## Payload

| Field | Type | Required | Description |
|---|---|---|---|
| TARGET_PATH | path | yes | Absolute path to the plan file |
| REVIEW_SCOPE | string | yes | What the reviewer should focus on |
| IGNORE_SECTIONS | list<string> | no | Plan sections to skip |

TARGET_PATH: .workspace/shelf/features/2026-05-12-loan-extension/plans/1-loan-extension.md
REVIEW_SCOPE: Behavioral Contracts and Error Scenarios — boundary cases are the highest risk. Verify that optimistic locking (ADR-01) is correctly reflected in BC post-conditions.
IGNORE_SECTIONS: Test Strategy

## Validation
- TARGET_PATH must exist on disk
- TARGET_PATH must point to a file in the plans/ directory
````

### Example 3: Response — Structured Output from Sub-Agent

**Bad** (current pattern — untyped plain text returned in Task result):
```
MISSION: what was being tested
TEST_FILES_CHANGED:
- some file [created]
RED_RESULT: expected_failure_confirmed
STATUS: done
```

No types. No validation. `some file` is not a path. The receiver has to guess whether the test actually failed for the right reasons.

**Good** (proposed — response handoff file):

````markdown
---
from: executor-red
to: executor
timestamp: 2026-05-26T14:45:00Z
type: response
status: done
---

# Handoff: RED → Executor

## Purpose
Confirm that failing tests were written and prove the loan extension behavior does not yet exist.

## Context
Executed RED phase for BC-01 and BC-02. Two test files created against skeleton classes. Tests fail as expected — assertions target unimplemented behavior.

## Payload

| Field | Type | Required | Description |
|---|---|---|---|
| STATUS | enum(done, failed) | yes | Final status of the RED phase |
| RESULT | enum(expected_failure_confirmed, failed) | yes | Whether tests fail as expected |
| TEST_FILES | list<{path: path, action: enum(created, modified)}> | yes | Every test file written |
| TEST_COMMAND | string | yes | Exact command that was run |
| EVIDENCE | string | yes | Actual error output from test run |
| NOTES | string | no | Observations or caveats |

STATUS: done
RESULT: expected_failure_confirmed
TEST_FILES:
  - path: ~/projects/shelf/modules/loan-extension/src/test/java/LoanExtensionServiceTest.java, action: created
  - path: ~/projects/shelf/modules/loan-extension/src/test/java/LoanExtensionRepositoryTest.java, action: created
TEST_COMMAND: mvn test -pl modules/loan-extension -Dtest="*LoanExtension*"
EVIDENCE: |
  Tests run: 4, Failures: 4, Errors: 0, Skipped: 0
  - LoanExtensionServiceTest.testExtendLoan_Success: AssertionError: Expected status PENDING but was null
  - LoanExtensionServiceTest.testRejectExtensionOverLimit: AssertionError: Expected HTTP 422 but response was null
  - LoanExtensionRepositoryTest.testSave: AssertionError: Expected entity to be persisted but repository returned empty
  - LoanExtensionRepositoryTest.testFindByLoanId: AssertionError: Expected list of 1 but got empty

## Validation
- STATUS `done` requires RESULT = `expected_failure_confirmed`
- STATUS `failed` requires NOTES explaining why
- Every path in TEST_FILES must exist on disk
- EVIDENCE must contain actual error output, not a summary
````

### Example 4: Completion — Leaf Agent Signals Done

**Bad** (current pattern — freeform text with no validation):
```
[Shelf — Crawl Complete]
Workspace: .workspace/shelf/crawls/catalog-search/
Files written: 2
  - 01-search-page.png — search results page
  - search-flow.md — navigation flow
Summary: Mapped the catalog search flow and its entry points.
Recommended Next Action: Send to the Architect for planning.
```

No types. No validation. `2` files but only 2 listed. `Send to the Architect` is vague — send what, how?

**Good** (proposed — completion handoff file):

````markdown
---
from: crawler
to: orchestrator
timestamp: 2026-05-26T13:00:00Z
type: completion
status: done
---

# Handoff: Crawler → Orchestrator

## Purpose
Crawl complete for the catalog search flow. Files written and ready for planning.

## Context
Walked the search page, its filters, and the result detail navigation in the running shelf app. Found the entry points and URL patterns the architect needs to produce a plan.

## Payload

| Field | Type | Required | Description |
|---|---|---|---|
| WORKSPACE | path | yes | Absolute path to the crawl workspace |
| FILES_WRITTEN | list<{path: path, description: string}> | yes | Every file produced |
| SUMMARY | string | yes | 1-2 sentences on what was found |
| NEXT_ACTION | string | yes | Concrete recommendation for what happens next |

WORKSPACE: .workspace/shelf/crawls/2026-05-12-catalog-search-flow/
FILES_WRITTEN:
  - path: .workspace/shelf/crawls/2026-05-12-catalog-search-flow/01-search-page.png, description: Search results page with filters expanded
  - path: .workspace/shelf/crawls/2026-05-12-catalog-search-flow/search-flow.md, description: Navigation flow from search to result detail, with URL patterns
SUMMARY: Search is a single page with query-string filters, and result detail opens in a modal. Extending a loan from the detail modal requires a new action alongside the existing hold button.
NEXT_ACTION: Route to Architect with the workspace path for feature planning.

## Validation
- WORKSPACE path must exist on disk
- Every file in FILES_WRITTEN must exist on disk
- SUMMARY must be 1-2 sentences
- NEXT_ACTION must name a concrete next step and who performs it
````

---

## Commands

### Create the handoffs directory
```bash
# For features
mkdir -p .workspace/{project}/features/{date}-{slug}/execution/handoffs/

# For incidents
mkdir -p .workspace/{project}/incidents/{date}-{slug}/execution/handoffs/
```

### Determine the next file number
```bash
# List existing handoff files to find the next number
ls .workspace/{project}/features/{date}-{slug}/execution/handoffs/ | sort -t'-' -k1 -n | tail -1
# If the last file is "5-quality-review-response.md", the next number is 6
```

### Create a new handoff file
```bash
N=1  # or next available number
touch .workspace/{project}/features/{date}-{slug}/execution/handoffs/${N}-{slug}.md
```

### Verify handoff files before returning
```bash
# List all handoffs in chronological order
ls .workspace/{project}/features/{date}-{slug}/execution/handoffs/ | sort -t'-' -k1 -n

# Read a specific handoff file back
cat .workspace/{project}/features/{date}-{slug}/execution/handoffs/{N}-{slug}.md
```

---

## Quality Gate

Before writing a handoff file to disk, verify every item:

- [ ] File is in the correct location: `execution/handoffs/` under the right workspace
- [ ] File is numbered sequentially after the last existing handoff
- [ ] Frontmatter has all required fields: `from`, `to`, `timestamp`, `type`, `status`
- [ ] `type` is one of: `dispatch`, `response`, `completion`, `coordination`
- [ ] `status` is one of: `pending`, `done`, `failed`
- [ ] Purpose explains what this handoff achieves in 1-2 sentences
- [ ] Context explains why this handoff exists now in 2-3 sentences
- [ ] Payload uses tables with typed fields, required/optional marks, and descriptions
- [ ] Every field in the Payload has a type
- [ ] Every field in the Payload is marked required or optional
- [ ] Every field in the Payload has a description
- [ ] Concrete values are used — no `{placeholder}` syntax in actual values
- [ ] Validation section has at least one explicit rule with a clear pass/fail condition
- [ ] The file is self-contained for its declared scope — the receiver needs nothing else to act
- [ ] If the content already exists as a file, the payload points to it rather than duplicating it

If any item fails, fix the file before writing it to disk. A malformed handoff file is worse than no handoff file — it creates a false sense of structure while leaving the receiver guessing.
