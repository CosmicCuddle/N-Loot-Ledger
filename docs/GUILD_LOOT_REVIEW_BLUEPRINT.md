# Guild Loot Review — non-awarding development blueprint

**Draft, not installed.** Stacked after draft PR #13 (Award Winner UX), which follows #12 (personal NEED/GREED & RAID countdown) and #10 (HF2). Published pre-release and the owner's in-game HF2 remain untouched.

## Owner's requested policy
Every unreserved item, **including crafting materials, reagents, BoE gear and recipes**, should eventually be allocated to the raid leader for guild use. Reserved NEED always takes priority over GREED. Legendary, quest and special items must be held for explicit leader review. These are goals, not active transfer permissions.

## What this draft actually does
- New **Guild Loot** button in Current Loot's separate footer row and the command `/nll guildloot` show a six-row paged, READ-ONLY panel.
- Scans every WoW real item-link loot slot via `GetNumLootItems` / `GetLootSlotLink` rather than only NLL's Molten Core gear table. Unlisted crafting materials still appear, with the localized WoW class name where available.
- Recognizes saved **NEEDED** and **GREED** records even for offline bots/players as `RESERVED`; not eligible for any fallback.
- Local unsent reservations, unresolved records, and pending Inbox submissions become `UNRESOLVED`, never presumed unreserved.
- Manual-only, known legendary, quest-type and legendary-quality entries are `SPECIAL_HOLD`.
- Locked or empty loot slots become `LOCKED`. Items whose class/quality is unavailable from WoW's cache are `UNRESOLVED`.
- Other items appear as `GUILD_REVIEW`: no saved NEED/GREED found, **not a guarantee** all guild reservations were received. Recipient shown is the current raid leader; `recipientVerified=false` and `transferAuthorized=false` are explicit on every row.
- On `LOOT_CLOSED`, the dialog refreshes immediately and clears stale items. A saved loot record can never be treated as a live corpse.
- **There is no item transfer call, automatic allocation, winner creation, SavedVariables modification or loot history write.** This stage is observation only.

## Why allocation is still disabled
WoW 3.3.5's `GiveMasterLoot(slot, candidateIndex)` only makes sense against a specific **live loot slot** and that slot's current Master Loot candidate dropdown. The raid leader is not necessarily the acting Master Looter, and some items may be unawardable or outside the addon DB. Before any real transfer action is written, we need a separately reviewed, fail-closed recipient/candidate verifier and receipt-audit path. Even a successful API call does not prove recipient receipt.

**Later stage**, behind OFF-by-default explicit consent: validate the designated Master Looter, exact item link/slot/quantity, raid leader identity and presence in current candidate list, pending/reserved/quest holds, absence of unresolved award requests, and audit request/clear/unknown outcomes. First test manual two-click transfers with expendable items; only after explicit approval consider optional automatic guild routing. No real player or bot data modifications in this draft.

## Tests / acceptance
- `tests/test_guild_loot_review.lua`: ten item slots, including non-database Trade Goods, reserved NEED, reserved GREED, local reservations, pending recipe, legendary, quest, locked, uncached unknown, non-item coin. Verifies pagination, corpse closure, ambiguous leader, debug mode, and **zero** `GiveMasterLoot` calls and no saved-plan changes.
- `tests/test_award_winner_ui.lua` additionally tests selection drift during modal review and after award arming: changing the selected item cannot silently transfer to a different winner.
- Use Lua 5.1 for every `tests/test_*.lua` and the packaging smoke test. No in-game visual/real loot evidence yet.
- When full in-game tests begin, first **fully close WoW and take paired backups** of `Interface/AddOns/NaxxLootLottery/` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` / `.lua.bak` where present. Preserve the 604 bot plan records and old winners; never distribute a development ZIP as the official release.

This stage is deliberately not a substitute for the owner approving actual item delivery.
