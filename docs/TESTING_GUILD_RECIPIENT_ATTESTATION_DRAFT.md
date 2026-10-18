# NLL Guild Recipient Self-Attestation — draft #28

**Scope:** Separate, human-confirmed statement from the exact intended
guild loot recipient. NEVER convert a NO RETRY review into delivery
proof, winner receipt, Gear Plan OBTAINED or permission to give an item.

This stage is modeled after recipient authority from
[alternative PR #20](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/20)
but uses a separate append-only record, not overwriting the original audit.

## Distinct meanings

- **LOOT_SLOT_CLEARED:** Loot disappeared; recipient unverified.
- **CLOSED_NO_RETRY:** An actor investigated an uncertain outcome; the
  original physical item remains permanently locked. NOT delivery proof.
- **RECIPIENT_SELF_ATTESTED_BAGS:** The exact intended recipient
  personally states they checked their own bags. NLL also found
  at least the recorded item quantity in their current bags.
  **Not proof the item came from this corpse or Master Loot attempt.**
  Old bag contents may already satisfy the count.

An attestation never automatically releases global uncertainty holds
in GuildLootTransfer:IsUnresolved or authorizes item transfer.

## Interface / commands

- /nll guildreceiptui — separate paged My Bags window.
- Guild Loot -> Investigate -> select GUILD -> My Bag Receipt.
- /nll guildreceipt list
- /nll guildreceipt arm <audit index>
- /nll guildreceipt confirm — within 15 seconds
- /nll guildreceipt cancel

ARM and CONFIRM are separate actions. Selection, page changes, close,
changed character, elapsed time, changed old record fields or
insufficient bag count all fail closed. Only exact UnitName("player")
matching the stored recipient may confirm. Realm-stripped names and
addon messages cannot authorise another client's bag assertion.

## New SavedVariables data — additive ONLY

NaxxLootLotteryDB.guildRecipientReceiptAudit is initialised empty if
absent. Each event holds the exact guild audit index, item ID/link,
quantity, source audit status, actor, recipient, observed bag count,
timestamp, and negative proof flags:

- sourceVerified=false
- deliveryServerVerified=false
- grantsAuthorized=false

No guild original audit, NO RETRY status, Gear Plans, lottery/winners,
receipt tracker, local wishlists or attempt locks are rewritten.

## Owner-approved test checklist (future)

- [ ] Choose controlled session, approve test build separately.
- [ ] Back up matched Interface/AddOns/NaxxLootLottery directory,
      account NaxxLootLottery.lua and NaxxLootLottery.lua.bak (if present).
- [ ] Back up both intended recipient and separate leader clients.
- [ ] Verify original 604 records, 38 bots, 469 NEED and 135 GREED.
- [ ] Wrong officer cannot attest recipient's bags.
- [ ] No required item quantity -> confirmation denied.
- [ ] First click only arms; second appends one human receipt statement.
- [ ] Pre-existing bag stock is NOT proof of item-delivery origin.
- [ ] NO RETRY closure coexists without unlocking any original item.
- [ ] Test paging, multiple identical item IDs, different audit indices,
      timeout, actor change, /reload and closing the modal.
- [ ] Compare exact SavedVariables counts, history and all default OFF
      physical transfer settings against the dated backups.
- [ ] No deliberate re-awards or repeat grants during safety tests.

**No release, merge, installation, real item award or real
recipient-inventory inspection has been performed.**
