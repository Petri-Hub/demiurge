# Brag Plan v2: demiurge (TUI + voiceover)

## What is this app?
Demiurge is a meta-harness for Claude Code made of plain markdown — one agent (Demiurge) whose only job is writing the instructions of every other agent: agent files, pipeline skills, plan templates, handoff contracts.

## The angle
Hands-on, not promo: a Demiurge desktop TUI. Left side is the conversation, right side is the harness panel where the agent title mounts and pipeline phases light up as they are created. A calm voice walks through it while it happens.

## Hook (first 2-3 seconds)
TUI boots: top bar `🏺 demiurge · agent: Demiurge ● live`. Voice starts: "You describe the work to Demiurge…"

## Key moments (the middle)
- User bubble types the Reviewer request in the chat pane; right HARNESS panel sits empty ("waiting for brief")
- Demiurge replies with `# Demiurge | Intake` + three question bubbles; agent row `Reviewer.md — mounting… ✓` appears; five phase chips (Intake → Alignment → Production → Self-review → Delivery) light up one by one
- File cards land: `Reviewer.md ✓` + `pipeline-reviewer-review/SKILL.md ✓` with `Goal / Actions / Avoid / Exit when` phase block

## Outro / punchline
Voice: "From here on, every task starts with that rigor." Logo + `demiurge — the agent that writes the others.` Music returns briefly, fades.

## User flow worth showing
entry: describe the Reviewer need in chat → key action: Demiurge Intake questions + Alignment while agent mounts and phases light up → result: agent file + pipeline skill ready; every future task starts with that rigor.

## Tone
- Preset: polished
- Creative direction: calm narrated TUI demo — screen-record with a guide, zero hype
- Interpretation: voice leads, music is texture; motion stays slow, holds stay long, panels update like a real app

## Format: landscape — 1920x1080
## Duration: 22 seconds

## Visual identity (from the project)
- Background: #0d1117
- Panel: #010409 with #30363d borders
- Accent: #D97757 (Claude Code orange)
- Text: #e6edf3
- Secondary: #A78BFA (Demiurge purple)
- Success: #3fb950
- Display font: monospace (system, lint-clean)
- Body font: monospace (system, lint-clean)
- Strongest visual element: TUI two-pane layout — chat left, HARNESS mounting panel right

## Share copy (draft)
Demiurge, narrated: describe the work, answer three questions, and the Reviewer agent + its pipeline phases mount live in the harness panel.

## Voiceover script
Voice: af_heart (Kokoro-82M, en-US female — flagship most-natural English voice). Generated 15.4s, starts 0.8s, ends ~16.2s.
> You describe the work to Demiurge — say, a Reviewer agent with a real review pipeline. It pushes back with three sharp questions, aligns on scope, then writes the agent and every pipeline phase. From here on, every task starts with that rigor.

## Audio direction
- Role: voice-led; music is quiet texture under narration
- Music: happy-beats-business-moves-vol-10-by-ende-dot-app.mp3 (punchier loop, less classroom than vol-12)
- Music treatment: 0.13 ducked under VO (0–16.5s), returns to 0.30 after VO (16.5–22s), fades last 2s
- Music cue guidance: vol-10 preset; file payoff near a strong cue ±0.15s; phase chips on beat grid ±0.10s
- Audio-reactive treatment: subtle; RMS breathes panel glow only
- SFX posture: very sparse — VO carries it. One key tick, three soft drops, one payoff bell, one outro click.
- Audio-coupled moments: user bubble typing (tick), question bubbles + phase chips (drops), file landing (bell), outro (click)
- Restraint rule: nothing competes with the voice; no stacked hits

## Storyboard

### Scene 1 — Boot — 3s (0–3)
TUI fades in: top bar, empty chat, empty HARNESS panel. Line under logo: `You describe the work.` VO begins 0.8s.
Sequential/interaction: none (boot reveal)
Audio intent: ducked bed under VO start
Audio-coupled idea: none
Music: vol-10 at 0.13
Transition mood: soft → Scene 2

### Scene 2 — The ask — 5s (3–8)
User bubble types in chat: `Create a Reviewer agent with one review pipeline. Three checks before it approves: ambiguity, architecture drift, OWASP Top 10.` Right panel: `HARNESS — waiting for brief…`
Sequential/interaction: yes — bubble types out
Audio intent: VO describes request; soft key tick at type start
Audio-coupled idea: typing simulation
Transition mood: soft → Scene 3

### Scene 3 — Demiurge works — 6s (8–14)
Demiurge reply: `# Demiurge | Intake` + 3 question bubbles arrive one by one. Right panel: `Reviewer.md — mounting… ✓`, then 5 phase chips light one by one.
Sequential/interaction: yes — questions + chips arrive one by one
Audio intent: VO covers questions/scope; soft drops per arrival
Audio-coupled idea: card-by-card sequence on beat grid with full-set hold
Transition mood: clean → Scene 4

### Scene 4 — Files land — 5s (14–19)
File cards: `Reviewer.md ✓` + `pipeline-reviewer-review/SKILL.md ✓`, phase block `Goal · Actions · Avoid · Exit when`. VO ends 16.2s: "…starts with that rigor."
Sequential/interaction: yes — 2 files land one by one
Audio intent: one soft payoff bell, VO closes, music starts returning
Audio-coupled idea: card sequence + single success accent
Transition mood: soft → Scene 5

### Scene 5 — Outro — 3s (19–22)
`demiurge` + `the agent that writes the others.` + `plain markdown · no framework`. Music at 0.30, fades last 2s.
Sequential/interaction: none
Audio intent: bed returns then fades, one dry click
Audio-coupled idea: final logo accent only

**Music mood for this video:** quiet punchy texture under voice, brief return at outro
**Audio summary:** Ducked bed under a 15.4s narration, sparse drops/bell marking arrivals, music returns for the outro and fades.
