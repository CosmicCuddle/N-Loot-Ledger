-- Lua 5.1: unfinished winner receipt / human ACK blocks guild routing.
-- No real WoW items, SavedVariables or stored Gear Plans modified.
local checks=0
local function ok(v,m)assert(v,m);checks=checks+1 end
local calls=0
GiveMasterLoot=function()calls=calls+1;error("NO physical awards")end
RandomRoll=function()calls=calls+1;error("NO rolls")end
local ids={17010,17011,17012,17013,17014,17015}
GetLootThreshold=function()return 1 end
GetNumLootItems=function()return #ids end
GetLootSlotLink=function(slot)
    local id=ids[slot]
    return "|Hitem:"..id..":0|h[Material "..id.."]|h"
end
GetLootSlotInfo=function()return nil,nil,1,2,false end
GetItemInfo=function(id)return "Material "..id,nil,2,nil,nil,"Trade Goods" end
GetNumRaidMembers=function()return 3 end
local leader,masterIndex,masterMode,actor="Leader",1,"master","Leader"
GetRaidRosterInfo=function(i)
    if i==1 then return leader,2 end
    return "Raid"..i,0
end
GetLootMethod=function()return masterMode,nil,masterIndex end
UnitName=function()return actor end
local pending={dropUID="L1:1:17010",itemID=17010,
    character="Throgar",status="WON_AWAITING_ITEM"}
local ack={dropUID="L1:2:17011",itemID=17011,
    character="Pikeotter",status="OBTAINED",remoteSyncStatus="AWAITING_PLAYER"}
local done={dropUID="L1:3:17012",itemID=17012,
    character="Pikeotter",status="OBTAINED",remoteSyncStatus="ACKNOWLEDGED"}
local bot={dropUID="L1:4:17013",itemID=17013,
    character="Throgar",status="OBTAINED"}
local unknown={dropUID="L1:5:17014",itemID=17014,
    character="Pikeotter",status="SOMETHING_UNKNOWN"}
local receiptBook={
    [pending.dropUID]=pending,[ack.dropUID]=ack,
    [done.dropUID]=done,[bot.dropUID]=bot,
    [unknown.dropUID]=unknown,
}
local needs={old={itemID=17010,character="Throgar",
    raidKey="MOLTEN_CORE",status="OBTAINED"}}
local localWish={Pikeotter={MOLTEN_CORE={
    [17013]=true,[17015]=true}}}
local obtained={Pikeotter={MOLTEN_CORE={[17013]=true}}}
local inbox={}
local records={itemID=17015,recipient="Leader",
    slotIndex=1,status="LOOT_SLOT_CLEARED"}
local guildAudit={records}
local db={
    gearNeeds=needs,localWishlists=localWish,
    localWishlistObtained=obtained,submissionInbox=inbox,
    lootReceiptTracker=receiptBook,guildLootTransferAudit=guildAudit,
    lootAwardHistory={},settings={
        directMasterLootEnabled=true,
        guildLootTransfersEnabled=true,
        guildAutoPreviewEnabled=true},
}
NaxxLootLottery={
    db=db,
    DebugSimulator={IsActive=function()return false end},
    LootDetection={lootOpen=true},
    TicketLottery={active=nil,liveLootObserved=true,
        AuthorityAllowed=function()return true end},
    Data={MoltenCore={GetItem=function()end}},
    AwardWorkflow={verification=nil,liveRequests={}},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GuildLootReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildAutoPreview.lua"))()
local R=N.GuildLootReview
local G=N.GuildLootTransfer
local P=N.GuildAutoPreview
local rows=R:Scan()
ok(#rows==6,"live all-slot scan includes different crafting materials")
for i=1,2 do
    ok(rows[i].status=="UNRESOLVED" and
       rows[i].receiptPending==1,
       "missing active Gear Plan / outstanding recipient ACK held")
end
ok(rows[1].reason:find("NEVER auto-route",1,true),
    "reason explicitly identifies pending recipient confirmation")
ok(rows[3].status=="GUILD_REVIEW" and rows[4].status=="GUILD_REVIEW",
    "confirmed human and bot receipts clear only extra hold")
ok(rows[5].status=="UNRESOLVED" and rows[5].receiptPending==1,
    "unknown future receipt state fails closed")
ok(rows[6].status=="UNRESOLVED" and rows[6].localCount==1,
    "unverified local reservation still held")
ok(R:GetReservationSummary(17013).localCount==0,
    "obtained local boolean is historical rather than active reservation")
ok(db.localWishlists==localWish and db.localWishlistObtained==obtained,
    "read-only scanner does not create/replace local tables")
local plan=P:Build()
ok(plan.proposed==0 and plan.rows[3].decision=="HOLD_UNRESOLVED_REQUEST",
    "LOOT_SLOT_CLEARED without receipt blocks unrelated proposals globally")
records.reconciliationStatus="CLOSED_NO_RETRY"
plan=P:Build()
ok(plan.rows[1].decision=="HOLD_UNCERTAIN" and
   plan.rows[2].decision=="HOLD_UNCERTAIN" and
   plan.rows[3].decision=="PROPOSE_TO_LEADER" and
   plan.rows[4].decision=="PROPOSE_TO_LEADER",
   "NO RETRY closes global gate but pending receipts remain held")
ok(plan.rows[5].decision=="HOLD_UNCERTAIN" and
   plan.rows[6].decision=="HOLD_UNCERTAIN" and plan.proposed==2,
   "only acknowledged or truly unreserved items proposed")
ack.remoteSyncStatus="SEND_FAILED"
plan=P:Build()
ok(plan.rows[2].decision=="HOLD_UNCERTAIN",
   "failed player notification still holds")
ack.remoteSyncStatus="ACKNOWLEDGED"
plan=P:Build()
ok(plan.rows[2].decision=="PROPOSE_TO_LEADER",
   "remote acknowledgment lifts its receipt-only hold")
pending.status="OBTAINED"
plan=P:Build()
ok(plan.rows[1].decision=="PROPOSE_TO_LEADER",
   "independent bot receipt clears pending hold")
pending.status="WON_AWAITING_ITEM"
ack.remoteSyncStatus="AWAITING_PLAYER"
local bad={itemID=17010,itemLink=rows[1].itemLink,
    slotIndex=1,quantity=1}
local allowed,message=G:Validate(bad)
ok(not allowed and message:find("reservation changed",1,true),
    "manual guild transfer cannot bypass orphaned winner")
N.TicketLottery.active={status="WAITING_FOR_ROLL"}
plan=P:Build()
ok(plan.rows[3].decision=="HOLD_ACTIVE_ROLL" and plan.proposed==0,
   "active NEED/GREED tickets hold dry-run proposals")
N.TicketLottery.active=nil
masterMode="group"
plan=P:Build()
ok(plan.rows[3].decision=="HOLD_MASTER_LOOT",
   "Group Loot instead of Master Loot stops proposals")
masterMode="master";actor="Other"
plan=P:Build()
ok(plan.rows[3].decision=="HOLD_MASTER_LOOT",
   "non-designated actor cannot propose")
actor="Leader";masterIndex=2
plan=P:Build()
ok(plan.rows[3].decision=="HOLD_MASTER_LOOT",
   "acting client must match WoW Master Looter raid index")
masterIndex=1
plan=P:Build()
ok(plan.rows[3].decision=="PROPOSE_TO_LEADER",
   "verified master permits ONLY read-only human-reviewed proposal")
N.LootDetection.lootOpen=false
plan=P:Build()
ok(#plan.rows==0 and plan.proposed==0,
   "closed corpse has zero proposals")
ok(calls==0 and db.gearNeeds==needs and db.localWishlists==localWish and
   db.lootReceiptTracker==receiptBook and db.submissionInbox==inbox and
   db.guildLootTransferAudit==guildAudit and #guildAudit==1,
   "zero GiveMasterLoot/RandomRoll and no saved data replaced")
print("PASS: "..checks.." receipt/ACK/cleared-slot/master/lottery holds")
