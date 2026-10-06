---
name: specialization-maestro
description: "Maestro mobile E2E testing patterns for React Native/Expo apps: YAML test flows, testID selectors, adaptive auth state, optimistic update verification, GraalJS scripting, cross-platform stability, CI/CD integration, Maestro Cloud, and Maestro Runner execution"
user-invocable: false
---

# Maestro Mobile E2E Testing

## Overview

Maestro is a declarative YAML-based mobile E2E testing framework. It provides automatic waiting, built-in retry logic, and fast execution without boilerplate. It's more stable than Detox or Appium for React Native apps.

### Key Features

- **Declarative YAML** — no imperative test code, just steps
- **Automatic waiting** — no manual `sleep()` or flaky waits
- **Built-in retry** — reduces test flakiness
- **Fast execution** — runs quickly without setup overhead
- **Sub-flows** — reusable YAML sequences for DRY tests
- **JavaScript scripting** — GraalJS runtime for HTTP calls and data manipulation
- **Maestro Cloud** — real device testing in CI without local simulators

## Quick Start

### Minimal test

```yaml
# Mobile app
appId: com.myapp
---
- launchApp:
    clearState: true
- tapOn:
    id: "my-button"
- assertVisible: "Expected Text"
```

```yaml
# Web app (Chromium)
url: https://my-website.com
---
- launchApp:
    clearState: true
- tapOn:
    id: "my-button"
- assertVisible: "Expected Text"
```

> **Important:** `appId` and `url` are mutually exclusive. Use `appId` for mobile (Android/iOS), `url` for web (Chromium). Never use both in the same file.

### Run

```bash
maestro-runner test .maestro/smoke-test.yaml
```

---

## Frontmatter Format

Every Maestro YAML flow file has a header section separated from the flow steps by `---`. Getting this wrong produces invalid flows that fail silently or throw parse errors.

### Structure

```yaml
# Optional comments go HERE — above the header fields
appId: com.myapp          # or: url: https://example.com
tags:                      # optional
  - smoke
env:                       # optional
  KEY: value
---                         # REQUIRED separator between header and steps
- launchApp                # Flow steps begin here
- assertVisible: "Welcome"
```

### Rules

- The `---` separator is **mandatory**. Without it, Maestro cannot distinguish header metadata from flow steps.
- Comments (`#`) are valid above the header fields and within the flow steps, but avoid placing them between header fields and `---`.
- `appId` and `url` are **mutually exclusive** — use `appId` for mobile (Android/iOS), `url` for web (Chromium). Never use both in the same file.
- `env` and `tags` are optional. `appId` (or `url`) is required.

### Common frontmatter errors

```yaml
# WRONG — no --- separator
appId: com.myapp
- launchApp
# Maestro will fail to parse this

# WRONG — both appId and url
appId: com.myapp
url: https://example.com
---
- launchApp
# Behavior is undefined — use one or the other

# WRONG — comments between header and separator
appId: com.myapp
# This comment may cause issues
---
- launchApp
```

---

## Core Patterns

### 1. Selector Strategy: testID vs Text

Choose your selector approach based on project context. Both are valid — the right choice depends on whether your app is localized and your team's testing philosophy.

| Context | Recommended Selector | Rationale |
|---------|---------------------|-----------|
| **Multi-language / i18n** | `id:` (testID) | Stable across translations |
| **Single language** | Text labels (with regex for web) | Human-readable, self-documenting tests |
| **System dialogs** | Text (always) | No testID possible on native alerts |
| **Web (Chromium)** | `id:` preferred, or text with `.*` regex | Plain text matching is unreliable on web — always wrap in regex |

```yaml
# testID selector — stable across translations, works on all platforms
- tapOn:
    id: "submit-button"

# Text selector on MOBILE — works with plain text
- tapOn: "Submit"

# Text selector on WEB (Chromium) — MUST use regex wrapping
- tapOn: ".*Submit.*"
- assertVisible: ".*Welcome.*"
```

> **Critical web gotcha:** On Chromium (web) targets, plain text matching is unreliable — a button displaying "New member" will not match `tapOn: "New member"`. You MUST wrap all text selectors in regex: `tapOn: ".*New member.*"`. This applies to ALL text-based commands on web: `tapOn`, `assertVisible`, `extendedWaitUntil`, `back`, etc. Mobile targets (Android/iOS) do not have this issue — plain text works.

#### testID Naming Convention

When using ID-based selectors:

```
{component}-{action/type}[-{variant}]

Examples:
- auth-prompt-login-button
- product-card-{id}
- otp-input-0
- tab-home
- dashboard-loading
```

### 2. Adaptive Tests (Handle Both Auth States)

Because every test starts with `clearState: true`, the app is always in a logged-out state at the beginning of each test. This means **every test must include authentication handling** — either an adaptive auth check or a login subflow. A test that assumes the user is already logged in will fail on every run.

```yaml
# MANDATORY — every test must handle auth after clearState + launchApp
- launchApp:
    clearState: true

# Auth flow — only runs if login prompt is visible
- runFlow:
    when:
      visible: "Sign In"
    file: flows/auth-flow.yaml

# Already authenticated — proceed directly
- runFlow:
    when:
      visible:
        id: "tab-home"
    file: flows/authenticated-action.yaml
```

> **Never assume the user is logged in.** `clearState` wipes all sessions. Every main flow file must include an auth pre-flight after `launchApp` — either an adaptive `runFlow` with a `when` condition, or an explicit login sequence. If the application has no authentication, skip this step — but document the decision in a comment.

### 3. Test Independence with clearState

Every test must start from a clean state. Without clearing state, tests share cookies, localStorage, authentication sessions, and app data between runs — producing inconsistent results that depend on execution order.

The recommended approach is to use `clearState` as a nested property under `launchApp`:

```yaml
# Preferred — clear state and launch in one command
- launchApp:
    clearState: true

# With additional options
- launchApp:
    appId: com.example.app
    clearState: true
    clearKeychain: true      # iOS only — clears entire Keychain
    stopApp: true             # Default: restarts the app
```

`clearState` is also available as a standalone command for cases where you need to clear state without launching:

```yaml
# Standalone — clear current app
- clearState

# Standalone — clear a specific app
- clearState: com.other.app

# Standalone — clear web browser data for an origin
- clearState: https://example.com
```

| Platform | What `clearState` clears |
|----------|--------------------------|
| Android | Shared preferences, databases, accounts — equivalent to `adb shell pm clear` |
| iOS | App data — equivalent to a fresh install |
| Chromium (web) | Cookies, localStorage, sessionStorage for the origin |

> Use `launchApp: { clearState: true }` as the first command in every main flow. Sub-flows should NOT include `clearState` — the main flow owns the lifecycle.

### 4. Testing Optimistic Updates

Use short timeouts to verify UI changes happen before server response:

```yaml
# Trigger mutation
- tapOn:
    id: "action-button"

# OPTIMISTIC: UI must change within 3s (not waiting for server)
- extendedWaitUntil:
    visible:
      id: "undo-button"
    timeout: 3000

# Verify derived UI state
- extendedWaitUntil:
    visible:
      id: "user-indicator"
    timeout: 5000
```

> Only use this when necessary, as this enlarges the testing time.

| Action | Expected Change | Timeout |
|--------|----------------|---------|
| Mutation trigger | Button state flips | < 3s |
| List update | Item appears/disappears | < 5s |
| Re-do action | Proves persistence | < 3s |

### 5. Dismissing Native Alerts

React Native `Alert.alert()` creates native dialogs that block the UI:

```yaml
- tapOn:
    id: "action-button"

# Wait for expected state change first
- extendedWaitUntil:
    visible:
      id: "new-state-element"
    timeout: 5000

# Dismiss alert (optional in case it already closed)
- tapOn:
    text: "OK"
    optional: true

# Brief delay for alert animation
- swipe:
    direction: DOWN
    duration: 300
```

### 6. Sub-Flows for Reusability

Break repeated sequences into sub-flow files:

```
my-maestro-folder/
├── flows/
│   ├── auth-and-return.yaml
│   ├── complete-purchase.yaml
│   └── verify-result.yaml
├── smoke-test.yaml
└── feature-test.yaml
```

```yaml
# In smoke-test.yaml (at the root level)
# Path is relative to THIS file's location
- runFlow:
    file: flows/auth-and-return.yaml

# In flows/complete-purchase.yaml (inside flows/)
# Path is relative to THIS file's location — no "flows/" prefix
- runFlow:
    file: auth-and-return.yaml
```

> **Path resolution rule:** `runFlow: { file: }` paths are resolved relative to the file containing the `runFlow` command — NOT relative to the project root, NOT relative to the working directory. If both files are in the same `flows/` directory, reference the subflow by filename only (`auth-flow.yaml`), not by its full path (`flows/auth-flow.yaml`).

### 7. Platform-Specific Logic

```yaml
- runFlow:
    when:
      platform: ios
    file: flows/ios-specific.yaml

- runFlow:
    when:
      platform: android
    file: flows/android-specific.yaml
```

### 8. Environment Variables

```yaml
appId: com.myapp
env:
  TEST_EMAIL: maestro-test@example.com
  API_BASE_URL: http://localhost:3000
---
- inputText: ${TEST_EMAIL}
```

### 9. Selector State Properties

Use `enabled`, `selected`, `checked`, and `focused` to target elements by their current state. This is useful for validating interactive element states before or after actions.

```yaml
# Only tap the submit button if it's enabled
- tapOn:
    id: "submit-button"
    enabled: true

# Assert a checkbox is checked
- assertVisible:
    id: "terms-checkbox"
    checked: true

# Wait for an input to be focused
- extendedWaitUntil:
    visible:
      id: "email-input"
      focused: true
    timeout: 3000
```

| Property | Values | Use Case |
|----------|--------|----------|
| `enabled` | `true` / `false` | Buttons that disable during submission or until form is valid |
| `checked` | `true` / `false` | Checkboxes, toggle switches |
| `selected` | `true` / `false` | Tab items, segmented controls |
| `focused` | `true` / `false` | Input fields with auto-focus |

### 10. Relative Position Selectors

Distinguish between similar elements by their spatial relationship to other elements. This is more idiomatic and resilient than index-based selection.

```yaml
# BAD — fragile, breaks if order changes
- tapOn:
    text: "Add to Basket"
    index: 1

# GOOD — contextual, self-documenting
- tapOn:
    text: "Add to Basket"
    below:
      text: "Awesome Shoes"
```

Available relative selectors:

```yaml
# Target element below another
- tapOn:
    text: "Buy Now"
    below: "Product Title"

# Target element that is a child of a parent
- tapOn:
    text: "Delete"
    childOf:
      id: "item-card-42"

# Target a parent that contains a specific child
- tapOn:
    containsChild: "Urgent"

# Target by multiple descendants
- tapOn:
    containsDescendants:
      - id: title_id
        text: "Specific Title"
      - "Another descendant text"

# Horizontal positioning
- tapOn:
    text: "Edit"
    rightOf: "Username"
```

| Selector | Meaning |
|----------|---------|
| `below:` | Element is positioned below the referenced element |
| `above:` | Element is positioned above the referenced element |
| `leftOf:` | Element is to the left of the referenced element |
| `rightOf:` | Element is to the right of the referenced element |
| `childOf:` | Element is a direct child of the referenced parent |
| `containsChild:` | Element contains a direct child matching the reference |
| `containsDescendants:` | Element contains all specified descendant elements |

---

## Test File Template

```yaml
# {Feature} {Action} Test
#
# Tests: {what this validates}
# Prerequisites:
# - Simulator/emulator running with app installed
# - Backend or mock server running (if API-dependent)

appId: com.myapp
env:
  TEST_EMAIL: maestro-{feature}@example.com
  EMAIL_SERVICE_URL: http://localhost:8025
---
# ==========================================
# STEP 1: CLEAR STATE + LAUNCH
# ==========================================

- launchApp:
    clearState: true

- swipe:
    direction: DOWN
    duration: 100

- extendedWaitUntil:
    visible:
      id: "auth-loaded"
    timeout: 15000

- takeScreenshot: 01-initial-state

# ==========================================
# STEP 2: {ACTION}
# ==========================================

- tapOn:
    id: "target-element"

# ==========================================
# STEP 3: VERIFY
# ==========================================

- extendedWaitUntil:
    visible:
      id: "expected-result"
    timeout: 5000

- takeScreenshot: 02-final-state
```

---

## Folder Structure

The test suite uses one of two structure modes, determined by the application's scope and complexity.

### Flat Mode — small apps, focused scopes

```
{storage-path}/
├── flows/
│   ├── 01-login-valid-credentials.yaml
│   └── 02-navigate-settings.yaml
├── subflows/
│   ├── login.yaml
│   └── logout.yaml
├── screenshots/
└── outputs/
```

### Modular Mode — large apps, multi-module scopes

```
{storage-path}/
├── authentication/
│   ├── flows/
│   │   ├── 01-login-valid-credentials.yaml
│   │   └── 02-forgot-password.yaml
│   └── subflows/
│       ├── login.yaml
│       └── logout.yaml
├── members/
│   ├── flows/
│   │   ├── 01-view-members-list.yaml
│   │   └── 02-search-members.yaml
│   └── subflows/
├── screenshots/
└── outputs/
```

### Storage Path

The storage path depends on the invocation context:

| Context | Path pattern | Example |
|---|---|---|
| **Workspace** | `.workspace/tests/{application}/maestro/` | `.workspace/tests/web/maestro/` |
| **Local project** | Discovered from existing structure, or `tests/{application}/maestro/` | `tests/admin/maestro/` |

The `{application}` is derived from the application target:
- **URL** (web): subdomain or path segment (`https://admin.myapp.com` → `admin`)
- **Package name** (Android): last segment (`com.example.app` → `app`)
- **Bundle ID** (iOS): last segment (`com.example.app` → `app`)

### Directory Purposes

| Directory | Contents | Created by |
|---|---|---|
| `flows/` | Standalone executable Maestro test files — one YAML per scenario | Authoring phase |
| `subflows/` | Reusable Maestro sequences included via `runFlow` — never executed directly | Authoring phase |
| `screenshots/` | Exploration screenshots documenting the application's visual state | Exploration phase |
| `outputs/` | Maestro Runner output — execution reports, failure screenshots, `takeScreenshot` outputs | Runner CLI (`--output`) |

### runFlow Path Conventions

`runFlow: { file: }` resolves paths relative to the containing file, not the project root.

**Flat mode:**

```yaml
# In flows/01-login-test.yaml — reference subflow
- runFlow:
    file: ../subflows/login.yaml
```

**Modular mode — intra-module:**

```yaml
# In authentication/flows/01-login-test.yaml — reference subflow in same module
- runFlow:
    file: ../subflows/login.yaml
```

**Modular mode — cross-module:**

```yaml
# In members/flows/01-view-list.yaml — reference subflow in another module
- runFlow:
    file: ../../authentication/subflows/login.yaml
```

Cross-module references are valid but should be rare. Prefer keeping subflows local to their module. If a subflow is shared across modules, place it in a `shared/` module folder.

### Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Main test | `{NN}-{scenario}.yaml` | `01-login-valid-credentials.yaml` |
| Sub-flow | `{action}-{context}.yaml` | `login-and-return-to-dashboard.yaml` |
| Module folder | `{feature-area}` (kebab-case) | `authentication/`, `member-management/` |
| Script | `{verb}-{noun}.js` | `fetch-otp.js` |

---

### Android Permission Handling

Android permissions appear as system dialogs. Dismiss with optional taps:

```yaml
- tapOn:
    text: "Allow"
    optional: true

- tapOn:
    text: "While using the app"
    optional: true
```

---

### Tag-Based Flow Filtering

Use tags to control which tests run in CI vs locally:

```yaml
# In your flow file header
appId: com.myapp
tags:
  - ci
  - smoke
---
- launchApp
# ... test steps
```

```bash
# Run only CI-tagged flows locally
maestro-runner test --include-tags ci .maestro/

# Exclude work-in-progress flows
maestro-runner test --exclude-tags wip .maestro/
```

---

## Debugging

```bash
maestro-runner test .maestro/test.yaml           # Run a single test
maestro-runner test .maestro/                     # Run all tests in directory
maestro-runner test --parallel .maestro/          # Run tests in parallel
maestro-runner test --output results/ .maestro/   # Output to specific directory
```

Screenshots and results saved to the Runner's output directory (default or as specified by `--output`).

---

## Maestro Runner

The [Maestro Runner](https://github.com/devicelab-dev/maestro-runner) is a high-performance, open-source drop-in replacement for the Maestro CLI. It runs the same Maestro YAML files significantly faster with lower memory usage, using a Go runtime instead of Kotlin/JVM.

### How It Complements This Skill

| | **This Skill** | **Maestro Runner** |
|---|---|---|
| **Role** | Teaches correct patterns | Provides runtime execution |
| **Layer** | Authoring (write good YAML) | Execution (run tests, capture results) |
| **Output** | Better test files | Test results, screenshots, reports |

Use both together: this skill ensures the AI writes correct tests; the Runner executes them fast and captures results.

### Key Capabilities

| Feature | Details |
|---------|---------|
| Platforms | Android, iOS, Web (Chromium) |
| Parallel execution | `--parallel` flag for running tests concurrently |
| Tag filtering | `--include-tags` / `--exclude-tags` for selective runs |
| Screenshots | Auto-captured on failure; explicit `takeScreenshot` commands in YAML for controlled checkpoints |
| Output formats | HTML, JUnit XML, Allure reports |
| Platform selection | `--platform android/ios/web` |
| Drivers | `--driver devicelab/appium/uiautomator2` |

### Not Supported

The Maestro Runner does **not** support viewport configuration for web (Chromium) targets. Tests must work at the Runner's default viewport size. Do not include viewport-related directives or rely on specific window dimensions.

### Write-Run-Fix Loop

With both this skill and the Runner available, the AI can:

1. **Write** a test YAML using patterns from this skill
2. **Run** it via the Maestro Runner CLI: `maestro-runner test <file>`
3. **See** failures via Runner output and auto-captured screenshots
4. **Fix** the YAML and re-run — all in one conversation

---

## Checklist for New Tests

```
[ ] Unique test email (maestro-{feature}@example.com)
[ ] Selector strategy chosen (testID for i18n apps, text for single-language — see Pattern 1)
[ ] Selectors use state properties where relevant (enabled, checked — see Pattern 10)
[ ] Similar elements distinguished with relative selectors, not index (see Pattern 11)
[ ] Auth pre-flight pattern used (auth-loaded)
[ ] Post-launch swipe added (iOS crash prevention)
[ ] Both auth states handled (adaptive flows)
[ ] Native alerts dismissed after mutations
[ ] Short timeouts for optimistic updates (3-5s)
[ ] Sub-flows created for reusable sequences
[ ] Descriptive screenshots at key points
[ ] Header comment with prerequisites
[ ] Added to README.md test table
[ ] Mock API server started if backend-dependent
[ ] Tags added for CI filtering (ci, smoke, wip)
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Unable to locate Java Runtime" | Java not in PATH | `export JAVA_HOME=/opt/homebrew/opt/openjdk@17/...` |
| "Element not found" after tap | Native alert blocking | Add `tapOn: text: "OK" optional: true` |
| Test passes but nothing happened | `optional: true` misused | Only use optional for truly optional actions |
| "Assertion is false" on visibility | Element not rendered yet | Increase timeout or verify testID exists |
| Script output empty | Wrong JS API | Use `http.get()` not `fetch()` |
| Permission dialog blocking (Android) | System dialog not dismissed | Add `tapOn: text: "Allow" optional: true` |

---

## Common Mistakes

| Mistake | Why It Happens | What To Do Instead |
|---------|---------------|-------------------|
| Placing comments between header fields and `---` | YAML allows comments anywhere, but Maestro's frontmatter parser expects a clean header block | Place comments above the header fields (before `appId:`/`url:`) or within the flow steps (after `---`). Never between header fields and the separator. See **Frontmatter Format**. |
| Missing the `---` separator | Forgetting that Maestro requires the separator between header and flow steps | Always include `---` between the header block (`appId`/`url`, `env`, `tags`) and the flow steps (`- launchApp`, etc.). See **Frontmatter Format**. |
| Using `appId` and `url` in the same file | Copy-pasting from mobile examples and adding `url` for web, or vice versa | They are mutually exclusive. Use `appId` for Android/iOS, `url` for Chromium (web). Never both. See **Frontmatter Format**. |
| Not using `clearState` | Tests pass locally because state carries over from previous runs, then fail in CI | Use `launchApp: { clearState: true }` as the first command in every main flow. See **Pattern 3**. |
| Missing `launchApp` in flow files | Assuming the app is already running from a previous test | Include `launchApp` in every main flow file. Sub-flows can include it with `stopApp: false` to foreground without restarting. See **Pattern 2** and **Pattern 6**. |
| Hard-coded waits (`- delay: 3000`) | Copied from tutorials or added out of caution during flaky test runs | Use `extendedWaitUntil` with a timeout — it polls and proceeds as soon as the condition is met, no wasted time. See **Pattern 4**. |
| Fragile index-based selectors (`index: 1`) | Quick to write, works on first run, breaks when UI order changes | Use relative position selectors (`below:`, `childOf:`) or testIDs. See **Pattern 10**. |
| Overusing `optional: true` | Added to silence failures without understanding why they occur | Only use `optional: true` for genuinely non-deterministic UI (native alerts, permission dialogs). If an element should always be there, don't make it optional — fix the selector or add a wait. See **Pattern 5**. |
| Text matching fails on web (Chromium) | `tapOn: "New member"` or `assertVisible: "Submit"` fails even though the text is exactly on screen — plain text matching is broken/unreliable on web targets | **For web (Chromium) targets, ALWAYS wrap text in regex: `".*New member.*"`.** This applies to ALL text-based commands: `tapOn`, `assertVisible`, `extendedWaitUntil`, etc. Mobile targets do not have this issue. See **Pattern 1**. |
| Wrong subflow paths in `runFlow` | Using `file: flows/auth-flow.yaml` from a file that is already inside `flows/` — basing the path on the project root instead of the current file's location | `runFlow: { file: }` resolves paths relative to the file containing the command, NOT the project root. If both files are in `flows/`, use `file: auth-flow.yaml` (no prefix). See **Pattern 6**. |
| Using `fetch()` in GraalJS scripts | Muscle memory from browser-based JavaScript | GraalJS doesn't have `fetch()`. Use `http.get()` / `http.post()` from Maestro's scripting API. See **Common Errors** table. |
| Writing one giant test for an entire user journey | Feels natural — "test the whole signup flow in one file" | Break into sub-flows (auth, action, verify). One scenario per file. Easier to debug, fix, and re-run. See **Pattern 6**. |
| Assuming the user is logged in | `clearState: true` wipes all sessions — the app is always logged out at test start. Tests that skip login fail every time | Every main flow must include auth handling after `launchApp`: either an adaptive `runFlow` with a `when` condition, or a login subflow. If the app has no auth, add a comment documenting that decision. See **Pattern 2**. |

---

## Resources

- [Maestro Documentation](https://docs.maestro.dev/)
- [Maestro Selectors Reference](https://docs.maestro.dev/api-reference/selectors)
- [Maestro Cloud](https://cloud.maestro.dev/)
- [Maestro GitHub](https://github.com/mobile-dev-inc/Maestro)
- [Maestro Runner](https://github.com/devicelab-dev/maestro-runner)
- [Maestro Runner Documentation](https://devicelab.dev/open-source/maestro-runner)
- [Conditions & Adaptive Flows](https://docs.maestro.dev/advanced/conditions)
- [GitHub Actions Integration](https://docs.maestro.dev/cloud/ci-integration/github-actions)
- [BrowserStack: Maestro Testing Guide](https://www.browserstack.com/guide/maestro-testing)
- [DEV.to: Tips & Tricks for Maestro + React Native](https://dev.to/retyui/best-tips-tricks-for-e2e-maestro-with-react-native-2kaa)