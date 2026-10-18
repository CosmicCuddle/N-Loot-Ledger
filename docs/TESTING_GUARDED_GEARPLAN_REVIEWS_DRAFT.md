# NLL — Guarded Existing Playerbot Gear Plan Reviews (Draft #32)

**Dev-only version:** `0.1.0.29-rc.1-dev14` (46 Lua modules).
**Base:** draft #31. **Owner installation remains HF2.**

## Problem and solution

The previous Gear Plans list immediately applied status dropdown selections or deleted a plan upon pressing **X**. With 604 real saved bot reservations, this is too easy to do unintentionally.

Draft #32 makes **existing Playerbot plan status changes and removals** an explicitly confirmed workflow:

1. Open **My Wishlist → Gear Plans**, optionally filter to an **exact** bot name.
2. Select **NEEDED, GREED or DISABLED** in that plan's status dropdown, or select **X**.
3. NLL opens a review window naming the **exact character and item ID**, showing the proposed change. At this point **nothing has changed**.
4. Select **CONFIRM THIS CHANGE** within **15 seconds**, or **Cancel (Keep Plan)**. A fresh review is needed if time elapses or anything relevant changes.

### Safety boundaries

- Operates **only** on an existing `source=BOT_GEAR_PLAN` and `characterType=PLAYERBOT`, with matching saved identity/key. It does not touch `PLAYER_SUBMITTED` or `RAID_LEADER_MANUAL` rows.
- **OBTAINED cannot be selected manually.** An already obtained record cannot be manually downgraded or removed by this workflow. Real recipient receipt confirmation is the existing separate path to OBTAINED.
- Records with a pending winner/recipient receipt or unverified physical award history remain **HELD**. `LOOT_SLOT_CLEARED` and `CLOSED_NO_RETRY` do not constitute receipt proof.
- Existing `GearPlanTransfer:IsBlocked()` prevents changes in the Debug Lab, during an active lottery or open loot window, and restricts actor authority in an actual raid.
- Confirmation checks the exact saved record, the acting client character, the full saved Gear Plans fingerprint, and a 15-second deadline. Changes or cancellation invalidate consent.
- Status changes only update **that saved row's status**. Confirmed deletion removes only the exact reviewed bot plan. Neither operation edits global roles, character types, historical winners, other saved plans, receipts or personal wishlists.
- Changing page or exact-character filter cancels an armed review.
- The original import/export remains **add-only** and independent. This stage does not introduce bulk overwrite, automatic item assignment, role editing, or an `OBTAINED` shortcut.

## Owner-approved in-game test checklist (not yet performed)

- [ ] Back up `Interface/AddOns/NaxxLootLottery/` and the matched account `NaxxLootLottery.lua` and optional `.lua.bak` first.
- [ ] Verify 604 existing plans / 38 bots / 469 NEED / 135 GREED, plus roles, previous winners, receipts, and personal wishlists.
- [ ] Filter to one bot by its exact character name; choose a **non-OBTAINED** test row with no outstanding winner.
- [ ] Change NEED → GREED. Confirm initial dropdown click only **previews** and the saved row remains NEED until the second explicit click.
- [ ] Check **Cancel**, expiration after 15 seconds, closing/reopening the window, page changes and /reload. No stale confirmation should persist.
- [ ] Confirm X requires review and that Cancel keeps the original entry. Do not delete an important real reservation simply to test.
- [ ] Confirm OBTAINED cannot be made from the dropdown or downgraded; pending winner/ACK histories deny changes and deletion.
- [ ] Confirm nonbot rows are not modified by the bot editor; role, type, status of unrelated 603 rows and old loot history remain unchanged.
- [ ] Verify controls, long item/character names and modal separation at the real 3.3.5a UI scale with screenshots.
- [ ] Restore from paired backups only when the owner authorises rollback and after preserving test evidence.

## Verification status

- [x] Lua 5.1 offline mock fixture covers 604 existing plans, two-step changes, cancellation, expiration, stale record, changed actor, wrong state, pending receipt, NO RETRY, and the modal.
- [x] Dedicated no-release and full historical Lua 5.1 regression CI
      passed; final exact-head run IDs linked in draft PR #32.
- [ ] Owner-approved actual WoW client acceptance.

**No live SavedVariables were touched. No item was awarded, no module/core/SQL file installed, and no merge or release was performed.**