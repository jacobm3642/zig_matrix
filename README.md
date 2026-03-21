# zig math

this is a basic linear algebra library written in zig for my use in C 

![Workflow Status](http://charon:3000/jacobm3642/zig_math/actions/workflows/build.yml/badge.svg)

## the contract 

- caller owns memory

- caller owns temporary buffers

- shape correctness is a precondition

- exact aliasing is allowed

- assertions catch misuse during development

> [!WARNING]
> assertions disappear in the release build so check with the debug build 

