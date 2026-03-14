# Zag

Zag is a fork of Zig 0.15.2 focused on a different concurrency model.

The short version: Zag is exploring zero-infection structured concurrency.
That means concurrency should live at the call site, not in function
signatures. We do not want `async fn` coloring, and we do not want an `Io`
parameter threaded through every layer of a program just because some leaf
needs to block.

The current design direction is tracked in [issue #1](https://github.com/justrach/zag/issues/1):
ZEP-0002 Structured Async.

## Why Zag Exists

Zag exists to test a language and runtime thesis:

- Functions should stay plain functions.
- Concurrency should be introduced by spawning work, opening a scope, or
  waiting on a channel at the call site.
- Cancellation should be runtime state, not parameter infection.
- Structured concurrency should be the default, not an afterthought.
- The compiler and toolchain should support this direction directly, rather
  than forcing application code to simulate it with ceremony.

The motivating argument is laid out in the early design issues:

- [#1](https://github.com/justrach/zag/issues/1) tracks ZEP-0002 and the core
  fiber-based structured async proposal.
- [#3](https://github.com/justrach/zag/issues/3) documents the practical cost
  of function coloring, drawing on systems like Codex, Symphony, and opencode.
- [#4](https://github.com/justrach/zag/issues/4) tracks the Phase 1 runtime:
  fibers plus a work-stealing scheduler.

The design position is straightforward:

- Zig upstream is moving toward explicit I/O capability passing.
- Zag is intentionally exploring the opposite direction.
- We want a stackful, fiber-oriented model that preserves direct style and
  keeps APIs reusable.

## Current Direction

Zag is currently a forked compiler/toolchain based on Zig 0.15.2.

The repo is in a transition state:

- the codebase was refreshed onto the upstream 0.15.2 compiler sources
- Zag-specific compiler work is being reapplied on top of that base
- the runtime model proposed in ZEP-0002 is not fully implemented yet
- some macOS ARM64 self-hosted backend work is still in progress

So this is not a finished language release. It is an active fork being shaped
around a specific concurrency agenda.

## What Has Landed So Far

Two user-visible changes are already in the tree:

- `.zag` source files are accepted alongside `.zig`
- the CLI and formatter know about `.zag`

That means the compiler currently accepts both:

- `.zig`
- `.zag`

The goal of `.zag` support right now is transitional compatibility while the
language and runtime direction are being worked out.

## Planned Model

The current proposal in issue `#1` is centered on:

- fibers rather than stackless async coloring
- structured scopes for task lifetime management
- work-stealing scheduling across worker threads
- cancellation without parameter threading
- a single-thread fallback for constrained or test contexts

In other words, Zag is trying to preserve Zig-style direct code while gaining
modern structured concurrency semantics.

## Status

What works today:

- the compiler builds on the refreshed 0.15.2 base
- `.zag` root files compile
- LLVM-enabled macOS builds work with the Homebrew Polly flag described below

What is still incomplete:

- the Phase 1 fiber runtime from issue `#4`
- full end-to-end validation of the non-LLVM macOS ARM64 backend path
- proper public language/runtime documentation for the Zag-specific model
- release packaging and a polished install story

The main tracked backend blocker right now is:

- [#13](https://github.com/justrach/zag/issues/13) macOS ARM64 standalone
  simple suite hitting AArch64 codegen failures on the 0.15.2 baseline

## Building Zag

Zag currently builds from source. There is not yet a polished binary release
channel specific to Zag.

The current tree identifies itself against Zig 0.15.2 in `build.zig`. 

A typical development build is:

```sh
zig build -Dno-lib -Dno-langref
```

If you want the LLVM-enabled path on macOS with Homebrew LLVM/LLD, the tree now
supports an explicit Polly flag:

```sh
zig build \
  -Denable-llvm=true \
  -Dllvm-has-polly=true \
  --search-prefix /opt/homebrew/opt/llvm@20 \
  --search-prefix /opt/homebrew/opt/lld@20
```

That `-Dllvm-has-polly=true` option exists because Homebrew's LLVM packaging on
macOS needs extra help when linking the system LLVM stack.

## Using `.zag`

The compiler currently treats `.zag` as Zag source code and routes it through
the same source pipeline as `.zig`.

Examples:

```sh
zig build-exe hello.zag
zig test math.zag
zig fmt src/
```

The formatter, import handling, and file classification have already been wired
so `.zag` and `.zig` can coexist during the transition.

## Repository Shape

This repository is still mostly upstream Zig compiler source plus targeted Zag
changes.

That is intentional for now. The goal is to keep rebasing possible while the
fork proves out the runtime and language direction.

You should read the repo as:

- upstream Zig 0.15.2 base
- plus Zag-specific compiler behavior
- plus ongoing runtime/backend experiments needed to support the model

## Contributing

If you want to work on Zag, the most important thing is to understand the design
intent before changing compiler code.

Start here:

- [#1](https://github.com/justrach/zag/issues/1) for the structured async thesis
- [#3](https://github.com/justrach/zag/issues/3) for the argument against
  function coloring
- [#4](https://github.com/justrach/zag/issues/4) for the runtime implementation
  roadmap
- [#12](https://github.com/justrach/zag/issues/12) for the preserved pre-refresh
  branch context
- [#13](https://github.com/justrach/zag/issues/13) for the current macOS ARM64
  backend blocker

Contributions are most useful when they align with that agenda rather than
pushing Zag back toward upstream Zig's concurrency model.

## Summary

Zag is not trying to be "Zig with a different file extension".

Zag is a fork of Zig pursuing a different answer to async and concurrency:
plain functions, structured scopes, fiber-based scheduling, and a toolchain that
accepts `.zag` while that model is being built out.
