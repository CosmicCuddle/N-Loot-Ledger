# NLL dark-only UI — development branch testing and rollback

**Branch:** `dev/nll-dark-only-ui`  
**Base:** `main` at `6afe667d698ab5c4ea7b2008354b78b2df2e7d0d` (13 October 2026)  
**Release status:** NOT merged or released. Existing `v0.1.0.27` is unchanged.  
**Scope:** `UI/SkinManager.lua`, `UI/SettingsFrame.lua`, `Storage/Database.lua`, documentation and offline regression tests. No loot-award, lottery, communication or raid-priority behavior changes.

## 1. Backup gate (required before in-game installation)

1. **Exit World of Warcraft fully.**
2. Copy the entire existing `Interface/AddOns/NaxxLootLottery/` to a dated, separate backup location.
3. Copy `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `NaxxLootLottery.lua.bak` if present, plus any matching character-specific SavedVariables, to the same dated backup set.
4. Retain these paired backups until acceptance. Do not post private SavedVariables to public GitHub issues.
5. For development testing, ideally use a **copy of the client and test SavedVariables**, not the only live copy. Do not run tests while WoW is open.

## 2. Offline Lua 5.1 checks

Run from the repository root with a Lua 5.1-compatible interpreter:

```sh
find NaxxLootLottery tests -type f -name '*.lua' -print0 | xargs -0 -n1 luac5.1 -p
lua5.1 tests/test_loot_identity.lua
lua5.1 tests/test_loot_history_and_bots.lua
lua5.1 tests/test_dark_skin.lua
```

The `NLL Lua 5.1 regression tests` GitHub Actions workflow runs these checks on development-branch pushes and pull requests. **Do not mark the milestone complete until the latest HEAD has a passing run.** Offline mocks cannot prove correct 3.3.5a rendering.

## 3. Safe WoW 3.3.5a visual acceptance

1. Install the development branch **only after backup**, preserving the installed folder name `NaxxLootLottery` and the SavedVariables key `NaxxLootLotteryDB`.
2. Start WoW and confirm `/nll version` still says `0.1.0.27`; `/nll status` should say READY. This is a development source checkpoint, not a new published version.
3. Open `/nll settings`: tabs should be **Priority Setup**, **Debug Lab**, **Loot Awards**, **Award History**. There should be no Appearance tab or Vanilla skin option.
4. Check **Priority Setup**, **Wishlists**, **Raid Loot Search**, **Raid Roles**, **Current Loot**, **Debug Lab**, **Loot Awards** and **Award History**: backgrounds, hover/active buttons, text, row spacing, and scrolling should match the existing NLL Dark presentation without parchment, overlap or missing controls. In Priority Setup, verify that **Disable Presets** and its explanation now sit **fully above the bottom border** with a small margin, and that the statistics and paging controls remain visible. Do **not** click Disable Presets while inspecting the layout.
5. Check that previously saved priorities, roles, gear needs, wishlists, loot identity, winners and award history remain present. Only `settings.skin` may normalize to `DARK`; `directMasterLootEnabled` must still reset OFF.
6. If Debug is already ON, leave it ON; otherwise toggle `/nll debug` once. Run `/nll sim mc40`, inspect the 40 fake members, 13 fake drops, an expendable fake ticket/roll and fake award, then `/nll sim stop`.
7. **Do not activate Direct Master Loot, click a real item recipient, call `GiveMasterLoot`, or clear/replace real SavedVariables.** No live transfer is authorised for this UI milestone.
8. Capture screenshots of Settings, Wishlists and one dark table view (plus any defects) for the owner to review before merge.

## 4. Rollback

1. Exit WoW.
2. Remove the development addon folder from the test client and restore the **matching pre-test** addon-folder backup.
3. Restore the paired `NaxxLootLottery.lua` / `.lua.bak` SavedVariables copies from the same date and any matching character copies.
4. Restart WoW and verify `/nll status`, gear plans and recorded history. Never revert only code while leaving newly migrated SavedVariables without evaluating compatibility.

## 5. Acceptance / evidence

- [x] Lua 5.1 regression workflow passed on development-source commit `a00e88cc` ([run](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/38396113585)); re-check if source changes again
- [ ] Full WoW 3.3.5a UI check passes at the owner's actual UI scale (remaining panels not yet inspected)
- [x] Priority Setup footer visually retested by owner on 13 October 2026: Disable Presets button and explanation fit inside panel; statistics, four item rows and pagination remain visible. 136 presets shown enabled. Screenshot evidence provided in development conversation; no preset toggle was performed.
- [ ] No Vanilla option/artwork and existing Dark appearance retained
- [x] My Wishlist panel visually checked by owner on 13 October 2026: four existing Molten Core entries (Arcanist Belt, Bindings, Boots, Crown) visible; item/source columns, paging and Submit to Leader controls display correctly. Owner reports existing wishlist retained; no add/remove/submit performed.
- [x] Gear Plans empty-state visually checked by owner on 13 October 2026: character/type/role/source/item fields, filtering, Add Need, list header and pagination visible with no apparent clipping. `0 saved Gear Need(s)` matches owner's statement that no Playerbot plans had previously been created; no persistent entries were added.
- [x] Debug Lab panel visually checked in owner's WoW 3.3.5a client on 13 October 2026: scenario controls, class dropdown, action buttons and status text displayed without obvious overlapping or clipping. Simulator not yet started; owner suggested a future raid-size-focused layout instead of prominent Mage Contest scenario controls.
- [ ] SavedVariables and award history preserved
- [x] Owner screenshot confirms in-client MC40 simulator displays `[SIMULATION - FAKE RAID]`, Raid Roles `40 bots / 8 groups`, and `Page 1 / 4` with visible fake member classes, group assignments and NLL roles. Only first roster page was inspected; other pages, all 13 simulated drops, and fake roll/award remain untested.
- [x] Owner inspected **Current Loot** during active MC40 simulation on 13 October 2026: 13 fake boss drops, first five visible on page 1/3, matching character/role/presence/priority columns with Gauntlets of Might showing three in-raid candidates (SimWar1 tier 1; SimWar2/SimWar3 tier 2), no apparent layout clipping. Built-in suggestion correctly marked not saved. **Preview/prepare/roll/award not yet exercised in this test.**
- [x] Owner screenshot confirms **Preview Pool** on first MC40 simulated Gauntlets of Might drop: message `Tier 1 has 1 equal-priority candidate(s); 2 waiting; 0 excluded. Preview only: no roll or award.` Chat log reports `Pool 1: SimWar1`. This verifies the visible highest-tier selection, not ticket preparation or a roll. No real transfer occurred.
- [ ] Simulator passes without live award effects
- [ ] Backup and rollback instructions verified on the test copy
- [ ] Owner explicitly authorises any merge/release

Record actual observations; do not convert offline test PASS into a claim of live Master Loot delivery.
