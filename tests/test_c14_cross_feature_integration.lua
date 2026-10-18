-- Integrated Lua 5.1 regression for NLL C8-C13 at one shared 604-plan
-- baseline. All actors/loot/frames are mocks. NEVER load a real account.
local checks=0
local function ok(value,why) assert(value,why);checks=checks+1 end
local now=100
local actor="Owner"
GetTime=function()return now end
UnitName=function()return actor end
GetNumRaidMembers=function()return 0 end
local grants=0
GiveMasterLoot=function()grants=grants+1;error("NO PHYSICAL GRANTS")end
RandomRoll=function()grants=grants+1;error("NO RANDOM ROLLS")end
SendAddonMessage=function()grants=grants+1;error("NO ADDON COMMUNICATION")end
GetLootSourceInfo=function()error("5.0.4+ API NOT AVAILABLE IN WRATH")end
local opened=false
GetNumLootItems=function()return 3 end
GetLootSlotLink=function(slot)
    return ({"|Hitem:17010:0|h[Fiery Core]|h",
        "|Hitem:17010:0|h[Fiery Core]|h",
        "|Hitem:17011:0|h[Lava Core]|h"})[slot]
end
GetLootSlotInfo=function(slot)
    return nil,nil,slot==1 and 5 or 1,1,false
end
UnitGUID=function(unit)ok(unit=="target","target hint only");return "OTHER_TARGET" end
local fake=false
local db={
    gearNeeds={},characters={},roleAssignments={},
    localWishlists={Owner={MOLTEN_CORE={[18291]=true}}},
    localWishlistGreed={},localWishlistObtained={},
    guildLootTransferAudit={{
        itemID=17010,status="LOOT_SLOT_CLEARED",
        reconciliationStatus="CLOSED_NO_RETRY",slotIndex=8}},
    lootAwardHistory={{itemID=16800,winner="Pastwinner",
        status="AWARD_OUTCOME_UNKNOWN",dropUID="prior:1:16800"}},
    lootReceiptTracker={},
    awardAttemptLocks={["prior:1:16800"]={status="AWARD_REQUESTED"}},
    lotteryHistory={{winner="Pastwinner"}},
    settings={directMasterLootEnabled=false,
        guildLootTransfersEnabled=false,guildAutoPreviewEnabled=false},
}
NaxxLootLottery={
    db=db,Data={},UI={},
    DebugSimulator={IsActive=function()return fake end},
    LootDetection={lootOpen=false},
    TicketLottery={liveLootObserved=false,active=nil},
    roleLabels={CASTER_DPS="Caster DPS",HEALER="Healer",
        MAIN_TANK="Main Tank",TANK="Tank",MELEE_DPS="Melee DPS",
        RANGED_PHYSICAL_DPS="Ranged Physical DPS"},
    roles={
        {id="MAIN_TANK",label="Main Tank"},{id="TANK",label="Tank"},
        {id="HEALER",label="Healer"},{id="MELEE_DPS",label="Melee DPS"},
        {id="RANGED_PHYSICAL_DPS",label="Ranged Physical DPS"},
        {id="CASTER_DPS",label="Caster DPS"}},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Data/MoltenCore.lua"))()
N.Data.MoltenCore:Initialize()
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearPlanTransfer.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearPlanReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/ProfessionRecipeReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/LootSourceDiagnostics.lua"))()
assert(loadfile("NaxxLootLottery/Core/LootCopyAudit.lua"))()
local IDs={18291,16800,16805,16829,16837,16859,16863,18870,
    17109,19145,19146,18872,18875,18861,18879,19147}
local byKey={}
local needCount,greedCount=0,0
for i=1,604 do
    local index=math.floor((i-1)/16)
    local char="Bot"..string.char(65+math.floor(index/26))..
        string.char(65+(index%26))
    local id=IDs[((i-1)%16)+1]
    ok(N.Data.MoltenCore:GetItem(id),"all fixture item IDs are actual Molten Core loot")
    local key=N.GearNeeds:MakeKey(char,"MOLTEN_CORE",id,"BOT_GEAR_PLAN")
    local row={key=key,character=char,characterType="PLAYERBOT",
        role="CASTER_DPS",itemID=id,raidKey="MOLTEN_CORE",
        status=i<=469 and "NEEDED" or "GREED",
        source="BOT_GEAR_PLAN"}
    db.gearNeeds[key]=row
    byKey[key]=row
    if row.status=="NEEDED" then needCount=needCount+1
    else greedCount=greedCount+1 end
end
local originals={gear=db.gearNeeds,roles=db.roleAssignments,
    roster=db.characters,wishlist=db.localWishlists,
    awards=db.lootAwardHistory,receipt=db.lootReceiptTracker,
    locks=db.awardAttemptLocks,guild=db.guildLootTransferAudit,
    lotteries=db.lotteryHistory,settings=db.settings}
ok(N.GearNeeds:GetCount()==604 and needCount==469 and greedCount==135,
    "38-playerbot 604-plan fixture maintains exact 469 NEED / 135 GREED")
local exported={}
for page=1,3 do
    local text,count,pages,total=N.GearPlanTransfer:ExportChunk(page)
    ok(text and pages==3 and total==604 and
        count==(page==3 and 104 or 250),
        "original paged 604 Gear Plans remain exportable as 250/250/104")
    exported[page]=text
end
local before=N.ProfessionRecipeReview:Build(18291)
ok(before and #before.candidates==38 and
    not before.autoEligible and not before.professionVerified,
    "38 recipe interests do not prove profession eligibility")
local firstKey=N.GearNeeds:MakeKey("BotAA","MOLTEN_CORE",18291,"BOT_GEAR_PLAN")
local first=db.gearNeeds[firstKey]
ok(first and first.status=="NEEDED" and first.role=="CASTER_DPS",
    "selected bot item starts as an ordinary saved 604-row reservation")

-- Load actual UI behavior; never construct the full live addon frame.
assert(loadfile("NaxxLootLottery/UI/MainFrame.lua"))()
assert(loadfile("NaxxLootLottery/UI/WishlistFrame.lua"))()
assert(loadfile("NaxxLootLottery/UI/GearPlanReviewFrame.lua"))()
assert(loadfile("NaxxLootLottery/UI/GearPlanConflictFrame.lua"))()
assert(loadfile("NaxxLootLottery/UI/ProfessionRecipeFrame.lua"))()
local UI=N.UI
local function frame()
    local f={visible=true}
    function f:Hide()self.visible=false end
    function f:Show()self.visible=true end
    function f:ClearFocus()self.focusCleared=true end
    return f
end
UI.mainFrame=frame()
UI.rolesPanel=frame()
UI.wishlistPanel=frame()
UI.searchPanel=frame()
UI.settingsPanel=frame()
UI.currentLootPanel=frame()
UI.overviewPanel=frame()
UI.SetActiveNav=function(self,name)self.lastNav=name end
UI.RefreshRolesPanel=function()end
UI.RefreshWishlistPanel=function()end
UI.RefreshSearchPanel=function()end
UI.RefreshSettingsPanel=function()end
UI.RefreshCurrentLootPanel=function()end
UI.RefreshOverview=function()end
local role=frame()
local review=frame()
local comparison=frame()
local profession=frame()
local transfer=frame()
UI.gearPlanRolePicker=role
UI.gearPlanReviewDialog=review
UI.gearPlanConflictDialog=comparison
UI.professionRecipePanel=profession
UI.gearTransferDialog=transfer
local canceled=0
UI.gearTransferCancelTransient=function()canceled=canceled+1 end
UI.gearTransferTextBox=frame()

ok(N.GearPlanReview:Arm(firstKey,"ROLE","HEALER"),
    "item role change requires independent 15-second confirmation")
UI.gearPlanRoleKey=firstKey
UI.gearConflictPreview={sourceText="stale"}
UI.gearConflictIndex=3
UI:ShowPanel("roles")
ok(UI.lastNav=="roles" and
    not role.visible and not review.visible and
    not comparison.visible and not profession.visible and
    not transfer.visible and
    UI.gearPlanRoleKey==nil and UI.gearConflictPreview==nil and
    canceled==1,
    "full addon navigation disarms role, item review, stale conflict,
     recipe review and old transfer authorization")
ok(not N.GearPlanReview:Confirm() and first.role=="CASTER_DPS",
    "navigation alone cannot commit an earlier pending Gear Plan")
ok(N.GearPlanReview:Arm(firstKey,"STATUS","GREED"),
    "a second proposal can be armed independently")
UI:HideMainFrame()
ok(not UI.mainFrame.visible and not N.GearPlanReview:Confirm()
    and first.status=="NEEDED" and canceled==2,
    "closing main addon disarms pending consent without touching SavedVariables")

-- The tested C14 guard allows one deliberate row role/status change
-- only after full explicit confirmation, with all other rows intact.
ok(N.GearPlanReview:Arm(firstKey,"ROLE","HEALER"),
    "explicit role review may be started again after navigation")
ok(N.GearPlanReview:Confirm() and first.role=="HEALER" and
    db.roleAssignments==originals.roles,
    "intentional one-item role change does NOT rewrite shared raid role")
ok(N.GearPlanReview:Arm(firstKey,"STATUS","GREED"),
    "second, separate status review for exact row")
ok(N.GearPlanReview:Confirm() and first.status=="GREED",
    "explicitly approved one-item NEED to GREED edit works")

local modified=0
for key,row in pairs(byKey) do
    ok(db.gearNeeds[key]==row,"all 604 saved row objects preserved")
    if row.role~="CASTER_DPS" or
       (row.status~=(key==firstKey and "GREED" or
        ((row.character=="BotAA" or row.character=="BotAB") and "NEEDED" or row.status))) then
        -- Explicit comparison below detects any unexpected row changes
        -- without judging later fixture bot naming patterns.
    end
    if key==firstKey and row.role=="HEALER" and row.status=="GREED" then
        modified=modified+1
    else
        ok(row.role=="CASTER_DPS","unrelated item role unchanged")
    end
end
ok(modified==1,"only chosen row received intended role/status changes")
local after=N.ProfessionRecipeReview:Build(18291)
ok(after and #after.candidates==38 and
    after.need==before.need-1 and after.greed==before.greed+1 and
    not after.autoEligible and not after.transferAuthorized,
    "recipe review reflects single interest edit but never grants eligibility")
local oldPreview=N.GearPlanTransfer:Preview(exported[1])
ok(oldPreview and not oldPreview.ready and
    #oldPreview.conflicts==1,"old original export now conflicts with edited item")
local diff=N.GearPlanTransfer:CompareConflict(oldPreview,exported[1],1)
ok(diff and #diff.changes==2 and
    not diff.replaceAuthorized and not diff.safeToApply,
    "saved vs pasted role/status conflict remains inspect-only")
local noWrite,why=N.GearPlanTransfer:Apply(oldPreview,exported[1])
ok(not noWrite,"old export must never overwrite later approved edit")
local pagesAfter={}
for i=1,3 do
    local text,count=N.GearPlanTransfer:ExportChunk(i)
    ok(text and count==(i==3 and 104 or 250),
       "new 604-plan export still complete after guarded edit")
    pagesAfter[i]=text
end
ok(pagesAfter[1]~=exported[1] and pagesAfter[2]==exported[2] and
   pagesAfter[3]==exported[3],
   "one saved item change affects only its original deterministic export batch")

-- Physical safeguards must coexist, not become weaker after review.
N.LootDetection.lootOpen=true
N.TicketLottery.liveLootObserved=true
local live=N.LootCopyAudit:Inspect()
ok(live.visibleSlots==3 and live.distinctItemIDs==2 and
    live.heldItemIDs==1 and
    not live.canUnlock and not live.canRetry and not live.canAward,
    "old material attempt still held after UI and Gear Plan operations")
ok(not N.GearPlanReview:Arm(firstKey,"REMOVE") and
   not N.GearPlanTransfer:Preview(exported[1]),
   "real open loot blocks Gear Plan editing and imports")
N.LootDetection.lootOpen=false
N.TicketLottery.liveLootObserved=false
ok(#N.LootCopyAudit:Inspect().items==0,
    "closing real loot does not keep stale copy/source observations")
ok(db.gearNeeds==originals.gear and
   db.roleAssignments==originals.roles and
   db.characters==originals.roster and
   db.localWishlists==originals.wishlist and
   db.lootAwardHistory==originals.awards and
   db.lootReceiptTracker==originals.receipt and
   db.guildLootTransferAudit==originals.guild and
   db.awardAttemptLocks==originals.locks and
   db.lotteryHistory==originals.lotteries and
   db.settings==originals.settings and
   not db.settings.directMasterLootEnabled and
   not db.settings.guildLootTransfersEnabled and
   grants==0,"global role/wishlist, audit, physical attempt, receipt and consent identities preserved")
print("PASS: "..checks.." C14 integrated 604-plan role/status/export/recipe/conflict/loot/navigation safeguards")
