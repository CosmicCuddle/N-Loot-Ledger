-- Visual award-winner flow must not call GiveMasterLoot until BOTH user clicks.
local assertions=0
local function ok(v,m) assert(v,m);assertions=assertions+1 end
local awards=0
local updates=0
local notices={}
local now=100
GetTime=function()return now end
time=function()return 1800000000+now end
date=function()return "2026-10-17" end
UnitName=function()return "Leader" end
GetNumRaidMembers=function()return 40 end
GetLootMethod=function()return "master",nil,1 end
GetRaidRosterInfo=function(i) if i==1 then return "Leader",2 end end
GetNumLootItems=function()return 1 end
GetLootSlotLink=function(i) if i==1 then return "|Hitem:16800:0|h[Arcanist Boots]|h" end end
GetLootSlotInfo=function()return nil,nil,1,4,false end
GetMasterLootCandidate=function(i)if i==1 then return "Pikeotter" end end
GiveMasterLoot=function(slot,candidate) awards=awards+1;ok(slot==1 and candidate==1,"exact real slot/candidate") end
local function frame()
    local f={enabled=true,shown=false,scripts={}}
    function f:SetPoint(...)end
    function f:SetSize(...)end
    function f:SetWidth(...)end
    function f:SetFrameStrata(...)end
    function f:SetFrameLevel(...)end
    function f:GetFrameLevel()return 1 end
    function f:EnableMouse(...)end
    function f:SetBackdrop(...)end
    function f:SetBackdropColor(...)end
    function f:SetBackdropBorderColor(...)end
    function f:SetJustifyH(...)end
    function f:SetText(v)self.text=v end
    function f:SetScript(k,v)self.scripts[k]=v end
    function f:CreateFontString()return frame()end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=frame
local entry={dropUID="UID-A",slotIndex=1,itemID=16800,itemName="Arcanist Boots",
    raidKey="MOLTEN_CORE",boss="Lucifron",state="DETECTED"}
local finished={dropUID=entry.dropUID,itemID=entry.itemID,itemName=entry.itemName,
    raidKey=entry.raidKey,boss=entry.boss,winner="Pikeotter",winningTicket=1,
    selectionType="NEED",tier=1,status="COMPLETE",test=false}
NaxxLootLottery={
    db={settings={directMasterLootEnabled=false},lootAwardHistory={},gearNeeds={sentinel=true}},
    Print=function(_,x)notices[#notices+1]=x end,
    DebugSimulator={IsActive=function()return false end},
    LootDetection={lootOpen=true,GetCurrentLoot=function()return {entry} end},
    TicketLottery={
        liveLootObserved=true,
        AuthorityAllowed=function()return true end,
        GetActiveFor=function()return finished end,
    },
    LootIdentity={
        GetRow=function()return nil end,
        MarkAward=function(_,id,state)ok(id=="UID-A","audit right physical drop")end,
    },
    UI={currentLootSelected=1,mainFrame=frame(),
        RefreshCurrentLootPanel=function()updates=updates+1 end,
        RefreshOverview=function()end},
}
local N=NaxxLootLottery
local UI=N.UI
function UI:CreateTextButton(_,label,width)
    local btn=frame()
    btn.label=frame()
    btn.label:SetText(label)
    btn.width=width
    return btn
end
assert(loadfile("NaxxLootLottery/Core/AwardWorkflow.lua"))()
assert(loadfile("NaxxLootLottery/UI/AwardReviewFrame.lua"))()
local a=N.AwardWorkflow
ok(UI:OpenAwardReview(),"winner review dialog opens without a live dropdown")
ok(UI.awardReviewFrame.shown,"review visible to leader")
ok(not UI.awardReviewConfirm.enabled and not UI.awardReviewDirect.enabled,
    "old/stale dropdown can never activate a real transfer")
ok(awards==0 and #N.db.lootAwardHistory==0,
    "opening award review is strictly non-awarding")
UI.currentLootSelected=2
UI.awardReviewCheck.scripts.OnClick()
ok(not UI.awardReviewConfirm.enabled and not UI.awardReviewDirect.enabled and
    UI.awardReviewStatus.text:find("Selection changed",1,true),
    "reviewed recipient cannot silently switch to another selected item")
UI.currentLootSelected=1
LootFrame={selectedSlot=1,IsShown=function()return true end}
UI.awardReviewCheck.scripts.OnClick()
ok(UI.awardReviewConfirm.enabled and not UI.awardReviewDirect.enabled,
    "after live review, direct transfer still OFF by default")
ok(a.verification and a.verification.winner=="Pikeotter",
    "live candidate verified for exact winner")
ok(awards==0,"recheck alone does not award")
ok(a:SetDirectEnabled(true),"direct award enabling is separate user consent")
UI.awardReviewCheck.scripts.OnClick()
ok(UI.awardReviewDirect.enabled,"explicit enable PLUS recheck exposes arm action")
UI.awardReviewDirect.scripts.OnClick()
ok(awards==0 and a.verification.armedAt==now and
    UI.awardReviewDirect.label.text=="CONFIRM GIVE ITEM",
    "first deliberate click arms but cannot transfer")
UI.currentLootSelected=2
UI.awardReviewDirect.scripts.OnClick()
ok(awards==0 and a.verification==nil,
    "switching selected item AFTER arming cannot transfer another recipient")
UI.currentLootSelected=1
UI.awardReviewCheck.scripts.OnClick()
UI.awardReviewDirect.scripts.OnClick()
ok(awards==0 and a.verification and a.verification.armedAt==now,
    "new explicit review and arm required after selection drift")
UI.awardReviewDirect.scripts.OnClick()
ok(awards==1 and finished.awardStatus=="AWARD_REQUESTED",
    "second deliberate click requests exact transfer once")
ok(#N.db.lootAwardHistory==1 and
    N.db.lootAwardHistory[1].status=="AWARD_REQUESTED",
    "request is AUDITED but receipt remains explicitly unverified")
ok(N.db.gearNeeds.sentinel==true,"no Gear Plans ever modified")
ok(not UI.awardReviewFrame.shown,"review closes after attempted transfer")
ok(not UI:OpenAwardReview(),"a requested award is never offered a second time")
ok(awards==1,"review reopening cannot duplicate the loot transfer")
-- Regression: missing candidate/dropdown gives visible blocked context.
finished.awardStatus=nil
LootFrame=nil
a:SetDirectEnabled(false)
ok(UI:OpenAwardReview(),"stale corpse still displays review instructions")
ok(not UI.awardReviewDirect.enabled and awards==1,"no second transfer when live context missing")
UI.awardReviewCheck.scripts.OnClick()
ok(not UI.awardReviewConfirm.enabled and awards==1,
    "rechecking stale corpse keeps action blocked")
ok(updates>=2,"actions cause normal UI refresh")
print("PASS: "..assertions.." Award Winner review/arm/commit and stale-corpse assertions")
