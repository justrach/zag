# ADR-0001: zag as a Divergent Fork of Zig

| Field    | Value             |
|----------|-------------------|
| ADR      | 0001              |
| Status   | Accepted          |
| Created  | 2026-03-02        |
| Deciders | zag core team     |

## Context

zag needed a starting point. The options were:

1. Build a new language from scratch.
2. Fork an existing language and diverge.
3. Build a language that compiles *to* an existing language (transpiler approach).

## Decision

**Option 2: divergent fork of Zig.**

Zig's source was imported from Codeberg (`codeberg.org/ziglang/zig`) once as a starting point.

**Fork-point commit:** `5e512051190602bbff0f9b06fbb4a9a9bf5a5fff` (Zig `main`, 2026-03-02)

zag does not track Zig upstream — it owns its own history from the fork point. Future Zig changes are evaluated case-by-case and cherry-picked if relevant, never merged wholesale.

## Rationale

### Why Zig as the base?

- Zig's philosophy (explicit, no hidden allocations, comptime over macros, errors as values) aligns with zag's goals.
- The self-hosted compiler written in Zig gives zag a working bootstrap path.
- Zig's syntax is clean, unambiguous, and well-suited to AI-assisted authorship — fewer edge cases and footguns for agents to hit.

### Why divergent, not tracking?

- zag's direction (agent-driven co-development, stabilized async, language-level evolution via ZEPs) will produce breaking changes relative to Zig.
- Tracking upstream would create constant merge conflicts and force zag to absorb Zig decisions that may contradict accepted ZEPs.
- A clean divergence gives zag a stable base without the overhead of reconciling two active language designs.

### Why not from scratch?

- A working compiler, standard library, and build system are not free. Starting from Zig means zag starts with a working toolchain on day one.
- The cost is inheriting Zig's history and some of its unresolved design questions (notably async). zag treats these as first ZEP targets.

### Why not transpile to Zig?

- Zig is not stable enough as a compilation target — Zig itself is still pre-1.0.
- Transpilation adds a dependency zag can't control.

## Consequences

- zag is **not** a Zig compatibility layer. Programs written for Zig may not compile under zag once the two languages diverge.
- The `zig-upstream` remote is read-only reference. It is never merged into `main`; cherry-picks require a tracking comment citing the Zig commit SHA.
- **Security/critical fixes:** If a CVE or critical bug is found in Zig's compiler or stdlib that also affects zag, a maintainer may cherry-pick the fix directly without a ZEP. The cherry-pick PR must reference the upstream commit and the CVE/issue. All other upstream changes require a ZEP.
- **Attribution:** Source files inherited at the fork point retain Zig's MIT copyright header. New zag-originated files use the zag MIT header. Files substantially rewritten post-fork are relicensed to zag's header with a note of origin.

## Status History

| Date       | Status   | Note                     |
|------------|----------|--------------------------|
| 2026-03-02 | Accepted | Initial ADR at fork time |
