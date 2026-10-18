# NLL — Integrated WoW 3.3.5a acceptance checklist

**Status: NOT STARTED — automated tests are not evidence of physical item delivery.**

Applies to development stack #10 -> #12 -> #13 -> #14 -> #15 ->
#16 -> #17 -> #22 -> #23 -> #24 -> #25.

Current installed raid build is 0.1.0.29-rc.1-hf2.
Do not install development builds until owner approves a controlled test.
Do not merge, publish or change the live server/SavedVariables.

## Before testing: owner action

- [ ] Choose a quiet, safe test window, not the next active raid.
- [ ] Make a complete dated copy of Interface/AddOns/NaxxLootLottery/.
- [ ] Back up WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua.
- [ ] Also copy NaxxLootLottery.lua.bak if it exists.
- [ ] Make separate backups on EACH human player's WoW client involved.
- [ ] Record the current addon version, realm, leader and recipient names,
      actual build head and screenshots of key interfaces.
- [ ] Verify 604 imported Playerbot records, 38 bots, 469 NEED and
      135 GREED as the expected baseline; counts should NOT be reset.
- [ ] Verify role assignments, historical winners and personal wishlists.
- [ ] Keep Direct Master Loot and guild transfer settings OFF.
- [ ] Use only the owner-approved test package once a future test is authorised.

## A — New Drop, duplicate copies and physical identities

- [ ] Reopening the same corpse preserves the previous UID and winner.
- [ ] Two identical item drops on a single corpse get distinct drop UIDs.
- [ ] If one copy disappears and identity becomes ambiguous, refuse to
      guess, roll or send a second physical award.
- [ ] An actually different corpse requires New Drop -> Confirm Drop
      while a REAL loot window is open and leader authority is verified.
- [ ] The previous winner/receipt remains unchanged when another corpse
      produces the same item.
- [ ] Closing the corpse and /reload disarms both New Drop and transfer
      confirmations. No stale loot slot or candidate is reused.
- [ ] A prior unverified material request remains held across slot
      reordering, including after CLOSED_NO_RETRY. NO automatic reissue.
- [ ] New legitimate identical guild materials are intentionally held
      pending a future reliable per-corpse identity mechanism.
      This is a conservative limitation, not an approval to bypass it.

## B — Reservations and ticket lottery

- [ ] Verify all 604 saved Playerbot Gear Plan rows before/after.
- [ ] Check NEED priority ahead of GREED, original tier rules unchanged.
- [ ] Reserve gear for bot and human; confirm offline reservations
      still block the guild dry-run suggestion.
- [ ] Prepare tickets/rolls and optional RAID chat count from 5 seconds
      using controlled non-awarding tests first.
- [ ] Distinct physical drops may create new tickets without deleting
      the old winner, subject to unique identity verification.
- [ ] Pending roll/countdown is never silently bypassed by New Drop.

## C — Item award and reconciliation

- [ ] Current WoW Master Looter, recipient candidate and exact loot slot
      must match before any permitted manual review.
- [ ] Merely pressing Review or ARM never invokes GiveMasterLoot.
- [ ] Explicit real transfer consent remains OFF on login and /reload.
- [ ] A simulated Master Loot API error remains AWARD_OUTCOME_UNKNOWN;
      the durable attempt lock exists BEFORE the attempted API call.
- [ ] LOOT_SLOT_CLEARED is clearly marked delivery UNVERIFIED.
- [ ] Reconciliation modal opens from Award History, Guild Loot and
      /nll reconcileui.
- [ ] Changing page, selecting another record or closing cancels arming.
- [ ] 15-second expiry, authority change and fake raid cancel closure.
- [ ] CONFIRM CLOSE only records CLOSED_NO_RETRY, never OBTAINED.
- [ ] Original winner, persistent lock, receipt and Gear Plans survive
      closure, login and subsequent reopen.

## D — Playerbot and human OBTAINED receipt tracking

- [ ] Winner initially remains WON — AWAITING ITEM.
- [ ] Award request / slot clear alone never marks a plan OBTAINED.
- [ ] Use independent recipient inventory evidence and explicit leader
      confirmation to mark leader-side Gear Plans OBTAINED.
- [ ] For humans on another WoW client, check targeted R1 receipt
      notification in My Wishlist -> Receipts.
- [ ] Human explicitly confirms THEIR own inventory; only then local
      wishlist changes to OBTAINED and an ACK is returned.
- [ ] Lost ACK can be retried without converting another reservation or
      rewriting any other player's SavedVariables.
- [ ] Disconnected client, changed raid leader, wrong recipient/UID,
      forged sender, duplicate replay are all handled conservatively.
- [ ] Test a bot receipt separately from an ordinary player receipt.

## E — Guild materials and future automation safety

- [ ] Guild Loot displays non-database materials, reagents, recipes
      and eligible equipment, including BoE where metadata is available.
- [ ] NEED/GREED, pending Inbox, local wishes, special/legendary/quest,
      unknown metadata and locked slots are all HELD.
- [ ] DRY RUN starts OFF; ON only PROPOSES unreserved known items
      to the raid leader for human verification.
- [ ] Any missing or ambiguous remote reservations must prevent
      unattended allocation.
- [ ] Prior item-ID award attempts remain held even when the loot
      slot number changes.
- [ ] No timer or scan invokes GiveMasterLoot or changes wishlists.
- [ ] Never enable unattended item transfer in this test campaign.

## F — Visual, persistence, version and rollback

- [ ] HF2 New Drop button stays non-overlapping.
- [ ] No button obscures the guild review or reconciliation controls.
- [ ] Long item names, 6+ historical rows and multiple pages remain usable.
- [ ] Existing 604 bots / 469 NEED / 135 GREED and all important saved
      data remain intact across login, reload and tested client transition.
- [ ] Preserve screenshots, error logs and receipt/award audit messages
      with exact observed timestamp, item ID, drop UID and character.
- [ ] Compare test SavedVariables to the dated backups, not only UI totals.
- [ ] If any item outcome is uncertain: DO NOT RETRY. Record evidence,
      close the UI and investigate offline without giving a second item.
- [ ] Roll back only after preserving test logs and restoring both addon
      and the CORRESPONDING SavedVariables backup as a matched pair.

## Release gates (require separate owner approval)

- [ ] Full Lua 5.1 CI passes at the exact stacked final SHA.
- [ ] All relevant multi-client and physical award test scenarios have
      independently reviewed evidence; simulation alone is insufficient.
- [ ] Regression issues are resolved in new draft PR commits.
- [ ] Owner agrees on staged migration/install plan and a release version.
- [ ] Owner explicitly authorises merging, releasing and installation.

No section of this checklist authorises a physical item transfer.
