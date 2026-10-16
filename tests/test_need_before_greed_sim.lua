-- WoW 3.3.5a Lua 5.1: mixed 40-player NEED/GREED simulator.
-- Must not touch the saved loot ledger or transfer any items.
local count=0
local function ok(v,why) assert(v,why);count=count+1 end
local roles={"MAIN_TANK","TANK","MELEE_DPS","RANGED_PHYSICAL_DPS","CASTER_DPS","HEALER"}
local classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST",
    "DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","DRUID"}
local roleLabels={}
local rolesAsObjects,classesAsObjects={},{}
for _,role in ipairs(roles) do
    roleLabels[role]=role
    rolesAsObjects[#rolesAsObjects+1]={id=role,label=role}
end
for _,class in ipairs(classes) do
    classesAsObjects[#classesAsObjects+1]={id=class}
end
local db={settings={debug=true},gearNeeds={historical={status="OBTAINED"}},
    lootAwardHistory={{winner="HistoricalWinner"}},lotteryHistory={{winner="OldRoll"}},
    localWishlists={Owner={MOLTEN_CORE={[16800]=true}}}}
local refs={gear=db.gearNeeds,award=db.lootAwardHistory,
    lottery=db.lotteryHistory,wishlist=db.localWishlists.Owner.MOLTEN_CORE}
NaxxLootLottery={
    db=db,roles=rolesAsObjects,classes=classesAsObjects,roleLabels=roleLabels,
    UI={},Debug=function()end,Print=function()end,
    GetClassLabel=function(_,class) return class end,
    GetRoleLabel=function(_,role) return role end,
    IsValidClass=function(_,class)
        for _,v in ipairs(classes) do if v==class then return true end end
        return false
    end,
    Data={MoltenCore={GetItem=function(_,id)
        if tonumber(id) then return {itemID=id,name="MC Item "..id,manualOnly=false} end
    end}},
    PriorityEngine={
        EXCLUDE="EXCLUDE",
        GetCustomRule=function() return nil end,
        GetUnsetRoleCount=function() return 0 end,
        GetEffectiveClassEligibility=function()
            local all={}
            for _,class in ipairs(classes) do all[class]=true end
            return all
        end,
        IsClassEligible=function() return true end
    },
    PrioritySuggestions={GetSuggestion=function()
        local policy={}
        for _,role in ipairs(roles) do policy[role]=2 end
        return {rolePriority=policy}
    end}
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/DebugSimulator.lua"))()
assert(loadfile("NaxxLootLottery/Core/TicketPlanner.lua"))()
local S=N.DebugSimulator
local good,why=S:Start("mc40greed")
ok(good,why)
ok(#S:GetPlayers()==40 and #S.active.entries==13,"full 40-bot MC test fixture")
ok(S.active.players[1].subgroup==1 and S.active.players[40].subgroup==8,
    "40 fake characters in eight groups")
local first=S:Preview()
ok(first.ready and first.selectionType=="NEED" and first.chosenTier~=nil,
    "original Need stage works on early class loot")
good,why=S:SelectDrop(13)
ok(good and S.active.itemID==18821,why)
local greedMatches=S:FakeMatches("GREED")
ok(#greedMatches>=2,"two or more Greed candidates")
ok(#S:FakeMatches("NEEDED")==0,"no Need candidate for test drop")
local preview=S:Preview()
ok(preview.ready and preview.selectionType=="GREED" and preview.chosenTier==nil,
    "Greed is a separate stage with no fourth Need tier")
ok(#preview.current>=2,"equal Greed pool has multiple tickets")
local plans=S:GetNeeds()
local found=0
for _,plan in ipairs(plans) do
    if plan.itemID==18821 then
        ok(plan.state=="GREED","fake Gear Plans label Greed correctly")
        found=found+1
    end
end
ok(found>=2,"fake Gear Plans contain Greed entries")
good,why=S:Prepare()
ok(good and S.active.prepared.selectionType=="GREED",why)
-- A last-minute raid change invalidates the already prepared lottery.
local firstGreed=S.active.prepared.tickets[1].character
good,why=S:SetOnline(firstGreed,false)
ok(good,why)
good,why=S:Roll()
ok(not good and not S.active.prepared,"fake changed pool rejected at roll time")
good,why=S:SetOnline(firstGreed,true)
ok(good,why)
good,why=S:Prepare()
ok(good,why)
good,why=S:Roll()
ok(good,why)
ok(S.active.result.selectionType=="GREED" and
    S.active.result.tier==nil,"fake winner records Greed, not Tier 4")
good,why=S:Roll()
ok(not good,"fake copy cannot receive a second winner")
good,why=S:ConfirmAward()
ok(good,why)
ok(S.active.result.awardStatus=="SIMULATED_AWARDED","fake award only")
ok(db.gearNeeds==refs.gear and db.lootAwardHistory==refs.award and
   db.lotteryHistory==refs.lottery and
   db.localWishlists.Owner.MOLTEN_CORE==refs.wishlist and
   db.lootAwardHistory[1].winner=="HistoricalWinner",
   "all saved tables/old winner history preserve original identity")
S:Stop()
ok(not S:IsActive(),"simulation exits cleanly")
-- Existing MC40 is unaffected by the new mixed fixture.
good,why=S:Start("mc40")
ok(good,why)
good,why=S:SelectDrop(13)
ok(good,why)
preview=S:Preview()
ok(preview.ready and preview.selectionType=="NEED" and
    preview.chosenTier~=nil,"original MC40 uses Need for Quick Strike Ring")
S:Stop()
print("PASS: "..count.." mixed-40 Need Before Greed simulator assertions")
