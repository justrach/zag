const std = @import("std");
const zag = @import("zag");
const Fiber = zag.Fiber;
const Scheduler = zag.Scheduler;

fn testFn(flag: *bool) void {
    std.debug.print("  [fiber] inside testFn, setting flag\n", .{});
    flag.* = true;
    std.debug.print("  [fiber] about to switchToScheduler\n", .{});
    Fiber.switchToScheduler(Fiber.getCurrentFiber().?);
    std.debug.print("  [fiber] ERROR: should not reach here\n", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("=== Debug Fiber Test ===\n", .{});

    // Manual fiber test — no scheduler, just raw context switch
    var fiber = try Fiber.init(allocator, Fiber.default_stack_size);
    defer fiber.deinit();

    var flag: bool = false;
    fiber.setup(testFn, .{&flag});

    std.debug.print("1. Fiber created and set up\n", .{});

    // Set up scheduler context on current stack
    var sched_ctx: Fiber.Context = .{};
    Fiber.setSchedulerContext(&sched_ctx);

    std.debug.print("2. About to switch to fiber\n", .{});

    // Switch to the fiber
    Fiber.switchFromScheduler(&fiber);

    std.debug.print("3. Returned from fiber, flag={}\n", .{flag});

    if (flag) {
        std.debug.print("\n=== PASS ===\n", .{});
    } else {
        std.debug.print("\n=== FAIL ===\n", .{});
    }
}
