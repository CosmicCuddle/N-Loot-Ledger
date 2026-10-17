-- Historical Guild Transfer Audit dialog: paging and two-step human
-- receipt verification. No GiveMasterLoot and no new item generation.
local checks=0
local function ok(v,m)assert(v,m);checks=checks+1 end
local clock=100
GetTime=function()return clock end
UnitName=function()return "Leader" end
date=function()return "2026-10-17" end
local actions=0
GiveMasterLoot=function()actions=actions+1;error("must stay zero")end
local function frame()
    local x={events={},shown=false,enabled=true}
    function x:SetPoint(...)self.point={...}end
    function x:SetSize(w,h)self.width=w;self.height=h end
    function x:SetWidth(w)self.width=w end
    function x:SetHeight(h)self.height=h end
    function x:SetFrameStrata(...)end
    function x:SetFrameLevel(...)end
    function x:GetFrameLevel()return 1 end
    function x:EnableMouse(...)end
    function x:SetBackdrop(...)end
    function x:SetBackdropColor(...)end
    function x:SetBackdropBorderColor(...)end
    function x:SetJustifyH(...)end
    function x:SetText(t)self.text=t end
    function x:SetScript(k,fn)self.events[k]=fn end
    function x:CreateFontString()return frame()end
    function x:Enable()self.enabled=true end
    function x:Disable()self.enabled=false end
    function x:Show()self.shown=true end
    function x:Hide()self.shown=false end
    return x
end
CreateFrame=frame
local entries={}
for i=1,6 do
    entries[i]={
        itemID=17000+i,itemLink="|Hitem:"..(17000+i).."|h[Material]|h",
        slotIndex=i,recipient="Leader",actor="Leader",
        status=i==3 and "RECONCILED_RECEIVED" or "AWARD_OUTCOME_UNKNOWN",
        quantity=1,when="earlier"
    }
end
NaxxLootLottery={
    db={guildLootTransferAudit=entries,guildLootReconciliations={}},
    UI={mainFrame=frame()},
    GuildLootTransfer={review=nil},
    TicketLottery={active=nil},
    DebugSimulator={IsActive=function()return false end},
    Print=function()end
}
local N=NaxxLootLottery
local UI=N.UI
function UI:CreateTextButton(_,label,width)
    local o=frame()
    o.label=frame()
    o.label:SetText(label)
    o.width=width
    return o
end
function UI:RegisterSkinnedFrame()end
assert(loadfile("NaxxLootLottery/Core/GuildLootReconcile.lua"))()
assert(loadfile("NaxxLootLottery/UI/GuildReconciliationFrame.lua"))()
UI:OpenGuildReconciliation()
ok(UI.guildReconciliationFrame.shown and
    UI.guildReconciliationPageText.text=="Page 1 / 2",
    "audit visible with enough rows for a second page")
ok(not UI.guildReconciliationCommit.enabled and
   not UI.guildReconciliationReceived.enabled,
   "no receipt may be confirmed without inspection")
ok(not UI.guildReconciliationRows[3].inspect.enabled,
    "already reconciled record never exposes Inspect")
UI.guildReconciliationCommit.events.OnClick()
ok(#N.db.guildLootReconciliations==0,
    "direct Confirm with no arm never changes history")
local inspect=UI.guildReconciliationRows[1].inspect
inspect.events.OnClick(inspect)
ok(UI.guildReconciliationReceived.enabled and
    not UI.guildReconciliationCommit.enabled,
    "Inspect only enables first stage; it does not mark received")
UI.guildReconciliationReceived.events.OnClick()
ok(UI.guildReconciliationCommit.enabled and
    #N.db.guildLootReconciliations==0,
    "Verified Received arm requires separate final click")
UI.guildReconciliationNext.events.OnClick()
ok(UI.guildReconciliationPageText.text=="Page 2 / 2" and
    not UI.guildReconciliationCommit.enabled,
    "page switch disarms outstanding confirmation")
UI.guildReconciliationRows[1].inspect.events.OnClick(
    UI.guildReconciliationRows[1].inspect)
ok(UI.guildReconciliationReceived.enabled,
    "second page offers valid sixth historical record")
UI.guildReconciliationHold.events.OnClick()
UI.guildReconciliationCommit.events.OnClick()
ok(entries[6].status=="INVESTIGATION_HOLD" and
    #N.db.guildLootReconciliations==1,
    "explicit Hold records unresolved outcome without granting item")
UI.guildReconciliationPrev.events.OnClick()
UI.guildReconciliationRows[1].inspect.events.OnClick(
    UI.guildReconciliationRows[1].inspect)
UI.guildReconciliationReceived.events.OnClick()
clock=clock+16
UI.guildReconciliationCommit.events.OnClick()
ok(entries[1].status=="AWARD_OUTCOME_UNKNOWN" and
    #N.db.guildLootReconciliations==1,
    "15-second expiry prevents stale receipt confirmation")
UI.guildReconciliationRows[1].inspect.events.OnClick(
    UI.guildReconciliationRows[1].inspect)
UI.guildReconciliationReceived.events.OnClick()
UI.guildReconciliationCommit.events.OnClick()
ok(entries[1].status=="RECONCILED_RECEIVED" and
    #N.db.guildLootReconciliations==2,
    "explicit second click records manually checked recipient receipt")
UI.guildReconciliationRows[1].inspect.events.OnClick(
    UI.guildReconciliationRows[1].inspect)
ok(not UI.guildReconciliationReceived.enabled,
    "already-reconciled item cannot be armed for repeated confirmation")
UI.guildReconciliationClose.events.OnClick()
ok(not UI.guildReconciliationFrame.shown and
    N.GuildLootReconcile.review==nil,
    "closing audit drops all transient review consent")
ok(actions==0,"historical audit cannot call GiveMasterLoot")
print("PASS: "..checks.." historical guild reconciliation UI gating assertions")
