const std = @import("std");
const zag = @import("zag");
const Fiber = zag.Fiber;
const Scope = zag.Scope;
const Scheduler = zag.Scheduler;

// ============================================================
// Helpers
// ============================================================

fn expect(ok: bool, comptime msg: []const u8, args: anytype) !void {
    if (!ok) {
        std.debug.print("FAIL: " ++ msg ++ "\n", args);
        return error.TestFailed;
    }
}

// ============================================================
// Test functions
// ============================================================

fn increment(counter: *std.atomic.Value(u64)) void {
    _ = counter.fetchAdd(1, .release);
}

fn incrementN(counter: *std.atomic.Value(u64), n: u64) void {
    _ = counter.fetchAdd(n, .release);
}

/// Simulates work by doing computation then yielding, then more computation.
/// This is the "async-like" pattern: fiber does work, yields to let others run,
/// then resumes and does more work.
fn yieldingWorker(counter: *std.atomic.Value(u64), id: u64) void {
    // Phase 1: do some work
    _ = counter.fetchAdd(1, .release);

    // Yield — let other fibers run (like an async await point)
    zag.yield();

    // Phase 2: do more work after "resuming"
    _ = counter.fetchAdd(id, .release);
}

/// Worker that checks cancellation periodically
fn cancellableWorker(counter: *std.atomic.Value(u64)) void {
    var i: u64 = 0;
    while (i < 1000) : (i += 1) {
        zag.checkCancel() catch {
            // We were cancelled — record how far we got
            _ = counter.fetchAdd(i, .release);
            return;
        };
        // Simulate work
        std.mem.doNotOptimizeAway(i);
    }
    // Completed all iterations
    _ = counter.fetchAdd(1000, .release);
}

/// Worker that returns an error
fn failingWorker(counter: *std.atomic.Value(u64)) !void {
    _ = counter.fetchAdd(1, .release);
    return error.IntentionalFailure;
}

/// Simulates an HTTP request handler (TurboAPI pattern):
/// read → process → write, each could be an async point
fn httpHandler(results: *std.atomic.Value(u64), request_id: u64) void {
    // "Read" phase
    var hash: u64 = request_id *% 6364136223846793005 +% 1;
    std.mem.doNotOptimizeAway(hash);

    // Yield (simulates I/O wait for read)
    zag.yield();

    // "Process" phase
    hash = hash *% 6364136223846793005 +% 1442695040888963407;
    std.mem.doNotOptimizeAway(hash);

    // Yield (simulates I/O wait for write)
    zag.yield();

    // "Write" phase — record completion
    _ = results.fetchAdd(1, .release);
}

/// Agent tool call simulation with nested scope
fn agentOrchestrator(result: *std.atomic.Value(u64), allocator: std.mem.Allocator) void {
    // Agent receives request, creates a scope for tool calls
    var scope = Scope.init(allocator);
    defer scope.deinit();

    // Fan out to 3 tools
    scope.spawn(incrementN, .{ result, 10 }) catch return;
    scope.spawn(incrementN, .{ result, 20 }) catch return;
    scope.spawn(incrementN, .{ result, 30 }) catch return;

    // Wait for all tools
    scope.join() catch return;

    // Post-process: add orchestrator's own result
    _ = result.fetchAdd(1, .release);
}

// ============================================================
// Tests
// ============================================================

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("=== Zag Fiber Stress Tests ===\n\n", .{});

    // --- Stress: 1000 fibers ---
    std.debug.print("Stress 1: Spawn 1000 fibers... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        var counter = std.atomic.Value(u64).init(0);

        for (0..1000) |_| {
            _ = try zag.spawn(allocator, increment, .{&counter});
        }
        sched.runUntilComplete();

        try expect(counter.load(.acquire) == 1000, "expected 1000, got {}", .{counter.load(.acquire)});
        std.debug.print("PASS (1000 fibers completed)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Stress: yield + resume (async-like interleaving) ---
    std.debug.print("Stress 2: Yield/resume interleaving... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        var counter = std.atomic.Value(u64).init(0);

        // Spawn 50 yielding workers — they'll interleave execution
        for (0..50) |i| {
            _ = try zag.spawn(allocator, yieldingWorker, .{ &counter, @as(u64, i) + 1 });
        }
        sched.runUntilComplete();

        // Expected: 50 (from phase 1) + sum(1..50) (from phase 2) = 50 + 1275 = 1325
        const expected: u64 = 50 + (50 * 51 / 2);
        try expect(counter.load(.acquire) == expected, "expected {}, got {}", .{ expected, counter.load(.acquire) });
        std.debug.print("PASS (50 fibers yielded and resumed)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Stress: TurboAPI pattern — concurrent HTTP handlers ---
    std.debug.print("Stress 3: 200 concurrent HTTP handlers... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        var completed = std.atomic.Value(u64).init(0);

        for (0..200) |i| {
            _ = try zag.spawn(allocator, httpHandler, .{ &completed, @as(u64, i) });
        }
        sched.runUntilComplete();

        try expect(completed.load(.acquire) == 200, "expected 200, got {}", .{completed.load(.acquire)});
        std.debug.print("PASS (200 requests, 2 yields each)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Stress: scope with many children ---
    std.debug.print("Stress 4: Scope with 100 children... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;
        var counter = std.atomic.Value(u64).init(0);

        {
            var scope = Scope.init(allocator);
            defer scope.deinit();

            for (0..100) |_| {
                try scope.spawn(increment, .{&counter});
            }
            try scope.join();
        }

        try expect(counter.load(.acquire) == 100, "expected 100, got {}", .{counter.load(.acquire)});
        std.debug.print("PASS\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Stress: nested scopes (agent spawning sub-agents) ---
    std.debug.print("Stress 5: Nested scopes (agent orchestration)... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;
        var result = std.atomic.Value(u64).init(0);

        // Outer scope: spawn 5 agents, each creates inner scope with 3 tools
        {
            var outer = Scope.init(allocator);
            defer outer.deinit();

            for (0..5) |_| {
                try outer.spawn(agentOrchestrator, .{ &result, allocator });
            }
            try outer.join();
        }

        // Each agent: 10 + 20 + 30 + 1 = 61. Five agents: 305
        try expect(result.load(.acquire) == 305, "expected 305, got {}", .{result.load(.acquire)});
        std.debug.print("PASS (5 agents × 3 tools + orchestration)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Stress: cancellation ---
    std.debug.print("Stress 6: Scope cancellation on error... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;
        var counter = std.atomic.Value(u64).init(0);

        {
            var scope = Scope.init(allocator);
            defer scope.deinit();

            // Spawn a failing worker and some normal ones
            try scope.spawn(failingWorker, .{&counter});
            try scope.spawn(increment, .{&counter});
            try scope.spawn(increment, .{&counter});

            const join_result = scope.join();
            // Should get the error from failingWorker
            if (join_result) {
                std.debug.print("FAIL (expected error)\n", .{});
                return error.TestFailed;
            } else |err| {
                try expect(err == error.IntentionalFailure, "wrong error: {}", .{err});
            }
        }

        std.debug.print("PASS (error propagated)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Stress: rapid spawn/complete cycles ---
    std.debug.print("Stress 7: 5000 rapid spawn/complete... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        var counter = std.atomic.Value(u64).init(0);

        for (0..5000) |_| {
            _ = try zag.spawn(allocator, increment, .{&counter});
        }
        sched.runUntilComplete();

        try expect(counter.load(.acquire) == 5000, "expected 5000, got {}", .{counter.load(.acquire)});
        std.debug.print("PASS\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Benchmark: throughput ---
    std.debug.print("\nBenchmark: fiber spawn+run throughput... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        var counter = std.atomic.Value(u64).init(0);

        const n: u64 = 10_000;
        const start = std.time.nanoTimestamp();

        for (0..n) |_| {
            _ = try zag.spawn(allocator, increment, .{&counter});
        }
        sched.runUntilComplete();

        const elapsed = std.time.nanoTimestamp() - start;
        const elapsed_us = @divTrunc(elapsed, 1000);
        const rate = if (elapsed_us > 0) @divTrunc(@as(i128, n) * 1_000_000, elapsed_us) else 0;

        try expect(counter.load(.acquire) == n, "expected {}, got {}", .{ n, counter.load(.acquire) });
        std.debug.print("{} fibers in {}µs ({} fibers/sec)\n", .{ n, elapsed_us, rate });
        zag.deinitRuntime(allocator);
    }

    std.debug.print("\n=== All stress tests passed! ===\n", .{});
}
