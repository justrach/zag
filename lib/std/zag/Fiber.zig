//! Fiber — lightweight stackful coroutine for Zag structured concurrency.
//!
//! A fiber is a user-space thread with its own stack, cooperatively scheduled
//! on a work-stealing thread pool. Functions spawned on fibers are plain
//! functions — no async, no Io parameter, no coloring.
//!
//! Stack sizes are configurable (default 16KB). Context switching is done
//! via platform-specific assembly (aarch64, x86_64).

const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const Fiber = @This();

/// Fiber states
pub const State = enum {
    /// Created but not yet started
    dormant,
    /// Currently executing on a worker thread
    running,
    /// Suspended, waiting to be resumed (yielded or parked)
    suspended,
    /// Finished execution
    completed,
    /// Cancelled via checkCancel()
    cancelled,
};

/// Platform-specific saved context for context switching.
/// On aarch64: callee-saved registers x19-x30, d8-d15, sp.
/// On x86_64: callee-saved registers rbx, rbp, r12-r15, rsp.
pub const Context = switch (builtin.cpu.arch) {
    .aarch64 => extern struct {
        x19: u64 = 0,
        x20: u64 = 0,
        x21: u64 = 0,
        x22: u64 = 0,
        x23: u64 = 0,
        x24: u64 = 0,
        x25: u64 = 0,
        x26: u64 = 0,
        x27: u64 = 0,
        x28: u64 = 0,
        x29: u64 = 0, // frame pointer
        x30: u64 = 0, // link register (return address)
        sp: u64 = 0,
        d8: u64 = 0,
        d9: u64 = 0,
        d10: u64 = 0,
        d11: u64 = 0,
        d12: u64 = 0,
        d13: u64 = 0,
        d14: u64 = 0,
        d15: u64 = 0,
    },
    .x86_64 => extern struct {
        rbx: u64 = 0,
        rbp: u64 = 0,
        r12: u64 = 0,
        r13: u64 = 0,
        r14: u64 = 0,
        r15: u64 = 0,
        rsp: u64 = 0,
    },
    else => @compileError("Unsupported architecture for Zag fibers"),
};

/// Saved execution context
context: Context = .{},

/// Current fiber state
state: State = .dormant,

/// Stack memory (owned by the fiber)
stack: []u8,

/// Allocator used for the stack
allocator: Allocator,

/// The function this fiber will execute (type-erased)
entry_fn: *const fn (*Fiber) void = undefined,

/// Cancellation flag — checked by zag.checkCancel()
cancel_flag: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

/// Result: error captured from the fiber's execution
@"error": ?anyerror = null,

/// Parent scope (if any) — set by Scope.spawn
scope: ?*anyopaque = null,

/// Default stack size: 16KB (sized for network handlers with 8KB+ buffers)
pub const default_stack_size: usize = 16 * 1024;

/// Minimum stack size: 8KB
pub const min_stack_size: usize = 8 * 1024;

/// Create a new fiber with the given stack size.
pub fn init(allocator: Allocator, stack_size: usize) !Fiber {
    const actual_size = @max(stack_size, min_stack_size);
    const page_size = std.heap.pageSize();
    const aligned_size = std.mem.alignForward(usize, actual_size, page_size);

    const stack = try allocator.alloc(u8, aligned_size);

    return Fiber{
        .stack = @alignCast(stack),
        .allocator = allocator,
        .state = .dormant,
    };
}

/// Free fiber resources.
pub fn deinit(self: *Fiber) void {
    self.allocator.free(self.stack);
    self.* = undefined;
}

/// Prepare the fiber to execute a function.
/// The function is type-erased via a wrapper that captures the comptime fn and args.
pub fn setup(self: *Fiber, comptime func: anytype, args: anytype) void {
    const Args = @TypeOf(args);

    const Wrapper = struct {
        fn entry(fiber: *Fiber) void {
            // Recover args from the top of the fiber's stack
            const stack_top = @intFromPtr(fiber.stack.ptr) + fiber.stack.len;
            const args_addr = std.mem.alignBackward(usize, stack_top - @sizeOf(Args), @alignOf(Args));
            const args_ptr: *Args = @ptrFromInt(args_addr);
            const captured_args = args_ptr.*;

            // Call the actual function
            const result = @call(.auto, func, captured_args);

            // Handle the result
            switch (@typeInfo(@TypeOf(result))) {
                .error_union => {
                    if (result) |_| {} else |err| {
                        fiber.@"error" = err;
                    }
                },
                else => {},
            }

            fiber.state = .completed;

            // Yield back to scheduler — fiber is done
            switchToScheduler(fiber);
        }
    };

    // Store args at the top of the stack
    const stack_top = @intFromPtr(self.stack.ptr) + self.stack.len;
    const args_addr = std.mem.alignBackward(usize, stack_top - @sizeOf(Args), @alignOf(Args));
    const args_ptr: *Args = @ptrFromInt(args_addr);
    args_ptr.* = args;

    self.entry_fn = Wrapper.entry;
    self.state = .dormant;

    // Set up initial context: stack pointer and entry point
    const usable_stack_top = std.mem.alignBackward(usize, args_addr, 16);
    self.initContext(usable_stack_top);
}

/// Check if this fiber has been cancelled.
/// Called by user code via zag.checkCancel().
pub fn isCancelled(self: *const Fiber) bool {
    return self.cancel_flag.load(.acquire);
}

/// Request cancellation of this fiber.
pub fn cancel(self: *Fiber) void {
    self.cancel_flag.store(true, .release);
}

// --- Platform-specific context switching ---

/// Initialize the fiber's context for first execution.
fn initContext(self: *Fiber, stack_top: usize) void {
    self.context = .{};
    switch (builtin.cpu.arch) {
        .aarch64 => {
            self.context.sp = stack_top;
            self.context.x30 = @intFromPtr(&fiberStart);
        },
        .x86_64 => {
            // x86_64: return address is at top of stack
            const rsp = stack_top - @sizeOf(u64);
            const ret_addr_ptr: *u64 = @ptrFromInt(rsp);
            ret_addr_ptr.* = @intFromPtr(&fiberStart);
            self.context.rsp = rsp;
        },
        else => unreachable,
    }
}

/// Entry point for a newly started fiber.
/// Called via the context switch with the fiber pointer in a known register.
fn fiberStart() callconv(.c) void {
    // The current fiber pointer is stored in thread-local state by the scheduler
    const fiber = getCurrentFiber() orelse unreachable;
    fiber.state = .running;
    fiber.entry_fn(fiber);
    // entry_fn sets state to .completed and yields back
    // If we somehow get here, just loop (shouldn't happen)
    unreachable;
}

/// Switch from the current fiber to the scheduler context.
/// This saves the fiber's registers and restores the scheduler's.
pub fn switchToScheduler(fiber: *Fiber) void {
    // The scheduler context is stored in thread-local storage
    const sched_ctx = getSchedulerContext() orelse return;
    switchContext(&fiber.context, sched_ctx);
}

/// Switch from the scheduler to a fiber.
/// This saves the scheduler's registers and restores the fiber's.
pub fn switchFromScheduler(fiber: *Fiber) void {
    const sched_ctx = getSchedulerContext() orelse return;
    setCurrentFiber(fiber);
    switchContext(sched_ctx, &fiber.context);
}

/// Low-level context switch: save current registers to `from`, load registers from `to`.
pub fn switchContext(from: *Context, to: *const Context) void {
    switch (builtin.cpu.arch) {
        .aarch64 => switchContextAarch64(from, to),
        .x86_64 => switchContextX86_64(from, to),
        else => unreachable,
    }
}

fn switchContextAarch64(from: *Context, to: *const Context) void {
    asm volatile (
        // Save callee-saved registers to `from`
        \\stp x19, x20, [x0, #0]
        \\stp x21, x22, [x0, #16]
        \\stp x23, x24, [x0, #32]
        \\stp x25, x26, [x0, #48]
        \\stp x27, x28, [x0, #64]
        \\stp x29, x30, [x0, #80]
        \\mov x2, sp
        \\str x2, [x0, #96]
        \\stp d8, d9, [x0, #104]
        \\stp d10, d11, [x0, #120]
        \\stp d12, d13, [x0, #136]
        \\stp d14, d15, [x0, #152]
        // Load callee-saved registers from `to`
        \\ldp x19, x20, [x1, #0]
        \\ldp x21, x22, [x1, #16]
        \\ldp x23, x24, [x1, #32]
        \\ldp x25, x26, [x1, #48]
        \\ldp x27, x28, [x1, #64]
        \\ldp x29, x30, [x1, #80]
        \\ldr x2, [x1, #96]
        \\mov sp, x2
        \\ldp d8, d9, [x1, #104]
        \\ldp d10, d11, [x1, #120]
        \\ldp d12, d13, [x1, #136]
        \\ldp d14, d15, [x1, #152]
        \\ret
        :
        : [from] "{x0}" (from),
          [to] "{x1}" (to),
        : .{ .x2 = true, .memory = true });
}

fn switchContextX86_64(from: *Context, to: *const Context) void {
    asm volatile (
        // Save callee-saved registers to `from`
        \\movq %%rbx, 0(%%rdi)
        \\movq %%rbp, 8(%%rdi)
        \\movq %%r12, 16(%%rdi)
        \\movq %%r13, 24(%%rdi)
        \\movq %%r14, 32(%%rdi)
        \\movq %%r15, 40(%%rdi)
        \\movq %%rsp, 48(%%rdi)
        // Load callee-saved registers from `to`
        \\movq 0(%%rsi), %%rbx
        \\movq 8(%%rsi), %%rbp
        \\movq 16(%%rsi), %%r12
        \\movq 24(%%rsi), %%r13
        \\movq 32(%%rsi), %%r14
        \\movq 40(%%rsi), %%r15
        \\movq 48(%%rsi), %%rsp
        \\ret
        :
        : [from] "{rdi}" (from),
          [to] "{rsi}" (to),
        : .{ .memory = true });
}

// --- Thread-local storage for fiber/scheduler state ---

threadlocal var current_fiber: ?*Fiber = null;
threadlocal var scheduler_context: ?*Context = null;

pub fn getCurrentFiber() ?*Fiber {
    return current_fiber;
}

pub fn setCurrentFiber(fiber: *Fiber) void {
    current_fiber = fiber;
}

pub fn getSchedulerContext() ?*Context {
    return scheduler_context;
}

pub fn setSchedulerContext(ctx: *Context) void {
    scheduler_context = ctx;
}
