# Changelog

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
