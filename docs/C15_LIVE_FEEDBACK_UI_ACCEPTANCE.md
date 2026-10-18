# NLL — First live 3.3.5a UI feedback (draft #38, dev20)

**Owner feedback:** 18 October 2026, after installing and testing the verified C14 dev19 TEST-ONLY package. Screenshots cover Inbox, Award History, Gear Plans and My Wishlist.

**No real SavedVariables were transferred to development, read, edited, or reset by GitHub. All work here is a new stacked draft.**

## Actual screenshot findings

1. **Gear Plans show 636 SAVED GEAR NEED(S), 106 pages of six.** This is NOT the historic **604** baseline. It may represent 32 additional legitimate records; the cause has not been independently determined. **NEVER migrate, truncate, restore to 604, or silently adjust statuses.** Before testing a later candidate, back up the *current* matching dev19 addon folder and current SavedVariables, as well as preserving the earlier HF2 backup separately. Determine the true counts of NEED/GREED and distinct Playerbots from verified exported data before a final release decision; the earlier 469/135 split is not a claim about the latest 636.
2. **Inbox shows 6 saved submissions but only 4 top rows**, with rejected and accepted historic entries that clutter selection. Fix: top 4-row paging **Newer / Older**, reversible two-click **Archive**, separate **Archived / Active** view, and **Restore**. The full original submission, status, item IDs, interests, exclusions, acceptance audit and Gear Plans are preserved. Archiving a pending submission does not accept/reject it; submissions are only hidden in the local list. No automatic purging.
3. **Award History shows 0 records.** Original UI only inspected physical `lootAwardHistory` attempts, not the completed separate `lotteryHistory` table. Fix: read-only combined **Roll Winners & Loot Award History**, showing the winners of completed real rolls with the explicit **Won roll - unverified** state; when a physical attempt exists for the same drop UID, show the physical attempt instead of a duplicated win. Never count a lottery draw as physical delivery or an independently verified recipient receipt.
4. **New run Clear request:** implement **New Run View** with a second explicit confirm within 15 seconds and an **All History / This Run** toggle. The only persistent change is a visibility cutoff `raidHistoryView.startedAfter`; **never clear/delete/replace** `lotteryHistory`, `lootAwardHistory`, `lootReceiptTracker`, write-ahead locks or `CLOSED_NO_RETRY` rows. Boundary timestamps are second-resolution; events recorded *in the same second* as the switch may be conservatively hidden rather than risk showing previous run entries. The original lottery log retains its historic cap at 100.
5. **My Wishlist screenshot overlaps:** the long "My Molten Core wishlist" count wraps into the item header. Bottom 8th Gear row, a long 3-line boss list and Submit-to-Leader status overlap page controls. Fix a compact one-line header, shorten overlong boss-source text, reduce visible wishlist rows to **7**, and put outbound submission status in a separate higher footer strip. The entire collection still remains available with pagination; no reservation edits or deletions.
6. **Award History screenshot** has spacious empty state but misleading "real awards only" wording. New labels reflect lottery winner vs physically attempted vs independently checked recipient status. Distinguish this from true item delivery.
7. **Inbox permissions:** when outside current raid-leader context, disable Accept/Reject buttons for pending submissions in UI. Archive/restore is only local presentation and can be used without claiming raid leader authority. Existing server/communication protocol is unchanged.

## Safe review and test plan

- [x] Add new read-only `Core/RaidHistoryView.lua` and wire in TOC; default new-run view + All History toggle.
- [x] Add `Communication:ArchiveSubmission` / `RestoreArchivedSubmission` and archive-filtered deterministic submission list; archive action does not delete entries.
- [x] Add top Inbox paging (6 stored entries now accessible), explicit two-click archive and one-click restore.
- [x] Adjust My Wishlist header/footer geometry based on supplied screenshot, shortening text without altering saved data.
- [x] Add Lua 5.1 integrated no-award test using **636 synthetic saved plans**, six Inbox submissions, one standalone completed real roll, one physical history record with same drop UID, simulated-only records excluded, immutable old receipt/write-ahead state and default physical consent OFF.
- [x] Add Inbox GUI test for sixth entry, two-click archive and restore.
- [x] Dedicated no-release, full historical Lua 5.1 and owner
      TEST-ONLY package CI passed; exact-head links recorded on PR #38.
- [ ] Owner-approved in-client UI screenshots at actual large font, scaling, 636-plan count and item visibility. No newly generated test build should be installed until full matched backups are made.
- [ ] Test explicit New Run View only after observing winner-history read-only snapshots; **do not test a real physical award**, retry, deletion or imported changes as part of these UI checks.
- [ ] Investigate any other overlapping elements visible on screen after these first changes and add tests; do not assume mock geometry is real WoW proof.

## In-game test conditions for dev20 (future owner approval only)

1. Fully close WoW. Keep existing original **HF2 backups** intact and make a **NEW dated backup** of the currently installed dev19 `Interface/AddOns/NaxxLootLottery` and matching `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` + optional `.lua.bak`, before replacement.
2. Use a verified, successful and SHA256-checked **TEST-ONLY** dev20 ZIP with 51 addon Lua modules and Interface 30300. Never overwrite the `WTF` database.
3. `/nll version` must show `0.1.0.29-rc.1-dev20`, `/nll status` READY; note any Lua errors.
4. Observe **636 Gear Plans before and after**, with all previously present characters, statuses, saved Inbox submissions, personal wishlist entries and history unchanged. If it differs, **STOP** and preserve evidence.
5. Verify My Wishlist one-line count, seven visible rows, no footer overlap, readable abbreviated multi-boss text and all items reachable via pages.
6. Verify Inbox: six initial active submissions (unless changed by owner), top page 1/2 + 2/2, bottom submitted-item pager independent. Test archiving **one already rejected test/old entry** with two-click confirmation, switch to Archived and Restore; verify all item decisions/statuses and accepted Gear Plans are unchanged.
7. Verify Award History displays completed real **roll winners** distinctly from physical award attempts. An empty actual award log does not mean zero winners. Compare with historical logs; do not assume simulated winners are real.
8. With no active lottery or loot window, use **New Run View** first arm then confirm; switch **All History** to see older wins again. The display changes but full audit remains. Do not perform real physical award or repeat on a former `CLOSED_NO_RETRY`.
9. Reconfirm Direct Master Loot, Guild Transfers, auto-preview OFF. Compare matched SavedVariables. Screenshot remaining UI overlaps, especially at user's preferred font/scale.

## Safety

**New Run View is not Clear/Delete History. Archive is not permanent deletion.** History, winner identities, immutable old loot attempts and saved Gear Plans are retained. No actual server, SQL, AzerothCore module, IP, Playerbots or installed addon was touched by GitHub draft work. The user must opt into every subsequent test installation explicitly.
