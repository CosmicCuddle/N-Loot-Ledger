-- NLL / WoW 3.3.5a Lua 5.1 fallback/off-spec regression.
-- Runs only offline; no WoW loot transfer APIs are called.
local assertions=0
local function check(value,reason)
    assert(value,reason)
    assertions=assertions+1
end
local roster={
    {name="Druzz",classFile="MAGE",online=true,assignedRole="CASTER_DPS"},
    {name="Gorak",classFile="WARRIOR",online=true,assignedRole="MAIN_TANK"},
    {name="Eiga",classFile="PRIEST",online=true,assignedRole="HEALER"},
    {name="Offline",classFile="MAGE",online=false,assignedRole="CASTER_DPS"}
}
local roles={
    {id="MAIN_TANK",label="Main Tank"},
    {id="CASTER_DPS",label="Caster DPS"},
    {id="HEALER",label="Healer"}
}
local classes={
    {id="MAGE"},{id="WARRIOR"},{id="PRIEST"}
}
local rules={
    [100]={
        rolePriority={MAIN_TANK=1,CASTER_DPS=2,HEALER="EXCLUDE"}
    },
    [200]={
        rolePriority={MAIN_TANK=1,CASTER_DPS=2,HEALER="EXCLUDE"}
    }
}
local items={
    [100]={itemID=100,name="Shared Equipment"},
    [200]={itemID=200,name="Mage Only",allowedClasses={MAGE=true}},
    [300]={itemID=300,name="Guild Item",manualOnly=true}
}
local names={}
for _,m in ipairs(roster) do names[m.name]=m end
NaxxLootLottery={
    db={gearNeeds={},gearNeedsSchema=1,priorityRules={MOLTEN_CORE=rules},
        settings={priorityPresetsEnabled=false},lotteryHistory={{status="COMPLETE",winner="Historic"}}},
    roles=roles,classes=classes,roleLabels={
        MAIN_TANK="Main Tank",CASTER_DPS="Caster DPS",HEALER="Healer"},
    IsValidRole=function(_,value) return value=="MAIN_TANK" or value=="CASTER_DPS" or value=="HEALER" end,
    IsValidClass=function(_,value) return value=="MAGE" or value=="WARRIOR" or value=="PRIEST" end,
    GetRoleLabel=function(self,value) return self.roleLabels[value] or "Unassigned" end,
    GetClassLabel=function(_,value) return value or "Unknown" end,
    Debug=function()end,Print=function()end,
    Data={MoltenCore={GetItem=function(_,id) return items[tonumber(id)] end}},
    Roster={GetMembers=function() return roster end,Refresh=function()end},
    Database={
        SetCharacterType=function()end,SetRoleAssignment=function()end,
        GetRoleAssignment=function(_,name) return names[name] and names[name].assignedRole end,
        GetCharacterClass=function(_,name) return names[name] and names[name].classFile end,
        GetCharacterType=function()return "PLAYERBOT" end
    },
    DebugSimulator={IsActive=function() return false end},
    CandidateReview={MergeMatches=function(_,entry,matches) return matches end,
        IsExcluded=function() return false end},
    LootDetection={GetCurrentLoot=function() return {} end}
}
local N=NaxxLootLottery
local function load(path) assert(loadfile("NaxxLootLottery/"..path))() end
load("Core/GearNeeds.lua")
load("Core/NeedMatcher.lua")
load("Core/PriorityEngine.lua")
load("Core/TicketPlanner.lua")
GetTime=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
load("Core/TicketLottery.lua")
local G=N.GearNeeds
local function add(name,id,status,source)
    local m=names[name]
    local success,need=G:AddNeed(name,id,"MOLTEN_CORE",
        m.assignedRole,status,source or "BOT_GEAR_PLAN","PLAYERBOT")
    check(success,"save "..name.."/"..status)
    return need
end
local function preview(id)
    return N.TicketPlanner:BuildPreview({
        itemID=id,itemName="Item",raidKey="MOLTEN_CORE",
        dropUID="drop-"..id,slotIndex=1,state="DETECTED"
    })
end
local main=add("Gorak",100,"NEEDED")
local off=add("Druzz",100,"FALLBACK")
local ghost=add("Offline",100,"FALLBACK")
local excluded=add("Eiga",100,"FALLBACK")
check(G:IsValidStatus("FALLBACK"),"fallback is valid")
check(N.db.gearNeedsSchema==1,"no SavedVariables schema migration")
check(#N.NeedMatcher:GetMatchesForItem(100)==1,"legacy matcher still returns NEEDED only")
check(#N.NeedMatcher:GetMatchesForItem(100,"FALLBACK")==3,"fallback matches separate")
check(#N.NeedMatcher:GetMatchesForReview(100)==4,"leader sees primary and fallback")
local p=preview(100)
check(p.ready and p.chosenTier==1 and #p.current==1 and
    p.current[1].character=="Gorak","normal Tier 1 beats fallback")
check(#p.waiting==1 and p.waiting[1].tier==4,"fallback remains waiting")
check(G:GetNeed(off.key).status=="FALLBACK",
    "fallback saved independently")
check(G:SetStatus(main.key,"OBTAINED"),"primary obtained")
p=preview(100)
check(p.ready and p.chosenTier==4 and #p.current==1 and
    p.current[1].character=="Druzz","fallback only if no primary available")
check(#p.excluded==2,"offline and guild-excluded interests never enter pool")
check(G:SetStatus(main.key,"NEEDED"),"primary restored")
rules[100].rolePriority.MAIN_TANK=3
p=preview(100)
check(p.ready and p.chosenTier==3,"even Tier 3 need beats fallback")
rules[100].rolePriority.MAIN_TANK=1
-- If primary and fallback exist for the same person from separate sources,
-- primary wins; the candidate must never obtain two tickets.
add("Gorak",100,"FALLBACK","RAID_LEADER_MANUAL")
p=preview(100)
check(#p.current==1 and p.current[1].character=="Gorak" and
    #p.waiting==1,"same-character duplicate source is never another ticket")
-- All present primary role/class unknown blocks a fallback roll.
names.Gorak.assignedRole=nil
G:GetNeed(main.key).role=nil
p=preview(100)
check(not p.ready and p.message:find("NEEDED"),"unknown primary blocks fallback")
names.Gorak.assignedRole="MAIN_TANK"
G:GetNeed(main.key).role="MAIN_TANK"
-- Guild/manual items and unconfigured rules must remain manual.
add("Druzz",300,"FALLBACK")
check(not preview(300).ready,"manual-only item cannot fall back")
rules[100]=nil
check(not preview(100).ready,"unconfigured priority blocks fallback")
rules[100]={rolePriority={MAIN_TANK=1,CASTER_DPS=2,HEALER="EXCLUDE"}}
-- Explicit leader exclusions must remain effective for fallback.
G:SetStatus(main.key,"OBTAINED")
N.CandidateReview.IsExcluded=function(_,entry,name) return name=="Druzz" and "Raid leader review" or false end
p=preview(100)
print("DEBUG fallback exclusion",tostring(p.ready),tostring(p.chosenTier),p.message,#p.current,#p.excluded)
for _,row in ipairs(p.current) do print("DEBUG eligible",row.character) end
check(not p.ready and not p.chosenTier,"leader exclusion blocks the only eligible fallback")
N.CandidateReview.IsExcluded=function() return false end
-- Actual item/class restrictions override fallback declarations.
add("Gorak",200,"FALLBACK")
p=preview(200)
check(not p.ready and #p.excluded>0,"wrong-class fallback excluded")
-- A prepared fallback draw cannot proceed after a new legitimate need appears.
G:SetStatus(main.key,"OBTAINED")
p=preview(100)
check(p.ready and p.chosenTier==4,"fallback pool can be prepared")
N.TicketLottery.active={dropUID="drop-100",tier=p.chosenTier,
    candidateKeys={"druzz"},tickets={{number=1,character="Druzz"}},
    status="PREPARED"}
local okay=N.TicketLottery:PoolStillMatches({
    itemID=100,itemName="Item",raidKey="MOLTEN_CORE",
    dropUID="drop-100",slotIndex=1,state="DETECTED"})
check(okay,"unchanged fallback pool valid")
G:SetStatus(main.key,"NEEDED")
okay=N.TicketLottery:PoolStillMatches({
    itemID=100,itemName="Item",raidKey="MOLTEN_CORE",
    dropUID="drop-100",slotIndex=1,state="DETECTED"})
check(not okay,"new NEED invalidates prepared fallback pool")
check(N.db.lotteryHistory[1].winner=="Historic","old winner history untouched")
check(G:GetNeed(off.key).status=="FALLBACK","fallback SavedVariables preserved")
print("PASS: "..assertions.." fallback/off-spec interest assertions")
