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
- [x] Owner's 13 October 2026 client screenshot: `/nll version` reports `0.1.0.27`; `/nll status` reports `Initialization status: READY`; `/nll lootidentity` reports no current loot opportunity, 0 previously assigned items and 0 archived groups. This is a valid empty-ledger baseline; persistence of an actual prior winner/archive remains untested.
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

- [x] Owner ran `/nll botcheck` in a real 39-member raid on 13 October 2026 and confirmed the expected empty-plan diagnostic (`No saved Playerbot gear plans...`). This proves the command's zero-plan path behaves normally, **not** actual Playerbot compatibility. Gear Plans still have 0 saved needs; no test plan was created. Any single-plan test must be owner-approved, backed up, removable, and strictly non-awarding.
- [x] Owner's 13 October 2026 real Raid Roles screenshot shows **39 raid members**, page 1/4, with names/classes/online status and saved NLL role values (e.g. Gorak Main Tank, Eiga Tank, Arndor and Rakari Healer).
- [x] Owner later inspected all four roster pages and confirmed all members appeared without overlaps or missing rows; separate page-2 screenshot shows real classes/online status and some legitimately `UNASSIGNED` NLL roles. Owner confirmed previously assigned roles **persisted after `/reload`**. This verifies in-client roster/role persistence, but not the underlying bot AI identity, all members' eligibility, or actual loot/item delivery.
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
- [x] Post-simulation Priority Setup screenshot confirms presets unchanged: 136 active, 0 custom, 0 drafts, 22 manual, 2 unconfigured; footer remains correctly laid out.
- [x] Owner's post-simulation Real Loot Award History screenshot on 13 October 2026 shows 0 records (Page 1/1), no SimWar1 or Gauntlets of Might fake award, and correct informational text. Confirms fake award absent from the visible real history; no prior non-empty history baseline was established.
- [x] Owner verbally confirmed post-simulation Gear Plans still display `0 saved Gear Need(s)` (13 October 2026); no screenshot required for this straightforward count. This supports absence of persisted fake Playerbot Gear Plans in the displayed view.
- [x] Owner confirmed **Direct Master Loot: OFF** in Settings > Loot Awards after completing and stopping the MC40 simulation (13 October 2026). All tested fake awards remained isolated; no actual loot transfer was authorised or attempted.
- [x] Owner confirmed their original four Arcanist Wishlist entries remained present after `/reload` on 13 October 2026. This verifies real-client reload persistence of the personal wishlist, not a full historical database/rollback exercise.
- [x] Owner confirmed the Overview screen looks and works normally after the simulator was stopped; visual confirmation only, no screenshot or exhaustive functional test (13 October 2026).
- [x] Owner confirmed Raid Loot Search loads the Molten Core library and searching for `Arcanist` displays expected results without reported overlap or Lua errors (13 October 2026); no screenshot required for routine positive UI checks.
- [x] Owner confirmed Wishlist Inbox opens and works as intended (13 October 2026); no Accept or Reject actions were needed. All planned interface panels have now been visually checked at the owner's in-game UI scale, although this is not exhaustive functional validation.
- [ ] Decide exact real-raid read-only acceptance checks and perform them safely before a stable release.
- [x] Owner confirmed making backups before both in-client development installations; contents of backups have not been independently inspected.
- [ ] Perform an actual paired addon-folder/SavedVariables rollback rehearsal only on an expendable test copy, not on the owner's sole live data. Preserve original backup sets.
- [ ] Only with owner's approval merge or publish; update v0.1.0.27 references when a **new** version is explicitly agreed.
- Review: [draft PR #2](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/2) (not merged). Reference: [Dark-only testing checklist](TESTING_DARK_ONLY_UI.md).

### M5b — Debug Lab raid-size scenarios (proposal only; not approved for code)

- [x] Owner-supplied WoW 3.3.5a screenshot visually confirms current Debug Lab panel is displayed, with no obvious clipping or overlap; the simulator was not started during this check.
- [ ] Discuss replacing prominent special-case scenario buttons (Mage Contest, Healer Loot, Guild Item, Missing Role) with raid-size simulation choices, potentially 10/20/25/40 fake players plus optionally other five-player increments.
- [ ] Preserve specialist safety regression scenarios behind an Advanced Tests menu or slash commands rather than deleting their engine coverage.
- [ ] Replace fixed SimBryn-only exclusion/offline controls with targeting of a selected simulated character; SimBryn does not exist in 40-player MC scenarios.
- [ ] Preserve the existing isolated 40-person/eight-group/13-drop stress test and no-SavedVariables/no-server-transfer guarantees; validate realistic, size-dependent compositions and contender pools.
- [ ] Agree exact UI scope, fixtures, regression tests and a separate reviewable development branch with owner before implementing.

### M5c — Recipe wishlist separation (requested before first stable release; review branch)

- [x] Owner requests that **reserved recipes have their own area under My Wishlist** so they are no longer mixed with gear (13 October 2026).
- [x] Implement **Gear / Items** and **Recipes** subviews without changing the existing wishlist SavedVariables table, recipe manual-only allocation, combined leader submissions or any live award path; independent branch `dev/nll-recipe-wishlist-tabs` is based on unmerged dark-only PR #2.
- [x] Add `tests/test_recipe_wishlist.lua` and Lua 5.1 CI coverage; see [recipe acceptance checklist](TESTING_RECIPE_WISHLIST.md).
- [x] Owner's Overview screenshot (13 October 2026) showed **11** reserved Molten Core items and the obsolete `Full wishlist view coming in Phase 4.` summary placeholder. Replace with `Full list: Wishlists > My Wishlist.` (fake-raid-specific guidance when simulated); add `tests/test_overview_wishlist_copy.lua`. Check for other user-visible stale `Phase` messages in UI sources: only this instance found.
- [x] Owner's post-install Overview screenshot confirms `+ 6 more reserved item(s)` and `Full list: Wishlists > My Wishlist.` replacing the obsolete Phase 4 placeholder; two-line text remains within its row without apparent overlap. The 11 locally reserved Molten Core items and 39-member raid count are unchanged (13 October 2026).
- [x] Owner verbally confirmed the new My Wishlist **Gear / Items** and **Recipes** controls work well in their installed client (13 October 2026). This is basic UI acceptance, not yet an end-to-end recipe reservation test.
- [x] Owner's 13 October 2026 Recipes screenshot after `/reload` shows **15 total = 11 Gear / Items + 4 Recipes**, containing Healing Power and Spell Power enchant formulas plus Core Felcloth Bag and Flarecore Wraps patterns. Recipes display in separate rows without obvious overlap and persist through `/reload`. Do not remove these reservations: the owner has not identified any as disposable.
- [x] Owner's subsequent **Gear / Items** screenshot shows count **11**, correct **Page 1/2** navigation, original Arcanist pieces and other gear (e.g. Azuresong Mageblade, Chokers) with no recipes on the visible page; owner confirms the full grouping is correct. Combined 11 + 4 = 15 and recipes remain separate. Lower-edge row/footer appears crowded with multi-line boss text: inspect during remaining UI polish, but do not claim an actual overlap without reproduction.
- [x] Owner verbally confirmed [Issue #4 — Raid Loot Search recipe text overlap](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/4) **seems fine in the updated client** (13 October 2026); the compact name/Item ID/Manual priority fix and `tests/test_search_layout.lua` passed Lua 5.1 CI. No dedicated post-fix screenshot was provided; retain that evidence boundary and review issue closure before release.
- [x] **Owner accepts Issue #5 visual fix (13 October 2026):** [Wishlist Inbox submitted-item pagination overlap](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/5). Following the four-items-per-page change (7-item submission → 4 + 3), compact Previous/Next buttons, and a dedicated page-label area, the owner reports the updated real-client layout 'looks all good now.' This is **verbal UI acceptance**, not a new screenshot nor a real Accept/Reject operation. `tests/test_inbox_layout.lua` and all Lua 5.1 CI suites passed. Preserve real submissions and avoid clicking decision actions merely for a visual retest.
- [ ] Review this separate draft PR and get express owner merge approval. No stable release is authorised by the feature request.

### M6 — First non-prerelease GitHub release (proposed; no release authorised)

**Goal:** ship a clearly scoped, tested WoW 3.3.5a addon without implying that currently unverified direct Master Loot delivery or Playerbot inventory receipt has been certified. Stable is a GitHub release designation, not a guarantee of every optional feature.

**Owner-selected release scope — Option A (13 October 2026):** Target a stable, **verified core** release after remaining acceptance checks. Optional Direct Master Loot requests and unverified Playerbot item receipt must be clearly labelled **experimental / not certified**, stay **OFF by default**, and must not be portrayed as tested. The owner's selection of Option A is **not** permission to activate real awarding, merge a PR, or publish a release.

**Release-blocking acceptance checks:**
- [x] Owner's original four personal MC wishlist items survived earlier `/reload` tests. Later, four recipes were added and confirmed in the 15-entry wishlist (11 Gear / Items + 4 Recipes), all persisting through `/reload`; never assume the old four-item baseline is still current.
- [x] Existing MC40 simulation completes a safe fake pool/ticket/roll/fake award; 0 saved Gear Needs and 136 presets remain after stop; real award history visibly empty; Direct Master Loot OFF.
- [x] Current candidate Lua 5.1 source suites and package checks passed in [v0.1.0.28 CI build 38433305898](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/38433305898): 32 TOC Lua modules, deterministic install ZIP, SavedVariables absent, Direct Master Loot OFF. SHA256 of installable ZIP: `1f1158cd66d0d76dd578451f018508ee6a8d2cfdcc8428a711b63370cccf755d`. Subsequent documentation-only commits require latest CI confirmation.
- [x] Final UI sweep: Owner confirmed Overview, Molten Core Raid Loot Search (`Arcanist` filtering), and Wishlist Inbox work as intended, with no reported defects (13 October 2026).
- [x] Screenshot verifies version `0.1.0.27`, initialization READY, and an empty real-loot identity ledger (current: none; prior assigned: 0; archived: 0). No claim of non-empty history recovery or real loot transfer.
- [ ] Verify persistence of a non-empty fake-independent winner/identity fixture across `/reload` and rollback on an **expendable** SavedVariables copy. Do not fabricate or overwrite real personal history.
- [ ] Conduct controlled **real-raid observational tests** without transferring items: real roster/loot detection, botcheck for online/offline/class/role, read-only candidate listings, and A→B→A duplicate-lock behavior where test drops are available. If impractical, carry unverified features as explicitly experimental/not certified; do not mislabel them as proven.
- [x] Owner selected release Option A: keep optional Direct Master Loot experimental/unverified, OFF by default, with explicit warnings in documentation and release notes. No real `GiveMasterLoot` testing or delivery claims are authorised.
- [ ] Verify release messaging and safety defaults reflect this decision; consider whether the existing optional experimental control needs any additional guard before publication.
- [ ] Re-evaluate open [loot identity issue #1](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/1) against test evidence; close only when genuinely accepted, otherwise document as an outstanding known limitation.
- [ ] Review [draft PR #2](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/2), then [draft PR #3](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/3), then [v0.1.0.28 release-prep draft PR #6](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/6). Verify final code/CI/visual changes and obtain **separate explicit owner approval** before merging each.
- [x] Owner selected `v0.1.0.28` on 13 October 2026 **for preparation**, not publication. Internal Lua and TOC version set to `0.1.0.28` on independent `dev/nll-v0.1.0.28-stable-prep` branch stacked on review PR #3; no tag exists.
- [x] Prepared README, CHANGELOG, TOC/Core version, [v0.1.0.28 notes](RELEASE_NOTES_v0.1.0.28.md), [installation and rollback](INSTALL-v0.1.0.28.md), and [separate approval checklist](RELEASE_CHECKLIST_v0.1.0.28.md). Direct Master Loot visibly labelled Experimental; no change to transfer logic, SavedVariables schema, or addon folder/key.
- [x] Created an explicitly **non-publishing, read-only** candidate packaging workflow and deterministic addon-only ZIP builder. [Successful candidate run](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/38433305898) uploaded review artifact `Naxxramas-Loot-Ledger-v0.1.0.28-REVIEW` (ZIP + SHA256SUMS). Existing v0.1.0.25–27 auto-publication workflows were not modified.
- [ ] Owner downloads this **candidate** artifact, tests installed v0.1.0.28 in a WoW 3.3.5a test client with paired backups, verifies 15 saved wishes/roles/presets/real history, and confirms Direct Master Loot OFF. A final post-merge release asset must be re-generated and inspected before publication.
- [ ] Only with the owner's **explicit separate release approval**, merge the approved branch and create a **new GitHub release without the prerelease flag**. Preserve old prerelease tags/assets unchanged.
- [ ] Optionally update N Addon Collection and other documentation only after the new artifact is verified and separately approved.

**Not blockers unless the owner promotes them into scope:** copy/paste wishlist import/export, new raid-size simulator controls, cosmetic singular/plural text refinements, and broad future raid expansions. **Recipe wishlist separation is now explicitly required before the stable release**, with in-client acceptance pending.

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
