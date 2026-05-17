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

fn checkTileCollision(ball: *Ball) void {
    const col: usize = @intCast(@min(@divTrunc(@as(i32, @intFromFloat(ball.x)), TILE_SIZE), GRID_COLS - 1));
    const row: usize = @intCast(@min(@divTrunc(@as(i32, @intFromFloat(ball.y)), TILE_SIZE), GRID_ROWS - 1));
    const tile = grid[gridIdx(row, col)];

    if (tile != 0 and tile != ball.team) {
        // Enemy tile — convert to ball's colour and bounce
        grid[gridIdx(row, col)] = ball.team;
        ball.vx = -ball.vx;
        ball.vy = -ball.vy;
    }
}

fn renderGrid() void {
    for (0..GRID_ROWS) |row| {
        for (0..GRID_COLS) |col| {
            const team = grid[gridIdx(row, col)];
            if (team == 0) continue;

            const colour: Colour = if (team == 1) Colour.day else Colour.night;
            const x: i32 = @intCast(col * TILE_SIZE);
            const y: i32 = @intCast(row * TILE_SIZE);
            Engine.fillRect(x, y, TILE_SIZE, TILE_SIZE, colour);
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
