# v0.1.0.28 — First stable-core release checklist

**State: release candidate under review; NOT APPROVED TO PUBLISH.** Scope agreed by owner 13 October 2026: stable **verified core** with unverified Direct Master Loot explicitly **experimental and OFF**. This list distinguishes prior in-game observation, source tests, and remaining release gates.

## Completed evidence

- [x] Owner chose tag/version `v0.1.0.28` for release **preparation** (not merge/publication).
- [x] WoW 3.3.5a UI checks: Overview, My Wishlist, Gear Plans, Recipes, Raid Loot Search, Priority Setup, Debug Lab, Current Loot, Award History, Inbox (including post-fix visual acceptance).
- [x] Owner verified 15 saved wishlist reservations (11 Gear / Items; 4 Recipes), and Recipes persisted through `/reload`.
- [x] Real 39-person raid roster showed correct names/classes/statuses and NLL roles persisted through `/reload`.
- [x] Fake MC40 lottery and fake award completed without actual loot transfer; real Award History showed 0 during the test.
- [x] Direct Master Loot was OFF when observed after the tests; code resets it on each DB initialization.
- [x] Pre-release workflows `publish-v0.1.0.25–27-prerelease.yml` remain unchanged; **no** new release auto-publication pathway is enabled.

## Candidate preparation (no permission to publish)

- [x] Bump internal `NLL.version` and `## Version` to 0.1.0.28 on separate review branch, preserving `NaxxLootLottery` / `NaxxLootLotteryDB`.
- [x] Write release notes, install/rollback instructions and a reproducible addon-only package script.
- [x] Add read-only candidate CI with Lua 5.1 tests and a downloadable workflow artifact, **without any tag/release creation**.
- [x] Automated [candidate CI run](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/38433305898) passed and created `Naxxramas-Loot-Ledger-v0.1.0.28-REVIEW` artifact (ZIP + SHA256SUMS). ZIP verifier confirmed exactly 32 Lua modules + one TOC, a single `NaxxLootLottery` folder, no WTF/SavedVariables, matching internal/TOC versions and OFF-by-default direct awarding. ZIP SHA256: `1f1158cd66d0d76dd578451f018508ee6a8d2cfdcc8428a711b63370cccf755d`.
- [ ] Before recommending installation, manually inspect/download the exact candidate artifact from successful branch HEAD; a fresh run on updated documentation may have a different run ID but should produce the same ZIP hash if addon sources are unchanged.
- [x] Owner installed the candidate build and provided a real WoW chat screenshot showing `[NLL] Naxxramas Loot Ledger version 0.1.0.28` and `[NLL] Initialization status: READY.` (13 October 2026). No NLL Lua error is visible in this screenshot; this is not an exhaustive error check.
- [ ] Finish the **candidate** WoW smoke-test: confirm saved 15 wishlist entries (11 Gear / Items, 4 Recipes), role assignments/presets, Direct Master Loot OFF, and no unwanted real-history changes. Confirm the exact install source was the validated candidate ZIP, if necessary.
- [ ] Perform/approve a matched-addon-and-SavedVariables restore rehearsal on an **expendable** copy (not production), or explicitly document why deferred.
- [ ] Resolve owner-reviewed Issue #4 / #5 closure disposition; leave unrelated [Issue #1](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/1) open as a clearly documented known limitation unless real live-raid testing supports closure.
- [ ] Decide explicitly how to disclose deferred real boss loot observation, multi-corpse recovery and bot eligibility, without claiming real item delivery.

## Publication requires new, separate approvals

- [ ] Review and explicitly approve **draft PR #2** (Dark-only UI); merge only after approval.
- [ ] Review and explicitly approve **draft PR #3** (recipe and UI fixes); then retarget from PR #2's branch to `main` if appropriate and merge only after approval.
- [ ] Review and explicitly approve [**release-prep draft PR #6**](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/6); merge only after approval.
- [ ] Rebuild from final merged commit; ensure checksum and in-game smoke-test results match the intended GitHub release asset.
- [ ] Obtain **separate explicit publication approval** before creating the `v0.1.0.28` tag and GitHub **non-prerelease** release with installable ZIP, SHA256 and these scoped notes.
- [ ] Keep all prior pre-release tags/assets unchanged. Update N Addon Collection only after separate approval.

**Never test a real item transfer or alter existing submitted loot decisions just to complete this checklist.** Do not mistake an offline Lua test or simulated award for a verified real item receipt.
