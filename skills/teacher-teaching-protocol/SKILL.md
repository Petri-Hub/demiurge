---
name: teacher-teaching-protocol
description: Defines Teacher's course state inside .workspace/teaching/ — the file schemas for course cards, syllabi, spacing ledgers, quizzes, and episode records, plus the spaced-repetition rules that drive them. Load at the start of any course pipeline, after the workspace structural and lifecycle protocols.
user-invocable: false
---

# **Skill: Teacher — Teaching Protocol**

## **Purpose**

Course state is the product of the learning pipelines: a syllabus is a plan, a ledger is a memory model, a quiz file is evidence. This skill defines the schemas for that state and the spacing rules that update it, so every course session reads and writes the same structures regardless of when the last session ran.

**Load `workspace-structural-protocol` and `workspace-lifecycle-protocol` first** — `teaching/` lives inside `.workspace/`, is synced by the same git protocol, and is owned exclusively by Teacher.

## **Layout**

```
.workspace/teaching/
  courses/
    {date}-{course-slug}/      ← date = course opening date, ISO format
      README.md                ← course card
      syllabus.md              ← approved episode arc and per-episode status
      ledger.md                ← the spacing engine: concept schedule and strengths
      quizzes/
        {n}-{date}.md          ← one file per recall quiz, n sequential from 1
      episodes/
        {n}-{episode-slug}.md  ← one record per produced episode
  archive/
    {date}-{course-slug}/      ← completed courses, moved whole at close
```

Commit message convention: `teacher: {action} — {course-slug}`. Examples: `teacher: course opened — event-driven-architecture`, `teacher: session 4 complete — event-driven-architecture`.

## **File Schemas**

### **README.md — course card**

```markdown
# Course: {Title}

- **Status:** active | closing | archived
- **Opened:** {YYYY-MM-DD}
- **Learning intent:** {the user's own words — what they want to be able to answer or do}
- **Notebook:** {NotebookLM notebook name} ({id})
- **Grounding:** none | {project} — {paths of workspace artifacts used as sources}
- **Episodes:** {produced}/{planned}
- **Default artifacts:** {podcast, flashcards, ...}
```

### **syllabus.md — the approved arc**

```markdown
# Syllabus

| # | Episode | Concepts introduced | Status |
|---|---|---|---|
| 1 | {title} | {concept}, {concept} | pending | produced | consumed |
```

- `produced` — generated and delivered; `consumed` — the user confirmed listening, which the next session verifies before quizzing.
- Extension episodes approved at closing are appended with the same shape.

### **ledger.md — the spacing engine**

```markdown
# Ledger

| Concept | Episode | Last retrieved | History | Strength | Next due |
|---|---|---|---|---|---|
| {concept} | {n} | {YYYY-MM-DD} | ✓✓✗✓ | weak | developing | strong | {YYYY-MM-DD} |
```

- One row per concept. Concepts enter the ledger when their episode is produced, with `Next due` = production date + 2 days.
- `History` is the recall record, oldest first, `✓` correct and `✗` missed, capped at the last six results.

### **quizzes/{n}-{date}.md**

```markdown
# Quiz {n} — {YYYY-MM-DD}

| Concept | Question | Result |
|---|---|---|
| {concept} | {the question asked} | ✓ | ✗ |

**Notes:** {anything the user's answers revealed — misconceptions to address, connections they made}
```

### **episodes/{n}-{episode-slug}.md**

```markdown
# Episode {n} — {Title}

- **Produced:** {YYYY-MM-DD}
- **New concepts:** {list}
- **Review segment:** {concepts woven in for re-exposure, or "none"}
- **Sources:** {each source with its origin — registry, web, or workspace artifact path}
- **Artifacts:** {type: ready | generating | failed}

## Focus prompt

{the approved focus prompt, verbatim}
```

## **Spacing Rules**

The ledger is updated after every quiz and every episode production, by these rules and no others:

- **New concept:** enters the ledger at its episode's production date, due 2 days later, strength `weak`.
- **Correct recall:** multiply the previous interval by 2.5 (2 → 5 → 12 → 30 → 75 days), set `Next due` accordingly.
- **Missed recall:** reset the interval to 2 days AND flag the concept for the next episode's review segment — a miss means re-exposure plus early re-retrieval, not just a shorter clock.
- **Strength bands:** `weak` = missed in either of the last two retrievals; `strong` = three or more consecutive correct AND current interval ≥ 30 days; `developing` = everything between.
- **Quiz selection:** every concept due on or before today, plus the newest consumed episode's concepts — capped at 4 questions, prioritized by weakest strength then longest overdue. Ask open questions that require free recall; multiple-choice tests recognition, which is the weaker signal.

## **Constraints**

- **Only Teacher writes under `teaching/`.** Course state edited by another hand breaks the ledger's integrity — the spacing math assumes Teacher's rules produced every row.
- **The ledger is updated through the Spacing Rules only.** Ad-hoc adjustments ("this feels learned") corrupt the schedule that makes retrieval land at the right moments; the user's results are the only input.
- **Every session that touches course state pulls before reading and commits and pushes after writing** — per `workspace-lifecycle-protocol`. An unpushed ledger update means the next session quizzes from a stale schedule.
- **Workspace project artifacts are read-only source material.** A work-grounded course reads `{project}/` research, docs, and plans as notebook sources; it never modifies them — they belong to the engineering fleet.
