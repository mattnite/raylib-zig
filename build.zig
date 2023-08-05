//
// build
// Zig version: 0.9.0
// Author: Nikolas Wipper
// Date: 2020-02-15
//

const std = @import("std");
const Build = std.Build;
const CompileStep = Build.CompileStep;
const raylib = @import("raylib");

const Program = struct {
    name: []const u8,
    path: []const u8,
    desc: []const u8,
};

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const examples = [_]Program{
        .{
            .name = "basic_window",
            .path = "examples/core/basic_window.zig",
            .desc = "Creates a basic window with text",
        },
        .{
            .name = "input_keys",
            .path = "examples/core/input_keys.zig",
            .desc = "Simple keyboard input",
        },
        .{
            .name = "input_mouse",
            .path = "examples/core/input_mouse.zig",
            .desc = "Simple mouse input",
        },
        .{
            .name = "input_mouse_wheel",
            .path = "examples/core/input_mouse_wheel.zig",
            .desc = "Mouse wheel input",
        },
        .{
            .name = "input_multitouch",
            .path = "examples/core/input_multitouch.zig",
            .desc = "Multitouch input",
        },
        .{
            .name = "2d_camera",
            .path = "examples/core/2d_camera.zig",
            .desc = "Shows the functionality of a 2D camera",
        },
        .{
            .name = "sprite_anim",
            .path = "examples/textures/sprite_anim.zig",
            .desc = "Animate a sprite",
        },
        .{
            .name = "texture_outline",
            .path = "examples/shaders/texture_outline.zig",
            .desc = "Uses a shader to create an outline around a sprite",
        },
        // .{
        //     .name = "models_loading",
        //     .path = "examples/models/models_loading.zig",
        //     .desc = "Loads a model and renders it",
        // },
        // .{
        //     .name = "shaders_basic_lighting",
        //     .path = "examples/shaders/shaders_basic_lighting.zig",
        //     .desc = "Loads a model and renders it",
        // },
    };

    const examples_step = b.step("examples", "Builds all the examples");
    const system_lib = b.option(bool, "system-raylib", "link to preinstalled raylib libraries") orelse false;

    for (examples) |ex| {
        const exe = b.addExecutable(.{
            .name = ex.name,
            .root_source_file = .{ .path = ex.path },
            .target = target,
            .optimize = optimize,
        });

        link(b, exe, system_lib);
        addAsPackage("raylib", exe);
        math.addAsPackage("raylib-math", exe);

        const exe_run = b.addRunArtifact(exe);
        const exe_run_step = b.step(ex.name, ex.desc);
        exe_run_step.dependOn(&exe_run.step);
        examples_step.dependOn(&exe.step);
    }
}

fn getSrcDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub fn link(b: *Build, exe: *CompileStep, system_lib: bool) void {
    if (system_lib) {
        exe.linkSystemLibrary("raylib");
        return;
    } else {
        exe.linkLibrary(raylib.addRaylib(b, exe.target, exe.optimize));
    }

    const target_os = exe.target.toTarget().os.tag;
    switch (target_os) {
        .windows => {
            exe.linkSystemLibrary("winmm");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("opengl32");
        },
        .macos => {
            exe.linkFramework("OpenGL");
            exe.linkFramework("Cocoa");
            exe.linkFramework("IOKit");
            exe.linkFramework("CoreAudio");
            exe.linkFramework("CoreVideo");
        },
        .freebsd, .openbsd, .netbsd, .dragonfly => {
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("rt");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("m");
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("Xrandr");
            exe.linkSystemLibrary("Xinerama");
            exe.linkSystemLibrary("Xi");
            exe.linkSystemLibrary("Xxf86vm");
            exe.linkSystemLibrary("Xcursor");
        },
        else => { // linux and possibly others
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("rt");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("m");
            exe.linkSystemLibrary("X11");
        },
    }
}

const srcdir = getSrcDir();

pub fn addAsPackage(name: []const u8, to: *CompileStep) void {
    to.addAnonymousModule(name, .{
        .source_file = .{ .path = srcdir ++ "/lib/raylib-zig.zig" },
    });
}
pub const math = struct {
    pub fn addAsPackage(name: []const u8, to: *CompileStep) void {
        to.addAnonymousModule(name, .{
            .source_file = .{ .path = srcdir ++ "/lib/raylib-zig-math.zig" },
        });
    }
};
