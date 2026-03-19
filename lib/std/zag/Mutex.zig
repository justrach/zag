//! Fiber-aware Mutex — parks the fiber (not the OS thread) when contended.
//!
//! When a fiber tries to lock a contended mutex, it yields to the scheduler
//! instead of blocking the OS thread. This allows other fibers on the same
//! worker to make progress.
//!
//! Falls back to spin-yield when not in a fiber context.

const std = @import("std");
const Fiber = @import("Fiber.zig");

const Mutex = @This();

/// 0 = unlocked, 1 = locked
state: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),

/// Lock the mutex. Parks the fiber if contended.
pub fn lock(self: *Mutex) void {
    while (self.state.cmpxchgWeak(0, 1, .acquire, .monotonic) != null) {
        // Contended — yield the fiber instead of spinning the OS thread
        const zag = @import("../zag.zig");
        zag.yield();
    }
}

/// Try to lock without blocking. Returns true if acquired.
pub fn tryLock(self: *Mutex) bool {
    return self.state.cmpxchgWeak(0, 1, .acquire, .monotonic) == null;
}

/// Unlock the mutex.
pub fn unlock(self: *Mutex) void {
    self.state.store(0, .release);
}

/// RAII-style lock guard.
pub fn Held(comptime MutexT: type) type {
    return struct {
        mutex: *MutexT,

        pub fn release(self: @This()) void {
            self.mutex.unlock();
        }
    };
}

/// Lock and return a guard that auto-unlocks on scope exit.
pub fn acquire(self: *Mutex) Held(Mutex) {
    self.lock();
    return .{ .mutex = self };
}
