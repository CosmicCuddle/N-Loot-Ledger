# Naxxramas Loot Ledger v0.1.0.25 — Pre-release

**Development preview for World of Warcraft 3.3.5a / AzerothCore.** This is a pre-release, not a production-certified addon. Back up your existing addon folder and `WTF/Account/.../SavedVariables/NaxxLootLottery.lua` before updating.

## What's included
- Raid Roles, wishlists, gear planning and per-item loot priority tools.
- Post-drop ticket lotteries, visual winner announcements and separate results for multiple drops.
- A 40-character Molten Core debug raid with 13 simulated drops to test without real items.
- Candidate review controls, audit history and separate award reporting.
- Optional real Master Loot requests with two confirmation steps. **Direct awards are OFF by default and reset to OFF on login/reload.** A loot slot clearing does not independently verify the recipient received an item.

## Install (3.3.5a)
1. Download **Naxxramas-Loot-Ledger-v0.1.0.25.zip** from the Assets section below (not GitHub's auto-generated *Source code* archive).
2. Extract the ZIP. Copy the **NaxxLootLottery** folder into `World of Warcraft/Interface/AddOns/`. It must contain `NaxxLootLottery.toc` immediately inside the folder.
3. Start or restart WoW, enable the addon on the character-select AddOns screen, then type `/nll` or `/nll status`.
4. To try the isolated 40-player test: `/nll debug` (if not enabled), then `/nll sim mc40`; stop with `/nll sim stop`.

**Do not rename the installed NaxxLootLottery folder or its SavedVariables names.** They remain unchanged to preserve compatibility with earlier builds.

## Feedback and limitations
- Please test on a non-production character/realm first, especially Master Loot functionality.
- The simulated raid does **not** summon actual AzerothCore Playerbots or give real items.
- Report problems through the repository Issues tab, including the addon version and reproducible steps; omit personal SavedVariables or private character data.
