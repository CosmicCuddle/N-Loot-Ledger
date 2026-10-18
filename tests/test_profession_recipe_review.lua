-- NLL WoW 3.3.5a Lua 5.1: recipe review NEVER verifies bot professions
-- from a wishlist or awards physical items.
local checks=0
local function ok(v,why)assert(v,why);checks=checks+1 end
local transfers=0
GiveMasterLoot=function()transfers=transfers+1;error("no award")end
SendAddonMessage=function()transfers=transfers+1;error("no network action")end
RandomRoll=function()transfers=transfers+1;error("no roll")end
local db={
    gearNeeds={},roleAssignments={BotAA={role="MAIN_TANK"}},
    characters={BotAA={characterType="PLAYERBOT"}},
    localWishlists={Owner={MOLTEN_CORE={[18291]=true,[16800]=true}}},
    lotteryHistory={{winner="OldWinner"}},
    lootAwardHistory={{status="AWARD_REQUESTED"}},
    lootReceiptTracker={claim={status="WON_AWAITING_ITEM"}},
    guildLootTransferAudit={{status="CLOSED_NO_RETRY"}},
    awardAttemptLocks={old={status="AWARD_REQUESTED"}},
    settings={directMasterLootEnabled=false,
        guildLootTransfersEnabled=false,guildAutoPreviewEnabled=false},
}
NaxxLootLottery={db=db,Data={},UI={}}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Data/MoltenCore.lua"))()
local mc=N.Data.MoltenCore
mc:Initialize()
assert(loadfile("NaxxLootLottery/Core/ProfessionRecipeReview.lua"))()
local R=N.ProfessionRecipeReview
local expected={
    [18264]="Blacksmithing",[18292]="Engineering",
    [18291]="Engineering",[18290]="Engineering",
    [18259]="Enchanting",[18260]="Enchanting",
    [18252]="Leatherworking",[18265]="Tailoring",
    [21371]="Tailoring",[18257]="Alchemy",
}
local recipes=R:ListRecipes()
ok(#recipes==10 and R.RECIPE_COUNT==10,
    "all ten original MC recipes are classified")
local seen={}
for _,entry in ipairs(recipes) do
    ok(expected[entry.itemID]==entry.profession and entry.skill==300
        and entry.manualOnly==true and entry.autoEligible==false
        and entry.transferAuthorized==false
        and entry.specializationVerified==false,
        "recipe belongs to exact researched profession, never auto-eligible")
    ok(not seen[entry.itemID],"recipe catalog contains no duplicate IDs")
    seen[entry.itemID]=true
    local report=assert(R:Build(entry.itemID))
    ok(report.requiredSkill==300 and
       report.profession==entry.profession and
       report.status=="MANUAL_REVIEW_ONLY" and
       report.recipientVerified==false and
       report.professionVerified==false and
       report.skillVerified==false and
       report.specializationVerified==false and
       report.learnedAlreadyVerified==false and
       report.autoEligible==false and report.transferAuthorized==false,
       "no invented profession proof, guild approval or physical award")
end
ok(not R:Build(17010) and not R:Build(16800) and
    not R:Build("junk") and not R:Build(18291.5),
    "crafting materials, equipment and invalid IDs cannot become recipes")
-- 604 baseline Gear Plans with unrelated item IDs plus seven candidate
-- interests in Force Reactive Disk; all actual stored records remain intact.
local original={}
for i=1,604 do
    local group=math.floor((i-1)/16)
    local name="Bot"..string.char(65+math.floor(group/26))..
        string.char(65+(group%26))
    local key=name.."|"..i
    local row={character=name,itemID=16800,raidKey="MOLTEN_CORE",
        status=i<=469 and "NEEDED" or "GREED",
        source="BOT_GEAR_PLAN",characterType="PLAYERBOT"}
    db.gearNeeds[key]=row
    original[key]=row
end
for i=1,7 do
    local key="Interested"..i
    local status=({ "NEEDED","NEEDED","GREED","GREED",
        "OBTAINED","DISABLED","NEEDED" })[i]
    local row={character="Recipebot"..i,itemID=18291,
        raidKey="MOLTEN_CORE",status=status,
        source="BOT_GEAR_PLAN",characterType="PLAYERBOT"}
    db.gearNeeds[key]=row
    original[key]=row
end
-- Explicit another source is an interest, NOT a verified profession.
db.gearNeeds["self"]={character="Ownerview",itemID=18291,
    raidKey="MOLTEN_CORE",status="NEEDED",
    source="PLAYER_SUBMITTED",characterType="PLAYER"}
original.self=db.gearNeeds.self
db.gearNeeds.invalid={character="Spoof",itemID=18291,
    raidKey="BLACKWING_LAIR",status="NEEDED",source="BOT_GEAR_PLAN"}
original.invalid=db.gearNeeds.invalid
db.gearNeeds.disabledSource={character="Spoof2",itemID=18291,
    raidKey="MOLTEN_CORE",status="NEEDED",source="SOME_OTHER_SOURCE"}
original.disabledSource=db.gearNeeds.disabledSource
local refs={gear=db.gearNeeds,roles=db.roleAssignments,
    characters=db.characters,wishes=db.localWishlists,
    lotteries=db.lotteryHistory,awards=db.lootAwardHistory,
    receipts=db.lootReceiptTracker,guild=db.guildLootTransferAudit,
    locks=db.awardAttemptLocks,settings=db.settings}
local result=assert(R:Build(18291))
ok(#result.candidates==8 and result.need==4 and result.greed==2
    and result.obtained==1 and result.disabled==1,
    "seven bot interests plus one player interest; untrusted sources excluded")
ok(result.candidates[1].character=="Ownerview",
    "deterministic case-insensitive character ordering")
for _,candidate in ipairs(result.candidates) do
    ok(candidate.eligible==false and candidate.awardAuthorized==false
       and candidate.profession=="UNVERIFIED"
       and candidate.skill=="UNVERIFIED"
       and candidate.specialization=="UNVERIFIED"
       and candidate.recipeKnown=="UNVERIFIED",
       "interested character is never upgraded into profession proof")
end
local old=getmetatable(db.gearNeeds)
ok(not old,"test fixture has no hidden lazy data mutation")
local originalMC=mc:GetItem(18291)
originalMC.manualOnly=false
ok(not R:Build(18291),"unverified non-manual recipe fails closed")
originalMC.manualOnly=true
-- Simulated WoW UI, including two independent pagers.
local function frame()
    local f={events={},visible=false,enabled=true}
    function f:SetPoint(...)end
    function f:SetWidth(w)self.width=w end
    function f:SetHeight(h)self.height=h end
    function f:SetFrameStrata()end
    function f:EnableMouse()end
    function f:CreateFontString()return frame()end
    function f:SetJustifyH()end
    function f:SetText(value)self.text=value end
    function f:SetScript(e,fn)self.events[e]=fn end
    function f:Show()self.visible=true end
    function f:Hide()self.visible=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=function()return frame()end
UIParent=frame()
N.UI.RegisterSkinnedFrame=function()end
N.UI.CreateTextButton=function(_,parent,label,w)
    local x=frame();x.label=frame();x.label:SetText(label)
    return x
end
assert(loadfile("NaxxLootLottery/UI/ProfessionRecipeFrame.lua"))()
local UI=N.UI
UI:ShowProfessionRecipeReview()
ok(UI.professionRecipePanel.visible and
    UI.professionRecipeStatus.text:find("Recipe 1/10",1,true) and
    not UI.professionRecipePrev.enabled and UI.professionRecipeNext.enabled,
    "UI starts at first catalog page and has bounded navigation")
local forceIndex
for i,recipe in ipairs(recipes) do
    if recipe.itemID==18291 then forceIndex=i end
end
ok(forceIndex~=nil,"Force Reactive Disk in researched recipe catalog")
while UI.professionRecipeIndex<forceIndex do
    UI.professionRecipeNext.events.OnClick()
end
ok(UI.professionRecipeItem.text:find("Force Reactive Disk",1,true)
   and UI.professionRecipeRequirement.text:find("Engineering",1,true)
   and UI.professionRecipeRequirement.text:find("300",1,true)
   and UI.professionRecipeWarning.text:find("UNVERIFIED",1,true),
   "UI shows exact profession/skill but no verified learner")
ok(UI.professionRecipeCandidateNext.enabled and
   not UI.professionRecipeCandidatePrev.enabled and
   UI.professionRecipeFooter.text:find("1/2",1,true),
   "eight different interest rows shown four at a time")
UI.professionRecipeCandidateNext.events.OnClick()
ok(UI.professionRecipeCandidatePage==2 and
   UI.professionRecipeCandidatePrev.enabled and
   not UI.professionRecipeCandidateNext.enabled and
   UI.professionRecipeFooter.text:find("2/2",1,true),
   "second page contains remainder without dropping recipients")
UI.professionRecipeCandidateNext.events.OnClick()
ok(UI.professionRecipeCandidatePage==2,
   "forced Next does not leak beyond last candidate page")
UI.professionRecipeCandidatePrev.events.OnClick()
ok(UI.professionRecipeCandidatePage==1,
   "Prev restores first interested-candidate page")
UI.professionRecipeNext.events.OnClick()
ok(UI.professionRecipeCandidatePage==1,
   "changing recipe resets interested candidate pagination")
UI:CloseProfessionRecipeReview()
ok(not UI.professionRecipePanel.visible,
   "Close is read only")
for key,row in pairs(original) do
    ok(db.gearNeeds[key]==row,"all 614 original mock saved rows preserved")
end
ok(db.gearNeeds==refs.gear and db.roleAssignments==refs.roles
   and db.characters==refs.characters and
   db.localWishlists==refs.wishes and
   db.lotteryHistory==refs.lotteries and
   db.lootAwardHistory==refs.awards and
   db.lootReceiptTracker==refs.receipts and
   db.guildLootTransferAudit==refs.guild
   and db.awardAttemptLocks==refs.locks
   and db.settings==refs.settings and transfers==0,
   "no SavedVariables table changes, role edits, transfers or addon messages")
print("PASS: "..checks.." recipe profession review, full catalog, paging and zero awards")
