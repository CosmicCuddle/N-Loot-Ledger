# Stage C1 — Reconciliation UI test plan (draft)

**Stack:** PR #17 -> #22 -> #23 -> this draft PR. **Do not install yet.**

## Goal

Replace hard-to-remember reconciliation commands with a read-only
investigation window and deliberate NO-RETRY close procedure.

Entry points:

- Award History -> Investigate Transfers
- Current Loot -> Guild Loot -> Investigate
- /nll reconcileui

The window shows old winner and guild Master Loot attempt records,
including request/slot-cleared/unknown status and a distinct "recipient
receipt OBTAINED" display where independently verified. When a recorded
attempt is marked CLOSED_NO_RETRY, its original attempt and winner are
still permanently locked. This closure is NOT evidence of delivery,
receipt, failed delivery or permission for a new award.

## Manual acceptance after user approval and backups

1. Before installing test code, back up both Interface/AddOns/NaxxLootLottery/
   and WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua plus
   .lua.bak when present. Back up the separate human player's client too.
2. Open the new modal from both Award History and Guild Loot; confirm
   no item is sent and no Gear Plan status changes merely by opening.
3. Check paging with 6+ historical requests. Selecting a new row, switching
   pages and closing must cancel any armed NO-RETRY action.
4. Confirm an armed request expires at 15 seconds; changing leader,
   losing raid authority or entering a fake raid must refuse confirmation.
5. Verify UNKNOWN and SLOT CLEARED remain distinct from OBTAINED.
   No-retry review should append one audit event without replacing winners,
   Playerbot Gear Plans, wishlist choices, receipt ACKs or physical item locks.
6. Test a previously recipient-confirmed OBTAINED record. The modal must
   not allow a second NO-RETRY investigation for that confirmed receipt.
7. Test /reload. Armed UI review must not survive, persistent historical
   attempt locks and separate audit entries must survive intact.
8. Reopen the corpse and compare truly different corpses separately.
   A repeated item/slot remains blocked from physical re-award. Never
   test safety by actually giving a duplicate item.

## Automated checks

- Lua 5.1 syntax for addon and test fixtures, full historical regressions.
- UI mock tests for six-plus rows, exact UID targeting, arm/confirm,
  closing, page switching, expiry, authority loss and fake raids.
- Zero GiveMasterLoot calls, zero direct award settings changed.
- Packaging expected dev6, 41 Lua modules. No release or install.

## Unresolved future tasks

- Extend duplicate-item cross-corpse tests with repeated gear/material
  slots and historical write-ahead locks.
- Integrated leader and human-client tests for the physical receipt
  handshake. Add user-friendly visual acceptance evidence and report.
- Do not allow unattended guild transfers while remote reservations
  remain unverified across clients.
