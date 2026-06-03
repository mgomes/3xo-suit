---
name: writing-technical
description: Write clear technical documents — design docs, PR descriptions, proposals, postmortems — that lead with the decision and ground every claim in specifics. Use when drafting or editing workplace technical writing where a reader must act or later understand why. For the specific RFC and ADR formats, use writing-rfc and writing-adr.
---

# Technical Writing

Good writing belongs in technical documents as much as in essays. The craft is the
same — concrete over abstract, plain words, claims grounded in specifics,
intellectual honesty — but one core move flips.

## The one big inversion: lead with the answer

An essay opens cold and arrives at its thesis at the end. **A work document states
its conclusion first (BLUF — bottom line up front), then justifies it.** Reviewers are
busy; respect the skim. Suspense is an essay tool; in a work doc it's a tax.

> **Buried:** "We evaluated Postgres, DynamoDB, and Cassandra… and landed on Postgres."
>
> **BLUF:** "**Decision: use Postgres.** It meets our throughput needs with the least
> operational burden. The rest of this doc explains why, and what we gave up."

## Principles

- **Concrete problem statement.** Open on a real symptom, error, or metric — what's
  broken, blocked, or needed. Not an abstract framing.
- **Quantify every claim.** Latency, p99, cost/month, error rate, throughput, blast
  radius. Never "this is faster" without the number.
- **Cite prior art and precedent** instead of historical analogy — how we solved this
  before, what others ship, the last incident.
- **Informative headers**, never `Section 2`. A reader should skim the headers and get
  the gist.
- **Homely analogy, then specifics**, to make a mechanism legible. Prefer a small
  worked example or diagram over a paragraph. Define every acronym on first use.
- **Honesty is the structure, not a footnote.** State the alternatives you rejected
  (steelmanned, not strawmen), the drawbacks, the blast radius, and what you don't
  know. A proposal with no stated downsides reads as unconsidered.
- **Deliberate rhythm carries over.** Unspool the mechanism in a long sentence, land
  the consequence in a short one. A one-line decision statement is a hammer.
- **Link generously** — to prior art, related decisions, tickets, dashboards.
- **Voice:** "We will…" for team decisions; "I recommend…" when you own the call and
  want that visible. Active voice, contractions fine.

## Document types

- **Design doc / proposal** → use `writing-rfc`.
- **Decision record** → use `writing-adr`.
- **PR description** — lead with **what** changed and **why** (the diff shows the
  what; the why is the point). Note downstream impact, what to review hardest, and how
  it was verified. Keep it short; link the RFC/ticket for depth.
- **Postmortem** — blameless. Timeline in specifics; root cause without scapegoating
  ("human error" is a stop sign, not a cause); action items with owners.

## What to drop from essay style

No cold open or narrative throat-clearing — the first line carries information. No
reader address, no date/place sign-off. Trim vintage colloquialisms; a dry
parenthetical aside is fine, sparingly, and never at the cost of clarity. Don't
withhold the point for effect.

## Checklist before review

- [ ] Decision / summary in the first few lines (BLUF).
- [ ] Problem stated concretely, with a symptom or metric.
- [ ] Real alternatives, each with an honest why-not.
- [ ] Drawbacks, risks, and blast radius named.
- [ ] Claims attached to numbers or precedent.
- [ ] Jargon defined; an analogy where it helps.
- [ ] Informative headers; survives a 30-second skim.
- [ ] Links to related docs/tickets/dashboards.
- [ ] Rollback / verification plan where relevant.
- [ ] Write for the maintainer debugging this in two years.
