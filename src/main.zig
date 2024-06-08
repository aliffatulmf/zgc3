const std = @import("std");
const shell = @import("shell.zig");

const mem = std.mem;
const time = std.time;
const os = std.os;

const Dir = std.fs.Dir;
const OpenError = Dir.OpenError;
const DeleteTreeError = Dir.DeleteTreeError;
const DeleteFileError = Dir.DeleteFileError;
const Kind = Dir.Entry.Kind;

pub fn main() !void {
    const stderr = std.io.getStdErr().writer();

    // create an Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // get the target path
    const target = try getTarget(allocator);

    // ======================== BEGIN ========================
    const t = try std.fs.cwd().openDir(target, .{ .iterate = true });

    // set the directory as the current working directory
    try t.setAsCwd();

    // create a walker
    var walker = try t.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == Kind.directory) {
            t.deleteTree(entry.path) catch |err| {
                return switch (err) {
                    DeleteTreeError.FileBusy => {
                        try stderr.print("[ERROR]: Directory is busy.\n", .{});
                    },
                    else => err,
                };
            };
        } else if (entry.kind == Kind.file) {
            t.deleteFile(entry.path) catch |err| {
                return switch (err) {
                    DeleteFileError.FileBusy => {
                        try stderr.print("[ERROR]: File is busy.\n", .{});
                    },
                    else => err,
                };
            };
        }
    }
}

fn getTarget(allocator: mem.Allocator) ![]const u8 {
    const roaming: []const u8 = try shell.getAppDataRoaming(allocator);

    // buffer for storing the target path
    var buf: [256]u8 = undefined;
    const target = try std.fmt.bufPrint(&buf, "{s}\\{s}", .{ roaming, "Code\\User\\workspaceStorage" });
    return target;
}
