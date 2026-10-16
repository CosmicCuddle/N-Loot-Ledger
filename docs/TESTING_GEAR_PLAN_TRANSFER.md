# Gear Plans Import / Export — First Review Stage

**Branch:** dev/nll-gear-plan-import-export (stacked on unmerged PR #8).
**Status:** Review only. Not installed, published, merged or authorised for live saved-data edits.
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
Statuses: NEEDED, GREED, OBTAINED, DISABLED. The last value **must be 1**; multi-copy rings are a separate future milestone. Source/type are restricted to bot Gear Plans, and role must be an existing NLL role ID. Item IDs must exist in the Molten Core catalogue.

The first version allows up to **250 plans or 48,000 bytes per paste**. Invalid, duplicated or malformed rows, unknown roles/items, manual or player-submitted sources, and old/different status conflicts are rejected before any mutation. If a batch is edited after preview, the confirm button is disabled automatically. No automation, local disk I/O, network transfer, SQL or live loot award is involved.

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
