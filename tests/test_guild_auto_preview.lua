-- All-slot automatic guild routing DRY RUN, not a real loot transfer.
local assertions=0
local function ok(v,reason)assert(v,reason);assertions=assertions+1 end
local IDs={16800,18821,17010,17011,17012,17204,17013,17014,0}
local originalGear={a={itemID=16800,raidKey="MOLTEN_CORE",status="NEEDED",
    character="Gorak",source="BOT_GEAR_PLAN"},
    b={itemID=18821,raidKey="MOLTEN_CORE",status="GREED",
    character="Pikeotter",source="PLAYER_SUBMITTED"}}
local wishes={Pikeotter={MOLTEN_CORE={[17011]=true}}}
local inbox={x={raidKey="MOLTEN_CORE",status="PENDING",itemIDs={17010}}}
local saved={gearNeeds=originalGear,localWishlists=wishes,
    submissionInbox=inbox,lootAwardHistory={{winner="Old"}},
    guildLootTransferAudit={}}
local actor="Leader"
local masterIndex=1
local unresolved=false
local busy=false
local live=true
local actualAwardCalls=0
GiveMasterLoot=function()actualAwardCalls=actualAwardCalls+1;error("NO ITEM GRANTS")end
RandomRoll=function()error("NO ROLLS IN PREVIEW")end
GetNumLootItems=function()return #IDs end
GetLootSlotLink=function(slot)
    local id=IDs[slot]
    if id==0 then return nil end
    return "|Hitem:"..id..":0|h[Fixture "..id.."]|h"
end
GetLootSlotInfo=function()return nil,nil,2,4,false end
GetItemInfo=function(id)
    if id==17013 then return nil end
    return "Fixture "..id,nil,(id==17204 and 5 or 2),nil,nil,
        ((id==17012 or id==16800 or id==18821) and "Armor" or "Trade Goods")
end
GetNumRaidMembers=function()return 2 end
GetRaidRosterInfo=function(i)
    if i==1 then return "Leader",2 end
    return "Pikeotter",0
end
GetLootMethod=function()return "master",nil,masterIndex end
UnitName=function()return actor end
NaxxLootLottery={
    db=saved,
    LootDetection={lootOpen=true},
    TicketLottery={liveLootObserved=true,active=nil},
    DebugSimulator={IsActive=function()return false end},
    GuildLootTransfer={
        IsUnresolved=function()return unresolved end,
        WasAttempted=function(_,id,slot)return id==17014 and slot==8 end
    },
    Data={MoltenCore={GetItem=function(_,id)
        if id==17204 then return {itemID=id,manualOnly=true} end
    end}},
    Database={GetLocalInterest=function(_,_,_,id)
        if id==17011 then return "OBTAINED" end
    end}
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GuildLootReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildAutoPreview.lua"))()
local P=N.GuildAutoPreview
local plan=P:Plan()
ok(#plan.items==8 and plan.proposed==3 and plan.held==5,
    "all item-link slots included, previously obtained local wish not counted")
local index={}
for _,r in ipairs(plan.items) do index[r.itemID]=r end
ok(index[16800].decision=="HOLD_RESERVED" and
    index[18821].decision=="HOLD_RESERVED",
    "saved NEED and GREED both outrank automatic guild routing")
ok(index[17010].decision=="HOLD_UNCERTAIN",
    "pending Inbox submission cannot be called unreserved")
ok(index[17011].decision=="PROPOSED_ONLY" and
    index[17011].classification=="Trade Goods",
    "known-unreserved crafting material proposed for leader inspection")
ok(index[17012].decision=="PROPOSED_ONLY",
    "unreserved armor proposed, never automatically transferred")
ok(index[17204].decision=="HOLD_SPECIAL",
    "legendary/manual treasure is special hold")
ok(index[17013].decision=="HOLD_UNCERTAIN",
    "uncached item may never be auto-assigned")
ok(index[17014].decision=="HOLD_DUPLICATE",
    "historical same item-slot attempt blocks new automatic proposal")
ok(plan.dryRun and plan.automaticTransfersEnabled==false and
    plan.realTransfers==0 and actualAwardCalls==0,
    "preview never calls any item transfer API")
for _,row in ipairs(plan.items) do
    ok(row.dryRun==true and
       row.recipientVerified==false and
       row.candidateVerified==false and
       row.transferAuthorized==false and
       row.physicalAwardRequested==false,
       "no planner row carries an award authorization")
end
ok(saved.gearNeeds==originalGear and
    saved.localWishlists==wishes and
    saved.submissionInbox==inbox and
    saved.lootAwardHistory[1].winner=="Old",
    "running planner doesn't edit 604-plan-equivalent source data")
unresolved=true
plan=P:Plan()
ok(plan.proposed==0 and
    index[17011].decision=="PROPOSED_ONLY",
    "refresh creates new plan without mutating earlier summary")
ok(plan.items[4].decision=="HOLD_PRIOR_AWARD",
    "any uncertain earlier material delivery suppresses proposals")
unresolved=false
masterIndex=2
plan=P:Plan()
ok(plan.proposed==0 and
    plan.items[4].decision=="HOLD_MASTER_LOOT",
    "acting player not designated Master Looter means no proposals")
masterIndex=1
N.TicketLottery.active={status="COUNTDOWN"}
plan=P:Plan()
ok(plan.items[4].decision=="HOLD_ACTIVE_ROLL",
    "active NLL ticket lottery blocks proposed leader materials")
N.TicketLottery.active=nil
N.LootDetection.lootOpen=false
plan=P:Plan()
ok(#plan.items==0 and
    plan.notice:find("CORPSE CLOSED",1,true),
    "closed real corpse produces zero proposals, ignores stale loot history")
N.LootDetection.lootOpen=true
N.DebugSimulator.IsActive=function()return true end
plan=P:Plan()
ok(#plan.items==0 and plan.realTransfers==0,
    "fake raids do not generate real guild proposals")
ok(actualAwardCalls==0 and #saved.guildLootTransferAudit==0,
    "no server awards or saved request attempts from preview")
print("PASS: "..assertions.." full-slot unreserved material routing preview/zero-award assertions")
