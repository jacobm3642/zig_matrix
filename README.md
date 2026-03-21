# zig math

A small linear algebra library written in Zig for use from C.

![Workflow Status](http://charon:3000/jacobm3642/zig_math/actions/workflows/build.yml/badge.svg)

## Contract

- The caller owns all matrix memory.
- The caller provides all temporary buffers.
- Matrices use row-major layout.
- Shape compatibility is a caller precondition.
- `dst` may alias an input exactly.
- Partial overlap between distinct buffers is unsupported.
- Assertions catch contract violations during development.

> [!WARNING]
> Assertions may be removed in optimized builds. Invalid inputs must be treated as undefined/unsupported usage, so verify correctness in debug builds.

## Notes

- Temporary buffer size depends on the operation.
- `matrix_inverse` returns an error code for singular matrices.