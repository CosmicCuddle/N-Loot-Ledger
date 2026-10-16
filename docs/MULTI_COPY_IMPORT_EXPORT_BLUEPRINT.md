# Blueprint — multiple-copy reservations and controlled Gear Plan import/export

**Planning only. Not implemented, merged, released, installed or authorised for live-data migration.** This document is intentionally separate from draft PR #8's Need Before Greed core.

## A. Equippable duplicate items — problem
The existing local wishlist maps `itemID => true`, and one saved Gear Need key represents a character/item/source. Neither directly represents **two desired copies**. Giving the same character two lottery tickets for one physical item copy would be incorrect.

Item 19147, **Ring of Spell Power**, is a useful initial test case. Its WotLK and Classic-era versions may differ in uniqueness wording, and this realm has Individual Progression/other customisations. The server's actual `item_template` and client tooltip must be verified before permitting two equipped copies. Two finger slots **do not** automatically mean every identical ring is equippable twice.

## B. Proposed per-copy reservation model

- **Copy 1**: keep all original `gearNeeds` keys and personal wishlist booleans unchanged.
- **Copy 2**: store a separately identified copy, only for verified eligible items. A new second-copy record must not overwrite or rename copy 1.
- Allow one item to have copy 1 **NEEDED** and copy 2 **GREED** if the leader chooses; each copy can become **OBTAINED** individually.
- For humans, retain `localWishlists[character][raid][itemID]=true` as the existing "at least one wanted" reference. A separate optional quantity/per-copy structure should express additional copies, defaulting to 1 for all old saves. Do **not** convert unrelated recipes, materials or manual-only items to multi-copy Gear Needs.
- For bots, a copy-specific status is preferable to blindly changing a global item status. Preserve original `status`, `source`, `raidKey`, `character` and old history.
- The matcher returns **at most one candidate per character for any one physical drop copy**, regardless of copies desired or how many sources requested it. After a **verified or manually confirmed** copy award, only the corresponding copy's reservation becomes obtained; an announced lottery winner or a Master Loot request is not proof of delivery.
- Detect a legitimate second physical loot copy via existing drop-identity rules; never weaken identical-drop uncertainty or archived-winner locks to satisfy a second reservation.
- Ensure one copy's `NEEDED` outranks another copy's `GREED` for the same item and character only when the prior Need copy is actually acquired. Never fabricate a reward receipt.
- Keep duplicate limits `1` by default; consider explicit item allowances for `2` only after a read-only verification of slot and uniqueness on the actual target realm.

## C. UI proposal

In My Wishlist, retain the existing Gear / Items versus Recipes views. For eligible items, show `Requested: 1 / 2` (not two visually identical unlabelled rows), and identify the held/acquired count separately. Uniqueness-restricted items should not offer a second-copy control.

In Gear Plans, show an unobtrusive copy indicator `1/2` or `2/2`, with independently editable **NEEDED/GREED/OBTAINED/DISABLED** interest. Paging must remain within the six-row safe layout and avoid adding another wide column that overlaps status/remove controls. Confirm exact layout by WoW screenshots before release.

## D. Controlled offline import/export — proposed format

Use a versioned, human-readable, printable line format (example only):

```text
NLL-GEARPLANS-1
character|characterType|role|raidKey|itemID|source|interest|copyIndex
Druzz|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|19147|BOT_GEAR_PLAN|GREED|1
Druzz|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|19147|BOT_GEAR_PLAN|GREED|2
```

The planned importer must:
1. Accept pasted text in the WoW 3.3.5a addon only. Lua 5.1 does not provide unrestricted local filesystem I/O through the addon sandbox; no external service or modern Retail API may be assumed.
2. Parse and validate the entire batch first (header/version, fields, item IDs, known class/type/role, source, Need/Greed/status, legal copies, duplicate rows and size caps).
3. Present a **read-only dry-run diff**: unchanged, additions, conflicts, edits and rejections, including count summaries.
4. Require an explicit owner confirmation to apply only approved changes. Never delete existing plans by default; reject conflicts rather than silently overwriting personal/other-source records.
5. Keep `NaxxLootLotteryDB` and original SavedVariables intact; provide backup/rollback instructions and staged/atomic apply semantics.
6. Preserve per-copy identity, winners, award history, priorities and role assignments. No real loot action is triggered by an import.
7. Export only leader-managed plan data by explicit action, with bounded chunks for WoW EditBox copy limits. No passwords or private account data.

## E. Acceptance tests before implementation

- Existing one-copy plans, human reservations, recipe-only rows, histories and roles survive an upgrade and a rollback using paired backups.
- Item 19147 requires server-item uniqueness verification; unsupported unique rings remain capped at one.
- One-copy and two-copy plan status transitions survive `/reload`, and `OBTAINED` only reflects explicit, verified/manual-reported acquisition.
- No duplicated candidate ticket appears on a single drop; two genuine independent drops can fulfil distinct copies safely.
- A Need copy always outranks a Greed copy and no unresolved Need is bypassed.
- Malformed/unknown/oversize import is rejected before **any** mutation. Identical imports are idempotent; duplicate rows cannot create duplicate items.
- Import preview counts and protected record identities are checked. Roundtrip export → import on a throwaway DB is deterministic.
- Original 40-bot MC, mixed Need/Greed MC40, all Lua 5.1 regressions and owner's exact large-font Gear Plans UI remain valid.

**Approval gate:** Implement this as independent reviewable follow-up work, not as an unreviewed expansion of PR #8; ask for agreement on exact per-copy representation and the eligible-item list before enabling real saved-data changes.
