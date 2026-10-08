# Compatibility and rollback

For stability, the first Naxxramas Loot Ledger release **does not rename** the `NaxxLootLottery` addon folder, `.toc` filename or `NaxxLootLotteryDB` SavedVariables key. Existing `/nll` commands are unchanged. Only the displayed title, user-facing text and documentation are rebranded.

## Upgrade

1. Copy the existing `Interface/AddOns/NaxxLootLottery` directory to a safe backup.
2. Back up the game's `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `.lua.bak` if present.
3. Replace the addon folder with the repository's `NaxxLootLottery` folder.
4. Launch the game and run `/nll version` and `/nll status`.
5. Validate in simulation before attempting real Master Loot transfers.

## Rollback

Exit the game. Restore the previous addon folder **and** the corresponding SavedVariables backup, then restart. Simply deleting the new addon files does not roll back SavedVariables changes.

Development build 0.1.0.27 does not represent independent verification of real Master Loot delivery.

## Loot-identity migration (0.1.0.27)

This update creates `raidSession.lootIdentity` in the **existing** `NaxxLootLotteryDB` SavedVariables. Old currentLoot data is cleared once because pre-0.1.0.27 drop IDs are not trustworthy after reopen. Previously recorded lottery and award histories are preserved. A rollback must restore the saved variables from the same pre-upgrade backup; an old client cannot be assumed to understand the new identity ledger.

Schema 2 loot identity records migrate to schema 3 in-place, preserving current winners and saved award history. Archived group history is intentionally conservative; this is not reliable corpse GUID recognition.
