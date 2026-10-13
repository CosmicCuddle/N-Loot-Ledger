# Naxxramas Loot Ledger — Development Roadmap

**Repository:** https://github.com/CosmicCuddle/N-Loot-Ledger  
**Current baseline:** `v0.1.0.27` pre-release, `main` source `7169f5d7b8e959d1f0b86f9b7f98913d5288b1bb` at handover  
**Last reviewed:** 13 October 2026  
**Scope:** N-Loot-Ledger / `NaxxLootLottery` addon, WoW 3.3.5a, Lua 5.1.  
**Companion handover:** [PROJECT-HANDOVER.md](PROJECT-HANDOVER.md)

## Current position

The NLL source is published as development pre-release `0.1.0.27`. The latest completed additions are:

- Historical loot-opportunity identity recovery across A → B → A visits and `/reload`, with bounded archived groups, conservative ambiguous-group denial and in-place schema-2-to-3 migration.
- Explicit, logged manual `/nll newloot` / `/nll newloot confirm` for a **different** physical corpse with overlapping loot, not for re-rolling a previously completed drop.
- Read-only `/nll botcheck [name]` preflight for **real raid** roster presence, online/class/role validation and optional actual Master Loot candidate listing, without relying on an invented Playerbot API.
- Existing 40-person Molten Core Debug Lab (eight groups, 13 fake loot drops), custom and optional curated priority rules, personal and Playerbot gear needs, drop-specific tickets, winner announcement/history and two-stage optional Master Loot request.

**Evidence boundary:** the repo reports in-game simulation testing, and contains Lua regression tests. It does **not** claim successful real Master Loot delivery to players or Playerbots. No real-award integration test has been newly performed or authorised during this handover. Do not treat source tests, a candidate dropdown or a disappearing loot slot as a delivered-item receipt.

## Milestones

### M0 — Handover and branch hygiene (documentation only; complete)

- [x] Identify correct public repository `CosmicCuddle/N-Loot-Ledger` and current pre-release identity.
- [x] Record installation identity (`NaxxLootLottery` folder, `NaxxLootLotteryDB`, `/nll`) and version `0.1.0.27`.
- [x] Create [project handover](PROJECT-HANDOVER.md) and this roadmap for a dedicated future NLL conversation.
- [x] Keep N-MultiBot-Chatless, its draft PR #5 and the pending Naxxramas Core NT1 work **independent**.
- [ ] New conversation: verify latest HEAD, tags, release assets and open PRs; compare against this 13 October handover.

### M1 — Safe client baseline (next candidate; owner to confirm scope)

- [ ] Keep a copy of working `Interface/AddOns/NaxxLootLottery` and matching `WTF/.../SavedVariables/NaxxLootLottery.lua` + `.bak` files before installation.
- [ ] Confirm `/nll version` shows `0.1.0.27`, `/nll status` READY and `/nll lootidentity` a sensible ledger summary in the real client.
- [ ] Re-check `/nll sim mc40`, fake ticket selection, fake winner, fake award, and `/nll sim stop`; ensure simulation does not create real award records.
- [ ] Execute `tests/test_loot_identity.lua` and `tests/test_loot_history_and_bots.lua` under a suitable Lua 5.1-compatible runner; maintain syntax checks.
- [ ] If screenshots reveal a visual defect, fix in a reviewable development branch with a narrow regression and fresh ZIP; do not silently ship.

### M2 — Conservative loot-identity robustness (investigate, not pre-authorised to rewrite)

- [ ] Inspect natural multiple-corpse A → B → A and duplicate-item cases in a controlled raid without real item transfer.
- [ ] Confirm archive ambiguity never opens a new roll merely because of a `/reload` or an identical new item list.
- [ ] Confirm `/nll newloot` requires a **known different corpse**, valid raid context, exact two-step 20-second confirmation, and leaves an audit trail.
- [ ] Preserve historical winners/award state through schema migration and restore. Use backed-up throwaway SavedVariables to test migration/rollback; never clear production history.
- [ ] Document unavoidable **no reliable corpse GUID** limitation; avoid inferring true corpse identity from item links alone.

### M3 — Actual Playerbot observations (read-only first)

- [ ] In an actual raid with saved BOT_GEAR_PLAN needs, run `/nll botcheck` and `/nll botcheck BotName` for representative online/offline roles and classes.
- [ ] Optionally open a real Master Loot candidate dropdown for an expendable item; verify whether the expected recipient appears. **Do not select/award yet.**
- [ ] Distinguish **in roster**, **eligible candidate**, **verified Playerbot**, **loot request accepted** and **item actually received**. The client does not generally prove all these states.
- [ ] Compare against the specific current AzerothCore, Playerbots and Individual Progression environment only where verified; no undocumented server integration assumptions.

### M4 — Award request safety (blocked on separate owner approval)

- [ ] Review explicit opt-in, session-reset OFF state, the two confirmations and last-moment candidate/loot-slot revalidation.
- [ ] Keep `GiveMasterLoot` **disabled** for routine tests. A normal request or slot clearing must not be marked as confirmed inventory receipt.
- [ ] Only if the owner expressly authorises controlled live award testing: choose an expendable item and disposable/controlled recipient; capture before/after inventories or trustworthy server-side receipt and preserve rollback/backups. Record failure/uncertainty distinctly.
- [ ] Preserve recovery winners as display-only when their original loot slot is closed or cannot be revalidated.

### M5a — Dark-only UI (in review; not merged or released)

- [x] Prepare isolated `dev/nll-dark-only-ui` branch from the verified 13 October `main`.
- [x] Remove Vanilla presentation and selection; preserve NLL Dark visuals, widget dimensions and hover states.
- [x] Normalize legacy skin preferences to `DARK` in the existing SavedVariables table, without touching loot or award records.
- [x] Add an offline Lua 5.1 dark-skin/persistence/settings smoke test and a GitHub Actions regression workflow.
- [x] Lua 5.1 workflow and existing loot-history tests passed on the development branch ([successful CI run](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/38396113585)).
- [x] Owner's first WoW screenshot confirms Dark-only Settings tabs and Direct Master Loot OFF. Priority Setup screenshot revealed preset controls overlapping the bottom border; footer anchoring and regression test added to draft PR #2 (awaiting owner visual retest).
- [x] Priority Setup footer visually rechecked in the owner's WoW 3.3.5a client on 13 October 2026: footer now entirely inside the panel, 136 presets still displayed enabled, paging and summary visible. No functional priority changes made.
- [x] Owner's My Wishlist screenshot reviewed: four Molten Core entries visible; layout/navigation intact and owner confirms retained entries. Gear Plans and remaining panels still require review.
- [x] Owner's Gear Plans screenshot reviewed on 13 October 2026: empty list (0 saved needs), entry controls, filtering and navigation display correctly. No Playerbot plans were created or modified.
- [x] 40-person MC fake raid started in owner's WoW client: Raid Roles screenshot shows simulation indicator, reported 40 bots in eight groups, normal role dropdowns and page 1/4. This is first-page visual evidence, not verification of all entries, rolls or loot delivery.
- [x] Owner's Current Loot screenshot confirms 13 fake MC40 drops, pagination page 1/3 and three simulated eligible Gauntlets of Might contenders: main tank at tier 1 and two tanks at tier 2. No clipping seen; ticket preparation/roll not yet tested.
- [x] Owner ran MC40 `Preview Pool` against Gauntlets of Might: SimWar1 uniquely selected in Tier 1; two Tier 2 candidates waiting; zero excluded. UI/chat both explicitly say no roll or award. Screenshots inspected on 13 October 2026.
- [x] In-client MC40 fake ticket preparation verified visually on 13 October 2026: Gauntlets of Might shows one Tier 1 ticket ready; chat also confirms one fake ticket prepared. Start Roll/award still pending. Cosmetic follow-up: use singular `ticket` for 1 in UI/chat.
- [x] MC40 in-client fake roll verified visually on 13 October 2026: SimWar1 wins Gauntlets of Might with ticket #1, winner overlay and item-row history update, `PENDING AWARD` remains; fake/no-real-award text visible. Next: duplicate-roll guard and separate simulated award review (not a real transfer).
- [x] Owner confirmed the duplicate-roll UI gate after fake MC40 Gauntlets of Might win: Start Roll cannot be activated while SimWar1 (#1) remains the winner and status is PENDING AWARD. This checks the disabled UI gate, not a second invocation of the underlying rejection handler. Next: simulated award review and fake receipt.
- [x] Owner reviewed fake Award Review modal on 13 October 2026: Gauntlets of Might -> SimWar1 shown; simulation-only warning and two safe controls visible; real Direct Award control correctly hidden. Awaiting separate fake confirmation test (no actual award).
- [x] Owner confirmed `Confirm Fake Award` on Gauntlets of Might in the MC40 simulator (13 October 2026): `Winner: SimWar1 [SIMULATED_AWARDED]` and `[FAKE AWARDED]` now displayed; needed count falls from 3 to 2, retaining SimWar2/SimWar3 and removing the fake winner from the need list. Chat explicitly reports `No real item moved.` This confirms one simulated end-to-end loot cycle, not persistence or a real award.
- [x] After `/nll sim stop`, owner's My Wishlist screenshot confirms `[SIMULATION - FAKE RAID]` banner gone and original four Arcanist items (Belt, Bindings, Boots, Crown) still listed at 4/4 with normal navigation. This verifies visual return to normal wishlist, not yet a full persisted-data or reload test.
- [ ] Verify post-simulation Gear Plans remain empty, Molten Core presets remain 136 active, real award/history state unchanged, and remaining Settings panels; use only non-destructive UI review.
- [ ] Confirm installation and matched SavedVariables rollback with an expendable/throwaway test copy.
- [ ] Only with owner's approval merge or publish; update v0.1.0.27 references when a **new** version is explicitly agreed.
- Review: [draft PR #2](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/2) (not merged). Reference: [Dark-only testing checklist](TESTING_DARK_ONLY_UI.md).

### M5b — Debug Lab raid-size scenarios (proposal only; not approved for code)

- [x] Owner-supplied WoW 3.3.5a screenshot visually confirms current Debug Lab panel is displayed, with no obvious clipping or overlap; the simulator was not started during this check.
- [ ] Discuss replacing prominent special-case scenario buttons (Mage Contest, Healer Loot, Guild Item, Missing Role) with raid-size simulation choices, potentially 10/20/25/40 fake players plus optionally other five-player increments.
- [ ] Preserve specialist safety regression scenarios behind an Advanced Tests menu or slash commands rather than deleting their engine coverage.
- [ ] Replace fixed SimBryn-only exclusion/offline controls with targeting of a selected simulated character; SimBryn does not exist in 40-player MC scenarios.
- [ ] Preserve the existing isolated 40-person/eight-group/13-drop stress test and no-SavedVariables/no-server-transfer guarantees; validate realistic, size-dependent compositions and contender pools.
- [ ] Agree exact UI scope, fixtures, regression tests and a separate reviewable development branch with owner before implementing.

### M5 — UI, raid policy and release candidate (future proposals, not yet agreed scope)

- [ ] Ask owner which NLL enhancement, interface screen or problem they want addressed first. Avoid speculative feature batches.
- [ ] Preserve manual guild priorities over optional curated Molten Core presets; don't silently populate decisions or auto-award.
- [ ] Consider UI readability and dyslexia-friendly spacing only when concrete screenshots reveal issues or the owner requests design changes; verify in WoW 3.3.5a at their real UI scale.
- [ ] If a candidate is approved, maintain CHANGELOG, documentation, source tests and a safe install/rollback artifact.
- [ ] Only after explicit owner permission: open/merge PR, create release, publish pre-release or update N Addon Collection. Public releases `v0.1.0.25–27` remain untouched otherwise.

## Engineering and review constraints

- Only WoW **3.3.5a / Interface 30300 / Lua 5.1** compatible APIs. Avoid modern Retail-only functionality.
- Protect item identity, award history, saved priority/needs rules and persisted schema; migration needs fixture tests and matched backups.
- **No automatic irreversible action** on page open, character target change, roll preview, loot reopen, bot class/role display or simulation.
- No live loot award, NLL SavedVariables deletion, database modification or server changes without express approval, backups and a rollback plan.
- Prefer a narrow draft branch/PR for code, batch related changes sensibly, run offline regressions and use in-client screenshots for final UI acceptance.
- Do not merge with or modify N-MultiBot-Chatless/Naxxramas Core code while developing NLL unless the owner explicitly starts a separately documented integration workstream.

## Resume instructions for a new chat

1. Read `docs/PROJECT-HANDOVER.md`, this roadmap, README, CHANGELOG, and latest TESTING/COMPATIBILITY notes.
2. Recheck repository branch HEAD, pre-release assets, PRs and source; note differences from the recorded `7169f5d7...` baseline.
3. Confirm the exact NLL feature/problem the owner wants next. **No new NLL task is implicitly authorised by creating this handover.**
4. Create a small implementation/test plan with a backup and rollback boundary before touching persistent loot records or any real-award path.
5. Keep this roadmap current after each meaningful milestone so a future conversation can continue accurately without reconstructing context.
