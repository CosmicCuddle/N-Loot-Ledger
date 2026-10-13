# Naxxramas Loot Ledger v0.1.0.28

**Prepared release notes — NOT PUBLISHED.** Proposed first **non-prerelease (stable-core)** build for WoW **3.3.5a / AzerothCore**. Release name/tag `v0.1.0.28` is reserved only for consideration; no tag or release exists yet.

## Changes since published v0.1.0.27

- **One consistent Dark interface.** Removed obsolete Vanilla/Classic appearance choice. Existing saved UI preferences are normalized to Dark without resetting gear needs, priorities, raid roles, saved loot identities or award history.
- **Separated recipes from equipment.** `Wishlists → My Wishlist` now has **Gear / Items** and **Recipes** subviews. Profession recipes remain **manual allocation**, not auto-awarded. Both categories stay in the same original saved wishlist and are included together in `Submit to Leader`.
- **Cleaned up Overview.** The obsolete “Full wishlist view coming in Phase 4” text now directs players to `Wishlists → My Wishlist`.
- **Improved priority controls.** Fixed the Priority Setup preset button/footer position at the tested client font size.
- **Improved Raid Loot Search readability.** Long formula titles and Item IDs use separate lines; compact `Manual` priority labels show the full policy on hover.
- **Improved Wishlist Inbox readability.** Item review now displays four submitted items per page, with a separate, clearer Previous/Next footer. Submission acceptance and rejection behavior is unchanged.
- **Retained 40-player Molten Core simulation.** Fake awards remain session-only and do not perform item transfers or create real award receipts.
- Added automated WoW 3.3.5a / Lua 5.1 regression coverage for UI layout, recipe categorization, submission compatibility, loot-opportunity recovery and simulated award safety.

## Validation evidence and boundaries

**Observed in the owner's game client:**
- NLL initialized READY under v0.1.0.27 before the candidate version update; 39-member raid detected and role assignments persisted across `/reload`.
- A 40-player/13-drop **fake** Molten Core simulation completed a fake winner and fake award; no real item was moved.
- Current saved wishlist after recipe separation had **15 reservations: 11 Gear / Items, 4 Recipes**. Recipe reservations survived `/reload`.
- Owner approved corrected Overview, Priority Setup, Raid Loot Search and Inbox display. Inbox fix approval was verbal, not a new screenshot.
- Direct Master Loot was confirmed **OFF** after simulation. The release candidate version/ZIP still needs its own final WoW smoke test.

**Not certified / do not infer from the above:**
- Real boss corpse/loot-list observation, same-looking multi-corpse A → B → A recovery and duplicate-item ambiguity under live raid conditions have **not** been fully validated.
- NLL winner identity/award logs are not independent evidence that a player/Playerbot received an item.
- Real Playerbot Gear Plan matching and physical inventory delivery are **not** validated across AzerothCore installations.
- `GiveMasterLoot` delivery via NLL has **not** been tested. **Direct Master Loot is experimental**, remains **OFF on every login or `/reload`**, requires explicit separate opt-in and confirmation, and must not be treated as stable-certified functionality.

## Installation and rollback

See [INSTALL-v0.1.0.28.md](INSTALL-v0.1.0.28.md) for exact paired backup/rollback instructions. The installable artifact should contain **one top-level `NaxxLootLottery` directory** with `NaxxLootLottery.toc`, not a whole source repository. Preserve `NaxxLootLotteryDB` and the existing `/nll` commands.

**Before a public release:** install and smoke-test the exact release-candidate ZIP, verify checksums and direct-award defaults, review outstanding [loot identity issue #1](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/1) plus display issues [#4](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/4) and [#5](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/5). A GitHub “stable” label must not suggest that these untested paths are certified.

Do not upload SavedVariables, raid history or account information to GitHub. **This file is not approval to merge, tag, publish or transfer loot.**
