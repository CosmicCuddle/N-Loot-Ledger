# Guild Master Loot transfer reconciliation — read-only until human confirmation

Draft only, built on PR #17. No addon installed, item granted, branch merged, tag published or real SavedVariables edited.

## Problem
A Master Loot request (`AWARD_REQUESTED`), uncertain result (`AWARD_OUTCOME_UNKNOWN`) **and even a loot slot clearing (`LOOT_SLOT_CLEARED`) are NOT independent evidence that a recipient received the item**. Before this stage, the last state could stop blocking later unrelated guild transfers despite the missing receipt.

## Implemented

- `Core/GuildLootTransfer.lua`: **all three** unresolved statuses and `INVESTIGATION_HOLD` block a new guild transfer; cleared slots do not imply recipient proof.
- Every new guild transfer attempt now records the acting Master Looter (`actor`) before the WoW request. Existing audit entries without an actor remain available for inspection but **cannot** be reconciled automatically.
- `Core/GuildLootReconcile.lua`: append-only `guildLootReconciliations` SavedVariables. `/nll guildaudit` and the **Guild Loot → Transfer Audit** button open a paged historical audit dialog, even after corpse despawn.
- Only the **original recorded Master Looter** can start review. Current selection must be an exact saved audit entry with intact itemID, item link, recipient and slot. An active lottery or armed guild transfer blocks reconciliation; fake raids are excluded.
- Click **Inspect**, then choose **Verified Received** (only if you independently inspected the recipient inventory/server record) or **Keep On Hold** (receipt cannot be verified), then **CONFIRM RESULT** within 15 seconds. An item/candidate/actor/audit-status change, different index, or expired arm fails closed.
- Verified Received writes an `OPERATOR_CHECKED_RECIPIENT_INVENTORY` attestation, marks **RECONCILED_RECEIVED** and removes the *global uncertain-request hold*. This is a **human assertion**, not client/server independent proof.
- Keep On Hold writes **INVESTIGATION_HOLD** with evidence `OUTCOME_STILL_UNVERIFIED`. The global block stays on; no item is retried.
- Both outcomes preserve the original audit row and append a separate record. Historical `WasAttempted(itemID,slot)` remains TRUE **forever** for that item/slot (even after receipt reconciliation), because WoW 3.3.5a has no trustworthy corpse/source GUID. Reconciliation NEVER opens a second award to the same item/slot.
- Nothing here calls `GiveMasterLoot`, invents a winner, changes Gear Plans to OBTAINED or resets lottery history. The player/bot winning-item receipt path remains the separate PR #16/#17 flow. **No automatic guild routing** enabled.

## Known limits requiring final in-game acceptance

A mistaken human assertion could falsely declare delivery; therefore the interface specifically asks for an independent recipient inventory/server-log check. If a recipient cannot be reached, choose Keep On Hold; this deliberately prevents further guild transfers until independently resolved. Older audit rows missing actor cannot be marked verified via the new panel. Permanent same-item/slot historical lock is intentionally conservative and may block a genuinely new corpse; future unique-corpse sequencing requires its own verified safeguards.

## Tests

- `tests/test_guild_loot_reconcile.lua` exercises legacy/unknown actor refusal, original actor authority, hold vs verified received, 15s expiry, audit tamper refusal, active lottery/armed transfer, append-only timeline, SavedVariables persistence, zero physical transfers.
- `tests/test_guild_reconciliation_ui.lua` exercises six historical entries, two pages, disabled terminal rows, Inspect → choice → Confirm, disarming on pagination, and time expiry.
- Existing `tests/test_guild_loot_transfer.lua` is extended so `LOOT_SLOT_CLEARED` still blocks until human reconciliation; even then the original item+slot remains permanently ungrantable.
- Entire prior Lua 5.1 regression + version/packaging consistency must pass at exact commit.
- Do not install during raids. When approved for final tests, **exit WoW and back up both** `Interface/AddOns/NaxxLootLottery` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.lua.bak`. All existing 604 Playerbot plans and award histories must survive.

No client in-game acceptance or independent physical delivery tests have been performed.
