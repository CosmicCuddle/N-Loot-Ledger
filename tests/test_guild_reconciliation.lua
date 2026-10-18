-- Guild receipts never imply delivery from a cleared loot slot.
-- Only intended recipient confirms their own inventory; no award API here.
local tests=0
local function ok(v,msg)assert(v,msg);tests=tests+1 end
local clock=100
local actor="Leader"
GetTime=function()return clock end
UnitName=function()return actor end
date=function()return "2026-10-18" end
local transfers=0
GiveMasterLoot=function()transfers=transfers+1;error("forbidden")end
local original={
    {itemID=17010,itemLink="|Hitem:17010|h[Fiery Core]|h",
        recipient="Leader",slotIndex=1,quantity=2,
        status="LOOT_SLOT_CLEARED",note="NOT verified"},
    {itemID=17011,itemLink="|Hitem:17011|h[Lava Core]|h",
        recipient="Leader",slotIndex=2,quantity=1,
        status="AWARD_OUTCOME_UNKNOWN",note="WoW denied"},
    {itemID=16800,itemLink="|Hitem:16800|h[Boots]|h",
        recipient="Other",slotIndex=3,quantity=1,
        status="AWARD_REQUESTED"}
}
local gear={Gorak={itemID=16800,status="NEEDED"}}
local nllDB={guildLootTransferAudit=original,gearNeeds=gear,
    lootAwardHistory={{status="LEADER_REPORTED"}}}
NaxxLootLottery={
    db=nllDB,DebugSimulator={IsActive=function()return false end},
    GuildLootTransfer={liveRequests={
        [1]={row=original[1]}
    },WasAttempted=function(_,id,slot)
        for _,row in ipairs(original) do
            if row.itemID==id and row.slotIndex==slot then return true end
        end
        return false
    end},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GuildLootReconciliation.lua"))()
local R=N.GuildLootReconciliation
local list=R:List()
ok(#list==3 and list[1].status=="LOOT_SLOT_CLEARED",
    "read-only audit includes slot clear as UNCERTAIN")
ok(N.db.gearNeeds==gear and N.db.guildLootTransferAudit==original,
    "loading and listing never rebuild saved Gear Plans")
actor="Other"
local allowed,reason=R:Arm(1)
ok(not allowed and reason:find("intended raid leader"),
    "officer or unrelated player cannot confirm raid leader's bags")
actor="Leader"
ok(R:Arm(1),"guild recipient can inspect own saved receipt after raid")
ok(original[1].status=="LOOT_SLOT_CLEARED",
    "first click never claims receipt")
clock=clock+16
allowed,reason=R:Confirm(1)
ok(not allowed and reason:find("expired") and
    original[1].status=="LOOT_SLOT_CLEARED",
    "15-second expiry changes absolutely nothing")
ok(R:Arm(1),"fresh review allowed")
local changedLink=original[1].itemLink
original[1].itemLink="|Hitem:17010|h[Changed]|h"
allowed,reason=R:Confirm(1)
ok(not allowed and reason:find("changed"),
    "audit tampering/mutation before second click refuses receipt")
original[1].itemLink=changedLink
ok(R:Arm(1),"can re-review valid original audit")
clock=clock+1
local verified,msg=R:Confirm(1)
ok(verified and original[1].status=="RECIPIENT_CONFIRMED",
    "separate second click attests OWN verified inventory")
ok(original[1].priorStatus=="LOOT_SLOT_CLEARED" and
    original[1].confirmedBy=="Leader" and
    original[1].evidence=="RECIPIENT_CHECKED_OWN_INVENTORY",
    "old uncertain status and human evidence retained")
ok(N.GuildLootTransfer.liveRequests[1]==nil and
    original[2].status=="AWARD_OUTCOME_UNKNOWN" and
    original[3].status=="AWARD_REQUESTED",
    "only matching pending guild request cleared; other requests retained")
ok(N.GuildLootTransfer:WasAttempted(17010,1),
    "original item+slot forever blocks duplicate attempt")
ok(not R:Arm(1),"already confirmed cannot be re-armed")
ok(not R:Confirm(1),"replaying confirm without armed receipt denied")
ok(R:Arm(2),"another unknown request may be reviewed independently")
actor="Other"
allowed,reason=R:Confirm(2)
ok(not allowed and reason:find("intended raid leader"),
    "recipient change between clicks cancels receipt")
ok(original[2].status=="AWARD_OUTCOME_UNKNOWN",
    "denied confirmation does not rewrite unknown status")
actor="Leader"
allowed,reason=R:Arm(3)
ok(not allowed and reason:find("intended raid leader"),
    "third-party leader cannot confirm someone else's personal inventory")
local existing=N.db.guildLootTransferAudit
ok(gear.Gorak.status=="NEEDED" and N.db.guildLootTransferAudit==existing
    and N.db.lootAwardHistory[1].status=="LEADER_REPORTED",
    "reconciliation doesn't touch bots, plans or winner award history")
ok(transfers==0,"no Master Loot call in reconciliation")
print("PASS: "..tests.." guild receipt reconciliation / anti-duplicate assertions")
