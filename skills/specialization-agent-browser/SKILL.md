---
name: specialization-agent-browser
description: "Driving a real browser from the shell with the agent-browser CLI — when to reach for it, how to isolate a run's session from every other agent's, how screenshots come back, and where the version-matched command reference lives. Load when a change has to be proven against a running UI."
user-invocable: false
---

# Agent Browser

`agent-browser` is a browser automation CLI built for agents — Chrome over CDP, accessibility-tree snapshots, and compact `@eN` element refs instead of raw DOM. It is a global binary invoked through `Bash`, so it costs nothing until the moment a run actually needs a browser.

## The command reference lives in the CLI

Do not work from memory or from this file for command syntax. The CLI ships its own skills, always matched to the installed version:

```bash
agent-browser skills get core --full     # read this before running any command
agent-browser skills list                # specialized skills, listed below
```

`core` covers the snapshot-and-ref workflow, navigation, interaction, extraction, screenshots, tabs, forms, auth, and waiting. Read it once per run that uses a browser, then drive from it.

Specialized skills exist for narrower work — load one only when it applies:

| Skill | For |
|---|---|
| `dogfood` | Systematically exploring an app to find bugs and UX problems |
| `derive-client` | Reverse-engineering a site's internal API by recording traffic |
| `electron` | Electron desktop apps — VS Code, Slack, Discord, Figma |
| `slack` | Slack workspaces |
| `agentcore` · `vercel-sandbox` | Cloud browsers on AWS Bedrock AgentCore or Vercel Sandbox microVMs |

## Isolate the session, always

From inside one run you cannot see whether other agents are driving browsers alongside you. Isolate unconditionally rather than assuming you are alone — parallel runs that share a session collapse onto one browser and corrupt each other's navigation and screenshots.

Derive a stable id from the working tree and export it once, so every later command inherits it:

```bash
export AGENT_BROWSER_SESSION="$(agent-browser session id --scope worktree --prefix <run-or-feature>)"
```

`--namespace` isolates the daemon sockets and restore-state directories on top of that; reach for it when a run must not share daemon state at all.

**Close only what you opened.** `agent-browser close --all` terminates every session on the machine, including other agents' work mid-flight, and they get no signal beyond their next command failing. Plain `close` ends yours.

## Screenshots come back as files

Screenshots are written to disk and the command returns the path. `Read` that path directly — the model is multimodal and needs no separate vision step. Save any screenshot that serves as evidence into the run's own evidence location rather than a temp path that later gets cleaned up.

## Before the first command

`agent-browser doctor` runs the binary, Chrome, and daemon checks and is the fastest way to tell a broken environment from a broken application. If Chrome is missing, `agent-browser install` provisions the bundled one. A crash here is a blocker, never a silent pass — surface it rather than reporting an unverified result as verified.

## Gotchas

- **A single-page app can paint after the command returns.** Wait for a stable anchor on the target view before capturing or asserting, rather than trusting that navigation finished.
- **One URL per invocation.** Batching pages into a single command is unsupported; loop instead.
- **`read` is cheaper than a snapshot for prose.** When the goal is consuming documentation or text rather than driving a UI, `agent-browser read <url>` skips Chrome entirely and returns markdown.
- **Credentials never go in a command.** Take them from the environment or the run's provided auth, and use the CLI's auth profiles to persist a login across runs.

## References

- [agent-browser](https://agent-browser.dev) — documentation
- [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) — source and skills
