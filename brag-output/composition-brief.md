# Hyperframes Composition Brief: demiurge

## Objective
Create a short hands-on brag video for demiurge. No promo hype — a quiet terminal screen-record of someone asking Demiurge to create an agent with a pipeline.

## Output
- Composition directory: `brag-output/composition/`
- Rendered video: `brag-output/brag.mp4`
- Format: landscape — 1920x1080
- Duration: 22 seconds

## Source Material
- Project root: /home/petri/Desktop/Personal/Projects/demiurge
- Primary files read: README.md, agents/Demiurge.md, install.sh, assets/idea.png, assets/agent-anatomy.png
- Product name: demiurge
- Tagline / strongest claim: An agent whose only job is writing the instructions of the others
- Key UI or visual moment to recreate: Claude Code terminal session (`claude --agent Demiurge`), phase header `# Demiurge | Intake`, two file cards landing
- Copy that must appear verbatim:
  - `claude --agent Demiurge`
  - `An agent whose only job is writing the instructions of the others`
  - `Reviewer.md`
  - `pipeline-reviewer-review/SKILL.md`

## Creative Direction
- Tone preset: polished
- Creative direction: quiet hands-on terminal demo, no hype — watch it work
- Interpretation: slow holds, real terminal typing, minimal motion, files are the payoff
- Angle: You don't write the agent. You describe the work. Demiurge asks back, then the agent + pipeline files land.
- Hook: `You don't write the agent. You describe the work.` typed on dark terminal
- Outro / punchline: `demiurge — the agent that writes the others.`
- Avoid:
  - Generic SaaS language
  - Abstract filler visuals
  - Unrelated visual redesign

## Visual Identity
- Background: #0d1117
- Text: #e6edf3
- Accent: #D97757
- Secondary: #A78BFA
- Display font: system monospace stack (no webfont, keeps lint clean)
- Body font: system monospace stack
- Visual references from the project: Claude Code terminal, idea.png You → Demiurge → Harness flow, agent-anatomy Phase Goal/Actions/Avoid/Exit-when block

## Storyboard
Use the storyboard in `brag-output/brag-plan.md` as the creative contract.

Scene summary:
1. Hook — 2.5s — typed hook lines
2. The ask — 4.5s — claude --agent Demiurge + Reviewer request types out
3. Demiurge works — 6s — Intake header + 3 question cards one by one
4. Files land — 5s — 2 file cards + phase block
5. Outro — 4s — demiurge + tagline + install hint

## Audio
- Audio role: sparse professional accents over warm bed
- Audio arc: low bed throughout, ticks/drops mid, one bell payoff, fade under outro
- Music: happy-beats-business-moves-vol-12-by-ende-dot-app.mp3
- Music treatment: volume 0.22, fade out last 2s
- Music cue guidance: preset brag/assets/music/cues/happy-beats-business-moves-vol-12...json; lock file payoff near 13.11s strong cue ±0.15s, outro near 17.47s; sequential cards snap to beats ±0.10s
- Audio-reactive treatment: subtle; RMS breathes terminal glow only
- Audio-coupled moments:
  - hook + ask — typing with key ticks
  - questions — card-by-card soft drops
  - files land — single success bell
  - outro — final dry tick then fade
- SFX selection guidance: keyboard ticks for typing, interface/drop for cards, one impactBell for payoff; restraint, low HF risk for repeats
- SFX analysis guidance: brag/assets/sfx/sfx-analysis.md; prefer low/medium HF risk for polished repeats
- Exact SFX choice: Hyperframes should choose filenames, timestamps, density, volume based on implemented animation
- Audio files: copy chosen music + SFX into `brag-output/composition/assets/`

## Hyperframes Instructions
Load hyperframes-core (composition contract + data-* timing), hyperframes-animation (motion), hyperframes-creative (design spec, beats, audio-reactive), hyperframes-keyframes (seek-safe keyframes), hyperframes-cli (lint/check/render). /brag is its own workflow: do not enter hyperframes entry-point intent interview.

Requirements:
- Show at least one real UI, copy, or visual element from the source project.
- Keep all text readable in the final render.
- Keep the video within 15-25 seconds.
- Include the planned music/SFX layer unless explicitly disabled.
- Treat /brag audio notes as guidance, not fixed cue sheet.
- Major reveals may move toward nearby strong cues within ~0.15s. Smaller entrances may align to beats within ~0.10s. Use only 1-3 strong cue locks.
- Use SFX to support motion and interaction with restraint.
- Use local assets for audio when possible.
- Run `hyperframes check` before render.
- Keep creation and rendering local.
