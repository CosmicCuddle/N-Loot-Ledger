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
candidates={"Pikeotter-OtherRealm"}
show(false)
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0,"realm-stripped recipient alias is not exact proof")
candidates={"Pikeotter"}
local savedClock=GetTime
GetTime=function()return nil end
show(false)
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0,"missing client clock fails closed")
GetTime=savedClock
local originalLootMethod=GetLootMethod
GetLootMethod=function()return "group",nil,1 end
show(false)
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0,"master loot OFF in Blizzard cannot be bypassed")
GetLootMethod=originalLootMethod
local originalRoster=GetRaidRosterInfo
GetRaidRosterInfo=function(i)if i==1 then return "OtherMaster",2 end end
show(false)
UI.winnerQuickAwardButton.scripts.OnClick()
ok(#sends==0,"wrong designated Master Looter cannot quick-award")
GetRaidRosterInfo=originalRoster
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
-- A SavedVariables reload never restores a previous dangerous opt-in.
NaxxLootLotteryDB=db
N.databaseVersion=1
assert(loadfile("NaxxLootLottery/Storage/Database.lua"))()
N.Database:Initialize()
ok(N.db==db and not db.settings.directMasterLootEnabled and
   not db.settings.winnerQuickAwardEnabled and
   db.gearNeeds.old.status=="NEEDED" and #sends==1,
   "login/reload revokes both physical consent flags and preserves Gear Plans")
-- New guild-only route must reverify the CURRENT leader at award time.
-- It cannot borrow a previously completed one-ticket win after a leader
-- change, even with both physical consents explicitly enabled.
A.liveRequests={}
entry.dropUID="UID-GUILD"
entry.itemID=17011
entry.itemName="Lava Core"
entry.itemLink="|Hitem:17011:0|h[Lava Core]|h"
entry.quantity=1
actualLink=entry.itemLink
finished.dropUID=entry.dropUID
finished.itemID=entry.itemID
finished.itemName=entry.itemName
finished.selectionType="GUILD"
finished.awardStatus=nil
local liveLeader="Other"
N.GuildLootReview={
    IsGuildMaterial=function(_,id)return id==17011 end,
    LeaderTicketRecipient=function()
        if liveLeader=="BLOCKED" then
            return nil,"Previous physical award for this material. NO RETRY."
        end
        return liveLeader
    end,
}
ok(A:SetDirectEnabled(true) and A:SetQuickEnabled(true),
    "guild physical award still requires both opt-ins")
local sent,why=A:QuickAward("UID-GUILD","Pikeotter")
ok(not sent and why:find("raid leader",1,true) and #sends==1,
    "leader changed after guild ticket: no real award")
ok(not A:Review(entry) and #sends==1,
    "standard two-stage Review Award cannot bypass guild leader drift")
liveLeader="BLOCKED"
sent,why=A:QuickAward("UID-GUILD","Pikeotter")
ok(not sent and why:find("NO RETRY",1,true) and #sends==1,
    "previous material attempt guard enforced again at physical transfer")
liveLeader="Pikeotter"
candidates={"Pikeotter-OtherRealm"}
ok(not A:Review(entry) and #sends==1,
    "guild Review Award refuses same short name from another realm")
candidates={"Pikeotter","Pikeotter"}
ok(not A:Review(entry) and #sends==1,
    "guild Review Award refuses duplicate exact recipient candidates")
candidates={"Pikeotter"}
sent,why=A:QuickAward("UID-GUILD","Pikeotter")
ok(sent and #sends==2 and sends[2].slot==1 and
   sends[2].candidate==1 and db.gearNeeds.old.status=="NEEDED",
    "verified live raid leader can receive exactly one guild material request")
sent=A:QuickAward("UID-GUILD","Pikeotter")
ok(not sent and #sends==2,
    "guild-only winner cannot be physically awarded a second time")
print("PASS: "..n.." one-click award, guild leader drift and no-retry checks")
