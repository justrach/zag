# ZEP-XXXX: Title

| Field    | Value                             |
|----------|-----------------------------------|
| ZEP      | XXXX                              |
| Title    | Short descriptive title           |
| Author   | Name \<email\> (or GitHub handle) |
| Status   | Draft                             |
| Type     | Language / Toolchain / Process    |
| Created  | YYYY-MM-DD                        |
| Updated  | YYYY-MM-DD                        |
| Requires | ZEP-YYYY (if any)                 |

---

## Abstract

One paragraph. What is this ZEP proposing? What problem does it solve?

## Motivation

Why is this needed? What use cases does it enable? What is the cost of *not* doing this? Include real-world examples where possible.

## Non-Goals

What is explicitly out of scope for this ZEP? This prevents scope creep during review.

## Specification

Precise description of the proposed change. For language features, include:

- Grammar changes (BNF/ABNF if applicable)
- Semantics and runtime behaviour
- Type system implications
- Error conditions and error messages
- Interaction with existing language features

## Examples

```zig
// Concrete, runnable examples showing the feature in use.
// Show at least one "happy path" and one edge case.
```

## Backwards Compatibility

**Required.** Choose one:

- [ ] **No breakage.** Existing programs continue to compile and behave identically.
- [ ] **Breaking change.** Describe exactly what breaks and provide a migration path below.

Migration path (if breaking):

```
// Before:
// After:
```

## Risk Assessment

| Risk                  | Likelihood | Impact | Mitigation                    |
|-----------------------|------------|--------|-------------------------------|
| (e.g. parser ambiguity) | Low      | High   | (e.g. add grammar tests)      |

## Testing and Validation Plan

How will correctness be verified?

- [ ] Compiler test cases (list key scenarios)
- [ ] Standard library tests
- [ ] Fuzzing / property tests (if applicable)
- [ ] Benchmark (if performance is a claim)

## Implementation Notes

How would this be implemented in the zag compiler? Reference relevant source files or compiler stages. Not required for Draft; **required for Accepted**.

## Rollout / Migration Strategy

For breaking changes or large features:

- What is the rollout sequence (e.g. feature flag → default-on → old-path removed)?
- Is there a deprecation window?
- What tooling (e.g. `zag fix`) is provided to migrate existing code?

## Alternatives Considered

What other approaches were evaluated and why were they rejected?

| Alternative | Reason rejected |
|-------------|-----------------|
| ...         | ...             |

## Open Questions

*Remove this section before moving to Review.*

- [ ] Question 1
- [ ] Question 2

## Done Criteria

This ZEP is **Final** when:

- [ ] Specification is fully implemented in the compiler.
- [ ] All test cases pass.
- [ ] Language reference is updated.
- [ ] Standard library updated if affected.
- [ ] Migration tooling shipped (if breaking).
- [ ] This ZEP's status is updated to `Final` and linked from release notes.

---

## Status History

| Date       | Status  | Note            | Council votes |
|------------|---------|-----------------|---------------|
| YYYY-MM-DD | Draft   | Initial draft   | —             |
