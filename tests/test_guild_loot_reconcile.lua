-- Historical guild transfer receipt reconciliation, Lua 5.1 and no real items.
local count=0
local function ok(v,msg)assert(v,msg);count=count+1 end
local t=600
local actor="Leader"
UnitName=function()return actor end
GetTime=function()return t end
date=function()return "2026-10-17" end
local awarded=0
GiveMasterLoot=function()awarded=awarded+1;error("NEVER REAWARD")end
local good={itemID=17010,itemLink="|Hitem:17010|h[Fiery Core]|h",
    slotIndex=1,quantity=2,recipient="Leader",actor="Leader",
    status="LOOT_SLOT_CLEARED",when="earlier"}
local held={itemID=17011,itemLink="|Hitem:17011|h[Lava Core]|h",
    slotIndex=2,quantity=1,recipient="Leader",actor="Leader",
    status="AWARD_OUTCOME_UNKNOWN"}
local old={itemID=17012,itemLink="|Hitem:17012|h[Material]|h",
    slotIndex=3,quantity=1,recipient="Leader",
    status="AWARD_REQUESTED"}
local protected={itemID=16800,itemLink="|Hitem:16800|h[Gear]|h",
    slotIndex=4,quantity=1,recipient="Leader",actor="Other",
    status="AWARD_REQUESTED"}
local db={guildLootTransferAudit={good,held,old,protected},
    guildLootReconciliations={},gearNeeds={sentinel={status="NEEDED"}},
    localWishlists={},lotteryHistory={{winner="Historic"}},lootAwardHistory={}}
NaxxLootLottery={
    db=db,
    GuildLootTransfer={review=nil},
    DebugSimulator={IsActive=function()return false end},
    TicketLottery={active=nil},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GuildLootReconcile.lua"))()
local R=N.GuildLootReconcile
ok(#R:GetRows()==4 and R:GetRows()[1].status=="LOOT_SLOT_CLEARED",
    "historical audit exposes request including cleared-but-unverified slot")
ok(not R:Commit(),"no audit change without review and arm")
ok(not R:Review(3),"legacy row with no recorded actor cannot be forged")
ok(not R:Review(4),"nonoriginal operator cannot reconcile another person's item")
ok(R:Review(1),"original Master Looter can review own earlier item")
ok(#db.guildLootReconciliations==0 and good.status=="LOOT_SLOT_CLEARED",
    "opening historical audit cannot imply physical delivery")
ok(R:Arm("RECEIVED"),"operator independently verified inventory, first deliberate click")
ok(#db.guildLootReconciliations==0,"arming does not alter any saved audit")
t=t+16
local accepted,msg=R:Commit()
ok(not accepted and msg:find("expired"),"15-second reconciliation arm expires")
ok(R:Review(1) and R:Arm("UNVERIFIED"),"uncertain outcome can be held, not automatically retried")
ok(R:Commit(),"explicit second click records investigation hold")
ok(good.status=="INVESTIGATION_HOLD" and
    #db.guildLootReconciliations==1 and
    db.guildLootReconciliations[1].noRegrant==true,
    "hold recorded separately without permission to resend the loot")
ok(R:Review(1) and R:Arm("RECEIVED"),
    "original operator can later check old receipt and confirm")
local before=#db.guildLootReconciliations
good.itemID=99999
accepted,msg=R:Commit()
ok(not accepted and #db.guildLootReconciliations==before and
    good.status=="INVESTIGATION_HOLD",
    "audit tampering after arming stops confirmation")
good.itemID=17010
ok(R:Review(1) and R:Arm("RECEIVED"),"new explicit review after failed stale data")
ok(R:Commit(),"second human verified receipt confirmation works")
ok(good.status=="RECONCILED_RECEIVED" and
    good.reconciliationEvidence=="OPERATOR_CHECKED_RECIPIENT_INVENTORY",
    "only a verified human attestation resolves the request")
ok(#db.guildLootReconciliations==2 and
   db.guildLootReconciliations[2].initialStatus=="INVESTIGATION_HOLD",
   "append-only immutable evidence for both original and final decisions")
ok(not R:Review(1) and not R:Commit(),
    "terminal verified item cannot be reconciled twice")
ok(R:Review(2) and R:Arm("UNVERIFIED") and R:Commit(),
    "unknown API result can remain on HOLD without claiming receipt")
ok(held.status=="INVESTIGATION_HOLD",
    "remaining unknown request is still explicitly unresolved")
actor="Other"
ok(not R:Review(2),"different operator not allowed to change hold")
actor="Leader"
N.TicketLottery.active={status="COUNTDOWN"}
ok(not R:Review(2),"active lottery blocks historical reconciliation")
N.TicketLottery.active=nil
N.GuildLootTransfer.review={armedAt=t}
ok(not R:Review(2),"another armed transfer blocks reconciliation")
N.GuildLootTransfer.review=nil
ok(db.gearNeeds.sentinel.status=="NEEDED" and
    db.lotteryHistory[1].winner=="Historic" and
    #db.lootAwardHistory==0,"history and Playerbot Gear Plans are untouched")
ok(awarded==0,"reconciliation NEVER uses GiveMasterLoot")
-- Simulate reload: SavedVariables references and audit entries stay durable.
local previous=db.guildLootReconciliations
N.GuildLootReconcile=nil
assert(loadfile("NaxxLootLottery/Core/GuildLootReconcile.lua"))()
ok(N.db.guildLootReconciliations==previous and
    N.db.guildLootTransferAudit[1].status=="RECONCILED_RECEIVED",
    "reconciliation and hold persist after reload")
print("PASS: "..count.." guild audit reconciliation/no-regrant assertions")
