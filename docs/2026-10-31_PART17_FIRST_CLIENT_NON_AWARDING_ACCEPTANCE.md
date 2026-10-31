# NLL Part 17 — First controlled WoW 3.3.5a client check (NO AWARDS)

**Owner:** CosmicCuddle  
**State:** DRAFT / test-only. **Not an installed update, approved merge or release.**  
**Code:** [PR #43](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/43), stacked on [#42](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/42), [#41](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/41) and [#40](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/40).  
**Verified source/test code checkpoint:** `35917594eb15283fba35a88274217a80cedaf61f`; [Lua 5.1 green](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/41209745595) and [full NO-RELEASE green](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/41209742036). This is mocked/source evidence only. Later documentation-only commits do not alter Build 141's packaged Lua, but always compare the installed artifact's own source commit, never just the TOC version.

## Verified Build 141 test-only artifact (31 October 2026)

- [Successful exact-source packaging run](https://github.com/CosmicCuddle/N-Loot-Ledger/actions/runs/41209742036) → **Artifacts** → `NLL-MC-leader-ticket-award-141` (GitHub artifact ID `13046300143`). It may expire after seven days.
- The downloaded outer archive contains exactly `NLL-MC-leader-ticket-award-test-ONLY.zip`, `SHA256SUMS.txt` and `BUILD_INFO.txt`. **Do not install this outer archive as an addon.**
- Exact SHA-256 for the **inner addon ZIP** `NLL-MC-leader-ticket-award-test-ONLY.zip`:
  `896571baca5360a6f0c7d19e4485e5a22066b32ef82876bc0c5f0be8300e81f2`
- Independently inspected the actual downloaded GitHub Actions artifact on 31 October 2026: both ZIP CRC tests passed, inner ZIP has **51 Lua modules + one TOC**, exactly matches every TOC-listed file, has exactly one root folder `NaxxLootLottery/`, and its SHA-256 matches `SHA256SUMS.txt`. The inner TOC confirms `## Interface: 30300` and `## SavedVariables: NaxxLootLotteryDB`.
- On Windows, after extracting the **outer** archive outside the WoW directory, you can verify the **inner** ZIP using PowerShell (with PowerShell opened in that extraction directory):

  ```powershell
  Get-FileHash ".\\NLL-MC-leader-ticket-award-test-ONLY.zip" -Algorithm SHA256
  ```

  It must match the exact digest above. Missing files, an unexpected hash, a different `BUILD_INFO.txt` commit or an unexpected directory layout means **STOP; do not install**.
- **Raid-day decision:** stay on the previously installed Build 60 for any imminent raid. Build 141 is cleared for the *first owner-controlled, backed-up, non-awarding client smoke test*, preferably after the raid or on a separate test client. This verification does **not** authorise a real roll, physical item award, merger or production deployment.

## Before touching the installed addon

**No immediate owner action is requested.** The following is a *future controlled testing plan*, not permission to install, loot, alter SavedVariables or merge. The last reported installed build is **Build 60**; the exact currently installed build and current saved-data counts must be confirmed, not assumed.

1. **Exit WoW.** Copy the entire current `Interface/AddOns/NaxxLootLottery/` folder to a clearly named safe backup. Preserve `NaxxLootLottery.toc` and every original subfolder. Do **not** rename the live folder to `N-Loot-Ledger`.
2. Back up the *matching current account's* `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua`, plus `NaxxLootLottery.lua.bak` if present. Preserve any applicable character copies. Keep these together with the addon backup; never share them publicly.
3. Record the current live in-game Gear Plans count and winner/award history before testing. **638** was previously reported by the owner; **636** was an older screenshot and **604** an earlier fixture. None is an automatic target for migration, reset or deletion.
4. **Only when the owner chooses this test:** obtain the installable ZIP from a **successful exact-head NO-RELEASE GitHub Actions artifact** on PR #43 (not the repository Source ZIP, a previous branch, or the published prerelease). Match the artifact's `BUILD_INFO.txt` commit to the tested source and verify the inner ZIP against `SHA256SUMS.txt`. The test artifact is normally retained for **7 days**.
5. Restore both the matching addon **and** SavedVariables backups if reverting a test. Replacing only one half can leave a different saved-data state.

## Phase 1 — First login, read-only; no live item handling

1. On the controlled client only, use `/nll version` and `/nll status`. Note any Lua errors. The candidate's TOC version string may still display `0.1.0.29-rc.1-dev20`; **do not use the version alone to identify the exact ZIP**.
2. Open Settings → Loot Awards. Confirm that **Direct Master Loot**, **Enable 1-Click Award** and any separate Guild transfer consent are **OFF** at login and after `/reload`. Do not turn these on during Phase 1.
3. Inspect current Gear Plans and saved NEED/GREED/OBTAINED rows, the owner-recorded count, historical winners and Award History. Do not import, remove, edit status, use New Run to obscure history, or treat the synthetic regression-test count as the live total.
4. Open the ordinary UI pages and check their readability at the owner's enlarged font/UI scale. Where a Guild Loot panel is available, a held guild material must keep its **real HOLD reason** and not show the retired **Guild Master** recipient. Eligible material prompts refer to leader-only tickets.
5. Check for overlapping, clipped or hidden controls; record the exact addon build, page, screenshot and error text if something looks wrong. **Stop** rather than resetting stored data to fix a visual issue.

**Phase 1 does NOT press `Prepare Tickets`, `Start Roll`, `AWARD ITEM` or `/nll newloot` on real loot.** This means it cannot prove the real guild-allocation popup, live material eligibility, or physical receipt. That is intentional.

## Phase 2 — Separate owner-approved *no-physical-award* guild workflow

**This is not read-only.** Even without `GiveMasterLoot`, selecting a genuine Molten Core material and pressing **Prepare Tickets → Start Roll** creates a completed, **persistent winner/receipt record** and consumes the same-drop lottery opportunity. A real raid can also see NLL raid announcements if enabled. Do not casually use a rare drop just to get a popup screenshot.

With the owner's separate go-ahead, use a controlled, expendable material opportunity and inspect: exactly one **actual raid leader** ticket, deterministic **GUILD ALLOCATION**, no server random-roll result, title **GUILD ALLOCATION**, separate **Raid leader only - Guild ticket #1** label, correct winner name, and **AWARD ITEM disabled** while the two physical award consents are OFF. Verify that the loot remains in WoW and no Gear Plan is falsely marked OBTAINED. Changing raid leader or closing the loot window must not grant physical items.

If a guild material is **below Blizzard's Master Loot quality threshold**, the client must HOLD it rather than change raid loot settings. Also stop if `GetInstanceInfo` or an exact recipient cannot be verified. The exact old-client instance API and custom Playerbot roster still need in-game evidence.

## Phase 3 — Separate owner approval needed for an actual physical award

An experimental `AWARD ITEM` click calls `GiveMasterLoot` and is **irreversible/NO RETRY** once attempted, including on unknown outcomes. Require a deliberately expendable item, an actual open matching Blizzard Master Loot slot, designated Master Looter, exact unique candidate and fresh confirmation by CosmicCuddle. Both physical consent switches must be deliberately enabled for that session. Never test with a Windseeker binding or irreplaceable item.

Even if the WoW API returns without an error, the recipient's bag must be **independently checked**. A cleared loot slot is not ownership evidence. Only the separate human **I Checked Inventory → MARK OBTAINED** process may update a matching Gear Plan; a remote player's wishlist requires actual communication/synchronisation. **Never repeat a physical award request to diagnose a missing result.**

For a separately approved **two-human-client receipt test**, both characters must be in the same real raid and their **full character names must exactly match** the live raid roster, saved award recipient and addon whisper sender. After a true human inventory check, the leader may offer the `R1` receipt through NLL. The receiving player must check their own bag, press **I Have the Item**, then **MARK OBTAINED** within 15 seconds. Validate that no automatic OBTAINED occurs on message receipt, another-realm lookalike sender/recipient is rejected, switching the displayed offer disarms, and any missing/backwards clock cancels confirmation. Confirm the separate `R1|ACK` on leader side. If a real 3.3.5a roster inconsistently includes realm suffixes, **STOP/HOLD and record evidence** instead of modifying saved names or bypassing the exact match.

## Current limits / stop conditions

- The Wrath 3.3.5a addon has no verified authenticated per-physical-corpse/source identifier. A prior attempt for a guild material ID can permanently HOLD a later genuine copy. [Existing Maintenance research and undecided source bridge](https://github.com/CosmicCuddle/Naxxramas-Server-Coordination/issues/2) remains blocked; preserve NO RETRY.
- Stop on any unresolved request, unexpected previously owned item, ambiguous slot/source, duplicate candidates, changed raid leader, non-Molten Core location, unexpected saved count, Lua error or new UI overlap.
- Automated Lua and packaging CI are **source and mock evidence only**. They do not verify the actual client, Playerbot inventory delivery, server module state or owner backups.
- **No publish, merge, live transfer, configuration change or SavedVariables migration is approved by this document.**

## Acceptance notes to capture when testing is separately authorised

Record: actual installed package `BUILD_INFO.txt` SHA and ZIP hash; UI scale/font; original/current Gear Plans count; `/nll status`; both physical consents at login and `/reload`; selected item's ID and live WoW source; actual raid leader vs Master Looter; popup title/ticket/winner; any Lua errors; receipt evidence and whether an item was truly transferred. Keep personal save files private.
