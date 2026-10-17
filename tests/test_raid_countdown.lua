-- Guard the optional five-second live-raid countdown; Lua 5.1 only.
local checks=0
local function ok(v,m)assert(v,m);checks=checks+1 end
local now=100
GetTime=function()return now end
date=function()return "2026-10-17" end
UnitName=function()return "Leader" end
GetNumRaidMembers=function()return 40 end
IsRaidLeader=function()return true end
IsRaidOfficer=function()return false end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local rolls={}
RandomRoll=function(a,b)rolls[#rolls+1]={a,b}end
local public={}
SendChatMessage=function(s,channel)public[#public+1]={s,channel}end
local localMsgs={}
local awardCalls=0
GiveMasterLoot=function()awardCalls=awardCalls+1 end
local first={dropUID="L1:1:16800",itemID=16800,itemName="Giantstalker's Bracers",
    raidKey="MOLTEN_CORE",state="DETECTED",slotIndex=1}
local second={dropUID="L2:1:18821",itemID=18821,itemName="Quick Strike Ring",
    raidKey="MOLTEN_CORE",state="DETECTED",slotIndex=1}
local entries={first,second}
local selectedIndex=1
local poolNames={"Elki","Hettraz"}
local processed={}
NaxxLootLottery={
    initialized=true,
    db={settings={raidAnnouncementsEnabled=true,raidCountdownEnabled=true,
        directMasterLootEnabled=false,debug=false},
        lotteryHistory={},lootAwardHistory={},gearNeeds={}},
    Print=function(_,s)localMsgs[#localMsgs+1]=s end,
    Debug=function()end,
    UI={currentLootSelected=1,RefreshCurrentLootPanel=function()end,
        ShowWinnerAnnouncement=function()end},
    Roster={Refresh=function()end},
    DebugSimulator={IsActive=function()return false end},
    LootIdentity={IsProcessed=function(_,uid)return processed[uid]==true end,
        MarkCompleted=function(_,uid)processed[uid]=true end},
    LootDetection={lootOpen=true,GetCurrentLoot=function()return entries end},
    TicketPlanner={BuildPreview=function()
        local pool={}
        for _,name in ipairs(poolNames) do pool[#pool+1]={character=name} end
        return {ready=true,current=pool,chosenTier=1,selectionType="NEED"}
    end}
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/TicketLottery.lua"))()
local L=N.TicketLottery
local prepared,msg=L:Prepare(first)
ok(prepared and L.active.status=="PREPARED","prepare tickets is manual")
ok(#rolls==0 and #public==2,"prepare announces only; no server roll")
ok(public[1][2]=="RAID" and public[1][1]:find("Giantstalker's Bracers",1,true),
    "prepared item announced in RAID only")
ok(public[2][1]:find("1:Elki",1,true) and
    public[2][1]:find("2:Hettraz",1,true),"tickets announced compactly")
ok(N.db.settings.directMasterLootEnabled==false and awardCalls==0,
    "chat feature never activates Direct Master Loot")
local started,notice=L:StartRoll(first)
ok(started and L.active.status=="COUNTDOWN" and #rolls==0,
    "Start Roll begins countdown, not a premature roll")
ok(public[#public][1]:find("rolling in 5",1,true),
    "start of five-second countdown announced")
for remaining=4,1,-1 do
    now=now+1
    L:OnUpdate(0.6)
    ok(L.active.status=="COUNTDOWN" and #rolls==0,
        "remaining "..remaining.." seconds cannot roll")
    ok(public[#public][1]:find("NLL: "..remaining,1,true),
        "announces countdown "..remaining)
end
now=now+1
L:OnUpdate(0.6)
ok(L.active.status=="WAITING_FOR_ROLL" and #rolls==1 and
    rolls[1][1]==1 and rolls[1][2]==2,
    "exactly one server RandomRoll after full 5 seconds")
L:OnUpdate(0.6)
ok(#rolls==1,"additional OnUpdate does not double-roll")
ok(L:Finish(2,"SERVER_RANDOM_ROLL"),
    "validated WoW server roll result finishes once")
ok(processed[first.dropUID]==true and
    L.active.winner=="Hettraz","winner committed with original identity")
ok(public[#public][1]:find("Hettraz",1,true) and
    public[#public][1]:find("not yet awarded",1,true),
    "RAID confirms winner but never pretends to award")
ok(awardCalls==0 and #N.db.lootAwardHistory==0,
    "result and RAID messages never give a real item")
-- A second click cannot reroll an already completed physical drop.
local duplicate,duplicateMsg=L:Prepare(first)
ok(not duplicate and duplicateMsg:find("already has a winner"),
    "physical drop's previous winner locked")
-- Start a new drop, switch selection during countdown -> abort.
N.UI.currentLootSelected=1
entries={second,first}
L.active=nil
L.results={}
ok(L:Prepare(second),"different drop prepares")
ok(L:StartRoll(second),"different drop begins new countdown")
local before=#rolls
N.UI.currentLootSelected=2
now=now+1
L:OnUpdate(0.6)
ok(L.active==nil and #rolls==before,
    "change of selected drop aborts countdown before server roll")
-- Live corpse closure aborts without a roll.
N.UI.currentLootSelected=1
ok(L:Prepare(second),"tickets can be prepared after selection restored")
ok(L:StartRoll(second),"countdown can start again")
N.LootDetection.lootOpen=false
L.liveLootObserved=false
before=#rolls
now=now+1
L:OnUpdate(0.6)
ok(L.active==nil and #rolls==before,"despawned corpse cannot finish countdown")
-- A changed candidate list must abort the draw.
N.LootDetection.lootOpen=true
L.liveLootObserved=true
ok(L:Prepare(second),"prepare on the genuinely reopened drop")
ok(L:StartRoll(second),"start valid countdown")
poolNames={"Elki","Mani"}
before=#rolls
now=now+1
L:OnUpdate(0.6)
ok(L.active==nil and #rolls==before,"pool drift aborts before rolling")
poolNames={"Elki","Hettraz"}
-- Opted-out users keep immediate manual Start Roll, without any RAID chat.
N.db.settings.raidCountdownEnabled=false
N.db.settings.raidAnnouncementsEnabled=false
local announcements=#public
ok(L:Prepare(second),"legacy immediate ticket preparation")
ok(L:StartRoll(second),"legacy immediate roll remains")
ok(#rolls==before+1 and #public==announcements,
    "default-off path causes no countdown and no raid announcements")
ok(awardCalls==0 and N.db.settings.directMasterLootEnabled==false,
    "no Master Loot API used in any countdown branch")
print("PASS: "..checks.." guarded 5-second RAID countdown / compatibility assertions")
