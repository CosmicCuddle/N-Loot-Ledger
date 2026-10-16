# Need Before Greed — implementation and acceptance

**Status:** Review-only draft PR [#8](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/8). Not released, installed, merged or certified for real loot delivery. WoW 3.3.5a / Lua 5.1 / Molten Core.

## Behaviour
A Gear Plan status is exactly `NEEDED`, `GREED`, `OBTAINED` or `DISABLED`.

1. **NEED stage:** Use the pre-existing configured **Tier 1, Tier 2, Tier 3** rules. Lower Need tiers never outrank higher ones. A present online Need candidate with unresolved class/role/rule **blocks rolling** until reviewed.
2. **GREED stage:** Consider only if there are no eligible Need contenders and no unresolved Need blockers. Every eligible Greed contender receives one equal-opportunity ticket. **Greed is NOT Tier 4**, and the chosen Need tier is `nil`. Unresolved Greed data blocks a Greed roll. Invalid class, excluded roles, absent/offline players and leader-excluded characters are excluded.
3. **Manual stage:** If both stages have no eligible candidates, NLL does not roll or transfer anything.
4. **Manual/guild items, including recipes**, retain their previous manual-only policy. Existing Playerbot Gear Plans are intentions, not proof of inventory receipt.
5. A winner may come from **NEED - Tier 1/2/3** or **GREED**, never both for one drop copy. Duplicate/corpse-identity locks and real loot/authority checks remain intact.
6. A leader **cannot manually add** an already-GREED character into the Need stage without first deliberately changing their saved plan. This avoids an accidental Need bypass.
7. No status migrations: existing `NEEDED`, `OBTAINED` and `DISABLED` records remain as saved. New GREED records use the existing `gearNeeds` table and key convention.
8. On confirmed *lottery* completion, store `selectionType` and optional Need tier with lottery history and the per-drop identity. Recovered legacy records without a type display as Need (tier unknown). A selected winner is **not proof** that an item was delivered.
9. No modification of core/server, IP, Playerbots, SQL, addon SavedVariables key, custom priority tables or the real `GiveMasterLoot` opt-in.

## Automated regression checks

Run under a Lua 5.1-capable interpreter from the repository root:

- `lua5.1 tests/test_need_before_greed.lua`: Need/Greed separation, all three Need tiers, equal Greed contenders, offline/absent bots and wrong-class exclusions, missing role/class blockers, manual items, duplicate characters/sources, priority rule requirements, leader exclusion, stale manual candidate protection, full real TicketLottery completion, last-minute Need invalidation at result acceptance, audited cancellation and preserved historical records.
- `lua5.1 tests/test_need_greed_savedvariables.lua`: exercise **real** Database initialization for fresh installs, an existing v0.1.0.28 SavedVariables shape and reinitialization after simulated `/reload`. Assert in-place retention of old NEEDED/OBTAINED/DISABLED plans, new GREED plan, player wishlist booleans, role assignments, priority rules, lottery and award history, loot identity and direct Master Loot OFF. No migration or table replacement.
- `lua5.1 tests/test_need_before_greed_sim.lua`: complete 40-bot/eight-group MC scenario; a Greed-only Quick Strike Ring drop with multiple eligible contestants; changing roster after preparation cancels tickets; fake roll, fake award and duplicate safety; existing MC40 unchanged; all live SavedVariables still the same objects.
- `lua5.1 tests/test_gear_plans_layout.lua`: owner's 19 saved plans now use six rows, four pages, correct last-page controls, and `GREED` status choices. No saved plan writes during navigation.
- Full CI workflow `.github/workflows/lua51-regression.yml`: Lua 5.1 syntax + all existing loot identity, Playerbot, UI and history tests. Verify **exact PR head** before calling this PASS.

## Safe WoW client checks — NOT YET PERFORMED

**Before installing any build:** close WoW. Copy both the current `Interface/AddOns/NaxxLootLottery` directory and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `.lua.bak`, plus any character-level copies. Keep the backups together. Use a copy of the client or other expendable test setup where possible.

1. Confirm `/nll version` still displays current TOC version `0.1.0.28`, `/nll status` READY, all existing 19 or more Gear Plans intact, existing roles/wishlists untouched, and Direct Master Loot OFF.
2. Open Wishlists > Gear Plans at the **same UI scale as the 16 October screenshot**. Verify the sixth row stops above the paginator; the last row must not cross the page label or next/previous controls. Navigate every page.
3. Add a throwaway GREED item for an expendable fake/leader-managed entry. Check the new-plan interest selector and row status menu; `/reload` preserves it. Do not edit the owner's genuine Druzz reservations without permission.
4. Preview a configured non-manual MC item with both Need and Greed candidates: Need tier should win and Greed should wait. Remove Need *only on test fixtures*: Greed pool should become active. Test a missing role, leader exclusion and offline member without creating a live roll.
5. From Debug Lab use `/nll sim mc40greed`. Inspect early Need drop, then select the last drop (Quick Strike Ring) to see Greed-only contenders. Run fake Prepare, test a changed roster, then safely fake roll and fake award. `/nll sim stop`. No real `RandomRoll`, `GiveMasterLoot`, or award history writes.
6. Recheck `/nll sim mc40` original fixture, real award-history view, original player reservations and new `/reload` persistence. If an error occurs, record screenshot/trace and restore paired backups.

**Not validated:** actual boss/corpse behaviour, Master Loot delivery, Playerbot inventory changes, visual owner acceptance of six-row pager and winner overlay at their exact font scaling. No real item transfer tests are authorised.

## Related future milestones (not included in this PR)

- Multiple copies of non-unique rings/trinkets per character, with exact equipment/unique restrictions and first-copy history accounted for.
- Human wishlist copy quantities and bot Gear Plan copy quantities without overwriting existing boolean reservation tables.
- Bulk import/export of bot plans, with a preview and explicit commit gate.
- These should not be silently added to the Need Before Greed release candidate.
