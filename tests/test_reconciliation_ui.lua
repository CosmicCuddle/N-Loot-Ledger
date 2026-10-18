-- WoW 3.3.5a Lua 5.1 mocked UI: reconciliation never awards physical items.
local assertions=0
local function ok(value,message)assert(value,message);assertions=assertions+1 end
local now=100
local actor="Leader"
local authorized=true
local fake=false
local physical=0
GetTime=function()return now end
UnitName=function()return actor end
date=function()return "2026-10-18" end
GiveMasterLoot=function()physical=physical+1;error("UI must not award")end
local function frame()
    local f={shown=false,enabled=true,events={}}
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
    function f:SetAllPoints(...)end
    function f:SetJustifyH(...)end
    function f:SetText(t)self.text=t end
    function f:GetText()return self.text end
    function f:CreateFontString()return frame()end
    function f:SetScript(n,fn)self.events[n]=fn end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=frame
local originalNeeds={Throgar={itemID=16800,status="NEEDED"}}
local originalWishlist={Pikeotter={MOLTEN_CORE={[16800]=true}}}
local award={}
for i=1,7 do
    award[i]={dropUID="L"..i..":1:16800",itemID=16800,
        itemName="Arcanist Boots",winner="Pikeotter",
        status="AWARD_OUTCOME_UNKNOWN"}
end
local guild={
    {itemID=17010,slotIndex=1,recipient="Leader",status="AWARD_REQUESTED"},
}
local receipts={["L7:1:16800"]={
    status="OBTAINED",itemID=16800,character="Pikeotter"}}
local audit={}
local locks={["L1:1:16800"]={status="AWARD_OUTCOME_UNKNOWN"}}
NaxxLootLottery={
    db={lootAwardHistory=award,guildLootTransferAudit=guild,
        lootReceiptTracker=receipts,lootReconciliationAudit=audit,
        awardAttemptLocks=locks,gearNeeds=originalNeeds,
        localWishlists=originalWishlist},
    TicketLottery={AuthorityAllowed=function()return authorized end},
    DebugSimulator={IsActive=function()return fake end},
    LootReceiptTracker={Get=function(_,uid)return receipts[uid] end},
    Print=function()end,
    UI={mainFrame=frame()},
}
local N=NaxxLootLottery
local UI=N.UI
function UI:CreateTextButton(_,label,width)
    local b=frame()
    b.label=frame()
    b.label:SetText(label)
    return b
end
function UI:RegisterSkinnedFrame()end
assert(loadfile("NaxxLootLottery/Core/LootReconciliation.lua"))()
assert(loadfile("NaxxLootLottery/UI/ReconciliationFrame.lua"))()
local R=N.LootReconciliation
UI:OpenReconciliationDialog()
ok(UI.reconciliationDialog.shown and #UI.reconciliationRows==5,
    "investigation opens independent paged modal")
ok(UI.reconciliationPageLabel.text=="Page 1/2 (8)" and
    not UI.reconciliationArm.enabled and not UI.reconciliationConfirm.enabled,
    "opening cannot arm, complete, change winner or award")
local first=UI.reconciliationRows[1]
ok(first.name.text:find("WINNER",1,true) and
    first.detail.text:find("recipient receipt unverified",1,true),
    "state and recipient uncertainty shown accurately")
first.pick.events.OnClick(first.pick)
ok(UI.reconciliationArm.enabled and not UI.reconciliationConfirm.enabled and
    UI.reconciliationSelected.id=="L1:1:16800",
    "selection alone never arms")
UI.reconciliationArm.events.OnClick()
ok(R.armed and UI.reconciliationConfirm.enabled and #audit==0 and
    first.detail.text:find("unverified",1,true),
    "first confirmation only arms, audit remains empty")
-- Changing selection MUST disarm, without using stale arming.
UI.reconciliationRows[2].pick.events.OnClick(UI.reconciliationRows[2].pick)
ok(not R.armed and not UI.reconciliationConfirm.enabled and #audit==0,
    "different row cancels previous two-click consent")
UI.reconciliationConfirm.events.OnClick()
ok(not R.armed and #audit==0,"forged disabled click cannot commit old selection")
UI.reconciliationArm.events.OnClick()
ok(R.armed and #audit==0,"new row can arm explicitly")
UI.reconciliationNext.events.OnClick()
ok(not R.armed and UI.reconciliationSelected==nil and
    UI.reconciliationPageLabel.text=="Page 2/2 (8)" and
    not UI.reconciliationConfirm.enabled,
    "page change invalidates pending confirmation")
ok(UI.reconciliationRows[2].detail.text:find("Recipient receipt OBTAINED",1,true),
    "confirmed separate receipt displayed without allowing no-retry closure")
UI.reconciliationRows[2].pick.events.OnClick(UI.reconciliationRows[2].pick)
ok(not UI.reconciliationArm.enabled and not UI.reconciliationConfirm.enabled,
    "cannot review a verified receipt as uncertain")
UI:OpenReconciliationDialog("GUILD",1)
ok(UI.reconciliationSelected and UI.reconciliationSelected.kind=="GUILD" and
    UI.reconciliationPage==2,"opening from targeted guild audit selects exact row")
UI.reconciliationArm.events.OnClick()
ok(UI.reconciliationConfirm.enabled and R.armed.kind=="GUILD",
    "guild entry can be armed through same no-retry workflow")
now=now+16
UI:RefreshReconciliationDialog()
ok(not UI.reconciliationConfirm.enabled,"expired arm visibly disables confirmation")
UI.reconciliationConfirm.events.OnClick()
ok(#audit==0 and not R.armed,"expired even forced action never mutates history")
now=now+1
UI.reconciliationArm.events.OnClick()
authorized=false
UI.reconciliationConfirm.events.OnClick()
ok(#audit==0 and not R.armed,"lost raid authority blocks modal commit")
authorized=true
UI.reconciliationArm.events.OnClick()
UI.reconciliationConfirm.events.OnClick()
ok(#audit==1 and guild[1].reconciliationStatus=="CLOSED_NO_RETRY" and
    guild[1].status=="AWARD_REQUESTED",
    "manual guild investigation adds audit without changing original outcome")
ok(not UI.reconciliationArm.enabled and not UI.reconciliationConfirm.enabled,
    "reviewed entry cannot be closed a second time")
UI:OpenReconciliationDialog("WINNER","L1:1:16800")
ok(UI.reconciliationSelected.id=="L1:1:16800" and UI.reconciliationArm.enabled,
    "targeted winner opens at exact UID, not nearby same item ID")
UI.reconciliationArm.events.OnClick()
UI.reconciliationClose.events.OnClick()
ok(not UI.reconciliationDialog.shown and not R.armed and #audit==1,
    "closing modal cancels arming without writing audit")
UI:OpenReconciliationDialog("WINNER","L1:1:16800")
UI.reconciliationArm.events.OnClick()
fake=true
UI.reconciliationConfirm.events.OnClick()
ok(#audit==1 and not R.armed,"fake raid cannot confirm an armed real review")
fake=false
UI.reconciliationArm.events.OnClick()
UI.reconciliationConfirm.events.OnClick()
ok(#audit==2 and award[1].reconciliationStatus=="CLOSED_NO_RETRY" and
    award[1].status=="AWARD_OUTCOME_UNKNOWN",
    "winner review closure is NO RETRY, NEVER OBTAINED")
ok(receipts["L7:1:16800"].status=="OBTAINED" and
    originalNeeds.Throgar.status=="NEEDED" and
    originalWishlist.Pikeotter.MOLTEN_CORE[16800]==true and
    N.db.awardAttemptLocks==locks and physical==0,
    "no receipt, saved Gear Plan, local wishlist, attempt lock or physical API altered")
print("PASS: "..assertions.." paged investigation UI, expiry, selection guards and zero-award assertions")
