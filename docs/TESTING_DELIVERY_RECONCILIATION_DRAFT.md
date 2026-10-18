# Draft PR #18 — Delivery reconciliation and write-ahead lock

Stack: #10 -> #12 -> #13 -> #14 -> #15 -> #16 -> #17 -> #18.

This is developer code, NOT installed and not confirmed in a real WoW raid.

## What is new

- Direct winner Master Loot attempts are recorded BEFORE calling WoW in a persistent drop-UID lock and history.
- If the API throws or reload happens, the outcome remains AWARD_OUTCOME_UNKNOWN; no NLL retry. Success only means AWARD_REQUESTED, not receipt.
- The read-only reconciliation ledger distinguishes requested, slot cleared, unknown and a separately confirmed recipient.
- /nll reconcile list shows winner and guild attempts, without mutations.
- /nll reconcile winner <dropUID> or /nll reconcile guild <auditIndex> arms a 15-second review with current real raid authority.
- /nll reconcile confirm is a second deliberate command. It adds a separate audit event and marks the review CLOSED_NO_RETRY while retaining the original status.
- Closing an investigation can release the GLOBAL block on unrelated guild items, but permanently retains the original winner UID and guild item/slot attempt lock.
- /nll reconcile cancel disarms. Reload does not preserve an arm.

## Distinct states

| State | Meaning |
|---|---|
| AWARD_REQUESTED | WoW API invoked; no physical delivery proof |
| LOOT_SLOT_CLEARED | Slot disappeared; no recipient proof |
| AWARD_OUTCOME_UNKNOWN | Exception or missing observation; never retry |
| CLOSED_NO_RETRY | Human reviewed; original attempt permanently locked |
| OBTAINED | Recipient inventory explicitly confirmed in existing receipt workflow |
| Player ACK | Separate client accepted its personal wishlist notification |

CLOSED_NO_RETRY is NOT evidence that an item did or did not arrive.

## Acceptance / backups

Before in-game testing, back up all of:
1. Interface/AddOns/NaxxLootLottery/
2. WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua
3. WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua.bak (if present)
4. Separate recipient-client SavedVariables if testing remote ACK.

Run Lua 5.1 regressions including simulated Master Loot API errors, saved audit retention, reload, the UI and packaging. No unknown physical item should ever be reissued. A genuinely different corpse requires its own New Drop confirmation; it does NOT bypass an earlier attempted item lock.

Unattended guild routing is not enabled. Both direct award and guild transfer opt-ins remain OFF after login. No merge, release, installation or live SavedVariables modification is authorized.
