# NLL — rolling development tracker

**Start here:** [MASTER DEVELOPMENT CHECKLIST](MASTER_DEVELOPMENT_CHECKLIST.md) is the authoritative project-wide source of truth. This shorter table is a quick status snapshot, not a replacement for historical and parallel work.

**Update this document when opening or completing each development stage.**
Never confuse draft code, automated checks, real WoW acceptance or release.

| Stage / PR | Scope | Automated verification | Integrated WoW testing | Deployment |
|---|---|---|---|---|
| #10 | New Drop HF2, duplicate safeguards, corrected UI | Previous automated checks | HF2 overlap visually checked | HF2 installed, remain untouched |
| #12 | Personal NEED/GREED + RAID chat count | Passed in handover | Pending | Draft only |
| #13 | Award Winner / guarded Master Loot | Passed in handover | Pending | Draft only |
| #14 | All-slot guild loot review incl. mats | Passed in handover | Pending | Draft only |
| #15 | Manual guild transfer & audit | Passed in handover | Pending | Draft only |
| #16 | Winner -> recipient-confirmed OBTAINED | Passed in handover | Pending | Draft only |
| #17 | Remote human receipt ACK | Passed on 82ce0ebb8a32 | Pending paired clients | Draft only |
| #22 | Write-ahead persistent lock / NO-RETRY audit | Passed on 497fe3be04d1 | Pending | Draft only |
| #23 | Optional all-slot dry-run guild allocation | Passed on 14dd65ff24f0 | Pending | Draft only |
| #24 | UI for reconciliation list, paging, arm/confirm | Passed on 60e28ad81eae | Pending | Draft only |
| #25 | Duplicate item ID across slots / full test checklist | Passed (latest exact-head CI evidence linked on PR #25) | Pending | Draft only |

| #26 | Live exact character filter + master checklist | Full Lua 5.1 and dedicated safety CI passed (PR #26 checks) | Pending client acceptance | Draft only |
| #27 | Orphaned winner/pending human ACK, slot-cleared, lottery and Master Looter holds | Lua 5.1 + dedicated safety checks passed (PR #27) | Pending paired clients | Draft only |
| #28 | Intended recipient own-bag statement, separate no-retry audit and paged UI | Dedicated no-release + full Lua 5.1 suite PASSED (PR #28) | Pending in-game | Draft only |
| #29 | UI footer geometry + recipient-only My Bags entry | Pending CI | Pending visual screenshots | Draft only |

**Parallel, separately stacked drafts #18–#21** are inventoried in the master checklist; see [review decisions](REVIEW_PARALLEL_DRAFTS.md) for the safe findings forwarded into #27. The alternative reconciliation branches remain separate drafts.

## Hard safety rules

- Do not merge, release, install or change live server or actual item.
- Never reset 604 Playerbot Gear Plan rows; back up addon and
  SavedVariables separately before any future controlled testing.
- NEED/GREED comes first. Receipt OBTAINED is independent of a loot
  slot clearing or API success; remote wishlist ACK is an assertion.
- Physical direct award and guild transfer consent both remain OFF on
  every login; automatic allocation is strictly preview-only.
- Same-item-ID guild loot transfers stay blocked across slot changes:
  this conservative hold awaits reliable independent corpse identity.

## Next work (after current draft #29)

- [ ] Visual test evidence for the reconciliation window, dry-run
      allocations, overlapping buttons and long item names.
- [ ] Identify a robust, testable way to distinguish repeated materials
      on genuinely different corpses in the WoW 3.3.5a API.
- [ ] Final integrated WoW acceptance against
      docs/INTEGRATED_RAID_TEST_CHECKLIST.md, only with owner approval.
- [ ] Fix failures in separate stacked draft PRs with exact-head CI.
- [ ] Prepare future release notes; no release without explicit approval.

## Owner actions (only when we reach controlled in-game testing)

- [ ] Approve a quiet testing window.
- [ ] Back up installed HF2, all relevant account SavedVariables, plus
      .lua.bak if present; include both leader and human recipient clients.
- [ ] Verify saved Playerbot Gear Plan baseline counts before testing.

Until then: **nothing to install, merge, award or modify on the live server.**
