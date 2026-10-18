-- Lua 5.1: dry-run proposer includes unreserved materials but NEVER moves loot.
local checks=0
local function ok(v,m)assert(v,m);checks=checks+1 end
local awards=0
GiveMasterLoot=function()awards=awards+1;error("DRY RUN MAY NEVER GIVE")end
local ids={17010,16800,18259,17011,17204,17012,17013,17014,17015,0}
local function link(i)
    local id=ids[i]
    return id and id>0 and ("|Hitem:"..id..":0|h[Item "..id.."]|h") or nil
end
GetNumLootItems=function()return #ids end
GetLootSlotLink=function(i)return link(i)end
GetLootSlotInfo=function(i)return nil,nil,i==1 and 3 or 1,4,false end
GetItemInfo=function(id)
    if id==17012 then return nil end
    return "Item "..id,nil,(id==17204 and 5 or 2),nil,nil,
        (id==17013 and "Quest" or
        id==18259 and "Recipe" or "Trade Goods")
end
GetNumRaidMembers=function()return 3 end
local duplicate=false
GetRaidRosterInfo=function(i)
    if i==1 then return "Leader",2 end
    if i==2 and duplicate then return "Other",2 end
    return "Other"..i,0
end
local simulation=false
local transfersOn=0
local needs={bot={itemID=16800,character="Throgar",
    raidKey="MOLTEN_CORE",status="NEEDED"}}
local inbox={formula={raidKey="MOLTEN_CORE",status="PENDING",
    itemIDs={18259}}}
local wish={Pikeotter={MOLTEN_CORE={}}}
NaxxLootLottery={
    databaseVersion=1,
    DebugSimulator={IsActive=function()return simulation end},
    LootDetection={lootOpen=true},
    TicketLottery={liveLootObserved=true,AuthorityAllowed=function()return true end},
    Data={MoltenCore={GetItem=function(_,id)
        if id==17204 then return {legendary=true,manualOnly=true} end
        if id==18259 then return {itemID=id} end
    end,IsRecipeItem=function(_,item)return item and item.itemID==18259 end}},
    AwardWorkflow={liveRequests={}},
    UI={},
}
NaxxLootLotteryDB={gearNeeds=needs,submissionInbox=inbox,localWishlists=wish,
    lootAwardHistory={{itemID=17015,slotIndex=9,status="LOOT_SLOT_CLEARED"}},
    guildLootTransferAudit={{itemID=17014,slotIndex=8,status="LOOT_SLOT_CLEARED"}}}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Storage/Database.lua"))()
N.Database:Initialize()
assert(loadfile("NaxxLootLottery/Core/GuildLootReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildAutoPreview.lua"))()
local P=N.GuildAutoPreview
local db=N.db
local awardHistory=db.lootAwardHistory
local guildHistory=db.guildLootTransferAudit
local records=db.gearNeeds
local pending=db.submissionInbox
local plan=P:Build()
ok(not P:IsEnabled() and #plan.rows==0 and plan.proposed==0,
    "dry-run off by default; no scan or proposals")
ok(db.settings.directMasterLootEnabled==false and
    db.settings.guildLootTransfersEnabled==false,"physical consent remains OFF")
ok(P:SetEnabled(true),"explicit preview-only enable")
plan=P:Build()
ok(plan.mode=="DRY_RUN" and #plan.rows==9 and
    plan.proposed==2 and plan.held==7 and plan.autoEligible==0,
    "materials included; every reserved/uncertain/special/attempted item held")
local decisions={}
for _,row in ipairs(plan.rows) do
    decisions[row.itemID]=row
    ok(not row.autoEligible and not row.transferAuthorized and
       not row.leaderCandidateVerified and not row.physicalReceiptVerified,
       "no plan row is an automatic award instruction")
end
ok(decisions[17010].decision=="PROPOSE_TO_LEADER" and
    decisions[17010].quantity==3 and
    decisions[17010].proposedRecipient=="Leader",
    "three crafting materials proposed to the verified raid leader")
ok(decisions[17011].decision=="PROPOSE_TO_LEADER",
    "another unreserved material also proposed")
ok(decisions[16800].decision=="HOLD_RESERVED" and
    decisions[16800].need==1,"offline bot NEED is never auto-routed")
ok(decisions[18259].decision=="HOLD_UNCERTAIN",
    "incoming recipe reservation blocks allocation")
ok(decisions[17204].decision=="HOLD_SPECIAL" and
    decisions[17013].decision=="HOLD_SPECIAL",
    "legendary and quest item require separate human review")
ok(decisions[17012].decision=="HOLD_UNCERTAIN",
    "missing item cache never becomes auto eligible")
ok(decisions[17014].decision=="HOLD_PREVIOUS_ATTEMPT" and
    decisions[17015].decision=="HOLD_PREVIOUS_ATTEMPT",
    "past guild/winner attempts block same item and slot")
ok(db.gearNeeds==records and db.submissionInbox==pending and
    db.lootAwardHistory==awardHistory and db.guildLootTransferAudit==guildHistory,
    "read-only plan preserves same SavedVariables objects")
guildHistory[1].status="AWARD_OUTCOME_UNKNOWN"
plan=P:Build()
ok(plan.proposed==0 and
    decisions[17010].decision=="PROPOSE_TO_LEADER" and
    plan.rows[1].decision=="HOLD_UNRESOLVED_REQUEST",
    "one unresolved transfer blocks every new allocation proposal")
guildHistory[1].reconciliationStatus="CLOSED_NO_RETRY"
plan=P:Build()
ok(plan.proposed==2 and
    plan.rows[8].decision=="HOLD_PREVIOUS_ATTEMPT",
    "manual NO-RETRY closure restores unrelated proposals but never old item")
duplicate=true
plan=P:Build()
ok(#plan.rows==0 and plan.proposed==0,
    "ambiguous raid leadership never produces a proposal")
duplicate=false
N.LootDetection.lootOpen=false
plan=P:Build()
ok(#plan.rows==0 and plan.message:find("CORPSE CLOSED"),
    "closed corpse immediately removes all live proposals")
N.LootDetection.lootOpen=true
simulation=true
plan=P:Build()
ok(#plan.rows==0 and not P:SetEnabled(true),
    "fake raids cannot produce proposals or enable preview")
simulation=false
-- Mock only the guild dialog. The regular review/arm/commit controls remain
-- independent of the preview and cannot auto-invoke a transfer.
local function frame()
    local f={shown=false,scripts={},enabled=true}
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
    function f:SetText(x)self.text=x end
    function f:SetScript(n,fn)self.scripts[n]=fn end
    function f:CreateFontString()return frame()end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=frame
N.Print=function()end
N.UI.mainFrame=frame()
function N.UI:CreateTextButton(_,text,width)
    local f=frame()
    f.label=frame()
    f.label:SetText(text)
    return f
end
function N.UI:RegisterSkinnedFrame()end
assert(loadfile("NaxxLootLottery/UI/CurrentLootFrame.lua"))()
N.UI:OpenGuildLootReview()
ok(N.UI.guildLootDialog.shown and N.UI.guildLootDryRun.label.text=="Dry Run: ON",
    "guild review shows visible preview-only ON control")
ok(N.UI.guildLootRows[1].nameText.text:find("PROPOSE_TO_LEADER",1,true),
    "first crafting material proposal shown next to actual loot slot")
N.UI.guildLootDryRun.scripts.OnClick()
ok(not P:IsEnabled() and N.UI.guildLootDryRun.label.text=="Dry Run: OFF",
    "button safely disables preview without touching physical controls")
ok(N.UI.guildLootRows[1].nameText.text:find("GUILD_REVIEW",1,true),
    "disabled preview restores ordinary manual review")
N.UI.guildLootDryRun.scripts.OnClick()
ok(P:IsEnabled() and awards==0,"UI preview toggle never calls GiveMasterLoot")
N.Database:Initialize()
ok(db==N.db and not P:IsEnabled() and
    db.settings.directMasterLootEnabled==false and
    db.settings.guildLootTransfersEnabled==false,
    "reload disables preview and both physical consents")
ok(records==db.gearNeeds and pending==db.submissionInbox and
    awards==0 and transfersOn==0,
    "604-like Gear Plan SavedVariables structures are untouched")
print("PASS: "..checks.." guild dry-run materials, holds, UI, reload and no-award assertions")
