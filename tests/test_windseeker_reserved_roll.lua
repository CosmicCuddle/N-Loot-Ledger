-- NLL Windseeker reservation-only equal roll gate (WoW Lua 5.1).
-- No real loot, random rolls or item transfers.
local grants,rolls=0,0
GiveMasterLoot=function()grants=grants+1;error("do not award")end
RandomRoll=function()rolls=rolls+1;error("preview cannot roll")end
local entries={
    [18563]={itemID=18563,name="Bindings of the Windseeker",
        manualOnly=true,legendary=true,reservationLottery=true},
    [18564]={itemID=18564,name="Bindings of the Windseeker",
        manualOnly=true,legendary=true,reservationLottery=true},
    [17010]={itemID=17010,name="Fiery Core",manualOnly=true},
}
local function plan(id,name,status)
    return {itemID=id,character=name,status=status,raidKey="MOLTEN_CORE"}
end
local saved={
    a=plan(18563,"Warrior","NEEDED"),
    b=plan(18563,"Rogue","NEEDED"),
    c=plan(18563,"Mage","NEEDED"),
    d=plan(18563,"Paladin","GREED"),
    e=plan(18564,"Paladin","GREED"),
}
local function match(name,status,classFile,online)
    return {character=name,interestStatus=status,classFile=classFile,
        inRaid=true,online=online~=false,eligiblePresence=online~=false}
end
NaxxLootLottery={
    db={gearNeeds=saved},
    Data={MoltenCore={GetItem=function(_,id)return entries[id]end}},
    DebugSimulator={IsActive=function()return false end},
    PriorityEngine={
        STATUS={MANUAL_ONLY="MANUAL_ONLY",CONFIGURED="CONFIGURED"},
        EXCLUDE="EXCLUDE",
        GetState=function()return "MANUAL_ONLY" end,
        IsClassEligible=function(_,_,_,classFile)
            return classFile=="WARRIOR" or classFile=="ROGUE" or
                classFile=="HUNTER" or classFile=="PALADIN"
        end,
        GetCandidatePriority=function()
            error("Legendary no role ranking allowed")
        end,
    },
    IsValidClass=function(_,c)return type(c)=="string" and c~="" end,
    roleLabels={},
    NeedMatcher={GetMatchesForItem=function(_,id,status)
        status=status or "NEEDED"
        if id==18563 then
            if status=="NEEDED" then
                return {match("Warrior",status,"WARRIOR"),
                    match("Rogue",status,"ROGUE"),
                    match("Mage",status,"MAGE")}
            end
            return {match("Paladin",status,"PALADIN")}
        elseif id==18564 and status=="GREED" then
            return {match("Paladin",status,"PALADIN")}
        end
        return {}
    end},
    CandidateReview={
        MergeMatches=function(_,entry,matches)
            local result={}
            for _,v in ipairs(matches) do result[#result+1]=v end
            result[#result+1]=match("NoSaved", "NEEDED","HUNTER")
            return result
        end,
        IsExcluded=function()return false end
    },
}
assert(loadfile("NaxxLootLottery/Core/TicketPlanner.lua"))()
local P=NaxxLootLottery.TicketPlanner
local function preview(id,simulated)
    return P:BuildPreview({itemID=id,itemName="item",raidKey="MOLTEN_CORE",
        state=simulated and "SIMULATED_DROP" or "DETECTED",
        simulationOnly=simulated==true,manualOnly=true,
        slotIndex=1,dropUID="L1:"..id},nil,
        simulated and {simulation=true} or nil)
end
local p=preview(18563)
assert(p.ready and p.selectionType=="NEED" and p.chosenTier==1)
assert(#p.current==2 and #p.waiting==1 and #p.excluded==2)
assert(p.current[1].character=="Rogue" and p.current[2].character=="Warrior")
assert(p.message:find("WINDSEEKER") and rolls==0 and grants==0)
-- Off-spec is permitted only after all active NEED reservations are gone.
p=preview(18564)
assert(p.ready and p.selectionType=="GREED" and #p.current==1)
assert(p.current[1].character=="Paladin" and p.chosenTier==nil)
p=preview(17010)
assert(not p.ready and p.message:find("no normal lottery"))
p=preview(18563,true)
assert(not p.ready and rolls==0 and grants==0)
saved.a.status="OBTAINED";saved.b.status="OBTAINED";saved.c.status="OBTAINED"
saved.d.status="OBTAINED"
p=preview(18563)
assert(not p.ready and #p.current==0 and #p.waiting==0 and grants==0)
print("PASS: only saved, eligible Windseeker interests enter equal guarded tickets")
