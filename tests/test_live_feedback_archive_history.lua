-- Lua 5.1: owner visual feedback from live 3.3.5a client.
-- 636 plans are the CURRENT screenshot, never reset to older 604 count.
local n=0
local function ok(v,why)assert(v,why);n=n+1 end
local grant=0
GiveMasterLoot=function()grant=grant+1;error("NO GRANTS")end
RandomRoll=function()grant=grant+1;error("NO ROLLS")end
SendAddonMessage=function()grant=grant+1;error("NO CHAT")end
local now=100
local stamp="2026-10-18 16:43:00"
GetTime=function()return now end
date=function(fmt) if fmt=="%Y-%m-%d %H:%M:%S" then
    return stamp end
    return "18/10/2026 16:43" end
UnitName=function()return "Owner" end
local function frame()
    local f={enabled=true,visible=false,scripts={}}
    function f:SetPoint(...)self.point={...}end
    function f:SetAllPoints(...)end
    function f:SetWidth(w)self.width=w end
    function f:SetHeight(h)self.height=h end
    function f:SetSize(w,h)self.width=w;self.height=h end
    function f:SetText(v)self.text=v end
    function f:GetText()return self.text end
    function f:SetJustifyH(...)end
    function f:SetJustifyV(...)end
    function f:CreateFontString()return frame()end
    function f:RegisterEvent()end
    function f:SetScript(k,fn)self.scripts[k]=fn end
    function f:Hide()self.visible=false end
    function f:Show()self.visible=true end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=function()return frame()end
local db={
    gearNeeds={},roleAssignments={Owner={role="HEALER"}},
    lotteryHistory={
        {status="COMPLETE",test=false,dropUID="A",
         itemID=16800,itemName="Arcanist Boots",
         winner="BotAA",when="2026-10-18 16:20:00"},
        {status="COMPLETE",test=false,dropUID="B",
         itemID=18291,itemName="Force Reactive Disk",
         winner="BotAB",when="2026-10-18 16:21:00"},
        {status="COMPLETE",test=true,dropUID="FAKE",
         itemID=16800,itemName="Arcanist Boots",
         winner="Fake",when="2026-10-18 16:22:00"},
        {status="INVALIDATED",test=false,dropUID="C",
         itemID=16800,itemName="Arcanist Boots",
         winner="Nobody",when="2026-10-18 16:23:00"}
    },
    lootAwardHistory={{
        dropUID="B",itemID=18291,itemName="Force Reactive Disk",
        winner="BotAB",status="AWARD_OUTCOME_UNKNOWN",
        when="2026-10-18 16:24:00"}},
    awardAttemptLocks={old={status="CLOSED_NO_RETRY"}},
    lootReceiptTracker={},
    submissionInbox={},
    localWishlists={Owner={MOLTEN_CORE={[16800]=true}}},
    settings={directMasterLootEnabled=false,
        guildLootTransfersEnabled=false,guildAutoPreviewEnabled=false},
}
for i=1,636 do
    db.gearNeeds["key"..i]={character="Bot"..i,itemID=16800,
        status=i<=469 and "NEEDED" or "GREED",source="BOT_GEAR_PLAN"}
end
local plans=db.gearNeeds
for i=1,6 do
    db.submissionInbox["sub"..i]={key="sub"..i,
        player="Player"..i,receivedEpoch=i,
        itemIDs={16800,16801},status=i<=4 and "REJECTED" or "PENDING",
        interests={[16800]="NEEDED"},excluded={}}
end
local original={}
for key,v in pairs(db.submissionInbox)do original[key]=v end
NaxxLootLottery={
    db=db,UI={},
    Print=function()end,
    DebugSimulator={IsActive=function()return false end},
    LootDetection={lootOpen=false},
    TicketLottery={active=nil},
    LootReceiptTracker={Get=function()return nil end}
}
local N=NaxxLootLottery
N.UI.RegisterSkinnedFrame=function()end
N.UI.CreateTextButton=function(_,parent,label,width)
    local f=frame();f.width=width;f.label=frame();f.label:SetText(label)
    return f
end
-- Communication adds only addon-message stub event frames.
assert(loadfile("NaxxLootLottery/Core/Communication.lua"))()
assert(loadfile("NaxxLootLottery/Core/RaidHistoryView.lua"))()
assert(loadfile("NaxxLootLottery/UI/AwardHistoryFrame.lua"))()
local Comm=N.Communication
local H=N.RaidHistoryView
local active=Comm:GetInboxSubmissions()
ok(#active==6 and active[1].key=="sub6",
   "six old inbox entries visible and ordered newest-first")
ok(Comm:ArchiveSubmission("sub6"),
   "pending obsolete submission can be locally archived without rejecting")
ok(#Comm:GetInboxSubmissions()==5 and
    #Comm:GetInboxSubmissions(true)==1 and
    db.submissionInbox.sub6.status=="PENDING" and
    db.submissionInbox.sub6.archived==true,
   "archival removes only active VIEW, never changes status")
ok(not Comm:ArchiveSubmission("sub6"),"double archive refused")
ok(Comm:RestoreArchivedSubmission("sub6") and
    #Comm:GetInboxSubmissions()==6 and
    #Comm:GetInboxSubmissions(true)==0,
   "archived item is reversible with its original fields")
ok(not Comm:RestoreArchivedSubmission("sub6"),
   "cannot restore unarchived item")
ok(not Comm:ArchiveSubmission("unknown"),
   "unknown submission does not add a record")
for key,originalEntry in pairs(original)do
    ok(db.submissionInbox[key]==originalEntry and
       #originalEntry.itemIDs==2 and originalEntry.excluded~=nil,
       "all six submissions and original saved item arrays preserved")
end
local entries=H:Build(true)
ok(#entries==2,"one standalone real lottery winner plus one physical audit")
ok(entries[1].source=="PHYSICAL_ATTEMPT" and
   entries[1].winner=="BotAB" and
   entries[1].deliveryVerified==false and
   entries[2].status=="ROLL_WINNER_ONLY" and
   entries[2].winner=="BotAA",
   "physical attempt and lottery-only winner never count as delivered")
ok(not H:ConfirmNewRun(),"no run view without deliberate first click")
ok(H:ArmNewRun(),"new run view can arm without changing history")
ok(#H:Build(false)==2,"arming cannot hide even old entries")
now=now+16
ok(not H:ConfirmNewRun() and #H:Build(false)==2,
   "expired confirmation refuses to hide winner history")
now=now+1
ok(H:ArmNewRun(),"can request a fresh view after expiry")
ok(H:ConfirmNewRun(),"two-click view start confirmed")
ok(#H:Build()==0 and #H:Build(true)==2,
   "This Run empty but All History retains original real winners")
stamp="2026-10-18 16:45:00"
table.insert(db.lotteryHistory,{
    dropUID="D",status="COMPLETE",test=false,
    itemID=18814,itemName="Choker of the Fire Lord",
    winner="BotAC",when=stamp
})
ok(#H:Build()==1 and H:Build()[1].winner=="BotAC",
   "post-boundary winner appears on new run without erasing old data")
local ui=N.UI
ui:CreateAwardHistoryContent(frame())
ok(#ui.awardHistoryRows==6 and
   ui.awardHistoryPageLabel.text:find("THIS RUN",1,true) and
   ui.awardHistoryRows[1].winner.text=="BotAC",
   "UI displays recent winner and six bounded review rows")
ui.awardHistoryAll.scripts.OnClick()
ok(ui.awardHistoryShowAll and
   ui.awardHistoryPageLabel.text:find("ALL",1,true),
   "All History toggle recovers pre-run entries")
ui.awardHistoryAll.scripts.OnClick()
ok(not ui.awardHistoryShowAll,"This Run toggle restores run filter")
local snapshot={
    gear=db.gearNeeds,lottery=db.lotteryHistory,
    award=db.lootAwardHistory,locks=db.awardAttemptLocks,
    wish=db.localWishlists,role=db.roleAssignments,
    settings=db.settings,receipt=db.lootReceiptTracker,
    inbox=db.submissionInbox,
}
ok(db.gearNeeds==plans and db.gearNeeds==snapshot.gear and
   db.lotteryHistory==snapshot.lottery and
   db.lootAwardHistory==snapshot.award and
   db.awardAttemptLocks==snapshot.locks and
   db.localWishlists==snapshot.wish and
   db.roleAssignments==snapshot.role and
   db.settings==snapshot.settings and
   db.lootReceiptTracker==snapshot.receipt and
   db.submissionInbox==snapshot.inbox and
   not db.settings.directMasterLootEnabled and
   not db.settings.guildLootTransfersEnabled and
   not db.settings.guildAutoPreviewEnabled and grant==0,
   "owner 636 plans, immutable physical history/roles and OFF consent untouched")
local num=0
for _ in pairs(db.gearNeeds)do num=num+1 end
ok(num==636,"NEVER reset current owner 636 to former 604 baseline")
print("PASS: "..n.." current 636-plan, archive/restore, winner ledger, new-run view, no grants")
