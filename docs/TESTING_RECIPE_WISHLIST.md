# NLL — Recipe wishlist category acceptance (unreleased)

**Branch:** `dev/nll-recipe-wishlist-tabs`, built on unmerged `dev/nll-dark-only-ui` (draft PR #2).  
**Client:** WoW 3.3.5a / Lua 5.1, installed folder `NaxxLootLottery`, SavedVariables key `NaxxLootLotteryDB`.  
**Status:** Development-only; no release or actual loot delivery is authorised.

## What changed

- Inside **Wishlists → My Wishlist**, compact **Gear / Items** and **Recipes** controls display separate lists.
- An item is classified as a recipe when the existing Molten Core data marks it `manualReason = "Profession recipe"`; currently includes Plans, Schematics, Formulas, Patterns and Recipes.
- **Gear / Items** contains all remaining reserved items, including crafting materials. An original saved gear wishlist still appears unchanged.
- The same existing personal item-ID reservation table is used. No new SavedVariables schema, migration, personal recipe table, or item deletion.
- **Submit to Leader** continues to submit the entire combined wishlist; leader Inbox and loot-priority handling have not been changed.
- Existing profession recipe allocation remains **manual-only**. This is display separation, not automatic recipe awarding.

## Offline checks

From repository root:

```sh
find NaxxLootLottery tests -type f -name '*.lua' -print0 | xargs -0 -n1 luac5.1 -p
lua5.1 tests/test_loot_identity.lua
lua5.1 tests/test_loot_history_and_bots.lua
lua5.1 tests/test_dark_skin.lua
lua5.1 tests/test_recipe_wishlist.lua
lua5.1 tests/test_overview_wishlist_copy.lua
```

The recipe test loads real Molten Core recipe data, checks unchanged SavedVariables identities, filtering, leader submission and category navigation. The Overview test ensures the old Phase 4 placeholder is gone, with correct guidance for both a normal character and a fake raid.

## Back up before in-client review

1. Exit WoW fully. Preserve a dated copy of `Interface/AddOns/NaxxLootLottery`.
2. Save the **matching** `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `.lua.bak` (plus character-level files if they exist).
3. Use a test client/throwaway SavedVariables copy when practical. Do not upload personal saved data to GitHub.
4. Install only the updated `NaxxLootLottery` directory; do not rename the addon folder or database key.

## Safe in-client acceptance (no loot transfers)

- [x] Owner verbally confirmed the newly installed **My Wishlist → Gear / Items / Recipes** interface works and looks good (13 October 2026); no screenshot supplied or required. This confirms basic navigation/appearance, not yet recipe reservation, count matching, or `/reload` preservation.
- [ ] Note the **current live reservation baseline before any changes**. The latest owner Overview screenshot shows **11 Molten Core reservations** (including Arcanist pieces), not the earlier four. Verify existing items are retained under **Gear / Items**, and any previously reserved recipes are correctly listed under **Recipes**. Combined count must match the pre-install baseline.
- [x] Owner supplied Raid Loot Search screenshot with **Formula: Enchant Weapon - Healing Power** (ID `18260`) and **Spell Power** (`18259`) both showing **Remove**, indicating reserved state. Their creation order and whether either was previously reserved were not established; do not click Remove now.
- [ ] Verify these reserved formulas appear in **My Wishlist → Recipes** and are absent from **Gear / Items**; record the current combined count rather than assuming 11/12.
- [ ] **Visual release blocker:** [Issue #4](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/4) — Raid Loot Search longer formula names overlap Item ID; `MANUAL: PROFESSION RECIPE` priority column wraps beyond comfortable row height. User asked to finish testing first, fix before stable release.
- [ ] Revisit **My Wishlist → Recipes**. Verify the newly reserved recipe appears here, not under **Gear / Items**. The combined count should increase by exactly one from the recorded baseline.
- [ ] Run `/reload`; verify the test recipe remains in **Recipes**, all original gear/items are still listed, and the total count remains one above baseline.
- [ ] To undo the test, click **Remove** only on the recipe newly reserved during this test. Verify it disappears and the combined count returns to the recorded baseline (**11 in the most recent screenshot**, unless changed beforehand). Do not remove earlier reservations.
- [x] Owner's post-install Overview screenshot (13 October 2026) shows **11** locally reserved Molten Core items, **39** raid members, `+ 6 more reserved item(s)` and **`Full list: Wishlists > My Wishlist.`** across two lines without visible overlap/clipping. The old Phase 4 placeholder is absent; real-award safety footer remains.
- [ ] Check NLL 136 optional presets and Direct Master Loot remains OFF. No fake or real award-history changes expected.

## Safeguards

- **Do not click Submit to Leader** simply to exercise visual filtering; that would transmit a real addon submission to the raid leader.
- **Do not click a genuine Master Loot recipient**, enable real awarding or invoke `GiveMasterLoot`.
- If the addon does not load or the layout fails, stop testing; quit WoW and restore the **paired** addon-directory and SavedVariables backups, then confirm the full original wishlist baseline.

Owner must separately approve merging PRs, updating N Addon Collection, or publishing a stable release.
