<h1 align="center">🧩 agenkit</h1>

<br>

<h3 align="center">15 agents and 58 skills for Claude Code.<br>Plain markdown, installed with symlinks</h3>

<p align="center">
  <a href="https://github.com/Petri-Hub/agenkit/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/Petri-Hub/agenkit" /></a> <a href="LICENSE.md"><img alt="License" src="https://img.shields.io/github/license/Petri-Hub/agenkit" /></a>
</p>

<br>

## About

> **TL;DR:** a set of specialized Claude Code agents instead of one long conversation. An Orchestrator proposes the next step and dispatches an Architect, an Executor, reviewers and a few others, each with its own model, tools and skills. I built it for my own daily work and this is the generic version, with every project-specific example replaced by a fictional library app called `shelf`. There is nothing to build: it is `.md` files and one install script.

## How it works

```
                          you
                           │
                           ▼
                     Orchestrator
                           │
      ┌──────────┬─────────┼──────────┬───────────┐
      ▼          ▼         ▼          ▼           ▼
  Architect   Executor  Crawler  Quality-Engineer  Scribe
      │          │
      ├─ Plan reviewer      ├─ Quality reviewer
      └─ Rules reviewer     ├─ Security reviewer
                            ├─ Test reviewer
                            └─ Refinement reviewer

  Librarian   documentation research, called by Architect, Executor and others
  Teacher     courses and spaced repetition, on its own
  God         writes and maintains the agents and skills themselves
```

Agents don't share memory. What one learns, the next reads from a file in `.workspace/`, a git repository that lives next to your project and holds plans, handoffs, audits and crawl records. Each agent knows which folders it may write to.

## The three decisions that mattered

**📄 Handoffs are files, not conversation.** A sub-agent only sees what it is given, so each dispatch is a typed markdown file with a payload and a validation block, and each response is another file. The receiver reads it from disk and the trail stays there for debugging.

**🔒 Every agent writes to its own folders.** Librarian only writes `docs/`, Scribe only `compositions/`, and Architect never writes research. Reviews and plans stay separate from the work they judge, which is the point of having a second agent look at it.

**🧪 The agent that writes is not the one that reviews.** Executor writes the code and four reviewers check it afterwards, each on one concern: quality, security, tests, and whether the code honors the plan's behavioral contracts. Most reviewers run on Sonnet, the planners and the Executor on Opus.

## Install

```sh
git clone https://github.com/Petri-Hub/agenkit.git
cd agenkit
./install.sh
```

It symlinks every agent into `~/.claude/agents` and every skill into `~/.claude/skills`, so a `git pull` updates them. Anything already at a destination is moved to `~/.claude/.agenkit-backup/`, never overwritten. `./install.sh --uninstall` removes only the links it created.

Agents read their skills from `~/.claude/skills`, so allow that path in `~/.claude/settings.json`:

```json
{ "permissions": { "allow": ["Read(~/.claude/skills/**)"] } }
```

Then start Claude Code with the Orchestrator as the main agent:

```sh
claude --agent Orchestrator
```

## What's inside

```sh
├── agents          # 15 agents, one file each
├── skills          # 58 skills, one folder each, grouped by prefix
│   ├── pipeline-*        # 30 · the flow each agent follows, phase by phase
│   ├── forge-*           # 7  · templates God uses to write agents, pipelines and plans
│   ├── workspace-*       # 7  · the .workspace/ layout, naming and git lifecycle
│   ├── handoff-*         # 6  · what each reviewer is handed
│   ├── specialization-*  # 6  · tools: tmux, Maestro, Slidev, Lighthouse and axe, agent-browser, frontend design
│   └── teacher-*         # 2  · course state and source ranking
├── install.sh      # symlink installer, with --uninstall
└── LICENSE.md
```

## Before you use it

Five agents declare an MCP server in their frontmatter, and Claude Code starts it through `npx`, `uvx` or a local binary:

| Agent | MCP server | Needs |
|---|---|---|
| Crawler | Playwright | Node |
| Executor, Architect, Quality-Engineer | next-devtools | Node |
| Architect | Sentrux | the `sentrux` binary |
| Teacher | NotebookLM | `uv` |

If you don't use an agent, its server never starts. Models and effort are set per agent in the frontmatter, so lowering the Opus agents to Sonnet is a one-line change each, at the cost of weaker plans.

This is not a framework. There is no versioned interface, and the agents assume each other's file formats, so expect to edit the markdown to fit your project. The examples inside the skills use `shelf`, a library lending app, and the Java-style module layout in some of them is only an example.

## License

MIT, in [`LICENSE.md`](LICENSE.md).
