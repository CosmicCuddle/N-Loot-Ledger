# NLL — WoW 3.3.5a Loot Source Identity Investigation

**Stage:** NLL-030, draft PR #30 (built atop #29).
**Development version:** 0.1.0.29-rc.1-dev12.
**Status:** Safe diagnostic implemented; reliable physical item/corpse proof
still **UNSOLVED**. No physical item may be re-issued because of this stage.

## The verified API limit

The WoW API **GetLootSourceInfo(lootSlot)** was introduced in **patch
5.0.4**, after Wrath 3.3.5a. We must not call or require it on the
owner's AzerothCore/Individual Progression/Playerbot 3.3.5a client.

References:

- https://warcraft.wiki.gg/wiki/API:GetLootSourceInfo
- https://warcraft.wiki.gg/wiki/Patch_5.0.4/API_changes

In the supported client:

- GetLootSlotLink(slot) identifies an item displayed at a temporary
  **loot-window slot**. The slot position is NOT an item-instance ID.
- GetNumLootItems and GetLootSlotInfo do not supply a stable per-corpse
  source GUID. Stack quantities also do not distinguish physical copies.
- UnitGUID("target") identifies only the **currently targeted unit**.
  It can refer to a different living enemy, party target or nothing
  while a loot window is open. A different target is NOT reliable
  evidence of a new corpse or item source.
- LOOT_OPENED and LOOT_CLOSED provide window events, not a validated
  per-item source proof. Reopening the same corpse can yield new events.
- Two distinct creatures may drop identical material item IDs. Even
  the player's deliberate New Drop -> Confirm Drop acknowledges a
  possible new opportunity but is not a cryptographically or
  server-verified link to each original item.

**Consequence:** never automatically unlock an old attempted item ID
because the target GUID, corpse name, slot, quantity, timestamp,
loot-opening count, item link, boss death or manual New Drop changed.

## Stage #30 read-only diagnostic

- /nll lootsource
- Works only with a real observed open loot window; returns no stale
  item evidence after the corpse closes or in Debug Simulator fake mode.
- Prints live item-slot count, number of slots with prior guild/winner
  attempt locks, visible same-ID material copy slots, and up to six
  diagnostic lines for held/repeated entries.
- If UnitGUID("target") exists, prints it with an explicit
  **CURRENT TARGET HINT — NOT LOOT SOURCE PROOF** warning.
- Returns sourceVerified=false, canUnlock=false,
  autoTransferAuthorized=false for every call, without exceptions.
- **Never calls** GiveMasterLoot, RandomRoll or GetLootSourceInfo.
- Makes no SavedVariables writes, doesn't persist target IDs, doesn't
  grant new abilities, doesn't change current guild transfer or
  winner retry guards. All consent settings stay OFF on login.

This is a *diagnostic only*. It is not another "New Corpse" button,
a special admin override, or an automatic material allocation feature.

## Simulated acceptance matrix (Lua 5.1)

- [x] Previous guild transfer with CLOSED_NO_RETRY stays held across
      new loot slot positions.
- [x] Previous winner with AWARD_OUTCOME_UNKNOWN stays held.
- [x] Two identical materials in one loot window flagged as ambiguous.
- [x] Different target GUID while old item appears cannot unlock.
- [x] Target absent, live loot closed, missing 3.3.5a API or fake
      raid provide no invented source identity.
- [x] Simulated 5.0.4 GetLootSourceInfo (if injected) is NEVER called.
- [x] No Gear Plan, stored loot history, winner receipt or durable
      item-attempt lock is mutated.
- [x] Neither physical item transfer nor rolling API is invoked.
- [x] Dedicated and full Lua 5.1 GitHub CI passed; exact-head
      proof links are retained on PR #30.
- [ ] Owner-approved in-game checks on an actual 3.3.5a client.

## Future solution research (no implementation or authorisation)

For genuinely distinct corpses to safely carry identical material IDs,
we would require a separately reviewed *trustworthy per-loot source
identity*. One possible design would be authenticated server-side
events that bind **loot source GUID, specific item-instance / stack
identity, slot, allowed recipient and verified receipt** to each
attempt. AzerothCore and any relay would need separate compatibility,
replay, permission, reconnect, corpse/despawn and audit threat-model
testing. A server event is NOT automatically authenticated simply
because a Lua addon receives a message.

Even with strong source identity, an old request's permanent write-ahead
NO-RETRY lock must never be reissued; the trusted proof could only allow
separately authorised **new** physical copies after additional owner
review. Nothing here modifies the core, SQL, individual-progression
module or Playerbots.

## Owner-approved future WoW test checklist

- [ ] Before using any newer draft build, back up the installed
      Interface/AddOns/NaxxLootLottery directory.
- [ ] Back up account SavedVariables NaxxLootLottery.lua and
      NaxxLootLottery.lua.bak if present on **all** test clients.
- [ ] Verify the 604 saved plans / 38 bots / 469 NEED / 135 GREED
      baseline and compare history before and after diagnostics.
- [ ] On an owner-approved controlled dev client only, open one real
      loot window and run /nll lootsource; record console/screenshot.
- [ ] Reopen same corpse, change target, clear target, and inspect a
      known repeated material. No result should claim a source proof.
- [ ] Verify old attempts are still held and ALL manual/automatic
      physical transfer consent remains OFF.
- [ ] Compare actual SavedVariables; inspect no added audit/receipt
      records from merely running the diagnostic.
- [ ] Confirm fallback UX when no loot window is open or current
      target GUID is unavailable.
- [ ] No deliberate repeat granting as part of this diagnostic test.

**Installed build remains 0.1.0.29-rc.1-hf2.**
No in-game test, merge, release, deployment or physical award has
occurred as part of the development stage.
