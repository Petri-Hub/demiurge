---
name: forge-plan
description: Canonical template, section catalog, composition rules, and quality checklist for creating new plan template skills in the agenkit agent system. Use this skill when God needs to design, generate, or validate a plan template skill file for the Architect. Covers the plan template skill format, the master section catalog, and the quality checklist every plan template must pass before being saved.
user-invocable: false
---

# Skill: Plan Creation

## Purpose

A plan is the contract between the Architect and the implementation agent — every ambiguity in it becomes a design judgment made at implementation time, by the wrong agent. Plan templates keep that contract tight: each one defines the structure, sections, and writing standards for one kind of plan, and the Architect loads the right template during its Planning phase instead of improvising a document shape.

This skill is the canonical reference for creating those templates. Every plan template draws its sections from the Section Catalog defined here — no template invents sections outside the catalog. If a gap exists, God surfaces it and the user decides whether to extend the catalog first.

---

## Plan Template Skill Format

Every plan template skill follows this canonical structure. No exceptions.

```markdown
---
name: plan-{type}
description: {one-line description of when the Architect loads this template — states the plan intent and domain}
user-invocable: false
---

# Skill: Plan — {Type Name}

## Purpose

{What kind of plans this template produces. What distinguishes it from other plan templates. 2-3 sentences.}

## Sections

{Per-section subsections drawn from the Section Catalog. Each section includes a Rationale (blockquote), Template (code block), and Example (code block). Only sections applicable to this template's applicability and plan_type appear.}

### {Section Name}

> {1-2 sentence rationale from the catalog entry's Rationale field.}

#### Template
```markdown
{Section template from catalog}
```

#### Example
```markdown
{Filled example adapted to this template's domain}
```

{Repeat for each included section.}

## Writing Standards

{Rules the Architect follows when filling the template. Shared standards that apply to all plans plus any standards specific to this template type.}
```

### Frontmatter

#### Rationale

The frontmatter identifies the template and is how the Architect selects it. The `name` follows the `plan-*` family pattern the Architect's skill tables reference; the `description` carries the selection signal — the plan intent (feature, hotfix, improvement, refactor) and the domain it serves — so the Architect picks the right template without loading it.

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Skill identifier. Must follow the pattern `plan-{type}`. Examples: `plan-feature`, `plan-frontend-feature`, `plan-mobile-feature`. |
| `description` | Yes | One line stating when the Architect loads this template — the plan intent, the product or domain, and the kind of work it covers. |
| `user-invocable` | Yes | Always `false` — plan templates are loaded by the Architect, never invoked by the user. |

#### Example

```yaml
---
name: plan-backend-feature
description: Use when the Architect needs to produce a technical plan for a backend feature involving data models, business rules, API endpoints, or domain logic.
user-invocable: false
---
```

#### Directives

**Do:**
- Follow the `plan-{type}` naming convention strictly — the Architect's skill tables reference the family by this pattern
- Make `description` specific enough that the Architect can distinguish this template from others without loading it — name the plan intent and the domain

**Don't:**
- Don't use generic names like `plan-generic` or `plan-default` — every template should have a specific scope
- Don't describe a template as universal unless it genuinely works for both backend and frontend without modification

### Sections

#### Rationale

This section is the heart of the plan template. Each section from the Section Catalog gets its own subsection with three elements: a Rationale (why the section exists), a Template (the markdown structure), and an Example (a filled version showing target quality). This gives the Architect the complete picture — *why*, *what shape*, and *what good looks like* — for every section it must fill. Sections not included in the template do not appear — their absence is the constraint that prevents drift.

#### Template

```markdown
## Sections

### Summary

> A navigation TOC for the plan file. Mirrors the Summary section in agent files — gives the human reader a scannable map of every section and its anchor link.

#### Template
```markdown
## Summary

- [{Section Name}](#{section-anchor})
- [{Section Name}](#{section-anchor})
{...}
```

#### Example
```markdown
## Summary

- [Context & Motivation](#context--motivation)
- [Actors](#actors)
- [Architecture Decision Records](#architecture-decision-records-adrs)
- [Use Cases & Acceptance Criteria](#use-cases--acceptance-criteria)
- [Business Rules & Validations](#business-rules--validations)
- [Test Strategy](#test-strategy)
```

### {Section Name from Catalog}

> {1-2 sentence rationale copied from the catalog entry's Rationale field.}

#### Template
```markdown
{Section template from catalog, reproduced verbatim}
```

#### Example
```markdown
{Filled example adapted to this template's domain — shows target quality and specificity}
```

{Repeat for each included section.}
```

#### Directives

**Do:**
- Include only sections from the Section Catalog — no invented sections
- Preserve the section template format from the catalog entry exactly
- Include a **Rationale blockquote** after each `### Section Name` header — copy the 1-2 sentence rationale from the catalog entry's `#### Rationale` field
- Include a **Template subsection** with the section's markdown structure in a code block
- Include an **Example subsection** with a domain-appropriate filled version in a code block — compact (1-3 table rows, not the full catalog example), realistic (domain-specific values, not generic placeholders), and demonstrating the expected specificity and cross-referencing style
- Include the **Summary section** as the first entry — it is a structural element, not a catalog section, and must list every section included in the template
- Sections appear in the order defined by Composition Rules

**Don't:**
- Don't include sections from the catalog that don't apply to this template's `applicability`
- Don't modify the section templates from the catalog — use them verbatim in the Template subsection
- Don't add "optional" sections — if a section is in the template, the Architect fills it. If applicability is uncertain, omit the section entirely
- Don't use monolithic code fences to wrap all sections together — each section is an independent subsection with its own code blocks

### Writing Standards

#### Rationale

Writing standards are the guardrails that prevent the Architect from producing vague, inconsistent, or incomplete plans. They sit between the section template (what the section looks like) and the Architect's judgment (what content goes in it). Without them, the same section template produces wildly different quality depending on the complexity of the feature.

#### Template

```markdown
## Writing Standards

**Reference exact file paths.** `{full/path/to/File.ext}` is acceptable. "The hold entity" is not. The Architect has read the codebase — use that knowledge.

**One concern per entry.** A data model row that says "status and due date" is two rows. A use case that covers "create and notify" is two use cases. Split them.

**No placeholders.** "...", "etc", "TBD", "N/A (fill later)" are not acceptable. If a section genuinely has no content, omit the entire section — do not leave placeholders.

**Cross-reference by ID.** Business rules are BR-XX. ADRs are ADR-XX. Error scenarios reference their use case by name. State machine transitions reference their guard condition's business rule. Everything links.

**Separate new from modified.** When a section distinguishes between new and existing elements (Use Cases, Tests, Entities), maintain that separation — they have different implementation implications.

{Template-specific standards follow.}
```

#### Directives

**Do:**
- Include the universal standards above in every plan template
- Add template-specific standards for sections unique to this template type
- Keep standards as imperative rules — "do X", "don't Y"

**Don't:**
- Don't duplicate standards that are already in individual section directives
- Don't write standards as aspirational guidelines — they must be verifiable rules

---

## Composition Rules

These rules govern how God selects and orders sections when composing a plan template from the Section Catalog.

### Mandatory sections

These sections appear in EVERY plan template, regardless of applicability:

| Section | Why mandatory |
|---|---|
| Context & Motivation | Every plan must state why it exists |
| Test Strategy | Every plan must define how to verify correctness |

### Conditional sections

These sections appear when their inclusion criteria are met:

| Section | Applicability | Include when |
|---|---|---|
| Actors | universal | The system has multiple interacting roles (human or system) |
| ADRs | universal | Non-trivial architectural choices were made during planning |
| Use Cases & Acceptance Criteria | universal | The plan defines distinct behavioral flows |
| Error Scenarios | backend | Use cases have failure modes that need documentation |
| Business Rules & Validations | universal | Domain logic constraints govern the plan's behavior |
| Entities & Data Model | backend | New data structures or schema changes are involved |
| State Machine Transitions | universal | Entities have lifecycle states with defined transitions between them |
| Domain Events | backend | The system produces or consumes asynchronous events |
| File Structure | universal | New files or directories are created |
| Files Created / Modified / Deleted | universal | Specific file operations are part of the plan |
| Interfaces & Typings | backend | New port interfaces (repository ports, gateway ports, SPI contracts) are needed |
| API Contracts | backend | The plan defines server endpoints |
| Component Tree & Pages | frontend | New UI surfaces or route structures are involved |
| State Management | frontend | Client-side state is involved in the plan |
| Interaction Contracts | frontend | UI components have prop/event contracts worth documenting |
| API Consumption | frontend | The plan consumes existing API endpoints |
| Cross-Domain Modifications | universal | Changes span domains, products, or infrastructure boundaries |

### Ordering

Sections appear in this order within the plan document. The order follows the reasoning flow: understand the problem, understand the decisions, understand the behavior, understand the structure, understand verification, understand cross-cutting concerns.

1. Context & Motivation
2. Actors
3. ADRs
4. Use Cases & Acceptance Criteria
5. Error Scenarios
6. Business Rules & Validations
7. Entities & Data Model
8. State Machine Transitions
9. Domain Events
10. File Structure
11. Files Created / Modified / Deleted
12. Interfaces & Typings
13. API Contracts
14. Component Tree & Pages
15. State Management
16. Interaction Contracts
17. API Consumption
18. Test Strategy
19. Cross-Domain Modifications

### Template type heuristics

When God composes a plan template, use these heuristics for common types:

| Template type | Applicability | Included sections (by number) | Omitted sections (by number) | Notes |
|---|---|---|---|---|
| Backend feature | backend | 1-13, 18-19 | 14-17 (frontend) | Omit any conditional section whose criteria are not met |
| Frontend feature | frontend | 1-4, 6, 10-11, 14-18 | 5, 7-9, 12-13 (backend) | Omit any conditional section whose criteria are not met |
| Full-stack feature | universal | All whose criteria are met | — | Backend + frontend sections combined |
| Hotfix | backend or frontend | 1, 10-11, 18 | Most others | Surgical — ADRs only if non-obvious choice; Test Strategy always |

---

## Section Catalog

The Section Catalog is the single source of truth for all plan sections. Every plan template composes from this catalog. No plan template invents sections outside it.

Each catalog entry defines:
- **Applicability** — which template types can include this section
- **Category** — the conceptual layer this section addresses
- **When to include** — the inclusion criteria
- **When to omit** — explicit exclusion criteria
- **Rationale** — why this section exists and what failure mode it prevents
- **Template** — the markdown structure the Architect reproduces
- **Example** — a realistic filled example
- **Directives** — rules for filling this section correctly

---

### Context & Motivation

**Applicability:** universal
**Category:** WHY
**When to include:** Mandatory — every plan includes this section.
**When to omit:** Never.

#### Rationale

Without a clear statement of why the plan exists, the executor cannot distinguish essential behavior from incidental detail. Context & Motivation anchors every downstream decision — when the executor encounters ambiguity in a later section, this section tells them what the plan is fundamentally trying to achieve. A plan without motivation is a list of tasks without purpose.

#### Template

```markdown
## Context & Motivation

{1-3 sentences on WHY this plan exists. What business pain or technical debt it addresses. What changes after this plan is executed.}
```

#### Example

```markdown
## Context & Motivation

Members can borrow a title only when a copy happens to be on the shelf, so popular titles go to whoever checks most often. Members need to join a queue for a title with no available copy and be offered the next returned copy in order. This plan introduces the hold queue that allocates returned copies in queue order while keeping positions consistent under concurrent requests.
```

#### Directives

**Do:**
- Focus on business value and the problem being solved, not the technical solution
- State what changes after execution — the reader should understand the before/after
- Keep to 1-3 sentences — this is an anchor, not a history lesson

**Don't:**
- Don't describe the technical solution here — that belongs in later sections
- Don't include implementation details, file paths, or technology names
- Don't write more than 3 sentences — if you need more, the scope is too broad

---

### Actors

**Applicability:** universal
**Category:** WHO
**When to include:** The system has multiple interacting roles (human or system actors).
**When to omit:** Single-actor systems with no role differentiation.

#### Rationale

Without named actors, use cases and contracts cannot specify WHO triggers behavior and WHO has permission. Actors define the permission model and the interaction surface. A plan that says "the system processes the request" without naming who triggers it leaves the executor guessing about authentication, authorization, and audit trails.

#### Template

```markdown
## Actors

- **{Actor Name / Role}:** {Brief description of what this actor represents and how it relates to the plan}
- **{Actor Name / Role}:** {Brief description}
```

#### Example

```markdown
## Actors

- **Member:** The library member who places a hold on a title with no available copy. Initiates the hold flow.
- **Librarian:** Staff operator who manages the catalog and monitors hold queues. Has read access to all hold records.
- **Circulation Service:** Internal system actor that allocates returned copies to waiting holds. Consumes domain events.
```

#### Directives

**Do:**
- Include system actors (services, external systems) alongside human roles
- Describe what the actor DOES in relation to this specific plan, not in general
- Name actors by their domain role, not by their technical identifier

**Don't:**
- Don't describe implementation details — focus on role and relationship
- Don't list actors that don't interact with the plan's scope
- Don't use generic names like "User" or "System" when a domain-specific name exists

---

### Architecture Decision Records (ADRs)

**Applicability:** universal
**Category:** DECIDED
**When to include:** Non-trivial architectural or design choices were made during planning.
**When to omit:** No significant decisions — the plan follows established patterns entirely.

#### Rationale

Decisions made without documentation are decisions that will be re-litigated endlessly. ADRs capture the context, choice, and trade-off at the moment the decision is made, when the reasoning is fresh. Without ADRs, future readers see the "what" but not the "why," and are tempted to reverse decisions whose trade-offs they don't understand.

#### Template

```markdown
## Architecture Decision Records (ADRs)

| ID | Decision (Title) | Context (Why?) | Trade-offs / Consequences |
|---|---|---|---|
| ADR-01 | {Title} | {Why this decision was needed — what alternatives existed} | {What is sacrificed or gained by this choice} |
| ADR-02 | {Title} | {Context} | {Trade-offs} |
```

#### Example

```markdown
## Architecture Decision Records (ADRs)

| ID | Decision (Title) | Context (Why?) | Trade-offs / Consequences |
|---|---|---|---|
| ADR-01 | Optimistic locking for the title's queue | Prevents two holds taking the same queue position when members place holds concurrently, without distributed lock infrastructure. Alternative: Redis distributed lock — rejected due to infrastructure overhead for a single-field concurrency concern. | Adds retry complexity on the caller side; conflicts require the caller to fetch fresh state and retry. |
| ADR-02 | Event-driven hand-off to Circulation | Decouples placing a hold from allocating a copy. Alternative: Synchronous call — rejected because allocation runs against branch inventory and would block the member's request. | Introduces eventual consistency; allocation may lag behind the hold. Requires compensation logic if allocation fails. |
```

#### Directives

**Do:**
- Include trade-offs for every decision — a decision without trade-offs is either trivial (doesn't need an ADR) or incomplete
- Name the alternatives considered, not just the chosen path
- Reference ADRs from other sections when a section is affected by a decision (e.g., "per ADR-01, optimistic locking is used")

**Don't:**
- Don't document obvious or trivial choices — ADRs are for decisions where reasonable alternatives exist
- Don't write trade-offs as purely positive — every decision sacrifices something
- Don't repeat the ADR content in other sections — reference by ID

---

### Use Cases & Acceptance Criteria

**Applicability:** universal
**Category:** HOW
**When to include:** The plan defines distinct behavioral flows — new functionality or modified existing behavior.
**When to omit:** Pure data model changes with no behavioral impact, or infrastructure-only changes.

#### Rationale

Use cases are the behavioral contract between the plan and the executor. Without them, the executor knows WHAT to build (entities, endpoints) but not HOW the system should behave under different conditions. Acceptance criteria transform use cases into verifiable tests — they are the quality gate between "implemented" and "correct." A plan without use cases produces code that works but doesn't behave as intended.

#### Template

```markdown
## Use Cases & Acceptance Criteria

### New Use Cases

#### {Use Case Name}

| **Name** | **Description** | **Actors** | **Scope** |
|---|---|---|---|
| **{ServiceName}** | {One-line summary of what this use case does} | {Actor names or "N/A"} | {Permission scope or "N/A"} |

- **Main Flow:** {Numbered step-by-step of the new behavior}

- **Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| 1 | {precondition — system state, data, actor context} | {triggering action by actor or system} | {expected result — state change, output, or assertion} |
| 2 | {precondition} | {action} | {result} |

### Modified Use Cases

#### {Use Case Name}

| **Name** | **Description** | **Actors** | **Scope** |
|---|---|---|---|
| **{ServiceName}** | {One-line summary of what changes in the existing behavior} | {Actor names or "N/A"} | {Permission scope or "N/A"} |

- **What Changes:** {Brief description of the modification}

- **New or Adjusted Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| 1 | {precondition} | {action} | {result — note if replacing legacy behavior} |
```

#### Example

```markdown
## Use Cases & Acceptance Criteria

### New Use Cases

#### Place Hold

| **Name** | **Description** | **Actors** | **Scope** |
|---|---|---|---|
| **PlaceHoldService** | Places a hold on a title with no available copy, adding the member to the end of the title's queue | Member, Librarian | hold:write |

- **Main Flow:**
  1. Member opens a title with no available copy and chooses a pickup branch
  2. System validates the request against the member's active holds and the title's availability
  3. System increments the title's queue length using optimistic locking
  4. System creates a Hold record with WAITING status at the end of the queue
  5. System publishes a HoldPlaced event
  6. Circulation Service consumes the event and allocates the next returned copy in queue order

- **Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| 1 | Title has 0 available copies and 3 holds in queue; Member has 2 active holds | Member places a hold | queueLength becomes 4; Hold record created with status WAITING and queuePosition 4 |
| 2 | Title has 2 available copies | Member places a hold | Request rejected with HTTP 422; queueLength unchanged; no Hold record created |
| 3 | Member has 5 active holds | Request is submitted | Request rejected with HTTP 422; error message "HOLD_LIMIT_REACHED" |

### Modified Use Cases

#### Withdraw Title

| **Name** | **Description** | **Actors** | **Scope** |
|---|---|---|---|
| **WithdrawTitleService** | Updated to check for active holds before allowing withdrawal from the catalog | Librarian | catalog:write |

- **What Changes:** The withdrawal flow now checks for waiting or ready holds. If any exist, withdrawal is blocked.

- **New or Adjusted Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| 1 | Title has active holds (status IN [WAITING, READY]) | Librarian requests withdrawal | Request rejected with HTTP 422; error "Cannot withdraw title with active holds"; title status unchanged |
| 2 | Title has no active holds | Librarian requests withdrawal | Title status transitions to WITHDRAWN (legacy behavior preserved) |
```

#### Directives

**Do:**
- Separate new use cases from modified existing ones — they have different implementation implications (create vs. modify)
- Write acceptance criteria as BDD tables (Given/When/Then columns) — each row is a directly testable scenario
- Use the table format for every use case — Name, Description, Actors, Scope
- Number the main flow steps — this enables traceability to implementation steps
- Reference actors from the Actors section by their exact names

**Don't:**
- Don't combine multiple behaviors into one use case — one use case = one coherent behavioral flow
- Don't skip the "Modified Use Cases" sub-section when existing behavior changes — unmodified legacy behavior is a source of regressions
- Don't write vague acceptance criteria like "the system works correctly" — be specific about state changes and outputs
- Don't duplicate acceptance criteria that are already expressed in Business Rules — reference by BR-XX
- Don't use bullet lists for acceptance criteria — BDD tables enforce structure and make each criterion independently testable

---

### Error Scenarios

**Applicability:** backend
**Category:** HOW
**When to include:** Use cases have failure modes that produce distinct error responses or state changes.
**When to omit:** Plans with no error conditions beyond standard HTTP errors.

#### Rationale

Error scenarios are where production incidents hide. The happy path is usually correct because it's tested. Error paths are where assumptions break down — unhandled edge cases, missing validations, incorrect error codes. Documenting every error scenario per use case forces the plan author to think through failure modes systematically. Each error scenario becomes a test case.

#### Template

```markdown
## Error Scenarios

| Use Case | Scenario | Failure Pre-condition | Post-condition (verifiable) | Business Rule |
|---|---|---|---|---|
| {UseCaseName} | {error name} | {condition that causes failure} | {HTTP status + response body + system state} | {BR-XX} |
```

#### Example

```markdown
## Error Scenarios

| Use Case | Scenario | Failure Pre-condition | Post-condition (verifiable) | Business Rule |
|---|---|---|---|---|
| PlaceHoldUseCase | Hold limit reached | Member's active holds >= 5 | HTTP 422 + `{"error": "HOLD_LIMIT_REACHED"}`; queue unchanged | BR-01 |
| PlaceHoldUseCase | Concurrent modification conflict | Optimistic lock version mismatch on save | HTTP 409 + `{"error": "CONCURRENT_MODIFICATION"}`; caller must retry | BR-03 |
| PlaceHoldUseCase | Title has an available copy | availableCopies > 0 | HTTP 422 + `{"error": "TITLE_AVAILABLE"}`; queue unchanged | BR-02 |
| PlaceHoldUseCase | Title not found | titleId does not exist in database | HTTP 404 + `{"error": "TITLE_NOT_FOUND"}` | — |
```

#### Directives

**Do:**
- Map every error scenario to its use case by name
- Include the HTTP status code and response body shape
- Include the system state after the error (what changed vs. what stayed the same)
- Reference the business rule that triggers the error by BR-XX

**Don't:**
- Don't list generic HTTP errors (500, timeout) unless they have domain-specific handling
- Don't write vague error descriptions like "validation fails" — specify exactly which validation
- Don't omit the system state — the executor needs to know if partial state changes occurred or were rolled back

---

### Business Rules & Validations

**Applicability:** universal
**Category:** WHY
**When to include:** Domain logic constraints govern the plan's behavior — rules about what is allowed, what is valid, what must be enforced.
**When to omit:** Plans with no domain-specific constraints beyond standard CRUD validation.

#### Rationale

Business rules are the invariants that make the system correct. Without a centralized rule catalog, rules are scattered across use cases, contracts, and error scenarios — and inevitably, one gets missed during implementation. The rule catalog is the single source of truth: contracts reference rules, error scenarios reference rules, test cases verify rules. Every rule has a unique ID that traces through the entire plan.

#### Template

```markdown
## Business Rules & Validations

| ID | Rule Name | Description & Validation |
|---|---|---|
| BR-01 | {Name} | {Description of the rule and how/where it is validated} |
| BR-02 | {Name} | {Description} |
```

#### Example

```markdown
## Business Rules & Validations

| ID | Rule Name | Description & Validation |
|---|---|---|
| BR-01 | Hold limit | A member cannot have more than 5 active holds (status IN [WAITING, READY]). Validated by counting the member's active holds at service entry. |
| BR-02 | Holds only on unavailable titles | A hold can be placed only when the title has no available copy. Validated by comparing `availableCopies` to zero at service entry, after the hold limit check. |
| BR-03 | Optimistic concurrency | The title's version field is checked on save. If the version in memory differs from the database, the operation is rejected with 409. Validated at repository save. |
| BR-04 | Withdrawal guard | A title cannot be withdrawn from the catalog while it has active holds (status IN [WAITING, READY]). Validated by querying active hold count before withdrawal. |
```

#### Directives

**Do:**
- Give each rule a unique ID (BR-XX) — referenced by contracts and error scenarios throughout the plan
- Include WHERE the rule is validated (service entry, repository save, controller layer) — this tells the executor where to implement the check
- Include WHEN the rule fires (what triggers the validation) — this connects the rule to its context
- Separate business rules (domain invariants) from technical constraints (those belong in the plan's constraint section or ADRs)

**Don't:**
- Don't mix business rules with technical constraints — "use optimistic locking" is an ADR, not a business rule
- Don't write rules as implementation instructions — state the invariant, not the code
- Don't duplicate rules that are already in the catalog — each rule appears exactly once

---

### Entities & Data Model

**Applicability:** backend
**Category:** WHAT
**When to include:** New data structures are introduced or existing schema changes are needed.
**When to omit:** Frontend plans (use Component Tree & Pages instead), or plans with no data model changes.

#### Rationale

Entities are the nouns of the system. Without explicit entity definitions, the executor infers field names, types, and relationships from context — and inference produces mismatches. A plan that says "add a due date field" without specifying the type, time zone handling, or whether it's nullable produces a different database schema depending on the executor's assumptions. Entity definitions eliminate this ambiguity.

#### Template

```markdown
## Entities & Data Model

### {EntityName} — {NEW | MODIFIED}

| **Field** | **Type** | **Nullable** | **Description** |
|---|---|---|---|
| {field_1} | {type} | {yes/no} | {description} |
| {field_2} | {type} | {yes/no} | {description} |

{Repeat for each entity. Mark NEW entities with full definitions. Mark MODIFIED entities with only changed fields, noting what changes.}
```

#### Example

```markdown
## Entities & Data Model

### Hold — NEW

| **Field** | **Type** | **Nullable** | **Description** |
|---|---|---|---|
| id | UUID | no | Primary key, auto-generated |
| titleId | UUID | no | Foreign key to Title |
| memberId | UUID | no | Foreign key to Member |
| pickupBranchId | UUID | no | Foreign key to Branch where the copy will be collected |
| queuePosition | Integer | no | Position in the title's queue; 1 is next to be allocated |
| status | Enum(WAITING, READY, FULFILLED, CANCELLED, EXPIRED) | no | Current lifecycle state |
| readyUntil | Timestamp | yes | End of the pickup window, set when the hold becomes READY |
| version | Integer | no | Optimistic locking version |
| createdAt | Timestamp | no | Record creation time |
| updatedAt | Timestamp | no | Last modification time |

### Title — MODIFIED

| **Field** | **Type** | **Change** |
|---|---|---|
| queueLength | Integer | NEW FIELD — number of active holds waiting on this title. Initialized to 0 for existing records. |
```

#### Directives

**Do:**
- Mark every entity as NEW or MODIFIED
- For NEW entities, include all fields with full definitions
- For MODIFIED entities, include only the changed fields with a "Change" column describing what changes
- Specify precision for decimal types — `Decimal(18,2)`, not just "Decimal"
- Include foreign key relationships explicitly

**Don't:**
- Don't include fields inherited from base classes unless they're directly relevant to the plan
- Don't use vague types like "number" or "text" — use the database-level type (Decimal, Varchar, etc.)
- Don't omit the Nullable column — nullable vs. not-null is a database constraint that affects implementation

---

### State Machine Transitions

**Applicability:** universal
**Category:** HOW
**When to include:** The plan involves entities with lifecycle states and defined transitions between them.
**When to omit:** Entities with no state machine behavior (static data, simple CRUD without status changes).

#### Rationale

State machines are where the most critical business logic lives — especially in workflow, booking, and order-processing systems. Without an explicit transition table, the executor infers valid transitions from scattered business rules and use cases, inevitably missing edge cases like forbidden transitions, self-transitions, or guard conditions that must hold during a state change. A state machine table makes every possible transition — and every forbidden one — visible at a glance. It is the single source of truth for lifecycle behavior.

#### Template

```markdown
## State Machine Transitions

### {EntityName} — Lifecycle

| From State | To State | Trigger | Guard Condition | Side Effect |
|---|---|---|---|---|
| {state} | {state} | {what causes the transition} | {required condition, or "none"} | {what else happens during transition} |

{Repeat for each entity with lifecycle states.}
```

#### Example

```markdown
## State Machine Transitions

### Hold — Lifecycle

| From State | To State | Trigger | Guard Condition | Side Effect |
|---|---|---|---|---|
| WAITING | READY | Returned copy allocated by Circulation Service | Hold is first in the title's queue (BR-06) | Set readyUntil; publish HoldReadyForPickup |
| WAITING | CANCELLED | Cancellation request by Member | Hold not yet allocated a copy | Shift queuePosition of every hold behind it |
| READY | FULFILLED | Member checks out the allocated copy | Checkout happens before readyUntil (BR-07) | Create Loan for the copy |
| READY | EXPIRED | Pickup window elapsed | readyUntil is in the past (BR-07) | Allocate the copy to the next hold; publish HoldExpired |

### Member — Lifecycle (modified transitions)

| From State | To State | Trigger | Guard Condition | Side Effect |
|---|---|---|---|---|
| ACTIVE | SUSPENDED | Loan becomes overdue | Member has at least one loan past its due date (BR-08) | Set suspendedAt; log audit event |
| SUSPENDED | ACTIVE | Last overdue copy returned | No overdue loans remain | Clear suspendedAt |
| SUSPENDED | CLOSED | — | FORBIDDEN — must transition to ACTIVE first | — |
```

#### Directives

**Do:**
- Document every valid transition explicitly — if a transition does not appear in the table, it is forbidden
- Include guard conditions that reference Business Rules by ID (BR-XX) — transitions are where rules are enforced
- Include side effects — state changes often trigger notifications, counter adjustments, or audit logs
- Forbid impossible transitions explicitly with a "FORBIDDEN" entry when the forbidden path is a likely misconception
- Group transitions by entity — each entity with lifecycle states gets its own sub-table

**Don't:**
- Don't omit transitions because they seem "obvious" — what is obvious during planning is not obvious during implementation
- Don't describe transitions in prose — use the table format for scannability and completeness
- Don't duplicate guard conditions that are already in Business Rules — reference by BR-XX

---

### Domain Events

**Applicability:** backend
**Category:** WHEN
**When to include:** The system produces or consumes asynchronous events as part of the plan.
**When to omit:** Synchronous-only plans with no event-driven communication.

#### Rationale

Events are the temporal dimension of the system — they capture WHAT happens and WHEN. Without explicit event definitions, the executor doesn't know what to publish, what to subscribe to, what payload to include, or what triggers the event. Event-driven architectures without documented events produce silent failures: events that are never published, consumers that never subscribe, payloads that don't match expectations.

#### Template

```markdown
## Domain Events

| Event | Producer | Consumer | Trigger | Payload |
|---|---|---|---|---|
| {EventName} | {Who publishes} | {Who subscribes} | {When it fires} | `{JSON field list}` |
```

#### Example

```markdown
## Domain Events

| Event | Producer | Consumer | Trigger | Payload |
|---|---|---|---|---|
| HoldPlaced | PlaceHoldService | Circulation Service | After hold record created with WAITING status | `{ holdId, titleId, memberId, pickupBranchId, queuePosition, createdAt }` |
| HoldReadyForPickup | Circulation Service | Notification Service | After a returned copy is allocated to the hold | `{ holdId, copyId, pickupBranchId, readyUntil }` |
| HoldExpired | Circulation Service | PlaceHoldService | After the pickup window elapses without checkout | `{ holdId, copyId, expiredAt }` |
```

#### Directives

**Do:**
- Include the payload shape — the consumer needs to know what fields to expect
- Specify the trigger condition precisely — "after X is created with Y status", not "when things happen"
- List both producer and consumer by their service/module name

**Don't:**
- Don't list internal domain events that don't cross module boundaries unless they're architecturally significant
- Don't include infrastructure events (e.g., "message published to queue") — focus on domain events
- Don't omit the failure event if the flow has a failure path — consumers need to know about failures too

---

### File Structure

**Applicability:** universal
**Category:** HOW
**When to include:** New files or directories are created as part of the plan.
**When to omit:** Plans that modify existing files without creating new structural elements.

#### Rationale

The file structure gives the executor a map of where new code lives before they start writing it. Without it, the executor places files based on convention — which works until the convention is ambiguous. A visual tree structure is scannable in a way that a flat list of paths is not. It shows the hierarchical relationship between modules, directories, and files at a glance.

#### Template

````markdown
## File Structure

```
{root}/
└── {module}/
    ├── {directory}/
    │   └── {File.ext}
    └── ...
```
````

#### Example

````markdown
## File Structure

src/
└── modules/
    └── holds/
        ├── domain/
        │   ├── entities/
        │   │   └── Hold.java
        │   ├── ports/
        │   │   └── HoldRepository.java
        │   └── events/
        │       └── HoldPlaced.java
        ├── application/
        │   └── services/
        │       └── PlaceHoldService.java
        └── infrastructure/
            ├── controllers/
            │   └── HoldController.java
            └── repositories/
                └── HoldRepositoryImpl.java
````

#### Directives

**Do:**
- Show the approximate structure AFTER implementation — what will exist that doesn't now
- Use actual directory names from the codebase, not generic placeholders
- Include new directories and key files — not every file in the module

**Don't:**
- Don't include files that already exist unless they're moving to new locations
- Don't show the full existing module structure — only the new or changed parts
- Don't use placeholder names like `{module}` or `{file}` — use the actual names from the plan

---

### Files Created / Modified / Deleted

**Applicability:** universal
**Category:** HOW
**When to include:** Specific file operations are part of the plan.
**When to omit:** Plans with no file-level changes (rare — most plans change files).

#### Rationale

This section is the executor's checklist. Every file touched by the plan is listed here with its operation and justification. Without it, the executor discovers files to change by reading the entire plan and inferring them — a process that inevitably misses edge-case files. This table is also the review surface: during plan review, the reviewer scans this table to catch scope creep or missing files.

#### Template

```markdown
## Files Created / Modified / Deleted

| Action | File | Justification |
|---|---|---|
| **Create** | `{full/path/to/File.ext}` | {Why this file is being created} |
| **Modify** | `{full/path/to/File.ext}` | {What changes and why} |
| **Delete** | `{full/path/to/File.ext}` | {Why this file is being removed} |
```

#### Example

```markdown
## Files Created / Modified / Deleted

| Action | File | Justification |
|---|---|---|
| **Create** | `modules/holds/domain/entities/Hold.java` | New entity for hold records |
| **Create** | `modules/holds/domain/ports/HoldRepository.java` | Repository port for persistence abstraction |
| **Create** | `modules/holds/domain/events/HoldPlaced.java` | Domain event for hold creation |
| **Create** | `modules/holds/application/services/PlaceHoldService.java` | Core business logic for placing holds |
| **Create** | `modules/holds/infrastructure/controllers/HoldController.java` | REST endpoint for holds |
| **Create** | `modules/holds/infrastructure/repositories/HoldRepositoryImpl.java` | Repository implementation |
| **Modify** | `modules/catalog/domain/entities/Title.java` | Add `queueLength` field and queue increment logic |
| **Modify** | `modules/catalog/application/services/WithdrawTitleService.java` | Add active hold check before withdrawal |
| **Delete** | `modules/catalog/services/ReserveCopyService.java` | Replaced by the queue-based hold flow — holds no longer lock a specific copy |
```

#### Directives

**Do:**
- Use full file paths, not just filenames
- Explain WHY for each file operation — the reviewer needs to understand the reasoning
- Order by action type: Creates first, then Modifies, then Deletes

**Don't:**
- Don't group unrelated changes into one row — one file per row
- Don't use vague justifications like "update for new feature" — be specific about what changes
- Don't omit files that are indirectly affected (e.g., test files, configuration files)

---

### Interfaces & Typings

**Applicability:** backend
**Category:** WHAT
**When to include:** New port interfaces are needed — repository ports, gateway ports, or SPI contracts that define the domain boundary.
**When to omit:** Plans that don't introduce new port interfaces or change existing interface signatures.

#### Rationale

Port interfaces are the anticorruption boundary of the domain — they define where the domain connects to infrastructure, external providers, and other modules. Repository ports abstract persistence. Gateway ports abstract external service integrations. SPI contracts abstract provider-specific behavior. Without explicit port interface definitions, the executor creates interfaces based on the first implementation they write, which locks the abstraction to that implementation. Defining port interfaces before implementation ensures the abstraction serves the domain contract, not a specific infrastructure detail.

This section is exclusively for **port interfaces** — the `interface` keyword in Java, the `protocol` in Swift, the abstract contract in any language. Commands, Results, DTOs, request/response records, and other concrete types do NOT belong here. Commands and Results are visible through Use Cases. DTOs and request/response payloads are visible through API Contracts.

#### Template

````markdown
## Interfaces & Typings

- **{Port Interface Type}:** `{Name}`
  - **Purpose:** {Where it's used and why}
  - **Structure:**
    ```
    {interface or type definition}
    ```
````

#### Example

````markdown
## Interfaces & Typings

- **Repository Port:** `HoldRepository`
  - **Purpose:** Port interface for Hold persistence. Implemented by the infrastructure layer. Enables testing the service with a mock repository.
  - **Structure:**
    ```java
    public interface HoldRepository {
        Hold save(Hold hold);
        Optional<Hold> findById(UUID id);
        List<Hold> findByTitleId(UUID titleId);
        boolean hasActiveHolds(UUID titleId);
    }
    ```

- **Gateway Port:** `NotificationGateway`
  - **Purpose:** Port interface for the external messaging provider that delivers pickup notices by email or SMS. Implemented by the infrastructure layer with provider-specific adapters. Enables testing the service with a mock gateway.
  - **Structure:**
    ```java
    public interface NotificationGateway {
        DeliveryReceipt send(NotificationRequest request) throws NotificationGatewayException;
        DeliveryStatus status(String messageId) throws NotificationGatewayException;
    }
    ```
````

#### Directives

**Do:**
- Define the full interface signature, not just the name
- Include method signatures with parameter types, return types, and checked exceptions
- Explain WHERE the interface is used and WHY it exists as a port
- Use descriptive port interface type labels: `Repository Port`, `Gateway Port`, `SPI Contract`, `Port Interface`

**Don't:**
- Don't include Commands, Results, DTOs, or request/response records — those are concrete types, not port interfaces. Commands and Results are visible through Use Cases. DTOs and request/response payloads are visible through API Contracts.
- Don't include trivial interfaces (e.g., a repository with only `save`) unless they serve a testing or architectural purpose
- Don't mix interface definitions with implementation details — this section defines contracts, not implementations
- Don't omit the Purpose field — an interface without a stated purpose is an abstraction without justification

---

### API Contracts

**Applicability:** backend
**Category:** HOW
**When to include:** The plan defines new server endpoints or modifies existing ones.
**When to omit:** Frontend plans (use API Consumption instead), or plans with no HTTP endpoint changes.

#### Rationale

API contracts are the interface between the backend and everything that consumes it — frontend, other services, external integrations. Without explicit contract definitions, the executor decides request/response shapes on the fly, producing inconsistent error handling, undocumented status codes, and missing fields. A complete API contract is a test plan: every status code, every payload shape, every validation rule.

#### Template

````markdown
## API Contracts

- **{METHOD} `/api/v1/{resource}`**
  - **Request:**
    ```json
    {payload shape}
    ```
  - **Response (2xx):**
    ```json
    {payload shape}
    ```
  - **Errors (4xx/5xx):**
    - `{status code} {reason}`: {specific cause}
````

#### Example

````markdown
## API Contracts

- **POST `/api/v1/holds`**
  - **Request:**
    ```json
    {
      "titleId": "uuid",
      "pickupBranchId": "uuid"
    }
    ```
  - **Response (201):**
    ```json
    {
      "id": "uuid",
      "titleId": "uuid",
      "pickupBranchId": "uuid",
      "queuePosition": 4,
      "status": "WAITING",
      "createdAt": "2026-05-12T10:30:00Z"
    }
    ```
  - **Errors:**
    - `400 Bad Request`: Invalid payload (missing fields, non-UUID titleId or pickupBranchId)
    - `404 Not Found`: Title or branch does not exist
    - `422 Unprocessable Entity`: Title has an available copy, or member already has 5 active holds
    - `409 Conflict`: Concurrent modification detected (optimistic lock version mismatch)
````

#### Directives

**Do:**
- Define full request and response payload shapes with example values
- Map every error status to a specific cause — no generic "400 Bad Request"
- Include field types in the example (uuid, decimal, timestamp format)
- Use realistic example values, not "string" or "value"

**Don't:**
- Don't use vague error descriptions like "bad request" or "validation error" — specify the exact validation rule
- Don't include authentication/authorization errors unless they have domain-specific handling beyond standard 401/403
- Don't repeat the error details from the Error Scenarios section — this section defines the HTTP contract, that section maps to behavioral contracts

---

### Component Tree & Pages

**Applicability:** frontend
**Category:** WHAT
**When to include:** New UI surfaces, pages, or route structures are involved.
**When to omit:** Backend plans, or plans with no UI changes.

#### Rationale

For frontend plans, the component tree is the equivalent of the file structure for backend plans. It shows WHAT the user will see and HOW components compose. Without it, the executor decides component boundaries on the fly — producing either too few components (monolithic pages that are hard to test) or too many (unnecessary fragmentation). The component tree defines the structural contract before implementation begins.

#### Template

````markdown
## Component Tree & Pages

### Route: `/{path}`

**Page:** {PageName}
**Layout:** {LayoutName or "Default"}
**Access:** {public | authenticated | role-based (specify role)}

```
{PageName}
├── {ComponentA}
│   ├── {SubComponentA1}
│   └── {SubComponentA2}
├── {ComponentB}
└── {ComponentC}
```

{Repeat for each route / page}
````

#### Example

````markdown
## Component Tree & Pages

### Route: `/catalog/titles/:id`

**Page:** TitleDetailPage
**Layout:** MemberLayout
**Access:** authenticated (Member role)

```
TitleDetailPage
├── TitleHeader
│   ├── CoverImage
│   └── AuthorList
├── TitleAvailability
│   ├── CopyCountDisplay
│   ├── QueueLengthDisplay
│   └── PlaceHoldButton (visible when availableCopies === 0)
├── BranchSelector
└── LoanHistory (collapsible)
    └── HistoryTable
```

### Route: `/account/holds/:id`

**Page:** HoldDetailPage
**Layout:** MemberLayout
**Access:** authenticated (Member or Librarian)

```
HoldDetailPage
├── StatusBanner
├── HoldInfo
│   ├── QueuePositionDisplay
│   ├── PickupWindowDisplay (visible when status === READY)
│   └── StatusBadge
└── ActionButtons
    └── CancelButton (visible when status === WAITING)
```
````

#### Directives

**Do:**
- Include route, layout, and access control for every page
- Show the component hierarchy as a tree — this communicates composition at a glance
- Annotate conditional rendering inline (e.g., "visible when status === PENDING")
- Use domain-specific component names, not generic names like "Form" or "List"

**Don't:**
- Don't include styling, CSS, or visual design details — focus on structure and composition
- Don't show every possible sub-component — include components that have meaningful behavior or state
- Don't use placeholder component names — use names the executor can directly map to implementation

---

### State Management

**Applicability:** frontend
**Category:** WHAT
**When to include:** Client-side state is involved — form state, API response caching, UI state machines.
**When to omit:** Static pages with no dynamic state, or backend plans.

#### Rationale

State is where frontend bugs hide. Without an explicit state definition, the executor scatters state management across components — duplicating state, creating inconsistent updates, and making debugging difficult. Defining the state shape, actions, and mutations upfront ensures state is managed consistently and every state transition is documented.

#### Template

````markdown
## State Management

### {StateName}

**Scope:** {global | feature | component}
**Shape:**
```typescript
interface {StateName} {
  {field}: {type};
}
```

**Actions:**
| Action | Trigger | State Change |
|---|---|---|
| {actionName} | {what triggers it} | {how state mutates} |

**Initial State:**
```typescript
const initial{StateName}: {StateName} = {
  {field}: {value},
};
```
````

#### Example

````markdown
## State Management

### HoldRequestState

**Scope:** Feature (scoped to `/catalog/titles/*`)

**Shape:**
```typescript
interface HoldRequestState {
  branches: Branch[];
  titleId: string | null;
  selectedBranchId: string | null;
  status: 'idle' | 'loading' | 'success' | 'error';
  error: string | null;
}
```

**Actions:**
| Action | Trigger | State Change |
|---|---|---|
| setTitle | Page loads a title | `titleId = id; selectedBranchId = null` |
| setSelectedBranch | User picks a pickup branch | `selectedBranchId = id` |
| submitRequest | User clicks place hold | `status = 'loading'` |
| submitSuccess | API returns 201 | `status = 'success'; error = null` |
| submitFailure | API returns error | `status = 'error'; error = message` |
| reset | User navigates away | All fields reset to initial state |

**Initial State:**
```typescript
const initialHoldRequestState: HoldRequestState = {
  branches: [],
  titleId: null,
  selectedBranchId: null,
  status: 'idle',
  error: null,
};
```
```
````

#### Directives

**Do:**
- Define the full state shape as a typed interface — field names, types, and nullability
- List every action with trigger and state mutation — no action should be undocumented
- Distinguish UI state (loading, error) from domain state (data) within the same structure
- Include the initial state — the executor needs to know the starting point

**Don't:**
- Don't include implementation details (which state library, how reducers work) — focus on the shape and transitions
- Don't define state at the component level unless the state is truly local — prefer feature or global scope
- Don't omit the Scope field — it tells the executor where the state lives

---

### Interaction Contracts

**Applicability:** frontend
**Category:** HOW
**When to include:** UI components have prop/event contracts that define their interface boundary.
**When to omit:** Backend plans, or frontend plans with trivial component interactions.

#### Rationale

Interaction contracts are the frontend equivalent of Behavioral Contracts. They define the interface between components — props in, events out, rendering rules. Without them, the executor decides prop names, event payloads, and conditional rendering logic on the fly. This produces inconsistent component APIs, missing prop validations, and components that know too much about their parents.

#### Template

```markdown
## Interaction Contracts

### {ComponentName}

**Props:**
| Prop | Type | Required | Description |
|---|---|---|---|
| {propName} | {type} | {yes/no} | {what it provides} |

**Events emitted:**
| Event | Payload | When emitted |
|---|---|---|
| {eventName} | {payload type} | {trigger condition} |

**Rendering rules:**
- {Rule describing conditional rendering or behavior}
```

#### Example

```markdown
## Interaction Contracts

### TitleAvailability

**Props:**
| Prop | Type | Required | Description |
|---|---|---|---|
| availableCopies | number | yes | Copies currently on the shelf |
| queueLength | number | yes | Members already waiting for this title |
| activeHoldCount | number | yes | The member's current active holds |
| holdLimit | number | no | Maximum active holds per member (default: 5) |
| disabled | boolean | no | Disables the hold action (default: false) |

**Events emitted:**
| Event | Payload | When emitted |
|---|---|---|
| placeHold | string (title ID) | User clicks PlaceHoldButton |
| limitReached | number | When rendered with `activeHoldCount >= holdLimit` |

**Rendering rules:**
- Shows PlaceHoldButton only when `availableCopies === 0`
- Disables PlaceHoldButton and shows the limit message when `activeHoldCount >= holdLimit`

### BranchSelector

**Props:**
| Prop | Type | Required | Description |
|---|---|---|---|
| branches | Branch[] | yes | Pickup branches to display |
| selectedId | string \| null | yes | Currently selected branch ID |
| loading | boolean | no | Shows skeleton while loading |

**Events emitted:**
| Event | Payload | When emitted |
|---|---|---|
| select | string (branch ID) | User clicks a branch option |

**Rendering rules:**
- Shows empty state when `branches` array is empty
- Highlights selected option with accent border
- Shows loading skeleton when `loading` is true
```

#### Directives

**Do:**
- Define props, events, and rendering rules for every component that has non-trivial behavior
- Include conditional rendering rules — they prevent the executor from hardcoding visibility logic
- Specify default values for optional props
- Use TypeScript types for props and events — they map directly to implementation

**Don't:**
- Don't describe component implementation — focus on the contract (inputs, outputs, rules)
- Don't include trivial components that just render static content with no props/events
- Don't mix styling concerns with interaction contracts — color, spacing, and visual details belong in design specs

---

### API Consumption

**Applicability:** frontend
**Category:** HOW
**When to include:** The plan consumes existing API endpoints from the frontend.
**When to omit:** Backend plans, or frontend plans with no API calls.

#### Rationale

API Consumption defines the client-side perspective of API interactions — which component triggers the call, what happens on success, and critically, what happens on each error status. Without it, the executor implements generic error handling (catch-all toast message) instead of domain-specific UX (redirect on 404, inline validation on 422, retry prompt on 409). This section bridges the backend's API Contracts with the frontend's user experience.

#### Template

````markdown
## API Consumption

### {methodName} — {METHOD} `{endpoint}`

**Called by:** {Which component or service triggers this call}
**When:** {Trigger condition}

**Request:**
```typescript
{request shape or type}
```

**Response (2xx):**
```typescript
{response shape or type}
```

**Error handling:**
| Status | Action |
|---|---|
| {status} | {what the frontend does — UI behavior, state change, navigation} |

{Repeat for each consumed endpoint}
````

#### Example

````markdown
## API Consumption

### createHold — POST `/api/v1/holds`

**Called by:** HoldService (invoked from TitleAvailability on placeHold)
**When:** User confirms the hold request

**Request:**
```typescript
interface CreateHoldRequest {
  titleId: string;
  pickupBranchId: string;
}
```

**Response (201):**
```typescript
interface HoldResponse {
  id: string;
  titleId: string;
  pickupBranchId: string;
  queuePosition: number;
  status: 'WAITING' | 'READY' | 'FULFILLED' | 'CANCELLED' | 'EXPIRED';
  createdAt: string;
}
```

**Error handling:**
| Status | Action |
|---|---|
| 400 | Show generic form error: "Invalid request. Check the fields." |
| 404 | Show toast: "Title not found." Redirect to catalog search. |
| 422 | Extract error message from response body. Display inline on TitleAvailability. |
| 409 | Show toast: "This title was just updated. Please refresh and try again." Trigger data refetch. |
| 500 | Show toast: "Unexpected error. Please try again later." Log to error tracking. |

### getBranches — GET `/api/v1/branches?active=true`

**Called by:** TitleDetailPage on mount
**When:** Page loads

**Response (200):**
```typescript
interface BranchesResponse {
  data: Branch[];
  total: number;
}
```

**Error handling:**
| Status | Action |
|---|---|
| 401 | Redirect to login |
| 500 | Show empty state with retry button |
````

#### Directives

**Do:**
- Define the error handling strategy per status code — each status produces a specific UX response
- Specify which component triggers the call — this connects the API layer to the component tree
- Use TypeScript interfaces for request/response shapes
- Include both success and error paths

**Don't:**
- Don't repeat the full API definition from API Contracts — focus on the client-side perspective (what the frontend does with the response)
- Don't use generic error handling like "show error" — specify the UX action (toast, inline, redirect, retry)
- Don't omit the "Called by" and "When" fields — they connect the API call to the component interaction flow

---

### Test Strategy

**Applicability:** universal
**Category:** VERIFIED
**When to include:** Mandatory — every plan includes this section.
**When to omit:** Never.

#### Rationale

Without a test strategy, the executor writes tests reactively — covering what they remember, missing what they don't. The test strategy enumerates exactly what to verify, turning the plan's contracts and rules into explicit test cases. It also catches existing tests that need adjustment when behavior changes. A plan without a test strategy produces code that works but isn't verified — and unverified code is untrusted code.

#### Template

```markdown
## Test Strategy

### New Tests

| Type | Test File | Test Name | Scenario to Validate |
|---|---|---|---|
| {Unit | Integration | E2E} | `{file path}` | {method name} | {what it verifies — traceable to a use case or rule} |

### Modified Tests

| Type | Test File | Test Name | Adjustment Needed |
|---|---|---|---|
| {Unit | Integration} | `{file path}` | {method name} | {what changes — new mocks, adjusted assertions, new test} |
```

#### Example

```markdown
## Test Strategy

### New Tests

| Type | Test File | Test Name | Scenario to Validate |
|---|---|---|---|
| Unit | PlaceHoldServiceTest.java | shouldCreateHoldAtEndOfQueue | PlaceHoldUseCase: happy path — queue length increased, record created |
| Unit | PlaceHoldServiceTest.java | shouldRejectWhenHoldLimitReached | BR-01: member already has 5 active holds |
| Unit | PlaceHoldServiceTest.java | shouldRejectWhenTitleAvailable | BR-02: availableCopies > 0 |
| Unit | PlaceHoldServiceTest.java | shouldHandleConcurrentModification | BR-03: optimistic lock conflict returns 409 |
| Integration | HoldControllerTest.java | shouldReturn201OnValidRequest | Full HTTP flow with valid payload |
| Integration | HoldControllerTest.java | shouldReturn422WhenTitleAvailable | Error response shape for the availability validation (BR-02) |

### Modified Tests

| Type | Test File | Test Name | Adjustment Needed |
|---|---|---|---|
| Unit | WithdrawTitleServiceTest.java | shouldWithdrawTitleSuccessfully | Add mock for `hasActiveHolds` returning false |
| Unit | WithdrawTitleServiceTest.java | shouldRejectWithdrawalWithActiveHolds | NEW test: validate withdrawal blocked when active holds exist (WithdrawTitleUseCase) |
```

#### Directives

**Do:**
- Separate new tests from modified existing tests — they have different implementation implications
- Name test files and methods explicitly — they become implementation tasks
- Trace each test to a use case (by name), rule (BR-XX), or error scenario — every test verifies something specific
- Include test type (Unit, Integration, E2E) — it determines the testing scope

**Don't:**
- Don't write vague test descriptions like "test the service" — specify the scenario
- Don't omit the "Modified Tests" section when existing behavior changes — regressions hide in unmodified tests
- Don't list tests for standard framework behavior (e.g., "test that the controller returns JSON") — focus on domain-specific verification

---

### Cross-Domain Modifications

**Applicability:** universal
**Category:** HOW
**When to include:** Changes span domains, products, infrastructure, or external systems outside the plan's primary scope.
**When to omit:** Plans fully contained within a single domain/product scope.

#### Rationale

Cross-domain changes are the highest-risk part of any plan — they affect systems the planner may not fully understand, they require coordination across teams, and they're the easiest to overlook during review. Isolating them in a dedicated section forces the planner to explicitly identify what falls outside the main scope and document the impact. Without this section, cross-domain changes are buried in other sections and missed during implementation.

#### Template

````markdown
## Cross-Domain Modifications

### Context: {Domain / Product / Infrastructure area}

**1. {Title}**

{What needs to be done, the impact, and any coordination requirements.}

```{code snippet if needed}```
````

#### Example

````markdown
## Cross-Domain Modifications

### Context: Infrastructure — AWS / Terraform

**1. Add SQS queue for Hold events**

Create a new SQS queue `hold-events` for the Circulation Service to consume. Required before the application change is deployed.

```hcl
resource "aws_sqs_queue" "hold_events" {
  name                       = "hold-events"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600
}
```

### Context: Frontend — Member Portal

**1. Update the title page to support placing holds**

Add a hold flow to the title page for titles with no available copy. The existing borrow flow for available titles remains unchanged. Coordinate with frontend team — this is a separate deployment from the backend change.
````

#### Directives

**Do:**
- Use this section ONLY for changes outside the main application scope — infrastructure, other products, external systems
- Include code snippets for infrastructure changes (Terraform, CloudFormation, etc.)
- Note coordination requirements — who needs to know, what needs to deploy first
- Separate by context — each domain/product/infrastructure area gets its own sub-section

**Don't:**
- Don't include changes to the main application module here — those go in Files Created / Modified / Deleted
- Don't use this section as a catch-all for "miscellaneous changes" — every entry must be genuinely cross-domain
- Don't omit infrastructure prerequisites — if the application change depends on infrastructure, say so explicitly

---

## Quality Checklist

Before saving a plan template skill file, verify every item:

- [ ] Frontmatter is exactly `name`, `description`, and `user-invocable: false`
- [ ] `name` follows the `plan-{type}` convention, and `description` states the plan intent and domain
- [ ] "Sections" includes only sections from the Section Catalog (plus the structural Summary entry)
- [ ] Every section in "Sections" matches the template's applicability (backend sections not in frontend templates, frontend sections not in backend templates)
- [ ] Sections appear in the order defined by Composition Rules
- [ ] Mandatory sections (Context & Motivation, Test Strategy) are present
- [ ] Conditional sections have their inclusion criteria met for this template type
- [ ] Each section has a Rationale blockquote (from the catalog entry's Rationale field), a Template subsection (verbatim from catalog), and an Example subsection (domain-appropriate filled version)
- [ ] Examples are compact (1-3 table rows), realistic (domain-specific values), and demonstrate expected specificity and cross-referencing
- [ ] Summary is the first section entry and lists every section included in the template with correct anchor links
- [ ] Writing Standards include the universal standards (exact file paths, one concern per entry, no placeholders, cross-reference by ID)
- [ ] No section in the catalog is missing from the template without justification (applicability mismatch or conditional criteria not met)
- [ ] No invented sections exist in the template that are not in the Section Catalog