---
name: writing-adr
description: Write an Architecture Decision Record (ADR) — lead with the decision, give neutral context, and state consequences both ways. Use when recording an architectural or technical decision, documenting why a choice was made, or capturing tradeoffs for future maintainers.
---

# ADR Writing

An ADR captures a decision and the forces behind it, so a future maintainer doesn't
have to reverse-engineer "why is it like this?" from the code. It is a log entry, not
a monument. (For proposing a change still under debate, use `writing-rfc`.)

## The rules that govern everything

**Lead with the decision.** State it in the first lines, in active voice ("We will…").
Context and justification follow. Don't bury the conclusion under the analysis.

**State consequences both ways.** What becomes easier *and* what becomes harder, what
you now owe. The honesty of the "harder" half is what makes the record trustworthy.

**Append-only.** A record is not edited away when it's overturned. Set the old ADR's
status to `Superseded by ADR-NNN` and link forward; preserve the original reasoning.

## Skeleton

1. **Title** — `ADR-NNN: <the decision, as a short imperative>`.
2. **Status** — Proposed / Accepted / Superseded by ADR-NNN · date.
3. **Context** — the forces at play: requirements, constraints, what's true today.
   Concrete and neutral. No solution yet — just the situation that demands one.
4. **Decision** — one or two sentences, active voice: "We will…".
5. **Consequences** — what becomes easier, what becomes harder, what we now owe. Both
   directions. This is where the honesty lives.

Optionally add **Alternatives considered** (each with an honest why-not) when the
rejected options carry real weight, and **Non-goals** to bound scope.

## Filling it well

- Keep Context free of the answer — describe the problem so neutrally that a reader
  could reach a different decision from the same facts.
- Quantify the forces: the throughput need, the cost, the on-call burden — not just
  "performance mattered."
- The Decision is a hammer: short, declarative, unambiguous.
- In Consequences, name the thing you now owe (the new dependency, the manual step,
  the migration) before someone discovers it the hard way.
- Link to the implementation, related ADRs, and any RFC that led here.

## Checklist

- [ ] Decision stated in the first lines, active voice.
- [ ] Status and date present; supersession linked if applicable.
- [ ] Context is concrete, neutral, and solution-free.
- [ ] Consequences cover both easier and harder.
- [ ] Forces quantified where possible.
- [ ] Alternatives noted if they carry weight, each with a why-not.
- [ ] Links to implementation and related records.
