# Automatic guild-loot routing — proposal-only (development)

This stage follows draft #18 (receipt reconciliation), which follows #17, #16, #15, #14, #13, #12 and HF2 draft #10. **No live transfer logic is enabled or installed.** This code is a blueprint for future owner-approved automatic routing, NOT an implementation of automatic loot delivery.

## Owner's target policy
Whenever legitimate Molten Core loot (including materials, reagents, gear, recipes and BoEs) has NO eligible NEED and NO eligible GREED reservation, the **raid leader** should ultimately receive it for guild allocation. Quest/legendary/manual-only loot and uncertain reservations remain on hold. A Master Looter and a raid leader may be different people.

## What this draft implements
- `Core/GuildAutoPreview.lua`: read-only `Plan()` classifies **every real item-link slot**, including materials not present in NLL's gear database. Uses existing GuildLootReview:Scan and its full Need/Greed/Inbox/unknown/special protection.
- New **Auto Preview** button next to Guild Loot inside Current Loot and `/nll guildpreview` command open a separate paged, read-only **AUTOMATIC GUILD ROUTING — PREVIEW ONLY** window.
- For a genuinely unreserved item, while the acting player is the designated WoW Master Looter and leader identity is stable, report **PROPOSED_ONLY** as a suggestion that the leader could receive it AFTER live manual verification.
- Other classifications: `HOLD_RESERVED`, `HOLD_SPECIAL`, `HOLD_UNCERTAIN`, `HOLD_UNCLASSIFIED`, `HOLD_PRIOR_AWARD`, `HOLD_DUPLICATE`, `HOLD_ACTIVE_ROLL`, `HOLD_MASTER_LOOT`, `HOLD_LEADER`.
- None of these proposals marks the Master Loot candidate index verified. Even a proposed candidate has `recipientVerified=false`, `candidateVerified=false`, `transferAuthorized=false`, `physicalAwardRequested=false`, `dryRun=true`, and `realTransfers=0`.
- The planner NEVER calls `GiveMasterLoot`, `RandomRoll`, `TicketLottery:StartRoll`, `GuildLootTransfer:Commit` or edits SavedVariables.
- On corpse closure, preview has zero rows and displays **CORPSE CLOSED** instead of showing old proposed items.
- Confirmed local `OBTAINED` (PR #16/#17) wishes remain in historical boolean wishlist storage but are **not an active reservation** in the material/guild review summary. If local status is missing or uncertain, hold the item.
- A known unresolved prior request or an older same item/slot transfer attempt **overrides** unreserved status and blocks proposal, even after an operator reconciled receipt. This intentionally retains the 3.3.5a duplicate-corpse ambiguity protection.
- Existing manual two-click Guild Transfers and both live consent switches are unchanged (still OFF on login/reload). No automated setting is offered because real auto-transfers are NOT implemented.

## Why this is not ready to transfer items
WoW 3.3.5a does not provide a trustworthy per-corpse loot source GUID; Master Loot recipients/candidate indices are **specific to the currently selected real Blizzard item dropdown**; an unseen or unsent player wishlist cannot be treated as an absent reservation; some reagent/material loot may not be Master-Loot-eligible. The exact item, corpse, designated Master Looter, raid leader and current candidate MUST be revalidated immediately before any eventual award. An API call alone is not a delivery receipt.

## Automated tests
- `tests/test_guild_auto_preview.lua`: all item slots including Trade Goods/armor, NEED/GREED holds, pending Inbox, unknown cached item, legendary, former local OBTAINED, duplicate history, unresolved global award, acting Master Looter, active lottery, fake raid and closed corpse. Verifies every row reports NO authorization and NO physical award, and saved plan/history tables are untouched.
- `tests/test_guild_auto_preview_ui.lua`: six-item pagination, warning text, corpse closure, navigation and NO item transfer controls.
- All historical Lua 5.1 tests and deterministic package/version smoke tests must pass for the exact PR head.

## Eventual acceptance
Finish active looting, **exit WoW**, and take paired backups of BOTH the addon folder (`Interface/AddOns/NaxxLootLottery`) and the current account's `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.lua.bak`. Use an isolated test client/realm, never the owner's active HF2 Molten Core raid. Confirm all 604 imported bot Gear Plans and receipt records survive.

A future separately approved implementation of **actual automatic loot routing** needs controlled in-game Master Loot candidate/delivery tests, fail-closed per-corpse identity and an owner policy for absent/reserve-unsubmitted players. This preview does not authorize that implementation or enable any live transfer.

Status: **unmerged, uninstalled draft `0.1.0.29-rc.1-dev5`; 42 Lua modules; no downloadable package.**
