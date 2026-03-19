//! Fiber HTTP server benchmark — mimics TurboAPI's architecture.
//!
//! TurboAPI: accept loop → mutex queue → 24 OS threads → handleOneRequest (blocking I/O)
//! Zag fiber: accept loop → spawn fiber per connection → scheduler runs fibers on 1 thread
//!
//! This demonstrates the fiber advantage: thousands of concurrent connections
//! on a single OS thread, vs TurboAPI's 24.
//!
//! Run with: zig build-exe --dep zag -Mroot=test/zag/http_bench.zig -Mzag=lib/std/zag.zig -O ReleaseFast
//! Then: wrk -t4 -c100 -d10s http://127.0.0.1:8080/

const std = @import("std");
const zag = @import("zag");
const net = std.net;
const Fiber = zag.Fiber;
const Scope = zag.Scope;

const response_200 = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 27\r\nConnection: keep-alive\r\n\r\n{\"message\":\"Hello, World!\"}";
const response_404 = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: 22\r\nConnection: close\r\n\r\n{\"error\":\"Not Found\"}";

var total_requests: std.atomic.Value(u64) = std.atomic.Value(u64).init(0);
var active_connections: std.atomic.Value(u64) = std.atomic.Value(u64).init(0);

fn handleConnection(stream: net.Stream) void {
    defer stream.close();
    defer _ = active_connections.fetchSub(1, .release);
    _ = active_connections.fetchAdd(1, .release);

    // Keep-alive loop: handle multiple requests per connection
    var buf: [4096]u8 = undefined;
    while (true) {
        // Read request
        const n = stream.read(&buf) catch break;
        if (n == 0) break;

        // Minimal HTTP parse — find end of headers
        const request = buf[0..n];
        const header_end = std.mem.indexOf(u8, request, "\r\n\r\n") orelse {
            stream.writeAll(response_404) catch break;
            break;
        };
        _ = header_end;

        // Parse method + path from first line
        const first_line_end = std.mem.indexOf(u8, request, "\r\n") orelse break;
        const first_line = request[0..first_line_end];

        var parts = std.mem.splitScalar(u8, first_line, ' ');
        const method = parts.next() orelse break;
        const path = parts.next() orelse break;
        _ = method;

        // Route
        if (std.mem.eql(u8, path, "/") or std.mem.eql(u8, path, "/hello")) {
            stream.writeAll(response_200) catch break;
        } else {
            stream.writeAll(response_404) catch break;
            break; // close on 404
        }

        _ = total_requests.fetchAdd(1, .release);
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const port: u16 = 8080;

    // Initialize fiber runtime
    const sched = try zag.initRuntime(allocator, 1);

    const addr = net.Address.parseIp4("0.0.0.0", port) catch return;
    var server = try addr.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    std.debug.print("=== Zag Fiber HTTP Server ===\n", .{});
    std.debug.print("Listening on http://0.0.0.0:{d}\n", .{port});
    std.debug.print("Fiber runtime: single-threaded, 16KB stacks\n", .{});
    std.debug.print("Benchmark with: wrk -t4 -c100 -d10s http://127.0.0.1:{d}/\n\n", .{port});

    // Stats printer fiber
    _ = try zag.spawn(allocator, struct {
        fn run() void {
            var last: u64 = 0;
            while (true) {
                zag.sleep(1 * std.time.ns_per_s);
                const current = total_requests.load(.acquire);
                const rps = current - last;
                last = current;
                const conns = active_connections.load(.acquire);
                std.debug.print("[stats] {d} req/s | {d} total | {d} active conns\n", .{ rps, current, conns });
            }
        }
    }.run, .{});

    // Accept loop — each connection becomes a fiber
    Fiber.setSchedulerContext(&sched.workers.?[0].sched_context);

    while (true) {
        const conn = server.accept() catch continue;

        // Spawn a fiber for this connection
        _ = zag.spawn(allocator, handleConnection, .{conn.stream}) catch {
            conn.stream.close();
            continue;
        };

        // Run some fibers between accepts to keep things moving
        const workers = sched.workers orelse continue;
        var ran: usize = 0;
        while (ran < 16) : (ran += 1) {
            if (workers[0].getNextFiber()) |fiber| {
                workers[0].runFiber(fiber);
            } else break;
        }
    }
}
