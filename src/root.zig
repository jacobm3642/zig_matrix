const std = @import("std");
const testing = std.testing;
const c_imp = @cImport(@cInclude("stdio.h"));

const Matrix = extern struct {
    data: [*c]f32,
    rows: u32,
    cols: u32,
};

pub export fn matrix_scalar_mult(m: Matrix, alpha: f32) callconv(.C) void {
    const n = m.rows * m.cols;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        m.data[i] *= alpha;
    }
}

test "matrix_scalar_mult_test" {
    var data = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0 };
    const check_data = [_]f32{ 2.0, 4.0, 6.0, 8.0, 10.0, 12.0 };

    const m = Matrix{ .data = &data, .rows = 2, .cols = 3 };

    matrix_scalar_mult(m, 2.0);

    for (data, check_data) |d, c| {
        try testing.expectEqual(d, c);
    }
}

pub export fn copy_matrix(dst: Matrix, src: Matrix) callconv(.C) void {
    std.debug.assert(src.rows == dst.rows and src.cols == dst.cols);
    const n = src.rows * src.cols;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        dst.data[i] = src.data[i];
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

    matrix_scalar_mult(dst, 2.0);
    try testing.expectEqual(src_data[0], 1.0);
    try testing.expectEqual(dst_data[0], 2.0);
}

pub export fn matrix_add(A: Matrix, B: Matrix, dst: Matrix, tmp: [*c]f32) callconv(.C) void {
    std.debug.assert(A.rows == B.rows and A.cols == B.cols and A.rows == dst.rows and A.cols == dst.cols);
    const n = A.rows * A.cols;
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
    const check_data = [_]f32{ 3.0, 6.0, 9.0, 12.0, 15.0, 18.0 };
    var tmp: [6]f32 = undefined;

    const A = Matrix{ .data = &A_data, .rows = 2, .cols = 3 };
    const B = Matrix{ .data = &B_data, .rows = 2, .cols = 3 };

    matrix_add(A, B, A, &tmp);

    for (A_data, check_data) |d, c| {
        try testing.expectEqual(d, c);
    }
}

pub export fn matrix_sub(A: Matrix, B: Matrix, dst: Matrix, tmp: [*c]f32) callconv(.C) void {
    std.debug.assert(A.rows == B.rows and A.cols == B.cols and A.rows == dst.rows and A.cols == dst.cols);
    const n = A.rows * A.cols;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        tmp[i] = A.data[i] - B.data[i];
    }
    i = 0;
    while (i < n) : (i += 1) {
        dst.data[i] = tmp[i];
    }
}

test "matrix_sub_test" {
    var A_data = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0 };
    var B_data = [_]f32{ 2.0, 4.0, 6.0, 8.0, 10.0, 12.0 };

    var OLS_test = [_]f32{ 9.0, 16.0, 21.0};
    
    const check_data = [_]f32{ -1.0, -2.0, -3.0, -4.0, -5.0, -6.0 };
    var tmp: [6]f32 = undefined;

    const A = Matrix{ .data = &A_data, .rows = 2, .cols = 3 };
    const B = Matrix{ .data = &B_data, .rows = 2, .cols = 3 };

    matrix_sub(A, B, A, &tmp);

    for (A_data, check_data) |d, c| {
        try testing.expectEqual(d, c);
    }

    const C = Matrix{ .data = &OLS_test, .rows = 3, .cols = 1 };
    const D = Matrix{ .data = &OLS_test, .rows = 3, .cols = 1 };

    matrix_sub(C, D, C, &tmp);

    for (OLS_test) |d| {
        try testing.expectEqual(d, 0);
    }

}

pub export fn matrix_mult(A: Matrix, B: Matrix, dst: Matrix, tmp: [*c]f32) callconv(.C) void {
    std.debug.assert(A.cols == B.rows);
    std.debug.assert(dst.rows == A.rows and dst.cols == B.cols);
    var i: usize = 0;
    while (i < A.rows) : (i += 1) {
        var j: usize = 0;
        while (j < B.cols) : (j += 1) {
            var sum: f32 = 0.0;
            var k: usize = 0;
            while (k < A.cols) : (k += 1) {
                sum += A.data[i * A.cols + k] * B.data[k * B.cols + j];
            }
            tmp[i * B.cols + j] = sum;
        }
    }
    const n = A.rows * B.cols;
    i = 0;
    while (i < n) : (i += 1) {
        dst.data[i] = tmp[i];
    }
}

test "matrix_mult_alias_test" {
    var A_data = [_]f32{ 1.0, 2.0, 3.0, 4.0 };
    var B_data = [_]f32{ 2.0, 0.0, 1.0, 2.0 };
    const check_data = [_]f32{ 4.0, 4.0, 10.0, 8.0 };
    var tmp: [4]f32 = undefined;

    const A = Matrix{ .data = &A_data, .rows = 2, .cols = 2 };
    const B = Matrix{ .data = &B_data, .rows = 2, .cols = 2 };

    matrix_mult(A, B, A, &tmp);

    for (A_data, check_data) |d, c| {
        try testing.expectEqual(d, c);
    }
}

pub export fn matrix_transpose(A: *Matrix, tmp: [*c]f32) callconv(.C) void {
    var i: usize = 0;
    while (i < A.rows) : (i += 1) {
        var j: usize = 0;
        while (j < A.cols) : (j += 1) {
            tmp[j * A.rows + i] = A.data[i * A.cols + j];
        }
    }
    const n = A.rows * A.cols;
    i = 0;
    while (i < n) : (i += 1) {
        A.data[i] = tmp[i];
    }
    const r = A.rows;
    A.rows = A.cols;
    A.cols = r;
}

test "matrix_transpose_test" {
    var A_data = [_]f32{ 1.0, 2.0, 3.0, 4.0 };
    const check_data = [_]f32{ 1.0, 3.0, 2.0, 4.0 };
    var tmp: [4]f32 = undefined;

    var A = Matrix{ .data = &A_data, .rows = 2, .cols = 2 };

    matrix_transpose(&A, &tmp);

    for (A_data, check_data) |d, c| {
        try testing.expectEqual(d, c);
    }
}

pub export fn matrix_map(A: Matrix, func_ptr: *const fn (f32) callconv(.C) f32) callconv(.C) void{
    var i: usize = 0;
    while (i < A.rows * A.cols) : (i += 1) {
        A.data[i] = func_ptr(A.data[i]);
    }
}

test "matrix_map_test" {
    const square = struct {
        fn call(a: f32) callconv(.C) f32 {
            return a * a;
        }
    }.call;

    var A_data = [_]f32{ 1.0, 2.0, 3.0, 4.0 };
    const check_data = [_]f32{ 1.0, 4.0, 9.0, 16.0 };
    
    const A = Matrix{ .data = &A_data, .rows = 2, .cols = 2 };
    
    matrix_map(A, &square);

    for (A_data, check_data) |d, c| {
        try testing.expectEqual(d, c);
    }
}

pub export fn matrix_det(in: Matrix, tmp: [*c]f32) callconv(.C) f32 {
    std.debug.assert(in.rows == in.cols);
    const dim: usize = in.rows;

    var M = Matrix{ .data = tmp, .rows = in.rows, .cols = in.cols };
    copy_matrix(M, in);

    var swaps: usize = 0;
    var col: usize = 0;

    while (col < dim - 1) : (col += 1) {
        var max_val = @abs(M.data[col * dim + col]);
        var max_row: usize = col;
        var row: usize = col + 1;
        while (row < dim) : (row += 1) {
            const val = @abs(M.data[row * dim + col]);
            if (val > max_val) {
                max_val = val;
                max_row = row;
            }
        }

        if (max_val < 1e-12) return 0.0;

        if (max_row != col) {
            var k: usize = 0;
            while (k < dim) : (k += 1) {
                const a = max_row * dim + k;
                const b = col * dim + k;
                const temp = M.data[a];
                M.data[a] = M.data[b];
                M.data[b] = temp;
            }
            swaps += 1;
        }

        row = col + 1;
        while (row < dim) : (row += 1) {
            const factor = M.data[row * dim + col] / M.data[col * dim + col];
            var k: usize = col;
            while (k < dim) : (k += 1) {
                M.data[row * dim + k] -= factor * M.data[col * dim + k];
            }
        }
    }

    var result: f32 = 1.0;
    var i: usize = 0;
    while (i < dim) : (i += 1) {
        result *= M.data[i * dim + i];
    }

    if (swaps % 2 == 1) result = -result;

    return result;
}

test "matrix_det_2x2" {
    var data = [_]f32{ 1.0, 2.0, 3.0, 4.0 };
    var tmp: [4]f32 = undefined;
    const A = Matrix{ .data = &data, .rows = 2, .cols = 2 };
    try testing.expectApproxEqAbs(matrix_det(A, &tmp), -2.0, 1e-6);
}

pub export fn matrix_inverse(in: Matrix, dst: Matrix, tmp: [*c]f32) callconv(.C) i32 {
    std.debug.assert(in.rows == in.cols);
    std.debug.assert(dst.rows == in.rows and dst.cols == in.cols);
    const dim: usize = in.rows;
    const stride: usize = dim * 2;

    var i: usize = 0;
    while (i < dim) : (i += 1) {
        var j: usize = 0;
        while (j < dim) : (j += 1) {
            tmp[i * stride + j] = in.data[i * dim + j];
            tmp[i * stride + dim + j] = if (i == j) @as(f32, 1.0) else @as(f32, 0.0);
        }
    }

    var col: usize = 0;
    while (col < dim) : (col += 1) {
        var max_val = @abs(tmp[col * stride + col]);
        var max_row: usize = col;
        var row: usize = col + 1;
        while (row < dim) : (row += 1) {
            const val = @abs(tmp[row * stride + col]);
            if (val > max_val) {
                max_val = val;
                max_row = row;
            }
        }

        if (max_val < 1e-12) return -1; // singular

        if (max_row != col) {
            var k: usize = 0;
            while (k < stride) : (k += 1) {
                const a = max_row * stride + k;
                const b = col * stride + k;
                const temp = tmp[a];
                tmp[a] = tmp[b];
                tmp[b] = temp;
            }
        }

        const pivot = tmp[col * stride + col];
        var k: usize = 0;
        while (k < stride) : (k += 1) {
            tmp[col * stride + k] /= pivot;
        }

        row = 0;
        while (row < dim) : (row += 1) {
            if (row == col) continue;
            const factor = tmp[row * stride + col];
            k = 0;
            while (k < stride) : (k += 1) {
                tmp[row * stride + k] -= factor * tmp[col * stride + k];
            }
        }
    }

    i = 0;
    while (i < dim) : (i += 1) {
        var j: usize = 0;
        while (j < dim) : (j += 1) {
            dst.data[i * dim + j] = tmp[i * stride + dim + j];
        }
    }

    return 0;
}

test "matrix_inverse_2x2" {
    var data = [_]f32{ 1.0, 2.0, 3.0, 4.0 };
    var dst_data: [4]f32 = undefined;
    var tmp: [8]f32 = undefined;

    const A = Matrix{ .data = &data, .rows = 2, .cols = 2 };
    const dst = Matrix{ .data = &dst_data, .rows = 2, .cols = 2 };

    const ret = matrix_inverse(A, dst, &tmp);
    try testing.expectEqual(ret, 0);

    try testing.expectApproxEqAbs(dst_data[0], -2.0, 1e-5);
    try testing.expectApproxEqAbs(dst_data[1], 1.0, 1e-5);
    try testing.expectApproxEqAbs(dst_data[2], 1.5, 1e-5);
    try testing.expectApproxEqAbs(dst_data[3], -0.5, 1e-5);
}


pub export fn matrix_print(m: Matrix) callconv(.C) void {
    var i: usize = 0;
    while (i < m.rows) : (i += 1) {
        _ = c_imp.printf("[ ");
        var j: usize = 0;
        while (j < m.cols) : (j += 1) {
            _ = c_imp.printf("%8.3f ", @as(f64, m.data[i * m.cols + j]));
        }
        _ = c_imp.printf("]\n");
    }
    _ = c_imp.printf("\n");
}


test "OLS_example_test" {
    var scrach_buffer: [32]f32 = undefined;
    var XD = [_]f32{1.0, 6.0, 1.0, 7.0, 1.0, 8.0};
    var XDT = [_]f32{0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    var YD = [_]f32{9.0, 15.0, 21.0};
    const check_data = [_]f32{-27.0, 6.0};
    
    var X = Matrix{.data = &XD, .rows = 3, .cols = 2};
    var XT = Matrix{.data = &XDT, .rows = 3, .cols = 2};
    const Y = Matrix{.data = &YD, .rows = 3, .cols = 1};

    copy_matrix(XT, X);

    matrix_transpose(&XT, &scrach_buffer);
    
    const XTX = Matrix{.data = &XDT, .rows = 2, .cols = 2};

    matrix_mult(XT, X, XTX, &scrach_buffer);
    
    _ = matrix_inverse(XTX, XTX, &scrach_buffer);

    matrix_transpose(&X, &scrach_buffer);

    const XTy = Matrix{.data = &XD, .rows = 2, .cols = 1};

    matrix_mult(X, Y, XTy, &scrach_buffer);
    
    matrix_mult(XTX, XTy, XTy, &scrach_buffer);
    
    const beta_hat = XD[0..2];

    for (beta_hat, check_data) |d, c| {
        try testing.expectApproxEqAbs(c, d, 1e-3);
    }
}
