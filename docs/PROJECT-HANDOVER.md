# Naxxramas Loot Ledger — Project Handover

**Repository:** https://github.com/CosmicCuddle/N-Loot-Ledger  
**Project short name:** NLL  
**Development baseline:** `main` at `7169f5d7b8e959d1f0b86f9b7f98913d5288b1bb` (8 October 2026, version `0.1.0.27`)  
**Handover prepared:** 13 October 2026  
**Client:** World of Warcraft 3.3.5a, Interface 30300, Lua 5.1  
**Status:** Development **pre-release**; not independently certified for real Master Loot delivery.

**Unreleased development checkpoint (13 October 2026):** Owner elected to continue with a dark-only UI cleanup. The isolated branch `dev/nll-dark-only-ui` removes the Vanilla theme and appearance-selection panel, retaining existing NLL Dark styling; obsolete skin preferences normalize to DARK without replacing the DB. The branch adds offline Lua 5.1 smoke tests and branch regression CI. Treat this as **pending review and client acceptance**, not a merged fix or public release. No real loot award or SavedVariables destructive operation is authorised. See [dark-only testing checklist](TESTING_DARK_ONLY_UI.md) and the roadmap M5a milestone.

## 1. Purpose and scope

Naxxramas Loot Ledger manages raid loot planning, raid-role and class/gear-needs reviews, wishlists for human players and manual Playerbot gear plans, drop-specific post-drop ticket lotteries, winner/award history and optional opt-in live Master Loot requests. The initial data package is focused on Molten Core. The 40-character/eight-group/13-drop **simulator** is separate from live raid data and does not transfer real items.

This is a **handover to a separate NLL development conversation**. The active N-MultiBot-Chatless draft PR #5 and its Naxxramas Core NT1 integration belong to a DIFFERENT project/chat; do not carry MultiBot changes, presets, server Apply mechanisms or PR state into NLL.

## 2. Exact package identity — preserve compatibility

- **Public project name:** Naxxramas Loot Ledger (NLL).
- **GitHub repository:** `CosmicCuddle/N-Loot-Ledger`.
- **Installed addon directory:** `Interface/AddOns/NaxxLootLottery/`.
- **TOC filename:** `NaxxLootLottery.toc`, `## Interface: 30300`, `## Version: 0.1.0.27`.
- **Global SavedVariables key:** `NaxxLootLotteryDB` (do not rename casually).
- **Primary command:** `/nll`; legacy `/naxxlootlottery` remains.
- Existing addon folders, SavedVariables and slash commands were intentionally kept during rebranding. Do not replace them just because public wording says N-Loot-Ledger.

**Public releases:** `v0.1.0.25`, `v0.1.0.26` and `v0.1.0.27` were published as **pre-releases**. The latest published `v0.1.0.27` includes the installable `Naxxramas-Loot-Ledger-v0.1.0.27.zip` asset. No newer approved code version or open development PR was visible at this handover. Always verify the current branch, PRs, tags and CI again when resuming.

## 3. Latest completed features (0.1.0.27)

- Revisit loot corpse A after B, even across `/reload`, without silently re-rolling previously completed winners. Bounded historical loot-opportunity groups and schema-2-to-3 identity migration.
- For multiple possible matching old loot groups, **block** ambiguous rolls rather than guessing physical corpse identity.
- Keep independent duplicate-item handling where possible; refuse guessing which same-item copy remains when count changes.
- Explicit, audited two-step `/nll newloot` then `/nll newloot confirm` (20-second window) exists **only** when a human leader knows a different corpse is open. It is not permission to re-roll completed drops.
- `/nll botcheck [name]` is an **observational** compatibility check: actual raid roster online/class/role versus saved `BOT_GEAR_PLAN` needs, plus Master Loot candidate dropdown where the game exposes it. This cannot prove the character is AI-controlled or that loot will reach its inventory.
- Optional curated MC priority presets; players can override with guild rules. Manual/class/profession exclusions and custom priorities take precedence.
- Manual award reporting, award history, visually distinct winner announcements, dark/Vanilla presentation, all-ten-class simulation and 40-character MC raid simulation.
- Two-confirmation, opt-in `GiveMasterLoot` path exists but is **OFF on every login or reload**. A request or disappearing loot slot is NOT proof of recipient inventory receipt. Do not turn it on automatically.

## 4. Known limitations — do not misrepresent as completed

1. The client-side WoW 3.3.5a loot APIs used here **do not expose a dependable corpse GUID**; similar item lists can belong to different corpses. Conservative identity lock and manual new-corpse confirmation are mandatory until reliable evidence exists.
2. **Real Master Loot delivery to players or Playerbots is not fully tested/accepted.** The feature is a cautious optional request workflow, not a production-certified distribution service; bot recipient eligibility must be verified in-game for the actual server.
3. The simulator is meaningful regression evidence for internal UI and logic, **not** a substitute for live raid/server testing.
4. Recovered winners from a closed/reloaded loot context remain display-only; direct award is blocked when that original loot slot/candidate state cannot be reverified.
5. Existing `NaxxLootLotteryDB.raidSession.lootIdentity` schema 3 and prior award/winner history require careful migration testing. Do not overwrite or clear user data to fix a presentation issue.
6. Optional built-in loot-priority suggestions target Vanilla/MC and can differ from this server's Individual Progression, custom talents, roles or user-defined guild rules.

## 5. Safe installation, tests and rollback

**Before any addon install:** exit WoW, copy `Interface/AddOns/NaxxLootLottery` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.lua.bak` (and any character-level copies if present). Preserve matching folder and SavedVariables backups together. To undo an upgrade, quit WoW and restore **both** backups; reverting only Lua files may not undo data migration.

**Non-destructive first acceptance:**
- `/nll version` should show `0.1.0.27`; `/nll status` should show READY.
- `/nll lootidentity` reports the active opportunity and archived group count.
- Check whether Debug is enabled before toggling `/nll debug`; `/nll sim mc40` starts an isolated 40-player simulation. Run fake tickets, inspect fake winner and simulated award, then `/nll sim stop`.
- For real Playerbot diagnostics, stop simulation, enter a genuine raid and use `/nll botcheck` or `/nll botcheck BotName`; this is read-only.
- For actual raid/drop identity behaviour, follow `docs/TESTING_v0.1.0.27.txt` and do not force `newloot` merely to make a locked roll available.

**Offline regressions:** `texlua tests/test_loot_identity.lua`, `texlua tests/test_loot_history_and_bots.lua`, `texluac -p` for syntax, and target a WoW 3.3.5a-compatible Lua 5.1 environment. Verify correct available test runner in the new chat; do not claim tests passed without running them.

**High-risk boundary:** do not initiate `GiveMasterLoot`, change real loot candidates, publish a release or alter live-server/SQL data without explicit approval. If the owner later authorises a real transfer test, insist on an expendable item, exact Master Looter/raid context, recipient identity verification, a restorable backup and a documented outcome (including ambiguous delivery).

## 6. Development rules for the follow-up chat

- **First verify current GitHub state** before editing: commit SHA, README, CHANGELOG, TOC, tests, release notes, active PRs and relevant source files. Keep a concise change log and update this handover and `docs/ROADMAP.md` after meaningful work.
- Work **one clear, testable milestone at a time**, or batch related low-risk changes when sensible. The owner prefers practical step-by-step instructions with small visual verification steps.
- For code work, prefer a reviewable development branch/draft PR; do not silently alter released tags/assets, ship a ZIP or change the public N-Addon-Collection. Request explicit owner approval before merging or publishing.
- Maintain the 3.3.5a/Lua 5.1 API contract; avoid modern Retail-only APIs (`C_ChatInfo`, `C_Timer`, `GetLootSourceInfo`, `RegisterAddonMessagePrefix`).
- Preserve original functionality, SavedVariables continuity, historical loot winners, duplicate-roll locks, user-defined priorities and server-side authorization. Always differentiate **request** from **verified receipt**.
- Use actual online Playerbots and the server modules as authoritative only where proven: NLL's client-side `BOT_GEAR_PLAN` is a declared intention, not proof of bot status. Coordinate with Mod-Naxxramas-Core, Individual Progression or other add-ons only if a specific feature genuinely needs it.
- Record what has/hasn't been tested and restore instructions; never claim live-server validation from Lua mocks or screenshots alone.
- **No unapproved destructive operation**: real Master Loot distribution, clearing SavedVariables/history, bulk migration, SQL/DBC/server changes, or dangerous automation all require an independent safety/rollback plan and express consent.

## 7. Canonical project references

- [Repository README](../README.md)
- [Changelog](../CHANGELOG.md)
- [Development roadmap](ROADMAP.md)
- [Version 0.1.0.27 test checklist](TESTING_v0.1.0.27.txt)
- [Version 0.1.0.27 pre-release notes](PRERELEASE_v0.1.0.27.md)
- [Compatibility and rollback](COMPATIBILITY.md)
- [Data-source policy](DATA_SOURCES.txt)
- [Priority preset policy](PRESET_POLICY.txt)

## 8. Resumption checkpoint

**No new NLL feature request has yet been established in the present MultiBot handover conversation.** The new NLL chat should read this file and `docs/ROADMAP.md`, review current GitHub HEAD, summarize what is ready and what needs live verification, and ask the owner which NLL enhancement or issue to address first. Do not assume a release, live award or new feature has already been approved.

**Current separation:** N-MultiBot-Chatless remains an unfinished independent conversation awaiting Mod-Naxxramas-Core's equipment/talent reset investigation, with its own `docs/NT1-UI-HANDOVER-2026-10-12.md` and draft PR #5. NLL development should not disturb that work.
