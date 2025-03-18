const std = @import("std");
const objc = @import("objc.zig");

// Basic macOS types
const CGFloat = f64; // 64-bit floating number
const NSInteger = c_long; // 64-bit signed integer
const NSUInteger = c_ulong; // 64-bit unsigned integer

// NSRect structure for window fram
const NSRect = extern struct { x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat };

// Window style constraints
const NSWindowStyleMaskTitled = 1 << 0;
const NSWindowStyleMaskClosable = 1 << 1;
const NSWindowStyleMaskMiniaturizable = 1 << 2;
const NSWindowStyleMaskResizable = 1 << 3;
const NSBackingStoreBuffered = 2;
const NSApplicationActivationPolicyRegular = 0;

pub fn main() !void {
    std.debug.print("Starting Floppy Birds\n", .{});

    // Get the NSApplication class and create a shared instance
    const NSApp_class = objc.get_class("NSApplication").?;
    const NSApp_obj = objc.ClassType.init(NSApp_class);
    const app = NSApp_obj.msgSend(objc.id, objc.sel("sharedApplication"), .{});
    const app_obj = objc.Object.init(app);

    // Create app header menu
    const menu = try create_menu();
    _ = app_obj.msgSend(void, objc.sel("setMainMenu:"), .{menu.value});

    // Set the application to be a regular app (with Dock icon)
    _ = app_obj.msgSend(void, objc.sel("setActivationPolicy:"), .{NSApplicationActivationPolicyRegular});

    // Create a new window
    const NSWindow_class = objc.get_class("NSWindow") orelse {
        std.debug.print("Failed to get NSWindow class\n", .{});
        return error.ClassNotFound;
    };

    const NSWindow_obj = objc.ClassType.init(NSWindow_class);
    const window_alloc = NSWindow_obj.msgSend(objc.id, objc.sel("alloc"), .{});
    const window_obj = objc.Object.init(window_alloc);

    // Init window with frame and style
    const frame = NSRect{
        .x = 0,
        .y = 0,
        .width = 800,
        .height = 600,
    };

    const window = window_obj.msgSend(objc.id, objc.sel("initWithContentRect:styleMask:backing:defer:"), .{
        frame,
        NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable,
        NSBackingStoreBuffered,
        false,
    });
    const styled_window = objc.Object.init(window);

    // Create a title string
    const NSString_class = objc.get_class("NSString") orelse {
        std.debug.print("Failed to get NSString class\n", .{});
        return error.ClassNotFound;
    };

    const NSString_obj = objc.ClassType.init(NSString_class);
    const title_alloc = NSString_obj.msgSend(objc.id, objc.sel("alloc"), .{});
    const title_obj = objc.Object.init(title_alloc);
    const title = title_obj.msgSend(objc.id, objc.sel("initWithUTF8String:"), .{"Flappy Birds"});
    const title_str = objc.Object.init(title);

    // Set window title
    _ = styled_window.msgSend(void, objc.sel("setTitle:"), .{title_str.value});

    // Center window on screen
    _ = styled_window.msgSend(void, objc.sel("center"), .{});

    // Show window
    _ = styled_window.msgSend(void, objc.sel("makeKeyAndOrderFront:"), .{@as(?objc.id, null)});

    // Activate the app
    _ = app_obj.msgSend(void, objc.sel("activateIgnoringOtherApps:"), .{true});

    // Run the app main loop
    std.debug.print("Starting main event loop\n", .{});
    _ = app_obj.msgSend(void, objc.sel("run"), .{});
}

fn create_menu() !objc.Object {
    const SubMenuItem = struct {
        title: ?[]const u8,
        action: ?[]const u8,
        shortcut: ?[]const u8,
        is_separator: bool = false,
    };
    const MenuItem = struct { title: []const u8, submenu: []const SubMenuItem };

    const app_menu = [_]MenuItem{
        .{ .title = "Flappy Birds", .submenu = &[_]SubMenuItem{
            .{ .title = "About Flappy Birds", .action = "orderFrontStandardAboutPanel:", .shortcut = null },
            .{ .title = "Check for updates...", .action = "orderFrontStandardAboutPanel:", .shortcut = null },
            .{ .is_separator = true, .title = null, .action = null, .shortcut = null },
            .{ .title = "Settings", .action = "orderFrontStandardAboutPanel:", .shortcut = "," },
            .{ .is_separator = true, .title = null, .action = null, .shortcut = null },
            .{ .title = "Quit Flappy Birds", .action = "terminate:", .shortcut = "q" },
        } },
        .{ .title = "File", .submenu = &[_]SubMenuItem{} },
        .{ .title = "Edit", .submenu = &[_]SubMenuItem{} },
        .{ .title = "View", .submenu = &[_]SubMenuItem{} },
        .{ .title = "Window", .submenu = &[_]SubMenuItem{} },
        .{ .title = "Help", .submenu = &[_]SubMenuItem{} },
    };

    const menu = try objc.create_obj("NSMenu");

    for (app_menu) |item| {
        const menu_item = try objc.create_obj("NSMenuItem");
        const menu_title = try objc.create_string(item.title);
        _ = menu_item.msgSend(void, objc.sel("setTitle:"), .{menu_title.value});

        const submenu = try objc.create_obj("NSMenu");
        const submenu_title = try objc.create_string(item.title);
        _ = submenu.msgSend(void, objc.sel("setTitle:"), .{submenu_title.value});

        for (item.submenu) |sub_item| {
            if (sub_item.is_separator) {
                const separator = try create_menu_separator();
                _ = submenu.msgSend(void, objc.sel("addItem:"), .{separator.value});
                continue;
            }

            const submenu_item = try objc.create_obj("NSMenuItem");
            const submenu_item_title = try objc.create_string(sub_item.title.?);
            _ = submenu_item.msgSend(void, objc.sel("setTitle:"), .{submenu_item_title.value});

            if (sub_item.action) |action| {
                _ = submenu_item.msgSend(void, objc.sel("setAction:"), .{objc.sel(action)});
            }

            if (sub_item.shortcut) |key| {
                const shortcut_str = try objc.create_string(key);
                _ = submenu_item.msgSend(void, objc.sel("setKeyEquivalent:"), .{shortcut_str.value});
            }

            _ = submenu.msgSend(void, objc.sel("addItem:"), .{submenu_item.value});
        }
        _ = menu_item.msgSend(void, objc.sel("setSubmenu:"), .{submenu.value});
        _ = menu.msgSend(void, objc.sel("addItem:"), .{menu_item.value});
    }
    return menu;
}

fn create_menu_separator() !objc.Object {
    const NSMenuItem = try objc.wrap_class("NSMenuItem");
    const separator = NSMenuItem.msgSend(objc.id, objc.sel("separatorItem"), .{});

    return objc.Object.init(separator);
}
