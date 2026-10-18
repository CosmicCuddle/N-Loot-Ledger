-- WoW 3.3.5a Lua 5.1: explicit two-click bot Gear Plan review.
local checks=0
local function ok(v,why)assert(v,why);checks=checks+1 end
local now=200
local actor="Leader"
local fake=false
GetTime=function()return now end
UnitName=function()return actor end
local awards=0
GiveMasterLoot=function()awards=awards+1;error("No loot from Gear Plan review")end
local data={gearNeeds={},lootReceiptTracker={},lootAwardHistory={},
    roleAssignments={Leader={role="HEALER"}},characters={},
    localWishlists={Leader={MOLTEN_CORE={[16800]=true}}},
    lotteryHistory={{winner="Previous"}},awardAttemptLocks={old={status="AWARD_REQUESTED"}}}
NaxxLootLottery={
    db=data,
    DebugSimulator={IsActive=function()return fake end},
    GearPlanTransfer={IsBlocked=function()return false end},
    GearNeeds={
        MakeKey=function(_,name,raid,id,source)
            return string.lower(name).."|"..raid.."|"..id.."|"..source
        end
    },
    UI={},
    Print=function()end,
}
local N=NaxxLootLottery
for i=1,604 do
    local index=math.floor((i-1)/16)
    local name="Bot"..string.char(65+math.floor(index/26))..
        string.char(65+(index%26))
    local id=10000+i
    local key=N.GearNeeds:MakeKey(name,"MOLTEN_CORE",id,"BOT_GEAR_PLAN")
    data.gearNeeds[key]={key=key,character=name,itemID=id,
        raidKey="MOLTEN_CORE",role="CASTER_DPS",
        source="BOT_GEAR_PLAN",characterType="PLAYERBOT",
        status=i<=469 and "NEEDED" or "GREED"}
end
local original={}
for key,row in pairs(data.gearNeeds) do original[key]=row end
local first="botaa|MOLTEN_CORE|10001|BOT_GEAR_PLAN"
local last="botbl|MOLTEN_CORE|10604|BOT_GEAR_PLAN"
ok(data.gearNeeds[first]~=nil and data.gearNeeds[last]~=nil,
   "fixture spans exactly 604 original Playerbot Gear Plans")
assert(loadfile("NaxxLootLottery/Core/GearPlanReview.lua"))()
local R=N.GearPlanReview
local initRoles=data.roleAssignments
local initWishes=data.localWishlists
local initHistory=data.lotteryHistory
local initLocks=data.awardAttemptLocks
local initGear=data.gearNeeds
local initial=data.gearNeeds[first]
local approved,message=R:Arm(first,"STATUS","GREED")
ok(approved and R.armed and initial.status=="NEEDED",
   "first deliberate action previews edit without writing saved status")
approved,message=R:Confirm()
ok(approved and initial.status=="GREED" and not R.armed,
   "second deliberate action edits only exact existing bot record")
ok(data.gearNeeds==initGear and data.gearNeeds[first]==initial,
   "status confirmation keeps same table and row identities")
ok(not R:Confirm(),"cannot reuse already-consumed consent")
ok(not R:Arm(first,"STATUS","OBTAINED"),
   "manual dropdown may NEVER manufacture OBTAINED receipt")
ok(not R:Arm(first,"STATUS","GREED"),
   "no-op existing status is not presented as an edit")
data.gearNeeds[first].status="OBTAINED"
ok(not R:Arm(first,"STATUS","NEEDED") and
   not R:Arm(first,"REMOVE"),"confirmed obtained row is immutable from editor")
data.gearNeeds[first].status="NEEDED"
ok(R:Arm(first,"STATUS","DISABLED"),"selected bot may arm other status")
now=now+16
ok(not R:Confirm() and initial.status=="NEEDED",
   "15 second expiry refuses mutation")
now=now+1
ok(R:Arm(first,"STATUS","DISABLED"),"arm again after expiry")
actor="Different"
ok(not R:Confirm() and initial.status=="NEEDED",
   "different acting character cancels status confirmation")
actor="Leader"
ok(R:Arm(first,"STATUS","DISABLED"),"actor restored")
data.gearNeeds[last].status="DISABLED"
ok(not R:Confirm() and initial.status=="NEEDED",
   "other Gear Plan changed since review; refuse stale consent")
data.gearNeeds[last].status="GREED"
ok(R:Arm(first,"STATUS","DISABLED"),"review fresh history")
data.gearNeeds[first]={key=first,character=initial.character,
    itemID=initial.itemID,raidKey=initial.raidKey,role=initial.role,
    status="NEEDED",source="BOT_GEAR_PLAN",characterType="PLAYERBOT"}
ok(not R:Confirm(),"replaced target row pointer cannot reuse old confirmation")
data.gearNeeds[first]=initial
ok(R:Arm(first,"REMOVE"),"removal requires separate review")
R:Cancel()
ok(not R:Confirm() and data.gearNeeds[first]==initial,
   "cancel never deletes saved bot plan")
data.lootReceiptTracker["L1"]={character=initial.character,
    itemID=initial.itemID,status="WON_AWAITING_ITEM"}
ok(not R:Arm(first,"STATUS","GREED") and not R:Arm(first,"REMOVE"),
   "pending winner receipt protects record from status change/removal")
data.lootReceiptTracker["L1"]={character=initial.character,
    itemID=initial.itemID,status="OBTAINED",remoteSyncStatus="AWAITING_PLAYER"}
ok(not R:Arm(first,"STATUS","GREED"),
   "human remote receipt without ACK cannot bypass safety")
data.lootReceiptTracker={}
data.lootAwardHistory={{itemID=initial.itemID,winner=initial.character,
    dropUID="L1",status="LOOT_SLOT_CLEARED",
    reconciliationStatus="CLOSED_NO_RETRY"}}
ok(not R:Arm(first,"REMOVE"),
   "loot slot cleared + no-retry is still NOT item delivery evidence")
data.lootAwardHistory={}
fake=true
ok(not R:Arm(first,"REMOVE"),"fake raid cannot arm real plan removal")
fake=false
N.GearPlanTransfer.IsBlocked=function()return true,"Active loot" end
ok(not R:Arm(first,"STATUS","GREED"),"active-raid safety gate enforced")
N.GearPlanTransfer.IsBlocked=function()return false end
ok(not R:Arm(first,"STATUS","UNKNOWN") and
   not R:Arm(first,"STATUS","OBTAINED"),
   "only NEED/GREED/DISABLED editing allowed")
ok(R:Arm(first,"REMOVE"),"valid remaining bot plan can be reviewed for X")
ok(data.gearNeeds[first]==initial,
   "X first click never deletes anything")
ok(R:Confirm() and data.gearNeeds[first]==nil,
   "second explicit confirmation deletes exactly one selected bot plan")
local preserved=0
for key,row in pairs(original) do
    if key~=first then
        ok(data.gearNeeds[key]==row,
           "other 603 Gear Plans remain byte-for-byte original objects")
        preserved=preserved+1
    end
end
ok(preserved==603 and N.db.roleAssignments==initRoles and
   N.db.localWishlists==initWishes and
   N.db.lotteryHistory==initHistory and
   N.db.awardAttemptLocks==initLocks and awards==0,
   "no global roles, wishlist, lottery, locks or physical items changed")
-- UI modal tests: cancel, expiry, explicit confirm and zero unarmed grants.
local function frame()
    local f={shown=false,enabled=true,events={}}
    function f:SetPoint(...)end
    function f:SetSize(...)end
    function f:GetFrameLevel()return 1 end
    function f:SetFrameLevel(...)end
    function f:SetFrameStrata(...)end
    function f:EnableMouse(...)end
    function f:SetBackdrop(...)end
    function f:SetBackdropColor(...)end
    function f:SetBackdropBorderColor(...)end
    function f:CreateFontString()return frame()end
    function f:SetWidth(...)end
    function f:SetJustifyH(...)end
    function f:SetText(v)self.text=v end
    function f:SetScript(e,fn)self.events[e]=fn end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    return f
end
CreateFrame=frame
UIParent=frame()
N.UI.mainFrame=UIParent
N.UI.RefreshGearPlans=function(self)self.refreshed=(self.refreshed or 0)+1 end
N.UI.CreateTextButton=function(_,parent,label,w)
    local x=frame()
    x.label=frame()
    x.label:SetText(label)
    return x
end
assert(loadfile("NaxxLootLottery/UI/GearPlanReviewFrame.lua"))()
local UI=N.UI
UI:ReviewBotPlan(last,"STATUS","NEEDED")
ok(UI.gearPlanReviewDialog and UI.gearPlanReviewDialog.shown and
   data.gearNeeds[last].status=="GREED",
   "editor modal only opens; first click keeps status unchanged")
UI.gearPlanReviewCancel.events.OnClick()
ok(not UI.gearPlanReviewDialog.shown and
   not R.armed and data.gearNeeds[last].status=="GREED",
   "cancel button cannot modify record")
UI:ReviewBotPlan(last,"STATUS","NEEDED")
UI.gearPlanReviewConfirm.events.OnClick()
ok(data.gearNeeds[last].status=="NEEDED" and UI.refreshed==1 and
   not UI.gearPlanReviewDialog.shown,
   "UI final confirm applies only chosen status and refreshes once")
ok(N.db.gearNeeds==initGear and N.db.roleAssignments==initRoles,
   "UI edit never rewrites account roles or bot roster")
print("PASS: "..checks.." guarded Gear Plan reviews, pending receipt holds and modal UI")
