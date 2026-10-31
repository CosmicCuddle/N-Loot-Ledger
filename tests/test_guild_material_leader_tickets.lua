-- WoW 3.3.5a Lua 5.1: owner-approved five-material leader-only ticket
-- routing. No random contest, never changes NEED/GREED or real items.
local n=0
local function ok(v,m)assert(v,m);n=n+1 end
local awards,randomRolls=0,0
GiveMasterLoot=function()awards=awards+1;error("NEVER GRANT")end
RandomRoll=function()randomRolls=randomRolls+1;error("NEVER ROLL")end
GetTime=function()return 100 end
date=function()return "2026-10-31" end
UnitName=function()return "Operator" end
IsRaidLeader=function()return true end
local leader="RaidLeader"
GetNumRaidMembers=function()return 3 end
GetRaidRosterInfo=function(i)
    if i==1 then return leader,2 end
    if i==2 then return "Operator",0 end
    return "Other",0
end
local itemID=17011
local qty=2
local lootOpen=true
local threshold=1
GetLootThreshold=function()return threshold end
GetNumLootItems=function()return 1 end
local function link(id)return "|Hitem:"..id..":0|h[Material "..id.."]|h"end
GetLootSlotLink=function()return link(itemID)end
GetLootSlotInfo=function()return nil,nil,qty,2,false end
GetItemInfo=function(id)return "Material "..id,nil,2,nil,nil,"Trade Goods" end
local entry={dropUID="LIVE:1:17011",state="DETECTED",
    itemID=itemID,itemLink=link(itemID),quantity=qty,
    itemName="Lava Core",raidKey="MOLTEN_CORE",slotIndex=1,
    manualOnly=true}
local rosterRefresh=0
local popup=nil
local db={gearNeeds={},localWishlists={},localWishlistObtained={},
    lootReceiptTracker={},submissionInbox={},lotteryHistory={},
    lootAwardHistory={},guildLootTransferAudit={},
    settings={guildLootTransfersEnabled=true,directMasterLootEnabled=true}}
NaxxLootLottery={
    db=db,
    DebugSimulator={IsActive=function()return false end},
    TicketLottery={},
    LootDetection={
        lootOpen=true,GetCurrentLoot=function()return {entry}end},
    Roster={Refresh=function()rosterRefresh=rosterRefresh+1 end},
    LootIdentity={
        IsProcessed=function()return false end,
        GetRow=function()return nil end,
        MarkCompleted=function()end,
    },
    LootReceiptTracker={ObserveWinner=function()return true end},
    AwardWorkflow={liveRequests={}},
    NeedMatcher={GetMatchesForItem=function()return {}end},
    CandidateReview={MergeMatches=function(_,_,m)return m end},
    Data={MoltenCore={GetItem=function(_,id)
        local known={17011,17010,17012,11382,7075}
        for _,i in ipairs(known) do
            if id==i then return {itemID=i,name="Material "..i,manualOnly=true} end
        end
    end,IsRecipeItem=function()return false end}},
    PriorityEngine={STATUS={MANUAL_ONLY="MANUAL_ONLY",
        CONFIGURED="CONFIGURED"},GetState=function()return "MANUAL_ONLY" end},
    UI={currentLootSelected=1,RefreshCurrentLootPanel=function()end,
        ShowWinnerAnnouncement=function(_,...)popup={...}end},
    Print=function()end,
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GuildLootReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
assert(loadfile("NaxxLootLottery/Core/TicketPlanner.lua"))()
assert(loadfile("NaxxLootLottery/Core/TicketLottery.lua"))()
N.TicketLottery.liveLootObserved=true
local G=N.GuildLootReview
local T=N.GuildLootTransfer
local P=N.TicketPlanner
local L=N.TicketLottery
local p=P:BuildPreview(entry)
ok(p.ready and p.guildLeaderOnly and p.selectionType=="GUILD" and
   #p.current==1 and p.current[1].character=="RaidLeader",
   "guild material prepares one actual raid-leader ticket")
ok(#p.waiting==0 and #p.unresolved==0 and not popup and
   randomRolls==0 and awards==0 and #db.lotteryHistory==0,
   "mere preview cannot roll/award or edit histories")
local sent,why=T:Review({slotIndex=1,itemID=itemID,
    itemLink=entry.itemLink,quantity=qty})
ok(not sent and why:find("leader%-only"),"old Guild Master transfer route blocked")
ok(L:Prepare(entry),"leader-only material may use normal Prepare Tickets")
ok(L.active and #L.active.tickets==1 and
    L.active.tickets[1].character=="RaidLeader" and
    L.active.selectionType=="GUILD" and randomRolls==0,
    "saved ticket pool is exclusively the designated raid leader")
ok(L:StartRoll(entry),"Start Roll finalises a single-ticket allocation")
ok(randomRolls==0 and awards==0 and popup and popup[2]=="RaidLeader" and
   popup[5]=="GUILD" and popup[7]=="LIVE:1:17011",
   "Start Roll produces leader winner popup, never random roll/physical give")
ok(L.active.status=="COMPLETE" and L.active.winner=="RaidLeader" and
    L.active.method=="GUILD_LEADER_ONLY" and
    db.lotteryHistory[#db.lotteryHistory].winner=="RaidLeader",
    "leader-only selection is clearly audited, never portrayed as random")
ok(not L:Prepare(entry),"same live opportunity cannot reroll after winner")
ok(#db.gearNeeds==0 and awards==0,
   "no Gear Plan status changed from preparing or finishing guild material")

-- Subsequent fresh source cases test scanner and reservation holds only;
-- do not reset/erase a real completed roll to claim a second winner.
local function hold(whyExpected)
    local v=P:BuildPreview(entry)
    ok(not v.ready and v.message:find(whyExpected,1,true),
       "material preview held: "..whyExpected)
end
db.gearNeeds.a={itemID=17011,character="Other",raidKey="MOLTEN_CORE",
    status="NEEDED"}
hold("NEED")
db.gearNeeds.a=nil
db.localWishlists.Other={MOLTEN_CORE={[17011]=true}}
hold("wishlist")
db.localWishlists.Other=nil
threshold=3
hold("Below WoW")
threshold=1
qty=3
hold("stack changed")
qty=2
leader="ChangedLeader"
local q=P:BuildPreview(entry)
ok(q.ready and q.current[1].character=="ChangedLeader" and
   #q.current==1,"live raid-leader roster change is re-read, not pinned")
leader="RaidLeader"
db.guildLootTransferAudit[1]={itemID=17011,status="AWARD_REQUESTED"}
hold("unresolved")
db.guildLootTransferAudit[1].reconciliationStatus="CLOSED_NO_RETRY"
hold("NO RETRY")
db.guildLootTransferAudit={}
N.LootDetection.lootOpen=false
hold("absent")
N.LootDetection.lootOpen=true
entry.identityUncertain=true
hold("unambiguous")
ok(awards==0 and randomRolls==0,"all leader policy tests remain non-awarding")
print("PASS: "..n.." sole-leader guild tickets and reservation/identity safety")
