-- NLL / WoW 3.3.5a Lua 5.1.
-- Profession recipe review: read-only and never a recipient proof.
-- Recipe interests are NOT evidence of known skill, specialization,
-- recipe-learning eligibility, inventory receipt or actual item delivery.
local NLL=NaxxLootLottery
NLL.ProfessionRecipeReview=NLL.ProfessionRecipeReview or {}
local R=NLL.ProfessionRecipeReview

-- Exact Molten Core catalog IDs. Skill values and profession category are
-- for offline human review, not permission to award a physical item.
-- A specialization that is NOT VERIFIED is never inferred as "none needed".
local REQUIREMENTS={
    [18264]={profession="Blacksmithing",skill=300},
    [18292]={profession="Engineering",skill=300},
    [18291]={profession="Engineering",skill=300},
    [18290]={profession="Engineering",skill=300},
    [18259]={profession="Enchanting",skill=300},
    [18260]={profession="Enchanting",skill=300},
    [18252]={profession="Leatherworking",skill=300},
    [18265]={profession="Tailoring",skill=300},
    [21371]={profession="Tailoring",skill=300},
    [18257]={profession="Alchemy",skill=300},
}
R.RECIPE_COUNT=10

local function VerifiedCatalogItem(id)
    local mc=NLL.Data and NLL.Data.MoltenCore
    if not mc or not mc.GetItem or not mc.IsRecipeItem then return nil end
    local item=mc:GetItem(id)
    if not item or not mc:IsRecipeItem(item) or
       item.manualOnly~=true then return nil end
    return item
end

function R:ListRecipes()
    local result={}
    for id,requirement in pairs(REQUIREMENTS) do
        local item=VerifiedCatalogItem(id)
        if item then
            result[#result+1]={
                itemID=id,name=item.name,
                profession=requirement.profession,skill=requirement.skill,
                requiredProfessionKnown=true,
                specializationVerified=false,
                specializationRequirement="Check exact recipe and IP/3.3.5a rules",
                manualOnly=true,autoEligible=false,
                transferAuthorized=false,
            }
        end
    end
    table.sort(result,function(a,b)
        if a.profession~=b.profession then
            return a.profession<b.profession
        end
        return a.name<b.name
    end)
    return result
end

function R:Build(itemID)
    local id=tonumber(itemID)
    if not id or id%1~=0 or not REQUIREMENTS[id] then
        return nil,"Not an inventoried Molten Core profession recipe."
    end
    local item=VerifiedCatalogItem(id)
    if not item then
        return nil,"Recipe is not present as manual-only MC data; no review."
    end
    local r=REQUIREMENTS[id]
    local result={
        itemID=id,name=item.name,profession=r.profession,
        requiredSkill=r.skill,
        manualOnly=true,autoEligible=false,transferAuthorized=false,
        recipientVerified=false,professionVerified=false,
        skillVerified=false,specializationVerified=false,
        learnedAlreadyVerified=false,
        status="MANUAL_REVIEW_ONLY",
        candidates={},need=0,greed=0,obtained=0,disabled=0,
        message="Reservations are NOT profession proof. Verify skill 300, "..
            "specialisation, already-learned recipe and intended recipient "..
            "in the actual WoW/IP client before manual guild allocation.",
    }
    local gear=NLL.db and NLL.db.gearNeeds
    if type(gear)=="table" then
        for _,plan in pairs(gear) do
            if type(plan)=="table" and tonumber(plan.itemID)==id
               and plan.raidKey=="MOLTEN_CORE"
               and type(plan.character)=="string"
               and plan.character~="" and
               (plan.source=="BOT_GEAR_PLAN" or
                plan.source=="PLAYER_SUBMITTED" or
                plan.source=="RAID_LEADER_MANUAL") then
                local status=plan.status
                if status=="NEEDED" or status=="GREED" or
                   status=="OBTAINED" or status=="DISABLED" then
                    local candidate={
                        character=plan.character,source=plan.source,
                        characterType=plan.characterType or "UNKNOWN",
                        interest=status,
                        profession="UNVERIFIED",skill="UNVERIFIED",
                        specialization="UNVERIFIED",recipeKnown="UNVERIFIED",
                        eligible=false,awardAuthorized=false,
                    }
                    result.candidates[#result.candidates+1]=candidate
                    if status=="NEEDED" then result.need=result.need+1
                    elseif status=="GREED" then result.greed=result.greed+1
                    elseif status=="OBTAINED" then result.obtained=result.obtained+1
                    else result.disabled=result.disabled+1 end
                end
            end
        end
    end
    table.sort(result.candidates,function(a,b)
        local x,y=string.lower(a.character),string.lower(b.character)
        if x~=y then return x<y end
        if a.source~=b.source then return a.source<b.source end
        return a.interest<b.interest
    end)
    return result
end
