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
   request. The popup now opens the **existing Confirm Item Receipt**
   review for the exact saved drop automatically after a successful
   AWARD ITEM request. This is a **read-only next step**, NOT proof of
   delivery. Until the loot slot is observed cleared, the review is
   `NOT READY`; the operator must independently verify recipient
   inventory and click **I Checked Inventory → MARK OBTAINED**.
   Those two explicit clicks alone can update a matching local plan;
   a remote player's own wishlist still needs synchronization.
   Guild materials usually have no matching Gear Plan because any
   saved NEED/GREED blocks this leader-only route.
6. The older Guild Loot window remains a **read-only all-item review**
   and may still support ordinary unreserved non-material review, but
   material controls are labelled **Tickets**, with old Guild Master
   physical transfer disabled for these five IDs. Dry Run explains
   **USE_LEADER_TICKETS** rather than proposing Guild Master.

## Verification additions — after source review (31 October)

- **Actual location must be Molten Core:** the leader-only route checks
  `GetInstanceInfo()` for **raid** type and map ID **409**, when exposed.
  Because client/API references disagree on whether 3.3.5a exposes the
  eighth map ID, a missing ID permits the exact English instance name
  `Molten Core` with `raid` type. A different non-nil ID or a different
  name without an ID fails closed; other languages may need a separately
  verified translation. Recognition of item 7075 or other materials in
  outdoor/unrelated loot alone can never create guild tickets.
  In-game client confirmation of the location API is still pending.
- **Receipt screen refresh:** after a successful AWARD ITEM request,
  the read-only receipt review opens without marking anything obtained.
  If WoW later reports that same loot slot cleared while that exact
  receipt window remains visible, NLL refreshes the warning/status in
  place. A cleared slot is NOT recipient ownership evidence; only
  `I Checked Inventory` and the subsequent `MARK OBTAINED` action
  can update matching plans.
- **Practical single-click limitation:** on this client the matching
  item must already be **selected in the Blizzard Master Loot window**
  before pressing the NLL popup's AWARD ITEM. A fully self-selecting
  loot action is NOT yet verified. The popup now explains this requirement
  instead of promising a completely untouched-window one-click action.
- **Receipt-created-before-award special case:** `TicketLottery:Finish`
  creates a real `WON_AWAITING_ITEM` receipt before the operator can press
  AWARD ITEM. The recheck now excludes **only the exact, completed, same-UID,
  same-item, same-full-winner guild receipt** when determining eligibility for
  that item's first physical award. A missing/mismatched receipt, any older
  unverified receipt or any other pending human ACK remains a HOLD. The
  ordinary read-only Guild Loot summary still shows the pending receipt.
- **Online raid-leader safeguard:** the raid roster's explicitly offline
  leader marker (e.g. zone `Offline`, online `0` or `false`) blocks the
  sole-ticket route. A missing optional online flag on a custom 3.3.5a
  Playerbot roster is **not** interpreted as online proof. Correct
  recipient still must be uniquely present in the real Blizzard Master
  Loot candidates before any physical award.
- **All physical award routes re-check policy:** even if a one-ticket guild
  winner has already been recorded, standard Review Award and opt-in
  winner-popup AWARD ITEM must re-confirm that the live recipient remains
  the same raid leader and the item remains safely eligible. Neither route
  can use a stale guild allocation after leadership changes or new holds.
- **Cross-route permanent NO RETRY:** a previously sent normal Master Loot
  request for the same material ID blocks the guild ticket path using
  `lootAwardHistory` and **durable** `awardAttemptLocks`, even if the old
  audit was later reconciled or the WoW item moved to another slot.
- **Important owner impact:** these deliberately conservative physical
  attempt locks can stop later genuine drops with the same material ID.
  Without an authenticated per-corpse source token exposed to the addon
  (outstanding coordination issue #2), this draft **cannot honestly promise
  unlimited automatic repeat material transfers**. Never loosen the guard
  merely to make the feature appear to work.
- **Tests:** separate mocks for all five item IDs, non-MC source, changing
  raid leader, previous guild transfers, previous normal Master Loot
  requests and immutable locks. These are NOT evidence of in-game receipt
  or a successful real award.

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
