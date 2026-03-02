# zag

**zag** is a systems programming language that diverges from [Zig](https://ziglang.org) toward an agent-driven future.

It keeps Zig's core syntax and philosophy — explicit, no hidden control flow, no hidden allocations — and evolves it through a structured proposal process (ZEPs).

## Status

Early design phase. Language evolution is driven by [Zag Enhancement Proposals](docs/zep/).

## Design Process

Language changes go through the **ZEP** (Zag Enhancement Proposal) process — see [`docs/zep/ZEP-0000-template.md`](docs/zep/ZEP-0000-template.md) for how to write one.

Architecture decisions are recorded in [`docs/adr/`](docs/adr/).

## Contributing

1. Read [ZEP-0001](docs/zep/ZEP-0001-charter.md) to understand zag's direction.
2. Open a discussion before writing a ZEP for significant language changes.
3. Follow the [ZEP template](docs/zep/ZEP-0000-template.md).

## Building

zag is built from Zig's toolchain. See [Building from Source](https://github.com/ziglang/zig/wiki/Building-Zig-From-Source) for dependencies (CMake, LLVM 19.x).

```
mkdir build
cd build
cmake ..
make install
```

## Origin

zag started as a divergent fork of Zig (imported from `codeberg.org/ziglang/zig`). The Zig codebase was the launch point; zag owns its own history from here. See [ADR-0001](docs/adr/ADR-0001-divergent-fork.md).
