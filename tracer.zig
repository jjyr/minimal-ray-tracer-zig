const std = @import("std");

const Vec = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,

    fn add(a: Vec, b: Vec) Vec {
        return Vec{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    fn sub(a: Vec, b: Vec) Vec {
        return Vec{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    fn mul(a: Vec, b: Vec) Vec {
        return Vec{ .x = a.x * b.x, .y = a.y * b.y, .z = a.z * b.z };
    }

    fn dot(a: Vec, b: Vec) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    fn length(v: Vec) f32 {
        return @sqrt(v.dot(v));
    }

    fn normalize(v: Vec) Vec {
        const f = (1.0 / v.length());
        return Vec{
            .x = v.x * f,
            .y = v.y * f,
            .z = v.z * f,
        };
    }
};

const Sphere = struct {
    center: Vec,
    radius: f32,
    color: f32, // 0 = black, 1 = white

    // return distance from ray to intersection, return NaN if there is none
    //
    // See this article for math explanation
    // https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
    fn intersect(s: Sphere, origin: Vec, direction: Vec) f32 {
        const l = s.center.sub(origin);
        const t_ca = l.dot(direction);
        // d^2 + t_ca^2 = l^2
        const d2 = l.dot(l) - (t_ca * t_ca);
        if (d2 > (s.radius * s.radius)) {
            return std.math.nan(f32);
        }
        // d^2 + t_hc^2 = radius^2
        const t_hc = @sqrt((s.radius * s.radius) - d2);
        var t0 = t_ca - t_hc;
        var t1 = t_ca + t_hc;
        if (t0 > t1) {
            // swap t0, t1
            const t = t0;
            t0 = t1;
            t1 = t;
        }

        if (t0 < 0.0) {
            // use t1 instead
            t0 = t1;
            if (t0 < 0.0) {
                return std.math.nan(f32);
            }
        }

        return t0;
    }
};

const World = struct {
    spheres: []const Sphere,
    lights: []const Sphere,
};

fn trace(world: World, origin: Vec, direction: Vec) !f32 {
    var index: isize = -1;
    var distance: f32 = std.math.nan(f32);

    for (0..world.spheres.len) |i| {
        const d = world.spheres[i].intersect(origin, direction);
        if (!std.math.isNan(d)) {
            if ((index < 0) or (d < distance)) {
                distance = d;
                index = @intCast(i);
            }
        }
    }

    if (index < 0) {
        return 0; // black
    }

    // white
    return world.spheres[@intCast(index)].color;
}

fn render(world: World, width: isize, height: isize) !void {
    const stdout = std.io.getStdOut().writer();
    for (0..@intCast(height)) |y| {
        for (0..@intCast(width)) |x| {
            const direction = (Vec{
                .x = @as(f32, @floatFromInt(x)) - @as(f32, @floatFromInt(width)) / 2.0,
                .y = @as(f32, @floatFromInt(height)) / 2.0 - @as(f32, @floatFromInt(y)),
                .z = @as(f32, @floatFromInt(-height)),
            }).normalize();
            // get color of the pixel
            const c = try trace(world, (Vec{ .x = 0.0, .y = 1.0, .z = 5.0 }), direction);
            // find the suitable ASCII symbol
            const pixel = " .:-=+*#%@$"[@as(usize, @intFromFloat(c * 10))];
            try stdout.print("{c}{c}", .{ pixel, pixel });
        }
        try stdout.print("\n", .{});
    }
}

pub fn main() !void {
    const spheres = [_]Sphere{
        Sphere{
            .center = Vec{
                .x = 0.0,
                .y = -1000.0,
                .z = 0.0,
            },
            .color = 0.001,
            .radius = 1000.0,
        },
        Sphere{
            .center = Vec{
                .x = -2.0,
                .y = 1.0,
                .z = -2.0,
            },
            .color = 1.0,
            .radius = 1.0,
        },
        Sphere{
            .center = Vec{
                .x = 0.0,
                .y = 1.0,
                .z = 0.0,
            },
            .color = 0.5,
            .radius = 1.0,
        },
        Sphere{
            .center = Vec{
                .x = 2.0,
                .y = 1.0,
                .z = -1.0,
            },
            .color = 0.1,
            .radius = 1.0,
        },
    };
    const lights = [_]Sphere{
        Sphere{
            .center = Vec{
                .x = 0.0,
                .y = 100.0,
                .z = 0.0,
            },
            .color = 0.4,
            .radius = 0.0,
        },
        Sphere{
            .center = Vec{
                .x = 100.0,
                .y = 100.0,
                .z = 200.0,
            },
            .color = 0.5,
            .radius = 0.0,
        },
        Sphere{
            .center = Vec{
                .x = -100.0,
                .y = 300.0,
                .z = 100.0,
            },
            .color = 0.1,
            .radius = 0.0,
        },
    };
    const world = World{
        .spheres = &spheres,
        .lights = &lights,
    };

    try render(world, 40, 25);
}
