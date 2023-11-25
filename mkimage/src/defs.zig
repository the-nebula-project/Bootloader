const std = @import("std");

pub const version_str: []const u8 = "0.1";

pub const ParserInput = struct {
    input: []const u8 = "",
    directory: std.fs.Dir = undefined,
};

pub const BootOption = struct {
    name: []const u8,
    file: []const u8 = undefined,
};

pub const Config = struct {
    autoboot: ?[]const u8 = null,
    boot_options: std.ArrayList(BootOption) = undefined,
    bootloader_path: ?[]const u8 = null,
    out_path: ?[]const u8 = null,
};

pub const default_out_path = "out.img";

pub const sector_size = 512; // Probably varies from medium to medium, get a way to calculate this
pub const bootloader_size_bytes = (sector_size * 16);

pub const EmittedFlags = enum(u32) {
    Autoboot = (1 << 0), // The bootloader ignores all bootoptions except for the first
};
