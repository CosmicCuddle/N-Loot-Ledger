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
- [ ] Inspect remaining WoW 3.3.5a Wishlists, Current Loot, Debug Lab and award panels at the owner's UI scale.
- [ ] Confirm installation and matched SavedVariables rollback with an expendable/throwaway test copy.
- [ ] Only with owner's approval merge or publish; update v0.1.0.27 references when a **new** version is explicitly agreed.
- Review: [draft PR #2](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/2) (not merged). Reference: [Dark-only testing checklist](TESTING_DARK_ONLY_UI.md).

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
