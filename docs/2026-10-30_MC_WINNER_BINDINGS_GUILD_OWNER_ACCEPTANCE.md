# NLL Molten Core: reserved Windseeker rolls, bot receipts, guild materials
Date: 2026-10-30 | Owner acceptance: PENDING | GitHub: DRAFT ONLY

## Live owner findings
- User reports manual Master Loot succeeded; actual bots now have awarded items.
- The previous emergency draft lets the leader attest an exact bot/item as locally OBTAINED without rewriting physical receipts.
- Some saved reservations (both Windseeker binding halves) never opened tickets.
- Lava Core, Core of Earth and similar reagent drops need a distinct Guild route targeting the real guild master.

## Exact implementation
1. **Existing normal winner lock is unchanged.** Completing a server roll creates WON_AWAITING_ITEM and captures the winner's saved active NEEDED/GREED Gear Plans. It does **not** mark OBTAINED or call GiveMasterLoot.
2. After the leader separately records an already-performed WoW manual Master Loot award in Award Winner, NLL now immediately opens the existing two-step **I Checked Inventory -> MARK OBTAINED** receipt UI if this real win has a receipt record. Only after that deliberate confirmation does LootReceiptTracker update matching saved needs and (for the local player only) local wishlist data. This is **not automatic on rolling**; NLL has no independent proof of bot inventory.
3. For Molten Core item IDs **18563 and 18564**, a controlled reservation-only (NEED first, GREED second) equal-ticket lottery is permitted despite their existing manualOnly data label and missing role-priority configuration. A participant must have an actual saved matching need/greed, be present and online in the raid, have known live/saved class and pass the inherent Warrior/Paladin/Hunter/Rogue class restriction. Leader review/exclusions and all duplicate-winner locks still apply. No legendary is awarded automatically; no unreserved character may be pulled into tickets by UI addition.
4. Explicit guild material item IDs: **17011 Lava Core, 17010 Fiery Core, 17012 Core Leather, 11382 Blood of the Mountain, 7075 Core of Earth**. A cached, unlocked, unreserved item appears in Guild Loot with a **Guild** review button, not a regular normal ticket. Reserved/uncertain records and other special/legendary/quest items remain held.
5. Guild material transfer requires the guild member with **rankIndex=0 (actual guild master)** to be online, in the current raid once, and present exactly once in the current Blizzard Master Loot candidate list. If guild master != raid leader, use the guild master; never guess or fallback. The operator must be the designated WoW Master Looter, with BOTH direct-award and guild-transfer toggles explicitly opted in. Review -> Arm -> Confirm rechecks exact item link/slot/quantity/recipient/candidate each time. A physical attempt is auditable before GiveMasterLoot; request success is not receipt evidence; no retry of the same item ID without future trusted server-side instance evidence.

## Testing
- Lua 5.1 full historic suite + all source/test syntax + deterministic test-only ZIP.
- New `tests/test_windseeker_reserved_roll.lua`: both halves, equal reserved NEED, GREED after NEED, excluded class/unreserved, material still manual, no awarding.
- New `tests/test_guild_master_materials.lua`: distinct guild master, guild roster and online/raid presence, candidate drift, once-only transfer, unknown outcomes.
- Updated guild transfer fixture with a separately verified Guild Master and guild UI fixture verifying material-specific button label.
- **Never** make a live loot transfer during an automated test.

## Owner manual acceptance (backup before changing addon)
1. **Outside combat** exit WoW normally. Save a separate copy of the CURRENT `Interface/AddOns/NaxxLootLottery` and current `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` (plus account-specific backups if relevant). Do not merge an older SavedVariables into a newer profile.
2. Download the ZIP + SHA256 from the exact passing Actions artifact. It is a **test build based on C15 dev20 + emergency fix**, not a public release. Extract the nested ZIP to `Interface/AddOns/NaxxLootLottery` with exactly one addon folder. The in-client version remains dev20, so use BUILD_INFO source SHA to identify the hotfix.
3. In a safe non-live / expendable loot test, load addon and run `/nll version`, `/nll status`, `/nll directaward off`. Verify old Gear Plan counts, old receipts and award locks still present.
4. For a Windseeker half, test with **read-only saved reservations first**: eligible present two characters in NEED -> Preview -> Prepare -> Start Roll. Confirm losing/offline/unreserved/invalid-class characters never join; after winner, item remains **pending item**. Do not perform a real test award with a rare legendary.
5. Rehearse the existing receipt flow using a test consumable / controlled safe fixture: report award via **I Awarded It in WoW** only after actual manual Blizzard action, see the inventory-check review, confirm only after the recipient truly has item. Check only matching Gear Plans become OBTAINED; original receipts, locks preserved.
6. Check Guild Loot with an expendable material while the **guild master and raid leader differ**. Before touching transfer toggles, confirm Guild row shows correct guild master; unavailable/offline/absent guild master must refuse. Review without giving; only do the physical test when owner has explicitly consented to consuming that actual item. After real test, confirm exact candidate and that repeated attempts are blocked.

## Known constraints / no-deployment claims
- Source/test CI success is NOT in-client 3.3.5a acceptance, no automation is live on user’s existing installed addon until they install the exact test build.
- An actual bot’s bags are **not visible via standard WoW addon API**. Winner alone and loot slot clearing do not prove item delivery.
- Multiple physically different *copies* of the same guild material are not safely distinguishable by standard 3.3.5a APIs. The existing conservative item-ID no-retry lock deliberately blocks subsequent same-ID requests until a future authenticated item-instance source bridge exists.
- Other legendary/manual item IDs remain excluded from the special binding lottery.
- No release/tag/merge/SQL/core/server work. All changes live in a separate draft branch.
