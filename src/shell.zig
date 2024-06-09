const std = @import("std");
const mem = std.mem;
const os = std.os;
const testing = std.testing;

// https://docs.microsoft.com/en-us/windows/win32/shell/knownfolderid
const FOLDERID_RoamingAppData = os.windows.GUID.parse("{3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}");

// Not Yet Implemented:
// https://github.com/ziglang/zig/issues/18098
pub extern "shell32" fn SHGetKnownFolderPath(
    rfid: *const os.windows.KNOWNFOLDERID,
    dwFlags: os.windows.DWORD,
    hToken: ?os.windows.HANDLE,
    ppszPath: *[*:0]os.windows.WCHAR,
) callconv(os.windows.WINAPI) os.windows.HRESULT;

pub fn getAppDataPath(allocator: mem.Allocator) ![]u8 {
    var dir_path_ptr: [*:0]u16 = undefined;
    switch (SHGetKnownFolderPath(
        &FOLDERID_RoamingAppData,
        os.windows.KF_FLAG_CREATE,
        null,
        &dir_path_ptr,
    )) {
        os.windows.S_OK => {
            const global_dir = std.unicode.utf16LeToUtf8Alloc(allocator, mem.sliceTo(dir_path_ptr, 0)) catch |err| switch (err) {
                error.UnexpectedSecondSurrogateHalf => return error.AppDataDirUnavailable,
                error.ExpectedSecondSurrogateHalf => return error.AppDataDirUnavailable,
                error.DanglingSurrogateHalf => return error.AppDataDirUnavailable,
                error.OutOfMemory => return error.OutOfMemory,
            };
            return global_dir;
        },
        os.windows.E_OUTOFMEMORY => return error.OutOfMemory,
        else => return error.AppDataDirUnavailable,
    }
}
