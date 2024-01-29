const std = @import("std");
const AddGlobFilesStep = @import("./add_glob_files_step.zig");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const generate_sources = b.addSystemCommand(&.{ "python", "generate_bindings.py" });
    generate_sources.addFileArg(.{ .path = "gdextension/extension_api.json" });
    const output_dir = generate_sources.addOutputFileArg("");

    const generate = b.step("generate", "Generate sources");
    generate.dependOn(&generate_sources.step);

    const lib = b.addStaticLibrary(.{
        .name = "godot-cpp",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .target = target,
        .optimize = optimize,
    });
    lib.step.dependOn(&generate_sources.step);
    lib.linkLibCpp();
    lib.addIncludePath(.{ .path = "gdextension" });
    lib.addIncludePath(.{ .path = "include" });
    lib.addCSourceFiles(.{ .files = &cpp_source_files });

    const add_generated_cpp_step = AddGlobFilesStep.create(b, .{
        .library = lib,
        .dir = output_dir,
        .extension = ".cpp",
    });
    lib.step.dependOn(&add_generated_cpp_step.step);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);
}

const cpp_source_files = [_][]const u8{
    "src/godot.cpp",

    "src/classes/editor_plugin_registration.cpp",
    "src/classes/low_level.cpp",
    "src/classes/wrapped.cpp",

    "src/core/class_db.cpp",
    "src/core/error_macros.cpp",
    "src/core/memory.cpp",
    "src/core/method_bind.cpp",
    "src/core/object.cpp",

    "src/variant/aabb.cpp",
    "src/variant/basis.cpp",
    "src/variant/callable_custom.cpp",
    "src/variant/callable_method_pointer.cpp",
    "src/variant/char_string.cpp",
    "src/variant/color.cpp",
    "src/variant/packed_arrays.cpp",
    "src/variant/plane.cpp",
    "src/variant/projection.cpp",
    "src/variant/quaternion.cpp",
    "src/variant/rect2.cpp",
    "src/variant/rect2i.cpp",
    "src/variant/transform2d.cpp",
    "src/variant/transform3d.cpp",
    "src/variant/variant.cpp",
    "src/variant/vector2.cpp",
    "src/variant/vector2i.cpp",
    "src/variant/vector3.cpp",
    "src/variant/vector3i.cpp",
    "src/variant/vector4.cpp",
    "src/variant/vector4i.cpp",
};
