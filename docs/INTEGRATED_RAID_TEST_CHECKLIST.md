# NLL — Integrated WoW 3.3.5a acceptance checklist

**Status: NOT STARTED — automated tests are not evidence of physical item delivery.**

Applies to development stack #10 -> #12 -> #13 -> #14 -> #15 ->
#16 -> #17 -> #22 -> #23 -> #24 -> #25 -> #26 -> #27 -> #28.

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

## B2 — Character-only Gear Plans filtering (new draft #26)

- [ ] Open Wishlists -> Gear Plans on the controlled test build.
- [ ] Type one exact bot name, for example Gorak. Confirm only that
      character's records appear; no similarly named bot appears.
- [ ] Repeat with different letter case and surrounding spaces.
- [ ] Type a partial or nonexistent name; ensure the list shows no
      other character and has no stale paged rows.
- [ ] Try Apply, Enter and All. All restores the complete Gear Plans
      view, with the six-row pager remaining readable.
- [ ] Compare the 604 / 469 NEED / 135 GREED saved baselines before
      and after filtering; verify no item statuses or receipt history
      changed as a result of the filter.

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

## D2 — Pending recipient receipts and Master Looter dry-run gates

- [ ] Confirm a recorded winner with WON_AWAITING_ITEM is HELD even
      if the original Gear Plan was replaced, removed or marked obtained.
- [ ] Confirm a leader-side human OBTAINED with pending, failed or
      unacknowledged remote player message stays HELD for guild review.
- [ ] Confirm the human client's ACKNOWLEDGED state lifts ONLY this
      extra receipt hold and never unlocks a historic item request.
- [ ] Confirm LOOT_SLOT_CLEARED without independent inventory review
      remains an unresolved global hold on unrelated new proposals.
- [ ] Explicit no-retry closure lifts only that global hold; original
      item stays locked and historical receipt remains unchanged.
- [ ] Dry Run ON with an active lottery, Group Loot or a different
      designated Master Looter returns HOLD, never PROPOSE_TO_LEADER.
- [ ] Test that historic local OBTAINED wishlist entries are not counted
      as active interest without a new SavedVariables table being created.

## D3 — Recipient-self guild bag-check (draft #28)

- [ ] In the owner-authorized test build open /nll guildreceiptui.
- [ ] Only the EXACT intended guild recipient may arm their own entry.
- [ ] Require visible quantity in their own bags, but recognise
      pre-existing stock is not proof of which corpse supplied it.
- [ ] Two deliberate buttons within 15 seconds; page/selection change,
      fake mode, changed actor, closing and /reload cancel pending work.
- [ ] A successful second click adds only one append-only attestation
      to guildRecipientReceiptAudit; original statuses stay unchanged.
- [ ] CLOSED_NO_RETRY and recipient attestation can both exist,
      but neither unblocks original same-item transfer locks.
- [ ] Validate same-item different audit rows independently and reject
      duplicate attestations for the same exact audit index.
- [ ] This is NOT server delivery certification or an automatic
      permission to allocate additional guild loot.

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

## F2 — Modal geometry and accessibility (draft #29)

- [ ] Test the Guild Loot, NO RETRY investigation and My Bags modals
      at the owner's real WoW interface scale, including fonts.
- [ ] Confirm the final Guild Loot row has a visible, comfortable
      gap to ARM / CONFIRM / Dry Run controls and no overlapping click
      target or obscured label.
- [ ] Confirm paging buttons, labels, receipt link and Close never
      overlap or clip long item names and recipient names.
- [ ] Verify on a different officer's client that My Bag Receipt
      stays disabled for another person's transfer and even a forced
      click cannot start an attestation.
- [ ] On intended recipient client, check that My Bag Receipt opens
      the correct indexed guild audit, not the nearest matching item ID.
- [ ] Confirm page changes, close, loot reopen and /reload never leave
      a previously armed confirmation active.
- [ ] Record screenshots; geometry mock tests alone are not proof of
      pixel-perfect in-client appearance.

## F3 — Corpse source diagnostics (draft #30)

- [ ] On a controlled dev client open one REAL corpse's loot window
      and run /nll lootsource. Record slot summary and target GUID hint.
- [ ] Change the current target and repeat WITHOUT changing the corpse.
      Different UnitGUID target must NEVER claim a different loot source.
- [ ] Reopen same corpse or compare a separate corpse with the same
      crafting material. Previous physical attempt must remain locked.
- [ ] Repeat without current target; confirm no source is invented.
- [ ] Use Debug Simulator and closed loot: zero live source rows.
- [ ] No GetLootSourceInfo (5.0.4+) dependency, no new delivery proof,
      no bypass for guild materials or repeated winner rolls.
- [ ] Compare backup with saved Gear Plans, winners and receipts; running
      diagnostic should not append records or change settings.
- [ ] Record in-game screenshots, not just Lua geometry/mock evidence.

## F4 — Read-only full Playerbot Gear Plan export (draft #31)

- [ ] Before controlled dev build installation, back up addon folder
      and NaxxLootLottery.lua / .lua.bak on all participating clients.
- [ ] Verify 604 / 38 bots / 469 NEED / 135 GREED.
- [ ] Open Import / Export; check Batch 1/3, 2/3, 3/3, with
      250/250/104 complete, ordered and copyable plan rows.
- [ ] Copy EACH batch with Ctrl+C into individually labelled .txt files.
      Each batch must start with NLL-GEARPLANS-1.
- [ ] Confirm export does not enable Preview Changes or Confirm ADD.
- [ ] Verify Import disables Prev/Next; previously pasted text is not
      silently overwritten by disabled batch navigation.
- [ ] Preview each exported batch, on matching test data ONLY:
      no new plans, no conflicts and no save changes.
- [ ] Test invalid late record to ensure ALL export pages fail closed.
- [ ] Confirm original roles/wishlists/history/SavedVariables unchanged.
      This partial Gear Plan text export never replaces full WTF backup.

## F5 — Existing Playerbot Gear Plan edit safety (draft #32)

- [ ] Verify original 604/38/469/135 with full paired backups.
- [ ] Status change or X first opens explicit exact-bot/item review,
      not an immediate SavedVariables mutation.
- [ ] Cancel, page/filter switch, different actor, 15-second expiry
      or /reload disarms review with no saved-row change.
- [ ] Confirm one safe test-row NEED/GREED/DISABLED change updates
      ONLY that exact bot plan; no global role/type assignment rewrite.
- [ ] OBTAINED is blocked unless existing recipient receipt process
      updates it. Pending winner / player ACK holds protect records.
- [ ] X removal requires its own review; do not delete a valuable
      saved reservation just to demonstrate the button.
- [ ] No edited record or other 603 rows are accidentally overwritten.
- [ ] Record real UI screenshots, including long bot names.

## F6 — Individual bot Gear Plan item-role editing (draft #33)

- [ ] Back up all client SavedVariables and addon folder; confirm
      604 plans, 38 bots, 469 NEED, 135 GREED baseline.
- [ ] Click Edit in Role column for a safe NON-OBTAINED plan; full
      six-role choice screen opens with no immediate saved change.
- [ ] Select role, cancel in confirmation window, then verify no edit.
- [ ] Expire confirmation (>15 sec), switch pages/character filters,
      and test stale data; pending review must never save.
- [ ] Explicit Confirm changes **ONE plan row.role only**; compare
      account db.roleAssignments (unchanged) and all other rows.
- [ ] OBTAINED and pending winner/remote ACK roles cannot be changed.
- [ ] Verify long role names and inline Edit buttons at actual UI scale,
      and preserve original files and screenshots for review.

## F7 — Gear Plan import conflict comparison (draft #34)

- [ ] Back up full client addon and account SavedVariables; record
      604 / 38 / 469 NEED / 135 GREED before any dev installation.
- [ ] In controlled test context, Preview valid V1 paste differing from
      an existing plan in role/status. Confirm ADD must remain disabled.
- [ ] Compare Conflicts shows the exact SAVED and PASTED values, with
      clear count X/Y, Previous/Next and Close.
- [ ] Include a pasted NEW row alongside a CONFLICT: none are imported.
- [ ] Casefolded UTF-8 character aliases are identified, not duplicated.
- [ ] Close, alter paste, switch mode or change saved data; all stale
      comparisons must fail closed and show no old approval.
- [ ] Verify actual UI dimensions, font wrapping, keyboard/mouse
      accessibility, zero receipt/loot history/role changes and no
      mutation to the 604 stored real plans.

## F8 — Profession-aware recipe review (draft #35)

- [ ] Save matched full addon + account SavedVariables backups, and
      verify the 604 / 38 / 469 NEED / 135 GREED Gear Plan baseline.
- [ ] In My Wishlist → Recipes, confirm Prof. Review replaces only
      the category's Interest header; Gear / Items header is unchanged.
- [ ] Browse ten Molten Core recipe IDs, profession and 300 skill;
      verify actual skill/specialization rules in the IP/3.3.5a client.
- [ ] Browse many names with four-per-page candidate controls;
      imported Gear Plan NEED/GREED is interest, NOT profession proof.
- [ ] Verify OBTAINED/DISABLED plans, unknown professions and
      unverified Goblin/Gnomish/Leatherworking specializations are
      never deemed eligible or offered automatic allocation.
- [ ] Confirm no GiveMasterLoot, roll, raid message, award attempt
      lock change, SavedVariables write or item transfer.
- [ ] Capture real game UI screenshots and full data comparison.

## Release gates (require separate owner approval)

- [ ] Full Lua 5.1 CI passes at the exact stacked final SHA.
- [ ] All relevant multi-client and physical award test scenarios have
      independently reviewed evidence; simulation alone is insufficient.
- [ ] Regression issues are resolved in new draft PR commits.
- [ ] Owner agrees on staged migration/install plan and a release version.
- [ ] Owner explicitly authorises merging, releasing and installation.

No section of this checklist authorises a physical item transfer.
