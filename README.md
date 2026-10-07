<h1 align="center">🏺 demiurge</h1>

<br>

<h3 align="center">A meta-harness that creates other agents.<br>An agent whose only job is writing the instructions of the others</h3>

<p align="center">
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude%20Code-D97757?logo=claude&logoColor=white" /> <a href="https://github.com/Petri-Hub/demiurge/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/Petri-Hub/demiurge" /></a>
</p>

<br>

## About

> **TL;DR:** a harness for Claude Code, made of plain markdown, built around one agent that doesn't write code. I call it God, and its job is to write the instructions of every other agent: their system prompts, the pipelines they follow, the plan templates and the handoff contracts. This is not a framework: it has no versioned interface, and the roster around it was built for my own work, so expect to edit the markdown to fit yours.

## The idea, in two paragraphs

<img alt="You describe the work to God, the meta-agent, which writes and maintains the harness: agents, pipelines, plan templates and handoffs" src="assets/idea.png" />

**A model computes what comes next from everything that came before:** the system prompt, the skill it loaded, the plan it was handed, the handoff it read. So the quality of what comes out depends on how well that *before* is written, and the real question is what the best possible instructions look like for the work you want out.

**If that is true, what if you had an agent whose only job was to write that *before*?** It would know how to write a system prompt, a pipeline, a plan template or a handoff so that another agent reads it and follows it. Current frontier models are good at following a path, and a pipeline is one: phases, gates and exit conditions, with the model free to adapt inside each phase. That agent is God, and the harness around it is what it produces.

## Don't use this

> **Don't use these agents. Use the one that makes them.** This harness was built around my work: my agents, my HITL gates, my way of reviewing. The piece worth taking is **God**, the agent that creates the others, together with the forge skills.

I built it for a financial system, where I needed to read and understand what was going to be built before it was built. That is why there is an Architect whose plan I review, and an Executor whose code can go through four reviewers before it reaches me. There is a Scribe for writing anything from a post-mortem to a simple integration report, and a Crawler that gathers context from other websites and maps their features before I recreate the product. Those are my needs. Yours are different, and you would spend your time fighting agents shaped around mine.

## How to use this

Take **God**, the `pipeline-god-*` skills, the `forge-*` skills and the three `workspace-*` skills God uses to record its own notes. Leave the rest, or read it as examples of what God produces.

Start Claude Code with `claude --agent God` and tell it what you need: an agent, a pipeline, a plan template, a handoff contract or a rule system. It interviews you first, writes the draft, then attacks its own draft against the forge checklist before handing it over. God needs the Context7 MCP server configured in Claude Code.

`install.sh` links the whole kit into `~/.claude`. To take only the God subset, link those folders by hand.

```sh
git clone https://github.com/Petri-Hub/demiurge.git && cd demiurge && ./install.sh
```

Agents read their skills from `~/.claude/skills`, so allow `Read(~/.claude/skills/**)` in your `settings.json`. `./uninstall.sh` removes only the links it created. It does not restore anything `install.sh` moved to `~/.claude/.demiurge-backup/`.

## How it works

The Orchestrator is the entry point: it proposes the next step, dispatches the specialists and stops at the gates. The Architect's plan is attacked by two reviewers before you read it. The Executor's code can be attacked by four, each switched on per run: quality, security, tests, and whether the code honors the plan's behavioral contracts. God and the Teacher you call directly.

<img alt="Organogram: You reach God, the Orchestrator and the Teacher. The Orchestrator dispatches the Architect, the Executor and on-demand specialists. Two reviewers attack the Architect's plan and four attack the Executor's code" src="assets/roster.png" />

## Glossary

| Entity | What it is |
|---|---|
| **Agent** | A markdown file with a system prompt, a model, a tool list and the agents it is allowed to call. Lives in `agents/` |
| **Skill** | A markdown file an agent loads on demand instead of carrying it in its prompt. Lives in `skills/<name>/SKILL.md` |
| **Pipeline** | A skill describing one execution flow: phases, each with a goal, actions, things to avoid and exit conditions |
| **Forge skill** | The template and the quality checklist for one kind of artifact. God's reference material |
| **Plan template** | What the Architect fills in to write a plan. Either catalog-driven, for domain features, or open-structure, for tooling and infrastructure |
| **Handoff** | A typed markdown file one agent writes for another, with a purpose, a context, a payload table and a validation block. The receiver reads it from disk |
| **Workspace** | `.workspace/`, a git repository beside your project where plans, handoffs, research, docs, audits, crawls and evolution notes live. Each agent knows which folders it may write to |
| **HITL gate** | A point where an agent stops and asks you. The Orchestrator runs at one of three levels: Supervised, Guided (the default) or Autonomous |
| **Behavioral contract** | A numbered, testable statement in a plan, such as BC-01. The Refinement reviewer checks the code and the tests against them |
| **Evolution note** | A short note an agent writes at the end of a run about friction in its own instructions. God reviews them in batches |
| **Rule system** | `.claude/rules/` plus the root `CLAUDE.md` that orients the agents, in three tiers: foundation, concerns and components |

Skills are grouped by prefix: `pipeline-` for flows, `forge-` for templates, `workspace-` for layout, naming and git lifecycle, `handoff-` for what each reviewer receives, `specialization-` for tools (tmux, Maestro, Slidev, Lighthouse and axe, agent-browser, frontend design) and `teacher-` for course state and source ranking.

## When it is worth it

It is worth it when a mistake is expensive: fintech, distributed systems, anything mission critical. You trade tokens and time for review before and after the work. A plan is not one model's first draft, it gets attacked by other agents. Code is not only implemented, it can come back with the findings of four reviewers. The point is to stay away from the keyboard and still deliver something you can trust.

If your work is not critical, it is probably not worth the cost. Plain Claude Code with a few skills is faster and cheaper, and for most work that is the better trade.

## What it produced

I used this day to day for almost four months in 2026, in a fintech environment, and the agents produced 149 plan files in 120 feature workspaces, 601 handoffs, 27 audits with 261 findings and 3,254 markdown files, counting my copy of the workspace. The version published here has 15 agents and 58 skills.

## License

MIT, in [`LICENSE.md`](LICENSE.md).
