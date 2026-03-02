# zag

**zag** is a systems programming language built by AI, for AI — and for the humans who work alongside them.

It diverges from [Zig](https://ziglang.org), keeping its core philosophy (explicit, no hidden allocations, errors as values) and evolving it through a structured proposal process.

## Status

Early design phase. The Zig source is imported; language divergence begins now via ZEPs.

| Area        | State        |
|-------------|--------------|
| Source base | Zig `main` @ `5e512051` (2026-03-02) |
| Language    | Zig-compatible (no divergence yet) |
| Async (ZEP-0002) | Draft — first milestone |

## Governance

| Document | Purpose |
|----------|---------|
| [ZEP-0001 — Charter](docs/zep/ZEP-0001-charter.md) | Language vision and founding principles |
| [ZEP process & index](docs/zep/README.md) | How to propose changes, ZEP lifecycle, council rules |
| [ZEP-0000 — Template](docs/zep/ZEP-0000-template.md) | Copy this to write a ZEP |
| [ADR-0001 — Divergent fork](docs/adr/ADR-0001-divergent-fork.md) | Why zag forked Zig and how upstream is handled |
| [Council](docs/COUNCIL.md) | Language council membership and voting |

## Contributing

**To propose a language change:**
1. Open a [GitHub Issue](../../issues/new) tagged `zep:draft` to discuss your idea first.
2. Copy [`docs/zep/ZEP-0000-template.md`](docs/zep/ZEP-0000-template.md), fill it in.
3. Open a PR — a ZEP number will be assigned.
4. See [docs/zep/README.md](docs/zep/README.md) for the full process.

**To fix bugs or improve tooling:** no ZEP needed — open a PR directly.

## Building

zag builds from the same toolchain as Zig. Dependencies: CMake ≥ 3.15, LLVM/Clang/LLD 19.x.

```sh
mkdir build && cd build
cmake ..
make install
```

For a no-LLVM bootstrap (C compiler only):

```sh
cc -o bootstrap bootstrap.c && ./bootstrap
```

## Origin

Divergent fork of Zig — imported from `codeberg.org/ziglang/zig` at commit `5e512051`. zag owns its own history from here. See [ADR-0001](docs/adr/ADR-0001-divergent-fork.md).
