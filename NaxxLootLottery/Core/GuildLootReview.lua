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

-- Explicit guild-store whitelist; never infer that every item with no
-- NLL reservation should be automatically sent to the guild master.
local GUILD_MATERIALS={
    [17011]=true, -- Lava Core
    [17010]=true, -- Fiery Core
    [17012]=true, -- Core Leather
    [11382]=true, -- Blood of the Mountain
    [7075]=true,  -- Core of Earth (may be absent from MC curated list)
}
function G:IsGuildMaterial(itemID)
    return GUILD_MATERIALS[tonumber(itemID)]==true
end

-- Owner-approved new raid-leader-only ticket route for these five guild
-- material IDs. This never overrides a real existing reservation,
-- quest/special classification, loot threshold, item metadata, or past
-- physical transfer attempts. Scan remains the single live policy source.
function G:LeaderTicketRecipient(entry)
    if type(entry)~="table" or entry.state~="DETECTED" or
       entry.simulationOnly or entry.identityUncertain or
       not self:IsGuildMaterial(entry.itemID) or
       type(entry.dropUID)~="string" or entry.dropUID=="" or
       type(entry.slotIndex)~="number" or entry.slotIndex<1 then
        return nil,"Not an unambiguous live guild-material drop."
    end
    if type(GetLootMethod)~="function" or GetLootMethod()~="master" then
        return nil,"WoW Master Loot must be active for raid-leader guild tickets."
    end
    if NLL.GuildLootTransfer and
       NLL.GuildLootTransfer:IsUnresolved() then
        return nil,"Earlier physical loot request remains unresolved. Confirm receipt first."
    end
    if NLL.GuildLootTransfer and
       NLL.GuildLootTransfer:WasAttempted(entry.itemID,entry.slotIndex) then
        return nil,"A guild transfer for this material ID was already attempted. NO RETRY."
    end
    -- A previous standard winner-award request can target the same
    -- physical material as a later leader-only attempt. WoW 3.3.5a
    -- exposes no authenticated corpse-source token to the addon;
    -- the same item ID in another slot is NOT proof of a new copy.
    -- Check immutable write-ahead locks as well as older audit rows
    -- (history is capped; locks intentionally are not).
    for _,attempt in pairs(NLL.db and NLL.db.awardAttemptLocks or {}) do
        if type(attempt)=="table" and
           tonumber(attempt.itemID)==tonumber(entry.itemID) then
            return nil,"A standard Master Loot request already attempted this material ID. NO RETRY without verified corpse identity."
        end
    end
    for _,audit in ipairs(NLL.db and NLL.db.lootAwardHistory or {}) do
        if type(audit)=="table" and
           tonumber(audit.itemID)==tonumber(entry.itemID) and
           (audit.status=="AWARD_REQUESTED" or
            audit.status=="AWARD_OUTCOME_UNKNOWN" or
            audit.status=="LOOT_SLOT_CLEARED") then
            return nil,"Previous winner Master Loot request for this material ID. NO RETRY."
        end
    end
    local rows=self:Scan()
    for _,row in ipairs(rows or {}) do
        if row.slotIndex==entry.slotIndex and
           row.itemID==entry.itemID then
            if row.itemLink~=entry.itemLink or
               row.quantity~=entry.quantity then
                return nil,"Live material link/stack changed; reopen review."
            end
            if row.status~="GUILD_REVIEW" then
                return nil,row.reason or row.status or "Material held."
            end
            local leader=row.leader
            if type(leader)~="string" or leader=="" then
                return nil,"The raid leader cannot be uniquely verified."
            end
            return leader,"Leader-only guild-material ticket."
        end
    end
    return nil,"Guild material is absent from the live loot window."
end

-- This is the GUILD MASTER (rankIndex 0), not the raid leader (rank 2).
-- Roster might be missing/stale on 3.3.5a; fail closed instead of
-- guessing. Verify one online guild master is in the current raid.
function G:GetGuildMaster()
    if type(GetNumGuildMembers)~="function" or
       type(GetGuildRosterInfo)~="function" or
       type(GetNumRaidMembers)~="function" or
       type(GetRaidRosterInfo)~="function" then
        return nil
    end
    local master
    for i=1,(GetNumGuildMembers() or 0) do
        local name,_,rank,_,_,_,_,_,online=GetGuildRosterInfo(i)
        if name and rank==0 then
            if master or online~=true then return nil end
            master=name
        end
    end
    if not master then return nil end
    local count=0
    for i=1,(GetNumRaidMembers() or 0) do
        local member=GetRaidRosterInfo(i)
        if member and NameKey(member)==NameKey(master) then
            count=count+1
        end
    end
    return count==1 and master or nil
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
        incoming=0,receiptPending=0,activeNames={}}
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
    -- The live Gear Plan may disappear or be changed AFTER a real
    -- winner is recorded. Persistent receipt rows, not just current
    -- plans, must hold the next copy until physical delivery is checked.
    -- A leader-side human OBTAINED requires the REMOTE player's own ACK.
    -- Reading these ledgers MUST NOT create local wishlist tables.
    for _,receipt in pairs(db.lootReceiptTracker or {}) do
        if type(receipt)=="table" and
           tonumber(receipt.itemID)==tonumber(itemID) then
            local status=receipt.status
            local remote=receipt.remoteSyncStatus
            local awaitingReceipt=status~="OBTAINED"
            local awaitingPlayer=status=="OBTAINED" and
                remote~=nil and remote~="" and remote~="ACKNOWLEDGED"
            if awaitingReceipt or awaitingPlayer then
                summary.receiptPending=summary.receiptPending+1
            end
        end
    end
    -- Keep the existing historical local wishlist boolean. Confirmed
    -- OBTAINED status is not an active local reservation, but missing
    -- status data MUST fail closed. Consult saved tables read-only.
    for character,raids in pairs(db.localWishlists) do
        if type(raids)=="table" then
            local mc=raids.MOLTEN_CORE
            if type(mc)=="table" and mc[itemID]==true then
                local statuses=db.localWishlistObtained and
                    db.localWishlistObtained[character]
                local obtained=type(statuses)=="table" and
                    statuses.MOLTEN_CORE
                local received=type(obtained)=="table" and
                    obtained[itemID]==true
                if not received then
                    summary.localCount=summary.localCount+1
                end
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
    local questType=itemType=="Quest" or
        (type(ITEM_CLASS_QUESTITEM)=="string" and
         itemType==ITEM_CLASS_QUESTITEM)
    if self:IsGuildMaterial(itemID) then
        -- Whitelisting an item ID must never override a custom server's
        -- quest/legendary/recipe classification or high-rarity safeguards.
        if questType or (item and item.legendary) or
           classification=="Recipe" or
           (type(quality)=="number" and quality>=5) then
            return "SPECIAL_HOLD",classification,
                "Guild item is quest/legendary/recipe/special; manual only"
        end
        if type(quality)~="number" or not itemType then
            return "INFORMATION_MISSING","Guild material",
                "Item quality/type unavailable; open loot/item cache"
        end
        return nil,"Guild material",nil
    end
    if (item and (item.legendary or item.manualOnly)) or questType or
       (type(quality)=="number" and quality>=5) then
        return "SPECIAL_HOLD",classification,
            "Legendary/quest/manual/special: leader review only"
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
    local guildMaster=self:GetGuildMaster()
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
            local lootInfoKnown=false
            if type(GetLootSlotInfo)=="function" then
                local _,_,count,_,isLocked=GetLootSlotInfo(slot)
                local parsed=tonumber(count)
                -- Never assume a missing/invalid live stack count is 1:
                -- a later Master Loot request would be based on guesswork.
                lootInfoKnown=parsed~=nil and parsed%1==0 and
                    parsed>=0
                if lootInfoKnown then quantity=parsed end
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
            local threshold=type(GetLootThreshold)=="function" and
                tonumber(GetLootThreshold()) or nil
            if locked or quantity<1 then
                status="LOCKED"
                reason="Loot slot is locked or empty"
            elseif category=="SPECIAL_HOLD" then
                status="SPECIAL_HOLD"
            elseif summary.need>0 or summary.greed>0 then
                status="RESERVED"
                reason=summary.need.." NEED, "..summary.greed.." GREED (including absent bots/players)"
            elseif summary.unknown>0 or summary.localCount>0 or
                   summary.incoming>0 or summary.receiptPending>0 then
                status="UNRESOLVED"
                reason=summary.receiptPending>0 and
                    ("Pending winner receipt/player ACK ("..
                    summary.receiptPending..") - NEVER auto-route") or
                    "Unknown records/local wishlist/pending Inbox - do not auto-route"
            elseif category=="INFORMATION_MISSING" then
                status="UNRESOLVED"
            elseif not lootInfoKnown then
                status="LOOT_INFO_UNKNOWN"
                reason="WoW loot-slot stack count unavailable; no transfer"
            elseif self:IsGuildMaterial(id) and
                   (not threshold or threshold<0 or threshold>7) then
                status="THRESHOLD_UNKNOWN"
                reason="Cannot verify WoW Master Loot threshold; no guild transfer"
            elseif self:IsGuildMaterial(id) and
                   type(quality)=="number" and quality<threshold then
                status="BELOW_THRESHOLD"
                reason="Below WoW Master Loot threshold. Cannot assign "..
                    "with Master Looter; loot normally, then trade if allowed."
            else
                status="GUILD_REVIEW"
                reason="No saved NEED/GREED found; VERIFY with guild before directing to leader"
            end
            rows[#rows+1]={
                itemID=id,itemName=name or LinkName(link) or ("Item "..id),
                guildMaterial=self:IsGuildMaterial(id),
                guildMaster=guildMaster,
                itemLink=link,slotIndex=slot,quantity=quantity,
                lootInfoKnown=lootInfoKnown,
                category=itemType or "Unclassified item",status=status,
                reason=reason or "Manual review",leader=leader,
                need=summary.need,greed=summary.greed,
                localCount=summary.localCount,pending=summary.incoming,
                receiptPending=summary.receiptPending,
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
