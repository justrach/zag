# Zag Release Convention

## Version Format

```
zag-rt-{major}.{minor}.{patch}-{stage}.{build}
```

### Stages (in order of maturity)

| Stage | Meaning | API stable? | Tests required? |
|---|---|---|---|
| `gamma` | Early experimental — features may be incomplete or change | No | Basic tests |
| `alpha` | Feature-complete — all planned APIs exist but may have bugs | No | Stress tests |
| `beta` | API frozen — only bug fixes, no new features | Yes | Full suite + benchmarks |
| `rc` | Release candidate — believed ready, final validation | Yes | All tests + real-world usage |
| *(none)* | Stable release | Yes | Everything |

### Examples

```
zag-rt-0.1.0-gamma.1   First experimental build of the fiber runtime
zag-rt-0.1.0-gamma.2   Second experimental build (more features)
zag-rt-0.1.0-alpha.1   All Phase 1+2 features complete
zag-rt-0.1.0-beta.1    API frozen, testing phase
zag-rt-0.1.0-rc.1      Release candidate
zag-rt-0.1.0           Stable release
```

### What triggers each stage

- **gamma → alpha**: All planned primitives implemented (Fiber, Scope, Channel, Mutex, EventLoop, io, Sandbox)
- **alpha → beta**: All tests passing, benchmarks documented, no known crashes
- **beta → rc**: Real-world usage (TurboAPI integration, agent runtime tested)
- **rc → release**: No issues found during rc period

## Compiler Tags

The compiler itself tracks upstream Zig versioning:

```
zag-0.15.2              Compiler baseline (Zig 0.15.2 fork)
zag-0.15.2-N-gHASH      Development builds (git describe)
```

## Current Status

- Compiler: `zag-0.15.2` (stable baseline)
- Runtime: `zag-rt-0.1.0-gamma.2` (experimental, all core features working)
