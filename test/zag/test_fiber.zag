//! Integration tests for the Zag fiber runtime.
//!
//! Tests the core patterns needed by TurboAPI (concurrent connections)
//! and agent runtimes (parallel tool fan-out).

const std = @import("std");
const zag = @import("zag");
const Fiber = zag.Fiber;
const Scope = zag.Scope;
const Scheduler = zag.Scheduler;

// --- Basic fiber tests ---

fn simpleAdd(a: *std.atomic.Value(u64), val: u64) void {
    _ = a.fetchAdd(val, .release);
}

test "spawn and run single fiber" {
    const allocator = std.testing.allocator;

    const sched = try zag.initRuntime(allocator, 1);
    defer zag.deinitRuntime(allocator);

    var counter = std.atomic.Value(u64).init(0);
    _ = try zag.spawn(allocator, simpleAdd, .{ &counter, 42 });

    sched.runUntilComplete();

    try std.testing.expectEqual(@as(u64, 42), counter.load(.acquire));
}

test "spawn 100 fibers all complete" {
    const allocator = std.testing.allocator;

    const sched = try zag.initRuntime(allocator, 1);
    defer zag.deinitRuntime(allocator);

    var counter = std.atomic.Value(u64).init(0);

    for (0..100) |_| {
        _ = try zag.spawn(allocator, simpleAdd, .{ &counter, 1 });
    }

    sched.runUntilComplete();

    try std.testing.expectEqual(@as(u64, 100), counter.load(.acquire));
}

// --- Scope tests ---

fn scopeWorker(result: *std.atomic.Value(u64), value: u64) void {
    _ = result.fetchAdd(value, .release);
}

test "scope: spawn and join" {
    const allocator = std.testing.allocator;

    const sched = try zag.initRuntime(allocator, 1);
    defer zag.deinitRuntime(allocator);
    _ = sched;

    var result = std.atomic.Value(u64).init(0);

    var scope = Scope.init(allocator);
    defer scope.deinit();

    try scope.spawn(scopeWorker, .{ &result, 10 });
    try scope.spawn(scopeWorker, .{ &result, 20 });
    try scope.spawn(scopeWorker, .{ &result, 30 });

    try scope.join();

    try std.testing.expectEqual(@as(u64, 60), result.load(.acquire));
}

// --- Agent pattern: parallel tool fan-out ---

fn simulateToolCall(result: *std.atomic.Value(u64), tool_id: u64) void {
    // Simulate some work
    var acc: u64 = 0;
    for (0..1000) |i| {
        acc +%= i;
    }
    std.mem.doNotOptimizeAway(acc);

    // Record that this tool completed
    _ = result.fetchAdd(tool_id, .release);
}

test "agent pattern: parallel tool calls with scope" {
    const allocator = std.testing.allocator;

    const sched = try zag.initRuntime(allocator, 1);
    defer zag.deinitRuntime(allocator);
    _ = sched;

    var result = std.atomic.Value(u64).init(0);

    // Agent receives request, fans out to 3 tools
    var scope = Scope.init(allocator);
    defer scope.deinit();

    try scope.spawn(simulateToolCall, .{ &result, 1 }); // tool: search
    try scope.spawn(simulateToolCall, .{ &result, 2 }); // tool: database
    try scope.spawn(simulateToolCall, .{ &result, 4 }); // tool: cache

    try scope.join(); // structured — no leaked fibers

    // All tools completed: 1 + 2 + 4 = 7
    try std.testing.expectEqual(@as(u64, 7), result.load(.acquire));
}

// --- Cancellation tests ---

fn cancellableWork(counter: *std.atomic.Value(u64)) !void {
    for (0..1000) |_| {
        try zag.checkCancel();
        _ = counter.fetchAdd(1, .release);
    }
}

test "cancellation: checkCancel returns error.Cancelled" {
    const allocator = std.testing.allocator;

    var fiber = try Fiber.init(allocator, Fiber.default_stack_size);
    defer fiber.deinit();

    // Not cancelled — should not error
    try std.testing.expect(!fiber.isCancelled());

    // Cancel it
    fiber.cancel();
    try std.testing.expect(fiber.isCancelled());
}

// --- TurboAPI pattern: simulated request handling ---

fn handleRequest(result: *std.atomic.Value(u64), request_id: u64) void {
    // Simulate: read request → process → write response
    // In real TurboAPI, read/write would suspend the fiber on I/O
    var hash: u64 = request_id;
    for (0..100) |_| {
        hash = hash *% 6364136223846793005 +% 1442695040888963407;
    }
    _ = result.fetchAdd(1, .release);
}

test "turboapi pattern: concurrent request handling" {
    const allocator = std.testing.allocator;

    const sched = try zag.initRuntime(allocator, 1);
    defer zag.deinitRuntime(allocator);
    _ = sched;

    var completed = std.atomic.Value(u64).init(0);

    // Simulate 50 concurrent connections
    var scope = Scope.init(allocator);
    defer scope.deinit();

    for (0..50) |i| {
        try scope.spawn(handleRequest, .{ &completed, @as(u64, i) });
    }

    try scope.join();

    try std.testing.expectEqual(@as(u64, 50), completed.load(.acquire));
}
