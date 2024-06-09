const std = @import("std");
const shell = @import("shell.zig");

const mem = std.mem;
const time = std.time;
const os = std.os;

const Dir = std.fs.Dir;
const Kind = Dir.Entry.Kind;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const wsp = try workspaceStoragePath(allocator);

    var w = try std.fs.openDirAbsolute(wsp, .{ .iterate = true });
    defer w.close();

    try w.setAsCwd();

    execute(allocator, w) catch |err| {
        std.debug.print("error: {}\n", .{err});
        std.process.exit(1);
    };
}

fn execute(allocator: mem.Allocator, dir: Dir) !void {
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == Kind.directory) {
            try dir.deleteTree(entry.path);
        }
    }
}

fn workspaceStoragePath(allocator: mem.Allocator) ![]const u8 {
    const app_data = try shell.getAppDataPath(allocator);

    const target = try std.fs.path.join(allocator, &[_][]const u8{
        app_data,
        "Code",
        "User",
        "workspaceStorage",
    });
    return target;
}
