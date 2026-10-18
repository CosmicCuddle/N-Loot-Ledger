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
| #29 | UI footer geometry + recipient-only My Bags entry | Dedicated + full Lua 5.1 CI passed (PR #29) | Pending visual screenshots | Draft only |
| #30 | 3.3.5a loot-source API research + non-awarding /nll lootsource | Dedicated no-release + full Lua 5.1 CI passed (PR #30) | Pending source-hint diagnostic check | Draft only |
| #31 | Read-only 604-plan export 250/250/104 with batch pager | Dedicated no-release + complete Lua 5.1 tests passed (PR #31) | Pending clipboard and GUI acceptance | Draft only |
| #32 | Two-click per-bot Gear Plan status/deletion review; protect OBTAINED and pending awards | Dedicated no-release + all Lua 5.1 tests passed (PR #32) | Pending full-roster client acceptance | Draft only |
| #33 | Item-only bot role picker + 15-second two-click review, zero shared-role writes | Dedicated no-release + complete Lua 5.1 CI passed (PR #33) | Pending client role/picker visual acceptance | Draft only |
| #34 | Read-only V1 import conflict comparisons incl. UTF-8 aliases, paged SAVED/PASTED UI | Dedicated no-release + complete Lua 5.1 CI passed (PR #34) | Pending clipboard/UI acceptance | Draft only |
| #35 | Ten MC recipe professions + unverified Gear Plan candidates; manual-only paged review | Dedicated no-release + full Lua 5.1 CI passed (PR #35) | Pending profession evidence/UI acceptance | Draft only |
| #36 | Read-only grouped duplicate slot/stack audit, old item-ID holds and trusted source evidence blueprint | Dedicated no-release + full Lua 5.1 checks passed (PR #36) | Pending controlled real 3.3.5a /nll copyaudit checks | Draft only |
| #37 | C14 combined 604-plan regression + stale review/import modal disarming on navigation, Escape and close | Dedicated no-release + complete Lua 5.1 CI passed (PR #37) | Partial owner dev19 UI screenshots received: 636 saved plans; overlaps discovered | Draft only |
| #38 | Owner dev19 live UI follow-up: Inbox archive/paging, roll winners vs physical attempts, new run display, Wishlist footer | Dedicated/complete Lua 5.1 + TEST-ONLY ZIP checks passed (PR #38) | Owner dev20 screenshot/retest pending | Draft only |

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

**Owner Phase 1 packaging handoff (PR #37, unmerged):** dedicated TEST-ONLY
Actions workflow prepares a checksum-verified dev19 addon archive and
[backup-first non-destructive test instructions](OWNER_TEST_ONLY_HANDOFF.md).
An artifact is eligible for owner testing only after exact-commit build and
entire Lua 5.1 regressions pass; no automated installation or release.
Actual WoW UI screenshots and saved-data preservation remain outstanding.

**Current real owner screenshot (18 Oct): 636 saved Gear Plans, NOT old 604**.
Keep the older 604/469 NEED/135 GREED regression fixture, but require
new matched backups and check actual record status counts before migration
or further installs. No reset or import is approved.

## Next work (after current draft #38 — owner dev19 feedback and safe retest gate)

- [ ] Controlled test evidence for all 604-bot-plan batch exports,
      including Ctrl+C, labels, import preview and SavedVariables backup.
- [ ] Visual test evidence for the reconciliation window, dry-run
      allocations, overlapping buttons and long item names.
- [x] Confirm GetLootSourceInfo is unavailable in 3.3.5a and target
      UnitGUID is only a hint; document safe evidence gaps.
- [ ] Evaluate authenticated server-to-addon loot-source evidence
      separately before proposing any change to the permanent item-ID lock.
- [ ] Final integrated WoW acceptance against
      docs/INTEGRATED_RAID_TEST_CHECKLIST.md, only with owner approval.
- [ ] Fix failures in separate stacked draft PRs with exact-head CI.
- [ ] Prepare future release notes; no release without explicit approval.

**SHARED TEST PRERELEASE PUBLISHED 18 Oct:** [v0.1.0.29-rc.1-dev20-test.1](https://github.com/CosmicCuddle/N-Loot-Ledger/releases/tag/v0.1.0.29-rc.1-dev20-test.1), exact already-tested SHA e7566c77bdee565c35830e9fddc9481f7db88464, ZIP hash 19f1ec42328ee184b84e2de2fac91000e1d0c68480a61fbf06f407aff22acae7. Pre-release for voluntary 19 October tests only; stable v0.1.0.28, main and draft PRs remain unchanged. Source ZIP includes no personal roster or SavedVariables. Normal manual loot handling required, NLL physical transfers OFF. Winner event logging still needs real-raid validation; buff overlay #39 deferred.

## Owner actions (only when we reach controlled in-game testing)

- [ ] Approve a quiet testing window.
- [ ] Back up the currently installed dev20 (or that tester's current version), all relevant account SavedVariables, plus
      .lua.bak if present; include both leader and human recipient clients.
- [ ] Verify saved Playerbot Gear Plan baseline counts before testing.

Current owner has dev20 installed; other testers may **optionally** install the published dev20 prerelease only after matched backups and SHA256 verification. No PR merge, server changes or real NLL physical awards authorised.
