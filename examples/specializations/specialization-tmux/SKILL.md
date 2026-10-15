---
name: specialization-tmux
description: 'Use when a task requires starting, monitoring, or stopping a long-lived process — dev servers, APIs, watchers, databases, build daemons, log tails, REPLs, or any command that does not exit on its own. These run detached in tmux so the agent''s shell never blocks. Do NOT use for one-shot commands that return (single test/build/lint runs, installs, git, curl, file ops) — those run directly in the shell so their exit code is preserved. Trigger phrases: "start the server", "run the backend", "keep the dev server running", "check if it''s running", "restart the API", "show me the logs", "stop the dev server".'
user-invocable: false
---

# Long-Lived Process Management with tmux

## The Cost of Foreground Execution

When an agent runs a long-lived command (`npm run dev`, `python manage.py runserver`, `docker compose up`, a watcher, a database) directly in its shell, the command does not return. The shell blocks waiting for a process that runs forever. From that point on:

- **Every subsequent tool call hangs or times out** — the agent cannot execute anything else because its only shell is occupied by a process that never exits.
- **Server output buries prior context** — startup logs, request logs, and warnings scroll into the buffer, pushing earlier work out of view.
- **The session may time out and kill the process mid-task** — the user returns to a frozen agent with no recoverable state.
- **There is no way to inspect, restart, or stop the process cleanly** — the agent has lost control of the thing it started.

This is the failure mode tmux exists to prevent. A detached tmux session runs the process in the background, survives across agent turns, keeps its own scrollback for inspection, and leaves the agent's shell free to run the next command. **Every long-lived process goes in a tmux session. No exceptions.**

## When to Use tmux (and When Not To)

**Decision rule — does this command return on its own?**

- **Yes (one-shot) → run it directly in the shell.** `ls`, `git`, `npm install`, a single `npm test` / `pytest` run, builds, lint/typecheck, migrations, `curl`. These return an exit code — the primary success/failure signal. Wrapping them in tmux discards that code and forces log-scraping for output the shell would have handed you directly. That a one-shot command blocks until it finishes is the feature, not the problem.
- **No (long-lived) → tmux session.** Dev servers, backends/frontends, `docker compose up`, watchers and file-watch test runners (`jest --watch`, `vitest`), `tail -f`, REPLs, build daemons, message consumers. These run until stopped — detach them so the shell stays free.

## Session Naming

Every session name answers three questions in one compound slug: **whose work, what runs, why it exists.** Each layer narrows the scope, and the trailing context keeps the name task-scoped — so no agent sees a session and mistakes it for a standing reusable service. This compound is the `<session>` placeholder used throughout the rest of this skill.

**Format:** `<product>-<service>-<context>`

- `<product>` — the product or platform area this work belongs to: `shelf`, `catalog`, `infra`, `crawl`. Sessions cluster by product in `list-sessions`, so one product's processes are visible together at a glance.
- `<service>` — what is running: `api`, `web`, `db`, `worker`, `proxy`, `cache`. Short tokens.
- `<context>` — why this session exists: the feature, the investigation, the task. This is the layer that marks the session task-scoped and disposable. Make it specific enough to be unique within the product+service. When parallel agents could share the same product+service+context, fold a port or short id into the context — `shelf-api-holds-3032` — rather than adding a fourth slot.

**Good names:**

| Name | Why it works |
|---|---|
| `shelf-api-holds-testing` | Product (shelf) + service (api) + context (holds testing). Reads as "the holds-testing session on shelf's API," not a standing API. |
| `shelf-api-new-search-feature` | Same product, same service, different context — both can run in parallel with the earlier session and neither collides. |
| `catalog-db-reindex-logs` | Product (catalog) + service (db) + context (reindex log tail). Clearly a task-scoped log tail, not a database to connect to. |
| `infra-proxy-mitm-debug` | Non-product work is still namespaced — `infra` is a platform area standing in for product. |

**Bad names:** `backend`, `api`, `shelf-api`. A bare service (`api`) or a product+service with no context (`shelf-api`) both read as standing services and invite false reuse — another agent sees `shelf-api` and assumes "shelf's API is up, let me hit it," when the session actually exists for a specific task that may be about to end. The context layer is what prevents this; never omit it.

**Reuse rule:** Never assume a session is reusable from its name alone. Before reusing a running session, run `tmux list-sessions` and `tmux capture-pane -t <session> -p -S -50` to confirm what is actually running and that it belongs to your current work.

## Lifecycle

Every long-lived process follows the same pattern: **list → start → verify → monitor → stop.** Skip a step and you either duplicate a running session or report a process as "started" that actually crashed on boot.

### Step 0 — List before you act

Before starting anything, check what is already running. A session for your work may already exist from a prior turn.

```bash
tmux list-sessions
```

If a session matching your work-context already exists, `capture-pane` it (see Monitor) to see its state before deciding to reuse, restart, or leave it.

### Start

```bash
tmux new-session -d -s <session> -c <workdir> '<command>'
```

- `-d` — detach immediately; the command does not block.
- `-s <session>` — the session name, per the naming scheme above.
- `-c <workdir>` — starting directory; prefer this over embedding `cd /path &&` in the command (avoids quoting issues).
- `'<command>'` — the command to run, quoted as a single string.

**Enable `remain-on-exit` on every new session — this is mandatory, not optional:**

```bash
tmux new-session -d -s <session> -c <workdir> '<command>'
tmux set-option -t <session> remain-on-exit on
```

By default, when a command exits (including a crash), tmux destroys the session — so `capture-pane` finds nothing at the exact moment you need the crash output. With `remain-on-exit`, a dead session keeps its full scrollback for inspection. Recreate it with the restart pattern in Stop and Restart once you have read the logs.

### Verify

Never report a process as "started" without confirming it actually started. Give it time to boot, then check its output.

```bash
# 1. Start in background (with remain-on-exit, per above)

# 2. Give it time to boot
sleep 5

# 3. Check logs for success/error markers
tmux capture-pane -t <session> -p -S -50 | grep -qi "ready\|listening\|started" && echo "OK" || echo "CHECK LOGS"

# 4. For a web server, verify via HTTP
curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>/health
```

If step 3 or 4 fails, read the full recent output and diagnose before retrying — never assume the process crashed without checking logs first:

```bash
tmux capture-pane -t <session> -p -S -200
```

### Monitor and Search

Read what a session is doing without attaching to it.

```bash
# Currently visible pane content
tmux capture-pane -t <session> -p

# Last 100 lines of scrollback
tmux capture-pane -t <session> -p -S -100

# Entire scrollback history
tmux capture-pane -t <session> -p -S -
```

Search the output for specific conditions:

```bash
# Did the server start?
tmux capture-pane -t <session> -p -S -200 | grep -i "listening\|ready\|started"

# Any errors?
tmux capture-pane -t <session> -p -S -200 | grep -i "error\|exception\|traceback"

# Bound to the expected port?
tmux capture-pane -t <session> -p -S -200 | grep -i "<port>"
```

### Stop and Restart

**Interrupt the command but keep the session (for restarting in place):**
```bash
tmux send-keys -t <session> C-c
```

**Kill a session entirely:**
```bash
tmux kill-session -t <session>
```

**Restart cleanly (kill + recreate):**
```bash
tmux kill-session -t <session> 2>/dev/null
tmux new-session -d -s <session> -c <workdir> '<command>'
tmux set-option -t <session> remain-on-exit on
```

### Send Input to a Running Process

For interactive prompts, REPLs, or tools that accept commands while running (e.g. `nodemon`'s `rs` to restart).

```bash
tmux send-keys -t <session> "rs" Enter     # send a line + Enter
tmux send-keys -t <session> C-c            # send Ctrl+C
tmux send-keys -t <session> "y" Enter      # answer a y/n prompt
tmux send-keys -t <session> Down Enter     # navigate a menu
```

### Run Multiple Services

Give each service its own named session. Logs stay separate and each is manageable independently.

```bash
tmux new-session -d -s shelf-api-holds      -c /app/shelf/api  'npm run dev'
tmux new-session -d -s shelf-web-holds      -c /app/shelf/web  'npm run dev'
tmux new-session -d -s shelf-db-holds-logs  -c /app/shelf      'docker logs -f shelf-postgres'
```

Batch-check all of them:

```bash
for s in shelf-api-holds shelf-web-holds shelf-db-holds-logs; do
  echo "=== $s ==="
  tmux capture-pane -t "$s" -p -S -20
done
```

## Reference

| Goal | Command |
|---|---|
| List all sessions | `tmux list-sessions` |
| Start a long-lived process | `tmux new-session -d -s <session> -c <workdir> '<cmd>'` |
| Retain logs on crash | `tmux set-option -t <session> remain-on-exit on` |
| Check if a session exists | `tmux has-session -t <session> 2>/dev/null` |
| Read recent output | `tmux capture-pane -t <session> -p -S -100` |
| Read full scrollback | `tmux capture-pane -t <session> -p -S -` |
| Search for errors | `tmux capture-pane -t <session> -p -S -200 \| grep -i "error"` |
| Send input/command | `tmux send-keys -t <session> "<text>" Enter` |
| Interrupt (Ctrl+C) | `tmux send-keys -t <session> C-c` |
| Stop a session | `tmux kill-session -t <session>` |
| Restart | `tmux kill-session -t <name> 2>/dev/null; tmux new-session -d -s <name> -c <dir> '<cmd>'` |

## Hard Rules

1. **Every long-lived process goes in a tmux session** — running a server/watcher/daemon in the foreground blocks the shell, loses context, and leaves no way to inspect or stop the process cleanly.
2. **One-shot commands run in the plain shell** — wrapping them in tmux discards the exit code (your primary success/failure signal) and forces log-scraping for output the shell would have returned directly.
3. **Enable `remain-on-exit` on every new session** — without it, a process that crashes on boot takes its scrollback with it, leaving nothing to diagnose at the moment you most need it.
4. **List before you start** — run `tmux list-sessions` before `new-session` so you reuse an existing session for your work instead of creating a duplicate.
5. **Verify before you report** — after starting, `capture-pane` and check for success/error markers before claiming the process is running. A boot crash looks identical to a successful start until you read the logs.
6. **Name sessions with all three layers — product, service, context** — a bare service (`api`) or product+service without context (`shelf-api`) reads as a standing service and invites false reuse; the context layer is what marks the session task-scoped and disposable.
7. **Kill only your own sessions, by name** — use `kill-session -t <session>`. Never use `tmux kill-server` — it destroys every session on the machine, including the user's own work and sessions from other agents, worktrees, and devcontainers.
