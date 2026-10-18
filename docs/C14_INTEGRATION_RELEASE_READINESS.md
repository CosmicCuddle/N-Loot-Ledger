# NLL — C14 Combined Integration, Accessibility & Release-Readiness Handover

**Draft:** PR #37 stacked onto PR #36; developer candidate `0.1.0.29-rc.1-dev19` with 50 Lua modules.  
**Scope:** Desktop 3.3.5a addon mocked Lua 5.1 integration and navigational safety. This is **not a live-client accepted release candidate**.

## What was integrated

The 604-row synthetic 38-Playerbot fixture exercises the previously separate branches as a single stack, including:
- The established **604 Gear Plans / 469 NEED / 135 GREED** and deterministic 250/250/104 export batch preservation.
- The Stage #32/#33 **two-click** per-item status and role change, never changing global `roleAssignments` or unrelated saved plans.
- The Stage #34 saved-vs-pasted conflict report: a prior export cannot silently overwrite a subsequently changed row; any conflict blocks **all** additions.
- The Stage #35 profession recipe review: interest and role edits appear in the report, but no bot becomes *profession verified*, *eligible to learn*, or an authorised award recipient.
- The Stage #36 copy-risk audit: duplicated item IDs, stack quantities, and previous guild/winner attempt holds remain non-authorising, including `CLOSED_NO_RETRY`.
- Stale modal confirmation/preview disarming on main-frame tab navigation, Wishlist subtab switches, import dialog close, Escape or main window close.

## C14 safety repair: transient controls

**Identified integration defect:** prior draft modals were anchored to `UIParent` and could outlive their originating panel. A user could navigate to another tab or dismiss the main addon while an unrelated confirm/review modal remained visible or armed.

The shared `UI:DismissContextReviews()` path now:
- cancels an in-memory Gear Plan confirmation and the role picker;
- hides the previous Gear Plan review modal;
- invalidates/hides the read-only import conflict view;
- closes the separate recipe profession review;
- invalidates any import preview / Confirm ADD and closes the transfer dialog without touching SavedVariables;
- triggers on changing main addon tabs (even the same tab), hiding the main addon, Escape via WoW's `UISpecialFrames` OnHide hook, and changing the Wishlist subtab;
- an invalid new Gear Plan status/role selection cannot leave the previous confirmation visibly active.

The submitted paste text is **not a SavedVariables backup**; its transient import preview is invalidated when leaving the dialog. This does not alter the underlying saved Gear Plans.

## Automated verification gate

- [x] New `tests/test_c14_cross_feature_integration.lua`: real project core modules loaded together, 38 synthetic bots / 604 row identities, 469 NEED / 135 GREED; verify 3 export chunks (250/250/104), approved single-row status/role updates, blocked old import, updated read-only recipe interest and immutable physical source audit.
- [x] Main UI navigation and invalid selection mocked transitions; all previously armed controls revoked and new confirmation required.
- [x] Original personal wishlists, global raid roles, Gear Plans table identity and other 603 saved row objects remain intact; old winner/receipt/write-ahead/guild attempt history stays untouched; direct Master Loot and guild transfers OFF.
- [x] Dedicated C14 exact-head scope/NO RELEASE and historical Lua 5.1
      regressions passed; final exact-head evidence linked in draft PR #37.
- [ ] Actual WoW 3.3.5a FrameXML/Lua execution and multi-client acceptance with screenshots and paired account backups. **Mocked CI does not verify real client pixels or permissions.**

## Unresolved physical safety blockers — do NOT downgrade

| Area | Automated finding | Gate required before a release |
|---|---|---|
| Recipient inventory | Human ACK, self bag count, LOOT_SLOT_CLEARED and client message aren't authenticated server receipts | Never treat them as proof of delivery |
| Repeated physical materials | Client loot slots and stack units don't identify an independently grantable item or source | Same-item-ID NO RETRY physical locks stay; future server proof requires separate approved engineering |
| Legacy second copies | Ring of Spell Power unique/unique-equipped compatibility depends on actual realm and IP | No second-copy reservations / tickets in this build |
| Profession patterns | Saved NEED/GREED bot plan doesn't prove skill 300, learned status or spec | Manual-only review; no recipe auto allocation |
| Owner data | Installed HF2 has **604 plan records across 38 bots** | Paired full addon and SavedVariables backups before any test |
| Parallel drafts | Alternative PRs #18–#21 weren't merged into the main stack | Preserve comparison and explicit PR review; do not blindly cherry-pick |

## Owner-approved in-game acceptance sequence (NOT yet begun)

1. **Choose a test window** separate from a real Molten Core raid or a copy of the game client. Make dated, matching backups of `Interface/AddOns/NaxxLootLottery` and `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua`, and the optional `.lua.bak`, for **each participating client**.
2. Confirm exactly **604 Playerbot plans, 38 bots, 469 NEED, 135 GREED** plus the account's roles, all previous winners, reserved recipes, materials, recipient receipts and permanent attempt locks.
3. Only after explicit owner approval, install a **temporary test build** (not an automatic release), load the client and check `/nll version`, the addon launcher and error-free Lua startup. Verify all physical transfer opt-ins OFF.
4. Exercise the 604-plan **250/250/104 batch export** and save each text chunk separately; do **not** consider three chunks a substitute for the full SavedVariables backup.
5. Filter by exact character, inspect status/role guarded edit and cancel; test the 15-second expiry, invalid new selection, change tab, go to Inbox, close main window, press Escape and reopen. No stale modal may remain active.
6. Check **SAVED vs PASTED** comparisons with a deliberately conflicting **test-only** row; Confirm ADD stays disabled and nothing overwrites real plans.
7. Inspect all ten Recipes/Prof. Review pages and 4-name candidate paging. Recipient profession and specialisation must remain UNVERIFIED.
8. In a strictly controlled loot context, use **`/nll lootsource` and `/nll copyaudit`**, including duplicate material stack and target changes. Never test a repeat grant; locks are permanent for the original request.
9. Test genuine human/bot multisession receipt behaviour only with an owner-approved plan, no real award unless separately authorised. Test NO RETRY, no pending review bypass and status OBTAINED only via the existing recipient confirmation path.
10. Verify real frame geometry: small UI scale, large UI scale, long character names, visibility of Edit, Compare, Prof. Review and transfer controls, mouse/keyboard navigation and Esc. Log screenshots and any overlap before acceptance.
11. Exit WoW, compare SavedVariables with the original full backup: no unplanned deletes, missing records, role/receipt rewriting or audit loss. If a problem is found, stop, preserve evidence and restore **the same paired addon + SavedVariables versions** only with the owner's authorisation.
12. **Release decision:** owner reviews unresolved safety limits, trial notes, PR stack #10–#37, alternative PRs #18–#21, actual UI acceptance and rollback. Only after explicit approval should any merge, release, installation or server operation be discussed.

## Gate summary

C14 automated work is **development completion, not production readiness**. Keep the latest stack **draft**. No GitHub merge, automatic release, SQL/core modification, live data migration or item award is warranted by tests alone.
