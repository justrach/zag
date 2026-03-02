# ZEP-0002: Structured Async

| Field    | Value                                                |
|----------|------------------------------------------------------|
| ZEP      | 0002                                                 |
| Title    | Structured Async                                     |
| Author   | zag contributors                                     |
| Status   | Draft                                                |
| Type     | Language                                             |
| Created  | 2026-03-02                                           |
| Updated  | 2026-03-02                                           |
| Requires | —                                                    |

---

## Abstract

This ZEP defines zag's async model: **structured, colorblind, and explicit**. It adopts Zig's `Io`-as-parameter approach (landed in Zig upstream PR #25592, now in our base), extends it with structured concurrency scopes, and makes cancellation first-class. The result is an async model that AI agents and humans can reason about correctly without hidden scheduler magic.

---

## Background: A Brief History of Coroutines

Understanding why zag's model looks the way it does requires knowing where coroutines came from and what each generation got wrong.

### 1958–1980: Birth and neglect

Melvin Conway coined "coroutine" in 1958 and first published the concept in 1963 in *Design of a Separable Transition-diagram Compiler*. The idea: program modules that communicate as peers — each thinking it is the master program, with no true master. Coroutines appeared in COBOL compilers and assembly programs but were largely forgotten as OS threads became mainstream in the 1980s–90s. Game development (Lua, Unity) kept them alive.

### 1990s–2010s: The callback era and its failure

OS threads scale poorly past thousands. The alternative — event loops with callbacks — is how Node.js, early browser JavaScript, and libevent-era C servers worked. Callbacks produce "callback hell": deeply nested, hard to reason about, difficult to debug, and nearly impossible for tools to analyze automatically.

### 2012–2018: async/await arrives

C# shipped `async`/`await` in 2012. JavaScript followed with Promises (ES6, 2015) and `async`/`await` (ES2017). Python adopted it in 3.5 (2015). The syntax was cleaner, but the underlying model created a new problem: **function coloring**, named by Bob Nystrom in his 2015 essay *"What Color is Your Function?"*.

In a colored system, every function is either sync (white) or async (red). You can call white from red, but not red from white — without special handling. This forces duplicate APIs (blocking and async variants of the same library), viral refactoring when a function deep in a call stack needs to become async, and cognitive overhead for anyone reading the code.

### Language-by-language survey

| Language   | Model               | Stackful? | Coloring?  | Runtime?  | Key strength            | Key weakness                     |
|------------|---------------------|-----------|------------|-----------|-------------------------|----------------------------------|
| **Go**     | Goroutines (M:N)    | Yes       | No         | Yes (GC)  | Simple to write         | Large per-goroutine stack, GC    |
| **Rust**   | Poll-based Futures  | No        | Yes        | No        | Zero-cost, no runtime   | Complex, viral, hard to read     |
| **Python** | asyncio event loop  | No        | Yes        | Yes       | Readable                | Single-threaded, GIL             |
| **JS**     | Promises + event loop | No      | Yes        | Yes       | Ubiquitous              | Colored, single-threaded         |
| **Kotlin** | Structured concurrency | No     | Yes (suspend) | Yes    | Scope safety, cancellation | JVM overhead                  |
| **C++20**  | Stackless coroutines | No       | Yes        | No        | Low-level control       | Extremely verbose, no stdlib     |
| **Zig (old)** | Colorblind async | No        | No         | No        | Single source, sync+async | Leaked through fn pointers      |
| **Zig (new)** | `Io` interface   | No        | No         | No        | Colorblind, no keywords  | Structured concurrency missing  |

### What Zig's new model gets right (and what it still lacks)

Zig's 0.15/0.16 async (PR #25592) threads an `Io` interface through functions that do I/O. Different `Io` implementations — `std.Io.Threaded`, `std.Io.Evented` — provide different execution models. The same source code works in both. `io.async()` spawns a future; `future.await(io)` resolves it. No `async`/`await` keywords on functions, no colored function types.

What it does not yet have:
- **Structured concurrency**: futures can be created but there is no scope that guarantees all futures are awaited before the scope exits.
- **Cancellation as a first-class concept**: a cancelled future must still be awaited; there is no mechanism to propagate cancellation through a tree of tasks automatically.
- **Error propagation across task boundaries**: if one parallel task fails, coordinating cleanup of sibling tasks requires manual bookkeeping.

zag's model addresses all three.

---

## Motivation

zag needs a stable async story for two reasons:

1. **Practical**: zag is a systems language. I/O-bound programs — servers, CLIs, build tools — are primary use cases. Without async, they either block or spawn OS threads for everything.

2. **Agent authorship**: AI agents generate async code more reliably when the model is consistent and explicit. A colored system forces agents to track function colors through a call graph. A system with implicit spawning and hidden cancellation produces agent-generated code that leaks tasks. zag's model must be auditable: an agent reading a function should be able to determine its concurrency behavior from local context alone.

---

## Non-Goals

- zag does not provide a built-in runtime or event loop. `Io` is always a parameter.
- zag does not implement Go-style goroutines with a managed scheduler and GC.
- zag does not provide coroutine-based generators (`yield`) in this ZEP. That is a separate proposal.
- This ZEP does not define the `std.Io.Evented` implementation. That is a follow-on.

---

## Specification

### 1. The `Io` interface (inherited from Zig, stabilized by zag)

Any function that performs I/O receives an `Io` parameter. This is the only coloring in zag: a function either takes `Io` or it does not, and that is visible in its signature.

```zig
// sync-capable function: takes Io, works under any Io implementation
fn readFile(io: Io, path: []const u8) ![]u8 { ... }

// no-Io function: provably synchronous and I/O-free
fn parseHeader(data: []const u8) !Header { ... }
```

`Io` is not a keyword type. It is an interface (a comptime-known vtable) defined in the standard library. User code may implement custom `Io` backends for testing, simulation, or novel execution models.

### 2. Futures

`io.async(func, args)` spawns a task and returns a `Future(T)`. A `Future(T)` is a resource — it must be awaited or explicitly cancelled before it goes out of scope.

```zig
var f = io.async(readFile, .{ io, "data.bin" });
const data = try f.await(io);
```

`Future(T)` is not heap-allocated by default. Under `std.Io.Threaded`, the future encapsulates a thread handle. Under `std.Io.Evented`, it is a suspended coroutine frame on a pool.

### 3. Structured Task Groups (zag addition)

The core zag extension: `io.group()` returns a `TaskGroup` scoped to a block. All futures spawned through the group are guaranteed to be resolved (awaited or cancelled) when the group scope exits — whether by normal return, early return, or error unwinding.

```zig
var group = io.group();
defer group.deinit(io); // awaits or cancels all outstanding futures

var f_a = group.async(io, saveFile, .{ io, data, "a.bin" });
var f_b = group.async(io, saveFile, .{ io, data, "b.bin" });

// Both futures are awaited here; if either errors, both are resolved
// before the error propagates.
try group.awaitAll(io);
```

`defer group.deinit(io)` is the structured concurrency guarantee. It is idiomatic to pair every `io.group()` with a `defer group.deinit(io)` on the next line, enforced by a compiler lint.

**Failure semantics:**

When one task in a group errors, `awaitAll` cancels the remaining tasks, collects the first error, and returns it. Remaining task errors after cancellation are discarded (logged in debug builds). This matches Kotlin's structured concurrency semantics.

```zig
var group = io.group();
defer group.deinit(io);

var f_a = group.async(io, fetchUrl, .{ io, url_a });
var f_b = group.async(io, fetchUrl, .{ io, url_b });

// If f_a errors, f_b is cancelled. The error from f_a is returned.
const results = try group.awaitAll(io);
```

### 4. Cancellation

Cancellation is modelled as an error: `error.Cancelled`. Any function that takes `Io` may receive a cancelled `Io` and must propagate the cancellation by returning `error.Cancelled` at the next suspension point.

```zig
fn fetchUrl(io: Io, url: []const u8) ![]u8 {
    const conn = try io.tcpConnect(url);  // returns error.Cancelled if io is cancelled
    const data = try io.read(conn);        // same
    return data;
}
```

A function does not need to check for cancellation explicitly. The `Io` methods handle it. This means:
- Cancellation is cooperative.
- Pure compute functions (no `Io` calls) are not cancellable — by design.
- Cancellation is not a signal; it is a structured error path that follows normal error unwinding.

### 5. Timeout

Timeouts are implemented as cancellation with a deadline, not as a separate mechanism.

```zig
var timed_io = io.withDeadline(std.time.nanoTimestamp() + std.time.ns_per_s * 5);
const data = try fetchUrl(timed_io, url); // errors with Cancelled after 5s
```

`io.withDeadline` returns a new `Io` that wraps the original and cancels at the deadline. It is a value type, not heap-allocated.

### 6. No hidden spawning

`io.async()` is the only way to spawn a concurrent task. There is no implicit parallelism, no work-stealing from bare function calls, no "green thread per request" model. Concurrency is always visible at the call site.

### 7. Executor implementations (standard library)

| Implementation          | Description                                          |
|-------------------------|------------------------------------------------------|
| `std.Io.Blocking`       | All operations block the calling thread. No concurrency. Default for CLI tools. |
| `std.Io.Threaded`       | Thread pool. `io.async()` submits to the pool. Good for CPU-bound tasks mixed with I/O. |
| `std.Io.Evented`        | Event loop (io_uring on Linux, kqueue on macOS, IOCP on Windows). WIP. |
| `std.Io.Test`           | Deterministic single-threaded executor for testing. |

All implementations satisfy the same `Io` interface. Swapping them requires changing one line at program startup.

---

## Examples

### Basic parallel I/O

```zig
const std = @import("std");

fn saveData(io: Io, alloc: Allocator, data: []const u8) !void {
    var group = io.group();
    defer group.deinit(io);

    _ = group.async(io, saveFile, .{ io, alloc, data, "backup_a.bin" });
    _ = group.async(io, saveFile, .{ io, alloc, data, "backup_b.bin" });

    try group.awaitAll(io);
}
```

### HTTP server handler (conceptual)

```zig
fn handleRequest(io: Io, alloc: Allocator, req: Request) !Response {
    var group = io.group();
    defer group.deinit(io);

    // Fetch user and permissions in parallel
    var f_user = group.async(io, db.getUser, .{ io, alloc, req.user_id });
    var f_perms = group.async(io, db.getPermissions, .{ io, alloc, req.user_id });

    const results = try group.awaitAll(io);
    const user = results.get(f_user);
    const perms = results.get(f_perms);

    return buildResponse(user, perms);
}
```

### Testing with deterministic Io

```zig
test "saveData writes two files" {
    var test_io = std.Io.Test.init();
    defer test_io.deinit();

    try saveData(test_io.io(), alloc, "hello");

    try std.testing.expect(test_io.fileExists("backup_a.bin"));
    try std.testing.expect(test_io.fileExists("backup_b.bin"));
}
```

### Timeout

```zig
fn fetchWithTimeout(io: Io, url: []const u8) ![]u8 {
    var timed = io.withDeadline(std.time.nanoTimestamp() + 10 * std.time.ns_per_s);
    return fetchUrl(timed, url) catch |err| switch (err) {
        error.Cancelled => error.Timeout,
        else => err,
    };
}
```

---

## Backwards Compatibility

- [ ] **Breaking change.**

Zig programs using the old stage1 async/await keywords (`async fn`, `await`, `suspend`, `resume`) will not compile — those keywords were already removed in Zig 0.11 and are not present in our fork base.

Zig programs using the new `io.async()` / `future.await(io)` pattern (Zig 0.15+) are compatible with this ZEP's `Future` API. `TaskGroup` is a zag addition with no Zig equivalent to conflict with.

Migration from raw `Future` to `TaskGroup`:

```zig
// Before (raw futures, manual bookkeeping):
var f_a = io.async(work, .{io, a});
var f_b = io.async(work, .{io, b});
const ra = try f_a.await(io);
const rb = try f_b.await(io);

// After (TaskGroup, structured):
var group = io.group();
defer group.deinit(io);
var f_a = group.async(io, work, .{io, a});
var f_b = group.async(io, work, .{io, b});
const results = try group.awaitAll(io);
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `TaskGroup` lifetime bugs (use after deinit) | Medium | High | Compiler lint: warn if group escapes its scope |
| Cancellation not propagated through third-party code | Medium | Medium | Document: code that does not take `Io` cannot be cancelled by design |
| `defer group.deinit(io)` forgotten | High | High | Compiler lint: `TaskGroup` without `defer deinit` in same scope is a warning |
| `std.Io.Evented` being WIP delays adoption | High | Low | `std.Io.Threaded` is fully functional; Evented is a perf optimization |
| Executor swap not obvious to newcomers | Medium | Low | `zag new` scaffold always generates `main` with explicit Io setup |

---

## Testing and Validation Plan

- [ ] `std.Io.Test` unit tests for all standard library async functions
- [ ] Compile-time tests: `TaskGroup` escaping scope → compile error
- [ ] Integration tests: parallel file I/O, parallel HTTP fetches (mock)
- [ ] Cancellation propagation tests: deadline fires, all tasks unwind correctly
- [ ] Fuzz test: arbitrary task failure order → no leaked tasks
- [ ] Benchmark: `std.Io.Threaded` vs `std.Io.Blocking` for N parallel reads

---

## Implementation Notes

1. `Io` is already an interface in the Zig upstream we forked. zag stabilizes its API (Zig may still change it; zag will not without a ZEP).
2. `TaskGroup` is implemented in `std/io/group.zig`. It holds an array list of `AnyFuture` (type-erased futures).
3. The "compiler lint" for forgotten `defer group.deinit` is implemented as a semantic analysis pass: if a `TaskGroup` value goes out of scope without a call to `deinit` in the same scope, emit a warning.
4. `error.Cancelled` is added to the standard error set. It is handled identically to other errors by the type system.
5. `io.withDeadline` returns a stack-allocated `DeadlineIo` struct that wraps `Io` and checks the deadline before delegating each operation.

---

## Rollout / Migration Strategy

1. **Phase 1** (this ZEP): `std.Io.Blocking`, `std.Io.Threaded`, `std.Io.Test`, `TaskGroup`, cancellation, timeout. Stable API, no breaking changes to stabilized APIs after this point without a new ZEP.
2. **Phase 2** (follow-on ZEP): `std.Io.Evented` — io_uring/kqueue/IOCP backend. Io-compatible; no source changes required.
3. **Phase 3** (follow-on ZEP): `zag fix async` migration tool for any upstream Zig async patterns that differ.

---

## Alternatives Considered

| Alternative | Reason rejected |
|-------------|-----------------|
| Go-style goroutines | Requires GC for stack management; contradicts zag's no-hidden-allocations principle |
| Rust-style `async fn` / poll-based futures | Function coloring; viral in call graphs; hostile to AI agent authorship (agents must track colors across files) |
| Kotlin structured concurrency (coroutine scopes) | Good model, but requires a JVM-style runtime and suspend keyword coloring |
| Raw `io.async()` without TaskGroup (pure Zig approach) | Does not guarantee task cleanup on error paths; AI-generated code reliably leaks tasks without scope enforcement |
| Green threads / stackful coroutines | Large per-coroutine memory cost; less predictable performance; not composable with the no-hidden-allocation principle |
| Explicit event loop in user code | Pushes too much boilerplate to users; not ergonomic for agent-generated code |

---

## Open Questions

- [ ] Should `group.awaitAll` return a typed results struct or individual `try result_a`, `try result_b` calls? The current proposal uses a results handle but the API ergonomics need prototyping.
- [ ] Should `error.Cancelled` be a distinct error type (`CancelledError`) rather than a member of the common error set, to prevent accidental catching in catch-all handlers?
- [ ] `std.Io.Evented`: what is the API for integrating with platform-native event loops (e.g., macOS `CFRunLoop`, Windows message pump)? This affects GUI application support.

---

## Done Criteria

- [ ] `std.Io.Blocking`, `std.Io.Threaded`, `std.Io.Test` implemented and tested.
- [ ] `TaskGroup` implemented with compiler lint for missing `defer deinit`.
- [ ] `error.Cancelled` in standard error set; `io.withDeadline` implemented.
- [ ] All standard library I/O functions accept `Io` parameter.
- [ ] Language reference section on async updated.
- [ ] This ZEP status updated to `Final`.

---

## Status History

| Date       | Status | Note                                             | Council votes |
|------------|--------|--------------------------------------------------|---------------|
| 2026-03-02 | Draft  | Initial draft — research from coroutine history  | —             |
