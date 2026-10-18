# NLL C13 — Verified physical-copy and corpse identity: evidence contract

**Stage:** C13, draft PR #36, WoW 3.3.5a / AzerothCore / Individual Progression.  
**Current capability:** read-only grouped copy-risk audit. **No new grant, second-copy reservation, retry, source or recipient proof is authorised.**

## Why slot counts are not independent physical copies

WoW 3.3.5a exposes `GetNumLootItems()`, `GetLootSlotLink(slot)` and `GetLootSlotInfo(slot)`. These identify **visible loot slots, links and displayed stack quantities**, not durable per-source or per-item-instance identities.

`GetLootSourceInfo` was added in patch **5.0.4** and is unavailable on 3.3.5a; `UnitGUID("target")` identifies the currently targeted unit, not necessarily the corpse furnishing a loot slot.

Authoritative references:
- [Warcraft Wiki — GetLootSourceInfo (added 5.0.4)](https://warcraft.wiki.gg/wiki/API:GetLootSourceInfo)
- [3.3.5a original LootFrame.lua uses GetLootSlotInfo quantity](https://github.com/wowgaming/3.3.5-interface-files/blob/main/LootFrame.lua)
- [Warcraft Wiki — GetLootSlotLink](https://warcraft.wiki.gg/wiki/API:GetLootSlotLink)
- [NLL's existing WoW 3.3.5a source study](RESEARCH_WOTLK_LOOT_SOURCE_IDENTITY.md)
- [Original wishlist multi-copy proposal (NOT implemented)](MULTI_COPY_IMPORT_EXPORT_BLUEPRINT.md)

### What the client can show

| Observation | What it establishes | What it does **not** establish |
|---|---|---|
| Two visible slots with item ID 17010 | Same item ID appears in two loot-window slots | Distinct corpse GUID, independent loot transactions, permission to retry an old award |
| One slot, quantity 20 | The UI displays a stack amount of 20 | 20 independently grantable copies, valid recipient receipts |
| Different target GUID | Targeted unit changed | Source/corpse providing item changed |
| Different loot slot index or LOOT_OPENED event | Client layout/window changed | Verified new item instance, no previous award |
| New /nll newloot confirmation | Operator believes loot opportunity differs | Server-authenticated physical identity; old award retry authorisation |
| Recipient human report or LOOT_SLOT_CLEARED | A client-level statement/slot observation exists | Independently verified inventory transfer or old request release |
| Two wishlist or equippable slots | Two UI intentions/slots exist | Two identical rings can be worn on *this* realm (unique restrictions differ) |
| CLOSED_NO_RETRY recorded | Original attempt closed for review without repeating | Old transfer lock cleared or another grant permitted |

## C13 implemented, read-only audit

Run **`/nll copyaudit`** in an owner-approved future **real observed open loot window** to see:

- Count of distinct visible item IDs and visible loot slots.
- Sum of displayed stack-unit quantities for each item ID. This is **UI quantity**, explicitly not proven physical copy identity.
- Existing winner/guild prior-attempt holds on that item ID.
- Deterministic sorted, bounded diagnostics for at most six duplicated/stacked/held item IDs.
- Explicit warning that nothing is a verified source or new independent copy.
- Closed/unverified windows and fake raids return **no live item rows**, even if prior saved history is present.
- No persistent audit, user SavedVariables writes, RNG, roll, slash reset, `GiveMasterLoot`, `SendAddonMessage`, `GetLootSourceInfo`, SQL or AzerothCore modification.

Every audit and per-item row keeps `canUnlock=false`, `canRetry=false`, `canAward=false`, `autoTransferAuthorized=false`, `physicalCopyVerified=false`; multi-copy plans remain unsupported.

## Hypothetical authenticated future server-side evidence — **research only**

No current addon code parses or trusts these events. A server-side bridge is **not built, installed or authorised**.

A separately reviewed server-origin event system **might** one day provide evidence *only after* all of these design requirements are independently demonstrated:

1. **Authoritative identity origin:** AzerothCore allocates server-owned unique IDs for each independently grantable loot occurrence; bind the server's realm/instance/session, source/corpse GUID, original loot/container record, item entry, actual stack portion, and an unforgeable transaction/epoch identity. A loot **slot index** alone is not sufficient.
2. **Authentication and freshness:** The client must verify authenticated server origin, authority and target context (not ordinary player-supplied addon chat), short expiry, session binding and anti-replay nonce. Any chat payload or unsigned GUID is untrusted.
3. **Idempotency:** Server side enforces at most one physical grant per unique verified *new* copy. Maintain durable write-ahead status and original recipient attempts across reconnects, reloads and crash recovery.
4. **Receipt evidence:** Authoritative acknowledgement must tie the successful server inventory change to the exact target character and item transaction. `LOOT_SLOT_CLEARED`, local bag counts, an ACK whisper or `GiveMasterLoot` return do not independently prove this.
5. **No old-request reset:** Historical original `AWARD_REQUESTED`, `AWARD_OUTCOME_UNKNOWN`, `LOOT_SLOT_CLEARED`, `CLOSED_NO_RETRY` and saved `awardAttemptLocks` remain permanently non-repeatable. The bridge **must never** reopen the original transaction. A *new* proof can only be considered for a **distinct new source/transaction** with separate future, deliberately authorised review and transfer rules.
6. **Raid authority and availability:** The server validates current Master Looter, recipient online/group/eligible status, loot source still active, route of loot ownership and no conflicting roll. All these are time-bound checks; previous authority cannot be cached indefinitely.
7. **Threat model:** Reject replayed events, forged addon chat, duplicated source IDs, arbitrary user target GUIDs, moved slots, two clients racing for the same stack, partial stack grants, stale receipt, server crash and imported SavedVariables.
8. **Realm-specific unique item rules:** Confirm item-template uniqueness and equip limits for item 19147 (Ring of Spell Power) and any other duplicate-equippable candidate on the actual AzerothCore/IP realm. Two finger slots by themselves are no assurance of a second identical equip.
9. **Staged owner approval:** The eventual server/core/module change must be developed and reviewed in a different, owner-approved project/PR with matched backups, compatibility testing and a standalone no-release path before any server deployment. No automatic guild awarding is implied.

**Do not treat this blueprint as an instruction to change or install the server.** Its purpose is to make future safety criteria explicit and keep the current conservative holds intact.

## Controlled acceptance checklist (NOT performed)

- [ ] Before testing any new development draft, copy the complete installed addon folder and the matching account `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `.lua.bak` where present, on every participating client.
- [ ] Verify the original 604 saved Playerbot Gear Plans / 38 bots / 469 NEED / 135 GREED, recipient audit, attempted loot, original closed-no-retry outcomes and consent settings OFF.
- [ ] In an explicitly authorised testing setup, use `/nll copyaudit` with **closed** loot and fake raid; there must be no current item rows.
- [ ] Open one real controlled loot window with repeated material/stack quantities and run `/nll copyaudit`; compare visible slot and displayed unit counts. No action should be offered.
- [ ] Change target and slot ordering if safe; unchanged old holds must still show. Also run `/nll lootsource` to confirm target is labelled a hint only.
- [ ] Never try repeating a physical Master Loot attempt to validate a diagnostic. No original award may be reissued.
- [ ] Check no unexpected SavedVariables changes or new persistent receipt/attempt records, including across `/reload`.
- [ ] Verify real chat readability, bounded six-item lines and the no-authorisation warning.
- [ ] Confirm original copy-count wishlist semantics remain ONE, pending later separate approved multi-copy design.

## Offline verification

- [x] Lua 5.1 test fixture: repeated item 17010, stacked 17011, uncertain winner item 16800, possible 19147 second-copy ring, 604 preserved original Gear Plan rows.
- [x] Different target, reordered slots, partial copy subset, old no-retry evidence, fake/closed/missing APIs, and attempts to forge a later `GetLootSourceInfo`-like source claim all fail closed.
- [ ] Dedicated exact-head and entire historical Lua 5.1 CI.
- [ ] Owner-approved real 3.3.5a screenshots, SavedVariables comparison and client acceptance.

**Installed HF2 is unchanged. No merge, release, install, server change or loot transfer.**
