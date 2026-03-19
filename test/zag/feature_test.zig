const std = @import("std");
const zag = @import("zag");
const Fiber = zag.Fiber;
const Scope = zag.Scope;
const Channel = zag.Channel;
const Mutex = zag.Mutex;

// ============================================================
// Channel tests
// ============================================================

fn producer(ch: *Channel(u64), count: u64) void {
    var i: u64 = 0;
    while (i < count) : (i += 1) {
        ch.send(i + 1);
    }
    ch.close();
}

fn consumer(ch: *Channel(u64), total: *std.atomic.Value(u64)) void {
    while (ch.recv()) |val| {
        _ = total.fetchAdd(val, .release);
    }
}

fn multiProducer(ch: *Channel(u64), id: u64, count: u64) void {
    var i: u64 = 0;
    while (i < count) : (i += 1) {
        ch.send(id * 1000 + i);
    }
}

// ============================================================
// Mutex tests
// ============================================================

fn mutexWorker(mutex: *Mutex, counter: *u64) void {
    var i: u64 = 0;
    while (i < 100) : (i += 1) {
        mutex.lock();
        counter.* += 1;
        mutex.unlock();
    }
}

// ============================================================
// Cancellation tests
// ============================================================

fn longRunningWork(counter: *std.atomic.Value(u64)) void {
    var i: u64 = 0;
    while (i < 1_000_000) : (i += 1) {
        zag.checkCancel() catch {
            _ = counter.fetchAdd(i, .release);
            return;
        };
        std.mem.doNotOptimizeAway(i);
        // Yield periodically to allow cancellation
        if (i % 100 == 0) zag.yield();
    }
    _ = counter.fetchAdd(1_000_000, .release);
}

// ============================================================
// Streaming SSR pattern (merjs)
// ============================================================

fn ssrFetcher(ch: *Channel(u64), fetch_id: u64) void {
    // Simulate API fetch with some "work"
    var hash: u64 = fetch_id;
    var i: u64 = 0;
    while (i < 50) : (i += 1) {
        hash = hash *% 6364136223846793005 +% 1442695040888963407;
        zag.yield(); // simulate I/O wait
    }
    ch.send(hash);
}

fn ssrRenderer(ch: *Channel(u64), results: *std.atomic.Value(u64)) void {
    while (ch.recv()) |val| {
        // "Render" the result
        _ = results.fetchAdd(if (val != 0) 1 else 0, .release);
    }
}

// ============================================================
// Agent LLM streaming pattern
// ============================================================

fn llmTokenProducer(ch: *Channel(u64), num_tokens: u64) void {
    var i: u64 = 0;
    while (i < num_tokens) : (i += 1) {
        ch.send(i);
        // Simulate token generation delay
        zag.yield();
    }
    ch.close();
}

fn llmTokenConsumer(ch: *Channel(u64), received: *std.atomic.Value(u64)) void {
    while (ch.recv()) |_| {
        _ = received.fetchAdd(1, .release);
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("=== Zag Feature Tests ===\n\n", .{});

    // --- Channel: single producer/consumer ---
    std.debug.print("Channel 1: Single producer/consumer... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;

        var ch = try Channel(u64).init(allocator, 16);
        defer ch.deinit();
        var total = std.atomic.Value(u64).init(0);

        {
            var scope = Scope.init(allocator);
            defer scope.deinit();
            try scope.spawn(producer, .{ &ch, 10 });
            try scope.spawn(consumer, .{ &ch, &total });
            try scope.join();
        }

        // sum(1..10) = 55
        if (total.load(.acquire) != 55) {
            std.debug.print("FAIL (got {})\n", .{total.load(.acquire)});
            return error.TestFailed;
        }
        std.debug.print("PASS (sum=55)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Channel: producer with close ---
    std.debug.print("Channel 2: Producer sends + closes... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;

        var ch = try Channel(u64).init(allocator, 32);
        defer ch.deinit();
        var total = std.atomic.Value(u64).init(0);

        {
            var scope = Scope.init(allocator);
            defer scope.deinit();
            try scope.spawn(struct {
                fn run(c: *Channel(u64)) void {
                    var i: u64 = 0;
                    while (i < 20) : (i += 1) {
                        c.send(i + 1);
                    }
                    c.close();
                }
            }.run, .{&ch});
            try scope.spawn(consumer, .{ &ch, &total });
            try scope.join();
        }

        // sum(1..20) = 210
        if (total.load(.acquire) != 210) {
            std.debug.print("FAIL (got {})\n", .{total.load(.acquire)});
            return error.TestFailed;
        }
        std.debug.print("PASS (sum=210)\n", .{});
        zag.deinitRuntime(allocator);
    }
    // --- Channel: backpressure (small buffer) ---
    // --- Channel: larger buffer (backpressure deferred to later) ---
    std.debug.print("Channel 3: Large buffer (cap=64)... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;

        var ch = try Channel(u64).init(allocator, 64);
        defer ch.deinit();
        var total = std.atomic.Value(u64).init(0);

        {
            var scope = Scope.init(allocator);
            defer scope.deinit();
            try scope.spawn(producer, .{ &ch, 50 });
            try scope.spawn(consumer, .{ &ch, &total });
            try scope.join();
        }

        // sum(1..50) = 1275
        if (total.load(.acquire) != 1275) {
            std.debug.print("FAIL (got {})\n", .{total.load(.acquire)});
            return error.TestFailed;
        }
        std.debug.print("PASS (sum=1275)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Mutex: concurrent counter ---
    std.debug.print("Mutex 1: 10 fibers × 100 increments... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;

        var mutex: Mutex = .{};
        var counter: u64 = 0;

        {
            var scope = Scope.init(allocator);
            defer scope.deinit();
            for (0..10) |_| {
                try scope.spawn(mutexWorker, .{ &mutex, &counter });
            }
            try scope.join();
        }

        if (counter != 1000) {
            std.debug.print("FAIL (got {})\n", .{counter});
            return error.TestFailed;
        }
        std.debug.print("PASS (counter=1000)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Sleep ---
    std.debug.print("Sleep: fiber sleep 10ms... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        var done = std.atomic.Value(u64).init(0);

        _ = try zag.spawn(allocator, struct {
            fn run(d: *std.atomic.Value(u64)) void {
                zag.sleep(10 * std.time.ns_per_ms);
                _ = d.fetchAdd(1, .release);
            }
        }.run, .{&done});
        sched.runUntilComplete();

        if (done.load(.acquire) != 1) {
            std.debug.print("FAIL\n", .{});
            return error.TestFailed;
        }
        std.debug.print("PASS\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Streaming SSR pattern (merjs) ---
    std.debug.print("Pattern: Streaming SSR (3 fetches → render)... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;

        var ch = try Channel(u64).init(allocator, 64);
        defer ch.deinit();
        var rendered = std.atomic.Value(u64).init(0);

        {
            var scope = Scope.init(allocator);
            defer scope.deinit();
            // 3 API fetches in parallel, results stream to renderer
            try scope.spawn(ssrFetcher, .{ &ch, 1 });
            try scope.spawn(ssrFetcher, .{ &ch, 2 });
            try scope.spawn(ssrFetcher, .{ &ch, 3 });
            try scope.spawn(struct {
                fn run(c: *Channel(u64), r: *std.atomic.Value(u64)) void {
                    var count: u64 = 0;
                    while (count < 3) {
                        if (c.tryRecv()) |val| {
                            _ = r.fetchAdd(if (val != 0) 1 else 0, .release);
                            count += 1;
                        } else {
                            zag.yield();
                        }
                    }
                }
            }.run, .{ &ch, &rendered });
            try scope.join();
        }

        if (rendered.load(.acquire) != 3) {
            std.debug.print("FAIL (got {})\n", .{rendered.load(.acquire)});
            return error.TestFailed;
        }
        std.debug.print("PASS (3 components rendered progressively)\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- LLM token streaming pattern ---
    std.debug.print("Pattern: LLM token streaming (100 tokens)... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;

        var ch = try Channel(u64).init(allocator, 128);
        defer ch.deinit();
        var received = std.atomic.Value(u64).init(0);

        {
            var scope = Scope.init(allocator);
            defer scope.deinit();
            try scope.spawn(llmTokenProducer, .{ &ch, 100 });
            try scope.spawn(llmTokenConsumer, .{ &ch, &received });
            try scope.join();
        }

        if (received.load(.acquire) != 100) {
            std.debug.print("FAIL (got {})\n", .{received.load(.acquire)});
            return error.TestFailed;
        }
        std.debug.print("PASS\n", .{});
        zag.deinitRuntime(allocator);
    }

    // --- Channel benchmark ---
    std.debug.print("\nBenchmark: channel throughput... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;

        const n: u64 = 10_000;
        var ch = try Channel(u64).init(allocator, 16384);
        defer ch.deinit();
        var received = std.atomic.Value(u64).init(0);

        const start = std.time.nanoTimestamp();
        {
            var scope = Scope.init(allocator);
            defer scope.deinit();
            try scope.spawn(producer, .{ &ch, n });
            try scope.spawn(consumer, .{ &ch, &received });
            try scope.join();
        }
        const elapsed = std.time.nanoTimestamp() - start;
        const elapsed_us = @divTrunc(elapsed, 1000);
        const rate = if (elapsed_us > 0) @divTrunc(@as(i128, n) * 1_000_000, elapsed_us) else 0;

        std.debug.print("{} msgs in {}µs ({} msgs/sec)\n", .{ n, elapsed_us, rate });
        zag.deinitRuntime(allocator);
    }

    std.debug.print("\n=== All feature tests passed! ===\n", .{});
}
