# Zag Enhancement Proposals (ZEPs)

This directory contains all ZEPs — the mechanism by which zag evolves.
## Index

| ZEP    | Title                    | Status   | Type     |
|--------|--------------------------|----------|----------|
| 0000   | ZEP Template             | —        | Process  |
| 0001   | The Zag Language Charter | Accepted | Process  |
| 0002   | Structured Async         | Draft    | Language |
| 0000   | ZEP Template             | —        | Process |
| 0001   | The Zag Language Charter | Accepted | Process |
| 0002   | Async Structure          | Draft    | Language |

## What is a ZEP?

A ZEP (Zag Enhancement Proposal) is a design document that proposes a language change, toolchain addition, or process improvement. It must be accepted before implementation begins (for language-level changes).

See [ZEP-0001 §The ZEP Process](ZEP-0001-charter.md#the-zep-process) for the full lifecycle.

## Numbering

- ZEP numbers are assigned sequentially when a PR is opened.
- Numbers are never recycled.
- File naming: `ZEP-NNNN-short-slug.md` (e.g. `ZEP-0002-async-structure.md`).
- Before a number is assigned, use `ZEP-XXXX-your-slug.md` in your branch.

## Submitting a ZEP

1. Copy [`ZEP-0000-template.md`](ZEP-0000-template.md) to `ZEP-XXXX-your-slug.md`.
2. Fill in all required sections. Mark optional sections N/A if not applicable.
3. Open a GitHub Issue tagged `zep:draft` to gather early feedback before opening a PR.
4. Open a PR. A ZEP number will be assigned and the filename updated.
5. The PR enters the **Review** period (minimum 7 calendar days).
6. After Review, the Language Council votes.

## Language Council

The Language Council makes final decisions on ZEP acceptance.

**Composition:** Any contributor with ≥2 accepted ZEPs or nominated by a current council member. The council list is maintained in [`COUNCIL.md`](../COUNCIL.md).

**Quorum:** Decisions require ≥3 council votes with no more than 1 veto.

**Voting:** Council members vote `+1` (accept), `0` (abstain), or `-1` (veto with required written rationale) directly on the ZEP PR. Votes are recorded in the ZEP's Status History table.

**Tie-breaking:** If quorum is not met within 14 days of a ZEP entering Review, the proposal is returned to Draft with a comment explaining what is needed.

## Status Definitions

| Status      | Meaning                                                         |
|-------------|-----------------------------------------------------------------|
| Draft       | Work in progress. Not ready for formal review.                  |
| Review      | PR open, minimum review period active.                          |
| Accepted    | Council approved. Implementation may proceed.                   |
| Rejected    | Council declined. Rationale recorded in ZEP.                    |
| Withdrawn   | Author withdrew. May be resubmitted as a new ZEP.               |
| Final       | Implemented, shipped, spec updated.                             |
| Superseded  | Replaced by a later ZEP (links to successor).                   |

## Acceptance Criteria

A ZEP may be accepted when:

- All required template sections are filled (no "TBD" in Specification).
- Backwards Compatibility section explicitly states what breaks and provides a migration path (or states "no breakage").
- At least one Implementation Note exists.
- Open Questions section is empty or removed.
- Minimum 7-day Review period has elapsed.
- Quorum of council votes achieved.

## What does not need a ZEP

- Bug fixes with no observable behaviour change.
- Performance improvements with no observable behaviour change.
- Documentation and comment updates.
- Standard library additions that introduce no new syntax or semantics.
- Toolchain/build system changes that do not affect language semantics.
