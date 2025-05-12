const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const os = target.result.os.tag;

    const dep = b.dependency("uv", .{});

    const uv = b.addStaticLibrary(.{
        .target = target,
        .optimize = optimize,
        .name = "uv",
    });
    b.installArtifact(uv);
    uv.linkLibC();

    uv.addIncludePath(dep.path("include"));
    uv.addIncludePath(dep.path("src"));

    var flags: std.ArrayListUnmanaged([]const u8) = .{};
    defer flags.deinit(b.allocator);

    if (os != .windows) {
        try flags.appendSlice(b.allocator, &.{
            "-D_FILE_OFFSET_BITS=64",
            "-D_LARGEFILE_SOURCE",
        });
    }

    if (os == .linux) {
        try flags.appendSlice(b.allocator, &.{
            "-D_GNU_SOURCE",
            "-D_POSIX_C_SOURCE=200112",
        });
    }

    if (os.isDarwin()) {
        try flags.appendSlice(b.allocator, &.{
            "-D_DARWIN_UNLIMITED_SELECT=1",
            "-D_DARWIN_USE_64_BIT_INODE=1",
        });
    }

    uv.addCSourceFiles(.{
        .root = dep.path("src"),
        .files = &.{
            "fs-poll.c",                "idna.c",    "inet.c",
            "random.c",                 "strscpy.c", "strtok.c",
            "threadpool.c",             "timer.c",   "uv-common.c",
            "uv-data-getter-setters.c", "version.c",
        },
        .flags = flags.items,
    });

    if (os != .windows) {
        uv.addCSourceFiles(.{
            .root = dep.path("src/unix"),
            .files = &.{
                "async.c",        "core.c",        "dl.c",
                "fs.c",           "getaddrinfo.c", "getnameinfo.c",
                "loop-watcher.c", "loop.c",        "pipe.c",
                "poll.c",         "process.c",     "random-devurandom.c",
                "signal.c",       "stream.c",      "tcp.c",
                "thread.c",       "tty.c",         "udp.c",
            },
            .flags = flags.items,
        });
    }

    if (os == .linux or os.isDarwin()) {
        uv.addCSourceFile(.{
            .file = dep.path("src/unix/proctitle.c"),
            .flags = flags.items,
        });
    }

    if (os == .linux) {
        uv.addCSourceFiles(.{
            .root = dep.path("src/unix"),
            .files = &.{
                "linux.c",
                "procfs-exepath.c",
                "random-getrandom.c",
                "random-sysctl-linux.c",
            },
            .flags = flags.items,
        });
    }

    if (os.isDarwin() or
        os == .openbsd or
        os == .netbsd or
        os == .freebsd or
        os == .dragonfly)
    {
        uv.addCSourceFiles(.{
            .root = dep.path("src/unix"),
            .files = &.{
                "bsd-ifaddrs.c",
                "kqueue.c",
            },
            .flags = flags.items,
        });
    }

    if (os.isDarwin() or os == .openbsd) {
        uv.addCSourceFile(.{
            .file = dep.path("src/unix/random-getentropy.c"),
            .flags = flags.items,
        });
    }

    if (os.isDarwin()) {
        uv.addCSourceFiles(.{
            .root = dep.path("src/unix"),
            .files = &.{
                "darwin-proctitle.c",
                "darwin.c",
                "fsevents.c",
            },
            .flags = flags.items,
        });
    }
}
