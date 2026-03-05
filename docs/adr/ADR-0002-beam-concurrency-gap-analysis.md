# ADR-0002: BEAM Concurrency Gap Analysis — Lessons from codedb2

| Field    | Value                           |
|----------|---------------------------------|
| ADR      | 0002                            |
| Status   | Accepted                        |
| Created  | 2026-03-05                      |
| Deciders | zag core team                   |
| Related  | ZEP-0002 (Structured Async)     |

## Context

[codedb2](https://github.com/justrach/codedb2) is a code intelligence server written in Zig 0.15 — it indexes a codebase, watches for changes, and serves structural queries over HTTP and MCP (Model Context Protocol). It is representative of the class of **agent infrastructure** that zag targets: long-lived daemons serving concurrent AI agent queries against shared indexed state.

Building and optimizing codedb2 in Zig exposed concrete concurrency limitations that motivate ZEP-0002's fiber model. This ADR documents those findings as evidence for the design direction.

## codedb2's Current Concurrency Model (Zig 0.15)

```
Main thread          ─── HTTP accept loop / MCP read loop
Watcher thread       ─── polls filesystem every 2s
ISR thread           ─── rebuilds snapshot when stale
Reaper thread        ─── cleans up dead agents every 5s
```

4 OS threads. Shared mutable state (`Explorer`, `Store`) protected by `RwLock` and `Mutex`. Manual `std.atomic.Value(bool)` shutdown coordination.

### Architecture

| Component | Role | Concurrency mechanism |
|-----------|------|-----------------------|
| `Explorer` | Code intelligence (outlines, symbols, trigrams, word index, dep graph) | `std.Thread.RwLock` — shared reads, exclusive writes |
| `Store` | Version tracking (append-only per-file log) | `std.Thread.Mutex` |
| `Prerender` | Cached JSON snapshot (ISR pattern) | `std.Thread.Mutex` + atomic epoch counters |
| `EventQueue` | Filesystem change events | Bounded ring buffer (4096) with mutex |
| `AgentRegistry` | Multi-agent identity, locking, heartbeats | `std.Thread.Mutex` |
| HTTP server | REST API on :7719 | Single-threaded accept loop (sequential) |
| MCP server | JSON-RPC over stdio | Single-threaded read loop |

## Gap Analysis: Zig vs BEAM

### What BEAM provides that Zig does not

| BEAM Property | codedb2 (Zig 0.15) | Impact |
|---|---|---|
| **Lightweight processes (millions)** | 4 hardcoded OS threads | Cannot scale to N concurrent agent queries |
| **Per-process isolation** | Shared mutable state + locks | One corrupted pointer can crash the daemon |
| **Let-it-crash + supervisors** | `catch \|err\|` in thread loops; no restart | A panic in the watcher thread is permanent |
| **Message passing** | Direct pointer sharing + RwLock | Lock contention under load; deadlock risk |
| **Preemptive scheduling** | Cooperative (one slow query blocks HTTP) | Long `searchContent` starves all other clients |
| **Hot code reload** | Full binary restart | Zero-downtime upgrades impossible |
| **Per-process GC** | Global allocator, manual free | Memory leaks cascade globally |
| **Location transparency** | Single-process only | Cannot distribute across machines |

### Concrete Pain Points Found in codedb2

#### 1. Single-threaded HTTP server

`server.zig` runs a sequential accept loop:

```zig
while (true) {
    const conn = try srv.accept();
    handleConnection(..., conn, ...); // blocks until complete
}
```

A 200ms `searchContent` on a large codebase blocks every other client. Thread-per-connection is possible but expensive (1-8MB stack per OS thread). In BEAM, each connection would be a lightweight process (~2KB). In zag (ZEP-0002), each would be an 8KB fiber.

#### 2. Explorer write lock blocks all reads

`Explorer.indexFileInner` takes an exclusive write lock during indexing. During a burst of file changes (e.g., `git checkout` switching branches), all query handlers stall waiting for the lock. BEAM's share-nothing model avoids this entirely — each process has its own copy or reads from ETS. ZEP-0002's fiber-aware `zag.RwLock` would at least avoid OS thread starvation.

#### 3. No supervision

If the watcher thread panics on a malformed file, it dies permanently. The daemon keeps running but stops watching for changes. There is no restart mechanism. BEAM supervisors restart crashed processes automatically with configurable strategies (one-for-one, one-for-all, rest-for-one).

#### 4. Fake agent model

`AgentRegistry` tracks agent IDs, cursors, and file locks, but agents are just HTTP clients — there's no concurrent execution model. A true BEAM-style system would model each agent as a lightweight process with its own mailbox, state, and failure domain.

#### 5. No backpressure

`EventQueue` is a fixed 4096-slot ring buffer. If the consumer is slow, events are silently dropped (`push` returns `false`). BEAM's process mailboxes provide natural backpressure through process scheduling — a producer sending to a full mailbox gets descheduled.

#### 6. Manual shutdown coordination

A `std.atomic.Value(bool)` shutdown flag is threaded through every background loop. Each loop must check it explicitly. BEAM processes receive shutdown signals through their mailbox — the mechanism is uniform and automatic.

## How ZEP-0002 (Structured Async) Addresses These Gaps

| Pattern | Zig 0.15 (codedb2 today) | zag (ZEP-0002) | BEAM |
|---|---|---|---|
| Concurrent connections | Sequential or OS thread per conn | `scope.spawn(handleConn, .{conn})` — 8KB fiber | Lightweight process per conn (~2KB) |
| Parallel file indexing | Sequential `initialScan` | `scope.spawn(indexFile, .{path})` per file | `Task.async` per file |
| Query isolation | Shared `Explorer` + RwLock | Fiber-aware `zag.RwLock` — parked fibers don't block OS threads | Per-process isolation |
| Timeout on slow queries | Not possible | `zag.Scope.initWithTimeout(5s)` | `receive after 5000 -> timeout end` |
| Supervision | None | Scope catches errors; can respawn | OTP Supervisor trees |
| Cancellation | Manual `shutdown` atomic flag | `zag.checkCancel()` — runtime-managed, zero-param | `Process.exit(pid, :shutdown)` |
| Backpressure | Ring buffer, silent drop | `zag.Channel(T)` — bounded MPMC, blocks on full | Mailbox + scheduler backpressure |

### What zag does NOT provide vs BEAM

| Property | BEAM | zag | Rationale for gap |
|---|---|---|---|
| Per-process heap isolation | Full isolation | Shared memory (fibers) | Systems language — direct memory access is the point |
| Hot code reload | Module-level hot swap | Restart required | Compiled native code; no VM |
| Distribution | Location-transparent messaging | Local only | Separate concern; could be a future ZEP |
| Per-fiber GC | Per-process GC | Manual allocators | Explicit memory management is a feature for systems code |

These are deliberate tradeoffs. zag gets ~80% of BEAM's concurrency model at ~10% of the runtime overhead — no GC, no VM, predictable latency, direct hardware access. The target use case is **agent infrastructure** (daemons, MCP servers, code intelligence tools), not distributed telecom systems.

## Pragmatic Steps for codedb2 (Zig 0.15, before zag)

Improvements that map 1:1 to zag primitives later:

| Now (Zig 0.15) | Later (zag) |
|---|---|
| `std.Thread.spawn` per HTTP connection | `scope.spawn` per connection (fiber) |
| Worker thread pool for `initialScan` | `scope.spawn` per file |
| Manual supervision wrapper (restart on panic) | `zag.Scope` error recovery |
| Bounded MPMC channel (replace ring buffer) | `zag.Channel(T)` |
| Atomic shutdown flag | `zag.checkCancel()` |

## Decision

This analysis is recorded as evidence supporting ZEP-0002's fiber-first, zero-infection async model. The concrete gaps found in codedb2 demonstrate that:

1. **OS threads don't scale** for agent infrastructure workloads (concurrent queries, parallel indexing, file watching, supervision).
2. **Shared mutable state + locks** is error-prone and creates contention bottlenecks under concurrent agent access.
3. **Function coloring / Io parameter infection** would make these problems worse by forcing every I/O function in codedb2 to thread an extra parameter — with no concurrency benefit.
4. **Fibers with structured concurrency** (ZEP-0002) address all five concrete pain points while maintaining Zig's explicit, no-hidden-allocation philosophy.

## Consequences

- codedb2 serves as a **reference workload** for zag's async implementation. When ZEP-0002 reaches Phase 1, codedb2 will be ported to validate the fiber model against real-world agent infrastructure.
- Pragmatic Zig 0.15 improvements (thread-per-connection, supervision wrappers) proceed now and are designed to map cleanly to zag primitives.
- This ADR is referenced from ZEP-0002 discussion (issue #1) as supporting evidence.

## Status History

| Date       | Status   | Note |
|------------|----------|------|
| 2026-03-05 | Accepted | Initial analysis from codedb2 optimization work |
