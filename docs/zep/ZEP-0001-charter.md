# ZEP-0001: The Zag Language Charter

| Field   | Value                          |
|---------|--------------------------------|
| ZEP     | 0001                           |
| Title   | The Zag Language Charter       |
| Author  | zag contributors               |
| Status  | Accepted                       |
| Type    | Process                        |
| Created | 2026-03-02                     |
| Updated | 2026-03-02                     |

---

## Abstract

This ZEP establishes zag's identity, goals, and the process by which the language evolves. It is the founding document of the project.

**zag is built by AI, for AI** — and for the humans who work alongside them.

## What zag is

zag is a systems programming language that started as a divergent fork of Zig. It inherits Zig's core philosophy:

- **Explicit over implicit.** No hidden control flow, no hidden allocations.
- **One obvious way to do things.** Simplicity at the syntax level; power at the semantics level.
- **Errors are values.** No exceptions; error handling is part of the type system.
- **Comptime over macros.** Metaprogramming through compile-time execution, not a separate macro language.

## Built by AI, for AI

zag is designed from the ground up to be a language that AI agents can read, reason about, and write correctly — not as a secondary concern, but as a primary design goal.

This means:

- **Unambiguous grammar.** Every construct parses one way. No context-sensitive rules, no operator precedence surprises.
- **Explicit semantics.** What you see in source code is what happens at runtime. Agents don't need to model invisible compiler magic.
- **Machine-readable toolchain.** The compiler, build system, and standard library expose structured, stable interfaces that agents can call programmatically.
- **Documented evolution.** Every language change goes through a ZEP. An agent reading the ZEP history can reconstruct why the language is the way it is.

The practical consequence: zag code written by an AI agent should be indistinguishable from code written by a skilled human. That is the bar.

## Co-developed by humans and AI

zag is not built *for* AI at the expense of humans. It is built *with* AI, as a co-author from day one.

- Human and AI contributors propose, review, and implement features together through the ZEP process. A ZEP stands or falls on its reasoning, not on who wrote it.
- Because AI agents can implement accepted ZEPs rapidly, the gap between "accepted proposal" and "shipped feature" shrinks significantly. We can afford to be more deliberate about design because implementation velocity is high.
- The language and toolchain are kept legible to humans. If a human can't read it, an agent shouldn't write it.

## What zag is becoming

zag evolves Zig's foundations through a structured proposal process. The language grows in the directions its contributors — human and AI — define through ZEPs.

### First milestone: async

The first substantive evolution beyond Zig is a **proper async structure** (see ZEP-0002, forthcoming). Zig's async/await story has been in flux; zag will define and stabilize it.

## What zag is not

- zag is not a scripting language.
- zag is not a Zig distribution or a Zig compatibility layer.
- zag is not designed for backwards compatibility with Zig. Zig was the launch point; zag has its own trajectory.
- zag is not an AI runtime. It does not ship an LLM or agent framework. It is a language that agents author.

## Design Principles

1. **Built by AI, for AI — and for humans.** Legibility is a hard constraint in both directions.
2. **Syntax changes require a ZEP.** No ad-hoc evolution.
3. **Every accepted ZEP ships with a spec update.** The spec and compiler stay in sync.
4. **Breaking changes are explicit.** A ZEP that breaks existing programs must say so and provide a migration path.
5. **Implementation velocity is an asset.** Use it to be more deliberate about design, not less.

## The ZEP Process

A **Zag Enhancement Proposal (ZEP)** is the primary mechanism for proposing language changes, new features, and process improvements.

### ZEP Types

| Type      | Used for                                              |
|-----------|-------------------------------------------------------|
| Language  | Changes to syntax, semantics, or the type system      |
| Toolchain | Changes to the compiler, build system, or package manager |
| Process   | Changes to how zag is developed (like this ZEP)       |

### ZEP Lifecycle

```
Draft → Review → Final Council Vote → Accepted | Rejected | Withdrawn
```

| Status      | Meaning                                                       |
|-------------|---------------------------------------------------------------|
| **Draft**   | Work in progress. Author is actively shaping the proposal.    |
| **Review**  | Ready for community feedback. Author considers it complete.   |
| **Accepted**| Approved. Implementation may proceed.                         |
| **Rejected**| Declined. Rationale must be recorded in the ZEP.             |
| **Withdrawn**| Author withdrew the proposal.                                |
| **Final**   | Implemented and shipped. Spec has been updated.               |
| **Superseded**| Replaced by a later ZEP.                                   |

### Rules

- A ZEP number is assigned when a PR is opened. Numbers are not recycled.
- Any contributor may write a ZEP.
- A ZEP moves from Draft → Review when the author opens a PR and marks it `status: review`.
- A ZEP moves to Accepted only after a designated review period (minimum 7 days in Review) and a decision by the language council.
- Implementation without an accepted ZEP is not merged for language-level changes.

### What does not need a ZEP

- Bug fixes
- Performance improvements with no observable behavior change
- Documentation and tooling improvements
- Standard library additions that add no new syntax

## Architecture Decision Records

Internal decisions that are not language-facing (e.g. compiler architecture, IR design, build system internals) are recorded as **ADRs** in `docs/adr/`. ADRs do not require community review but must be written before the decision is implemented.

## Open Questions

None. This is the founding document.

---

## Status History

| Date       | Status   | Note            |
|------------|----------|-----------------|
| 2026-03-02 | Accepted | Founding charter |
