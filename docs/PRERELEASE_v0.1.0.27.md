# Naxxramas Loot Ledger v0.1.0.27 (Pre-release)

**A development build for World of Warcraft 3.3.5a / AzerothCore.** This is **not** a production-certified loot distribution system; back up before installing.

## What's improved

- **Multi-corpse recovery:** Earlier loot opportunities remain available in the saved ledger after you inspect a different corpse. Returning to corpse A after corpse B no longer silently creates a fresh lottery for A.
- **Conservative conflict handling:** When more than one historical opportunity matches a drop, NLL blocks the ambiguous lottery instead of guessing.
- **Real Playerbot preflight:** `/nll botcheck` and `/nll botcheck <character>` check your **actual live raid roster**, saved Playerbot Gear Plans, class and role availability. If a genuine WoW Master Loot candidate list is open, the command checks whether a planned bot is listed for that selected item. **No loot is awarded.**
- **Backwards compatibility:** Existing folder `NaxxLootLottery`, SavedVariables `NaxxLootLotteryDB`, `/nll` commands, dark/Vanilla styling, and 40-player MC simulator remain intact.

## Install

1. Back up `Interface/AddOns/NaxxLootLottery` **and** `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` (plus `.lua.bak`, if present).
2. Download **Naxxramas-Loot-Ledger-v0.1.0.27.zip** under **Assets**, not the GitHub-generated *Source code* archive.
3. Extract the ZIP, and place `NaxxLootLottery` directly inside `World of Warcraft/Interface/AddOns/`.
4. Check that `Interface/AddOns/NaxxLootLottery/NaxxLootLottery.toc` exists. Restart WoW and run `/nll version`, `/nll status`.
5. Optional safe test: `/nll debug` (if disabled), `/nll sim mc40`, then `/nll sim stop`. For actual bots, stop simulation and use `/nll botcheck` in a real raid.

## Warnings and known limitations

- There is **no trustworthy physical corpse GUID** via the 3.3.5 APIs used here. Similar loot lists might belong to the same or different corpses, so an ambiguous match is never proof of an item identity. Only `/nll newloot` followed by `/nll newloot confirm` after verifying a truly different corpse explicitly overrides this restriction.
- Master Loot candidate listing does not prove the target actually received the item. Playerbot support is **not validated** on all AzerothCore setups, and real delivery is still pending controlled server tests.
- Optional live direct awarding remains **OFF on each login/reload** and needs two user confirmations. Test it only with expendable gear after checking your local server behaviour.
- When rolling back, restore **both** the prior addon folder and its matching SavedVariables backup.

Details: `docs/RELEASE_NOTES_v0.1.0.27.txt` and `docs/TESTING_v0.1.0.27.txt`. Do not attach personal SavedVariables or private raid records to public issues.
