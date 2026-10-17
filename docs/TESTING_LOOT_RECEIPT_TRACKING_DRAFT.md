# Real loot receipt tracking — NEED/GREED → OBTAINED (draft)

**Status: unmerged, uninstalled development.** Based on draft PR #15, stacked after #14, #13, #12 and HF2 PR #10. The owner's installed HF2, raid roles, 604 Playerbot Gear Plans and earlier loot/award history are not modified by this branch.

## Purpose

When a player or Playerbot **wins an NLL lottery**, keep a durable record, then mark that character's matching active **NEEDED** or **GREED** reservation **OBTAINED only after the item is actually received**.

**A winning ticket does not prove physical delivery.** Neither `GiveMasterLoot` succeeding, `AWARD_REQUESTED`, nor `LOOT_SLOT_CLEARED` proves the recipient actually obtained the item. Never automatically mark OBTAINED from those events alone.

## New ledger

New SavedVariables table `lootReceiptTracker` keyed by real immutable `dropUID`; records itemID, itemName, winner, NEED/GREED selection, original active matching Gear Need keys/statuses, who observed the win and timestamps. On `TicketLottery:Finish` only for a verified real result:

- Store **`WON_AWAITING_ITEM`**. Leave *all* player/bot Gear Plans and local wishes unchanged.
- Require a separate existing `LEADER_REPORTED` award record (after the leader uses Blizzard UI) or `LOOT_SLOT_CLEARED` award record.
- After independently checking the actual recipient's inventory, the same raid leader or current authorized leader/officer opens **Current Loot → Confirm Receipt** or **Award History → Info** (for earlier drops, even if corpse despawned).
- Button **I Checked Inventory** then separately **MARK OBTAINED** within 15 seconds. Recheck immutable drop UID, winner, award record, original reservation keys/statuses and current authority. One human-confirmed receipt changes only that character and that item from NEED or GREED to **OBTAINED**.
- Write a persistent audit with `confirmedBy`, `confirmedAt`, `confirmedNeedCount` and evidence `LEADER_CONFIRMED_RECIPIENT_INVENTORY`. This is a **human attestation**, not a client-verified inventory receipt; no automated Master Loot request is made.
- A second confirmation is refused; fake winners never create real receipts. If a reservation changed since the roll, confirmation refuses rather than overwriting it.
- The existing `GearNeeds:GetNeedsForItem(id,"NEEDED"/"GREED")` matching excludes OBTAINED records automatically, so confirmed owners stop appearing as eligible for further item copies under this one-copy model.

## Player vs Playerbot behaviour

- **Playerbots:** Their saved `BOT_GEAR_PLAN` and any other matching active source row on the raid leader's account change to OBTAINED; other bots/items and existing receipt/roll records stay unchanged.
- **Players:** The raid leader's `PLAYER_SUBMITTED` Gear Needs change to OBTAINED using the same receipt workflow. Previously obtained player-submitted rows cannot silently become NEED or GREED during later submission merges.
- **The local player on the current client:** NLL also stores a sparse `localWishlistObtained` flag without deleting the existing boolean reservation or optional GREED preference. My Wishlist displays **OBTAINED** and disables Need/Greed; outgoing wishlist submissions exclude obtained items. Explicit Remove remains possible, and explicitly re-adding clears the local obtained flag.
- **Other human players on separate accounts:** This draft cannot edit a remote player's `WTF` SavedVariables. The raid leader's plan correctly becomes OBTAINED, but the remote player's personal My Wishlist needs a **separately authenticated/acknowledged addon-message synchronization phase** before we can claim it updates too. Do not pretend it is already synchronized.

## Important limitations / future testing

- This is **one reservation per character+item+source**, not yet a supported multi-copy ring/trinket counting system.
- Item delivery still requires real master-loot verification; the new receipt buttons only record confirmed physical receipt.
- If a roll happened before installing this draft, it may lack a tracking row. Do not fabricate previous receipt records or rewrite past wins automatically.
- After the original corpse disappears, **Award History → Info** can still open the immutable pending receipt for the exact original drop UID. This is for recording independently verified inventory, **not** reopening loot.
- Real award delivery and direct guild-material routing remain OFF by default. No SQL or worldserver changes.
- Developer branch carries version `0.1.0.29-rc.1-dev2` to prevent confusion with dev1 and the owner's HF2. No installable/test artifact is published by this PR.

## Automated tests

- `tests/test_loot_receipt_tracking.lua`: real/winning vs fake, unchanged roll-time statuses, bot multiple-source NEED/GREED to OBTAINED, player submitted to OBTAINED, local mirror only for same-account winner, duplicate/mismatched winner, inadequate AWARD_REQUESTED evidence, changed status fail-closed, persistent audit.
- `tests/test_receipt_savedvariables.lua`: original booleans/GREED untouched, local OBTAINED persists on reload, duplicate old player submissions cannot downgrade OBTAINED, explicitly removing/re-adding a wishlist entry.
- `tests/test_receipt_review_ui.lua`: first click enables only the separate second click, 15-second expiry, changed item, cancelled window, duplicate refusal and post-corpse historical review.
- Existing Lua 5.1 regression suites (including full gear-transfer, historical winner, bot plans, Need/Greed, real Master Loot and guild material safeguards) and deterministic packaging tests must all pass on exact PR head.

## Eventual in-game acceptance

**First finish any open loot and fully exit WoW**, back up BOTH `Interface/AddOns/NaxxLootLottery` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua`, plus `.lua.bak` if present. Prefer a separate backed-up client/realm and an expendable item. Verify `/nll version`, READY, both Direct Award and Guild Transfers OFF, all 604 plans still present.

Test one bot and one human player with different NEED/GREED interests; complete a real server lottery with the corpse open. Immediately verify both still show WANT/NEED or GREED, while receipt ledger is pending. Deliver through separately approved item-award flow, independently confirm the item in the winning character's inventory, then perform two-click receipt confirmation. Confirm only the correct item/character/source records switch to OBTAINED, persist through reload, and old roll/award history remains.

Do **not** enable real transfer or merge/publish this branch before owner approval and separate in-game safety validation. This is development, not a raid release.
