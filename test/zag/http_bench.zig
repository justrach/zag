//! Multi-threaded fiber HTTP server benchmark.
//!
//! Architecture:
//!   Main thread: accept loop → spawn fiber per connection → push to global queue
//!   Worker threads: pop fibers from global queue, run them (blocking I/O for now)
//!
//! Run: zig build-exe --dep zag -Mroot=test/zag/http_bench.zig -Mzag=lib/std/zag.zig -O ReleaseFast
//! Bench: wrk -t4 -c200 -d10s http://127.0.0.1:8080/

const std = @import("std");
const zag = @import("zag");
const net = std.net;
const Fiber = zag.Fiber;
const Scheduler = zag.Scheduler;
const Thread = std.Thread;

const response_200 = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 27\r\nConnection: keep-alive\r\n\r\n{\"message\":\"Hello, World!\"}";
const response_404 = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: 22\r\nConnection: close\r\n\r\n{\"error\":\"Not Found\"}";

var total_requests: std.atomic.Value(u64) = std.atomic.Value(u64).init(0);
var active_connections: std.atomic.Value(u64) = std.atomic.Value(u64).init(0);

fn handleConnection(stream: net.Stream) void {
    defer stream.close();
    defer _ = active_connections.fetchSub(1, .release);
    _ = active_connections.fetchAdd(1, .release);

    var buf: [4096]u8 = undefined;
    while (true) {
        const n = stream.read(&buf) catch break;
        if (n == 0) break;

        const request = buf[0..n];
        const header_end = std.mem.indexOf(u8, request, "\r\n\r\n") orelse {
            stream.writeAll(response_404) catch break;
            break;
        };
        _ = header_end;

        const first_line_end = std.mem.indexOf(u8, request, "\r\n") orelse break;
        const first_line = request[0..first_line_end];

        var parts = std.mem.splitScalar(u8, first_line, ' ');
        _ = parts.next() orelse break; // method
        const path = parts.next() orelse break;

        if (std.mem.eql(u8, path, "/") or std.mem.eql(u8, path, "/hello")) {
            stream.writeAll(response_200) catch break;
        } else {
            stream.writeAll(response_404) catch break;
            break;
        }

        _ = total_requests.fetchAdd(1, .release);
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const port: u16 = 8080;

    // Detect CPU count
    const cpu_count = Thread.getCpuCount() catch 4;
    const num_workers = @max(cpu_count, 2);

    std.debug.print("=== Zag Fiber HTTP Server (multi-threaded) ===\n", .{});
    std.debug.print("Workers: {d} threads\n", .{num_workers});
    std.debug.print("Fiber stacks: 16KB\n", .{});

    // Initialize scheduler with N worker threads
    const sched = try allocator.create(Scheduler);
    sched.* = try Scheduler.init(allocator, num_workers);

    // Allocate workers
    sched.workers = try allocator.alloc(Scheduler.Worker, num_workers);
    for (sched.workers.?, 0..) |*worker, i| {
        worker.* = Scheduler.Worker.init(i, sched);
    }
    Scheduler.setGlobal(sched);

    // Start worker threads (all of them — main thread does accept only)
    for (sched.workers.?) |*worker| {
        worker.thread = try Thread.spawn(.{}, Scheduler.Worker.run, .{worker});
    }

    // Bind and listen
    const addr = net.Address.parseIp4("0.0.0.0", port) catch return;
    var server = try addr.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    std.debug.print("Listening on http://0.0.0.0:{d}\n", .{port});
    std.debug.print("Benchmark: wrk -t4 -c200 -d10s http://127.0.0.1:{d}/\n\n", .{port});

    // Stats thread
    const stats_thread = try Thread.spawn(.{}, struct {
        fn run() void {
            var last: u64 = 0;
            while (true) {
                std.Thread.sleep(1 * std.time.ns_per_s);
                const current = total_requests.load(.acquire);
                const rps = current - last;
                last = current;
                const conns = active_connections.load(.acquire);
                std.debug.print("[stats] {d} req/s | {d} total | {d} active conns\n", .{ rps, current, conns });
            }
        }
    }.run, .{});
    _ = stats_thread;

    // Accept loop — main thread only does accept + spawn
    while (true) {
        const conn = server.accept() catch continue;

        // Create fiber for this connection
        const fiber = allocator.create(Fiber) catch {
            conn.stream.close();
            continue;
        };
        fiber.* = Fiber.init(allocator, Fiber.default_stack_size) catch {
            allocator.destroy(fiber);
            conn.stream.close();
            continue;
        };
        fiber.setup(handleConnection, .{conn.stream});

        // Submit to scheduler — worker threads will pick it up
        sched.submit(fiber);
    }
}
