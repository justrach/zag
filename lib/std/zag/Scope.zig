//! Scope — structured concurrency primitive for Zag.
//!
//! A scope owns a set of spawned fibers and guarantees that all of them
//! complete (or are cancelled) before the scope exits. The first error
//! from any fiber is captured and propagated to the joiner.
//!
//! Usage:
//!   var scope = zag.Scope.init(allocator);
//!   defer scope.deinit();
//!
//!   scope.spawn(fetchWeather, .{ alloc, req });
//!   scope.spawn(fetchUsers, .{ alloc, req });
//!
//!   scope.join(); // blocks until all fibers complete

const std = @import("std");
const Allocator = std.mem.Allocator;
const Fiber = @import("Fiber.zig");
const Scheduler = @import("Scheduler.zig");

const Scope = @This();

/// Maximum fibers per scope (can be made dynamic later)
const max_fibers = 256;

allocator: Allocator,

/// Fibers owned by this scope
fibers: [max_fibers]?*Fiber = [_]?*Fiber{null} ** max_fibers,
fiber_count: usize = 0,

/// Count of fibers still running
pending: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),

/// First error from any fiber
first_error: ?anyerror = null,

/// Whether join() has been called
joined: bool = false,

pub fn init(allocator: Allocator) Scope {
    return .{
        .allocator = allocator,
    };
}

/// Spawn a fiber within this scope.
/// The fiber is owned by the scope and will be cleaned up on deinit.
pub fn spawn(self: *Scope, comptime func: anytype, args: anytype) !void {
    if (self.fiber_count >= max_fibers) return error.TooManyFibers;

    const sched = Scheduler.getGlobal() orelse return error.NoScheduler;

    const fiber = try self.allocator.create(Fiber);
    fiber.* = try Fiber.init(self.allocator, Fiber.default_stack_size);
    fiber.setup(func, args);
    fiber.scope = @ptrCast(self);

    self.fibers[self.fiber_count] = fiber;
    self.fiber_count += 1;
    _ = self.pending.fetchAdd(1, .release);

    sched.submit(fiber);
}

/// Called by the scheduler when a fiber in this scope completes.
pub fn fiberCompleted(self: *Scope, fiber: *Fiber) void {
    // Capture first error
    if (fiber.@"error") |err| {
        if (self.first_error == null) {
            self.first_error = err;
            // Cancel remaining fibers
            self.cancelAll();
        }
    }

    const prev = self.pending.fetchSub(1, .release);
    _ = prev;

    // Decrement scheduler active count
    if (Scheduler.getGlobal()) |sched| {
        _ = sched.active_fibers.fetchSub(1, .release);
    }
}

/// Wait for all fibers in this scope to complete.
/// Returns the first error encountered, if any.
pub fn join(self: *Scope) !void {
    self.joined = true;

    // Participate in work while waiting for our fibers to complete
    const sched = Scheduler.getGlobal() orelse return;
    const workers = sched.workers orelse return;

    while (self.pending.load(.acquire) > 0) {
        // Help run fibers (not just ours — any fiber, to avoid deadlocks)
        if (workers[0].getNextFiber()) |fiber| {
            workers[0].runFiber(fiber);
        } else {
            std.Thread.yield() catch {};
        }
    }

    if (self.first_error) |err| return err;
}

/// Cancel all pending fibers in this scope.
pub fn cancelAll(self: *Scope) void {
    for (self.fibers[0..self.fiber_count]) |maybe_fiber| {
        if (maybe_fiber) |fiber| {
            if (fiber.state != .completed and fiber.state != .cancelled) {
                fiber.cancel();
            }
        }
    }
}

/// Clean up all fibers. Must be called after join().
pub fn deinit(self: *Scope) void {
    if (!self.joined and self.fiber_count > 0) {
        // Safety: cancel everything and wait
        self.cancelAll();
        self.join() catch {};
    }

    for (self.fibers[0..self.fiber_count]) |maybe_fiber| {
        if (maybe_fiber) |fiber| {
            fiber.deinit();
            self.allocator.destroy(fiber);
        }
    }

    self.* = undefined;
}
