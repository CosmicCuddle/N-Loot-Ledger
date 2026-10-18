# Naxxramas Loot Ledger — MASTER DEVELOPMENT CHECKLIST

**Single entrypoint for all completed, current and future NLL work.**
Update this file **every time** we plan a task, open a branch/PR, complete
implementation, discover a blocker, finish tests, or receive WoW results.
Do not delete historical work just because another feature takes priority.

**Last audited:** 18 October 2026.
**Repository:** https://github.com/CosmicCuddle/N-Loot-Ledger
**Owner's installed build:** 0.1.0.29-rc.1-hf2 (**leave installed**).
**Draft development stack:** #10 -> #12 -> #13 -> #14 -> #15 -> #16
-> #17 -> #22 -> #23 -> #24 -> #25 -> #26 -> #27 -> #28 -> #29 -> #30 -> #31 -> #32 -> #33 -> #34 -> #35 -> #36 (copy risk audit).
**Shared baseline:** 604 imported Gear Plans across 38 Playerbots
(469 NEED, 135 GREED). These are **real owner data**, not development fixtures.
**Public release baseline:** v0.1.0.28 on main, separate from the above.
**Compatibility:** WoW 3.3.5a, Interface 30300, Lua 5.1, AzerothCore,
Individual Progression and Playerbots.

## How to use this checklist

A tick means the **specific box** is satisfied, not that the whole
feature has shipped. Keep these four gates separate:

- **Built:** reviewed source exists on the named branch/PR.
- **CI:** automated Lua/tests pass on the exact PR head.
- **WoW:** someone has checked the relevant new feature inside the game.
- **Release:** owner approved, merged and the intended build was installed.

**Routine workflow for EVERY new feature**
- [x] This master checklist exists and is linked from the README.
- [ ] Add the new feature below with ID, PR/branch, scope and dependencies
      *when it is proposed*, not after implementation is forgotten.
- [ ] Mark Built / CI / WoW / Release separately for each feature; note
      the exact test commit and date in its PR's review comments.
- [ ] Update related docs/ROADMAP.md, docs/DEVELOPMENT_TRACKER.md,
      acceptance tests and release notes **without erasing older entries**.
- [ ] Keep all unmerged stacked PRs aligned; explicitly record parallel
      alternatives. Do not quietly substitute one PR for another.
- [ ] Re-audit this checklist before each new development stage and
      before any future release decision.

These maintenance tasks are repeated each stage; their unchecked state
is deliberate, not evidence that the checklist is unfinished.

## A. Stable/public and historical foundation (main)

**NLL-001 — Identity, compatibility and data safety**
- [x] 3.3.5a client and Lua 5.1 module loading documented.
- [x] Preserve the addon folder NaxxLootLottery, saved key
      NaxxLootLotteryDB and /nll commands.
- [x] Saved roles, manually entered Gear Plans, wishlists, raids,
      winners and previous history are distinct from a preview.
- [ ] Final full multi-client SavedVariables compatibility acceptance.

**NLL-002 — Dark-only UI and recipe presentation**
- [x] PR #2 merged: Dark-only interface.
- [x] PR #3 merged: separate gear/items and recipe wishlist views.
- [x] PR #6 merged: v0.1.0.28 stable-core preparation.
- [ ] Carry final UI/screen-reader/dyslexia-friendly layout review
      into the next release acceptance; don't count older screenshots
      as proof of changed development UI.

**NLL-003 — Older research and milestones**
- [x] Retain [historical ROADMAP](ROADMAP.md) M0-M9 and
      [project handover](PROJECT-HANDOVER.md) without rewriting old claims.
- [x] Keep previous Molten Core source/priority/gear-plan research.
- [ ] Review prior M0-M9 unchecked boxes when planning their next
      dependent work; update this master list with the resulting decision.

## B. Older active draft lane (NOT merged into the new stack)

**NLL-008 — NEED before GREED; draft [#8](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/8)**
- [x] Built: NEED Tier 1-3 precede equal GREED stage.
- [x] Built: Gear Plans statuses NEEDED/GREED/OBTAINED/DISABLED.
- [x] Built: 40-bot simulation and six-row Gear Plans page to prevent overlap.
- [x] Owner previously checked selected UI/simulator behaviour.
- [ ] Fully integrated real-raid acceptance and merge approval.

**NLL-009 — Safe Playerbot Gear Plan import/export; draft [#9](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/9)**
- [x] Built: add-only export, preview and explicit import confirmation.
- [x] Built: refuse clashes instead of overwriting existing Gear Plans.
- [ ] Validate full installed-client import/export and 604-row scenario.
- [ ] Consider large multi-chunk exports and guarded per-row *edits*
      in a separate future PR; neither is available automatically.

These are **unmerged historical development tracks**, not evidence the
current draft addon has been installed.

## C. Main current development stack (all PRs draft/unmerged)

**NLL-010 — New Drop and HF2 GUI; draft [#10](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/10)**
- [x] Built: New Drop -> Confirm Drop with duplicate identity locks.
- [x] Owner visually confirmed installed HF2 no longer overlaps controls.
- [ ] Cross-corpse identity stress tests in game, not just Lua mocks.

**NLL-012 — Personal NEED/GREED and RAID messages; [#12](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/12)**
- [x] Built and prior CI: personal interest, RAID chat and optional
      five-second roll countdown.
- [ ] Integrated multiple-recipient RAID chat and countdown acceptance.

**NLL-013 — Manual Award Winner; [#13](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/13)**
- [x] Built and prior CI: guarded exact-slot WoW Master Loot candidate
      review, explicit arm/confirm and write audit.
- [ ] Real safe physical delivery / recipient inventory acceptance.

**NLL-014 — All-slot guild loot review; [#14](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/14)**
- [x] Built and prior CI: materials, reagents, recipes, gear and BoE
      in conservative read-only status categories.
- [ ] Confirm full live loot/corpse UI with unreserved materials.

**NLL-015 — Manual guild Master Loot; [#15](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/15)**
- [x] Built and prior CI: separate consent, exact slot and candidate,
      request audit before WoW call, double confirmation.
- [ ] Real controlled in-game test. Direct transfer consent remains OFF.

**NLL-016 — Winner -> recipient-confirmed OBTAINED; [#16](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/16)**
- [x] Built and prior CI: NEED/GREED is not converted on lottery win,
      API request or slot clear.
- [x] Built and prior CI: after independent recipient inventory review,
      corresponding leader-side bot/player plans may become OBTAINED.
- [ ] Confirm player and Playerbot physical receipts separately in-game.

**NLL-017 — Remote human receipt ACK; [#17](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/17)**
- [x] Built and prior CI: two-client offer/accept/ACK, isolated client data.
- [ ] Test with multiple real WoW client accounts and altered leadership.
- [ ] Verify missing ACK, same-item replays and reconnect behaviour.

**NLL-022 — Write-ahead attempted award/no-retry; [#22](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/22)**
- [x] Built; exact-head Lua 5.1 safety CI passed.
- [x] Durable attempted drop UID lock recorded before GiveMasterLoot.
- [x] Explicit NO-RETRY reconciliation is not equivalent to delivery.
- [ ] In-game review of unknown and loot-slot-cleared records.

**NLL-023 — Guild allocation dry-run; [#23](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/23)**
- [x] Built; exact-head Lua 5.1 safety CI passed.
- [x] Only locally unreserved known items are *proposed* to leader.
- [x] Preview has no automatic Master Loot transfer authority.
- [ ] Cross-client reservation-completeness proof remains unavailable.

**NLL-024 — Reconciliation modal; [#24](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/24)**
- [x] Built; exact-head Lua 5.1 safety CI passed.
- [x] Paged window, select/arm/confirm, expiry and cancel paths tested.
- [ ] In-game visual/font-size/layout and interaction acceptance.

**NLL-025 — Duplicate item ID cross-slot protection; [#25](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/25)**
- [x] Built; exact-head Lua 5.1 safety CI passed.
- [x] Same-ID material across changed slots is held, including
      previously CLOSED_NO_RETRY cases.
- [x] Integrated owner-controlled raid acceptance guide written:
      [INTEGRATED_RAID_TEST_CHECKLIST.md](INTEGRATED_RAID_TEST_CHECKLIST.md).
- [ ] Find reliable different-corpse identity for repeated guild mats:
      currently legitimate distinct copies can remain deliberately held.

**NLL-026 — Exact live character filter; [PR #26](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/26)**
- [x] Built: matching by trimmed full character name only, ignoring case.
- [x] Built: typing updates immediately; Enter, Apply and All work.
- [x] Built: only the display is filtered, no status or saved row edits.
- [x] Draft PR #26 opened on top of #25; the prior stack remains unchanged.
- [x] Automated Lua 5.1, 604-row preservation and checklist integrity CI
      passed (see exact-head checks and review notes on PR #26).
- [ ] Perform the in-game filter acceptance separately; automated success
      is NOT proof of the installed client's UI behaviour.
- [ ] Owner verifies filter in the WoW client at their chosen test stage.

**NLL-027 — Outstanding winner receipts / master-looter preview guards; [draft PR #27](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/27)**
- [x] Compare alternative #18–#21 and record source-level decisions in
      [REVIEW_PARALLEL_DRAFTS.md](REVIEW_PARALLEL_DRAFTS.md).
- [x] Built: orphaned winner and missing remote human ACK stay HELD,
      regardless of removed old Gear Plans.
- [x] Built: unreviewed loot-slot-cleared attempts stay globally uncertain;
      no slot clear implies delivery or grants a reissue.
- [x] Built: active roll, missing or wrong Master Looter blocks dry-run
      proposals; recorded guild operator is audit metadata only.
- [x] Built: local OBTAINED wishlist status is checked read-only.
- [x] Open stacked draft PR #27; automated head verification is tracked in PR checks.
- [x] Dedicated and full Lua 5.1 GitHub Actions checks passed at
      audited dev9 head (exact-head links retained in draft PR #27).
- [ ] Repeat the CI status check if any new code commits are added.
- [ ] Owner-approved in-client and remote-human receipt testing.

**NLL-028 — Intended-recipient own-bag statement; [PR #28](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/28)**
- [x] Implement a separate, strictly recipient-owned two-click
      own-bag attestation ledger and window. It never edits old guild
      audit status, NO RETRY closure, item locks or Gear Plans.
- [x] Validate exact character, old audit identity, bag count,
      elapsed time, tamper, duplicate and fake raid; no server item
      source proof is asserted.
- [x] Add WoW 3.3.5a Lua 5.1 mock UI/backend regressions and
      [acceptance plan](TESTING_GUILD_RECIPIENT_ATTESTATION_DRAFT.md).
- [x] Open stacked draft PR #28 after #27.
- [x] Dedicated and full Lua 5.1 GitHub Actions passed; exact current
      head evidence is maintained in PR #28 review comments.
- [ ] Revalidate exact-head checks if later code commits change this draft.
- [ ] Real client and paired human-client acceptance; still not a
      certified delivery receipt or automatic allocation authority.

**NLL-029 — Modal geometry and exact-recipient navigation; [draft PR #29](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/29)**
- [x] Built: increase last Guild Loot row / action-row gap from 2px
      to 6px without moving dangerous physical-award controls closer.
- [x] Built: My Bag Receipt entry point requires actual intended
      recipient eligibility, not just a selected guild audit row.
      Both UI click and recipient backend revalidate the actor.
- [x] Built: mocked WoW 3.3.5a geometry checks of the six Guild Loot
      rows, five reconciliation rows, five My Bags rows, footer
      containment and visible button spacing. No frame screenshots
      or font-size claims from these simulated coordinates.
- [x] Dedicated geometry/no-release CI and all historical Lua 5.1
      regressions passed; exact-head evidence linked on PR #29.
- [ ] Repeat exact-head checks after any further code or doc change.
- [ ] Verify at real WoW UI scale during owner-approved test window;
      record screenshots for long names/font overflow and tooltips.
- [ ] Mark merge/release only after separate owner approval.

**NLL-030 — WoW 3.3.5a corpse-source diagnostics; [draft PR #30](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/30)**
- [x] Research version boundaries: GetLootSourceInfo appeared in 5.0.4
      and is not part of 3.3.5a. Full evidence/limitations:
      [RESEARCH_WOTLK_LOOT_SOURCE_IDENTITY.md](RESEARCH_WOTLK_LOOT_SOURCE_IDENTITY.md).
- [x] Built: /nll lootsource read-only diagnostic counts prior
      item-ID attempt holds and repeated same-ID live loot slots.
- [x] Built: UnitGUID('target') is labelled only a target hint,
      NEVER a verified loot/corpse source or authorisation.
- [x] Built: all results are sourceVerified=false/canUnlock=false;
      no saved histories, Need/Greed plans, settings, item transfers or
      permanent NO RETRY attempt locks may change.
- [x] Add deterministic Lua 5.1 tests: changed target, slot reorder,
      simultaneous identical items, fake/closed context and no modern API.
- [x] Open stacked draft PR #30, preserving the older PR #29 branch.
- [x] Dedicated read-only source-diagnostic safety CI and full Lua 5.1
      regression suite passed (exact-head evidence on PR #30).
- [ ] Recheck exact-head CI if any further changes are added.
- [ ] Record owner-approved in-game text/screenshots and baseline
      SavedVariables comparison; not yet a usable per-corpse solution.

**NLL-031 — Full-roster batched Playerbot Gear Plan export; [draft PR #31](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/31)**
- [x] Built: deterministic, fully validated 250-row read-only export
      batches with the original NLL-GEARPLANS-1 format.
- [x] Built: 604 records produce 250/250/104, each below 48 KB,
      with Prev/Next and Batch X/Y controls.
- [x] Built: import cannot activate batch controls, exporting cannot
      enable Confirm ADD, and the importer/add-only workflow is unchanged.
- [x] Built: an invalid plan anywhere blocks all batches; no
      incomplete export is mistaken for a full SavedVariables backup.
- [x] Added Lua 5.1 604-row fixtures with 469 NEED / 135 GREED and
      import-compatible roundtrip tests preserving old table identity.
- [x] Added [future copy, backup and game-client test plan](TESTING_BATCHED_GEAR_EXPORT_DRAFT.md).
- [x] Open stacked draft PR #31, preserving PR #30.
- [x] Dedicated 604-plan export/no-release checks and complete Lua 5.1
      regression suite passed; exact-head links recorded on draft PR #31.
- [ ] Repeat the checks after any new development commits.
- [ ] Owner-approved WoW clipboard, paging, full SavedVariables
      comparison and readability checks (not yet tested or installed).

**NLL-032 — Guarded edits/removal of existing Playerbot Gear Plans; [draft PR #32](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/32)**
- [x] Replace instant status/dropdown and X deletion with a
      distinct 15-second preview/confirm or cancel step.
- [x] Allow NEED/GREED/DISABLED, but not manual OBTAINED. Existing
      OBTAINED and pending winner receipt plans cannot be altered.
- [x] Require stable exact source/item/character and full Gear Plans
      snapshot. Changed actor, filter, page, record or active lottery
      cancels review.
- [x] Preserve 604 saved rows, global roles, local wishlists and
      winner/receipt histories except the ONE explicitly confirmed row.
- [x] Add [controlled in-game acceptance guide](TESTING_GUARDED_GEARPLAN_REVIEWS_DRAFT.md)
      and 604-row Lua 5.1 mocked data/UI regression tests.
- [x] Open stacked draft PR #32 after #31.
- [x] Dedicated no-release review and complete Lua 5.1 regression CI
      passed on audited head; exact final-head evidence in PR #32.
- [ ] Recheck exact-head CI if future commits change this draft.
- [ ] Separate owner-approved actual WoW test, not part of development.

**NLL-033 — Individual Playerbot Gear Plan item-role change; [draft PR #33](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/33)**
- [x] Built: small Edit control in Role column, full six-role chooser,
      then separate 15-second confirm/cancel for exact bot/item.
- [x] Built: only saved BOT_GEAR_PLAN row.role can change. The
      character-wide db.roleAssignments and all other saved Gear Plans
      must NOT change (unlike GearNeeds:AddNeed).
- [x] Built: reject wrong or no-op role, OBTAINED, pending receipts,
      uncertain award, changed actor/record, fake raid and active loot.
- [x] Built: explicit picker cancellation when filtering/paging and
      [owner acceptance instructions](TESTING_PER_ITEM_ROLE_REVIEWS_DRAFT.md).
- [x] Added 604-row Lua 5.1 fixture covering all 6 roles and UI
      selection, cancel, expiration and final confirmation.
- [x] Open stacked draft PR #33 after #32.
- [x] Dedicated item-role/no-release checks and all historical Lua 5.1
      regressions passed (exact-head run links recorded in PR #33).
- [ ] Repeat exact-head CI for any additional future code/doc changes.
- [ ] Real 3.3.5a UI/font/clipboard acceptance and matched backups
      still require separate owner approval.

**NLL-034 — Read-only saved-vs-pasted import conflicts; [draft PR #34](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/34)**
- [x] Built: comparison of conflicting existing Playerbot plans to
      validated NLL-GEARPLANS-1 import candidates: exact saved value
      vs pasted value for Character, Type, Role, Raid, Item, Source
      and Interest/Status, only showing changed fields.
- [x] Built: explicit saved-key versus Latin-1 UTF-8 case alias
      distinction, with NO automatic duplicate identity or overwrite.
- [x] Built: read-only paged Compare Conflicts modal with Prev/Next,
      Close, import blocked on ANY conflict and no "Resolve/Apply" control.
- [x] Built: stale text, database change, fake raid, closed/active
      import context and bad index fail closed; add-only import untouched.
- [x] Built: 604+alias Lua 5.1 fixtures, unchanged account data tests,
      UI paging and disarm checks. Owner acceptance blueprint:
      [TESTING_GEAR_PLAN_CONFLICT_COMPARISON.md](TESTING_GEAR_PLAN_CONFLICT_COMPARISON.md).
- [x] Open stacked draft PR #34 after PR #33.
- [x] Dedicated read-only conflict/no-release safety checks and all
      historic Lua 5.1 regressions passed; final exact-head run links
      are recorded on PR #34.
- [ ] Rerun exact-head CI if future commits change this draft.
- [ ] Actual WoW clipboard/multiline/modal acceptance with backups.

**NLL-035 — Read-only profession-aware Molten Core recipe review; [draft PR #35](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/35)**
- [x] Add exact ten MC recipe ID to profession/skill 300 catalogue,
      preserving current recipe manualOnly policy and no active grant.
- [x] Add read-only lookup joining saved Gear Plan interests to each
      recipe. Interest is explicitly NOT known profession, level,
      specialization, already-learned recipe or loot receipt proof.
- [x] Add Recipes-tab-only Prof. Review entry with ten-recipe pages and
      separate four-names-per-page candidate list; no add, edit, award
      or allocation control.
- [x] All potential recipients stay UNVERIFIED and autoEligible=false,
      transferAuthorized=false. No new SavedVariables roster/schema.
- [x] Add 604-row Lua 5.1 tests plus UI tab and paging regressions;
      controlled owner [acceptance guide](TESTING_PROFESSION_RECIPE_REVIEW_DRAFT.md).
- [x] Open stacked draft PR #35 after PR #34.
- [x] Dedicated recipe/no-release and complete Lua 5.1 regression
      checks passed; exact-head links recorded in draft PR #35.
- [ ] Revalidate exact-head checks if any future commits change this draft.
- [ ] Owner-approved visual and profession evidence verification in
      actual AzerothCore/IP 3.3.5a; no approval for live distribution.

**NLL-036 — Duplicate physical-copy risk and future trusted-source evidence; draft PR #36**
- [x] Group currently observed WoW 3.3.5a loot item IDs into
      visible slot count vs displayed stack units. Neither proves a
      distinct corpse, physical item instance or safe repeat grant.
- [x] Expose /nll copyaudit, using existing /nll lootsource live
      context. Closed/fake/unverified windows display no live item rows.
- [x] Preserve winner and guild attempt item-ID holds regardless of
      moved slot, changed target, stack quantity, or manual new-corpse
      acknowledgement. NO original CLOSED_NO_RETRY is unlocked.
- [x] Keep explicit canAward=false, canRetry=false, canUnlock=false,
      autoTransferAuthorized=false; multi-copy saved plan support stays OFF.
- [x] Write [authenticated per-item source and recipient receipt
      evidence contract](BLUEPRINT_VERIFIED_LOOT_COPY_BRIDGE.md),
      with replay/authority/crash/race restrictions. No actual server
      bridge, migration or auto-transfer implemented/authorised.
- [x] Add Lua 5.1 regressions: stacked/repeated materials, 604
      unchanged Gear Plans, original locks, absent/fake source and
      hostile attempts to claim future source-API authority.
- [ ] Open stacked draft PR #36; verify dedicated/all Lua 5.1 CI.
- [ ] Owner-approved actual WoW source/quantity audit and saved-data
      comparison; no direct award or repeat grant test is approved.

**Estimated remaining development stages (not a promise):**
- [x] **C11:** Read-only import conflict comparison in draft #34;
  existing saved plans cannot be replaced via import.
- [x] **C12:** Ten-recipe profession/skill reference plus unverified
  recipient interest audit in draft #35; no automatic recipient eligibility.
  Verify actual profession/spec/skill in the client's game.
- [x] **C13:** Read-only /nll copyaudit and trustworthy per-item
  receipt/source evidence research in draft #36. No physical copy
  identity, repeat attempt or second-copy reservation permitted.
- **C14:** Combined draft integration, accessibility and release-readiness
  hardening with full test coverage.
- **Then:** a separate owner-approved, backup-first WoW 3.3.5a testing,
  multi-client receipt review, rollback rehearsal and release decision.
  Bugs or new findings may require additional stages or split existing
  stages; there is no fixed completion count.

## D. Parallel draft work that must NOT be forgotten

**IMPORTANT:** The PRs below are **not** ancestors of #25/#26.
They are alternative development branches. Their existence does not
mean their code is included in the current stack.

- [x] **NLL-018 — [PR #18](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/18)** Guild transfer operator identity,
      receipt reconciliation, audit and hold UI. Compare safe recipient
      attestation against #22–#24. Keep unique findings; do not blindly merge.
- [x] **NLL-019 — [PR #19](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/19)** More detailed guild auto-preview
      including Master Looter/active roll state and all-slot proposal rows.
      Compare to #23; preserve valuable conservative review gates.
- [x] **NLL-020 — [PR #20](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/20)** Recipient-self guild confirmation
      and conservative winner receipt tracking. Compare to current
      ledger and document human vs server-verified limitations.
- [x] **NLL-021 — [PR #21](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/21)** Pending winner-receipt and human
      ACK holds even after Gear Plan changes. **Safety-relevant**:
      review for an eventual separate hardening patch against #23/#25.
- [x] For #18–#21: compare source, review recorded exact heads and CI,
      identify existing/missing guards and decisions. See
      [comparison](REVIEW_PARALLEL_DRAFTS.md). **Leave alternatives draft.**
- [ ] Revisit later if upstream changes add any new unique safeguards.
- [ ] Resolve any future conflicting branch choices by PR review and
      explicit decisions; do not claim parallel PRs were merged.

## E. Future requested or identified work (not implemented)

**NLL-F01 — Multi-copy and duplicate-equipped items**
- [x] C13 blueprint spells out the required unique-equipped and realm
      item_template verification; no extra copy is yet authorised.
- [ ] Research item-specific unique/unique-equipped restrictions.
- [ ] Design per-copy reservations/receipts without resetting the
      boolean wishlist or using two tickets for one physical copy.
- [ ] Add dedicated Lua 5.1 and in-game acceptance.

**NLL-F02 — Gear Plan maintenance**
- [x] Draft #33 edits only one Gear Plan's item-specific role, never
      its character-wide role assignment.
- [x] Draft #32 adds guarded *existing bot row* status/deletion edits
      with before/after preview and explicit owner click.
- [x] Draft #34 adds read-only import conflict COMPARISON; existing
      rows are never overwritten and direct resolution is not enabled.
- [ ] Shared/global role editing or conflict replacement require a
      separate reviewed design; #33 and #34 do not provide those.
- [x] Draft #31 implements all-roster read-only batched export
      (>250 plans) without replacing stored 604 rows.
- [ ] Owner verifies Ctrl+C / multi-batch clipboard behaviour in WoW.
- [ ] Consider more convenient bulk inspection/search without
      overwriting human wishlist or bot sources.

**NLL-F03 — Safer repeated corpses / materials**
- [x] Draft #36 inventories repeated slots versus stack quantities
      without interpreting either as authoritative copy/source proof.
- [x] Future authenticated source/receipt bridge contract documented
      in BLUEPRINT_VERIFIED_LOOT_COPY_BRIDGE.md; never authorises a
      retry of an old attempted physical transaction.
- [x] Completed client API limitation study: no GetLootSourceInfo
      before 5.0.4; UnitGUID('target') cannot prove loot source.
      See [source research](RESEARCH_WOTLK_LOOT_SOURCE_IDENTITY.md).
- [ ] Investigate whether a separately reviewed, authenticated
      AzerothCore server-side per-source/item receipt bridge is viable.
      Research does NOT authorise modifying AzerothCore or deployment.
- [ ] Preserve no-retry locks and original winners across reloads.
- [ ] Never use a loot slot alone as proof of new physical item.
- [ ] No unapproved auto-transfer until identity and receipt proof
      are both independently validated.

**NLL-F04 — Profession and guild recipe allocation**
- [x] Draft #35 maps all ten MC recipe requirements to primary
      professions/skill 300 for read-only manual review.
- [x] Never infer bot profession/spec, learned recipe or receipt from
      NEED/GREED or raid role; saved candidates remain UNVERIFIED.
- [ ] Verify any specialization constraints and individual bot profession
      /skill evidence through actual AzerothCore + IP 3.3.5a client.
- [ ] Only a separately approved module may ingest verified profession
      evidence. No automatic award or physical material retry.

**NLL-F05 — User experience and accessibility**
- [x] Draft #29 adds deterministic frame bounds/gutter regression
      for Guild Loot, NO RETRY and My Bags modal button placement.
- [ ] Verify long character/item text, filter names and paging.
- [ ] Verify reconciliation modal and dry-run buttons do not overlap.
- [ ] Preserve optional mouse/keyboard controls for fatiguing hands.
- [ ] Log repeatable UI defects with screenshots and matching regressions.

**NLL-F07 — Recipient-self guild receipt attestation**
- [x] Draft #28 adds intended-recipient self-attestation with an
      append-only audit; NO RETRY remains a distinct separate event.
- [x] Require exact actor, item, link, quantity and audit-row
      consistency, 15-second confirmation and non-mutating bag count.
- [x] Record human evidence explicitly; NOT API/server delivery proof.
- [x] Never unlock an original physical item or send a repeat grant.
- [ ] Owner-approved real-client acceptance and future decision on
      whether/when recipient evidence can help close OTHER holds
      (not authorised by this draft).

**NLL-F06 — Eventual automatic guild allocation**
- [x] Read-only proposal mode developed in #23.
- [ ] Establish accurate, cross-client reservation completeness.
- [ ] Establish trustworthy corpse/item/candidate/receipt evidence.
- [ ] Build a separate, explicitly approved feature proposal
      before any unattended physical transfer. OFF by default.

## F. Integrated testing, backup and release gate

- [ ] Owner chooses a controlled in-game testing session.
- [ ] Back up Interface/AddOns/NaxxLootLottery/ as a complete directory.
- [ ] Back up WTF/Account/<account>/SavedVariables/NaxxLootLottery.lua
      AND NaxxLootLottery.lua.bak (if it exists), including other
      human clients in remote ACK tests.
- [ ] Check baseline of **604 bot records / 38 bots / 469 NEED / 135 GREED**
      and preserve roles, winners, lottery history and wishlists.
- [ ] Follow the [integrated raid testing checklist](INTEGRATED_RAID_TEST_CHECKLIST.md)
      on a controlled build, with representative Playerbots and players.
- [ ] Correct in-game issues in further **draft** patches, repeating CI.
- [ ] Explicit user approval of release content and migration plan.
- [ ] Merge only authorised PRs and build/verify the proposed release.
- [ ] Owner authorises installation. No existing saved data is reset.
- [ ] Only then mark the released version and actual client acceptance.

**Owner action today: NONE.** Continue using installed HF2 until a separate
test/install approval is requested. These checkboxes are planning records,
not authorisations for a live server change or actual item award.

## Next-development handover rule

Before starting another NLL feature, read this document first,
check all still-open draft PRs (including #18–#21 alternatives), add
the proposed work ID and expected branch, preserve all prior ticks,
then update the branch and exact CI status in this document. Finish
each progress report with **Next development priorities**, immediately
followed by **Anything you need to do**.
