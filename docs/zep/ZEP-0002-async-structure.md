# ZEP-0002: Structured Async

| Field    | Value                                                |
|----------|------------------------------------------------------|
| ZEP      | 0002                                                 |
| Title    | Structured Async                                     |
| Author   | zag contributors                                     |
| Status   | Draft                                                |
| Type     | Language                                             |
| Created  | 2026-03-02                                           |
| Updated  | 2026-03-02 (rev 2 — thread-first, non-infectious)    |
| Requires | —                                                    |

---

## Abstract

This ZEP defines zag's async model. The core position: **async must not infect function signatures**. Not through `async fn`, not through `Io` parameters, not through `suspend`. A function that reads a file looks the same whether it runs on the main thread, in a thread pool, or inside a structured concurrency scope. Concurrency is expressed at the **call site**, not in function types.

zag achieves this with a **fiber-based structured concurrency model**: cheap user-space threads (fibers) scheduled on a work-stealing thread pool, with scope-based lifetime guarantees. Modern hardware has 16–128 cores and abundant memory. We use them.

---

## Background: A Brief History of Coroutines and What Each Era Got Wrong

### 1958–1980: Conway's insight and its neglect

Melvin Conway coined "coroutine" in 1958, published formally in 1963 in *Design of a Separable Transition-diagram Compiler*. The insight: program modules that communicate as peers, each treating itself as the master program, with no true master. Coroutines appeared in COBOL compilers and assembly programs, then were largely forgotten as OS threads became mainstream in the 1980s–90s. Games (Lua, Unity) kept them alive.

### 1990s–2010s: Callbacks and their failure

OS threads scale poorly past a few thousand. The alternative — event loops with callbacks — is how Node.js, early browser JavaScript, and libevent-based C servers worked. Callbacks produce callback hell: nested, hard to reason about, and nearly impossible for tools (or agents) to analyze statically.

### 2012–2018: async/await and function coloring

C# shipped `async`/`await` in 2012. JavaScript followed with Promises (ES6, 2015) and `async`/`await` (ES2017). Python adopted it in 3.5 (2015). The syntax improved, but the model created **function coloring** — named by Bob Nystrom in his 2015 essay *"What Color is Your Function?"*

In a colored system, every function is either sync or async. You can call sync from async, but not async from sync. This forces:
- Duplicate APIs (blocking and async variants of the same library)
- Viral refactoring when a function deep in a call stack needs to become async
- Cognitive overhead for human readers
- **Structural blindness for AI agents** — an agent must trace color through an entire call graph to determine whether a function call is safe

### The survey: what every language did, and what it cost

| Language      | Model                      | Stackful? | Infection?       | Key cost                                |
|---------------|----------------------------|-----------|------------------|-----------------------------------------|
| Go            | Goroutines (M:N scheduler) | Yes       | None             | GC required; large runtime              |
| Rust          | Poll-based Futures         | No        | `async fn` viral | Hostile to read; complex executor model |
| Python        | asyncio event loop         | No        | `async def` viral | Single-threaded; GIL                   |
| JavaScript    | Promises + event loop      | No        | Viral            | Single-threaded                         |
| Kotlin        | Structured concurrency     | No        | `suspend` viral  | JVM required                            |
| C++20         | Stackless coroutines       | No        | `co_await` viral | No stdlib; extremely verbose            |
| Zig (old)     | Colorblind async           | No        | None (almost)    | Leaked through fn pointers; removed     |
| Zig (new)     | `Io` parameter             | No        | `Io` viral       | `Io` must thread through all I/O callers|
| Java Loom     | Virtual threads            | Yes       | **None**         | JVM; GC                                 |
| Erlang        | Actors + lightweight procs | Yes       | **None**         | Immutable data model; different paradigm|

### The Io parameter is still infection

Zig's new async model (PR #25592, in our fork base) routes I/O through an `Io` interface parameter. This eliminates `async fn` coloring, but it introduces **parameter coloring**: any function that does I/O must accept an `Io` argument and thread it through every callee that also does I/O. Change a leaf function to need I/O? Refactor its entire call chain.

From an agent-authorship perspective this is strictly better than `async fn` coloring (the infection is at least visible as a parameter, not a type modifier), but it is still infection. An agent writing a utility function cannot know whether to add `Io` without understanding all possible callers.

### What Go and Java Loom got right

Go's goroutines and Java's virtual threads share one key property: **functions are just functions**. `go func()` spawns concurrently; the function itself is unchanged. A function written for synchronous use runs unchanged in a goroutine. The scheduler handles preemption and blocking transparently.

The cost in both cases is a garbage collector. zag does not have one. But the insight — **concurrency at the call site, not in the function type** — is correct and achievable without GC.

---

## Motivation

### Hardware reality in 2026

A laptop ships with 10–24 cores. A server has 64–256. Memory is cheap. The dominant I/O interfaces (io_uring, IOCP, kqueue) are designed for high concurrency. The assumption that underpinned stackless async — *"we can't afford a stack per concurrent task"* — is stale. Modern fiber libraries (like Boost.Context, Google's Fibers, or Go's own goroutine stacks) start stacks at 2–8KB and grow them as needed. Thousands of fibers are practical on any modern machine.

### Agent authorship requires local reasoning

An AI agent writing zag code must be able to answer: *"Is this function safe to call from here?"* In a colored system, the answer depends on the calling context — which may be in a different file. In a non-infected model, the answer is always yes. Local reasoning is sufficient.

The same property matters for human reviewers: a function's signature tells you everything about its behavior. No hidden async contracts.

### Structured concurrency is still the right safety model

Go's goroutines can leak — a goroutine spawned without a `sync.WaitGroup` or `context.Context` can outlive its parent, causing resource leaks and data races. zag adopts Kotlin's structural insight: **every spawned task is scoped to a lexical block**. The scope guarantees all tasks complete (or are cancelled) before the block exits.

---

## Non-Goals

- zag does not provide actors, channels, or message-passing primitives in this ZEP. Those are separate proposals.
- zag does not provide an event loop in this ZEP. Fiber scheduling is the foundation; evented I/O is built on top of it.
- This ZEP does not define generator coroutines (`yield`). Separate proposal.
- zag does not require a garbage collector.

---

## Specification

### 1. Fibers

A **fiber** is a user-space thread with its own stack, scheduled cooperatively by the zag runtime on top of OS threads. Fibers are:

- **Cheap**: initial stack size 8KB, grows on demand up to a configurable limit (default 1MB).
- **Opaque**: calling code does not know whether it is running on a fiber or an OS thread.
- **Blocking-transparent**: when a fiber blocks on I/O, the scheduler parks it and runs another fiber on the same OS thread. The fiber's code sees ordinary blocking calls.

Fibers are an implementation detail. The language surface is **scopes** and **tasks**.

### 2. The Thread Pool

zag's runtime maintains a **work-stealing thread pool** with one OS thread per logical CPU core by default (configurable). All fibers run on this pool. No goroutine-style M:N with a custom scheduler — the pool is the scheduler.

The pool is initialized at program start. Its size is controlled by:

```zig
pub fn main() void {
    zag.runtime.init(.{ .threads = .auto }); // default: num_cpus
    defer zag.runtime.deinit();
    // ...
}
```

Or via environment variable: `ZAG_THREADS=8 ./myprogram`.

### 3. `zag.Task(T)` — spawning at the call site

`zag.spawn(func, args)` spawns `func` as a fiber on the thread pool and returns a `Task(T)`. The function being spawned is **unchanged** — it has no special signature.

```zig
fn readFile(path: []const u8, alloc: Allocator) ![]u8 {
    // ordinary blocking code — no Io parameter, no async keyword
    const f = try std.fs.cwd().openFile(path, .{});
    defer f.close();
    return f.readToEndAlloc(alloc, 1 << 20);
}

// At the call site, concurrency is explicit:
const task = zag.spawn(readFile, .{ "data.bin", alloc });
const data = try task.join(); // blocks the calling fiber until done
```

`task.join()` blocks the **fiber**, not the OS thread. The OS thread is free to run other fibers while waiting.

### 4. `zag.Scope` — structured concurrency

`zag.Scope` is the structured concurrency primitive. Every task spawned through a scope is guaranteed to complete (or be cancelled) before `scope.wait()` returns. `defer scope.wait()` is the idiomatic pattern.

```zig
fn saveBackups(data: []const u8, alloc: Allocator) !void {
    var scope = zag.Scope.init();
    defer scope.wait(); // waits for all tasks; cancels on error

    scope.spawn(writeFile, .{ "backup_a.bin", data, alloc });
    scope.spawn(writeFile, .{ "backup_b.bin", data, alloc });
    scope.spawn(writeFile, .{ "backup_c.bin", data, alloc });
    // all three run in parallel; scope.wait() blocks until all finish
}
```

**No `Io` parameter. No `async` keyword. `writeFile` is an ordinary function.**

#### Failure semantics

If any task in the scope returns an error:
1. The scope cancels all remaining tasks (by setting a cancellation flag they can check at yield points).
2. `scope.wait()` collects the first error and returns it.
3. Subsequent errors from cancelled tasks are discarded.

```zig
fn fetchAll(urls: []const []u8, alloc: Allocator) ![][]u8 {
    var scope = zag.Scope.init();
    defer scope.wait();

    var tasks = try alloc.alloc(zag.Task([]u8), urls.len);
    for (urls, 0..) |url, i| {
        tasks[i] = scope.spawn(fetch, .{ url, alloc });
    }

    var results = try alloc.alloc([]u8, urls.len);
    for (tasks, 0..) |task, i| {
        results[i] = try task.join();
    }
    return results;
}
```

### 5. Cancellation

Cancellation is cooperative and explicit. A fiber checks for cancellation at **yield points** — blocking calls that park the fiber. There is no forced termination.

Functions opt into cancellation checking with `zag.checkCancel()`:

```zig
fn processLargeFile(path: []const u8, alloc: Allocator) !Result {
    const data = try readFile(path, alloc); // yield point — auto-checks cancel
    for (chunks(data)) |chunk| {
        try zag.checkCancel(); // explicit check in CPU-bound loop
        processChunk(chunk);
    }
    return summarize(data);
}
```

`zag.checkCancel()` returns `error.Cancelled` if the enclosing scope has been cancelled. It does not require any parameter — the runtime maintains the cancellation state per-fiber on the fiber's stack frame.

**No parameter threading. No infection.**

### 6. Timeouts

Timeouts wrap a scope:

```zig
fn fetchWithTimeout(url: []const u8, alloc: Allocator) ![]u8 {
    var scope = zag.Scope.initWithTimeout(5 * std.time.ns_per_s);
    defer scope.wait();

    const task = scope.spawn(fetch, .{ url, alloc });
    return task.join() catch |err| switch (err) {
        error.Cancelled => error.Timeout,
        else => err,
    };
}
```

### 7. Synchronization primitives

zag provides fiber-aware versions of standard synchronization primitives. Blocking on these parks the fiber, not the OS thread:

| Primitive          | Notes                                          |
|--------------------|------------------------------------------------|
| `zag.Mutex`        | Fiber-aware mutex. Parked fibers don't block OS threads. |
| `zag.RwLock`       | Fiber-aware read-write lock.                   |
| `zag.Semaphore`    | Counting semaphore.                            |
| `zag.WaitGroup`    | Wait for N tasks (lower-level than Scope).     |
| `zag.Channel(T)`   | Bounded MPMC channel. Blocks fibers on full/empty. |

### 8. Blocking legacy code

For code that cannot yield (e.g., a C library call that blocks an OS thread), zag provides `zag.blockingCall`:

```zig
// Runs func on a dedicated blocking thread so it doesn't starve the pool
const result = try zag.blockingCall(legacyCFunction, .{arg});
```

This is an escape hatch, not the default. It spawns an extra OS thread for the duration of the call.

---

## Examples

### Parallel file saves (no async, no Io)

```zig
fn saveBackups(data: []const u8, alloc: Allocator) !void {
    var scope = zag.Scope.init();
    defer scope.wait();

    scope.spawn(writeFile, .{ "backup_a.bin", data, alloc });
    scope.spawn(writeFile, .{ "backup_b.bin", data, alloc });
}
```

### Fan-out HTTP requests

```zig
fn fetchAll(urls: []const []u8, alloc: Allocator) ![]Response {
    var scope = zag.Scope.init();
    defer scope.wait();

    var tasks = try alloc.alloc(zag.Task(Response), urls.len);
    for (urls, 0..) |url, i| tasks[i] = scope.spawn(fetch, .{ url, alloc });

    var out = try alloc.alloc(Response, urls.len);
    for (tasks, 0..) |t, i| out[i] = try t.join();
    return out;
}
```

### CPU-bound parallel work

```zig
fn parallelMap(
    items: []Item,
    alloc: Allocator,
    comptime func: fn (Item, Allocator) !Result,
) ![]Result {
    var scope = zag.Scope.init();
    defer scope.wait();

    var tasks = try alloc.alloc(zag.Task(Result), items.len);
    for (items, 0..) |item, i| tasks[i] = scope.spawn(func, .{ item, alloc });

    var out = try alloc.alloc(Result, items.len);
    for (tasks, 0..) |t, i| out[i] = try t.join();
    return out;
}
```

### Testing — no special test executor needed

```zig
test "parallel saves" {
    // Works in test runner without any special async test setup.
    // zag.runtime is initialized by the test harness.
    var scope = zag.Scope.init();
    defer scope.wait();

    scope.spawn(writeFile, .{ "a.bin", "hello", testing.allocator });
    scope.spawn(writeFile, .{ "b.bin", "world", testing.allocator });
}
```

---

## Comparison: fiber model vs Io parameter

| Property                        | Io parameter (Zig upstream)     | Fiber + Scope (this ZEP)         |
|---------------------------------|---------------------------------|----------------------------------|
| Function signature change?      | Yes — add `Io` param            | **No**                           |
| Viral through call chain?       | Yes                             | **No**                           |
| Agent local reasoning?          | Partial — must trace `Io`       | **Full — functions are functions** |
| Stack per task?                 | No (stackless)                  | Yes — 8KB min, grows as needed   |
| Works without runtime?          | Yes                             | No — pool must be initialized    |
| Embedded / no-alloc targets?    | Yes                             | Constrained — fibers need memory |
| I/O abstraction for testing?    | Yes — swap `Io` impl            | `zag.Scope` + mock functions     |
| Cancellation threading?         | Via `Io` parameter              | Via runtime fiber state (no param)|
| Blocking C interop?             | Opaque to `Io`                  | `zag.blockingCall` escape hatch  |

---

## Backwards Compatibility

- [ ] **Breaking change from ZEP-0002 rev 1**: the `Io`-as-parameter API is not adopted. Code written for Zig's `std.Io` interface will not compile without removing the `Io` parameters.
- The old stage1 Zig async keywords are already absent from our fork base. No regression there.

Migration from Zig's `Io` pattern:

```zig
// Zig upstream:
fn readFile(io: Io, path: []const u8, alloc: Allocator) ![]u8 { ... }
const task = io.async(readFile, .{ io, path, alloc });
const data = try task.await(io);

// zag:
fn readFile(path: []const u8, alloc: Allocator) ![]u8 { ... }
const task = zag.spawn(readFile, .{ path, alloc });
const data = try task.join();
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Fiber stack overflow on deep recursion | Medium | High | Stack growth by default; configurable limit; compiler can warn on recursive fns |
| Forgetting `defer scope.wait()` — tasks leak | High | High | Compiler lint: `Scope` without `defer wait()` in same block is a warning |
| Pool starvation from blocking C calls | Medium | Medium | `zag.blockingCall` spawns extra OS thread; document the pattern |
| Embedded targets (no allocator, no runtime) | High | Medium | Scope: single-threaded fallback mode (`ZAG_THREADS=1` runs fibers sequentially on main thread) |
| Data races on shared mutable state | Medium | High | zag's existing ownership model + `zag.Mutex`; no GC race detector, but `ThreadSanitizer` compatible |
| High fiber count memory pressure | Low | Medium | Fibers start at 8KB; 10,000 fibers = 80MB — acceptable on modern hardware |

---

## Testing and Validation Plan

- [ ] Unit tests: `zag.Scope` correctly waits for all tasks
- [ ] Unit tests: failure in one task cancels siblings, error propagates
- [ ] Unit tests: `zag.checkCancel()` returns `error.Cancelled` after scope cancellation
- [ ] Unit tests: timeout cancels scope after deadline
- [ ] Stress test: 100,000 fibers on 8-core machine — no deadlock, no leak
- [ ] Benchmark: fiber spawn/join overhead vs OS thread spawn
- [ ] Benchmark: parallel file I/O throughput vs single-threaded
- [ ] Compile-time test: `Scope` without `defer wait()` → warning

---

## Implementation Notes

1. **Fiber implementation**: use platform `ucontext_t` (POSIX) or `SwitchToFiber` (Windows) for context switching, or a custom assembly implementation (like Go's runtime) for performance. The fiber scheduler is in `lib/zag/runtime/fiber.zig`.
2. **Work-stealing pool**: each OS thread has a local run queue (deque). Idle threads steal from the back of other threads' deques. Standard work-stealing algorithm (Chase-Lev deque).
3. **Cancellation state**: stored in a single `std.atomic.Value(bool)` on the fiber's stack frame header. `zag.checkCancel()` reads it. No parameter threading.
4. **`zag.spawn` vs `scope.spawn`**: `zag.spawn` creates a detached task (manual `join()` required). `scope.spawn` registers the task with the scope. Both share the same fiber runtime.
5. **Single-threaded fallback**: when `ZAG_THREADS=1` or on embedded targets, `scope.spawn` runs tasks sequentially inline. No fibers, no pool. The API surface is identical.

---

## Rollout / Migration Strategy

1. **Phase 1** (this ZEP): fiber runtime, work-stealing pool, `zag.Task`, `zag.Scope`, `zag.checkCancel`, timeout, `zag.Mutex`/`RwLock`/`Semaphore`/`Channel`.
2. **Phase 2** (follow-on ZEP): `std.Io.Evented` — io_uring/kqueue/IOCP integration. Fibers block on I/O without blocking OS threads.
3. **Phase 3** (follow-on ZEP): `zag fix async` migration tool for Zig `Io`-parameter code.

---

## Alternatives Considered

| Alternative | Reason rejected |
|-------------|-----------------|
| `Io` parameter (Zig upstream) | Still infectious — threads through every I/O caller. Rejected in favor of zero-infection fiber model. |
| `async fn` / stackless coroutines (Rust, JS) | Viral, hostile to agent authorship. Rejected. |
| Go-style goroutines | Correct model, but requires GC for stack management. zag has no GC. |
| Pure thread-per-task (no fibers) | OS threads cost 1–8MB stack each. 10,000 tasks = 10–80GB. Not practical. Fibers start at 8KB. |
| Actor model (Erlang) | Requires immutable-by-default data model. Too large a departure from Zig's semantics. |
| No async at all (blocking I/O, explicit thread management) | Leaves parallel I/O to users; they will reinvent fibers badly. |

---

## Open Questions

- [ ] Should `zag.spawn` (detached) be in the language at all, or should all spawning go through `Scope`? Detached tasks can leak if `join()` is never called.
- [ ] Stack growth: use `mmap` guard pages for overflow detection, or explicit stack-size hints on `spawn`?
- [ ] Should `zag.Channel(T)` be in scope for Phase 1, or deferred to the actor/message-passing ZEP?
- [ ] How does the fiber runtime interact with `comptime`? (It doesn't — `comptime` is single-threaded by definition. Clarify in spec.)

---

## Done Criteria

- [ ] Fiber runtime implemented and tested on Linux, macOS, Windows.
- [ ] Work-stealing thread pool implemented.
- [ ] `zag.Task`, `zag.Scope`, `zag.checkCancel`, `zag.blockingCall` implemented.
- [ ] Compiler lint for `Scope` without `defer wait()`.
- [ ] Synchronization primitives: `Mutex`, `RwLock`, `Semaphore`, `WaitGroup`, `Channel`.
- [ ] Single-threaded fallback (`ZAG_THREADS=1`) working.
- [ ] Benchmark report published.
- [ ] Language reference updated.
- [ ] This ZEP status updated to `Final`.

---

## Status History

| Date       | Status | Note                                                        | Council votes |
|------------|--------|-------------------------------------------------------------|---------------|
| 2026-03-02 | Draft  | Initial draft — Io-parameter model (rev 1)                  | —             |
| 2026-03-02 | Draft  | Rev 2 — fiber-first, zero-infection; Io parameter rejected  | —             |
