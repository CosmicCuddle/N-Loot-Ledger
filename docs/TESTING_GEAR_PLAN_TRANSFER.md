# Gear Plans Import / Export — First Review Stage

**Branch:** dev/nll-gear-plan-import-export (stacked on unmerged PR #8).
**Status:** Original add-only Import / Export was owner-tested and released as experimental `v0.1.0.29-rc.1` on 16 October. The **NEW paging controls** in this branch remain **review-only, unmerged and not installed or released**. Never modify live saved plans automatically.
**Client:** WoW 3.3.5a / Interface 30300 / Lua 5.1.

## Design and behaviour

Use `/nll` > Wishlists > Gear Plans > **Import / Export**. Export highlights bot plans as text for Ctrl+C. Paste / Import requires Preview Changes and a separate Confirm ADD action. Preview never writes anything.

**This first stage is ADD-ONLY.** Already identical entries are skipped. Changed existing entries are conflicts, and **any conflict blocks the entire batch**. No deletions, status conversions or replacement of an existing Gear Need occur. Global assigned raid roles, wishlist reservations and winner/award history are never changed by import.

## Paste format (eight fields per row)

```text
NLL-GEARPLANS-1
Druzz|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|19147|BOT_GEAR_PLAN|GREED|1
Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|18821|BOT_GEAR_PLAN|NEEDED|1
Gorak|PLAYERBOT|MAIN_TANK|MOLTEN_CORE|18821|BOT_GEAR_PLAN|DISABLED|1
```

Header is mandatory. Each row is: Character | PLAYERBOT | Role | MOLTEN_CORE | Item ID | BOT_GEAR_PLAN | Status | Copy index.
Statuses: NEEDED, GREED, OBTAINED, DISABLED. The importer accepts ASCII and carefully validated Latin-1 UTF-8 character letters, including the actual Raid04 character **TangØ**, without renaming. Invalid sequences and TangØ/Tangø duplicate-key collisions fail closed. The last value **must be 1**; multi-copy rings are a separate future milestone. Source/type are restricted to bot Gear Plans, and role must be an existing NLL role ID. Item IDs must exist in the Molten Core catalogue.

**WoW 3.3.5a clipboard compatibility:** The owner verified on the actual client that pasting a row with seven single `|` separators produces fourteen (`||` between all fields) inside the import EditBox. The importer now accepts exactly seven `|` or exactly seven `||` separators per record, converts doubled delimiters only while parsing, and continues to reject mixed/triple pipes, unknown items/roles/statuses, and duplicate entries. The export text format is unchanged (seven single pipes per row); **do not manually edit all batches to double pipes**. Run Preview Changes first, never Confirm ADD without checking the preview. Strict preview/apply source-text equality remains required.

The first version allows up to **250 plans or 48,000 bytes per paste**. Invalid, duplicated or malformed rows, unknown roles/items, manual or player-submitted sources, and old/different status conflicts are rejected before any mutation. If a batch is edited after preview, the confirm button is disabled automatically. No automation, local disk I/O, network transfer, SQL or live loot award is involved.

## NEW: Safe 604-Plan Export Paging (post-rc.1 review only)

**Why:** The published pre-release `v0.1.0.29-rc.1` refuses one-click export if a Playerbot has more than 250 saved plans. The development branch adds separate **Previous Export** / **Next Export** controls *inside the Import/Export dialog*, below the text box. It does NOT change the Gear Plans six-row pager.

- Clicking **Export Bot Plans** begins a fresh read-only export on **Page 1 / 3** for a 604-plan account, and selects that page's entire text for **Ctrl+C**. The footer shows the page count and the 604-plan total.
- Every page is an independently importable `NLL-GEARPLANS-1` document, with **250**, **250**, and **104** records respectively. Copy each page into a **different** plain-text file, e.g. `NLL-Backup-Part-01.txt`, `NLL-Backup-Part-02.txt`, `NLL-Backup-Part-03.txt`. Do not overwrite one page with another. Preserve the header on **each** page.
- **Next Export** and **Previous Export** select the text on the new page automatically; check each page indicator before Ctrl+C. Do not try to combine all pages into one paste, as the input is still limited to 250 rows and 48,000 bytes per paste.
- Export validates every stored bot plan before producing ANY page; an invalid record blocks the export rather than omitting it. If saved Gear Plans change between pages, further navigation is refused and the text is cleared, with a prompt to restart **Export Bot Plans** on page 1.
- **Paste / Import** remains add-only; clicking it exits export mode and disables paging. None of these steps perform a live loot roll, real award, SQL action, or SavedVariables migration.

### Focused owner check before accepting the new branch

1. Close WoW, preserve the **paired backups** of your known-working rc.1 addon folder and its `NaxxLootLottery.lua` (+ `.bak`). Do not test this on tomorrow's active raid build.
2. Install the newly built **PR #9 TEST-ONLY** artifact in a separate backed-up WoW test directory.
3. Open `/nll` > Wishlists > Gear Plans > Import / Export, and check the page controls are visible **below the text area**, with no overlapping status/footer on your UI scale.
4. On 604 plans, confirm **Page 1/3, Page 2/3, Page 3/3** and copy each page to its own `.txt` file. Verify the counts of **250, 250, 104** and all documents start with `NLL-GEARPLANS-1`.
5. Without saving any additional plans, paste each page into a **fresh backed-up test profile** (or preview against the existing account), and verify no missing/duplicate/conflicting records. **Preview only** is safest for the existing live data, where every record should show **identical**. Do not Confirm ADD for identical or unexpected conflicts.
6. Confirm changing any original saved plan during an export **blocks navigation** instead of mixing two datasets. Test only with expendable fixture data, NOT your 604-plan working profile.
7. Return to the official rc.1 package for the raid if the new controls are not separately accepted. No actual Master Loot delivery test is part of this milestone.

**Offline evidence:** `tests/test_gear_plan_export_pages.lua` exercises 604 synthetic bot plans, all 469 NEED / 135 GREED statuses, the exact `TangØ` UTF-8 name, deterministic 250/250/104 source files, exact restore via three add-only batches, conflicts, stale snapshots, and preservation of roles, personal wishlists and loot histories. `tests/test_gear_plan_transfer_ui.lua` exercises buttons/navigation, Ctrl+C selection and blocked stale export. CI does not prove live WoW visual behaviour.

## Step-by-step test in a spare backed-up game client

**Before installing any experimental build:** close WoW. Copy the current `Interface/AddOns/NaxxLootLottery` folder, and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.lua.bak` if present. Preserve character-level copies where applicable.

1. Open Gear Plans and check all existing reservations, roles and six-row pagination remain correct.
2. Open Import / Export. Export should show existing Playerbot plans selected for Ctrl+C. Copy into a text editor. Verify status/role/item numbers. The export screen cannot save changes.
3. Switch to Paste / Import, paste the unchanged export, and Preview Changes. Expect 0 NEW, 0 CONFLICTS, all unchanged; Confirm ADD stays disabled.
4. Add one harmless temporary bot/item row in the text editor. Preview must show 1 NEW, without yet creating the row. Editing the paste after preview must disable Confirm ADD.
5. Re-preview, then Confirm ADD only for that throwaway entry. It should appear in Gear Plans. Old records must remain untouched. Use `/reload` to confirm persistence. Delete only the throwaway row after verification.
6. Change the status of one already-existing entry in pasted text; Preview must report CONFLICT and prevent the whole import. Also test an invalid role and unknown item.
7. Import must refuse to run with an active fake raid, a pending real lottery or open loot window. Real Master Loot is experimental and must remain OFF.

**Do not perform a real loot transfer to test Import / Export.**

## Automated tests

- `lua5.1 tests/test_gear_plan_transfer.lua` — add-only validation, idempotent roundtrip, conflict safety, malformed rows, stale previews, blocked states and saved-data identity.
- `lua5.1 tests/test_gear_plan_transfer_ui.lua` — the dialog is read-only until the user previews and confirms; text editing cancels confirmation.
- Existing full Lua 5.1 regressions, 40-bot Need/Greed simulator, DB upgrade/reload, Gear Plans layout, and safe ZIP builder must remain green.

## Boundaries and rollback

CI cannot verify your exact WoW font scale, real SavedVariables persistence, or visual interaction. In-client acceptance remains pending.
To roll back, close WoW and restore the working addon folder **and its paired SavedVariables backups** together, then verify roles, reservations, and award history. Never overwrite a live user's data automatically.

Later optional milestones: explicitly confirmed before/after **updates** to existing rows, better export chunking for exceptionally large bot libraries, and per-copy reservations after item uniqueness is verified. Not part of this initial add-only stage.
