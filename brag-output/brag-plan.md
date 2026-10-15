# Brag Plan: demiurge

## What is this app?
Demiurge is a meta-harness for Claude Code made of plain markdown — one agent (Demiurge) whose only job is writing the instructions of every other agent: agent files, pipeline skills, plan templates, handoff contracts.

## The angle
No launch hype. A quiet screen-record: someone asks Demiurge for an agent with a pipeline, Demiurge asks back, then the files land. The joke/hook is restraint — it doesn't write code, it writes the *before* that makes code good.

## Hook (first 2-3 seconds)
Dark terminal. Cursor blinks. Line types: `You don't write the agent. You describe the work.`

## Key moments (the middle)
- Real Claude Code prompt recreated: `claude --agent Demiurge` + `> Create a Reviewer agent with one review pipeline…`
- Demiurge phase header `# Demiurge | Intake` + 3 sharp questions appearing one by one
- Two files landing with checks: `Reviewer.md` + `pipeline-reviewer-review/SKILL.md`, phases `Intake → Alignment → Production → Self-review → Delivery`

## Outro / punchline
`demiurge — the agent that writes the others.` Small install line. Hold. Cut.

## User flow worth showing
entry: `claude --agent Demiurge` + describe Reviewer agent need → key action: Demiurge Intake questions, Alignment, Production through pipeline phases with gates → result: agent file + pipeline skill ready to load, future tasks start with that rigor.

## Tone
- Preset: polished
- Creative direction: quiet hands-on terminal demo, no hype — watch it work
- Interpretation: slow holds, real terminal typing, minimal motion, let the files be the payoff. Restrained type, soft crossfades.

## Format: landscape — 1920x1080
## Duration: 22 seconds

## Visual identity (from the project)
- Background: #0d1117
- Accent: #D97757 (Claude Code orange, from README badge)
- Text: #e6edf3
- Secondary: #A78BFA (Demiurge purple, from agent color: purple)
- Display font: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace
- Body font: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace
- Strongest visual element: Claude Code terminal session + `You → Demiurge → Harness (agents, pipelines, plan templates, handoffs)` flow from assets/idea.png

## Share copy (draft)
I asked Demiurge for a Reviewer agent with a review pipeline. It asked three questions, then wrote the agent + pipeline files.

## Audio direction
- Role: sparse professional accents over warm bed
- Music: happy-beats-business-moves-vol-12-by-ende-dot-app.mp3 (steady and clean, best for polished)
- Music treatment: start at 0, volume 0.22, fade out last 2s, duck slightly under typing payoff
- Music cue guidance: preset read; tempo ~110 BPM; strong cues near 8.74s and 17.47s — lock file-payoff near 13.1s cue, outro landing near 17.47s; sequential questions snap to beat grid ±0.10s
- Audio-reactive treatment: subtle; RMS breathes terminal glow / card presence only, no waveforms
- SFX posture: sparse, motion-matched, professional restraint
- Audio-coupled moments: typed request (key ticks), question cards arriving one by one (soft drops), file landing (one bell payoff)
- Restraint rule: no hype hits, no stacked impacts, never cover readable text with loud cues

## Storyboard

### Scene 1 — Hook — 2.5s
Dark terminal. Small `🏺 demiurge` label. Hook line types: `You don't write the agent.` / `You describe the work.` Cursor blinks.
Sequential/interaction: yes — two lines type one after another
Audio intent: quiet bed establishes, soft key ticks
Audio-coupled idea: typed text with subtle key ticks
Music: vol-12 steady bed, low
Transition mood: soft → Scene 2

### Scene 2 — The ask — 4.5s
Claude Code window recreation. `$ claude --agent Demiurge` then `> Create a Reviewer agent with one review pipeline. Three checks before it approves: ambiguity, architecture drift, OWASP Top 10.` Types out.
Sequential/interaction: yes — command types, then request types
Audio intent: bed continues, typing stays subtle
Audio-coupled idea: typing simulation
Transition mood: soft → Scene 3

### Scene 3 — Demiurge works — 6s
Phase header `# Demiurge | Intake`. Three question cards arrive one by one: `1. What counts as approved?` `2. What triggers each review?` `3. Who can invoke it?` Footer: `Intake → Alignment → Production → Self-review → Delivery`.
Sequential/interaction: yes — 3 cards arrive one by one
Audio intent: bed steady, soft drop per card
Audio-coupled idea: card-by-card sequence, beat-aligned reveals with full-set hold for readability
Music: same bed
Transition mood: clean → Scene 4

### Scene 4 — Files land — 5s
Two file cards: `Reviewer.md ✓` + `pipeline-reviewer-review/SKILL.md ✓`. Under: `Goal / Actions / Avoid / Exit when` phase block. Line: `Every future task starts with that rigor.`
Sequential/interaction: yes — 2 files land one by one with check ticks
Audio intent: one soft payoff bell on second file, then back to bed
Audio-coupled idea: card sequence + single success accent
Transition mood: soft → Scene 5

### Scene 5 — Outro — 4s
`demiurge` + `the agent that writes the others.` Small: `plain markdown. no framework.` + `curl …/install.sh | bash`. Hold.
Sequential/interaction: none
Audio intent: bed fades, one dry logo tick, silence into hold
Audio-coupled idea: final logo accent only
Transition mood: hold, cut to black

**Music mood for this video:** restrained steady bed, polished
**Audio summary:** Low steady bed throughout with typed keys, three soft card drops, one file-payoff bell, gentle fade under the outro.
