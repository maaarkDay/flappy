const std = @import("std");

// Import C types
const c_bool = std.c.bool;
// Basic Objective-C types
pub const SEL = *opaque {};
pub const Class = *opaque {};
pub const IMP = *opaque {};
pub const id = *opaque {};
pub const BOOL = c_bool;

// External function declarations for Objective-C runtime
// pub - Makes this func publicly accessible
// extern "c" - Tells Zig this is an external C func, so use C calling conventions
// fn objc_getClass - The func name
// (name: [*:0]const u8) - The func takes a mull terminated string param
// ?Class - Returns either a Class object or null (? indicates it's optional)
pub extern "c" fn objc_getClass(name: [*:0]const u8) ?Class;
pub extern "c" fn sel_registerName(name: [*:0]const u8) SEL;
// In the Objectiv-C runtime msg_Send is used for methods that return small scalar
// values (integers, pointers, etc)
pub extern "c" fn objc_msgSend() void;
// Used for methods that return larger structures by value
pub extern "c" fn objc_msgSend_stret() void;
pub extern "c" fn class_getName(cls: Class) [*:0]const u8;

// Helper func to create selectors
pub fn sel(name: []const u8) SEL {
    var buffer = std.heap.c_allocator.alloc(u8, name.len + 1) catch @panic("Failed to allocate memory for selector");
    defer std.heap.c_allocator.free(buffer);

    std.mem.copyForwards(u8, buffer[0..name.len], name);
    buffer[name.len] = 0;
    const null_term_ptr: [*:0]const u8 = @ptrCast(buffer.ptr);

    return sel_registerName(null_term_ptr);
}

// Helper func to get a class by name
pub fn get_class(name: [*:0]const u8) ?Class {
    return objc_getClass(name);
}

// Object wrapper for Objective-C objects
pub const Object = struct {
    value: ?id,
    pub fn init(value: ?id) Object {
        return .{ .value = value };
    }

    // For sending messages to objects
    pub fn msgSend(self: Object, comptime ReturnType: type, sel_name: SEL, args: anytype) ReturnType {
        // This is a simplified implementation - we will need more type handling

        const ArgsType = @TypeOf(args);
        const args_info = @typeInfo(ArgsType);
        const args_len = args_info.@"struct".fields.len;

        if (args_len == 0) {
            const FnType = *const fn (id, SEL) callconv(.C) ReturnType;
            const method = @as(FnType, @ptrCast(&objc_msgSend));
            return method(self.value.?, sel_name);
        } else if (args_len == 1) {
            const arg0 = switch (@TypeOf(args[0])) {
                comptime_int => @as(c_long, args[0]),
                else => args[0],
            };
            const FnType = *const fn (id, SEL, @TypeOf(arg0)) callconv(.C) ReturnType;
            const method = @as(FnType, @ptrCast(&objc_msgSend));
            return method(self.value.?, sel_name, args[0]);
        } else if (args_len == 2) {
            const arg0 = switch (@TypeOf(args[0])) {
                comptime_int => @as(c_long, args[0]),
                else => args[0],
            };
            const arg1 = switch (@TypeOf(args[1])) {
                comptime_int => @as(c_long, args[1]),
                else => args[1],
            };
            const Arg0Type = @TypeOf(arg0);
            const Arg1Type = @TypeOf(arg1);
            const FnType = *const fn (id, SEL, Arg0Type, Arg1Type) callconv(.C) ReturnType;
            const method = @as(FnType, @ptrCast(&objc_msgSend));
            return method(self.value.?, sel_name, args[0], args[1]);
        } else if (args_len == 3) {
            const arg0 = switch (@TypeOf(args[0])) {
                comptime_int => @as(c_long, args[0]),
                else => args[0],
            };
            const arg1 = switch (@TypeOf(args[1])) {
                comptime_int => @as(c_long, args[1]),
                else => args[1],
            };
            const arg2 = switch (@TypeOf(args[2])) {
                comptime_int => @as(c_long, args[2]),
                else => args[2],
            };
            const Arg0Type = @TypeOf(arg0);
            const Arg1Type = @TypeOf(arg1);
            const Arg2Type = @TypeOf(arg2);
            const FnType = *const fn (id, SEL, Arg0Type, Arg1Type, Arg2Type) callconv(.C) ReturnType;
            const method = @as(FnType, @ptrCast(&objc_msgSend));
            return method(self.value.?, sel_name, args[0], args[1], args[2]);
        } else if (args_len == 4) {
            const arg0 = switch (@TypeOf(args[0])) {
                comptime_int => @as(c_long, args[0]),
                else => args[0],
            };
            const arg1 = switch (@TypeOf(args[1])) {
                comptime_int => @as(c_long, args[1]),
                else => args[1],
            };
            const arg2 = switch (@TypeOf(args[2])) {
                comptime_int => @as(c_long, args[2]),
                else => args[2],
            };
            const arg3 = switch (@TypeOf(args[3])) {
                comptime_int => @as(c_long, args[3]),
                else => args[3],
            };
            const Arg0Type = @TypeOf(arg0);
            const Arg1Type = @TypeOf(arg1);
            const Arg2Type = @TypeOf(arg2);
            const Arg3Type = @TypeOf(arg3);
            const FnType = *const fn (id, SEL, Arg0Type, Arg1Type, Arg2Type, Arg3Type) callconv(.C) ReturnType;
            const method = @as(FnType, @ptrCast(&objc_msgSend));
            return method(self.value.?, sel_name, args[0], args[1], args[2], args[3]);
        } else {
            // Add ability to handle more args in future
            @compileError("Unsupported number of args");
        }
    }
};

// Class wrapper for Objective-C classes
pub const ClassType = struct {
    cls: Class,

    pub fn init(cls: Class) ClassType {
        return .{ .cls = cls };
    }

    // For sending Class messages
    pub fn msgSend(self: ClassType, comptime ReturnType: type, sel_name: SEL, args: anytype) ReturnType {
        // Similar to Object.msgSend but with class as the receiver
        const ArgsType = @TypeOf(args);
        const args_info = @typeInfo(ArgsType);
        const args_len = args_info.@"struct".fields.len;

        if (args_len == 0) {
            const FnType = *const fn (Class, SEL) callconv(.C) ReturnType;
            const method = @as(FnType, @ptrCast(&objc_msgSend));
            return method(self.cls, sel_name);
        } else if (args_len == 1) {
            const Arg0Type = @TypeOf(args[0]);
            const FnType = *const fn (Class, SEL, Arg0Type) callconv(.C) ReturnType;
            const method = @as(FnType, @ptrCast(&objc_msgSend));
            return method(self.cls, sel_name, args[0]);
        } else if (args_len == 2) {
            const Arg0Type = @TypeOf(args[0]);
            const Arg1Type = @TypeOf(args[1]);
            const FnType = *const fn (Class, SEL, Arg0Type, Arg1Type) callconv(.C) ReturnType;
            const method = @as(FnType, @ptrCast(&objc_msgSend));
            return method(self.cls, sel_name, args[0], args[1]);
        } else {
            @compileError("Unsupported number of args");
        }
    }

    // Get name of the class
    pub fn getName(self: ClassType) [*:0]const u8 {
        return class_getName(self.cls);
    }
};

// Get and wrap class
pub fn wrap_class(name: [*:0]const u8) !ClassType {
    const cls = objc_getClass(name) orelse {
        return error.ClassNotFound;
    };
    return ClassType.init(cls);
}

// Create and init an instance of the class
// This function encapsulates the standard Obj-C object creation pattern ([[ClassName alloc] init]) in a single function, reducing the code needed to create objects throughout the  app.
pub fn create_obj(class_name: [*:0]const u8) !Object {
    const cls = try wrap_class(class_name);
    const alloc = cls.msgSend(id, sel("alloc"), .{});
    const obj = Object.init(alloc);
    const instance = obj.msgSend(id, sel("init"), .{});
    return Object.init(instance);
}

pub fn create_string(str: []const u8) !Object {
    var buffer = try std.heap.c_allocator.alloc(u8, str.len + 1);
    defer std.heap.c_allocator.free(buffer);

    std.mem.copyForwards(u8, buffer[0..str.len], str);
    buffer[str.len] = 0;

    const NSString = try wrap_class("NSString");
    const nsstring = NSString.msgSend(id, sel("stringWithUTF8String:"), .{buffer.ptr});

    return Object.init(nsstring);
}
