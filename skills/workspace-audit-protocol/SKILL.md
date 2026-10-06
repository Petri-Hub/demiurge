---
name: workspace-audit-protocol
description: Defines the audits/ workspace type — the run card, the per-finding folder contract, the verdict and severity vocabulary, and the evidence rules. Load this skill after workspace-structural-protocol whenever you perform an audit and record what it surfaced. Domain-agnostic by design, the same schema carries a quality audit, a security review, an accessibility sweep, and a functional test pass.
user-invocable: false
---

# Skill: Workspace Audit Protocol

## Purpose

An audit's only lasting output is evidence, and evidence is worthless if the next reader cannot reconstruct what you saw. This skill defines how any agent records an audit in the workspace so that a person — or another agent, months later — can act on a finding without rerunning the audit.

It is deliberately **domain-agnostic**. A web accessibility sweep, a security review, and a functional test pass all produce the same shape: findings, backed by evidence, judged against stated criteria. The domain is a field you declare, never a difference in structure.

Read the **workspace-structural-protocol** skill first — it defines the workspace repository and where audits sit within it. The **workspace-lifecycle-protocol** skill covers pulling before you write and pushing when you finish.

---

## What an audit is

Every audit, whatever its domain, records these five things. When one is missing, the audit stops being reconstructable and becomes an opinion.

| Element | The question it answers | Where it lives |
|---|---|---|
| **Subject** | What was audited? | Run card, and each finding |
| **Criteria** | Audited *against* what standard, ruleset, or expectation? | Run card, and each finding |
| **Method** | How did you look — tools, versions, flows, sampling? | Run card, and each finding |
| **Findings** | What surfaced? | One folder each |
| **Verdict** | What is the overall judgement, and what was left unexamined? | Run card |

**The schema is fixed; the domain is declared.** The run card's `audit type` field is what lets this one structure carry a WCAG sweep and a threat model equally well — so no audit domain ever needs a parallel folder shape.

---

## Structure

```
.workspace/{project}/audits/{date}-{slug}/
  README.md                              ← run card: subject, criteria, method, findings index
  AUDITS.md                              ← worklist: what is pending, audited, skipped
  findings/
    {N}-{finding-slug}/
      README.md                          ← the finding report
      evidence/
        {evidence files}                 ← raw tool output, screenshots, logs
```

A finding and its proof are one unit. Everything about a single finding lives in a single folder, so it can be read, moved, handed off, or registered downstream by touching exactly one path. Every folder's entry point is its `README.md` — the audit's README is the run card, a finding's README is the report.

Worked shape:

```
.workspace/shelf/audits/2026-07-23-admin-accessibility/
  README.md
  AUDITS.md
  findings/
    1-contrast-fails-on-member-table/
      README.md
      evidence/
        axe-violations.json
        01-member-table-desktop.png
    2-form-inputs-missing-labels/
      README.md
      evidence/
        axe-violations.json
        01-member-create-form.png
        02-member-create-form-focus.png
```

---

## Naming

### Audit folder

```
{date}-{slug}
```

- `date` — ISO format, the day the audit opened: `2026-07-23`
- `slug` — kebab-case, naming the subject and, where useful, the audit type
- **Do not repeat the product name** — the parent folder already carries it
- Examples: `2026-07-23-admin-accessibility`, `2026-07-23-checkout-security`, `2026-07-23-loans-regression-pass`

When one dispatch fans out into several audits, give them a shared slug prefix so `ls` groups them: `2026-07-23-sweep-admin`, `2026-07-23-sweep-checkout`, `2026-07-23-sweep-onboarding`.

### Finding folder

```
{N}-{finding-slug}
```

- `N` — sequential integer from 1, no zero-padding
- `finding-slug` — kebab-case naming **the finding itself**, not its category

| Good | Weak | Why |
|---|---|---|
| `1-contrast-fails-on-member-table` | `1-accessibility-issue` | The slug is the index a reader scans — it should say what was found |
| `2-session-token-logged-in-plaintext` | `2-security-finding` | Category is already in the run card's `audit type` |

### Evidence files

Keep each tool's native format and extension — a raw `axe-violations.json` is more useful to the next reader than a prose summary of it. Number screenshots `{NN}-{descriptor}.png` from `01`, matching the crawl convention.

---

## The Run Card — `README.md`

Every audit folder opens with a run card. Its job is orientation and honest scoping: what was examined, against what, how, and what was left alone.

```markdown
# Audit — {Title}

- **Type:** audit
- **Audit type:** {web-quality | accessibility | security | functional | performance | …}
- **Project:** {project}
- **Subject:** {what was audited — URL, route set, module, service}
- **Criteria:** {standard, ruleset, or expectation, with version}
- **Opened:** {YYYY-MM-DD}
- **Audited by:** {agent or user}

## Method

{How the subject was examined: tools and versions, the flows performed, what was sampled.}

## Verdict

{2–4 sentences. The overall judgement and the headline findings.}

## Findings

| # | Finding | Verdict | Severity |
|---|---|---|---|
| 1 | Contrast fails on member table | defect | high |
| 2 | Form inputs missing labels | defect | medium |
| 3 | Keyboard navigation order holds throughout | conformity | none |

## Coverage

{What was in scope, and — equally important — what was not examined. A reader who mistakes an unexamined area for a clean one draws false confidence from this audit.}
```

The findings index is what makes a folder-per-finding layout scannable: one table, whole audit.

---

## The Worklist — `AUDITS.md`

The worklist is the audit's durable progress state. It exists because an audit walks many states and a context window does not survive that walk — everything not written down is lost when the run is compacted or interrupted. Update it as each state is finished, never in a batch at the end: a run stopped halfway must be resumable from this file alone.

```markdown
# Audit Worklist

- **Target:** {base URL}
- **Base viewport:** {width}×{height}
- **Concerns enabled:** {list}
- **Max states:** {n}

## Pending

| # | State | Route | Type | Priority |
|---|---|---|---|---|
| 3 | Member detail | /admin/members/:id | page | normal |

## Audited

| # | State | Route | Instrumented | Heuristic | Findings |
|---|---|---|---|---|---|
| 1 | Member list | /admin/members | done | done | 3 |
| 2 | New member modal | /admin/members | n/a (same route) | done | 1 |

## Skipped

| State | Route | Reason |
|---|---|---|
| Catalog export | /catalog/export | Requires write access; data modification disabled |
```

**Field notes:**

- **Instrumented runs per route; heuristic runs per state.** A modal on an already-measured route records `n/a (same route)` for instrumented rather than re-running a page-level engine against the same document.
- **Skipped entries need a reason.** A state skipped for missing permission is a coverage gap, and the run card's Coverage section reports it — silence would read as "clean."
- **Discovered states are appended to Pending** as they are found, so the worklist reflects real scope rather than the initial guess.

---

## The Finding — `README.md`

One finding per folder. The frontmatter is the machine-readable summary a downstream reader parses; the body is what makes the finding reproducible.

```markdown
---
verdict: defect | risk | observation | conformity
severity: critical | high | medium | low | none
criteria: {the specific rule, standard, or expectation judged against}
subject: {precise locator — route, screen, module, endpoint}
---

# {One-line statement of what was found}

## Where

{The precise location: URL or route, element or selector, file and line, endpoint. Include the environment and any state required to observe it — viewport, auth state, data conditions.}

## How it was found

{The reproducible path: the flow performed, step by step; the tool and version; the configuration or ruleset applied. A reader following this lands on the same observation.}

## Evidence

This finding is backed by the files in `./evidence/`, stored alongside this report. Open them before acting on the finding — they are the record of what was actually observed.

| File | What it shows |
|---|---|
| `./evidence/{file}` | {what it demonstrates, including any detail not obvious from opening it} |
| `./evidence/{file}` | {what it demonstrates} |

## Impact

{Who or what is affected, and why it matters. A concrete consequence, not a restatement of the rule.}

## Direction

{A suggested direction for resolution — a direction, not an implementation.}
```

### Field notes

- **`criteria`** names the specific rule, not the family: `WCAG 2.2 AA — 1.4.3 Contrast (Minimum)` rather than `accessibility`. Vague criteria make a finding unarguable in both directions.
- **`subject`** is a locator someone can navigate to, not a description.
- **`Direction`** stays a direction because the auditor's independence is the value being protected — an auditor who specifies the fix has taken partial ownership of it and can no longer judge it cleanly.
- **The Evidence table is the bridge to the adjacent files.** A reader who opens only this report learns from it that the evidence folder exists, what each file contains, and that the finding rests on them. Describe what a file demonstrates rather than restating its name.

### Worked example

`.workspace/shelf/audits/2026-07-23-admin-accessibility/findings/1-contrast-fails-on-member-table/README.md`

```markdown
---
verdict: defect
severity: high
criteria: WCAG 2.2 AA — 1.4.3 Contrast (Minimum)
subject: /admin/members — member listing table
---

# Member table body text fails minimum contrast against its row background

## Where

`/admin/members`, the member listing table — body cells in every row. Reproduces at 1440×900 on Chromium, signed in as an operator with at least one member present. Header cells pass; the failure is limited to body text.

## How it was found

Navigated to `/admin/members` with an operator session, then ran axe-core 4.10 through Playwright against the rendered page with the `wcag2aa` tag set. The scan flagged `color-contrast` on the table body cells. Confirmed by reading the computed foreground and background values directly.

## Evidence

This finding is backed by the files in `./evidence/`, stored alongside this report. Open them before acting on the finding — they are the record of what was actually observed.

| File | What it shows |
|---|---|
| `./evidence/axe-violations.json` | Raw axe output — the `color-contrast` rule, the failing selectors, and the measured ratio of 3.1:1 against the 4.5:1 required |
| `./evidence/01-member-table-desktop.png` | The table as rendered, with the low-contrast body text visible against the row background |

## Impact

Operators with low vision cannot reliably read member names and identifiers — the primary data on the screen the support team uses most. At 3.1:1 the text sits below the AA threshold for normal-size text, and every row is affected rather than an edge case.

## Direction

The row background and the body text colour need enough separation to clear 4.5:1. Both are theme tokens rather than table-local styles, so which side moves is a design-system decision rather than a table fix.
```

The same shape carries a failed functional flow or a misconfigured header — only the `criteria` and the evidence artifacts change.

---

## Vocabulary

### Verdict

| Verdict | Use when | Severity |
|---|---|---|
| `defect` | The subject demonstrably fails the stated criteria | `critical`–`low` |
| `risk` | Nothing is broken now, but a credible failure path exists | `critical`–`low` |
| `observation` | Worth recording, neither pass nor fail — context the next reader needs | usually `none` |
| `conformity` | Checked against the criteria, and it holds | `none` |

**Record conformities.** They are how a later audit distinguishes "checked and fine" from "never looked at" — the distinction that makes repeat audits cheaper and coverage claims honest.

### Severity

Severity describes the finding, not the effort to resolve it.

| Severity | Meaning |
|---|---|
| `critical` | Blocks a core capability or exposes serious harm — data loss, security exposure, total inaccessibility |
| `high` | Significant impairment on a primary path or for many users |
| `medium` | Real but bounded — a secondary path, a subset of users, or a workaround exists |
| `low` | Minor — cosmetic, edge-case, or visible only under unusual conditions |
| `none` | Nothing is wrong to rate; pairs with `conformity` and most `observation` findings |

---

## Evidence

Evidence is what separates an audit from an assertion. Each finding's `evidence/` folder holds the raw material behind it.

- **Capture the artifact the tool produced** — the JSON report, the HAR, the log excerpt, the screenshot. Raw output survives reinterpretation; a prose summary of it does not.
- **List every evidence file in the finding README's Evidence table**, each with a line saying what it demonstrates. An unlisted file is invisible to a reader working from the report, and noise to one browsing the folder.
- **Screenshot the state that demonstrates the finding**, including the surrounding context needed to recognize the screen.
- **Trim volume, keep fidelity.** Excerpt a 40 MB log down to the relevant window and say what was trimmed — rather than attaching the whole file or paraphrasing it away.

---

## Ownership

`audits/` is a **shared workspace type**: any agent performing an audit writes here, and the run card's `audited by` field records which one. This is deliberate — audit domains multiply over time, and a shared schema keeps a new auditing agent from needing a parallel structure.

| File | Written by | Read by |
|---|---|---|
| `audits/.../README.md` | The auditing agent | Any agent, user |
| `audits/.../AUDITS.md` | The auditing agent | Any agent, user |
| `audits/.../findings/{N}-{slug}/README.md` | The auditing agent | Any agent, user |
| `audits/.../findings/{N}-{slug}/evidence/*` | The auditing agent | Any agent, user |

**One audit folder per dispatched audit unit.** When several audits run in parallel, separate folders keep their writes disjoint — shared folders collide on finding numbers and produce push conflicts between agents working at the same time.

---

## Persistence

Audits follow the standard workspace sync in `workspace-lifecycle-protocol` — pull before writing, commit and push before returning to the invoker. Use the audit-specific commit action:

```
{agent-id}: audit complete — {date}-{slug}
```

Findings that are not pushed are invisible to every downstream reader, including the agent that dispatched the audit.

---

## Hard Constraints

These are absolute. Each one, violated, breaks a property the audit exists to provide.

- **Write each finding as you observe it, and update the worklist before moving on.** An audit walks more states than a context window survives. Record the finding, save its evidence, mark the state audited in `AUDITS.md`, then continue — so a run that is compacted, interrupted, or stopped halfway keeps everything it already learned and can resume from the file. Work held in memory for a batched write at the end is lost in full.

- **Every finding carries evidence a reader can open.** A finding with an empty `evidence/` folder is an assertion, and assertions are exactly what an audit exists to replace. When a finding genuinely has no capturable artifact, say so explicitly in the Evidence section and explain what was observed instead.

- **Write a direction, never an implementation.** Describe where a resolution should go and let the agent that owns the fix design it. An auditor who writes the patch has become a stakeholder in it and can no longer judge the result independently.

- **Declare what you did not examine.** The Coverage section is not optional. An audit that reports only what it looked at invites the reader to mistake silence for a clean result.

- **State the criteria before the judgement.** Every finding names the rule, standard, or expectation it was judged against. A finding without criteria cannot be confirmed, disputed, or re-tested — it is one agent's opinion wearing an audit's format.

- **Record what you observed; leave lifecycle state to the tracker.** Findings carry `verdict` and `severity` — intrinsic, immutable properties of what was seen. They never carry `open`, `in progress`, `done`, an assignee, or a due date. Workflow state belongs to whatever system tracks the work; duplicating it into a file creates a second source of truth that silently rots.
