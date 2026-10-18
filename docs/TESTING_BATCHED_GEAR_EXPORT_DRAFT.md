# NLL — Safe Multi-Batch Playerbot Gear Plan Export (Draft #31)

**Draft-only dev build:** 0.1.0.29-rc.1-dev13.  
**Based on:** #30. **Live HF2 remains installed.**  
**Goal:** Export all 604 saved Playerbot plans without truncation, overwriting records or changing the original NLL-GEARPLANS-1 import format.

## What was built

- Existing single-batch `GearPlanTransfer:Export()` still refuses >250 rows instead of silently dropping the rest.
- New **read-only** `GearPlanTransfer:ExportChunk(page)` sorts and validates the **entire set** before returning any one batch.
- Each batch includes an independent `NLL-GEARPLANS-1` header and at most **250 rows** and **48,000 bytes**, preserving the established import/clipboard limits.
- Deterministic order: character, item ID, then status. For the 604-row example: **Batch 1/3 = 250**, **Batch 2/3 = 250**, **Batch 3/3 = 104**.
- Import / Export window adds **Prev Batch**, **Next Batch** and visible `Batch X/Y` label. Clicking either in export mode selects and highlights only that section for **Ctrl+C**.
- Switching to **Paste / Import** disables export paging. A disabled button action cannot change the pasted import text or enable Confirm ADD. The existing import parser, conflict check, preview, write consent and add-only semantics are unchanged.
- Invalid late records block **every** batch, so page 1 cannot falsely look like a complete export if page 3 contains invalid saved data. Export errors clear the displayed text rather than leaving a misleading partial backup.
- UI and core export are not file I/O, and no CSV/file is written by the addon. **The user must copy all batches separately** and preserve their order and individual headers.

## Future owner-approved backup and acceptance steps

1. Before any new development build is installed, copy the complete `Interface/AddOns/NaxxLootLottery/` directory.
2. Back up the actual per-account `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `.lua.bak` if present. Do the same on any other client's account. **This remains the authoritative rollback**, not the export text.
3. Confirm actual baseline: **604 records / 38 Playerbots / 469 NEED / 135 GREED**, and preserve the original character names, roles, wishlists, receipts and loot history.
4. In a **separately authorised controlled WoW test**, open Gear Plans → Import / Export. Check page counter **1/3**, copy and save to separate text files labelled `NLL-Batch-1-of-3.txt`, `NLL-Batch-2-of-3.txt`, `NLL-Batch-3-of-3.txt`.
5. Verify page 1 and 2 each have 250 entries and page 3 has 104 entries; each should contain `NLL-GEARPLANS-1` as the first line and each should stay below the 48 KB limit.
6. Verify Prev/Next buttons have clear states, highlight current section and do not overlap the edit box or the import controls at the **actual WoW UI scale**.
7. Verify switching to Import turns off page navigation; Preview Changes is required before Confirm ADD, and the original 604 rows have not changed after export.
8. If desired, **preview only** each saved batch (do NOT Confirm ADD): each should report **0 new / N unchanged / 0 conflicts** in a test client containing the same 604 records. A 3.3.5a Ctrl+V may double pipe separators: existing import code accepts consistently doubled separators.
9. Compare real SavedVariables, roles, loot receipts, lottery history and character counts to backups. Record screenshots and the actual exported text length.
10. Only owner approval may authorise additional installation, data changes, merges or releases.

**Important limitation:** Individual independently exported batches are useful backups of **Playerbot Gear Plan rows**, but they do not include personal wishlists, leader settings, winning history, receipts or all SavedVariables. Never substitute the batch export for the full account SavedVariables backup.

## Automated checks

- [x] Lua 5.1 tests of exact 604 synthetic bot rows with 469 NEED / 135 GREED, no truncation/duplicates, deterministic order, roundtrip `Parse` and no write.
- [x] 3.3.5a mocked window tests for Prev/Next, section label, Ctrl+C ready selection, Export-to-Import isolation and no ability to Confirm ADD while merely exporting.
- [ ] Verify exact-head dedicated CI and full historical regression checks.
- [ ] Real 3.3.5a in-game font/clipboard screenshots with owner authorisation.

**No merge, release, install, SQL/core change or actual item award is part of this stage.**