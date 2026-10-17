# Molten Core 40-bot Need/Greed Import — Source Blueprint Handoff

**Historical source blueprint and completed owner import.** The initial 640-row blueprint was reduced to **604** by excluding benched Ruby and Arley. The owner subsequently provided/verified the source rows, imported five prepared batches into their backed-up WoW client, and confirmed persistence across `/reload`. This document preserves the **original reported 640-row blueprint counts** as historical context, NOT the 38-bot import totals. No private SavedVariables are included in the GitHub repository.

## Owner's reported target counts (to verify against actual files)

| Batch filename | Entries | Reported bytes |
| --- | ---: | ---: |
| `NLL_Import_01_Raid01.txt` | 166 | 10,668 |
| `NLL_Import_02_Raid02.txt` | 135 | 8,827 |
| `NLL_Import_03_Raid03.txt` | 164 | 11,628 |
| `NLL_Import_04_Raid04_9bots.txt` | 157 | 10,706 |
| `NLL_Import_05_TangO_UTF8_REVIEW_ONLY.txt` | 18 | 1,256 |
| **Expected total** | **640** | **43,085** |

The blueprint reports **40 distinct bots** (10 Raid01, 10 Raid02, 10 Raid03, 10 Raid04), with **501 NEEDED** and **139 GREED** rows. P1: NEEDED 377, GREED 96; P2: NEEDED 124, GREED 43. Reported 123 distinct MC item IDs. The 640 actual input rows, uniqueness and row accuracy must be verified from the input files; this README does not contain them.

**Special:** The actual character is **TangØ** (Unicode U+00D8), regardless of the ASCII filename `TangO_UTF8_REVIEW_ONLY`. Never replace the name with `TangO`. The importer now includes a Lua 5.1 Latin-1 UTF-8 byte validator, exact-name roundtrip regression and case-variant collision protection (TangØ versus Tangø). The owner later tested the fixed PR9 client build and imported TangØ's separate 18-record batch successfully; its exact name was preserved. These initial features were published experimentally as rc.1 (not a stable release).

**Hunters:** Meshana, Elki, Mani, Hettraz all require NLL role ID `RANGED_PHYSICAL_DPS`. Do not silently change their roles in the import or alter any global Raid Role assignment.

**Important:** This importer stores *only* the eight-field format: `Character|PLAYERBOT|Role|MOLTEN_CORE|ItemID|BOT_GEAR_PLAN|NEEDED_or_GREED|1`, preceded by `NLL-GEARPLANS-1`. It does **not** import P1/P2 metadata, A/B planning hints, item names, group identifiers or raid tier settings. Keep the readable source/CSV for those.

## Owner's current bench exclusions — Ruby and Arley

**Owner decision (16 October 2026): Ruby and Arley are benched and must be EXCLUDED from this particular Molten Core Gear Plans import.** Exclude every plan row for either character across all five input batches, using case-insensitive exact character-name matching (not substrings). Preserve the remaining characters, role labels, item IDs, and Need/Greed statuses exactly as supplied.

- This is **an import-file filter**, not a permanent ban, new Gear Need status, deletion, DISABLED conversion, character renaming, or change to the bots' raid roles.
- Existing Ruby/Arley reservations in the user's live or backed-up `NaxxLootLotteryDB` must remain untouched. Do not remove/overwrite any stored entries or historical records.
- Once the actual files arrive, first identify which batch(es) and how many source rows belong to Ruby and Arley. Then produce filtered, independently validated import text and report the actual remaining bot count, per-batch counts, total NEED/GREED, and item catalogue checks. Do not guess the new row totals by assuming equal distributions.
- Verify neither `Ruby` nor `Arley` appears anywhere in the final 8-field import rows before presenting any batch for in-game preview. Preserve the unmodified source data as a backup for later reactivation.

## Client paste compatibility (verified 16 October 2026)

In WoW 3.3.5a, owner provided direct evidence that a correct Gorak row pasted as `Gorak||PLAYERBOT||TANK||...||NEEDED||1` with **14 pipes**, whereas the `.txt` source has 7. PR #9 now safely accepts all-seven-single or all-seven-doubled separators, and rejects malformed/mixed copies. **Do not manually double pipes** in the 604-entry import batches; the original versioned text files are still the source of truth. The owner must install a newer PR #9 test-only artifact after paired backups, preview just Raid01 and provide the NEW/UNCHANGED/CONFLICT counts before Confirm ADD. Ruby and Arley remain excluded. No saved plans were changed by these failed previews.

## Completed owner acceptance and new export backup follow-up (16–17 October 2026)

- Raid01: **166** new plans, Raid02: **135**, Raid03: **164**, Raid04 without Ruby and Arley: **121**, and final TangØ: **18** — **604 added** for **38 Playerbots**, **469 NEEDED** and **135 GREED**, with no reported conflicts. Owner reports successful `/reload` persistence.
- The original detailed records were supplied during the owner review; they are not copied into this public repository, and the owner retains their own prepared import text and SavedVariables backups.
- The official [v0.1.0.29-rc.1 pre-release](https://github.com/CosmicCuddle/N-Loot-Ledger/releases/tag/v0.1.0.29-rc.1) was published for the 17 October raid; it does not include a complete 604-row export. Preserve the paired SavedVariables backups.
- New in **unmerged draft PR #9 only**: export all 604 rows as **three separate files (250, 250, 104)**, each with its own valid `NLL-GEARPLANS-1` header, and require unchanged saved-data snapshot across pages. In-game UI verification is still needed. No further owner install or live-award testing is authorised.

## Historical verification procedure (now superseded by the completed import)

Historical instructions from the earlier preparation stage, retained here for audit context:

1. Verify exact counts per file, total 640 unique `(character, raid, item, source)` keys, 40 names, 501/139 status split, P1/P2 source planning metadata where present, and 123 item IDs against the actual `MoltenCore.lua` catalogue.
2. Validate strict version header, eight fields, no invalid status, no unexpected character names, proper Hunter roles, and TangØ UTF-8 exact preservation.
3. Confirm each batch remains under 250 entries and 48 KB; verify deterministic order and no duplicate records spanning batches.
4. Compare with a backed-up **export from the installed client** to discover any existing records that would conflict. Existing plans are never auto-overwritten or converted from DISABLED/OBTAINED to GREED.
5. With owner approval and backups, **preview the smallest appropriate first group**, inspect NEW / UNCHANGED / CONFLICT; only then use Confirm ADD. Do not import all five blindly.
6. Handle TangØ only after installing a NEW experimental build with the UTF-8 fix and checking preview. Never use an older PR9 build for batch 05.
7. Verify `/reload`, role assignments, saved plans, `/nll botcheck`, and fake Need/Greed stage results. Direct Master Loot stays OFF.

**Status (updated):** The owner confirmed 604 actual reservations imported and preserved after `/reload`. Existing raid-role assignments/loot histories were not modified by the add-only importer. Actual Master Loot transfer has **not** been tested. New paged export remains unreleased review code on PR #9.
