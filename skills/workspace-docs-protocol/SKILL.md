---
name: workspace-docs-protocol
description: Defines how to produce and consume documentation research files inside the .workspace/ directory. Load this skill whenever you are about to write a docs file (features/.../docs/ or incidents/.../docs/) or read one produced by the Librarian. Covers the file format, quality framework, writing standards, and commands.
user-invocable: false
---

# Skill: Workspace Docs Protocol

## Purpose

This skill governs how documentation research files are written and read inside `.workspace/`. A docs file is a persistent knowledge artifact produced by the Librarian after querying the configured documentation MCP for external documentation — API references, framework behavior, library capabilities, configuration options. Unlike research files (codebase investigation) or investigation files (incident root cause), docs files capture **external documentation distilled for a specific need**. They exist so that the Architect, Executor, and Orchestrator can consume synthesized documentation without re-querying the documentation MCP or polluting their own context with raw tool-call output.

**Load `workspace-structural-protocol` first** if you haven't already, to understand the broader workspace layout.

## Core Principle

**Docs files are shared knowledge, not private notes.**

When the Librarian produces a docs file, it writes it once and every downstream agent reads the same file. The Architect reads it during planning. The Executor reads it during implementation. Neither re-queries Context7 because the knowledge is already captured, synthesized, and persisted on disk. One research session, multiple consumers, zero duplication.

## File Location

Docs files live in the `docs/` subfolder inside any workspace type that needs external documentation research:

```
.workspace/
  {project}/
    features/
      {date}-{feature-slug}/
        research/          ← codebase investigation (user-supplied)
        docs/              ← external documentation (Librarian)
          1-{descriptive-slug}.md
          2-{descriptive-slug}.md
        plans/
    incidents/
      {date}-{slug}/
        investigations/    ← incident root cause (user-supplied)
        docs/              ← external documentation (Librarian)
          1-{descriptive-slug}.md
        plans/
```

The `docs/` subfolder is created when the first docs file is written. It does not exist in an empty workspace.

**When to create it:**
- The Librarian receives a research delegation and needs to persist findings for downstream agents
- Any agent needs deep external documentation that would pollute its own context if queried inline

**When NOT to create it:**
- Quick one-off Context7 queries that the agent handles inline — docs files are for deep research, not trivial lookups
- Research that targets the codebase itself — that belongs in `research/`
- Investigation findings from observability tools — that belongs in `investigations/`

## File Ownership

| Folder | Written by | Read by |
|---|---|---|
| `features/.../docs/` | Librarian | Architect, Executor, Orchestrator, any agent |
| `incidents/.../docs/` | Librarian | Architect, Executor, Orchestrator, any agent |

**Ownership rules:**
- Only the Librarian writes to `docs/` — other agents consume, they do not produce
- Docs files are immutable once written — do not edit an existing docs file; produce a new numbered file if additional research is needed
- Any agent can read any docs file at any time — there are no access restrictions

## Docs File Template

Filename: `{N}-{descriptive-slug}.md`
Location: `.workspace/{project}/{context-type}/{date}-{slug}/docs/`

````markdown
---
library: "{library or framework name}"
library_id: "{documentation MCP library id or 'not-resolved'}"
queries:
  - "{query 1 that was executed}"
  - "{query 2 that was executed}"
confidence: high | medium | low
gaps:
  - "{what was searched but not found in the documentation}"
  - "{omit this key if no gaps exist}"
query_count: {N}
---

# {Title — what this docs file covers}

> Docs file {N} for {feature-slug | incident-slug}
> Produced by: Librarian
> Date: {YYYY-MM-DD}

---

## Findings

{Narrative synthesis — what was discovered, organized by relevance to the original request.
Free-form structure that adapts to the domain. This section breathes:
code examples inline where relevant, API signatures documented,
configuration options explained, architectural patterns described.

The structure follows the request, not the source documentation.
If the request was about authentication, organize by auth concerns.
If the request was about middleware, organize by middleware lifecycle.
Let the domain dictate the shape.}

---

## Gaps

{What the documentation didn't cover or what the documentation MCP didn't have.
State gaps directly — "X was not documented" or "Y could not be found
in the available library documentation." If no gaps, write:
"No gaps identified — all requested topics were covered in the documentation."}

---

## Sources

{Traceability — which documentation queries produced which findings.
Does not need to be exhaustive, but must be honest:
- If a finding came from query results, say so.
- If a finding is the Librarian's inference from multiple queries, say so.}
````

## The DCA Quality Framework

Before writing any docs file, validate your output against DCA:

| Letter | Criterion | Question to ask yourself |
|---|---|---|
| **D** | **Documented** | Is every finding traceable to a documentation query result? No fabrication, no assumptions, no "I think this is how it works." |
| **C** | **Contextual** | Is the synthesis organized around what the requesting agent actually needs, not around the documentation's own structure? |
| **A** | **Actionable** | Can the consuming agent read this file and immediately know how to proceed — no additional research needed? |

**If any letter fails, rewrite before saving.** A docs file that fails DCA wastes the consuming agent's context window and may introduce false confidence in undocumented behavior.

## Writing Standards

**Organize by the request, not the source.** If the Architect asked "how does authentication work in Next.js," organize by authentication concerns — not by Context7's page structure. The consumer cares about the answer, not the documentation's table of contents.

**Include code examples where they exist.** If the documentation shows a code snippet that illustrates the relevant behavior, include it. Code examples are the most actionable content — they show exactly how something works, not just what it's supposed to do.

**State gaps honestly.** "The documentation does not cover X" is a valid and valuable finding. It tells the consuming agent that this area is unknown and needs either manual verification or an alternative approach. A missing gap statement is worse than a gap — it creates false confidence.

**Keep the frontmatter accurate.** The `confidence` field is your honest assessment of how complete the research feels. `high` means all major topics were covered. `medium` means some areas are thin. `low` means significant portions of the request could not be satisfied. The consuming agent uses this to decide whether to trust the findings or seek additional sources.

**One topic per file.** If the request covers multiple distinct topics (e.g., Next.js middleware AND Next.js edge functions), split them into separate files. This allows consuming agents to load only what they need.

**Number files by reading priority, not discovery order.** If the request implies a foundational topic (e.g., project structure before configuration), write the foundation file first regardless of when you discovered it.

**Do not dump raw documentation.** Copying paragraphs verbatim from Context7 results defeats the purpose. Synthesize — explain what the documentation says in terms the consuming agent can act on. Quote directly only for precise API signatures, configuration values, or critical behavioral constraints.

## Commands

### Create the docs directory

```bash
# For features
mkdir -p .workspace/{project}/features/{date}-{slug}/docs/

# For incidents
mkdir -p .workspace/{project}/incidents/{date}-{slug}/docs/
```

### Determine the next file number

```bash
# List existing docs files to find the next number
ls .workspace/{project}/{context-type}/{date}-{slug}/docs/ | sort -t'-' -k1 -n | tail -1
# If the last file is "2-auth-middleware.md", the next number is 3
```

### Create a new docs file

```bash
N=1  # or next available number
touch .workspace/{project}/{context-type}/{date}-{slug}/docs/${N}-{slug}.md
```

### Verify docs files before returning

```bash
# List all docs files in reading order
ls .workspace/{project}/{context-type}/{date}-{slug}/docs/ | sort -t'-' -k1 -n

# Read each file back as the consuming agent would
for f in $(ls .workspace/{project}/{context-type}/{date}-{slug}/docs/ | sort); do
  echo "=== $f ==="; cat ".workspace/{project}/{context-type}/{date}-{slug}/docs/$f"; echo;
done
```

## Quality Gate

Before reporting back to the invoking agent that research is complete, verify every item:

- [ ] Docs file is in the correct location: `docs/` subfolder under the right workspace
- [ ] Docs file is numbered sequentially after the last existing docs file
- [ ] YAML frontmatter has all required fields: `library`, `library_id`, `queries`, `confidence`, `query_count`
- [ ] `confidence` is one of: `high`, `medium`, `low`
- [ ] `library_id` is a valid documentation MCP library ID or `not-resolved` if the library was not found
- [ ] `queries` lists every documentation query that was executed
- [ ] Findings section is organized by relevance to the request, not by documentation structure
- [ ] Gaps section exists and honestly states what was not found (or explicitly says "No gaps identified")
- [ ] Sources section provides traceability between findings and Context7 queries
- [ ] Every finding traces to a documentation query result — no fabrication
- [ ] Code examples are included where the documentation provides them
- [ ] DCA self-check passes: Documented, Contextual, Actionable

If any item fails, fix the file before returning. A docs file that fails the quality gate creates false confidence or forces the consuming agent to re-query — both defeat the purpose of the Librarian.
