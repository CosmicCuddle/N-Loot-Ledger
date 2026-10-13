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
lua5.1 tests/test_search_layout.lua
lua5.1 tests/test_inbox_layout.lua
```

The recipe test loads real Molten Core recipe data, checks unchanged SavedVariables identities, filtering, leader submission and category navigation. The Overview test ensures the old Phase 4 placeholder is gone, with correct guidance for both a normal character and a fake raid.

## Back up before in-client review

1. Exit WoW fully. Preserve a dated copy of `Interface/AddOns/NaxxLootLottery`.
2. Save the **matching** `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `.lua.bak` (plus character-level files if they exist).
3. Use a test client/throwaway SavedVariables copy when practical. Do not upload personal saved data to GitHub.
4. Install only the updated `NaxxLootLottery` directory; do not rename the addon folder or database key.

## Safe in-client acceptance (no loot transfers)

- [x] Owner verbally confirmed the newly installed **My Wishlist → Gear / Items / Recipes** interface works and looks good (13 October 2026); no screenshot supplied or required. This confirms basic navigation/appearance, not yet recipe reservation, count matching, or `/reload` preservation.
- [x] Owner's post-`/reload` Recipes screenshot (13 October 2026) shows **15 total** reserved items: **11 Gear / Items and 4 Recipes**. Four recipes display correctly. Owner then checked Gear / Items and provided page 1/2 screenshot showing expected equipment (including Arcanist Bindings, Boots, Crown and Gloves) and **no recipes** on the visible page; owner confirmed the separation looks correct. Earlier 11-item baseline is no longer the current total.
- [x] Owner supplied Raid Loot Search screenshot with **Formula: Enchant Weapon - Healing Power** (ID `18260`) and **Spell Power** (`18259`) both showing **Remove**, indicating reserved state. Their creation order and whether either was previously reserved were not established; do not click Remove now.
- [x] Both reserved enchanting formulas (Healing Power ID 18260 and Spell Power ID 18259) appear in the **Recipes** subview alongside Pattern: Core Felcloth Bag (21371) and Pattern: Flarecore Wraps (18265); 4 recipe rows are visible with `Remove` controls and no obvious row overlap. The Gear / Items subview still needs explicit exclusion confirmation.
- [x] Owner verbally reported Raid Loot Search's previous text overlap **seems fine** after installing the development version (13 October 2026). The code fix and layout regression test pass, but no dedicated post-fix screenshot was supplied; keep issue #4 evidence qualified.
- [x] **Issue #5, Inbox overlap — owner visually accepted the updated development build (13 October 2026).** Existing screenshot documented the Pikeotter 7-item review with a footer overlap; update displays 4 submitted items per page, shorter Previous/Next captions and wider page-counter space. Owner's subsequent report: 'Yep looks all good now.' This is **verbal confirmation only** (no independent after-fix screenshot); it confirms perceived layout readability, not acceptance/rejection behavior or verified recipient receipt. `tests/test_inbox_layout.lua` passes 17 non-destructive and 4+3 pagination assertions.
- [x] Owner verified the Recipes view after reload; four matching recipe names and sources displayed, and count 11 + 4 = 15. Explicit visual confirmation of exclusion from Gear / Items remains pending.
- [x] Owner reports completing `/reload` and that reserved recipes persist, supported by the subsequent Recipes screenshot with all four recipes and 15 total. This does not independently show all 11 individual Gear / Items entries post-reload.
- [ ] Do **not** remove any of the four reserved recipes: user has not identified them as disposable test entries. Any future test cleanup requires explicit identification of a newly created test-only reservation.
- [x] Owner's post-install Overview screenshot (13 October 2026) shows **11** locally reserved Molten Core items, **39** raid members, `+ 6 more reserved item(s)` and **`Full list: Wishlists > My Wishlist.`** across two lines without visible overlap/clipping. The old Phase 4 placeholder is absent; real-award safety footer remains.
- [ ] Check NLL 136 optional presets and Direct Master Loot remains OFF. No fake or real award-history changes expected.

## Safeguards

- **Do not click Submit to Leader** simply to exercise visual filtering; that would transmit a real addon submission to the raid leader.
- **Do not click a genuine Master Loot recipient**, enable real awarding or invoke `GiveMasterLoot`.
- If the addon does not load or the layout fails, stop testing; quit WoW and restore the **paired** addon-directory and SavedVariables backups, then confirm the full original wishlist baseline.

Owner must separately approve merging PRs, updating N Addon Collection, or publishing a stable release.
