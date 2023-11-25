const std = @import("std");
const parser = @import("parser.zig");
const defs = @import("defs.zig");

const EmitterError = error{ NoSuchBootOption, NoBootloader, BootloaderTooLarge };

pub fn emit(alloc: std.mem.Allocator, input: *defs.ParserInput, config: *const defs.Config) !void {
    const stdout = std.io.getStdOut().writer();
    _ = alloc;

    if (config.bootloader_path == null) {
        return EmitterError.NoBootloader;
    }

    try stdout.print("ab: {s}\n", .{config.autoboot.?});
    var bl_file = input.directory.openFile(config.bootloader_path.?, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            try stdout.print("Error: Bootloader binary file not found", .{});
            return;
        },
        else => {
            return err;
        },
    };

    defer bl_file.close();

    var os_file: std.fs.File = undefined;

    if (config.autoboot != null) {
        var option_found: ?defs.BootOption = null;
        for (config.boot_options.items) |option| {
            if (std.mem.eql(u8, option.name, config.autoboot.?)) {
                option_found = option;
            }
        }

        if (option_found == null) {
            return EmitterError.NoSuchBootOption;
        }

        // We have a valid boot option
        os_file = input.directory.openFile(option_found.?.file, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                try stdout.print("Error: Bootoption file {s} not found\n", .{option_found.?.file});
                return;
            },
            else => {
                return err;
            },
        };

        defer os_file.close();

        var outfile: std.fs.File = try input.directory.createFile(if (config.out_path != null) config.out_path.? else defs.default_out_path, .{});
        defer outfile.close();

        // Begin by writing the bootloader to the bootsector.
        try outfile.writeFileAll(bl_file, .{});
        const written: usize = (try outfile.stat()).size;

        if (written <= defs.bootloader_size_bytes) {
            const remaining = defs.bootloader_size_bytes - written;
            try outfile.writer().writeByteNTimes(0, remaining);
        } else {
            try stdout.print("Error: Invalid bootloader file: too large", .{});
            return EmitterError.BootloaderTooLarge;
        }

        // Then, we serialize and write the config
        const flags: u32 = @intFromEnum(defs.EmittedFlags.Autoboot);
        try outfile.writer().writeInt(u32, flags, std.builtin.Endian.little);

        const bootoptions_len: u32 = @intCast(config.boot_options.items.len);
        try outfile.writer().writeInt(u32, bootoptions_len, std.builtin.Endian.little);

        const autoboot_size: u32 = @intCast((try os_file.stat()).size);
        try outfile.writer().writeInt(u32, (autoboot_size / defs.sector_size) + 1, std.builtin.Endian.little);

        try outfile.writeFileAll(os_file, .{});

        return;
    }
}
