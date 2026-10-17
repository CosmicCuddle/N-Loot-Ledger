# Award Winner review UX — draft only

Based on draft PR #12; no live raid code has been installed.

- In Current Loot, once a real winning ticket is verified, the existing second-row button says **Award Winner**; this launches NLL's own `AwardWorkflow` dialog, not another addon.
- Opening the dialog is **read-only** even if the corpse closed, so the leader can see why an award is blocked. It never calls GiveMasterLoot merely by opening it.
- **Check Master Loot** validates WoW's actual loot window, the exact slot/item, the acting character's designated Master Looter authority, and the winning character's live master-loot candidate index. Manual-award acknowledgement and direct-arming remain unavailable until review succeeds.
- The user must separately opt into Direct Master Loot in Settings > Loot Awards (automatically OFF on each login). The existing **Arm Direct Award → CONFIRM GIVE ITEM** two-click flow still requires a fresh live validation on both clicks within 15 seconds.
- After `GiveMasterLoot`, status is `AWARD_REQUESTED` and delivery is explicitly **UNVERIFIED**. Do not retry without checking WoW. Never mark Gear Plans obtained based on the request alone.
- Any previously reported or requested award locks this flow against duplicate transfers. The existing manual-award report button remains as a record only; never proof of receipt.
- Special reserved/legendary items and guild/unreserved transfers are separate features; this PR does not route items or materials to a player.
- In fake mode, winner-review remains a simulated record only.

**Offline validation:** run all `tests/test_*.lua` with Lua 5.1. `tests/test_award_winner_ui.lua` exercises opening a missing-loot review (no transfer), explicit live slot candidate recheck, default Direct Award OFF, separately enabling that setting, first-click arm (no transfer), second-click simulated `GiveMasterLoot` request, preventing retry, and untouched Gear Plans. The test mocks WoW APIs: live gameplay remains unverified.

**In-game acceptance later:** close WoW, back up BOTH `Interface/AddOns/NaxxLootLottery/` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.bak`. Use a separate backed-up client and disposable loot. Do not turn on real Direct Award in an active raid until standalone recipient/candidate validation and physical receipt confirmation have been observed and separately approved.
