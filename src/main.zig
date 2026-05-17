const types = @import("types.zig");
const SoftwareRenderer = @import("SoftwareRenderer.zig").SoftwareRenderer;

pub const Colour = types.Colour;

pub const screen_width = 800;
pub const screen_height = 600;

pub var buffer: [screen_width * screen_height * 4]u8 = undefined;

const Engine = SoftwareRenderer(screen_width, screen_height, &buffer);

const TILE_SIZE = 20;
const GRID_COLS = screen_width / TILE_SIZE; // 40
const GRID_ROWS = screen_height / TILE_SIZE; // 30
const GRID_HALF_COLS = GRID_COLS / 2; // 20
const BALL_RADIUS = 5;

const Ball = struct {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
    team: u8,
    colour: Colour,
};

var grid: [GRID_ROWS * GRID_COLS]u8 = undefined;

fn gridIdx(row: usize, col: usize) usize {
    return row * GRID_COLS + col;
}

var ball_day: Ball = undefined;
var ball_night: Ball = undefined;

pub fn init() void {
    // Pre-fill grid: left half = Day (1), right half = Night (2)
    for (0..GRID_ROWS) |row| {
        for (0..GRID_HALF_COLS) |col| {
            grid[gridIdx(row, col)] = 1;
        }
        for (GRID_HALF_COLS..GRID_COLS) |col| {
            grid[gridIdx(row, col)] = 2;
        }
    }

    ball_day = Ball{
        .x = 200.0,
        .y = 200.0,
        .vx = 3.0,
        .vy = 2.0,
        .team = 1,
        .colour = Colour.day,
    };

    ball_night = Ball{
        .x = 600.0,
        .y = 400.0,
        .vx = -2.5,
        .vy = -2.8,
        .team = 2,
        .colour = Colour.night,
    };

    Engine.clear(Colour.bg);
}

fn bounceOffWalls(ball: *Ball) void {
    if (ball.x - BALL_RADIUS <= 0) {
        ball.x = BALL_RADIUS;
        ball.vx = -ball.vx;
    } else if (ball.x + BALL_RADIUS >= screen_width) {
        ball.x = screen_width - BALL_RADIUS;
        ball.vx = -ball.vx;
    }

    if (ball.y - BALL_RADIUS <= 0) {
        ball.y = BALL_RADIUS;
        ball.vy = -ball.vy;
    } else if (ball.y + BALL_RADIUS >= screen_height) {
        ball.y = screen_height - BALL_RADIUS;
        ball.vy = -ball.vy;
    }
}

fn tileAt(x: f32, y: f32) struct { col: usize, row: usize } {
    const col: usize = @intCast(@min(@divTrunc(@as(i32, @intFromFloat(x)), TILE_SIZE), GRID_COLS - 1));
    const row: usize = @intCast(@min(@divTrunc(@as(i32, @intFromFloat(y)), TILE_SIZE), GRID_ROWS - 1));
    return .{ .col = col, .row = row };
}

fn checkTileCollision(ball: *Ball) void {
    // Check all 4 corners of the ball's bounding box, not just center
    const r = BALL_RADIUS;
    const corners = [_][2]f32{
        .{ ball.x - r, ball.y - r },
        .{ ball.x + r, ball.y - r },
        .{ ball.x - r, ball.y + r },
        .{ ball.x + r, ball.y + r },
    };

    var bounced = false;
    for (corners) |corner| {
        const pos = tileAt(corner[0], corner[1]);
        const tile = grid[gridIdx(pos.row, pos.col)];
        if (tile != 0 and tile != ball.team) {
            grid[gridIdx(pos.row, pos.col)] = ball.team;
            bounced = true;
        }
    }

    if (bounced) {
        ball.vx = -ball.vx;
        ball.vy = -ball.vy;
    }
}

fn renderGrid() void {
    for (0..GRID_ROWS) |row| {
        for (0..GRID_COLS) |col| {
            const team = grid[gridIdx(row, col)];
            if (team == 0) continue;

            const colour: Colour = if (team == 1) Colour.day_dim else Colour.night_dim;
            const x: i32 = @intCast(col * TILE_SIZE);
            const y: i32 = @intCast(row * TILE_SIZE);
            Engine.fillRect(x, y, TILE_SIZE, TILE_SIZE, colour);
        }
    }
}

pub fn flipTileAt(x: f32, y: f32) void {
    const pos = tileAt(x, y);
    const center_col: i32 = @intCast(pos.col);
    const center_row: i32 = @intCast(pos.row);

    // Flip a 3x3 area minus the 4 corner tiles, producing a circular pattern
    for (0..3) |dr| {
        for (0..3) |dc| {
            const col: i32 = center_col + @as(i32, @intCast(dc)) - 1;
            const row: i32 = center_row + @as(i32, @intCast(dr)) - 1;
            if (col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS) continue;

            // Skip the 4 corner tiles
            const dcol = @abs(col - center_col);
            const drow = @abs(row - center_row);
            if (dcol == 1 and drow == 1) continue;

            const tile = grid[gridIdx(@intCast(row), @intCast(col))];
            if (tile == 1) {
                grid[gridIdx(@intCast(row), @intCast(col))] = 2;
            } else if (tile == 2) {
                grid[gridIdx(@intCast(row), @intCast(col))] = 1;
            }
        }
    }
}

pub fn update(real_t: f32) void {
    _ = real_t;

    // Move balls
    ball_day.x += ball_day.vx;
    ball_day.y += ball_day.vy;
    ball_night.x += ball_night.vx;
    ball_night.y += ball_night.vy;

    // Bounce off walls
    bounceOffWalls(&ball_day);
    bounceOffWalls(&ball_night);

    // Check tile collisions (convert + bounce off enemy tiles)
    checkTileCollision(&ball_day);
    checkTileCollision(&ball_night);

    // Render
    renderGrid();
    Engine.fillCircle(@intFromFloat(ball_day.x), @intFromFloat(ball_day.y), BALL_RADIUS, ball_day.colour);
    Engine.fillCircle(@intFromFloat(ball_night.x), @intFromFloat(ball_night.y), BALL_RADIUS, ball_night.colour);
}
