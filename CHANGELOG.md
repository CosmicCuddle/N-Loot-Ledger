# Changelog

## Unreleased — Playerbot Gear Plan Import / Export (separate stacked review branch)

- Add a `Wishlists > Gear Plans > Import / Export` dialog with a copyable export and pasteable versioned `NLL-GEARPLANS-1` text format.
- Support **add-only** guarded import: Preview Changes identifies new/identical/conflicting entries; any conflict refuses the whole batch; Confirm ADD must be a separate explicit action and is invalidated by edits or changed Gear Plans.
- Fix actual WoW 3.3.5a clipboard behaviour: when pasted seven `|` delimiters are doubled to fourteen `||`, strictly normalize complete pairs during import; block malformed/mixed pipe formats. Regression reproduces the owner's Gorak test row, checks mixed batches, conflicting statuses, no partial writes, and correct single-pipe export.
- Preserve real Latin-1 UTF-8 character names (including TangØ); reject malformed bytes and case-colliding TangØ/Tangø reservations rather than generating duplicate Playerbot entries.
- Restrict the first version to PLAYERBOT / BOT_GEAR_PLAN, configured Molten Core item IDs, NLL role IDs and statuses NEEDED/GREED/OBTAINED/DISABLED. No duplicate-copy reservations (copy index must be 1). Limit each batch to 250 rows / 48KB.
- Do not modify existing Gear Plans, raid-role assignments, personal wishlists, loot identity, lottery/award history, priority rules, network, server or real loot; do not migrate SavedVariables.
- Add offline Lua 5.1 backend and UI interaction regressions, packaging checks, and a paired-backup owner test checklist. **Not yet installed, accepted, merged, tagged or released.**

## Unreleased — Need Before Greed (draft PR #8; NOT PUBLISHED)

- Add explicit `GREED` interest to leader-managed Gear Plans alongside `NEEDED`, `OBTAINED` and `DISABLED`; old statuses, keys and SavedVariables remain intact.
- Keep the existing Need Tier 1–3 priorities unchanged. GREED forms **an independent equal-opportunity stage, not Tier 4**, only when no valid Need contender or unresolved Need blocker exists.
- Preserve existing role/class, offline, manual-only item, leader exclusion, loot identity and duplicate-roll rules. Block manually promoting a character's Greed into Need without deliberately editing their Gear Plan.
- Persist NEED/GREED selection type (and optional Need tier) with completed lottery, recovered loot identity and new real award-history events. An old untyped winner remains backward-compatible.
- Extend the safe Debug Lab with `/nll sim mc40greed` (40 fake bots, eight groups, normal Need drops plus a Greed-only Quick Strike Ring scenario), entirely isolated from real loot and SavedVariables.
- Fix Gear Plans footer collision seen with 19 entries by limiting each page to **six rows**; add a Lua 5.1 paginated-layout regression.
- Add strict Lua 5.1 stage, persistence, 40-bot simulation and visual-control regressions and in-client acceptance checklist. Extend coverage to real v0.1.0.28 SavedVariables initialization/reload and actual lottery Finish acceptance/cancellation when the Need pool changes. **GitHub test success does not certify live award delivery or WoW UI scaling.**
- Multi-copy equipped-item wishlists and guarded import/export are documented future milestones, not bundled into this change.

## 0.1.0.28 — First stable-core release (published 2026-10-13)

- Make **NLL Dark** the only interface style. Normalize old Vanilla/Classic saved display settings without replacing existing SavedVariables or other records.
- Separate **My Wishlist → Gear / Items** and **Recipes** while retaining existing item-ID reservations and the combined raid-leader submission payload; profession recipes stay manual allocation.
- Remove outdated Overview “full wishlist in Phase 4” messaging and direct players to the existing complete wishlist screen.
- Improve Priority Setup preset footer spacing and resolve an additional large-font collision: move the counters to the top-right title row, keep the preset-toggle explanation on one line and preserve the full wording via hover. **Issue #7 owner post-fix screenshot confirms the overlap is resolved.** Also improve Raid Loot Search formula title/Item ID/Manual priority readability and Inbox pagination (four rows per page).
- Keep `NaxxLootLottery` folder, `NaxxLootLotteryDB` and `/nll` compatible. No changes to actual award/loot-transfer logic or saved-data schema.
- Mark Direct Master Loot visibly **Experimental**; it remains OFF after every startup/reload and is **not** validated for real inventory delivery.
- Add Lua 5.1 regression tests for recipe grouping, UI anchors, search readability, Inbox decisions staying untouched in navigation tests, and a Python standard-library build/verification process for a safe addon-only ZIP.

**Evidence boundary:** Owner confirmed the UI and simulated MC40 testing, 39 real raid members, role persistence, and 15 wishlist reservations (11 gear/items, 4 recipes) after `/reload`. Real boss corpse observation, nonempty historic receipt recovery and physical Master Loot delivery were not independently confirmed. See `docs/RELEASE_NOTES_v0.1.0.28.md` and `docs/RELEASE_CHECKLIST_v0.1.0.28.md`.

## 0.1.0.27 — Historical corpse revisits and read-only Playerbot checks (2026-10-08)

- Preserve old loot-opportunity groups so A → B → A does not reset a completed result.
- Migrate schema 2 to 3 with a bounded history and conservative ambiguity locks.
- Add `/nll botcheck [name]` to compare saved Playerbot gear plans against live raid roster class/role/online data and selected WoW Master Loot candidates.
- Keep 40-player simulation and explicit Master Loot confirmations unchanged; real bot delivery remains unverified.
- Expand offline historical-group and Playerbot diagnostic tests.

## 0.1.0.26 — Loot opportunity identity, duplicate prevention and recovery (2026-10-08)

- Add a persistent per-drop loot identity ledger to prevent accidentally re-rolling the same item after reopening its loot window or `/reload`.
- Restore completed winners and their known award states without treating saved data as a real item-delivery receipt.
- Preserve independent results when a loot list changes, while invalidating pending tickets if their selected item disappears.
- Refuse to guess the identity of ambiguous identical-item copies when loot counts change.
- Add audited, two-step `/nll newloot` and `/nll newloot confirm` commands for a genuinely new corpse with overlapping loot items.
- Disallow direct Master Loot awarding of winners recovered from a closed loot window; this requires a fresh, verifiable award context.
- Add offline loot-identity regression tests and update safety/rollback documentation.
- All existing fake-raid scenarios remain unchanged.

## 0.1.0.25 — Naxxramas Loot Ledger branding and public source checkpoint (2026-10-08)

- Publish the latest tested development source with the name **Naxxramas Loot Ledger**.
- Retain existing addon folder, SavedVariables, and slash commands for backward compatibility.
- Optional real Master Loot awarding is session-only opt-in, using two confirmations and live revalidation.
- Distinguish award request, observed loot-slot clearing and unverified delivery in award history.
- Add dedicated **Loot Awards** and **Award History** settings views.
- Preserve the full 40-player Molten Core simulator, all-class test scenarios, 13 sample drops and fake award flow.

## Prior development milestones

- **0.1.0.24:** 40-character Molten Core simulation in eight groups and 13 fake drops.
- **0.1.0.23:** All 10 classes, 20-character all-class scenario and loot-list pagination.
- **0.1.0.22:** Multiple simultaneous drops, per-item winners and simulated award confirmations.
- **0.1.0.21:** Prominent winner announcement and persistent winner details.
- **0.1.0.20:** Fake raid data integrated into Raid Roles, Wishlists, Overview and Current Loot.
- **0.1.0.19:** Debug Lab and isolated fake scenarios.
- **0.1.0.18:** Candidate review controls and more Molten Core priority recommendations.
- **0.1.0.17:** Manual post-drop ticket lottery and audited results.
- **0.1.0.16:** Opt-in curated Molten Core priority presets.

See `docs/RELEASE_NOTES_v0.1.0.26.txt` for the latest safety and behaviour notes.
