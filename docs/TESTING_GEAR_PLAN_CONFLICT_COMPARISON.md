# NLL — Read-only Gear Plan Import Conflict Comparison (Draft #34)

**Development-only:** `0.1.0.29-rc.1-dev16`.  
**Stacked on:** draft PR #33. **Installed owner's addon remains HF2.**

## The problem

The existing `NLL-GEARPLANS-1` importer correctly refuses to replace any
existing bot plan, but the message only shows the character and Item ID.
With **604 real Gear Plans across 38 bots**, a safe way to inspect a
conflict is needed before an operator decides which individual plan to
review manually.

This stage introduces **comparison only**, NOT import conflict resolution,
automatic replacement, merge, or deletion.

## New controls

1. Open Gear Plans → **Import / Export**.
2. Choose **Paste / Import**, paste the original
   `NLL-GEARPLANS-1` data, then choose **Preview Changes**.
3. If there are existing-key or case-alias conflicts, **Confirm ADD
   stays disabled** and a **Compare Conflicts** button becomes available.
4. Open **Compare Conflicts**. The separate window shows:
   - `CONFLICT X/Y` and exact incoming character/item.
   - **SAVED** and **PASTED** for each differing field: Character,
     Type, Role, Raid, Item ID, Source or Interest (NEED/GREED etc).
   - Explicit **CASE / UTF-8 CHARACTER ALIAS** warning where the
     character differs only by case/Latin-1 casefold.
   - **Import BLOCKED** and directions to use the separate existing
     per-item review flow for approved edits.
5. **Previous Conflict / Next Conflict** view remaining rows; **Close
   (No Changes)** hides the comparison. The original paste remains in
   the edit box, unchanged.

The modal has **no Apply, Replace, Merge, Delete or Confirm** action.
Normal add-only import remains unchanged for batches without conflicts.

## Immutable safety and edge cases

- Every comparison requires the same exact originally-previewed text
  and the same snapshot of all saved Gear Plans. Changing even a space
  or any stored plan blocks stale comparison.
- Valid V1 input only, maximum 250 rows and 48 KB per pasted batch.
  Existing 3.3.5a single/doubled pipe validation is unchanged.
- An import with 1 valid new plan and 1 conflict still blocks **all**
  additions. It can only be inspected, never applied.
- The preview distinguishes **EXACT_KEY** vs **CASE_ALIAS** and never
  generates duplicate Latin-1 case variants of bot identity.
- No current winner, saved plan, raid role, personal wishlist,
  recipient receipt, physical award or permanent NO RETRY lock changes.
- Disarming on text edit, mode change, cancel/close, or new preview
  prevents old comparison windows from blessing a changed paste.
- Paged report text is bounded to validated fields of a single row,
  not a full 604-record account dump.

## Owner-approved real-client test (NOT done yet)

1. Copy the existing installed `Interface/AddOns/NaxxLootLottery/`
   directory and account `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua`;
   back up `.lua.bak` as available. Keep a matched pair.
2. Verify original **604 plans / 38 bots / 469 NEED / 135 GREED**.
3. In an owner-approved non-live testing setup, paste a two-row
   `NLL-GEARPLANS-1` batch where an existing Playerbot item differs in
   Role and/or Interest. **Do not press Confirm ADD**.
4. Preview; ensure it reports conflicts and **Confirm ADD stays disabled**.
5. Open Compare Conflicts and verify **SAVED** vs **PASTED** values are
   legible, correct and not clipped at the client's actual UI scale.
6. Check keyboard/mouse navigation, Previous/Next boundaries and Close.
7. Test a case/UTF-8 alias in a disposable test plan, not against
   important real reservations.
8. Modify pasted text; verify comparison disappears and its old
   confirmation cannot be reused. Re-preview to inspect new text.
9. Try a paste with both a new and conflicting plan: neither may be
   written. Confirm an all-new batch continues using the established
   add-only Preview → Confirm ADD process **only in a disposable fixture**.
10. Compare SavedVariables with backups and record screenshots. No
    changed role, status, item, receipt, audit or settings are expected
    from the comparison feature.

## Automated checks

- [x] Added Lua 5.1 604-row fixture plus one Latin-1 case alias;
      tests role/status differences, exact and alias identity, invalid
      and stale indices/text/roster, blocked/normal import boundaries,
      and original objects remaining unchanged.
- [x] Added UI mock tests for Compare enabled only after conflict,
      two paged saved/pasted views, no Confirm ADD, Close and disarm.
- [ ] Dedicated no-release and entire Lua 5.1 regressions on final SHA.
- [ ] Separate actual WoW 3.3.5a acceptance under owner approval.

**No merge, install, published release, SQL/server change, physical
item award or modification to the owner's real data.**