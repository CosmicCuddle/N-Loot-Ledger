-- ============================================================
-- Naxxramas Loot Ledger - GuildLootReview (READ-ONLY)
-- Prepares the leader's review of all item slots, including
-- materials/recipes absent from the supported-raid lottery DB.
-- NEVER calls GiveMasterLoot, changes SavedVariables or assumes a
-- missing player reservation is proof that loot is unreserved.
-- ============================================================
local NLL=NaxxLootLottery
NLL.GuildLootReview=NLL.GuildLootReview or {}
local G=NLL.GuildLootReview

local function NameKey(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
local function ItemID(link)
    return type(link)=="string" and tonumber(link:match("item:(%d+)")) or nil
end
local function LinkName(link)
    return type(link)=="string" and link:match("%[([^%]]+)%]") or nil
end

function G:GetLeader()
    if type(GetNumRaidMembers)~="function" or
       type(GetRaidRosterInfo)~="function" or
       (GetNumRaidMembers() or 0)<1 then
        return nil
    end
    local leader
    for i=1,GetNumRaidMembers() do
        local name,rank=GetRaidRosterInfo(i)
        if name and rank==2 then
            if leader then return nil end -- refuse ambiguous raid leadership
            leader=name
        end
    end
    return leader
end

function G:GetReservationSummary(itemID)
    local db=NLL.db
    local summary={need=0,greed=0,unknown=0,localCount=0,
        incoming=0,activeNames={}}
    if not db or type(db.gearNeeds)~="table" or
       type(db.localWishlists)~="table" or
       type(db.submissionInbox)~="table" then
        summary.unknown=1
        return summary
    end
    local names={}
    for _,row in pairs(db.gearNeeds) do
        if type(row)=="table" and tonumber(row.itemID)==itemID and
           (row.raidKey=="MOLTEN_CORE" or row.raid=="Molten Core") then
            if row.status=="NEEDED" then summary.need=summary.need+1
            elseif row.status=="GREED" then summary.greed=summary.greed+1
            elseif row.status~="OBTAINED" and row.status~="DISABLED" then
                summary.unknown=summary.unknown+1
            end
            if row.status=="NEEDED" or row.status=="GREED" then
                local n=NameKey(row.character)
                if n~="" and not names[n] then
                    names[n]=true
                    summary.activeNames[#summary.activeNames+1]=row.character
                elseif n=="" then
                    summary.unknown=summary.unknown+1
                end
            end
        end
    end
    table.sort(summary.activeNames,function(a,b)
        return string.lower(a)<string.lower(b)
    end)
    -- An unsubmitted local wishlist is not proof of a reservation
    -- accepted by the raid leader, but MUST block automatic routing.
    for _,raids in pairs(db.localWishlists) do
        if type(raids)=="table" then
            local mc=raids.MOLTEN_CORE
            if type(mc)=="table" and mc[itemID]==true then
                summary.localCount=summary.localCount+1
            end
        end
    end
    for _,submission in pairs(db.submissionInbox) do
        if type(submission)=="table" and
           submission.raidKey=="MOLTEN_CORE" and
           submission.status=="PENDING" then
            for _,id in ipairs(submission.itemIDs or {}) do
                if tonumber(id)==itemID and
                   not (submission.excluded and submission.excluded[itemID]) then
                    summary.incoming=summary.incoming+1
                    break
                end
            end
        end
    end
    return summary
end

function G:Classify(itemID, quality, itemType)
    local mc=NLL.Data and NLL.Data.MoltenCore
    local item=mc and mc:GetItem(itemID) or nil
    local classification=itemType or "Unclassified item"
    if item and mc.IsRecipeItem and mc:IsRecipeItem(item) then
        classification="Recipe"
    end
    if item and (item.legendary or item.manualOnly) or
       (type(quality)=="number" and quality>=5) then
        return "SPECIAL_HOLD",classification,"Legendary/manual/special: leader review only"
    end
    if type(quality)~="number" or not itemType then
        return "INFORMATION_MISSING",classification,"Item type/quality unknown; manual review"
    end
    return nil,classification,nil
end

function G:Scan()
    local rows={}
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return rows,"Fake raid active: guild loot requires live WoW corpse"
    end
    if not NLL.LootDetection or not NLL.LootDetection.lootOpen or
       not NLL.TicketLottery or
       not NLL.TicketLottery.liveLootObserved then
        return rows,"CORPSE CLOSED: guild loot review requires REAL open loot"
    end
    if type(GetNumLootItems)~="function" or
       type(GetLootSlotLink)~="function" then
        return rows,"WoW loot-slot APIs unavailable"
    end
    local leader=self:GetLeader()
    if not leader then
        return rows,"Raid leader unavailable/ambiguous - no allocation decisions"
    end
    local allCount=GetNumLootItems() or 0
    local ignored=0
    for slot=1,allCount do
        local link=GetLootSlotLink(slot)
        local id=ItemID(link)
        if id then
            local quantity,locked=1,false
            if type(GetLootSlotInfo)=="function" then
                local _,_,count,_,isLocked=GetLootSlotInfo(slot)
                quantity=tonumber(count) or 1
                locked=isLocked==true
            end
            local name,quality,itemType
            if type(GetItemInfo)=="function" then
                local itemName,_,itemQuality,_,_,itemClass=
                    GetItemInfo(id)
                name=itemName
                quality=itemQuality
                itemType=itemClass
            end
            local category,reason
            category,_,reason=self:Classify(id,quality,itemType)
            local summary=self:GetReservationSummary(id)
            local status
            if locked or quantity<1 then
                status="LOCKED"
                reason="Loot slot is locked or empty"
            elseif category=="SPECIAL_HOLD" then
                status="SPECIAL_HOLD"
            elseif summary.need>0 or summary.greed>0 then
                status="RESERVED"
                reason=summary.need.." NEED, "..summary.greed.." GREED (including absent bots/players)"
            elseif summary.unknown>0 or summary.localCount>0 or summary.incoming>0 then
                status="UNRESOLVED"
                reason="Unknown records/local wishlist/pending Inbox - do not auto-route"
            elseif category=="INFORMATION_MISSING" then
                status="UNRESOLVED"
            else
                status="GUILD_REVIEW"
                reason="No saved NEED/GREED found; VERIFY with guild before directing to leader"
            end
            rows[#rows+1]={
                itemID=id,itemName=name or LinkName(link) or ("Item "..id),
                itemLink=link,slotIndex=slot,quantity=quantity,
                category=itemType or "Unclassified item",status=status,
                reason=reason or "Manual review",leader=leader,
                need=summary.need,greed=summary.greed,
                localCount=summary.localCount,pending=summary.incoming,
                -- Candidate verification and item delivery are NOT performed.
                recipientVerified=false,transferAuthorized=false,
            }
        else
            ignored=ignored+1
        end
    end
    return rows,("Read-only guild loot: "..#rows.." item slots, "..
        ignored.." non-item slot(s). Nothing transferred.")
end
