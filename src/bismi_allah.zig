//بسم الله الرحمن الرحيم
//la ilaha illa Allah Mohammed Rassoul Allah
const std = @import("std");
const sf = struct {
    const sfml = @import("sfml");
    usingnamespace sfml;
    usingnamespace sfml.audio;
    usingnamespace sfml.graphics;
    usingnamespace sfml.window;
    usingnamespace sfml.system;
};

const Settings = struct {
    bookmarks: [10]usize,
    current_page: usize,
};

const NUMBER_OF_PAGES = 604;
const IMAGE_WIDTH = 1792;
const IMAGE_HEIGHT = 2560;

// var flag_zoomed_in: bool = false;

fn embed_quran_pictures() [NUMBER_OF_PAGES][]const u8 {
    var quran_pictures: [NUMBER_OF_PAGES][]const u8 = undefined;

    var i: usize = 0;
    while (i < NUMBER_OF_PAGES) : (i += 1) {
        var file_name_buffer: [64]u8 = undefined;
        const file_name_slice = std.fmt.bufPrint(&file_name_buffer, "res/{d}-scaled.jpg", .{i + 1}) catch |e| {
            // std.log.err("alhamdo li Allah error while writing to 'file_name_buffer': {any}\n", .{e});
            @compileLog("alhamdo li Allah error ", e, " while writing to 'file_name_buffer' ", i);
            @compileError("error while writing file name to buffer\n");
        };

        const file = @embedFile(file_name_slice);
        quran_pictures[i] = file;
    }

    return quran_pictures;
}

const quran_pictures_arr = embed_quran_pictures();
var current_page: usize = 1;

var bookmarks: [10]usize = [1]usize{0} ** 10;

/// list of the number of pages every surah starts with
const surah_start_pages_list: [114]usize = [_]usize{ 1, 2, 50, 77, 106, 128, 151, 177, 187, 208, 221, 235, 249, 255, 262, 267, 282, 293, 305, 312, 322, 332, 342, 350, 359, 367, 377, 385, 396, 404, 411, 415, 418, 428, 434, 440, 446, 453, 458, 467, 477, 483, 489, 496, 499, 502, 507, 511, 515, 518, 520, 523, 526, 528, 531, 534, 537, 542, 545, 549, 551, 553, 554, 556, 558, 560, 562, 564, 566, 568, 570, 572, 574, 575, 577, 578, 580, 582, 583, 585, 586, 587, 587, 589, 590, 591, 591, 592, 593, 594, 595, 595, 596, 596, 597, 597, 598, 598, 599, 599, 600, 600, 601, 601, 601, 602, 602, 602, 603, 603, 603, 604, 604, 604 };
const hizb_start_pages_list: [60]usize = [60]usize{ 1, 11, 22, 32, 43, 51, 62, 72, 82, 92, 102, 111, 121, 132, 142, 151, 162, 173, 182, 192, 201, 212, 222, 231, 242, 252, 262, 272, 282, 292, 302, 312, 322, 332, 342, 352, 362, 371, 382, 392, 402, 413, 422, 431, 442, 451, 462, 472, 482, 491, 502, 513, 522, 531, 542, 553, 562, 572, 582, 591 };

var fixed_buffer: [1024]u8 = undefined;
var app_data_dir_path: []u8 = undefined;

var fba: std.heap.FixedBufferAllocator = undefined;
var allocator: std.mem.Allocator = undefined;

pub fn main() !void {
    // notes:
    // image size: 1792x2560
    fba = std.heap.FixedBufferAllocator.init(&fixed_buffer);
    allocator = fba.allocator();

    loadData() catch |e| {
        std.debug.print("alhamdo li Allah err: {any}\n", .{e});
    };

    var window = try sf.RenderWindow.create(.{ .x = IMAGE_WIDTH, .y = IMAGE_HEIGHT }, 64, "quran warsh - tajweed quran", sf.Style.defaultStyle, null);
    defer window.destroy();

    window.setFramerateLimit(30);

    window.setSize(.{ .x = IMAGE_WIDTH / 2, .y = IMAGE_HEIGHT / 2 });

    var quran_sprite = try sf.Sprite.create();
    defer quran_sprite.destroy();
    // quran_sprite.setScale(.{ .x = 0.5, .y = 0.5 });

    setPage(&quran_sprite, current_page);

    while (window.waitEvent()) |event| {
        switch (event) {
            .closed => {
                window.close();
            },
            .key_pressed => {
                if (event.key_pressed.shift) {
                    switch (event.key_pressed.code) {
                        .left => setPageToNextSurah(&quran_sprite),
                        .right => setPageToPreviousSurah(&quran_sprite),
                        .num0 => bookmarks[0] = current_page,
                        .num1 => bookmarks[1] = current_page,
                        .num2 => bookmarks[2] = current_page,
                        .num3 => bookmarks[3] = current_page,
                        .num4 => bookmarks[4] = current_page,
                        .num5 => bookmarks[5] = current_page,
                        .num6 => bookmarks[6] = current_page,
                        .num7 => bookmarks[7] = current_page,
                        .num8 => bookmarks[8] = current_page,
                        .num9 => bookmarks[9] = current_page,
                        else => {},
                    }
                } else if (event.key_pressed.control) {
                    switch (event.key_pressed.code) {
                        .left => setPageToNextHizb(&quran_sprite),
                        .right => setPageToPreviousHizb(&quran_sprite),
                        else => {},
                    }
                } else {
                    switch (event.key_pressed.code) {
                        .left => if (current_page < NUMBER_OF_PAGES) setPage(&quran_sprite, current_page + 1),
                        .right => if (current_page > 1) setPage(&quran_sprite, current_page - 1),
                        .num0 => setPage(&quran_sprite, bookmarks[0]),
                        .num1 => setPage(&quran_sprite, bookmarks[1]),
                        .num2 => setPage(&quran_sprite, bookmarks[2]),
                        .num3 => setPage(&quran_sprite, bookmarks[3]),
                        .num4 => setPage(&quran_sprite, bookmarks[4]),
                        .num5 => setPage(&quran_sprite, bookmarks[5]),
                        .num6 => setPage(&quran_sprite, bookmarks[6]),
                        .num7 => setPage(&quran_sprite, bookmarks[7]),
                        .num8 => setPage(&quran_sprite, bookmarks[8]),
                        .num9 => setPage(&quran_sprite, bookmarks[9]),
                        else => {},
                    }
                }

                // if (event.key_pressed.code == .I) {
                //        toggleZoom();
                // }
            },
            else => {},
        }

        window.clear(sf.Color.Black);
        defer window.display();

        //drawnig by the will of Allah
        window.draw(quran_sprite, null);
    }

    try saveData();
}

/// sets the page diplayed starting from 1
fn setPage(sprite: *sf.Sprite, target_page: usize) void {
    if (target_page > NUMBER_OF_PAGES or 0 == target_page) return;

    sprite.setTexture(sf.Texture.createFromMemory(quran_pictures_arr[target_page - 1], .{ .top = 0, .left = 0, .width = 0, .height = 0 }) catch unreachable);

    // sprite.setTextureRect(sf.IntRect.init(393, 170, 1360, 2184));
    // sprite.setTextureRect(sf.IntRect.init(196, 85, 680, 1542));

    current_page = target_page;
}

fn getCurrentSurahIndex() usize {
    var i: usize = 0;
    while (i < surah_start_pages_list.len) : (i += 1) {
        if (current_page <= surah_start_pages_list[i]) return i;
    }
    return 0;
}

fn setPageToNextSurah(sprite: *sf.Sprite) void {
    const current_surah_index = getCurrentSurahIndex();
    const starting_page = current_page;
    if (current_page == NUMBER_OF_PAGES) {
        setPage(sprite, 1);
    } else {
        setPage(sprite, surah_start_pages_list[current_surah_index + 1]);
        if (starting_page == current_page) {
            setPage(sprite, current_page + 1);
        }
    }
}

fn setPageToPreviousSurah(sprite: *sf.Sprite) void {
    const current_surah_index = getCurrentSurahIndex();
    if (current_surah_index == 0) {
        setPage(sprite, surah_start_pages_list[surah_start_pages_list.len - 1]);
    } else {
        setPage(sprite, surah_start_pages_list[current_surah_index - 1]);
    }
}

fn getCurrentHizbIndex() usize {
    var i: usize = 0;
    while (i < hizb_start_pages_list.len) : (i += 1) {
        if (current_page <= hizb_start_pages_list[i]) return i;
    }
    return 0;
}

fn setPageToNextHizb(sprite: *sf.Sprite) void {
    const current_hizb_index = getCurrentHizbIndex();
    if (current_hizb_index == 59) {
        setPage(sprite, 1);
    } else {
        setPage(sprite, hizb_start_pages_list[current_hizb_index + 1]);
    }
}

fn setPageToPreviousHizb(sprite: *sf.Sprite) void {
    const current_hizb_index = getCurrentHizbIndex();
    if (current_hizb_index == 0) {
        setPage(sprite, hizb_start_pages_list[hizb_start_pages_list.len - 1]);
    } else {
        setPage(sprite, hizb_start_pages_list[current_hizb_index - 1]);
    }
}

fn saveData() !void {
    std.fs.makeDirAbsolute(app_data_dir_path) catch |e| switch (e) {
        std.fs.Dir.MakeError.PathAlreadyExists => {},
        else => return e,
    };

    var app_data_dir = try std.fs.openDirAbsolute(app_data_dir_path, .{});
    defer app_data_dir.close();

    var file = try app_data_dir.createFile("cache", .{ .read = true });
    defer file.close();

    var settings = Settings{ .bookmarks = undefined, .current_page = current_page };
    std.mem.copyForwards(usize, &settings.bookmarks, &bookmarks);
    try std.json.stringify(settings, .{}, file.writer());
}

fn loadData() !void {
    app_data_dir_path = try std.fs.getAppDataDir(allocator, "quran-warsh");

    var data_dir = try std.fs.openDirAbsolute(app_data_dir_path, .{});
    defer data_dir.close();

    var file = try data_dir.openFile("cache", .{ .mode = .read_write });
    defer file.close();

    const buffer = try allocator.alloc(u8, 512);
    defer allocator.free(buffer);

    const read_bytes = try file.readAll(buffer);

    const parsed = try std.json.parseFromSlice(Settings, allocator, buffer[0..read_bytes], .{ .ignore_unknown_fields = true, .duplicate_field_behavior = .use_last });
    defer parsed.deinit();

    current_page = parsed.value.current_page;
    std.mem.copyForwards(usize, &bookmarks, &parsed.value.bookmarks);
}

test "surah start pages list is ordered" {
    var i: usize = 0;
    while (i < surah_start_pages_list.len - 1) : (i += 1) {
        std.debug.assert(surah_start_pages_list[i] <= surah_start_pages_list[i + 1]);
    }
}

test "hizb start pages list is ordered" {
    var i: usize = 0;
    while (i < hizb_start_pages_list.len - 1) : (i += 1) {
        std.debug.assert(hizb_start_pages_list[i] <= hizb_start_pages_list[i + 1]);
    }
}
