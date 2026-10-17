-- New Drop guard: live new corpse only, two clicks, no overwrite of winner.
-- Runs as Lua 5.1 with the exact UI and identity functions; no WoW UI or loot awards.
local tests=0
local function ok(v,msg) assert(v,msg);tests=tests+1 end
local now=120
GetTime=function() return now end
time=function() return 1800000000+now end
date=function() return "2026-10-17" end
UnitName=function() return "RaidLeader" end
GetNumRaidMembers=function() return 40 end
local leader=true
IsRaidLeader=function() return leader end
IsRaidOfficer=function() return false end
local itemID=16800
GetNumLootItems=function() return 1 end
GetLootSlotLink=function() return "|Hitem:"..itemID..":0:0:0|h[Test item]|h" end
GetLootSlotInfo=function() return nil,nil,1,4,false end
local eventFrame
CreateFrame=function()
    local frame={eventMap={}}
    function frame:RegisterEvent(event) self.eventMap[event]=true end
    function frame:SetScript(name,fn) self[name]=fn end
    eventFrame=frame
    return frame
end
local messages={}
local refreshed=0
NaxxLootLottery={
    db={raidSession={currentLoot={},lootGeneration=0},settings={debug=false},
        lootIdentityAudit={},lotteryHistory={},lootAwardHistory={}},
    Print=function(_,msg) messages[#messages+1]=msg end,
    Debug=function()end,
    UI={RefreshCurrentLootPanel=function()refreshed=refreshed+1 end},
    Roster={Refresh=function()end},
    CandidateReview={OnLootChanged=function()end},
    DebugSimulator={IsActive=function()return false end},
    AwardWorkflow={liveRequests={},OnLootClosed=function()end},
    Data={MoltenCore={GetItem=function(_,id)
        if id==16800 then return {itemID=id,name="Giantstalker's Bracers",
            bosses={"Ragnaros"}} end
    end}},
}
local n=NaxxLootLottery
local function load(path) assert(loadfile("NaxxLootLottery/"..path))() end
load("Core/LootIdentity.lua")
load("Core/TicketLottery.lua")
load("Core/LootDetection.lua")
load("UI/CurrentLootFrame.lua")
n.LootIdentity:Initialize()
ok(n.LootDetection:ScanLootWindow(),"a live supported item can be observed")
local first=n.LootDetection:GetCurrentLoot()[1]
n.LootIdentity:MarkCompleted(first.dropUID,"Elki",1,"SERVER_RANDOM_ROLL","NEED",1)
local group=n.LootIdentity:GetGroup()
local oldID=first.dropUID
local oldGeneration=n.db.raidSession.lootGeneration
ok(n.LootIdentity:IsProcessed(oldID),"existing winner is recorded")
ok(n.UI:RequestNewDrop(),"first click arms only")
ok(n.UI.currentLootNewDropPending and group.rows[1].uid==oldID and
    n.db.raidSession.lootGeneration==oldGeneration,
    "first click does not create a new loot opportunity")
local confirmed,message=n.UI:RequestNewDrop()
ok(confirmed and message:find("New loot opportunity"),
    "second click explicitly confirms a new corpse")
local second=n.LootDetection:GetCurrentLoot()[1]
ok(second.dropUID~=oldID and not n.LootIdentity:IsProcessed(second.dropUID),
    "new actual corpse gets a unique rollable UID")
ok(n.LootIdentity:IsProcessed(oldID) and
    n.LootIdentity:GetRow(oldID).winner=="Elki",
    "old winner is never erased on explicit new corpse")
ok(n.UI.currentLootNewDropPending==false,
    "successful confirmation exits pending mode")
ok(refreshed>0,"UI refreshes after confirming new drop")
local initialCount=#messages
n.LootDetection:ScanLootWindow()
local warned=false
for i=initialCount+1,#messages do
    if messages[i]:find("REPEATED LOOT DETECTED",1,true) then
        warned=true
    end
end
ok(not warned,"clean new drop does not spam a repeated-drop warning")
-- Reopen an already processed match to reproduce the live repeating case.
n.LootIdentity:MarkCompleted(second.dropUID,"Mani",2,"SERVER_RANDOM_ROLL","NEED",1)
initialCount=#messages
n.LootDetection:ScanLootWindow()
for i=initialCount+1,#messages do
    if messages[i]:find("REPEATED LOOT DETECTED",1,true) then warned=true end
end
ok(warned,"repeat winner triggers warning before corpse closes")
ok(n.UI:RequestNewDrop(),"new corpse action can be armed")
ok(n.UI.currentLootNewDropPending,"armed before LOOT_CLOSED")
local beforeGroup=n.LootIdentity:GetGroup().id
local beforeRepaint=refreshed
ok(eventFrame.eventMap.LOOT_CLOSED and eventFrame.OnEvent,
    "real LOOT_CLOSED event is registered")
eventFrame:OnEvent("LOOT_CLOSED")
ok(not n.LootDetection.lootOpen and not n.TicketLottery.liveLootObserved,
    "LOOT_CLOSED clears both live signals")
ok(not n.UI.currentLootNewDropPending and
    n.LootIdentity.confirmation==nil,
    "LOOT_CLOSED cancels pending new-drop confirmation")
ok(refreshed>beforeRepaint,"LOOT_CLOSED immediately updates controls")
local refused,reason=n.UI:RequestNewDrop()
ok(not refused and reason:find("Open REAL raid loot"),
    "despawned corpse cannot be revived by New Drop")
ok(n.LootIdentity:GetGroup().id==beforeGroup,
    "failed confirmation after corpse closure changes no ledger identity")
-- New real open, allow a fresh arm then let it expire (20-second deadline).
ok(n.LootDetection:ScanLootWindow(),"new LOOT_OPENED marks genuine live evidence")
ok(n.UI:RequestNewDrop(),"fresh active corpse arms")
now=now+21
local expired,expiredReason=n.UI:RequestNewDrop()
ok(not expired and expiredReason:find("expired") and
    not n.UI.currentLootNewDropPending,
    "confirmation expiry never unlocks previous winner")
-- Raid leadership is an independent gate even with valid live loot.
leader=false
local blocked,blockedReason=n.UI:RequestNewDrop()
ok(not blocked and blockedReason:find("Open REAL raid loot"),
    "non-officer cannot reset loot identity")
leader=true
-- Unresolved server roll is never bypassed by clicking New Drop.
n.TicketLottery.active={status="WAITING_FOR_ROLL",dropUID=second.dropUID}
local denied,deniedReason=n.UI:RequestNewDrop()
ok(not denied and deniedReason:find("pending server roll"),
    "unresolved server roll blocks new drop")
n.TicketLottery.active=nil
ok(n.db.lootAwardHistory and #n.db.lootAwardHistory==0,
    "neither new-drop action invents a real award receipt")
print("PASS: "..tests.." two-step New Drop, warning, closed-corpse, expiry, leader and history assertions")
