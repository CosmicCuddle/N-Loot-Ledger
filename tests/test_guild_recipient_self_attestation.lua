-- Lua 5.1: separate recipient-owned bag statement (NOT a Master Loot receipt).
-- All WoW APIs mocked; zero real awards, zero source verification claims.
local checks=0
local function ok(v,m)assert(v,m);checks=checks+1 end
local clock=100
local name="Leader"
local fake=false
local owned={ [17010]=3,[17011]=1,[17012]=2,[17013]=1 }
local awarded=0
GetTime=function()return clock end
UnitName=function()return name end
date=function()return "2026-10-18" end
GetItemCount=function(id,bank,charges)
    ok(bank==false and charges==false,"own bags only, no bank or charge estimate")
    return owned[id] or 0
end
GiveMasterLoot=function()awarded=awarded+1;error("Never GIVE")end
RandomRoll=function()awarded=awarded+1;error("Never roll")end
local guild={
    {itemID=17010,itemLink="|Hitem:17010:0|h[Fiery Core]|h",
     quantity=2,slotIndex=1,recipient="Leader",operator="Leader",
     status="LOOT_SLOT_CLEARED",when="2026-10-18",note="Original unknown"},
    {itemID=17011,itemLink="|Hitem:17011:0|h[Lava Core]|h",
     quantity=1,slotIndex=2,recipient="Another",status="AWARD_REQUESTED"},
    {itemID=17012,itemLink="|Hitem:17012:0|h[Core Leather]|h",
     quantity=2,slotIndex=3,recipient="Leader",
     status="AWARD_OUTCOME_UNKNOWN"},
    {itemID=17013,itemLink="|Hitem:17013:0|h[Old Material]|h",
     quantity=1,slotIndex=4,recipient="Leader",
     status="AWARD_REQUESTED",reconciliationStatus="CLOSED_NO_RETRY"},
    {itemID=17014,itemLink="|Hitem:17014:0|h[Another]|h",
     quantity=1,slotIndex=5,recipient="Leader",status="AWARD_REQUESTED"},
    {itemID=17010,itemLink="|Hitem:17010:0|h[Fiery Core]|h",
     quantity=2,slotIndex=6,recipient="Leader",status="AWARD_OUTCOME_UNKNOWN"},
    {itemID=17010,itemLink="|Hitem:17010:0|h[Fiery Core]|h",
     quantity=2,slotIndex=7,recipient="Leader",status="AWARD_REQUESTED"},
}
local savedGear={throgar={character="Throgar",itemID=17010,status="NEEDED"}}
local saveLocal={Leader={MOLTEN_CORE={[17010]=true}}}
local receiptBook={old={itemID=17010,status="WON_AWAITING_ITEM"}}
local original={version=1,gearNeeds=savedGear,localWishlists=saveLocal,
    lootReceiptTracker=receiptBook,lootAwardHistory={},
    guildLootTransferAudit=guild,lootReconciliationAudit={},
    awardAttemptLocks={["L1:1:17010"]={status="AWARD_REQUESTED"}}}
NaxxLootLotteryDB=original
NaxxLootLottery={
    databaseVersion=1,DebugSimulator={IsActive=function()return fake end},
    TicketLottery={liveLootObserved=true},
    UI={},Data={},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Storage/Database.lua"))()
N.Database:Initialize()
assert(loadfile("NaxxLootLottery/Core/GuildRecipientReceipt.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
local R=N.GuildRecipientReceipt
local T=N.GuildLootTransfer
local attest=N.db.guildRecipientReceiptAudit
ok(N.db==original and #attest==0 and T:IsUnresolved(),
   "saved account table preserved, cleared slot still unresolved")
ok(not N.db.settings.directMasterLootEnabled and
   not N.db.settings.guildLootTransfersEnabled,
   "all physical transfer switches reset OFF")
local list=R:List()
ok(#list==7 and list[1].auditIndex==1 and not list[1].selfAttested,
   "recipient ledger initially read-only and all past requests listed")
ok(not R:CanAttest(0) and not R:CanAttest(1.5) and
   not R:CanAttest("1") and not R:CanAttest(999),
   "invalid/ambiguous historical audit indices never accepted")
ok(not R:CanAttest(2),
   "only intended player can assert their OWN historical request")
ok(not R:CanAttest(5),
   "item missing from own bags cannot be falsely attested")
fake=true
ok(not R:Arm(1),"simulation cannot attest real item delivery")
fake=false
local can,msg=R:Arm(1)
ok(can and R.armed and #attest==0,
   "first click arms and does not yet create a persisted assertion")
name="Officer"
can,msg=R:Confirm()
ok(not can and #attest==0 and not R.armed,
   "change of character cancels confirmation, no other person can attest")
name="Leader"
ok(R:Arm(1),"legitimate recipient may arm")
clock=clock+16
can,msg=R:Confirm()
ok(not can and #attest==0 and not R.armed,
   "15-second expiry produces no audit")
clock=clock+1
ok(R:Arm(1),"recipient can rearm after timeout")
guild[1].itemID=17011
can,msg=R:Confirm()
ok(not can and #attest==0,
   "audit tampering during arm cancels instead of recording")
guild[1].itemID=17010
ok(R:Arm(1),"recipient can arm untampered transfer")
owned[17010]=0
can,msg=R:Confirm()
ok(not can and #attest==0,
   "bag count disappearing during arming cancels")
owned[17010]=3
ok(R:Arm(1),"recipient may confirm current bag count")
can,msg=R:Confirm()
ok(can and #attest==1 and attest[1].auditIndex==1 and
   attest[1].action=="RECIPIENT_SELF_ATTESTED_BAGS",
   "separate append-only receipt statement recorded by its audit index")
ok(attest[1].actor=="Leader" and attest[1].observedBagCount==3 and
   not attest[1].sourceVerified and
   not attest[1].deliveryServerVerified and
   not attest[1].grantsAuthorized,
   "self-checked inventory is explicitly NOT WoW delivery source proof")
ok(guild[1].status=="LOOT_SLOT_CLEARED" and
   guild[1].note=="Original unknown" and T:IsUnresolved() and
   not guild[1].reconciliationStatus,
   "recipient statement NEVER changes original result or global transfer gate")
ok(R:IsRecorded(1) and not R:Arm(1) and #attest==1,
   "duplicate confirmation against same audit row is blocked")
ok(not R:Confirm(),"unarmed repeat confirmation cannot alter history")
ok(R:Arm(4),"NO RETRY row may separately collect recipient evidence")
ok(R:Confirm(),"attestation can coexist with NO RETRY without undoing it")
ok(guild[4].reconciliationStatus=="CLOSED_NO_RETRY" and
   guild[4].status=="AWARD_REQUESTED" and #attest==2,
   "NO RETRY is retained when separate bag evidence is appended")
N.db=nil
N.Database:Initialize()
ok(N.db==original and N.db.guildRecipientReceiptAudit==attest and
   #attest==2 and R:IsRecorded(1) and not R.armed,
   "reload preserves audit, disarms confirmation and never resets saved data")

-- Validate paged, non-awarding window and exact target switching.
local function frame()
    local f={enabled=true,shown=false,events={}}
    function f:SetPoint(...)end
    function f:SetSize(...)end
    function f:SetWidth(...)end
    function f:SetHeight(...)end
    function f:GetFrameLevel()return 1 end
    function f:SetFrameLevel(...)end
    function f:SetFrameStrata(...)end
    function f:EnableMouse(...)end
    function f:SetBackdrop(...)end
    function f:SetBackdropColor(...)end
    function f:SetBackdropBorderColor(...)end
    function f:SetText(t)self.text=t end
    function f:SetJustifyH(...)end
    function f:CreateFontString()return frame()end
    function f:SetScript(k,fn)self.events[k]=fn end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=frame
N.UI.mainFrame=frame()
function N.UI:CreateTextButton(_,label,width)
    local button=frame()
    button.label=frame()
    button.label:SetText(label)
    return button
end
function N.UI:RegisterSkinnedFrame()end
assert(loadfile("NaxxLootLottery/UI/GuildRecipientReceiptFrame.lua"))()
local UI=N.UI
UI:OpenGuildRecipientReceiptDialog()
ok(UI.guildRecipientReceiptDialog.shown and #UI.guildReceiptRows==5 and
   UI.guildReceiptPages.text=="Page 1/2 (7)",
   "separate self-inventory modal paginates audit rows")
ok(not UI.guildReceiptArm.enabled and not UI.guildReceiptConfirm.enabled,
   "opening never silently arms receipt/authorization")
UI.guildReceiptRows[1].select.events.OnClick(UI.guildReceiptRows[1].select)
ok(UI.guildReceiptSelected==1 and not UI.guildReceiptArm.enabled,
   "already attested record is visible but cannot be attested twice")
UI:OpenGuildRecipientReceiptDialog(6)
ok(UI.guildReceiptPage==2 and UI.guildReceiptSelected==6 and
   UI.guildReceiptArm.enabled,
   "UI may target correct audit index even when itemID duplicates")
UI.guildReceiptArm.events.OnClick()
ok(R.armed and UI.guildReceiptConfirm.enabled and #attest==2,
   "first button only arms; second separate button still needed")
UI.guildReceiptPrev.events.OnClick()
ok(not R.armed and not UI.guildReceiptConfirm.enabled and
   UI.guildReceiptSelected==nil,
   "paging cancels the previously armed receipt")
UI:OpenGuildRecipientReceiptDialog(6)
UI.guildReceiptArm.events.OnClick()
UI.guildReceiptClose.events.OnClick()
ok(not R.armed and not UI.guildRecipientReceiptDialog.shown and #attest==2,
   "closing modal cancels arming without an audit event")
UI:OpenGuildRecipientReceiptDialog(6)
UI.guildReceiptArm.events.OnClick()
UI.guildReceiptConfirm.events.OnClick()
ok(#attest==3 and R:IsRecorded(6) and guild[6].status=="AWARD_OUTCOME_UNKNOWN",
   "second human click saves only the matching original audit index")
ok(N.db==original and N.db.gearNeeds==savedGear and
   N.db.localWishlists==saveLocal and N.db.lootReceiptTracker==receiptBook and
   original.awardAttemptLocks["L1:1:17010"].status=="AWARD_REQUESTED" and
   #original.lootReconciliationAudit==0 and awarded==0,
   "winner receipts, wishlist, 604-style Gear Plans, locks and game items unaltered")
print("PASS: "..checks.." self-attestation, dual-click UI and NO RETRY separation")
