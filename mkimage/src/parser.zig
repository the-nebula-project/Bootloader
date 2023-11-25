const std = @import("std");
const defs = @import("defs.zig");

pub const SyntaxError = error{ InvalidSeparator, InvalidKey, NoBootOptionHeader, NoBootOptions };

pub fn parse(alloc: std.mem.Allocator, parser_input: *defs.ParserInput) !defs.Config {
    var config_file = try parser_input.directory.openFile("boot.conf", .{});
    defer config_file.close();

    var lexer = Lexer{};
    lexer.init(&config_file);

    var config: defs.Config = .{ .boot_options = std.ArrayList(defs.BootOption).init(alloc) };

    var statement: ?KeyValue = try lexer.next();
    var curr_boot_option: ?defs.BootOption = null;

    while (statement != null) : (statement = try lexer.next()) {
        if (statement.?.key.len == 0) return SyntaxError.InvalidKey;
        if (statement.?.is_header) {
            if (std.mem.eql(u8, statement.?.key, "bootoption")) {
                if (curr_boot_option != null) try config.boot_options.append(curr_boot_option.?);
                curr_boot_option = .{ .name = try alloc.dupe(u8, statement.?.value) };
                continue;
            }
        } else {
            // Non bootoption specific options
            if (std.mem.eql(u8, statement.?.key, "autoboot")) {
                config.autoboot = try alloc.dupe(u8, statement.?.value);
                continue;
            }

            if (std.mem.eql(u8, statement.?.key, "bootloader.path")) {
                config.bootloader_path = try alloc.dupe(u8, statement.?.value);
                continue;
            }

            if (std.mem.eql(u8, statement.?.key, "outpath")) {
                config.out_path = try alloc.dupe(u8, statement.?.value);
                continue;
            }

            // Bootoption specific options
            if (curr_boot_option == null) return SyntaxError.NoBootOptionHeader;

            if (std.mem.eql(u8, statement.?.key, "file")) {
                curr_boot_option.?.file = try alloc.dupe(u8, statement.?.value);
                continue;
            }
        }
    }

    if (curr_boot_option == null) return SyntaxError.NoBootOptions;
    try config.boot_options.append(curr_boot_option.?);

    return config;
}

const KeyValue = struct {
    key: []const u8 = undefined,
    is_header: bool = false,
    value: []const u8 = undefined,
};

const Lexer = struct {
    buf_reader: std.io.BufferedReader(4096, std.fs.File.Reader).Reader = undefined,
    line: [1024]u8 = undefined,

    pub fn init(self: *Lexer, file: *std.fs.File) void {
        var read = std.io.bufferedReader(file.reader());
        self.buf_reader = read.reader();
    }

    pub fn next(self: *Lexer) !?KeyValue {
        var line: []u8 = try self.buf_reader.readUntilDelimiterOrEof(&self.line, '\n') orelse return null;

        var result: KeyValue = .{};
        while (line.len == 0) : (line = try self.buf_reader.readUntilDelimiterOrEof(&self.line, '\n') orelse return null) {}

        if (line.len >= 2) {
            while (std.mem.indexOf(u8, line, "//") != null) {
                line = try self.buf_reader.readUntilDelimiterOrEof(&self.line, '\n') orelse return null;
            }
        }

        const eql: ?usize = std.mem.indexOf(u8, line, "=");
        const colon: ?usize = std.mem.indexOf(u8, line, ":");
        const index = if (eql != null) eql.? else if (colon != null) colon.? else return SyntaxError.InvalidSeparator;

        const key = std.mem.trim(u8, line[0 .. index - 1], " \t");
        const value = std.mem.trim(u8, line[index + 1 ..], " \t");
        try std.io.getStdOut().writer().print("Key: {s}, Value: {s}\n", .{ key, value });

        result.is_header = eql == null;
        result.key = key;
        result.value = value;

        return result;
    }
};
