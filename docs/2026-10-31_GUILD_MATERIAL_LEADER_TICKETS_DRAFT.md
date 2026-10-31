# Guild materials: raid-leader-only tickets through normal Current Loot

**Owner decision:** 31 October 2026 — guild material allocation should use
**Prepare Tickets → Start Roll → winner popup → AWARD ITEM**, with
**only the actual raid leader** eligible for the guild-material ticket.

**State:** Draft code and mocked regression work in [PR #43](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/43), stacked on owner-requested one-click AWARD [PR #42](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/42), then C16 draft [PR #41](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/41). No real WoW test or merge; installed Build 60 unchanged.

## Exact scope

The five **existing** whitelisted IDs only: Lava Core (17011), Fiery Core
(17010), Core Leather (17012), Blood of the Mountain (11382), Core of Earth
(7075). We do **not** add every random unreserved green or trade good to the
new single-recipient policy.

Their destination changes from the former **Guild Master** path to the
**actual current raid leader**, regardless of whether guild master and raid
leader are the same person.

## Owner-visible behaviour

1. Open the **real** supported WoW loot window and select a whitelisted
   material in **Current Loot**. The scanner verifies the item ID, exact
   slot/link, valid stack count and cached non-special classification.
   Reserved NEED/GREED, remote ACK/pending receipt, uncertain identity,
   earlier unresolved award, failed threshold and prior Guild physical
   attempt all **HOLD**.
2. Click **Prepare Tickets**. The candidate preview constructs exactly
   **one ticket for the uniquely verified current raid leader**, with
   **GUILD** selection label. There is no special NEED/GREED contest and no
   extra tickets for guild master, officers, bots or unreserved users.
3. Click **Start Roll**. Because there is only one candidate, the result
   is a **deterministic guild allocation**, not a random draw. The
   module deliberately does not call `RandomRoll(1,1)`; it records
   `GUILD_LEADER_ONLY` and displays a **GUILD ALLOCATION** winner popup
   identifying the raid leader. The item is **not** awarded yet.
4. Use **AWARD ITEM** on the popup only if separately opted into physical
   **Direct Master Loot** and **Enable 1-Click Award** (both OFF at
   login/reload). The click verifies the actual designated Master Looter,
   selected live WoW slot, unique exact winner candidate and currently
   matching item link/stack. It then writes the permanent attempt/NO RETRY
   history **before** requesting `GiveMasterLoot`.
5. A successful API request **does not prove delivery**, so the Leader's
   Gear Plan/wishlist is not set to OBTAINED by a roll or Master Loot
   request. Separate **human-confirmed receipt** remains the only path
   to OBTAINED. (Guild materials normally have no matching Gear Plan
   because any saved NEED/GREED blocks this leader-only route.)
6. The older Guild Loot window remains a **read-only all-item review**
   and may still support ordinary unreserved non-material review, but
   material controls are labelled **Tickets**, with old Guild Master
   physical transfer disabled for these five IDs. Dry Run explains
   **USE_LEADER_TICKETS** rather than proposing Guild Master.

## Important guardrails

- New ticket policy does **not** override quest/recipe/legendary
  classification, materials with saved reservations, missing live loot
  data or physical award history. The special Windseeker NEED/GREED
  policy and normal equipment lottery are unchanged.
- The existing historical Guild Master transfer audit and its persistent
  same-material-ID NO RETRY hold remain authoritative. The normal
  post-drop loot-identity subsystem independently protects prior
  winners/duplicate physical contexts; the 3.3.5a client still cannot
  cryptographically prove new corpse identity. No authenticated source
  bridge was created or approved. The unresolved feasibility discussion
  remains [coordination #2](https://github.com/CosmicCuddle/Naxxramas-Server-Coordination/issues/2).
- **Master Loot quality threshold:** Some materials may fall below
  Blizzard's active threshold and cannot be assigned by Master Looter.
  NLL will HOLD them rather than silently change the raid's settings.
  Loot normally and trade separately when allowed.
- **A raid leader may not be the designated Master Looter.** Allocation
  may name the raid leader, but AWARD ITEM can only be used by the
  current designated Master Looter, and only while this character is an
  exact eligible Blizzard Master Loot candidate.
- This is an **experimental single-click physical transfer**; it needs
  full Lua 5.1 CI plus owner-approved, expendable in-game acceptance
  before any installation/merge/release. The existing installed Build 60
  does not include these changes.

## Acceptance checklist (all pending until verified)

- [ ] CI tests cover five whitelist IDs, one exact raid leader and no
  automatic `RandomRoll` or `GiveMasterLoot` on Prepare/Start.
- [ ] Missing Master Loot, reservation, pending receipt, threshold,
  unknown stack, quest/special, stale source and existing Guild audit
  prevent preparing/awarding a leader-only material.
- [ ] Guild Master may differ from raid leader; destination is still the
  actual raid leader, not guild master.
- [ ] All ordinary gear and Windseeker rolls retain their previous pool
  logic and never become leader-only.
- [ ] WoW client visual check of `GUILD ALLOCATION`, winner name and
  safely disabled AWARD ITEM while consent is OFF.
- [ ] **Only with separate owner go-ahead:** actual expendable transfer,
  correct recipient inventory evidence, no duplicated award, saved
  Gear Plans/history intact. No rare legendary test.

**No production/test client changes made by this PR.**
