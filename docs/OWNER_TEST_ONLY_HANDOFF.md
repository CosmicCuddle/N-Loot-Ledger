# NLL — Owner Test-Only Build and Phase 1 WoW Smoke Test

**Status:** Controlled test candidate, **NOT a release**.  
**Exact source:** draft [PR #37](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/37), branch `dev/nll-c14-integration-hardening`.  
**In-game expected version:** `0.1.0.29-rc.1-dev19`.  
**WoW client:** 3.3.5a (Interface 30300).

**Do not install until the uploaded GitHub Actions artifact is confirmed successful and you have made all required backups.** This is not a production-ready raid addon.

## A. Obtain the verified test ZIP

1. Open the latest green [NLL Owner Test ZIP (NO RELEASE) action](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/workflows/nll-owner-test-zip.yml).
2. Confirm **the workflow is green**, is on branch `dev/nll-c14-integration-hardening`, and its commit SHA matches the exact-head review noted in the related PR comment.
3. Under **Artifacts**, download the named **NLL-TEST-ONLY-dev19-...** artifact. GitHub may require signing in. The downloaded artifact is an outer ZIP containing the actual addon ZIP, the SHA256SUMS file and BUILD_INFO text.
4. Extract this outer artifact to a new folder **outside WoW**. Verify SHA-256 of the inner `Naxxramas-Loot-Ledger-v0.1.0.29-rc.1-dev19.zip` against `SHA256SUMS.txt` before using it.
5. **Do not install from a screenshot, old branch, unverified source ZIP, published v0.1.0.28 release, or unmatched run.** No checksum match means STOP.

Windows PowerShell checksum (point to the inner ZIP):

```powershell
Get-FileHash ".\Naxxramas-Loot-Ledger-v0.1.0.29-rc.1-dev19.zip" -Algorithm SHA256
```

## B. Mandatory matched backups — do this BEFORE launching WoW

1. Completely **exit World of Warcraft** on the test client. Close all its game processes.
2. Make a dated copy of the **entire** existing `World of Warcraft/Interface/AddOns/NaxxLootLottery/` folder, preserving its current installed HF2 version. Do not rename the original folder in place or mix old/new Lua files.
3. Make a dated copy of the account file `World of Warcraft/WTF/Account/<YOUR_ACCOUNT>/SavedVariables/NaxxLootLottery.lua`.
4. If `NaxxLootLottery.lua.bak` exists, copy it too. If you have multiple active WoW clients/accounts, preserve the matching addon + `.lua` / `.lua.bak` pair **for each one**.
5. Keep all copies outside the active `Interface/AddOns` and `WTF` folders. Do not delete anything from the originals.
6. **Check the current 604 Playerbot Gear Plans / 38 bots / 469 NEED / 135 GREED** before replacing the addon. Keep previous recipient/history/role data.

## C. Install only the test addon folder on ONE controlled client

1. Do not update AzerothCore, SQL, Individual Progression, Playerbots or any server-side module.
2. Open the inner verified addon ZIP and verify it contains exactly one root `NaxxLootLottery/` directory, holding `NaxxLootLottery.toc` plus 50 Lua modules.
3. After making the backups, replace the **entire** active `Interface/AddOns/NaxxLootLottery/` directory with the inner ZIP's `NaxxLootLottery/` folder. Do NOT layer the new files on top of old files.
4. Do not copy, delete, rewrite or import any SavedVariables file during installation. The already backed-up `WTF` file stays as-is.
5. Launch your WoW **3.3.5a** client normally, preferably outside an active raid.

## D. Phase 1 — NON-DESTRUCTIVE checks only

Follow these checks in order; stop on an error and keep evidence.

- [ ] Type `/nll version`. It should report **0.1.0.29-rc.1-dev19**.
- [ ] Type `/nll status`. It should report **READY**, not a failed module.
- [ ] Open `/nll` and verify all tabs load without Lua errors, missing controls or overlap. Check the smallest/normal UI scale you use.
- [ ] Confirm Gear Plans still show the expected **604 total records / 38 characters / 469 NEED / 135 GREED**. Do not delete or reclassify real reservations.
- [ ] Use exact-character filter to find one bot; do **not** use its X/Delete or confirm a status/role change in this first session.
- [ ] Open Import / Export and browse the **three EXPORT pages** (expected **250 / 250 / 104**). Copy/export is read-only. Save all three text chunks separately if wanted; they do not replace your full backup. **Do not paste/import** any records.
- [ ] Navigate to **My Wishlist → Recipes → Prof. Review**. All ten MC recipe entries should be visible using its recipe paging. Candidate professions should remain **UNVERIFIED**, and there must be **no auto award button**.
- [ ] With a purely **non-awarding** review window visible, switch tabs or close the addon with Escape. The temporary review should disappear and not reopen already confirmed.
- [ ] Type `/nll copyaudit` **with the loot window CLOSED**. It should show no live loot and warn that copy/source proof is unavailable. Do not open a real boss corpse just to test this.
- [ ] Confirm **Direct Master Loot OFF**, **Guild transfers OFF**, and **Guild Auto Preview OFF** wherever displayed. Do not enable those controls.
- [ ] Check that no item awards, raid lottery, countdown or guild loot transfers occurred from these inspections. Log any unexpected message or Lua error.

**For Phase 1, do not click Confirm ADD, Confirm This Change, Award, Grant, live Master Loot, Delete or any physical retry.** Also do not run a real Molten Core raid with the development build until we review Phase 1.

## E. Send back Phase 1 results

Please share: the output of `/nll version` and `/nll status`, screenshots of Gear Plans and the 250/250/104 pager, and any UI/Lua error or overlap. Confirm whether your saved baseline still shows 604/38/469/135.

If something fails, STOP. Do not attempt data repair, merge branches or delete the SavedVariables. Preserve screenshots/error text and both backups. We can address a defect in a new draft before proceeding.

## F. Phase 2 — held for separate review

- Staged NEED/GREED and role confirmation, import conflicts, multiple clients, Playerbots, actual loot windows and recipient acknowledgement.
- Any real physical loot award, item resend or reset is **not authorised** by a diagnostic or human receipt claim. `CLOSED_NO_RETRY` and identical-item holds remain permanent for the old transaction.
- Additional WoW acceptance may uncover new development stages before an owner-approved release decision.

## Build provenance

The download is generated only after the full historical Lua 5.1 suite, C14 integrated regression, package format/checksum and original physical-consent-off guards pass. The ZIP is uploaded as a **GitHub Actions artifact only** (never as a GitHub Release).

`BUILD_INFO.txt` records the exact Git commit. `SHA256SUMS.txt` records the inner ZIP digest. There is **no user/account SavedVariables inside this test ZIP**.

**Your HF2 original plus SavedVariables backup pair is the rollback point. No automatic installation or release will be performed.**
