const std = @import("std");

const Machine = struct {
    pc: i64,
    memory: std.ArrayList(i64),
    fn read(self: *Machine, at: i64) i64 {
        if (at < 0) {
            @panic("Something sinister happened!");
        }
        const atu: usize = @bitCast(at);
        return self.memory.items[atu];
    }
    fn write(self: *Machine, at: i64, value: i64) void {
        if (at < 0) {
            @panic("Something sinister happened!");
        }
        const atu: usize = @bitCast(at);
        self.memory.items[atu] = value;
    }
    fn deinit(self: *Machine) void {
        self.memory.deinit();
    }
};

fn interpret(m: *Machine) void {
    while (true) {
        const a_location = m.read(m.pc);
        const b_location = m.read(m.pc + 1);

        if ((a_location == -1) and (b_location == -1)) {
            std.debug.print("Press any key to continue\n", .{});
            var buf: [1]u8 = undefined;
            _ = std.io.getStdIn().read(&buf) catch 0;
            m.pc += 3;
        } else if (a_location == -1) {
            var buf: [1]u8 = undefined;
            var read = std.io.getStdIn().read(&buf) catch 0;
            const b = m.read(b_location);
            var new_b: i64 = undefined;
            if (read > 0) {
                new_b = b + buf[0];
            } else {
                new_b = b - 1;
            }
            m.write(b_location, new_b);
            if (new_b <= 0) {
                m.pc = m.read(m.pc + 2);
            } else {
                m.pc += 3;
            }
        } else if (b_location == -1) {
            const a = m.read(a_location);
            var out: [1]u8 = .{@intCast(a)};
            _ = std.io.getStdOut().write(&out) catch {};
            m.pc += 3;
        } else {
            const a = m.read(a_location);
            const b = m.read(b_location);
            const result = @subWithOverflow(b, a)[0];
            m.write(b_location, result);
            if (result <= 0) {
                m.pc = m.read(m.pc + 2);
                if (m.pc < 0) {
                    std.debug.print("Execution ended!\n", .{});
                    return;
                }
            } else {
                m.pc += 3;
            }
        }
    }
}

// TODO: Not used. Perhaps in the future?
fn load() Machine {
    const fd = try std.os.open("./boot.dat", std.os.O.RDONLY, 0);
    const prot = std.os.system.PROT.READ;
    const stats = try std.os.fstat(fd);
    const ptr = try std.os.mmap(null, @intCast(stats.size), prot, std.os.system.MAP.SHARED, fd, 0);
    const shorter = ptr[0 .. ((ptr.len - 1) / 4) * 4];
    const mem64 = std.mem.bytesAsSlice(i64, shorter);
    for (mem64) |i| {
        std.debug.print("hi: {d}\n", .{i});
    }
    return Machine{
        .pc = 0,
        .mem = mem64,
    };
}

fn loadSQ(allocator: std.mem.Allocator) !Machine {
    const fd = try std.os.open("./boot.sq", std.os.O.RDONLY, 0);
    const prot = std.os.system.PROT.READ;
    const flags = std.os.system.MAP.SHARED;
    const stats = try std.os.fstat(fd);
    const ptr = try std.os.mmap(null, @intCast(stats.size), prot, flags, fd, 0);
    var tokens = std.mem.tokenizeAny(u8, ptr, " \n\r\t");

    var machine = Machine{ .pc = 0, .memory = std.ArrayList(i64).init(allocator) };

    while (tokens.next()) |t| {
        const v = try std.fmt.parseInt(i64, t, 10);
        try machine.memory.append(v);
    }
    for (0..4096) |_| {
        try machine.memory.append(0);
    }

    return machine;
}

pub fn main() !void {
    var gen = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gen.deinit();
    const allocator = gen.allocator();

    var machine = try loadSQ(allocator);
    defer machine.deinit();

    interpret(&machine);
}
