# Naxxramas Loot Ledger v0.1.0.29-rc.1-dev20 — RAID TEST PRE-RELEASE

> **Experimental, opt-in test build for 19 October 2026. NOT STABLE and NOT a certified loot distribution solution.**

**World of Warcraft:** 3.3.5a (Interface 30300), AzerothCore / Individual Progression / Playerbots.  
**In-game version:** 0.1.0.29-rc.1-dev20  
**Source code:** pinned to fully tested commit e7566c77bdee565c35830e9fddc9481f7db88464, which the owner has already installed and tested in-game.  
**No merge to main, no changes to prior stable v0.1.0.28 or older prereleases.**

## Download and backup (everyone must follow)

1. Under **Assets**, download **Naxxramas-Loot-Ledger-v0.1.0.29-rc.1-dev20.zip** and **SHA256SUMS.txt**. Do **not** install GitHub-generated Source code (zip/tar.gz) archives.
2. Exit WoW completely. Back up the complete currently installed **Interface/AddOns/NaxxLootLottery/** addon folder somewhere outside WoW, alongside the matched account **WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua** and **.lua.bak** if present. Do this on each individual test client; preserve any older backups separately.
3. Confirm the downloadable addon ZIP SHA256 matches the attached SHA256SUMS.txt. The **expected inner ZIP SHA256** is:

   **19f1ec42328ee184b84e2de2fac91000e1d0c68480a61fbf06f407aff22acae7**

4. Replace the **entire old addon directory** with the ZIP's single **NaxxLootLottery** directory. Do not mix modules or overwrite/move/delete anything in account **WTF**. The ZIP has 51 Lua modules, one TOC, and **no user SavedVariables / private 636-plan roster**.
5. Restart WoW. Check **/nll version** (expect 0.1.0.29-rc.1-dev20), **/nll status** (expect READY), and verify **your own** Gear Plans, wishes and inbox. Do not import anyone else's account files or overwrite saved entries.

## What is included

- Improved seven-row My Wishlist UI, compact header, better footer spacing and paged access to all reservations.
- Gear Plan safe single-row review, exact character filtering, read-only multi-page export and conflict-blocking add-only import (not an approved way to repair someone's live records).
- Inbox **Newer/Older** navigation, reversible **Archive / Archived / Restore** (two-click 15-second confirmation to archive). Archiving is not deletion, acceptance or rejection.
- **Settings → Award History** displays completed genuine lottery winners as **Won roll - unverified** and separately displays actual physical Master Loot attempts. A roll win is never evidence of physical delivery.
- **New Run View / All History** switches the visible history only; audit, lottery rows, winner data, receipt records and original physical award attempts remain stored.
- Manual-only Molten Core profession recipe review; unverified profession, specialisation, recipe knowledge and recipient eligibility are **not** assumed.
- Read-only **/nll lootsource** and **/nll copyaudit**. Loot slots, stack quantities and target hints do not prove distinct, independently awardable physical copies.

## Real-game testing evidence and known gaps

The owner has installed this exact dev20 addon and confirmed: normal startup/version, My Wishlist layout, saved Inbox pagination and Archive/Restore in the WoW 3.3.5a client. Award History's empty-state layout was also visually checked. The owner's Gear Plans showed **636 saved entries**; the older 604/469 NEED/135 GREED snapshot is historical. This release does **not** include, reset, import or delete any Playerbot data.

**Still untested or not certified:** recording a *genuinely completed raid* lottery winner in Award History, multi-client behaviour, persistent actual receipt proof, real recipient transfer, all UI font sizes and AzerothCore physical loot identity.

**Known UI issue:** timed buff icons may render over NLL's main window ([tracked issue #39](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/39)). The outgoing submission status can still truncate at some scales. Development PR #38 remains open and unmerged.

## Required restrictions for tomorrow's raid

- **KEEP Direct Master Loot, Guild Loot Transfers and Guild Auto Preview OFF**. These reset OFF on login/reload. Use the raid leader's usual **independent manual game loot distribution**, not NLL automated physical delivery.
- Do not treat winner chat, a cleared loot slot or a user's self-report as proof an item was awarded. Review winning character / item / timestamp in the UI as **non-physical observations**.
- **Never retry** an already-attempted Master Loot transfer; **AWARD_REQUESTED**, **LOOT_SLOT_CLEARED**, **AWARD_OUTCOME_UNKNOWN** and **CLOSED_NO_RETRY** remain blocked. Identical materials on different corpses are **not safely resolved client-side**.
- Don't use **/nll newloot** or import/replace real Gear Plans as a workaround for physical or save errors; don't click dangerous grant/award buttons to test them.
- Recipes, ring/trinket multi-copy restrictions and profession skills need separate human eligibility checks. No auto-allocation is proven.
- If a Lua error, missing plan, confusing overlapping control, unexpected winner or incorrect item appears, **stop using the feature** and capture a screenshot/error. Keep original backups intact.

## Reporting, rollback and source history

For ordinary raid testing, please check **Settings → Award History** after a naturally completed genuine lottery and report whether the item, player/Playerbot winner, timestamp and **Won roll - unverified** status are correct. **Do not create an actual item award just to test a record.**

For problems: close WoW fully and restore the **matched addon folder and SavedVariables backup pair**; do not mix backup generations.

- [Dev20 development draft PR #38](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/38) — remains unmerged.
- [C15 in-game acceptance checklist](https://github.com/CosmicCuddle/N-Loot-Ledger/blob/dev/nll-live-ui-feedback/docs/C15_LIVE_FEEDBACK_UI_ACCEPTANCE.md).
- [Deferred buff frame overlap #39](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/39).

This pre-release is intended solely to let other players help with controlled testing. **Stable v0.1.0.28 remains unchanged.** GitHub Actions requires every Lua 5.1 regression to pass and the addon ZIP's exact SHA256 to match before publishing the tagged release.
