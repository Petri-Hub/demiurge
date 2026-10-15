<h1 align="center">🏺 demiurge</h1>

<br>

<h3 align="center">A meta-harness that creates other agents.<br>An agent whose only job is writing the instructions of the others</h3>

<p align="center">
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude%20Code-D97757?logo=claude&logoColor=white" /> <a href="https://github.com/Petri-Hub/demiurge/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/Petri-Hub/demiurge" /></a>
</p>

<br>

## About

> **TL;DR:** a harness for Claude Code, made of plain markdown, built around one agent that doesn't write code. I call it Demiurge, and its job is to write the instructions of every other agent: their system prompts, the pipelines they follow, the plan templates and the handoff contracts. This is not a framework: it has no versioned interface. The roster in [examples/](examples/) shows what I built for my own work; the installer only links Demiurge and its supporting skills.

## The idea, in two paragraphs

<img alt="You describe the work to Demiurge, the meta-agent, which writes and maintains the harness: agents, pipelines, plan templates and handoffs" src="assets/idea.png" />

**A model computes what comes next from everything that came before:** the system prompt, the skill it loaded, the plan it was handed, the handoff it read. So the quality of what comes out depends on how well that *before* is written, and the real question is what the best possible instructions look like for the work you want out.

**If that is true, what if you had an agent whose only job was to write that *before*?** It would know how to write a system prompt, a pipeline, a plan template or a handoff so that another agent reads it and follows it. Current frontier models are good at following a path, and a pipeline is one: phases, gates and exit conditions, with the model free to adapt inside each phase. That agent is Demiurge, and the harness around it is what it produces.

## Demonstration

You can start with a problem you see in your own workflow. Demiurge asks for the missing details, then works through the agent and pipeline files with you. These examples skip those intermediate steps.

### 📐 Creating a planning agent

Your coding plans keep leaving decisions ambiguous, drifting from the project's architecture, and using different names for the same concepts.

```dotenv
# claude --agent Demiurge

> Create an Architect agent with one planning pipeline. Before it
  delivers a plan, have three independent agents review it: one for
  ambiguity and inconsistent terminology, one for architectural
  drift, and one for risks covered by the OWASP Top 10.
```

```dotenv
# claude --agent Architect

> Plan a password reset flow for this application.
```

### 👤 Creating a customer agent

Your onboarding screens feel hard to use, and you want to see where a first-time customer gets stuck.

```dotenv
# claude --agent Demiurge

> Create a Customer agent that opens my running application in a
  browser without any prior explanation of its screens. Have it
  rate each screen against explicit usability criteria and report
  each issue with the violated principle and a suggested improvement.
```

```dotenv
# claude --agent Customer

> Go through the customer onboarding flow from the first visit to
  completion. Find the steps that are confusing or difficult to
  complete, and suggest changes that could improve onboarding
  completion.
```

### 🔧 Refining an existing agent

After a few runs, Architect's plans start covering work you didn't ask for.

```dotenv
# claude --agent Demiurge

> Architect's plans keep expanding beyond my request. Update its
  planning pipeline so that, before writing a plan, it produces a
  short scope brief with the goal, proposed work, explicit exclusions,
  and assumptions. Have it stop and wait for my approval or changes.
  Then it can write the plan within the agreed scope.
```

```dotenv
# claude --agent Architect

> Plan a CSV export for the billing dashboard.
```

Every future task you give these agents starts with the workflow, criteria, and review rigor you defined in their files.

## How it works

The hard part was finding a structure that lets current models expand the work inside a phase—read more files, inspect a hundred screens, produce a larger artifact—without skipping the phases that follow. I arrived at this shape through almost four months of daily use and repeated prompt revisions. Demiurge has changed more than any other agent in that time.

<img alt="An agent contains identity, knowledge, communication, tools and skills, constraints and guidelines, references, and pipeline routing. It loads a pipeline skill with phases, each defining a goal, actions, things to avoid, and exit conditions. Demiurge maintains this structure, including its own agent and pipelines." src="assets/agent-anatomy.png" />

Want to see some examples? Check agents and pipelines that I've produced for my roster, working mainly in a fintech environment:

- [Architect](examples/architect/Architect.md) — the agent that writes technical plans.
- [Architect Planning Pipeline](examples/architect/skills/pipeline-architect-deep-planning/SKILL.md) — the pipeline it plans with.
- [Architect Plan Reviewer](examples/architect-plan-reviewer/Architect-Plan-Reviewer.md) — the agent that checks plans for ambiguity.

Check other parts of the roster, from main utilities to main agents:

- [Orchestrator](examples/orchestrator/Orchestrator.md) — the agent that dispatches specialists and synthesizes results.
- [Librarian](examples/librarian/Librarian.md) — the agent that researches docs for other agents.
- [Teacher](examples/teacher/Teacher.md) — the agent that turns topics into NotebookLM audio overviews.
- [Crawler](examples/crawler/Crawler.md) — the agent that maps running web apps into view records.

And some pipelines I've created over time that you may be interested in:

- [Architect Planning Pipeline](examples/architect/skills/pipeline-architect-deep-planning/SKILL.md) — the pipeline from request to reviewed plan.
- [Teacher Study Session](examples/teacher/skills/pipeline-teacher-study-session/SKILL.md) — the pipeline from topic to podcast.
- [Executor Execution](examples/executor/skills/pipeline-executor-execution/SKILL.md) — the pipeline from plan to tested code.
- [Crawler Direct Crawl](examples/crawler/skills/pipeline-crawler-direct-crawl/SKILL.md) — the pipeline from live app to view records.

## Agent and pipeline structure

The sections below show how an agent prompt and its pipeline are structured, and what each part contributes. The snippets are shortened from [Quality Engineer](examples/quality-engineer/Quality-Engineer.md) and its [Web Audit pipeline](examples/quality-engineer/skills/pipeline-quality-engineer-web-audit/SKILL.md), applied to an imaginary onboarding audit.

> Imagine asking Quality Engineer to audit customer onboarding on a running staging site: account creation, email verification, company setup, and confirmation. It inspects each screen against stated criteria and leaves findings another engineer can reproduce.

### Agent

The agent file stays loaded throughout the run. It defines the agent's judgment, its tools, and which pipeline to load per request.

#### Identity

Identity gives the agent a job and a point of view. Quality Engineer is an independent reviewer: it reports failures it can demonstrate with evidence, and never redesigns the screens it inspects.

```md
## Identity

You are Quality Engineer. Judge application quality independently
and report what you observe with evidence.

You own the tests and findings, not the application under test.
Audit against stated criteria; leave fixes to the implementation agent.
```

#### Communication

Communication places the agent among the others. Quality Engineer takes requests directly or from an Orchestrator, may call on Librarian for documentation research, and never invokes agents that would implement the fixes.

```md
## Communication

### Who can invoke you
- The user directly, or Orchestrator as part of a workflow.

### Who you can invoke
- Librarian, for documentation research needed by the audit.
- Explore, for broad, read-only codebase searches.

### Who you never invoke
- Specialist agents that would implement the fixes.
```

#### Tools

Tools lists what the agent may use and when. Specialized skills carry the syntax and pitfalls that working from memory gets wrong, so the agent loads them before touching the tools they cover.

```md
## Tools

| Skill | When to load |
|---|---|
| Agent Browser | Before interacting with a running web app. |
| Web Audit Specialization | Before running any audit engine. |
```

#### Constraints

Constraints protect the judgment. Quality Engineer must capture what happened before calling something a defect, and must say exactly where its coverage ends when permissions block a check.

```md
## Constraints & Guidelines

- Never modify application code. Record defects for someone else to fix.
- Never claim a pass or a failure you did not observe.
- If permissions prevent a check, record it as a coverage gap.
```

#### Pipeline routing

The same agent handles different requests without mixing their steps. The route is declared in the agent file, while the steps live in separate skills.

```md
## Pipeline

| Request | Skill to load |
|---|---|
| Create automated tests | `pipeline-quality-engineer-test-authoring` |
| Run existing tests | `pipeline-quality-engineer-test-execution` |
| Audit a running web app | `pipeline-quality-engineer-web-audit` |
```

#### References

References name the books and ideas behind the agent's judgment, so its criteria trace back to something beyond the prompt.

```md
## References

- **Lessons Learned in Software Testing** — test bugs vs product bugs.
- **Thinking, Fast and Slow** — classify first, judge against criteria.
```

### Pipeline

For the onboarding request, Quality Engineer loads Web Audit. That file says what to produce, which criteria to apply, and how to move through the work.

#### Purpose

Purpose states the deliverable: an evidence-backed audit record. It does not create executable tests or decide whether a limitation is acceptable.

```md
## Purpose

Audit a running web application against stated criteria.
Produce an evidence-backed record of findings and coverage.
Do not write executable tests or change the application.
```

#### Knowledge

Knowledge carries the audit criteria, so “check the onboarding flow” means checking error recovery, copy consistency, and layout — not giving each screen a vague score. A concern can be switched off per run; interaction-gated checks run only when permitted.

```md
## Knowledge

| Concern | What to check |
|---|---|
| Forms & error states | Can someone understand and recover from an error? |
| Content & copy | Does the same concept keep the same name? |
| Visual / responsive | Do controls remain usable at narrow widths? |
```

#### Flow

Web Audit follows `Intake → Audit → Report`. Intake resolves target, scope, and permissions, and stops if the site can't be reached. Audit walks each state one at a time. Report finalizes the record, naming both coverage and gaps.

#### Phases

Each phase has a goal, actions, things to avoid, and exit conditions. The structure lets the agent expand work inside a phase without skipping the phases that follow:

```md
### Phase 2 — Audit

**Goal**
Write evidence-backed findings for each onboarding state before
moving to the next one.

**Actions**
- Open the next state in the worklist at the configured viewport.
- Check the enabled criteria: labels, error recovery, copy,
  accessibility, and layout at the selected screen sizes.
- Save each finding with its criterion, severity, steps, and evidence.
- Mark the state audited and add any newly discovered states.

**Avoid**
- Don't submit forms if this run does not permit it; the audit must
  stay within its agreed permissions.
- Don't keep findings only in memory; a long run can lose them.

**Exit when:**
- [ ] Every state is audited or skipped with a reason.
- [ ] Each audited state has its findings and evidence saved.
```

#### Constraints

The pipeline restates its boundaries where they matter most: at the point of judgment.

```md
## Constraints

- Report conformance to criteria, never product-acceptability.
```

A hypothetical finding: an expired verification code produces “Something went wrong” with no way to request a new one. The record carries the screen, steps, criterion, and evidence, so whoever fixes onboarding never guesses what the auditor saw.

## Installation

```bash
# Installing.
curl -fsSL https://github.com/Petri-Hub/demiurge/raw/main/install.sh | bash
```

```bash
# Uninstalling.
curl -fsSL https://github.com/Petri-Hub/demiurge/raw/main/uninstall.sh | bash
```

## When it is worth it

When a mistake is expensive: fintech, distributed systems, anything mission critical. You trade tokens and time for review before and after the work, so you can stay away from the keyboard and still trust what comes back. For everything else, plain Claude Code with a few skills is faster and cheaper.

## License

MIT, in [`LICENSE.md`](LICENSE.md).
