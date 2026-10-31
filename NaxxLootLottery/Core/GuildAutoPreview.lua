-- NLL: opt-in AUTOMATIC GUILD ALLOCATION PREVIEW ONLY.
-- No timer, drop handler, addon message or preview can GiveMasterLoot.
-- "Proposed" means locally unreserved and needs HUMAN final review;
-- it is NOT proof that absent/offline clients have no unsubmitted wishes.
local NLL=NaxxLootLottery
NLL.GuildAutoPreview=NLL.GuildAutoPreview or {}
local P=NLL.GuildAutoPreview
local function Key(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
local function LiveMasterLooter()
    if type(GetLootMethod)~="function" or
       type(GetRaidRosterInfo)~="function" or
       type(UnitName)~="function" then return false end
    local method,_,raidIndex=GetLootMethod()
    if method~="master" or type(raidIndex)~="number" or
       raidIndex<1 then return false end
    local designated=GetRaidRosterInfo(raidIndex)
    return Key(designated)~="" and
        Key(designated)==Key(UnitName("player"))
end
local function ActiveLottery()
    local current=NLL.TicketLottery and NLL.TicketLottery.active
    return current and current.status~="COMPLETE" and
        current.status~="CANCELLED" and
        current.status~="INVALIDATED"
end
local function PriorWinnerAttempt(itemID,slot)
    for _,row in ipairs(NLL.db and NLL.db.lootAwardHistory or {}) do
        if tonumber(row.itemID)==tonumber(itemID) and
           (row.status=="AWARD_REQUESTED" or
            row.status=="AWARD_OUTCOME_UNKNOWN" or
            row.status=="LOOT_SLOT_CLEARED") then
            -- Loot slot positions are not physical identity. Fail CLOSED
            -- across item-ID matches; do not silently auto-propose old
            -- winner attempts merely because the item moved to a new slot.
            return true
        end
    end
    return false
end
function P:IsEnabled()
    return NLL.db and NLL.db.settings and
        NLL.db.settings.guildAutoPreviewEnabled==true
end
function P:SetEnabled(enabled)
    if not NLL.db or not NLL.db.settings then
        return false,"Settings unavailable."
    end
    if enabled and NLL.DebugSimulator and
        NLL.DebugSimulator:IsActive() then
        return false,"Fake raids cannot enable guild allocation previews."
    end
    NLL.db.settings.guildAutoPreviewEnabled=enabled==true
    return true,enabled and "Guild allocation DRY RUN on: NO item transfers." or
        "Guild allocation preview OFF: no item transfers."
end

function P:Build()
    local result={mode="DRY_RUN",rows={},proposed=0,held=0,
        autoEligible=0,transferAuthorized=false,leader=nil,
        message="Read-only; no item will be transferred."}
    if not self:IsEnabled() then
        result.message="Guild allocation preview OFF. No item transfers."
        return result
    end
    if not NLL.GuildLootReview then
        result.message="Guild Loot review unavailable; no proposal possible."
        return result
    end
    -- The underlying scanner refuses fake raids, closed loot, ambiguous
    -- leadership and missing APIs. A saved loot history is NEVER live loot.
    local scanned,message=NLL.GuildLootReview:Scan()
    if #scanned==0 then
        result.message=message or "No live item slots; no proposals."
        return result
    end
    local unresolved=NLL.GuildLootTransfer and
        NLL.GuildLootTransfer:IsUnresolved()
    local lotteryBusy=ActiveLottery()
    local masterOK=LiveMasterLooter()
    for _,source in ipairs(scanned) do
        local decision,reason="HOLD",source.reason
        if source.status=="GUILD_REVIEW" then
            if unresolved then
                decision="HOLD_UNRESOLVED_REQUEST"
                reason="Another Master Loot outcome is uncertain; manual reconciliation first"
            elseif NLL.GuildLootTransfer and
                   NLL.GuildLootTransfer:WasAttempted(source.itemID,source.slotIndex) then
                decision="HOLD_PREVIOUS_ATTEMPT"
                reason="This item ID has a prior guild attempt; slot changes cannot prove a new corpse"
            elseif PriorWinnerAttempt(source.itemID,source.slotIndex) then
                decision="HOLD_PREVIOUS_ATTEMPT"
                reason="This item ID has a prior winner attempt; physical copy identity is unverified"
            elseif lotteryBusy then
                decision="HOLD_ACTIVE_ROLL"
                reason="A ticket lottery is pending; no guild allocation proposal"
            elseif not masterOK then
                decision="HOLD_MASTER_LOOT"
                reason="The acting character is not the verified WoW Master Looter"
            elseif source.guildMaterial then
                decision="USE_LEADER_TICKETS"
                reason="Guild material uses Prepare Tickets / Start Roll, sole raid leader; NO transfer here"
            elseif source.guildMaterial and not source.guildMaster then
                decision="HOLD_GUILD_MASTER"
                reason="Actual guild master is not verified online and present in raid; no fallback to raid leader"
            elseif source.guildMaterial then
                decision="PROPOSE_TO_GUILD_MASTER"
                reason="Guild master identified; physical loot candidate and any unsent reservations need manual review"
            else
                decision="PROPOSE_TO_LEADER"
                reason="No SAVED reservation found; guild/other clients must verify first"
            end
        elseif source.status=="RESERVED" then
            decision="HOLD_RESERVED"
        elseif source.status=="SPECIAL_HOLD" then
            decision="HOLD_SPECIAL"
        elseif source.status=="LOCKED" then
            decision="HOLD_LOCKED"
        else
            decision="HOLD_UNCERTAIN"
        end
        local proposed=decision=="PROPOSE_TO_LEADER" or
            decision=="PROPOSE_TO_GUILD_MASTER"
        if proposed then result.proposed=result.proposed+1
        else result.held=result.held+1 end
        result.rows[#result.rows+1]={
            itemID=source.itemID,itemName=source.itemName,
            itemLink=source.itemLink,quantity=source.quantity,
            slotIndex=source.slotIndex,category=source.category,
            leader=source.leader,guildMaster=source.guildMaster,
            guildMaterial=source.guildMaterial==true,
            recipientKind=proposed and (source.guildMaterial and
                "GUILD_MASTER" or "RAID_LEADER") or nil,
            proposedRecipient=proposed and (source.guildMaterial and
                source.guildMaster or source.leader) or nil,
            sourceStatus=source.status,decision=decision,reason=reason,
            need=source.need,greed=source.greed,
            receiptPending=source.receiptPending or 0,
            -- NEVER produce an auto-allocation instruction in this stage.
            autoEligible=false,transferAuthorized=false,
            leaderCandidateVerified=false,physicalReceiptVerified=false,
        }
    end
    result.leader=scanned[1].leader
    result.message="DRY RUN: "..result.proposed.." proposal(s) for manual review; "..
        result.held.." holds. Recipients are informational; no candidate verified. ZERO physical transfers."
    return result
end
