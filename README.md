# Naxxramas Loot Ledger (NLL)

**Raid loot planning, wishlists, post-drop ticket lotteries, and award tracking for World of Warcraft 3.3.5a (Wrath of the Lich King) on AzerothCore.**

**Latest published version:** `v0.1.0.28` (stable-core release, 13 October 2026)  
**Current owner raid installation:** `0.1.0.29-rc.1-hf2` — preserve this working build and its SavedVariables until the owner approves testing.  
**Current development:** Stacked draft PRs #10, #12–#17 and #22–#25; latest experimental draft `dev/nll-recipient-self-attestation` is `0.1.0.29-rc.1-dev10` (41 Lua modules). These new features are **not installed, merged or released**.  
**Status:** Direct Master Loot remains **experimental, unverified and OFF by default**. Live boss loot and bot inventory delivery are not certified.

**Historical release sequence:** PRs #2, #3 and #6 have been merged into `main`, and v0.1.0.28 was published. The new Need Before Greed branch does not alter that release or activate real awarding.

## Development tracker and test plan

- [Comparison of parallel PRs #18–#21](docs/REVIEW_PARALLEL_DRAFTS.md) — safety work imported into the main draft path versus deferred recipient-attestation design.
- **[MASTER DEVELOPMENT CHECKLIST](docs/MASTER_DEVELOPMENT_CHECKLIST.md)** — the authoritative stage-by-stage record of every past, current, parallel and planned NLL feature, plus completed CI, unfinished WoW testing and future actions.

- [Rolling development tracker](docs/DEVELOPMENT_TRACKER.md) — stage-by-stage status, automated checks, pending work, and owner action items.
- [Integrated WoW acceptance checklist](docs/INTEGRATED_RAID_TEST_CHECKLIST.md) — live raid, Playerbot reservations, cross-client receipt and backup/rollback steps.
- [Reconciliation interface acceptance](docs/TESTING_RECONCILIATION_UI_DRAFT.md) — no-retry modal behaviour and separate receipt proofs.

Development branches are *not* installation instructions. Follow the approved release guide for the published version only; do not replace your installed HF2 with these drafts.

## Features

- Molten Core item browser and configurable loot priority rules with optional presets.
- Gear wishlists for players and persistent manual gear plans for Playerbots.
- **Under development (not in v0.1.0.28):** **Need Before Greed**: Gear Plans support `NEEDED`, `GREED`, `OBTAINED`, `DISABLED`. NEED uses configured Tier 1–3 rules; GREED is a **separate equal-interest stage, never Tier 4**, considered only when no eligible/unresolved Need blockers remain. Manual-only items remain manual. [Draft PR #8](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/8), [testing guide](docs/TESTING_NEED_BEFORE_GREED.md).
- **Separate experimental branch (not published or installed):** Playerbot Gear Plans **Import / Export** with a bounded `NLL-GEARPLANS-1` copy/paste format, read-only dry-run preview, explicit Confirm ADD, identical skips and no changes to existing plans, roles, wishlists or history. [Safe test guide](docs/TESTING_GEAR_PLAN_TRANSFER.md).
- **My Wishlist → Gear / Items** and **Recipes** separate the display of existing reservations. Both groups are still submitted together to the raid leader; profession recipe allocation is **manual-only**.
- Class/role eligibility checks, candidate review and drop-specific ticket lotteries.
- Clear, visual winner announcements and winner persistence across multiple drops.
- Saved loot-opportunity identity: same-looking reopened loot keeps its original roll lock and winner across `/reload`, with archived-group recovery and a conservative confirmation path for new corpses.
- Manual award reporting and an Award History screen.
- **Opt-in** two-stage real Master Loot request with revalidation; **disabled at every login and reload**.
- 40-character Molten Core simulation with eight groups, class-specific equipment plans, 13 mock loot drops and fake award confirmations.
- NLL Dark interface only; legacy Vanilla/Classic appearance preferences are safely normalized to Dark, without replacing saved wishlist or loot history.

## Installation (WoW 3.3.5a)

1. Before changing anything, **back up** your current `Interface/AddOns/NaxxLootLottery` folder, and the NLL SavedVariables files from `WTF/Account/<account>/SavedVariables/` (and character-level SavedVariables if present).
2. For the published version, download the `v0.1.0.28` release asset (not the repository source ZIP or the unmerged fallback branch). For safe installation and rollback steps see [v0.1.0.28 install guide](docs/INSTALL-v0.1.0.28.md). Extract **only the `NaxxLootLottery` directory** into `World of Warcraft/Interface/AddOns/`.
3. The final path must be `Interface/AddOns/NaxxLootLottery/NaxxLootLottery.toc`. Avoid accidentally nesting a second `NaxxLootLottery` folder.
4. Restart the WoW client or enter `/reload`. If the addon is marked out of date, verify your client build is 3.3.5a (Interface 30300).
5. Enter `/nll version` and `/nll status` to confirm version **`0.1.0.28`** and **`READY`** in the published build. Development features are not included in that release.

**Compatibility note:** The installed addon directory is still **`NaxxLootLottery`**, the SavedVariables name remains **`NaxxLootLotteryDB`**, and chat commands remain **`/nll`**. These are intentionally unchanged during the public rename to preserve existing installations and preferences.

## Main commands

| Command | Purpose |
| --- | --- |
| `/nll` | Open/close NLL |
| `/nll roles` | Raid roles |
| `/nll search` | Raid loot browser |
| `/nll wishlist` | Gear wishlists and Playerbot plans |
| `/nll current` | Current detected loot |
| `/nll priorities` | Loot priority setup |
| `/nll presets on` | Enable optional built-in Molten Core presets |
| `/nll reviewpool` | Review current drop candidates |
| `/nll awardreview` | Review a winner's award |
| `/nll awardhistory` | View real award history |
| `/nll settings` | Preferences, Debug Lab and Loot Awards |
| `/nll directaward off` | Immediately disable optional direct awarding |
| `/nll lootidentity` | Show the active loot-opportunity ID and saved archive size |
| `/nll botcheck [name]` | Read-only preflight of actual raid members with saved Playerbot gear plans |
| `/nll newloot` | Begin explicit confirmation for a DIFFERENT corpse when loot overlaps |
| `/nll newloot confirm` | Confirm within 20 seconds; only while real raid loot is open |
| `/nll status` | Diagnostics |
| `/nll help` | Full command list |

### Test a complete 40-player raid without spawning bots

1. Enable Debug mode: `/nll debug` (toggles debug, so check its current state).
2. Start `/nll sim mc40`.
3. Inspect fake raid members in **Raid Roles**, needs in **Wishlists**, and 13 fake drops in **Current Loot**.
4. For a contested drop, use `/nll sim select 12` and then the normal Prepare Tickets / Start Roll process.
5. Confirm the **fake** award in the visual award review. No real inventory or loot is modified.
6. Stop with `/nll sim stop`.

You can also test every class individually (`/nll sim mage`, `/nll sim warrior`, `/nll sim deathknight`, etc.), or `/nll sim all` for a 20-character group.

## Loot recovery and preventing duplicate lotteries (v0.1.0.27)

- Reopening the same Molten Core loot window **reuses** stable per-drop identifiers, including when returning to A after visiting different corpse B. Completed winners remain visible after a client reload and are blocked from a second ticket draw.
- Earlier groups remain in a bounded ledger; multiple matching historical groups are considered ambiguous and cannot automatically enter a lottery.
- **WoW 3.3.5a does not provide a trustworthy corpse GUID through the loot APIs used here.** NLL conservatively treats overlapping loot signatures as the same opportunity, even when they may belong to a different corpse. It cannot prove corpse identity.
- If a **different** corpse has an overlapping item list, with that corpse's real loot window open, a raid leader/officer types `/nll newloot` followed by `/nll newloot confirm` within 20 seconds. **Never use this to re-roll a previous drop.** The manual reset is audited.
- Multiple identical copies of the same item are tracked independently, but if one disappears and NLL cannot determine which remains, further draws on ambiguous copies are blocked instead of guessing.
- A recovered winner is **viewable**, not automatically awarded. After the loot window closes (or `/reload`), direct NLL awarding of that previously completed winner is blocked. Use WoW's normal UI for manual handling as appropriate; no item delivery is inferred from a saved winner.
- Previous pre-v0.1.0.27 loot-window IDs were not persistent corpse identifiers and cannot be retroactively matched. For safety the stale on-screen queue is cleared on the first migration, but existing lottery/award history is kept.

## Read-only Playerbot compatibility preflight (v0.1.0.27)

Run `/nll botcheck` in an **actual raid** (not the Debug Lab) after saving Playerbot Gear Plans in Wishlists. It reports roster presence, online status, live client class, assigned role and counts of NEEDED plans. `/nll botcheck BotName` gives detailed status. Opening a genuine WoW Master Loot item dropdown also enables a read-only candidate-list check. **These observations do not prove a character is a server-side AI Playerbot or that it can receive the equipment.** If the client cannot expose a valid class, it is reported as unverified even if a saved class is available.

## Important award safety information

- Fake raid and fake lottery data are isolated from real records.
- **Live direct awarding is experimental / not certified, OFF by default and resets OFF every login or `/reload`.**
- Real awards require explicit manual confirmations, an actual eligible winner, an open matching loot slot, and Master Looter authority.
- A request sent by `GiveMasterLoot` **does not prove item receipt**; NLL tracks the request, observed slot clearing, and uncertain outcomes separately. An item slot disappearing is not an independent delivery receipt.
- Never test automatic item transfer with valuable gear until you have first validated the flow on your server using expendable items.
- Back up your addon and SavedVariables before upgrades; installation rollback involves restoring **both** backups.

## Development and compatibility

- Target: World of Warcraft **3.3.5a**, `## Interface: 30300`.
- Language: **Lua 5.1**, Wrath-era UI APIs.
- No modern `C_ChatInfo`, `C_Timer`, `GetLootSourceInfo`, or `RegisterAddonMessagePrefix` dependencies.
- The initial item library focuses on **Molten Core**; priorities are editable, not mandatory universal rules.
- Reproducible loot-identity regression tests: `texlua tests/test_loot_identity.lua` and `texlua tests/test_loot_history_and_bots.lua` (TeX Lua runner) and `texluac -p` for Lua module syntax.
- The 0.1.0.28 review code includes Lua 5.1 tests for the Dark-only UI, recipe grouping, Overview, Search, Inbox and loot-identity safety, plus `python3 tests/test_release_packaging.py` for the installable release-candidate ZIP. The [candidate-build workflow](.github/workflows/validate-v0.1.0.28-candidate.yml) does **not** publish a release.
- This repository includes **source code**, not personal SavedVariables, characters, raid histories, or server database exports.

## Documents

- [Project handover — new development chats](docs/PROJECT-HANDOVER.md)
- [Development roadmap and safety milestones](docs/ROADMAP.md)
- [Changelog](CHANGELOG.md)
- [v0.1.0.28 release-candidate checklist](docs/RELEASE_CHECKLIST_v0.1.0.28.md)
- [v0.1.0.28 prepared release notes](docs/RELEASE_NOTES_v0.1.0.28.md)
- [v0.1.0.28 safe install/rollback](docs/INSTALL-v0.1.0.28.md)
- [Prior v0.1.0.27 test checklist](docs/TESTING_v0.1.0.27.txt)
- [Data sources](docs/DATA_SOURCES.txt)

## License

A reuse license has not yet been selected by the repository owner. Public source visibility alone does not grant permission to redistribute or modify it. A `LICENSE` file can be added once a license is chosen.
