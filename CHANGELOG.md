# Changelog

## Unreleased — Recipe wishlist categories (dependent review branch; not shipped)

- Add **Gear / Items** and **Recipes** subviews inside My Wishlist, retaining the NLL Dark layout and normal wishlist pagination.
- Automatically classify reserved Molten Core plans, schematics, formulas, patterns and recipes using the existing `Profession recipe` metadata. Equipment and crafting materials remain under Gear / Items.
- Preserve the original per-player item-ID reservations, `Submit to Leader` combined payload, role priorities and manual-only recipe allocation. No database migration, new real-award path or client API changes.
- Add Lua 5.1 regression coverage for classification, reservation, leader-submission compatibility and category navigation. In-game owner acceptance is pending; there is no new release yet.

## Unreleased — Dark-only UI cleanup (development branch; not shipped)

- Remove the Vanilla appearance selector and parchment rendering; retain the existing NLL Dark theme.
- Open Settings on Priority Setup while preserving Debug Lab, Loot Awards, Award History and priority controls.
- Normalize old `VANILLA` / `CLASSIC` appearance settings to `DARK` without deleting or replacing SavedVariables, gear plans, priorities, loot identity, or award/winner history.
- Fix the Priority Setup preset footer overflowing the Settings bottom border: anchor its button above the panel bottom, align its description to the button, and raise the nearby statistics. No preset rules or SavedVariables are changed.
- Add `tests/test_dark_skin.lua` (including footer-anchor regression checks) and branch/PR Lua 5.1 regression workflow. Real 3.3.5a UI acceptance is still needed before any merge or release.
- No new Master Loot functionality or real award request behavior.

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
