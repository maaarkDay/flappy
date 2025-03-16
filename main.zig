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
    // File, Edit, View, Window, Help
    const menu = try objc.create_obj("NSMenu");
    const sub_menu = try objc.create_obj("NSMenu");
    const sub_menu_item = try objc.create_obj("NSMenuItem");

    _ = sub_menu_item.msgSend(void, objc.sel("setSubmenu:"), .{sub_menu.value});
    _ = menu.msgSend(void, objc.sel("addItem:"), .{sub_menu_item.value});

    const about_item = try create_menu_item("About Flappy Birds", "orderFrontStandardAboutPanel:", null);
    const updates_item = try create_menu_item("Check for updates...", "orderFrontStandardAboutPanel:", null);
    const separator_1_item = try create_menu_separator();
    const separator_2_item = try create_menu_separator();
    const settings_item = try create_menu_item("Settings", "orderFrontStandardAboutPanel:", ",");
    const quit_item = try create_menu_item("Quit Flappy Birds", "terminate:", "q");

    _ = sub_menu.msgSend(void, objc.sel("addItem:"), .{about_item.value});
    _ = sub_menu.msgSend(void, objc.sel("addItem:"), .{updates_item.value});
    _ = sub_menu.msgSend(void, objc.sel("addItem:"), .{separator_1_item.value});
    _ = sub_menu.msgSend(void, objc.sel("addItem:"), .{settings_item.value});
    _ = sub_menu.msgSend(void, objc.sel("addItem:"), .{separator_2_item.value});
    _ = sub_menu.msgSend(void, objc.sel("addItem:"), .{quit_item.value});

    const main_menu_items = [_][*:0]const u8{ "File", "Edit", "View", "Window", "Help" };

    for (main_menu_items) |title| {
        const new_menu = try objc.create_obj("NSMenu");
        const new_menu_item = try objc.create_obj("NSMenuItem");
        const new_menu_title = try objc.create_string(title);

        _ = new_menu_item.msgSend(void, objc.sel("setTitle:"), .{new_menu_title.value});
        _ = new_menu_item.msgSend(void, objc.sel("setSubmenu:"), .{new_menu.value});
        _ = menu.msgSend(void, objc.sel("addItem:"), .{new_menu_item.value});
    }

    return menu;
}

fn create_menu_item(title: [*:0]const u8, action: [*:0]const u8, key: ?[*:0]const u8) !objc.Object {
    const title_obj = try objc.create_string(title);
    const item = try objc.create_obj("NSMenuItem");

    if (key) |k| {
        const key_obj = try objc.create_string(k);

        _ = item.msgSend(void, objc.sel("setKeyEquivalent:"), .{key_obj.value});
    }

    _ = item.msgSend(void, objc.sel("setTitle:"), .{title_obj.value});
    _ = item.msgSend(void, objc.sel("setAction:"), .{objc.sel(action)});

    return item;
}

fn create_menu_separator() !objc.Object {
    const NSMenuItem = try objc.wrap_class("NSMenuItem");
    const separator = NSMenuItem.msgSend(objc.id, objc.sel("separatorItem"), .{});

    return objc.Object.init(separator);
}
