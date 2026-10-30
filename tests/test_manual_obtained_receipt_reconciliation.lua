-- Lua 5.1 regression: separately attested bot item can later receive an
-- exact human-verified receipt without fabricating evidence on first click.
-- No real loot, bot inventory, or remote client is modified.
local clock=100
local grants=0
GetTime=function()return clock end
time=function()return 1793300000 end
date=function()return "2026-10-30 10:00:00" end
UnitName=function(unit)return unit=="player" and "Leader" or nil end
GiveMasterLoot=function()grants=grants+1;error("no items may be awarded")end
RandomRoll=function()error("no random rolls")end
local key="BotOne|MOLTEN_CORE|16800|BOT_GEAR_PLAN"
local other="BotTwo|MOLTEN_CORE|16800|BOT_GEAR_PLAN"
local plan={key=key,character="BotOne",itemID=16800,
    raidKey="MOLTEN_CORE",source="BOT_GEAR_PLAN",
    characterType="PLAYERBOT",status="NEEDED",role="MAIN_TANK"}
local unrelated={key=other,character="BotTwo",itemID=16800,
    raidKey="MOLTEN_CORE",source="BOT_GEAR_PLAN",
    characterType="PLAYERBOT",status="GREED",role="MAIN_TANK"}
local lock={status="LOCKED_NO_RETRY"}
local db={
    gearNeeds={[key]=plan,[other]=unrelated},
    lootReceiptTracker={},lootAwardHistory={},awardAttemptLocks={old=lock},
}
NaxxLootLottery={
    db=db,
    DebugSimulator={IsActive=function()return false end},
    GearPlanTransfer={IsBlocked=function()return false end},
    GearNeeds={MakeKey=function(_,character,raid,id,source)
        return character.."|"..raid.."|"..id.."|"..source
    end},
    roleLabels={MAIN_TANK="Main Tank"},
    TicketLottery={AuthorityAllowed=function()return true end},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GearPlanReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/LootReceiptTracker.lua"))()
local review=N.GearPlanReview
local receipt=N.LootReceiptTracker
local drop={dropUID="REAL:1",winner="BotOne",itemID=16800,
    raidKey="MOLTEN_CORE",itemName="Arcanist Boots",status="COMPLETE"}
assert(receipt:ObserveWinner(drop))
assert(#db.lootReceiptTracker[drop.dropUID].needs==1)
assert(review:Arm(key,"ATTEST_OBTAINED"))
assert(review:Confirm())
assert(plan.status=="OBTAINED" and plan.obtainedDropUID==nil)
assert(db.lootReceiptTracker[drop.dropUID].status=="WON_AWAITING_ITEM")
assert(db.manualObtainedEvidence[1].receiptVerified==false and grants==0)
local ok,msg=receipt:CanConfirm(drop.dropUID)
assert(not ok and msg:find("record the award",1,true),
    "the manual attestation is not an independent drop award")
db.lootAwardHistory[1]={dropUID=drop.dropUID,itemID=16800,
    winner="BotOne",status="AWARD_REQUESTED"}
assert(not receipt:CanConfirm(drop.dropUID),
    "GiveMasterLoot request alone must never certify receipt")
db.lootAwardHistory[1].status="LEADER_REPORTED"
local audit=db.manualObtainedEvidence
db.manualObtainedEvidence={}
ok,msg=receipt:CanConfirm(drop.dropUID)
assert(not ok and msg:find("changed since",1,true),
    "unverified/manual status without a matching stored attestation is held")
db.manualObtainedEvidence=audit
assert(receipt:CanConfirm(drop.dropUID),
    "genuine past manual attestation must not permanently block later human review")
local done,description=receipt:ConfirmReceipt(drop.dropUID)
assert(done and description:find("1 earlier manual attestation",1,true))
assert(plan.status=="OBTAINED" and plan.obtainedDropUID==drop.dropUID)
assert(unrelated.status=="GREED" and unrelated.obtainedDropUID==nil,
    "different bot and same item remains unmodified")
assert(db.lootReceiptTracker[drop.dropUID].status=="OBTAINED" and
    db.lootReceiptTracker[drop.dropUID].evidence==
    "LEADER_CONFIRMED_RECIPIENT_INVENTORY")
assert(audit[1].receiptVerified==false and
    audit[1].kind=="LEADER_ATTESTED_BOT_HAS_ITEM",
    "original attestation must remain an unaltered historic record")
assert(db.awardAttemptLocks.old==lock and lock.status=="LOCKED_NO_RETRY",
    "no-retry lock must never be cleared")
assert(not receipt:ConfirmReceipt(drop.dropUID) and grants==0,
    "cannot mark same verified receipt again or grant a physical item")
print("PASS: existing manual bot OBTAINED can reconcile exact later receipt safely")
