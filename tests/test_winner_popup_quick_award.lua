-- Lua 5.1: optional ONE-CLICK winner transfer is explicitly opted in,
-- exact-live-context-only, never automatic after /roll and NEVER a receipt.
local n=0
local function ok(v,m) assert(v,m);n=n+1 end
local sends={}
local notices={}
local clock=100
local fake=false
local lootOpen=true
local link="|Hitem:16800:0|h[Arcanist Boots]|h"
local actualLink=link
local stack=1
local candidates={"Pikeotter"}
GetTime=function()return clock end
date=function()return "2026-10-31" end
UnitName=function()return "Leader" end
GetLootMethod=function()return "master",nil,1 end
GetRaidRosterInfo=function(i)if i==1 then return "Leader",2 end end
GetNumLootItems=function()return 1 end
GetLootSlotLink=function(i)if i==1 then return actualLink end end
GetLootSlotInfo=function()return nil,nil,stack,4,false end
GetMasterLootCandidate=function(i)return candidates[i] end
GiveMasterLoot=function(slot,candidate)
    sends[#sends+1]={slot=slot,candidate=candidate}
end
LootFrame={selectedSlot=1,IsShown=function()return lootOpen end}
local function frame()
    local f={enabled=true,shown=false,scripts={}}
    function f:SetPoint(...)end
    function f:SetSize(...)end
    function f:SetWidth(...)end
    function f:SetHeight(...)end
    function f:SetFrameStrata(...)end
    function f:SetFrameLevel(...)end
    function f:GetFrameLevel()return 1 end
    function f:EnableMouse(...)end
    function f:SetBackdrop(...)end
    function f:SetBackdropColor(...)end
    function f:SetBackdropBorderColor(...)end
    function f:SetJustifyH(...)end
    function f:SetText(t)self.text=t end
    function f:SetScript(t,cb)self.scripts[t]=cb end
    function f:CreateFontString()return frame()end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:IsShown()return self.shown end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=function()return frame()end
local entry={dropUID="UID-QUICK",slotIndex=1,itemID=16800,
    itemLink=link,quantity=1,itemName="Arcanist Boots",
    raidKey="MOLTEN_CORE",boss="Lucifron"}
local winner={dropUID=entry.dropUID,itemID=entry.itemID,
    itemName=entry.itemName,winner="Pikeotter",winningTicket=1,
    selectionType="NEED",tier=1,status="COMPLETE",test=false}
local db={settings={directMasterLootEnabled=false,
    winnerQuickAwardEnabled=false},gearNeeds={old={status="NEEDED"}},
    lootAwardHistory={},awardAttemptLocks={}}
NaxxLootLottery={
    db=db,
    Print=function(_,msg)notices[#notices+1]=tostring(msg)end,
    DebugSimulator={IsActive=function()return fake end},
    TicketLottery={liveLootObserved=true,
        AuthorityAllowed=function()return true end,
        GetActiveFor=function()return winner end},
    LootDetection={GetCurrentLoot=function()return {entry}end},
    LootIdentity={GetRow=function()return nil end,
        MarkAward=function()end},
    UI={currentLootSelected=1,mainFrame=frame(),
        ShowMainFrame=function(self)self.mainFrame:Show()end,
        RefreshCurrentLootPanel=function()end,
        RefreshOverview=function()end},
}
local N=NaxxLootLottery
local UI=N.UI
UI.mainFrame:Show()
function UI:CreateTextButton(_,label,width)
    local f=frame()
    f.label=frame()
    f.label:SetText(label)
    f.width=width
    return f
end
assert(loadfile("NaxxLootLottery/Core/AwardWorkflow.lua"))()
assert(loadfile("NaxxLootLottery/UI/WinnerAnnouncement.lua"))()
local A=N.AwardWorkflow
local function show(sim)
    return UI:ShowWinnerAnnouncement("Arcanist Boots","Pikeotter",1,
        sim,"NEED",1,"UID-QUICK")
end
ok(show(false) and not UI.winnerQuickAwardButton.enabled,
    "quick physical award is invisible to consent until separately enabled")
ok(UI.winnerReviewAwardButton.enabled,
    "previous Review Award workflow remains available")
ok(#sends==0,"popup showing NEVER awards loot")
ok(not A:SetQuickEnabled(true),
    "Master Loot selection alone cannot authorise quick award")
ok(A:SetDirectEnabled(true) and not A:IsQuickEnabled(),
    "ordinary direct consent does not silently enable one-click")
ok(A:SetQuickEnabled(true) and A:IsQuickEnabled(),
    "quick award needs separate deliberate consent")
ok(show(false) and UI.winnerQuickAwardButton.enabled,
    "pinned live winner exposes one-click award after dual opt-in")
ok(#sends==0,"enabling quick setting never auto-awards a winner")
UI.currentLootSelected=2
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0 and N.db.gearNeeds.old.status=="NEEDED",
    "selection drift blocks quick transfer and cannot mark obtained")
UI.currentLootSelected=1
show(false)
actualLink="|Hitem:16800:1|h[Arcanist Boots]|h"
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0 and not A.verification,
    "different enchant/link same itemID cannot be awarded quickly")
actualLink=link
stack=2
show(false)
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0,"stack count mismatch blocks quick transfer")
stack=1
candidates={"Pikeotter","Pikeotter"}
show(false)
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0,"duplicate same-name candidates cannot be guessed")
candidates={"Pikeotter"}
lootOpen=false
show(false)
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0,"closed Blizzard Master Loot window cannot give an item")
lootOpen=true
fake=true
show(true)
ok(not UI.winnerQuickAwardButton.enabled and not A:SetQuickEnabled(true),
    "simulations cannot enable or show physical quick award")
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0,"forcing simulated button callback never gives a real item")
fake=false
show(false)
ok(UI.winnerQuickAwardButton.enabled,"real winner re-enables opted-in button")
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==1 and sends[1].slot==1 and sends[1].candidate==1,
    "one deliberate click sends ONLY exact selected item to exact winner")
ok(not UI.winnerAnnouncement.shown and
    winner.awardStatus=="AWARD_REQUESTED",
    "winner popup closes only after real request is recorded")
ok(#N.db.lootAwardHistory==1 and
   N.db.lootAwardHistory[1].status=="AWARD_REQUESTED" and
   N.db.awardAttemptLocks["UID-QUICK"] and
   N.db.gearNeeds.old.status=="NEEDED",
   "request is audited/no-retry; no fake receipt or OBTAINED")
show(false)
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==1,"same popup/drop cannot send a second Master Loot request")
ok(A:SetDirectEnabled(false) and not A:IsQuickEnabled() and
   not db.settings.winnerQuickAwardEnabled,
   "disabling direct award immediately disarms quick transfer")
show(false)
ok(not UI.winnerQuickAwardButton.enabled and #sends==1,
   "popup quick control cannot remain enabled after consent revoked")
print("PASS: "..n.." one-click physical award opt-in, wrong-target, fake, no-retry checks")
