# Pending real winner receipt / remote acknowledgement safeguard

**Development-only hardening stacked after [draft PR #19](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/19).** This is not installed, merged, published, or an authorization to grant loot automatically.

## Why an item can look unreserved when it isn't

In NLL the original ticket winner may remain `WON_AWAITING_ITEM` while the character's saved Gear Plan has been replaced by a later wishlist submission. Checking only current `gearNeeds` can therefore falsely label the next copy `GUILD_REVIEW`.

A second gap happens after the leader checks a human recipient and marks the leader-side Gear Plan `OBTAINED`, but the remote human player's own Receipt Inbox is still waiting for an acknowledgement (`AWAITING_PLAYER`, `WAITING_FOR_PLAYER`, `SEND_FAILED`). That is **not** enough to conclude the recipient's account has acknowledged the receipt.

## Fail-closed review

Before classifying ANY visible new copy as guild-review loot, `GuildLootReview:GetReservationSummary(itemID)` also checks the durable `lootReceiptTracker` entries for the **same item ID**:
- `WON_AWAITING_ITEM` → `UNRESOLVED` hold even if the original Gear Plan was deleted/replaced.
- `OBTAINED` + a nonempty, non-`ACKNOWLEDGED` remote synchronization state → `UNRESOLVED` hold while the player remains unconfirmed.
- `OBTAINED` + `ACKNOWLEDGED` or a bot/local receipt with no remote synchronization requirement → no *extra* receipt hold; other existing reservation and transfer checks still apply.

A hold applies to both the manual Guild Loot review and the auto-routing **dry-run** proposal through the shared read-only scanner. The interface reason explicitly warns that a pending winning receipt or player ACK blocks guild routing.

No message, UID reset, auto roll, transfer, `GiveMasterLoot`, Gear Plan mutation or new SavedVariables table is introduced. This can be conservative on repeated common materials/items; the final in-client testing must establish correct accounting without ever duplicating an earlier award.

## Validation and acceptance

`tests/test_guild_pending_receipts.lua` uses real `GuildLootReview`, `GuildAutoPreview` and `GuildLootTransfer:Validate` with mocked 3.3.5a APIs. It checks both manual and preview hold paths, orphaned real winners, remote ACK pending/offline/send-failed, positive ACK recovery, unrelated items, corpse closure, zero physical award calls, and no data/history mutations.

All existing Lua 5.1 regression tests plus package smoke-check must pass on exact branch head. No test build is provided to the raid user until the final integrated testing stage, after paired backups of the addon and current SavedVariables (including all 604 Playerbot plans).
