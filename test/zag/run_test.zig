const std = @import("std");
const zag = @import("zag");
const Fiber = zag.Fiber;
const Scope = zag.Scope;
const Scheduler = zag.Scheduler;

fn simpleAdd(a: *std.atomic.Value(u64), val: u64) void {
    _ = a.fetchAdd(val, .release);
}

fn simulateToolCall(result: *std.atomic.Value(u64), tool_id: u64) void {
    _ = result.fetchAdd(tool_id, .release);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("=== Zag Fiber Runtime Tests ===\n", .{});

    // Test 1: Fiber init/deinit
    std.debug.print("Test 1: Fiber init/deinit... ", .{});
    {
        var fiber = try Fiber.init(allocator, Fiber.default_stack_size);
        defer fiber.deinit();
        std.debug.print("PASS\n", .{});
    }

    // Test 2: Cancellation flag
    std.debug.print("Test 2: Cancellation flag... ", .{});
    {
        var fiber = try Fiber.init(allocator, Fiber.default_stack_size);
        defer fiber.deinit();
        if (!fiber.isCancelled()) {
            fiber.cancel();
            if (fiber.isCancelled()) {
                std.debug.print("PASS\n", .{});
            } else {
                std.debug.print("FAIL\n", .{});
                return error.TestFailed;
            }
        }
    }

    // Test 3: Raw context switch
    std.debug.print("Test 3: Raw context switch... ", .{});
    {
        var sched_ctx: Fiber.Context = .{};
        _ = Fiber.Context{};
        const flag: u64 = 0;
        _ = flag;

        // We'll use inline asm to test: save current context to sched_ctx,
        // then immediately restore it (round-trip test)
        Fiber.setSchedulerContext(&sched_ctx);
        Fiber.switchContext(&sched_ctx, &sched_ctx);
        // If we get here, the round-trip context switch worked
        _ = flag;
        std.debug.print("PASS\n", .{});
    }

    // Test 4: Scheduler init
    std.debug.print("Test 4: Scheduler init... ", .{});
    {
        const sched = try zag.initRuntime(allocator, 1);
        _ = sched;
        std.debug.print("PASS\n", .{});
        zag.deinitRuntime(allocator);
    }

    std.debug.print("\n=== All tests passed! ===\n", .{});
}
