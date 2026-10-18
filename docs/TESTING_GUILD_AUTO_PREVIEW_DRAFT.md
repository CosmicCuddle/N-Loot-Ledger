# Draft PR #23: Guild allocation dry-run (Stage B)

Based on draft PR #22. The UI now has a visible DRY RUN ON/OFF button
inside Guild Loot, with a matching /nll guildpreview on|off|show command.

## Interpretation

- PROPOSE_TO_LEADER = a live item slot with no reservations in the LOCAL
  available leader ledger. Propose this quantity and loot slot to the
  current unique raid leader for HUMAN reservation verification.
- HOLD_RESERVED = existing NEED or GREED; never route.
- HOLD_UNCERTAIN = missing item data, unsubmitted personal wishlist,
  pending Inbox or other unknown status.
- HOLD_SPECIAL = quest, legendary or manually designated item.
- HOLD_LOCKED = locked/empty slot.
- HOLD_PREVIOUS_ATTEMPT = an earlier physical winner or guild award request
  for that item and slot, even if a human closed investigation NO RETRY.
- HOLD_UNRESOLVED_REQUEST = another request remains unknown; investigate first.

Everything is PROPOSAL ONLY. Every row has transferAuthorized=false and
autoEligible=false; no automatic Master Loot, timers or award confirmations.

## Limitations

WoW 3.3.5a cannot guarantee that another human player's client has no
unsent reservations, even when the leader's local ledger shows zero.
Consequently PROPOSE_TO_LEADER is NOT a machine-verifiable proof of an
unreserved item. Further remote verification and gameplay acceptance
checks are needed before any true automatic distribution could be safe.

Preview supports materials, reagents, equipment, BoE and recipes in the
same conservative way: these may be proposed only when their metadata
is known and they have no saved reservation; special items are held.
No guessed item or recipient is used if loot closes or raid leadership
is absent/ambiguous. Preview does not verify Master Loot candidate indices.

## Test / installation policy

This development version is 0.1.0.29-rc.1-dev5 with 40 Lua modules.
Run all Lua 5.1 regressions and read-only packaging checks, then test
the dialog with a backed-up client in a future controlled raid. Back up:

- Interface/AddOns/NaxxLootLottery/
- WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua
- WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua.bak if present

No existing 604 bot Gear Plans, local wishlists, winners, roles, raid
history or receipt ACKs are replaced. Preview opt-in and both real
Master Loot/guild transfer opt-ins reset OFF each login.
No auto transfer, release, merge or live installation is authorized.
