//! Test @atomicRmw codegen on AArch64 (issue #13).
//! Exercises the .atomic_rmw AIR instruction through the self-hosted backend.

const std = @import("std");

pub fn main() void {
    // Add: 64-bit (ldaddal_x)
    var val64: u64 = 10;
    const old64 = @atomicRmw(u64, &val64, .Add, 5, .seq_cst);
    std.debug.assert(old64 == 10);
    std.debug.assert(val64 == 15);

    // Add: 32-bit (ldaddal_w)
    var val32: u32 = 100;
    const old32 = @atomicRmw(u32, &val32, .Add, 7, .seq_cst);
    std.debug.assert(old32 == 100);
    std.debug.assert(val32 == 107);

    // Xchg: 64-bit (swpal_x)
    var xchg64: u64 = 42;
    const prev64 = @atomicRmw(u64, &xchg64, .Xchg, 99, .seq_cst);
    std.debug.assert(prev64 == 42);
    std.debug.assert(xchg64 == 99);
}
