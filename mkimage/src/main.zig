const std = @import("std");
const defs = @import("defs.zig");
const parser = @import("parser.zig");
const emitter = @import("emitter.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var args = std.process.args();

    if (!args.skip()) {
        try stdout.print("Invalid command syntax\n", .{});
        return;
    }

    var arg: ?[]const u8 = args.next();

    var parser_input = defs.ParserInput{};

    var input_found = false;
    while (arg != null) : (arg = args.next()) {
        if (arg.?[0] == '-') {
            if (std.mem.eql(u8, arg.?, "--version")) {
                try print_version();
                return;
            } else if (std.mem.eql(u8, arg.?, "--help")) {
                try print_helpmsg();
                return;
            } else {
                try stdout.print("Error: Unknown config option {s}\n", .{arg.?});
            }
        } else {
            // This is the input directory
            if (input_found) {
                try stdout.print("Error: Multiple input directories\n", .{});
                return;
            }

            input_found = true;
            parser_input.input = arg.?;
        }
    }

    if (!input_found) {
        try stdout.print("Error: No input directory\n", .{});
        return;
    }

    parser_input.directory = try std.fs.cwd().openDir(parser_input.input, .{});
    defer parser_input.directory.close();

    const config: defs.Config = parser.parse(alloc, &parser_input) catch |err| {
        try stdout.print("Error parsing config file:\n", .{});
        try stdout.print("{s}\n", .{switch (err) {
            parser.SyntaxError.NoBootOptionHeader => "NoBootOptionHeader",
            parser.SyntaxError.InvalidKey => "InvalidKey",
            parser.SyntaxError.NoBootOptions => "NoBootOptions",
            parser.SyntaxError.InvalidSeparator => "InvalidSeparator",
            else => "Unknown",
        }});
        return;
    };

    try emitter.emit(alloc, &parser_input, &config);
}

fn print_version() !void {
    try std.io.getStdOut().writer().print("Nebula bootloader version {s}\n", .{defs.version_str});
}

const help_msg =
    \\Nebula mkimage is a tool for creating a bootable image for running NebulaOS with the Nebula bootloader.
    \\Usage: mkimage <config-file> [options]
    \\Valid options for mkimage:
    \\  Others:
    \\    --version: Prints the version of the software. No config-file argument needed. 
    \\    --help: Shows a quick guide on how to use the command. No config-file needed.
    \\
;

fn print_helpmsg() !void {
    try std.io.getStdOut().writer().print("{s}", .{help_msg});
}
