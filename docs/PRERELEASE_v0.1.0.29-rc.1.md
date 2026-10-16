# Naxxramas Loot Ledger v0.1.0.29-rc.1 — Pre-release

> **Experimental preview for the Molten Core raid on 17 October 2026.** This is NOT a stable release. It is built from the tested Need Before Greed and Gear Plans Import / Export development stack. Use with backups and normal raid-leader oversight.

**Compatible with:** World of Warcraft 3.3.5a (Interface 30300) and the existing `NaxxLootLotteryDB` SavedVariables layout. **Version in-game:** `0.1.0.29-rc.1`. Existing stable **v0.1.0.28 remains untouched**; no changes were merged into `main` to make this pre-release.

## What is included

- **Need Before Greed:** adds independent `GREED` / off-spec interest in Gear Plans. Existing NEED priority tiers 1–3 always take precedence; GREED becomes a separate equal-chance fallback stage only after all eligible NEED candidates and unresolved NEED blockers have been ruled out. GREED is **not** Tier 4.
- **Safer loot decisions:** keeps candidate review, online/present, role/class, missing-data, manual-only, legendary and leader restrictions; maintains explicit confirmation and stage-aware logging. No automatic item delivery.
- **Improved Gear Plans layout:** six rows per page to prevent the original footer overlap, with NEEDED, GREED, OBTAINED and DISABLED choices. Existing account and Playerbot reservations are preserved.
- **Playerbot plan Import / Export (experimental):** `Wishlists > Gear Plans > Import / Export`. Export a versioned `NLL-GEARPLANS-1` text block. Paste, **Preview Changes**, then explicitly **Confirm ADD**. It adds *new* Playerbot Molten Core plans and skips exact duplicates, but blocks any conflicting existing plans rather than overwriting them. No SavedVariables schema migration.
- **WoW 3.3.5a compatibility fixes:** correctly named scroll widget; safe handling of the client's doubled `||` separators on paste; safe UTF-8 Latin-1 names including `TangØ`; preview invalidated when text or saved plans change.
- **Debug Lab:** non-awarding `/nll sim mc40greed` 40-player fake raid with a GREED-only Quick Strike Ring scenario. Actual imported plans are not needed to exercise fake simulations.

## In-game acceptance recorded (16 October 2026)

- Original values, Gear Plans and the new GREED selection remained usable after the experiment was installed.
- Simulated Quick Strike Ring offered 16 equal GREED candidates and selected fake winner SimPal3 (ticket #9), **without a real server roll or loot award**.
- The owner successfully previewed and explicitly imported five MC batches: **166 + 135 + 164 + 121 + 18 = 604 new Gear Plans** for **38 Playerbots**. The owner confirmed persistence after `/reload`; **Ruby and Arley were excluded as benched**. These 604 records are **NOT included in this public addon ZIP**: they are kept in the owner's personal SavedVariables, not distributed to other players.
- The owner-reported 604-plan import includes 469 NEEDED and 135 GREED reservations in the prepared source. This pre-release does **not** reproduce or publish those personal records.
- Lua 5.1 regression tests and release ZIP integrity/contents checks run on the precise published commit before creation.

## Important limitations / warnings

- **Export Bot Plans is limited to 250 rows per export.** At 604 imported records, one-click bulk export will refuse rather than produce an incomplete backup. For tomorrow's raid, **preserve paired SavedVariables backups**; do not assume Export can back up all 604 entries. A chunked export is planned for a subsequent build.
- **Import is ADD-ONLY.** Existing plans with changed interest, role or status will cause a blocking conflict. It does not update existing entries, import P1/P2 planning metadata, change raid roles or handle multi-copy identical ring/trinket reservations. It doesn't grant loot.
- **Real Master Loot delivery / inventory receipt has NOT been certified** for AzerothCore/Playerbots. **Direct Master Loot defaults OFF on login and `/reload`** and remains experimental. Use existing manual leader awarding rather than relying on experimental automated delivery for valuable raid items.
- All class/role/need/greed entries are requests/intent; they do **not** prove gear-stat suitability, class-quest completion, legal progression, or eligibility for each individual drop. Review item decisions manually.
- The original Lua winner announcement overlay was not independently accepted in-game; fake chat-winner selection was observed.
- PR [#8](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/8) and stacked PR [#9](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/9) remain open development reviews. The pre-release does not merge, close or approve them.

## Install and rollback

1. **Close WoW. Back up BOTH** `Interface/AddOns/NaxxLootLottery/` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.lua.bak` where present. Preserve relevant character-level files. Keep your newly imported 604-plan state before replacing the addon.
2. Download **`Naxxramas-Loot-Ledger-v0.1.0.29-rc.1.zip`** under this pre-release's **Assets**. Do **not** use GitHub's automatically generated source-code archives: those are not the standalone installable addon.
3. Unzip; install the **one** `NaxxLootLottery` folder into `World of Warcraft/Interface/AddOns/`. Do not place an extra parent folder or the ZIP itself in `AddOns`.
4. Restart WoW; run `/nll version` (expected `0.1.0.29-rc.1`), `/nll status` (expected READY), and open Wishlists > Gear Plans to confirm previously imported records survived.
5. Leave direct awarding disabled. For a safe fake test: `/nll debug` if necessary, `/nll sim mc40greed`, `/nll sim select 13`, `/nll sim preview`, then `/nll sim stop`. No real gear should be awarded.
6. If anything regresses: close WoW and **restore the matching backed-up addon folder and SavedVariables `.lua` / `.lua.bak` together**. Do not edit SavedVariables by hand and do not publish them in GitHub issues.

**Build provenance:** the GitHub release tag points to the exact tested pre-release commit. The attached ZIP contains only the addon directory/modules and TOC; `SHA256SUMS.txt` provides an integrity checksum.
