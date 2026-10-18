-- Lua 5.1: per-item Playerbot role editing must NEVER touch global raid roles.
local checks=0
local function ok(v,message) assert(v,message);checks=checks+1 end
local clock=100
local name="RaidOwner"
GetTime=function()return clock end
UnitName=function()return name end
local grants=0
GiveMasterLoot=function()grants=grants+1;error("Never award")end
RandomRoll=function()grants=grants+1;error("Never roll")end
local roles={
    {id="MAIN_TANK",label="Main Tank"},
    {id="TANK",label="Tank"},
    {id="HEALER",label="Healer"},
    {id="MELEE_DPS",label="Melee DPS"},
    {id="RANGED_PHYSICAL_DPS",label="Ranged Physical DPS"},
    {id="CASTER_DPS",label="Caster DPS"}
}
local labels={}
for _,role in ipairs(roles) do labels[role.id]=role.label end
local db={
    gearNeeds={},roleAssignments={BotAA={role="CASTER_DPS"},BotBL={role="CASTER_DPS"}},
    characters={BotAA={characterType="PLAYERBOT"}},
    lootAwardHistory={},lootReceiptTracker={},
    localWishlists={RaidOwner={MOLTEN_CORE={[10001]=true}}},
    lotteryHistory={{winner="OldWinner"}},
    awardAttemptLocks={historical="NO_RETRY"},
    guildLootTransferAudit={{itemID=17010,status="LOOT_SLOT_CLEARED"}}
}
NaxxLootLottery={
    roles=roles,roleLabels=labels,db=db,UI={},
    Print=function(self,message)self.lastPrint=message end,
    DebugSimulator={IsActive=function()return false end},
    GearPlanTransfer={IsBlocked=function()return false end},
    GearNeeds={
        MakeKey=function(_,character,raid,itemID,source)
            return string.lower(character).."|"..raid.."|"..
                tostring(itemID).."|"..source
        end
    }
}
local N=NaxxLootLottery
local original={}
local first=nil
local last=nil
for index=1,604 do
    local n=math.floor((index-1)/16)
    local char="Bot"..string.char(65+math.floor(n/26))..
        string.char(65+(n%26))
    local item=10000+index
    local key=N.GearNeeds:MakeKey(char,"MOLTEN_CORE",item,"BOT_GEAR_PLAN")
    local row={
        key=key,character=char,itemID=item,raidKey="MOLTEN_CORE",
        status=index<=469 and "NEEDED" or "GREED",
        role="CASTER_DPS",source="BOT_GEAR_PLAN",
        characterType="PLAYERBOT",
    }
    db.gearNeeds[key]=row
    original[key]=row
    if index==1 then first=row end
    if index==604 then last=row end
end
local persistent={gear=db.gearNeeds,roles=db.roleAssignments,
    characters=db.characters,receipts=db.lootReceiptTracker,
    awards=db.lootAwardHistory,wishes=db.localWishlists,
    lottery=db.lotteryHistory,locks=db.awardAttemptLocks,
    guild=db.guildLootTransferAudit}
assert(loadfile("NaxxLootLottery/Core/GearPlanReview.lua"))()
local R=N.GearPlanReview
ok(not R:CanEdit(first.key,"ROLE","NONEXISTENT"),"invalid role ID rejected")
ok(not R:CanEdit(first.key,"ROLE","CASTER_DPS"),"no-op role refused")
ok(not R:CanEdit(first.key,"ROLE",false),"non-string role refused")
local allowed,message=R:Arm(first.key,"ROLE","HEALER")
ok(allowed and message:find("ITEM ROLE",1,true) and
    message:find("Global raid-role",1,true) and
    first.role=="CASTER_DPS" and db.roleAssignments.BotAA.role=="CASTER_DPS",
    "role preview names one ITEM and does not alter shared assignments")
ok(R:Confirm() and first.role=="HEALER" and
   db.roleAssignments.BotAA.role=="CASTER_DPS",
   "confirm updates exactly one item's role without global role mutation")
ok(not R:Confirm(),"cannot replay role confirmation")
ok(R:Arm(first.key,"ROLE","MAIN_TANK"),"may preview another role")
clock=clock+16
ok(not R:Confirm() and first.role=="HEALER","expired role review fails closed")
ok(R:Arm(first.key,"ROLE","TANK"),"arm again for actor test")
name="DifferentActor"
ok(not R:Confirm() and first.role=="HEALER","changed actor denies role edit")
name="RaidOwner"
ok(R:Arm(first.key,"ROLE","TANK"),"arm again for plan mutation")
last.status="DISABLED"
ok(not R:Confirm() and first.role=="HEALER",
   "unrelated Gear Plan change invalidates role confirmation")
last.status="GREED"
ok(R:Arm(first.key,"ROLE","MELEE_DPS"),"arm after original roster restored")
local previous=first
db.gearNeeds[first.key]={key=first.key,character=first.character,
    itemID=first.itemID,raidKey=first.raidKey,role=first.role,
    status=first.status,source=first.source,characterType=first.characterType}
ok(not R:Confirm(),"replaced row object cannot inherit prior arm")
db.gearNeeds[first.key]=previous
first.status="OBTAINED"
ok(not R:Arm(first.key,"ROLE","MAIN_TANK"),
   "OBTAINED item role cannot be manually altered")
first.status="NEEDED"
db.lootReceiptTracker.pending={
    itemID=first.itemID,character=first.character,status="WON_AWAITING_ITEM"
}
ok(not R:Arm(first.key,"ROLE","MAIN_TANK"),
   "awaiting recipient receipt protects item role and original reservation")
db.lootReceiptTracker.pending=nil
db.lootAwardHistory[1]={
    itemID=first.itemID,winner=first.character,dropUID="D1",
    status="LOOT_SLOT_CLEARED",reconciliationStatus="CLOSED_NO_RETRY"
}
ok(not R:Arm(first.key,"ROLE","MAIN_TANK"),
   "NO RETRY never allows changing a pending winner's Gear Plan role")
for k in pairs(db.lootAwardHistory) do db.lootAwardHistory[k]=nil end
local fake=true
N.DebugSimulator.IsActive=function()return fake end
ok(not R:Arm(first.key,"ROLE","MAIN_TANK"),"debug raid refuses changes")
fake=false
N.GearPlanTransfer.IsBlocked=function()return true,"Loot window open" end
ok(not R:Arm(first.key,"ROLE","MAIN_TANK"),"real loot window refuses changes")
N.GearPlanTransfer.IsBlocked=function()return false end
local rowChanged=0
for key,row in pairs(original) do
    ok(db.gearNeeds[key]==row,"existing 604 row objects remain untouched")
    if row.role~="CASTER_DPS" then rowChanged=rowChanged+1 end
end
ok(rowChanged==1 and first.role=="HEALER",
   "exactly ONE role among 604 differs after one confirmed role update")
ok(db.gearNeeds==persistent.gear and
   db.roleAssignments==persistent.roles and
   db.characters==persistent.characters and
   db.lootReceiptTracker==persistent.receipts and
   db.lootAwardHistory==persistent.awards and
   db.localWishlists==persistent.wishes and
   db.lotteryHistory==persistent.lottery and
   db.awardAttemptLocks==persistent.locks and
   db.guildLootTransferAudit==persistent.guild and grants==0,
   "all shared data and historical physical item locks untouched")

local function frame()
    local f={events={},shown=false,enabled=true}
    function f:SetSize(...)end
    function f:SetPoint(...)end
    function f:SetFrameStrata(...)end
    function f:GetFrameLevel()return 1 end
    function f:SetFrameLevel(...)end
    function f:EnableMouse(...)end
    function f:SetBackdrop(...)end
    function f:SetBackdropColor(...)end
    function f:SetBackdropBorderColor(...)end
    function f:CreateFontString()return frame()end
    function f:SetWidth(...)end
    function f:SetJustifyH(...)end
    function f:SetText(v)self.text=v end
    function f:SetScript(name,cb)self.events[name]=cb end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    return f
end
CreateFrame=function()return frame()end
UIParent=frame()
N.UI.mainFrame=UIParent
N.UI.RefreshGearPlans=function(self)self.refreshed=(self.refreshed or 0)+1 end
N.UI.CreateTextButton=function(_,parent,label,width)
    local f=frame()
    f.label=frame()
    f.label:SetText(label)
    return f
end
assert(loadfile("NaxxLootLottery/UI/GearPlanReviewFrame.lua"))()
local UI=N.UI
UI:OpenGearPlanRolePicker(last.key)
ok(UI.gearPlanRolePicker.shown and #UI.gearPlanRoleButtons==6 and
   not R.armed and last.role=="CASTER_DPS",
   "item role chooser only displays six official labels, no writes")
UI.gearPlanRoleCancel.events.OnClick()
ok(not UI.gearPlanRolePicker.shown and
   not R.armed and last.role=="CASTER_DPS",
   "cancel chooser leaves the original item role untouched")
UI:OpenGearPlanRolePicker(last.key)
UI.gearPlanRoleButtons[3].events.OnClick()
ok(not UI.gearPlanRolePicker.shown and
   UI.gearPlanReviewDialog.shown and R.armed and
   R.armed.action=="ROLE" and R.armed.newStatus=="HEALER" and
   last.role=="CASTER_DPS",
   "choosing HEALER opens separate confirmation, not a save")
UI.gearPlanReviewCancel.events.OnClick()
ok(not R.armed and last.role=="CASTER_DPS",
   "review Cancel still leaves role untouched")
UI:OpenGearPlanRolePicker(last.key)
UI.gearPlanRoleButtons[3].events.OnClick()
UI.gearPlanReviewConfirm.events.OnClick()
ok(last.role=="HEALER" and not R.armed and
   not UI.gearPlanReviewDialog.shown and UI.refreshed==1,
   "explicit final modal Confirm updates exactly chosen row")
ok(db.roleAssignments.BotBL.role=="CASTER_DPS" and grants==0,
   "neither shared bot raid role nor physical items changed in UI")
print("PASS: "..checks.." per-item Gear Plan roles, six-role chooser, 604-row isolation")
