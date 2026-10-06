---
name: forge-principles
description: Canonical authoring principles God consults while producing any artifact — the instruction-design tradeoffs that make agent files, pipeline skills, plan templates, and handoff skills reliable, not just well-formed. Use this skill as a reference during any forge pipeline, before writing artifact content and again during adversarial self-review. Covers goal-over-procedure, specificity budget, instruction load, positional weighting, positive framing, rationale-bearing rules, example anchoring, structural restraint, and consistency. Reference only — it has no phases and is never executed as a flow.
user-invocable: false
---

# **Skill: Forge Principles**

## **Purpose**

This skill exists because a structurally perfect artifact can still behave badly. An agent file can pass every template checklist and still drift — its constraints phrased as prohibitions the model activates rather than suppresses, its one load-bearing rule buried mid-list where attention is thinnest. Structure is necessary and not sufficient. This skill owns the rest: the **wording** — whether the instructions inside an artifact are written in a way a model will actually follow.

This is a **reference, not a pipeline**. It has no phases and is never executed as a flow. God loads it before writing artifact content (Production in creation/update pipelines; Intake in validation) and applies its Review Lens during every review pass (Self-review in creation/update; Evaluation in validation).

Every principle below is a **tradeoff axis with two failure poles**, not a law. Applied deliberately, they raise artifact quality on the first draft. Applied dogmatically, they become their own failure mode — which is why each names both poles and a heuristic for leaning, never a rule.

## **How to Apply**

- **Deliberately, not dogmatically.** Name the principle in your reasoning when it drives a design decision. A principle that does not bite on this artifact is not invoked — the same discipline the domain agents apply to their Engineering and Architecture Principles.
- **As axes, not switches.** Each principle has two failure poles. The skill is leaning the right way for the artifact in hand, not maximizing one end. "More specific" and "more explicit" are not universally better — they have costs, named below.
- **At two moments.** Consult before writing artifact content, to shape it; consult again during adversarial Self-review, to attack the draft against each principle as a review dimension.
- **Under a clear precedence.** These principles govern *how* content is written; the artifact's structural template governs *what sections exist*. When they appear to conflict, the template wins on section shape, the principles win on wording within a section.

## **Authoring Principles**

| Principle | The tension | Heuristic — lean which way |
|---|---|---|
| **Goal over procedure** | Micro-steps give false control: models interpret intent from the whole instruction, they do not execute steps literally, and they break badly on non-linear or conditional step logic. But pure goals underspecify and drift. | Specify the **outcome and the why**. Use ordered steps only for genuinely sequential work. Never encode branching ("if X do A, else B") as prose steps — split it structurally. |
| **Specificity budget** | Vague instructions produce generic, inconsistent artifacts. Over-specified ones dilute attention, invite over-engineering, and turn brittle on inputs you did not anticipate. | Be specific about what **matters** (output shape, success criteria, hard constraints); stay **silent** on what does not. Specific is not the same as long. |
| **Instruction load is a cost** | Every directive spends the model's finite attention. Adherence drops non-linearly as directives accumulate, and earlier ones crowd out later ones. | **Prune ruthlessly.** Push detail into on-demand skills rather than inlining it. Fewer load-bearing rules beat a long list of small ones. |
| **Position the load-bearing rules** | The middle of a long section is the dead zone; the start and end carry the most weight. | Put the **highest-stakes, most-violated** directive at the **top or bottom** of a section — never buried mid-list. |
| **Instruct positively** | "Don't do Y" is fragile — the model must represent Y to suppress it, and often does Y anyway. "Do X" steers reliably. | Prefer **positive directives**. When you must prohibit, **pair it with the desired alternative** ("instead, do Z") — never a bare prohibition. |
| **Attach the why** | A bare rule is discarded the moment the model judges it inapplicable. A rule carrying its reason generalizes to edge cases and resists erosion. | Give each constraint its **failure mode** ("…because Y breaks"). Reserve reasons for rules that bite — do not justify trivia. |
| **Show the shape, don't over-fit it** | One concrete example conveys format better than paragraphs. But examples **anchor hard** — the model copies surface patterns, including incidental ones. | Use **representative** examples for format and shape; vary them; avoid edge-case examples unless the edge is the point. Do not over-constrain a role. |
| **Structure for navigation, not ceremony** | Consistent sections, tables, and headers help the model locate and parse. Rigid structure over-constrains, and its marginal value shrinks as models improve. | Structure for **findability and consistency**. Do not add structure that does not earn its tokens. |
| **Author for consistency; state precedence** | Contradictory instructions degrade behavior sharply, and the model cannot reliably arbitrate which one wins. | Hunt contradictions across sections. When two rules **can** conflict at runtime, **declare which wins** rather than leaving it to the model. |
| **Pointer over payload** | Inlining content is immediate and self-contained. But output whose size scales with the *work* rather than the *question* becomes unusable exactly when the work is largest. | Inline what is **bounded**; point at what is not. A file list, a directory tree, a full document — give the stat or the path, never the contents. |

> Apply deliberately. A principle that does not bite on this artifact is not invoked.

## **Applying Each Principle**

Compact guidance for authoring artifacts, with the reason each principle holds. This is the "why" the table omits for brevity.

- **Goal over procedure.** Models internalize step lists as a sequential pattern, not a reasoning skill — accuracy collapses (measured up to ~72%) the moment steps must be traversed out of order, and no amount of step-by-step phrasing guarantees the steps were actually followed. When authoring a pipeline phase, write the phase Goal and intent-level Actions; let branching live in the Flow diagram and decision nodes, never in prose "if/else" steps.

- **Specificity budget.** Instruction adherence falls as instruction density rises — even strong models drop toward ~68% when saturated — and the attention spent on a low-value directive is attention taken from a high-value one. When authoring, specify the artifact's output shape and hard constraints precisely; leave the model latitude everywhere the exact method does not matter.

- **Instruction load is a cost.** The *count* of directives is itself a tax, independent of their individual quality, and degradation begins well before any context limit. This is the empirical case for the system's own progressive-disclosure design: keep the always-loaded surface lean, and put depth in skills the agent loads only when the work demands it.

- **Position the load-bearing rules.** Models weight the beginning and end of a section far more than its middle, and favor earlier directives when they conflict. Place the constraint whose violation would cascade — the pipeline-discipline rule, the security invariant — at a section edge, not its interior.

- **Instruct positively.** To follow "do not do Y," the model must first activate Y, which frequently produces Y — negated instructions fail dramatically where their positive equivalents hold. Convert every prohibition in an authored artifact into a positive directive plus, where a boundary is genuinely needed, the alternative the agent should take instead. A bare "you never X" is weaker than "when tempted to X, do Z."

- **Attach the why.** A constraint paired with the failure mode it prevents survives contact with edge cases the author did not foresee; a bare constraint is dropped when the model decides it does not apply. This is already the house standard for Avoid items ("— because …"); this principle generalizes it to every constraint worth keeping.

- **Show the shape, don't over-fit it.** Examples are the highest-bandwidth way to convey format, but anchoring is strong and grows with model capability — the model mimics whatever the example happens to contain, including accidents. Choose examples that are representative rather than exceptional, vary them so no single incidental pattern dominates, and keep role framing general enough that the example illustrates without narrowing.

- **Structure for navigation, not ceremony.** Section headers, tables, and consistent ordering let a model find what it needs and let God itself reason over a uniform fleet — real value. But structure past the point of findability is cost without return, and its payoff shrinks as models improve. Keep the uniform template; resist adding structure that exists only to look rigorous.

- **Author for consistency; state precedence.** Conflicting directives are among the most damaging defects because the model cannot reliably choose between them and will apply them inconsistently. During Self-review, read the draft specifically for Identity-versus-Constraints and Constraints-versus-Pipeline contradictions. Where two rules can legitimately collide at runtime, write the tie-breaker explicitly rather than trusting the model to infer it.

- **Pointer over payload.** The test is whether a field's cost tracks the question or the work: a count, a stat, and a path are fixed; a list, a tree, and a document are not. Unbounded output is worst precisely when it matters most — the run with a hundred changed files is the one where the summary needs to stay readable, and a render re-emitted at several points multiplies its cost by the number of emissions. This governs both directions and the same defect appears at each: an instruction that has an agent enumerate its *inputs* (a recursive listing to discover what exists) and one that has it enumerate its *outputs* (every changed file in a summary) fail identically. Author the stat, the count, or the path, and let the reader open what they need.

## **Review Lens**

During adversarial Self-review, attack the draft against these dimensions, reading the file back rather than reviewing from memory:

- [ ] Are procedural steps reserved for genuinely sequential work, with branching pushed to structure rather than prose?
- [ ] Is every specified detail load-bearing, or is the artifact over-specified past what the task needs?
- [ ] Could any section be shorter without losing a rule that bites? Is depth pushed to on-demand skills?
- [ ] Is the most critical directive of each section at its edge, not buried in the middle?
- [ ] Is every prohibition either converted to a positive directive or paired with an alternative?
- [ ] Does every constraint that bites carry its reason?
- [ ] Are examples representative and varied, not edge-cases the model will over-fit?
- [ ] Does the structure aid navigation, or is any of it ceremony?
- [ ] Are there contradictions across sections, and is precedence stated wherever two rules can collide?
- [ ] Does every instruction that produces output bound its size, pointing at whatever scales with the work?

## **Scope & Boundaries**

- **Applies to every artifact God forges** — agent files, pipeline skills, plan templates, handoff skills, MDC rule sets. It is the shared craft layer beneath all of them.
- **HITL gate design is out of scope here.** The principles for *where and how many* human gates a flow should carry are a pipeline-authoring concern and live in `forge-pipeline`. Consult them when the artifact being authored is an interactive pipeline; this skill governs instruction wording, not gate topology.
- **These principles are priors, not universal laws.** Treat them as strong defaults, and prefer confirming a wording choice empirically over trusting the prior when the stakes are high.
- **The principles interact.** "Attach the why" spends tokens against "Instruction load"; "Show the shape" aids specificity but risks anchoring. They are a system of tradeoffs, not independent switches — which is why every one is framed as an axis with a heuristic, never a fixed rule.