# Manual Guild-Loot Master Loot — Development Only

**Unmerged, uninstalled draft.** Stacked after PR #14 (read-only material/gear classification) and earlier PRs #13, #12 and #10. The raid owner's HF2 addon and 604 Playerbot Gear Plans are not touched.

## Goal

Allow the authorized WoW Master Looter to allocate **eligible, unreserved** equipment, crafting reagents, materials and recipes to the current raid leader for guild management. Never divert a known NEED/GREED or unresolved reservation, and never grant quest/legendary/special loot through this path.

## Implemented manual workflow

From NLL > Settings > Loot Awards:
- **Direct Master Loot** remains OFF at every login/reload.
- A separate **Guild Transfers** switch also resets OFF at every login/reload.
- Both must be ON before even reviewing a real guild transfer. The separate slash command `/nll guildgive on|off` controls the Guild Transfers consent only and can be queried with `/nll guildgive`.

From NLL > Current Loot > Guild Loot (or `/nll guildloot`):
1. Open the actual corpse and the **Blizzard Master Loot candidate dropdown for the exact item slot** while acting as WoW's designated Master Looter.
2. Only `GUILD_REVIEW` rows allow the user to click **Review**. The code re-scans every live item slot and saved/unsent/pending need before accepting the selection; any NEED/GREED, quest/legendary/special/locked/uncached item or missing roster blocks.
3. A successful Review freezes itemID, exact item link, item slot, stack quantity, current raid leader and their **unique** item-specific Master Loot candidate index. It **does not transfer anything**.
4. **Arm Leader Transfer** rechecks all those fields and records a 15-second deadline. Still no transfer.
5. **CONFIRM GIVE ITEM** (second separate click) rechecks all conditions AGAIN, then issues exactly one `GiveMasterLoot(slot,candidateIndex)`. No automatic timers, countdowns, inbox messages or loot scans may trigger the call.

On request:
- Append an audit to `guildLootTransferAudit` **before** asking WoW. The audit starts `AWARD_OUTCOME_UNKNOWN` in case Blizzard throws, succeeds as `AWARD_REQUESTED` if the Lua API call returned without throwing.
- `LOOT_SLOT_CLEARED` changes the status to `LOOT_SLOT_CLEARED`, **not** "delivered" or "recipient verified".
- `LOOT_CLOSED` clears armed UI state and marks an outstanding request `AWARD_OUTCOME_UNKNOWN`.
- Any unresolved guild or lottery-winner real award request blocks another guild request, even after `/reload`. Re-using the same itemID+loot-slot is blocked permanently by this provisional safety design because 3.3.5a does **not** supply a reliable per-corpse GUID.
- No history or Gear Plans entries are automatically set `OBTAINED`. No winner is fabricated for unreserved materials. No physical receipt is claimed.

## Important known limitations (block live deployment)

- **Do not use in production yet.** Under this intentionally strict design, an observed slot-clear is still not independent proof of delivery. A future reconciliation screen is required before the same item/slot can be used again on a different corpse. An unknown receipt remains unresolved rather than allowing potentially duplicate transfers.
- We cannot know about wishlists held exclusively on clients that have not submitted them to the leader. `GUILD_REVIEW` means no **known** reservation; the human leader must confirm guild policy before routing.
- The recipient may be absent from the WoW candidate list, e.g. range/offline or custom Playerbot behaviour. If they cannot be uniquely resolved, the transfer stops instead of guessing.
- Master Loot may not apply to some material types or group-loot distributions; the validator will refuse if WoW's dropdown/candidate list is unavailable. Do not confuse materials visible in the window with all guild resources from skinning, mining, or normal inventory.
- UI positioning and protected `GiveMasterLoot` behaviour on AzerothCore/3.3.5a are **NOT yet verified in-game**.
- Fully automatic unreserved routing remains **disabled and unimplemented**. Only a human clicking Review → Arm → Confirm can make a direct request, and only after separate consent.

## Testing and backups

- Lua 5.1 regression includes `tests/test_guild_loot_transfer.lua` with mock Blizzard APIs for both consents, Master Looter and raid leader identity, exact loot slot/link/stack, candidate uniqueness, NEED/quest holds, active lottery/winner review, stale corpse, 15-second expiry, unknown result, audit/reload and duplicate prevention.
- `tests/test_guild_loot_transfer_ui.lua` checks that paged row Review only enables Arm, Arm only enables Confirm, and closed loot disables actions, all without calling a real award API.
- Run all `tests/test_*.lua`, `luac5.1 -p` for all modules and `python3 tests/test_release_packaging.py`; CI must pass on exact PR head before any other phase.
- When the user authorizes eventual in-game testing, finish all current loot, **fully exit WoW**, and back up **both** `Interface/AddOns/NaxxLootLottery/` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `.lua.bak` where present. Test only with expendable items in a separate backed-up client/realm. Restore addon and SavedVariables together on rollback. Never overwrite 604 real Playerbot plans.

No merges, tags, publishing or live setting changes are authorized by this draft.
