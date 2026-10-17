# NLL New Drop — Urgent Hotfix Test Build (17 October 2026)

**Status: Unmerged, unreleased TEST build**. This experimental hotfix is for the raid owner's explicit request to test it while raiding. It is NOT the official v0.1.0.29-rc.1 pre-release and NOT a verified live-loot fix until the owner checks it in their WoW 3.3.5a client.

**Version identity in WoW:** `0.1.0.29-rc.1-hf1`. Branch: `fix/nll-new-drop-live-loot-guard`, starting from the published `v0.1.0.29-rc.1` code, *not* the later PR #9 export-paging work. The hotfix has no migrations, new SavedVariables keys or SQL changes. The 604 imported Gear Plans live in your own saved data, which must not be overwritten.

## What changes

- A **New Drop** button immediately beside **Start Roll** in **Current Loot**; it becomes **Confirm Drop** after a successful first click. Confirmation is timed to 20 seconds and requires real raid loot still open, actual leader/officer authority, no live Debug Simulator and no pending server roll or unresolved award request.
- When successfully confirmed against a DIFFERENT physical corpse, only a new saved loot-opportunity identity is created; prior winner records are archived and retained. Preparing new tickets is then subject to all the normal Need/Greed and active-loot guards. **Never use this to reroll the same item copy.**
- A **CORPSE CLOSED** message replaces misleading “supported item(s)” whenever entries are saved but no longer seen in a real loot window. Prepare/Start Roll remain disabled and the UI refreshes instantly on `LOOT_CLOSED`. If New Drop had been armed, it is cancelled on loot close.
- When scanning a previously processed/ambiguous repeated item while the loot window is live, the addon prints a chat warning reminding the leader to consider **New Drop > Confirm Drop** while the corpse is still open.
- **No forced loot award, automatic reset, manual winner, or lost-corpse restoration.** Original pre-release remains available for immediate rollback.

## Install and rollback (important during an active raid)

1. **Finish any open roll/loot interaction first. Do not switch addon code mid-loot.** Close WoW fully to save account data. Make fresh paired backups of `Interface/AddOns/NaxxLootLottery`, `WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua`, and `NaxxLootLottery.lua.bak` where present. Preserve the existing Gear Plans and role settings. (The previous backup predates the current raid.)
2. Download the **TEST-ONLY** artifact from the successful GitHub Actions run for this branch. Inside the downloaded artifact ZIP, find `NLL-New-Drop-Hotfix-TEST-ONLY.zip`: this **inner** ZIP is the installable addon. Do NOT install the outer Actions artifact ZIP directly.
3. Extract the inner ZIP. Replace only `Interface/AddOns/NaxxLootLottery`, never the `WTF`/SavedVariables folders. Check there is precisely one `NaxxLootLottery/NaxxLootLottery.toc` path under AddOns.
4. Restart WoW and verify `/nll version` is `0.1.0.29-rc.1-hf1`, `/nll status` is READY, `/nll directaward` is OFF, and all 604 Gear Plans and role assignments remain visible.
5. Before risking an item, run an entirely non-awarding demonstration of the new buttons in a controlled context. New Drop should be disabled when the corpse loot window is closed, and the old winner must remain recorded. Only on a different, currently OPEN live corpse should New Drop become enabled. Click **New Drop**, verify it changes to **Confirm Drop**, click confirm promptly, then **Prepare Tickets**. Roll only if you intend to do so on that **new physical drop**. Keep Direct Master Loot OFF.
6. If WoW errors or previously stored data looks different, close WoW and restore **both** the backed-up original addon folder and its matching `NaxxLootLottery.lua` / `.bak` as a pair. Report the error, don't manually edit saved files.

**Known limitation:** Wrath client does not provide NLL a trustworthy distinct corpse GUID. The leader must explicitly verify a new corpse. Once the original corpse despawns, this hotfix cannot recover its loot, and manual/GM recovery requires separate controlled server-side accounting.

CI verifies Lua 5.1 syntax, unchanged full existing regression suite, read-only packaging and no live master loot by default. It does not prove in-client positioning, raid-specific UI lifetime or physical delivery.
