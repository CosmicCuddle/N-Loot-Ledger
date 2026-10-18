-- NLL: opt-in AUTOMATIC GUILD ALLOCATION PREVIEW ONLY.
-- No timer, drop handler, addon message or preview can GiveMasterLoot.
-- "Proposed" means locally unreserved and needs HUMAN final review;
-- it is NOT proof that absent/offline clients have no unsubmitted wishes.
local NLL=NaxxLootLottery
NLL.GuildAutoPreview=NLL.GuildAutoPreview or {}
local P=NLL.GuildAutoPreview
local function PriorWinnerAttempt(itemID,slot)
    for _,row in ipairs(NLL.db and NLL.db.lootAwardHistory or {}) do
        if tonumber(row.itemID)==itemID and row.slotIndex==slot and
           (row.status=="AWARD_REQUESTED" or
            row.status=="AWARD_OUTCOME_UNKNOWN" or
            row.status=="LOOT_SLOT_CLEARED") then
            -- Even a manually CLOSED_NO_RETRY investigation stays locked.
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
    for _,source in ipairs(scanned) do
        local decision,reason="HOLD",source.reason
        if source.status=="GUILD_REVIEW" then
            if unresolved then
                decision="HOLD_UNRESOLVED_REQUEST"
                reason="Another Master Loot outcome is uncertain; manual reconciliation first"
            elseif NLL.GuildLootTransfer and
                   NLL.GuildLootTransfer:WasAttempted(source.itemID,source.slotIndex) then
                decision="HOLD_PREVIOUS_ATTEMPT"
                reason="This item/slot has a permanent guild Master Loot attempt lock"
            elseif PriorWinnerAttempt(source.itemID,source.slotIndex) then
                decision="HOLD_PREVIOUS_ATTEMPT"
                reason="This item/slot has a previous winner Master Loot attempt"
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
        local proposed=decision=="PROPOSE_TO_LEADER"
        if proposed then result.proposed=result.proposed+1
        else result.held=result.held+1 end
        result.rows[#result.rows+1]={
            itemID=source.itemID,itemName=source.itemName,
            itemLink=source.itemLink,quantity=source.quantity,
            slotIndex=source.slotIndex,category=source.category,
            leader=source.leader,proposedRecipient=proposed and source.leader or nil,
            sourceStatus=source.status,decision=decision,reason=reason,
            need=source.need,greed=source.greed,
            -- NEVER produce an auto-allocation instruction in this stage.
            autoEligible=false,transferAuthorized=false,
            leaderCandidateVerified=false,physicalReceiptVerified=false,
        }
    end
    result.leader=scanned[1].leader
    result.message="DRY RUN: "..result.proposed.." proposals for leader review; "..
        result.held.." holds. ZERO automatic or physical item transfers."
    return result
end
