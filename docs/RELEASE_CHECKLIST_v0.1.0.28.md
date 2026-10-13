# v0.1.0.28 — First stable-core release checklist

**State: release candidate under review; NOT APPROVED TO PUBLISH.** Scope agreed by owner 13 October 2026: stable **verified core** with unverified Direct Master Loot explicitly **experimental and OFF**. This list distinguishes prior in-game observation, source tests, and remaining release gates.

## Completed evidence

- [x] Owner chose tag/version `v0.1.0.28` for release **preparation** (not merge/publication).
- [x] Earlier WoW 3.3.5a UI checks: Overview, My Wishlist, Gear Plans, Recipes, Raid Loot Search, Priority Setup, Debug Lab, Current Loot, Award History, Inbox. **Owner has now supplied a screenshot confirming the additional Issue #7 Priority Setup layout fix is visually correct at the actual font/UI scale.**
- [x] Owner verified 15 saved wishlist reservations (11 Gear / Items; 4 Recipes), and Recipes persisted through `/reload`.
- [x] Real 39-person raid roster showed correct names/classes/statuses and NLL roles persisted through `/reload`.
- [x] Fake MC40 lottery and fake award completed without actual loot transfer; real Award History showed 0 during the test.
- [x] Direct Master Loot was OFF when observed after the tests; code resets it on each DB initialization.
- [x] Pre-release workflows `publish-v0.1.0.25–27-prerelease.yml` remain unchanged; **no** new release auto-publication pathway is enabled.

## Candidate preparation (no permission to publish)

- [x] Bump internal `NLL.version` and `## Version` to 0.1.0.28 on separate review branch, preserving `NaxxLootLottery` / `NaxxLootLotteryDB`.
- [x] Write release notes, install/rollback instructions and a reproducible addon-only package script.
- [x] Add read-only candidate CI with Lua 5.1 tests and a downloadable workflow artifact, **without any tag/release creation**.
- [x] Original v0.1.0.28 review ZIP passed CI and was installed/tested in WoW, but it was **superseded** by a new Priority Setup footer layout fix (Issue #7). The original ZIP SHA256 was `1f1158cd66d0d76dd578451f018508ee6a8d2cfdcc8428a711b63370cccf755d`. **Do not use the earlier candidate to validate Issue #7.**
- [x] **Newest layout-fix candidate** passed [Lua 5.1 and non-publishing packaging CI](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/38443602149): 32 Lua modules plus TOC, no WTF or SavedVariables, Direct Master Loot OFF. New ZIP SHA256: `325af42295104eb448e96cf14211af732f7ba8045fa693718c5322dda7162ee3`. Automated mock tests include unusually wide fonts, counts and help tooltips; the owner has now **visually confirmed the updated in-client layout**. Actual hover help was not separately tested in WoW.
- [x] Owner installed the candidate build and provided a real WoW chat screenshot showing `[NLL] Naxxramas Loot Ledger version 0.1.0.28` and `[NLL] Initialization status: READY.` (13 October 2026). No NLL Lua error is visible in this screenshot; this is not an exhaustive error check.
- [x] Owner confirmed the v0.1.0.28 candidate still shows **15 total wishlist reservations**, that assigned **raid roles remain saved**, and that **Direct Master Loot is OFF** (13 October 2026). This is owner-reported acceptance without screenshots of these three panels; item-by-item reconciliation, reset on a fresh candidate `/reload`, and actual item delivery remain untested.
- [x] **Prior checks carried forward by owner confirmation (13 October 2026):** Priority Setup preset count/settings (previously **136** active), Award History's previously verified state, and previously reviewed UI screens are reported unchanged after installing v0.1.0.28. No duplicate screenshots or repeated page-by-page tests requested. This is an owner-reported unchanged-state check, **not a new exhaustive screenshot-backed history/persistence test**.
- [x] Validated package tested in client: owner installed downloaded review candidate, confirmed `0.1.0.28` / READY, 15 wishlist entries, roles intact and Direct Master Loot OFF. GitHub [head candidate CI](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/38438249671) passed; artifact `Naxxramas-Loot-Ledger-v0.1.0.28-REVIEW` remains available. It is not a published GitHub release.
- [x] **Issue #7 — Priority Setup large-font overlap accepted visually:** post-fix screenshot from owner (13 October 2026) shows Custom 1 / Presets 135 in the upper-right title row and `ACTIVE - 136 PRESETS. CUSTOM RULES WIN.` in one line beside Disable Presets; Previous / Next / Suggestions Only / Undo remain clear. This is visual verification only, with no button changes, hover check or loot awards. Issue stays open until the approved PR #6 merge.
- [ ] Perform/approve a matched-addon-and-SavedVariables restore rehearsal on an **expendable** copy (not production), or explicitly document why deferred.
- [ ] Resolve owner-reviewed Issue #4 / #5 closure disposition; leave unrelated [Issue #1](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/1) open as a clearly documented known limitation unless real live-raid testing supports closure.
- [ ] Decide explicitly how to disclose deferred real boss loot observation, multi-corpse recovery and bot eligibility, without claiming real item delivery.

## Publication requires new, separate approvals

- [x] Owner separately approved [PR #2 — Dark-only UI](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/2); merged to `main` as `7cd0db208f571c04cd8b513898947106b74456c1`.
- [x] Owner separately approved [PR #3 — Recipes and UI fixes](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/3); retargeted and merged to `main` as `82800507003082b4698ce9d1c3e47c99d0f2f694`.
- [x] [Release-preparation PR #6](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/6) retargeted to `main` after PR #3 was merged; the owner authorised **review/retarget only**. GitHub reported no merge conflicts and the candidate Lua 5.1 and packaging workflows passed at commit `f1e1a3c60fac4f9cb606ddb92a9ec8718f492018`.
- [ ] Obtain **separate explicit owner approval** to merge PR #6 into `main`; this is not permission to publish a release.
- [ ] Rebuild from final merged commit; ensure checksum and in-game smoke-test results match the intended GitHub release asset.
- [ ] Obtain **separate explicit publication approval** before creating the `v0.1.0.28` tag and GitHub **non-prerelease** release with installable ZIP, SHA256 and these scoped notes.
- [ ] Keep all prior pre-release tags/assets unchanged. Update N Addon Collection only after separate approval.

**Never test a real item transfer or alter existing submitted loot decisions just to complete this checklist.** Do not mistake an offline Lua test or simulated award for a verified real item receipt.
