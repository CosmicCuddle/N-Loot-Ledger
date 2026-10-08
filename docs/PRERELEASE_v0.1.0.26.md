# Naxxramas Loot Ledger v0.1.0.26 (Pre-release)

**Development pre-release for World of Warcraft 3.3.5a / AzerothCore.** Real Playerbot and Master Loot behaviour is not yet production-certified.

## Changes in this update

- Same or overlapping live loot scans now reuse a **persistent loot-opportunity ID**; the same item cannot silently receive new tickets after closing/reopening its loot window or reloading.
- A completed winner reappears when its saved drop identity is observed again, without suggesting the item was actually received.
- Multiple drops retain independent identifiers as loot changes. An ambiguous partial set of identical copies is blocked instead of guessing which was rolled.
- If a genuinely **different** corpse has overlapping loot, a leader/officer can enter `/nll newloot` then `/nll newloot confirm` within 20 seconds while viewing that corpse's real loot window. This explicit override is audited; **never use it to reroll the same physical drop**.
- Direct awarding of a previously completed winner is **blocked after the loot window closes or client reloads**, because the addon cannot prove that the selected corpse is still the same loot opportunity.
- Adds 35 deterministic offline loot-identity assertions and updates the rollback guide.

## Installation

1. **Back up** both `Interface/AddOns/NaxxLootLottery` and your saved `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` before updating.
2. Download **`Naxxramas-Loot-Ledger-v0.1.0.26.zip`** from **Assets** below; do not install GitHub's automatically generated *Source code* archive directly.
3. Extract the ZIP; place its `NaxxLootLottery` folder in `World of Warcraft/Interface/AddOns/`. The installed `.toc` path should be `Interface/AddOns/NaxxLootLottery/NaxxLootLottery.toc`.
4. Restart WoW and enter `/nll version` (expected `0.1.0.26`), `/nll status` (expected `READY`).
5. To regression-test safely, enable debug and run `/nll sim mc40`; stop with `/nll sim stop`.

## Known limitations

- WoW 3.3.5a provides **no reliable loot-source GUID through the APIs this addon uses**, so a different corpse with some of the same items can be conservatively treated as the previous opportunity until a leader confirms otherwise. A manual override is not proof of corpse identity.
- Old pre-0.1.0.26 current-loot IDs cannot be retroactively reconstructed. The addon clears that stale current-loot display once on upgrade but keeps previous award/lottery history.
- This addon does not verify actual item delivery. `GiveMasterLoot` is opt-in, requires two separate confirmations, and resets OFF at login/reload. Test only with expendable items.
- No real AzerothCore Playerbots are spawned by the simulator.

Please report issues with reproduction steps, addon version and WoW 3.3.5a build, but **do not upload personal SavedVariables**.
