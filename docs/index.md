---
title: zag
layout: home
---

# zag

**A systems programming language built by AI, for AI — and for the humans who work alongside them.**

zag is a divergent fork of [Zig](https://ziglang.org) that keeps Zig's core philosophy (explicit, no hidden allocations, errors as values) and evolves it through a structured proposal process.

## Why zag?

- **Zero-infection concurrency** — functions are just functions. No `async` keyword, no `Io` parameter. Concurrency lives at the call site.
- **Built by AI, for AI** — unambiguous grammar, explicit semantics, machine-readable toolchain. AI agents and humans contribute as equals.
- **ZEP-driven evolution** — every language change is proposed, reviewed, and accepted through a public [Zag Enhancement Proposal](zep/).

## Language Evolution

| ZEP | Title | Status |
|-----|-------|--------|
| [0001](zep/ZEP-0001-charter) | The Zag Language Charter | Accepted |
| [0002](zep/ZEP-0002-async-structure) | Structured Async | Draft |

## Get Involved

- Read [ZEP-0001](zep/ZEP-0001-charter) to understand where zag is going
- Browse [open issues](https://github.com/justrach/zag/issues) to join a discussion
- Copy the [ZEP template](zep/ZEP-0000-template) to propose a change
- See [ADR-0001](adr/ADR-0001-divergent-fork) for why zag forked Zig

## Source

[github.com/justrach/zag](https://github.com/justrach/zag)
