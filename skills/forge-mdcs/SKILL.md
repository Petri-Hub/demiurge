---
name: forge-mdcs
description: Canonical template, loading model, and quality checklist for creating, validating, and updating a project's rule system — the .claude/rules/ directory and the root CLAUDE.md that orients agents to it. Produces rule files in three tiers (foundation, concerns, components) that load natively in Claude Code, always-apply or path-scoped.
user-invocable: false
---

# **Skill: Forge MDCs**

## **Purpose**

A project's rule system is what makes any agent generate code that matches the codebase instead of generic best-practice output. This skill exists to make that system reliable: it defines the one shape every rule file takes, the loading model that puts each rule in context at the right moment — and only then — and the checklist that catches defects before a rule ships. The single optimization target is **agent adherence**: every design choice below — mechanism-level reasons, inline anti-patterns, decision tables, right-time loading — serves it.

## **References**

The official Claude Code documentation is the source of truth for how rules load. Consult it when loading behavior or frontmatter is in doubt — it evolves faster than this skill.

| Topic | Link |
|---|---|
| **Memory & rules** — CLAUDE.md locations, imports, rules directory, path scoping | https://code.claude.com/docs/en/memory.md |
| **Monorepos** — root and per-directory rule layout in large repos | https://code.claude.com/docs/en/large-codebases.md |
| **Full documentation index** — every available page | https://code.claude.com/docs/llms.txt |

## **The Two Artifacts**

A project carries two kinds of documents, and the boundary between them is what keeps both useful. **Technical documents** govern how code is written — anything an agent must obey *while coding* lives as a rule file. **Business and human documents** explain what the system is for — onboarding, domain context, the per-module catalogue. These live in the project's `README.md`, which is the place to reach for business context on the codebase; Demiurge never touches it.

Demiurge produces the two technical documents:

| Artifact | Role |
|---|---|
| **`.claude/rules/`** | The architectural rules — hand-authored rule files in three tiers. Claude Code discovers every `.md` under `.claude/rules/` recursively and loads each one natively. |
| **`CLAUDE.md`** (repo root) | The agent's introduction to the project: a short macro view of what the system is, pointing at the rule system and telling the agent when to reach for the task-triggered rules. Generated wholesale from the rules on every run — it carries no rule content of its own. |

In a monorepo, rules may sit under a base project folder — `.claude/rules/shelf-api/` — so several rule sets live side by side.

## **Loading Model**

Claude Code loads rules natively. The `paths` frontmatter field is the only switch:

| Frontmatter | Behavior |
|---|---|
| *(none)* | **Always-apply** — loaded into context at the start of every session |
| `paths: [globs]` | **Path-scoped** — loaded when Claude reads a file matching any glob |

```yaml
---
paths:
  - "**/apps/shelf-api/**/usecases/**/*.java"
---
```

Globs support brace expansion (`src/**/*.{ts,tsx}`) and multiple patterns. That is the entire frontmatter schema — rule files carry no other fields; the H1 and Purpose section identify the rule.

**The classification test:** a rule is always-apply if a model writing *any* file in the codebase must respect it. Everything else gets `paths` — scoped to the files where the rule's subject manifests. A rule whose trigger is a *task* rather than a file type (emitting an event, adding an audit entry) still gets `paths` covering the files that task touches (multiple globs are fine), plus a trigger row in CLAUDE.md so agents read it when planning the task, before any file is open.

This per-rule granularity is the point: it keeps every session's context spent only on rules relevant to the work at hand.

## **Directory Structure**

```
.claude/rules/
├── foundation/                  # ALWAYS-APPLY — universal context every task needs
│   ├── architecture.md          #   layers, dependency rules, where files go
│   ├── nomenclature.md          #   file/class/type/method naming
│   └── code-quality.md          #   universal conventions (formatting, logging, language idioms)
├── concerns/                    # CROSS-CUTTING — patterns and practices, classified per rule
│   ├── <practice>.md            #   e.g. security, error-handling, testing, configuration
│   └── <pattern>.md             #   e.g. pagination, events, audit
└── components/                  # PER-FILE-TYPE — path-scoped, one rule per component kind
    ├── domain/
    ├── application/
    ├── infrastructure/
    └── presentation/

CLAUDE.md                        # generated orientation file at the repo root
```

- **A repository holding more than one project namespaces the tiers beneath a project segment** — `.claude/rules/<project>/foundation/…`, `.claude/rules/<project>/components/…`. A single-project repository omits the segment and puts the tiers directly under `.claude/rules/`.
- **The namespace organizes; it does not scope.** A rule with no `paths` is always-apply across the entire repository whichever project folder it sits in, so in a namespaced repo one project's foundation tier loads while work happens in another. Where that matters, give those rules `paths` covering their own project's directory — the glob is the only thing that scopes loading, and the folder is only how a reader tells whose rules these are.
- The tier directory communicates the rule's nature, so filenames carry no suffix: `components/application/use-case.md`, not `use-case.pattern.md`.
- Organize `components/` by the architectural layers the project actually uses.
- Anti-patterns live inline as `🚫 Wrong` blocks in the rule they belong to — there is no separate anti-patterns folder.
- Don't nest deeper than `components/<layer>/<file>.md`.

### **The Three Tiers**

| Tier | Loading | Contents |
|---|---|---|
| **Foundation** | Always-apply (no `paths`) | The universal trio: `architecture.md` (layer/dependency contract and directory layout — not the per-module catalogue, which is README material), `nomenclature.md`, `code-quality.md` |
| **Concerns** | Per-rule, by the classification test | Cross-cutting practices (security model, error-handling philosophy → usually always-apply) and cross-cutting patterns (pagination, events, testing, configuration → usually path-scoped) |
| **Components** | Path-scoped (always `paths`) | How to implement one component kind — entity, repository, use case, resource, DTO, mapper |

## **The Rule Template**

Every rule file — regardless of tier — follows this structure, in this order:

````markdown
---
paths:                    # path-scoped rules only; omit entirely for always-apply
  - "<glob>"
---

# <Rule Name>

## Purpose

> Blockquoted prose (single `>` block). What this governs, WHY these conventions exist, what
> "good" looks like, and the IS / IS-NOT boundary so an agent knows instantly whether the rule
> applies. Plain language only — no code here.

## Rules

### ✅ Do

| Rule | Directive |
|------|-----------|
| **<short bold plain-language title>** | <imperative directive> — <mechanism-level reason> |

### 🚫 Don't

| Rule | Directive |
|------|-----------|
| **<short bold plain-language title>** | Don't <action> — <mechanism-level reason> |

## Reference            <!-- optional; when the rule has a canonical taxonomy/lookup/decision -->

<tables: hierarchies, status maps, role tiers, decision forks (offset vs cursor), etc.>

## Patterns             <!-- required for component & concern rules; foundation may omit -->

### ✅ Correct

<a realistic, code-shaped example — no import/package blocks; type names + naming rules convey
location. Include an import only when the import itself is the lesson.>

### 🚫 Wrong            <!-- whenever a common mistake exists for this rule -->

<the anti-pattern inline>

> Blockquoted mechanism-level reason why the wrong version is wrong — symptom + consequence.
````

### **Section guide**

- **Purpose** — one blockquoted paragraph: *why* the conventions exist, what good looks like, the IS / IS-NOT boundary.
- **Rules** — two directive tables, **Do** and **Don't**. Each row: a short bold plain-language title (no code in the title) and a directive carrying a **mechanism-level reason** after an em-dash — *what breaks*, not a restatement. "because UUID-only lookups bypass tenant isolation", not "for security".
- **Reference** — the structured scaffolding that most drives consistent output: hierarchies, status maps, naming tables, and **decision tables** for ambiguous forks (offset vs cursor, checked vs unchecked). Models bend rules at the decision boundary; an explicit table removes the judgment call.
- **Patterns** — `✅ Correct` is realistic and code-shaped but import-free (imports cost tokens and drift from the real package layout). `🚫 Wrong` is the anti-pattern inline with a blockquoted mechanism-level reason. Foundation rules may omit Patterns when the directive tables and Reference fully convey the convention.

There is no Checklist section, no Related-rules line, and no References section inside a rule — each file is self-contained.

## **CLAUDE.md Generation**

`CLAUDE.md` at the repo root orients any agent to the project and its rule system. It is regenerated in full from `.claude/rules/` on every run and contains no rule content — the loader puts the rules themselves in context; CLAUDE.md tells the agent what the system is and when to reach for the task-triggered rules.

````markdown
# <Project Name>

## Intro

<2–4 sentences of natural-language orientation: what the system is, its stack, its architecture
shape, and any defining trait (tenancy model, domain). No code snippets.>

## Rules

Conventions live in `.claude/rules/` and load automatically — always-apply rules every
session, path-scoped rules when a matching file is read. The only ones to load yourself are the
task-triggered rules below.

### Read when you are…

| When you are… | Read |
|---|---|
| emitting or editing a domain event from a use case | `.claude/rules/concerns/events.md` |
| building or editing a paginated list or search endpoint | `.claude/rules/concerns/pagination.md` |
````

### **Generation rules**

- **Intro:** what the project is, stack, architecture, defining traits — natural language, no code snippets.
- **Trigger table:** one row per task-triggered rule — a short natural-language trigger ("adding an audit registration to a write-path use case") and the rule's path. Only rules whose trigger is a task belong here; purely file-bound rules load themselves and need no row.
- Rule paths in the table are plain text in backticks — never `@`-imports. An `@`-import loads the file at launch, which both defeats the on-demand intent and duplicates what the rules loader already loads.
- No rule bodies, no hand-written prose beyond the Intro and the two-line loading explanation. The file is overwritten in full on every run.

## **Naming**

- Filenames: kebab-case topic + `.md`, no suffix — `use-case.md`, `error-handling.md`.
- Selection test: a developer scanning the path must know what the rule covers. `components/application/use-case.md` passes; `rules.md` does not.

## **Writing Standards**

Verifiable rules — a rule file that violates any of them fails the checklist and is not saved until fixed.

1. **Every directive has a mechanism-level reason.** Not "Always use DTOs — for safety", but "Always use DTOs — raw objects bypass validation and let malformed data reach the service". The reason names what breaks, after an em-dash in the directive cell.
2. **Directives are assertive.** Do rows state the action; Don't rows start with "Don't". No "consider", "should generally", "when appropriate".
3. **Examples are realistic but import-free.** Code-shaped and recognizable, not pseudocode; omit `import`/`package` blocks unless the import is the lesson.
4. **Ground every rule and example in the actual codebase.** Verify class names, types, annotations, and signatures against real files before writing them. A rule that contradicts the code is a defect — match reality, then improve it by rule.
5. **One concern per rule file.** A controller rule does not also cover services. Split diffuse rules.
6. **No placeholders.** No "…", "etc", "TBD". Omit empty sections entirely.
7. **Loading is correct for the tier.** Foundation: no `paths`. Components: `paths`, always. Concerns: classified by the test, and task-triggered concerns carry both `paths` and a CLAUDE.md trigger row.
8. **Rules reference concrete artifacts.** "Use `@Body()` for request payloads", not "use the appropriate decorator".
9. **Size is governed by content.** Cap combined Do + Don't rows at ≤12 — a rule needing more is two rules. Reference tables and examples may run as long as the canonical content requires.
10. **Language is English.** Prose, headers, and titles in English; example code in the project's language.
11. **Emoji are fixed:** `✅` for Do / Correct, `🚫` for Don't / Wrong. Never `❌`.

## **Quality Checklist**

Run every check before delivery; fix every failure. If a check cannot pass after the maximum review iterations, surface the unresolved item to the user instead of shipping a known-defective rule set.

### Per-file

- [ ] File is in the correct tier directory; filename is kebab-case `.md` with no suffix
- [ ] Frontmatter is `paths` only — present with valid globs for path-scoped rules, absent entirely for always-apply rules
- [ ] Loading matches the tier: foundation has no `paths`; components have `paths`; concerns are classified by the test
- [ ] `## Purpose` is a single blockquoted paragraph with the IS / IS-NOT boundary and no code
- [ ] `## Rules` has the `### ✅ Do` table (and `### 🚫 Don't` where a real don't exists); every row has a bold plain-language title and a mechanism-level reason
- [ ] `## Patterns` → `### ✅ Correct` present for component and concern rules (foundation may omit); examples import-free unless the import is the lesson
- [ ] `### 🚫 Wrong` present wherever a common mistake exists, with a blockquoted mechanism-level reason
- [ ] `## Reference` present when the rule has a taxonomy, lookup, or decision fork
- [ ] No Checklist / Related-rules / References sections inside the rule
- [ ] Emoji are `✅`/`🚫` only; no hedging; no placeholders; combined Do + Don't rows ≤12
- [ ] Every class name, type, annotation, and signature matches the real codebase

### CLAUDE.md

- [ ] Structure is `# <Project>` + `## Intro` + `## Rules` (loading explanation + trigger table); no rule bodies, no extra prose
- [ ] Every task-triggered rule has exactly one trigger row; no file-bound rule appears in the table
- [ ] Triggers are natural-language phrases; rule paths are backticked text, never `@`-imports
- [ ] Every path in the table resolves to an existing rule file

### Project-level

- [ ] In a repository holding more than one project, the tiers sit under `.claude/rules/<project>/`, and any rule that must not reach a sibling project carries `paths` scoped to its own — the folder alone does not scope it
- [ ] The foundation trio (architecture, nomenclature, code-quality) exists and is always-apply
- [ ] Every file type the agent creates or modifies has a component rule
- [ ] Cross-cutting practices (security, error handling, testing, configuration) and the patterns the project relies on are covered by concerns
- [ ] No contradictions across rules; terminology is consistent; the whole set reads as one picture of how the project is built — and it matches the actual codebase
