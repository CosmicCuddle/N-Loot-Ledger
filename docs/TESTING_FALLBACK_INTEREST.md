# Fallback / Off-Spec interest — development acceptance

**Branch:** `dev/nll-fallback-offspec-loot`. **Not released or installed.**

## Purpose
A Gear Plan can store `FALLBACK`: a player/Playerbot would like the item
only if nobody currently eligible has a `NEEDED` entry. This is not Tier 1–3
and must not bypass any guild role/class rule.

## Safety contract
- Normal Tier 1, 2 and 3 contenders always outrank FALLBACK.
- A fallback ticket pool may be prepared only if no eligible NEEDED
  contenders exist. Unresolved online NEEDED roles/classes block fallback.
- Manual/guild items, unconfigured/draft priorities, forbidden classes,
  excluded roles, absent/offline characters and explicit leader exclusions
  cannot enter fallback rolls.
- A character with both NEEDED and FALLBACK sources is considered NEEDED
  only once. Existing saved statuses and wishlist entries are not migrated.
- The existing duplicate-roll, identity, authority and pool revalidation
  gates remain mandatory. If a primary need appears after fallback tickets
  are prepared, starting or completing the fallback roll must be refused.
- Preview/Prepare do not award items. Direct Master Loot remains
  experimental, OFF by default and not certified for playerbot receipt.

## Review checklist (no real loot transfers)
1. Back up the existing `Interface/AddOns/NaxxLootLottery` directory and
   the matching `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua`
   plus `.lua.bak` before any future development-client installation.
2. On a **throwaway/test copy**, create one BOT_GEAR_PLAN entry as NEEDED
   and another as FALLBACK for an appropriate MC item. Confirm both are
   visible in Wishlists > Gear Plans, including after `/reload`.
3. Test the new **New entry interest** selector: NEEDED is the default;
   choosing Fallback / Off-Spec saves the row as FALLBACK from the outset.
   Check that the row status dropdown can switch NEEDED/FALLBACK/OBTAINED/
   DISABLED without losing the other plans.
4. In a safe preview-only raid context with a known configured priority
   rule and detected item, verify NEEDED contenders remain above FALLBACK.
   Recheck with no eligible primary contenders: preview identifies a
   Fallback / Off-Spec pool. **Do not roll or award real loot for this test.**
5. Check the leader Candidate Review can exclude and restore fallback
   interest and records the existing drop-scoped audit.
6. Verify `/nll botcheck <name>` includes fallback count, without implying
   that the bot's real inventory or loot eligibility was certified.
7. Confirm old wishlist reservations, award history, duplicate-roll locks,
   and the MC40 fake simulator still work; Direct Master Loot stays OFF.

## Offline verification
- `lua5.1 tests/test_fallback_interest.lua`
- `lua5.1 tests/test_loot_identity.lua`
- `lua5.1 tests/test_loot_history_and_bots.lua`
- All existing Lua 5.1 CI suites and syntax checks on the exact draft PR head.
- In-client validation remains outstanding until owner tests a backed-up
  development build; passing mocks is not real-loot certification.

## Rollback
Exit WoW, restore the paired addon-folder and SavedVariables backups.
Do not clear loot or winner history as a workaround, and do not merge or
publish the branch before owner approval.
