# NLL winner popup: optional single-click Master Loot award

**Date:** 2026-10-31  
**State:** DRAFT, not installed/released; client acceptance PENDING  
**Parent:** [C16 PR #41](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/41), installed test build 60 remains unchanged  
**Change:** [DRAFT PR #42](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/42)

## Owner request

When a completed live lottery pops up the winning character, offer a prominent
**AWARD ITEM** button so the designated World of Warcraft Master Looter can
give that physical item directly to the winner without opening another NLL
award dialog.

A real one-click award is an **irreversible** WoW Master Loot request. It
does NOT run automatically on a lottery result and must not mark any Gear Plan
or wishlist OBTAINED without separately confirmed physical receipt.

## Exact interaction — new draft only

1. The winner popup still shows **Review Award** (the existing safer two-step
   route) and **Close Result**.
2. **AWARD ITEM** is disabled on login/reload, during fake raids, or if no real
   pinned drop UID exists. Selecting WoW Master Loot alone does not enable it.
3. The operator must separately enable **Direct Master Loot** and then
   **Enable 1-Click Award** in NLL Settings → Loot Awards for *this* login.
   Turning Direct Master Loot off also revokes 1-click consent.
4. The one-click action checks the pinned saved completed real win and
   currently selected exact loot opportunity, its full item link and stack
   count, a real open WoW Master Loot dropdown on the exact slot, the actual
   designated Master Looter, live raid authority, and exactly **one** full
   case-insensitive matching Blizzard Master Loot candidate. Uncertain,
   simulated, moved, already-awarded or mismatched entries are refused.
5. Only then the click performs the existing AwardWorkflow
   Review → Arm → Commit validations in sequence. Its request attempt and
   immutable no-retry lock are recorded **before** `GiveMasterLoot`. API
   errors/silent failures remain UNKNOWN; never retry a physical item.
6. A successful API call is `AWARD_REQUESTED` only. **No Gear Plan changes
   to OBTAINED occur as a result of this click.** The separate leader/human
   inventory receipt checks remain necessary and another player's local
   SavedVariables cannot be rewritten by the leader.

## Testing gates before any owner install

- Lua 5.1 syntax and historical regression suite, including retained normal
  two-stage Review Award and independent direct/guild/quick consent checks.
- Mocked full-context positive one-click test: exact recipient and slot,
  exactly one request and durable no-retry audit, with Gear Plans unchanged.
- Negative tests: second click, fake raid, stale selection, altered item link,
  altered stack, duplicate or realm-ambiguous winner, missing clock, closed
  loot window, disabled consent, revoked consent and simulated result.
- **No real-item test from CI.** In-game acceptance only after explicit
  owner approval and backup of current addon + current account's SavedVariables.
  Verify non-awarding UI first; if separately approved for a real award,
  use an **expendable** Master Loot item and verified candidate with another
  account/Playerbot, never Windseeker or irreplaceable gear.
- After such a controlled transfer, separately verify recipient bags and
  saved Gear Plan changes only after the confirmed receipt, and ensure a
  duplicate request is blocked.

## Remaining uncertainties

- The 3.3.5a addon cannot cryptographically prove per-corpse identity or
  independently inspect a Playerbot's actual bag after the request.
  [Maintenance coordination #2](https://github.com/CosmicCuddle/Naxxramas-Server-Coordination/issues/2)
  remains blocked. Keep all existing permanent NO RETRY protections.
- A full character/realm mismatch intentionally fails closed, even where
  an alias might refer to the same person.
- WoW Master Loot quality threshold or candidate-list behaviour may block
  low-quality items; never assume the request delivered merely because the
  API did not throw.
- Only the dedicated draft branch is changed. The owner-installed Build 60,
  current saved Gear Plans, stable release, server core, DB and client patches
  are unaffected.
