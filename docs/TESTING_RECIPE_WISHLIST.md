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
```

The last test loads real Molten Core recipe data, confirms classification and existing saved reservation-table identity, filters two lists, checks that guild submission still contains both categories, and tests a lightweight mock of tab switching.

## Back up before in-client review

1. Exit WoW fully. Preserve a dated copy of `Interface/AddOns/NaxxLootLottery`.
2. Save the **matching** `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `.lua.bak` (plus character-level files if they exist).
3. Use a test client/throwaway SavedVariables copy when practical. Do not upload personal saved data to GitHub.
4. Install only the updated `NaxxLootLottery` directory; do not rename the addon folder or database key.

## Safe in-client acceptance (no loot transfers)

- [ ] Open **Wishlists → My Wishlist**. Confirm both subviews fit on the top status row, without covering the item header, eight-row list or pager.
- [ ] With the owner's original four Arcanist pieces reserved: **Gear / Items** lists those four; **Recipes** initially shows zero if none were reserved; combined count still equals four.
- [ ] Open **Raid Loot Search**; search for `Formula: Enchant Weapon - Spell Power` (ID `18259`) and press **Reserve** only once. This *adds one personal wishlist reservation*; do not submit or award any loot.
- [ ] Revisit **My Wishlist → Recipes**. Verify formula is listed here, but not under **Gear / Items**; combined count increases by one while original gear remains.
- [ ] `/reload` and recheck that the recipe is still reserved in **Recipes** and all original gear items remain under **Gear / Items**.
- [ ] To undo this test, click **Remove** on that recipe once; ensure the recipe disappears, combined count returns to four, and original wishlist entries are unchanged. **Do not remove original gear items.**
- [ ] Check NLL 136 optional presets and Direct Master Loot remains OFF. No fake or real award-history changes expected.

## Safeguards

- **Do not click Submit to Leader** simply to exercise visual filtering; that would transmit a real addon submission to the raid leader.
- **Do not click a genuine Master Loot recipient**, enable real awarding or invoke `GiveMasterLoot`.
- If the addon does not load or the layout fails, stop testing; quit WoW and restore the **paired** addon-directory and SavedVariables backups, then confirm original four wishes.

Owner must separately approve merging PRs, updating N Addon Collection, or publishing a stable release.
