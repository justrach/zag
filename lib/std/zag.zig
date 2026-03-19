//! zag — Zero-infection structured concurrency for Zig.
//!
//! Functions are just functions. Concurrency lives at the call site.
//!
//! Usage:
//!   const zag = @import("zag");
//!
//!   // Spawn a fiber
//!   const fiber = try zag.spawn(myFunction, .{ arg1, arg2 });
//!
//!   // Structured concurrency with a scope
//!   var scope = zag.Scope.init(allocator);
//!   defer scope.deinit();
//!   try scope.spawn(fetchWeather, .{ alloc, req });
//!   try scope.spawn(fetchUsers, .{ alloc, req });
//!   try scope.join();
//!
//!   // Cooperative cancellation
//!   zag.checkCancel();

const std = @import("std");

pub const Fiber = @import("zag/Fiber.zig");
pub const Scope = @import("zag/Scope.zig");
pub const Scheduler = @import("zag/Scheduler.zig");

/// Check if the current fiber has been cancelled.
/// Returns error.Cancelled if the cancellation flag is set.
/// This is a cooperative cancellation point — call it in loops and
/// before expensive operations.
pub fn checkCancel() !void {
    if (Fiber.getCurrentFiber()) |fiber| {
        if (fiber.isCancelled()) {
            fiber.state = .cancelled;
            return error.Cancelled;
        }
    }
}

/// Yield the current fiber, allowing other fibers to run.
pub fn yield() void {
    if (Fiber.getCurrentFiber()) |fiber| {
        fiber.state = .suspended;
        Fiber.switchToScheduler(fiber);
    }
}

/// Spawn a new fiber running the given function.
/// Returns the fiber handle.
pub fn spawn(allocator: std.mem.Allocator, comptime func: anytype, args: anytype) !*Fiber {
    const sched = Scheduler.getGlobal() orelse return error.NoScheduler;
    return sched.spawn(allocator, func, args);
}

/// Sleep the current fiber for the given number of nanoseconds.
/// Parks the fiber — does not block the OS thread.
pub fn sleep(ns: u64) void {
    // TODO: integrate with event loop timer
    // For now, yield and busy-wait (placeholder)
    _ = ns;
    yield();
}

/// Run a blocking function on a dedicated thread pool,
/// preventing it from starving other fibers on this core.
/// Placeholder — will be implemented with dedicated blocking pool.
pub fn blockingCall(comptime func: anytype, args: anytype) @typeInfo(@TypeOf(func)).@"fn".return_type.? {
    // TODO: move fiber to blocking pool
    // For now, just call directly
    return @call(.auto, func, args);
}

/// Initialize the global scheduler and start worker threads.
/// Call once at program startup.
pub fn initRuntime(allocator: std.mem.Allocator, num_threads: usize) !*Scheduler {
    const sched = try allocator.create(Scheduler);
    sched.* = try Scheduler.init(allocator, num_threads);
    try sched.start();
    Scheduler.setGlobal(sched);
    return sched;
}

/// Shut down the global scheduler.
pub fn deinitRuntime(allocator: std.mem.Allocator) void {
    if (Scheduler.getGlobal()) |sched| {
        sched.deinit();
        allocator.destroy(sched);
        Scheduler.setGlobal(undefined);
    }
}

test {
    _ = Fiber;
    _ = Scope;
    _ = Scheduler;
}
