const std = @import("std");
const Build = std.Build;
const Step = Build.Step;
const LazyPath = Build.LazyPath;
const path = std.fs.path;
const mem = std.mem;

const AddGlobFilesStep = @This();

pub const Options = struct {
    library: *Step.Compile,
    dir: LazyPath,
    extension: []const u8,
};

step: Step,
library: *Step.Compile,
dir: LazyPath,
extension: []const u8,

pub fn create(
    b: *std.Build,
    opts: Options,
) *AddGlobFilesStep {
    const self = b.allocator.create(AddGlobFilesStep) catch @panic("OOM");
    self.* = .{
        .library = opts.library,
        .dir = opts.dir.dupe(b),
        .extension = b.dupe(opts.extension),
        .step = Step.init(.{
            .id = .custom,
            .name = b.fmt("{s} add .{s} files from {s}", .{ opts.library.name, opts.extension, opts.dir.getDisplayName() }),
            .owner = b,
            .makeFn = make,
        }),
    };
    self.dir.addStepDependencies(&self.step);

    return self;
}

fn make(step: *Step, prog_node: *std.Progress.Node) anyerror!void {
    _ = prog_node; // autofix
    const b = step.owner;
    const arena = b.allocator;
    const self = @fieldParentPtr(AddGlobFilesStep, "step", step);
    // var man = b.cache.obtain();
    // defer man.deinit();

    const dir_path = self.dir.getPath2(b, step);
    defer arena.free(dir_path);

    const gen_rel_dir = try path.relative(arena, b.build_root.path orelse ".", dir_path);
    defer arena.free(gen_rel_dir);

    const include_dir = try path.join(arena, &.{ gen_rel_dir, "gen", "include" });
    // man.hash.addBytes(include_dir);

    self.library.addIncludePath(.{ .path = include_dir });
    // self.library.installHeadersDirectory(include_dir, ".");

    const dir = try std.fs.openDirAbsolute(dir_path, .{
        .access_sub_paths = true,
    });

    var source_files = std.ArrayList([]const u8).init(arena);
    defer source_files.deinit();

    {
        var walker = try dir.walk(arena);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            if (entry.kind == .file and mem.eql(u8, path.extension(entry.basename), self.extension)) {
                const file_path = try path.join(arena, &.{ gen_rel_dir, entry.path });
                try source_files.append(file_path);
            }
        }
    }

    self.library.addCSourceFiles(.{ .files = source_files.items });
}
