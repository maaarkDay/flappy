const std = @import("std");

pub fn build(b: *std.Build) void {
    // Create executable
    const exe = b.addExecutable(.{
        .name = "Flappy Birds",
        .root_source_file = b.path("main.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    // Link the C library
    exe.linkLibC();

    // Link Objective-C runtime
    exe.linkSystemLibrary("objc");

    // Link the required macOS frameworks
    exe.linkFramework("Foundation");
    exe.linkFramework("AppKit");
    exe.linkFramework("CoreGraphics");

    // Install the executable in the build directory
    b.installArtifact(exe);

    // Create a run step
    const run_artifact = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");

    // AddRunArtifact takes time to complete
    // DependOn makes sure it completes
    // & is a pointer to run_artifact.step
    // DependOn takes a pointer as it's arg
    run_step.dependOn(&run_artifact.step);
}
