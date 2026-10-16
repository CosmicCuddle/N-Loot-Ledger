-- NLL / WoW 3.3.5a Lua 5.1 greed/off-spec regression.
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
local off=add("Druzz",100,"GREED")
local ghost=add("Offline",100,"GREED")
local excluded=add("Eiga",100,"GREED")
check(G:IsValidStatus("GREED"),"greed is valid")
check(N.db.gearNeedsSchema==1,"no SavedVariables schema migration")
check(#N.NeedMatcher:GetMatchesForItem(100)==1,"legacy matcher still returns NEEDED only")
check(#N.NeedMatcher:GetMatchesForItem(100,"GREED")==3,"greed matches separate")
check(#N.NeedMatcher:GetMatchesForReview(100)==4,"leader sees primary and greed")
local p=preview(100)
check(p.ready and p.selectionType=="NEED" and p.chosenTier==1 and #p.current==1 and
    p.current[1].character=="Gorak","normal Tier 1 beats greed")
check(#p.waiting==1 and p.waiting[1].selectionType=="GREED","greed remains waiting")
check(G:GetNeed(off.key).status=="GREED",
    "greed saved independently")
check(G:SetStatus(main.key,"OBTAINED"),"primary obtained")
p=preview(100)
check(p.ready and p.selectionType=="GREED" and p.chosenTier==nil and #p.current==1 and
    p.current[1].character=="Druzz","greed only if no primary available")
check(#p.excluded==2,"offline and guild-excluded interests never enter pool")
-- A legitimate Tier 2 need outranks optional/off-spec interest.
local casterNeed=add("Druzz",100,"NEEDED","RAID_LEADER_MANUAL")
p=preview(100)
check(p.ready and p.selectionType=="NEED" and p.chosenTier==2 and #p.current==1 and
    p.current[1].character=="Druzz","Tier 2 Need beats greed")
-- Tier 2 must also outrank an actual Tier 3 Need, not only Greed.
rules[100].rolePriority.HEALER=3
local tierThree=add("Eiga",100,"NEEDED","RAID_LEADER_MANUAL")
p=preview(100)
check(p.ready and p.chosenTier==2 and
    p.current[1].character=="Druzz" and
    #p.waiting>=1 and p.waiting[1].tier==3,
    "Tier 2 Need beats eligible Tier 3 Need and all Greed")
check(G:SetStatus(tierThree.key,"DISABLED"),"Tier 3 fixture disabled")
rules[100].rolePriority.HEALER="EXCLUDE"
check(G:SetStatus(casterNeed.key,"DISABLED"),"optional secondary source disabled")
-- Several greed contenders must share one equal-priority pool.
local taenir={name="Taenir",classFile="MAGE",online=true,assignedRole="CASTER_DPS"}
table.insert(roster,taenir)
names.Taenir=taenir
local other=add("Taenir",100,"GREED")
p=preview(100)
check(p.ready and p.selectionType=="GREED" and p.chosenTier==nil and #p.current==2 and
    p.current[1].character=="Druzz" and
    p.current[2].character=="Taenir","equal greed contenders share one pool")
-- A missing greed role blocks greed but cannot obstruct a valid Need.
other.role=nil
taenir.assignedRole=nil
p=preview(100)
check(not p.ready and p.message:find("GREED"),"unknown greed role fails closed")
check(G:SetStatus(main.key,"NEEDED"),"primary restored")
p=preview(100)
check(p.ready and p.chosenTier==1,"unresolved greed does not block valid Need")
taenir.assignedRole="CASTER_DPS"
other.role="CASTER_DPS"
check(G:SetStatus(other.key,"DISABLED"),"additional greed disabled for later tests")
rules[100].rolePriority.MAIN_TANK=3
p=preview(100)
check(p.ready and p.selectionType=="NEED" and p.chosenTier==3,"even Tier 3 need beats greed")
rules[100].rolePriority.MAIN_TANK=1
-- If primary and greed exist for the same person from separate sources,
-- primary wins; the candidate must never obtain two tickets.
local secondary=add("Gorak",100,"GREED","RAID_LEADER_MANUAL")
p=preview(100)
check(#p.current==1 and p.current[1].character=="Gorak" and
    #p.waiting==1,"same-character duplicate source is never another ticket")
check(G:SetStatus(secondary.key,"DISABLED"),"secondary source disabled for later fixtures")
-- All present primary role/class unknown blocks a greed roll.
names.Gorak.assignedRole=nil
G:GetNeed(main.key).role=nil
p=preview(100)
check(not p.ready and p.message:find("NEED"),"unknown primary blocks greed")
names.Gorak.assignedRole="MAIN_TANK"
G:GetNeed(main.key).role="MAIN_TANK"
-- Guild/manual items and unconfigured rules must remain manual.
add("Druzz",300,"GREED")
check(not preview(300).ready,"manual-only item cannot fall back")
rules[100]=nil
check(not preview(100).ready,"unconfigured priority blocks greed")
rules[100]={rolePriority={MAIN_TANK=1,CASTER_DPS=2,HEALER="EXCLUDE"}}
-- Explicit leader exclusions must remain effective for greed.
G:SetStatus(main.key,"OBTAINED")
N.CandidateReview.IsExcluded=function(_,entry,name) return name=="Druzz" and "Raid leader review" or false end
p=preview(100)
check(not p.ready and not p.chosenTier,"leader exclusion blocks the only eligible greed")
N.CandidateReview.IsExcluded=function() return false end
-- Actual item/class restrictions override greed declarations.
add("Gorak",200,"GREED")
p=preview(200)
check(not p.ready and #p.excluded>0,"wrong-class greed excluded")
-- A prepared greed draw cannot proceed after a new legitimate need appears.
G:SetStatus(main.key,"OBTAINED")
p=preview(100)
check(p.ready and p.selectionType=="GREED" and p.chosenTier==nil,"greed pool can be prepared")
N.TicketLottery.active={dropUID="drop-100",tier=p.chosenTier,
    selectionType="GREED",candidateKeys={"druzz"},tickets={{number=1,character="Druzz"}},
    status="PREPARED"}
local okay=N.TicketLottery:PoolStillMatches({
    itemID=100,itemName="Item",raidKey="MOLTEN_CORE",
    dropUID="drop-100",slotIndex=1,state="DETECTED"})
check(okay,"unchanged greed pool valid")
G:SetStatus(main.key,"NEEDED")
okay=N.TicketLottery:PoolStillMatches({
    itemID=100,itemName="Item",raidKey="MOLTEN_CORE",
    dropUID="drop-100",slotIndex=1,state="DETECTED"})
check(not okay,"new NEED invalidates prepared greed pool")
check(N.db.lotteryHistory[1].winner=="Historic","old winner history untouched")
check(G:GetNeed(off.key).status=="GREED","greed SavedVariables preserved")
-- A leader manually adding a Greed character must not silently promote it.
N.TicketLottery.liveLootObserved=true
N.TicketLottery.AuthorityAllowed=function()return true end
load("Core/CandidateReview.lua")
local auditBefore=#(N.db.candidateAudit or {})
local allow,reason=N.CandidateReview:AddCandidate({
    dropUID="drop-100",state="DETECTED",itemID=100,
    raidKey="MOLTEN_CORE",slotIndex=1,itemName="Item"}, "Druzz")
check(not allow and reason:find("GREED"),
    "drop-scoped manual Add Candidate cannot bypass Greed interest")
check(#(N.db.candidateAudit or {})==auditBefore,
    "blocked Greed-to-Need promotion creates no misleading audit")
-- Also reject a stale manual candidate cached *before* a Gear Plan became Greed.
local drop={dropUID="drop-100",state="DETECTED",itemID=100,
    raidKey="MOLTEN_CORE",slotIndex=1,itemName="Item"}
local reviewState=N.CandidateReview:GetState(drop)
reviewState.manual.druzz={character="Druzz",role="CASTER_DPS",
    classFile="MAGE",manualAddition=true}
local reviewed=N.CandidateReview:MergeMatches(drop,
    N.NeedMatcher:GetMatchesForItem(100))
for _,match in ipairs(reviewed) do
    check(match.character~="Druzz",
        "cached manual candidate cannot bypass newly saved Greed")
end
reviewState.manual.druzz=nil
-- Exercise the *real* TicketLottery:Finish path, not merely the preview.
-- No RandomRoll or GiveMasterLoot is called in this offline verification.
local activeDrop={itemID=100,itemName="Shared Equipment",raidKey="MOLTEN_CORE",
    dropUID="greed-finish",slotIndex=1,state="DETECTED"}
N.LootDetection.GetCurrentLoot=function()return {activeDrop}end
G:SetStatus(main.key,"OBTAINED")
local ready=N.TicketPlanner:BuildPreview(activeDrop)
check(ready.ready and ready.selectionType=="GREED" and
    #ready.current==1,"Greed ready for real-ticket result revalidation")
local function pending(entry,result)
    local keys,tickets={},{}
    for i,m in ipairs(result.current) do
        keys[i]=string.lower(m.character)
        tickets[i]={number=i,character=m.character}
    end
    N.TicketLottery.active={
        status="WAITING_FOR_ROLL",dropUID=entry.dropUID,itemID=entry.itemID,
        itemName=entry.itemName,raidKey=entry.raidKey,boss="Ragnaros",
        selectionType=result.selectionType,tier=result.chosenTier,
        tickets=tickets,candidateKeys=keys,test=false
    }
end
local oldHistory=N.db.lotteryHistory[1]
pending(activeDrop,ready)
local finished=N.TicketLottery:Finish(1,"SERVER_RANDOM_ROLL")
check(finished,"unchanged Greed draw completes through real finish code")
check(N.TicketLottery.active.status=="COMPLETE" and
    N.TicketLottery.active.winner=="Druzz" and
    N.TicketLottery.active.selectionType=="GREED" and
    N.TicketLottery.active.tier==nil,"Greed winner never masquerades as Need tier")
local latest=N.db.lotteryHistory[#N.db.lotteryHistory]
check(latest.status=="COMPLETE" and latest.selectionType=="GREED" and
    latest.tier==nil and latest.winner=="Druzz",
    "real ticket history records Greed stage with no fourth tier")
check(N.db.lotteryHistory[1]==oldHistory and
    oldHistory.winner=="Historic","new Greed result preserves old history")
check(not N.TicketLottery:Finish(1,"SERVER_RANDOM_ROLL"),
    "same finished drop cannot finish twice")
-- If a Need appears AFTER Start Roll but BEFORE its result, fail closed.
local lateDrop={itemID=100,itemName="Shared Equipment",raidKey="MOLTEN_CORE",
    dropUID="late-need",slotIndex=1,state="DETECTED"}
N.LootDetection.GetCurrentLoot=function()return {lateDrop}end
ready=N.TicketPlanner:BuildPreview(lateDrop)
check(ready.ready and ready.selectionType=="GREED","late Need test starts in Greed")
pending(lateDrop,ready)
G:SetStatus(main.key,"NEEDED")
finished=N.TicketLottery:Finish(1,"SERVER_RANDOM_ROLL")
check(not finished and
    N.TicketLottery.active.status=="ROLL_UNCONFIRMED" and
    N.TicketLottery.active.winner==nil,
    "late Need prevents a Greed server roll result being accepted")
latest=N.db.lotteryHistory[#N.db.lotteryHistory]
check(latest.status=="UNVERIFIED" and latest.winner==nil and
    latest.selectionType=="GREED",
    "unaccepted result is audited, not saved as a second winner")
check(N.db.lotteryHistory[1]==oldHistory,
    "late Need guard never erases historical results")
-- An unverified/changed server roll must be explicitly cancelled.
local cancelled,message=N.TicketLottery:Cancel("Pool changed mid-roll")
check(cancelled and N.TicketLottery.active==nil,
    "unverified result can only be cleared by audited cancellation")
latest=N.db.lotteryHistory[#N.db.lotteryHistory]
check(latest.status=="CANCELLED" and latest.selectionType=="GREED" and
    latest.winner==nil,"cancelled Greed result does not invent a winner")
-- No stored plan is enough to place a character in a real raid.
local absentOkay,absent=G:AddNeed("AbsentBot",100,"MOLTEN_CORE",
    "CASTER_DPS","GREED","BOT_GEAR_PLAN","PLAYERBOT")
check(absentOkay,"save absent bot Greed plan for preflight")
G:SetStatus(main.key,"OBTAINED")
p=preview(100)
check(p.ready and p.selectionType=="GREED" and
    #p.current==1 and p.current[1].character=="Druzz",
    "missing raid member does not gain a Greed ticket")
local absentFound=false
for _,row in ipairs(p.excluded) do
    if row.match.character=="AbsentBot" and
        row.reason=="Not present/online" then absentFound=true end
end
check(absentFound,"absent Greed bot has explicit exclusion reason")
-- Unknown class is unresolved, not an eligible Greed player.
names.Druzz.classFile=nil
p=preview(100)
check(not p.ready and #p.greedUnresolved>0 and
    p.message:find("GREED"),"invalid live/saved class blocks Greed")
names.Druzz.classFile="MAGE"
p=preview(100)
check(p.ready and p.selectionType=="GREED",
    "restoring verified class restores Greed-only preview")
print("PASS: "..assertions.." greed/off-spec interest assertions")
