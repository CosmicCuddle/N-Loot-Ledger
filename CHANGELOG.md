# Changelog

## Unreleased — Fallback / Off-Spec Gear Plan interest (development branch)

- Add a separate `FALLBACK` Gear Need status for optional/off-spec interest, selectable before creating the need or later from an existing plan. The old status and storage keys remain valid.
- Place fallback contenders behind configured primary tiers 1, 2 and 3; preserve class/role restrictions, excluded candidates, manual-only item policy, raid-presence checks and missing-role fail-closed handling.
- Revalidate the fallback candidate pool before a roll and when accepting a roll result. A newly eligible `NEEDED` contender invalidates a previously prepared fallback pool.
- Show fallback interest separately in Current Loot, leader candidate review and read-only Playerbot diagnostics.
- Add Lua 5.1 fallback regression coverage and an acceptance/rollback checklist. **This is not a new released version, and in-client acceptance is outstanding.**

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
