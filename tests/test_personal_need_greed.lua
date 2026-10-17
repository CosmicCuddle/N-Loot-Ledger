-- NLL personal NEED/GREED V1/V2 transfer. Lua 5.1, no physical loot.
local checks=0
local function ok(v,msg) assert(v,msg);checks=checks+1 end
local actor="Pikeotter"
local clock=100
UnitName=function() return actor end
GetTime=function() return clock end
time=function() return 1800000000+clock end
date=function() return "2026-10-17" end
GetNumRaidMembers=function() return 2 end
GetRaidRosterInfo=function(i)
    if i==1 then return "Leader",2 end
    if i==2 then return "Pikeotter",0 end
end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local outbound={}
SendAddonMessage=function(prefix,message,channel,to)
    outbound[#outbound+1]={prefix=prefix,message=message,channel=channel,to=to}
end
local log={}
NaxxLootLottery={
    databaseVersion=1,
    initialized=true,
    Print=function(_,msg) log[#log+1]=msg end,
    Debug=function()end,
    IsValidRole=function()return true end,
    IsValidClass=function()return true end,
    UI={RefreshWishlistPanel=function()end},
    Data={MoltenCore={GetItem=function(_,id)
        if id==16800 or id==18821 or id==17010 then
            return {itemID=id,name="Fixture "..id}
        end
    end}},
}
local N=NaxxLootLottery
local function load(file)assert(loadfile("NaxxLootLottery/"..file))()end
load("Storage/Database.lua")
N.Database:Initialize()
load("Core/GearNeeds.lua")
load("Core/Communication.lua")
local d,g,c=N.Database,N.GearNeeds,N.Communication
ok(d:SetLocalReservation("Pikeotter","MOLTEN_CORE",16800,true),
    "old boolean Need is preserved")
ok(d:GetLocalInterest("Pikeotter","MOLTEN_CORE",16800)=="NEEDED",
    "legacy wishlist defaults Need")
ok(d:SetLocalReservation("Pikeotter","MOLTEN_CORE",18821,true),
    "second legacy reservation")
ok(d:SetLocalInterest("Pikeotter","MOLTEN_CORE",18821,"GREED"),
    "Greed explicitly saved")
ok(d:GetLocalInterest("Pikeotter","MOLTEN_CORE",18821)=="GREED",
    "individual Greed recalled without modifying original booleans")
local originalWishlist=N.db.localWishlists.Pikeotter.MOLTEN_CORE
local originalGreed=N.db.localWishlistGreed.Pikeotter.MOLTEN_CORE
local historical={status="COMPLETE",winner="Throgar"}
N.db.lotteryHistory={historical}
local historicalNeeds={key="historical",character="Gorak",
    itemID=16800,status="NEEDED",source="BOT_GEAR_PLAN",
    raidKey="MOLTEN_CORE",characterType="PLAYERBOT"}
N.db.gearNeeds.historical=historicalNeeds
N.db=nil
N.Database:Initialize()
ok(N.db.localWishlists.Pikeotter.MOLTEN_CORE==originalWishlist and
    N.db.localWishlistGreed.Pikeotter.MOLTEN_CORE==originalGreed and
    d:GetLocalInterest("Pikeotter","MOLTEN_CORE",18821)=="GREED",
    "Greed survives reload preserving original SavedVariables references")
ok(N.db.gearNeeds.historical==historicalNeeds and
    N.db.lotteryHistory[1]==historical,"bot plan and lottery history intact")
ok(not d:SetLocalInterest("Pikeotter","MOLTEN_CORE",16800,"OBTAINED"),
    "invalid interest cannot overwrite legacy reservation")
local ids=c:BuildLocalWishlistItemIDs()
local interests=c:BuildLocalWishlistInterests(ids)
ok(#ids==2 and interests[16800]=="NEEDED" and interests[18821]=="GREED",
    "outgoing item IDs and statuses match saved data")
local function receiveAs(who,msg)
    actor=who
    c:HandleAddonMessage("NLL",msg,"WHISPER",who=="Leader" and "Pikeotter" or "Leader")
end
-- Player sends V2 HELLO to leader; leader's V1 reply is an INVALID
-- handshake and must not downgrade a GREED reservation.
actor="Pikeotter"
c:SubmitLocalWishlist()
ok(c.pendingOutgoing and c.pendingOutgoing.protocol=="V2" and
    outbound[#outbound].message=="V2|HELLO","Greed requires V2 handshake")
local oldTotal=#outbound
receiveAs("Pikeotter","V1|HELLO_ACK")
ok(#outbound==oldTotal and c.pendingOutgoing.state=="WAIT_HELLO",
    "V1 raid leader cannot silently turn Greed into Need")
receiveAs("Pikeotter","V2|HELLO_ACK")
ok(c.pendingOutgoing.state=="WAIT_ACK" and #outbound>oldTotal,
    "V2 confirmation sends typed messages")
local sent={}
for _,m in ipairs(outbound) do
    if m.message:find("^V2|BEGIN") or m.message:find("^V2|ITEM") or
        m.message:find("^V2|END") then sent[#sent+1]=m.message end
end
local typed=false
for _,m in ipairs(sent) do
    if m:find("|18821|GREED",1,true) then typed=true end
end
ok(typed and #sent==4,"Greed interest explicitly typed on wire")
for _,msg in ipairs(sent) do receiveAs("Leader",msg) end
local all=c:GetInboxSubmissions()
ok(#all==1 and all[1].interests[16800]=="NEEDED" and
    all[1].interests[18821]=="GREED","raid leader inbox retains Need and Greed")
local submission=all[1]
ok(c:AcceptSubmission(submission.key),"leader accepts typed submission")
local needKey=g:MakeKey("Pikeotter","MOLTEN_CORE",16800,"PLAYER_SUBMITTED")
local greedKey=g:MakeKey("Pikeotter","MOLTEN_CORE",18821,"PLAYER_SUBMITTED")
ok(g:GetNeed(needKey).status=="NEEDED" and
    g:GetNeed(greedKey).status=="GREED",
    "accepted player Gear Needs preserve distinction")
ok(g:GetNeed("historical")==historicalNeeds and
    historicalNeeds.status=="NEEDED","bot plan never touched by player acceptance")
-- Even a forged bad status may never delete an earlier accepted plan.
local replaced,reason=g:ReplacePlayerSubmitted("Pikeotter","MOLTEN_CORE",
    {16800,18821},{[16800]="NEEDED",[18821]="OBTAINED"})
ok(replaced==false and reason:find("Invalid personal"),
    "invalid status rejected before mutating accepted Gear Needs")
ok(g:GetNeed(needKey).status=="NEEDED" and
    g:GetNeed(greedKey).status=="GREED","failed replacement keeps prior plans")
-- After unreserving a Greed item, the extra preference must disappear.
ok(d:SetLocalReservation("Pikeotter","MOLTEN_CORE",18821,false),
    "unreserve succeeds")
ok(d:GetLocalInterest("Pikeotter","MOLTEN_CORE",18821)==nil and
    originalGreed[18821]==nil,"unreserve clears only the related Greed flag")
-- Legacy V1 NEED-only lists continue to use the original message shape.
actor="Pikeotter"
outbound={}
c.pendingOutgoing=nil
c:SubmitLocalWishlist()
ok(c.pendingOutgoing.protocol=="V1" and outbound[1].message=="V1|HELLO",
    "all-Need wishlist stays backward compatible")
receiveAs("Pikeotter","V1|HELLO_ACK")
local v1item=false
for _,m in ipairs(outbound) do
    if m.message:find("^V1|ITEM") then
        v1item=(m.message:find("|NEEDED",1,true)==nil)
    end
end
ok(v1item,"legacy V1 item packets remain unchanged")
ok(N.db.lotteryHistory[1]==historical,"no need/greed submission writes lottery history")
print("PASS: "..checks.." personal NEED/GREED and legacy-V1 compatibility assertions")
