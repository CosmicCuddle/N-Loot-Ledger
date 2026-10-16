# Molten Core 40-bot Need/Greed Import — Source Blueprint Handoff

**Preparation only.** This document records the owner's uploaded `README_NLL_40_Bot_Import_Blueprint.txt` specification. The original 640 individual rows / five ready-import text files have **not been provided to this review branch**. Never invent missing bot/item reservations or claim a completed import.

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

**Special:** The actual character is **TangØ** (Unicode U+00D8), regardless of the ASCII filename `TangO_UTF8_REVIEW_ONLY`. Never replace the name with `TangO`. The importer now includes a Lua 5.1 Latin-1 UTF-8 byte validator, exact-name roundtrip regression and case-variant collision protection (TangØ versus Tangø). **The owner's previously installed PR9 test build predates this fix**; a freshly built experimental package, paired backups, and separate test approval are needed before batch 05.

**Hunters:** Meshana, Elki, Mani, Hettraz all require NLL role ID `RANGED_PHYSICAL_DPS`. Do not silently change their roles in the import or alter any global Raid Role assignment.

**Important:** This importer stores *only* the eight-field format: `Character|PLAYERBOT|Role|MOLTEN_CORE|ItemID|BOT_GEAR_PLAN|NEEDED_or_GREED|1`, preceded by `NLL-GEARPLANS-1`. It does **not** import P1/P2 metadata, A/B planning hints, item names, group identifiers or raid tier settings. Keep the readable source/CSV for those.

## Actual input files are still required

Ask the owner to provide the five prepared `NLL_Import_*.txt` files, or the original `NLL_40_Bot_Quick_Entry.txt` used to generate them. After receipt, perform **offline** tests before any in-game import:

1. Verify exact counts per file, total 640 unique `(character, raid, item, source)` keys, 40 names, 501/139 status split, P1/P2 source planning metadata where present, and 123 item IDs against the actual `MoltenCore.lua` catalogue.
2. Validate strict version header, eight fields, no invalid status, no unexpected character names, proper Hunter roles, and TangØ UTF-8 exact preservation.
3. Confirm each batch remains under 250 entries and 48 KB; verify deterministic order and no duplicate records spanning batches.
4. Compare with a backed-up **export from the installed client** to discover any existing records that would conflict. Existing plans are never auto-overwritten or converted from DISABLED/OBTAINED to GREED.
5. With owner approval and backups, **preview the smallest appropriate first group**, inspect NEW / UNCHANGED / CONFLICT; only then use Confirm ADD. Do not import all five blindly.
6. Handle TangØ only after installing a NEW experimental build with the UTF-8 fix and checking preview. Never use an older PR9 build for batch 05.
7. Verify `/reload`, role assignments, saved plans, `/nll botcheck`, and fake Need/Greed stage results. Direct Master Loot stays OFF.

**Status:** Compatibility fix and automated tests implemented in PR #9. 640-row contents not yet received; no real import, role update, server changes, simulated award or loot transfer has been performed.
