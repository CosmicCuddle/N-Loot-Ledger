-- Guild receipt UI can review past corpses but NEVER gives physical loot.
local checks=0
local function ok(v,msg)assert(v,msg);checks=checks+1 end
local now=101
local actor="Leader"
GetTime=function()return now end
UnitName=function()return actor end
date=function()return "2026-10-18" end
local awards=0
GiveMasterLoot=function()awards=awards+1;error("forbidden")end
local function frame()
    local f={events={},shown=false,enabled=true}
    function f:SetPoint(...)end
    function f:SetSize(...)end
    function f:SetWidth(...)end
    function f:SetHeight(...)end
    function f:SetText(v)self.text=v end
    function f:SetJustifyH(...)end
    function f:SetFrameStrata(...)end
    function f:SetFrameLevel(...)end
    function f:GetFrameLevel()return 1 end
    function f:EnableMouse(...)end
    function f:SetBackdrop(...)end
    function f:SetBackdropColor(...)end
    function f:SetBackdropBorderColor(...)end
    function f:CreateFontString()return frame()end
    function f:SetScript(k,fn)self.events[k]=fn end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    return f
end
CreateFrame=frame
local entries={}
for i=1,7 do
    entries[i]={itemID=17010+i,itemLink="|Hitem:"..(17010+i).."|h[Core]|h",
        slotIndex=i,recipient="Leader",quantity=1,status="LOOT_SLOT_CLEARED"}
end
NaxxLootLottery={
    db={guildLootTransferAudit=entries},
    DebugSimulator={IsActive=function()return false end},
    GuildLootTransfer={liveRequests={}},
    Print=function()end,
    UI={mainFrame=frame()}
}
local N=NaxxLootLottery
function N.UI:RegisterSkinnedFrame()end
function N.UI:CreateTextButton(_,label,width)
    local f=frame()
    f.label=frame()
    f.label:SetText(label)
    return f
end
assert(loadfile("NaxxLootLottery/Core/GuildLootReconciliation.lua"))()
assert(loadfile("NaxxLootLottery/UI/GuildReconciliationFrame.lua"))()
local UI=N.UI
local R=N.GuildLootReconciliation
UI:OpenGuildReconciliationReview()
ok(UI.guildReconcileFrame.shown and UI.guildReconcilePageText.text=="Page 1/2 (7 requests)",
    "saved guild receipt screen opens after corpse despawn")
ok(not UI.guildReconcileConfirm.enabled and not UI.guildReconcileInspect.enabled,
    "no audit selected, so neither confirmation control can act")
UI.guildReconcileRows[1].chooseButton.events.OnClick(
    UI.guildReconcileRows[1].chooseButton)
ok(UI.guildReconcileIndex==1 and UI.guildReconcileInspect.enabled and
    not UI.guildReconcileConfirm.enabled,
    "selecting audit only enables first inventory check")
UI.guildReconcileConfirm.events.OnClick()
ok(entries[1].status=="LOOT_SLOT_CLEARED",
    "confirm callback bypass must not update before first click")
UI.guildReconcileInspect.events.OnClick()
ok(UI.guildReconcileConfirm.enabled and entries[1].status=="LOOT_SLOT_CLEARED",
    "first click only arms proof for exact selected request")
UI.guildReconcileNext.events.OnClick()
ok(UI.guildReconcilePageText.text=="Page 2/2 (7 requests)" and
    not UI.guildReconcileConfirm.enabled,
    "switching page cancels original receipt selection")
UI.guildReconcilePrev.events.OnClick()
UI.guildReconcileRows[1].chooseButton.events.OnClick(
    UI.guildReconcileRows[1].chooseButton)
UI.guildReconcileInspect.events.OnClick()
now=now+16
UI.guildReconcileConfirm.events.OnClick()
ok(entries[1].status=="LOOT_SLOT_CLEARED",
    "expired second click cannot mark item received")
UI.guildReconcileInspect.events.OnClick()
UI.guildReconcileConfirm.events.OnClick()
ok(entries[1].status=="RECIPIENT_CONFIRMED" and
    not UI.guildReconcileConfirm.enabled,
    "only second deliberate confirmation updates audit, never awards")
ok(entries[2].status=="LOOT_SLOT_CLEARED" and
    not UI.guildReconcileRows[1].chooseButton.enabled,
    "confirmed audit is locked and other items remain uncertain")
UI.guildReconcileClose.events.OnClick()
ok(not UI.guildReconcileFrame.shown and R.armed==nil,
    "closing audit screen disarms any pending confirmation")
ok(awards==0,"receipt review UI never calls GiveMasterLoot")
print("PASS: "..checks.." post-raid reconciliation UI two-click/expiry/pagination assertions")
