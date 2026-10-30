-- Integrated Molten Core Windseeker regression using REAL item catalog
-- and priority engine, rather than stubbed policy logic. Lua 5.1 only.
-- Entirely read-only: RandomRoll and GiveMasterLoot must never run.
local randoms,grants=0,0
RandomRoll=function() randoms=randoms+1;error("preview called RandomRoll") end
GiveMasterLoot=function() grants=grants+1;error("preview called GiveMasterLoot") end
local classes={
    "WARRIOR","PALADIN","HUNTER","ROGUE","MAGE","PRIEST",
    "DRUID","WARLOCK","SHAMAN","DEATHKNIGHT"
}
local classInfo={}
for _,name in ipairs(classes) do
    classInfo[#classInfo+1]={id=name,label=name}
end
local roster={
    Alice="WARRIOR",Bert="ROGUE",Cathy="PALADIN",
    David="MAGE",Erin="HUNTER"
}
local needs={
    a={character="Alice",itemID=18563,status="NEEDED",raidKey="MOLTEN_CORE"},
    b={character="Bert",itemID=18563,status="NEEDED",raidKey="MOLTEN_CORE"},
    c={character="Cathy",itemID=18564,status="GREED",raidKey="MOLTEN_CORE"},
    d={character="David",itemID=18563,status="NEEDED",raidKey="MOLTEN_CORE"},
    e={character="Erin",itemID=18563,status="DISABLED",raidKey="MOLTEN_CORE"},
}
local N={
    classes=classInfo,
    roles={{id="MAIN_TANK"},{id="TANK"},{id="HEALER"},
       {id="MELEE_DPS"},{id="RANGED_PHYSICAL_DPS"},
       {id="CASTER_DPS"}},
    Data={},
    db={gearNeeds=needs,priorityRules={},
        settings={priorityPresetsEnabled=false}},
    DebugSimulator={IsActive=function() return false end},
    IsValidClass=function(_,name) return roster[name]~=nil or
        name=="WARRIOR" or name=="PALADIN" or name=="HUNTER" or
        name=="ROGUE" or name=="MAGE" end,
    roleLabels={},
    NeedMatcher={
        GetMatchesForItem=function(_,id,status)
            local out={}
            status=status or "NEEDED"
            for _,n in pairs(needs) do
                if n.itemID==id and n.status==status then
                    out[#out+1]={character=n.character,
                        interestStatus=status,classFile=roster[n.character],
                        inRaid=true,online=true,eligiblePresence=true}
                end
            end
            table.sort(out,function(a,b)return a.character<b.character end)
            return out
        end,
    },
    CandidateReview={MergeMatches=function(_,entry,matches)
        return matches
    end,IsExcluded=function()return false end},
}
NaxxLootLottery=N
assert(loadfile("NaxxLootLottery/Data/MoltenCore.lua"))()
assert(loadfile("NaxxLootLottery/Core/PriorityEngine.lua"))()
assert(loadfile("NaxxLootLottery/Core/TicketPlanner.lua"))()
local catalog=N.Data.MoltenCore
local priority=N.PriorityEngine
local planner=N.TicketPlanner
for _,id in ipairs({18563,18564}) do
    local item=catalog:GetItem(id)
    assert(item and item.itemID==id and item.manualOnly and
        item.legendary and item.reservationLottery,
        "real catalog must expose manual award, reserved roll for both halves")
    assert(priority:GetState("MOLTEN_CORE",id)=="MANUAL_ONLY",
        "legacy manual policy must remain authoritative for ordinary awards")
    for _,class in ipairs({"WARRIOR","PALADIN","HUNTER","ROGUE"}) do
        assert(priority:IsClassEligible("MOLTEN_CORE",id,class),
            "real Windseeker allowed class: "..class)
    end
    for _,class in ipairs({"MAGE","PRIEST","WARLOCK","SHAMAN","DRUID"}) do
        assert(not priority:IsClassEligible("MOLTEN_CORE",id,class),
            "ineligible class must not win binding: "..class)
    end
end
local function preview(id)
    return planner:BuildPreview({itemID=id,raidKey="MOLTEN_CORE",
        itemName="Bindings of the Windseeker",dropUID="INTEGRATION:"..id,
        slotIndex=1,state="DETECTED",manualOnly=true})
end
local garr=preview(18564)
assert(garr.ready and garr.selectionType=="GREED" and
    #garr.current==1 and garr.current[1].character=="Cathy",
    "real catalog plus priority must support saved greed-only half")
local baron=preview(18563)
assert(baron.ready and baron.selectionType=="NEED" and
    #baron.current==2 and baron.current[1].character=="Alice" and
    baron.current[2].character=="Bert",
    "saved class-eligible needs only; mage and disabled hunter absent")
assert(#baron.excluded==1 and baron.excluded[1].match.character=="David")
local core=catalog:GetItem(17011)
assert(core and core.manualOnly and not core.reservationLottery)
local material=planner:BuildPreview({itemID=17011,raidKey="MOLTEN_CORE",
    itemName="Lava Core",dropUID="INTEGRATION:17011",
    slotIndex=2,state="DETECTED",manualOnly=true})
assert(not material.ready and
    material.message:find("no normal lottery",1,true),
    "real catalog must never promote Lava Core into an equipment roll")
assert(randoms==0 and grants==0,
    "testing an item policy may not run RandomRoll or GiveMasterLoot")
print("PASS: real Molten Core Windseeker classes / saved roll / material hold")
