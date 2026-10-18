# Guild-loot receipt reconciliation and future routing preview — DRAFT

**Status:** Unmerged, uninstalled, still requires owner-controlled in-game testing. Based on NLL draft PR #17 (remote human receipt sync), which stacks on #16, #15, #14, #13, #12 and HF2 #10. The owner's working HF2, real 604 Playerbot Gear Plans and saved loot records are NOT modified by development. No database/server/SQL action.

## Problem

World of Warcraft 3.3.5a's `GiveMasterLoot` doesn't return a trustworthy independent recipient receipt. `LOOT_SLOT_CLEARED` also doesn't prove delivery. Previously, a guild transfer whose loot slot cleared stopped blocking *other* guild transfers, without anyone checking the raid leader's inventory. This was an audit gap.

The client also does not expose a trustworthy physical corpse GUID. Even after an audit is confirmed, the same itemID + loot slot remains blocked from another transfer to prevent silent retries or same-item duplication. This is intentionally conservative and will need a separately reviewed new-drop identity/reconciliation policy before normal automatic allocation.

## New recipient-side reconciliation

1. Once a guild Master Loot attempt has been recorded, it is **AWARD_REQUESTED**, **AWARD_OUTCOME_UNKNOWN** or **LOOT_SLOT_CLEARED** until the intended recipient personally checks the item in their bags.
2. All THREE statuses now block new guild transfer requests. No slot-clear automatically unlocks another attempt.
3. **The intended raid leader recipient** (same character who was to receive the item) opens NLL's **Guild Loot → Reconcile Awards**, or `/nll guildreceipts` after the raid. The old corpse does not need to be present to review past saved audit.
4. The recipient selects the exact saved request and clicks **I Checked My Bags**, then **CONFIRM RECEIVED** within 15 seconds. Each click rechecks that the local character matches the recorded intended recipient; a changed item, quantity, status or recipient aborts without edits.
5. NLL marks that one request **RECIPIENT_CONFIRMED**, stores the prior status, confirmer, time and `RECIPIENT_CHECKED_OWN_INVENTORY` human evidence. Any matching in-memory pending reference is cleared. This is a **human attestation**, not independent server proof.
6. Other, unconfirmed requests continue blocking new transfers. The old itemID+slot always remains blocked, **even if confirmed**. The original request row is never deleted or reset.

This workflow **never calls `GiveMasterLoot`**, does not create items, does not modify the loot winner or any Gear Plan, and never interprets uncertain loot as safe to retry. A physical item the recipient did not receive should remain unconfirmed until investigated. Do not mark it received to make a new transfer possible.

## Future automatic guild routing: preview ONLY

- `Core/GuildLootAutoPreview.lua` classifies **all actual live item-link slots** (gear, recipes, mats/reagents), using the existing `GuildLootReview` reservation analysis.
- Saved NEED and GREED status → `RESERVATION_BLOCKED`.
- Unknown source, pending Inbox, quest/legendary/special, uncached/locked loot → `MANUAL_HOLD`.
- Unverified earlier transfer → `TRANSFER_HISTORY_BLOCKED`; repeated itemID+slot → `PRIOR_ATTEMPT_BLOCKED`.
- Other live unreserved entries → `CANDIDATE_ONLY` (**not** permission to transfer). Absence of stored reservations does not prove every human's wishlist has been submitted.
- NLL's Guild Loot window shows a compact **DRY RUN** count of candidates, reservations, manual holds and previously attempted items, plus **ZERO AUTO AWARDS**. `/nll guildpreview` shows the same counts.
- There is **no automatic transfer setting**, timer or `GiveMasterLoot` path in this preview. `automaticTransfers=0` and `automaticTransferAuthorized=false` remain explicit on every result.
- Real automatic distribution is blocked pending separate live testing of recipient eligibility and physical item receipt, full raid reservation completeness, item/corpse identity and guild policy. No bulk auto-roll/auto-master-loot workflow is authorized here.

## Offline acceptance tests

- Full Lua 5.1 regression suite, including `tests/test_guild_reconciliation.lua`, `tests/test_guild_reconciliation_ui.lua`, `tests/test_guild_auto_preview.lua` and amended existing `tests/test_guild_loot_transfer.lua`.
- Tests cover no mutation on first click, expiry after 15s, actor or audit mutation, post-raid access, confirmed-only-on-second-click, duplicate prevention, all-item preview and changed/closed corpse, separate player/bot Gear Plan preservation.
- Separate GitHub Actions workflow gates only these approved files, asserts two OFF-by-default real transfer opt-ins, no automatic GiveMasterLoot in either new module, and package integrity.

## Later, owner-approved in-game testing

**Do not install a development branch during a raid.** After finishing current loot, fully exit WoW. Back up both the exact `Interface/AddOns/NaxxLootLottery/` folder and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` plus `.lua.bak`, so the user can restore both matching copies if anything changes.

Use a spare/test realm or expendable item and a separate account/character where possible. Check `/nll version` is `0.1.0.29-rc.1-dev4`, Direct Master Loot OFF, Guild Transfers OFF, all 604 saved Playerbot plans still present. Never mark an uncertain item received unless the intended raid leader actually finds it in their own inventory. Verify the exact audit row and no accidental transfer. Verify that a new distinct corpse cannot cause an old same-item attempt to be duplicated.

**No release, tag, merge, installable ZIP or real award is produced by this PR.**
