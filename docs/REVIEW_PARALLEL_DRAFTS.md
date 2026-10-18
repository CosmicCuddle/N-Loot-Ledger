# Comparison of NLL parallel drafts #18–#21

**Review date:** 18 October 2026.
**Purpose:** Compare earlier alternate development work, prevent its loss, and
forward-port only missing, safe behavior. No alternative branch was merged.
**Main reviewed base:** draft #26 at 51d7d2f1f86fcd16473af5bfa863a39b357f6934.
**Hardening draft:** #27 (this branch, version 0.1.0.29-rc.1-dev9).

## Comparison decisions

| Parallel PR | Valuable work | Current main path before #27 | Decision |
|---|---|---|---|
| [#18](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/18) | Guild operator audit, safe post-raid reconciliation UI, slot-cleared remains uncertain, keep-on-hold action | #22/#24 implement distinct NO-RETRY audit and modal; however #26's global gate did NOT include LOOT_SLOT_CLEARED | **Forward-port** cleared-slot global hold, record guild request operator. **Do not** treat master-looter attestation as recipient bag proof |
| [#19](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/19) | Live Master Looter / lottery checks before read-only auto proposals, all materials, recipe and gear slots | #23/#25 already scan all eligible slots but could show PROPOSE_TO_LEADER while the wrong actor is Master Looter or a lottery is running | **Forward-port** active-roll and exact designated Master Looter hold to #27. Keep dry-run ONLY |
| [#20](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/20) | Intended recipient's own inventory attestation, remote leader/recipient role separation | #22/#24 use NO-RETRY, which is deliberately not proof of actual receipt | **Defer** recipient-self guild attestation to a separately reviewed feature. Do not mix competing durable receipt schemas or silently convert NO-RETRY to OBTAINED |
| [#21](https://github.com/CosmicCuddle/N-Loot-Ledger/pull/21) | Hold orphaned winner receipt and outstanding human ACK even after Gear Plan changes | #26's GuildLootReview only checked current needs, local wishes and Inbox | **Forward-port** read-only persistent receipt and remote ACK holds to #27. Use direct SavedVariables reads for local OBTAINED, avoiding the mutating GetLocalWishlist helper |

## Specific #27 regression commitments

- [x] An orphaned WON_AWAITING_ITEM winner holds the same item ID.
- [x] Human OBTAINED without ACKNOWLEDGED holds; AWAITING_PLAYER,
      WAITING_FOR_PLAYER and SEND_FAILED are never assumed successful.
- [x] Unknown future receipt status fails closed.
- [x] A historical boolean wishlist marked local OBTAINED is not an
      active reservation, without the scanner inserting empty tables.
- [x] An unreviewed LOOT_SLOT_CLEARED guild or winner request blocks
      new manual transfers and unrelated proposals globally.
- [x] NO RETRY closes only the global investigation gate after separate
      intentional action; original item-ID / drop UID is permanently locked.
- [x] Active lottery and non-designated master looter block automatic
      *proposals*, not just physical API calls.
- [x] Capturing the operator for future guild audit does not claim
      delivery or authorization.
- [x] Keep all physical-award consents OFF at every login/reload.
- [x] Add new mocked Lua 5.1 coverage with zero GiveMasterLoot or RandomRoll.
- [ ] Pass dedicated and general exact-head GitHub Actions checks.
- [ ] Perform controlled WoW tests only after explicit owner approval.

## Risks not solved

- The WoW 3.3.5a client cannot prove two identical physical materials
  came from different corpses. Safe, legitimate later copies may be held.
- A leader-side OBTAINED status is a human attestation, not a server
  inventory record. The remote human recipient ACK is separate.
- Complete remote-client guild reservations are not globally available.
  A PROPOSE_TO_LEADER row is only a non-awarding suggestion.
- Physical recipient-self guild receipt reconciliation from #20 has
  intentionally NOT been integrated, since it conflicts with the
  narrower NO-RETRY semantics of #22/#24. It remains a future design.
- All #18–#21 remain separate drafts; they are not ancestors of this
  branch, and no automatic item transfer has been enabled.

## Next developer instructions

Before adding new modules, inspect the
[MASTER DEVELOPMENT CHECKLIST](MASTER_DEVELOPMENT_CHECKLIST.md),
refresh parent PR status, record exact CI SHA, and keep the #20
recipient-self attestation task listed for later review.
Only the owner may approve a controlled WoW test, merge or installation.
