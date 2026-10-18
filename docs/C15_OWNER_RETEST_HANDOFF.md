# NLL dev20 — C15 OWNER TEST-ONLY UI RETEST

**Status:** Do NOT install until the exact-head GitHub Actions tests pass and an artifact is available. No published release/merge.

**Expected version:** `0.1.0.29-rc.1-dev20`, WoW 3.3.5a Interface 30300, **51 Lua modules**.

**What the owner reported on dev19:** Gear Plans screenshot **636 entries** (106 pages of six); screenshot confirms only the total, NOT the exact current character count or NEED/GREED counts. No return to an outdated 604 baseline.

## Download and verify

1. Check latest green [C15 NLL TEST-ONLY GitHub Actions](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/workflows/nll-c15-owner-test-zip.yml), for branch `dev/nll-live-ui-feedback`. Confirm its `BUILD_INFO.txt` commit matches the exact HEAD of draft PR #38.
2. Download the corresponding `NLL-TEST-ONLY-dev20-...` artifact. Extract this outer GitHub ZIP to find the **inner** addon ZIP `Naxxramas-Loot-Ledger-v0.1.0.29-rc.1-dev20.zip`, `SHA256SUMS.txt` and `BUILD_INFO.txt`.
3. Compare the SHA256 of the **inner** ZIP to SHA256SUMS.txt (Windows PowerShell: `Get-FileHash ".\Naxxramas-Loot-Ledger-v0.1.0.29-rc.1-dev20.zip" -Algorithm SHA256`). A mismatch = STOP. The outer GitHub artifact has a separate digest.

## Backups BEFORE manual test installation

1. Exit **every WoW game process**. Make a fresh dated copy of the *CURRENT* installed **dev19** `Interface/AddOns/NaxxLootLottery/` directory and its matching per-account `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua` and optional `.lua.bak`.
2. Preserve the older original **HF2** backup separately, do not overwrite it with dev19. When several clients/accounts are involved, back up matching account files separately. Copies must be outside the active addon/WTF directories.
3. Make an independent text/visual check of your existing **636** saved Gear Plans and old winner/recipient/NO RETRY history. Do not expect a synthetic old 604 count. **No automated migration or import** is proposed here.
4. On **ONE controlled client**, replace the complete active addon directory using only the **inner** validated ZIP's `NaxxLootLottery/` folder. Do NOT overwrite, paste, import or replace any file in `WTF`. No server-side changes.

## Safe, non-awarding checks only

- [ ] Type `/nll version`, expect `0.1.0.29-rc.1-dev20`; `/nll status`, expect `READY`. Stop on any Lua error.
- [ ] **Gear Plans:** confirm **636** saved entries still visible and six-row page controls; do NOT delete, add, import, edit role/status or award. Confirm newest current NEED/GREED counts from a trusted export only if desired.
- [ ] **My Wishlist:** confirm compact one-line summary, separate submission status above footer, **seven** rows and all reserved items reachable via Previous/Next (none deleted). Confirm a multi-boss long source doesn't overlap rows.
- [ ] **Inbox:** confirm **all six** saved submissions accessible through **Newer / Older** top pager (4 + 2), separate from the selected submission's lower Previous/Next (four submitted items per page). **Archive** one old rejected submission using two clicks; switch **Archived**, **Restore**, and back to **Active**. All six saved records/individual item decisions must remain intact. Archive never means Accept/Reject or delete.
- [ ] **Award History:** completed REAL lottery winners should appear even without a physical award attempt, labelled **Won roll - unverified**. A physical attempt is a separate state, and no automatic OBTAINED occurs. Simulated draws should not masquerade as actual wins.
- [ ] With loot CLOSED and no lottery active, press **New Run View** once and read caution, press again within 15s to start a fresh display. Then press **All History** to inspect every preserved entry. Never clear/erase physical audit or repeat a `CLOSED_NO_RETRY` item.
- [ ] Check real UI font and scale, no My Wishlist / footer / Inbox / Award History overlap; screenshot every defect for a new draft fix.
- [ ] Confirm Direct Master Loot / guild transfers / guild auto-preview all OFF, and do not enter a real raid or grant/distribute loot.
- [ ] Compare current SavedVariables with backups after exit; make no bulk changes. Stop on any unexpected discrepancy, preserve evidence.

## What to report

Please send screenshots of **My Wishlist footer**, **Inbox page 1/2 and 2/2**, **Award History winner entries**, and **New Run View / All History**. Share any Lua errors. If Gear Plans no longer show **636**, stop rather than reverting to 604 or attempting an import.

**A winner label is not inventory proof.** The historical original winner/physical request audits and permanent NO RETRY guards remain intact. All real loot tests and release decisions require separate explicit permission.
