# Human Player Receipt Synchronization — draft PR #17

**Not installed. Not merged.** This stage builds on draft PR #16 (server-roll winner -> leader-verified OBTAINED). It is NOT part of the owner's visually tested HF2 raid addon, and is NOT certified to handle live Master Loot delivery.

## What problem this solves

The leader's Gear Plans are stored in the leader's WoW SavedVariables. A human player's **My Wishlist** is in a different WoW client's SavedVariables. Changing the former does not change the latter. This draft adds an **explicit two-client confirmation**.

### Real flow (requires NLL dev3 on both clients)

1. An NLL server lottery selects a real winner. Existing PR #16 creates `WON_AWAITING_ITEM`, without hiding anybody's NEED/GREED reservation.
2. Leader awards physical item through the separately tested WoW Master Loot workflow. NLL's award event is **not** independent proof of delivery.
3. **Leader independently checks the recipient actually has the item**. Their existing two-click Confirm Receipt changes only the leader's matching Gear Plans to OBTAINED.
4. If the winner is a **human player** with an accepted `PLAYER_SUBMITTED` plan or a row typed PLAYER, NLL sends a targeted `R1|OBTAINED|<dropUID>|<itemID>|MOLTEN_CORE|<recipient>` addon WHISPER. Playerbots do **not** receive this message.
5. Receiving the whisper merely adds a saved **AWAITING_PLAYER** message to the recipient's own `localReceiptSyncPending` table, visible from **My Wishlist → Receipts (N)** or `/nll receiptinbox`. The player's NEED/GREED stays **unchanged**.
6. **The recipient checks their OWN inventory**, then clicks **I Have the Item → MARK OBTAINED** within 15 seconds. Only the matching character/item/raid is updated in that client's sparse `localWishlistObtained` map. Original boolean wishlist and GREED status are retained. The player sends `R1|ACK|dropUID|itemID|MOLTEN_CORE` back to the leader.
7. The leader validates that acknowledgement came from the originally confirmed winner in their current raid and marks their receipt ledger `ACKNOWLEDGED`. No extra loot grant or ticket roll takes place.
8. If the player is out of raid/offline at initial notification, the leader can resend the **already-confirmed** notification when reunited using `/nll receiptsync L<generation>:<serial>:<itemID>`. If the ACK was lost, replay resends the ACK **only**, without duplicate status changes.

## Trust, safety and compatibility

- WoW 3.3.5a `CHAT_MSG_ADDON` messages are **not cryptographically authenticated**. The recipient must verify the sender is their **unique current raid leader**, that both people are in the raid, that the message is a private addon WHISPER, and that it names **their own character**, a strictly parsed saved dropUID and exactly one active local NEED/GREED reservation for that item.
- **No unsolicited item addition. No automatic OBTAINED from a message. No real `GiveMasterLoot` or SQL call from synchronization.** Only the recipient's explicit two-click inventory confirmation changes their own SavedVariables.
- Changing raid leaders or personal reservation after the offer causes confirmation to stop without edits. Wrong item, wrong target, spoofed nonleader sender, a broadcast, malformed drop ID, fake loot and duplicate/replayed offers are rejected or made harmless.
- Old HF2/dev1/dev2 clients ignore the `R1` message. Both leader and player require this dev3 protocol to fully synchronize; never downgrade GREED or auto-overwrite other clients.
- The leader does **not** modify another client's personal files. Leader Gear Plans are already OBTAINED before the notification; lack of ACK merely remains an outstanding synchronization state.
- **Privacy:** itemID, character and dropUID are sent directly through in-game addon whisper, not published to RAID chat.
- In this early draft, recipients must still be in a raid with the same raid leader to accept. Receipts from old raids cannot be accepted safely offline, but a leader can resend during a future raid.
- A leader receipt is a **human attestation**, not independent proof from the server that the item was added to inventory.
- NLL's current one-reservation-per-item model does **not** handle multiple required copies of unique/nonunique rings/trinkets. That needs a separately designed copy-count feature.

## New or modified files

- `Core/ReceiptSync.lua`: explicit `R1` targeted whisper + ACK handling, pending/done SavedVariables, leader/recipient/reservation/identity checks and replay-safe resends.
- `UI/ReceiptSyncFrame.lua`: paginated pending receipt review and separate two-click confirmation, each expiring after 15s.
- My Wishlist receipt count button and slash commands `/nll receiptinbox` and `/nll receiptsync <dropUID>`.
- The existing `LootReceiptTracker:ConfirmReceipt` calls the sync notifier only **after** leader receipt confirmation, never on a winning roll.
- Distinct branch test version `0.1.0.29-rc.1-dev3` with **38 addon modules**. All real transfer consent flags still default OFF.

## Tests and acceptance (DEVELOPMENT, NOT CERTIFICATION)

- `tests/test_remote_receipt_sync.lua`: two fully independent leader/player SavedVariables objects, NEED/GREED preserved before player click, player OBTAINED after explicit action, leader ACK, lost-ACK recovery, fake sender/changed leader/wrong recipient/item/UID, nonprivate messaging refusal, duplicate messages and Playerbot exclusions, plus no `GiveMasterLoot`.
- `tests/test_receipt_sync_ui.lua`: receipt list navigation and counts, two-click controls, expiry, selection change, Close/reopen and empty state.
- The full existing Lua 5.1 regressions and reproducible packaging test must remain green on the exact commit, plus a separate no-release safety workflow.
- **Final in-game acceptance** requires *two separately backed-up WoW 3.3.5a clients* (player + leader) and expendable loot: verify receipt notification, inventory checks, local update, leader ACK and reread after `/reload`. Test denial for leader change/offline player and duplicate sync. Any live Master Loot must use a dedicated controlled safety session, **not** a busy raid.

### Paired backups for each actual client

Before installing anything, **finish current loot, fully exit WoW**, then back up both `Interface/AddOns/NaxxLootLottery/` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.lua.bak` where present, separately for the leader AND player. Never import someone else's SavedVariables; the leader's previously imported 604 Playerbot plans must stay in the leader's own local files.

**Current status:** no downloadable test package, merge, tag, released addon, real award, or installed client changes. Keep HF2 unchanged until the agreed final integrated test phase.
