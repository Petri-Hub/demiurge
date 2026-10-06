---
name: teacher-source-registry
description: Teacher's living registry of trusted learning sources — channel types, per-channel heuristics, and the user's registered favorites. Loaded at the start of every study session before proposing a source strategy. Updated by Teacher only with the user's explicit approval.
user-invocable: false
---

# **Skill: Teacher — Source Registry**

## **Purpose**

This registry encodes the user's taste in learning material so every study session starts from earned trust instead of a cold web search. Teacher reads it before proposing any source strategy, weighs registered sources first, and treats the channel heuristics as the playbook for where a given kind of question is best answered.

The registry is a **starting bias, not a cage**. A topic the registry covers poorly still deserves a full search — the registry tells you where quality has been found before, not where it is allowed to exist.

## **How to Use**

- Load at session start, before the source-strategy proposal.
- Match the topic's *need* to a channel type using the heuristics below, then propose the mix — the user picks.
- Registered sources are pre-vetted: they can go on a shortlist without a spot-check. Everything else gets a WebFetch look before it is proposed.
- Prefer publicly accessible pages — NotebookLM ingests URLs server-side without the user's login, so paywalled articles arrive as teasers. For paywalled newsletters, use their free issues or archive pages.

## **Channels**

### **Newsletters — deep dives and industry analysis**

Reach for these when the topic benefits from a practitioner's long-form analysis: how real companies build, organizational patterns, industry shifts.

| Source | Why it's registered |
|---|---|
| [The Pragmatic Engineer](https://newsletter.pragmaticengineer.com/) — Gergely Orosz | First-hand big-tech engineering analysis; the strongest signal on how serious teams actually work. Paywalled issues — use free posts |
| [ByteByteGo](https://blog.bytebytego.com/) — Alex Xu | System design broken into clear diagrams; ideal seed material for audio explanations |

### **Engineering blogs — how it's built at scale**

Reach for these when the topic is architecture, scale, reliability, or a real-world case study. These teams publish trade-offs and failures, not theory.

| Source | Why it's registered |
|---|---|
| [Netflix TechBlog](https://netflixtechblog.com/) | Resilience, chaos engineering, microservices — scale lived, not described |
| [Meta Engineering](https://engineering.fb.com/) | Deep infrastructure posts — study material, not casual reads |
| [Uber Engineering](https://www.uber.com/blog/engineering/) | Real-time systems and data platforms |
| [Dropbox Tech](https://dropbox.tech/) | One of the best monolith-to-distributed migration stories in public |
| [AWS Architecture Blog](https://aws.amazon.com/blogs/architecture/) | Named design patterns with reference implementations |
| [martinfowler.com](https://martinfowler.com/) | Canonical vocabulary for architecture and refactoring — the definitions other sources assume |
| [luminousmen.com](https://luminousmen.com/) | Clear, language-neutral systems fundamentals — I/O models, blocking vs non-blocking, async; strong ground-up teaching for newcomers to a concept |

### **YouTube — talks, current discussion, spoken-word depth**

Reach for these when the user wants what people are talking about right now, or when a conference talk covers the topic better than any article. YouTube links ingest natively into NotebookLM.

| Source | Why it's registered |
|---|---|
| [GOTO Conferences](https://www.youtube.com/@goto) | 40–60 min talks by the people who wrote the books — Fowler, Newman, Ford, Richards |
| [Continuous Delivery](https://www.youtube.com/@ContinuousDelivery) — Dave Farley | Architecture and delivery discipline from decades of practice, trend-resistant |
| [CodeOpinion](https://www.youtube.com/@CodeOpinion) | Ten-minute cuts through architecture hype — strongest on messaging, CQRS, event-driven patterns |
| [Hussein Nasser](https://www.youtube.com/@hnasr) | The layers most content skips — protocol behavior, database internals, proxies |
| [Hello Interview](https://www.youtube.com/@hello_interview) | Modern system design walkthroughs with high production quality |

### **Subreddits — the current pulse**

Reach for these when the question is "what are practitioners saying about X right now" — sentiment, war stories, and what's actually being adopted versus marketed. Use top threads as sources or as leads to the articles they discuss.

| Source | Why it's registered |
|---|---|
| [r/ExperiencedDevs](https://www.reddit.com/r/ExperiencedDevs/) | Senior-level discussion without beginner noise — staff engineers and EMs on real trade-offs |
| [r/softwarearchitecture](https://www.reddit.com/r/softwarearchitecture/) | Focused architecture discussion and design critiques |
| [r/programming](https://www.reddit.com/r/programming/) | Broad pulse — what the industry is reading this week |

### **Book content — foundational depth without the full read**

Reach for these when a topic has a defining book and the user wants its core ideas in listenable form. Prefer detailed long-form reviews and chapter-level summaries over teaser blurbs — a good review engages the argument; a blurb repeats the cover.

| Source | Why it's registered |
|---|---|
| Search: `"{book title}" detailed summary` / `"{book title}" review` | The best summary of a famous book is usually a practitioner's long-form review on their own blog — find it per book |
| [StoryShots](https://www.getstoryshots.com/) | Free structured summaries when no strong long-form review exists |

### **Medium — practitioner articles, variable quality**

The user's stated channel. Quality varies widely — vet the author's track record and the article's depth before shortlisting; a publication tag is not a quality guarantee.

| Source | Why it's registered |
|---|---|
| [Javarevisited](https://medium.com/javarevisited) | Consistent system-design and career content; curated publication |

## **Maintenance**

- **Additions:** when a session proves a new source excellent — the user says so, or its material clearly carried the notebook — propose registering it with the channel, link, and a one-line "why". Write it here only after the user approves.
- **Removals:** when the user repeatedly cuts a registered source from shortlists, propose retiring it. Taste drifts; the registry follows the user, never argues with them.
- **Format:** every entry keeps the two-column shape — source (linked) and the reason it earned registration. An entry without a reason is a name, not a recommendation.
