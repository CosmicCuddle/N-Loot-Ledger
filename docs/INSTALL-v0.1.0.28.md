# Naxxramas Loot Ledger v0.1.0.28 — Install and rollback

**Release candidate only; not publicly released.** WoW 3.3.5a / `## Interface: 30300` / Lua 5.1.

## Upgrade safely

1. **Fully exit WoW** before copying files so SavedVariables have finished saving.
2. Back up the working `Interface/AddOns/NaxxLootLottery` directory and record its version.
3. Back up the **matching** `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and `NaxxLootLottery.lua.bak` (if present). Preserve character-specific NLL SavedVariables if present, too. Keep this backup pair together and do not overwrite it with later test data.
4. Use the **review candidate ZIP**, once CI has built and validated it. Do **not** use GitHub's generic `Source code (zip)` as the final installable asset. Never use a pre-release v0.1.0.27 ZIP for this test.
5. Unzip; the archive must contain a **single top-level `NaxxLootLottery`** directory. Replace the existing addon directory, not `WTF`.
6. Confirm the actual path `Interface/AddOns/NaxxLootLottery/NaxxLootLottery.toc` (not a nested folder), then launch WoW.
7. Check `/nll version` says **0.1.0.28** and `/nll status` says **READY**.
8. Check **Wishlists → My Wishlist** shows your existing Gear / Items and Recipes, **Priority Setup** retains your presets, and **Settings → Loot Awards** says **Direct Master Loot: OFF**. A UI layout or real-raid roster check is safe; do not click submission decisions or award actual items merely to test appearance.
9. Confirm the existing **real Award History** remains your own saved records, not fake simulator entries. Use a disposable client copy for risky migration/rollback exercises.

## Roll back if anything fails

1. Stop testing and **exit WoW**.
2. Preserve the failed addon version and its saved data as a separate diagnostic copy if useful; avoid uploading personal files.
3. Restore the backed-up **matching addon directory and SavedVariables** from step 2/3 together. Do not restore old addon code against newer SavedVariables blindly.
4. Launch WoW; check `/nll version`, `/nll status`, your original wishes, saved raid roles and priority setup.

## Important compatibility and safety notes

- Installed addon folder remains `NaxxLootLottery`.
- SavedVariables global remains `NaxxLootLotteryDB`; do not delete or manually rename it.
- Old recipe reservations are **not migrated** into new tables; the new tabs filter existing item IDs.
- Direct Master Loot is **experimental and OFF by default**, including after every `/reload`; do not enable it to perform release tests.
- A simulated winner, cleared loot slot or requested real award does not prove actual inventory receipt.

The new GitHub stable release must be **separately approved** after inspecting the exact release-candidate artifact.
