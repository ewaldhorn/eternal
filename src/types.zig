pub const Colour = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub const white = Colour{ .r = 255, .g = 255, .b = 255, .a = 255 };
    pub const black = Colour{ .r = 0, .g = 0, .b = 0, .a = 255 };
    pub const bg = Colour{ .r = 20, .g = 20, .b = 40, .a = 255 };
    pub const day = Colour{ .r = 255, .g = 180, .b = 50, .a = 255 };
    pub const night = Colour{ .r = 80, .g = 120, .b = 255, .a = 255 };
    pub const day_dim = Colour{ .r = 127, .g = 90, .b = 25, .a = 255 };
    pub const night_dim = Colour{ .r = 40, .g = 60, .b = 127, .a = 255 };

    pub fn rgba(r: u8, g: u8, b: u8, a: u8) Colour {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }
};
