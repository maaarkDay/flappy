const std = @import("std");
const objc = @import("objc.zig");

const GRAVITY: f32 = 0.25;
const JUMP: f32 = -5;
const PIPE_SPEED: f32 = 2;
const PIPE_GAP: f32 = 150;

const Pipe = struct {
    x: f32 = 0,
    y: f32 = 0,
};

const State = struct {
    y: f32 = 300,
    velocity: f32 = 0,
    pipes: []*Pipe = &[_]*Pipe{},
    score: u32 = 0,
    game_over: bool = false
};

var GameState = State{};

fn drawRect_impl(self: objc.id, _: objc.SEL, rect_ptr: objc.id) callconv(.C) void {
    // wraps the raw self pointer into an Object for easier method calling
    const NSView_obj = objc.Object.init(self);
    // call bounds method on view to get dimensions
    // returns a generic pointer (anyopaque) that will be the NSRect struct
    const bounds = NSView_obj.msgSend(*anyopaque, objc.sel("bounds"), .{});
    const bounds_struct = @as(*const objc.NSRect, @ptrCast(&bounds)).*;
    
    draw_background(self, bounds_struct);
    //draw_bird(self);

    _ = rect_ptr;
}

pub fn create_game_view(frame: objc.NSRect) !objc.Object {
    var class = objc.get_class("GameView");

    if (class == null) {
        const NSView_class = objc.get_class("NSView") orelse return error.ClassNotFound;

        class = objc.objc_allocateClassPair(NSView_class, "GameView", 0) orelse return error.ClassCreationFailed;
        // v = void return type 
        // @ = first param is an object(self),
        // : = second param is a selector 
        // @ = third param is an object
        const added = objc.class_addMethod(class.?, objc.sel("drawRect:"), @ptrCast(&drawRect_impl), "v@:@");

        if (!added) return error.MethodAdditionFailed;
        
        objc.objc_registerClassPair(class.?);
    }

    const ClassObj = objc.ClassType.init(class.?);
    const alloc = ClassObj.msgSend(objc.id, objc.sel("alloc"), .{});
    const view_obj = objc.Object.init(alloc);

    const view = view_obj.msgSend(objc.id, objc.sel("initWithFrame:"), .{frame});

    return objc.Object.init(view);
}

fn draw_background(self: objc.id, bounds: objc.NSRect) void {
    const NSGraphicsContext_class = objc.get_class("NSGraphicsContext") orelse return;
    const NSGraphicsContext_obj = objc.ClassType.init(NSGraphicsContext_class);
    const context = NSGraphicsContext_obj.msgSend(objc.id, objc.sel("currentContext"), .{});

    if (@intFromPtr(context) == 0) return;

    const NSColor_class = objc.get_class("NSColor") orelse return;
    const NSColor_obj = objc.ClassType.init(NSColor_class);
    //const sky_color = NSColor_obj.msgSend(objc.id, objc.sel("colorWithRed:green:blue:alpha:"), .{
    //    @as(f64, 0.4), @as(f64, 0.7), @as(f64, 1), @as(f64, 1)
    //});
    const sky_color = NSColor_obj.msgSend(objc.id, objc.sel("blueColor"), .{});
    const sky_color_obj = objc.Object.init(sky_color);
   
    _ = sky_color_obj.msgSend(void, objc.sel("set"), .{});


    const NSBezierPath_class = objc.get_class("NSBezierPath") orelse return;
    const NSBezierPath_obj = objc.ClassType.init(NSBezierPath_class);
    const bg_rect = NSBezierPath_obj.msgSend(objc.id, objc.sel("bezierPathWithRect:"), .{bounds});
    const bg_path = objc.Object.init(bg_rect);

    _ = bg_path.msgSend(void, objc.sel("fill"), .{});
    _  = self;
}
