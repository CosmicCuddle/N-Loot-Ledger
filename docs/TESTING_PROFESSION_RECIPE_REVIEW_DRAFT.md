# NLL C12 — Profession-aware Molten Core recipe review (draft #35)

**Build:** `0.1.0.29-rc.1-dev17`, 49 addon Lua modules; based on #34.  
**Status:** DEVELOPMENT-ONLY, not installed, merged or released.

## Why we cannot automatically assign recipes

NLL already groups 10 Molten Core recipes under **Wishlists → My Wishlist → Recipes** and marks them manual-only. It stores **Gear Plan interest**, not verified profession/skill/specialisation or known-recipe records for each of the owner's **38 Playerbots**.

A NEED reservation is NOT proof that the bot is qualified to learn a recipe. A saved role assignment (HEALER, TANK, CASTER_DPS etc.) is not profession evidence. Never derive Blacksmithing, Engineering, Tailoring, Alchemy, Enchanting, Leatherworking or their spec from raid role, class, name or an unverified user claim.

The goal of C12 is to make human allocation easier **without fabricating recipient eligibility**.

## New functionality

- `ProfessionRecipeReview:ListRecipes()` inventories the existing 10 MC recipe IDs with manually curated required profession and skill **300**. Actual 3.3.5a / Individual Progression settings and skill/spell knowledge must be independently checked by the owner before any decision.
- `ProfessionRecipeReview:Build(itemID)` displays existing `db.gearNeeds` entries (NEEDED, GREED, OBTAINED, DISABLED) for that exact Molten Core recipe, including source/characterType. Candidate data is **interest-only**; there is **no cached bot profession/skill evidence**.
- Every result has `autoEligible=false`, `transferAuthorized=false`, `recipientVerified=false`, `professionVerified=false`, `skillVerified=false`, `specializationVerified=false` and `learnedAlreadyVerified=false`.
- In **My Wishlist → Recipes**, the ordinary header **Interest** is temporarily replaced by **Prof. Review**. Clicking opens a separate read-only review window with:
  - a 10-recipe Prev/Next catalogue,
  - exact item ID, required profession and skill 300,
  - explicitly **UNVERIFIED** specialist/skill/known-recipe/receipt statements,
  - a second independent Prev/Next names pager (4 saved Gear Plan interests at a time), including statuses,
  - **Close**, no Edit, Add, Import, Grant, Award or Confirm action.
- Returning to Gear / Items restores the original **Interest** header. The My Wishlist rows and bottom pager do not move.
- It never modifies SavedVariables, global character role, a gear plan, wishlist, lottery ticket, audit, pending receipt, guild settings, physical attempt locks or an inventory item.
- Real guild loot, including recipes, continues to be managed only through separate manual guild review subject to existing irreversible NO RETRY physical protections. This feature never bypasses them.

## Exact Molten Core recipe categories (all skill 300)

| Item | Recipe | Profession | Specialisation validation |
|---|---|---|---|
| 18264 | Plans: Elemental Sharpening Stone | Blacksmithing | Check in actual 3.3.5a/IP client |
| 18292 | Schematic: Core Marksman Rifle | Engineering | Check, including Goblin/Gnomish where relevant |
| 18291 | Schematic: Force Reactive Disk | Engineering | Check, including Goblin/Gnomish where relevant |
| 18290 | Schematic: Biznicks 247x128 Accurascope | Engineering | Check, including Goblin/Gnomish where relevant |
| 18259 | Formula: Enchant Weapon - Spell Power | Enchanting | Check in client |
| 18260 | Formula: Enchant Weapon - Healing Power | Enchanting | Check in client |
| 18252 | Pattern: Core Armor Kit | Leatherworking | Check, including Dragonscale/Tribal/Elemental where relevant |
| 18265 | Pattern: Flarecore Wraps | Tailoring | Check in client |
| 21371 | Pattern: Core Felcloth Bag | Tailoring | Check in client |
| 18257 | Recipe: Major Rejuvenation Potion | Alchemy | Check in client |

**These are recipe profession requirements, not confirmations about individual Playerbots or specialised learning restrictions.** Recipe already known? Character at 300? A different skill system in Individual Progression? Check those manually.

## Source references used during review

- [Wowhead Classic – Plans: Elemental Sharpening Stone](https://www.wowhead.com/classic/item=18264/plans-elemental-sharpening-stone)
- [Wowhead Classic – Force Reactive Disk](https://www.wowhead.com/classic/item=18291/schematic-force-reactive-disk)
- [Wowhead Classic – Core Marksman Rifle](https://www.wowhead.com/classic/item=18292/schematic-core-marksman-rifle)
- [Wowhead Classic – Biznicks Accurascope](https://www.wowhead.com/classic/item=18290/schematic-biznicks-247x128-accurascope)
- [Wowhead Classic – Flarecore Wraps](https://www.wowhead.com/classic/item=18265/pattern-flarecore-wraps)
- [Wowhead Classic – Core Felcloth Bag](https://www.wowhead.com/classic/item=21371/pattern-core-felcloth-bag)
- [Wowhead Classic – Core Armor Kit](https://www.wowhead.com/classic/item=18252/pattern-core-armor-kit)
- [Wowhead Classic – Major Rejuvenation Potion](https://www.wowhead.com/classic/item=18257/recipe-major-rejuvenation-potion)

Research references are for the **profession categories**, not evidence about any saved player's skills. Confirm formulas and any additional restrictions in the matching server's item tooltips/DBC.

## Owner-approved in-game acceptance (still pending)

1. Make a dated copy of `Interface/AddOns/NaxxLootLottery` and the matching **per-account** `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua`, plus `.lua.bak` where present. Preserve previous HF2 as rollback. Do the same on other test clients.
2. Verify the original imported baseline **604 plans / 38 Playerbots / 469 NEED / 135 GREED**, unchanged roles, reserve statuses and award/receipt history.
3. In an explicit controlled test build only, open **My Wishlist → Recipes → Prof. Review**. Check 10 recipes are present and pages stay in bounds.
4. Compare the profession and minimum skill displayed for each of the 10 IDs with *actual* WoW 3.3.5a + Individual Progression tooltips.
5. Inspect one recipe with multiple Gear Plan interest rows; check all names/statuses and Prev Names/Next Names page boundaries.
6. Confirm a **HEALER** role is never treated as an Enchanter, an **Engineering** reservation is never interpreted as Goblin/Gnomish proof, and missing skill/specialist data reads **UNVERIFIED**.
7. Check recipes already marked OBTAINED/DISABLED do not become automatic winners or qualified recipients.
8. Verify no real `GiveMasterLoot`, raid message, lottery roll or inventory action occurs. Do not use a genuine item to test actual distribution.
9. Recheck exact SavedVariables counts/objects, direct Master Loot OFF and guild transfer OFF after navigation.
10. Record screenshots with long name clipping at actual WoW UI scale; on visual trouble, stop and restore matched backups.

## Automated gates

- [x] Lua 5.1 synthetic 604-plan + eight-interest fixture covers all ten recipes, profession mapping, skill requirement, unverified specialty, unknown profession/recipe status, candidate pagination and no writes/grants.
- [x] Existing recipe wishlist UI mock verifies entry is shown **only** on Recipes tab and the Items header returns without moving the list.
- [ ] Dedicated no-release and complete Lua 5.1 tests at final exact head.
- [ ] Owner-approved in-client tests and multi-client receipt/loot physical safeguards.

**No saved profession roster is created in C12.** Verified character-profession data ingestion would require a separate independently reviewed feature and approval; no guessed global attributes or server queries are introduced.