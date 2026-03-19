//! Scheduler — work-stealing thread pool for Zag fibers.
//!
//! Each worker thread has a local deque of fibers. When a worker's deque is
//! empty, it steals from other workers. This gives good locality for related
//! work while balancing load across cores.

const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const Fiber = @import("Fiber.zig");
const Thread = std.Thread;

const Scheduler = @This();

/// Worker thread state
pub const Worker = struct {
    /// Local fiber run queue (LIFO for locality)
    local_queue: FiberQueue,
    /// Thread handle (null for the main thread worker)
    thread: ?Thread = null,
    /// Worker index
    id: usize,
    /// Scheduler back-reference
    scheduler: *Scheduler,
    /// Scheduler context saved when switching to a fiber
    sched_context: Fiber.Context = .{},

    pub fn init(id: usize, scheduler: *Scheduler) Worker {
        return .{
            .local_queue = FiberQueue.init(),
            .id = id,
            .scheduler = scheduler,
        };
    }

    /// Main worker loop: run fibers from local queue, steal if empty.
    pub fn run(self: *Worker) void {
        // Set up thread-local scheduler context
        Fiber.setSchedulerContext(&self.sched_context);

        while (!self.scheduler.shutdown_flag.load(.acquire)) {
            if (self.getNextFiber()) |fiber| {
                self.runFiber(fiber);
            } else {
                // No work — brief pause before retrying
                // In production this would use futex/condition variable
                std.Thread.yield() catch {};
            }
        }

        // Drain remaining fibers on shutdown
        while (self.getNextFiber()) |fiber| {
            self.runFiber(fiber);
        }
    }

    /// Execute a single fiber until it yields or completes.
    pub fn runFiber(self: *Worker, fiber: *Fiber) void {
        fiber.state = .running;
        Fiber.switchFromScheduler(fiber);

        // Fiber has yielded or completed — handle post-switch
        switch (fiber.state) {
            .completed, .cancelled => {
                // Notify scope if attached
                if (fiber.scope) |scope_ptr| {
                    const scope: *@import("Scope.zig") = @ptrCast(@alignCast(scope_ptr));
                    scope.fiberCompleted(fiber);
                } else {
                    // No scope — decrement active count directly
                    if (Scheduler.getGlobal()) |sched| {
                        _ = sched.active_fibers.fetchSub(1, .release);
                    }
                }
            },
            .suspended => {
                // Fiber yielded — re-enqueue it so it can resume
                self.local_queue.push(fiber);
            },
            else => {},
        }
    }

    /// Get next fiber: try local queue first, then steal from others.
    pub fn getNextFiber(self: *Worker) ?*Fiber {
        // Try local queue first
        if (self.local_queue.pop()) |fiber| return fiber;

        // Try global queue
        if (self.scheduler.global_queue.pop()) |fiber| return fiber;

        // Try stealing from other workers
        return self.trySteal();
    }

    /// Attempt to steal a fiber from another worker's local queue.
    fn trySteal(self: *Worker) ?*Fiber {
        const workers = self.scheduler.workers orelse return null;
        const num_workers = workers.len;
        if (num_workers <= 1) return null;

        // Start stealing from a random worker
        var victim = (self.id +% 1) % num_workers;
        var attempts: usize = 0;

        while (attempts < num_workers - 1) : (attempts += 1) {
            if (victim != self.id) {
                if (workers[victim].local_queue.steal()) |fiber| {
                    return fiber;
                }
            }
            victim = (victim +% 1) % num_workers;
        }

        return null;
    }
};

/// Simple lock-free fiber queue (MPSC for global, LIFO for local).
/// This is a basic implementation — can be upgraded to Chase-Lev deque later.
pub const FiberQueue = struct {
    const capacity = 16384;

    head: std.atomic.Value(?*Fiber) = std.atomic.Value(?*Fiber).init(null),
    tail: std.atomic.Value(?*Fiber) = std.atomic.Value(?*Fiber).init(null),
    len: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    items: [capacity]?*Fiber = [_]?*Fiber{null} ** capacity,
    write_pos: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    read_pos: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),

    pub fn init() FiberQueue {
        return .{};
    }

    pub fn push(self: *FiberQueue, fiber: *Fiber) void {
        const pos = self.write_pos.load(.acquire) % capacity;
        self.items[pos] = fiber;
        _ = self.write_pos.fetchAdd(1, .release);
        _ = self.len.fetchAdd(1, .release);
    }

    pub fn pop(self: *FiberQueue) ?*Fiber {
        const len = self.len.load(.acquire);
        if (len == 0) return null;

        const pos = self.read_pos.load(.acquire) % capacity;
        const fiber = self.items[pos] orelse return null;
        self.items[pos] = null;
        _ = self.read_pos.fetchAdd(1, .release);
        _ = self.len.fetchSub(1, .release);
        return fiber;
    }

    /// Steal from the opposite end (FIFO steal for work-stealing).
    pub fn steal(self: *FiberQueue) ?*Fiber {
        return self.pop(); // simplified — same as pop for now
    }
};

/// Scheduler fields
allocator: Allocator,
workers: ?[]Worker = null,
global_queue: FiberQueue = FiberQueue.init(),
shutdown_flag: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
num_threads: usize,

/// Active fiber count — used by Scope to wait for completion
active_fibers: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),

/// Initialize the scheduler with the given number of worker threads.
/// Pass 0 to auto-detect (one per CPU core).
/// Pass 1 for single-threaded mode (ZAG_THREADS=1).
pub fn init(allocator: Allocator, num_threads: usize) !Scheduler {
    const thread_count = if (num_threads == 0)
        std.Thread.getCpuCount() catch 1
    else
        num_threads;

    return Scheduler{
        .allocator = allocator,
        .num_threads = thread_count,
    };
}

/// Start the worker threads.
pub fn start(self: *Scheduler) !void {
    self.workers = try self.allocator.alloc(Worker, self.num_threads);

    for (self.workers.?, 0..) |*worker, i| {
        worker.* = Worker.init(i, self);
    }

    // Start worker threads (skip index 0 — that's the calling thread)
    for (self.workers.?[1..]) |*worker| {
        worker.thread = try Thread.spawn(.{}, Worker.run, .{worker});
    }
}

/// Submit a fiber to the scheduler's global queue.
pub fn submit(self: *Scheduler, fiber: *Fiber) void {
    _ = self.active_fibers.fetchAdd(1, .release);
    self.global_queue.push(fiber);
}

/// Spawn a new fiber running the given function with args.
pub fn spawn(self: *Scheduler, allocator: Allocator, comptime func: anytype, args: anytype) !*Fiber {
    const fiber = try allocator.create(Fiber);
    fiber.* = try Fiber.init(allocator, Fiber.default_stack_size);
    fiber.setup(func, args);
    self.submit(fiber);
    return fiber;
}

/// Run the scheduler on the calling thread (worker 0) until shutdown.
/// This is for the main thread to participate as a worker.
pub fn runOnCallingThread(self: *Scheduler) void {
    if (self.workers) |workers| {
        workers[0].run();
    }
}

/// Signal all workers to stop and wait for them to finish.
pub fn shutdown(self: *Scheduler) void {
    self.shutdown_flag.store(true, .release);

    if (self.workers) |workers| {
        for (workers[1..]) |*worker| {
            if (worker.thread) |thread| {
                thread.join();
                worker.thread = null;
            }
        }
        self.allocator.free(workers);
        self.workers = null;
    }
}

/// Convenience: run fibers until all are complete, then shut down.
/// Good for batch/test usage.
pub fn runUntilComplete(self: *Scheduler) void {
    if (self.workers) |workers| {
        // Run on calling thread's worker until no active fibers remain
        Fiber.setSchedulerContext(&workers[0].sched_context);

        while (self.active_fibers.load(.acquire) > 0) {
            if (workers[0].getNextFiber()) |fiber| {
                workers[0].runFiber(fiber);
            } else {
                std.Thread.yield() catch {};
            }
        }
    }
}

pub fn deinit(self: *Scheduler) void {
    self.shutdown();
}

// --- Global scheduler instance ---

var global_scheduler: ?*Scheduler = null;

pub fn getGlobal() ?*Scheduler {
    return global_scheduler;
}

pub fn setGlobal(sched: *Scheduler) void {
    global_scheduler = sched;
}
