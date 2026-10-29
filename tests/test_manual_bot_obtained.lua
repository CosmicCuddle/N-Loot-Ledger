-- Focused Lua 5.1 test of manually attested, already-owned bot gear.
-- Fake account only. NEVER call real WoW inventory or award APIs.
local clock=100
local actor="Leader"
GetTime=function() return clock end
time=function() return 1793290000 end
UnitName=function(unit) if unit=="player" then return actor end end
local granted=0
GiveMasterLoot=function() granted=granted+1; error("A manual note cannot grant items") end
local key="BotOne|MOLTEN_CORE|16800|BOT_GEAR_PLAN"
local otherKey="BotTwo|MOLTEN_CORE|16801|BOT_GEAR_PLAN"
local one={
    key=key,character="BotOne",itemID=16800,
    raidKey="MOLTEN_CORE",source="BOT_GEAR_PLAN",
    characterType="PLAYERBOT",status="NEEDED",role="MAIN_TANK",
}
local two={
    key=otherKey,character="BotTwo",itemID=16801,
    raidKey="MOLTEN_CORE",source="BOT_GEAR_PLAN",
    characterType="PLAYERBOT",status="GREED",role="HEALER",
}
local pending={dropUID="old-drop",character="BotOne",itemID=16800,
    status="WON_AWAITING_ITEM"}
local award={dropUID="old-drop",winner="BotOne",itemID=16800,
    status="AWARD_OUTCOME_UNKNOWN",reconciliationStatus="CLOSED_NO_RETRY"}
local locks={["old-drop"]=true}
NaxxLootLottery={
    db={gearNeeds={[key]=one,[otherKey]=two},
        lootReceiptTracker={["old-drop"]=pending},
        lootAwardHistory={award},awardAttemptLocks=locks},
    DebugSimulator={IsActive=function() return false end},
    GearPlanTransfer={IsBlocked=function() return false end},
    GearNeeds={MakeKey=function(_,character,raidKey,itemID,source)
        return character.."|"..raidKey.."|"..itemID.."|"..source
    end},
    roleLabels={MAIN_TANK="Main Tank",HEALER="Healer"}
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GearPlanReview.lua"))()
local R=N.GearPlanReview
assert(not R:CanEdit(key,"STATUS","OBTAINED"),
    "plain status dropdown must never silently certify receipt")
assert(not R:CanEdit(key,"STATUS","GREED"),
    "pending receipt still blocks ordinary interest edit")
assert(not R:CanEdit(key,"ROLE","HEALER"),
    "pending receipt still blocks role edits")
assert(not R:CanEdit(key,"REMOVE"),
    "pending receipt still blocks deletions")
assert(not R:Arm(key,"ATTEST_OBTAINED","OBTAINED"),
    "attestation action cannot be confused with status change")
local ok,message=R:Arm(key,"ATTEST_OBTAINED")
assert(ok and message:find("human attestation"),
    "exact-item confirmation must identify human evidence")
assert(one.status=="NEEDED" and not N.db.manualObtainedEvidence,
    "first click cannot change anything")
assert(R:Confirm(), "leader must be able to log already owned item")
assert(one.status=="OBTAINED" and two.status=="GREED",
    "only selected bot item changes")
assert(one.manualObtainedEvidence=="LEADER_ATTESTED_BOT_HAS_ITEM")
assert(#N.db.manualObtainedEvidence==1)
local recorded=N.db.manualObtainedEvidence[1]
assert(recorded.character=="BotOne" and recorded.itemID==16800 and
    recorded.oldStatus=="NEEDED" and recorded.newStatus=="OBTAINED" and
    recorded.receiptVerified==false and recorded.by=="Leader")
assert(pending.status=="WON_AWAITING_ITEM" and
    award.status=="AWARD_OUTCOME_UNKNOWN" and
    award.reconciliationStatus=="CLOSED_NO_RETRY" and
    N.db.awardAttemptLocks==locks and grants==0,
    "manual entry must NEVER fabricate server receipt or unlock old item")
assert(not R:Arm(key,"ATTEST_OBTAINED"),
    "cannot attest same bot/item twice")
-- Confirm guard verifies actor, snapshot and expiry before any write.
assert(R:Arm(otherKey,"ATTEST_OBTAINED"))
actor="Different"
assert(not R:Confirm() and two.status=="GREED")
actor="Leader"
assert(R:Arm(otherKey,"ATTEST_OBTAINED"))
clock=116
assert(not R:Confirm() and two.status=="GREED")
clock=117
assert(R:Arm(otherKey,"ATTEST_OBTAINED"))
two.role="MAIN_TANK"
assert(not R:Confirm() and two.status=="GREED")
N.GearPlanTransfer.IsBlocked=function()return true,"Real loot open" end
assert(not R:Arm(otherKey,"ATTEST_OBTAINED"),
    "in-progress loot still blocks plan corrections")
assert(#N.db.manualObtainedEvidence==1 and grants==0)
print("PASS: audited exact bot-item manual ownership; old receipts/locks preserved")
