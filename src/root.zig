const std = @import("std");
const testing = std.testing;

const MathError = error{
    invalidSize,
};

const Matrix = extern struct {
    data: [*c]f32,
    rows: u32,
    cols: u32,
};

pub export fn scalar_mult(m: Matrix, alpha: f32) callconv(.C) void {
    const n = m.rows * m.cols;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        m.data[i] *= alpha;
    }
}

pub export fn copy_matrix(dst: Matrix, src: Matrix) callconv(.C) void {
    const n = src.rows * src.cols;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        dst.data[i] = src.data[i];
    }
}

pub export fn matrix_add(A: Matrix, B: Matrix, dst: Matrix) callconv(.C) void {
    std.debug.assert(A.rows == B.rows and A.cols == B.cols and A.rows == dst.rows and A.cols == dst.cols);
    const n = A.rows * A.cols;
    std.debug.assert(n <= 4096);
    var tmp: [4096]f32 = undefined;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        tmp[i] = A.data[i] + B.data[i];
    }
    i = 0;
    while (i < n) : (i += 1) {
        dst.data[i] = tmp[i];
    }
}

test "matrix_add_test" {
    var A_data = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0 };
    var B_data = [_]f32{ 2.0, 4.0, 6.0, 8.0, 10.0, 12.0 };
    const check_data = [_]f32{3.0, 6.0, 9.0, 12.0, 15.0, 18.0};

    const A = Matrix{ .data = &A_data, .rows = 2, .cols = 3 };
    const B = Matrix{ .data = &B_data, .rows = 2, .cols = 3 };
    
    matrix_add(A, B, A);

    for (A_data, check_data) |d, c| {
        try testing.expectEqual(d, c);
    }
}

test "matrix_scalar_mult_test" {
    var data = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0 };
    const check_data = [_]f32{ 2.0, 4.0, 6.0, 8.0, 10.0, 12.0 };

    const m = Matrix{ .data = &data, .rows = 2, .cols = 3 };

    scalar_mult(m, 2.0);

    for (data, check_data) |d, c| {
        try testing.expectEqual(d, c);
    }
}

test "matrix_copy_test" {
    var src_data = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0 };
    var dst_data = [_]f32{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };

    const src = Matrix{ .data = &src_data, .rows = 2, .cols = 3 };
    const dst = Matrix{ .data = &dst_data, .rows = 2, .cols = 3 };

    copy_matrix(dst, src);

    for (src_data, dst_data) |s, d| {
        try testing.expectEqual(s, d);
    }

    scalar_mult(dst, 2.0);
    try testing.expectEqual(src_data[0], 1.0);
    try testing.expectEqual(dst_data[0], 2.0);
}

