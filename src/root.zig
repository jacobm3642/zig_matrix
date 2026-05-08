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


pub export fn matrix_elementwise_mult(A: Matrix, B: Matrix, dst: Matrix, tmp: [*c]f32) callconv(.C) void {
    std.debug.assert(A.rows == B.rows and A.cols == B.cols and A.rows == dst.rows and A.cols == dst.cols);
    const n = A.rows * A.cols;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        tmp[i] = A.data[i] * B.data[i];
    }
    i = 0;
    while (i < n) : (i += 1) {
        dst.data[i] = tmp[i];
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

pub export fn matrix_set_all(M: Matrix, val: f32) callconv(.C) void {
    var i: usize = 0;
    while (i < M.rows * M.cols) : (i += 1) {
        M.data[i] = val;
    }
}

test "matrix_set_all_test" {
    var AD: [64]f32 = undefined;
    
    const M = Matrix{.data = &AD, .rows = 8, .cols = 8};

    matrix_set_all(M, 99.82);

    for (AD) |d| {
        try std.testing.expect(d == 99.82);
    }
}

pub export fn matrix_random(M: Matrix, min: f32, max: f32) callconv(.C) void {
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        if (std.posix.getrandom(std.mem.asBytes(&seed))) |_| {} else |_| {
            return;
        }
        break :blk seed;
    });
    const rand = prng.random();
    const n = M.rows * M.cols;
    var i: usize = 0;

    while (i < n) : (i += 1) {
        M.data[i] = min + rand.float(f32) * (max - min);
    }
}

test "random_matrix_test" {
    var AD: [64]f32 = undefined;
    
    const M = Matrix{.data = &AD, .rows = 8, .cols = 8};

    matrix_random(M, 0.3, 0.7);

    for (AD) |d| {
        try std.testing.expect(d < 0.7 and d >= 0.3);
    }
}

pub export fn matrix_zero(M: Matrix) callconv(.C) void {
    matrix_set_all(M, 0);
}

test "random_zero_test" {
    var AD: [64]f32 = undefined;
    
    const M = Matrix{.data = &AD, .rows = 8, .cols = 8};

    matrix_zero(M);

    for (AD) |d| {
        try std.testing.expect(d == 0);
    }

}

// -----------------------------------------------------
// |                  bigger tests                     |
// -----------------------------------------------------

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

fn expectSliceApproxEqAbs(expected: []const f32, actual: []const f32, tol: f32) !void {
    try testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |e, a| {
        try testing.expectApproxEqAbs(e, a, tol);
    }
}

test "transpose twice restores original non-square matrix" {
    var tmp: [6]f32 = undefined;
    var data = [_]f32{
        1.0, 2.0, 3.0,
        4.0, 5.0, 6.0,
    };
    const original = data;

    var A = Matrix{ .data = &data, .rows = 2, .cols = 3 };

    matrix_transpose(&A, &tmp);
    try testing.expectEqual(@as(u32, 3), A.rows);
    try testing.expectEqual(@as(u32, 2), A.cols);

    matrix_transpose(&A, &tmp);
    try testing.expectEqual(@as(u32, 2), A.rows);
    try testing.expectEqual(@as(u32, 3), A.cols);

    try expectSliceApproxEqAbs(&original, &data, 1e-6);
}

test "identity matrix behavior" {
    var tmp: [8]f32 = undefined;

    var a_data = [_]f32{
        2.0, 3.0,
        4.0, 5.0,
    };
    var i_data = [_]f32{
        1.0, 0.0,
        0.0, 1.0,
    };
    var left_data: [4]f32 = undefined;
    var right_data: [4]f32 = undefined;
    var inv_i_data: [4]f32 = undefined;

    const A = Matrix{ .data = &a_data, .rows = 2, .cols = 2 };
    const I = Matrix{ .data = &i_data, .rows = 2, .cols = 2 };
    const Left = Matrix{ .data = &left_data, .rows = 2, .cols = 2 };
    const Right = Matrix{ .data = &right_data, .rows = 2, .cols = 2 };
    const InvI = Matrix{ .data = &inv_i_data, .rows = 2, .cols = 2 };

    matrix_mult(I, A, Left, &tmp);
    matrix_mult(A, I, Right, &tmp);

    try expectSliceApproxEqAbs(&a_data, &left_data, 1e-6);
    try expectSliceApproxEqAbs(&a_data, &right_data, 1e-6);

    const det_i = matrix_det(I, &tmp);
    try testing.expectApproxEqAbs(@as(f32, 1.0), det_i, 1e-6);

    const ret = matrix_inverse(I, InvI, &tmp);
    try testing.expectEqual(@as(i32, 0), ret);
    try expectSliceApproxEqAbs(&i_data, &inv_i_data, 1e-6);
}

test "inverse correctness via multiplication" {
    var tmp_inv: [8]f32 = undefined;
    var tmp_mul: [4]f32 = undefined;

    var a_data = [_]f32{
        4.0, 7.0,
        2.0, 6.0,
    };
    var inv_data: [4]f32 = undefined;
    var prod1_data: [4]f32 = undefined;
    var prod2_data: [4]f32 = undefined;

    const identity = [_]f32{
        1.0, 0.0,
        0.0, 1.0,
    };

    const A = Matrix{ .data = &a_data, .rows = 2, .cols = 2 };
    const Inv = Matrix{ .data = &inv_data, .rows = 2, .cols = 2 };
    const Prod1 = Matrix{ .data = &prod1_data, .rows = 2, .cols = 2 };
    const Prod2 = Matrix{ .data = &prod2_data, .rows = 2, .cols = 2 };

    const ret = matrix_inverse(A, Inv, &tmp_inv);
    try testing.expectEqual(@as(i32, 0), ret);

    matrix_mult(A, Inv, Prod1, &tmp_mul);
    matrix_mult(Inv, A, Prod2, &tmp_mul);

    try expectSliceApproxEqAbs(&identity, &prod1_data, 1e-4);
    try expectSliceApproxEqAbs(&identity, &prod2_data, 1e-4);
}

test "singular matrix inverse fails and determinant is zero" {
    var tmp_inv: [8]f32 = undefined;
    var tmp_det: [4]f32 = undefined;

    var singular_data = [_]f32{
        1.0, 2.0,
        2.0, 4.0,
    };
    var dst_data: [4]f32 = undefined;

    const A = Matrix{ .data = &singular_data, .rows = 2, .cols = 2 };
    const Dst = Matrix{ .data = &dst_data, .rows = 2, .cols = 2 };

    const det = matrix_det(A, &tmp_det);
    try testing.expectApproxEqAbs(@as(f32, 0.0), det, 1e-6);

    const ret = matrix_inverse(A, Dst, &tmp_inv);
    try testing.expectEqual(@as(i32, -1), ret);
}

test "determinant of upper triangular matrix is product of diagonal" {
    var tmp: [9]f32 = undefined;
    var data = [_]f32{
        2.0, 1.0, 3.0,
        0.0, 4.0, 5.0,
        0.0, 0.0, 6.0,
    };
    const A = Matrix{ .data = &data, .rows = 3, .cols = 3 };

    const det = matrix_det(A, &tmp);
    try testing.expectApproxEqAbs(@as(f32, 48.0), det, 1e-5);
}

test "matrix_map matches matrix_scalar_mult for doubling" {
    const twice = struct {
        fn call(x: f32) callconv(.C) f32 {
            return 2.0 * x;
        }
    }.call;

    var a_data = [_]f32{
        1.0, 2.0,
        3.0, 4.0,
    };
    var b_data = a_data;

    const A = Matrix{ .data = &a_data, .rows = 2, .cols = 2 };
    const B = Matrix{ .data = &b_data, .rows = 2, .cols = 2 };

    matrix_map(A, &twice);
    matrix_scalar_mult(B, 2.0);

    try expectSliceApproxEqAbs(&b_data, &a_data, 1e-6);
}

test "add then subtract recovers original" {
    var tmp: [6]f32 = undefined;

    var a_data = [_]f32{
        1.0, 2.0, 3.0,
        4.0, 5.0, 6.0,
    };
    var b_data = [_]f32{
        6.0, 5.0, 4.0,
        3.0, 2.0, 1.0,
    };
    const original_a = a_data;

    const A = Matrix{ .data = &a_data, .rows = 2, .cols = 3 };
    const B = Matrix{ .data = &b_data, .rows = 2, .cols = 3 };

    matrix_add(A, B, A, &tmp);
    matrix_sub(A, B, A, &tmp);

    try expectSliceApproxEqAbs(&original_a, &a_data, 1e-6);
}

test "matrix multiplication distributes over addition" {
    var tmp_add: [6]f32 = undefined;
    var tmp_mul: [4]f32 = undefined;
    var tmp_sum: [4]f32 = undefined;

    var a_data = [_]f32{
        1.0, 2.0, 3.0,
        4.0, 5.0, 6.0,
    };
    var b_data = [_]f32{
        1.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
    };
    var c_data = [_]f32{
        2.0, 1.0,
        1.0, 0.0,
        0.0, 2.0,
    };

    var b_plus_c_data: [6]f32 = undefined;
    var left_data: [4]f32 = undefined;
    var ab_data: [4]f32 = undefined;
    var ac_data: [4]f32 = undefined;
    var right_data: [4]f32 = undefined;

    const A = Matrix{ .data = &a_data, .rows = 2, .cols = 3 };
    const B = Matrix{ .data = &b_data, .rows = 3, .cols = 2 };
    const C = Matrix{ .data = &c_data, .rows = 3, .cols = 2 };
    const BPlusC = Matrix{ .data = &b_plus_c_data, .rows = 3, .cols = 2 };
    const Left = Matrix{ .data = &left_data, .rows = 2, .cols = 2 };
    const AB = Matrix{ .data = &ab_data, .rows = 2, .cols = 2 };
    const AC = Matrix{ .data = &ac_data, .rows = 2, .cols = 2 };
    const Right = Matrix{ .data = &right_data, .rows = 2, .cols = 2 };

    matrix_add(B, C, BPlusC, &tmp_add);
    matrix_mult(A, BPlusC, Left, &tmp_mul);

    matrix_mult(A, B, AB, &tmp_mul);
    matrix_mult(A, C, AC, &tmp_mul);
    matrix_add(AB, AC, Right, &tmp_sum);

    try expectSliceApproxEqAbs(&right_data, &left_data, 1e-5);
}

test "scalar multiplication distributes over addition" {
    var tmp: [4]f32 = undefined;

    var a_data = [_]f32{
        1.0, 2.0,
        3.0, 4.0,
    };
    var b_data = [_]f32{
        5.0, 6.0,
        7.0, 8.0,
    };

    var left_data: [4]f32 = undefined;
    var right1_data = a_data;
    var right2_data = b_data;
    var right_data: [4]f32 = undefined;

    const alpha: f32 = 3.5;

    const A = Matrix{ .data = &a_data, .rows = 2, .cols = 2 };
    const B = Matrix{ .data = &b_data, .rows = 2, .cols = 2 };
    const Left = Matrix{ .data = &left_data, .rows = 2, .cols = 2 };
    const Right1 = Matrix{ .data = &right1_data, .rows = 2, .cols = 2 };
    const Right2 = Matrix{ .data = &right2_data, .rows = 2, .cols = 2 };
    const Right = Matrix{ .data = &right_data, .rows = 2, .cols = 2 };

    matrix_add(A, B, Left, &tmp);
    matrix_scalar_mult(Left, alpha);

    matrix_scalar_mult(Right1, alpha);
    matrix_scalar_mult(Right2, alpha);
    matrix_add(Right1, Right2, Right, &tmp);

    try expectSliceApproxEqAbs(&right_data, &left_data, 1e-5);
}

test "1x1 edge cases" {
    var tmp2: [2]f32 = undefined;
    var tmp1: [1]f32 = undefined;

    var a_data = [_]f32{ 5.0 };
    var inv_data: [1]f32 = undefined;

    var A = Matrix{ .data = &a_data, .rows = 1, .cols = 1 };
    const Inv = Matrix{ .data = &inv_data, .rows = 1, .cols = 1 };

    const det = matrix_det(A, &tmp1);
    try testing.expectApproxEqAbs(@as(f32, 5.0), det, 1e-6);

    const ret = matrix_inverse(A, Inv, &tmp2);
    try testing.expectEqual(@as(i32, 0), ret);
    try testing.expectApproxEqAbs(@as(f32, 0.2), inv_data[0], 1e-6);

    matrix_transpose(&A, &tmp1);
    try testing.expectEqual(@as(u32, 1), A.rows);
    try testing.expectEqual(@as(u32, 1), A.cols);
    try testing.expectApproxEqAbs(@as(f32, 5.0), a_data[0], 1e-6);
}
