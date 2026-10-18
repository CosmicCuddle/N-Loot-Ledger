# NLL — Per-Item Playerbot Role Reviews (Draft #33)

**Base:** draft #32. **Development-only version:** `0.1.0.29-rc.1-dev15`. No installation.

## Important distinction: which role is edited?

A Gear Plan's own `row.role` describes how a **particular bot** plans to use **one item**.

The shared `db.roleAssignments` role describes the bot's wider raid assignment. Changing one item must **never silently change this shared assignment**, since it can affect other Gear Plans and raid strategies.

This stage edits **only the selected existing BOT_GEAR_PLAN row's role**.

## In-game intended workflow (not yet tested)

1. Open **My Wishlist → Gear Plans** and use **Filter character (exact)** to find one bot.
2. On an existing bot row, press the small **Edit** button in the **Role** column. Short role labels are used to avoid crowding the adjacent **Source** column.
3. Select a full role from **Main Tank, Tank, Healer, Melee DPS, Ranged Physical DPS, Caster DPS**.
4. A separate review window displays the exact bot, item ID, **old item role → new item role**, and reminds the operator that the global raid role will stay unchanged.
5. Press **CONFIRM THIS CHANGE** within 15 seconds or **Cancel (Keep Plan)**.
6. Returning to the list shows the new **item-only** role; existing global roles, other items, winners and receipts remain unchanged.

## Safety

- An invalid role ID, unchanged role, missing or wrong record, nonbot source, already OBTAINED row, outstanding winner/receipt, fake raid or active loot workflow is refused.
- Picker selection does not write. Confirmation revalidates the actor, original row pointer, complete Gear Plans fingerprint, original status and role, and 15-second deadline.
- Page changes, exact-character filter changes and Cancel disarm the picker and any pending confirmation.
- This never calls `GearNeeds:AddNeed` or `Database:SetRoleAssignment`, never creates an OBTAINED receipt, never changes historical NO RETRY locks, never awards physical loot.
- New explicit Edit button and compact role label occupy the existing 105-pixel role column. Real client font/scale acceptance remains pending.

## Planned owner-approved WoW acceptance

- [ ] Back up the **entire installed addon folder** and complete `NaxxLootLottery.lua` / `.lua.bak` SavedVariables on every test client.
- [ ] Confirm original baseline **604 plans / 38 bots / 469 NEED / 135 GREED** before any test.
- [ ] Use a safe **test character/item** that is not OBTAINED, not won, and has no pending receipt.
- [ ] Press Edit; verify every official role appears and the original per-item role is unchanged.
- [ ] Choose a role, then Cancel; confirm no change.
- [ ] Choose a role, expire 15 seconds, then Confirm; confirm no change.
- [ ] Test a successful approved role change; compare just one `BOT_GEAR_PLAN.row.role` with the original backup.
- [ ] Confirm **db.roleAssignments** and **every other bot's item roles** are unchanged.
- [ ] Verify nonbot, OBTAINED and pending winner/ACK rows cannot use this editor.
- [ ] Change pages/character filter during selection to confirm cancellation; check the controls do not overlap at actual UI scale.
- [ ] Roll back with the matched addon + SavedVariables backup only under owner approval.

## Verification gates

- [x] Added Lua 5.1 604-plan fixture, all six roles, actor/expiry/fingerprint checks, pending receipts, no-retry and UI picker/confirm tests.
- [ ] Dedicated and full historical regressions must PASS at current exact GitHub head.
- [ ] Real WoW 3.3.5a testing and any merge/install require the owner's separate approval.

**Draft-only. No SQL/server module change, installation, real item award, SavedVariables modification or release.**