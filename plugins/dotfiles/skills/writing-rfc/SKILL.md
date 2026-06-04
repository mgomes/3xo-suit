---
name: writing-rfc
description: Write an RFC or design doc — summary-first, with goals/non-goals, real alternatives, drawbacks, and open questions. Use when proposing a technical change for review, writing a design doc, or documenting a system or feature proposal before building it.
---

# RFC / Design Doc Writing

An RFC argues a proposal and its alternatives before you build. It is for a change
worth thinking through in the open. (For recording a decision already made, use
`writing-adr`; for general technical writing principles, `writing-technical`.)

## The rule that governs everything

**Lead with the answer (BLUF).** The Summary states the proposal in full; a reader who
stops there still knows what and why. Don't make reviewers excavate the point.

**Honesty is the structure, not a footnote.** The Alternatives, Drawbacks, and Open
Questions sections are where the document earns trust. A proposal with no stated
downsides reads as unconsidered, not as strong. Steelman what you rejected.

## Skeleton

1. **Title** — `RFC-NNN: <imperative summary>`.
2. **Status** — Draft / Under review / Accepted / Rejected · date · author.
3. **Summary** — the proposal in 3–5 sentences. Self-contained.
4. **Motivation / Problem** — concrete, with the symptom or metric that forced it.
5. **Goals & Non-goals** — bound the scope explicitly. Non-goals prevent scope creep
   and review noise; they are not optional.
6. **Proposed design** — the mechanism in plain language. Define jargon; prefer a
   small worked example or diagram. Quantify (latency, cost, throughput).
7. **Alternatives considered** — real options, each with an honest why-not. Not
   strawmen. The reader should trust you argued against yourself.
8. **Drawbacks / Risks** — what this costs, what could go wrong, blast radius.
9. **Open questions** — what you don't know yet, and what evidence would resolve each.
10. **Rollout / migration** — steps, fallbacks, and how you'll know it worked.

## Filling it well

- Every claim attached to a number or precedent — not "faster," but "4× write spike
  at launch, drains in minutes."
- Headers are the skeleton above; keep them so reviewers can navigate by convention.
- A non-goal that says what you're explicitly *not* solving is worth a paragraph of
  prevented debate.
- For open questions, name the experiment or data that would settle each one. End with
  the question that decides whether to ship at all.
- Rollout should let a reader reverse the change: fallback, rollback, verification.

## Checklist

- [ ] Summary is self-contained and first.
- [ ] Problem is concrete, with a metric or symptom.
- [ ] Goals **and** non-goals are explicit.
- [ ] Alternatives are real and steelmanned, each with a why-not.
- [ ] Drawbacks, risks, blast radius named.
- [ ] Open questions list what would resolve them.
- [ ] Rollout includes fallback and verification.
- [ ] Claims quantified; jargon defined; links to related RFCs/ADRs/tickets.
