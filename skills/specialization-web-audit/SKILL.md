---
name: specialization-web-audit
description: "Web quality audit tooling mechanics — running Lighthouse via the CLI and parsing the LHR, running axe-core through the agent-browser accessibility audit for WCAG checks, gathering responsive, console, and network evidence with agent-browser, and the setup and gotchas that make each engine actually produce usable output against a running web app."
user-invocable: false
---

# Web Audit Tooling

## Overview

A web audit runs three engines over a running application, in one pass, per URL:

| Engine | Produces | How it runs |
|---|---|---|
| **Lighthouse** | Performance, best-practices, SEO, and a floor of accessibility — as scored JSON | `npx lighthouse` via Bash |
| **axe-core** | Deep WCAG accessibility violations with element selectors | `agent-browser a11y` via Bash |
| **Agent Browser** | Responsive screenshots, console errors, failed requests | `agent-browser` via Bash |

They are consumed together — an audit that runs Lighthouse also runs the accessibility audit and drives the browser for the same URL. This skill is the *how*: the commands, the output shapes, and the setup that makes them work.

> Load `specialization-agent-browser` before the first browser command — it carries the session-isolation contract and points at the CLI's own version-matched command reference.

> **Boundary.** This skill holds mechanics only. The *criteria and thresholds* (which CWV values pass, which WCAG level) live in the `pipeline-quality-engineer-web-audit` Knowledge section. The *verdict and severity vocabulary* live in `workspace-audit-protocol`. Raw output from every engine is written into the finding's `evidence/` folder, per that protocol. Do not restate criteria here.

## The evidence loop

For each URL in scope, at the resolved depth:

1. Run Lighthouse → save the LHR JSON into `evidence/`
2. Run `agent-browser a11y --json` → save the violations JSON into `evidence/`
3. Capture screenshots at the required breakpoints — written straight into `evidence/` by passing a path — and read the console → save into `evidence/`
4. Move to the next URL — Lighthouse and the accessibility audit both run **one URL per invocation**

---

## Lighthouse

### Invocation

```bash
npx lighthouse "https://target/route" \
  --output=json \
  --output-path=./lhr.json \
  --only-categories=performance,accessibility,best-practices,seo \
  --chrome-flags="--headless=new --no-sandbox" \
  --quiet
```

- `--only-categories` — pass just the instrumented concerns left on for this audit. Dropping a category skips its work entirely.
- One URL per run. Lighthouse audits a single page; loop over routes, saving one LHR per route.
- `--output=json` is the machine-readable form. Add `--output=html` alongside only when a human-readable artifact is wanted too — the JSON is what gets parsed.

### Reading the LHR

The result object (the "LHR") carries category scores (0–1) and individual audit results:

| Signal | Where in the LHR |
|---|---|
| Category score | `categories.<id>.score` — e.g. `categories.performance.score` |
| Largest Contentful Paint | `audits['largest-contentful-paint'].numericValue` (ms) |
| Cumulative Layout Shift | `audits['cumulative-layout-shift'].numericValue` |
| Total Blocking Time | `audits['total-blocking-time'].numericValue` (ms) |
| A failing specific audit | `audits['<id>'].score === 0` with `.title` and `.description` |

> **INP is field data, not lab.** Lighthouse's lab run does not measure INP — it reports **Total Blocking Time** as the responsiveness proxy. Treat TBT as the lab stand-in; genuine INP needs real user interaction (CrUX/field data), which a synthetic audit does not have. Do not report an "INP" number pulled from a lab LHR — it isn't there.

Extract the fields you need with a small `jq` or Node read of the saved `lhr.json`; keep the full LHR in `evidence/` as the raw proof.

---

## axe-core

Lighthouse's accessibility score is a floor. axe-core is the real WCAG check — it returns each violation with its rule id, impact, and the exact DOM selectors. It is built into agent-browser and runs in the same session as navigation, so it inherits the page's authentication directly.

### The audit

Run it against the current page — or pass a URL to navigate first:

```bash
agent-browser a11y --tags wcag2a,wcag2aa,wcag21a,wcag21aa,wcag22aa --json
```

- `--tags` — the axe rule set, comma-separated. The set above is the AA target. Drop tags to narrow; add `best-practice` to widen beyond WCAG.
- `--selector <css>` — scope the scan to a subtree (e.g. `#main`, the table, the form) when a region needs isolating.
- `--json` — the structured violations payload; write it straight into the finding's `evidence/`.

The audit runs offline against the page's frame tree and merges results without touching a page-provided `window.axe`, so it holds under strict CSP and iframe violations keep their frame selector paths.

> **One URL per run, and wait for the view first.** The audit measures the current page; loop over routes. On a client-rendered route, wait for a stable anchor before auditing (see Authenticated & SPA runs) — auditing before the view paints reports violations for a screen that isn't there yet.

### The output

Each entry in the audit's `violations[]` carries:

| Field | Use |
|---|---|
| `id` | The axe rule, e.g. `color-contrast`, `label`, `image-alt`, `button-name` |
| `impact` | `critical` / `serious` / `moderate` / `minor` — an input to severity, not the final severity |
| `description` / `help` / `helpUrl` | Plain-language description and the Deque reference |
| `tags` | The WCAG tags the rule maps to — use these to cite the criterion in the finding |
| `nodes[].target` | The CSS selector(s) of the offending element — the locator for the finding |
| `nodes[].html` | The offending element's markup |
| `nodes[].failureSummary` | What specifically failed on that node |

Save the whole violations JSON into the finding's `evidence/`; the `target` selector is what makes the finding reconstructable.

---

## Authenticated & SPA runs

**Authenticated areas.** The accessibility audit and every screenshot run inside the run's browser session, so they inherit whatever authentication that session holds. Reach logged-in pages by establishing auth once within the session rather than re-authenticating per URL:

- Sign in in the browser — navigate to the login page, fill and submit — then continue auditing; the session stays authenticated across every subsequent command.
- To reuse a login across runs, use agent-browser's auth profiles to save and replay the login. Never hard-code credentials — take them from the environment or the run's provided auth.

Only do this when the resolved configuration permits authenticated navigation.

**SPAs.** `open` can return before a client-rendered route paints. After navigating, wait for a stable anchor on the target view before auditing or capturing:

```bash
agent-browser open "https://target/route"
agent-browser wait 'main'          # a visible anchor, e.g. main, [role="main"]
agent-browser a11y --json          # then the audit and any screenshots
```

Audit each route as its own navigation — an SPA that changes the URL client-side still needs Lighthouse and the accessibility audit pointed at the resolved URL per view.

---

## Visual & responsive evidence

Use the browser for the heuristic and best-practices evidence the scored engines don't capture:

- **Responsive screenshots** — `agent-browser screenshot [selector] <path>`, passing a path inside the finding's `evidence/` so the image is written straight to disk (the command returns the saved path, not an inline blob). Add `--full` for the whole page, or a leading selector to scope to a region. Layout defects are judged from these.
- **Console errors** — `agent-browser console --json` for runtime errors and warnings, `agent-browser errors --json` for uncaught exceptions; these back Best Practices findings that a static score summarizes but doesn't localize.
- **Failed requests** — `agent-browser network requests --json` to list 4xx/5xx and mixed-content requests as evidence for Best Practices.

Name screenshots `{NN}-{descriptor}.png` in the path you pass, so they land in the finding's `evidence/` matching the workspace convention.

---

## Setup & first-run checks

The engines are standard tooling, but the harness has to actually have them. On the first audit in an environment, verify before relying on results:

| Check | Command | If it fails |
|---|---|---|
| Node + npx present (Lighthouse) | `node -v && npx -v` | Escalate — Lighthouse cannot run |
| A Chrome binary exists (Lighthouse) | `command -v google-chrome \|\| command -v chromium` | Lighthouse needs one; without it, escalate |
| Lighthouse package available | `npm ls lighthouse` | `npm i lighthouse` in a scratch directory |
| agent-browser healthy | `agent-browser doctor` | Runs the binary, Chrome, and daemon checks; if Chrome is missing, `agent-browser install` |
| Lighthouse runs end to end | `npx lighthouse "https://example.com" --output=json --output-path=./lhr.json --chrome-flags="--headless=new --no-sandbox" --quiet` | Exit 0 and a written `lhr.json` means the engine is good |

Install Lighthouse into a scratch working directory rather than a project — it is an audit tool, not a project dependency. agent-browser is a global binary with its own Chrome, provisioned via `agent-browser install`; the accessibility audit is built in, so Lighthouse is the only engine that needs an npm install.

- **Chrome flags (Lighthouse).** In a container, `--no-sandbox` (and sometimes `--headless=new`) is required or Chrome won't launch — apply to the Lighthouse `--chrome-flags`. agent-browser manages its own headless Chrome; `agent-browser doctor` surfaces launch problems.
- **One URL per run** for both Lighthouse and the accessibility audit — batching pages into one invocation is not supported; loop.
- **Treat a tool crash as a blocker, not a pass.** If Lighthouse exits non-zero or the accessibility audit errors, the concern was not measured — surface it, never record a silent pass.

---

## Common mistakes

| Mistake | What to do instead |
|---|---|
| Reporting an INP number from a lab Lighthouse run | Lab has no INP — read Total Blocking Time as the proxy, and say so |
| Trusting Lighthouse's accessibility score as the a11y result | It's a floor. Run `agent-browser a11y` for the actual WCAG violations with selectors |
| Running one Lighthouse invocation for many URLs | One page per run; loop over routes, one LHR each |
| Auditing an SPA route before it renders | Wait for a visible anchor with `agent-browser wait <sel>` after navigating, not just the `open` return |
| Summarizing tool output instead of saving it | Save the raw LHR and violations JSON into `evidence/`; the raw artifact is the proof |
| Chrome fails to launch (Lighthouse) in the container | Add `--no-sandbox` / `--headless=new` to the Lighthouse chrome-flags; for agent-browser, run `agent-browser doctor` / `agent-browser install` |
| Hard-coding login credentials to reach protected pages | Authenticate once inside the run's browser session (or replay a saved auth profile); take credentials from the environment |

---

## Resources

- [Lighthouse — npm](https://www.npmjs.com/package/lighthouse)
- [Lighthouse — Understanding results (LHR structure)](https://github.com/GoogleChrome/lighthouse/blob/main/docs/understanding-results.md)
- [agent-browser — browser automation for AI agents](https://agent-browser.dev)
- [Deque — axe rules reference](https://dequeuniversity.com/rules/axe/)
- [web.dev — Core Web Vitals](https://web.dev/articles/vitals)
