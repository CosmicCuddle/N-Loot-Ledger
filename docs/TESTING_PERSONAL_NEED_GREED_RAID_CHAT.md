# Draft test plan — personal NEED/GREED + RAID chat countdown

Status: **unmerged development test**, base is the verified HF2 draft, not official v0.1.0.29-rc.1. Current test version: `0.1.0.29-rc.1-dev1`. **Do not use this build for live Master Loot delivery.** The owner’s installed, visually checked `0.1.0.29-rc.1-hf2` remains the live fallback.

## Changes

### My Wishlist
- Gear/Items reservations gain a NEED/GREED button beside Remove. Each item starts NEED unless explicitly switched; re-click toggles back.
- Existing `localWishlists` remain booleans. Optional sparse `localWishlistGreed` stores only per-item GREED; no blanket conversion of old reservations, bots, Gear Plans or old loot history.
- Recipes remain guild/manual distribution, with the interest control disabled. No recipe can gain automatic tickets from this status toggle.
- NEED outranks GREED using the existing priority engine (GREED only if no eligible/uncertain NEED). Player submissions show [NEED] or [GREED] in raid-leader Inbox.
- V1 wire protocol remains unchanged for all-NEED submissions. If any item is GREED, both player and raid leader **must** run a V2-capable draft; otherwise the submission times out rather than erroneously converting it into NEED. Existing legacy inbox submissions still default NEED.

### Optional announcements & five-second countdown
- `/nll raidchat on` enables compact RAID announcement on ticket preparation (item/tier/number and capped candidate summary), each countdown second, and **confirmed** winner (explicitly NOT an award).
- `/nll rollcountdown on` delays Start Roll for five seconds. Every timer tick verifies the physical corpse is still open, same selected drop, raid leader/officer authority, unchanged eligible pool and no fake mode. A failed check cancels and audits the lottery, rather than rolling.
- Both flags default OFF on a new installation. Check with bare `/nll raidchat` and `/nll rollcountdown`. Each may be turned off by appending `off`.
- **Warning:** an extra five seconds matters if the corpse is near despawn. Countdown is not a replacement for New Drop/Confirm Drop.
- Original server `RandomRoll` and existing debug simulations remain unchanged when options OFF. No automatic `GiveMasterLoot`, leader routing, materials distribution or Gear Plan OBTAINED updates.

## Before testing in WoW
1. **Complete any open loot actions and fully exit WoW.** Back up BOTH the exact `Interface/AddOns/NaxxLootLottery/` folder and the current `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.lua.bak` if present. Preserve the player's 604 saved plans and roles.
2. Prefer a **separate backed-up WoW client** and a spare test character/account; do not deploy while the main Molten Core raid is actively looting.
3. Download the completed, passing GitHub Actions artifact from the branch and extract **the inner installable** `NLL-Need-Greed-Countdown-DEV1-TEST-ONLY.zip` (the outer artifact ZIP is not the addon folder). Replace ONLY the AddOns folder; do not overwrite WTF/SavedVariables.
4. Restart WoW: `/nll version` -> `0.1.0.29-rc.1-dev1`, `/nll status` -> READY, `/nll directaward` -> OFF. Confirm original Gear Plans, roles, and loot history are visible.
5. In My Wishlist → Gear/Items, inspect existing NEED records, select one item and click GREED; verify only its label changes, persists through `/reload`, and returns to NEED. Recipes remain disabled.
6. Use **two test clients of matching code version** to submit one NEED and one GREED. In the raid-leader Inbox, confirm both labels and review without accepting on the real account. On a backed-up throwaway account only, accept and verify both `PLAYER_SUBMITTED` statuses. Also confirm an older leader does not accept GREED as NEED; a timeout is expected.
7. Countdown/chat testing should initially run against mocks/controlled raid with an expendable loot opportunity. Start with `/nll raidchat`, `/nll rollcountdown` both OFF and check old behavior. If separately approved in a controlled raid, enable one at a time, then test prepared/5..1/confirmed winner messages. Never infer item award from a chat message.
8. Test cancellation when corpse closes, candidate pool changes, leader loses authority, or item selection changes before the countdown completes. **No real loot transfer** is authorized in this draft.
9. If anything is missing/wrong, stop and fully exit WoW; restore the original backed-up HF2 addon folder and its **matching** SavedVariables copy. Do not manually edit account data.

## Validation boundary
Lua 5.1 regressions include personal storage and old-NEED migration, V1/V2 negotiation, invalid interest rejection, UI toggle/recipe locks, and optional 5-second countdown / no real award calls. In-client visualization, network timing, multi-client addon-message ordering, RAID chat throttling and receiving physical loot still need the owner's explicit acceptance.

Developed in [draft PR #12](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/12). Further requests for visible Award Winner and routing unreserved gear **and materials** to the leader are separately tracked in [issue #11](https://github.com/CosmicCuddle/N-Loot-Ledger/issues/11).
